#pragma warning(disable: 3571)

#define NUM_LIGHTS                    10
#define NUM_SIMUL_LIGHTS               4
#define NUM_WORLD_MATRICES            32

#define LIGHT_TYPE_NONE                0
#define LIGHT_TYPE_POINT               1
#define LIGHT_TYPE_DIRECTIONAL         2
#define LIGHT_NUM_TYPES                3

#define PCF_NONE                       0
#define PCF_DEFAULT                    1
#define PCF_NVIDIA                     2
#define PCF_ATI                        3

/*
#define FOG_TYPE_NONE                  0
#define FOG_TYPE_LINEAR                1

Out.Fog = 1.f * (iFogType == FOG_TYPE_NONE)
			+ 1.f/exp(d * fFogDensity) * (iFogType == FOG_TYPE_EXP)
			+ 1.f/exp(pow(d * fFogDensity, 2)) * (iFogType == FOG_TYPE_EXP2)
			+ saturate((fFogEnd - d)/(fFogEnd - fFogStart)) * (iFogType == FOG_TYPE_LINEAR);

#define TEX_TYPE_NONE                0
#define TEX_TYPE_CUBEMAP             1
#define TEX_NUM_TYPES                2

#define TEXGEN_TYPE_NONE                          0
#define TEXGEN_TYPE_CAMERASPACENORMAL             1
#define TEXGEN_TYPE_CAMERASPACEPOSITION           2
#define TEXGEN_TYPE_CAMERASPACEREFLECTIONVECTOR   3
#define TEXGEN_NUM_TYPES                          4

//automatic texture coordinate generation
Out.Tex0 = float4((2.f * dot(V,N) * N - V) * (iTexGenType == TEXGEN_TYPE_CAMERASPACEREFLECTIONVECTOR)
		+ N * (iTexGenType == TEXGEN_TYPE_CAMERASPACENORMAL)
		+ P * (iTexGenType == TEXGEN_TYPE_CAMERASPACEPOSITION), 0);*/



// Structs and variables with default values

float4 vMaterialColor = float4(255.f/255.f, 230.f/255.f, 200.f/255.f, 1.0f);
float4 vMaterialColor2;
float fMaterialPower = 16.f;
float4 vSpecularColor = float4(5, 5, 5, 5);

float4 vAmbientColor = float4(64.f/255.f, 64.f/255.f, 64.f/255.f, 1.0f);

static float4 input_gamma = float4(2.2f, 2.2f, 2.2f, 2.2f);
float4 output_gamma = float4(2.2f, 2.2f, 2.2f, 2.2f);
float4 output_gamma_inv = float4(1.0f / 2.2f, 1.0f / 2.2f, 1.0f / 2.2f, 1.0f / 2.2f);

float time_var = 0.0f;

//fog settings
float4 vFogColor;
float fFogStart;
float fFogEnd;
float fFogDensity = 0.05f;
float uv_2_scale = 1.237;


texture diffuse_texture;
texture diffuse_texture_2;
texture specular_texture;
texture normal_texture;
texture env_texture;
texture shadowmap_texture;

int iLightIndices[NUM_SIMUL_LIGHTS] = { 0, 1, 2, 3 };
float3 vLightPosDir[NUM_LIGHTS];
float4 vLightDiffuse[NUM_LIGHTS];
float3 vSkyLightDir;
float4 vSkyLightColor;
float3 vSunDir;
float4 vSunColor;
float4 vPointLightColor;

float fShadowMapNextPixel = 1.0f / 4096;
float fShadowMapSize = 4096;

float fShadowBias = 0.00002f;//-0.000002f;

//initial and range of directional, point and spot lights within the light array
int iLightPointCount;

//transformation matrices
float4x4 matWorldViewProj                 : WORLDVIEWPROJ;
float4x4 matWorldView                     : WORLDVIEW;
float4x4 matViewProj                      : VIEWPROJ;
float4x4 matWorld                         : WORLD;
float4x4 matView                          : VIEW;

float4x4 matSunViewProj;

float4x4 matWaterWorldViewProj;
float4x4 matWorldArray[NUM_WORLD_MATRICES]: WORLDMATRIXARRAY;
float4   matBoneOriginArray[NUM_WORLD_MATRICES];

float4 vCameraPos;
float4 texture_offset = {0,0,0,0};

//float gradient_factor = 0.75f;
//float gradient_offset = 1.5f;


//function output structures

struct PS_INPUT_NOTEXTURE
{
	float4 Color                          : COLOR0;
};

struct PS_INPUT_FONT
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
};

struct PS_INPUT_FLORA
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
};

struct PS_INPUT_FLORA_NO_SHADOW
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
};

struct PS_INPUT
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
};

struct PS_INPUT_WATER
{
	float2 Tex0                           : TEXCOORD0;
	float3 LightDir                       : TEXCOORD1; //light direction for bump
	float4 LightDif                       : TEXCOORD2; //light diffuse for bump
	float3 CameraDir                      : TEXCOORD3; //camera direction for bump
	float4 PosWater                       : TEXCOORD4; //position according to the water camera
	float3 worldPos                       : TEXCOORD5; //global position for fresnel
	float3 worldNrm                       : TEXCOORD6; //global normal for fresnel
};



struct PS_INPUT_BUMP
{
	float4 VertexColor                    : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float3 SunLightDir                    : TEXCOORD1; //sun light dir in pixel coordinates
	float3 SkyLightDir                    : TEXCOORD2; //light diffuse for bump
	float4 PointLightDir                  : TEXCOORD3; //light ambient for bump
	float4 ShadowTexCoord                 : TEXCOORD4;
	float2 ShadowTexelPos                 : TEXCOORD5;
};

struct PS_INPUT_BUMP_DYNAMIC
{
	float4 VertexColor                    : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float3 vec_to_light_0                 : TEXCOORD1;
	float3 vec_to_light_1                 : TEXCOORD2;
	float3 vec_to_light_2                 : TEXCOORD3;
	// float3 vec_to_light_3              : TEXCOORD4;
	// float3 vec_to_light_4              : TEXCOORD5;
	// float3 vec_to_light_5              : TEXCOORD6;
	// float3 vec_to_light_6              : TEXCOORD7;
};


struct PS_INPUT_DOT3_BUMP
{
	float4 Color                          : COLOR0;
	float4 SunColor                       : COLOR1;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
};

struct PS_INPUT_SHADOWMAP
{
	float2 Tex0                           : TEXCOORD0;
	float  Depth                          : TEXCOORD1;
};

struct PS_INPUT_CHARACTER_SHADOW
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
};



struct VS_OUTPUT_CHARACTER_SHADOW
{
	float4 Pos                            : POSITION;
	float2 Tex0                           : TEXCOORD0;
	float4 Color                          : COLOR0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float  Fog                            : FOG;
};

struct VS_OUTPUT_SHADOWMAP
{

	float4 Pos                            : POSITION;
	float2 Tex0                           : TEXCOORD0;
	float  Depth                          : TEXCOORD1;
};

struct VS_OUTPUT_NOLIGHT
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
};

struct VS_OUTPUT_NOTEXTURE
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float  Fog                            : FOG;
};

struct VS_OUTPUT_FONT
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float  Fog                            : FOG;
};

struct VS_OUTPUT_FLORA
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float  Fog                            : FOG;
};


struct VS_OUTPUT_FLORA_NO_SHADOW
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float  Fog                            : FOG;
};

struct VS_OUTPUT
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float  Fog                            : FOG;
};

// Pixel shader output structure
struct PS_OUTPUT
{
	float4 RGBColor                       : COLOR;
};

struct VS_OUTPUT_BUMP
{
	float4 Pos                            : POSITION;
	float4 VertexColor                    : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float3 SunLightDir                    : TEXCOORD1; //sun light dir in pixel coordinates
	float3 SkyLightDir                    : TEXCOORD2; //light diffuse for bump
	float4 PointLightDir                  : TEXCOORD3; //light ambient for bump
	float4 ShadowTexCoord                 : TEXCOORD4;
	float2 ShadowTexelPos                 : TEXCOORD5;
	float  Fog                            : FOG;
};

struct VS_OUTPUT_BUMP_DYNAMIC
{
	float4 Pos                            : POSITION;
	float4 VertexColor                    : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float3 vec_to_light_0                 : TEXCOORD1;
	float3 vec_to_light_1                 : TEXCOORD2;
	float3 vec_to_light_2                 : TEXCOORD3;
	// float4 vec_to_light_3              : TEXCOORD4;
	// float4 vec_to_light_4              : TEXCOORD5;
	// float4 vec_to_light_5              : TEXCOORD6;
	// float4 vec_to_light_6              : TEXCOORD7;
	float  Fog                            : FOG;
};

struct VS_OUTPUT_DOT3_BUMP
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float4 SunColor                       : COLOR1;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float  Fog                            : FOG;
};

struct VS_OUTPUT_WATER
{
	float4 Pos                            : POSITION;
	float2 Tex0                           : TEXCOORD0;
	float3 LightDir                       : TEXCOORD1; //light direction for bump
	float4 LightDif                       : TEXCOORD2; //light diffuse for bump
	float3 CameraDir                      : TEXCOORD3; //camera direction for bump
	float4 PosWater                       : TEXCOORD4; //position according to the water camera
	float3 worldPos                       : TEXCOORD5; //global position for fresnel
	float3 worldNrm                       : TEXCOORD6; //global normal for fresnel
	float  Fog                            : FOG;
};

struct VS_OUTPUT_MAP_WATER
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float3 LightDir                       : TEXCOORD1; //light direction for bump
	float4 LightDif                       : TEXCOORD2; //light diffuse for bump
	float3 CameraDir                      : TEXCOORD3; //camera direction for bump
	float4 PosWater                       : TEXCOORD4; //position according to the water camera
	float  Fog                            : FOG;
};

struct PS_INPUT_MAP_WATER
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float3 LightDir                       : TEXCOORD1; //light direction for bump
	float4 LightDif                       : TEXCOORD2; //light diffuse for bump
	float3 CameraDir                      : TEXCOORD3; //camera direction for bump
	float4 PosWater                       : TEXCOORD4; //position according to the water camera
};

struct VS_OUTPUT_MAP_MOUNTAIN
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float3 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float  Fog                            : FOG;
};

struct PS_INPUT_MAP_MOUNTAIN
{
	float4 Color                          : COLOR0;
	float3 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
};

struct VS_OUTPUT_CLEAR_FLOATING_POINT_BUFFER
{
	float4 Pos                            : POSITION;
};

struct VS_OUTPUT_SPECULAR_ALPHA
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float3 worldPos                       : TEXCOORD4;
	float3 worldNormal                    : TEXCOORD5;
	float  Fog                            : FOG;
};

struct PS_INPUT_SPECULAR_ALPHA
{
	float4 Color                          : COLOR0;
	float2 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float3 worldPos                       : TEXCOORD4;
	float3 worldNormal                    : TEXCOORD5;
};

struct VS_OUTPUT_ENVMAP_SPECULAR
{
	float4 Pos                            : POSITION;
	float4 Color                          : COLOR0;
	float4 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float3 vSpecular                      : TEXCOORD4;
	//   float3 worldPos                  : TEXCOORD5;
	//   float3 worldNormal               : TEXCOORD6;
	float  Fog                            : FOG;
};

struct PS_INPUT_ENVMAP_SPECULAR
{
	float4 Color                          : COLOR0;
	float4 Tex0                           : TEXCOORD0;
	float4 SunLight                       : TEXCOORD1;
	float4 ShadowTexCoord                 : TEXCOORD2;
	float2 TexelPos                       : TEXCOORD3;
	float3 vSpecular                      : TEXCOORD4;
	// float3 worldPos                 : TEXCOORD5;
	// float3 worldNormal              : TEXCOORD6;
};

