//
//  ViewController.swift
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        let start: (NETunnelProviderManager) -> (Void) = { (manager) -> Void in
            do {
                try manager.connection.startVPNTunnel()
            } catch let error as NSError {
                NSLog("Error! %@", error)
            }
        }
        
        let enableAndStart: (NETunnelProviderManager) -> (Void) = { (manager) -> Void in
            if manager.enabled {
                start(manager)
            } else {
                manager.enabled = true
                manager.saveToPreferencesWithCompletionHandler({ (_) -> Void in
                    start(manager)
                })
            }
        }
        NETunnelProviderManager.loadAllFromPreferencesWithCompletionHandler { (managers, _) -> Void in
            if managers == nil || managers!.count == 0 {
                let config = NETunnelProviderProtocol()
                config.providerConfiguration = ["lol": 1]
                config.providerBundleIdentifier = CPAExtensionBundleIdentifier
                config.serverAddress = "somebridge"
                
                let manager = NETunnelProviderManager()
                manager.protocolConfiguration = config
                manager.localizedDescription = "Tor"
                manager.saveToPreferencesWithCompletionHandler { (error) -> Void in
                    if error != nil {
                        NSLog("Error! %@", error!)
                    }
                    enableAndStart(manager)
                }
            } else {
                enableAndStart(managers![0])
            }
        }
    }
}
