uniform sampler2D diffuse_texture;
uniform vec4 vFogColor;
uniform vec4 output_gamma_inv;
varying float Fog;
varying vec4 Color;
varying vec2 Tex0;
varying vec4 SunLight;
void main ()
{
  vec4 tex_col_1;
  vec4 tmpvar_2;
  vec4 tex_col;
  tex_col = texture2D (diffuse_texture, Tex0);
  tex_col_1.w = tex_col.w;
  tex_col_1.xyz = pow (tex_col.xyz, vec3(2.2, 2.2, 2.2));

  // --

  vec4 In_SunLight = max(tex_col.aaaa, SunLight);
  tmpvar_2 = tex_col *   Color   * (In_SunLight);

  //tmpvar_2 = (tex_col_1 * (Color + SunLight));

  // --

  tmpvar_2.xyz = pow (tmpvar_2.xyz, output_gamma_inv.xyz);
  tmpvar_2.xyz = mix (vFogColor.xyz, tmpvar_2.xyz, Fog);
  gl_FragColor = tmpvar_2;
}

