Shader "Unity Shader Book/Chapter 6/BlinnPhong"
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
                // 世界空间下的法线
                float3 worldNormal : TEXCOORD0;
                // 世界空间下的坐标
                fixed3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 世界空间下的法线
                // o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间下的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 世界法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界光线
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 漫反射部分
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);

                // 世界坐标的视线
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 视线和光线的中间方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 高光部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(worldNormal, halfDir) * 0.5 + 0.5, _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
