Shader "Unity Shader Book/Chapter 6/SpecularVertexLevel"
{
    Properties
    {
        // 漫反射颜色
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        // 高光颜色
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

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct appdata
            {
                // 模型空间顶点坐标
                float4 vertex : POSITION;
                // 法线方向
                float3 normal : NORMAL;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // 颜色
                fixed3 color : COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 法线从模型空间到世界空间
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                // 世界空间下的光线方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 漫反射部分
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);

                // 世界空间下的高光方向
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                // 世界空间下的视线方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

                // 高光部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb *
                    pow((dot(reflectDir, viewDir) * 0.5 + 0.5), _Gloss);

                // 最终颜色
                o.color = ambient + diffuse + specular;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
}