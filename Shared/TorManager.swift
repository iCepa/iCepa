//
//  TorManager.swift
//  iCepa
//
//  Created by Benjamin Erhart on 17.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

#if os(iOS)
import IPtProxy
#endif


class TorManager {

    private enum Errors: Error {
        case cookieUnreadable
    }

    static let shared = TorManager()

    static let localhost = "127.0.0.1"

    static let torProxyPort: UInt16 = 39050
    static let dnsPort: UInt16 = 39053
    static let leafProxyPort: UInt16 = 39080

    private static let torControlPort: UInt16 = 39060

    private var torThread: TorThread?

    private var torController: TorController?

    private var torConf: TorConfiguration?

    private var torRunning: Bool {
        log("#torRunning 0")

        guard torThread?.isExecuting ?? false else {
            log("#torRunning 1")

            return false
        }

        log("#torRunning 2")


        if let lock = torConf?.dataDirectory?.appendingPathComponent("lock") {
            log("#torRunning 3")

            return FileManager.default.fileExists(atPath: lock.path)
        }

        log("#torRunning 4")

        return false
    }

    private var cookie: Data? {
        if let cookieUrl = torConf?.dataDirectory?.appendingPathComponent("control_auth_cookie") {
            return try? Data(contentsOf: cookieUrl)
        }

        return nil
    }