//--------------------------------------------------------------------------------------
// Texture samplers

//--------------------------------------------------------------------------------------

sampler ShadowmapTextureSampler =
sampler_state
{
	Texture = <shadowmap_texture>;
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;


};

sampler ClampedTextureSampler =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler FontTextureSampler =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = Anisotropic;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler CharacterShadowTextureSampler =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = Anisotropic;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler MeshTextureSampler =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MaxAnisotropy = 4;
};

sampler MeshTextureSamplerNoFilter =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = NONE;
	MinFilter = NONE;
	MagFilter = NONE;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler MeshTextureSamplerHQ =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = Anisotropic;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler DiffuseTextureSamplerNoWrap =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MaxAnisotropy = 4;
};

sampler GrassTextureSampler =
sampler_state
{
	Texture = <diffuse_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MaxAnisotropy = 4;
	MipMapLodBias = -1.0;
};

sampler Diffuse2Sampler =
sampler_state
{
	Texture = <diffuse_texture_2>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MaxAnisotropy = 4;
};

sampler ReflectionTextureSampler =
sampler_state
{
	Texture = <env_texture>;
	MipFilter = Anisotropic;
	MinFilter = Anisotropic;
	MagFilter = Anisotropic;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

sampler EnvTextureSampler =
sampler_state
{
	Texture = <env_texture>;
	MipFilter = Anisotropic;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler NormalTextureSampler =
sampler_state
{
	Texture = <normal_texture>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

sampler SpecularTextureSampler =
sampler_state
{
	Texture = <specular_texture>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};

float GetSunAmount(uniform const int PcfMode, float4 ShadowTexCoord, float2 TexelPos)
{
	float sun_amount;
	if (PcfMode == PCF_NVIDIA)
	{
		sun_amount = tex2Dproj(ShadowmapTextureSampler, ShadowTexCoord).r;
	}
	else
	{
		float2 lerps = frac(TexelPos);
		//read in bilerp stamp, doing the shadow checks
		float sourcevals[4];
		sourcevals[0] = (tex2D(ShadowmapTextureSampler, ShadowTexCoord).r < ShadowTexCoord.z)? 0.0f: 1.0f;
		sourcevals[1] = (tex2D(ShadowmapTextureSampler, ShadowTexCoord + float2(fShadowMapNextPixel, 0)).r < ShadowTexCoord.z)? 0.0f: 1.0f;
		sourcevals[2] = (tex2D(ShadowmapTextureSampler, ShadowTexCoord + float2(0, fShadowMapNextPixel)).r < ShadowTexCoord.z)? 0.0f: 1.0f;
		sourcevals[3] = (tex2D(ShadowmapTextureSampler, ShadowTexCoord + float2(fShadowMapNextPixel, fShadowMapNextPixel)).r < ShadowTexCoord.z)? 0.0f: 1.0f;

		// lerp between the shadow values to calculate our light amount
		sun_amount = lerp(lerp(sourcevals[0], sourcevals[1], lerps.x), lerp(sourcevals[2], sourcevals[3], lerps.x), lerps.y);
	}
	return sun_amount;
}

float get_fog_amount(float distance_to_view, float ground_height)
{
	//   return saturate((fFogEnd - d) / (fFogEnd - fFogStart));
	return 1.0f / exp(( length(distance_to_view) - (ground_height*2) ) * fFogDensity);
}

//--> Derivative Maps helper functions from [http://www.rorydriscoll.com/2012/01/11/derivative-maps/]
// Project the surface gradient (dhdx, dhdy) onto the surface (n, dpdx, dpdy)
float3 CalculateSurfaceGradient(float3 normal, float3 dpdx, float3 dpdy, float dhdx, float dhdy)
{
    float3 r1 = cross(dpdy, normal);
    float3 r2 = cross(normal, dpdx);
 
    return (r1 * dhdx - r2 * dhdy) / dot(dpdx, r1);
}
 
// Move the normal away from the surface normal in the opposite surface gradient direction
float3 PerturbNormal(float3 normal, float3 dpdx, float3 dpdy, float dhdx, float dhdy)
{
    return normalize(normal - CalculateSurfaceGradient(normal, dpdx, dpdy, dhdx, dhdy));
}

// Calculate the surface normal using screen-space partial derivatives of the height field
float3 CalculateSurfaceNormal(float3 position, float3 normal, float height)
{
    float3 dpdx = ddx(position);
    float3 dpdy = ddy(position);
 
    float dhdx = ddx(height);
    float dhdy = ddy(height);
 
    return PerturbNormal(normal, dpdx, dpdy, dhdx, dhdy);
}
//<--

VS_OUTPUT_CLEAR_FLOATING_POINT_BUFFER vs_clear_floating_point_buffer(float4 vPosition : POSITION)
{
	VS_OUTPUT_CLEAR_FLOATING_POINT_BUFFER Out;

	Out.Pos = mul(matWorldViewProj, vPosition);

	return Out;
}

PS_OUTPUT ps_clear_floating_point_buffer()
{
	PS_OUTPUT Out;
	// Out.RGBColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
	Out.RGBColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
	return Out;
}

VS_OUTPUT_NOTEXTURE vs_main_notexture(float4 vPosition : POSITION, float4 vColor : COLOR)
{
	VS_OUTPUT_NOTEXTURE Out;

	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Color = vColor * vMaterialColor;
	float3 P = mul(matWorldView, vPosition); //position in view space
	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);

	return Out;
}

PS_OUTPUT ps_main_notexture( PS_INPUT_NOTEXTURE In )
{
	PS_OUTPUT Output;
	Output.RGBColor = In.Color;
	return Output;
}

VS_OUTPUT_FONT vs_font(float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FONT Out;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;
	Out.Color = vColor * vMaterialColor;
	
	
	/*
	  Replace hardcoded menu colors--
	  Yellow: #fddd0b
	  DGreen: #218221
	  BBrown: #d4c5b5
	  BGreen: #7cfd78   /255.f
	 */

   #define rgbcol(rr,gg,bb) float4(Out.Color.r == rr/255.f, \
                                   Out.Color.g == gg/255.f, \
                                   Out.Color.b == bb/255.f)

  /* yellow */
  if( Out.Color.r == 1.0f
  
   && Out.Color.g >= 0.86f
   && Out.Color.g <= 0.87f
   
   && Out.Color.b == 0.0f){
    Out.Color.rgb = float3(0.3f,0.4f,1.0f);  //--> soft blue
  }
  
  /* pure blue (#0000ff) */
  if( Out.Color.r == 0.0f
   && Out.Color.g == 0.0f //-->pure blue used all over the quests menu
   && Out.Color.b == 1.0f){
    Out.Color.rgb = float3(0.25f,0.35f,0.55f);  //--> darker soft blue
  }
  
  /* pure black (#000000) */
  if( Out.Color.r == 0.0f
   && Out.Color.g == 0.0f
   && Out.Color.b == 0.0f){
      Out.Color.rgb = float3(0.2f,0.2f,0.3f);  //--> bluish dark gray
  }
  
  /* dark green (#007700) */
  if((Out.Color.r == 0.0f
   
   && Out.Color.g >= 0.46f
   && Out.Color.g <= 0.47f
   
   && Out.Color.b == 0.0f)
 || ( Out.Color.r == 1.0f
   && Out.Color.g == 0.0f  //--> pure red used in the quests menu (#ff0000)
   && Out.Color.b == 0.0f)){
      Out.Color.rgb = float3(0.6f,0.2f,0.0f);  //-->  maroon
  }
  
  /* light green */
  if( Out.Color.r >= 0.333f
   && Out.Color.r <= 0.334f
   
   && Out.Color.g == 1.0f
   
   && Out.Color.b >= 0.313f
   && Out.Color.b <= 0.314f){
      Out.Color.rgb = float3(0.7f,0.4f,0.0f);  //--> dark redish
  }
  
	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);

	return Out;
}

VS_OUTPUT_FONT vs_swconquest_galaxy(float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FONT Out;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float3 P = mul(matWorldView, vPosition); //position in view space

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	Out.Fog = get_fog_amount(d,u);
	
	
	Out.Tex0 = tc;
	Out.Color = vColor * vMaterialColor;
	Out.Color.b += (d + 0.2f);
	Out.Color.a  = 0.8f;

	return Out;
}

PS_OUTPUT ps_font_uniform_color(PS_INPUT_FONT In)
{	
	PS_OUTPUT Output;
	Output.RGBColor =  In.Color;
	
	Output.RGBColor.a *= tex2D(FontTextureSampler, In.Tex0).a;
	return Output;
}

PS_OUTPUT ps_font_background(PS_INPUT_FONT In)
{
	PS_OUTPUT Output;
	Output.RGBColor.a = 1.0f; //In.Color.a;
	Output.RGBColor.rgb = tex2D(FontTextureSampler, In.Tex0).rgb + In.Color.rgb;
	// Output.RGBColor.rgb += 1.0f - In.Color.a;

	return Output;
}

PS_OUTPUT ps_font_outline(PS_INPUT_FONT In)
{

	float4 sample = tex2D(FontTextureSampler, In.Tex0);
	PS_OUTPUT Output;
	Output.RGBColor =  In.Color;
	Output.RGBColor.a = (1.0f - sample.r) + sample.a;
	Output.RGBColor.rgb *= 0.6f * sample.a + 0.4f;

	return Output;
}

PS_OUTPUT ps_no_shading(PS_INPUT_FONT In)
{
	PS_OUTPUT Output;
	Output.RGBColor =  In.Color;
	Output.RGBColor *= tex2D(DiffuseTextureSamplerNoWrap, In.Tex0);
	return Output;
}

PS_OUTPUT ps_no_shading_no_alpha(PS_INPUT_FONT In)
{
	PS_OUTPUT Output;
	Output.RGBColor =  In.Color;
	Output.RGBColor *= tex2D(MeshTextureSamplerNoFilter, In.Tex0);
	Output.RGBColor.a = 1.0f;
	return Output;
}

PS_OUTPUT ps_skybox_shading(PS_INPUT_FONT In)
{
	PS_OUTPUT Output;
	Output.RGBColor =  In.Color;
	Output.RGBColor *= tex2D(MeshTextureSampler, In.Tex0);
	return Output;
}

