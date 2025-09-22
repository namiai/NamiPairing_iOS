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
            targets: ["NamiPairingCore"])
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", path: "Sources/NamiPairing/NamiPairingFramework.xcframework"),
        .binaryTarget(name: "StandardPairingUI", path: "Sources/NamiPairing/StandardPairingUI.xcframework"),
        .target(
          name: "NamiPairingCore",
          dependencies: [
            "NamiPairingFramework",
          ],
          path: "Sources/NamiPairing/NamiPairingCore"
        ),
    ]
)
