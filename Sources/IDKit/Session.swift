import BigInt
import IDKitCore
import Foundation
import CryptoSwift

public func initiateSession(
    _ appID: AppID,
    action: String,
    verificationLevel: VerificationLevel = .orb,
    bridgeURL: BridgeURL = .default,
    signal: String = "",
    actionDescription: String? = nil
) async throws -> (connectURL: URL, stream: AsyncThrowingStream<Status<Proof>, Error>) {
    let payload = CreateRequestPayload(
        appID: appID,
        action: action,
        signal: try encodeSignal(signal),
        actionDescription: actionDescription,
        verificationLevel: verificationLevel
    )

    return try await initiateSession(for: payload, bridgeURL: bridgeURL)
}

public func initiateSession(
    _ appID: AppID,
    action: String,
    credentialCategories: Set<CredentialCategory>,
    bridgeURL: BridgeURL = .default,
    signal: String = "",
    actionDescription: String? = nil
) async throws -> (connectURL: URL, stream: AsyncThrowingStream<Status<CredentialCategoryProofResponse>, Error>) {
    let payload = CredentialCategoryRequestPayload(
        appID: appID,
        action: action,
        signal: try encodeSignal(signal),
        actionDescription: actionDescription,
        credentialCategories: credentialCategories
    )

    return try await initiateSession(for: payload, bridgeURL: bridgeURL)
}

func initiateSession<Request: RequestPayload>(
    for request: Request,
    bridgeURL: BridgeURL
) async throws -> (connectURL: URL, stream: AsyncThrowingStream<Status<Request.Response>, Error>) {
    let client = try await BridgeClient(sending: request, to: bridgeURL)
    return (client.connect_url, client.status())
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