VS_OUTPUT_FONT vs_skybox(float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FONT Out;
	Out.Pos = mul(matWorldViewProj, vPosition);

	float3 P = vPosition; //position in view space

	Out.Tex0 = tc;

	//SWY -- Sky rotation:
	Out.Tex0.x += time_var/1200;


	Out.Color = vColor * vMaterialColor;

	//apply fog
	P.z    *= 0.2f;
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

VS_OUTPUT_FLORA vs_flora(uniform const int PcfMode, float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FLORA Out = (VS_OUTPUT_FLORA)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	float4 vWorldPos = (float4)mul(matWorld,vPosition);

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;
	//   Out.Color = vColor * vMaterialColor;
	Out.Color = vColor * (vAmbientColor + vSunColor * 0.06f); //add some sun color to simulate sun passing through leaves.

	//   Out.Color = vColor * vMaterialColor * (vAmbientColor + vSunColor * 0.15f);
	//shadow mapping variables
	Out.SunLight = (vSunColor * 0.34f)* vMaterialColor * vColor;

	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
	}
	//shadow mapping variables end

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

PS_OUTPUT ps_flora(PS_INPUT_FLORA In, uniform const int PcfMode)
{
	PS_OUTPUT Output;
	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	clip(tex_col.a - 0.05f);


	tex_col.rgb = pow(tex_col.rgb, input_gamma);


	if (PcfMode != PCF_NONE)
	{
		float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		Output.RGBColor =  tex_col * ((In.Color + In.SunLight * sun_amount));
	}
	else
	{
		Output.RGBColor =  tex_col * ((In.Color + In.SunLight));
	}

	// Output.RGBColor = tex_col * (In.Color + In.SunLight);

	//Output.RGBColor = tex_col * In.Color;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);

	return Output;
}

VS_OUTPUT_FLORA_NO_SHADOW vs_flora_no_shadow(float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FLORA_NO_SHADOW Out = (VS_OUTPUT_FLORA_NO_SHADOW)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	float4 vWorldPos = (float4)mul(matWorld,vPosition);

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;
	Out.Color = vColor * vMaterialColor;

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

PS_OUTPUT ps_flora_no_shadow(PS_INPUT_FLORA_NO_SHADOW In)
{
	PS_OUTPUT Output;
	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	clip(tex_col.a - 0.05f);

	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor = tex_col * In.Color;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);

	return Output;
}

VS_OUTPUT_FLORA vs_grass(uniform const int PcfMode, float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FLORA Out = (VS_OUTPUT_FLORA)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	float4 vWorldPos = (float4)mul(matWorld,vPosition);

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;
	Out.Color = vColor * vAmbientColor;

	//shadow mapping variables
	if (PcfMode != PCF_NONE)
	{
		Out.SunLight = (vSunColor * 0.55f) * vMaterialColor * vColor;
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
	}
	else
	{
		Out.SunLight = vSunColor * 0.5f * vColor;
	}
	//shadow mapping variables end
	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	Out.Color.a = min(1.0f,(1.0f - (d / 50.0f)) * 2.0f);

	return Out;
}

PS_OUTPUT ps_grass(PS_INPUT_FLORA In, uniform const int PcfMode)
{
	PS_OUTPUT Output;
	float4 tex_col = tex2D(GrassTextureSampler, In.Tex0);

	// clip(tex_col.a - 0.05f);
	clip(tex_col.a - 0.1f);

	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	if ((PcfMode != PCF_NONE))
	{
		float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		Output.RGBColor =  tex_col * ((In.Color + In.SunLight * sun_amount));
	}
	else
	{
		Output.RGBColor =  tex_col * ((In.Color + In.SunLight));
	}

	// Output.RGBColor = tex_col * (In.Color + In.SunLight);
	// Output.RGBColor = tex_col * In.Color;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}

VS_OUTPUT_FLORA_NO_SHADOW vs_grass_no_shadow(float4 vPosition : POSITION, float4 vColor : COLOR, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_FLORA_NO_SHADOW Out = (VS_OUTPUT_FLORA_NO_SHADOW)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	float4 vWorldPos = (float4)mul(matWorld,vPosition);

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;
	Out.Color = vColor * vMaterialColor;

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	Out.Color.a = min(1.0f,(1.0f - (d / 50.0f)) * 2.0f);

	return Out;
}

PS_OUTPUT ps_grass_no_shadow(PS_INPUT_FLORA_NO_SHADOW In)
{
	PS_OUTPUT Output;
	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);

	clip(tex_col.a - 0.1f);

	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor = tex_col * In.Color;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}


VS_OUTPUT_FONT vs_main_no_shadow(uniform const bool isSarlacc, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vLightColor : COLOR1)
{
	VS_OUTPUT_FONT Out;
	
	if(isSarlacc){
		vPosition.x +=sin(time_var-vPosition.z)/4*saturate(vPosition.z);
		vPosition.y +=cos(time_var-vPosition.x)/4*saturate(vPosition.z);
		vPosition.z +=sin(time_var-vPosition.y)/2*saturate(vPosition.z); //move the tentacles in a menacing way :)
	}
	
	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space
	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;

	float4 diffuse_light = vAmbientColor + vLightColor;
	diffuse_light += max(0.0f, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;
	diffuse_light += max(0.0f,dot(vWorldN, -vSunDir)) * vSunColor;
	Out.Color = (vMaterialColor * vColor * diffuse_light);

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);

	return Out;
}


PS_OUTPUT ps_main_no_shadow(PS_INPUT_FONT In, uniform const bool isgalaxy=false)
{
	PS_OUTPUT Output;
	float4 tex_col  = tex2D(MeshTextureSamplerHQ, In.Tex0);
	tex_col.rgb     = pow(tex_col.rgb, input_gamma);
	Output.RGBColor = In.Color * tex_col;

  // if the fragment shader is used for the galaxy and this is not for asteroids
  // (texture in the bottom part of the UV map, as they share map_trees mat)
  if (isgalaxy && In.Tex0.y<0.86f ){
    clip(tex_col.a - 0.11f);
    
    float4 tex_colb = tex2D(Diffuse2Sampler, In.Tex0*30);
    float4 tex_colc = tex2D(Diffuse2Sampler, In.Tex0*20);
    
    Output.RGBColor.rg  += (tex_colc.rg*4);
    Output.RGBColor.rgb *= (tex_colb.rgb*1.5+(tex_col/14));
    Output.RGBColor.rgb *=  saturate((In.Tex0.x+0.5f)/(In.Tex0.y+0.5f));
    
    Output.RGBColor.rgb *= (tex_col.r+tex_col.g);
    
    Output.RGBColor.a    = max(tex_colb.a,  Output.RGBColor.a/2);
    Output.RGBColor.a   /= tex_colb.rgb;
    //Output.RGBColor.a += (In.Color.a) * (In.Color.a) * (3 - 2 * (In.Color.a));
  }
  
	//Output.RGBColor = In.Color * Output.RGBColor;
  
	Output.RGBColor.rgb  = pow(Output.RGBColor.rgb, output_gamma_inv);
  
	return Output;
}

PS_OUTPUT ps_simple_no_filtering(PS_INPUT_FONT In)
{
	PS_OUTPUT Output;
	float4 tex_col = tex2D(MeshTextureSamplerNoFilter, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);
	Output.RGBColor =  In.Color * tex_col;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}

PS_OUTPUT ps_main_no_shadow_no_wrap(PS_INPUT_FONT In)
{
	PS_OUTPUT Output;
	float4 tex_col = tex2D(DiffuseTextureSamplerNoWrap, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);
	Output.RGBColor =  In.Color * tex_col;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}



VS_OUTPUT vs_main (uniform const int PcfMode, uniform const bool UseSecondLight, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vLightColor : COLOR1)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;

	float4 diffuse_light = vAmbientColor;
	// diffuse_light.rgb *= gradient_factor * (gradient_offset + vWorldN.z);

	if (UseSecondLight)
	{
		diffuse_light += vLightColor;
	}

	//directional lights, compute diffuse color
	float dp = dot(vWorldN, -vSkyLightDir);
	diffuse_light += max(0, dp) * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float LD = length(point_to_light);
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float fAtten = 1.0f/(LD * LD);// + 0.9f / (LD * LD);
		//compute diffuse color
		diffuse_light += max(0, wNdotL) * vLightDiffuse[i] * fAtten;
	}
	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = (vMaterialColor * vColor * diffuse_light);

	//shadow mapping variables
	float wNdotSun = max(0.0f,dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor * vMaterialColor * vColor;
	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);
	return Out;
}

PS_OUTPUT ps_main(PS_INPUT In, uniform const int PcfMode, uniform const bool isGlowEnabled = false, uniform const bool isLavaEnabled = false)
{
	PS_OUTPUT Output;
	
	float4 tex_col = float4(0,0,0,0); //makes happy the dumb fx compiler :(
	
	if(isLavaEnabled){
	
		float time = sin(cos(time_var/32));
	
		float4 tex_cola = tex2D(MeshTextureSampler,     In.Tex0     +time    );
		float4 tex_colb = tex2D(Diffuse2Sampler,   (sin(In.Tex0)*cos(time))*2);
		float4 tex_colc = tex2D(Diffuse2Sampler,    cos(In.Tex0)*sin(time)   );
		
		tex_col = tex_cola;

	
		tex_col.rgb *= tex_colb.rgb;
		tex_col.rgb *= tex_colc.rgb;
		
		tex_col.rgb *= (tex_colc.rgb+tex_colc.rgb+tex_cola.rgb);//*tex_cola.rgb;
	
	}else{
	
		tex_col = tex2D(MeshTextureSampler, In.Tex0);
		tex_col.rgb = pow(tex_col.rgb, input_gamma);
	}
	
	
	if(isGlowEnabled)
	{
		In.SunLight = max(tex_col.a,In.SunLight);
    Output.RGBColor = tex_col * In.Color * (In.SunLight);
	}else{

    if ((PcfMode != PCF_NONE))
    {
      float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
      // sun_amount *= sun_amount;
      Output.RGBColor = tex_col * (In.Color + In.SunLight * sun_amount);

    }
    else
    {
      Output.RGBColor = tex_col * (In.Color + In.SunLight);
    }
  }
	
	// gamma correct
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}

VS_OUTPUT vs_swconquest_hologram(uniform const bool isAnimated, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	Out.Tex0  = tc;
	
	float time_var_mod = time_var + vPosition.z; //a little of variation never looks bad :)
	
	if(isAnimated)
	{
		Out.Tex0.x += time_var_mod/30;
	}

	//apply material color
	Out.Color = (vColor);
	Out.Color.a = max(0.6f,saturate(sin(time_var_mod*15)));
	
	return Out;
}

PS_OUTPUT ps_swconquest_hologram(PS_INPUT In)
{
	PS_OUTPUT Output;

	Output.RGBColor = tex2D(MeshTextureSampler, In.Tex0) * In.Color;
	
	return Output;
}

VS_OUTPUT vs_swconquest_lightsaber(float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Tex0 = tc;
	
	//apply material color
	Out.Color = (vColor);
	//Out.Color.rg = saturate(sin(time_var))+0.5f;
	Out.Color.a = saturate(sin(time_var*200))+0.6f;//max(0.6f,saturate(sin(time_var*15)*20));

	return Out;
}

PS_OUTPUT ps_swconquest_lightsaber(PS_INPUT In)
{
	PS_OUTPUT Output;
	
	Output.RGBColor = tex2D(MeshTextureSampler, In.Tex0);
  
  //we don't want have a blinking hilt :-)
  if(In.Tex0.x <= 0.8f){
      Output.RGBColor.a *= In.Color.a;
  }
  
  
	return Output;
}

