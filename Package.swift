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
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", .upToNextMajor(from: "4.4.3")),
    ],
    targets: [
        .binaryTarget(
            name: "NamiPairingFramework",
            url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.9.0/NamiPairingFramework.xcframework.zip",
            checksum: "bd1149784062f339d58fd26dc8772121783812c07f8f2c5f940821e914f1c7d2"),
        .binaryTarget(
            name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.9.0/StandardPairingUI.xcframework.zip",
            checksum: "fe81b152a27bda0514faf6c73b5550878c0def2087fab0bba1fdff6a97c274e1"),
        .target(
            name: "NamiPairingCore",
            dependencies: [
                "NamiPairingFramework",
                .product(name: "Lottie", package: "lottie-spm")
            ],
            path: "Sources/NamiPairing/NamiPairingCore"
        ),
    ]
)
