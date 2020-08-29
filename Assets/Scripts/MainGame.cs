using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainGame : MonoBehaviourSingleton<MainGame>
{

    //[SerializeField]
    //RenderManager _renderMan;
    //public RenderManager renderMan { get { return _renderMan; } }
    //[SerializeField]
    //SprayCanControlManager _sprayCanControl;
    //public SprayCanControlManager sprayCanControl { get { return _sprayCanControl; } }

    

    const string m_escape = "escape";

    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        if (Input.GetKey(m_escape))
            Application.Quit();
    }
}
