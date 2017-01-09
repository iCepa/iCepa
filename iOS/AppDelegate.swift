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
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var coordinator: AppCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let coordinator = AppCoordinator(window: window)
        window.makeKeyAndVisible()

        self.window = window
        self.coordinator = coordinator
        
        return true
    }
}
