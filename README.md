# iCepa

[![Travis CI](https://img.shields.io/travis/iCepa/iCepa.svg)](https://travis-ci.org/iCepa/iCepa)

[`tun2tor`]: https://github.com/iCepa/tun2tor
[`Tor.framework`]: https://github.com/iCepa/Tor.framework
[rustup]: https://www.rustup.rs
[Homebrew]: https://brew.sh
[Carthage]: https://github.com/Carthage/Carthage

iCepa is an iOS system-wide VPN [Tor](https://www.torproject.org) client. It uses [`Tor.framework`]
to manage its Tor instance, and [`tun2tor`] to bridge VPN traffic to Tor.

The project is in progress, and currently alpha-quality.

## Requirements

- iOS 10 or later
- Xcode 8 or later
- Rust
- [Carthage]
- [Homebrew] or MacPorts (optional but no fun without)


- An iOS device (Simulator *will not* work, due to lack of support of Network Extensions!)
- A paid Apple Developer account (The free account is not enough for the Network Extension!)


## Prepare signing

- You need to pick 3 *unique* identifiers. (as in: unique in the whole App Store!)
    Follow the pattern as per the examples:

    1. A bundle ID (`com.example.iCepa`)
    2. An extension bundle ID (`com.example.iCepa.extension`)
    3. A group ID (`group.com.example.iCepa`)

- *Before* ever touching the project configuration, update `Shared/iCepa-iOS.xcconfig` with these. 
    Xcode will mess up your configuration, otherwise.

- Automatic signing *will not work*, instead it requires some manual set up in Apple's 
    [developer portal](https://developer.apple.com/account/ios/identifier/bundle):

    1. Use your unique bundle ID (`com.example.iCepa`) and generate an `App ID` for it.
    2. Use your unique extension bundle ID (`com.example.iCepa.extension`), and generate an 
        `App ID` for that, too.
    3. Create an `App Group` (`group.com.example.iCepa`), and enable that `App Group` on both of the 
        `App ID`s that you just created.
    4. Check the `Network Extensions` checkbox on both of the `App ID`s.
    5. Create two new development `Provisioning Profiles`, one for each `App ID`.

- Load the provisioning profiles into Xcode using Xcode -> Preferences -> Accounts ->
[Your Apple-ID] -> Download All Profiles


## Building

1. Acquire both dependencies using Git:

    ```sh
    git submodule update --init --recursive
    ```

2. Because the network extension depends on [`tun2tor`], you will need Rust installed. 
    You can install it using [rustup]:

    ```sh
    curl https://sh.rustup.rs -sSf | sh
    ```

    or using [Homebrew]:

    ```sh
    brew install rustup-init
    rustup-init
    ```

    then, in both cases:

    ```sh
    rustup install stable
    rustup target add aarch64-apple-ios
    rustup target add armv7-apple-ios
    ```

    If set up correctly [`tun2tor`] will be built during Xcode's app build. 
    (There's a script `tun2tor.sh` contained doing that, which is hooked into the Xcode build process.)

    Since you will need the cross-compilation features of Rust, don't bother trying to install Rust 
    directly from [Homebrew]: You won't be able to install additional architecture targets.

2. iCepa also depends on [`Tor.framework`], which you have to build once using [Carthage]:

    ```sh
    brew install automake autoconf libtool gettext carthage
    carthage build --platform iOS
    ```

3. iCepa should now build normally from Xcode. 
    If it does not, please [file an issue](https://github.com/iCepa/iCepa/issues/new)!
    iCepa does not work in the iOS Simulator.


## Contributing

iCepa is separated into two components:

- The UI is written in Swift, and provides a basic interface to start, stop and configure the Tor network extension.
- The network extension itself is also written in Swift, and bridges traffic to Tor using an `NEPacketTunnelProvider` and [`tun2tor`].
    An `NEPacketTunnelProvider` is analogous to a `utun` (userspace network tunnel) interface.

[`Tor.framework`] is used to communicate with and start the `tor` instance from both the app and the extension.

### Things that need work:
- [`tun2tor`].
- The UI. The main focus is the control screen which will have controls to start/stop and information about the connection.
    Taking mockups/pull requests for either! Create Github issues for now.
- There is no icon or any branding (the name is not even final).
