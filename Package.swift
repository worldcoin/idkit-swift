// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
            targets: ["IDKit", "idkitFFI"]
        )
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
                "idkitFFI",
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ],
            path: "Sources/IDKit",
            exclude: [
                "Generated/idkitFFI.h",
                "Generated/idkitFFI.modulemap",
                "Generated/idkit_coreFFI.h",
                "Generated/idkit_coreFFI.modulemap"
            ]
        ),
        .binaryTarget(
            name: "idkitFFI",
            // TODO: Update with actual release URL and checksum after first release
            // This will be populated by the publish-swift.yml workflow in idkit repo
            url: "https://github.com/worldcoin/idkit-swift/releases/download/0.0.0-placeholder/IDKitFFI.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
        .testTarget(
            name: "IDKitTests",
            dependencies: ["IDKit"]
        ),
    ]
)
// Release version: <version>
