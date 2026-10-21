// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Release version: 4.2.0

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
    targets: [
        .binaryTarget(
            name: "idkitFFI",
            url: "https://github.com/worldcoin/idkit-swift/releases/download/4.2.0/IDKitFFI.xcframework.zip",
            checksum: "2edcbb057d6d511e54dea47a28872dd1ed76ff0fa3231d276b3e38d085969fae"
        ),
        .target(
            name: "IDKit",
            dependencies: [
                "idkitFFI"
            ],
            path: "Sources/IDKit",
            exclude: [
                "Generated/idkit_coreFFI.h",
                "Generated/idkit_coreFFI.modulemap"
            ]
        )
    ]
)
