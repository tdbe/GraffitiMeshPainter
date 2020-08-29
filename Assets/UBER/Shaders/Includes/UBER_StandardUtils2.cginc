#ifndef UBER_STANDARD_UTILS2_INCLUDED
#define UBER_STANDARD_UTILS2_INCLUDED

#if defined(ZWRITE) && (defined(SHADOWS_CUBE) || defined(SHADOWS_DEPTH))
	// we're resolving depth for shadow casting (collecting in forward)
	// in deferred this will be defined only for shadow casters (camera depth is taken from native buffer)
	#define DEPTH_PASS
#endif

#if !defined(POM) && (defined(_PARALLAX_POM) || defined(_PARALLAX_POM_ZWRITE) || defined(_PARALLAX_POM_SHADOWS))
	#define POM
#endif

#if !defined(DISTANCE_MAP) && (defined(_POM_DISTANCE_MAP) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_DISTANCE_MAP_SHADOWS))
	#define DISTANCE_MAP
#endif

#if !defined(EXTRUSION_MAP) && (defined(_POM_EXTRUSION_MAP) || defined(_POM_EXTRUSION_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_SHADOWS))
	#define EXTRUSION_MAP
#endif

#if !defined(TRIPLANAR) && (defined(TRIPLANAR_SELECTIVE))
 	#define TRIPLANAR
#endif

#if (defined(_PARALLAX_POM_ZWRITE) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_ZWRITE)) && !defined(ZWRITE)
	#define ZWRITE 1
#endif

#include "UnityCG.cginc"
#include "UnityStandardUtils.cginc"
//#include "../UBER_StandardConfig.cginc"

#if defined(UNITY_COMPILER_HLSL)
	#if !defined(UNITY_LOOP)
		#define UNITY_LOOP [loop]
	#endif
#else
	#if !defined(UNITY_LOOP)
		#define UNITY_LOOP
	#endif
#endif

#if ( defined(ZWRITE) || (defined(_SNOW) && (defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP))) ) && !defined(TRIPLANAR_SELECTIVE)
	#if !defined(RAYLENGTH_AVAILABLE)
		#define RAYLENGTH_AVAILABLE
	#endif
#endif

#if defined(SILHOUETTE_CURVATURE_MAPPED)
float4 _ObjectNormalsTex_TexelSize;
#endif

#ifdef _TANGENT_TO_WORLD
	half3x3 ExtractTangentToWorldPerPixel(half4 tan2world0, half4 tan2world1, half4 tan2world2)
	{
		half3 t = tan2world0.xyz;
		half3 b = tan2world1.xyz;
		half3 n = tan2world2.xyz;

	#if UNITY_TANGENT_ORTHONORMALIZE
		n = normalize(n);

		// ortho-normalize Tangent
		t = normalize (t - n * dot(t, n));

		// recalculate Binormal
		half3 newB = cross(n, t);
		b = newB * sign (dot (newB, b));
	#endif

		return half3x3(t, b, n);
	}
#else
	half3x3 ExtractTangentToWorldPerPixel(half4 tan2world0, half4 tan2world1, half4 tan2world2)
	{
		return half3x3(0,0,0,0,0,0,0,0,0);
	}
#endif

// here we displace inward (similar to POM)
half2 ParallaxOffset1StepAlt(half h, half height, half3 viewDir)
{
	h = (1 - h) * height;
#if defined(TRIPLANAR_SELECTIVE)
	half3 v = (viewDir); // (already normalized)
#else
	half3 v = half3(-viewDir.xy, viewDir.z); // (already normalized)	
#endif
	v.z += 1;
	return h * (v.xy / v.z);
}

