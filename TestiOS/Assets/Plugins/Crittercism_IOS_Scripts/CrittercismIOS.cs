using UnityEngine;
using System.Runtime.InteropServices;

public static class CrittercismIOS
{
	/// <summary>
	/// Address of Unity Side file Containing App ID's
	/// </summary>
	const string _KeyResources	= "Resources/CrittercismIDs.text";
	
	/// <summary>
	/// Show debug and log messaged in the console in release mode.
	/// If true CrittercismIOS logs will not appear in the console.
	/// </summary>
	const bool _ShowDebugOnOnRelease		= false;
	
	private static bool _HandleUnityExceptions	= true;
	private static bool _IsPluginInited			= false;
	private static bool _IsUnityPluginInited	= false;

#if (UNITY_IPHONE && !UNITY_EDITOR)
	
	const string _INTERNAL	= "__Internal";
	
	[DllImport(_INTERNAL)]
	private static extern bool Crittercism_IsInited();
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_EnableWithAppID(string appID);
	
    [DllImport(_INTERNAL)]
	private static extern bool Crittercism_LogHandledException();
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_LogUnhandledException();
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_LogUnhandledExceptionWillCrash();
	
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_SetAsyncBreadcrumbMode(bool writeAsync);
    [DllImport(_INTERNAL)]
	private static extern void Crittercism_LeaveBreadcrumb(string breadcrumb);
	
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_NewException(string name, string reason, string stack);
	
	[DllImport(_INTERNAL)]
	private static extern string Crittercism_GetUserUUID();
	
    [DllImport(_INTERNAL)]
	private static extern void Crittercism_SetAge(int age);
    [DllImport(_INTERNAL)]
	private static extern void Crittercism_SetGender(string gender);
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_SetUsername(string key);
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_SetEmail(string email);
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_SetValue(string value, string key);
	
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_SetOptOutStatus(bool status);
	[DllImport(_INTERNAL)]
	private static extern bool Crittercism_GetOptOutStatus();
	
	[DllImport(_INTERNAL)]
	private static extern void Crittercism_RefreshSignalRegister();
	
#else
	private static bool Crittercism_IsInited() { return false; }
	private static void Crittercism_EnableWithAppID(string appID)	{}
	
    private static bool Crittercism_LogHandledException()			 { return false; }
	private static void Crittercism_LogUnhandledException()							{}
	private static void Crittercism_LogUnhandledExceptionWillCrash()				{}
	
	private static void Crittercism_SetAsyncBreadcrumbMode(bool writeAsync)			{}
    private static void Crittercism_LeaveBreadcrumb(string breadcrumb)				{}
	
	private static void Crittercism_NewException(string name, string reason, string stack) {}
	
	private static string Crittercism_GetUserUUID()						{ return ""; }
	
    private static void Crittercism_SetAge(int age)									{}
    private static void Crittercism_SetGender(string gender)						{}
	private static void Crittercism_SetUsername(string key)							{}
	private static void Crittercism_SetEmail(string email)							{}
	private static void Crittercism_SetValue(string value, string key)				{}
	
	private static void Crittercism_SetOptOutStatus(bool status)					{}
	private static bool Crittercism_GetOptOutStatus()				 { return false; }
	
	private static void Crittercism_RefreshSignalRegister()							{}
    
#endif
	
