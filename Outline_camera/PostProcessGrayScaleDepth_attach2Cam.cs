using UnityEngine;
using System.Collections;

//so that we can see changes we make without having to run the game

[ExecuteInEditMode]
public class PostProcessGrayScaleDepth : MonoBehaviour {
	//public GameObject matobj;
	public Material mat;
	private Camera thisCamera;

	void Start () {
		thisCamera = GetComponent<Camera>();
		thisCamera.depthTextureMode = DepthTextureMode.DepthNormals;
		//mat = matobj.GetComponent<Renderer>().;
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination){
		Graphics.Blit(source,destination,mat);
		//mat is the material which contains the shader
		//we are passing the destination RenderTexture to
	}
}