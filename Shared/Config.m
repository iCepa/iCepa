//
//  Config.m
//  iCepa
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

#import "Config.h"

#define MACRO_STRING_(m) #m
#define MACRO_STRING(m) @MACRO_STRING_(m)

@implementation Config

+ (NSString *) extBundleId {
    return MACRO_STRING(EXT_BUNDLE_ID);
}

+ (NSString *) groupId {
    return MACRO_STRING(APP_GROUP);
}

@end
