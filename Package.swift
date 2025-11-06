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
    dependencies: [],
    targets: [
        .target(
            name: "IDKit",
            dependencies: ["idkitFFI"],
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
        )
    ]
)
// Release version: <version>
