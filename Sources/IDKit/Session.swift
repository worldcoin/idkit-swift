import Web3
import BigInt
import IDKitCore
import Foundation
import CryptoSwift

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
		signal: String = "",
		actionDescription: String? = nil
	) async throws {
		let payload = CreateRequestPayload(
			appID: appID,
			action: action,
			signal: try encodeSignal(signal),
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

func encodeSignal(_ signal: String) throws -> String {
	// Encode signal data
	let signalData = signal.data(using: .utf8) ?? Data()
	
	// Convert Data to bytes array and use SHA3 with keccak256 variant
	let bytes = [UInt8](signalData)
	let hash = SHA3(variant: .keccak256).calculate(for: bytes)
	
	// Convert to hex string
	let hashData = Data(hash)
	let hexString = String(BigUInt(hashData) >> 8, radix: 16)
	// Pad with leading zeros to ensure 64 characters
	let paddedHex = String(repeating: "0", count: max(0, 64 - hexString.count)) + hexString
	return "0x" + paddedHex
}
