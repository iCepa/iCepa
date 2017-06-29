Notes for getting this thing to really build
============================================

- Install Rust with rustup! Nothing else will get the cross compilation to work as easily.
  You can install Rustup also via brew instead of CURL:

  ```sh
  brew install rustup-init
  rustup-init
  rustup install stable
  rustup target add aarch64-apple-ios
  rustup target add armv7-apple-ios
  ```

- tun2tor needs to be fetched as a Git submodule, also, therefore make sure to call

  ```sh
  git submodule update --init --recursive
  brew install automake autoconf libtool gettext carthage
  carthage build --platform iOS
  ```

  not just (as I did the first time)

  ```sh
  carthage update --platform iOS --use-submodules
  ```

- Currently [`iCepa/tun2tor`](https://github.com/iCepa/tun2tor) doesn't build because of an issue
  with a dependency configuration. This version of iCepa therefore has a cloned repository as a 
  submodule dependency: [`tladesignz/tun2tor`](https://github.com/tladesignz/tun2tor).


- Signing:
  - Automatic signing *will not work*!
  - Do the configuration as described here: https://developer.apple.com/account/ios/certificate/?teamId=W36S8KLY7S
  - Then, load the provisioning profiles into Xcode using Xcode -> Preferences -> Accounts ->
    <Your Apple-ID> -> Download All Profiles


- Before ever touching the project configuration to select the provisioning profiles, adapt the 
  content of `iCepa-iOS.xcconfig`. Otherwise, Xcode will mess up your configuration, and you will
  have to fix it manually. (Keep an eye on the "Capabilities" tab!)


## Necessary Changes

- in `tun2tor`, `Cargo.toml`, line 16, from

  ```
  nix = { git = "https://github.com/nix-rust/nix.git" }
  ```

  to

  ```
  nix = "0.8.1"
  ```

- in `iCepa`, `Extension/PacketTunnelProvider.swift`, line 57, from

  ```swift
  let ipv4Settings = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
  ```

  to

  ```swift
  let ipv4Settings = NEIPv4Settings(addresses: ["172.30.20.2"], subnetMasks: ["255.255.255.0"])
  ```

  Otherwise, `tun2tor` cannot be connected, probably because of the wrong subnet. As per the 
  `tun2tor` documentation:

  > `tun2tor` is currently hardcoded in [`main.rs`](https://github.com/iCepa/tun2tor/blob/master/src/main.rs) 
  > to create an interface with an IP address of `172.30.20.1`

- in `iCepa`, `iOS/ControlViewController.swift`, line 90 + 94, from

  ```swift
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
  ```

  to

  ```swift
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
  ```

  Otherwise, you will end up with a "Cannot connect to tor:..." error. 0.1 seconds is far from enough
  time for the Tor thread to come up.


## Additional Notes

- The extension process can be debugged in Xcode with Debug -> Attach to Process -> Likely Targets
  -> iCepaTunnel - in theory, at least. I could not manage to get debug output on the console by 
  putting `print` and `NSLog` statements in `Extension/PacketTunnelProvider.swift`.

- In Safari: go to https://check.torproject.org, to check, if the Tor tunnel is finally working.

- The tunnel seems to come up more often in a working state, when you start it, using the Settings 
  app instead of the iCepa app: 
  General -> VPN -> Toggle the "Status" button and wait until it shows "Connected".
