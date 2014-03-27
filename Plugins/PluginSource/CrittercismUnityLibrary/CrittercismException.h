//
//  CrittercismException.h
//  CrittercismUnityLibrary
//
//  Created by David Shirley on 3/26/14.
//  Copyright (c) 2014 Crittercism. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrittercismException : NSException {
  NSString* mCallStack;
}

-(NSException*)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo callstack:(NSString*)stack;

- (NSArray *)callStackReturnAddresses;
- (NSArray *)callStackSymbols;

@end
