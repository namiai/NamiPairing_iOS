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
            targets: ["NamiPairingFramework", "StandardPairingUI", "DeviceConnections"]),
        .library(
            name: "NamiPairing-NoUI", 
            targets: ["NamiPairingFramework", "DeviceConnections"])
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.0/NamiPairingFramework.xcframework.zip",
            checksum: "9da54f253099fb073455a65a321780d8a2a30cfab26b3128ef5092c4de2271ed"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.0/StandardPairingUI.xcframework.zip",
            checksum: "81ec6279b639461bb24ac39b4dc96913e9f5940d7d17f5a01f2adb7282ab3609"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.0/DeviceConnections.xcframework.zip",
            checksum: "183bf778dab535cb56ba269b4dbfaeb74b8d9e542dd7adfeb3af21ec4ce070e4")
    ]
)
