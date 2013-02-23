using UnityEngine;

public class CrittercismTestGUI : MonoBehaviour
{
	void OnGUI()
	{
		int screenButtonHeight	= Screen.height / 8;
		
		if(GUI.Button(new Rect(0,0,Screen.width,screenButtonHeight), "Null Reference"))
		{
			string crash = null;
			crash	= crash.ToLower();
		}
		
		if(GUI.Button(new Rect(0,screenButtonHeight,Screen.width,screenButtonHeight), "Divide By Zero"))
		{
			int i = 0;
			i = 2 / i;
		}
		
		if(GUI.Button(new Rect(0,screenButtonHeight * 2,Screen.width,screenButtonHeight), "Index Out Of Range"))
		{
			string[] arr	= new string[1];
			arr[2]	= "Crash";
		}
		
		if(GUI.Button(new Rect(0,screenButtonHeight * 3,Screen.width,screenButtonHeight), "Custom Exception"))
		{	throw new System.Exception("Custom Exception");	}
		
		if(GUI.Button(new Rect(0,screenButtonHeight * 4,Screen.width,screenButtonHeight), "Coroutine Custom Exception"))
		{	StartCoroutine(MonoCorutineCrash());	}
		
		if(GUI.Button(new Rect(0,screenButtonHeight * 5,Screen.width,screenButtonHeight), "Coroutine Null Exception"))
		{	StartCoroutine(MonoCorutineNullCrash());	}
		
		if(GUI.Button(new Rect(0,screenButtonHeight * 7,Screen.width,screenButtonHeight), "Test Messages"))
		{
			Debug.Log("BreadcrumbTest");
			CrittercismIOS.LeaveBreadcrumb("BreadCrumb");
			
			Debug.Log("AgeTest");
			CrittercismIOS.SetAge(26);
			
			Debug.Log("EMailTest");
			CrittercismIOS.SetEmail("email@test.com");
			
			Debug.Log("UserTest");
			CrittercismIOS.SetUsername("Username");
			
			Debug.Log("ValueTest");
			CrittercismIOS.SetValue("A Value", "A Key");
			
			Debug.Log("EventTest");
//			CrittercismIOS.LogEvent("EventTest", null);
		}
	}
	
	System.Collections.IEnumerator MonoCorutineNullCrash()
	{
		string crash = null;
		crash	= crash.ToLower();
		yield break;
	}
	
	System.Collections.IEnumerator MonoCorutineCrash()
	{	
		throw new System.Exception("Custom Coroutine Exception");
	}
}
