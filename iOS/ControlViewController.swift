//
//  ControlViewController.swift
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import UIKit
import NetworkExtension
import Tor

class ControlViewController: UIViewController {
    
    let manager: NETunnelProviderManager
    var controller: TORController
    
    weak var establishedLabel: UILabel?
    
    required init(manager: NETunnelProviderManager) {
        self.manager = manager
        
        let dataDirectory = FileManager.appGroupDirectory.appendingPathComponent("Tor")
        let controlSocket = dataDirectory.appendingPathComponent("control_port")
        self.controller = TORController(socketURL: controlSocket)
        
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: OperationQueue.main) { (note) in
            
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.white
        
        let startButton = FloatingButton()
        startButton.setTitle("Start Tor", for: UIControlState())
        startButton.addTarget(self, action: #selector(enableAndStart), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.gradient = (UIColor(rgbaValue: 0x00CD86FF), UIColor(rgbaValue: 0x3AB52AFF))
        view.addSubview(startButton)
        
        let establishedLabel = UILabel(frame: CGRect.zero)
        establishedLabel.text = "Circuit Not Established"
        establishedLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(establishedLabel)
        self.establishedLabel = establishedLabel
        
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 180),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            establishedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            NSLayoutConstraint(item: establishedLabel, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.5, constant: 0)
            ])
    }
    
    func enableAndStart() {
        let manager = self.manager
        let controller = self.controller
        
        let start: ((Void) -> Void) = {
            do {
                try manager.connection.startVPNTunnel()
            } catch let error {
                return print("Error: Could not start manager: \(error)")
            }
            
            do {
                try controller.connect()
                let dataDirectory = FileManager.appGroupDirectory.appendingPathComponent("Tor")
                let cookie = try Data(contentsOf: dataDirectory.appendingPathComponent("control_auth_cookie"), options: NSData.ReadingOptions(rawValue: 0))
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
            start()
        } else {
            manager.isEnabled = true
            manager.saveToPreferences(completionHandler: { (error) in
                if let error = error {
                    return print("Error: Could not enable manager: \(error)")
                }
                start()
            })
        }
    }
}
