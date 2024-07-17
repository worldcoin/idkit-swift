@testable import IDKit
import Testing

@Test(.disabled("Run this manually to test the library!")) func testFlow() async throws {
	let session = try await Session(AppID("app_ce4cb73cb75fc3b73b71ffb4de178410"), action: "test-action")

	let connect_url = session.connect_url

	// Generate a QR Code with this URL and scan it with World App
	print("Connection URL: \(connect_url)")

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
