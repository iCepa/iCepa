//
//  PacketTunnelProvider.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider, URLSessionDelegate {

    private static let configuration: TORConfiguration = {
        let appGroupDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CPAAppGroupIdentifier)!
        let dataDirectory = appGroupDirectory.appendingPathComponent("Tor")
        
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: [FileAttributeKey.posixPermissions.rawValue: 0o700])
        } catch let error as NSError {
            NSLog("Error: Cannot configure data directory: %@", error.localizedDescription)
        }
        
        let configuration = TORConfiguration()
        configuration.options = ["DNSPort": "12345", "AutomapHostsOnResolve": "1", "SocksPort": "9050"]
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectory
        configuration.controlSocket = dataDirectory.appendingPathComponent("control_port")
        configuration.arguments = ["--ignore-missing-torrc"]
        return configuration
    }()
    
    private static let thread: TORThread = {
        let client = asl_open(nil, "com.apple.console", 0)
        asl_log_descriptor(client, nil, ASL_LEVEL_NOTICE, STDOUT_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
        asl_log_descriptor(client, nil, ASL_LEVEL_ERR, STDERR_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
        asl_close(client)
        
        let thread = TORThread(configuration: configuration)
        thread.start()
        return thread
    }()
    
    private lazy var controller: TORController = {
        return TORController(socketURL: configuration.controlSocket!)
    }()
    
    private lazy var interface: TunnelInterface = {
        weak var weakSelf = self
        return TunnelInterface() { (data, proto) -> Void in
            guard let strongSelf = weakSelf else { return }
            strongSelf.packetFlow.writePackets([data], withProtocols: [NSNumber(value: proto)])
        }
    }()
    
    override var protocolConfiguration: NETunnelProviderProtocol {
        return super.protocolConfiguration as! NETunnelProviderProtocol
    }
    
    override init() {
        super.init()
        let _ = PacketTunnelProvider.thread
    }

    override func startTunnel(options: [String : NSObject]? = [:], completionHandler: @escaping (Error?) -> Void) {
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.123.45.6")
        settings.iPv4Settings = ipv4Settings
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
       
//        let ipv6Settings = NEIPv6Settings(addresses: ["2001:4860:4860::8888"], networkPrefixLengths: [64])
//        ipv6Settings.includedRoutes = [NEIPv6Route.defaultRoute()]
        
//        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "::1")
//        settings.IPv6Settings = ipv6Settings
//        settings.DNSSettings = NEDNSSettings(servers: ["2001:4860:4860::8888"])
        
        let controller = self.controller
        self.setTunnelNetworkSettings(settings) { (error) -> Void in
            if let error = error {
                NSLog("%@: Error cannot set tunnel network settings: %@", self, error.localizedDescription)
                return completionHandler(error)
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
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
                            completionHandler(nil)
                            self.startReadingPackets()
                        })
                        
                        // TODO: Handle circuit establish failure
                    })
                } catch let error as NSError {
                    NSLog("%@: Error: Cannot connect to tor: %@", self, error.localizedDescription)
                    completionHandler(error)
                }
            })
        }
    }
    
    func stopTunnel(with reason: NEProviderStopReason, completionHandler: () -> Void) {
        // TODO: Add disconnect handler
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {

    }
    
    func startReadingPackets() {
        packetFlow.readPackets(completionHandler: { (packets, _) -> Void in
            for packet in packets {
                self.interface.input(packet: packet)
            }
            self.startReadingPackets()
        })
    }
}
