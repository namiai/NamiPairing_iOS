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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.1/NamiPairingFramework.xcframework.zip",
            checksum: "c0c3e989fd34fe99b7c870c1116d0163719b681180c99565381c44fb7dbcc7b2"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.1/StandardPairingUI.xcframework.zip",
            checksum: "97967da327e782f7779d9505f472b43ba73c5dc7d7c74b5c98147e3f9611df91"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.1/DeviceConnections.xcframework.zip",
            checksum: "10597ac0946b69aebad74d85065c35b5936e0ff5e5a9600592d5b708d10e0c4b")
    ]
)
