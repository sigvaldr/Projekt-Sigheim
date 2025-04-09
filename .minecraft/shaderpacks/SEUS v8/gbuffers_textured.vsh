#version 120

varying float mat;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

void main() {
	texcoord = gl_MultiTexCoord0.xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	mat = 0.5f;
	
	gl_Position = ftransform();
	gl_FogFragCoord = gl_Position.z;
}