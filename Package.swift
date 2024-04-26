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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.2/NamiPairingFramework.xcframework.zip",
            checksum: "8b1c1008b590c80b10518e94083f37c951f8dbadb744c4340ec4a5e673f114b7"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.2/StandardPairingUI.xcframework.zip",
            checksum: "8b9b83991249a1e5f6197cfbc82d72f9fc86f09f41ac0d2a64db8247ae146429"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.2/DeviceConnections.xcframework.zip",
            checksum: "5c79d5035587d784157a3e5c85126be406107bdf1a87b68ae1bd5f1bfbb569ce")
    ]
)
