Shader "hidden/rayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _spherePos ("SpherePosition" ,Vector) = (1,1,1,2)
        _boxScale ("BoxX" ,Vector) = (1,1,1)
        _boxPos ("BoxPosition" ,Vector) = (1,1,1)
        _lightPos ("Light position ", Vector) = (5,5,-5)
        _smoothAmount ("Smooth amount", Range(0, 5)) = 0.5
        
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #  include "UnityCG.cginc"

            #define  MAX_STEPS 100
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
           
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            struct floor_Plane
            {
                float height;

                
                
            };
                
            struct sphere 
            {
                float3 pos;
                float radius;
                
            };

            float sphereDist(float3 pos,sphere s)
            {
                return length(pos - s.pos) - s.radius; 
            }

           float boxDist( float3 p, float3 boxPos,float3 b )
            {
                p-=boxPos;
                 float3 q = abs(p) - (b);
                 return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }
            
            float planeDist(float3 pos ,floor_Plane f)
            {
                return pos.y - f.height; 
            }

            float smoothMax(float a,float b,float c)
            {
                return log(exp(c*a)+exp(c*b))/c;
            }
            float smoothMin(float a,float b,float c)
            {
                return -smoothMax(-a,-b,c);
            }
            float diff(float a ,float b)
            {
                if(a>100 && b>100)
                {
                    return b;
                }
                return 100;
                     
            }
            float3 _boxPos;
            float3 _boxScale;
            float3 _spherePos;
            float _smoothAmount;
            float getDist(float3 pos)
            {
                sphere s;
                s.pos = _spherePos.xyz;
                s.radius = 2;

                floor_Plane p;
                p.height = -3;

                s.pos += float3(0,_SinTime.x * 5,0);
                
                float bd = boxDist(pos,_boxPos, _boxScale);
                float sd = sphereDist(pos,s);
                float pd = planeDist(pos,p);

                //float minimum =  smoothMin(sd,pd,1);
                float minimum =  smoothMin(bd,sd,_smoothAmount);
                //float minimum = diff(bd,sd);
                return minimum;
            }
           
            float3 getNormal(float3 pos)
            {
                float d = getDist(pos);
                float2 e = float2(0.01,0);
                float3 n = d - float3(
                    getDist(pos-e.xyy),
                    getDist(pos-e.yxy),
                    getDist(pos-e.yyx));
                
                return normalize(n);
            }

            float3 _lightPos;
            
            float getLight(float3 pos)
            {
                
                float3 normal = getNormal(pos);
                float3 l = normalize(_lightPos - pos);
                return dot(normal,l);
                
            }

          
            
            float rayMarch(float3 rayOrigin,float3 rayDir)
            {
                float dist = 0;
                
                for(int i =0 ; i < MAX_STEPS;i++)
                {
                    float3 pos = rayOrigin + rayDir * dist;
                    float d = getDist(pos);
                    
                    if(d < 0.001)
                    {
                        return dist;
                    }
                    dist += d;   
                }
                
                return dist;
                
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            
            fixed4 frag(v2f i) : SV_Target
            {
                float2 normalizedUV = i.uv * 2 -1;
                normalizedUV.x *=1.77777;
                
                float3 rayPos = _WorldSpaceCameraPos;
                float3 rayDir = normalize(float3(normalizedUV,1));
                
                float dist = rayMarch(rayPos,rayDir);
                
                float3 pos = rayPos + rayDir * dist;
                float diff  = getLight(pos);
       
                
                float4 col = float4(diff,diff,diff,1);
                if(dist>100)
                {
                    return tex2D(_MainTex,i.uv); 
                }
                return col;
            }

            
            
            ENDCG
        }
    }
}
