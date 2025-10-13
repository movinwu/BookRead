Shader "Unity Shader Book/Chapter 5/Simple Shader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)    
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;

            struct a2v
            {
                // POSITION语义：使用模型空间的顶点坐标填充vertex变量
                float4 vertex : POSITION;
                // NORMAL语义：使用模型空间的法线方向填充normal变量
                float3 normal : NORMAL;
                // TEXCOORD0语义：使用模型的第一套纹理坐标填充normal变量
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                // SV_POSITION语义：pos中包含了顶点在裁剪空间中的位置信息
                float4 pos : SV_POSITION;
                // COLOR0语义：存储颜色信息
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算一个颜色，存储起来，传递给片元着色器
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            float4 frag(v2f o) : SV_Target
            {
                fixed3 c = o.color;
                c *= _Color.rgb;
                return fixed4(c, 1.0);
            }
            ENDCG
        }
    }
}