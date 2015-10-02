# iCepa

iCepa is an iOS system-wide VPN Tor client. It uses [Tor.framework](https://github.com/iCepa/Tor.framework) to manage its Tor instance, and [tun2tor](https://github.com/iCepa/tun2tor) to bridge VPN traffic to Tor. The project does *not* work yet, and is in progress.

## Requirements

- iOS 8.0 or later
- Xcode 7.0 or later

## Installation

Installing this application on your own iOS device requires special Network Extension entitlements from Apple. Email [networkextension@apple.com](mailto:networkextension@apple.com) to request access to these entitlements.

Once you have been granted these entitlements, you are going to have to provision the app:

1. Pick a bundle identifier and generate an App ID for that bundle identifier on Apple's developer portal.
2. Append a new component to that bundle identifier to form the extension's bundle identifier, and generate an App ID for that new bundle identifier.
3. Create an App Group, and set that App Group on both of the App IDs that you just created.
4. Create two new provisioning profiles, one for each App ID, and enable the Network Extension entitlements on both.
5. Put the App Group and both App IDs in `iCepa-iOS.xcconfig`

## Contributing

iCepa is separated into two components. The UI is written in Swift, and provides a basic interface to start, stop and configure the Tor network extension. The extension is written in Objective-C (but might be converted to Swift), and bridges traffic to Tor using an `NEPacketTunnelProvider`. Right now, none of it works!
