uniform sampler2D diffuse_texture;
uniform vec4 vFogColor;
uniform vec4 output_gamma_inv;
uniform float time_var;
uniform vec4 vCameraPos;
varying float Fog;
varying vec4 Color;
varying vec2 Tex0;
varying vec4 SunLight;

varying vec3 worldPos;
varying vec3 worldNormal;

float saturate(float arg)
{
  return clamp(arg, 0.0, 1.0);
}

void main ()
{
  vec2 Tex    = Tex0;
       Tex.x += time_var / 1200.0; // <-- rotation wasn't working because of time_var only changing in action mode

  vec3 normal   = normalize(worldNormal);
  vec3 lightVec = normalize(worldPos);

  float diffuse  = saturate(dot(normal, lightVec - 2.0));

  //@> The final shading is a composition of the diagonal pass and the base texture + rim lighting...
  vec4 RGBColor = texture2D(diffuse_texture, Tex) - (diffuse / 2.2);

  //@> Rimlight
  vec3 vHalf = normalize(vCameraPos.xyz - worldPos);
  RGBColor.rgb += (1.0 - saturate( dot( vHalf, normal ) * 2.0 )) / 2.0;

  //Output.RGBColor.rgb *= In.Color; --> had to comment it out because of the hardcoded vertex color lightning which makes the planets pitch black at night, sigh :(
  gl_FragColor = RGBColor;
}

