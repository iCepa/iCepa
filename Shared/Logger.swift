//
//  Logger.swift
//  iCepa
//
//  Created by Benjamin Erhart on 17.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

class Logger {

    static let ENABLE_LOGGING = true

    static var vpnLogfile: URL? = {
        if let url = FileManager.default.vpnLogFile {
            // Reset log on first write.
            try? "".write(to: url, atomically: true, encoding: .utf8)

            return url
        }

        return nil
    }()

    static var torLogfile: URL? = {
        if let url = FileManager.default.torLogFile {
            // Reset log on first write.
            try? "".write(to: url, atomically: true, encoding: .utf8)

            return url
        }

        return nil
    }()

    static func log(_ message: String, to: URL?) {
        guard ENABLE_LOGGING,
            let url = to,
            let data = message.trimmingCharacters(in: .whitespacesAndNewlines).appending("\n").data(using: .utf8),
            let fh = try? FileHandle(forUpdating: url) else {
                return
        }

        defer {
            fh.closeFile()
        }

        fh.seekToEndOfFile()
        fh.write(data)
    }
}
