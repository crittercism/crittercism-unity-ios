using UnityEngine;
using System.Collections;

public class CrittercismInit : MonoBehaviour {
	
	private const string CrittercismAppID	= "52b105e9d0d8f76a04000007";
	
	void Awake () {
		
		CrittercismIOS.Init(CrittercismAppID);
		Destroy(this);
	}
}
