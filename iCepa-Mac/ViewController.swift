//
//  ViewController.swift
//  iCepa-Mac
//
//  Created by Benjamin Erhart on 22.06.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    private enum Info: Int {
        case vpnLog = 0
        case torLog = 1
        case leafLog = 2
        case leafConf = 3
        case circuits = 4
    }

    @IBOutlet weak var confStatusLb: NSTextField!
    @IBOutlet weak var confBt: NSButton!
    @IBOutlet weak var errorLb: NSTextField!
    @IBOutlet weak var sessionStatusLb: NSTextField!
    @IBOutlet weak var sessionBt: NSButton!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var logTv: NSTextView!

    private static let nf: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 1

        return nf
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        let nc = NotificationCenter.default

        nc.addObserver(self, selector: #selector(updateUi), name: .vpnStatusChanged, object: nil)
        nc.addObserver(self, selector: #selector(updateUi), name: .vpnProgress, object: nil)

        clear()
        updateLog(continuous: true)
    }


    // MARK: Actions

    @IBAction func check(_ sender: Any) {
        NSWorkspace.shared.open(URL.checkTor)
    }

    @IBAction func ddgOnion(_ sender: Any) {
        NSWorkspace.shared.open(URL.ddgOnion)
    }

    @IBAction func fbOnion(_ sender: Any) {
        NSWorkspace.shared.open(URL.fbOnion)
    }

    @IBAction func neverSsl(_ sender: Any) {
        NSWorkspace.shared.open(URL.neverSsl)
    }

    @IBAction func clear(_ sender: Any? = nil) {
        if let logfile = FileManager.default.vpnLogFile {
            try? "".write(to: logfile, atomically: true, encoding: .utf8)
        }

        if let logfile = FileManager.default.torLogFile {
            try? "".write(to: logfile, atomically: true, encoding: .utf8)
        }

        if let logfile = FileManager.default.leafLogFile {
            try? "".write(to: logfile, atomically: true, encoding: .utf8)
        }

        updateUi()
    }

    @IBAction func changeConf(_ sender: Any) {
        switch VpnManager.shared.confStatus {
        case .notInstalled:
            VpnManager.shared.install()

        case .disabled:
            VpnManager.shared.enable()

        case .enabled:
            VpnManager.shared.disable()
        }
    }

    @IBAction func changeSession(_ sender: Any) {
        switch VpnManager.shared.sessionStatus {
        case .connected, .connecting:
            VpnManager.shared.disconnect()

        case .disconnected, .disconnecting:
            VpnManager.shared.connect()

        default:
            break
        }
    }

    @IBAction func switchInfo(_ sender: Any) {
        if segmentedControl.indexOfSelectedItem == Info.circuits.rawValue {
            logTv.string = ""

            let showCircuits = { [weak self] (circuits: [TorCircuit]) -> Void in
                DispatchQueue.main.async {
                    self?.logTv.string = circuits.map { $0.raw ?? "" }.joined(separator: "\n")
                }
            }

            if Config.torInApp {
                TorManager.shared.getCircuits(showCircuits)
            }
            else {
                VpnManager.shared.getCircuits { [weak self] circuits, error in
                    if let error = error {
                        self?.setError(error)
                    }

                    showCircuits(circuits)
                }
            }
        }
        else {
            updateLog()
        }
    }


    // MARK: Observers

    @objc func updateUi(_ notification: Notification? = nil) {
        confStatusLb.stringValue = String(format: NSLocalizedString("VPN Configuration: %@", comment: ""),
                                   VpnManager.shared.confStatus.description)

        switch VpnManager.shared.confStatus {
        case .notInstalled:
            confBt.title = NSLocalizedString("Install", comment: "")

        case .disabled:
            confBt.title = NSLocalizedString("Enable", comment: "")

        case .enabled:
            confBt.title = NSLocalizedString("Disable", comment: "")
        }

        setError(VpnManager.shared.error)

        var progress = ""

        if notification?.name == .vpnProgress,
            let raw = notification?.object as? Float {

            progress = ViewController.nf.string(from: NSNumber(value: raw)) ?? ""

        }

        sessionStatusLb.stringValue = String(format: NSLocalizedString("Session: %@", comment: ""),
                                      [VpnManager.shared.sessionStatus.description, progress].joined(separator: " "))

        switch VpnManager.shared.sessionStatus {
        case .connected, .connecting:
            sessionBt.title = NSLocalizedString("Disconnect", comment: "")
            sessionBt.isEnabled = true

        case .disconnected, .disconnecting:
            sessionBt.title = NSLocalizedString("Connect", comment: "")
            sessionBt.isEnabled = true

        default:
            sessionBt.isEnabled = false
        }

        updateLog()
    }

    private var running = false

    private func updateLog(continuous: Bool = false) {
        if !running {
            running = true

            if segmentedControl.indexOfSelectedItem < Info.circuits.rawValue {
                let text: String?
                let idx = segmentedControl.indexOfSelectedItem

                if idx == Info.torLog.rawValue {
                    text = FileManager.default.torLog
                }
                else if idx == Info.vpnLog.rawValue {
                    text = FileManager.default.vpnLog
                }
                else if idx == Info.leafLog.rawValue {
                    text = FileManager.default.leafLog
                }
                else {
                    text = FileManager.default.leafConf
                }

                if logTv.string != text {
                    logTv.string = text ?? ""
                    logTv.scrollToEndOfDocument(nil)
                }
            }

            running = false
        }

        if continuous {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.updateLog(continuous: true)
            }
        }
    }


    // MARK: Private Methods

    private func setError(_ error: Error?) {
        if let error = error {
            errorLb.isHidden = false
            errorLb.stringValue = String(format: NSLocalizedString("Error: %@", comment: ""),
                                  error.localizedDescription)
        }
        else {
            errorLb.isHidden = true
        }
    }
}