VS_OUTPUT vs_main_skin (float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR, float4 vBlendWeights : BLENDWEIGHT, float4 vBlendIndices : BLENDINDICES, uniform const int PcfMode)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float4 vObjectPos = mul(matWorldArray[vBlendIndices.x], vPosition - matBoneOriginArray[vBlendIndices.x]) * vBlendWeights.x
	+ mul(matWorldArray[vBlendIndices.y], vPosition - matBoneOriginArray[vBlendIndices.y]) * vBlendWeights.y
	+ mul(matWorldArray[vBlendIndices.z], vPosition - matBoneOriginArray[vBlendIndices.z]) * vBlendWeights.z
	+ mul(matWorldArray[vBlendIndices.w], vPosition - matBoneOriginArray[vBlendIndices.w]) * vBlendWeights.w;
	float3 vObjectN = normalize(mul((float3x3)matWorldArray[vBlendIndices.x], vNormal) * vBlendWeights.x
	+ mul((float3x3)matWorldArray[vBlendIndices.y], vNormal) * vBlendWeights.y
	+ mul((float3x3)matWorldArray[vBlendIndices.z], vNormal) * vBlendWeights.z
	+ mul((float3x3)matWorldArray[vBlendIndices.w], vNormal) * vBlendWeights.w);

	float4 vWorldPos = mul(matWorld,vObjectPos);
	Out.Pos = mul(matViewProj, vWorldPos);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vObjectN)); //normal in world space

	float3 P = mul(matView, vWorldPos); //position in view space

	Out.Tex0 = tc;

	//light computation
	Out.Color = vAmbientColor;
	//   Out.Color.rgb *= gradient_factor * (gradient_offset + vWorldN.z);

	//directional lights, compute diffuse color
	Out.Color += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float LD = length(point_to_light);
		float fAtten = 1.0f /(LD * LD);// +  0.9f / (LD * LD);
		//compute diffuse color
		Out.Color += max(0, wNdotL) * vLightDiffuse[i] * fAtten;
	}

	//apply material color
	Out.Color *= vMaterialColor * vColor;
	Out.Color = min(1, Out.Color);

	//shadow mapping variables
	float wNdotSun = max(-0.0001, dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor * vMaterialColor * vColor;
	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

VS_OUTPUT vs_face (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vLightColor : COLOR1)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;

	float4 diffuse_light = vAmbientColor;
	//   diffuse_light.rgb *= gradient_factor * (gradient_offset + vWorldN.z);

	//directional lights, compute diffuse color
	diffuse_light += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float LD = length(point_to_light);
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float fAtten = 1.0f/(LD * LD);// + 0.9f / (LD * LD);
		//compute diffuse color
		diffuse_light += max(0.2f * (wNdotL + 0.9f), wNdotL) * vLightDiffuse[i] * fAtten;
	}
	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = vMaterialColor * vColor * diffuse_light;

	//shadow mapping variables
	float wNdotSun = dot(vWorldN, -vSunDir);
	Out.SunLight =  max(0.2f * (wNdotSun + 0.9f),wNdotSun) * vSunColor * vMaterialColor * vColor;
	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);
	return Out;
}

PS_OUTPUT ps_face(PS_INPUT In, uniform const int PcfMode)
{
	PS_OUTPUT Output;

	float4 tex1_col = tex2D(MeshTextureSampler, In.Tex0);
	float4 tex2_col = tex2D(Diffuse2Sampler, In.Tex0);

	float4 tex_col;

	tex_col = tex2_col * In.Color.a + tex1_col * (1.0f - In.Color.a);

	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	if ((PcfMode != PCF_NONE))
	{
		float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		// sun_amount *= sun_amount;
		Output.RGBColor =  tex_col * ((In.Color + In.SunLight * sun_amount));
	}
	else
	{
		Output.RGBColor = tex_col * (In.Color + In.SunLight);
	}
	// gamma correct
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	Output.RGBColor.a = vMaterialColor.a;
	return Output;
}

VS_OUTPUT vs_hair (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vLightColor : COLOR1)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;

	float4 diffuse_light = vAmbientColor;
	//   diffuse_light.rgb *= gradient_factor * (gradient_offset + vWorldN.z);

	//directional lights, compute diffuse color
	diffuse_light += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float LD = length(point_to_light);
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float fAtten = 1.0f/(LD * LD);// + 0.9f / (LD * LD);
		//compute diffuse color
		diffuse_light += max(0.2f * (wNdotL + 0.9f), wNdotL) * vLightDiffuse[i] * fAtten;
	}
	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = vColor * diffuse_light;

	//shadow mapping variables
	float wNdotSun = dot(vWorldN, -vSunDir);
	Out.SunLight =  max(0.2f * (wNdotSun + 0.9f),wNdotSun) * vSunColor * vColor;
	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);
	return Out;
}

PS_OUTPUT ps_hair(PS_INPUT In, uniform const int PcfMode)
{
	PS_OUTPUT Output;

	float4 tex1_col = tex2D(MeshTextureSampler, In.Tex0);
	float4 tex2_col = tex2D(Diffuse2Sampler, In.Tex0);

	float4 final_col;

	tex1_col.rgb = pow(tex1_col.rgb, input_gamma);

	final_col = tex1_col * vMaterialColor;

	float alpha = saturate(((2.0f * vMaterialColor2.a ) + tex2_col.a) - 1.9f);
	final_col.rgb *= (1.0f - alpha);
	final_col.rgb += tex2_col.rgb * alpha;

	// tex_col = tex2_col * vMaterialColor2.a + tex1_col * (1.0f - vMaterialColor2.a);


	float4 total_light = In.Color;
	if ((PcfMode != PCF_NONE))
	{
		float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		total_light.rgb += In.SunLight.rgb * sun_amount;
	}
	else
	{
		total_light.rgb += In.SunLight.rgb;
	}
	Output.RGBColor =  final_col * total_light;
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}


