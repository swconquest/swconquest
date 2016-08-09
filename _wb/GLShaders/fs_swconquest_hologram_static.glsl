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
  gl_FragColor = texture2D(diffuse_texture, Tex0) * Color;
}

