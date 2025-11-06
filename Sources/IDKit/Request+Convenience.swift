import Foundation

public extension Request {
    /// Mirrors IDKit v2 Swift initializer that accepted a string signal.
    convenience init(
        credentialType: CredentialType,
        signal: String?,
        faceAuth: Bool? = nil
    ) throws {
        let signalObject = signal.map { Signal.fromString(s: $0) }
        let base = Request(credentialType: credentialType, signal: signalObject)
        let final = faceAuth.map { base.withFaceAuth(faceAuth: $0) } ?? base
        self.init(unsafeFromRawPointer: final.uniffiClonePointer())
    }

    /// Mirrors the IDKit v2 Swift initializer that accepted raw ABI-encoded bytes.
    convenience init(
        credentialType: CredentialType,
        abiEncodedSignal: Data,
        faceAuth: Bool? = nil
    ) throws {
        let signalObject = Signal.fromAbiEncoded(bytes: abiEncodedSignal)
        let base = Request(credentialType: credentialType, signal: signalObject)
        let final = faceAuth.map { base.withFaceAuth(faceAuth: $0) } ?? base
        self.init(unsafeFromRawPointer: final.uniffiClonePointer())
    }
}

public extension Signal {
    /// Backwards-compatible computed property returning the raw bytes as Data.
    var data: Data { Data(self.asBytes()) }

    /// Backwards-compatible computed property exposing the string form when available.
    var string: String? { self.asString() }
}
