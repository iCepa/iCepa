//
//  PermissionViewController.swift
//  iCepa
//
//  Created by Conrad Kramer on 8/26/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import UIKit
import NetworkExtension

class PermissionViewController: UIViewController {

    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .white
        
        let grantButton = FloatingButton()
        grantButton.translatesAutoresizingMaskIntoConstraints = false
        grantButton.setTitle("Grant Access", for: .normal)
        grantButton.addTarget(self, action: #selector(requestPermissions), for: .touchUpInside)
        grantButton.gradient = (UIColor(rgbaValue: 0x00CD86FF), UIColor(rgbaValue: 0x3AB52AFF))
        view.addSubview(grantButton)

        NSLayoutConstraint.activate([
            grantButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grantButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            grantButton.widthAnchor.constraint(equalToConstant: 180),
            grantButton.heightAnchor.constraint(equalToConstant: 50)
            ])
    }

    @objc private func requestPermissions() {
        NETunnelProviderManager.loadAllFromPreferences() { (managers, error) in
            if let managers = managers, managers.count > 0 {
                return NotificationCenter.default.post(name: .NEVPNConfigurationChange, object: nil)
            }
            
            let config = NETunnelProviderProtocol()
            config.providerConfiguration = ["lol": 1]
            config.providerBundleIdentifier = CPAExtensionBundleIdentifier
            config.serverAddress = "somebridge"
            
            let manager = NETunnelProviderManager()
            manager.protocolConfiguration = config
            manager.localizedDescription = "Tor"
            
            manager.saveToPreferences() { (error) -> Void in
                if let error = error as? NEVPNError, error.code == .configurationReadWriteFailed {
                    return
                }
                
                NotificationCenter.default.post(name: .NEVPNConfigurationChange, object: nil)
            }
        }
    }
}
