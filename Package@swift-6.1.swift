// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NamiPairing",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "NamiPairing",
            targets: ["NamiPairingFramework"]),
    ],
    targets: [
        .binaryTarget(
            name: "NamiPairingFramework",
            path: "Sources/NamiPairing/NamiPairingFramework.xcframework"),
    ]
)
