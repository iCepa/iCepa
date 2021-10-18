//
//  AppDelegate.swift
//  iCepa-Mac
//
//  Created by Benjamin Erhart on 22.06.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if Config.torInApp {
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleTor), name: .vpnStatusChanged, object: nil)
        }

        print("Group Folder: \(FileManager.default.groupFolder?.path ?? "nil")")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if Config.torInApp {
            TorManager.shared.stop()
        }
    }

    @objc
    private func handleTor(_ notification: Notification? = nil) {
        switch VpnManager.shared.sessionStatus {
        case .connected:
            TorManager.shared.start(.direct, nil) { progress in
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

        default:
            break
        }
    }
}
