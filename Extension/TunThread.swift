//
//  TunThread.swift
//  iCepa
//
//  Created by Conrad Kramer on 12/16/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import NetworkExtension

class TunThread: Thread {
    
    let packetFlow: NEPacketTunnelFlow
    
    init(packetFlow: NEPacketTunnelFlow) {
        self.packetFlow = packetFlow
    }
    
    override func main() {
        tun2tor_run(packetFlow.value(forKeyPath: "socket.fileDescriptor") as! Int32)
    }
}
