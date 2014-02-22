//
//  CrittercismsUnity.h
//  CrittercismUnity
//
//  Created by Ben Bethel on 3/13/12.
//  Copyright (c) 2012 Flying Wisdom Studios. All rights reserved.
//

#import "Crittercism.h"

@interface CrittercismUnity : NSObject

+(void)initWithAppID:(NSString*)appID;
+(void)logHandledException:(NSException*)exception;

+(BOOL)isInited;
+(void)logUnhandledException:(NSException *)exception;
+(void)_callLogHandleException:(NSException*)exception;

//+(void)registerLocalSignalHandlers;

@end