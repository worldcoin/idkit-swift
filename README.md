<a href="https://docs.worldcoin.org/">
  <img src="https://raw.githubusercontent.com/worldcoin/world-id-docs/main/public/images/shared-readme/readme-header.png" alt="" />
</a>

# IDKit (Swift)

This repository is the Swift Package Manager (SPM) mirror for the [IDKit](https://github.com/worldcoin/idkit) Rust SDK. The Swift sources are generated via [UniFFI](https://mozilla.github.io/uniffi-rs/), giving Swift clients the exact same surface area as the Rust core without any bespoke glue code.

## Package Layout

```
Sources/
  IDKit/
    IDKit.swift                // Version metadata
    Generated/                 // UniFFI-generated Swift + C headers
IDKitFFI.xcframework           // (added during release automation)
```

The `Generated/` directory is copied directly from the build artifacts produced in the main `idkit` repository. Release automation then builds the universal Rust library and publishes an `IDKitFFI.xcframework`, which this package references.

## Installation

Add the package to your project using SwiftPM:

```swift
.package(url: "https://github.com/worldcoin/idkit-swift", from: "3.0.0")
```

## Quick Start

```swift
import IDKit

let signal = Signal.fromString(s: "user_action_12345")
let request = Request(credentialType: .orb, signal: signal)

let session = try Session.create(
    appId: "app_staging_1234567890abcdef",
    action: "vote",
    requests: [request]
)

print("Scan this QR code in World App: \(session.connectUrl())")

let proof = try session.waitForProofWithTimeout(timeoutSeconds: 900)
print("Verified! Nullifier: \(proof.nullifierHash)")
```

For manual status polling:

```swift
while true {
    let status = try session.poll()
    switch status {
    case .waitingForConnection:
        print("Waiting for the user to scan…")
    case .awaitingConfirmation:
        print("User is confirming…")
    case .confirmed(let proof):
        print("Proof ready: \(proof)")
        break
    case .failed(let error):
        fatalError("Verification failed: \(error)")
    }

    Thread.sleep(forTimeInterval: 3)
}
```

## Releasing New Builds

Releases are automated from the main [`idkit`](https://github.com/worldcoin/idkit) repo. Merging a PR into `main` with the `release` label triggers the "Publish Swift Release" workflow, which:

1. Builds the universal Rust library and regenerates the Swift bindings.
2. Produces `IDKitFFI.xcframework` and uploads it as a draft release asset here.
3. Syncs `Sources/IDKit`, updates `Package.swift` with the new asset URL and checksum, and tags the release.
4. Publishes the release so Swift Package Manager clients can pull the new binary target.

For local testing you can run `scripts/package-swift.sh` in the main repo and follow the same steps manually.

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
