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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.7/NamiPairingFramework.xcframework.zip",
            checksum: "43bd6e495572ef268abfbcde67c0e6e76163619e6b3633f62c8c3e7a717d60b1"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.7/StandardPairingUI.xcframework.zip",
            checksum: "de328dfd1d3c13ba71b924043d4b2078667aee6d79839dcea8c58fa21a7399ff"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.7/DeviceConnections.xcframework.zip",
            checksum: "3540d4212a695b2c7fb8dacaacf7f04b23744d0e3b0cd1191e0ea5e8281de8e0")
    ]
)
