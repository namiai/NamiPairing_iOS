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
            targets: ["NamiPairingFramework", "StandardPairingUI"]),
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.4/NamiPairingFramework.xcframework.zip",
            checksum: "070c446d5f6736e0f7803221854d6f01318ef468a8753249f49cc3e7a546b6a5"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.4/StandardPairingUI.xcframework.zip",
            checksum: "3a977a1369c64f42b2236c691c18d0ef47895fb4d066abc7b1fc9a1adb501461"),
    ]
)
