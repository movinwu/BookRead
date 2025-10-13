Shader "Unity Shader Book/Chapter 6/DiffusePixelLevel"
{
    Properties
    {
        // 漫反射颜色
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            // LightMode是Pass标签的一种，用于定义Pass在Unity的光照流水线中的角色。在这里，正切定义了LightMode，才能得到一些Unity的内置光照变量
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            // 漫反射颜色
            fixed4 _Diffuse;

            struct appdata
            {
                // 模型空间坐标
                float4 vertex : POSITION;
                // 法线
                float3 normal : NORMAL;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // 世界坐标下的法线
                fixed3 worldNormal : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                // 空间坐标变换
                o.pos = UnityObjectToClipPos(v.vertex);

                // 计算世界空间下的法线
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 标准化法线
                // 由于片元着色器中得到的法线并不是真正的法线，而是由顶点法线插值得到的，因此这个法线模长不一定为1，所以需要标准化。
                fixed3 worldNormal = normalize(i.worldNormal);
                // 标准化光线方向
                // _WorldSpaceLightPos0:光源方向，unity提供的内置变量。
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射
                // _LightColor0:Unity提供的变量，用于访问当前Pass处理的光源的颜色和强度信息。要正确得到这个信息，需要定义好LightMode标签。
                // saturate函数:cg提供的函数，将数据截取到区间[0, 1]内。
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 最终反射颜色
                fixed3 color = ambient + diffuse;

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
