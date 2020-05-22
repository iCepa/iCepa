//
//  FileManager+Helpers.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

extension FileManager {

	var groupFolder: URL? {
		return containerURL(forSecurityApplicationGroupIdentifier: Config.groupId)
	}

	var vpnLogfile: URL? {
		return groupFolder?.appendingPathComponent("log")
	}

    var torLogfile: URL? {
        return groupFolder?.appendingPathComponent("tor.log")
    }

	var vpnLog: String? {
		if let logfile = vpnLogfile {
			return try? String(contentsOf: logfile)
		}

		return nil
	}

    var torLog: String? {
        if let logfile = torLogfile {
            return try? String(contentsOf: logfile)
        }

        return nil
    }
}
