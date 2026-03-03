// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Release version: 4.0.4

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
            url: "https://github.com/worldcoin/idkit-swift/releases/download/4.0.4/IDKitFFI.xcframework.zip",
            checksum: "0018f219fb842b496aea45d3258fffc16f2f988036bfc8fd16cdb82d228e9a46"
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
