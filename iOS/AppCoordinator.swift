//
//  AppCoordinator.swift
//  iCepa
//
//  Created by Conrad Kramer on 11/10/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import UIKit
import NetworkExtension

class AppCoordinator {
    
    private let window: UIWindow
    
    private let launchViewController: UIViewController = {
        let bundle = Bundle.main
        let storyboardName = bundle.object(forInfoDictionaryKey: "UILaunchStoryboardName") as! String
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        return storyboard.instantiateInitialViewController()!
    }()
    
    private let permissionViewController = PermissionViewController()
    
    private var controlViewController: ControlViewController?
    
    private var currentViewController: UIViewController? {
        didSet {
            let launchViewController = self.launchViewController
            
            if let toViewController = self.currentViewController {
                launchViewController.addChildViewController(toViewController)
                toViewController.view.frame = launchViewController.view.bounds
                toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            if let fromViewController = oldValue {
                fromViewController.willMove(toParentViewController: nil)
            }
            if let toViewController = self.currentViewController, let fromViewController = oldValue {
                UIView.transition(from: fromViewController.view, to: toViewController.view, duration: 0.25, options: .transitionCrossDissolve, completion: { (_) in
                    fromViewController.removeFromParentViewController()
                    toViewController.didMove(toParentViewController: launchViewController)
                })
            } else if let toViewController = self.currentViewController {
                launchViewController.view.addSubview(toViewController.view)
                toViewController.didMove(toParentViewController: launchViewController)
            } else if let fromViewController = oldValue {
                fromViewController.view.removeFromSuperview()
                fromViewController.removeFromParentViewController()
            }
        }
    }
    
    required init(window: UIWindow) {
        self.window = window
        
        window.rootViewController = launchViewController
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentViewController), name: .NEVPNConfigurationChange, object: nil)
        updateCurrentViewController()
    }
    
    @objc private func updateCurrentViewController() {
        NETunnelProviderManager.loadAllFromPreferences() { (managers, error) -> Void in
            if let managers = managers, managers.count > 0 {
                self.controlViewController = ControlViewController(manager: managers[0])
                self.currentViewController = self.controlViewController
            } else {
                self.currentViewController = self.permissionViewController
            }
        }
    }
}
