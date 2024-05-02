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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.4/NamiPairingFramework.xcframework.zip",
            checksum: "d8e39059edb64be1307c7c39ff84c779901bb3f88f7ee5a91a982f8db2174534"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.4/StandardPairingUI.xcframework.zip",
            checksum: "6e1ed10697876087ea68bc504232ea3e02e80b8468f1269ce3489bea2d087077"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.4/DeviceConnections.xcframework.zip",
            checksum: "ca40d7514b88dca6ac0513f31fae5ba41376641908d9bbda70e2e35dc2fc8e4f")
    ]
)
