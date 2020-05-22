#  iCepa Restart

This is a completely fresh implementation of the iCepa app.

It's still an experiment and doesn't work, yet.

It uses 2 dependencies:

- Tor.framework, which is directly integrated into the workspace, to ease debugging.
- OBTun2Socks, which is fetched via CocoaPods.

## Getting started

```sh
git clone git@github.com:tladesignz/iCepa.git
cd iCepa
git checkout restart
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
