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
            url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.8.3/NamiPairingFramework.xcframework.zip",
            checksum: "910c9f2105353a931c5ba1e8f941d6150aad83c9326f768ad3d22a74288c3082"),
        .binaryTarget(
            name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.8.3/StandardPairingUI.xcframework.zip",
            checksum: "c87c1977046a32353d7ed0b68a08c309a7ed4b97bbdacf9fcb2c43389ddd8d57"),
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
