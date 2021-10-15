//
//  LeafPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 16.09.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 https://github.com/eycorsican/leaf.git
 */
class LeafPTProvider: BasePTProvider {

    private static let leafId: UInt16 = 666

    override func startTun2Socks() {
        var conf: String?

        if Config.torInApp {
            conf = FileManager.default.leafConfAppTemplate?
                .replacingOccurrences(of: "{{leafProxyPort}}", with: String(TorManager.leafProxyPort))
        }
        else {
            conf = FileManager.default.leafConfNeTemplate
        }

        conf = conf?.replacingOccurrences(of: "{{leafLogFile}}", with: FileManager.default.leafLogFile!.path)
            .replacingOccurrences(of: "{{tunFd}}", with: String(tunnelFd!))
            .replacingOccurrences(of: "{{torProxyPort}}", with: String(TorManager.torProxyPort))
            .replacingOccurrences(of: "{{dnsPort}}", with: String(TorManager.dnsPort))

        let file = FileManager.default.leafConfFile

        try! conf!.write(to: file!, atomically: true, encoding: .utf8)

        setenv("LOG_NO_COLOR", "true", 1)

        DispatchQueue.global(qos: .userInteractive).async {
            leaf_run(LeafPTProvider.leafId, file?.path)
        }
    }

    override func stopTun2Socks() {
        leaf_shutdown(LeafPTProvider.leafId)
    }
}
