//
//  GoT2SPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 07.10.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 Uses a tun2socks implementation written in Go:

 https://github.com/eycorsican/go-tun2socks

 Problems:
 - No working DNS via Tor.
 - Memory limit of 15 MByte is easily overshot.
 - No stop, yet. (Needs to be implemented in Go.)
 - Tor says: "Socks version 71 not recognized."
 */
class GoT2SPTProvider: BasePTProvider {

    private lazy var t2sPacketFlow = PacketFlow(packetFlow)

    override func startTun2Socks() {
        Tun2socksStartSocks(t2sPacketFlow, TorManager.localhost,
                            Int(TorManager.torProxyPort))
    }

    override func stopTun2Socks() {
        // TODO: Need Go function to stop this again.
    }
}
