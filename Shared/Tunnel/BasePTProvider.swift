//
//  BasePTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

class BasePTProvider: NEPacketTunnelProvider {

    private static var messageQueue = [Message]()

    private var hostHandler: ((Data?) -> Void)?

    var tunnelFd: Int32? {
        var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))

        for fd: Int32 in 0 ... 1024 {
            var len = socklen_t(buf.count)

            if getsockopt(fd, 2 /* IGMP */, 2, &buf, &len) == 0 && String(cString: buf).hasPrefix("utun") {
                return fd
            }
        }

        return packetFlow.value(forKey: "socket.fileDescriptor") as? Int32
    }


    override init() {
        super.init()

        NSKeyedUnarchiver.setClass(CloseCircuitsMessage.self, forClassName:
            "iCepa.\(String(describing: CloseCircuitsMessage.self))")

        NSKeyedUnarchiver.setClass(GetCircuitsMessage.self, forClassName:
            "iCepa.\(String(describing: GetCircuitsMessage.self))")

        NSKeyedUnarchiver.setClass(CloseCircuitsMessage.self, forClassName:
            "iCepa_Mac.\(String(describing: CloseCircuitsMessage.self))")

        NSKeyedUnarchiver.setClass(GetCircuitsMessage.self, forClassName:
            "iCepa_Mac.\(String(describing: GetCircuitsMessage.self))")
    }


    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log("#startTunnel")

        let ipv4 = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]


        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: TorManager.localhost)
        settings.ipv4Settings = ipv4
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1"])

        log("#startTunnel before setTunnelNetworkSettings")

        setTunnelNetworkSettings(settings) { error in
            self.log("#startTunnel in setTunnelNetworkSettings callback")

            if let error = error {
                self.log("#startTunnel error=\(error)")
                return completionHandler(error)
            }

            let completion = { (error: Error?) -> Void in
                if let error = error {
                    return completionHandler(error)
                }

                self.startTun2Socks()

                self.log("#startTunnel successful")

                completionHandler(nil)
            }

            if Config.torInApp {
                completion(nil)
            }
            else {
                self.log("#startTunnel before start Tor thread")

                TorManager.shared.start({ progress in
                    BasePTProvider.messageQueue.append(ProgressMessage(Float(progress) / 100))
                    self.sendMessages()
                }, completion)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        log("#stopTunnel reason=\(reason)")

        stopTun2Socks()

        TorManager.shared.stop()

        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        let request = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(messageData)

        log("#handleAppMessage messageData=\(messageData), request=\(String(describing: request))")

        if request is GetCircuitsMessage {
            TorManager.shared.getCircuits { circuits in
                let response = try? NSKeyedArchiver.archivedData(
                    withRootObject: circuits, requiringSecureCoding: true)

                completionHandler?(response)
            }

            return
        }

        if let request = request as? CloseCircuitsMessage {
            TorManager.shared.close(request.circuits) { success in
                let response = try? NSKeyedArchiver.archivedData(
                    withRootObject: success, requiringSecureCoding: true)

                completionHandler?(response)
            }

            return
        }

        // Wait for progress updates.
        hostHandler = completionHandler
    }


    // MARK: Abstract Methods

    func startTun2Socks() {
        assertionFailure("Method needs to be implemented in subclass!")
    }

    func stopTun2Socks() {
        assertionFailure("Method needs to be implemented in subclass!")
    }


    // MARK: Private Methods

    @objc private func sendMessages() {
        DispatchQueue.main.async {
            if let handler = self.hostHandler {
                let response = try? NSKeyedArchiver.archivedData(
                    withRootObject: BasePTProvider.messageQueue,
                    requiringSecureCoding: true)

                BasePTProvider.messageQueue.removeAll()

                handler(response)

                self.hostHandler = nil
            }
        }
    }


    // MARK: Logging

    func log(_ message: String) {
        Logger.log(message, to: Logger.vpnLogfile)
    }
}
