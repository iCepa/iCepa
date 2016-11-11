//
//  TunnelInterface.swift
//  iCepa
//
//  Created by Conrad Kramer on 10/3/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import os
import Foundation

class TunnelInterface {

    var interface: OpaquePointer!
    var callback: ((Data, UInt8) -> Void)
    
    init(callback: @escaping ((Data, UInt8) -> Void)) {
        self.callback = callback
        self.interface = tunif_new(Unmanaged.passUnretained(self).toOpaque()) { (context, bytes, len, proto) in
            guard let context = context,
                let bytes = bytes else { return }
            let tunif: TunnelInterface = Unmanaged.fromOpaque(context).takeUnretainedValue()
            tunif.callback(Data(bytesNoCopy: bytes, count: len, deallocator: .free), proto)
        }
    }
    
    deinit {
        tunif_free(interface)
    }
    
    func input(packet: Data) {
        tunif_input_packet(interface, (packet as NSData).bytes, packet.count)
    }
}
