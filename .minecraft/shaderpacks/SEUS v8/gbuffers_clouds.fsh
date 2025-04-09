#version 120

#define FOG
#define RADIAL_FOG

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 color;

#ifdef FOG
uniform int fogMode;
uniform float sunAngle;

const int GL_EXP = 2048;
const int GL_LINEAR = 9729;

#ifdef RADIAL_FOG
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
#endif
#endif

void main() {
	float mat = 0.0f;
	vec4 col = vec4(color.rgb, 1.0f);
	
	#ifdef FOG
	float fogStrength = 0.0f;
	
	if(fogMode == GL_EXP) {
		fogStrength = 1.0f - exp(-gl_Fog.density * gl_FogFragCoord);
	}else if(fogMode == GL_LINEAR) {
		#ifndef RADIAL_FOG
		fogStrength = (gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale;
		#endif
		
		#ifdef RADIAL_FOG
		vec4 fragPos = gbufferProjectionInverse * vec4((gl_FragCoord.xy / vec2(viewWidth, viewHeight)) * 2.0f - 1.0f, gl_FragCoord.z * 2.0f - 1.0f, 1.0f);
		fragPos /= fragPos.w;
		
		float dist = length(fragPos.xyz);
		float end = gl_Fog.end;
		float start = gl_Fog.start / gl_Fog.end;
		
		fogStrength = dist / end;
		fogStrength -= (start);
		fogStrength /= (1.0f - start);
		#endif
	}
	
	col.a *= clamp(1.0f - fogStrength, 0.0f, 1.0f);
	#endif
	
	gl_FragData[0] = texture2D(texture, texcoord) * col;
	gl_FragData[1] = vec4(0.0f, mat, 0.0f, 1.0f);
}