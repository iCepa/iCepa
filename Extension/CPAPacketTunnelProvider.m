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

- (void)handleAppMessage:(NSData *)messageData completionHandler:(nullable void (^)(NSData * __nullable responseData))completionHandler {
    
}

- (void)startTunnelWithOptions:(nullable NSDictionary<NSString *,NSObject *> *)options completionHandler:(void (^)(NSError * __nullable error))completionHandler {
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.168.1.2"] subnetMasks:@[@"255.255.255.0"]];
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"8.8.8.8"];
    settings.IPv4Settings = ipv4Settings;
    settings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"192.168.1.2"]];
    
    __weak __typeof__(self) weakSelf = self;
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *error) {
        completionHandler(nil);
        
        __block __weak void (^weakHandler)(NSArray<NSData *> *, NSArray<NSNumber *> *) = nil;
        void (^handler)(NSArray<NSData *> *, NSArray<NSNumber *> *) = ^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
            tunif *interface = tunif_new();
            for (NSData *packet in packets) {
                NSLog(@"Packet! %@", packet);
                tunif_input_packet(interface, packet.bytes, packet.length);
            }
            tunif_free(interface);
            
            [weakSelf.packetFlow readPacketsWithCompletionHandler:weakHandler];
        };
        weakHandler = handler;
        handler(nil, nil);
    }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

@end
