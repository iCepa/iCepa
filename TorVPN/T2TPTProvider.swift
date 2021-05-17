//
//  T2TPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 12.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

class T2TPTProvider: BasePTProvider {

    class TunThread: Thread {

        let packetFlow: NEPacketTunnelFlow

        init(_ packetFlow: NEPacketTunnelFlow) {
            self.packetFlow = packetFlow
        }

        override func main() {
            if let fd = packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 {
                tun2tor_run(fd, BasePTProvider.dnsPort, Int32(BasePTProvider.torProxyPort))
            }
        }
    }

    private lazy var tunThread: TunThread? = {
        return TunThread(packetFlow)
    }()

    override func startTun2Socks() {
        tunThread?.start()
    }

    override func stopTun2Socks() {
        tunThread?.cancel()
        tunThread = nil
    }
}
