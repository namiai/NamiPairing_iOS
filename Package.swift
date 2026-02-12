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
            url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.8.1/NamiPairingFramework.xcframework.zip",
            checksum: "f56cd144153f0e4d18eabc5c9091db5c7b5d80a1ef07e810e74c35cd6e645cb3"),
        .binaryTarget(
            name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.8.1/StandardPairingUI.xcframework.zip",
            checksum: "ecbd744036fafaeb23f80d2eca012097474bd8bd6c5ef130cc261f934d58a865"),
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
