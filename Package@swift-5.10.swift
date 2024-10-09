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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.1.0/NamiPairingFramework.xcframework.zip",
            checksum: "1bea476e6be495864d8f44f52f65fec7eb54c9439a19595e38b21803887b5dc9"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.1.0/StandardPairingUI.xcframework.zip",
            checksum: "6fba8c302c28ad9b9a3abc9172b61c816f7888ea14d2594a556cfe046a07f21f"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.1.0/DeviceConnections.xcframework.zip",
            checksum: "8477b8cb15fc6074876068bc75ac795a312abb50725e9f699509d6e846bdedd0")
    ]
)
