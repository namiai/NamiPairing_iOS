# NamiPairing

The Package contains two binary targets providing a consuming app with nami pairing framework and the standard UI for it.


### Getting started

Importing target should be set to iOS version not lower than 14.0.
Please see "Alternative addition options" below if you would want to use core pairing in the targets with iOS version set to 13.1 up to 14.0.

#### Adding into iOS project
To import the package into your iOS project please go to the project tab -> 'Package Dependencies' -> '+' -> search for `git@github.com:namiai/NamiPairing_iOS.git`
or
in menu bar File -> 'Add Package Dependencies' -> search for `git@github.com:namiai/NamiPairing_iOS.git`

#### Adding into Swift Package
If you going to use NamiPairing in some other Swift Packege please add
`.package(url: "https://github.com:namiai/NamiPairing_iOS.git", from: "1.4.0")`
to package dependencies and
`.product(name: "NamiPairing", package: "NamiPairing_iOS")`
to the target dependencies of the target requiring the package import.


#### Alternative addition options
It is possible to add the `xcframework` files directly to your iOS project's target.
Please go to target -> 'General' -> 'Frameworks, Libraries and Embedded content' and add the xcframework files to the list by dragging and dropping or by hitting the '+'.
While importing the `NamiPairingFramework.xcframework` this way you lifting this package limitation to be used in targets with iOS version over 14.0 sice the particular framework is good to be used with targets set not lower then iOS 13.1.
`StandardPairingUI.xcframework` can't be used in targets with iOS version set below 14.0 so it would require you to provide an alternative UI container to `NamiPairing` initialiser and `startPairing` method.

#### Using in code
There are two targets in this package both of which you can import separately.
```
import NamiPairingFramework
import StandardPairingUI
```
