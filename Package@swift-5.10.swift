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
        .binaryTarget(name: "NamiPairingFramework", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.6/NamiPairingFramework.xcframework.zip",
            checksum: "7cf855f644401741a9229d4f6465e6d293c7ef9ced83333f81ac8a74a593bdc6"),
        .binaryTarget(name: "StandardPairingUI", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.6/StandardPairingUI.xcframework.zip",
            checksum: "b694ccaea132a296d4bb54fe0958463d528deb6a5d4d85ca2813acd9d7e90830"),
        .binaryTarget(name: "DeviceConnections", url: "https://github.com/namiai/NamiPairing_iOS/releases/download/1.6.6/DeviceConnections.xcframework.zip",
            checksum: "14e255d12b45a3d7e94ef9f2414aa6b3dc6b6dfd3bacd66f95983d6bc7c1055e")
    ]
)
