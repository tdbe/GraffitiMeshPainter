// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Custom/3DPaintAccumulator_Amplify_Multipass"
{
	Properties
	{
		_EdgeLength ( "Edge length", Range( 2, 50 ) ) = 15
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "Tessellation.cginc"
		#pragma target 5.0
		#pragma surface surf StandardCustomLighting keepalpha addshadow fullforwardshadows noforwardadd exclude_path:deferred vertex:vertexDataFunc 
		struct Input
		{
			fixed filler;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			fixed Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float _EdgeLength;

		void vertexDataFunc( inout appdata_full v )
		{
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			c.rgb = 0;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
			o.Emission = float4( 0,0,0,0 ).rgb;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=15301
2182;24;1445;646;2017.209;604.9462;2.351155;True;True
Node;AmplifyShaderEditor.FunctionNode;4;-475.5732,47.0462;Float;False;AmplifyStandardShader;6;;4;a556fec095486464b94c9511392aad26;0;0;12;COLOR;0;FLOAT3;35;COLOR;34;COLOR;33;FLOAT;36;FLOAT;37;COLOR;38;COLOR;39;COLOR;40;COLOR;41;INT;42;COLOR;43
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;7;Float;ASEMaterialInspector;0;7;Standard;Custom/3DPaintAccumulator_Amplify_Multipass;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;0;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;True;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;-1;False;-1;-1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;0;-1;-1;0;0;0;False;0;0;0;False;-1;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;0;0;4;0
WireConnection;0;1;4;35
WireConnection;0;2;4;34
WireConnection;0;3;4;33
WireConnection;0;4;4;36
WireConnection;0;5;4;37
WireConnection;0;6;4;38
WireConnection;0;7;4;39
WireConnection;0;11;4;40
WireConnection;0;12;4;41
WireConnection;0;14;4;42
WireConnection;0;15;4;43
ASEEND*/
//CHKSM=4E00F2E97590C136BC81DA382449180C8F71E7AE