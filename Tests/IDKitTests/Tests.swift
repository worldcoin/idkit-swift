@testable import IDKit
import Testing

@Test(.disabled("Run this manually to test the library!")) func testFlow() async throws {
	let session = try await Session(AppID("app_ce4cb73cb75fc3b73b71ffb4de178410"), action: "test-action")

	let verificationURL = session.verificationURL

	// Generate a QR Code with this URL and scan it with World App
	print("Connection URL: \(verificationURL)")

	for try await status in session.status() {
		switch status {
			case .waitingForConnection:
				print("Waiting for the user to scan the QR Code")
			case .awaitingConfirmation:
				print("Awaiting user confirmation")
			case let .confirmed(proof):
				print("Got proof: \(proof)")
			case let .failed(error):
				print("Got error: \(error.localizedDescription)")
		}
	}
}

// MARK: - encodeSignal Tests

@Test func testEncodeSignalEmpty() throws {
	// Empty string should hash to keccak256("") >> 8
	#expect(try encodeSignal("") == "0x00c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a4")
}

@Test func testEncodeSignalHelloWorld() throws {
	#expect(try encodeSignal("hello world") == "0x0047173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01f")
}

@Test func testEncodeSignalTest() throws {
	#expect(try encodeSignal("test") == "0x009c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb6")
}

@Test func testEncodeSignalMyTestSignal() throws {
	#expect(try encodeSignal("my_test_signal") == "0x0063cd863d8abefd774a9cf896b5628208d11c2975639f996c6d05f943a20036")
}

@Test func testEncodeSignalSignal1() throws {
	#expect(try encodeSignal("signal1") == "0x00f20f8ca6b12bd32d799ca43c344265f00191a7455e061ead0b3620ea869f54")
}

@Test func testEncodeSignalSignal2() throws {
	#expect(try encodeSignal("signal2") == "0x0086bfb4197550d7104cfa94a8678249d6dbb1296134ac537231e28da770d843")
}

@Test func testEncodeSignalAnyString() throws {
	#expect(try encodeSignal("any_string") == "0x0092f38309c0e58ba0a94f6d8f5f7a0804013e12611fce779d05761924be6282")
}

@Test func testEncodeSignalNumeric() throws {
	#expect(try encodeSignal("12345") == "0x001841d653f9c4edda9d66a7e7737b39763d6bd40f569a3ec6859d3305b72310")
}

@Test func testEncodeSignalSingleSpace() throws {
	#expect(try encodeSignal(" ") == "0x00681afa780d17da29203322b473d3f210a7d621259a4e6ce9e403f5a266ff71")
}

@Test func testEncodeSignalDoubleSpace() throws {
	#expect(try encodeSignal("  ") == "0x0061b60eed9684ac70562be74e9b9ccb0b2ff8d286a9fc2928b3e798416d65ea")
}

@Test func testEncodeSignalTab() throws {
	#expect(try encodeSignal("\t") == "0x00b2e7b7a21d986ae84d62a7de4a916f006c4e42a596358b93bad65492d174c4")
}

@Test func testEncodeSignalTestSignal123() throws {
	#expect(try encodeSignal("test_signal_123") == "0x00670b177d9cbfa149888e1c0b4fd0826a4eb2f4c1288244a0add43a3409950d")
}

@Test func testEncodeSignalConsistency() throws {
	// Same input should always produce same output
	let signal = "consistency_test"
	let result1 = try encodeSignal(signal)
	let result2 = try encodeSignal(signal)
	#expect(result1 == result2)
}

@Test func testEncodeSignalFormat() throws {
	// All outputs should have the format: 0x + 64 hex characters
	let testCases = ["test", "hello", "123", ""]
	
	for testCase in testCases {
		let result = try encodeSignal(testCase)
		#expect(result.hasPrefix("0x"))
		#expect(result.count == 66)
		
		let hexPart = String(result.dropFirst(2))
		#expect(hexPart.allSatisfy { $0.isHexDigit })
	}
}
