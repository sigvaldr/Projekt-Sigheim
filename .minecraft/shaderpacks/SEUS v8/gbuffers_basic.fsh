#version 120

varying vec4 color;

void main() {
	vec4 col = color;
	float mat = 0.5f;
	
	if(col.r == 0.0f && col.g == 0.0f && col.b == 0.0f){
		col.a = 1.0f;
	}
	
	gl_FragData[0] = col;
	gl_FragData[1] = vec4(0.0f, mat, 0.0f, 1.0f);
}