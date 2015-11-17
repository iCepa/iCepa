//
//  TunnelInterface.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import Foundation

class TunnelInterface {
    let interface: COpaquePointer
    var packetCallback: ((NSData) -> Void)? {
        didSet {
            if let _ = packetCallback {
                tunif_set_packet_callback(interface, unsafeBitCast(self, UnsafeMutablePointer<Void>.self)) { (tunif, context, bytes, len) -> Void in
                    unsafeBitCast(context, TunnelInterface.self).packetCallback!(NSData(bytes: bytes, length: len))
                }
            } else {
                tunif_set_packet_callback(interface, nil, nil)
            }
        }
    }
    
    init() {
        var onceToken: dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            let client = asl_open(nil, "com.apple.console", 0)
            asl_log_descriptor(client, nil, ASL_LEVEL_NOTICE, STDOUT_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
            asl_log_descriptor(client, nil, ASL_LEVEL_ERR, STDERR_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
            asl_close(client)
        }
        
        interface = tunif_new()
    }
    
    deinit {
        tunif_free(interface)
    }
    
    func inputPacket(data: NSData) {
        tunif_input_packet(interface, data.bytes, data.length)
    }
}
