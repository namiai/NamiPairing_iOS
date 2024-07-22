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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.1/NamiPairingFramework.xcframework.zip",
            checksum: "99798a5d7a36b208ae4d55cdab64ddf60d6e44da71c770093b41293c94186cd2"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.1/StandardPairingUI.xcframework.zip",
            checksum: "ecb01173488e1c9e5f649e0bb39678b60ce765530636fd54ee5c2dd365e3fbdc"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.1/DeviceConnections.xcframework.zip",
            checksum: "85b28dd6b31094087100dbad6f4fe90f320b2e9abb6464ac621fda94cf821375")
    ]
)
