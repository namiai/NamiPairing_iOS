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
            targets: ["NamiPairingCore", "StandardPairingUI"]
        ),
        .library(
            name: "NamiPairing-NoUI", 
            targets: ["NamiPairingCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Yandex/DivKit.git", from: "31.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "NamiPairingFramework", 
            path: "Sources/NamiPairing/NamiPairingFramework.xcframework"
        ),
        .binaryTarget(
            name: "StandardPairingUI", 
            path: "Sources/NamiPairing/StandardPairingUI.xcframework"
        ),
        .target(
            name: "NamiPairingCore",
            dependencies: [
                "NamiPairingFramework",
                .product(name: "DivKit", package: "DivKit")
            ],
            path: "Sources/NamiPairing/NamiPairingCore",
            publicHeadersPath: "."
        ),
    ]
)
