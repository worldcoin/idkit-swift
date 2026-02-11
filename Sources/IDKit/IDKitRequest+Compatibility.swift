import Foundation

// MARK: - Type Aliases for UniFFI Generated Types
// UniFFI 0.30 generates IdKit* names (not IDKit*), so we alias for public API consistency.

/// Type alias for public API - maps to generated IdKitBuilder (unified builder)
public typealias IDKitBuilder = IdKitBuilder
/// Type alias for backwards compatibility - maps to unified IdKitBuilder
public typealias IDKitRequestBuilder = IdKitBuilder
/// Type alias for backwards compatibility - maps to unified IdKitBuilder
public typealias IDKitSessionBuilder = IdKitBuilder
/// Type alias for public API - maps to generated IdKitRequestConfig
public typealias IDKitRequestConfig = IdKitRequestConfig
/// Type alias for public API - maps to generated IdKitSessionConfig
public typealias IDKitSessionConfig = IdKitSessionConfig
/// Type alias for public API - maps to generated IdKitRequestWrapper
public typealias IDKitRequestWrapper = IdKitRequestWrapper
/// Type alias for public API - maps to generated IdKitResult
public typealias IDKitResult = IdKitResult

/// Type alias for backwards compatibility
public typealias IDKitRequest = IdKitRequestWrapper
/// Type alias for backwards compatibility - the generated type is StatusWrapper
public typealias Status = StatusWrapper

/// Errors surfaced by the high-level Swift conveniences.
public enum IDKitRequestError: Error, LocalizedError {
    case timeout
    case verificationFailed(String)
    case invalidURL(String)

    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Verification timed out before completing"
        case .verificationFailed(let reason):
            return "Verification failed: \(reason)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        }
    }
}

// MARK: - IDKitRequestWrapper Extensions

public extension IDKitRequestWrapper {
    /// Matches the IDKit v2 `status()` helper
    func status(pollInterval: TimeInterval = 3.0) -> AsyncThrowingStream<StatusWrapper, Error> {
        AsyncThrowingStream { continuation in
            let pollingTask = Task {
                var previousStatus: StatusWrapper?

                do {
                    while !Task.isCancelled {
                        let current = self.pollStatus(pollIntervalMs: nil, timeoutMs: nil)

                        if current != previousStatus {
                            previousStatus = current
                            continuation.yield(current)
                        }

                        switch current {
                        case .confirmed, .failed:
                            continuation.finish()
                            return
                        case .waitingForConnection, .awaitingConfirmation:
                            break
                        }

                        try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                pollingTask.cancel()
            }
        }
    }

    /// Backwards-compatible alias for the IDKIT v3 async stream helper.
    func statusStream(pollInterval: TimeInterval = 3.0) -> AsyncThrowingStream<StatusWrapper, Error> {
        status(pollInterval: pollInterval)
    }

    /// Convenience accessor returning a URL instead of a string.
    var verificationURL: URL {
        let urlString = connectUrl()
        guard let url = URL(string: urlString) else {
            fatalError("Invalid connect URL generated: \(urlString)")
        }
        return url
    }

    var requestUUID: UUID {
        let raw = requestId()
        guard let uuid = UUID(uuidString: raw) else {
            fatalError("Invalid request ID generated: \(raw)")
        }
        return uuid
    }
}

// MARK: - StatusWrapper Convenience

public extension StatusWrapper {
    /// Returns the IDKitResult if this is a confirmed status, nil otherwise.
    var idkitResult: IDKitResult? {
        if case .confirmed(let result) = self {
            return result
        }
        return nil
    }

    /// Returns true if the result is a session proof (has a session_id).
    var isSessionResult: Bool {
        if case .confirmed(let result) = self {
            return result.sessionId != nil
        }
        return false
    }

    /// Returns the session ID if this is a session result, nil otherwise.
    var sessionId: String? {
        if case .confirmed(let result) = self {
            return result.sessionId
        }
        return nil
    }
}
