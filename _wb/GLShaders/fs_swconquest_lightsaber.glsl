/* swyter -- custom swc glsl shaders for warband, ported from hlsl by hand */

uniform sampler2D diffuse_texture;
uniform vec4 vFogColor;
uniform vec4 output_gamma_inv;
varying float Fog;
varying vec4 Color;
varying vec2 Tex0;
varying vec4 SunLight;
void main ()
{
  vec4 Output_RGBColor = texture2D(diffuse_texture, Tex0);

  //we don't want have a blinking hilt :-)
  if(Tex0.x <= 0.8)
  {
      Output_RGBColor.a *= Color.a;
  }

  gl_FragColor = Output_RGBColor;
}

