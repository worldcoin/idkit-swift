import Foundation

/// Main entry point for IDKit Swift SDK
public enum IDKit {
    /// Version of the IDKit SDK
    public static let version = "4.0.0"

    /// Creates a new IDKit request builder for uniqueness proofs
    ///
    /// This is the main entry point for creating World ID verification requests.
    /// Use the builder pattern with constraints to specify which credentials to accept.
    ///
    /// - Parameter config: Request configuration
    /// - Returns: An IDKitBuilder instance
    ///
    /// Example:
    /// ```swift
    /// let request = try IDKit.request(config: config)
    ///     .constraints(anyOf(CredentialRequest.create(.orb), CredentialRequest.create(.face)))
    /// ```
    public static func request(config: IDKitRequestConfig) -> IDKitBuilder {
        IdKitBuilder.fromRequest(config: config)
    }

    /// Creates a new IDKit builder for creating a new session
    ///
    /// Use this when creating a new session for a user who doesn't have one yet.
    /// The response will include a session_id that should be saved for future session proofs.
    ///
    /// - Parameter config: Session configuration
    /// - Returns: An IDKitBuilder instance
    ///
    /// Example:
    /// ```swift
    /// let request = try IDKit.createSession(config: sessionConfig)
    ///     .constraints(anyOf(CredentialRequest.create(.orb), CredentialRequest.create(.face)))
    /// let result = try request.pollStatus()
    /// // Save result.sessionId for future sessions
    /// ```
    public static func createSession(config: IDKitSessionConfig) -> IDKitBuilder {
        IdKitBuilder.fromCreateSession(config: config)
    }

    /// Creates a new IDKit builder for proving an existing session
    ///
    /// Use this when a returning user needs to prove they own an existing session.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID from a previous session creation
    ///   - config: Session configuration
    /// - Returns: An IDKitBuilder instance
    ///
    /// Example:
    /// ```swift
    /// let request = try IDKit.proveSession(sessionId: savedSessionId, config: sessionConfig)
    ///     .constraints(anyOf(CredentialRequest.create(.orb), CredentialRequest.create(.face)))
    /// ```
    public static func proveSession(sessionId: String, config: IDKitSessionConfig) -> IDKitBuilder {
        IdKitBuilder.fromProveSession(sessionId: sessionId, config: config)
    }
}

// MARK: - CredentialRequest convenience extension
//
// UniFFI generates static methods from Rust constructors:
//   - CredentialRequest.new(credentialType:signal:) - takes Signal?
//   - CredentialRequest.withStringSignal(credentialType:signal:) - takes String?
//
// The static `create` method below provides a cleaner positional API:
//   CredentialRequest.create(.orb, signal: "test")

public extension CredentialRequest {
    /// Creates a CredentialRequest for a credential type with an optional string signal
    ///
    /// This is a convenience factory method with a cleaner positional API.
    ///
    /// - Parameters:
    ///   - type: The credential type (e.g., .orb, .face)
    ///   - signal: Optional signal string for cryptographic binding
    /// - Returns: A CredentialRequest instance
    ///
    /// Example:
    /// ```swift
    /// let orb = CredentialRequest.create(.orb, signal: "user-123")
    /// let face = CredentialRequest.create(.face)
    /// ```
    static func create(_ type: CredentialType, signal: String? = nil) -> CredentialRequest {
        CredentialRequest.withStringSignal(credentialType: type, signal: signal)
    }
}

// MARK: - Convenience wrappers around UniFFI-generated types

/// Creates an OR constraint - at least one child must be satisfied
///
/// - Parameter items: The request items (at least one must be satisfied)
/// - Returns: A ConstraintNode representing an "any" constraint
///
/// Example:
/// ```swift
/// let constraint = anyOf(CredentialRequest.create(.orb), CredentialRequest.create(.face))
/// ```
public func anyOf(_ items: CredentialRequest...) -> ConstraintNode {
    ConstraintNode.any(nodes: items.map { ConstraintNode.item(request: $0) })
}

/// Creates an OR constraint from an array of request items
///
/// - Parameter items: Array of request items (at least one must be satisfied)
/// - Returns: A ConstraintNode representing an "any" constraint
public func anyOf(_ items: [CredentialRequest]) -> ConstraintNode {
    ConstraintNode.any(nodes: items.map { ConstraintNode.item(request: $0) })
}

/// Creates an OR constraint from constraint nodes
///
/// - Parameter nodes: The constraint nodes (at least one must be satisfied)
/// - Returns: A ConstraintNode representing an "any" constraint
///
/// Example:
/// ```swift
/// let constraint = anyOf(nodes: ConstraintNode.item(request: orb), ConstraintNode.item(request: face))
/// ```
public func anyOf(nodes: ConstraintNode...) -> ConstraintNode {
    ConstraintNode.any(nodes: nodes)
}

