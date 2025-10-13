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
            targets: ["NamiPairingCore", "StandardPairingUI"]),
        .library(
            name: "NamiPairing-NoUI",
            targets: ["NamiPairingCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", .upToNextMajor(from: "4.4.3")),
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.3.1/NamiPairingFramework.xcframework.zip",
            checksum: "f3713f1ae13fc5d6780c87e7fde62f3ebd5d22857536df007adc5975aa29dcb1"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.3.1/StandardPairingUI.xcframework.zip",
            checksum: "3ec69eb2dc453e77a974179074693b0983012851cbdb0242615756ef64801acd"),
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
