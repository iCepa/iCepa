//
//  AppDelegate.swift
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import UIKit
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, URLSessionTaskDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main().bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
