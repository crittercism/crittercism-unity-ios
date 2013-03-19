//
//  CrittercismsUnity.h
//  CrittercismUnity
//
//  Created by Ben Bethel on 3/13/12.
//  Copyright (c) 2012 Flying Wisdom Studios. All rights reserved.
//

#import "Crittercism.h"

@interface CrittercismUnity

+(void)initWithAppID:(NSString*)appID;//andKey:(NSString*)key andSecret:(NSString*)secret;
+(void)logHandledException:(NSException*)exception;

//+(void)initWithAppData:(NSString*)appData;
+(BOOL)isInited;
+(void)logUnhandledException:(NSException *)exception;
+(void)_callLogHandleException:(NSException*)exception;

+(void)registerLocalSignalHandlers;

@end