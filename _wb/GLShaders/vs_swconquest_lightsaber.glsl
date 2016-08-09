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
varying vec4 SunLight;
varying vec4 ShadowTexCoord;

uniform float time_var;

float saturate(float arg)
{
  return clamp(arg, 0.0, 1.0);
}

void main()
{
  Fog = 1.0;
  SunLight = vec4(1.0);
  ShadowTexCoord = vec4(0.0);

  gl_Position = matWorldViewProj * vec4(inPosition.xyz, 1.0);
  Tex0 = inTexCoord;

  //apply material color
  Color = inColor0;
  //Out.Color.rg = saturate(sin(time_var))  + 0.5;
  Color.a = saturate(sin(time_var * 200.0)) + 0.6;  //max(0.6f,saturate(sin(time_var*15)*20));
}

