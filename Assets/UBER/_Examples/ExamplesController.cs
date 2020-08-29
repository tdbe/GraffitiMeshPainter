using UnityEngine;
using System.Collections;
using UnityEngine.UI;

//using FullInspector;
//public class ExamplesController : BaseBehavior<JsonNetSerializer> {

public class ExamplesController : MonoBehaviour {
	public UBER_ExampleObjectParams[] objectsParams;
	
	public Camera mainCamera;
	public UBER_MouseOrbit_DynamicDistance mouseOrbitController;
	public GameObject InteractiveUI;
	
	[Space(10)]
	
	public GameObject autorotateButtonOn;
	public GameObject autorotateButtonOff;
	
	public GameObject togglepostFXButtonOn;
	public GameObject togglepostFXButtonOff;
	
	public float autoRotationSpeed = 30.0f;
	public bool autoRotation=true;
	
	[Space(10)]
	
	public GameObject skyboxSphere1;
	public Cubemap reflectionCubemap1;
	[Range(0f,1f)] public float exposure1=1;
	public GameObject realTimeLight1;
	public Material skyboxMaterial1;
	
	public GameObject skyboxSphere2;
	public Cubemap reflectionCubemap2;
	[Range(0f,1f)] public float exposure2=1;
	public GameObject realTimeLight2;
	public Material skyboxMaterial2;
	
	public GameObject skyboxSphere3;
	public Cubemap reflectionCubemap3;
	[Range(0f,1f)] public float exposure3=1;
	public GameObject realTimeLight3;
	public Material skyboxMaterial3;
	
	public Material skyboxSphereMaterialActive;
	public Material skyboxSphereMaterialInactive;
	
	[Space(10)]
	
	public Slider materialSlider;
	public Slider exposureSlider;
	public Text titleTextArea;
	public Text descriptionTextArea;
	public Text matParamTextArea;
	
	[Space(10)]
	
	public Button buttonSun;
	public Button buttonFrost;

	[Space(10)]
	
	public float hideTimeDelay = 10;
	
	private MeshRenderer currentRenderer;
	private Material currentMaterial;
	private Material originalMaterial;
	
	private float hideTime;
	
	private int currentTargetIndex;
	
	private GameObject skyboxSphereActive;

	
	public void Start() {
		RenderSettings.skybox = skyboxMaterial1;
		realTimeLight1.SetActive (true); realTimeLight2.SetActive (false); realTimeLight3.SetActive(false);
		RenderSettings.customReflection = reflectionCubemap1;
		RenderSettings.reflectionIntensity = exposure1;
		DynamicGI.UpdateEnvironment();
		
		skyboxSphereActive = skyboxSphere1;

		currentTargetIndex=0;
		PrepareCurrentObject();
		for(int i=1; i<objectsParams.Length; i++) {
			objectsParams[i].target.SetActive(false);
		}
		hideTime = Time.time + hideTimeDelay;
		
	}
	
	public void ClickedAutoRotation() {
		autoRotation = !autoRotation;
		autorotateButtonOn.SetActive(autoRotation);
		autorotateButtonOff.SetActive(!autoRotation);
	}
	
	public void ClickedArrow(bool rightFlag) {
		objectsParams[currentTargetIndex].target.transform.rotation = Quaternion.identity;
		objectsParams[currentTargetIndex].target.SetActive(false);
		// restore material
		if (currentRenderer != null && originalMaterial != null) {
			Material[] mats=currentRenderer.sharedMaterials;
			mats[ objectsParams[currentTargetIndex].submeshIndex ] = originalMaterial;
			currentRenderer.sharedMaterials=mats;
			// if (!(originalMaterial is ProceduralMaterial)) {
			// 	Object.DestroyObject (currentMaterial);
			// }
		}
		
		if (rightFlag) {
			currentTargetIndex = (currentTargetIndex + 1) % objectsParams.Length;
		} else {
			currentTargetIndex=(currentTargetIndex+objectsParams.Length-1)%objectsParams.Length;
		}
		
		PrepareCurrentObject();
		
		objectsParams[currentTargetIndex].target.SetActive(true);
		mouseOrbitController.target = objectsParams[currentTargetIndex].target;
		mouseOrbitController.targetFocus = objectsParams[currentTargetIndex].target.transform.Find ("Focus");
		mouseOrbitController.Reset();
	}
	
