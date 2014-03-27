//
//  CrittercismExtern.h
//  CrittercismUnity
//
//  Created by Ben Bethel on 3/13/12.
//  Copyright (c) 2012 Flying Wisdom Studios. All rights reserved.
//

#ifndef CrittercismUnity_CrittercismExtern_h
#define CrittercismUnity_CrittercismExtern_h

#ifdef __cplusplus
extern "C" {
#endif
  
  bool Crittercism_IsInited();
  void Crittercism_EnableWithAppID(const char* appID);
  
  void Crittercism_LogHandledException();
	void Crittercism_LogUnhandledException();
  void Crittercism_LogUnhandledExceptionWillCrash();
  
  void Crittercism_SetAsyncBreadcrumbMode(bool writeAsync);
  void Crittercism_LeaveBreadcrumb(const char* breadcrumb);
  
  void Crittercism_NewException(const char* name, const char* reason, const char *stack);
  
  const char * Crittercism_GetUserUUID();
  
  void Crittercism_SetUsername(const char* username);
  void Crittercism_SetValue(const char* value, const char* key);
  
	void Crittercism_SetOptOutStatus(bool status);
  bool Crittercism_GetOptOutStatus();
  
  void Crittercism_RefreshSignalRegister();
  
#ifdef __cplusplus
};
#endif

#endif
