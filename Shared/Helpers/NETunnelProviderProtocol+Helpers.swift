//
//  NETunnelProviderProtocol+Helpers.swift
//  iCepa
//
//  Created by Benjamin Erhart on 18.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

extension NETunnelProviderProtocol {

    enum Transport: Int, CustomStringConvertible, CaseIterable {
        case direct = 0
        case obfs4 = 1
        case snowflake = 2

        var description: String {
            switch self {
            case .obfs4:
                return NSLocalizedString("Tor + Obfs4", comment: "")

            case .snowflake:
                return NSLocalizedString("Tor + Snowflake", comment: "")

            default:
                return NSLocalizedString("Tor", comment: "")
            }
        }
    }

    var transport: Transport {
        get {
            guard let value = providerConfiguration?[String(describing: Transport.self)] as? NSNumber else {
                return .direct
            }

            return Transport(rawValue: value.intValue) ?? .direct
        }

        set {
            if (providerConfiguration == nil) {
                providerConfiguration = [:]
            }

            providerConfiguration?[String(describing: Transport.self)] = NSNumber(value: newValue.rawValue)
        }
    }
}
