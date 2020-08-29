// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AmplifyStandard_Tess"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			fixed filler;
		};

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=15301
2182;24;1445;646;1104.114;669.6998;2.197856;True;True
Node;AmplifyShaderEditor.SamplerNode;22;-137.9137,271.8711;Float;True;Property;_OcclusionTex;_OcclusionTex;10;0;Create;True;0;0;False;0;None;a794d09b4c27e044191f337596e4616f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;44;-1182.003,393.6512;Float;False;Property;_NormalDetailAmount;_NormalDetailAmount;18;0;Create;True;0;0;False;0;1;1.77;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-641.9626,-210.4487;Float;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;31;-871.7963,338.4503;Float;True;Property;_NormalDetailTex;_NormalDetailTex;17;0;Create;True;0;0;False;0;None;302951faffe230848aa0d3df7bb70faa;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;60;190.8442,139.2386;Float;False;Property;_OcclusionAmount;_OcclusionAmount;11;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;11;-947.6179,736.5889;Float;True;Property;_HeightmapTex;_HeightmapTex;7;0;Create;True;0;0;False;0;None;314fd349759024244b7aceb27d9c5d27;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;41;-1165.591,-18.34243;Float;True;Property;_DetailMaskTex;_DetailMaskTex;15;0;Create;True;0;0;False;0;None;314fd349759024244b7aceb27d9c5d27;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;-489.2731,5.467143;Float;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-763.2821,-747.0547;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCGrayscale;54;208.9479,328.3257;Float;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;19;47.48378,-187.1371;Float;True;Property;_MetallicTex;_MetallicTex;2;0;Create;True;0;0;False;0;None;314fd349759024244b7aceb27d9c5d27;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;47;-1005.05,-533.1224;Float;False;Property;_NormalAmount;_NormalAmount;6;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;50;150.6134,223.7246;Float;False;Property;_OcclusionExponentialAmount;_OcclusionExponentialAmount;12;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;26;99.84628,759.3977;Float;True;Property;_TranslucencyTex;_TranslucencyTex;13;0;Create;True;0;0;False;0;None;7fd348dde11531b449f7228a3e6e02b6;True;0;True;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;37;-922.3117,-163.2874;Float;False;Property;_DetailSlider;_DetailSlider;16;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;31.09967,-288.9866;Float;False;Property;_MetallicSlider;_MetallicSlider;3;0;Create;True;0;0;False;0;0;0.95;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;13;-879.7903,583.0285;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;39;-327.6875,-950.3199;Float;False;Property;_Color;_Color;0;0;Create;True;0;0;False;0;0,0,0,0;1,1,1,1;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;432.678,719.0059;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;444.3006,334.3606;Float;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;-725.6163,-538.9252;Float;True;Property;_NormalTex;_NormalTex;5;0;Create;True;0;0;False;0;None;7fd348dde11531b449f7228a3e6e02b6;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-544.2886,877.0473;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;46;133.1609,662.6536;Float;False;Property;_TranslucencyAmount;_TranslucencyAmount;14;0;Create;True;0;0;False;0;1;1.06;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-453.8842,-748.6095;Float;True;Property;_MainTex;_MainTex;1;0;Create;True;0;0;False;0;None;84508b93f15f2b64386ec07486afc7a3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;21;85.34923,22.96742;Float;False;Property;_Smoothness;_Smoothness;4;0;Create;True;0;0;False;0;0;0.52;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;9.654617,-850.7771;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-891.7674,983.4048;Float;False;Property;_DisplacementAmount;_DisplacementAmount;8;0;Create;True;0;0;False;0;1;-0.12;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;53;575.0521,195.5625;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;430.2537,-130.6177;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;-557.2843,685.4269;Float;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.IntNode;10;-856.2189,1080.563;Float;False;Property;_TessellationAmount;_TessellationAmount;9;0;Create;True;0;0;False;0;1;5;0;1;INT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-132.2148,-526.9331;Float;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;86;1151.488,91.73489;Float;False;True;2;Float;ASEMaterialInspector;0;0;Standard;AmplifyStandard_Tess;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;0;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;-1;False;-1;-1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;0;0;False;0;0;0;False;-1;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;38;0;37;0
WireConnection;38;1;35;0
WireConnection;31;5;44;0
WireConnection;35;0;41;4
WireConnection;35;1;31;0
WireConnection;54;0;22;0
WireConnection;27;0;46;0
WireConnection;27;1;26;0
WireConnection;55;0;54;0
WireConnection;55;1;22;4
WireConnection;55;2;60;0
WireConnection;6;5;47;0
WireConnection;14;0;11;0
WireConnection;14;1;45;0
WireConnection;1;1;2;0
WireConnection;40;0;1;0
WireConnection;40;1;39;0
WireConnection;53;0;55;0
WireConnection;53;1;50;0
WireConnection;20;0;19;0
WireConnection;20;1;16;0
WireConnection;12;0;13;0
WireConnection;12;1;14;0
WireConnection;49;0;6;0
WireConnection;49;1;38;0
ASEEND*/
//CHKSM=10A32153B0841B7CEE9006C0CC6C45A7CA435B78