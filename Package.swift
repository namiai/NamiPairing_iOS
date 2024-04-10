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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.5/NamiPairingFramework.xcframework.zip",
            checksum: "800dd625e810fa73feb7d3752572c6f443fc6cb96864bd5d51a823f658a95d55"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.5/StandardPairingUI.xcframework.zip",
            checksum: "cd4e76313226d4c3bbeadf94f442d7cb67dd3946da4d9447058b95826a94ddb5"),
    ]
)
