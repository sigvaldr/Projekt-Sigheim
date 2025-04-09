#version 120

#define FOG
#define RADIAL_FOG

varying vec4 color;

uniform int fogMode;
uniform float sunAngle;

#ifdef RADIAL_FOG
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
#endif

const int GL_EXP = 2048;
const int GL_LINEAR = 9729;

void main() {
	vec4 albedo = color;
	float mat = 0.2f;
	
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
		fogStrength = clamp(fogStrength, 0.0f, 1.0f);
		#endif
	}
	
	albedo.rgb = mix(albedo.rgb, gl_Fog.color.rgb, clamp(fogStrength, 0.0f, 1.0f));
	#endif
	
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(0.0f, mat, 0.0f, 1.0f);
}