VS_OUTPUT_WATER vs_main_water(float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0,  float3 vTangent : TANGENT, float3 vBinormal : BINORMAL)
{
	VS_OUTPUT_WATER Out = (VS_OUTPUT_WATER) 0;

	//SWY-- Wavy Water
	vPosition.z += (cos( time_var + (vPosition.y/vPosition.x) * 5 ) /50 );

  //water surfaces massively bigger
  //vPosition.xy *= 6;
  //vPosition.xy -= 600;

	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.PosWater = mul(matWaterWorldViewProj, vPosition);

	float3 vWorldPos = (float3)mul(matWorld,vPosition);
	float3 point_to_camera_normal = normalize(vCameraPos - vWorldPos);

	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space
	float3 vWorld_binormal = normalize(mul((float3x3)matWorld, vBinormal)); //normal in world space
	float3 vWorld_tangent  = normalize(mul((float3x3)matWorld, vTangent)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space

	float3x3 TBNMatrix = float3x3(vWorld_tangent, vWorld_binormal, vWorldN);

	Out.CameraDir = normalize(mul(TBNMatrix, point_to_camera_normal));

	Out.Tex0 = tc + texture_offset.xy;

	//SWY-- water displacement
	Out.Tex0.xy += (time_var/300);

	Out.LightDir = 0;
	Out.LightDif = vAmbientColor;
	float totalLightPower = 0;

	//directional lights, compute diffuse color
	Out.LightDir += normalize(mul(TBNMatrix, -vSunDir) * length(vSunColor.xyz));
	Out.LightDif += vSunColor;
	totalLightPower += length(vSunColor.xyz);
	/*
//point lights
for(int j = 0; j < iLightPointCount; j++)
{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i] - vWorldPos;
		float3 L = normalize(point_to_light);
		float LD = length(point_to_light);
		float fAtten = 1.0f/LD;// + 0.9f / (LD * LD);
		float light_strength = length(vLightDiffuse[i].xyz) * fAtten;
		Out.LightDir += normalize(mul(TBNMatrix, L)) * light_strength;
		Out.LightDif += vLightDiffuse[i] * fAtten;
		totalLightPower += light_strength;
}
*/
	float vectoral_light_sum = length(Out.LightDir);
	//   float coef = vectoral_light_sum / totalLightPower;
	//   Out.LightDif *= coef;
	Out.LightDir = normalize(Out.LightDir);
	//   Out.LightDir.y = -Out.LightDir.y;
	//   Out.LightDif = min(1, Out.LightDif);

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	//SWY-- no fog for water
	Out.Fog = get_fog_amount(d,u);///600);
  
  //Fresnel vectors
  Out.worldPos=vWorldPos;
  Out.worldNrm=vWorldN;
  
	return Out;
}

PS_OUTPUT ps_main_water( PS_INPUT_WATER In )
{
  PS_OUTPUT Output;
  
  // Load normal and expand range
  float4 vNormalSample = normalize(tex2D( NormalTextureSampler, In.Tex0 )/18);
  float3 vNormal = (vNormalSample * 2.0 - 1.0)*0.06f;

  Output.RGBColor   = tex2D(ReflectionTextureSampler,
  float2(0.5f + 0.5f * ((In.PosWater.x / In.PosWater.z) +vNormal.x)+.016f,
         0.5f - 0.5f * ((In.PosWater.y / In.PosWater.z) -vNormal.y))
  );
  
  //Output.RGBColor.rgb = vNormalSample.rgb;
  
  
  //fresnel
  float3 vHalf = normalize(normalize(vCameraPos - In.worldPos) );
  float4 fVec  = saturate( dot( vHalf, normalize( In.worldNrm+vNormal) ));
  Output.RGBColor.rgb += (1-fVec)*(fVec);
  
  
  Output.RGBColor.a = max(Output.RGBColor.r/vNormalSample.z,.5f);
  return Output;
}


PS_OUTPUT ps_fake_water( PS_INPUT_WATER In )
{
	PS_OUTPUT Output;

	//TODO: Remove normalize when the image is correct
	float3 normal = (2.0f * tex2D(NormalTextureSampler, In.Tex0 * 2.0f).agb - 1.0f);
	normal.z = sqrt(1.0f - (normal.x * normal.x + normal.y * normal.y));

	float NdotL = dot(normal, In.LightDir);
	// Output.RGBColor = max(0, NdotL) * In.LightDif;

	float3 H = normalize(In.LightDir + In.CameraDir); //half vector
	float4 ColorSpec = pow(max(0, dot(H, normal)), fMaterialPower) * In.LightDif;

	// Output.RGBColor *= float4(1.5f, 1.5f, 3.0f, 1.0f);
	// ColorSpec *= float4(1.5f, 1.5f, 3.0f, 1.0f);

	// float distScaledDistortion = In.PosWater.z;
	//   distScaledDistortion = clamp(5 / (distScaledDistortion), 0.1f, 0.5f);

	//TODO: Remove scaledNormal. Apply it on the image.
	float3 scaledNormal = normalize(normal * float3(0.5f, 0.5f, 1.0f));

	float4 tex = tex2D(ReflectionTextureSampler, float2(0.5f + 0.5f * (In.PosWater.x / In.PosWater.z) + scaledNormal.x, 0.5f - 0.5f * (In.PosWater.y / In.PosWater.z) + scaledNormal.y));
	tex.rgb = pow(tex.rgb, output_gamma);

	Output.RGBColor = ((tex)/* + ColorSpec*/) * 0.4f;

	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor += 0.6f * tex_col;

	Output.RGBColor *= max(0, NdotL) * In.LightDif;
	// Output.RGBColor.a = 1 - distScaledDistortion;
	Output.RGBColor.w = 1.5f - In.CameraDir.z;

	Output.RGBColor.rgb = saturate(pow(Output.RGBColor.rgb, output_gamma_inv));

	return Output;
}

VS_OUTPUT_MAP_WATER vs_map_water (float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vLightColor : COLOR1)
{
	VS_OUTPUT_MAP_WATER Out = (VS_OUTPUT_MAP_WATER)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space


	Out.Tex0 = tc + texture_offset.xy;


	float4 diffuse_light = vAmbientColor + vLightColor;

	//directional lights, compute diffuse color
	diffuse_light += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	float wNdotSun = max(-0.0001f,dot(vWorldN, -vSunDir));
	diffuse_light += (wNdotSun) * vSunColor;

	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = (vMaterialColor * vColor) * diffuse_light;


	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

PS_OUTPUT ps_map_water(PS_INPUT_MAP_WATER In)
{
	PS_OUTPUT Output;
	Output.RGBColor =  In.Color;

	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor *= tex_col;

	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}


VS_OUTPUT_MAP_MOUNTAIN vs_map_mountain(uniform const int PcfMode, uniform const bool UseSecondLight, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vLightColor : COLOR1)
{
	VS_OUTPUT_MAP_MOUNTAIN Out = (VS_OUTPUT_MAP_MOUNTAIN)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0.xy = tc;
	Out.Tex0.z = max(0.0f, 0.7f * (vWorldPos.z - 1.5f));

	float4 diffuse_light = vAmbientColor;
	if (UseSecondLight)
	{
		diffuse_light += vLightColor;
	}

	//directional lights, compute diffuse color
	diffuse_light += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = (vMaterialColor * vColor * diffuse_light);

	//shadow mapping variables
	float wNdotSun = max(0.0f,dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor;
	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)

	Out.Fog = get_fog_amount(d,u);
	return Out;
}

PS_OUTPUT ps_map_mountain(PS_INPUT_MAP_MOUNTAIN In, uniform const int PcfMode)
{
	PS_OUTPUT Output;

	float4 sample_col = tex2D(MeshTextureSampler, In.Tex0.xy);

	float4 tex_col;
	tex_col.rgb = pow(sample_col.rgb, input_gamma);

	tex_col.rgb += saturate(In.Tex0.z * (sample_col.a) - 1.5f);
	tex_col.a = 1.0f;
	/*
	float snow = In.Tex0.z * (0.1f + sample_col.a) - 1.5f;
	if (snow > 0.5f)
	{
		tex_col = float4(1.0f,1.0f,1.0f,1.0f);
	}
*/
	if ((PcfMode != PCF_NONE))
	{
		float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		// sun_amount *= sun_amount;
		Output.RGBColor =  saturate(tex_col) * ((In.Color + In.SunLight * sun_amount));
	}
	else
	{
		Output.RGBColor = saturate(tex_col) * (In.Color + In.SunLight);
	}
	// gamma correct
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
	return Output;
}

VS_OUTPUT_DOT3_BUMP vs_main_dot3_bump (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vSunDir : COLOR1)
{
	VS_OUTPUT_DOT3_BUMP Out = (VS_OUTPUT_DOT3_BUMP)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Tex0 = tc;
	Out.Color = vColor;
	Out.SunColor = vSunDir;

	float3 P = mul(matWorldView, vPosition); //position in view space

	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal));
	float wNdotSun = max(-0.0001, dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor;
	if (PcfMode != PCF_NONE)
	{
		//shadow mapping variables
		float4 vWorldPos = (float4)mul(matWorld,vPosition);

		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

/*
PS_OUTPUT ps_main_dot3_bump(PS_INPUT_DOT3_BUMP In, uniform const int PcfMode)
{
	PS_OUTPUT Output;
	float3 normal = 2.0f * tex2D(NormalTextureSampler, In.Tex0).rgb - 1.0f;
	float3 diffuse = 2.0f * In.Color.rgb - 1.0f;
	float3 sun_color = 2.0f * In.SunColor.rgb - 1.0f;

	float4 light_amount = vAmbientColor;
	if (PcfMode != PCF_NONE)
	{
		float sun_amount = GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		light_amount += ((saturate(dot(sun_color, normal)) * (sun_amount)));
	}
	else
	{
		light_amount += saturate(dot(sun_color, normal));
	}
	light_amount += (saturate(dot(diffuse, normal)));

	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor =  tex_col * light_amount;

	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);

	Output.RGBColor.a = In.Color.a;
	return Output;
}
*/

VS_OUTPUT_BUMP vs_main_bump (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0,  float3 vTangent : TANGENT, float3 vBinormal : BINORMAL, float4 vVertexColor : COLOR0, float4 vPointLightDir : COLOR1)
{
	VS_OUTPUT_BUMP Out = (VS_OUTPUT_BUMP)0;

	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Tex0 = tc;


	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space
	float3 vWorld_binormal = normalize(mul((float3x3)matWorld, vBinormal)); //normal in world space
	float3 vWorld_tangent  = normalize(mul((float3x3)matWorld, vTangent)); //normal in world space

	float3 P = mul(matWorldView, vPosition); //position in view space

	float3x3 TBNMatrix = float3x3(vWorld_tangent, vWorld_binormal, vWorldN);

	if (PcfMode != PCF_NONE)
	{
		float4 vWorldPos = (float4)mul(matWorld,vPosition);

		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.ShadowTexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	Out.SunLightDir = mul(TBNMatrix, -vSunDir);
	Out.SkyLightDir = mul(TBNMatrix, -vSkyLightDir);
	Out.PointLightDir.rgb = 2.0f * vPointLightDir.rgb - 1.0f;
	Out.PointLightDir.a = vPointLightDir.a;
	Out.VertexColor = vVertexColor;

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

PS_OUTPUT ps_main_bump( PS_INPUT_BUMP In, uniform const int PcfMode )
{
	PS_OUTPUT Output;

	float4 total_light = vAmbientColor;//In.LightAmbient;

	//float3 normal = tex2D(NormalTextureSampler, In.Tex0).rgb;
	float3 normal = (2.0f * tex2D(NormalTextureSampler, In.Tex0).agb - 1.0f);
	normal.z = sqrt(1.0f - (normal.x * normal.x + normal.y * normal.y));
	normal.y *=  -1.0f;

	if (PcfMode != PCF_NONE)
	{
		float sun_amount = 0.05f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.ShadowTexelPos);
		// sun_amount *= sun_amount;
		total_light += ((saturate(dot(In.SunLightDir.xyz, normal.xyz)) * (sun_amount))) * vSunColor;
	}
	else
	{
		total_light += saturate(dot(In.SunLightDir.xyz, normal.xyz)) * vSunColor;
	}
	total_light += saturate(dot(In.SkyLightDir.xyz, normal.xyz)) * vSkyLightColor;
	total_light += saturate(dot(In.PointLightDir.xyz, normal.xyz)) * vPointLightColor;

	Output.RGBColor.rgb = total_light.rgb;
	Output.RGBColor.a = 1.0f;
	Output.RGBColor *= vMaterialColor;

	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor *= tex_col;
	Output.RGBColor *= In.VertexColor;

	// Output.RGBColor = saturate(Output.RGBColor);
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);

	Output.RGBColor.a = In.VertexColor.a;


	return Output;
}

PS_OUTPUT ps_main_bump_simple( PS_INPUT_BUMP In, uniform const int PcfMode )
{
	PS_OUTPUT Output;

	float4 total_light = vAmbientColor;//In.LightAmbient;

	//float3 normal = (2.0f *tex2D(NormalTextureSampler, In.Tex0).rgb - 1.0f);
	float3 normal = (3.0f * tex2D(NormalTextureSampler, In.Tex0).rgb - 1.0f);
	normal = normalize(normal);
	normal.y =  -normal.y;


	if (PcfMode != PCF_NONE)
	{
		float sun_amount = 0.05f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.ShadowTexelPos);
		// sun_amount *= sun_amount;
		total_light += ((saturate(dot(In.SunLightDir.xyz, normal.xyz)) * (sun_amount))) * vSunColor;
	}
	else
	{
		total_light += saturate(dot(In.SunLightDir.xyz, normal.xyz)) * vSunColor;
	}
	total_light += saturate(dot(In.SkyLightDir.xyz, normal.xyz)) * vSkyLightColor;
	total_light += saturate(dot(In.PointLightDir.xyz, normal.xyz)) * vPointLightColor;

	Output.RGBColor.rgb = total_light.rgb;
	Output.RGBColor.a = 1.0f;
	Output.RGBColor *= vMaterialColor;

	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor *= tex_col;
	Output.RGBColor *= In.VertexColor;

	// Output.RGBColor = saturate(Output.RGBColor);
	Output.RGBColor.rgb = saturate(pow(Output.RGBColor.rgb, output_gamma_inv));

	Output.RGBColor.a = In.VertexColor.a;

	return Output;
}

PS_OUTPUT ps_main_bump_simple_multitex( PS_INPUT_BUMP In, uniform const int PcfMode )
{
	PS_OUTPUT Output;

	float4 total_light = vAmbientColor;//In.LightAmbient;

	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	float4 tex_col2 = tex2D(Diffuse2Sampler, In.Tex0 * uv_2_scale);
	tex_col2.rgb = pow(tex_col2.rgb, input_gamma);

	float4 multi_tex_col = tex_col;
	float inv_alpha = (1.0f - In.VertexColor.a);
	multi_tex_col.rgb *= inv_alpha;
	multi_tex_col.rgb += tex_col2.rgb * In.VertexColor.a;

	//float3 normal = (2.0f * tex2D(NormalTextureSampler, In.Tex0).rgb - 1.0f);
	float3 normal = (1.0f * (tex2D(NormalTextureSampler, In.Tex0).rgb + tex2D(NormalTextureSampler, In.Tex0 * 3.17f).rgb) - 1.0f);

	// float3 normal2 = (2.0f * tex2D(NormalTexture2Sampler, In.Tex0).rgb - 1.0f);
	float3 multi_normal = normal;
	// multi_normal.rgb *= inv_alpha;
	// multi_normal.rgb += normal2.rgb * In.VertexColor.a;

	multi_normal.y *=  -1.0f;
	// multi_normal.z *= 0.5f;
	multi_normal = normalize(multi_normal);

	if (PcfMode != PCF_NONE)
	{
		float sun_amount = 0.05f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.ShadowTexelPos);
		// sun_amount *= sun_amount;
		total_light += ((saturate(dot(In.SunLightDir.xyz, multi_normal.xyz)) * (sun_amount))) * vSunColor;
	}
	else
	{
		total_light += saturate(dot(In.SunLightDir.xyz, multi_normal.xyz)) * vSunColor;
	}
	total_light += saturate(dot(In.SkyLightDir.xyz, multi_normal.xyz)) * vSkyLightColor;
	// total_light += saturate(dot(In.PointLightDir.xyz, multi_normal.xyz)) * vPointLightColor;


	Output.RGBColor.rgb = total_light.rgb;
	Output.RGBColor.a = 1.0f;
	// Output.RGBColor *= vMaterialColor;



	Output.RGBColor *= multi_tex_col;
	// Output.RGBColor *= In.VertexColor;
	Output.RGBColor.a *= In.PointLightDir.a;

	// Output.RGBColor = saturate(Output.RGBColor);
	Output.RGBColor.rgb = saturate(pow(Output.RGBColor.rgb, output_gamma_inv));
	return Output;
}

VS_OUTPUT_BUMP_DYNAMIC vs_main_bump_interior (float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0,  float3 vTangent : TANGENT, float3 vBinormal : BINORMAL, float4 vVertexColor : COLOR0)
{
	VS_OUTPUT_BUMP_DYNAMIC Out = (VS_OUTPUT_BUMP_DYNAMIC)0;

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Tex0 = tc;

	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space
	float3 vWorld_binormal = normalize(mul((float3x3)matWorld, vBinormal)); //normal in world space
	float3 vWorld_tangent  = normalize(mul((float3x3)matWorld, vTangent)); //normal in world space


	float3x3 TBNMatrix = float3x3(vWorld_tangent, vWorld_binormal, vWorldN);

	float3 point_to_light = vLightPosDir[0]-vWorldPos.xyz;
	Out.vec_to_light_0.xyz =  mul(TBNMatrix, point_to_light);
	point_to_light = vLightPosDir[1]-vWorldPos.xyz;
	Out.vec_to_light_1.xyz =  mul(TBNMatrix, point_to_light);
	point_to_light = vLightPosDir[2]-vWorldPos.xyz;
	Out.vec_to_light_2.xyz =  mul(TBNMatrix, point_to_light);

	/*
	point_to_light = vLightPosDir[3]-vWorldPos.xyz;
	Out.vec_to_light_3.xyz =  mul(TBNMatrix, point_to_light);
	Out.vec_to_light_3.w = length(point_to_light.xyz);
	point_to_light = vLightPosDir[4]-vWorldPos.xyz;
	Out.vec_to_light_4.xyz =  mul(TBNMatrix, point_to_light);
	Out.vec_to_light_4.w = length(point_to_light.xyz);
	point_to_light = vLightPosDir[5]-vWorldPos.xyz;
	Out.vec_to_light_5.xyz =  mul(TBNMatrix, point_to_light);
	Out.vec_to_light_5.w = length(Out.vec_to_light_5.xyz);
	point_to_light = vLightPosDir[6]-vWorldPos.xyz;
	Out.vec_to_light_6.xyz =  mul(TBNMatrix, point_to_light);
	Out.vec_to_light_6.w = length(Out.vec_to_light_6.xyz);
*/
	Out.VertexColor = vVertexColor;

	//apply fog
	float3 P = mul(matWorldView, vPosition); //position in view space
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);
	return Out;
}

