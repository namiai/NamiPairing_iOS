// swift-tools-version: 5.7
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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.2/NamiPairingFramework.xcframework.zip",
            checksum: "8d59a4e435f212a324856abaf33fd1a5f33191f9c12ec4e891ba5626a6baa022"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.2/StandardPairingUI.xcframework.zip",
            checksum: "a9e6427d194d6a64b91be9086065b90477ed9e25a9094e92f6a607732df91dab"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.2/DeviceConnections.xcframework.zip",
            checksum: "cb1180f5c436f06d729d08e55e2353729993b76621d12942c0e783a0153c5476")
    ]
)
