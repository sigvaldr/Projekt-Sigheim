#version 120

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 color;

void main() {
	float mat = 0.0f;
	
	gl_FragData[0] = texture2D(texture, texcoord) * color;
	gl_FragData[1] = vec4(0.0f, mat, 0.0f, 1.0f);
}