// swift-tools-version: 5.9
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
            targets: ["IDKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "idkitFFI",
            url: "https://api.github.com/repos/worldcoin/idkit-swift/releases/assets/318935300.zip",
            checksum: "98ea5021da442e5e358455700a6229ccea34cc608b657f5b0f47df68d3687313"
        ),
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
        .testTarget(
            name: "IDKitTests",
            dependencies: ["IDKit"],
            exclude: ["README.md"]
        ),
    ]
)
// Release version: 3.0.3