PS_OUTPUT ps_main_bump_interior( PS_INPUT_BUMP_DYNAMIC In)
{
	PS_OUTPUT Output;

	float4 total_light = vAmbientColor;//In.LightAmbient;

	//float3 normal = tex2D(NormalTextureSampler, In.Tex0).rgb;
	//float3 normal = 2.0f * tex2D(NormalTextureSampler, In.Tex0).rgb - 1.0f;// - float3(1.0f, , 1.0f);
	float3 normal = (2.0f * tex2D(NormalTextureSampler, In.Tex0).agb - 1.0f);
	normal.z = sqrt(1.0f - (normal.x * normal.x + normal.y * normal.y));
	normal.y =  - normal.y;



	// normal = normalize(normal);

	// float3 abs_min_vec_to_light = float3(100000, 100000, 100000);

	// float LD = In.vec_to_light_0.w;
	float LD = length(In.vec_to_light_0.xyz);
	float3 L = normalize(In.vec_to_light_0.xyz);
	float wNdotL = dot(normal, L);
	total_light += saturate(wNdotL) * vLightDiffuse[0] /(LD * LD);

	// LD = In.vec_to_light_1.w;
	LD = length(In.vec_to_light_1.xyz);
	L = normalize(In.vec_to_light_1.xyz);
	wNdotL = dot(normal, L);
	total_light += saturate(wNdotL) * vLightDiffuse[1] /(LD * LD);

	// LD = In.vec_to_light_2.w;
	LD = length(In.vec_to_light_2.xyz);
	L = normalize(In.vec_to_light_2.xyz);
	wNdotL = dot(normal, L);
	total_light += saturate(wNdotL) * vLightDiffuse[2] /(LD * LD);

	/*
	LD = In.vec_to_light_3.w;
	L = normalize(In.vec_to_light_3.xyz);
	wNdotL = dot(normal, L);
	fAtten = 10.0f/(LD * LD);// + 0.01f / (LD * LD);
	total_light += saturate(wNdotL) * vLightDiffuse[3] * fAtten;

	LD = In.vec_to_light_4.w;
	L = normalize(In.vec_to_light_4.xyz);
	wNdotL = dot(normal, L);
	fAtten = 1.0f/(LD * LD);// + 0.01f / (LD * LD);
	total_light += saturate(wNdotL) * vLightDiffuse[4] * fAtten;

	LD = In.vec_to_light_5.w;
	L = normalize(In.vec_to_light_5.xyz);
	wNdotL = dot(normal, L);
	fAtten = 1.0f/(LD);// + 0.01f / (LD * LD);
	total_light += saturate(wNdotL) * vLightDiffuse[5] * fAtten;

	LD = In.vec_to_light_6.w;
	L = normalize(In.vec_to_light_6.xyz);
	wNdotL = dot(normal, L);
	fAtten = 1.0f/(LD);// + 0.01f / (LD * LD);
	total_light += saturate(wNdotL) * vLightDiffuse[6] * fAtten;
*/
	// Output.RGBColor = saturate(total_light * 0.6f) * 1.66f;
	Output.RGBColor = total_light;
	float4 tex_col = tex2D(MeshTextureSampler, In.Tex0);
	tex_col.rgb = pow(tex_col.rgb, input_gamma);

	Output.RGBColor *= tex_col;
	Output.RGBColor *= In.VertexColor;

	// Output.RGBColor = saturate(Output.RGBColor);
	Output.RGBColor.rgb = saturate(pow(Output.RGBColor.rgb, output_gamma_inv));
	Output.RGBColor.a = In.VertexColor.a;

	return Output;
}

VS_OUTPUT_SHADOWMAP vs_main_shadowmap_skin (float4 vPosition : POSITION, float2 tc : TEXCOORD0, float4 vBlendWeights : BLENDWEIGHT, float4 vBlendIndices : BLENDINDICES)
{
	VS_OUTPUT_SHADOWMAP Out;

	float4 vObjectPos = mul(matWorldArray[vBlendIndices.x], vPosition - matBoneOriginArray[vBlendIndices.x]) * vBlendWeights.x
	+ mul(matWorldArray[vBlendIndices.y], vPosition - matBoneOriginArray[vBlendIndices.y]) * vBlendWeights.y
	+ mul(matWorldArray[vBlendIndices.z], vPosition - matBoneOriginArray[vBlendIndices.z]) * vBlendWeights.z
	+ mul(matWorldArray[vBlendIndices.w], vPosition - matBoneOriginArray[vBlendIndices.w]) * vBlendWeights.w;

	Out.Pos = mul(matWorldViewProj, vObjectPos);
	Out.Depth = Out.Pos.z/ Out.Pos.w;
	Out.Tex0 = tc;

	return Out;
}

VS_OUTPUT_SHADOWMAP vs_main_shadowmap (float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0)
{
	VS_OUTPUT_SHADOWMAP Out;
	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Depth = Out.Pos.z/Out.Pos.w;

	if (1)//TODO: NVidia mode
	{
		float3 vScreenNormal = mul((float3x3)matWorldViewProj, vNormal); //normal in screen space
		Out.Depth -= vScreenNormal.z * fShadowBias;
	}

	Out.Tex0 = tc;
	return Out;
}

PS_OUTPUT ps_main_shadowmap(PS_INPUT_SHADOWMAP In)
{
	PS_OUTPUT Output;
	Output.RGBColor.a = tex2D(MeshTextureSampler, In.Tex0).a;
	Output.RGBColor.a -= 0.5f;
	clip(Output.RGBColor.a);

	Output.RGBColor.rgb = In.Depth;// + fShadowBias;
	return Output;
}

PS_OUTPUT ps_render_character_shadow(PS_INPUT_CHARACTER_SHADOW In)
{
	PS_OUTPUT Output;
	// Output.RGBColor = tex2D(MeshTextureSampler, In.Tex0);
	// Output.RGBColor.a = 1.0f;
	Output.RGBColor = 1.0f;
	return Output;
}

VS_OUTPUT_CHARACTER_SHADOW vs_character_shadow (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR)
{
	VS_OUTPUT_CHARACTER_SHADOW Out;

	if (PcfMode != PCF_NONE)
	{
		//shadow mapping variables
		float4 vWorldPos = (float4)mul(matWorld,vPosition);
		float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal));

		float wNdotSun = max(-0.0001, dot(vWorldN, -vSunDir));
		Out.SunLight = ( wNdotSun) * vSunColor;

		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}
	else
	{
		Out = (VS_OUTPUT_CHARACTER_SHADOW)0;
	}



	Out.Pos = mul(matWorldViewProj, vPosition);
	Out.Tex0 = tc;
	Out.Color = vColor * vMaterialColor;

	float3 P = mul(matWorldView, vPosition); //position in view space
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}


PS_OUTPUT ps_character_shadow(uniform const int PcfMode, PS_INPUT_CHARACTER_SHADOW In)
{
	PS_OUTPUT Output;

	if (PcfMode == PCF_NONE)
	{
		Output.RGBColor.a = tex2D(CharacterShadowTextureSampler, In.Tex0).a * In.Color.a;
	}
	else
	{
		float sun_amount = 0.05f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		// sun_amount *= sun_amount;
		Output.RGBColor.a = saturate(tex2D(CharacterShadowTextureSampler, In.Tex0).a * In.Color.a * sun_amount);
	}
	Output.RGBColor.rgb = In.Color.rgb;
	return Output;
}


VS_OUTPUT_SPECULAR_ALPHA vs_specular_alpha_skin (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, float4 vBlendWeights : BLENDWEIGHT, float4 vBlendIndices : BLENDINDICES)
{
	VS_OUTPUT_SPECULAR_ALPHA Out = (VS_OUTPUT_SPECULAR_ALPHA)0;

	float4 vObjectPos = mul(matWorldArray[vBlendIndices.x], vPosition - matBoneOriginArray[vBlendIndices.x]) * vBlendWeights.x
	+ mul(matWorldArray[vBlendIndices.y], vPosition - matBoneOriginArray[vBlendIndices.y]) * vBlendWeights.y
	+ mul(matWorldArray[vBlendIndices.z], vPosition - matBoneOriginArray[vBlendIndices.z]) * vBlendWeights.z
	+ mul(matWorldArray[vBlendIndices.w], vPosition - matBoneOriginArray[vBlendIndices.w]) * vBlendWeights.w;
	float3 vObjectN = normalize(mul((float3x3)matWorldArray[vBlendIndices.x], vNormal) * vBlendWeights.x
	+ mul((float3x3)matWorldArray[vBlendIndices.y], vNormal) * vBlendWeights.y
	+ mul((float3x3)matWorldArray[vBlendIndices.z], vNormal) * vBlendWeights.z
	+ mul((float3x3)matWorldArray[vBlendIndices.w], vNormal) * vBlendWeights.w);

	float4 vWorldPos = mul(matWorld,vObjectPos);
	Out.Pos = mul(matViewProj, vWorldPos);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vObjectN)); //normal in world space

	float3 P = mul(matView, vWorldPos); //position in view space

	// Out.Pos = mul(matWorldViewProj, vPosition);

	// float4 vWorldPos = (float4)mul(matWorld,vPosition);
	// float3 vWorldN = mul((float3x3)matWorld, vNormal); //normal in world space

	Out.worldPos = vWorldPos;
	Out.worldNormal = vWorldN;

	// float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;

	float4 diffuse_light = vAmbientColor;
	// diffuse_light.rgb *= gradient_factor * (gradient_offset + vWorldN.z);

	//directional lights, compute diffuse color
	diffuse_light += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float LD = length(point_to_light);
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float fAtten = 1.0f/(LD*LD);// + 0.9f / (LD * LD);
		//compute diffuse color
		diffuse_light += max(0, wNdotL) * vLightDiffuse[i] * fAtten;
	}
	//apply material color
	//	Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = (vMaterialColor * vColor * diffuse_light);
	//shadow mapping variables
	float wNdotSun = max(-0.0001f,dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor * vMaterialColor * vColor;

	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}


