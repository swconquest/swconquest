uniform sampler2D diffuse_texture;
uniform sampler2D diffuse_texture_2;
uniform vec4 vFogColor;
uniform vec4 output_gamma_inv;
varying float Fog;
varying vec4 Color;
varying vec2 Tex0;
varying vec4 SunLight;
void main ()
{
  vec4 Output_RGBColor;
  vec4 tex_col = texture2D(diffuse_texture, Tex0);

  tex_col.xyz = pow(tex_col.xyz, vec3(2.2, 2.2, 2.2));

  if(tex_col.a < 0.11)
    discard;

  Output_RGBColor = Color * tex_col;

  vec4 tex_colb = texture2D(diffuse_texture_2, Tex0 * 30.0);
  vec4 tex_colc = texture2D(diffuse_texture_2, Tex0 * 20.0);

  Output_RGBColor.rg  += tex_colc.rg * 4.0;
  Output_RGBColor.rgb *= tex_colb.rgb * 1.5 + (tex_col.rgb / 14.0);
  Output_RGBColor.rgb *= clamp((Tex0.x + 0.5) / (Tex0.y + 0.5), 0.0, 1.0);

  Output_RGBColor.rgb *= tex_col.r + tex_col.g;

  Output_RGBColor.a    = max(tex_colb.a, Output_RGBColor.a / 2.0);
  Output_RGBColor.a   /= length(tex_colb.rgb);

  Output_RGBColor.rgb = pow(Output_RGBColor.rgb, vec3(output_gamma_inv));

  gl_FragColor = Output_RGBColor;
}

