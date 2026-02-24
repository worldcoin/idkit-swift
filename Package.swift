// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Release version: 4.0.2

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
            targets: ["IDKit"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "idkitFFI",
            url: "https://github.com/worldcoin/idkit-swift/releases/download/4.0.2/IDKitFFI.xcframework.zip",
            checksum: "26cf50fbb3ce9c04fd24e7e6854c018ddfadb8c0ed1676696724a226203f94f0"
        ),
        .target(
            name: "IDKit",
            dependencies: [
                "idkitFFI",
            ],
            path: "Sources/IDKit",
            exclude: [
                "Generated/idkit_coreFFI.h",
                "Generated/idkit_coreFFI.modulemap"
            ]
        )
    ]
)
