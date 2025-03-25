import Foundation

public struct Proof: Codable, Sendable {
	/// The strongest credential with which a user has been verified.
	public enum CredentialType: String, Codable, Sendable {
		case orb
        case secure_document
        case document
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
    case secure_document
    case document
	case device
}

extension VerificationLevel {
    var credentialTypes: [Proof.CredentialType] {
        switch self {
        case .orb:
            return [.orb]
        case .secure_document:
            return [.orb, .secure_document]
        case .document:
            return [.document, .secure_document, .orb]
        case .device:
            return [.orb, .device]
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
