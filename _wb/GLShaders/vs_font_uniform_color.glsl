uniform vec4 vMaterialColor;
uniform float fFogDensity;
uniform mat4 matWorldViewProj;
uniform mat4 matWorldView;
attribute vec3 inPosition;
attribute vec4 inColor0;
attribute vec2 inTexCoord;
varying vec4 outColor0;
varying vec2 outTexCoord;
varying float outFog;
void main ()
{
  vec4 tmpvar_1;
  tmpvar_1.w = 1.0;
  tmpvar_1.xyz = inPosition;
  gl_Position = (matWorldViewProj * tmpvar_1);
  vec4 tmpvar_2;
  tmpvar_2.w = 1.0;
  tmpvar_2.xyz = inPosition;
  vec3 tmpvar_3;
  tmpvar_3 = (matWorldView * tmpvar_2).xyz;

  vec4 Out_Color = (inColor0.zyxw * vMaterialColor);
	
	/*
	  Replace hardcoded menu colors--
	  Yellow: #fddd0b
	  DGreen: #218221
	  BBrown: #d4c5b5
	  BGreen: #7cfd78   /255.f
	 */

  /* yellow */
  if( Out_Color.r == 1.0
  
   && Out_Color.g >= 0.86
   && Out_Color.g <= 0.87
   
   && Out_Color.b == 0.0){
    Out_Color.rgb = vec3(0.3,0.4,1.0);  //--> soft blue
  }
  
  /* pure blue (#0000ff) */
  if( Out_Color.r == 0.0
   && Out_Color.g == 0.0 //-->pure blue used all over the quests menu
   && Out_Color.b == 1.0){
    Out_Color.rgb = vec3(0.25,0.35,0.55);  //--> darker soft blue
  }
  
  /* pure black (#000000) */
  if( Out_Color.r == 0.0
   && Out_Color.g == 0.0
   && Out_Color.b == 0.0){
      Out_Color.rgb = vec3(0.2,0.2,0.3);  //--> bluish dark gray
  }
  
  /* dark green (#007700) */
  if((Out_Color.r == 0.0
   
   && Out_Color.g >= 0.46
   && Out_Color.g <= 0.47
   
   && Out_Color.b == 0.0)
 || ( Out_Color.r == 1.0
   && Out_Color.g == 0.0  //--> pure red used in the quests menu (#ff0000)
   && Out_Color.b == 0.0)){
      Out_Color.rgb = vec3(0.6,0.2,0.0);  //-->  maroon
  }
  
  /* light green */
  if( Out_Color.r >= 0.333
   && Out_Color.r <= 0.334
   
   && Out_Color.g == 1.0
   
   && Out_Color.b >= 0.313
   && Out_Color.b <= 0.314){
      Out_Color.rgb = vec3(0.7,0.4,0.0);  //--> dark redish
  }
  
  
  outColor0 = Out_Color;
  outTexCoord = inTexCoord;
  outFog = (1.0/(exp2((
    sqrt(dot (tmpvar_3, tmpvar_3))
   * fFogDensity))));
}

