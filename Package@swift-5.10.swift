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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.1.1/NamiPairingFramework.xcframework.zip",
            checksum: "6fcfa282b11482f73c89917ec7ca4d1d452a30e6c64169092d575c0975bc35fe"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.1.1/StandardPairingUI.xcframework.zip",
            checksum: "5231db3069be78d26c25266676843437d65f1060f996588022e6e0a28a66af2b"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.1.1/DeviceConnections.xcframework.zip",
            checksum: "84c7948301f975b8daa09dea6b35630ed51968f75cd38d3a2edb4c126c187867")
    ]
)
