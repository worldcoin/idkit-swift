import Foundation
import IDKitCore

/// The categories of credentials that are associated to a user's World ID.
public enum CredentialCategory: String, Codable, Sendable {
    /// The set of NFC credentials with no authentication.
    case document
    /// The set of NFC credentials with active or passive authentication.
    case secure_document
}

public struct Proof: Codable, Sendable {
	/// The strongest credential with which a user has been verified.
	public enum CredentialType: String, Codable, Sendable {
		case orb
		case device
        case document
        case secure_document
	}

	public let proof: String
	public let merkle_root: String
	public let nullifier_hash: String
	public let verification_level: CredentialType

	// Separate coding key definition to avoid compile errors
	private enum _CodingKeys: CodingKey {
		case proof
		case merkle_root
		case nullifier_hash
		case verification_level
	}
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: _CodingKeys.self)
		self.proof = try container.decode(String.self, forKey: .proof)
		self.merkle_root = try container.decode(String.self, forKey: .merkle_root)
		self.nullifier_hash = try container.decode(String.self, forKey: .nullifier_hash)
        self.verification_level = try container.decode(Proof.CredentialType.self, forKey: .verification_level)
	}
}

/// The minimum verification level accepted.
public enum VerificationLevel: String, Codable, Sendable {
	case orb
	case device
    case document
    case secure_document
}

struct CreateRequestPayload: Encodable, RequestPayload {
    typealias Response = Proof

	let app_id: String
	let action: String
	let signal: String
	let action_description: Optional<String>
	let verification_level: VerificationLevel

	init(appID: AppID, action: String, signal: String, actionDescription: String?, verificationLevel: VerificationLevel) {
		self.action = action
		self.signal = signal
		app_id = appID.rawId
		action_description = actionDescription
		verification_level = verificationLevel
	}
}

struct CredentialCategoryRequestPayload: Codable, RequestPayload {
    typealias Response = Proof

    let app_id: String
    let action: String
    let signal: String
    let action_description: Optional<String>
    let credential_categories: Set<CredentialCategory>

    init(appID: AppID, action: String, signal: String, actionDescription: String?, credentialCategories: Set<CredentialCategory>) {
        self.action = action
        self.signal = signal
        app_id = appID.rawId
        action_description = actionDescription
        credential_categories = credentialCategories
    }
}


public struct AppID {
	public enum AppIDError: Error {
		case invalidAppID
	}

	public let rawId: String

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
