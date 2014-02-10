using UnityEngine;
using UnityEditor;
using System.Collections;

public class CrittercismEditor : EditorWindow
{
	string mApplicationID	= null;
	
	
	[MenuItem ("Crittercism/Setup IOS")]
    public static void Setup ()
	{
      	CrittercismEditor window = (CrittercismEditor)EditorWindow.GetWindow(typeof(CrittercismEditor));
		window.mApplicationID	= EditorPrefs.GetString("CrittercismAppID", "");
      	window.Show();
	}
	
	void OnGUI ()
	{
		GUILayout.Label ("Crittercism", EditorStyles.boldLabel);
		mApplicationID = EditorGUILayout.TextField ("Application ID", mApplicationID);
		
		GUILayoutOption[] options	= new GUILayoutOption[0];
		if(GUILayout.Button("Setup",options))
		{
			if(string.IsNullOrEmpty(mApplicationID))
			{
				UnityEditor.EditorUtility.DisplayDialog("Error", "No Crittercism Application ID Entered", "Close");
				return;
			}
			
			EditorPrefs.SetString("CrittercismAppID", mApplicationID);
			string ret	= HandleDynamicCrittercismSetup(mApplicationID);
			if(!string.IsNullOrEmpty(ret))
			{
				string retHardcode	= HandleHardcodedCrittercismSetup (mApplicationID);
				if(!string.IsNullOrEmpty(retHardcode))
				{
					UnityEditor.EditorUtility.DisplayDialog("Error", ret, "Close");
					return;
				}
			}
			UnityEditor.EditorUtility.DisplayDialog("Success", "Crittercisms AppController Was Installed Successfully.", "Close");
		}
	}
	
	public static string HandleHardcodedCrittercismSetup(string applicationID)
	{
		string acFile	= "AppController";
#if UNITY_3_4
		acFile	+= "3.4.0";
#elif UNITY_3_5 && !UNITY_3_5_7
		acFile	+= "3.5.6";
#elif UNITY_3_5_7
		acFile	+= "3.5.7";
#elif UNITY_4_0 || UNITY_4_0_1
		acFile	+= "4.0.1";
#elif UNITY_4_1
		acFile	+= "4.1";
#else
		UnityEditor.EditorUtility.DisplayDialog("Error", "Unknown Version of Unity!", "Close");
		return;
#endif
		
		string writePath	= GetIOSPluginsFolder() + "/AppController.mm";
		acFile = Application.dataPath + "/Editor/Crittercism/" + acFile + ".mm";
		try
		{
			if(!System.IO.File.Exists(acFile))
			{	throw new System.Exception("Invalid File Path For AppController:\n" + acFile);	}
			
			if(System.IO.File.Exists(writePath))
			{
				try
				{
					System.IO.File.Delete(writePath);
				}catch
				{	throw new System.Exception("Failed to Delete File For AppController:\n" + writePath);	}
			}
		}catch(System.Exception e)
		{	return e.Message;	}
		
		try
		{
			System.IO.StreamReader readFile		= new System.IO.StreamReader(acFile);
			System.IO.StreamWriter writeFile	= new System.IO.StreamWriter(writePath);
			
			bool applicationIDWasWritten	= false;
			string lineData	= null;
			while((lineData = readFile.ReadLine()) != null)
			{
				if(!applicationIDWasWritten)
				{
					if(lineData.Contains("\"CRITTERCISM_APP_ID\""))
					{
						lineData	= lineData.Replace("CRITTERCISM_APP_ID", applicationID);
						applicationIDWasWritten	= true;
					}
				}
				
				writeFile.Write(lineData + "\n");
			}
			
			readFile.Close();
			readFile	= null;
			writeFile.Flush();
			writeFile.Close();
			writeFile	= null;
			
		}catch
		{	return "Unable to finish writting file data.";	}
		
		return null;
	}
	
	public static string HandleDynamicCrittercismSetup(string applicationID)
	{
		string iphoneDataPath		= UnityEditor.EditorApplication.applicationContentsPath + "/PlaybackEngines/iPhonePlayer/iPhone-Trampoline/";
		string appControllerPath	= null;
		try
		{
			string[] files	= System.IO.Directory.GetFiles(iphoneDataPath, "*.mm", System.IO.SearchOption.AllDirectories);
			for(int nItter = 0; nItter < files.Length; nItter++)
			{
				if(files[nItter].Contains("AppController.mm"))
				{
					appControllerPath	= files[nItter];
					break;
				}
			}
		}
		catch(System.Exception e)
		{	return e.Message;	}
		
		if(string.IsNullOrEmpty(appControllerPath))
		{	return "Failed To Locate IOS App Controller";	}
		
		try
		{
			string writePath	= GetIOSPluginsFolder() + "/AppController.mm";
			System.IO.StreamReader readFile		= new System.IO.StreamReader(appControllerPath);
			System.IO.StreamWriter writeFile	= new System.IO.StreamWriter(writePath);
			
			bool applicationIDWasWritten	= false;
			bool hasWritenExtern			= false;
			string lineData	= null;
			while((lineData = readFile.ReadLine()) != null)
			{
				if(!applicationIDWasWritten)
				{
					if(!hasWritenExtern)
					{
						if(lineData.Contains("//"))
						{
							writeFile.Write("const char* kCrittercism_App	= \"" + applicationID + "\";\n");
							writeFile.Write("extern \"C\" void Crittercism_EnableWithAppID(const char* appID);\n\n");
							hasWritenExtern	= true;
						}
					}
					else
					{
						if(lineData.Contains("-"))
						{
							if(lineData.Contains("didFinishLaunchingWithOptions:"))
							{
								writeFile.Write(lineData + "\n");
								lineData = readFile.ReadLine();
								if(lineData.Contains("{") && !lineData.Contains("if"))
								{
									writeFile.Write(lineData + "\n");
									lineData = readFile.ReadLine();
								}
								writeFile.Write("	Crittercism_EnableWithAppID(kCrittercism_App);\n\n");
								applicationIDWasWritten	= true;
							}
						}
					}
				}
				
				writeFile.Write(lineData + "\n");
			}
			
			readFile.Close();
			readFile	= null;
			writeFile.Flush();
			writeFile.Close();
			writeFile	= null;
			
		}catch
		{	return "Unable to finish writting file data.";	}
		
		return null;
	}
	
	private static string GetIOSPluginsFolder()
	{
		string fileDirectory	= "ios";
		try
		{
			string[] dirs	= System.IO.Directory.GetDirectories(Application.dataPath + "/Plugins/");
			for(int nItter = 0; nItter < dirs.Length; nItter++)
			{
				//	HACK: Support the bugged versions
				string temp	= dirs[nItter].ToLower() + "/";
				if(temp.Contains("plugins/ios/"))
				{
					fileDirectory	= dirs[nItter];
					break;
				}
			}
		}
		catch
		{	}
		return fileDirectory;
	}
}