VS_OUTPUT_SPECULAR_ALPHA vs_specular_alpha (uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0, uniform const bool swytraffic = false)
{
	VS_OUTPUT_SPECULAR_ALPHA Out = (VS_OUTPUT_SPECULAR_ALPHA)0;

  if(swytraffic){
    //lerping position in local coordinates using a sawtooth wave /|/|/|/
    vPosition.y=lerp(vPosition.y-100,vPosition.y+200,(time_var-floor(time_var))/3)-1;
    /* refs: http://en.wikipedia.org/wiki/Piecewise_linear_function 
             http://en.wikipedia.org/wiki/Sawtooth_wave
             */
  }
  
	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	Out.worldPos = vWorldPos;
	Out.worldNormal = vWorldN;

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0 = tc;

	float4 diffuse_light = vAmbientColor;
	// diffuse_light.rgb *= gradient_factor * (gradient_offset + vWorldN.z);


	//directional lights, compute diffuse color
	float dp = dot(vWorldN, -vSkyLightDir);
	if (dp < 0.0f)
	{
		dp *= -0.2f;
	}
	diffuse_light += dp * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float LD = length(point_to_light);
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float fAtten = 1.0f/(LD*LD);// + 0.9f / (LD * LD);
		//compute diffuse color
		diffuse_light += max(0, wNdotL) * vLightDiffuse[i] * fAtten;
	}
	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = (vMaterialColor * (vColor * diffuse_light));
	//shadow mapping variables
	float wNdotSun = max(-0.0001f,dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor * vMaterialColor * vColor;

	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}



PS_OUTPUT ps_specular_alpha(PS_INPUT_SPECULAR_ALPHA In, uniform const int PcfMode, uniform const bool isGlowEnabled = false, uniform const bool isLightsaber = false)
{
	PS_OUTPUT Output;

	// Compute half vector for specular lighting
	// float3 vHalf = normalize(normalize(-ViewPos) + normalize(g_vLight - ViewPos));

	float4 outColor = tex2D(MeshTextureSampler, In.Tex0);
	outColor.rgb = pow(outColor.rgb, input_gamma);

	float3 vHalf = normalize(normalize(vCameraPos - In.worldPos) - vSunDir);
	// Compute normal dot half for specular light
  float4 fVec = saturate( dot( vHalf, normalize( In.worldNormal) ));
	float4 fSpecular = vSpecularColor * pow( fVec, fMaterialPower) * outColor.a;
	
	if(isGlowEnabled && outColor.a>.01f)
	{
		In.SunLight = In.SunLight = max(outColor.a,In.SunLight)*fVec; /* polarized-like effect at side angles */
	}
	
	if(isLightsaber)
	{
		//we don't want to draw the lightblade in metallic fashion :-)
		if(In.Tex0.x < 0.811f){
			clip(-1);
		}
	}
	
	if ((PcfMode != PCF_NONE))
	{
		float sun_amount = 0.15f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		// sun_amount *= sun_amount;
		Output.RGBColor = (outColor * ((In.Color + (In.SunLight + fSpecular) * sun_amount)));
	}
	else
	{
		Output.RGBColor = (outColor * ((In.Color + (In.SunLight + fSpecular * 0.5f))));
	}
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);

	Output.RGBColor.a = 1.0f;
	return Output;
}

PS_OUTPUT ps_swconquest_planet(PS_INPUT_SPECULAR_ALPHA In)
{
	PS_OUTPUT Output;

	//In.Tex0.x += time_var/1200; <-- rotation isn't working because of time_var only changing in action mode

	float3 normal   = normalize(In.worldNormal);
	float3 lightVec = normalize(In.worldPos);
	
	float  diffuse  = saturate(dot(normal, lightVec-2));

	//@> The final shading is a composition of the diagonal pass and the base texture + rim lighting...
	Output.RGBColor = ( tex2D(MeshTextureSampler, In.Tex0) - (diffuse.x/2.2) );
	
	//@> Rimlight
	float3 vHalf = normalize(vCameraPos - In.worldPos);
	Output.RGBColor.rgb += (1.0f - saturate( dot( vHalf, normal ) *2 ))/2;

	//Output.RGBColor.rgb *= In.Color; --> had to comment it out because of the hardcoded vertex color lightning which makes the planets pitch black at night, sigh :(
	return Output;
}

PS_OUTPUT ps_specular(PS_INPUT_SPECULAR_ALPHA In, uniform const int PcfMode)
{
	PS_OUTPUT Output;

	// Compute half vector for specular lighting
	// float3 vHalf = normalize(normalize(-ViewPos) + normalize(g_vLight - ViewPos));
	float4 outColor = tex2D(MeshTextureSampler, In.Tex0);
	outColor.rgb = pow(outColor.rgb, input_gamma);
	float4 specColor = tex2D(SpecularTextureSampler, In.Tex0);

	float3 vHalf = normalize(normalize(vCameraPos - In.worldPos) - vSunDir);
	// Compute normal dot half for specular light
	float4 fSpecular = specColor * vSpecularColor * pow( saturate( dot( vHalf, normalize( In.worldNormal) ) ), fMaterialPower);
	if ((PcfMode != PCF_NONE))
	{
		float sun_amount = 0.15f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		// sun_amount *= sun_amount;
		Output.RGBColor = (outColor * ((In.Color + (In.SunLight + fSpecular) * sun_amount)));
	}
	else
	{
		Output.RGBColor = (outColor * ((In.Color + (In.SunLight + fSpecular * 0.5f))));
	}
	Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);

	Output.RGBColor.a = 1.0f;
	return Output;
}

VS_OUTPUT_ENVMAP_SPECULAR vs_envmap_specular(uniform const int PcfMode, float4 vPosition : POSITION, float3 vNormal : NORMAL, float2 tc : TEXCOORD0, float4 vColor : COLOR0)
{
	VS_OUTPUT_ENVMAP_SPECULAR Out = (VS_OUTPUT_ENVMAP_SPECULAR)0;

	Out.Pos = mul(matWorldViewProj, vPosition);

	float4 vWorldPos = (float4)mul(matWorld,vPosition);
	float3 vWorldN = normalize(mul((float3x3)matWorld, vNormal)); //normal in world space

	// Out.worldPos = vWorldPos;
	// Out.worldNormal = vWorldN;

	float3 P = mul(matWorldView, vPosition); //position in view space

	Out.Tex0.xy = tc;

	float3 relative_cam_pos = normalize(vCameraPos - vWorldPos);
	float2 envpos;
	float3 tempvec = relative_cam_pos - vWorldN;
	float3 vHalf = normalize(relative_cam_pos - vSunDir);
	float3 fSpecular = 4.0f * vSpecularColor * pow( saturate( dot( vHalf, vWorldN) ), fMaterialPower);

	Out.vSpecular = relative_cam_pos;

	envpos.x = (tempvec.y);// + tempvec.x);
	envpos.y = tempvec.z;
	envpos += 1.0f;
	// envpos *= 0.5f;

	Out.Tex0.zw = envpos;

	float4 diffuse_light = vAmbientColor;
	// diffuse_light.rgb *= gradient_factor * (gradient_offset + vWorldN.z);


	//directional lights, compute diffuse color
	diffuse_light += max(0, dot(vWorldN, -vSkyLightDir)) * vSkyLightColor;

	//point lights
	for(int j = 0; j < iLightPointCount; j++)
	{
		int i = iLightIndices[j];
		float3 point_to_light = vLightPosDir[i]-vWorldPos;
		float LD = length(point_to_light);
		float3 L = normalize(point_to_light);
		float wNdotL = dot(vWorldN, L);

		float fAtten = 1.0f/(LD*LD);// + 0.9f / (LD * LD);
		//compute diffuse color
		diffuse_light += max(0, wNdotL) * vLightDiffuse[i] * fAtten;
	}

	//apply material color
	// Out.Color = min(1, vMaterialColor * vColor * diffuse_light);
	Out.Color = (vMaterialColor * vColor * diffuse_light);
	//shadow mapping variables
	float wNdotSun = max(-0.0001f,dot(vWorldN, -vSunDir));
	Out.SunLight = (wNdotSun) * vSunColor * vMaterialColor * vColor;

	if (PcfMode != PCF_NONE)
	{
		float4 ShadowPos = mul(matSunViewProj, vWorldPos);
		Out.ShadowTexCoord = ShadowPos;
		Out.ShadowTexCoord.z /= ShadowPos.w;
		Out.ShadowTexCoord.w = 1.0f;
		Out.TexelPos = Out.ShadowTexCoord * fShadowMapSize;
		//shadow mapping variables end
	}

	//apply fog
	float d = length(P);

	float3 U = mul(matWorld, vPosition);
	float  u = length(U.z); //Exponential HeightFog! :)
	
	Out.Fog = get_fog_amount(d,u);

	return Out;
}

PS_OUTPUT ps_envmap_specular(PS_INPUT_ENVMAP_SPECULAR In, uniform const int PcfMode)
{
	PS_OUTPUT Output;

	// Compute half vector for specular lighting
	//  float3 vHalf = normalize(normalize(-ViewPos) + normalize(g_vLight - ViewPos));
	float4 texColor = tex2D(MeshTextureSampler, In.Tex0.xy);
	texColor.rgb = pow(texColor.rgb, input_gamma);

	float3 specTexture = tex2D(SpecularTextureSampler, In.Tex0.xy).rgb;
	float3 fSpecular = specTexture * In.vSpecular.rgb;

	//  float3 relative_cam_pos = normalize(vCameraPos - In.worldPos);
	//  float3 vHalf = normalize(relative_cam_pos - vSunDir);
	/*
	float2 envpos;
	float3 tempvec =relative_cam_pos -  In.worldNormal ;
  //envpos.x = tempvec.x;
  //envpos.y = tempvec.z;
	envpos.xy = tempvec.xz;
	envpos += 1.0f;
	envpos *= 0.5f;
	*/
	float4 envColor = tex2D(EnvTextureSampler, In.Tex0.zw/2);
	//float3 envColor = texCUBE(EnvTextureSampler, In.vSpecular).rgb; //float3(In.Tex0.zw,1)).rgb;

	// Compute normal dot half for specular light
	// float4 fSpecular = 4.0f * specColor * vSpecularColor * pow( saturate( dot( vHalf, normalize( In.worldNormal) ) ), fMaterialPower);


//	if ((PcfMode != PCF_NONE))
//	{
//
//		float sun_amount = 0.1f + GetSunAmount(PcfMode, In.ShadowTexCoord, In.TexelPos);
		// sun_amount *= sun_amount;
//		float4 vcol = In.Color;
//		vcol.rgb += (In.SunLight.rgb + fSpecular) * sun_amount;
//		Output.RGBColor = (texColor * vcol);
//		Output.RGBColor.rgba = envColor.a;
//	}
//	else
//	{
//		float4 vcol = In.Color;
//		vcol.rgb += (In.SunLight.rgb + fSpecular);
//		Output.RGBColor = (texColor * vcol);
//		Output.RGBColor.rgba = envColor.a;

	Output.RGBColor.rgb = texColor.rgb;
    Output.RGBColor.a   = 0.4f;
	Output.RGBColor.a  *= envColor.a/9;
	Output.RGBColor.rgb  *= envColor.a/5;
//	}

	//Output.RGBColor.rgb = pow(Output.RGBColor.rgb, output_gamma_inv);
  Output.RGBColor.ra*=1.4f;
  Output.RGBColor.a*=3.0f;

 // In.vSpecular=normalize(In.vSpecular);
	Output.RGBColor.a *= ((0.4f-envColor.y)-envColor.x);
	Output.RGBColor+=texColor.rgba/2;
	
	
	Output.RGBColor.a *=1.4f;
	float2 thingie = normalize(In.Tex0.zw);
	//Output.RGBColor.a = (thingie.x+thingie.y);
	
	
	In.vSpecular=normalize(In.vSpecular);
	Output.RGBColor.a *= max(0.3f,saturate((0.4f-In.vSpecular.y)+(0.4f+In.vSpecular.x)));
	Output.RGBColor.a  = max(0.1f,Output.RGBColor.a);
	
	return Output;
}


 /* * * * * * * * * * * * * * * * * * * * *
  * swconquest based shaders -- by swyter
  */
  
