//
//  CrittercismException.m
//  CrittercismUnityLibrary
//
//  Created by David Shirley 2 on 3/26/14.
//
//

#import "CrittercismException.h"

@implementation CrittercismException

-(NSException*)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo callstack:(NSString*)stack
{
  if (self = [super initWithName:name reason:reason userInfo:userInfo])
  {
    mCallStack  = stack;
  }
  
  return self;
}

- (NSArray *)callStackReturnAddresses
{
  NSArray *arr    = NULL;
  if (arr == NULL || [arr count] == 0) {
    arr = [super callStackReturnAddresses];
  }
  
  return arr;
}

- (NSArray *)callStackSymbols
{
  NSArray *arr = NULL;
  
  if (mCallStack != NULL) {
    NSLog(@"Callstack: %@",mCallStack);
    arr = [mCallStack componentsSeparatedByString:@"\n"];
  }
  
  if (arr == NULL || [arr count] == 0) {
    arr = [super callStackSymbols];
  }
  
  return arr;
}

@end