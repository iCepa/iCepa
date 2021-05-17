//
//  OGoT2SPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 14.10.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 Uses another tun2socks implementation written in Go:

 https://github.com/Jigsaw-Code/outline-go-tun2socks

 Problems:
 - No working DNS via Tor.
 - Memory limit of 15 MByte is easily overshot.
 - No stop, yet. (Needs to be implemented in Go.)
 - Tor says: "Socks version 71 not recognized."
 */
class OGoT2SPTProvider: BasePTProvider {

    private lazy var tunWriter = TunWriter(packetFlow)

    private var tunnel: Tun2socksOutlineTunnelProtocol?

    private var error: NSError?

    override func startTun2Socks() {
        tunnel = Tun2socksConnectShadowsocksTunnel(
            tunWriter,
            TorManager.localhost,
            Int(TorManager.torProxyPort),
            "onion",
            nil,
            false, &error)

        tunWriter.tunnel = tunnel
    }

    override func stopTun2Socks() {
        tunnel?.disconnect()
        tunnel = nil

        tunWriter.tunnel = nil
    }
}
