import Crypto
import Foundation

extension Encodable where Self: Decodable {
	func encrypt(with key: SymmetricKey, nonce: AES.GCM.Nonce) throws -> Payload<Self> {
		let sealedBox = try AES.GCM.seal(JSONEncoder().encode(self), using: key, nonce: nonce)
		var payload = sealedBox.ciphertext
		payload.append(sealedBox.tag)

		return Payload(
			iv: nonce.withUnsafeBytes { Data($0).base64EncodedString() },
			payload: payload.base64EncodedString()
		)
	}
}
