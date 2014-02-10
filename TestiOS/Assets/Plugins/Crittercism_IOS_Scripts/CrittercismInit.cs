using UnityEngine;
using System.Collections;

public class CrittercismInit : MonoBehaviour {
	
	private const string CrittercismAppID	= "YOUR_APP_ID";
	
	void Awake () {
		
		CrittercismIOS.Init(CrittercismAppID);
		Destroy(this);
	}
}
