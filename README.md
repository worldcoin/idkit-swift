<a href="https://docs.worldcoin.org/">
  <img src="https://raw.githubusercontent.com/worldcoin/world-id-docs/main/public/images/shared-readme/readme-header.png" alt="" />
</a>

# IDKit (Swift)

[![Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm1guelpf%2Fziggy-vapor%2Fbadge%3Ftype%3Dswift-versions&color=brightgreen)](http://swift.org)
[![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://swiftpackageindex.com/worldcoin/idkit-swift)

The `IDKit` library provides a simple Swift interface for prompting users for World ID proofs. For other platforms, check out the following:
- [Kotlin](https://github.com/worldcoin/idkit-kotlin)
- [React and React Native](https://github.com/worldcoin/idkit-js)

## Usage
There are three main ways to use `idkit-swift`:

1. To request proof of a minimum verification level. For example, if you ask for proof with a minimum level `document` proof, you may get a `document`, `secure_document` or `orb` proof, depending on the highest verification level that the user has.

   For more on the concept of verification levels, see [this page](https://docs.world.org/world-id/concepts).
2. To request proof of verification with specific credential categories. For example, if you ask for a `secure_document` proof, you will only receive a proof if the user verified using a `secure_document` category of credential.

3. To request proof that the user is 18+ years of age. The World App only allows `document` or `secure_document` verifications if the user is 18+. Therefore, you can request proof of verification using one or both of these two categories as a proxy of proof that user is 18+ years of age.

All of these require the creation of a `Session` with our hosted [Wallet Bridge service](https://github.com/worldcoin/wallet-bridge), then polling for an update from the World App instance that the user is using to respond to the request. Wallet Bridge acts as a secure relay between your app and World App.

> [!CAUTION]
> A `Session` instance is valid only for a single proof request, and should not be re-used or cached. It's reasonably inexpensive to create, though does make a network call during initialization. By design, re-using `Sessions` will lead to errors that are user-facing in both World App and your app.

### Proof of Minimum Verification Level
Use the verification level API when you're interested in getting the strongest human assurance level of a user. 

```swift
import IDKit

 // 1. Initialize your App ID configured in World Developer Portal.
let appID: AppID
do {
	appID = try AppID("your_app_id")
} catch {
	// Handle error
	return
}

// 2. Create a session with Wallet Bridge. This requests that the user proves they're a human with an orb level verification.
let session = try await Session(appID, action: "your_action", verificationLevel: .orb)

// 3. Create a universal link compatible with World App.
let verificationURL = session.verificationURL

// 4. Launch World App with the verification level request.
UIApplication.shared.open(verificationURL)

// 5. Poll for the result of the request. 
for try await status in session.status() {
	switch status {
	case .waitingForConnection:
		print("Waiting for the user to scan the QR Code")
	case .awaitingConfirmation:
		print("Awaiting user confirmation")
	case let .confirmed(proof):
		print("Got proof: \(proof)")
	case let .failed(error):
		print("Got error: \(error)")
	}
}
```

### Proof of Specific Credential Categories
Use this API when you're interested in knowing if a user possesses a credential from one of the specific categories you specify. There are 3 supported categories:

1. `document` - for credentials derived from NFC-enabled documents that can be cloned.
2. `secure_document` - for credentials derived from NFC-enabled documents that can't be cloned.
3. `personhood` - for credentials derived from the Orb. 

```swift
import IDKit

// 1. Initialize your AppID
let appID: AppID
do {
	appID = try AppID("your_app_id")
} catch {
	// Handle error
	return
}

// 2. Create a session with Wallet Bridge. This session requests both a secure document and personhood proof.
let session = try await Session(appID, action: "your_action", credentialCategories: [.secure_document, .personhood])

// 3. Create a universal link that opens either World App Clip or World App. This approach significantly speeds up getting proofs from users who don't have a verified World ID.
let deferredOnboardingURL = try session.deferredOnboardingURL

// 4. Launch World App, or World App Clip, with the credential presentation request.
UIApplication.shared.open(deferredOnboardingURL)

// 5. Poll for the result of the request. 
for try await status in session.status() {
	switch status {
	case .waitingForConnection:
		print("Waiting for the user to scan the QR Code")
	case .awaitingConfirmation:
		print("Awaiting user confirmation")
	case let .confirmed(proof):
		print("Got proof: \(proof)")
	case let .failed(error):
		print("Got error: \(error)")
	}
}
```

Note: If `personhood` is requested along with `document` or `secure_document`, a proof of `personhood` will only be returned if the user also has `document` or `secure_document` credentials. Else, the user will be prompted to verify themselves using a `document` or `secure_document` credential first.

### Proof of Age of 18+ Years

The World App only accepts `document` or `secure_document` verifications if the user is 18+ as determined from the user's date of birth stored on the NFC chip of the document. Therefore, you can request proof of verification using these two categories as proof that user is 18+ years of age.

To do this, use credential categories API with the categories set to `[.document, .secure_document]`.  

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
