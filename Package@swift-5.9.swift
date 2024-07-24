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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.5/NamiPairingFramework.xcframework.zip",
            checksum: "57222f8d9ab8ffff1259d94b85f4287a30e4eae9e245824416c1a276456d93bd"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.5/StandardPairingUI.xcframework.zip",
            checksum: "f69fd98d3a483fa9135ccc87308076d0d5472678c7a6bf8a56af812fc3767943"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.5/DeviceConnections.xcframework.zip",
            checksum: "a4d5c39993fedb2d6dc3ce02c9e78c6002cd78d466ca437ea8b83941db8e2409")
    ]
)
