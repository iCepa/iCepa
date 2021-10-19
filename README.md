#  iCepa Restart

This is a completely fresh implementation of the iCepa app.

It is a testbed for [Network Extension](https://developer.apple.com/documentation/networkextension)
experiments for advanced VPN-style apps.

It was originally developed for use with Tor by Conrad Kramer, hence the name 
("Cepa" means onion in Latin), but can be used as a base for all other sorts of proxies now and 
also with [Pluggable Transports](https://www.pluggabletransports.info).

## Features

- Container app for installing and controlling the Network Extension and displaying log output 
  for easier debugging.
- App Group storage to share files between the app and the extension.
- iOS and MacOS implementation.
- Basic messaging implementation to show how to communicate between app and extension.
- Easy build configuration via xcconfig file.
- Clean encapsulation of NE code in `VpnManager` and `BasePTProvider` classes.
- Clean implementation of a `TorManager` to show usage of `Tor.framework`.
- `Tor.framework` integrated as a git submodule for easy debugging.
- Proxy can be run in extension **and in app** and easily switched.
- Glue code for different tun2socks implementations to try out.

## Different tun2socks implementations

Since a lot of existing proxy code can't handle IP packets directly (like Tor), a big part of the
experiment is/was trying out different projects which go in between. Code for these is kept
around for demonstration purposes, but is disabled, except the last (called leaf), which currently
seems to be the best option.

The following libraries were tried and might be of interest to you:

- [OBTun2Socks](https://github.com/tladesignz/OBTun2Socks)
  A stab at packaging a C tun2socks implementation in a CocoaPod.
  
-  [GoTun2Socks](https://github.com/eycorsican/go-tun2socks)
  A Go implementation of tun2socks. Discontinued.
  
- [outline-go-tun2socks](https://github.com/Jigsaw-Code/outline-go-tun2socks)
  A Go tun2socks implementation by the Outline project.
  
- [tun2tor](https://github.com/iCepa/tun2tor)
  A Rust implementation of tun2socks specifically written for Tor with support for its DNS resolution.
  (slightly updated to fix compilation issues, but still outdated and discontinued)
  
- [leaf](https://github.com/eycorsican/leaf.git)
  A flexible proxy framework written in Rust with support for SOCKS, HTTP CONNECT,
  ShadowSocks and many more with highly configurable routing options. 

## Getting started

```sh
git clone --recursive git@github.com:iCepa/iCepa.git
cd iCepa
pod install # or `update`
open iCepa.xcworkspace
```

Network Extensions can only be run on a real device.
You will also need a paid Apple Developer subscription to be able to manually create the 
development certificates needed.

Don't edit `project.pbxproj` (the project configuration) directly, instead use  `Config.xcconfig`, 
where all signing-related info is kept out of the way.

You will need to create 3 identifiers here:
https://developer.apple.com/account/resources/identifiers/list

- A group identifier.
- An app bundle identifier for the app itself.
- An app bundle identifier used for the Network Extension.

Both app IDs need the capabilities "App Groups" and "Network Extensions".
Add the created group ID to the "App Groups" capability.

Put these IDs in the respective fields in `Config.xcconfig`.

The devloper team ID can be found on the aforementioned page in the top right.

Create 2 iOS development profiles here for the app and the extension:
https://developer.apple.com/account/resources/profiles/list

Put their "names" as their specifiers in `Config.xcconfig`.

In Xcode, go to "Preferences" -> "Accounts" -> select your Apple ID -> "Download Manual Profiles"

Now, you should be able to compile and run on a real device.


## Author, License

Benjamin Erhart, [Die Netzarchitekten e.U.](https://die.netzarchitekten.com)

Under the authority of [Guardian Project](https://guardianproject.info).

Licensed under [MIT](LICENSE.txt)


## Icon

Icon taken from

https://thenounproject.com/term/onion/35969/

By Brennan Novak, Public Domain
