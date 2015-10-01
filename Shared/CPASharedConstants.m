//
//  CPASharedConstants.m
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

#import "CPASharedConstants.h"

#define CPA_MACRO_STRING_(m) #m
#define CPA_MACRO_STRING(m) @CPA_MACRO_STRING_(m)

NSString * const CPAAppGroupIdentifier = CPA_MACRO_STRING(CPA_APPLICATION_GROUP);
NSString * const CPAExtensionBundleIdentifier = CPA_MACRO_STRING(CPA_EXTENSION_BUNDLE_IDENTIFIER);
