#version 120

#define SHADOWMAP_DISTORTION // Must match composite.fsh
//#define SHADOWMAP_BIAS 0.4

varying vec2 texcoord;

void main() {
	texcoord = gl_MultiTexCoord0.xy;
	
	vec4 pos = ftransform();
	
	#ifdef SHADOWMAP_DISTORTION
	float shadowMapBias = SHADOWMAP_BIAS;
	pos.xy *= 1.0 / (sqrt(pos.x * pos.x + pos.y * pos.y) * shadowMapBias + (1.0 - shadowMapBias));
	#endif
	
	gl_Position = pos;
}