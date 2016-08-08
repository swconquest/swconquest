/* swyter -- custom swc glsl shaders for warband, ported from hlsl by hand */

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

float get_fog_amount(float distance_to_view, float ground_height)
{
	// return saturate((fFogEnd - d) / (fFogEnd - fFogStart));
	return 1.0 / exp2(( length(distance_to_view) - (ground_height * 2.0) ) * fFogDensity);
}

void main ()
{
    vec4 vertPos = vec4(inPosition.xyz, 1.0);

	gl_Position = matWorldViewProj * vertPos;

	vec3 P = (matWorldView * vertPos).xyz; //position in view space

	//apply fog
	float d = length(P);

	vec3  U = (matWorld * vertPos).xyz;
	float u = length(U.z); //Exponential HeightFog! :)
	Fog = get_fog_amount(d, u);

	Tex0 = inTexCoord;
	Color = inColor0 * vMaterialColor;
	Color.b += (d + 0.2);
	Color.a  = 0.8;
}

