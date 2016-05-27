# iCepa

iCepa is an iOS system-wide VPN Tor client. It uses [Tor.framework](https://github.com/iCepa/Tor.framework) to manage its Tor instance, and [`tun2tor`](https://github.com/iCepa/tun2tor) to bridge VPN traffic to Tor. The project does *not* work yet, and is in progress.

## Requirements

- iOS 9.0 or later
- Xcode 7.0 or later

## Building

Because the network extension depends on [`tun2tor`](https://github.com/iCepa/tun2tor), building this application requires the Rust compiler. You can install it using [rustup](https://www.rustup.rs):


```sh
curl https://sh.rustup.rs -sSf | sh
rustup install stable
rustup target add aarch64-apple-ios
rustup target add armv7s-apple-ios
rustup target add armv7-apple-ios
```

## Installation

Installing this application on your own iOS device requires special Network Extension entitlements from Apple. Email [networkextension@apple.com](mailto:networkextension@apple.com) to request access to these entitlements.

Once you have been granted these entitlements, you are going to have to provision the app:

1. Pick a bundle identifier and generate an App ID for that bundle identifier on Apple's developer portal.
2. Append a new component to that bundle identifier to form the extension's bundle identifier, and generate an App ID for that new bundle identifier.
3. Create an App Group, and set that App Group on both of the App IDs that you just created.
4. Create two new provisioning profiles, one for each App ID, and enable the Network Extension entitlements on both.
5. Put the App Group and both App IDs in `iCepa-iOS.xcconfig`

## Contributing

iCepa is separated into two components. The UI is written in Swift, and provides a basic interface to start, stop and configure the Tor network extension. The network extension is also written in Swift, and bridges traffic to Tor using an `NEPacketTunnelProvider` and [`tun2tor`](https://github.com/iCepa/tun2tor). An `NEPacketTunnelProvider` is analogous to a `utun` (userspace network tunnel) interface. `Tor.framework` is used to communicate with and start the `tor` instance from both the app and the extension.

Things that need work:
- `tun2tor` parses packets, but does not forward them over SOCKS to tor. Reach out to @conradev if you are interested in helping with this part.
- Tor currently exceeds the 5 MB memory limit set on packet provider extensions by Apple (TODO: File radar). Until this is fixed, iCepa's extension **will crash**. If you have a jailbroken device, you can circumvent this with [`jetsamctl`](https://github.com/conradev/jetsamctl). Possible solutions include increasing the use of memory mapping in `tor`.
- The UI is neither designed nor implemented. It will be one screen with very simple controls. Taking mockups/pull requests for either! Create Github issues for now.
- There is no icon or any branding (the name is not even final).
