import Crypto
import Foundation

public struct Proof: Codable, Sendable {
	/// The strongest credential with which a user has been verified.
	public enum CredentialType: String, Codable, Sendable {
		case orb
		case device
	}

	public let proof: String
	public let merkle_root: String
	public let nullifier_hash: String
	public let credential_type: CredentialType
}

/// The minimum verification level accepted.
public enum VerificationLevel: String, Codable {
	case orb
	case device
}

/// The error returned by the World App.
public enum AppError: String, Error, Codable, Sendable {
	/// Failed to connect to the World App. Please create a new session and try again.
	case connectionFailed = "connection_failed"
	/// The user rejected the verification request in the World App.
	case verificationRejected = "verification_rejected"
	/// The user already verified the maximum number of times for this action.
	case maxVerificationsReached = "max_verifications_reached"
	/// The user does not have the verification level required by this app.
	case credentialUnavailable = "credential_unavailable"
	/// There was a problem with this request. Please try again or contact the app owner.
	case malformedRequest = "malformed_request"
	/// Invalid network. If you are the app owner, visit docs.worldcoin.org/test for details.
	case invalidNetwork = "invalid_network"
	/// There was an issue fetching the user's credential. Please try again.
	case inclusionProofFailed = "inclusion_proof_failed"
	/// The user's identity is still being registered. Please wait a few minutes and try again.
	case inclusionProofPending = "inclusion_proof_pending"
	/// Unexpected response from the user's World App. Please try again.
	case unexpectedResponse = "unexpected_response"
	/// Verification failed by the app. Please contact the app owner for details.
	case failedByHostApp = "failed_by_host_app"
	/// Something unexpected went wrong. Please try again.
	case genericError = "generic_error"

	var localizedDescription: String {
		switch self {
			case .connectionFailed:
				return "Failed to connect to the World App. Please create a new session and try again."
			case .verificationRejected:
				return "The user rejected the verification request in the World App."
			case .maxVerificationsReached:
				return "The user already verified the maximum number of times for this action."
			case .credentialUnavailable:
				return "The user does not have the verification level required by this app."
			case .malformedRequest:
				return "There was a problem with this request. Please try again or contact the app owner."
			case .invalidNetwork:
				return "Invalid network. If you are the app owner, visit docs.worldcoin.org/test for details."
			case .inclusionProofFailed:
				return "There was an issue fetching the user's credential. Please try again."
			case .inclusionProofPending:
				return "The user's identity is still being registered. Please wait a few minutes and try again."
			case .unexpectedResponse:
				return "Unexpected response from the user's World App. Please try again."
			case .failedByHostApp:
				return "Verification failed by the app. Please contact the app owner for details."
			case .genericError:
				return "Something unexpected went wrong. Please try again."
		}
	}
}

struct Payload: Codable {
	let iv: String
	let payload: String

	func decrypt(with key: SymmetricKey) throws -> BridgeResponse {
		let payload = Data(base64Encoded: self.payload)!
		let nonce = try AES.GCM.Nonce(data: Data(base64Encoded: iv)!)

		let cipher = payload.prefix(payload.count - 16)
		let authTag = payload.suffix(16)

		return try JSONDecoder().decode(BridgeResponse.self, from: AES.GCM.open(
			AES.GCM.SealedBox(nonce: nonce, ciphertext: cipher, tag: authTag),
			using: key
		))
	}
}

struct CreateRequestPayload: Codable {
	let app_id: String
	let action: String
	let signal: String
	let action_description: Optional<String>
	let verification_level: VerificationLevel
	let credential_types: [Proof.CredentialType]

	init(appID: AppID, action: String, signal: String, actionDescription: String?, verificationLevel: VerificationLevel) {
		self.action = action
		self.signal = signal
		app_id = appID.rawId
		action_description = actionDescription
		verification_level = verificationLevel
		credential_types = verificationLevel == .orb ? [.orb] : [.orb, .device]
	}

	func encrypt(with key: SymmetricKey, nonce: AES.GCM.Nonce) throws -> Payload {
		let sealedBox = try AES.GCM.seal(JSONEncoder().encode(self), using: key, nonce: nonce)
		var payload = sealedBox.ciphertext
		payload.append(sealedBox.tag)

		return Payload(
			iv: nonce.withUnsafeBytes { Data($0).base64EncodedString() },
			payload: payload.base64EncodedString()
		)
	}
}

public struct AppID {
	public enum AppIDError: Error {
		case invalidAppID
	}

	let rawId: String

	public var is_staging: Bool {
		rawId.starts(with: "app_staging_")
	}

	public init(_ app_id: String) throws {
		guard app_id.starts(with: "app_") else {
			throw AppIDError.invalidAppID
		}

		rawId = app_id
	}
}

public struct BridgeURL: Sendable, Equatable {
	public enum BridgeURLError: Error {
		/// Bridge URL must use HTTPS.
		case notHttps
		/// Bridge URL must use the default port.
		case notDefaultPort
		/// Bridge URL must not contain a path.
		case containsPath
		/// Bridge URL must not contain a query.
		case containsQuery
		/// Bridge URL must not contain a fragment.
		case containsFragment

		var localizedDescription: String {
			switch self {
				case .notHttps:
					return "Bridge URL must use HTTPS."
				case .notDefaultPort:
					return "Bridge URL must use the default port."
				case .containsPath:
					return "Bridge URL must not contain a path."
				case .containsQuery:
					return "Bridge URL must not contain a query."
				case .containsFragment:
					return "Bridge URL must not contain a fragment."
			}
		}
	}

	public static let `default` = try! BridgeURL(URL(string: "https://bridge.worldcoin.org")!)

	let rawURL: URL

	public init(_ url: URL) throws {
		if url.host == "localhost" || url.host == "127.0.0.1" {
			rawURL = url
			return
		}

		guard url.scheme == "https" else {
			throw BridgeURLError.notHttps
		}

		guard url.port == nil else {
			throw BridgeURLError.notDefaultPort
		}

		guard url.path == "" || url.path == "/" else {
			throw BridgeURLError.containsPath
		}

		guard url.query == nil else {
			throw BridgeURLError.containsQuery
		}

		guard url.fragment == nil else {
			throw BridgeURLError.containsFragment
		}

		rawURL = url
	}

	public static func == (lhs: BridgeURL, rhs: BridgeURL) -> Bool {
		lhs.rawURL == rhs.rawURL
	}
}
