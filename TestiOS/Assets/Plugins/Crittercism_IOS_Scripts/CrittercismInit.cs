using UnityEngine;
using System.Collections;

public class CrittercismInit : MonoBehaviour {
	
	private const string CrittercismAppID	= "4fea23d1c8f9745183000005";
	private const string CrittercismKey		= "hrnel67igbctkul51iecsrxj3w0b";
	private const string CrittercismSecret	= "6tekxnxlwyjuq8mben4zkgbf5ty29o7p";
	
	void Awake () {
		
		CrittercismIOS.Init(CrittercismAppID, CrittercismKey, CrittercismSecret);
		Destroy(this);
	}
}
