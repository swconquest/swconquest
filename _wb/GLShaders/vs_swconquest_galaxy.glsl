uniform vec4 vLightDiffuse[4];
uniform vec4 vMaterialColor;
uniform vec4 vSunDir;
uniform vec4 vSunColor;
uniform vec4 vAmbientColor;
uniform vec4 vSkyLightDir;
uniform vec4 vSkyLightColor;
uniform float fFogDensity;
uniform int iLightPointCount;
uniform int iLightIndices[4];
uniform mat4 matWorldViewProj;
uniform mat4 matWorldView;
uniform mat4 matWorld;
uniform vec4 vLightPosDir[4];
attribute vec3 inPosition;
attribute vec3 inNormal;
attribute vec4 inColor0;
attribute vec4 inColor1;
attribute vec2 inTexCoord;
varying float Fog;
varying vec4 Color;
varying vec2 Tex0;
void main ()
{ 
	gl_Position = matWorldViewProj * vec4(inPosition.xyz, 1.0);

	vec3 P = (matWorldView * vec4(inPosition, 1.0)).xyz; //position in view space

	//apply fog
	float d = length(P);

	//float3 U = mul(matWorld, inPosition).xyz;
	//float  u = length(U.z); //Exponential HeightFog! :)
	Fog = 1.0; //get_fog_amount(d,u);

	
	Tex0 = inTexCoord;
	Color = inColor0 * vMaterialColor;
	Color.b += (d + 0.2);
	Color.a  = 0.8;
  
}

