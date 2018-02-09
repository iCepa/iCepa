//
//  PacketTunnelProvider.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider, URLSessionDelegate {

    private static let ENABLE_LOGGING = false
    private static var messageQueue: [String: Any] = ["log":[]]

    private static let configuration: TorConfiguration = {
        let appGroupDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CPAAppGroupIdentifier)!
        let dataDirectory = appGroupDirectory.appendingPathComponent("Tor")
        
        // This is needed because tor loads its cache too aggressively for Jetsam
        try? FileManager.default.removeItem(at: dataDirectory)
        
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: [FileAttributeKey(rawValue: FileAttributeKey.posixPermissions.rawValue): 0o700])
        } catch let error as NSError {
            log("Error: Cannot configure data directory: \(error.localizedDescription)")
        }
        
        let configuration = TorConfiguration()
        configuration.options = ["DNSPort": "12345", "AutomapHostsOnResolve": "1", "SocksPort": "9050", "AvoidDiskWrites": "1"]
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectory
        configuration.controlSocket = dataDirectory.appendingPathComponent("control_port")
        configuration.arguments = ["--ignore-missing-torrc"]
        return configuration
    }()
    
    private static let torThread: TorThread = {
        return TorThread(configuration: configuration)
    }()

    private var timer: Timer?

    private lazy var tunThread: TunThread? = {
        return TunThread(packetFlow: self.packetFlow)
    }()
    
    private lazy var controller: TorController? = {
        return TorController(socketURL: PacketTunnelProvider.configuration.controlSocket!)
    }()

    override var protocolConfiguration: NETunnelProviderProtocol {
        return super.protocolConfiguration as! NETunnelProviderProtocol
    }

    private var hostHandler: ((Data?) -> Void)?

    override func startTunnel(options: [String : NSObject]? = [:], completionHandler: @escaping (Error?) -> Void) {
        let ipv4Settings = NEIPv4Settings(addresses: ["172.30.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]

        log("startTunnel, options: \(String(describing: options))")

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.ipv4Settings = ipv4Settings
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])

        let controller = self.controller
        self.setTunnelNetworkSettings(settings) { (error) -> Void in
            if let error = error {
                self.log("Error cannot set tunnel network settings: \(error.localizedDescription)")
                return completionHandler(error)
            }
            
            PacketTunnelProvider.torThread.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                do {
                    self.log("startTunnel, before connecting to Tor thread.")

                    // Use this with a recent Tor.framework to tunnel logs from Tor to the app.
                    //                    TORInstallTorLoggingCallback { (type: OSLogType, message: UnsafePointer<Int8>) in
                    //                        PacketTunnelProvider.log(String.init(cString: message))
                    //                    }
                    //
                    //                    self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                    //                                                      selector: #selector(self.sendMessages),
                    //                                                      userInfo: nil, repeats: true)

                    try controller?.connect()
                    let cookie = try Data(contentsOf: PacketTunnelProvider.configuration.dataDirectory!.appendingPathComponent("control_auth_cookie"), options: NSData.ReadingOptions(rawValue: 0))
                    controller?.authenticate(with: cookie, completion: { (success, error) -> Void in
                        if let error = error {
                            self.log("Error: Cannot authenticate with Tor: \(error.localizedDescription)")
                            return completionHandler(error)
                        }
                        
                        var observer: Any? = nil
                        observer = controller?.addObserver(forCircuitEstablished: { (established) -> Void in
                            guard established else {
                                return
                            }
                            
                            controller?.removeObserver(observer)
                            
                            self.tunThread?.start()

                            self.log("startTunnel, tunnel started.")

                            completionHandler(nil)
                        })
                        
                        // TODO: Handle circuit establish failure
                    })
                } catch let error as NSError {
                    self.log("Error: Cannot connect to Tor: \(error.localizedDescription)")
                    completionHandler(nil /* error */)
                }
            }
        }
    }
    
    func stopTunnel(with reason: NEProviderStopReason, completionHandler: () -> Void) {
        log("stopTunnel, reason: \(reason)")

        tunThread = nil
        controller = nil

        self.timer?.invalidate()
        self.timer = nil

        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if PacketTunnelProvider.ENABLE_LOGGING {
            hostHandler = completionHandler
        }
    }

    @objc private func sendMessages() {
        if PacketTunnelProvider.ENABLE_LOGGING, let handler = hostHandler {
            let response = NSKeyedArchiver.archivedData(withRootObject: PacketTunnelProvider.messageQueue)
            PacketTunnelProvider.messageQueue = ["log": []]
            handler(response)
            hostHandler = nil
        }
    }

    private func log(_ message: String) {
        PacketTunnelProvider.log(message)

        sendMessages()
    }

    private static func log(_ message: String) {
        if ENABLE_LOGGING, var log = messageQueue["log"] as? [String] {
            log.append("\(self): \(message)")
            messageQueue["log"] = log
        }
    }
}
