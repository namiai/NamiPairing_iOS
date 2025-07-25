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
        .package(url: "https://github.com/divkit/divkit-ios", from: "32.9.0"),
        .package(url: "https://github.com/namiai/vgsl.git", revision: "3a1ce6687505ef40965930d198c0f700234bf70b")
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.0.0/NamiPairingFramework.xcframework.zip",
            checksum: "6574b205c46989e73c077b506d9b6cd3ac46b5310301654df48823d487de3720"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/4.0.0/StandardPairingUI.xcframework.zip",
            checksum: "8d923ef2615436c328409c836d6334ed2d6a80e2341f11645f8d9666a29b20e1"),
        .target(
          name: "NamiPairingCore",
          dependencies: [
            "NamiPairingFramework",
            .product(name: "DivKit", package: "divkit-ios"),
            .product(name: "DivKitSVG", package: "divkit-ios"),
            .product(name: "DivKitExtensions", package: "divkit-ios"),
            .product(name: "VGSL", package: "vgsl"),
          ],
          path: "Sources/NamiPairing/NamiPairingCore"
        ),
    ]
)
