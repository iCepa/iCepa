//
//  AppDelegate.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/1/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import Cocoa
import NetworkExtension
import Tor

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let start: (NETunnelProviderManager) -> (Void) = { (manager) in
            do {
                try manager.connection.startVPNTunnel()
            } catch let error as NSError {
                NSLog("Error: Could not start manager: %@", error)
            }
            
            let appGroupDirectory = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(CPAAppGroupIdentifier)!
            let dataDirectory = appGroupDirectory.URLByAppendingPathComponent("Tor")
            let controlSocket = dataDirectory.URLByAppendingPathComponent("control_port")
            
            let controller = TORController(socketURL: controlSocket)
            controller.addObserverForCircuitEstablished({ (established) in
                
            })
        }
        
        NETunnelProviderManager.loadOrCreateDefaultWithCompletionHandler { (manager, _) -> Void in
            if let manager = manager {
                if manager.enabled {
                    start(manager)
                } else {
                    manager.enabled = true
                    manager.saveToPreferencesWithCompletionHandler({ (error) in
                        if let error = error {
                            NSLog("Error: Could not enable manager: %@", error)
                            return
                        }
                        start(manager)
                    })
                }
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
