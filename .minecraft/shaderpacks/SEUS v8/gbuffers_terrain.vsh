#version 120

#define WAVING_LEAVES
#define WAVING_GRASS
#define WAVING_WHEAT
#define WAVING_FLOWERS

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

attribute float id;
attribute float isTopVertex;

varying float mat;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

float worldTime = frameTimeCounter * 20;

void addWave(inout vec3 pos) {
	{
		float speed = 3.0;
		float magnitude = (sin(((pos.y + pos.x)/2.0 + worldTime * 3.14159265358979323846264 / ((88.0)))) * 0.05 + 0.15) * 0.35;
		float d0 = sin(worldTime * 3.14159265358979323846264 / (122.0 * speed)) * 3.0 - 1.5;
		float d1 = sin(worldTime * 3.14159265358979323846264 / (152.0 * speed)) * 3.0 - 1.5;
		float d2 = sin(worldTime * 3.14159265358979323846264 / (192.0 * speed)) * 3.0 - 1.5;
		float d3 = sin(worldTime * 3.14159265358979323846264 / (142.0 * speed)) * 3.0 - 1.5;
		pos.x += sin((worldTime * 3.14159265358979323846264 / (16.0 * speed)) + (pos.x + d0)*0.5 + (pos.z + d1)*0.5 + (pos.y)) * magnitude;
		pos.z += sin((worldTime * 3.14159265358979323846264 / (18.0 * speed)) + (pos.z + d2)*0.5 + (pos.x + d3)*0.5 + (pos.y)) * magnitude;
	}
	{
		float speed = 1.1;
		float magnitude = (sin(((pos.y + pos.x)/8.0 + worldTime * 3.14159265358979323846264 / ((88.0)))) * 0.15 + 0.05) * 0.22;
		float d0 = sin(worldTime * 3.14159265358979323846264 / (112.0 * speed)) * 3.0 + 0.5;
		float d1 = sin(worldTime * 3.14159265358979323846264 / (142.0 * speed)) * 3.0 + 0.5;
		float d2 = sin(worldTime * 3.14159265358979323846264 / (112.0 * speed)) * 3.0 + 0.5;
		float d3 = sin(worldTime * 3.14159265358979323846264 / (142.0 * speed)) * 3.0 + 0.5;
		pos.x += sin((worldTime * 3.14159265358979323846264 / (18.0 * speed)) + (-pos.x + d0)*1.6 + (pos.z + d1)*1.6) * magnitude;
		pos.z += sin((worldTime * 3.14159265358979323846264 / (18.0 * speed)) + (pos.z + d2)*1.6 + (-pos.x + d3)*1.6) * magnitude;
		pos.y += sin((worldTime * 3.14159265358979323846264 / (11.0 * speed)) + (pos.z + d2) + (pos.x + d3)) * (magnitude/4.0);
	}
}

void main() {
	texcoord = gl_MultiTexCoord0.xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	mat = 0.5f;
	
	vec4 pos = ftransform();
	
	pos = gbufferProjectionInverse * pos;
	pos = gbufferModelViewInverse * pos;
	pos.xyz += cameraPosition;
	
	int blockID = int(id);
	
	#ifdef WAVING_LEAVES
	if(blockID >= 290 && blockID <= 298) {
		addWave(pos.xyz);
	}
	#endif
	#ifdef WAVING_GRASS
	if(isTopVertex > 0.5f) {
		if(blockID == 320 || blockID == 321) {
			addWave(pos.xyz);
		}
	}
	#endif
	#ifdef WAVING_WHEAT
	if(isTopVertex > 0.5f) {
		if(blockID == 690) {
			addWave(pos.xyz);
		}
	}
	#endif
	#ifdef WAVING_FLOWERS
	if(isTopVertex > 0.5f) {
		if(blockID == 330 || blockID == 331) {
			addWave(pos.xyz);
		}
	}
	#endif
	
	pos.xyz -= cameraPosition;
	pos = gbufferModelView * pos;
	pos = gbufferProjection * pos;
	
	gl_Position = pos;
	gl_FogFragCoord = gl_Position.z;
}