//
//  PacketTunnelProvider.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider, URLSessionDelegate {

    private static let configuration: TorConfiguration = {
        let appGroupDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CPAAppGroupIdentifier)!
        let dataDirectory = appGroupDirectory.appendingPathComponent("Tor")
        
        // This is needed because tor loads its cache too aggressively for Jetsam
        try? FileManager.default.removeItem(at: dataDirectory)
        
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: [FileAttributeKey(rawValue: FileAttributeKey.posixPermissions.rawValue): 0o700])
        } catch let error as NSError {
            NSLog("Error: Cannot configure data directory: %@", error.localizedDescription)
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
        let client = asl_open(nil, "com.apple.console", 0)
        asl_log_descriptor(client, nil, ASL_LEVEL_NOTICE, STDOUT_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
        asl_log_descriptor(client, nil, ASL_LEVEL_ERR, STDERR_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
        asl_close(client)
        
        return TorThread(configuration: configuration)
    }()
    
    private lazy var tunThread: TunThread = {
        return TunThread(packetFlow: self.packetFlow)
    }()
    
    private lazy var controller: TorController = {
        return TorController(socketURL: PacketTunnelProvider.configuration.controlSocket!)
    }()

    override var protocolConfiguration: NETunnelProviderProtocol {
        return super.protocolConfiguration as! NETunnelProviderProtocol
    }

    override func startTunnel(options: [String : NSObject]? = [:], completionHandler: @escaping (Error?) -> Void) {
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.ipv4Settings = ipv4Settings
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])

        let controller = self.controller
        self.setTunnelNetworkSettings(settings) { (error) -> Void in
            if let error = error {
                NSLog("%@: Error cannot set tunnel network settings: %@", self, error.localizedDescription)
                return completionHandler(error)
            }
            
            PacketTunnelProvider.torThread.start()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try controller.connect()
                    let cookie = try Data(contentsOf: PacketTunnelProvider.configuration.dataDirectory!.appendingPathComponent("control_auth_cookie"), options: NSData.ReadingOptions(rawValue: 0))
                    controller.authenticate(with: cookie, completion: { (success, error) -> Void in
                        if let error = error {
                            NSLog("%@: Error: Cannot authenticate with tor: %@", self, error.localizedDescription)
                            return completionHandler(error)
                        }
                        
                        var observer: Any? = nil
                        observer = controller.addObserver(forCircuitEstablished: { (established) -> Void in
                            guard established else {
                                return
                            }
                            
                            controller.removeObserver(observer)
                            
                            self.tunThread.start()
                            completionHandler(nil)
                        })
                        
                        // TODO: Handle circuit establish failure
                    })
                } catch let error as NSError {
                    NSLog("%@: Error: Cannot connect to tor: %@", self, error.localizedDescription)
                    completionHandler(nil /* error */)
                }
            }
        }
    }
    
    func stopTunnel(with reason: NEProviderStopReason, completionHandler: () -> Void) {
        // TODO: Add disconnect handler
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {

    }
}
