@preconcurrency import Crypto
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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

	private struct CreateRequestResponse: Codable {
		let request_id: UUID
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

        return URL(string: "https://worldcoin.org/verify")!.appending(queryItems: queryParams)
    }

	/// Create a new session with the Wallet Bridge.
	///
	/// # Errors
	///
	/// Throws an error if the request to the bridge fails, or if the response from the bridge is malformed.
    public init<Request: Codable>(sending payload: Request, to bridgeURL: BridgeURL = .default, linkType: String = "wld") async throws {
		self.bridgeURL = bridgeURL
        self.linkType = linkType
        key = SymmetricKey(size: .bits256)
        iv = AES.GCM.Nonce()

        let response = try await Self.create_request(payload.encrypt(with: key, nonce: iv), bridgeURL: bridgeURL)

        requestID = response.request_id
	}

	/// Retrieve the status of the verification request.
	/// Returns a stream of status updates, which will be updated as the request progresses.
	///
	/// # Errors
	///
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