	/// <summary>
	/// Description:
	/// Start Crittercism for Unity, will start crittercism for ios if it is not already active.
	/// Application will will attempt to load keys from Resources/CrittercismIDs.text plist formated file.
	/// </summary>
	public static void Init()
	{	Init(null, true, true);	}
	
	
	/// <summary>
	/// Description:
	/// Start Crittercism for Unity, will start crittercism for ios if it is not already active.
	/// Application will will attempt to load keys from Resources/CrittercismIDs.text plist formated file.
	/// Parameters:
	/// handleUnityExceptions: Allow crittercisms to recieve unity handled exceptions.
	/// </summary>
	public static void Init(bool handleUnityExceptions)
	{	Init(null, true, handleUnityExceptions);	}
	
	
	/// <summary>
	/// Description:
	/// Start Crittercism for Unity, will start crittercism for ios if it is not already active.
	/// Application will will attempt to load keys from Resources/CrittercismIDs.text plist formated file.
	/// If these keys exist in file. The provided parameters will be overriden.
	/// Parameters:
	/// appID: Crittercisms Provided App ID for this application
	/// key: Crittercisms Provided Key for this application
	/// Secret: Crittercisms Provided Secret for this application
	/// </summary>
	public static  void Init(string appID)
	{	Init(appID, false, true);	}
	
	
	/// <summary>
	/// Description:
	/// Start Crittercism for Unity, will start crittercism for ios if it is not already active.
	/// Application will will attempt to load keys from Resources/CrittercismIDs.text plist formated file.
	/// If these keys exist in file. The provided parameters will be overriden.
	/// Parameters:
	/// appID: Crittercisms Provided App ID for this application
	/// key: Crittercisms Provided Key for this application
	/// secret: Crittercisms Provided Secret for this application
	/// handleUnityExceptions: Allow crittercisms to recieve unity handled exceptions.
	/// </summary>
	public static  void Init(string appID, bool handleUnityExceptions)
	{	Init(appID, true, handleUnityExceptions);	}
	
	
	/// <summary>
	/// Description:
	/// Start Crittercism for Unity, will start crittercism for ios if it is not already active.
	/// Parameters:
	/// appID: Crittercisms Provided App ID for this application
	/// key: Crittercisms Provided Key for this application
	/// secret: Crittercisms Provided Secret for this application
	/// loadFromResources: Attempt to load the appID, key, and secret from the CrittercismIDs.text file.
	/// handleUnityExceptions: Allow crittercisms to recieve unity handled exceptions.
	/// </summary>
	public static void Init(string appID, bool loadFromResources, bool handleUnityExceptions)
	{
		_IsPluginInited	= Crittercism_IsInited();
		if(_IsUnityPluginInited && _IsPluginInited)
		{
			Crittercism_RefreshSignalRegister();
			return;
		}
		
		_HandleUnityExceptions	= handleUnityExceptions;
		
		if(!_IsPluginInited)
		{
			if(loadFromResources)
			{
				string appData	= null;
				try
				{
					TextAsset text	= (TextAsset)Resources.Load(_KeyResources);
					if(text != null)
					{
						System.IO.StringReader reader	= new System.IO.StringReader(text.text);
						if(reader == null)	{	throw new System.Exception();	}
						appData	= reader.ReadToEnd();
						appData	= WWW.EscapeURL(appData);
					}
				}
				catch
				{	appData	= null;	}
				
				try
				{
					if(appData == null)	{	throw new System.Exception();	}
					
					Crittercism_EnableWithAppID(appData);
					_IsPluginInited	= Crittercism_IsInited();
					//_IsPluginInited = true;
				}
				catch
				{
					if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
					{	Debug.Log("CrittercismIOS: Failed to start Crittercism for ios");	}
				}
			}
			
			
			if(!_IsPluginInited)
			{
				if(appID == null)	{	appID	= "";	}
//				if(key == null)		{	key		= "";	}
//				if(secret == null)	{	secret	= "";	}
			
				try
				{
					Crittercism_EnableWithAppID(appID);
					_IsPluginInited	= Crittercism_IsInited();
					//_IsPluginInited = true;
				}
				catch
				{
					if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
					{	Debug.Log("CrittercismIOS: Failed to start Crittercism for ios");	}
				}
			}
		}
		else
		{
			Debug.Log("CrittercismIPS: already initialized");
		}
		
		if(_IsUnityPluginInited == false && _IsPluginInited)
		{	
			System.AppDomain.CurrentDomain.UnhandledException += _OnUnresolvedExceptionHandler;
			Application.RegisterLogCallback(_OnDebugLogCallbackHandler);
			_IsUnityPluginInited	= true;
			Debug.Log("CrittercismIOS: Sucessfully Initialized");
		}
		
	}
	
	/// <summary>
	/// Log an exception that has been handled in code.
	/// This exception will be reported to the Crittercism portal.
	/// </summary>
	static public void LogHandledException(System.Exception e)
	{
		if(e == null)	{	return;	}
		
#if (UNITY_IPHONE && !UNITY_EDITOR)
		string str1	= _EscapeString(e.ToString());
		string str2	= _EscapeString(e.Message);
		string str3	= _EscapeString(e.StackTrace);
		
		Crittercism_NewException(str1, str2, str3);
		Crittercism_LogHandledException();
#else
		string message	= e.ToString() + "\n" + e.Message + "\n" + e.StackTrace;
		if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
		{	Debug.LogWarning(message);	}
#endif
	}
	
