Shader "Unity Shader Book/Chapter 7/RampTexture"
{
    Properties
    {
        // 颜色
        _Color ("色调", Color) = (1, 1, 1, 1)
        // 渐变纹理
        _RampTex ("渐变纹理", 2D) = "white" {}
        // 高光颜色
        _Specular ("高光颜色", Color) = (1, 1, 1, 1)
        // 光滑度
        _Gloss ("光滑度", Range(8.0, 256)) = 20
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

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct appdata
            {
                // 顶点坐标
                float4 vertex : POSITION;
                // 顶点法线
                float3 normal : NORMAL;
                // 纹理
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                // 裁剪坐标
                float4 pos : SV_POSITION;
                // 世界坐标下的法线
                float3 worldNormal : TEXCOORD0;
                // 世界坐标
                float3 worldPos : TEXCOORD1;
                // uv坐标
                float2 uv : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算世界法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 计算世界坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 计算uv坐标
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                ambient = ambient * tex2D(_RampTex, i.uv);

                // 半兰伯特模型计算漫反射
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                // 高光计算
                fixed3 viewDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
