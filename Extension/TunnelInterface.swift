//
//  TunnelInterface.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import Foundation

class TunnelInterface {
    private static var asl: asl_object_t! = {
        let client = asl_open(nil, "com.apple.console", 0)
        asl_log_descriptor(client, nil, ASL_LEVEL_NOTICE, STDOUT_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
        asl_log_descriptor(client, nil, ASL_LEVEL_ERR, STDERR_FILENO, UInt32(ASL_LOG_DESCRIPTOR_WRITE))
        asl_close(client)
        return client
    }()
    
    let interface: OpaquePointer
    var callback: ((Data, NSNumber) -> Void)? {
        didSet {
            if let _ = callback {
                tunif_set_packet_callback(interface, unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self)) { (tunif, context, bytes, len, proto) -> Void in
                    unsafeBitCast(context, to: TunnelInterface.self).callback!(Data(bytes: UnsafePointer<UInt8>(bytes!), count: len), NSNumber(value: proto))
                }
            } else {
                tunif_set_packet_callback(interface, nil, nil)
            }
        }
    }
    
    init() {
        let _ = TunnelInterface.asl
        interface = tunif_new()
    }
    
    deinit {
        tunif_free(interface)
    }
    
    func input(packet: Data) {
        tunif_input_packet(interface, (packet as NSData).bytes, packet.count)
    }
}
