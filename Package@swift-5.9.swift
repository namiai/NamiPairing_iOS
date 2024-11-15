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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.0/NamiPairingFramework.xcframework.zip",
            checksum: "27f91c61a05781cb7229f1b319de3e9a3f63a7d0233d36839d5ca778d8b1fcca"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.0/StandardPairingUI.xcframework.zip",
            checksum: "b0523d522037ae5de2f62d47c810b81ab0d8c2345e2f00b93270013f99d7de30"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.0/DeviceConnections.xcframework.zip",
            checksum: "15a4e8f32e14611b21ee870a96445c070c0e761eb6ef357baa32ee0314697130")
    ]
)
