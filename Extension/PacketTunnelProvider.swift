//
//  PacketTunnelProvider.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let configuration: TORConfiguration
    let thread: TORThread
    let controller: TORController
    
    let interface: TunnelInterface
    
    override var protocolConfiguration: NETunnelProviderProtocol {
        return super.protocolConfiguration as! NETunnelProviderProtocol
    }
    
    override init() {
        let appGroupDirectory = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(CPAAppGroupIdentifier)!
        let dataDirectory = appGroupDirectory.URLByAppendingPathComponent("Tor")
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(dataDirectory, withIntermediateDirectories: true, attributes: [NSFilePosixPermissions: 0o700])
        } catch let error as NSError {
            NSLog("Error: Cannot configure data directory: %@", error.localizedDescription)
        }
        
        // TODO: Convert to use NSURL, make properties optional, add DNSPort
        configuration = TORConfiguration()
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectory.path!
        configuration.controlSocket = dataDirectory.URLByAppendingPathComponent("control_port").path!
        configuration.arguments = ["--ignore-missing-torrc"]
        
        if let x = TORThread.torThread() {
            thread = x
        } else {
            thread = TORThread(configuration: configuration)
            thread.start()
        }
        
        controller = TORController(controlSocketPath: configuration.controlSocket)
        
        interface = TunnelInterface()
        
        super.init()
    }
    
    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.defaultRoute()]
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        settings.IPv4Settings = ipv4Settings
        settings.DNSSettings = NEDNSSettings(servers: ["192.168.1.2"])
        
        let controller = self.controller
        setTunnelNetworkSettings(settings) { (_) -> Void in
            do {
                try controller.connect()
                let cookie = try NSData(contentsOfURL: NSURL(fileURLWithPath: self.configuration.dataDirectory).URLByAppendingPathComponent("control_auth_cookie"), options: NSDataReadingOptions(rawValue: 0))
                
                // TODO: Make error nullable
                controller.authenticateWithData(cookie, completion: { (success, _) -> Void in
//                    if error != nil {
//                        NSLog("%@: Error: Cannot authenticate with tor: %@", self, error.localizedDescription)
//                        return completionHandler(error)
//                    }
                    
                    var observer: AnyObject? = nil
                    let initial = controller.addObserverForCircuitEstablished({ (established) -> Void in
                        if (established) {
                            completionHandler(nil)
                            self.startReadingPackets()
                            
                            // TODO: Make nullable
                            if observer != nil {
                                controller.removeObserver(observer!)
                            }
                        }
                        // TODO: Handle circuit establish failure
                    })
                    observer = initial
                })
            } catch let error as NSError {
                NSLog("%@: Error: Cannot connect to tor: %@", self, error.localizedDescription)
                return completionHandler(error)
            }
        }
    }
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        // TODO: Add disconnect handler
        completionHandler()
    }
    
    override func handleAppMessage(messageData: NSData, completionHandler: ((NSData?) -> Void)?) {

    }
    
    func startReadingPackets() -> Void {
        packetFlow.readPacketsWithCompletionHandler { (packets, _) -> Void in
            for packet in packets {
                self.interface.inputPacket(packet)
            }
            self.startReadingPackets()
        }
    }
}