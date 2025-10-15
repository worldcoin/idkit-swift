import CryptoKit
import Keccak

struct SHA3Keccak256: HashFunction {
	struct SHA3Keccak256Digest: CryptoKit.Digest, Sendable {
		static let byteCount = SHA3Keccak256.digestByteCount

		fileprivate let bytes: [UInt8]

		init(bytes: [UInt8]) {
			precondition(bytes.count == Self.byteCount, "Keccak digest must be 32 bytes")
			self.bytes = bytes
		}

		var count: Int { bytes.count }

		func makeIterator() -> Array<UInt8>.Iterator {
			bytes.makeIterator()
		}

		func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
			try bytes.withUnsafeBytes(body)
		}

		var description: String {
			bytes.map { String(format: "%02x", $0) }.joined()
		}

        var debugDescription: String {
            "SHA3Keccak256Digest(\(description))"
        }

		static func == (lhs: SHA3Keccak256Digest, rhs: SHA3Keccak256Digest) -> Bool {
			lhs.bytes == rhs.bytes
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(bytes.count)
			for chunk in bytes {
				hasher.combine(chunk)
			}
		}
	}

	typealias Digest = SHA3Keccak256Digest

	static let blockByteCount = 136
	static let digestByteCount = 32
	static let maxMessageLength = Int.max

	private var buffer = [UInt8]()

	init() {}

	mutating func update(bufferPointer: UnsafeRawBufferPointer) {
		guard !bufferPointer.isEmpty else {
			return
		}
		precondition(buffer.count <= Self.maxMessageLength - bufferPointer.count, "Message too long")
		buffer.append(contentsOf: bufferPointer)
	}

	func finalize() -> Digest {
		Digest(bytes: Self.computeDigest(for: buffer))
	}

	private static func computeDigest(for message: [UInt8]) -> [UInt8] {
		var digest = [UInt8](repeating: 0, count: digestByteCount)

		digest.withUnsafeMutableBufferPointer { outputBuffer in
			guard let outputBaseAddress = outputBuffer.baseAddress else {
				return
			}

			message.withUnsafeBufferPointer { inputBuffer in
				keccak256_hash(inputBuffer.baseAddress, inputBuffer.count, outputBaseAddress)
			}
		}

		return digest
	}
}
