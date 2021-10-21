//
//  ViewController.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private enum Info: Int {
        case vpnLog = 0
        case torLog = 1
        case leafLog = 2
        case leafConf = 3
        case circuits = 4
    }

    @IBOutlet weak var confStatusLb: UILabel!
    @IBOutlet weak var confBt: UIButton!
    @IBOutlet weak var transportSc: UISegmentedControl!
    @IBOutlet weak var errorLb: UILabel!
    @IBOutlet weak var sessionStatusLb: UILabel!
    @IBOutlet weak var sessionBt: UIButton!
    @IBOutlet weak var logSc: UISegmentedControl!
    @IBOutlet weak var logTv: UITextView!
    
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

    @IBAction func clear() {
        if let logfile = FileManager.default.vpnLogFile {
            try? "".write(to: logfile, atomically: false, encoding: .utf8)
        }

        if let logfile = FileManager.default.torLogFile {
            try? "".write(to: logfile, atomically: false, encoding: .utf8)
        }

        if let logfile = FileManager.default.leafLogFile {
            try? "".write(to: logfile, atomically: false, encoding: .utf8)
        }

        updateUi()
    }

    @IBAction func changeConf() {
        switch VpnManager.shared.confStatus {
        case .notInstalled:
            VpnManager.shared.install()

        case .disabled:
            VpnManager.shared.enable()

        case .enabled:
            VpnManager.shared.disable()
        }
    }

    @IBAction func changeTransport() {
        VpnManager.shared.switch(to: .init(rawValue: transportSc.selectedSegmentIndex) ?? .direct)
    }

    @IBAction func changeSession() {
        switch VpnManager.shared.sessionStatus {
        case .connected, .connecting:
            VpnManager.shared.disconnect()

        case .disconnected, .disconnecting:
            VpnManager.shared.connect()

        default:
            break
        }
    }

    @IBAction func switchInfo() {
        if logSc.selectedSegmentIndex == Info.circuits.rawValue {
            logTv.text = ""

            let showCircuits = { [weak self] (circuits: [TorCircuit]) -> Void in
                DispatchQueue.main.async {
                    self?.logTv.text = circuits.map { $0.raw ?? "" }.joined(separator: "\n")
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
        confStatusLb.text = String(format: NSLocalizedString("VPN Configuration: %@", comment: ""),
                                   VpnManager.shared.confStatus.description)

        switch VpnManager.shared.confStatus {
        case .notInstalled:
            confBt.setTitle(NSLocalizedString("Install", comment: ""))

        case .disabled:
            confBt.setTitle(NSLocalizedString("Enable", comment: ""))

        case .enabled:
            confBt.setTitle(NSLocalizedString("Disable", comment: ""))
        }

        transportSc.selectedSegmentIndex = VpnManager.shared.transport.rawValue

        var progress = ""

        if notification?.name == .vpnProgress,
            let raw = notification?.object as? Float {

            progress = ViewController.nf.string(from: NSNumber(value: raw)) ?? ""

        }

        sessionStatusLb.text = String(format: NSLocalizedString("Session: %@", comment: ""),
                                      [VpnManager.shared.sessionStatus.description, progress].joined(separator: " "))

        switch VpnManager.shared.sessionStatus {
        case .connected, .connecting:
            transportSc.isEnabled = false
            sessionBt.setTitle(NSLocalizedString("Disconnect", comment: ""))
            sessionBt.isEnabled = true

        case .disconnected, .disconnecting:
            transportSc.isEnabled = true
            sessionBt.setTitle(NSLocalizedString("Connect", comment: ""))
            sessionBt.isEnabled = true

        default:
            transportSc.isEnabled = false
            sessionBt.isEnabled = false
        }

        setError(VpnManager.shared.error)

        updateLog()
    }

    private var running = false

    private func updateLog(continuous: Bool = false) {
        if !running {
            running = true

            if logSc.selectedSegmentIndex < Info.circuits.rawValue {
                let text: String?
                let idx = logSc.selectedSegmentIndex

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

                if logTv.text != text {
                    logTv.text = text
                    logTv.scrollToBottom()
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
            errorLb.text = String(format: NSLocalizedString("Error: %@", comment: ""),
                                  error.localizedDescription)
        }
        else {
            errorLb.isHidden = true
        }
    }
}