	public void Update() {
		skyboxSphereActive.transform.Rotate (Vector3.up, Time.deltaTime * 200, Space.World);
		
		if (objectsParams[currentTargetIndex].Title=="Ice block" && Input.GetKeyDown (KeyCode.L)) {
			GameObject go=objectsParams[currentTargetIndex].target.transform.Find("Amber").gameObject;
			go.SetActive(!go.activeSelf);
		}
		
		if (Input.GetKeyDown (KeyCode.RightArrow)) {
			ClickedArrow(true);
		} else if (Input.GetKeyDown (KeyCode.LeftArrow)) {
			ClickedArrow(false);
		}
		
		if (autoRotation) {
			objectsParams[currentTargetIndex].target.transform.Rotate(Vector3.up, Time.deltaTime*autoRotationSpeed, Space.World);
		}
		
		if (Input.GetAxis("Mouse X")!=0 || Input.GetAxis("Mouse Y")!=0) {
			hideTime=Time.time+hideTimeDelay;
			InteractiveUI.SetActive(true);
		}
		if (Time.time > hideTime) {
			InteractiveUI.SetActive(false);
		}
	}
	
	public void ButtonPressed(Button button) {
		RectTransform rt = button.GetComponent<RectTransform> ();
		Vector3 pos = rt.anchoredPosition;
		pos.x += 2;
		pos.y -= 2;
		rt.anchoredPosition = pos;
	}
	public void ButtonReleased(Button button) {
		RectTransform rt = button.GetComponent<RectTransform> ();
		Vector3 pos = rt.anchoredPosition;
		pos.x -= 2;
		pos.y += 2;
		rt.anchoredPosition = pos;
	}
	
	public void ButtonEnterScale(Button button) {
		RectTransform rt = button.GetComponent<RectTransform> ();
		rt.localScale = new Vector3 (1.1f, 1.1f, 1.1f);
	}
	public void ButtonLeaveScale(Button button) {
		RectTransform rt = button.GetComponent<RectTransform> ();
		rt.localScale = new Vector3 (1.0f, 1.0f, 1.0f);
	}
	
	public void SliderChanged(Slider slider) {
		mouseOrbitController.disableSteering = true;
		
		if (objectsParams [currentTargetIndex].materialProperty == "fallIntensity") {
			// global param
			UBER_GlobalParams weather_controller=mainCamera.GetComponent<UBER_GlobalParams>();
			weather_controller.fallIntensity=slider.value;
		} else if (objectsParams [currentTargetIndex].materialProperty == "_SnowColorAndCoverage") {
			Color col = currentMaterial.GetColor("_SnowColorAndCoverage");
			col.a=slider.value;
			currentMaterial.SetColor("_SnowColorAndCoverage", col );
			slider.wholeNumbers=false;
		} else if (objectsParams [currentTargetIndex].materialProperty == "SPECIAL_Tiling") {
			currentMaterial.SetTextureScale("_MainTex", new Vector2(slider.value, slider.value) );
			slider.wholeNumbers=true;
		} else {
			currentMaterial.SetFloat (objectsParams [currentTargetIndex].materialProperty, slider.value);
			slider.wholeNumbers=false;
		}
	}
	
	public void ExposureChanged(Slider slider) {
        //
        // Unity's tonemapper install image effect to get it working
        //
        UnityStandardAssets.CinematicEffects.TonemappingColorGrading tm = mainCamera.gameObject.GetComponent<UnityStandardAssets.CinematicEffects.TonemappingColorGrading> ();
        UnityStandardAssets.CinematicEffects.TonemappingColorGrading.TonemappingSettings tmSettings = tm.tonemapping;
        tmSettings.exposure = slider.value;
        tm.tonemapping = tmSettings;
    }
	
