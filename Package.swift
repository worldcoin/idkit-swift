// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "idkit-swift",
	platforms: [.macOS(.v13), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
	products: [
		.library(name: "IDKit", targets: ["IDKit"]),
		.library(name: "IDKitCore", targets: ["IDKitCore"]),
	],
	dependencies: [
		.package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.9.0"),
		.package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"4.0.0"),
	],
	targets: [
		.target(
			name: "IDKit",
			dependencies: [
				"IDKitCore",
				.product(name: "BigInt", package: "BigInt"),
				.product(name: "CryptoSwift", package: "CryptoSwift"),
			],
			path: "./Sources/IDKit",
			swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
		),
		.target(
			name: "IDKitCore",
			dependencies: [
				.product(name: "Crypto", package: "swift-crypto"),
			],
			path: "./Sources/IDKitCore",
			swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
		),
	]
)
