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
            targets: ["NamiPairingCore", "StandardPairingUI"]),
        .library(
            name: "NamiPairing-NoUI",
            targets: ["NamiPairingCore"]),
    ],
    targets: [
        .binaryTarget(
            name: "NamiPairingFramework",
            url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.2.0/NamiPairingFramework.xcframework.zip",
            checksum: "5285a7023bc526bd06760ea8dd9acacc97bc5eefee73461ee0131553d3c93cc3"),
        .binaryTarget(
            name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.2.0/StandardPairingUI.xcframework.zip",
            checksum: "4d6fec46fb893fe9a38ecf4f81dd27ce91d230b2be30076f1dceaa2c1d90e16a"),
        .target(
            name: "NamiPairingCore",
            dependencies: [
                "NamiPairingFramework"
            ],
            path: "Sources/NamiPairing/NamiPairingCore"
        ),
    ]
)
