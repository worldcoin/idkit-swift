import Foundation

public typealias IDKitRequestConfig = IdKitRequestConfig
public typealias IDKitSessionConfig = IdKitSessionConfig
public typealias IDKitResult = IdKitResult

/// Main entry point for IDKit Swift SDK.
public enum IDKit {
    public static let version = "4.0.0"

    /// Creates a builder for uniqueness proof requests.
    public static func request(config: IDKitRequestConfig) -> IDKitBuilder {
        IDKitBuilder(inner: IdKitBuilder.fromRequest(config: config))
    }

    /// Creates a builder for creating a new session.
    public static func createSession(config: IDKitSessionConfig) -> IDKitBuilder {
        IDKitBuilder(inner: IdKitBuilder.fromCreateSession(config: config))
    }

    /// Creates a builder for proving an existing session.
    public static func proveSession(sessionId: String, config: IDKitSessionConfig) -> IDKitBuilder {
        IDKitBuilder(inner: IdKitBuilder.fromProveSession(sessionId: sessionId, config: config))
    }

    /// Hashes a string signal to the canonical 0x-prefixed field element string.
    public static func hashSignal(_ signal: String) -> String {
        hashSignalFfi(signal: Signal.fromString(s: signal))
    }

    /// Hashes raw signal bytes to the canonical 0x-prefixed field element string.
    public static func hashSignal(_ signal: Data) -> String {
        hashSignalFfi(signal: Signal.fromBytes(bytes: signal))
    }
}

/// Builder wrapper that returns canonical `IDKitRequest` values.
public final class IDKitBuilder {
    private let inner: IdKitBuilder

    fileprivate init(inner: IdKitBuilder) {
        self.inner = inner
    }

    public func constraints(_ constraints: ConstraintNode) throws -> IDKitRequest {
        let request = try inner.constraints(constraints: constraints)
        return try IDKitRequest(inner: request)
    }

    public func preset(_ preset: Preset) throws -> IDKitRequest {
        let request = try inner.preset(preset: preset)
        return try IDKitRequest(inner: request)
    }
}

/// One-shot polling status returned by `IDKitRequest.pollStatusOnce()`.
public enum IDKitStatus: Equatable {
    case waitingForConnection
    case awaitingConfirmation
    case confirmed(IDKitResult)
    case failed(IDKitErrorCode)
}

/// Result returned by `IDKitRequest.pollUntilCompletion(options:)`.
public enum IDKitCompletionResult: Equatable {
    case success(IDKitResult)
    case failure(IDKitErrorCode)
}

/// Polling options for `pollUntilCompletion`.
public struct IDKitPollOptions: Equatable {
    public var pollIntervalMs: UInt64
    public var timeoutMs: UInt64

    public init(pollIntervalMs: UInt64 = 1_000, timeoutMs: UInt64 = 300_000) {
        self.pollIntervalMs = pollIntervalMs
        self.timeoutMs = timeoutMs
    }
}

/// Canonical error codes exposed by the Swift API.
///
/// World App errors mirror JS `IDKitErrorCodes` naming and values.
/// `timeout` and `cancelled` are client-side errors.
public enum IDKitErrorCode: String, Equatable {
    case userRejected = "user_rejected"
    case verificationRejected = "verification_rejected"
    case credentialUnavailable = "credential_unavailable"
    case malformedRequest = "malformed_request"
    case invalidNetwork = "invalid_network"
    case inclusionProofPending = "inclusion_proof_pending"
    case inclusionProofFailed = "inclusion_proof_failed"
    case unexpectedResponse = "unexpected_response"
    case connectionFailed = "connection_failed"
    case maxVerificationsReached = "max_verifications_reached"
    case failedByHostApp = "failed_by_host_app"
    case genericError = "generic_error"
    case timeout = "timeout"
    case cancelled = "cancelled"

    static func from(appError: AppError) -> Self {
        switch appError {
        case .userRejected:
            .userRejected
        case .verificationRejected:
            .verificationRejected
        case .credentialUnavailable:
            .credentialUnavailable
        case .malformedRequest:
            .malformedRequest
        case .invalidNetwork:
            .invalidNetwork
        case .inclusionProofPending:
            .inclusionProofPending
        case .inclusionProofFailed:
            .inclusionProofFailed
        case .unexpectedResponse:
            .unexpectedResponse
        case .connectionFailed:
            .connectionFailed
        case .maxVerificationsReached:
            .maxVerificationsReached
        case .failedByHostApp:
            .failedByHostApp
        case .genericError:
            .genericError
        }
    }
}

/// Client-side errors raised while constructing canonical wrappers.
public enum IDKitClientError: Error, LocalizedError {
    case invalidConnectorURL(String)
    case invalidRequestID(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConnectorURL(let value):
            return "Invalid connector URL: \(value)"
        case .invalidRequestID(let value):
            return "Invalid request ID: \(value)"
        }
    }
}

/// Canonical request wrapper.
public final class IDKitRequest {
    public let connectorURL: URL
    public let requestID: UUID

    private let pollOnceImpl: @Sendable () async -> IDKitStatus

    fileprivate init(inner: IdKitRequestWrapper) throws {
        let rawURL = inner.connectUrl()
        guard let connectorURL = URL(string: rawURL) else {
            throw IDKitClientError.invalidConnectorURL(rawURL)
        }

        let rawRequestID = inner.requestId()
        guard let requestID = UUID(uuidString: rawRequestID) else {
            throw IDKitClientError.invalidRequestID(rawRequestID)
        }

        self.connectorURL = connectorURL
        self.requestID = requestID
        self.pollOnceImpl = {
            Self.mapStatus(inner.pollStatusOnce())
        }
    }

