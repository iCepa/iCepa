//
//  VpnManager.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension
import Tor

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

    enum Errors: LocalizedError {
        public var errorDescription: String? {
            switch self {
            case .noConfiguration:
                return NSLocalizedString("No VPN configuration set.", comment: "")

            case .couldNotConnect:
                return NSLocalizedString("Could not connect.", comment: "")
            }
        }

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

    var transport: NETunnelProviderProtocol.Transport {
        return manager?.transport ?? .direct
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

        NSKeyedUnarchiver.setClass(ProgressMessage.self, forClassName:
            "TorVPN_Mac.\(String(describing: ProgressMessage.self))")

        NotificationCenter.default.addObserver(
            self, selector: #selector(statusDidChange),
            name: .NEVPNStatusDidChange, object: nil)

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            self?.error = error
            self?.manager = managers?.first(where: { $0.isEnabled }) ?? managers?.first

            self?.postChange()
        }
    }

    private var transportIterator: IndexingIterator<[NETunnelProviderProtocol.Transport]>? = nil

    func install() {
        if transportIterator == nil {
            transportIterator = NETunnelProviderProtocol.Transport.allCases.makeIterator()
            error = nil
        }

        if error != nil {
            transportIterator = nil

            postChange()

            return
        }

        var transport = transportIterator?.next()

        #if os(macOS)
        // Don't install Obfs4 and Snowflake profiles: both are unavailable on MacOS.
        while transport == .obfs4 || transport == .snowflake {
            transport = transportIterator?.next()
        }
        #endif

        if let transport = transport {
            let conf = NETunnelProviderProtocol()
            conf.providerBundleIdentifier = Config.extBundleId
            conf.serverAddress = transport.description // Needs to be set to something, otherwise error.
            conf.transport = transport

            let manager = NETunnelProviderManager()
            manager.protocolConfiguration = conf
            manager.localizedDescription = "\(Bundle.main.displayName) (\(transport.description))"

            // Add a "always connect" rule to avoid leakage after the network
            // extension got killed.
            manager.onDemandRules = [NEOnDemandRuleConnect()]

            manager.saveToPreferences { [weak self] error in
                self?.error = error

                // Install next one.
                self?.install()
            }
        }
        else {
            // Always re-load the manager from preferences.
            // If we use one of the created ones, it will stay invalid and can't
            // be used for connecting right away.

            NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
                self?.error = error

                // After install, we use and enable the direct (no) transport at first.
                self?.manager = managers?.first(where: { $0.transport == .direct }) ?? managers?.first
                self?.manager?.isEnabled = true

                self?.save()
            }

            transportIterator = nil
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

    func `switch`(to transport: NETunnelProviderProtocol.Transport) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            self?.error = error

            self?.manager = managers?.first(where: { $0.transport == transport })
            self?.manager?.isEnabled = true

            self?.save()
        }
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

    func getCircuits(_ callback: @escaping ((_ circuits: [TorCircuit], _ error: Error?) -> Void)) {
        let request: Data

        do {
            request = try NSKeyedArchiver.archivedData(withRootObject: GetCircuitsMessage(), requiringSecureCoding: true)
        }
        catch let error {
            return callback([], error)
        }

        do {
            try session?.sendProviderMessage(request) { response in

                guard let response = response else {
                    return callback([], nil)
                }

                do {
                    let circuits = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? [TorCircuit]
                    callback(circuits ?? [], nil)
                }
                catch let error {
                    callback([], error)
                }
            }
        }
        catch let error {
            callback([], error)
        }
    }

    func closeCircuits(_ circuits: [TorCircuit], _ callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        let request: Data

        do {
            request = try NSKeyedArchiver.archivedData(withRootObject: CloseCircuitsMessage(circuits), requiringSecureCoding: true)
        }
        catch let error {
            return callback(false, error)
        }

        do {
            try session?.sendProviderMessage(request) { response in
                guard let response = response else {
                    return callback(false, nil)
                }

                do {
                    let success = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? Bool
                    callback(success ?? false, nil)
                }
                catch let error {
                    callback(false, error)
                }
            }
        }
        catch let error {
            callback(false, error)
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
                        if let response = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? [Message] {
                            for message in response {
                                if let pm = message as? ProgressMessage {
                                    NSLog("[\(String(describing: type(of: self)))] ProgressMessage=\(pm.progress)")

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
                NSLog("[\(String(describing: type(of: self)))] "
                    + "Could not establish communications channel with extension. "
                    + "Error: \(error)")
            }

            if poll {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.commTunnel)
            }
        }
        else {
            NSLog("[\(String(describing: type(of: self)))] "
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
