// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Release version: 4.0.0-dev.a6de581

import PackageDescription

let package = Package(
    name: "IDKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "IDKit",
            targets: ["IDKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.9.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"4.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "idkitFFI",
            url: "https://github.com/worldcoin/idkit-swift/releases/download/4.0.0-dev.a6de581/IDKitFFI.xcframework.zip",
            checksum: "30b84eedb12a0a55c812438c54ad81d96e7fd4bdf767b693cc860481563d1ba5"
        ),
        .target(
            name: "IDKit",
            dependencies: [
                "idkitFFI",
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "CryptoSwift", package: "CryptoSwift")
            ],
            path: "Sources/IDKit",
            exclude: [
                "Generated/idkitFFI.h",
                "Generated/idkitFFI.modulemap",
                "Generated/idkit_coreFFI.h",
                "Generated/idkit_coreFFI.modulemap"
            ]
        )
    ]
)