	public void ClickedSkybox1() {
		skyboxSphereActive.transform.rotation = Quaternion.identity;
		Renderer rend = skyboxSphereActive.GetComponentInChildren<Renderer>();
		rend.sharedMaterial = skyboxSphereMaterialInactive;
		
		skyboxSphereActive = skyboxSphere1;
		rend = skyboxSphereActive.GetComponentInChildren<Renderer>();
		rend.sharedMaterial = skyboxSphereMaterialActive;
		
		RenderSettings.customReflection = reflectionCubemap1;
		RenderSettings.reflectionIntensity = exposure1;
		RenderSettings.skybox = skyboxMaterial1;
		
		realTimeLight1.SetActive (true); realTimeLight2.SetActive (false); realTimeLight3.SetActive(false);

		DynamicGI.UpdateEnvironment();
	}
	
	public void ClickedSkybox2() {
		skyboxSphereActive.transform.rotation = Quaternion.identity;
		Renderer rend = skyboxSphereActive.GetComponentInChildren<Renderer>();
		rend.sharedMaterial = skyboxSphereMaterialInactive;
		
		skyboxSphereActive = skyboxSphere2;
		rend = skyboxSphereActive.GetComponentInChildren<Renderer>();
		rend.sharedMaterial = skyboxSphereMaterialActive;
		
		RenderSettings.customReflection = reflectionCubemap2;
		RenderSettings.reflectionIntensity = exposure2;
		RenderSettings.skybox = skyboxMaterial2;
		
		realTimeLight1.SetActive (false); realTimeLight2.SetActive (true); realTimeLight3.SetActive(false);

		DynamicGI.UpdateEnvironment();
	}
	
	public void ClickedSkybox3() {
		skyboxSphereActive.transform.rotation = Quaternion.identity;
		Renderer rend = skyboxSphereActive.GetComponentInChildren<Renderer>();
		rend.sharedMaterial = skyboxSphereMaterialInactive;
		
		skyboxSphereActive = skyboxSphere3;
		rend = skyboxSphereActive.GetComponentInChildren<Renderer>();
		rend.sharedMaterial = skyboxSphereMaterialActive;
		
		RenderSettings.customReflection = reflectionCubemap3;
		RenderSettings.reflectionIntensity = exposure3;
		RenderSettings.skybox = skyboxMaterial3;
		
		realTimeLight1.SetActive (false); realTimeLight2.SetActive (false); realTimeLight3.SetActive(true);
		DynamicGI.UpdateEnvironment();
	}
	
	public void TogglePostFX() {
		//
		// 3rd party effects
		//
        UnityStandardAssets.CinematicEffects.TonemappingColorGrading tm = mainCamera.gameObject.GetComponent<UnityStandardAssets.CinematicEffects.TonemappingColorGrading>();
		
		togglepostFXButtonOn.SetActive(!tm.enabled);
		togglepostFXButtonOff.SetActive(tm.enabled);
		
		exposureSlider.interactable = !tm.enabled;
		
		tm.enabled=!tm.enabled;

        UnityStandardAssets.CinematicEffects.Bloom bl = mainCamera.gameObject.GetComponent<UnityStandardAssets.CinematicEffects.Bloom>();
        bl.enabled = tm.enabled;
    }

    public void SetTemperatureSun() {
		ColorBlock cols = buttonSun.colors;
		cols.normalColor = new Color (1, 1, 1, 0.7f);
		buttonSun.colors = cols;
		
		cols = buttonFrost.colors;
		cols.normalColor = new Color (1, 1, 1, 0.2f);
		buttonFrost.colors = cols;
		UBER_GlobalParams weather_controller=mainCamera.GetComponent<UBER_GlobalParams>();
		weather_controller.temperature=20;
	}
	
