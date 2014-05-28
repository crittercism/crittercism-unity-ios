using UnityEngine;

public class CrittercismTestGUI : MonoBehaviour
{
        
    void OnGUI ()
    {
        GUIStyle customStyle = new GUIStyle (GUI.skin.button);
        customStyle.fontSize = 30;

        int screenButtonHeight = Screen.height / 8;
        
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

    }

    // Demo stacktraces by calling a few interim methods before crashing
    void causeDivideByZeroException ()
    {
        interimMethod1 ("hi mom", 42);
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
