//
//  ViewController.swift
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import UIKit
import NetworkExtension
import Tor

extension NETunnelProviderManager {
    class func loadOrCreateDefaultWithCompletionHandler(completionHandler: ((NETunnelProviderManager?, NSError?) -> Void)?) {
        self.loadAllFromPreferencesWithCompletionHandler { (managers, error) -> Void in
            if let error = error {
                NSLog("Error: Could not load managers: %@", error)
                if let completionHandler = completionHandler {
                    completionHandler(nil, error)
                }
                return
            }
            
            if let managers = managers {
                if managers.indices ~= 0 {
                    if let completionHandler = completionHandler {
                        completionHandler(managers[0], nil)
                    }
                    return
                }
            }
            
            let config = NETunnelProviderProtocol()
            config.providerConfiguration = ["lol": 1]
            config.providerBundleIdentifier = CPAExtensionBundleIdentifier
            config.serverAddress = "somebridge"
            
            let manager = NETunnelProviderManager()
            manager.protocolConfiguration = config
            manager.localizedDescription = "Tor"
            manager.saveToPreferencesWithCompletionHandler({ (error) -> Void in
                if let completionHandler = completionHandler {
                    if let error = error {
                        NSLog("Error: Could not create manager: %@", error)
                    }
                    completionHandler(manager, error)
                }
            })
        }
    }
}

class ViewController: UIViewController {
    
    var manager: NETunnelProviderManager?
    var controller: TORController?
    weak var establishedLabel: UILabel?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NETunnelProviderManager.loadOrCreateDefaultWithCompletionHandler { (manager, _) -> Void in
            self.manager = manager
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.whiteColor()
        
        let button = UIButton(type: .System)
        button.setTitle("Start Tor", forState: .Normal)
        button.addTarget(self, action: "buttonPressed:", forControlEvents: .TouchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        let establishedLabel = UILabel(frame: CGRectZero)
        establishedLabel.text = "Circuit Not Established"
        establishedLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(establishedLabel)
        self.establishedLabel = establishedLabel
        
        view.addConstraint(NSLayoutConstraint(item: button, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: button, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: establishedLabel, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: establishedLabel, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 0.5, constant: 0))
    }
    
    func buttonPressed(sender: AnyObject?) {
        enableAndStart()
    }
    
    func enableAndStart() {
        if self.manager == nil {
            return
        }
        
        let manager = self.manager!
        
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
                self.establishedLabel!.text = (established ? "Circuit Established" : "Circuit Not Established")
            })
        }
        
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
