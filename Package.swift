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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.1/NamiPairingFramework.xcframework.zip",
            checksum: "819233da9de6f0c6bd20346ddc81332ae8d7029d7d447e2710e54d95dbdc770e"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.1/StandardPairingUI.xcframework.zip",
            checksum: "0b6024b64d3662776dd4e9fff66f87e28e0e5f75f625fa13f31a1253d8e21a81"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.1/DeviceConnections.xcframework.zip",
            checksum: "3f6c128980e906eaeb14b3b25a4c3614ad87fecd9807d2204c0ac47e96bd4f27")
    ]
)