    private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)


    private init() {
        
    }

    func start(_ transport: NETunnelProviderProtocol.Transport,
               _ port: Int? = nil,
               _ progressCallback: @escaping (Int) -> Void,
               _ completion: @escaping (Error?) -> Void)
    {
        if !torRunning {
            log("#startTunnel configure Tor thread")

            torConf = getTorConf(transport, port)

            torThread = TorThread(configuration: torConf)

            log("#startTunnel start Tor thread")
            torThread?.start()
        }

        log("#startTunnel before dispatch")

        controllerQueue.asyncAfter(deadline: .now() + 0.65) {
            self.log("#startTunnel try to connect to Tor thread=\(String(describing: self.torThread))")

            if self.torController == nil {
                self.torController = TorController(
                    socketHost: TorManager.localhost,
                    port: TorManager.torControlPort)
            }

            if !(self.torController?.isConnected ?? false) {
                do {
                    try self.torController?.connect()
                }
                catch let error {
                    self.log("#startTunnel error=\(error)")

                    return completion(error)
                }
            }

            guard let cookie = self.cookie else {
                self.log("#startTunnel cookie unreadable")

                return completion(Errors.cookieUnreadable)
            }

            self.torController?.authenticate(with: cookie) { success, error in
                if let error = error {
                    self.log("#startTunnel error=\(error)")

                    return completion(error)
                }

                var progressObs: Any?
                progressObs = self.torController?.addObserver(forStatusEvents: {
                    (type, severity, action, arguments) -> Bool in

                    if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
                        let progress = Int(arguments!["PROGRESS"]!)!
                        self.log("#startTunnel progress=\(progress)")

                        progressCallback(progress)

                        if progress >= 100 {
                            self.torController?.removeObserver(progressObs)
                        }

                        return true
                    }

                    return false
                })

                var observer: Any?
                observer = self.torController?.addObserver(forCircuitEstablished: { established in
                    guard established else {
                        return
                    }

                    self.torController?.removeObserver(observer)

                    completion(nil)
                })
            }
        }
    }

    func stop() {
        torController?.disconnect()
        torController = nil

        torThread?.cancel()
        torThread = nil

        torConf = nil
    }

    func getCircuits(_ completion: @escaping ([TorCircuit]) -> Void) {
        torController?.getCircuits(completion)
    }

    func close(_ circuits: [TorCircuit], _ completion: ((Bool) -> Void)?) {
        torController?.close(circuits, completion: completion)
    }


    // MARK: Private Methods

    private func log(_ message: String) {
        Logger.log(message, to: Logger.vpnLogfile)
    }

    private func getTorConf(_ transport: NETunnelProviderProtocol.Transport, _ port: Int?) -> TorConfiguration {
        let conf = TorConfiguration()

        let dataDirectory = FileManager.default.groupFolder?.appendingPathComponent("tor")

        // Should not be needed anymore with 50 MB RAM limit.
//        if let dataDirectory = dataDirectory {
//            // Need to clean out, so data doesn't grow too big. Otherwise
//            // we get killed by Jetsam because Tor will use too much memory.
//            try? FileManager.default.removeItem(at: dataDirectory)
//        }

        conf.options = [
            // DNS
            "DNSPort": "\(TorManager.localhost):\(TorManager.dnsPort)",
            "AutomapHostsOnResolve": "1",
            // By default, localhost resp. link-local addresses will be returned by Tor.
            // That seems to not get accepted by iOS. Use private network addresses instead.
            "VirtualAddrNetworkIPv4": "10.192.0.0/10",
            "VirtualAddrNetworkIPv6": "[FC00::]/7",

            // Log
            "Log": "[~circ,~guard]info stdout",
            "LogMessageDomains": "1",
            "SafeLogging": "0",

            // Ports
            "SocksPort": "\(TorManager.localhost):\(TorManager.torProxyPort)",
            "ControlPort": "\(TorManager.localhost):\(TorManager.torControlPort)",

            // Miscelaneous
            "ClientOnly": "1",
            "AvoidDiskWrites": "1",
            "MaxMemInQueues": "5MB"]

        if Config.torInApp && transport == .direct {
            conf.options["Socks5Proxy"] = "\(TorManager.localhost):\(TorManager.leafProxyPort)"
        }

#if os(iOS)
        if transport == .obfs4 {
            conf.options["ClientTransportPlugin"] = "obfs4 socks5 \(TorManager.localhost):\(port ?? IPtProxyObfs4Port())"
            conf.options["UseBridges"] = "1"

            conf.arguments += [
                "--Bridge", "obfs4 192.95.36.142:443 CDF2E852BF539B82BD10E27E9115A31734E378C2 cert=qUVQ0srL1JI/vO6V6m/24anYXiJD3QP2HgzUKQtQ7GRqqUvs7P+tG43RtAqdhLOALP7DJQ iat-mode=1",
                "--Bridge", "obfs4 38.229.1.78:80 C8CBDB2464FC9804A69531437BCF2BE31FDD2EE4 cert=Hmyfd2ev46gGY7NoVxA9ngrPF2zCZtzskRTzoWXbxNkzeVnGFPWmrTtILRyqCTjHR+s9dg iat-mode=1",
                "--Bridge", "obfs4 38.229.33.83:80 0BAC39417268B96B9F514E7F63FA6FBA1A788955 cert=VwEFpk9F/UN9JED7XpG1XOjm/O8ZCXK80oPecgWnNDZDv5pdkhq1OpbAH0wNqOT6H6BmRQ iat-mode=1",
                "--Bridge", "obfs4 37.218.245.14:38224 D9A82D2F9C2F65A18407B1D2B764F130847F8B5D cert=bjRaMrr1BRiAW8IE9U5z27fQaYgOhX1UCmOpg2pFpoMvo6ZgQMzLsaTzzQNTlm7hNcb+Sg iat-mode=0",
                "--Bridge", "obfs4 85.31.186.98:443 011F2599C0E9B27EE74B353155E244813763C3E5 cert=ayq0XzCwhpdysn5o0EyDUbmSOx3X/oTEbzDMvczHOdBJKlvIdHHLJGkZARtT4dcBFArPPg iat-mode=0",
                "--Bridge", "obfs4 85.31.186.26:443 91A6354697E6B02A386312F68D82CF86824D3606 cert=PBwr+S8JTVZo6MPdHnkTwXJPILWADLqfMGoVvhZClMq/Urndyd42BwX9YFJHZnBB3H0XCw iat-mode=0",
                "--Bridge", "obfs4 144.217.20.138:80 FB70B257C162BF1038CA669D568D76F5B7F0BABB cert=vYIV5MgrghGQvZPIi1tJwnzorMgqgmlKaB77Y3Z9Q/v94wZBOAXkW+fdx4aSxLVnKO+xNw iat-mode=0",
                "--Bridge", "obfs4 193.11.166.194:27015 2D82C2E354D531A68469ADF7F878FA6060C6BACA cert=4TLQPJrTSaDffMK7Nbao6LC7G9OW/NHkUwIdjLSS3KYf0Nv4/nQiiI8dY2TcsQx01NniOg iat-mode=0",
                "--Bridge", "obfs4 193.11.166.194:27020 86AC7B8D430DAC4117E9F42C9EAED18133863AAF cert=0LDeJH4JzMDtkJJrFphJCiPqKx7loozKN7VNfuukMGfHO0Z8OGdzHVkhVAOfo1mUdv9cMg iat-mode=0",
                "--Bridge", "obfs4 193.11.166.194:27025 1AE2C08904527FEA90C4C4F8C1083EA59FBC6FAF cert=ItvYZzW5tn6v3G4UnQa6Qz04Npro6e81AP70YujmK/KXwDFPTs3aHXcHp4n8Vt6w/bv8cA iat-mode=0",
                "--Bridge", "obfs4 209.148.46.65:443 74FAD13168806246602538555B5521A0383A1875 cert=ssH+9rP8dG2NLDN2XuFw63hIO/9MNNinLmxQDpVa+7kTOa9/m+tGWT1SmSYpQ9uTBGa6Hw iat-mode=0",
                "--Bridge", "obfs4 146.57.248.225:22 10A6CD36A537FCE513A322361547444B393989F0 cert=K1gDtDAIcUfeLqbstggjIw2rtgIKqdIhUlHp82XRqNSq/mtAjp1BIC9vHKJ2FAEpGssTPw iat-mode=0",
                "--Bridge", "obfs4 45.145.95.6:27015 C5B7CD6946FF10C5B3E89691A7D3F2C122D2117C cert=TD7PbUO0/0k6xYHMPW3vJxICfkMZNdkRrb63Zhl5j9dW3iRGiCx0A7mPhe5T2EDzQ35+Zw iat-mode=0",
                "--Bridge", "obfs4 [2a0c:4d80:42:702::1]:27015 C5B7CD6946FF10C5B3E89691A7D3F2C122D2117C cert=TD7PbUO0/0k6xYHMPW3vJxICfkMZNdkRrb63Zhl5j9dW3iRGiCx0A7mPhe5T2EDzQ35+Zw iat-mode=0",
                "--Bridge", "obfs4 51.222.13.177:80 5EDAC3B810E12B01F6FD8050D2FD3E277B289A08 cert=2uplIpLQ0q9+0qMFrK5pkaYRDOe460LL9WHBvatgkuRr/SL31wBOEupaMMJ6koRE6Ld0ew iat-mode=0"]
        }
        else if transport == .snowflake {
            conf.options["ClientTransportPlugin"] = "snowflake socks5 127.0.0.1:\(port ?? IPtProxySnowflakePort())"
            conf.options["UseBridges"] = "1"
            conf.options["Bridge"] = "snowflake 192.0.2.3:1 2B280B23E1107BB62ABFC40DDCC8824814F80A72"
        }
#endif

        conf.cookieAuthentication = true
        conf.dataDirectory = dataDirectory

        conf.arguments += [
            "--allow-missing-torrc",
            "--ignore-missing-torrc",
        ]

        if Logger.ENABLE_LOGGING,
           let logfile = Logger.torLogfile?.path
        {
            conf.arguments += ["--Log", "[~circ,~guard]info file \(logfile)"]
        }

        return conf
    }
}
