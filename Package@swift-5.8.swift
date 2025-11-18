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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.4.3/NamiPairingFramework.xcframework.zip",
            checksum: "7eeddb3b26dcf32442d6ebbc540e2ecb14d7798cf26fc7f2f4e17750c1223920"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.4.3/StandardPairingUI.xcframework.zip",
            checksum: "2928bfd319a93d5ff068b6d428e2107db790707b6d98f06254e61e532076c486"),
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
