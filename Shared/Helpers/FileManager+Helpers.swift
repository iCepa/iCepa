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

	var logfile: URL? {
		return groupFolder?.appendingPathComponent("log")
	}

	var log: String? {
		if let logfile = logfile {
			return try? String(contentsOf: logfile)
		}

		return nil
	}
}