	public void SetTemperatureFrost() {
		ColorBlock cols = buttonSun.colors;
		cols.normalColor = new Color (1, 1, 1, 0.2f);
		buttonSun.colors = cols;
		
		cols = buttonFrost.colors;
		cols.normalColor = new Color (1, 1, 1, 0.7f);
		buttonFrost.colors = cols;
		UBER_GlobalParams weather_controller=mainCamera.GetComponent<UBER_GlobalParams>();
		weather_controller.temperature=-20;
	}
	
	private void PrepareCurrentObject() {
		currentRenderer = objectsParams[currentTargetIndex].renderer;
		if (currentRenderer) {
			originalMaterial=currentRenderer.sharedMaterials[ objectsParams[currentTargetIndex].submeshIndex ];
			// if (!(originalMaterial is ProceduralMaterial)) {
			// 	currentMaterial=Object.Instantiate<Material>(originalMaterial);
			// } else {
				currentMaterial=originalMaterial;
			//}
			Material[] mats=currentRenderer.sharedMaterials;
			mats[ objectsParams[currentTargetIndex].submeshIndex ]=currentMaterial;
			currentRenderer.sharedMaterials=mats;
		}
		bool empty = objectsParams [currentTargetIndex].materialProperty == null || objectsParams [currentTargetIndex].materialProperty == string.Empty;
		if (empty) {
			materialSlider.gameObject.SetActive(false);
		} else {
			materialSlider.gameObject.SetActive(true);
			materialSlider.minValue = objectsParams [currentTargetIndex].SliderRange.x;
			materialSlider.maxValue = objectsParams [currentTargetIndex].SliderRange.y;
			if (objectsParams [currentTargetIndex].materialProperty == "fallIntensity") {
				// global param
				UBER_GlobalParams weather_controller=mainCamera.GetComponent<UBER_GlobalParams>();
				materialSlider.value=weather_controller.fallIntensity;
				weather_controller.UseParticleSystem = true;
				buttonSun.gameObject.SetActive(true);
				buttonFrost.gameObject.SetActive(true);
			} else {
				// material param
				UBER_GlobalParams weather_controller = mainCamera.GetComponent<UBER_GlobalParams> ();
				weather_controller.UseParticleSystem = false;
				buttonSun.gameObject.SetActive(false);
				buttonFrost.gameObject.SetActive(false);
				if (originalMaterial.HasProperty (objectsParams [currentTargetIndex].materialProperty)) {
					if (objectsParams[currentTargetIndex].materialProperty == "_SnowColorAndCoverage") {
						Color col = originalMaterial.GetColor("_SnowColorAndCoverage");
						materialSlider.value = col.a;
					} else {
						materialSlider.value = originalMaterial.GetFloat (objectsParams [currentTargetIndex].materialProperty);
					}
				} else {
					if (objectsParams [currentTargetIndex].materialProperty == "SPECIAL_Tiling") {
						materialSlider.value = 1; // special case - tiling
					}
				}
			}
		}
		titleTextArea.text = objectsParams [currentTargetIndex].Title;
		descriptionTextArea.text = objectsParams [currentTargetIndex].Description;
		matParamTextArea.text = objectsParams [currentTargetIndex].MatParamName;
		Vector2 anchoredPosition = titleTextArea.rectTransform.anchoredPosition;
		anchoredPosition.y = (empty ? 50 : 110) + descriptionTextArea.preferredHeight;
		titleTextArea.rectTransform.anchoredPosition = anchoredPosition;
		//		Debug.Log (descriptionTextArea.preferredHeight);
	}
}


[System.Serializable]
public class UBER_ExampleObjectParams {
	public GameObject target;
	public string materialProperty;
	public MeshRenderer renderer;
	public int submeshIndex;
	public Vector2 SliderRange;
	public string Title;
	public string MatParamName;
	[TextArea(2,5)] public string Description;
}