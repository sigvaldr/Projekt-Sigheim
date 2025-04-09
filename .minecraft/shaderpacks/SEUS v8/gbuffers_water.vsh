#version 120

//#define WAVING_WATER

#ifdef WAVING_WATER

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

#endif

attribute float id;

varying float mat;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

void main() {
	texcoord = gl_MultiTexCoord0.xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	
	mat = 0.5f;
	
	int blockID = int(id);
	
	if(blockID == 270 || blockID == 271) {
		mat = 0.7f;
	}
	
	vec4 pos = ftransform();
	
	#ifdef WAVING_WATER
	
	if(mat > 0.65f && mat < 0.75f){
		pos = gbufferProjectionInverse * pos;
		pos = gbufferModelViewInverse * pos;
		pos.xyz += cameraPosition;
		
		float wave = 0.0f;
		wave += sin(pos.x + pos.z + frameTimeCounter * 4.0f) * 0.015f;
		wave += sin(pos.x * 0.3f - pos.z * 0.5f + frameTimeCounter * 4.0f) * 0.007f;
		
		pos.y += wave;
		
		pos.xyz -= cameraPosition;
		pos = gbufferModelView * pos;
		pos = gbufferProjection * pos;
	}
	
	#endif
	
	gl_Position = pos;
	gl_FogFragCoord = gl_Position.z;
}