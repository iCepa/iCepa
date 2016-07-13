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

class ViewController: UIViewController {
    
    var manager: NETunnelProviderManager?
    var controller: TORController?
    weak var establishedLabel: UILabel?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NETunnelProviderManager.loadOrCreateDefaultWithCompletionHandler { (manager, _) -> Void in
            self.manager = manager
        }
        
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: OperationQueue.main) { (note) in
            
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.white()
        
        let button = UIButton(type: .system)
        button.setTitle("Start Tor", for: UIControlState())
        button.addTarget(self, action: #selector(ViewController.buttonPressed(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        let establishedLabel = UILabel(frame: CGRect.zero)
        establishedLabel.text = "Circuit Not Established"
        establishedLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(establishedLabel)
        self.establishedLabel = establishedLabel
        
        view.addConstraint(NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: establishedLabel, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: establishedLabel, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.5, constant: 0))
    }
    
    func buttonPressed(_ sender: AnyObject?) {
        enableAndStart()
    }
    
    func enableAndStart() {
        guard let manager = manager else { return }
        let start: (NETunnelProviderManager) -> (Void) = { (manager) in
            do {
                try manager.connection.startVPNTunnel()
            } catch let error as NSError {
                return NSLog("Error: Could not start manager: %@", error)
            }
            
            guard let appGroupDirectory = FileManager.default.containerURLForSecurityApplicationGroupIdentifier(CPAAppGroupIdentifier) else { return }
            let dataDirectory = try! appGroupDirectory.appendingPathComponent("Tor")
            let controlSocket = try! dataDirectory.appendingPathComponent("control_port")
            
            let controller = TORController(socketURL: controlSocket)
            do {
                try controller.connect()
                let cookie = try Data(contentsOf: try! dataDirectory.appendingPathComponent("control_auth_cookie"), options: NSData.ReadingOptions(rawValue: 0))
                controller.authenticate(with: cookie, completion: { (success, error) -> Void in
                    if let error = error {
                        NSLog("%@: Error: Cannot authenticate with tor: %@", self, error.localizedDescription)
                        return
                    }
                    
                    controller.addObserver(forCircuitEstablished: { (established) in
                        DispatchQueue.main.async {
                            self.establishedLabel!.text = (established ? "Circuit Established" : "Circuit Not Established")
                        }
                    })
                })
            } catch let error as NSError {
                NSLog("%@: Error: Cannot connect to tor: %@", self, error.localizedDescription)
            }
        }
        
        if manager.isEnabled {
            start(manager)
        } else {
            manager.isEnabled = true
            manager.saveToPreferences(completionHandler: { (error) in
                if let error = error {
                    return NSLog("Error: Could not enable manager: %@", error)
                }
                start(manager)
            })
        }
    }
}
