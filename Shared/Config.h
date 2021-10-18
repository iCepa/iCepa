//
//  Config.h
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Config : NSObject

@property (class, nonatomic, assign, readonly, nonnull) NSString *extBundleId NS_REFINED_FOR_SWIFT;

@property (class, nonatomic, assign, readonly, nonnull) NSString *groupId NS_REFINED_FOR_SWIFT;

@property (class, readonly) BOOL torInApp;

@end

NS_ASSUME_NONNULL_END
