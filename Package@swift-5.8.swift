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
            targets: ["NamiPairingFramework", "StandardPairingUI", "DeviceConnections"]),
        .library(
            name: "NamiPairing-NoUI", 
            targets: ["NamiPairingFramework", "DeviceConnections"])
    ],
    targets: [
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.2/NamiPairingFramework.xcframework.zip",
            checksum: "36805b9ff7ce1a19524d2419a4604149717f13b9cf7896fa9fec3b9412b55df4"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.2/StandardPairingUI.xcframework.zip",
            checksum: "0adb1857975b565da6bbcf63a8909ae186507ee6e633f5cbaad160b65e137fe5"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.2/DeviceConnections.xcframework.zip",
            checksum: "a1f6e9b4205aaebc58db80b6b57a408f1ee58db006068b47c230a3802ac619bc")
    ]
)
