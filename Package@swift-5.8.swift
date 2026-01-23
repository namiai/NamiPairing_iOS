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
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", .upToNextMajor(from: "4.4.3")),
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.7.3/NamiPairingFramework.xcframework.zip",
            checksum: "6d42348c0db9b952a9fa01529d50587a7e8022fa6fc4004cfd2df8b0be4b6382"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.7.3/StandardPairingUI.xcframework.zip",
            checksum: "dfecf684c058adb0095479003fc83f3dc9289888d1b08fa8a4b6e33aee7e0f26"),
        .target(
          name: "NamiPairingCore",
          dependencies: [
            "NamiPairingFramework",
            .product(name: "Lottie", package: "lottie-spm"),
          ],
          path: "Sources/NamiPairing/NamiPairingCore"
        ),
    ]
)
