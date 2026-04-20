// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Release version: 4.0.6-dev.9f6a75d

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
            url: "https://github.com/worldcoin/idkit-swift/releases/download/4.0.6-dev.9f6a75d/IDKitFFI.xcframework.zip",
            checksum: "a2eccf872e50c9c80baed65d04853052aa068dc2f1daf2f903c02ceddaaf3c96"
        ),
        // System-library shim that provides the idkit_coreFFI C module map.
        // Xcode 26 explicit-module-build mode fails to propagate binary-target
        // module maps to Swift dependents; this target forces the correct
        // -fmodule-map-file flag through SPM's official mechanism.
        .systemLibrary(
            name: "idkit_coreFFI",
            path: "Sources/IDKit/Generated"
        ),
        .target(
            name: "IDKit",
            dependencies: [
                "idkitFFI",
                "idkit_coreFFI"
            ],
            path: "Sources/IDKit",
            exclude: [
                "Generated/idkit_coreFFI.h",
                "Generated/idkit_coreFFI.modulemap",
                "Generated/module.modulemap"
            ]
        )
    ]
)
