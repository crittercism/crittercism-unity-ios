using UnityEngine;
using System;
using System.Collections.Generic;
using System.Net;
using System.Runtime.InteropServices;

public static class CrittercismIOS
{
	[DllImport("__Internal")]
	private static extern void Crittercism_EnableWithAppID (string appID, bool enableServiceMonitoring);

	[DllImport("__Internal")]
	private static extern bool Crittercism_LogHandledException (string name, string reason, string stack, int platformId);

	[DllImport("__Internal")]
	private static extern void Crittercism_LogUnhandledException (string name, string reason, string stack, int platformId);

	[DllImport("__Internal")]
	private static extern bool Crittercism_LogNetworkRequest(string method,
	                                                         string uriString,
	                                                         double latency,
	                                                         int bytesRead,
	                                                         int bytesSent,
	                                                         int responseCode,
	                                                         int errorCode);
	
	[DllImport("__Internal")]
	private static extern void Crittercism_SetAsyncBreadcrumbMode (bool writeAsync);

	[DllImport("__Internal")]
	private static extern void Crittercism_LeaveBreadcrumb (string breadcrumb);

	[DllImport("__Internal")]
	private static extern void Crittercism_SetUsername (string key);

	[DllImport("__Internal")]
	private static extern void Crittercism_SetValue (string value, string key);

	[DllImport("__Internal")]
	private static extern void Crittercism_SetOptOutStatus (bool status);

	[DllImport("__Internal")]
	private static extern bool Crittercism_DidCrashOnLastLoad();
	
	[DllImport("__Internal")]
	private static extern bool Crittercism_GetOptOutStatus ();

	[DllImport("__Internal")]
	private static extern void Crittercism_BeginTransaction (string name);

	[DllImport("__Internal")]
	private static extern void Crittercism_BeginTransactionWithValue (string name, int value);

	[DllImport("__Internal")]
	private static extern void Crittercism_EndTransaction (string name);

	[DllImport("__Internal")]
	private static extern void Crittercism_FailTransaction (string name);
	
	[DllImport("__Internal")]
	private static extern void Crittercism_CancelTransaction (string name);

	[DllImport("__Internal")]
	private static extern void Crittercism_SetTransactionValue (string name, int value);

	[DllImport("__Internal")]
	private static extern int Crittercism_GetTransactionValue (string name);

	// Crittercism-ios CRPluginException.h defines crPlatformId crUnityId = 0 .
	private const int crUnityId = 0;
	
	// Reporting uncaught C# Exception's as crashes (red blips)?
	private static volatile bool logUnhandledExceptionAsCrash = false;

	/// <summary>
	/// Initializes Crittercism.  Crittercism must be initialized before any other calls may be
	/// made to Crittercism.  Once Crittercism is initialized, any crashes will be reported to
	/// Crittercism.
	/// </summary>
	/// <param name="appID">A Crittercism app identifier.  The app identifier may be found
	/// in the Crittercism web portal under "App Settings".</param>
	public static void Init (string appID)
	{
		if (Application.platform != RuntimePlatform.IPhonePlayer) {
			Debug.Log ("CrittercismIOS only supports the iOS platform. Crittercism will not be enabled");
			return;
		}
		if (appID == null) {
			Debug.Log ("Crittercism given a null app ID");
			return;
		}
		try {
			Crittercism_EnableWithAppID (appID, true);
			AppDomain.CurrentDomain.UnhandledException += OnUnhandledException;
			Application.logMessageReceived += OnLogMessageReceived;
			Debug.Log ("CrittercismIOS: Sucessfully Initialized");
		} catch {
			Debug.Log ("Crittercism Unity plugin failed to initialize.");
		}
	}

	private static string StackTrace (Exception e)
	{
		// Allowing for the fact that the "name" and "reason" of the outermost
		// exception e are already shown in the Crittercism portal, we don't
		// need to repeat that bit of info.  However, for InnerException's, we
		// will include this information in the StackTrace .  The horizontal
		// lines (hyphens) separate InnerException's from each other and the
		// outermost Exception e .
		string answer = e.StackTrace;
		// Using seen for cycle detection to break cycling.
		List<Exception> seen = new List<Exception> ();
		seen.Add (e);
		if (answer != null) {
			// There has to be some way of telling where InnerException ie stacktrace
			// ends and main Exception e stacktrace begins.  This is it.
			answer = ((e.GetType ().FullName + " : " + e.Message + "\r\n")
				+ answer);
			Exception ie = e.InnerException;
			while ((ie != null) && (seen.IndexOf(ie) < 0)) {
				seen.Add (ie);
				answer = ((ie.GetType ().FullName + " : " + ie.Message + "\r\n")
					+ (ie.StackTrace + "\r\n")
					+ answer);
				ie = ie.InnerException;
			}
		} else {
			answer = "";
		}
		return answer;
	}

