using UnityEngine;
using System.Collections;

//
// script used in deferred lighting mode to give light direction to relief shaders
//
// 1. when added to object w/o renderer (for example camera) it will affect every material using UBER shaders in the scene
// 2. when added to object with renderer it will only affect materials of this object
// (you can't mix both versions on the scene as result might be unpredictible)
// when working globally just drag'n'drop the script on the light you'd like relief shaders to follow
//

[AddComponentMenu("UBER/Apply Light for Deferred")]
[ExecuteInEditMode]
public class UBER_applyLightForDeferred : MonoBehaviour {
	public Light lightForSelfShadowing;
	private Renderer _renderer;

	void Start() {
		Reset ();
	}

	void Reset() {
		if (GetComponent<Light>() && lightForSelfShadowing==null) {
			lightForSelfShadowing=GetComponent<Light>();
		}
		if (GetComponent<Renderer>() && _renderer==null) {
			_renderer=GetComponent<Renderer>();
		}
	}
	
	void Update () {
		if (lightForSelfShadowing) {
			if (_renderer) {
				if (lightForSelfShadowing.type==LightType.Directional) {
					for(int i=0; i<_renderer.sharedMaterials.Length; i++) {
						_renderer.sharedMaterials[i].SetVector("_WorldSpaceLightPosCustom", -lightForSelfShadowing.transform.forward);
					}
				} else {
					for(int i=0; i<_renderer.materials.Length; i++) {
						_renderer.sharedMaterials[i].SetVector("_WorldSpaceLightPosCustom", new Vector4(lightForSelfShadowing.transform.position.x, lightForSelfShadowing.transform.position.y, lightForSelfShadowing.transform.position.z, 1));
					}
				}
			} else {
				if (lightForSelfShadowing.type==LightType.Directional) {
					Shader.SetGlobalVector("_WorldSpaceLightPosCustom", -lightForSelfShadowing.transform.forward);
				} else {
					Shader.SetGlobalVector("_WorldSpaceLightPosCustom", new Vector4(lightForSelfShadowing.transform.position.x, lightForSelfShadowing.transform.position.y, lightForSelfShadowing.transform.position.z, 1));
				}
			}
		}
	}
}
