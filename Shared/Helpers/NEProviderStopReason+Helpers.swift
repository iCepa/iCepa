//
//  NEProviderStopReason+Helpers.swift
//  iCepa
//
//  Created by Benjamin Erhart on 03.06.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation
import NetworkExtension

extension NEProviderStopReason: CustomStringConvertible {

    public var description: String {
        switch self {
        case .appUpdate:
            return "appUpdate"

        case .authenticationCanceled:
            return "authenticationCanceled"

        case .configurationDisabled:
            return "configurationDisabled"

        case .configurationFailed:
            return "configurationFailed"

        case .configurationRemoved:
            return "configurationRemoved"

        case .connectionFailed:
            return "connectionFailed"

        case .idleTimeout:
            return "idleTimeout"

        case .none:
            return "none"

        case .noNetworkAvailable:
            return "noNetworkAvailable"

        case .providerDisabled:
            return "providerDisabled"

        case .providerFailed:
            return "providerFailed"

        case .sleep:
            return "sleep"

        case .superceded:
            return "superceded"

        case .unrecoverableNetworkChange:
            return "unrecoverableNetworkChange"

        case .userInitiated:
            return "userInitiated"

        case .userLogout:
            return "userLogout"

        case .userSwitch:
            return "userSwitch"

        @unknown default:
            return "unknown"
        }
    }
}
