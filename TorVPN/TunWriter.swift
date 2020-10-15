//
//  TunWriter.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 14.10.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

class TunWriter: NSObject, Tun2socksTunWriterProtocol {

    public var tunnel: Tun2socksOutlineTunnelProtocol?

    private let tunnelFlow: NEPacketTunnelFlow

    private var returnValue = 0

    private var error: NSError?


    init(_ tunnelFlow: NEPacketTunnelFlow) {
        self.tunnelFlow = tunnelFlow

        super.init()

        tunnelFlow.readPackets(completionHandler: readPackets)
    }

    func close() throws {
        log("#close")
    }

    func write(_ p0: Data?, n: UnsafeMutablePointer<Int>?) throws {
        log("#writePacket size=\(p0?.count ?? -1), content=\(String(data: p0 ?? Data(), encoding: .utf8) ?? "nil")")

        guard let packet = p0 else {
            return
        }

        tunnelFlow.writePackets([packet], withProtocols: [NSNumber(value: AF_INET)])
    }

    private func readPackets(data: [Data], protocols: [NSNumber]) {
        log("#readPackets count=\(data.count), size=\(data.first?.count ?? -1), content=\(String(data: data.first ?? Data(), encoding: .utf8) ?? "nil")")

        for packet in data {
            do {
                try tunnel?.write(packet, ret0_: &returnValue)
            }
            catch {
                log("#readPackets write error. returnValue=\(returnValue), error=\(error)")
            }
        }
    }

    private func log(_ message: String) {
        BasePTProvider.log("\(String(describing: type(of: self)))" + message, to: BasePTProvider.vpnLogfile)
    }
}
