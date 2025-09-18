import BigInt
import Foundation
import CryptoSwift

public enum SessionError: Error, CustomDebugStringConvertible {
    case incorrectDataEncoding(String)
    case deferredOnboardingURLInvalid(String)

    public var debugDescription: String {
        switch self {
        case .incorrectDataEncoding(let value):
            return "An unexpected data encoding was found: \(value). This is a bug in idkit-swift. Please file an issue: https://github.com/worldcoin/idkit-swift/issues"
        case .deferredOnboardingURLInvalid(let value):
            return "idkit was unable to create a valid deferred onboarding URL: \(value). This is a bug in idkit-swift. Please file an issue: https://github.com/worldcoin/idkit-swift/issues"
        }
    }
}

/// A World ID session with the Wallet Bridge.
public struct Session<Response: Decodable & Sendable>: Sendable {
	public typealias Status = BridgeClient<Response>.Status

	private let client: BridgeClient<Response>

	/// The URL that the user should be directed to in order to connect their World App to the client.
    @available(*, deprecated, renamed: "verificationURL", message: "Prefer verificationURL")
	public var connect_url: URL {
		client.verificationURL
	}

    /// The URL that the user should be directed to in order to connect their World App to the client. If World App isn't installed, this leads to the App Store for users to install the app. Clients of `idkit-swift` will need to re-issue the request in this case since iOS has no deferred deep linking capabilities.
    public var verificationURL: URL {
        client.verificationURL
    }
    
    /// A URL that links to World App Clip or World App, depending on what the user has installed. This URL is used to handle deferred deep linking, and facilitates on-boarding new users to World who may not have an account or a way to respond to a request yet. 
    public var deferredOnboardingURL: URL {
        get throws {
            guard let data = "\(verificationURL)".data(using: .utf8) else {
                throw SessionError.incorrectDataEncoding("\(verificationURL)")
            }

            let experience = data.base64URLEncodedString()
            let urlString = "https://appclip.apple.com/id?p=org.worldcoin.insight.Clip&experience=\(experience)"

            guard let deferredOnboardingURL = URL(string: urlString) else {
                throw SessionError.deferredOnboardingURLInvalid(urlString)
            }

            return deferredOnboardingURL
        }
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
        var credentialCategories = credentialCategories
        var orbVerificationRequest: CreateRequestPayload?

        if credentialCategories.contains(.personhood) {
            credentialCategories.remove(.personhood)
            orbVerificationRequest = CreateRequestPayload(
                appID: appID,
                action: action,
                signal: try encodeSignal(signal),
                actionDescription: actionDescription,
                verificationLevel: .orb
            )
        }

        let payload = CredentialCategoryRequestPayload(
            appID: appID,
            action: action,
            signal: try encodeSignal(signal),
            actionDescription: actionDescription,
            credentialCategories: credentialCategories,
            orbVerificationRequest: orbVerificationRequest
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
