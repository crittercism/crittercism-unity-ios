using UnityEngine;

public class CrittercismTestGUI : MonoBehaviour
{
        
    void OnGUI ()
    {
        GUIStyle customStyle = new GUIStyle (GUI.skin.button);
        customStyle.fontSize = 30;

        int screenButtonHeight = Screen.height / 12;
        
        if (GUI.Button (new Rect (0, 0, Screen.width, screenButtonHeight), "Leave breadcrumb", customStyle)) {
            CrittercismIOS.LeaveBreadcrumb ("BreadCrumb");
        }
        
        if (GUI.Button (new Rect (0, screenButtonHeight, Screen.width, screenButtonHeight), "Set User Metadata", customStyle)) {
            CrittercismIOS.SetUsername ("Username");
            CrittercismIOS.SetValue ("5", "Game Level");
            CrittercismIOS.SetValue ("Crashes a lot", "Status");
        }
        
        if (GUI.Button (new Rect (0, screenButtonHeight * 2, Screen.width, screenButtonHeight), "C# Crash", customStyle)) {
			causeDivideByZeroException ();
        }
        
        if (GUI.Button (new Rect (0, screenButtonHeight * 3, Screen.width, screenButtonHeight), "C# Handled Exception", customStyle)) {
            try {
                causeDivideByZeroException ();
            } catch (System.Exception e) {
                CrittercismIOS.LogHandledException (e);
            }
        }
		if (GUI.Button (new Rect (0, screenButtonHeight * 4, Screen.width, screenButtonHeight), "C# Null Pointer Exception", customStyle)) {
			try {
				causeNullPointerException ();
			} catch (System.Exception e) {
				CrittercismIOS.LogHandledException (e);
			}
		}

		if (GUI.Button (new Rect (0, screenButtonHeight * 5, Screen.width, screenButtonHeight), "Begin Transaction", customStyle)) {
			CrittercismIOS.BeginTransaction("UnityIOS");
		}

		if (GUI.Button (new Rect (0, screenButtonHeight * 6, Screen.width, screenButtonHeight), "Begin Transaction with Value", customStyle)) {
			CrittercismIOS.BeginTransaction("UnityIOS", 300);
		}
		
		if (GUI.Button (new Rect (0, screenButtonHeight * 7, Screen.width, screenButtonHeight), "End Transaction", customStyle)) {
			CrittercismIOS.EndTransaction("UnityIOS");
		}
		
		if (GUI.Button (new Rect (0, screenButtonHeight * 8, Screen.width, screenButtonHeight), "Fail Transaction", customStyle)) {
			CrittercismIOS.FailTransaction("UnityIOS");
		}
		
		if (GUI.Button (new Rect (0, screenButtonHeight * 9, Screen.width, screenButtonHeight), "Set Transaction Value", customStyle)) {
			CrittercismIOS.SetTransactionValue("UnityIOS", 500);
		}
		
		if (GUI.Button (new Rect (0, screenButtonHeight * 10, Screen.width, screenButtonHeight), "Get Transaction Value", customStyle)) {
			int value = CrittercismIOS.GetTransactionValue("UnityIOS");
			Debug.Log("TransactionValue is: " + value);
		}
    }

    // Demo stacktraces by calling a few interim methods before crashing
    void causeDivideByZeroException ()
    {
        interimMethod1 ("hi mom", 42);
    }

	void causeNullPointerException ()
	{
		object o = null;
		o.GetHashCode ();
	}
    
    void interimMethod1 (string demoParam1, int demoParam2)
    {
        interimMethod2 (7, 7, "abc");
    }

    void interimMethod2 (byte demoParam1, int demoParam2, string demoParam3)
    {
        finallyDoTheCrash (100);
    }

    void finallyDoTheCrash (int number)
    {
        number /= 0;    
    }

}
