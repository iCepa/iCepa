//
//  PacketTunnelProvider.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider, URLSessionDelegate {
    
    let configuration: TORConfiguration
    let thread: TORThread
    let controller: TORController
    
    let interface: TunnelInterface
    
    override var protocolConfiguration: NETunnelProviderProtocol {
        return super.protocolConfiguration as! NETunnelProviderProtocol
    }
    
    override init() {
        let appGroupDirectory = FileManager.default.containerURLForSecurityApplicationGroupIdentifier(CPAAppGroupIdentifier)!
        let dataDirectory = try! appGroupDirectory.appendingPathComponent("Tor")
        
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: [FileAttributeKey.posixPermissions.rawValue: 0o700])
        } catch let error as NSError {
            NSLog("Error: Cannot configure data directory: %@", error.localizedDescription)
        }
        
        configuration = TORConfiguration()
        configuration.options = ["DNSPort": "12345", "AutomapHostsOnResolve": "1", "SocksPort": "9050", "ControlPort": "9051"]
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectory
        configuration.controlSocket = try! dataDirectory.appendingPathComponent("control_port")
        configuration.arguments = ["--ignore-missing-torrc"]
        
//        if let existing = TORThread.torThread() {
//            thread = existing
//        } else {
            thread = TORThread(configuration: configuration)
            thread.start()
//        }
    
        controller = TORController(socketURL: configuration.controlSocket!)
        
        interface = TunnelInterface()
        
        super.init()
        
        weak var weakSelf = self
        interface.callback = { (data, proto) -> Void in
            if let weakSelf = weakSelf {
                weakSelf.packetFlow.writePackets([data], withProtocols: [proto])
            }
        }
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
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
            
            do {
                try controller.connect()
                let cookie = try Data(contentsOf: try! self.configuration.dataDirectory!.appendingPathComponent("control_auth_cookie"), options: NSData.ReadingOptions(rawValue: 0))
                controller.authenticate(with: cookie, completion: { (success, error) -> Void in
                    if let error = error {
                        NSLog("%@: Error: Cannot authenticate with tor: %@", self, error.localizedDescription)
                        return completionHandler(error)
                    }
                    
                    var observer: AnyObject? = nil
                    observer = controller.addObserver(forCircuitEstablished: { (established) -> Void in
                        guard established else {
                            return
                        }
                        
                        completionHandler(nil)
                        controller.removeObserver(observer)
                        self.startReadingPackets()
                    })
                    
                    // TODO: Handle circuit establish failure
                })
            } catch let error as NSError {
                NSLog("%@: Error: Cannot connect to tor: %@", self, error.localizedDescription)
                completionHandler(error)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: () -> Void) {
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
