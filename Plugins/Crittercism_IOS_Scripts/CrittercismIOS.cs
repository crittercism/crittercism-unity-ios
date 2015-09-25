using UnityEngine;
using System;
using System.Collections.Generic;
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
	private static extern void Crittercism_SetTransactionValue (string name, int value);

	[DllImport("__Internal")]
	private static extern int Crittercism_GetTransactionValue (string name);

	// Crittercism-ios CRPluginException.h defines crPlatformId crUnityId = 0 .
	private const int crUnityId = 0;

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

			// Add _OnUnresolvedExceptionHandler
			System.AppDomain.CurrentDomain.UnhandledException += _OnUnresolvedExceptionHandler;
			Application.RegisterLogCallback (_OnDebugLogCallbackHandler);
			Debug.Log ("CrittercismIOS: Sucessfully Initialized");
		} catch {
			Debug.Log ("Crittercism Unity plugin failed to initialize.");
		}
	}

	private static string StackTrace (System.Exception e)
	{
		// Allowing for the fact that the "name" and "reason" of the outermost
		// exception e are already shown in the Crittercism portal, we don't
		// need to repeat that bit of info.  However, for InnerException's, we
		// will include this information in the StackTrace .  The horizontal
		// lines (hyphens) separate InnerException's from each other and the
		// outermost Exception e .
		string answer = e.StackTrace;
		// Using seen for cycle detection to break cycling.
		List<System.Exception> seen = new List<System.Exception> ();
		seen.Add (e);
		if (answer != null) {
			// There has to be some way of telling where InnerException ie stacktrace
			// ends and main Exception e stacktrace begins.  This is it.
			answer = ((e.GetType ().FullName + " : " + e.Message + "\r\n")
				+ answer);
			System.Exception ie = e.InnerException;
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
	static public void LogHandledException (System.Exception e)
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
	static public bool GetOptOut ()
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
	static public void SetOptOut (bool isOptedOut)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_SetOptOutStatus (isOptedOut);
		}
	}

	/// <summary>
	/// Set the Username of the current user.
	/// </summary>
	/// <param name="username">The user name to set</param>
	static public void SetUsername (string username)
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
	static public void SetValue (string val, string key)
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
	static public void LeaveBreadcrumb (string breadcrumb)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_LeaveBreadcrumb (breadcrumb);
		}
	}

	/// <summary>
	/// Begin a transaction to track ex. login
	/// </summary>
	static public void BeginTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_BeginTransaction (name);
		}
	}

	static public void BeginTransaction (string name, int value)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_BeginTransactionWithValue (name, value);
		}
	}
	
	/// <summary>
	/// Ends a tracked transaction ex. login was successful
	/// </summary>
	static public void EndTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_EndTransaction (name);
		}
	}
	
	/// <summary>
	/// Fails a tracked transaction ex. login error
	/// </summary>
	static public void FailTransaction (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_FailTransaction (name);
		}
	}
	
	/// <summary>
	/// Set a value for a transaction ex. shopping cart value
	/// </summary>
	static public void SetTransactionValue (string name, int value)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			Crittercism_SetTransactionValue (name, value);
		}
		;
	}
	
	/// <summary>
	/// Get the current value of the tracked transaction
	/// </summary>
	static public int GetTransactionValue (string name)
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			return Crittercism_GetTransactionValue (name);
		} else {
			return -1;
		}
	}

	static private void _OnUnresolvedExceptionHandler (object sender, System.UnhandledExceptionEventArgs args)
	{
		if (args == null || args.ExceptionObject == null) {
			return;
		}
		try {
			System.Exception e = args.ExceptionObject as System.Exception;
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

	static private void _OnDebugLogCallbackHandler (string name, string stack, LogType type)
	{
		if (LogType.Exception == type || LogType.Assert == type) {
			if (Application.platform == RuntimePlatform.IPhonePlayer) {
				// Should never get here since the Init() call would have bailed on the same if statement
				Crittercism_LogUnhandledException (name, name, stack, crUnityId);
			}
		}
	}
}
