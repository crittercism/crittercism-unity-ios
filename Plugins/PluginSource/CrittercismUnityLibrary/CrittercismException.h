//
//  CrittercismException.h
//  CrittercismUnityLibrary
//
//  Created by David Shirley 2 on 3/26/14.
//
//

#import <Foundation/Foundation.h>

@interface CrittercismException : NSException {
  NSString* mCallStack;
}

-(NSException*)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo callstack:(NSString*)stack;

- (NSArray *)callStackReturnAddresses;
- (NSArray *)callStackSymbols;

@end
