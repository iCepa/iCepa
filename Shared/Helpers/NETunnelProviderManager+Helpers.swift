//
//  NETunnelProviderManager+Helpers.swift
//  iCepa
//
//  Created by Benjamin Erhart on 18.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

extension NETunnelProviderManager {

    var transport: NETunnelProviderProtocol.Transport {
        get {
            return (protocolConfiguration as? NETunnelProviderProtocol)?.transport ?? .direct
        }
        set {
            (protocolConfiguration as? NETunnelProviderProtocol)?.transport = newValue
        }
    }
}