// texLodUsed=true used in tessellation - the flag is static one and doesn't lead to dynamic branching
float GetH(inout fixed4 i_vertex_color, float4 texcoords, bool texLodUsed, float level) {
	#if defined(_TWO_LAYERS)
		float4 vertex_color=i_vertex_color;
		#if defined(_PARALLAXMAP_2MAPS)	
			float2 hgt;
			if (texLodUsed) {
				hgt = float2(tex2Dlod(_ParallaxMap2, float4(texcoords.zw,level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, float4(texcoords.xy,level.xx)).PARALLAX_CHANNEL);
			} else {
				hgt = float2(tex2D (_ParallaxMap2, texcoords.zw).PARALLAX_CHANNEL, tex2D (_ParallaxMap, texcoords.xy).PARALLAX_CHANNEL);
			}
		#else
			float4 heightTexVal;
			if (texLodUsed) {
				heightTexVal=tex2Dlod(_ParallaxMap, float4(texcoords.xy, level.xx));
			} else {
				heightTexVal=tex2D(_ParallaxMap, texcoords.xy);
			}
			float2 hgt = float2(heightTexVal.PARALLAX_CHANNEL_2ND_LAYER, heightTexVal.PARALLAX_CHANNEL);
		#endif
		float2 control=float2(__VERTEX_COLOR_CHANNEL_LAYER, 1-__VERTEX_COLOR_CHANNEL_LAYER);
		control*=hgt+0.01;			// height evaluation
		control*=control; 			// compress
		control/=dot(control,1);	// normalize
		control*=control;			// compress
		control*=control;			// compress
		control/=dot(control,1);	// normalize
		__VERTEX_COLOR_CHANNEL_LAYER=control.x; // write blending value back into the right vertex_color channel variable
		i_vertex_color=vertex_color; // overwrite heightblended vertex_color value
		return lerp(hgt.x, hgt.y, __VERTEX_COLOR_CHANNEL_LAYER);
	#else
		if (texLodUsed) {
			return tex2Dlod(_ParallaxMap, float4(texcoords.xy, level.xx)).PARALLAX_CHANNEL;
		} else {
			return tex2D (_ParallaxMap, texcoords.xy).PARALLAX_CHANNEL;
		}
	#endif
}

#if (defined(_PARALLAX_POM) || defined(_PARALLAX_POM_ZWRITE) || defined(_PARALLAX_POM_SHADOWS)) && defined(SILHOUETTE_CURVATURE_MAPPED)
void GetTanBasisPerPixel(float4 uvmip, inout half3x3 _TBN, inout float normStamp, inout float2 texture2ObjectRatio) {
	half4 normTexVal=tex2Dlod(_ObjectNormalsTex, uvmip);
	half3 _N=normTexVal.xyz;
	//bool out_uv_bound_flag = false;//all(_N==0);
	float new_normStamp=dot(_N,1); // would be safier to make it like this: distance (_N*2-1, _TBN[2]), but this normStamp comparator should work in most cases
	
	// skip on flats (use basis from prev step)
	UNITY_BRANCH if (normStamp!=new_normStamp) {
		half4 _T=tex2Dlod(_ObjectTangentsTex, uvmip).xyzw;
		
		// decode scale ratio from textures
		float2 Scl;
		Scl.x=(normTexVal.w*2-1)*12; // max scale ratio - 12 (set the same in BakeProps.shader !)
		Scl.y=abs((_T.w*2-1)*12);
		Scl=float2(1.0,1.0)/Scl;
		texture2ObjectRatio=_MainTex_ST.xy*Scl;
		
		_N=_N*2-1;
		_T.xyz=_T.xyz*2-1;
		_T.w = _T.w>=0.5 ? 1:-1;
		half3 _B=cross(_N,_T.xyz)*_T.w;
		_TBN=half3x3(_T.xyz, _B, _N);
	}
}
#endif

// UBER - 3 states (None, Parallax, POM)
float4 Parallax (float4 texcoords, inout half3 viewDir, inout half3x3 i_tanToWorld, float3 i_posWorld, inout half4 i_vertex_color, float2 _ddx, float2 _ddy, half snowVal, inout half actH, inout float4 outRayPos, inout float2 outTexture2WorldRatio, inout float rayLength, float3 tangentBasisScaled, float4 SclCurv, half blendFade)
{

// init actH if needed
#if !defined(POM) && !defined(DISTANCE_MAP) && !defined(EXTRUSION_MAP)
	#if defined(TRIPLANAR_SELECTIVE)
		// actH already inited
	#else
		actH = GetH(/* inout */ i_vertex_color, texcoords, false, 0);
	#endif
	#if defined(_TESSELLATION)
		return texcoords; // in tessellation mode we don't affect texcoords here (the all we need is actH value calculated above)
	#endif
	#if defined(_SNOW)
		actH = saturate( actH + saturate(snowVal-0.5)*0.05*_SnowDeepSmoothen );
	#endif
	#if defined(GEOM_BLEND)
		actH = lerp(actH, 1, i_vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
	#endif
#endif	

#if ( !defined(_PARALLAXMAP) && !defined(_PARALLAXMAP_2MAPS) && !defined(POM) && !defined(DISTANCE_MAP) && !defined(EXTRUSION_MAP) )
	// no parallax
	return texcoords;
#else

	#if defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS)

		#if defined(_TWO_LAYERS)
			#if defined(VERTEX_COLOR_CHANNEL_LAYER)
				float2 offset = ParallaxOffset1StepAlt(actH, lerp(_Parallax2, _Parallax, i_vertex_color.VERTEX_COLOR_CHANNEL_LAYER), viewDir);
			#else
				float2 offset = ParallaxOffset1StepAlt(actH, lerp(_Parallax2, _Parallax, i_vertex_color.r), viewDir);
			#endif
		#else
			float2 offset = ParallaxOffset1StepAlt(actH, _Parallax, viewDir);
		#endif
		
	#elif !defined(_TWO_LAYERS)
	
		#if FIX_SUBSTANCE_BUG
			float4 ParallaxMap_TexelSize=heightMapTexelSize;
		#else
			float4 ParallaxMap_TexelSize=_ParallaxMap_TexelSize;
		#endif	
		
		// POM
		float2 hgtDDX = _ddx * ParallaxMap_TexelSize.zw;
		float2 hgtDDY = _ddy * ParallaxMap_TexelSize.zw;
//		float2 hgtDDX = ddx( texcoords.xy*ParallaxMap_TexelSize.zw );
//		float2 hgtDDY = ddy( texcoords.xy*ParallaxMap_TexelSize.zw );
		float d = max( dot( hgtDDX, hgtDDX ), dot( hgtDDY, hgtDDY ) );
		float heightMapMIP = max(0, 0.5*log2(d))+_ReliefMIPbias;
		
		#if defined(DEPTH_PASS)
			heightMapMIP+=DEPTH_PASS_MIP_ADD; // higher mip offset for zwrite depth/shadow caster
		#endif		
		
		#if defined(SILHOUETTE_CURVATURE_MAPPED)
			heightMapMIP=min(5,heightMapMIP);
		#endif
		
		//o.Emission.r+=heightMapMIP;
		const float _WAVELENGTH = 1;
		#if defined(VERTEX_COLOR_CHANNEL_POMZ)
			float rayPosZStart = _POM_MeshIsVolume ? i_vertex_color.VERTEX_COLOR_CHANNEL_POMZ : 1;
		#else
			float rayPosZStart = 1;
		#endif
		#if defined(_SNOW)
			float4 rayPos = float4(texcoords.xy, rayPosZStart, heightMapMIP+snowVal);
		#else
			float4 rayPos = float4(texcoords.xy, rayPosZStart, heightMapMIP);
		#endif
		
		float2 texture2ObjectRatio=_MainTex_ST.xy*SclCurv.xy;
		#if defined(SILHOUETTE_CURVATURE_MAPPED)
			float2 uvmip=rayPos.ww+exp2(_ObjectNormalsTex_TexelSize.zz*ParallaxMap_TexelSize.xx);
			
			// viewDir is defined in object space
			half3x3 _TBN=0;
			float normStamp=-1;
			float4 _MainTex_ST_inv;
			_MainTex_ST_inv.xy=1.0/_MainTex_ST.xy;
			_MainTex_ST_inv.zw=-_MainTex_ST.zw*_MainTex_ST_inv.xy;
			GetTanBasisPerPixel( float4(rayPos.xy*_MainTex_ST_inv.xy+_MainTex_ST_inv.zw, uvmip), /* inout */ _TBN, /* inout */ normStamp, /* inout */ texture2ObjectRatio);
			float3 EyeDirTan = mul( _TBN, -viewDir.xyz );
		#else
			float3 EyeDirTan = -viewDir.xyz;
		#endif

//		#if defined(ZWRITE)
//			float3 wsU = i_tanToWorld[0]; // dir of u (tangent) in WorldSpace
//			//wsU=UnityWorldToObjectDir(wsU);
//			float3 wsV = i_tanToWorld[1]; // dir of v (binormal) in WorldSpace
//			//wsV=UnityWorldToObjectDir(wsV);
//			//float2 worldPosAlongTangentBasis=float2(dot(wsU, mul(_World2Object, float4(i_posWorld,1))) , dot(wsV, mul(_World2Object, float4(i_posWorld,1)))); // worldSpace view dir (not normalized!) along tangent U and binormal V
//			float2 worldPosAlongTangentBasis=float2(dot(wsU, i_posWorld) , dot(wsV, i_posWorld)); // worldSpace view dir (not normalized!) along tangent U and binormal V
//
//			float2 _ddxUV=abs(ddx( worldPosAlongTangentBasis )); // measure of worldSpace uv (tangent/binormal) change in screen space ddx
//			float2 _ddyUV=abs(ddy( worldPosAlongTangentBasis )); // measure of worldSpace uv (tangent/binormal) change in screen space ddy
//			float2 _ddxAbs=abs(_ddx);
//			float2 _ddyAbs=abs(_ddy);
//			// below we could use _ddxAbs/_ddxUV only (no comparison and ddy calcs) but it gets unstable depending on screenspace ddx/ddy alignment (divs by zero)

//			float2 texture2ObjectRatio=_MainTex_ST.xy*SclCurv.xy;//(_ddxUV>_ddyUV ? _ddxAbs/_ddxUV : _ddyAbs/_ddyUV); // (comparison and action on vector)
			
//		#endif
		
		EyeDirTan.xy*=texture2ObjectRatio;
		//EyeDirTan=normalize(EyeDirTan);

		#if defined(_SNOW)
			float _DepthS=_Depth*(1-saturate(snowVal-0.4)*0.05*_SnowDeepSmoothen);
		#else
			float _DepthS=_Depth;
		#endif
		_DepthS/=min(texture2ObjectRatio.x, texture2ObjectRatio.y);
		_DepthS=lerp(_DepthS, 0.001, saturate( distance(i_posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
		#if defined(GEOM_BLEND)
			_DepthS = lerp(_DepthS, 0.001, i_vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
		#endif
		float _DepthS_inv=1.0/_DepthS;
		
		EyeDirTan.z/=max(0.001, _DepthS);
		bool hit_flag=false;
		float delta=ParallaxMap_TexelSize.x*exp2(rayPos.w)*_WAVELENGTH;
		#if defined(DEPTH_PASS)
			delta*=exp2(DEPTH_PASS_MIP_ADD); // larger step for zwrite/shadows (we need to gain performance here)
		#endif		
		
		EyeDirTan*=delta/length(EyeDirTan.xy);
		
		float dh_prev=0;
		float h_prev=1.001;
		float _h;
		
		float3 rayPosStart=rayPos.xyz;
		
		#ifdef SILHOUETTE_CURVATURE_BASIC
			float3 rayPosOffset=float3(0,0,rayPos.z);
			float2 curvature=(1.0/(texture2ObjectRatio * texture2ObjectRatio)) * (SclCurv.zw*_CurvatureMultOffset.xy+_CurvatureMultOffset.zw) / _DepthS; // float2(0.95,0)
		#endif
		
		#if !defined(SHADER_API_D3D11) && defined(SAFE_LOOPS)
		UNITY_LOOP for(int i=0; i<256; i++) {
		#else
		UNITY_LOOP for(int i=0; i<_DistSteps; i++) {
		#endif
			#ifdef SILHOUETTE_CURVATURE_BASIC
				rayPosOffset+=EyeDirTan;
				rayPos.xy+=EyeDirTan.xy;
				rayPos.z=rayPosOffset.z + dot(curvature.xy, rayPosOffset.xy*rayPosOffset.xy);
			#else
				rayPos.xyz+=EyeDirTan;
			#endif		
			
			_h=tex2Dlod(_ParallaxMap, rayPos.xyww).PARALLAX_CHANNEL;
			hit_flag=_h >= rayPos.z;
			#if defined(SILHOUETTE_CURVATURE_BASIC) || defined(SILHOUETTE_CURVATURE_MAPPED)
				if ((hit_flag || rayPos.z>1)) break;
			#else
				if (hit_flag) break; 
			#endif
			h_prev=_h;
			dh_prev = rayPos.z - _h;
			
			#ifdef SILHOUETTE_CURVATURE_MAPPED
//				float3 EyeDirTan2=
//				rayPos.xyz+=EyeDirTan2;
//				half curvU=tex2Dlod(_ObjectNormalsTex, float4((rayPos.xy-_MainTex_ST.zw)/_MainTex_ST.xy,rayPos.ww)).r;
//				rayPos.z+=curvU*_CurvatureMultOffset.x;
				
				GetTanBasisPerPixel( float4(rayPos.xy*_MainTex_ST_inv.xy+_MainTex_ST_inv.zw, uvmip), /* inout */ _TBN, /* inout */ normStamp, /* inout */ texture2ObjectRatio);
				EyeDirTan = mul( _TBN, -viewDir.xyz );
				EyeDirTan.xy*=texture2ObjectRatio;
				EyeDirTan.z*=_DepthS_inv;
				EyeDirTan*=delta/length(EyeDirTan.xy);
				
				//EyeDirTan = delta * mul( i_tanToWorld, normalize(i_posWorld-_WorldSpaceCameraPos) );
				//EyeDirTan = delta * mul( i_tanToWorld, mul(i_tanToWorld, -viewDir.xyz) );

//				half3 newNorm=UnpackNormal(tex2Dlod(_ObjectNormalsTex, float4((rayPos.xy-_MainTex_ST.zw)/_MainTex_ST.xy,rayPos.ww)));
//				half3 halfNorm=newNorm;//normalize(newNorm+lastNorm);
////				halfNorm=normalize(newNorm+halfNorm);
////				halfNorm=normalize(newNorm+halfNorm);
//				float sin_angle=sin(_CurvatureMultOffset.z*EyeDirTan.x*abs(EyeDirTan.x)*40000);//length(cross(lastNorm, halfNorm));//sqrt(1-dot(lastNorm,newNorm)*dot(lastNorm,newNorm));
//				float cos_angle=cos(_CurvatureMultOffset.z*EyeDirTan.x*abs(EyeDirTan.x)*40000);//dot(lastNorm,halfNorm);
//				float3 EyeDirTan2;
//				EyeDirTan2.z=EyeDirTan.z*cos_angle-EyeDirTan.x*sin_angle;
//				EyeDirTan2.y=EyeDirTan.y;
//				EyeDirTan2.x=EyeDirTan.z*sin_angle+EyeDirTan.x*cos_angle;
//				//EyeDirTan=EyeDirTan2;
//
//				//rayPos.z +=  _CurvatureMultOffset.z*100000*EyeDirTan.x;//*EyeDirTan.x;
//
////				half3 newNorm=mul(UnpackNormal(tex2Dlod(_ObjectNormalsTex, float4((rayPos.xy-_MainTex_ST.zw)/_MainTex_ST.xy,rayPos.ww))), i_tanToWorld);
//				float4 quat;
////				half3 halfNorm = normalize(lastNorm + newNorm);
////				quat.xyz=cross(lastNorm, halfNorm);
////				quat.w=dot(lastNorm, halfNorm);
//				float3x3 i_worldToTan=transpose(i_tanToWorld);
//				float3 tanNorm = mul(newNorm, i_worldToTan);
//				float3 rotVec = normalize( cross(tanNorm, EyeDirTan) );
//				quat.xyz=rotVec*sin(_CurvatureMultOffset.z*length(EyeDirTan.x)*100);
//				quat.w=cos(_CurvatureMultOffset.z*length(EyeDirTan.x)*100);
//				//quat=normalize(quat);
////				
//				half3 t = 2 * cross(quat.xyz, EyeDirTan);
//				//EyeDirTan = EyeDirTan + quat.w * t + cross(quat.xyz, t);
//				
//				//lastNorm=newNorm;
			#endif		
		}
		#if defined(SILHOUETTE_CURVATURE_MAPPED)
			viewDir.xyz = mul( _TBN, viewDir.xyz ); // update viewDir to tan space as is expected
			i_tanToWorld = _TBN;
			// tbn is in object space - move to world
			i_tanToWorld[0] = (unity_WorldToObject[0].xyz * i_tanToWorld[0].x + unity_WorldToObject[1].xyz * i_tanToWorld[0].y + unity_WorldToObject[2].xyz * i_tanToWorld[0].z);
			i_tanToWorld[1] = (unity_WorldToObject[0].xyz * i_tanToWorld[1].x + unity_WorldToObject[1].xyz * i_tanToWorld[1].y + unity_WorldToObject[2].xyz * i_tanToWorld[1].z);
			i_tanToWorld[2] = (unity_WorldToObject[0].xyz * i_tanToWorld[2].x + unity_WorldToObject[1].xyz * i_tanToWorld[2].y + unity_WorldToObject[2].xyz * i_tanToWorld[2].z);
			//i_tanToWorld = out_uv_bound_flag ? i_tanToWorld : half3x3(_T,_B,_N); // overwrite tangent basis for lighting
		#endif
		
		
		if (hit_flag) {
			// secant search - 2 steps
			float scl=dh_prev / ((_h-h_prev) - EyeDirTan.z);
			rayPos.xyz-=EyeDirTan*(1 - scl); // back
			float _nh=tex2Dlod(_ParallaxMap, rayPos.xyww).PARALLAX_CHANNEL;
			if (_nh >= rayPos.z) {
				EyeDirTan*=scl;
				scl=dh_prev / ((_nh-h_prev) - EyeDirTan.z);
				rayPos.xyz-=EyeDirTan*(1 - scl); // back
			} else {
				EyeDirTan*=(1-scl);
				dh_prev = rayPos.z - _nh;
				scl=dh_prev / ((_h-_nh) - EyeDirTan.z);
				rayPos.xyz+=EyeDirTan*scl; // forth
			}
		}
		
		//defined(SILHOUETTE_CURVATURE_BASIC) || defined(VERTEX_COLOR_CHANNEL_POMZ) || defined(SILHOUETTE_CURVATURE_MAPPED)
		#if defined(POM_UV_BORDER_CLIP)
			if (rayPos.z>1 || rayPos.z<_POM_BottomCut) {
				clip(-1);
//				return;
			}		
		#endif
//		#if defined(SILHOUETTE_CURVATURE_MAPPED)
//			clip(hit_flag ? 1:-1);
//		#endif
		#if defined(POM_UV_BORDER_CLIP)
			// UV border cut
			clip( (_UV_Clip && (rayPos.x<_UV_Clip_Borders.x || rayPos.x>_UV_Clip_Borders.z || rayPos.y<_UV_Clip_Borders.y || rayPos.y>_UV_Clip_Borders.w)) ? -1:1);
		#endif
				
		//rayPos.xyz+=rayPos.z < 0 ? -EyeDirTan*(rayPos.z/EyeDirTan.z) : 0; // clamp raypos bottom boundary to be >=0
		//rayPos.z=max(rayPos.z,0);
		#if defined(DEPTH_PASS)
			// we need to move rayPos to the ground for shadows z-write (hit virtual bottom extrude side)
			if (!hit_flag) {
				rayPos.z=0;
				rayPos.xy=rayPosStart.xy-EyeDirTan.xy/EyeDirTan.z;
			}
		#endif		

		// out
		actH=rayPos.z;
		// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
		// thus rayLength is required
		#if defined(RAYLENGTH_AVAILABLE)
			float3 rayDeltaTexture=rayPos.xyz-rayPosStart.xyz;
			float3 rayDeltaWorld;
			rayDeltaWorld=float3(rayDeltaTexture.xy/texture2ObjectRatio, rayDeltaTexture.z*_DepthS)*tangentBasisScaled;
			rayLength=length(rayDeltaWorld);
		#endif
		
		// in dx9 - COLOR1 semantic (lightdir) counts and is not available with POM self shadowing
		#if defined(_PARALLAX_POM_SHADOWS)
		{
			// pass rayPos outside (for optional self shadowing)
			outRayPos=rayPos;
			outRayPos.w=max(0, heightMapMIP-1); // avoid aggressive shadow detail cut at grazing angles
			outTexture2WorldRatio=texture2ObjectRatio;
		}
		#endif

		
		float2 offset=(rayPos.xy-texcoords.xy);
	#endif
	// main tex offset to detail tex offset ratio
	// TODO: might NOT work if detail takes coords from UV1
	float2 detail_offset=offset*_DetailAlbedoMap_ST.xy/_MainTex_ST.xy;
	return float4(texcoords.xy+offset, texcoords.zw+detail_offset);
#endif
}

// UBER - distance map POM
#if defined(DISTANCE_MAP)
float4 ParallaxPOMDistance (float4 texcoords, inout half3 viewDir, float3 i_posWorld, inout half4 i_vertex_color, float2 _ddx, float2 _ddy, half snowVal, inout half actH, inout float4 outRayPos, inout float2 outTexture2WorldRatio, inout float rayLength, float3 tangentBasisScaled, float4 SclCurv, inout half3 _norm)
{
#if FIX_SUBSTANCE_BUG
	float4 ParallaxMap_TexelSize=heightMapTexelSize;
#else
	float4 ParallaxMap_TexelSize=_ParallaxMap_TexelSize;
#endif

	// POM
	float2 hgtDDX = _ddx * ParallaxMap_TexelSize.zw;
	float2 hgtDDY = _ddy * ParallaxMap_TexelSize.zw;
	float d = max( dot( hgtDDX, hgtDDX ), dot( hgtDDY, hgtDDY ) );
	float heightMapMIP = max(0, 0.5*log2(d))+_ReliefMIPbias;
	
//	#if defined(DEPTH_PASS)
//		heightMapMIP+=DEPTH_PASS_MIP_ADD; // higher mip offset for zwrite depth/shadow caster
//	#endif		
	
	#if defined(VERTEX_COLOR_CHANNEL_POMZ)
		float rayPosZStart = _POM_MeshIsVolume ? saturate(i_vertex_color.VERTEX_COLOR_CHANNEL_POMZ+0.0001) : 1;
	#else
		float rayPosZStart=1;
	#endif
	float4 rayPos = float4(texcoords.xy, rayPosZStart, 0); //heightMapMIP); // no mips for distance map
	float3 rayPosStart=rayPos.xyz;

	float2 texture2ObjectRatio=_MainTex_ST.xy*SclCurv.xy;
	float3 EyeDirTan = -viewDir.xyz;
	
	EyeDirTan.xy*=texture2ObjectRatio;
	//EyeDirTan=normalize(EyeDirTan);

//	#if defined(_SNOW)
//		float _DepthS=_Depth*(1-saturate(snowVal-0.4)*0.05*_SnowDeepSmoothen);
//	#else
		float _DepthS=_Depth;
//	#endif
	_DepthS/=min(texture2ObjectRatio.x, texture2ObjectRatio.y);
	float distanceReduction=saturate( distance(i_posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance );
	_DepthS=lerp(_DepthS, 0.001, distanceReduction );

	EyeDirTan.z/=max(0.001, _DepthS);

	_norm=float3(0,0,1);
//	_norm.xy=SclCurv.zw;
//	_norm.z=sqrt(1-saturate(dot(_norm.xy,_norm.xy))); // initial _norm state - for ceil it's supposed to be (0,0,1), for extruded sidewalls it may differ
	float2 delta;
	float4 rect_constraints=tex2Dlod(_ParallaxMap, rayPos.xyww);
	bool ceil_flag=dot(rect_constraints,rect_constraints)==0; // actually ceil_flag means also that we're initially on the extruded sidewall when VERTEX_COLOR_CHANNEL_POMZ is used
	int i=0;
	UNITY_BRANCH if (!ceil_flag) {
		for(i=0; i<DISTANCEMAP_STEPS; i++) {
			if (i>0) {
				rect_constraints=tex2Dlod(_ParallaxMap, rayPos.xyww);
				if (dot(rect_constraints,rect_constraints)==0 || (rayPos.z <= 0)) {
					break;
				}
			}
			delta=(EyeDirTan.xy<0) ? -rect_constraints.ra : rect_constraints.gb;
			// 1.00001 multiplication to heal frac edge precision glitch in DX11
			delta -=  frac(rayPos.xy*ParallaxMap_TexelSize.zw*float2(1.00001, 1.00001))*ParallaxMap_TexelSize.xy;

			// workaround for some ugly miscompilation that's present when making glcore + zwrite
			#if defined(SHADER_API_GLCORE) && !defined(_POM_DISTANCE_MAP_SHADOWS)
				delta/=(EyeDirTan.xy==0) ? 1 : EyeDirTan.xy; // horizontal / vertical artifact remover for EyeDirTan==0
			#else
				delta/=EyeDirTan.xy;
			#endif

			rayPos.xyz += EyeDirTan*(min(delta.x, delta.y)+ParallaxMap_TexelSize.x*0.5);//*1.005;
		}
		_norm=delta.x<delta.y ? float3(1,0,0) : float3(0,1,0);
		_norm.xy=(EyeDirTan.xy>0) ? -_norm.xy : _norm.xy;
	}
	//	rayPos.xyz = ceil_flag ? rayPosStart.xyz : rayPos.xyz;
	bool floor_flag=rayPos.z <= 0;
	rayPos.xyz=floor_flag ? rayPos.xyz-(rayPos.z/EyeDirTan.z)*EyeDirTan : rayPos.xyz;
	_norm=floor_flag ? float3(0,0,1) : _norm;	
	// filtering norm at far distance (will be blended from bumpmap texture)
	_norm=lerp(_norm, float3(0,0,1), saturate(heightMapMIP*0.5)); // approximately 2nd mip level will cancel sidewalls _norm
		
	#if defined(POM_UV_BORDER_CLIP)
		if (rayPos.z>1 || rayPos.z<(_POM_BottomCut-0.001)) {
			clip(-1);
//			return;
		}		
	#endif
	#if defined(POM_UV_BORDER_CLIP)
		// UV border cut
		clip( (_UV_Clip && (rayPos.x<_UV_Clip_Borders.x || rayPos.x>_UV_Clip_Borders.z || rayPos.y<_UV_Clip_Borders.y || rayPos.y>_UV_Clip_Borders.w)) ? -1:1);
	#endif

	// out
	actH=rayPos.z;
	// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
	// thus rayLength is required
	#if defined(RAYLENGTH_AVAILABLE)
		float3 rayDeltaTexture=rayPos.xyz-rayPosStart.xyz;
		float3 rayDeltaWorld;
		rayDeltaWorld=float3(rayDeltaTexture.xy/texture2ObjectRatio, rayDeltaTexture.z*_DepthS)*tangentBasisScaled;
		rayLength=length(rayDeltaWorld);
	#endif
	
	// in dx9 - COLOR1 semantic (lightdir) counts and is not available with POM self shadowing
	#if defined(_POM_DISTANCE_MAP_SHADOWS)
	{
		// pass rayPos outside (for optional self shadowing)
		outRayPos=rayPos;
		outRayPos.w=0; // no mips for distance map
		outTexture2WorldRatio=texture2ObjectRatio;
	}
	#endif
	
	// sidewalls texturing
	#if DISTANCEMAP_TEXTURING_SIDEWALLS
		#if defined(VERTEX_COLOR_CHANNEL_POMZ)
			rayPos.xy+=(saturate( _POM_MeshIsVolume && (SclCurv.z==0) ? (1-rayPos.z):rayPos.z )*_Depth)*_norm.xy;
		#else
			rayPos.xy+=saturate(1-rayPos.z)*_Depth*_norm.xy;
		#endif
	#endif

	float2 offset=(rayPos.xy-texcoords.xy);

	// main tex offset to detail tex offset ratio
	// TODO: might NOT work if detail takes coords from UV1
	float2 detail_offset=offset*_DetailAlbedoMap_ST.xy/_MainTex_ST.xy;
	return float4(texcoords.xy+offset, texcoords.zw+detail_offset);
}
#endif

#if defined(EXTRUSION_MAP)
float4 ParallaxPOMExtrusion (float4 texcoords, inout half3 viewDir, float3 i_posWorld, inout half4 i_vertex_color, float2 _ddx, float2 _ddy, half snowVal, inout half actH, inout float4 outRayPos, inout float2 outTexture2WorldRatio, inout float rayLength, float3 tangentBasisScaled, float4 SclCurv, inout half3 _norm)
{
#if FIX_SUBSTANCE_BUG
	float4 ParallaxMap_TexelSize=heightMapTexelSize;
#else
	float4 ParallaxMap_TexelSize=_ParallaxMap_TexelSize;
#endif

	// POM
	float2 hgtDDX = _ddx * ParallaxMap_TexelSize.zw;
	float2 hgtDDY = _ddy * ParallaxMap_TexelSize.zw;
	float d = max( dot( hgtDDX, hgtDDX ), dot( hgtDDY, hgtDDY ) );
	float heightMapMIP = max(0, 0.5*log2(d))+_ReliefMIPbias;
	
	#if defined(DEPTH_PASS)
		heightMapMIP+=DEPTH_PASS_MIP_ADD; // higher mip offset for zwrite depth/shadow caster
	#endif		
		
	//o.Emission.r+=heightMapMIP;
	#if defined(VERTEX_COLOR_CHANNEL_POMZ)
		float rayPosZStart = _POM_MeshIsVolume ? i_vertex_color.VERTEX_COLOR_CHANNEL_POMZ : 1;
	#else
		float rayPosZStart=1;
	#endif
	float4 rayPos = float4(texcoords.xy, rayPosZStart, heightMapMIP);
	float3 rayPosStart=rayPos.xyz;

	float2 texture2ObjectRatio=_MainTex_ST.xy*SclCurv.xy;
	float3 EyeDirTan = -viewDir.xyz;
	
	EyeDirTan.xy*=texture2ObjectRatio;
	//EyeDirTan=normalize(EyeDirTan);

//	#if defined(_SNOW)
//		float _DepthS=_Depth*(1-saturate(snowVal-0.4)*0.05*_SnowDeepSmoothen);
//	#else
		float _DepthS=_Depth;
//	#endif
	_DepthS/=min(texture2ObjectRatio.x, texture2ObjectRatio.y);
	_DepthS=lerp(_DepthS, 0.001, saturate( distance(i_posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
	
	EyeDirTan.z/=max(0.001, _DepthS);		
		
	//bool hit_flag=false;
	float delta=ParallaxMap_TexelSize.x*exp2(rayPos.w)*EXTRUSION_MAP_WAVELENGTH;
	#if defined(DEPTH_PASS)
		delta*=exp2(DEPTH_PASS_MIP_ADD); // larger step for zwrite/shadows (we need to gain performance here)
	#endif		
	
	EyeDirTan*=delta/length(EyeDirTan.xy);
	
	bool ceil_flag=tex2Dlod(_ParallaxMap, rayPos.xyww).a > 0.5;
	UNITY_BRANCH if (!ceil_flag) {	
		bool height=false;
		#if !defined(SHADER_API_D3D11) && defined(SAFE_LOOPS)
		UNITY_LOOP for(int i=0; i<256; i++) {
		#else
		//_DistSteps=min(_DepthS/abs(EyeDirTan.z), _DistSteps);
		UNITY_LOOP for(int i=0; i<_DistSteps; i++) {
		#endif
			rayPos.xyz+=EyeDirTan;
			height=tex2Dlod(_ParallaxMap, rayPos.xyww).a > 0.5; 
			//hit_flag=hit_flag||height;
			if (height) break;
		}

		EyeDirTan*=height ? -0.5 : 1;
		for(int j=0; j<EXTRUSIONMAP_BINARY_SEARCH_STEPS; j++) {
			rayPos.xyz+=EyeDirTan;
			bool new_height=tex2Dlod(_ParallaxMap, rayPos.xyww).a > 0.5;
			EyeDirTan *= (height != new_height) ? -0.5 : 1;
			height=new_height;
			//hit_flag=hit_flag||height;
		}
	}

	bool floor_flag=rayPos.z < 0;
	rayPos.xyz=floor_flag ? rayPos.xyz-(rayPos.z/EyeDirTan.z)*EyeDirTan : rayPos.xyz;
	// used for optional texturing sidewalls, will be reused later
	_norm=UnpackScaleNormal( tex2Dgrad(_BumpMap, rayPos.xy, _ddx, _ddy), _BumpScale);
		
	#if defined(POM_UV_BORDER_CLIP)
		if (rayPos.z>1 || rayPos.z<(_POM_BottomCut-0.001)) {
			clip(-1);
//			return;
		}		
	#endif
	#if defined(POM_UV_BORDER_CLIP)
		// UV border cut
		clip( (_UV_Clip && (rayPos.x<_UV_Clip_Borders.x || rayPos.x>_UV_Clip_Borders.z || rayPos.y<_UV_Clip_Borders.y || rayPos.y>_UV_Clip_Borders.w)) ? -1:1);
	#endif

	// out
	actH=rayPos.z;
	// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
	// thus rayLength is required
	#if defined(RAYLENGTH_AVAILABLE)
		float3 rayDeltaTexture=rayPos.xyz-rayPosStart.xyz;
		float3 rayDeltaWorld;
		rayDeltaWorld=float3(rayDeltaTexture.xy/texture2ObjectRatio, rayDeltaTexture.z*_DepthS)*tangentBasisScaled;
		rayLength=length(rayDeltaWorld);
	#endif
	
	// in dx9 - COLOR1 semantic (lightdir) counts and is not available with POM self shadowing
	#if defined(_POM_EXTRUSION_MAP_SHADOWS)
	{
		// pass rayPos outside (for optional self shadowing)
		outRayPos=rayPos;
		outRayPos.w=max(0, heightMapMIP-1); // avoid aggressive shadow detail cut at grazing angles
		outTexture2WorldRatio=texture2ObjectRatio;
	}
	#endif
	
	// sidewalls texturing
	#if EXTRUSIONMAP_TEXTURING_SIDEWALLS
//	#if defined(VERTEX_COLOR_CHANNEL_POMZ)
//		rayPos.xy+=floor_flag ? float2(0,0) : saturate( _POM_MeshIsVolume && (SclCurv.z==0) ? (1-rayPos.z):rayPos.z )*_norm.xy*_Depth;
//	#else
		rayPos.xy+=floor_flag ? float2(0,0) : saturate(1-rayPos.z)*_Depth*_norm.xy;
//	#endif
	#endif


	float2 offset=(rayPos.xy-texcoords.xy);

	// main tex offset to detail tex offset ratio
	// TODO: might NOT work if detail takes coords from UV1
	float2 detail_offset=offset*_DetailAlbedoMap_ST.xy/_MainTex_ST.xy;
	return float4(texcoords.xy+offset, texcoords.zw+detail_offset);
}
#endif

// UBER - self shadowing
#if defined(_POM_DISTANCE_MAP_SHADOWS)
half SelfShadows(float4 rayPos, float2 texture2ObjectRatio, float3 lightDirInTanSpace, half snowVal) {

#if FIX_SUBSTANCE_BUG
	float4 ParallaxMap_TexelSize=heightMapTexelSize;
#else
	float4 ParallaxMap_TexelSize=_ParallaxMap_TexelSize;
#endif

	half SS=1;
	float3 EyeDirTan=normalize(lightDirInTanSpace);
	rayPos.xyz+=EyeDirTan*ParallaxMap_TexelSize.xxx;
	
	texture2ObjectRatio=1.0/texture2ObjectRatio;
	EyeDirTan.xy*=texture2ObjectRatio;
	//EyeDirTan=normalize(EyeDirTan);
//	#if defined(_SNOW)
//		float _DepthS=_Depth*(1-saturate(snowVal-0.4)*0.025*_SnowDeepSmoothen);
//	#else
		float _DepthS=_Depth;
//	#endif
	_DepthS/=min(texture2ObjectRatio.x, texture2ObjectRatio.y);
	EyeDirTan.z/=max(0.001, _DepthS);
	
	for(int i=0; i<DISTANCEMAP_STEPS; i++) {
		fixed4 rect_constraints=tex2Dlod(_ParallaxMap, rayPos.xyww);
		if ((dot(rect_constraints,rect_constraints)==0) ) break;
		
		float2 delta;
		delta = (EyeDirTan.xy<0) ? -rect_constraints.ra : rect_constraints.gb;
		// 1.00001 multiplication to heal frac edge precision glitch in DX11
		delta -=  frac(rayPos.xy*ParallaxMap_TexelSize.zw*float2(1.00001, 1.00001))*ParallaxMap_TexelSize.xy;		
		delta/=EyeDirTan.xy;
		rayPos.xyz += EyeDirTan*(min(delta.x, delta.y)+ParallaxMap_TexelSize.x*0.5);//*1.005;
	}

	const float hardness=4;
	SS = saturate( hardness * (rayPos.z-0.95) * (_Softness+0.5) + 0.5 );

	SS=lerp(1, SS, _ShadowStrength);
//	#if defined(_SNOW)
//		SS=lerp(SS, 1, saturate(snowVal*_SnowDeepSmoothen));
//	#endif
	
	return SS;
}
#elif defined(_POM_EXTRUSION_MAP_SHADOWS)
half SelfShadows(float4 rayPos, float2 texture2ObjectRatio, float3 lightDirInTanSpace, half snowVal) {

#if FIX_SUBSTANCE_BUG
	float4 ParallaxMap_TexelSize=heightMapTexelSize;
#else
	float4 ParallaxMap_TexelSize=_ParallaxMap_TexelSize;
#endif

	half SS=1;
	float3 EyeDirTan=normalize(lightDirInTanSpace);
	rayPos.xyz+=EyeDirTan*ParallaxMap_TexelSize.xxx;
	
	texture2ObjectRatio=1.0/texture2ObjectRatio;
	EyeDirTan.xy*=texture2ObjectRatio;
	//EyeDirTan=normalize(EyeDirTan);
//	#if defined(_SNOW)
//		float _DepthS=_Depth*(1-saturate(snowVal-0.4)*0.025*_SnowDeepSmoothen);
//	#else
		float _DepthS=_Depth;
//	#endif
	_DepthS/=min(texture2ObjectRatio.x, texture2ObjectRatio.y);
	EyeDirTan.z/=max(0.001, _DepthS);
	
	float delta=ParallaxMap_TexelSize.x*exp2(rayPos.w)*EXTRUSION_MAP_WAVELENGTH/length(EyeDirTan.xy);
	EyeDirTan*=delta;

	//bool hit_flag=false;
	UNITY_BRANCH if (rayPos.z<1) {
		bool height=false;
		#if !defined(SHADER_API_D3D11) && defined(SAFE_LOOPS)
		for(int i=0; i<256; i++) {
		#else
		for(int i=0; i<_DistStepsShadows; i++) {
		#endif
			rayPos.xyz+=EyeDirTan;
			height=tex2Dlod(_ParallaxMap, rayPos.xyww).a > 0.5; 
			//hit_flag=hit_flag||height;
			if (height) break;
		}

		EyeDirTan*=height ? -0.5 : 1;
		for(int j=0; j<EXTRUSIONMAP_BINARY_SEARCH_STEPS; j++) {
			rayPos.xyz+=EyeDirTan;
			bool new_height=tex2Dlod(_ParallaxMap, rayPos.xyww).a > 0.5;
			EyeDirTan *= (height != new_height) ? -0.5 : 1;
			height=new_height;
			//hit_flag=hit_flag||height;
		}
	}
	
	const float hardness=4;
	SS = saturate( hardness * (rayPos.z-0.95) * (_Softness+0.5) + 0.5 );

	SS=lerp(1, SS, _ShadowStrength);
//	#if defined(_SNOW)
//		SS=lerp(SS, 1, saturate(snowVal*_SnowDeepSmoothen));
//	#endif
	
	return SS;
}
#elif defined(_PARALLAX_POM_SHADOWS)
half SelfShadows(float4 rayPos, float2 texture2ObjectRatio, float3 lightDirInTanSpace, half snowVal) {

#if FIX_SUBSTANCE_BUG
	float4 ParallaxMap_TexelSize=heightMapTexelSize;
#else
	float4 ParallaxMap_TexelSize=_ParallaxMap_TexelSize;
#endif

	half SS=1;
	const float _WAVELENGTH_SHADOWS=1; 
	rayPos.w+=_ShadowMIPbias;
	#if defined(_SNOW)
	rayPos.w+=snowVal*0.2*_SnowDeepSmoothen;
	#endif
	float3 EyeDirTan=lightDirInTanSpace;
	texture2ObjectRatio=1.0/texture2ObjectRatio;
	EyeDirTan.xy*=texture2ObjectRatio;
	//EyeDirTan=normalize(EyeDirTan);
	#if defined(_SNOW)
		float _DepthS=_Depth*(1-saturate(snowVal-0.4)*0.025*_SnowDeepSmoothen);
	#else
		float _DepthS=_Depth;
	#endif
	_DepthS/=min(texture2ObjectRatio.x, texture2ObjectRatio.y);
//	_DepthS=lerp(_DepthS, 0.001, saturate( distance(i_posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
	EyeDirTan.z/=max(0.001, _DepthS);
	float delta=ParallaxMap_TexelSize.x*exp2(rayPos.w)*_WAVELENGTH_SHADOWS/length(EyeDirTan.xy);
	EyeDirTan*=delta;
	rayPos.z+=EyeDirTan.z*delta*2048*0.2;
	float h_prev=rayPos.z;

	bool hit_flag=false;
	float dh_prev=0;
	float _h;
	#if !defined(SHADER_API_D3D11) && defined(SAFE_LOOPS)
	UNITY_LOOP for(int i=0; i<256; i++) {
	#else
	UNITY_LOOP for(int i=0; i<_DistStepsShadows; i++) {
	#endif
		rayPos.xyz+=EyeDirTan;
		_h=tex2Dlod(_ParallaxMap, rayPos.xyww).PARALLAX_CHANNEL;
		hit_flag=_h >= rayPos.z;
		if (hit_flag) break;
		h_prev=_h;
		dh_prev = rayPos.z - _h;
	}
	
	#ifdef _SOFT_SHADOWS
		if (hit_flag) {
			// secant search
			float scl=dh_prev / ((_h-h_prev) - EyeDirTan.z);
			rayPos.xyz-=EyeDirTan*(1 - scl); // back
			
			float dh;
			
			rayPos.xyz += (1+_SoftnessFade)*EyeDirTan.xyz; rayPos.w++;
			dh = saturate( tex2Dlod(_ParallaxMap, rayPos.xyww).PARALLAX_CHANNEL - rayPos.z ); // weight 1 (mip+1 frequency)
			
			rayPos.xyz += (1+_SoftnessFade*3)*EyeDirTan.xyz; rayPos.w++;
			dh += saturate( tex2Dlod(_ParallaxMap, rayPos.xyww).PARALLAX_CHANNEL - rayPos.z )*4; // weight 4 (mip+2 frequency)
			
			rayPos.xyz += (1+_SoftnessFade*7)*EyeDirTan.xyz; rayPos.w++;
			dh += saturate( tex2Dlod(_ParallaxMap, rayPos.xyww).PARALLAX_CHANNEL - rayPos.z )*8; // weight 8 (mip+3 frequency)
			#if defined(_SNOW)
				SS=1-saturate(dh*exp2(_Softness-snowVal*2));
			#else
				SS=1-saturate(dh*exp2(_Softness));
			#endif
		}
	#else
		SS=hit_flag ? 0 : 1;
	#endif
	SS=lerp(1, SS, _ShadowStrength);
	#if defined(_SNOW)
	SS=lerp(SS, 1, saturate(snowVal*_SnowDeepSmoothen));
	#endif
	
	return SS;
}
#endif

#endif // UBER_STANDARD_UTILS2_INCLUDED
