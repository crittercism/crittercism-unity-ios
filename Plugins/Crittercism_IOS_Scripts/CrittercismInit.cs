using UnityEngine;
using System.Collections;

public class CrittercismInit : MonoBehaviour {
	
	private const string CrittercismAppID	= "/*Your Application ID Here*/";
	
	void Awake () {
		
		CrittercismIOS.Init(CrittercismAppID);
		Destroy(this);
	}
}
