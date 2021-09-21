//
//  T2TPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 12.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 https://github.com/iCepa/tun2tor
 */
class T2TPTProvider: BasePTProvider {

    class TunThread: Thread {

        let packetFlow: NEPacketTunnelFlow

        init(_ packetFlow: NEPacketTunnelFlow) {
            self.packetFlow = packetFlow
        }

        override func main() {
            if let fd = tunnelFd {
                tun2tor_run(fd, TorManager.dnsPort, Int32(TorManager.torProxyPort))
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
