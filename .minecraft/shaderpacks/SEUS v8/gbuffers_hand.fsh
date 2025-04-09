#version 120

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 color;

void main() {
	vec4 albedo = texture2D(texture, texcoord) * color;
	float mat = 1.0f;
	
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(0.0f, mat, 0.0, 1.0);
}