    // Internal initializer for deterministic polling tests.
    init(connectorURL: URL, requestID: UUID, pollOnce: @escaping @Sendable () async -> IDKitStatus) {
        self.connectorURL = connectorURL
        self.requestID = requestID
        self.pollOnceImpl = pollOnce
    }

    /// Polls the request exactly once.
    public func pollStatusOnce() async -> IDKitStatus {
        await pollOnceImpl()
    }

    /// Polls repeatedly until a terminal result, timeout, or cancellation.
    public func pollUntilCompletion(options: IDKitPollOptions = IDKitPollOptions()) async -> IDKitCompletionResult {
        let pollIntervalMs = max(options.pollIntervalMs, 1)
        let startTime = Date()

        while true {
            if Task.isCancelled {
                return .failure(.cancelled)
            }

            let elapsedMs = Date().timeIntervalSince(startTime) * 1_000
            if elapsedMs >= Double(options.timeoutMs) {
                return .failure(.timeout)
            }

            let status = await pollStatusOnce()
            switch status {
            case .confirmed(let result):
                return .success(result)
            case .failed(let error):
                return .failure(error)
            case .waitingForConnection, .awaitingConfirmation:
                break
            }

            do {
                try await Task.sleep(nanoseconds: pollIntervalMs * 1_000_000)
            } catch {
                return .failure(.cancelled)
            }
        }
    }

    static func mapStatus(_ status: StatusWrapper) -> IDKitStatus {
        switch status {
        case .waitingForConnection:
            .waitingForConnection
        case .awaitingConfirmation:
            .awaitingConfirmation
        case .confirmed(let result):
            .confirmed(result)
        case .failed(let error):
            .failed(IDKitErrorCode.from(appError: error))
        }
    }
}

public struct CredentialRequestOptions: Equatable {
    public var signal: String?
    public var genesisIssuedAtMin: UInt64?
    public var expiresAtMin: UInt64?

    public init(
        signal: String? = nil,
        genesisIssuedAtMin: UInt64? = nil,
        expiresAtMin: UInt64? = nil
    ) {
        self.signal = signal
        self.genesisIssuedAtMin = genesisIssuedAtMin
        self.expiresAtMin = expiresAtMin
    }
}

public extension CredentialRequest {
    /// Creates a `CredentialRequest` with optional string signal.
    static func create(_ type: CredentialType, signal: String? = nil) -> CredentialRequest {
        CredentialRequest.withStringSignal(credentialType: type, signal: signal)
    }

    /// Creates a `CredentialRequest` with options parity with JS core:
    /// `signal`, `genesis_issued_at_min`, and `expires_at_min`.
    static func create(_ type: CredentialType, options: CredentialRequestOptions) throws -> CredentialRequest {
        if options.genesisIssuedAtMin == nil, options.expiresAtMin == nil {
            return CredentialRequest.withStringSignal(credentialType: type, signal: options.signal)
        }

        let payload = CredentialRequestJSON(
            type: type.requestType,
            signal: options.signal,
            genesisIssuedAtMin: options.genesisIssuedAtMin,
            expiresAtMin: options.expiresAtMin
        )
        let encoded = try JSONEncoder().encode(payload)
        let json = String(decoding: encoded, as: UTF8.self)
        return try CredentialRequest.fromJson(json: json)
    }
}

public func anyOf(_ items: CredentialRequest...) -> ConstraintNode {
    ConstraintNode.any(nodes: items.map { ConstraintNode.item(request: $0) })
}

public func anyOf(_ items: [CredentialRequest]) -> ConstraintNode {
    ConstraintNode.any(nodes: items.map { ConstraintNode.item(request: $0) })
}

public func anyOf(nodes: ConstraintNode...) -> ConstraintNode {
    ConstraintNode.any(nodes: nodes)
}

public func anyOf(nodes: [ConstraintNode]) -> ConstraintNode {
    ConstraintNode.any(nodes: nodes)
}

public func allOf(_ items: CredentialRequest...) -> ConstraintNode {
    ConstraintNode.all(nodes: items.map { ConstraintNode.item(request: $0) })
}

public func allOf(_ items: [CredentialRequest]) -> ConstraintNode {
    ConstraintNode.all(nodes: items.map { ConstraintNode.item(request: $0) })
}

public func allOf(nodes: ConstraintNode...) -> ConstraintNode {
    ConstraintNode.all(nodes: nodes)
}

public func allOf(nodes: [ConstraintNode]) -> ConstraintNode {
    ConstraintNode.all(nodes: nodes)
}

public func orbLegacy(signal: String? = nil) -> Preset {
    .orbLegacy(signal: signal)
}

public func secureDocumentLegacy(signal: String? = nil) -> Preset {
    .secureDocumentLegacy(signal: signal)
}

public func documentLegacy(signal: String? = nil) -> Preset {
    .documentLegacy(signal: signal)
}

private struct CredentialRequestJSON: Encodable {
    let type: String
    let signal: String?
    let genesisIssuedAtMin: UInt64?
    let expiresAtMin: UInt64?

    enum CodingKeys: String, CodingKey {
        case type
        case signal
        case genesisIssuedAtMin = "genesis_issued_at_min"
        case expiresAtMin = "expires_at_min"
    }
}

private extension CredentialType {
    var requestType: String {
        switch self {
        case .orb:
            return "orb"
        case .face:
            return "face"
        case .secureDocument:
            return "secure_document"
        case .document:
            return "document"
        case .device:
            return "device"
        }
    }
}

public extension Signal {
    var bytesData: Data {
        Data(self.asBytes())
    }

    var stringValue: String? {
        self.asString()
    }
}
