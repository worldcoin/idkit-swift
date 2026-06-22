@preconcurrency import Crypto
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A single per-`app_id` URL override entry, as returned by the bridge. Both
/// fields are independently optional.
///
/// - `app_clip_bundle_id`: the App Clip's bundle identifier (the `p` parameter
///   of an `appclip.apple.com/id` default link). The SDK builds the full link.
/// - `verify_url`: a verify *base* URL the SDK decorates with query params.
struct AppOverride: Codable {
	let app_clip_bundle_id: String?
	let verify_url: String?
}

/// The decoded `POST /request` response from the Wallet Bridge.
struct CreateRequestResponse: Codable {
	let request_id: UUID
	/// The full server-driven override map (`app_id → AppOverride`), returned
	/// verbatim by the bridge. The SDK selects its own `app_id` entry locally.
	/// Absent when no overrides are configured (or against an older bridge) —
	/// the SDK then keeps its built-in defaults.
	let app_overrides: [String: AppOverride]?
}

/// The default verify base URL when the bridge supplies no override.
let defaultVerificationBaseURL = URL(string: "https://world.org/verify")!

/// Whether a server-provided override base is safe to use as a URL: a
/// well-formed *absolute* http(s) URL with a host. `URL(string:)` is lenient
/// (e.g. `"not a url"` becomes a relative URL), so we validate explicitly and
/// fall back to defaults otherwise — untrusted server input must never produce
/// a broken verification/onboarding URL.
func isUsableOverrideBaseURL(_ string: String) -> Bool {
	guard let url = URL(string: string),
	      let scheme = url.scheme?.lowercased(),
	      scheme == "https" || scheme == "http",
	      url.host?.isEmpty == false
	else { return false }
	return true
}

/// Resolve the verify *base* URL: prefer the server-driven override when it is
/// a usable absolute URL, otherwise fall back to the built-in default. A
/// malformed override must never crash or break verification.
func resolveVerificationBaseURL(_ override: String?) -> URL {
	if let override, isUsableOverrideBaseURL(override), let url = URL(string: override) {
		return url
	}
	return defaultVerificationBaseURL
}

/// An abstraction over the Worldcoin Wallet Bridge.
public struct BridgeClient<Response: Decodable & Sendable>: Sendable {
	/// The status of a verification request.
	public enum Status: Equatable, Sendable {
		/// Waiting for the World App to retrieve the request
		case waitingForConnection
		/// Waiting for the user to confirm the request
		case awaitingConfirmation
		/// The user has confirmed the request. Contains the proof of verification.
		case confirmed(Response)
		/// The request has failed. Contains details about the failure.
		case failed(AppError)

		/// Check if two statuses are equal. Does not compare the associated values of `.confirmed` and `.failed`, only the case
		public static func == (lhs: Status, rhs: Status) -> Bool {
			switch (lhs, rhs) {
				case (.waitingForConnection, .waitingForConnection),
				     (.awaitingConfirmation, .awaitingConfirmation),
				     (.confirmed, .confirmed),
				     (.failed, .failed):
					return true
				default:
					return false
			}
		}
	}

	private struct BridgeQueryResponse: Codable {
		let status: String
		let response: Payload?
	}

	let requestID: UUID
	let key: SymmetricKey
	let iv: AES.GCM.Nonce
	let bridgeURL: BridgeURL
    let linkType: String
	/// Server-driven overrides for this session's `app_id`, or `nil` to use the
	/// built-in defaults. `appClipBundleID` is the App Clip default-link `p`
	/// value; `verifyURLBase` is a verify base URL the SDK decorates.
	let appClipBundleID: String?
	let verifyURLBase: String?

	/// The URL that the user should be directed to in order to connect their World App to the client.
    @available(*, deprecated, renamed: "connectURL", message: "Prefer connectURL over connect_url")
	public var connect_url: URL {
        verificationURL
	}

