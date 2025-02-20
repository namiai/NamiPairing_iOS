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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/3.0.0/NamiPairingFramework.xcframework.zip",
            checksum: "f6f64aa375266095cbaf2f3efbbb5896601643ec22c3979d7e87ee80be67f3fd"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/3.0.0/StandardPairingUI.xcframework.zip",
            checksum: "c41e7f97aaa748764daa9ea80f8db7255bfca2887250955cf1f024de944b5513"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/3.0.0/DeviceConnections.xcframework.zip",
            checksum: "363cb6e0bd27ed4889a9cc047433391077f261a181f6ad37ad5b12418214ea17")
    ]
)
