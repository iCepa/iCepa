//
//  TorManager.swift
//  iCepa
//
//  Created by Benjamin Erhart on 17.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

class TorManager {

    private enum Errors: Error {
        case cookieUnreadable
    }

    static let shared = TorManager()

    static let localhost = "127.0.0.1"

    static let torProxyPort: UInt16 = 39050
    static let dnsPort: Int32 = 39053

    private static let torControlPort: UInt16 = 39060

    private var torThread: TorThread?

    private lazy var torConf: TorConfiguration = {
        let conf = TorConfiguration()

        let dataDirectory = FileManager.default.groupFolder?.appendingPathComponent("tor")

        if let dataDirectory = dataDirectory {
            // Need to clean out, so data doesn't grow too big. Otherwise
            // we get killed by Jetsam because Tor will use too much memory.
            try? FileManager.default.removeItem(at: dataDirectory)
        }

        conf.options = ["DNSPort": "\(TorManager.localhost):\(TorManager.dnsPort)",
                        "AutomapHostsOnResolve": "1",
                        "ClientOnly": "1",
//                        "HTTPTunnelPort": "\(PacketTunnelProvider.localhost):\(PacketTunnelProvider.torProxyPort)",
                        "SocksPort": "\(TorManager.torProxyPort)",
                        "ControlPort": "\(TorManager.localhost):\(TorManager.torControlPort)",
                        "AvoidDiskWrites": "1",
                        "MaxMemInQueues": "5MB" /* For reference, no impact seen so far */]

        conf.cookieAuthentication = true
        conf.dataDirectory = dataDirectory

        conf.arguments = [
            "--allow-missing-torrc",
            "--ignore-missing-torrc",
        ]

        return conf
    }()

    private var torController: TorController?

    private var torRunning: Bool {
        log("#torRunning 0")

        guard torThread?.isExecuting ?? false else {
            log("#torRunning 1")

            return false
        }

        log("#torRunning 2")

        if let lock = torConf.dataDirectory?.appendingPathComponent("lock") {
            log("#torRunning 3")

            return FileManager.default.fileExists(atPath: lock.path)
        }

        log("#torRunning 4")

        return false
    }

    private var cookie: Data? {
        if let cookieUrl = torConf.dataDirectory?.appendingPathComponent("control_auth_cookie") {
            return try? Data(contentsOf: cookieUrl)
        }

        return nil
    }

    private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)


    private init() {
        
    }

    func start(_ progressCallback: @escaping (Int) -> Void,
               _ completion: @escaping (Error?) -> Void)
    {
        if !torRunning {
            log("#startTunnel configure Tor thread")

            torThread = TorThread(configuration: self.torConf)

            log("#startTunnel start Tor thread")
            torThread?.start()
        }

        log("#startTunnel before dispatch")

        controllerQueue.asyncAfter(deadline: .now() + 0.65) {
            self.log("#startTunnel try to connect to Tor thread=\(String(describing: self.torThread))")

            if Logger.ENABLE_LOGGING {
                TORInstallTorLoggingCallback { (type: OSLogType, message: UnsafePointer<Int8>) in
                    let header: String

                    switch type {
//                        case .debug:
//                            header = "[debug] "

                    case .default:
                        header = "[default] "

                    case .error:
                        header = "[error] "

                    case .fault:
                        header = "[fault] "

                    case .info:
                        header = "[info] "

                    default:
                        return
                    }

                    Logger.log(header.appending(String(cString: message)),
                               to: Logger.torLogfile)
                }
            }

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
    }

    func getCircuits(_ completion: @escaping ([TorCircuit]) -> Void) {
        torController?.getCircuits(completion)
    }

    func close(_ circuits: [TorCircuit], _ completion: ((Bool) -> Void)?) {
        torController?.close(circuits, completion: completion)
    }

    private func log(_ message: String) {
        Logger.log(message, to: Logger.vpnLogfile)
    }
}
