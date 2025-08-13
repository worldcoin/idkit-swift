@testable import IDKit
import Testing

@Test(.disabled("Run this manually to test the library!")) func testFlow() async throws {
    let (connectURL, stream) = try await initiateSession(AppID("app_ce4cb73cb75fc3b73b71ffb4de178410"), action: "test-action", verificationLevel: .device)

	// Generate a QR Code with this URL and scan it with World App
	print("Connection URL: \(connectURL)")

	for try await status in stream {
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
