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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.5/NamiPairingFramework.xcframework.zip",
            checksum: "fee8744ce3d3f5792756f2dbe1342d72e894bab0d46cdb4f069addb712176aba"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.5/StandardPairingUI.xcframework.zip",
            checksum: "4a465f15a1050276e2474ef09ff021d50b1d81068a21aaa704ce760c1f2b0f2c"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.5/DeviceConnections.xcframework.zip",
            checksum: "5511e18fb7aa9aedd404526dcc299338328b1c982b4f35048878af16aea17df2")
    ]
)
