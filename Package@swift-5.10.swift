// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NamiPairing",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "NamiPairing",
            targets: ["NamiPairingFramework", "StandardPairingUI", "DeviceConnections"]),
        .library(
            name: "NamiPairing-NoUI", 
            targets: ["NamiPairingFramework", "DeviceConnections"])
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", path: "Sources/NamiPairing/NamiPairingFramework.xcframework"),
        .binaryTarget(name: "StandardPairingUI", path: "Sources/NamiPairing/StandardPairingUI.xcframework"),
        .binaryTarget(name: "DeviceConnections", path: "Sources/NamiPairing/DeviceConnections.xcframework")
    ]
)