    /// The URL to open so a user can create or use their World App to handle your request. On iOS, this is a universal link that launches either World App or World App Clip depending on the installation status of World App. For more info, see https://developer.apple.com/documentation/appclip
    public var verificationURL: URL {
        var queryParams = [
            URLQueryItem(name: "t", value: linkType),
            URLQueryItem(name: "i", value: requestID.uuidString),
            URLQueryItem(name: "k", value: key.withUnsafeBytes { Data($0).base64EncodedString() }),
        ]

        if bridgeURL != .default {
            queryParams.append(URLQueryItem(name: "b", value: bridgeURL.rawURL.absoluteString))
        }

        // Prefer the server-driven verify base when present, but never trust it
        // blindly: a malformed override falls back to the built-in default
        // rather than crashing.
        return resolveVerificationBaseURL(verifyURLBase).appending(queryItems: queryParams)
    }

	/// Create a new session with the Wallet Bridge.
	///
	/// # Errors
	///
	/// Throws an error if the request to the bridge fails, or if the response from the bridge is malformed.
    public init<Request: Codable>(sending payload: Request, appID: String, to bridgeURL: BridgeURL = .default, linkType: String = "wld") async throws {
		self.bridgeURL = bridgeURL
        self.linkType = linkType
        key = SymmetricKey(size: .bits256)
        iv = AES.GCM.Nonce()

        let response = try await Self.create_request(payload.encrypt(with: key, nonce: iv), bridgeURL: bridgeURL)

        requestID = response.request_id

        // The bridge returns the whole override map; pick this app's entry (if
        // any) locally. `appID` is never sent to the bridge.
        let override = response.app_overrides?[appID]
        appClipBundleID = override?.app_clip_bundle_id
        verifyURLBase = override?.verify_url
	}

	/// Retrieve the status of the verification request.
	/// Returns a stream of status updates, which will be updated as the request progresses.
    /// This interface polls indefinetly. Clients are expected to implement a timeout with their preferred duration.
	///
    /// # Note
    /// Wallet Bridge times out a request after 15 minutes, though clients can prefer a shorter duration.
    ///
	/// # Errors
	/// The stream will throw an error if the request to the bridge fails, or if the response from the bridge is malformed.
	public func status() -> AsyncThrowingStream<Status, Error> {
		let (stream, continuation) = AsyncThrowingStream.makeStream(of: Status.self)

		let task = Task.detached {
			var currentStatus: Status = .waitingForConnection

			continuation.yield(currentStatus)

			do {
				while true {
					let response = try await get_status(for: requestID, bridgeURL: bridgeURL)

					if response.status == "completed" {
						guard let payload = response.response else { throw AppError.unexpectedResponse }

                        switch try payload.decrypt(with: key, responseType: BridgeResponse<Response>.self) {
							case let .error(error): continuation.yield(.failed(error))
							case let .success(proof): continuation.yield(.confirmed(proof))
						}

						continuation.finish()
						break
					}

					let status: Status = switch response.status {
						case "retrieved": .awaitingConfirmation
						case "initialized": .waitingForConnection
						default: throw AppError.unexpectedResponse
					}

					if status != currentStatus {
						currentStatus = status
						continuation.yield(status)
					}

					try await Task.sleep(nanoseconds: 3_000_000_000)
				}
			} catch {
				continuation.finish(throwing: error)
			}
		}

		continuation.onTermination = { _ in
			task.cancel()
		}

		return stream
	}

	private static func create_request(_ data: Payload, bridgeURL: BridgeURL) async throws -> CreateRequestResponse {
		var request = URLRequest(url: bridgeURL.rawURL.appendingPathComponent("request"))

		request.httpMethod = "POST"
		request.httpBody = try JSONEncoder().encode(data)

		request.setValue("idkit-swift", forHTTPHeaderField: "User-Agent")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unrecognizedBridgeResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.bridgeFailedToAddRequest
        }

		return try JSONDecoder().decode(CreateRequestResponse.self, from: data)
	}

	private func get_status(for requestID: UUID, bridgeURL: BridgeURL) async throws -> BridgeQueryResponse {
		let request = URLRequest(url: bridgeURL.rawURL.appendingPathComponent("response/\(requestID)"))

		let (data, res) = try await URLSession.shared.data(for: request)
		guard let res = res as? HTTPURLResponse, (200...299).contains(res.statusCode) else { throw AppError.connectionFailed }

		return try JSONDecoder().decode(BridgeQueryResponse.self, from: data)
	}
}
