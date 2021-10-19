//
//  AppDelegate.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import NetworkExtension
import IPtProxy

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
            // Snowflake doesn't support a proxy behind itself, so we can
            // only run that in the extension, not here in the app.
            // So it's either direct or Obfs4.
            var transport = NETunnelProviderProtocol.Transport.direct
            var port: Int? = nil

            if VpnManager.shared.transport == .obfs4 {
                #if DEBUG
                let ennableLogging = true
                #else
                let ennableLogging = false
                #endif

                IPtProxyStartObfs4Proxy(
                    "DEBUG", ennableLogging, true,
                    "socks5://\(TorManager.localhost):\(TorManager.leafProxyPort)")

                transport = .obfs4
                port = IPtProxyObfs4Port()
            }

            TorManager.shared.start(transport, port) { progress in
                print("Progress: \(progress)")
            } _: { error in
                if let error = error {
                    print("Tor start failed: \(error)")
                }
                else {
                    print("Tor started successfully!")
                }
            }

        case .disconnecting:
            TorManager.shared.stop()

            if VpnManager.shared.transport == .obfs4 {
                IPtProxyStopObfs4Proxy()
            }

        default:
            break
        }
    }
}
