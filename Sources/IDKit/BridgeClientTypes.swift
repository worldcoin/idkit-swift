import CryptoKit
import Foundation

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
    /// Wallet Bridge returned an error code when the request was added.
    case bridgeFailedToAddRequest = "bridge_failed_to_add_request"
    /// Wallet Bridge returned an unrecognizable response (I.E it wasn't HTTP/S)
    case unrecognizedBridgeResponse = "unrecognized_bridge_response"
	/// Something unexpected went wrong. Please try again.
	case genericError = "generic_error"

	public var localizedDescription: String {
		switch self {
            case .unrecognizedBridgeResponse:
                return "Wallet Bridge returned something other than HTTP/S. Use a different bridge."
            case .bridgeFailedToAddRequest:
                return "Wallet Bridge failed to add the request. Please try again."
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

public struct Payload: Codable {
	let iv: String
	let payload: String

    public func decrypt<Response: Decodable>(with key: SymmetricKey, responseType: Response.Type) throws -> Response {
		let payload = Data(base64Encoded: self.payload)!
		let nonce = try AES.GCM.Nonce(data: Data(base64Encoded: iv)!)

		let cipher = payload.prefix(payload.count - 16)
		let authTag = payload.suffix(16)

        let decrypted = try AES.GCM.open(
            AES.GCM.SealedBox(nonce: nonce, ciphertext: cipher, tag: authTag),
            using: key
        )

		return try JSONDecoder().decode(Response.self, from: decrypted)
	}
}

public enum BridgeResponse<Response: Decodable>: Decodable {
	case success(Response)
	case error(AppError)

	enum CodingKeys: String, CodingKey {
		case proof
		case errorCode = "error_code"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		if let errorCode = try? container.decode(AppError.self, forKey: .errorCode) {
			self = .error(errorCode)
		} else {
			let response = try Response(from: decoder)
			self = .success(response)
		}
	}
}

extension BridgeResponse: Encodable where Response: Encodable {
	public func encode(to encoder: Encoder) throws {
		switch self {
			case let .success(response):
				try response.encode(to: encoder)
			case let .error(error):
				var container = encoder.container(keyedBy: CodingKeys.self)
				try container.encode(error, forKey: .errorCode)
		}
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

		public var localizedDescription: String {
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

	public let rawURL: URL

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