technique swconquest_planet
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_NONE);
		PixelShader  = compile ps_2_0 ps_swconquest_planet();
	}
}

technique swconquest_galaxy
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_swconquest_galaxy();
		PixelShader  = compile ps_2_0 ps_main_no_shadow(true);
	}
}

technique swconquest_hologram
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_swconquest_hologram(true);
		PixelShader  = compile ps_2_0 ps_swconquest_hologram();
	}
}

technique swconquest_hologram_static
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_swconquest_hologram(false);
		PixelShader  = compile ps_2_0 ps_swconquest_hologram();
	}
}

technique swconquest_lightsaber
{

	pass Lightblade
	{
		VertexShader = compile vs_2_0 vs_swconquest_lightsaber();
		PixelShader  = compile ps_2_0 ps_swconquest_lightsaber();
	}
	
	pass Hilt
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_NONE);
		PixelShader  = compile ps_2_0 ps_specular_alpha(PCF_NONE,false, true); //special parameter for clipping out the lightblade parts
	}
	

}

technique swconquest_glow
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_NONE, true);
		PixelShader  = compile ps_2_0 ps_main(PCF_NONE, true); //glow_enabled
	}
}

technique swconquest_sarlacc
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_no_shadow(true);
		PixelShader  = compile ps_2_0 ps_main_no_shadow();
	}
}

technique swconquest_glow_iron
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_NONE);
		PixelShader  = compile ps_2_0 ps_specular_alpha(PCF_NONE, true, false); //glow_enabled
	}
}

technique swconquest_lava
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_NONE, false);
		PixelShader  = compile ps_2_0 ps_main(PCF_NONE, false, true);
	}
}

technique swconquest_swytraffic_iron
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_NONE, true);
		PixelShader  = compile ps_2_0 ps_specular_alpha(PCF_NONE, true, false); //glow_enabled
	}
}

//the technique for the programmable shader (simply sets the vertex shader)
technique font_uniform_color
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_font_uniform_color();
	}
}

technique font_background
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_font_background();
	}
}

technique font_outline
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_font_outline();
	}
}

technique no_shading
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_no_shading();
	}
}

technique no_shading_no_alpha
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_no_shading_no_alpha();
	}
}

technique simple_shading //Uses gamma
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_main_no_shadow();
	}
}

technique simple_shading_no_filter //Uses gamma
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_font();
		PixelShader = compile ps_2_0 ps_simple_no_filtering();
	}
}

technique skybox
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_skybox();
		PixelShader = compile ps_2_0 ps_skybox_shading();
	}
}

technique diffuse
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_NONE, true);
		PixelShader = compile ps_2_0 ps_main(PCF_NONE, false);
	}
}

technique diffuse_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_DEFAULT, true);
		PixelShader = compile ps_2_0 ps_main(PCF_DEFAULT, false);
	}
}

technique diffuse_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main(PCF_NVIDIA, true);
		PixelShader = compile ps_2_a ps_main(PCF_NVIDIA, false);
	}
}

technique diffuse_dynamic
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_NONE, false);
		PixelShader = compile ps_2_0 ps_main(PCF_NONE, false);
	}
}

technique diffuse_dynamic_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_DEFAULT, false);
		PixelShader = compile ps_2_0 ps_main(PCF_DEFAULT, false);
	}
}

technique diffuse_dynamic_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main(PCF_NVIDIA, false);
		PixelShader = compile ps_2_a ps_main(PCF_NVIDIA, false);
	}
}

technique skin_diffuse
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_skin(PCF_NONE);
		PixelShader = compile ps_2_0 ps_main(PCF_NONE, false);
	}
}

technique skin_diffuse_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_skin(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_main(PCF_DEFAULT, false);
	}
}

technique skin_diffuse_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main_skin(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_main(PCF_NVIDIA, false);
	}
}

technique face_shader
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_face(PCF_NONE);
		PixelShader = compile ps_2_0 ps_face(PCF_NONE);
	}
}
technique face_shader_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_face(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_face(PCF_DEFAULT);
	}
}
technique face_shader_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_face(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_face(PCF_NVIDIA);
	}
}

technique hair_shader
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_hair(PCF_NONE);
		PixelShader = compile ps_2_0 ps_hair(PCF_NONE);
	}
}
technique hair_shader_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_hair(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_hair(PCF_DEFAULT);
	}
}
technique hair_shader_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_hair(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_hair(PCF_NVIDIA);
	}
}

technique map_water
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_map_water();
		PixelShader = compile ps_2_0 ps_map_water();
	}
}



technique map_mountain
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_map_mountain(PCF_NONE, true);
		PixelShader = compile ps_2_0 ps_map_mountain(PCF_NONE);
	}
}
technique map_mountain_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_map_mountain(PCF_DEFAULT, true);
		PixelShader = compile ps_2_0 ps_map_mountain(PCF_DEFAULT);
	}
}
technique map_mountain_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_map_mountain(PCF_NVIDIA, true);
		PixelShader = compile ps_2_0 ps_map_mountain(PCF_NVIDIA);
	}
}




technique envmap_metal
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_NONE, true);
		PixelShader = compile ps_2_0 ps_main(PCF_NONE, false);
	}
}

technique envmap_metal_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main(PCF_DEFAULT, true);
		PixelShader = compile ps_2_0 ps_main(PCF_DEFAULT, false);
	}
}

technique envmap_metal_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main(PCF_NVIDIA, true);
		PixelShader = compile ps_2_a ps_main(PCF_NVIDIA, false);
	}
}

technique bumpmap
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump(PCF_NONE);
		PixelShader = compile ps_2_0 ps_main_bump(PCF_NONE);
	}
}

technique bumpmap_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_main_bump(PCF_DEFAULT);
	}
}

technique bumpmap_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main_bump(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_main_bump(PCF_NVIDIA);
	}
}

technique bumpmap_interior
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump_interior();
		PixelShader = compile ps_2_0 ps_main_bump_interior();
	}
}

technique watermap
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_water();
		PixelShader = compile ps_2_0 ps_main_water();
	}
}

technique fakewatermap
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_water();
		PixelShader = compile ps_2_0 ps_fake_water();
	}
}

technique dot3
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump(PCF_NONE);
		PixelShader = compile ps_2_0 ps_main_bump_simple(PCF_NONE);
	}
}

technique dot3_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_main_bump_simple(PCF_DEFAULT);
	}
}

technique dot3_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main_bump(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_main_bump_simple(PCF_NVIDIA);
	}
}

technique dot3_multitex
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump(PCF_NONE);
		PixelShader = compile ps_2_0 ps_main_bump_simple_multitex(PCF_NONE);
	}
}

technique dot3_multitex_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_bump(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_main_bump_simple_multitex(PCF_DEFAULT);
	}
}

technique dot3_multitex_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_main_bump(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_main_bump_simple_multitex(PCF_NVIDIA);
	}
}

technique diffuse_no_shadow
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_no_shadow(false);
		PixelShader = compile ps_2_0 ps_main_no_shadow();
	}
}

technique notexture
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_notexture();
		PixelShader = compile ps_2_0 ps_main_notexture();
	}
}

technique renderdepth
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_shadowmap();
		PixelShader = compile ps_2_0 ps_main_shadowmap();
	}
}

technique renderdepthwithskin
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_shadowmap_skin();
		PixelShader = compile ps_2_0 ps_main_shadowmap();
	}
}

technique clear_floating_point_buffer
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_clear_floating_point_buffer();
		PixelShader = compile ps_2_0 ps_clear_floating_point_buffer();
	}
}

technique character_shadow
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_character_shadow(PCF_NONE);
		PixelShader = compile ps_2_0 ps_character_shadow(PCF_NONE);
	}
}

technique character_shadow_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_character_shadow(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_character_shadow(PCF_DEFAULT);
	}
}

technique character_shadow_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_character_shadow(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_character_shadow(PCF_NVIDIA);
	}
}

technique render_character_shadow
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_shadowmap();
		PixelShader = compile ps_2_0 ps_render_character_shadow();
	}
}

technique render_character_shadow_with_skin
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_main_shadowmap_skin();
		PixelShader = compile ps_2_0 ps_render_character_shadow();
	}
}

technique flora
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_flora(PCF_NONE);
		PixelShader = compile ps_2_0 ps_flora(PCF_NONE);
	}
}

technique flora_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_flora(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_flora(PCF_DEFAULT);
	}
}

technique flora_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_flora(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_flora(PCF_NVIDIA);
	}
}

technique flora_PRESHADED
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_flora_no_shadow();
		PixelShader = compile ps_2_0 ps_flora_no_shadow();
	}
}

technique grass_no_shadow
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_grass_no_shadow();
		PixelShader = compile ps_2_0 ps_grass_no_shadow();
	}
}

technique grass
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_grass(PCF_NONE);
		PixelShader = compile ps_2_0 ps_grass(PCF_NONE);
	}
}

technique grass_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_grass(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_grass(PCF_DEFAULT);
	}
}

technique grass_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_grass(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_grass(PCF_NVIDIA);
	}
}

technique grass_PRESHADED
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_grass_no_shadow();
		PixelShader = compile ps_2_0 ps_grass_no_shadow();
	}
}

technique specular_diffuse
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_NONE);
		PixelShader = compile ps_2_0 ps_specular(PCF_NONE);
	}
}

technique specular_diffuse_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_specular(PCF_DEFAULT);
	}
}

technique specular_diffuse_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_specular_alpha(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_specular(PCF_NVIDIA);
	}
}

technique specular_diffuse_skin
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha_skin(PCF_NONE);
		PixelShader = compile ps_2_0 ps_specular(PCF_NONE);
	}
}

technique specular_diffuse_skin_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha_skin(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_specular(PCF_DEFAULT);
	}
}

technique specular_diffuse_skin_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_specular_alpha_skin(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_specular(PCF_NVIDIA);
	}
}

technique envmap_specular_diffuse
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_envmap_specular(PCF_NONE);
		PixelShader = compile ps_2_0 ps_envmap_specular(PCF_NONE);
	}
}

technique swconquest_glass
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_envmap_specular(PCF_NONE);
		PixelShader = compile ps_2_0 ps_envmap_specular(PCF_NONE);
	}
}


technique envmap_specular_diffuse_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_envmap_specular(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_envmap_specular(PCF_DEFAULT);
	}
}

technique envmap_specular_diffuse_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_envmap_specular(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_envmap_specular(PCF_NVIDIA);
	}
}

technique specular_alpha
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_NONE);
		PixelShader = compile ps_2_0 ps_specular_alpha(PCF_NONE);
	}
}
technique specular_alpha_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_specular_alpha(PCF_DEFAULT);
	}
}
technique specular_alpha_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_specular_alpha(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_specular_alpha(PCF_NVIDIA);
	}
}

technique specular_alpha_skin
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha_skin(PCF_NONE);
		PixelShader = compile ps_2_0 ps_specular_alpha(PCF_NONE);
	}
}
technique specular_alpha_skin_SHDW
{
	pass P0
	{
		VertexShader = compile vs_2_0 vs_specular_alpha_skin(PCF_DEFAULT);
		PixelShader = compile ps_2_0 ps_specular_alpha(PCF_DEFAULT);
	}
}
technique specular_alpha_skin_SHDWNVIDIA
{
	pass P0
	{
		VertexShader = compile vs_2_a vs_specular_alpha_skin(PCF_NVIDIA);
		PixelShader = compile ps_2_a ps_specular_alpha(PCF_NVIDIA);
	}
}