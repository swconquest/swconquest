uniform sampler2D diffuse_texture;
uniform sampler2D diffuse_texture_2;
uniform vec4 vFogColor;
uniform vec4 output_gamma_inv;
uniform float time_var;
varying float Fog;
varying vec4 Color;
varying vec2 Tex0;
varying vec4 SunLight;
void main ()
{


  vec4 tex_col = vec4(0,0,0,0); //makes happy the dumb fx compiler :(

  float time = sin(cos(time_var/32.0));

  vec4 tex_cola = texture2D(diffuse_texture,          Tex0     +time      );
  vec4 tex_colb = texture2D(diffuse_texture_2,   (sin(Tex0)*cos(time))*2.0);
  vec4 tex_colc = texture2D(diffuse_texture_2,    cos(Tex0)*sin(time)     );

  tex_col = tex_cola;


  tex_col.rgb *= tex_colb.rgb;
  tex_col.rgb *= tex_colc.rgb;

  tex_col.rgb *= (tex_colc.rgb+tex_colc.rgb+tex_cola.rgb);//*tex_cola.rgb;

  // --

  vec4 tex_col_1;
  vec4 tmpvar_2;

  tex_col_1.xyz = pow (tex_col.xyz, vec3(2.2, 2.2, 2.2));
  tmpvar_2 = (tex_col_1 * (Color + SunLight));
  tmpvar_2.xyz = pow (tmpvar_2.xyz, output_gamma_inv.xyz);
  tmpvar_2.xyz = mix (vFogColor.xyz, tmpvar_2.xyz, Fog);
  gl_FragColor = tmpvar_2;
}