	/// <summary>
	/// Log an exception that has been handled in code.
	/// This exception will be reported to the Crittercism portal.
	/// </summary>
	/// <param name="e">A caught exception that should be reported to Crittercism.</param>
	public static void LogHandledException (Exception e)
	{
		if (e == null) {
			return;
		}
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_LogHandledException (e.GetType ().FullName, e.Message, StackTrace (e), crUnityId);
		}
	}

	/// <summary>
	/// Check if the user has opted out of Crittercism.  If a user is opted out, then no data will be
	/// sent to Crittercism.
	/// </summary>
	/// <returns>True if the user has opted out of Crittercism</returns>
	public static bool GetOptOut ()
	{
		bool isOptedOut = true;
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			isOptedOut = Crittercism_GetOptOutStatus ();
		}
		return isOptedOut;
	}

	/// <summary>
	/// Changes whether the user is opted in or out of reporting data to Crittercism.
	/// </summary>
	/// <param name="isOptedOut">True to opt out of sending data to Crittercism</param>
	public static void SetOptOut (bool isOptedOut)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_SetOptOutStatus (isOptedOut);
		}
	}

	/// <summary>
	/// Set the Username of the current user.
	/// </summary>
	/// <param name="username">The user name to set</param>
	public static void SetUsername (string username)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_SetUsername (username);
		}
	}

	/// <summary>
	/// Tell Crittercism to associate the given value/key pair with the current
	/// device UUID.
	/// <param name="val">The metadata value to set</param>
	/// <param name="key">The key to associate with the given metadata<c/param>
	/// <example>SetValue("5", "Game Level")</example>
	/// </summary>
	public static void SetValue (string val, string key)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_SetValue (val, key);
		}
	}

	/// <summary>
	/// Log a breadcrumb.  Breadcrumbs are used for tracking local events.  Breadcrumbs
	/// will be attached to handled exceptions and crashes, which will allow diagnosing
	/// which events lead up to a crash.
	/// </summary>
	/// <param name="breadcrumb">The breadcrumb text to append to the breadcrumb trail</param>
	/// <example>LeaveBreadcrumb("Game started");</example>
	public static void LeaveBreadcrumb (string breadcrumb)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_LeaveBreadcrumb (breadcrumb);
		}
	}

	public static void LogNetworkRequest (string method,
	                                      string uriString,
	                                      double latency,
	                                      int bytesRead,
	                                      int bytesSent,
	                                      HttpStatusCode responseCode,
	                                      WebExceptionStatus exceptionStatus)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_LogNetworkRequest (method, uriString, latency, bytesRead, bytesSent, (int)responseCode, (int)exceptionStatus);
		}
	}

	/// <summary>
	/// Did the application crash on the previous load?
	/// </summary>
	public static bool DidCrashOnLastLoad ()
	{
		bool answer = false;
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			answer = Crittercism_DidCrashOnLastLoad ();
		}
		return answer;
	}

	/// <summary>
	/// Init and begin a transaction with a default value.
	/// </summary>
	public static void BeginTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_BeginTransaction (name);
		}
	}

	/// <summary>
	/// Init and begin a transaction with an input value.
	/// </summary>
	public static void BeginTransaction (string name, int value)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_BeginTransactionWithValue (name, value);
		}
	}
	
	/// <summary>
	/// Cancel a transaction as if it never existed.
	/// </summary>
	public static void CancelTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_CancelTransaction (name);
		}
	}

	/// <summary>
	/// End an already begun transaction successfully.
	/// </summary>
	public static void EndTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_EndTransaction (name);
		}
	}
	
	/// <summary>
	/// End an already begun transaction as a failure.
	/// </summary>
	public static void FailTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_FailTransaction (name);
		}
	}
	
	/// <summary>
	/// Set the currency cents value of a transaction.
	/// </summary>
	public static void SetTransactionValue (string name, int value)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_SetTransactionValue (name, value);
		}
		;
	}
	
	/// <summary>
	/// Get the currency cents value of a transaction.
	/// </summary>
	public static int GetTransactionValue (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			return Crittercism_GetTransactionValue (name);
		} else {
			return -1;
		}
	}

	private static void OnUnhandledException (object sender, UnhandledExceptionEventArgs args)
	{
		if (args == null || args.ExceptionObject == null) {
			return;
		}
		try {
			Exception e = args.ExceptionObject as Exception;
			if (e != null) {
				if (Application.platform == RuntimePlatform.IPhonePlayer) {
					// Should never get here since the Init() call would have bailed on the same if statement
					Crittercism_LogUnhandledException (e.GetType ().FullName, e.Message, StackTrace (e), crUnityId);
				}
			}
		} catch {
			if (Debug.isDebugBuild == true) {
				Debug.Log ("CrittercismIOS: Failed to log exception");
			}
		}
	}

	/// <summary>
	/// Report uncaught C# Exception's as crashes (red blips) iff value is true .
	/// </summary>
	public static void SetLogUnhandledExceptionAsCrash (bool value)
	{
		logUnhandledExceptionAsCrash = value;
	}

	/// <summary>
	/// Reporting uncaught C# Exception's as crashes (red blips)?
	/// </summary>
	public static bool GetLogUnhandledExceptionAsCrash ()
	{
		return logUnhandledExceptionAsCrash;
	}

	private static void OnLogMessageReceived (String name, String stack, LogType type)
	{
		if (type == LogType.Exception) {
			if (Application.platform == RuntimePlatform.IPhonePlayer) {
				if (logUnhandledExceptionAsCrash) {
					Crittercism_LogUnhandledException (name, name, stack, crUnityId);
				} else {
					Crittercism_LogHandledException (name, name, stack, crUnityId);
				}
			}
		}
	}
}
