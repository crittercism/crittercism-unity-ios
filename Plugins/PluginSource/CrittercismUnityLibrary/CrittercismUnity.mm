//
//  CrittercismUnity.mm
//  CrittercismUnity
//
//  Created by Ben Bethel on 3/13/12.
//  Copyright (c) 2012 Flying Wisdom Studios. All rights reserved.
//
#import <fstream>

#define VERSION_3
//#define VERSION_2
//#define DEBUG_LOGS
#define CUSTOM_EXCEPTION
#import "Crittercism.h"
#import "CrittercismUnity.h"
#import "CrittercismExtern.h"

#ifdef DEBUG_LOGS
#define DEBUG_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DEBUG_LOG(...)
#endif

void signal_handler(int idn);   //  Prototype, just to kill the warning

@interface NSString (StringByDecodingURLFormat)
- (NSString *)stringByDecodingURLFormat;
@end

@implementation NSString (StringByDecodingURLFormat)
- (NSString *)stringByDecodingURLFormat
{
  NSString *result = [(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  return [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
@end


#ifdef CUSTOM_EXCEPTION
@interface CrittercismException : NSException {
  NSString* mCallStack;
}

-(NSException*)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo callstack:(NSString*)stack;

- (NSArray *)callStackReturnAddresses;
- (NSArray *)callStackSymbols;

@end



@implementation CrittercismException

-(NSException*)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo callstack:(NSString*)stack
{
  DEBUG_LOG(@"CrittercismException: ctor(), %@, %@, %@", name, reason, stack);

  if (self = [super initWithName:name reason:reason userInfo:userInfo])
  {   mCallStack  = stack;    }
  
  DEBUG_LOG(@"CrittercismException: ctor() done");
  return self;
}

- (NSArray *)callStackReturnAddresses
{
  DEBUG_LOG(@"CrittercismException: callStackReturnAddresses");

  NSArray *arr    = NULL;
  if (arr == NULL || [arr count] == 0) {
    arr = [super callStackReturnAddresses];
  }
  
  return arr;
}

- (NSArray *)callStackSymbols
{
  DEBUG_LOG(@"CrittercismException: callStackReturnAddresses");
  
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

#endif



@interface PerformExceptionHandler : NSObject

+ (void) PerformException:(NSException *)e;

@end

@implementation PerformExceptionHandler

+ (void)PerformException:(NSException *)e
{
  PerformExceptionHandler *handler = [[[PerformExceptionHandler alloc]init] autorelease];
  
  [handler performSelectorOnMainThread:@selector(_PerformHandledExceptionOnMainThread:)
                            withObject:e waitUntilDone:TRUE];
}

- (void)_PerformHandledExceptionOnMainThread:(NSException*)e
{
  [CrittercismUnity _callLogHandleException:e];
}

@end


@interface CrittercismDataGenerator : NSObject
{
  NSException *mException;
  NSString *mExceptionName;
  NSString *mExceptionDescription;
  NSString *mCallStack;
  NSMutableDictionary *mExceptionDetails;
  
  NSString *mLogName;
  NSMutableDictionary *mLogData;
}

- (void)NewException;
- (NSException*)GetException;

- (void)SetExceptionName:(NSString*)name;
- (void)SetExceptionDescription:(NSString*)desc;
- (void)AddExceptionInformation:(NSString*)information key:(NSString*)key;


- (void)performInit:(NSString*)app;

- (void)NewLog:(NSString*)logName;
- (void)AddLogValue:(NSString*)val key:(NSString*)key;
- (void)FinalizeLog;

- (void)SaveLastException;
- (void)SendLastException;

@end

static CrittercismDataGenerator* _ExceptionGenerator  = NULL;

@implementation CrittercismDataGenerator

NSString *_LAST_FILE_PATH  = @"CrittercismLastException.plist";

-(void)NewException
{
  if (mException)   {  [mException release];   }
  mException      = NULL;
  
  if (mExceptionName)  {   [mExceptionName release];   }
  mExceptionName  = NULL;
  if (mCallStack)  {   [mExceptionName release];   }
  mCallStack  = NULL;
  if (mExceptionDescription)   {   [mExceptionDescription release];    }
  mExceptionDescription   = NULL;
  if (mExceptionDetails)   {   [mExceptionDetails release];    }
  mExceptionDetails   = NULL;
}

-(void)SetExceptionName:(NSString*)name
{
  if (mExceptionName)   {   [mExceptionName release];    }
  mExceptionName   = [[NSString alloc] initWithString:[name stringByDecodingURLFormat]];
}

-(void)SetExceptionStack:(NSString*)stack
{
  if (mCallStack)   {   [mCallStack release];    }
  mCallStack   = [[NSString alloc] initWithString:[stack stringByDecodingURLFormat]];
}

-(void)SetExceptionDescription:(NSString*)desc
{
  if (mExceptionDescription)   {   [mExceptionDescription release];    }
  mExceptionDescription   = [[NSString alloc] initWithString:[desc stringByDecodingURLFormat]];
}

-(void)AddExceptionInformation:(NSString*)information key:(NSString*)key
{
  if (mExceptionDetails == NULL)   {   mExceptionDetails   = [[NSMutableDictionary alloc]init];    }
  [mExceptionDetails setObject:[information stringByDecodingURLFormat] forKey:key];
}

-(NSException*)GetException
{
  if (mException == NULL)
  {
#ifdef CUSTOM_EXCEPTION
    mException  = [[CrittercismException alloc]initWithName:mExceptionName
                                                     reason:mExceptionDescription
                                                   userInfo: nil
                                                  callstack:mCallStack];
#else
    mException  = [[NSException alloc]initWithName:mExceptionName
                                            reason:[NSString stringWithFormat:@"%@\n%@", mExceptionDescription, mCallStack]
                                          userInfo:mExceptionDetails];
#endif
  }
  return mException;
}

-(void)performInit_Main:(NSArray*)arr
{
  [Crittercism enableWithAppID:[arr objectAtIndex:0] ];
}

-(void)performInit:(NSString*)app
{
  NSArray *arr    = [[[NSArray alloc]initWithObjects:app,
                      nil,nil,nil] autorelease];
  
  [self performSelectorOnMainThread:@selector(performInit_Main:) withObject:arr waitUntilDone:TRUE];
}


-(void)NewLog:(NSString*)logName
{
  if (mLogName != NULL)    {   [mLogName release]; }
  mLogName    = NULL;
  
  if (mLogData != NULL)    {   [mLogData release]; }
  mLogData    = NULL;
  
  if (logName == NULL) {   return; }
  
  mLogName    = [[NSString alloc]initWithString:logName];
  mLogData    = [[NSMutableDictionary alloc]init];
}

-(void)AddLogValue:(NSString*)val key:(NSString*)key
{
  if (val == NULL || key == NULL || mLogData == NULL)  {   return; }
  [mLogData setValue:val forKey:key];
}

-(void)FinalizeLog
{
  if (mLogName == NULL)    {   return; }
  
  //[Crittercism logEvent:mLogName andEventDict:mLogData];
  [mLogName release];
  mLogName    = NULL;
  [mLogData release];
  mLogData    = NULL;
}


-(void)writeString:(NSString*)str file:(FILE*)file
{
  //  Write out the description
  int nCount  = [str length];
  const char *pWriteString = [str UTF8String];
  
  fwrite((char*)&nCount, 4, 1, file);
  
  if (pWriteString != NULL && nCount != 0)
  {
    int nWrittenLength  = 0;
    while(nWrittenLength < nCount)
    {
      int nWrite  = fwrite(pWriteString, sizeof(char), nCount - nWrittenLength, file);
      if (nWrite <= 0) {   break;  }
      nWrittenLength += nWrite;
    }
  }
}

-(NSString*)readString:(FILE*)file
{
  int nCount  = 0;
  fread((char*)&nCount, 4, 1, file);
  if (nCount == 0) {   return NULL;   }
  
  char* mArray    = (char*)malloc(sizeof(char) * (nCount + 1));
  
  int nReadLength = 0;
  while(nReadLength < nCount)
  {
    int nRead   = fread(mArray + nReadLength, sizeof(char), nCount - nReadLength, file);
    if (nRead <= 0)  {   break;  }
    nReadLength += nRead;
  }
  
  mArray[nCount] = 0;
  
  
  NSString * str  = [[NSString alloc] initWithUTF8String:mArray];
  free(mArray);
  return str;
}


-(void)SaveLastException
{
  try
  {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *pathString    = [cachePath stringByAppendingPathComponent:_LAST_FILE_PATH];
    if ([fileManager fileExistsAtPath:pathString]) {
      [fileManager removeItemAtPath:pathString error:NULL];
    }
    
#ifdef  USE_C_SAVE
    FILE* file  = fopen([pathString UTF8String] , "wb+");
    if (file != NULL)
    {
      //  Write out the description, name and stack
      [self writeString:mExceptionDescription file:file];
      [self writeString:mExceptionName file:file];
      [self writeString:mCallStack file:file];
      
      //  Close the fie
      fclose(file);
      file    = NULL;
    }
#else
    
    NSMutableDictionary *exceptionData  = [[NSMutableDictionary alloc]init];
    
    if (mExceptionDescription != NULL) {
      [exceptionData setObject:mExceptionDescription forKey:@"Description"];
    }
    
    if (mExceptionDetails != NULL) {
      [exceptionData setObject:mExceptionDetails forKey:@"Details"];
    }
    
    if (mExceptionName != NULL) {
      [exceptionData setObject:mExceptionName forKey:@"Name"];
    }
    
    if (mCallStack != NULL) {
      [exceptionData setObject:mCallStack forKey:@"CallStack"];
    }
    
    [exceptionData writeToFile:pathString atomically:TRUE];
    [exceptionData release];
    
#endif
  } catch(NSException* e) {
    DEBUG_LOG(@"CrittercismException: SaveLastException: Error: %@", [e reason]);
  }
}

-(void)SendLastException
{
  if (![CrittercismUnity isInited ]) {
    return;
  }
  
  try {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *pathString  = [cachePath stringByAppendingPathComponent:_LAST_FILE_PATH];
    if ([fileManager fileExistsAtPath:pathString]) {
      
#ifdef  USE_C_SAVE
      FILE* file  = fopen([pathString UTF8String] , "wb+");
      if (file != NULL) {
        mExceptionDescription = [self readString:file];
        mExceptionName = [self readString:file];
        mCallStack = [self readString:file];
        
        [CrittercismUnity logUnhandledException:[self GetException]];
      }
#else
      NSMutableDictionary *exceptionData = [[NSMutableDictionary alloc]initWithContentsOfFile:pathString];
      
      mExceptionDescription = [exceptionData objectForKey:@"Description"];
      if (mExceptionDescription != NULL) {
        mExceptionDescription = [[NSString alloc]
                                 initWithString:mExceptionDescription];
      }
      
      mExceptionDetails = [exceptionData objectForKey:@"Details"];
      if (mExceptionDetails != NULL) {
        mExceptionDetails  = [[NSMutableDictionary alloc]
                              initWithDictionary:mExceptionDetails];
      }
      
      mExceptionName = [exceptionData objectForKey:@"Name"];
      if (mExceptionName != NULL) {
        mExceptionName = [[NSString alloc] initWithString:mExceptionName];
      }
      
      mCallStack = [exceptionData objectForKey:@"CallStack"];
      if (mCallStack != NULL) {
        mCallStack = [[NSString alloc] initWithString:mCallStack];
      }
      
      [fileManager removeItemAtPath:pathString error:NULL];
      [exceptionData release];
      
      [CrittercismUnity logUnhandledException:[self GetException]];
#endif
    }
  } catch(NSException *e) {
    DEBUG_LOG(@"CrittercismException: SendLastException: Error: %@", [e reason]);
  }
}

@end

void Crittercism_EnableWithAppID(const char* appID)
{
  NSString *str_appID = NULL;
  if (appID != NULL) {
    str_appID = [NSString stringWithUTF8String:appID];
  }

  [CrittercismUnity initWithAppID:str_appID];
}

bool Crittercism_IsInited()	{
  return [CrittercismUnity isInited];
}

void Crittercism_LogUnhandledExceptionWillCrash()
{
	DEBUG_LOG(@"Crittercism_LogUnhandledExceptionWillCrash");
  
  if (_ExceptionGenerator == NULL) {
    return;
  }
  
  [_ExceptionGenerator SaveLastException];
  
  NSException *e  = [_ExceptionGenerator GetException];
  [CrittercismUnity logHandledException:e];
}

void Crittercism_LogHandledException()
{
	DEBUG_LOG(@"Crittercism_LogHandledException");
	
  if (_ExceptionGenerator == NULL) {
    return;
  }
  
  [_ExceptionGenerator SaveLastException];
  
  NSException *e  = [_ExceptionGenerator GetException];
  [CrittercismUnity logHandledException:e];
}

void Crittercism_LogUnhandledException()
{
	DEBUG_LOG(@"Crittercism_LogUnhandledException");
	
	if (_ExceptionGenerator == NULL) {
    return;
  }
  
  [_ExceptionGenerator SaveLastException];
  
  NSException *e  = [_ExceptionGenerator GetException];
  [CrittercismUnity logUnhandledException:e];
}

void Crittercism_NewException(const char* name,
                              const char* reason,
                              const char *stack)
{
	DEBUG_LOG(@"Crittercism_NewException");
	
  if (_ExceptionGenerator == NULL) {
    _ExceptionGenerator = [[CrittercismDataGenerator alloc]init];
  }
  
  [_ExceptionGenerator NewException];
  
  NSString *str_name  = @"";
  if (name != NULL) {
    str_name = [NSString stringWithUTF8String:name];
  }
  
  NSString *str_reason = @"";
  if (reason != NULL) {
    str_reason  = [NSString stringWithUTF8String:reason];
  }
  
  NSString *str_stack  = @"";
  if (stack != NULL) {
    str_stack = [NSString stringWithUTF8String:stack];
  }
  
  [_ExceptionGenerator SetExceptionName:str_name];
  [_ExceptionGenerator SetExceptionDescription:str_reason];
  [_ExceptionGenerator SetExceptionStack:str_stack];
}

void Crittercism_LeaveBreadcrumb(const char* breadcrumb)
{
  if (breadcrumb == NULL || ![CrittercismUnity isInited])  {   return; }
  
  @try {
    NSString *crumb   = [NSString stringWithCString:breadcrumb encoding:NSUTF8StringEncoding];
    crumb   = [crumb stringByDecodingURLFormat];
    [Crittercism  leaveBreadcrumb:crumb];
  } @catch (NSException *e) { }
}

void Crittercism_SetAsyncBreadcrumbMode(bool writeAsync)
{
  if (![CrittercismUnity isInited]) {
    return;
  }
  
  @try {
    [Crittercism setAsyncBreadcrumbMode:writeAsync];
  } @catch (NSException *e) { }
}

// Don't currently support this for C# scripts in Unity
const char* Crittercism_GetUserUUID()
{
  //return (char*)[Crittercism getUserUUID];
  return "";
}

void Crittercism_SetUsername(const char* username)
{
  if (![CrittercismUnity isInited] || username == NULL) {
    return;
  }
  
  NSString *usr   = [NSString stringWithUTF8String:username];
  usr = [usr stringByDecodingURLFormat];
  [Crittercism setUsername:usr];
}

void Crittercism_SetValue(const char* value, const char* key)
{
  if (![CrittercismUnity isInited] || value == NULL || key == NULL || _ExceptionGenerator == NULL) {
    return;
  }
  
  NSString *t_val   = [NSString stringWithUTF8String:value];
  t_val = [t_val stringByDecodingURLFormat];
  
  NSString *t_key   = [NSString stringWithUTF8String:key];
  t_key = [t_key stringByDecodingURLFormat];
  
  [Crittercism setValue:t_val forKey:t_key];
}

void Crittercism_NewLog(const char* name)
{
  if (![CrittercismUnity isInited] || name == NULL || _ExceptionGenerator == NULL) {
    return;
  }
  
  NSString *str   = [NSString stringWithUTF8String:name];
  str = [str stringByDecodingURLFormat];
  
  [_ExceptionGenerator NewLog:str];
}

void Crittercism_SetLogValue(const char *key, const char *value)
{
  if (![CrittercismUnity isInited] || value == NULL || key == NULL || _ExceptionGenerator == NULL) {
    return;
  }
  
  NSString *str   = [NSString stringWithUTF8String:value];
  str = [str stringByDecodingURLFormat];
  
  NSString *str1   = [NSString stringWithUTF8String:key];
  str1 = [str stringByDecodingURLFormat];
  
  [_ExceptionGenerator AddLogValue:str key:str1];
}

void Crittercism_FinishLog()
{
  if (![CrittercismUnity isInited] || _ExceptionGenerator == NULL) {
    return;
  }

  [_ExceptionGenerator FinalizeLog];
}

bool Crittercism_GetOptOutStatus()
{
  if (![CrittercismUnity isInited]) {
    return false;
  }

  return [Crittercism getOptOutStatus];
}

void Crittercism_SetOptOutStatus(bool status)
{
  if (![CrittercismUnity isInited]) {
    return;
  }
  
  [Crittercism setOptOutStatus:status];
}

@implementation CrittercismUnity

BOOL _IsInited  = FALSE;

+(void)initWithAppID:(NSString*)appID
{
  NSString *use_appID     = appID;
  
  @try {
    //  Attempt to load the Crittercism id file
    NSString *file_name = [[NSBundle mainBundle] pathForResource:@"CrittercismIDs" ofType:@"plist"];
    
    if (file_name != NULL) {
      DEBUG_LOG(@"Crittercism: AppID File Found: %@", file_name);

      NSDictionary *dictionary    = [[NSDictionary alloc]initWithContentsOfFile:file_name];
      if (dictionary != NULL) {
        use_appID   = [[[NSString alloc]initWithString:(NSString*)[dictionary objectForKey:@"AppID"]] autorelease];
      }
      
      [dictionary release];
      
      //  Handle the init
      if (use_appID == NULL || [use_appID isEqual: @""]) {
        use_appID   = appID;
      }
    }
  } @catch(NSException *e) {
    use_appID   = appID;
  }
  
  DEBUG_LOG(@"Crittercism: AppID:%@", use_appID);
	
  //  Last check for null keys
  if (use_appID == NULL) {
    return;
  }

  //  Init Crittercism
	if (_ExceptionGenerator == NULL) {
    _ExceptionGenerator	= [[CrittercismDataGenerator alloc]init];
  }
  
  //  Call the main thread to preform the init
	[_ExceptionGenerator performInit:use_appID ];
  
  _IsInited   = TRUE;
  
  [_ExceptionGenerator SendLastException];
}

+ (void)initWithFileData:(NSString *)appData
{
  if (_IsInited || appData == NULL) {
    return;
  }
  
  NSString *use_appID = NULL;
  
  @try
  {
    NSData* plistData = [appData dataUsingEncoding:NSUTF8StringEncoding];
    NSString *error = NULL;
    NSPropertyListFormat format;
    NSDictionary* dictionary = [NSPropertyListSerialization propertyListFromData:plistData
                                                                mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if (!dictionary) {
      NSLog(@"Crittercism: Plist Error: %@",error);
      throw new NSException();
    }
    
    // Attempt to load the Crittercism file data
    if (dictionary != NULL) {
      use_appID   = [dictionary objectForKey:@"AppID"];
    }
    
    [dictionary release];
    
    //  Handle the init
    if (use_appID == NULL || [use_appID isEqual: @""]) {
      use_appID = NULL;
    }
  } @catch(NSException *e) {
    return;
  }
  
  DEBUG_LOG(@"Crittercism: AppID:%@", use_appID);
	
  //  Last check for null keys
  if (use_appID == NULL) {
    return;
  }
  
  //  Init Crittercism
	if (_ExceptionGenerator == NULL) {
    _ExceptionGenerator	= [[CrittercismDataGenerator alloc]init];
  }
  
  //  Call the main thread to preform the init
	[_ExceptionGenerator performInit:use_appID ];
  _IsInited   = TRUE;
  
  [_ExceptionGenerator SendLastException];
}

+ (BOOL)isInited	{
  return _IsInited;
}

+(void) logHandledException:(NSException *)exception
{
  if (_IsInited == false || exception == NULL) {
    return;
  }
  
	DEBUG_LOG(@"Crittercism: logHandledException: logging");
	
  [PerformExceptionHandler PerformException:exception];
  
	DEBUG_LOG(@"Crittercism: logHandledException: logged");
}


+ (void)logUnhandledException:(NSException *)exception
{
	if (_IsInited == false || exception == NULL || _ExceptionGenerator == NULL) {
    return;
  }
  
	DEBUG_LOG(@"Crittercism: logUnhandledException: logging");
  
  [PerformExceptionHandler PerformException:exception];
  
	DEBUG_LOG(@"Crittercism: logUnhandledException: logged");
}

+(void)_callLogHandleException:(NSException*)exception
{
#ifdef VERSION_3

	DEBUG_LOG(@"Crittercism: _callLogHandleException: logging");
  
  [Crittercism logHandledException:exception];

  DEBUG_LOG(@"Crittercism: _callLogHandleException: logged");
  
#elif defined(VERSION_2)
  [Crittercism logEvent:[exception name] andEventDict:[[NSMutableDictionary alloc]init]];
#endif
}

@end