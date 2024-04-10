# NamiPairing

The package contains two binary targets that provide a consuming app with the Nami Pairing framework and its standard UI.

## Getting Started

The importing target should be set to an iOS version not lower than 14.0. Please refer to the "Alternative Addition Options" below if you intend to use the core pairing in targets with an iOS version set between 13.1 and 14.0.

### Adding to iOS Project

To import the package into your iOS project, navigate to the project tab -> 'Package Dependencies' -> '+' -> search for `git@github.com:namiai/NamiPairing_iOS.git` or, in the menu bar, go to File -> 'Add Package Dependencies' -> search for `git@github.com:namiai/NamiPairing_iOS.git`.

### Adding to Swift Package

If you are using NamiPairing in another Swift Package, add the following lines to your package dependencies:

```swift
.package(url: "https://github.com/namiai/NamiPairing_iOS.git", from: "1.4.0")
```

Also, add the following line to the target dependencies of the target requiring the package import:

```swift
.product(name: "NamiPairing", package: "NamiPairing_iOS")
```

### Alternative Addition Options

This framework embeds 2 xcframeworks: `NamiPairingFramework.xcframework` and `StandardPairingUI.xcframework`. `StandardPairingUI.xcframework` can't be used in targets with an iOS version set below 14.0.  
If you intend to replace the commissioning UI and only need the core pairing framework (`NamiPairingFramework.xcframework`), you can include it directly into the Xcode project and keep the iOS target at 13.1. Navigate to the target -> 'General' -> 'Frameworks, Libraries and Embedded Content,' and add the xcframework files to the list by dragging and dropping or by clicking the '+' button.

### Using in Code

There are two targets in this package, both of which you can import separately:

```swift
import NamiPairingFramework
import StandardPairingUI
```
