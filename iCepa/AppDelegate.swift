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

    private var backgroundTaskId = UIBackgroundTaskIdentifier.invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if Config.torInApp {
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleTor), name: .vpnStatusChanged, object: nil)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if Config.torInApp {
            let app = UIApplication.shared

            // Delay stop of our app as long as possible to keep Tor running.

            backgroundTaskId = app.beginBackgroundTask(expirationHandler: endHandler)

            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + app.backgroundTimeRemaining - 10) {
                if self.backgroundTaskId != .invalid {
                    TorManager.shared.stop()
                }

                self.endHandler()
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        endHandler()
    }

    private func endHandler() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }

    @objc
    private func handleTor(_ notification: Notification? = nil) {
        switch VpnManager.shared.sessionStatus {
        case .connected:
            if Config.useObfs4 {
                #if DEBUG
                let ennableLogging = true
                #else
                let ennableLogging = false
                #endif

                IPtProxyStartObfs4Proxy(
                    "DEBUG", ennableLogging, true,
                    "socks5://\(TorManager.localhost):\(TorManager.leafProxyPort)")

                TorManager.obfs4ProxyPort = IPtProxyObfs4Port()
            }

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

        case .disconnecting:
            TorManager.shared.stop()

            if Config.useObfs4 {
                IPtProxyStopObfs4Proxy()
            }

        default:
            break
        }
    }
}
