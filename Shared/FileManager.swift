//
//  FileManager.swift
//  iCepa
//
//  Created by Conrad Kramer on 8/4/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import Foundation

extension FileManager {
    static var appGroupDirectory: URL {
        get {
            return self.default.containerURL(forSecurityApplicationGroupIdentifier: CPAAppGroupIdentifier)!
        }
    }
}
