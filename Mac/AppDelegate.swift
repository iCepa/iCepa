//
//  AppDelegate.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/1/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import Cocoa
import NetworkExtension

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let start: (NETunnelProviderManager) -> (Void) = { (manager) -> Void in
            do {
                try manager.connection.startVPNTunnel()
            } catch let error as NSError {
                NSLog("Error! %@", error)
            }
        }
        
        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler { (managers, _) -> Void in
            if managers == nil || managers!.count == 0 {
                let config = NETunnelProviderProtocol()
                config.providerConfiguration = ["lol": 1]
                config.providerBundleIdentifier = CPAExtensionBundleIdentifier
                config.serverAddress = "lolserver"
                
                let manager = NETunnelProviderManager()
                manager.protocolConfiguration = config
                manager.localizedDescription = "Tor"
                manager.saveToPreferencesWithCompletionHandler { (error) -> Void in
                    if error != nil {
                        NSLog("Error! %@", error!)
                    }
                    start(manager)
                }
            } else {
                start(managers![0])
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
