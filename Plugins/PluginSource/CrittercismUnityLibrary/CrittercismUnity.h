//
//  CrittercismsUnity.h
//  CrittercismUnity
//
//  Edited by Eddie Freeman
//  Copyright (c) 2014 Crittercism. All rights reserved.
//

#import "Crittercism.h"

@interface CrittercismUnity : NSObject

+(void)initWithAppID:(NSString*)appID;
+(void)logHandledException:(NSException*)exception;

+ (BOOL)isInited;
+ (void)logUnhandledException:(NSException *)exception;
+ (void)_callLogHandleException:(NSException*)exception;

@end