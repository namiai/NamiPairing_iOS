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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.1/NamiPairingFramework.xcframework.zip",
            checksum: "07c4f3a0c72815602a00a73e6eab2824c35d607dbbede9c1230924e40def1c2c"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.1/StandardPairingUI.xcframework.zip",
            checksum: "ea7f093d14279a36e6c31fdf70d76065454396caeafccf4c92455e9a9627abfc"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.2.1/DeviceConnections.xcframework.zip",
            checksum: "92126cf9c7d572cb31e1f523f21c32226567f5b745a5a896ef618a41b4a74b12")
    ]
)
