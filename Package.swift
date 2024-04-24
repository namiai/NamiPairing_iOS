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
            targets: ["NamiPairingFramework", "StandardPairingUI"]),
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6/NamiPairingFramework.xcframework.zip",
            checksum: "3bf2f54f728a701e2ef1d72436fd3346e975f6c5e31a1e016259661628056ba0"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6/StandardPairingUI.xcframework.zip",
            checksum: "4a1b82319efffded4cf32344a491f229965233ecd33b86f60fe98325d65ebe20"),
    ]
)
