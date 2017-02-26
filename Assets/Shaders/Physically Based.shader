Shader "Custom/Physically Based" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "LightMode"="ForwardBase" }
		LOD 200

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

		    //
		    // Fresnel Micro Facet Surface Reflectance Moel
			//                     F(l,h)G(l,v,h)D(h)
			// fmicrofacet(l,v) = --------------------
			//                         4(n.l)(n.v)
			//
			// Schlick Fresnel Reflectance Term 
			// F^F0(l,h) = F0+(1-F0)(1-(l.h))^5
			//
			// GXX Normal Distribution Term
			//                       a
			// D_tr(h) = ------------------------
			//            PI((n.h)^2(a^2-1)+1)^2
			//                             a(h.n)
			// D_tr(h) = ------------------------------------------
			//            PI((n.h)^2(a^2+((1-(h.n)^2)/(h.n)^2))^2)
			//
			// Cook-Torrance Geometry Term
			//                        2(n.h)(n.v)    2(n.h)(n.l)
			// G_ct(l,v,h) = min (1, -------------, -------------)
			//                            v.h            v.h
			//

			static const float PI = 3.14159265f;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			half _Glossiness;
			half _Metallic;
			fixed4 _Color;

			struct vertexOutput {
				float2 uv     : TEXCOORD0;
				float3 normal : NORMAL;
				float4 vertex : SV_POSITION;
			};

			vertexOutput vert(appdata_base v) 
			{
				vertexOutput o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			fixed4 frag(vertexOutput i) : COLOR
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;

				float3 v = _WorldSpaceCameraPos;
				float3 l = _WorldSpaceLightPos0.xyz;
				float3 h = normalize(l + v);
				float3 n = i.normal;

				half lh = dot(l, h);
				half nh = dot(n, h);
				half nl = dot(n, l);
				half nv = dot(n, v);
				half vh = dot(v, h);

				half F = _Metallic + ((1 - _Metallic) * pow(1 - lh, 5));
				half D = _Glossiness / (PI * pow(pow(nh, 2) * (pow(_Glossiness, 2) - 1) + 1, 2));
				half G = min(1, min((2 * nh * nv) / vh, (2 * nh * nl) / vh));
				half facet = (F * G * D) / (4 * nl * nv);

				half Fnl = _Metallic + ((1 - _Metallic) * pow(1 - nl, 5));
				half diff = pow(1 - F, _Metallic / PI);

				return (col * 0.1) + (col * _LightColor0 * nl) + (col * _LightColor0 * diff) + (_LightColor0 * facet);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
