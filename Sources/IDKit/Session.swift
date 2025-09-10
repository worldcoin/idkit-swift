import BigInt
import Foundation
import CryptoSwift

/// A World ID session with the Wallet Bridge.
public struct Session<Response: Decodable & Sendable>: Sendable {
	public typealias Status = BridgeClient<Response>.Status

	private let client: BridgeClient<Response>

	/// The URL that the user should be directed to in order to connect their World App to the client.
    @available(*, deprecated, renamed: "verificationURL", message: "Prefer verificationURL")
	public var connect_url: URL {
		client.verificationURL
	}

    /// The URL that the user should be directed to in order to connect their World App to the client.
    public var verificationURL: URL {
        client.verificationURL
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

public extension Session where Response == Proof {
    /// Create a new session with the Wallet Bridge.
    ///
    /// # Errors
    ///
    /// Throws an error if the request to the bridge fails, or if the response from the bridge is malformed.
    init(
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

        client = try await BridgeClient(sending: payload, to: bridgeURL, linkType: "wld")
    }
}

public extension Session where Response == CredentialCategoryProofResponse {
    /// Establishes a session with Wallet Bridge for generating a proof that a Holder posesses at least one credential in any set of possible credential classes.
    /// - Parameters:
    ///   - appID: The app ID of the Relying Party.
    ///   - action: The identifier of the action related to the attestation.
    ///   - credentialCategories: The set of credentials for which a proof should be generated. The strictest credential will be preferred.
    ///   - bridgeURL: The URL of the Wallet Bridge instance to establish a session against.
    ///   - signal: The ZK signal associated with this session.
    ///   - actionDescription: A description of the action.
    /// # Errors
    /// * If the request to the bridge fails.
    /// * If the response from the bridge is malformed.
    init(
        _ appID: AppID,
        action: String,
        credentialCategories: Set<CredentialCategory>,
        bridgeURL: BridgeURL = .default,
        signal: String = "",
        actionDescription: String? = nil
    ) async throws {
        let payload = CredentialCategoryRequestPayload(
            appID: appID,
            action: action,
            signal: try encodeSignal(signal),
            actionDescription: actionDescription,
            credentialCategories: credentialCategories
        )

        client = try await BridgeClient(sending: payload, to: bridgeURL, linkType: "cred")
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
