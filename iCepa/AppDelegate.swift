//
//  AppDelegate.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if Config.torInApp {
            TorManager.shared.start { progress in
                NSLog("Progress: \(progress)")
            } _: { error in
                if let error = error {
                    NSLog("Tor start failed: \(error)")
                }
                else {
                    NSLog("Tor started successfully!")
                }
            }
        }

        return true
    }
}

