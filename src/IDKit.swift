import web3
import BigInt
@preconcurrency import Crypto
import Foundation

/// A session with the Wallet Bridge.
public struct Session: Sendable {
	/// The status of a verification request.
	public enum Status: Equatable, Sendable {
		/// Waiting for the World App to retrieve the request
		case waitingForConnection
		/// Waiting for the user to confirm the request
		case awaitingConfirmation
		/// The user has confirmed the request. Contains the proof of verification.
		case confirmed(Proof)
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

	let requestID: UUID
	let key: SymmetricKey
	let iv: AES.GCM.Nonce
	let bridgeURL: BridgeURL

	/// The URL that the user should be directed to in order to connect their World App to the client.
	public var connect_url: URL {
		var queryParams = [
			URLQueryItem(name: "t", value: "wld"),
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
	public init<Signal: ABIType>(
		_ appID: AppID,
		action: String,
		verificationLevel: VerificationLevel = .orb,
		bridgeURL: BridgeURL = .default,
		signal: Signal = "",
		actionDescription: String? = nil
	) async throws {
		self.bridgeURL = bridgeURL
		key = SymmetricKey(size: .bits256)
		iv = AES.GCM.Nonce()

		let response = try await BridgeClient.create_request(CreateRequestPayload(
			app_id: appID.rawId,
			action: action,
			signal: encodeSignal(signal),
			action_description: actionDescription,
			verification_level: verificationLevel
		).encrypt(with: key, nonce: iv), bridgeURL: bridgeURL)

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
			let request = URLRequest(url: self.bridgeURL.rawURL.appendingPathComponent("response/\(requestID)"))

			continuation.yield(currentStatus)

			do {
				while true {
					let (data, res) = try await URLSession.shared.data(for: request)
					guard let res = res as? HTTPURLResponse, (200...299).contains(res.statusCode) else { throw AppError.connectionFailed }

					let response = try JSONDecoder().decode(BridgeClient.BridgeQueryResponse.self, from: data)

					if response.status == "completed" {
						guard let payload = response.response else { throw AppError.unexpectedResponse }

						switch try payload.decrypt(with: key) {
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
}

func encodeSignal(_ signal: any ABIType) throws -> String {
	let bytes = try Data(ABIEncoder.encode(signal, packed: true).bytes).web3.keccak256

	return "0x" + String(BigUInt(bytes) >> 8, radix: 16)
}
