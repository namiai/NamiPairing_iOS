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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.3/NamiPairingFramework.xcframework.zip",
            checksum: "c1563a098c5fcfa8173a1e8f721b398224f0d451ae91c3a2bf41b011452c01b5"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.3/StandardPairingUI.xcframework.zip",
            checksum: "bec9450aa55ad33cd9969be992b78343c92a4acf85142dcc6baac105bb65b3ea"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.3/DeviceConnections.xcframework.zip",
            checksum: "41211b4f2e42b66a8679032ccf5c1daf813674d6b09737b90fbe09fa24c869b0")
    ]
)
