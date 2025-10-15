Shader "Unity Shader Book/Chapter 7/NormalMapTangentSpace"
{
    Properties
    {
        // 颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex ("Main Tex", 2D) = "white" {}
        // 法线纹理，默认值 bump 是unity内置的法线纹理，对应原始法线纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 法线纹理缩放
        _BumpScale ("Bump Scale", Float) = 1.0
        // 高光反射
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 光滑度
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                // 顶点
                float4 vertex : POSITION;
                // 法线
                float3 normal : NORMAL;
                // 切线
                float4 tangent : TANGENT;
                // 纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // uv，xy为主纹理uv，zw为法线纹理uv
                float4 uv : TEXCOORD0;
                // 光照方向
                float3 lightDir : TEXCOORD1;
                // 视线方向
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                // o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                // 将切线方向、副切线方向、法线方向按照行排列，得到模型空间到切线空间的变换矩阵rotation
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                // 得到模型空间到切线空间变换矩阵rotation的操作已经封装好了
                TANGENT_SPACE_ROTATION;

                // 将光线方向和视线方向从模型空间变换到切线空间中
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // 根据颜色反向计算得到切线
                // fixed3 tangentNormal;
                // tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                // tangentNormal.z = sqrt(1.0 - max(dot(tangentNormal.xy, tangentNormal.xy), 0));

                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - max(dot(tangentNormal.xy, tangentNormal.xy), 0));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(dot(tangentNormal, tangentLightDir), 0);
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(dot(tangentNormal, halfDir), 0), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}