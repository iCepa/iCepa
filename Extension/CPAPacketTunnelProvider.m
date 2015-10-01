//
//  CPAPacketTunnelProvider.m
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

#import "CPAPacketTunnelProvider.h"
#import "CPASharedConstants.h"

#import "tun2tor.h"

@interface CPAPacketTunnelProvider ()

@property (readonly) NETunnelProviderProtocol *protocolConfiguration;

@end

@implementation CPAPacketTunnelProvider

@dynamic protocolConfiguration;

+ (void)load {
    NSLog(@"STARTING");
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(nullable void (^)(NSData * __nullable responseData))completionHandler {
    
}

- (void)startTunnelWithOptions:(nullable NSDictionary<NSString *,NSObject *> *)options completionHandler:(void (^)(NSError * __nullable error))completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler(nil);
        
        __block __weak void (^weakHandler)(NSArray<NSData *> *, NSArray<NSNumber *> *) = nil;
        void (^handler)(NSArray<NSData *> *, NSArray<NSNumber *> *) = ^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
            tunif *interface = tunif_new();
            for (NSData *packet in packets) {
                tunif_input_packet(interface, packet.bytes, packet.length);
            }
            tunif_free(interface);
            
            [self.packetFlow readPacketsWithCompletionHandler:weakHandler];
        };
        weakHandler = handler;
        
        [self.packetFlow readPacketsWithCompletionHandler:handler];
    });
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

@end
