// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Release version: 4.0.8-dev.4c2c6df

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
            url: "https://github.com/worldcoin/idkit-swift/releases/download/4.0.8-dev.4c2c6df/IDKitFFI.xcframework.zip",
            checksum: "803c5662943abdeb05ce95a65880bcfae5d2ab816501c11f92bfac743fdfdacf"
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
