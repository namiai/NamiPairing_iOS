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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.0/NamiPairingFramework.xcframework.zip",
            checksum: "9bcbc31e0706bace7ebcbffbbac2f51f7144187adbb7b69510ec63a2fd8a2e36"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.0/StandardPairingUI.xcframework.zip",
            checksum: "7a7285b4b8abbee13ac0063bcecc74df0c0ebf61211502a4e27ff776a7fd9981"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/2.0.0/DeviceConnections.xcframework.zip",
            checksum: "fb4035c71f2729a98eca8085d43d4da1285e909fee7a39c5309d5d065f6cbadc")
    ]
)
