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
        
        configuration = TORConfiguration()
        configuration.options = ["DNSPort": "12345"]
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectory
        configuration.controlSocket = dataDirectory.URLByAppendingPathComponent("control_port")
        configuration.arguments = ["--ignore-missing-torrc"]
        
        if let x = TORThread.torThread() {
            thread = x
        } else {
            thread = TORThread(configuration: configuration)
            thread.start()
        }
        
        controller = TORController(socketURL: configuration.controlSocket!)
        
        interface = TunnelInterface()
        
        super.init()
        
        weak var weakSelf = self
        interface.packetCallback = { (data) -> Void in
            NSLog("Received data! %@", data)
            if let weakSelf = weakSelf {
                weakSelf.packetFlow.writePackets([data], withProtocols: [0])
            }
        }
    }
    
    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
//        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
//        ipv4Settings.includedRoutes = [NEIPv4Route.defaultRoute()]

        let ipv6Settings = NEIPv6Settings(addresses: ["2001:4860:4860::8888"], networkPrefixLengths: [64])
        ipv6Settings.includedRoutes = [NEIPv6Route.defaultRoute()]
      
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "::1")
//        settings.IPv4Settings = ipv4Settings
        settings.IPv6Settings = ipv6Settings
        settings.DNSSettings = NEDNSSettings(servers: ["2001:4860:4860::8888"])
        
        let controller = self.controller
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
            self.setTunnelNetworkSettings(settings) { (error) -> Void in
                if let error = error {
                    NSLog("%@: Error cannot set tunnel network settings: %@", self, error.localizedDescription)
                    return completionHandler(error)
                }
                
                do {
                    try controller.connect()
                    let cookie = try NSData(contentsOfURL: self.configuration.dataDirectory!.URLByAppendingPathComponent("control_auth_cookie"), options: NSDataReadingOptions(rawValue: 0))
                    controller.authenticateWithData(cookie, completion: { (success, error) -> Void in
                        if let error = error {
                            NSLog("%@: Error: Cannot authenticate with tor: %@", self, error.localizedDescription)
                            return completionHandler(error)
                        }
                        
                        var observer: AnyObject? = nil
                        observer = controller.addObserverForCircuitEstablished({ (established) -> Void in
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
