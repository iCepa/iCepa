//
//  VpnManager.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import NetworkExtension

extension Notification.Name {
    static let vpnStatusChanged = Notification.Name("vpn-status-changed")
    static let vpnProgress = Notification.Name("vpn-progress")
}

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connected:
            return NSLocalizedString("connected", comment: "")

        case .connecting:
            return NSLocalizedString("connecting", comment: "")

        case .disconnected:
            return NSLocalizedString("disconnected", comment: "")

        case .disconnecting:
            return NSLocalizedString("disconnecting", comment: "")

        case .invalid:
            return NSLocalizedString("invalid", comment: "")

        case .reasserting:
            return NSLocalizedString("reasserting", comment: "")

        @unknown default:
            return NSLocalizedString("unknown", comment: "")
        }
    }
}

class VpnManager {

    enum ConfStatus: CustomStringConvertible {
        var description: String {
            switch self {
            case .notInstalled:
                return NSLocalizedString("not installed", comment: "")

            case .disabled:
                return NSLocalizedString("disabled", comment: "")

            case .enabled:
                return NSLocalizedString("enabled", comment: "")
            }
        }

        case notInstalled
        case disabled
        case enabled
    }

    enum Errors: Error {
        case noConfiguration
        case couldNotConnect
    }

    static let shared = VpnManager()

    private var manager: NETunnelProviderManager?

    private var session: NETunnelProviderSession? {
        return manager?.connection as? NETunnelProviderSession
    }

    private var poll = false

    var confStatus: ConfStatus {
        return manager == nil ? .notInstalled : manager!.isEnabled ? .enabled : .disabled
    }

    var sessionStatus: NEVPNStatus {
        if confStatus != .enabled {
            return .invalid
        }

        return session?.status ?? .disconnected
    }

    private(set) var error: Error?

    init() {
        NSKeyedUnarchiver.setClass(ProgressMessage.self, forClassName:
            "TorVPN.\(String(describing: ProgressMessage.self))")

        NotificationCenter.default.addObserver(
            self, selector: #selector(statusDidChange),
            name: .NEVPNStatusDidChange, object: nil)

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            self?.error = error
            self?.manager = managers?.first

            self?.postChange()
        }
    }

    func install() {
        let conf = NETunnelProviderProtocol()
        conf.providerBundleIdentifier = Config.extBundleId
        conf.serverAddress = "Tor" // Needs to be set to something, otherwise error.

        let manager = NETunnelProviderManager()
        manager.protocolConfiguration = conf
        manager.localizedDescription = Bundle.main.displayName
        manager.isEnabled = true

        // Add a "always connect" rule to avoid leakage after the network
        // extension got killed.
        manager.onDemandRules = [NEOnDemandRuleConnect()]

        manager.saveToPreferences { [weak self] error in
            self?.error = error

            if error == nil {
                self?.manager = manager
            }

            self?.postChange()
        }
    }

    func enable() {
        manager?.isEnabled = true

        save()
    }

    func disable() {
        manager?.isEnabled = false

        save()
    }

    func connect() {
        guard let session = session else {
            error = Errors.noConfiguration

            postChange()

            return
        }

        DispatchQueue.main.async {
            do {
                try session.startVPNTunnel()
            }
            catch let error {
                self.error = error

                self.postChange()
            }

            self.commTunnel()
        }
    }

    func disconnect() {
        session?.stopTunnel()
    }

    func getCircuits(_ callback: @escaping ((_ circuits: [TorCircuit]) -> Void)) {
        guard let request = try? NSKeyedArchiver.archivedData(
            withRootObject: GetCircuitsMessage(), requiringSecureCoding: true) else {

                print("[\(String(describing: type(of: self)))]#getCircuits error=Could not create request.")
                return callback([])
        }

        do {
            try session?.sendProviderMessage(request) { response in
                if let response = response,
                    let circuits = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? [TorCircuit] {

                    callback(circuits)
                }
                else {
                    print("[\(String(describing: type(of: self)))]#getCircuits error=Could not decode response.")
                    callback([])
                }
            }
        }
        catch let error {
            print("[\(String(describing: type(of: self)))]#getCircuits error=\(error)")
            callback([])
        }
    }

    func closeCircuits(_ circuits: [TorCircuit], _ callback: @escaping ((_ success: Bool) -> Void)) {
        guard let request = try? NSKeyedArchiver.archivedData(
            withRootObject: CloseCircuitsMessage(circuits), requiringSecureCoding: true) else {

                print("[\(String(describing: type(of: self)))]#closeCircuits error=Could not create request.")
                return callback(false)
        }

        do {
            try session?.sendProviderMessage(request) { response in
                if let response = response,
                    let success = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? Bool {

                    callback(success)
                }
                else {
                    print("[\(String(describing: type(of: self)))]#closeCircuits error=Could not decode response.")
                    callback(false)
                }
            }
        }
        catch let error {
            print("[\(String(describing: type(of: self)))]#closeCircuits error=\(error)")
            callback(false)
        }
    }


    // MARK: Private Methods

    private func save() {
        manager?.saveToPreferences { [weak self] error in
            self?.error = error

            self?.postChange()
        }
    }

    @objc
    private func statusDidChange(_ notification: Notification) {
        switch sessionStatus {
        case .invalid:
            // Provider not installed/enabled

            poll = false

            error = Errors.couldNotConnect

        case .connecting:
            poll = true
            commTunnel()

        case .connected:
            poll = false

        case .reasserting:
            // Circuit reestablishing
            poll = true
            commTunnel()

        case .disconnecting:
            // Circuit disestablishing
            poll = false

        case .disconnected:
            // Circuit not established
            poll = false

        default:
            assert(session == nil)
        }

        postChange()
    }

    private func commTunnel() {
        if (session?.status ?? .invalid) != .invalid {
            do {
                try session?.sendProviderMessage(Data()) { response in
                    if let response = response {
                        if let response = NSKeyedUnarchiver.unarchiveObject(with: response) as? [Message] {

                            for message in response {
                                if let pm = message as? ProgressMessage {
                                    print("[\(String(describing: type(of: self)))] ProgressMessage=\(pm.progress)")

                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: .vpnProgress, object: pm.progress)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch {
                print("[\(String(describing: type(of: self)))] "
                    + "Could not establish communications channel with extension. "
                    + "Error: \(error)")
            }

            if poll {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.commTunnel)
            }
        }
        else {
            print("[\(String(describing: type(of: self)))] "
                + "Could not establish communications channel with extension. "
                + "VPN configuration does not exist or is not enabled. "
                + "No further actions will be taken.")

            error = Errors.couldNotConnect

            postChange()
        }
    }

    private func postChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .vpnStatusChanged, object: self)
        }
    }
}
