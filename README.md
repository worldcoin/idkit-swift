<a href="https://docs.worldcoin.org/">
  <img src="https://raw.githubusercontent.com/worldcoin/world-id-docs/main/public/images/shared-readme/readme-header.png" alt="" />
</a>

# IDKit (Swift)

[![Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm1guelpf%2Fziggy-vapor%2Fbadge%3Ftype%3Dswift-versions&color=brightgreen)](http://swift.org)
[![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://swiftpackageindex.com/worldcoin/idkit-swift/documentation)

The `IDKit` library provides a simple Swift interface for prompting users for World ID proofs. For our Web and React Native SDKs, check out the [IDKit JS library](https://github.com/worldcoin/idkit-js).

## Usage

```swift
import IDKit

let session = try await Session(AppID("app_ce4cb73cb75fc3b73b71ffb4de178410"), action: "test-action")

// Generate a QR Code with this URL and scan it with World App
let connect_url = session.connect_url

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
```

<!-- WORLD-ID-SHARED-README-TAG:START - Do not remove or modify this section directly -->
<!-- The contents of this file are inserted to all World ID repositories to provide general context on World ID. -->

## <img align="left" width="28" height="28" src="https://raw.githubusercontent.com/worldcoin/world-id-docs/main/public/images/shared-readme/readme-world-id.png" alt="" style="margin-right: 0; padding-right: 4px;" /> About World ID

World ID is the privacy-first identity protocol that brings global proof of personhood to the internet. More on World ID in the [announcement blog post](https://worldcoin.org/blog/announcements/introducing-world-id-and-sdk).

World ID lets you seamlessly integrate authentication into your app that verifies accounts belong to real persons through [Sign in with Worldcoin](https://docs.worldcoin.org/id/sign-in). For additional flexibility and cases where you need extreme privacy, [Anonymous Actions](https://docs.worldcoin.org/id/anonymous-actions) lets you verify users in a way that cannot be tracked across verifications.

Follow the [Quick Start](https://docs.worldcoin.org/quick-start) guide for the easiest way to get started.

## 📄 Documentation

All the technical docs for the Wordcoin SDK, World ID Protocol, examples, guides can be found at https://docs.worldcoin.org/

<a href="https://docs.worldcoin.org">
  <p align="center">
    <picture align="center">
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/worldcoin/world-id-docs/main/public/images/shared-readme/visit-documentation-dark.png" height="50px" />
      <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/worldcoin/world-id-docs/main/public/images/shared-readme/visit-documentation-light.png" height="50px" />
      <img />
    </picture>
  </p>
</a>

<!-- WORLD-ID-SHARED-README-TAG:END -->