	/// <summary>
	/// Retrieve whether the user is opting out of Crittercism.
	/// </summary>
	static public bool GetOptOut()	{	return Crittercism_GetOptOutStatus();	}
	
	/// <summary>
	/// Set if whether the user is opting to use crittercism
	/// </summary></param>
	static public void SetOptOut(bool s)	{	Crittercism_SetOptOutStatus(s);	}
	
	/// <summary>
	/// Set the Username of the user
	/// This will be reported in the Crittercism Meta.
	/// </summary>
    static public void SetUsername(string username)	{	Crittercism_SetUsername(_EscapeString(username));	}
	
	/// <summary>
	/// Add a custom value to the Crittercism Meta.
	/// </summary>
    static public void SetValue(string v, string key)	{	Crittercism_SetValue(_EscapeString(v), _EscapeString(key)); }
	
	/// <summary>
	/// Leave a breadcrumb for tracking.
	/// </summary>
	static public void LeaveBreadcrumb(string l)	{	Crittercism_LeaveBreadcrumb(_EscapeString(l));	}
	
	/// <summary>
	/// Log an event with Crittercism to be sent to the Web Portal.
	/// </summary>
	static public void LogEvent(string eventName, System.Collections.Generic.Dictionary<string, string> vals)
	{
//		Crittercism_NewLog(eventName);
		
		if(vals != null)
		{
			//TODO: Check whether SetValue == SetLogValue
			foreach(System.Collections.Generic.KeyValuePair<string,string> entry in vals)
			{	Crittercism_SetValue(_EscapeString(entry.Key), _EscapeString(entry.Value));	}
		}
		
//		Crittercism_FinishLog();
	}
	
	
	
	static private string _EscapeString(string enter)
	{
		if(string.IsNullOrEmpty(enter))	{	enter	= "";	}
		else{	enter	= WWW.EscapeURL(enter);	}
		return enter;
	}
	
	static private void _OnUnresolvedExceptionHandler(object sender, System.UnhandledExceptionEventArgs args)
	{
		if(args == null)	{	return;	}
		
		if(args.ExceptionObject == null)	{	return;	}
		
		try
		{
			System.Type type	= args.ExceptionObject.GetType();
			if(type == typeof(System.Exception))
			{
				System.Exception e	= (System.Exception)args.ExceptionObject;
#if (UNITY_IPHONE && !UNITY_EDITOR)
				string str1	= _EscapeString(e.ToString());
				string str2	= _EscapeString(e.Message);
				string str3	= _EscapeString(e.StackTrace);
				
				Crittercism_NewException(str1, str2, str3);
				Crittercism_LogUnhandledException();
				Crittercism_LogUnhandledExceptionWillCrash();
#else
				string message	= e.ToString() + "\n" + e.Message + "\n" + e.StackTrace;
				if(args.IsTerminating)
				{
					if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
					{	Debug.LogError("CrittercismIOS: Terminal Exception: " + message);	}
				}
				else
				{
					if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
					{	Debug.LogWarning(message);	}
				}
#endif
			}
			else
			{
				if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
				{	Debug.Log("CrittercismIOS: Unknown Exception Type: " + args.ExceptionObject.ToString());	}
			}
		
		}catch{
			if(Debug.isDebugBuild == true || _ShowDebugOnOnRelease == true)
			{	Debug.Log("CrittercismIOS: Failed to resolve exception");	}
		}
	}
	
	static private void _OnDebugLogCallbackHandler(string name, string stack, LogType type)
	{
		if(LogType.Exception == type || LogType.Assert == type)
		{	
			if(!_IsUnityPluginInited || !_HandleUnityExceptions)	{	return;	}
			
#if (UNITY_IPHONE && !UNITY_EDITOR)
			
			name	= _EscapeString(name);
			stack	= _EscapeString(stack);
			
			Crittercism_NewException(name, name, stack);
			Crittercism_LogUnhandledException();
#else
#endif
		}
	}
}
