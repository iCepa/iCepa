//
//  ViewController.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var confStatusLb: UILabel!
    @IBOutlet weak var confBt: UIButton!
    @IBOutlet weak var errorLb: UILabel!
    @IBOutlet weak var sessionStatusLb: UILabel!
    @IBOutlet weak var sessionBt: UIButton!

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

        updateUi()
    }


    // MARK: Actions

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

        if let error = VpnManager.shared.error {
            errorLb.isHidden = false
            errorLb.text = String(format: NSLocalizedString("Error: %@", comment: ""),
                                  error.localizedDescription)
        }
        else {
            errorLb.isHidden = true
        }

        var progress = ""

        if notification?.name == .vpnProgress,
            let raw = notification?.object as? Float {

            progress = ViewController.nf.string(from: NSNumber(value: raw)) ?? ""

        }

        sessionStatusLb.text = String(format: NSLocalizedString("Session: %@", comment: ""),
                                      [VpnManager.shared.sessionStatus.description, progress].joined(separator: " "))

        switch VpnManager.shared.sessionStatus {
        case .connected, .connecting:
            sessionBt.setTitle(NSLocalizedString("Disconnect", comment: ""))
            sessionBt.isEnabled = true

        case .disconnected, .disconnecting:
            sessionBt.setTitle(NSLocalizedString("Connect", comment: ""))
            sessionBt.isEnabled = true

        default:
            sessionBt.isEnabled = false
        }
    }
}

