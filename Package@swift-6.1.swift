// swift-tools-version: 6.1
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
            targets: ["NamiPairingCore", "StandardPairingUI", "NamiPairingResources"]),
        .library(
            name: "NamiPairing-NoUI", 
            targets: ["NamiPairingCore", "NamiPairingResources"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", .upToNextMajor(from: "4.4.3")),
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", path: "Sources/NamiPairing/NamiPairingFramework.xcframework"),
        .binaryTarget(name: "StandardPairingUI", path: "Sources/NamiPairing/StandardPairingUI.xcframework"),
        .target(
          name: "NamiPairingCore",
          dependencies: [
            "NamiPairingFramework",
            .product(name: "Lottie", package: "lottie-spm"),
          ],
          path: "Sources/NamiPairing/NamiPairingCore"
        ),
        .target(
          name: "NamiPairingResources",
          path: "Sources/NamiPairing/NamiPairingResources",
          resources: [
            .copy("Resources/I18n_I18n.bundle"),
            .copy("Resources/SharedAssets_SharedAssets.bundle"),
            .copy("Resources/CommonTypes_CommonTypes.bundle"),
            .copy("Resources/NamiSharedUIElements_NamiSharedUIElements.bundle")
          ]
        ),
    ]
)
