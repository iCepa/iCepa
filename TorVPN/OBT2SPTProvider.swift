//
//  OBT2SPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 07.10.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 Uses a tun2socks implementation written in C:

 https://github.com/tladesignz/OBTun2Socks

 Problems:
 - No working DNS via Tor.
 - Memory limit of 15 MByte is easily overshot.
 */
class OBT2SPTProvider: BasePTProvider {

    override func startTun2Socks() {
        TunnelInterface.setup(with: packetFlow)
        TunnelInterface.startTun2Socks(Int32(TorManager.torProxyPort),
                                       withUsername: "iCepa",
                                       andPassword: "iCepa");

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            TunnelInterface.processPackets()
        }
    }

    override func stopTun2Socks() {
        TunnelInterface.stop()
    }
}
