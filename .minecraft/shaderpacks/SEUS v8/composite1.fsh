#version 120

//#define SIMPLE_WATER_SHADER		// Very simple water shader by pedro, might not work with texture packs

#define WATER_SHADER // Must match composite.fsh
//#define WATER_SHADER_EVERYWHERE

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

varying vec2 texcoord;

uniform float viewWidth;
uniform float viewHeight;
float aspectRatio = 1.0f; // TODO

float isWater(vec2 coord){
	float mat = texture2D(colortex1, coord).g;
	return float(mat > 0.65f && mat < 0.75f);
}

#ifdef WATER_SHADER

void ApplyWaterShader(inout vec3 color){
	#ifndef WATER_SHADER_EVERYWHERE
	if(isWater(texcoord) == 0.0f){
		return;
	}
	#endif
	float noiseX2 = 0.0f;
	
	const float rspread = 0.30f;						//How long reflections are spread across the screen
	
	float depth = texture2D(depthtex0, texcoord).r;
	float rdepth = depth;

	float pix_x = 1.0f / viewWidth;
	float pix_y = 1.0f / viewHeight;

	rdepth = pow(rdepth, 1.0f);

	const float wnormalclamp = 0.05f;
	
	//Detect water surface normals

	//Compare change in depth texture over 1 pixel and return an angle
	float wnormal_x1 = texture2D(depthtex0, texcoord.st + vec2(pix_x, 0.0f)).x - texture2D(depthtex0, texcoord.st).x;
	float wnormal_x2 = texture2D(depthtex0, texcoord.st).x - texture2D(depthtex0, texcoord.st + vec2(-pix_x, 0.0f)).x;			
	float wnormal_x = 0.0f;
	
	if(abs(wnormal_x1) > abs(wnormal_x2)){
		wnormal_x = wnormal_x2;
	} else {
		wnormal_x = wnormal_x1;
	}
	
	wnormal_x /= 1.0f - rdepth;
	wnormal_x = clamp(wnormal_x, -wnormalclamp, wnormalclamp);
	wnormal_x *= rspread*1.0f;
	
	float wnormal_y1 = texture2D(depthtex0, texcoord.st + vec2(0.0f, pix_y)).x - texture2D(depthtex0, texcoord.st).x;
	float wnormal_y2 = texture2D(depthtex0, texcoord.st).x - texture2D(depthtex0, texcoord.st + vec2(0.0f, -pix_y)).x;		
	float wnormal_y;
	
	if(abs(wnormal_y1) > abs(wnormal_y2)){
		wnormal_y = wnormal_y2;
	} else {
		wnormal_y = wnormal_y1;
	}
	
	wnormal_y /= 1.0f - rdepth;
	wnormal_y = clamp(wnormal_y, -wnormalclamp, wnormalclamp);
	wnormal_y *= rspread*1.0f*aspectRatio;
	
	//if (down >= 1.0f) {
	//		down = 0.0f;
	// }
	
	//REFRACTION
	
	//Heightmap of small waves
	float waves = texture2D(colortex1, texcoord.st).r;
	float wavesraw = waves;
		  waves -= 0.5f;
		  waves *= 1.0 - depth;
		  waves *= 100.0f;
	//Detect angle of waves by comparing 1 pixel difference and resolving discontinuities
	float wavesdeltax1 = texture2D(colortex1, texcoord.st).r - texture2D(colortex1, texcoord.st + vec2(-pix_x, 0.0f)).r;
	float wavesdeltax2 = texture2D(colortex1, texcoord.st + vec2(pix_x, 0.0f)).r - texture2D(colortex1, texcoord.st).r;
	float wavesdeltax;
	
	if(abs(wavesdeltax1) > abs(wavesdeltax2)){
		wavesdeltax = wavesdeltax2;
	} else {
		wavesdeltax = wavesdeltax1;
	}
	
	wavesdeltax = clamp(wavesdeltax, -0.1f, 0.1f);	
	wavesdeltax *= 1.0f - depth;
	wavesdeltax *= 30.0f;
	
	float wavesdeltay1 = texture2D(colortex1, texcoord.st).r - texture2D(colortex1, texcoord.st + vec2(0.0f, -pix_y)).r;
	float wavesdeltay2 = texture2D(colortex1, texcoord.st + vec2(0.0f, pix_y)).r - texture2D(colortex1, texcoord.st).r;
	float wavesdeltay = 0.0f;
	
	if(abs(wavesdeltay1) > abs(wavesdeltay2)){
		wavesdeltay = wavesdeltay2;
	} else {
		wavesdeltay = wavesdeltay1;
	}
	
	wavesdeltay *= 1.0f - depth;
	wavesdeltay *= 30.0f;
	wavesdeltay = clamp(wavesdeltay, -0.1f, 0.1f);
	
	float refractamount = 500.1154f*1.75f;
	float refractamount2 = 0.0214f*0.00f;
	float refractamount3 = 0.214f*0.25f;
	float waberration = 0.10f;
	
	vec3 refracted = vec3(0.0f);
	vec3 refractedmask = vec3(0.0f);
	float bigWaveRefract = 1000.0f * (1.0f - depth);
	float bigWaveRefractScale = 1500.0f * (1.0f - depth);
	
	vec2 bigRefract = vec2(wnormal_x*bigWaveRefract, wnormal_y*bigWaveRefract);
	
	for (int i = 0; i < 1; ++i) {
		/*
		if(water != 1.0f) {
			break;
		}
		*/

		vec2 refractcoord_r = texcoord.st * (1.0f + waves*refractamount3) - (waves*refractamount3/2.0f) + vec2(wavesdeltax*refractamount*(-wnormal_x*0.3f) + waves*refractamount2 + (-wnormal_x*0.4f) - bigRefract.x, wavesdeltay*refractamount*(-wnormal_y*0.3f) + waves*refractamount2 + (-wnormal_y*0.4f) - bigRefract.y) * (waberration * 2.0f + 1.0f);
		vec2 refractcoord_g = texcoord.st * (1.0f + waves*refractamount3) - (waves*refractamount3/2.0f) + vec2(wavesdeltax*refractamount*(-wnormal_x*0.3f) + waves*refractamount2 + (-wnormal_x*0.4f) - bigRefract.x, wavesdeltay*refractamount*(-wnormal_y*0.3f) + waves*refractamount2 + (-wnormal_y*0.4f) - bigRefract.y) * (waberration + 1.0f);
		vec2 refractcoord_b = texcoord.st * (1.0f + waves*refractamount3) - (waves*refractamount3/2.0f) + vec2(wavesdeltax*refractamount*(-wnormal_x*0.3f) + waves*refractamount2 + (-wnormal_x*0.4f) - bigRefract.x, wavesdeltay*refractamount*(-wnormal_y*0.3f) + waves*refractamount2 + (-wnormal_y*0.4f) - bigRefract.y);
		
		refractcoord_r = refractcoord_r * vec2(1.0f - abs(wnormal_x) * bigWaveRefractScale, 1.0f - abs(wnormal_y) * bigWaveRefractScale) + vec2(abs(wnormal_x) * bigWaveRefractScale * 0.5f, abs(wnormal_y) * bigWaveRefractScale * 0.5f);
		refractcoord_g = refractcoord_g * vec2(1.0f - abs(wnormal_x) * bigWaveRefractScale, 1.0f - abs(wnormal_y) * bigWaveRefractScale) + vec2(abs(wnormal_x) * bigWaveRefractScale * 0.5f, abs(wnormal_y) * bigWaveRefractScale * 0.5f);
		refractcoord_b = refractcoord_b * vec2(1.0f - abs(wnormal_x) * bigWaveRefractScale, 1.0f - abs(wnormal_y) * bigWaveRefractScale) + vec2(abs(wnormal_x) * bigWaveRefractScale * 0.5f, abs(wnormal_y) * bigWaveRefractScale * 0.5f);
		
		/*
		refractcoord_r.s = clamp(refractcoord_r.s, 0.001f, 0.999f);
		refractcoord_r.t = clamp(refractcoord_r.t, 0.001f, 0.999f);	
		
		refractcoord_g.s = clamp(refractcoord_g.s, 0.001f, 0.999f);
		refractcoord_g.t = clamp(refractcoord_g.t, 0.001f, 0.999f);
		
		refractcoord_b.s = clamp(refractcoord_b.s, 0.001f, 0.999f);
		refractcoord_b.t = clamp(refractcoord_b.t, 0.001f, 0.999f);
		*/
		
		if (refractcoord_r.s > 1.0 || refractcoord_r.s < 0.0 || refractcoord_r.t > 1.0 || refractcoord_r.t < 0.0 ||
			refractcoord_g.s > 1.0 || refractcoord_g.s < 0.0 || refractcoord_g.t > 1.0 || refractcoord_g.t < 0.0 ||
			refractcoord_b.s > 1.0 || refractcoord_b.s < 0.0 || refractcoord_b.t > 1.0 || refractcoord_b.t < 0.0) {
				break;
			}
		/*
		if (refractcoord_r.st * vec2(water) == 0.0f) break;
		if (refractcoord_g.st * vec2(water) == 0.0f) break;
		if (refractcoord_b.st * vec2(water) == 0.0f) break;
		*/
		if (refractcoord_r.st == 0.0f) break;
		if (refractcoord_g.st == 0.0f) break;
		if (refractcoord_b.st == 0.0f) break;
		
		refracted.r = texture2D(colortex0, refractcoord_r).r;
		refracted.g = texture2D(colortex0, refractcoord_g).g;
		refracted.b = texture2D(colortex0, refractcoord_b).b;
		
		refractedmask.r = isWater(refractcoord_r);
		refractedmask.g = isWater(refractcoord_g);
		refractedmask.b = isWater(refractcoord_b);
	}
	
	color.r = mix(color.r, refracted.r, refractedmask.r);
	color.g = mix(color.g, refracted.g, refractedmask.g);
	color.b = mix(color.b, refracted.b, refractedmask.b);
	
	//REFLECTION

	//color.rgb = worldposition.g;
	
	vec3 reflection = vec3(0.0f);
	float rtransy = 0.01f * rspread;
	float rtransin = 0.05f;
	
	const float rstrong = 5.4f;
	const float reflectwaviness = 0.00395f;
	const float rcurve = 1.0f;
	
	//coordinates for translating reflection
	vec2 coordnormal = vec2(0.0f);
	vec2 coordin = texcoord.st;
	vec2 rcoord = vec2(0.0f);
	
	float dwaves = waves * 0.4f * reflectwaviness;
	float dwavesdeltax = wavesdeltax * 7.3f * reflectwaviness;
	float dwavesdeltay = wavesdeltay * 7.3f * reflectwaviness;
	float reflectmask = 0.0f;
	float reflectmaskhold = 0.0f;
	float rnoise = 0.0f;
	
	float depthcheck = 0.0f;
	float depthcheck2 = 0.0f;
	float depthpass = 0.0f;
	float prevdepth;
	float thisdepth;
	
	int samples = 1;
	
	float redge = distance(texcoord.s, 0.5f);
	redge = max(redge, distance(texcoord.t, 0.5f));
	redge *= 2.0f;
	redge = clamp(redge * 4.0f - 3.0f, 0.0f, 1.0f);
	redge = 1.0f;

	for (int i = 0; i < 8; ++i) {
		/*
		if(water != 1.0f) {
			samples += 1;
			break;
		}
		*/
		
		rcoord = coordnormal + vec2(dwavesdeltax*4.0f + wnormal_x, dwavesdeltay*4.0f + wnormal_y)*(samples * samples - 1)*redge;
		
		thisdepth = texture2D(depthtex0, clamp(texcoord.st + rcoord, 0.001f, 0.999f)).x;
		
		depthcheck = (rdepth - thisdepth);
		depthcheck = 1.0f - depthcheck;
		depthcheck = clamp(depthcheck * 140.0 - 139.0f, 0.0f, 1.0f);
		depthcheck2 = clamp(depthcheck * 70.0 - 69.0f, 0.0f, 1.0f);
		
		reflectmask   = ((1.0 - isWater(clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseX2*wnormal_x*rnoise*(samples - 1), noiseX2*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f))) * ((9 - samples)/9.0f))/1.0f;
		//reflectmask  += ((1.0 - texture2D(gaux1, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseY2*wnormal_x*rnoise*(samples - 1), noiseY2*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).g) * ((9 - samples)/9.0f))/4.0f;
		//reflectmask  += ((1.0 - texture2D(gaux1, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseX4*wnormal_x*rnoise*(samples - 1), noiseX4*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).g) * ((9 - samples)/9.0f))/4.0f;
		//reflectmask  += ((1.0 - texture2D(gaux1, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseY4*wnormal_x*rnoise*(samples - 1), noiseY4*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).g) * ((9 - samples)/9.0f))/4.0f;
																																																																																																					
		reflection  += 	((texture2D(colortex0, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseX2*wnormal_x*rnoise*(samples - 1), noiseX2*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).rgb * reflectmask) * ((9 - samples)/9.0f))/1.0f;
		//reflection  += 	((texture2D(composite, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseY2*wnormal_x*rnoise*(samples - 1), noiseY2*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).rgb * reflectmask) * ((9 - samples)/9.0f))/4.0f;
		//reflection  += 	((texture2D(composite, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseX4*wnormal_x*rnoise*(samples - 1), noiseX4*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).rgb * reflectmask) * ((9 - samples)/9.0f))/4.0f;
		//reflection  += 	((texture2D(composite, clamp(texcoord.st + (rcoord*depthcheck + vec2(noiseY4*wnormal_x*rnoise*(samples - 1), noiseY4*wnormal_y*rnoise*(samples - 1))*redge*depthcheck), 0.001f, 0.999f)).rgb * reflectmask) * ((9 - samples)/9.0f))/4.0f;
		
		reflectmaskhold += reflectmask;

		samples += 1;
	}
	
	reflection /= samples - 1;
	reflectmaskhold /= samples - 1;
	
	reflectmaskhold = pow(reflectmaskhold, 1.0f)*2.5f;
	
	float wfresnel = pow(distance(vec2(wnormal_x, wnormal_y) + vec2(dwavesdeltax, dwavesdeltay), vec2(0.0f)), 0.7f) * 20.0f;
	
				
	//Darken objects behind water
	//color.rgb = mix(color.rgb, vec3(color.r * (1.1f - wfresnel), color.g * (1.1f - wfresnel * 0.9f), color.b * (1.1f - wfresnel * 0.8f)) * (1.0 - reflectmaskhold), water);
	color.rgb = mix(color.rgb, vec3(color.r * (1.1f - wfresnel), color.g * (1.1f - wfresnel * 0.9f), color.b * (1.1f - wfresnel * 0.8f)) * (1.0 - reflectmaskhold), 1.0f);
	
	//Add reflections to water only >:3
	//reflection *= water;
	
	color.rgb = color.rgb + (reflection * rstrong);
	
}

#endif
void main() {
	float mat = texture2D(colortex1, texcoord).g;
	float alpha = texture2D(colortex1, texcoord).b * 3.0f - 1.9f;
	vec2 coord = texcoord;
	
	#ifdef SIMPLE_WATER_SHADER
	if(isWater(texcoord) > 0.5f) {
		vec2 coord2 = coord;
		coord2.x += alpha * 0.03f;
		
		//if(isWater(coord2) > 0.5f){
			coord = coord2;
		//}
	}
	#endif
	
	vec3 color = texture2D(colortex0, coord).rgb;
	
	#ifdef WATER_SHADER
	ApplyWaterShader(color);
	#endif
	
	gl_FragData[0] = vec4(color, 1.0f);
}