import Foundation

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
	/// [Migrate from `credential_type` to `verification_level`](https://docs.world.org/world-id/reference/world-id-2-migration-guide#migrate-from-credential-types-to-verification-level)
	@available(*, deprecated, renamed: "verification_level", message: "Renamed to verification_level")
	public var credential_type: CredentialType { verification_level }
	public let verification_level: CredentialType

	// Separate coding key definition to avoid compile errors
	private enum _CodingKeys: CodingKey {
		case proof
		case merkle_root
		case nullifier_hash
		/// deprecated
		case credential_type
		case verification_level
	}
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: _CodingKeys.self)
		self.proof = try container.decode(String.self, forKey: .proof)
		self.merkle_root = try container.decode(String.self, forKey: .merkle_root)
		self.nullifier_hash = try container.decode(String.self, forKey: .nullifier_hash)
		if let credentialType = try? container.decodeIfPresent(Proof.CredentialType.self, forKey: .credential_type) {
			verification_level = credentialType
		} else {
			verification_level = try container.decode(Proof.CredentialType.self, forKey: .verification_level)
		}
	}
}

/// The minimum verification level accepted.
public enum VerificationLevel: String, Codable {
	case orb
	case device
    case document
    case secure_document
}

extension VerificationLevel {
    var credentialTypes: [Proof.CredentialType] {
        switch self {
			case .orb: [.orb]
			case .device: [.orb, .device]
			case .secure_document: [.orb, .secure_document]
			case .document: [.document, .secure_document, .orb]
        }
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
        credential_types = verificationLevel.credentialTypes
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
