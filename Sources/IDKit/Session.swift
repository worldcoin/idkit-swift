import BigInt
import IDKitCore
import Foundation

/// A World ID session with the Wallet Bridge.
public struct Session: Sendable {
	public typealias Status = BridgeClient<Proof>.Status

	let client: BridgeClient<Proof>

	/// The URL that the user should be directed to in order to connect their World App to the client.
	public var connect_url: URL {
		client.connect_url
	}

	/// Create a new session with the Wallet Bridge.
	///
	/// # Errors
	///
	/// Throws an error if the request to the bridge fails, or if the response from the bridge is malformed.
	public init(
		_ appID: AppID,
		action: String,
		verificationLevel: VerificationLevel = .orb,
		bridgeURL: BridgeURL = .default,
		actionDescription: String? = nil
	) async throws {
		let payload = CreateRequestPayload(
			appID: appID,
			action: action,
			actionDescription: actionDescription,
			verificationLevel: verificationLevel
		)

		client = try await BridgeClient(sending: payload, to: bridgeURL)
	}

	/// Retrieve the status of the verification request.
	/// Returns a stream of status updates, which will be updated as the request progresses.
	///
	/// # Errors
	///
	/// The stream will throw an error if the request to the bridge fails, or if the response from the bridge is malformed.
	public func status() -> AsyncThrowingStream<Status, Error> {
		return client.status()
	}
}
