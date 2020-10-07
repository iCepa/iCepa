//
//  PacketFlow.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 06.10.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

class PacketFlow: NSObject, Tun2socksPacketFlowProtocol {

    private let tunnelFlow: NEPacketTunnelFlow

    init(_ tunnelFlow: NEPacketTunnelFlow) {
        self.tunnelFlow = tunnelFlow

        super.init()

        tunnelFlow.readPackets(completionHandler: readPackets)
    }

    func writePacket(_ packet: Data?) {
        log("#writePacket size=\(packet?.count ?? -1), content=\(String(data: packet ?? Data(), encoding: .utf8) ?? "nil")")

        guard let packet = packet else {
            return
        }

        tunnelFlow.writePackets([packet], withProtocols: [NSNumber(value: AF_INET)])
    }

    private func readPackets(data: [Data], protocols: [NSNumber]) {
        log("#readPackets count=\(data.count), size=\(data.first?.count ?? -1), content=\(String(data: data.first ?? Data(), encoding: .utf8) ?? "nil")")

        for packet in data {
            Tun2socksInputPacket(packet)
        }
    }

    private func log(_ message: String) {
        BasePTProvider.log("\(String(describing: type(of: self)))" + message, to: BasePTProvider.vpnLogfile)
    }
}
