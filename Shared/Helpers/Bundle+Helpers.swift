//
//  Bundle+displayName.swift
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

public extension Bundle {

    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
            ?? ""
    }

	var version: String {
		return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
			?? "unknown"
	}
}
