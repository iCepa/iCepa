//
//  PacketTunnelProvider.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider, NSURLSessionDelegate {
    
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
        configuration.options = ["DNSPort": "12345", "AutomapHostsOnResolve": "1", "SocksPort": "9050", "ControlPort": "9051"]
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectory
        //configuration.controlSocket = dataDirectory.URLByAppendingPathComponent("control_port")
        configuration.arguments = ["--ignore-missing-torrc"]
        
        if let x = TORThread.torThread() {
            thread = x
        } else {
            thread = TORThread(configuration: configuration)
            thread.start()
        }
        
//        controller = TORController(socketURL: configuration.controlSocket!)
        controller = TORController(socketHost: "127.0.0.1", port: 9051)
        
        interface = TunnelInterface()
        
        super.init()
        
        weak var weakSelf = self
        interface.packetCallback = { (data, proto) -> Void in
            if let weakSelf = weakSelf {
                weakSelf.packetFlow.writePackets([data], withProtocols: [proto])
            }
        }
    }

    override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.defaultRoute()]

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.IPv4Settings = ipv4Settings
        settings.DNSSettings = NEDNSSettings(servers: ["8.8.8.8"])
        
//        let ipv6Settings = NEIPv6Settings(addresses: ["2001:4860:4860::8888"], networkPrefixLengths: [64])
//        ipv6Settings.includedRoutes = [NEIPv6Route.defaultRoute()]
        
//        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "::1")
//        settings.IPv6Settings = ipv6Settings
//        settings.DNSSettings = NEDNSSettings(servers: ["2001:4860:4860::8888"])
        
        let controller = self.controller
        self.setTunnelNetworkSettings(settings) { (error) -> Void in
            self.startReadingPackets()
            #if os(iOS)
            self.wakeUpApplication()
            #endif
            
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
    
    override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
        // TODO: Add disconnect handler
        completionHandler()
    }
    
    override func handleAppMessage(messageData: NSData, completionHandler: ((NSData?) -> Void)?) {

    }
    
    func startReadingPackets() {
        packetFlow.readPacketsWithCompletionHandler { (packets, _) -> Void in
            for packet in packets {
                self.interface.inputPacket(packet)
            }
            self.startReadingPackets()
        }
    }
    
    #if os(iOS)
    func wakeUpApplication() {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(NSUUID().UUIDString)
        configuration.sharedContainerIdentifier = CPAAppGroupIdentifier
        
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        session.downloadTaskWithURL(NSURL(string: "http://127.0.0.1:1")!).resume()
        session.finishTasksAndInvalidate()
        
        let count: UnsafeMutablePointer<UInt32> = UnsafeMutablePointer.alloc(4)
        let variables = class_copyIvarList(object_getClass(session), count)
        for index in 0..<count.memory {
            let ivar = variables[Int(index)]
            if UInt8(ivar_getTypeEncoding(ivar)[0]) != "@".utf8.first! { continue }
            guard let object = object_getIvar(session, ivar) else { continue }
            if !object.respondsToSelector(#selector(NSPort.invalidate)) { continue }
                        
            object.performSelector(#selector(NSPort.invalidate))
            break
        }
    }
    #endif
}
