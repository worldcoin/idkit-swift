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
            url: "<asset_url>",
            checksum: "<checksum>"
        )
    ]
)
// Release version: <version>
