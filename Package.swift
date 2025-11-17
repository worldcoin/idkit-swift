// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "idkit-swift",
	platforms: [.macOS(.v13), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
	products: [
		.library(name: "IDKit", targets: ["IDKit"]),
	],
	dependencies: [
		.package(url: "https://api.github.com/repos/worldcoin/idkit-swift/releases/assets/314157476.zip", from: "5.3.0"),
        .package(url: "https://api.github.com/repos/worldcoin/idkit-swift/releases/assets/314157476.zip", from: "1.9.0"),
		.package(url: "https://api.github.com/repos/worldcoin/idkit-swift/releases/assets/314157476.zip", "1.0.0"..<"4.0.0"),
	],
	targets: [
		.target(
			name: "IDKit",
			dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Crypto", package: "swift-crypto"),
				.product(name: "CryptoSwift", package: "CryptoSwift"),
			],
			path: "./Sources/IDKit",
			swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
		),
        .testTarget(
            name: "IDKitTests",
            dependencies: ["IDKit"]
        )
	]
)