#version 120

#define FOG
#define RADIAL_FOG

uniform sampler2D texture;
uniform sampler2D lightmap;

varying float mat;
varying vec2 texcoord;
varying vec2 lmcoord;
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
	vec4 albedo = texture2D(texture, texcoord) * color * texture2D(lightmap, lmcoord);
	
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
	
	const float noon = 0.00f;
	const float sunset = 0.25f;
	const float midnight = 0.50f;
	const float sunrise = 0.75f;
	
	const float sunsetStart = 0.1f;
	const float sunsetEnd = 0.3f;
	const float sunriseStart = 0.7f;
	const float sunriseEnd = 0.9f;
	
	float time = sunAngle;
	
	float TimeSunrise = time < sunrise ? 
		clamp((time - sunriseStart) / (sunrise - sunriseStart), 0.0f, 1.0f):
		1.0f - clamp((time - sunrise) / (sunriseEnd - sunrise), 0.0f, 1.0f);
		
	float TimeNoon = 
		1.0f - clamp((time - sunsetStart) / (sunset - sunsetStart), 0.0f, 1.0f) +
		clamp((time - sunrise) / (sunriseEnd - sunrise), 0.0f, 1.0f);
		
	float TimeSunset = time < sunset ? 
		clamp((time - sunsetStart) / (sunset - sunsetStart), 0.0f, 1.0f):
		1.0f - clamp((time - sunset) / (sunsetEnd - sunset), 0.0f, 1.0f);
	
	float TimeMidnight = time < 0.5f ?
		clamp((time - sunset) / (sunsetEnd - sunset), 0.0f, 1.0f):
		1.0f - clamp((time - sunriseStart) / (sunrise - sunriseStart), 0.0f, 1.0f);
	
	vec3 fogColor = gl_Fog.color.rgb;
	fogColor = (fogColor * 1.4 - 0.2) * (TimeSunrise + TimeSunset) + (fogColor * 1.4 - 0.4) * TimeNoon + fogColor * TimeMidnight;
	
	albedo.rgb = mix(albedo.rgb, fogColor, clamp(fogStrength, 0.0f, 1.0f));
	#endif
	
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(0.0f, mat, 0.0, 1.0);
}