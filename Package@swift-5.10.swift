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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.6/NamiPairingFramework.xcframework.zip",
            checksum: "449b023a5423099e06dfc71144cb5713c68d7b3e2e150438d0f767411ae89b4f"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.6/StandardPairingUI.xcframework.zip",
            checksum: "4b29133fd8a989b3a8e25f8c04e63c1f3e98aa0826c453cc8c6157bffc69cbc9"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.7.6/DeviceConnections.xcframework.zip",
            checksum: "1a849e5ed1796411d36ef750c65307595f8e6f31702dadddc744fa2a9ae4a785")
    ]
)
