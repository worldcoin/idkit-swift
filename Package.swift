// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "idkit-swift",
	platforms: [.macOS(.v13), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
	products: [
		.library(name: "IDKit", targets: ["IDKit"]),
	],
	dependencies: [],
	targets: [
		.target(
			name: "Keccak",
			path: "./Sources/Keccak",
			publicHeadersPath: "include"
		),
		.target(
			name: "IDKit",
			dependencies: [
				"Keccak",
			],
			path: "./Sources/IDKit",
			swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
		),
		.testTarget(
			name: "IDKitTests",
			dependencies: ["IDKit"],
			swiftSettings: [.enableExperimentalFeature("SwiftTesting")]
		),
	]
)