/// Creates an OR constraint from an array of constraint nodes
///
/// - Parameter nodes: Array of constraint nodes (at least one must be satisfied)
/// - Returns: A ConstraintNode representing an "any" constraint
public func anyOf(nodes: [ConstraintNode]) -> ConstraintNode {
    ConstraintNode.any(nodes: nodes)
}

/// Creates an AND constraint - all children must be satisfied
///
/// - Parameter items: The request items (all must be satisfied)
/// - Returns: A ConstraintNode representing an "all" constraint
///
/// Example:
/// ```swift
/// let constraint = allOf(CredentialRequest.create(.orb), CredentialRequest.create(.document))
/// ```
public func allOf(_ items: CredentialRequest...) -> ConstraintNode {
    ConstraintNode.all(nodes: items.map { ConstraintNode.item(request: $0) })
}

/// Creates an AND constraint from an array of request items
///
/// - Parameter items: Array of request items (all must be satisfied)
/// - Returns: A ConstraintNode representing an "all" constraint
public func allOf(_ items: [CredentialRequest]) -> ConstraintNode {
    ConstraintNode.all(nodes: items.map { ConstraintNode.item(request: $0) })
}

/// Creates an AND constraint from constraint nodes
///
/// - Parameter nodes: The constraint nodes (all must be satisfied)
/// - Returns: A ConstraintNode representing an "all" constraint
///
/// Example:
/// ```swift
/// let constraint = allOf(nodes: orbNode, anyOf(document, secureDocument))
/// ```
public func allOf(nodes: ConstraintNode...) -> ConstraintNode {
    ConstraintNode.all(nodes: nodes)
}

/// Creates an AND constraint from an array of constraint nodes
///
/// - Parameter nodes: Array of constraint nodes (all must be satisfied)
/// - Returns: A ConstraintNode representing an "all" constraint
public func allOf(nodes: [ConstraintNode]) -> ConstraintNode {
    ConstraintNode.all(nodes: nodes)
}

// MARK: - Preset helpers

/// Creates an OrbLegacy preset for World ID 3.0 legacy support
///
/// This preset creates an IDKit request compatible with both World ID 4.0 and 3.0 protocols.
/// Use this when you need backward compatibility with older World App versions.
///
/// - Parameter signal: Optional signal string for cryptographic binding
/// - Returns: An OrbLegacy preset
///
/// Example:
/// ```swift
/// let request = try IDKit.request(config: config).preset(preset: orbLegacy(signal: "user-123"))
/// ```
public func orbLegacy(signal: String? = nil) -> Preset {
    .orbLegacy(signal: signal)
}

/// Creates a SecureDocumentLegacy preset for World ID 3.0 legacy support
///
/// This preset creates an IDKit request compatible with both World ID 4.0 and 3.0 protocols.
/// Use this when you need backward compatibility with older World App versions.
///
/// - Parameter signal: Optional signal string for cryptographic binding
/// - Returns: A SecureDocumentLegacy preset
///
/// Example:
/// ```swift
/// let request = try IDKit.request(config: config).preset(preset: secureDocumentLegacy(signal: "user-123"))
/// ```
public func secureDocumentLegacy(signal: String? = nil) -> Preset {
    .secureDocumentLegacy(signal: signal)
}

/// Creates a DocumentLegacy preset for World ID 3.0 legacy support
///
/// This preset creates an IDKit request compatible with both World ID 4.0 and 3.0 protocols.
/// Use this when you need backward compatibility with older World App versions.
///
/// - Parameter signal: Optional signal string for cryptographic binding
/// - Returns: A DocumentLegacy preset
///
/// Example:
/// ```swift
/// let request = try IDKit.request(config: config).preset(preset: documentLegacy(signal: "user-123"))
/// ```
public func documentLegacy(signal: String? = nil) -> Preset {
    .documentLegacy(signal: signal)
}

// MARK: - Hashing Utilities

public extension IDKit {
    /// Hashes a Signal to its hash representation.
    /// This is the same hashing used internally when constructing proof requests.
    ///
    /// - Parameter signal: The signal to hash
    /// - Returns: A 0x-prefixed hex string
    static func hashSignal(_ signal: Signal) -> String {
        hashSignalFfi(signal: signal)
    }
}

// MARK: - Signal convenience extensions

public extension Signal {
    /// Returns the signal bytes as Foundation Data
    var bytesData: Data {
        Data(self.asBytes())
    }

    /// Returns the signal as a string if it's valid UTF-8, nil otherwise
    var stringValue: String? {
        self.asString()
    }
}

