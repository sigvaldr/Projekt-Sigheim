#version 120

#define WATER_SHADER // Must match composite1.fsh

#define SHADOW
//#define SHADOWMAP_DISTORTION // Must match shadow.vsh
#define SHADOWMAP_BIAS 0.4
#define SHADOW_DISTANCE 100.0

#define SHADOW_FILTER
#define BLURFACTOR 3.5
#define SHADOWOFFSET 0.4				// Shadow offset multiplier. Values that are too low will cause artefacts.

#define CORRECTSHADOWCOLORS
#define SHADOWDISTANCE 100.0

#define SSAO
#define SSAO_LUMINANCE 0.0				// At what luminance will SSAO's shadows become highlights.
#define SSAO_STRENGTH 1.65				// Too much strength causes white highlights on extruding edges and behind objects
#define SSAO_LOOP 1						// Integer affecting samples that are taken to calculate SSAO. Higher values mean more accurate shadowing but bigger performance impact
#define SSAO_NOISE false				// Randomize SSAO sample gathering. With noise enabled and SSAO_LOOP set to 1, you will see higher performance at the cost of fuzzy dots in shaded areas.
#define SSAO_NOISE_AMP 0.5				// Multiplier of noise. Higher values mean SSAO takes random samples from a larger radius. Big performance hit at higher values.
#define SSAO_MAX_DEPTH 0.5				// View distance of SSAO
#define SSAO_SAMPLE_DELTA 0.6			// Radius of SSAO shadows. Higher values cause more performance hit.

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform int dimensionShadow;

uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;
uniform float frameTimeCounter;

uniform vec3 fogColor;
uniform vec3 cameraPosition;

// good enough
const float near = 0.05f;
const float far = 256.0f;

varying vec2 texcoord;

#ifdef SSAO

// Alternate projected depth (used by SSAO, probably AA too)
float getProDepth( vec2 coord ) {
	float depth = texture2D(depthtex0, coord).x;
	return ( 2.0 * near ) / ( far + near - depth * ( far - near ) );
}

float znear = near; //Z-near
float zfar = far; //Z-far

float diffarea = 0.6; //self-shadowing reduction
float gdisplace = 0.30; //gauss bell center

bool noise = SSAO_NOISE; //use noise instead of pattern for sample dithering?
bool onlyAO = false; //use only ambient occlusion pass?

vec2 texCoord = texcoord.st;

vec2 rand(vec2 coord) { //generating noise/pattern texture for dithering
  float width = 1.0;
  float height = 1.0;
  float noiseX = ((fract(1.0-coord.s*(width/2.0))*0.25)+(fract(coord.t*(height/2.0))*0.75))*2.0-1.0;
  float noiseY = ((fract(1.0-coord.s*(width/2.0))*0.75)+(fract(coord.t*(height/2.0))*0.25))*2.0-1.0;

  if (noise) {
    noiseX = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233))) * 43758.5453),0.0,1.0)*2.0-1.0;
    noiseY = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233)*2.0)) * 43758.5453),0.0,1.0)*2.0-1.0;
  }
  return vec2(noiseX,noiseY)*0.002*SSAO_NOISE_AMP;
}


float compareDepths(float depth1, float depth2, int zfar) {  
  float garea = 1.5; //gauss bell width    
  float diff = (depth1 - depth2) * 100.0; //depth difference (0-100)
  //reduce left bell width to avoid self-shadowing 
  if (diff < gdisplace) {
    garea = diffarea;
  } else {
    zfar = 1;
  }

  float gauss = pow(2.7182,-2.0*(diff-gdisplace)*(diff-gdisplace)/(garea*garea));
  return gauss;
} 

float calAO(float depth, float dw, float dh) {  
  float temp = 0;
  float temp2 = 0;
  float coordw = texCoord.x + dw/depth;
  float coordh = texCoord.y + dh/depth;
  float coordw2 = texCoord.x - dw/depth;
  float coordh2 = texCoord.y - dh/depth;

  if (coordw  < 1.0 && coordw  > 0.0 && coordh < 1.0 && coordh  > 0.0){
    vec2 coord = vec2(coordw , coordh);
    vec2 coord2 = vec2(coordw2, coordh2);
    int zfar = 0;
    temp = compareDepths(depth, getProDepth(coord),zfar);

    //DEPTH EXTRAPOLATION:
    if (zfar > 0){
      temp2 = compareDepths(getProDepth(coord2),depth,zfar);
      temp += (1.0-temp)*temp2; 
    }
  }

  return temp;  
}  

float getSSAOFactor() {
	vec2 noise = rand(texCoord); 
	float depth = getProDepth(texCoord);
  if (depth > SSAO_MAX_DEPTH) {
    return 1.0;
  }
  float cdepth = texture2D(depthtex0,texCoord).g;
	
	float ao;
	float s;
	
  float incx = 1.0 / viewWidth * SSAO_SAMPLE_DELTA;
  float incy = 1.0 / viewHeight * SSAO_SAMPLE_DELTA;
  float pw = incx;
  float ph = incy;
  float aoMult = SSAO_STRENGTH;
  int aaLoop = SSAO_LOOP;
  float aaDiff = (1.0 + 2.0 / aaLoop);
  for (int i = 0; i < aaLoop ; i++) {
    float npw  = (pw + 0.2 * noise.x) / cdepth;
    float nph  = (ph + 0.2 * noise.y) / cdepth;

    ao += calAO(depth, npw, nph) * aoMult;
    ao += calAO(depth, npw, -nph) * aoMult;
    ao += calAO(depth, -npw, nph) * aoMult;
    ao += calAO(depth, -npw, -nph) * aoMult;
	
	 ao += calAO(depth, 2.0*npw, 2.0*nph) * aoMult/2.0;
    ao += calAO(depth, 2.0*npw, -2.0*nph) * aoMult/2.0;
    ao += calAO(depth, -2.0*npw, 2.0*nph) * aoMult/2.0;
    ao += calAO(depth, -2.0*npw, -2.0*nph) * aoMult/2.0;
	
	 ao += calAO(depth, 3.0*npw, 3.0*nph) * aoMult/3.0;
    ao += calAO(depth, 3.0*npw, -3.0*nph) * aoMult/3.0;
    ao += calAO(depth, -3.0*npw, 3.0*nph) * aoMult/3.0;
    ao += calAO(depth, -3.0*npw, -3.0*nph) * aoMult/3.0;
	
	 ao += calAO(depth, 4.0*npw, 4.0*nph) * aoMult/4.0;
    ao += calAO(depth, 4.0*npw, -4.0*nph) * aoMult/4.0;
    ao += calAO(depth, -4.0*npw, 4.0*nph) * aoMult/4.0;
    ao += calAO(depth, -4.0*npw, -4.0*nph) * aoMult/4.0;
	
    pw += incx*4.0;
    ph += incy*4.0;
    aoMult /= aaDiff; 
    s += 16.0;
  }
	
	ao /= s;
	ao = 1.0-ao;	
  ao = clamp(ao, 0.0, 0.5) * 2.0;
	
  return ao;
}

#endif

#ifdef WATER_SHADER

float getWaves(vec4 worldPos){
	float wsize = 9.0f*3.0;
	float wspeed = 0.3f;
	float time = frameTimeCounter * 24;
	vec3 pos = (worldPos.xzy + cameraPosition.xzy) * 0.0025f;
	//vec3 pos = shadowPos.xyz;

	float rs0 = abs(sin((time*wspeed/5.0) + (pos.s*wsize) * 20.0 + (pos.z*4.0))+0.2);
	float rs1 = abs(sin((time*wspeed/7.0) + (pos.t*wsize) * 27.0) + 0.5);
	float rs2 = abs(sin((time*wspeed/2.0) + (pos.t*wsize) * 60.0 - sin(pos.s*wsize) * 13.0)+0.4);
	float rs3 = abs(sin((time*wspeed/1.0) - (pos.s*wsize) * 20.0 + cos(pos.t*wsize) * 83.0)+0.1);

	float wsize2 = 5.4f*1.5;
	float wspeed2 = 0.2f;

	float rs0a = abs(sin((time*wspeed2/4.0) + (pos.s*wsize2) * 24.0) + 0.5);
	float rs1a = abs(sin((time*wspeed2/11.0) + (pos.t*wsize2) * 77.0  - (pos.z*6.0)) + 0.5);
	float rs2a = abs(sin((time*wspeed2/6.0) + (pos.s*wsize2) * 50.0 - (pos.t*wsize2) * 23.0) + 0.5);
	float rs3a = abs(sin((time*wspeed2/14.0) - (pos.t*wsize2) * 4.0 + (pos.s*wsize2) * 98.0) + 0.5);

	float wsize3 = 2.0f*0.75;
	float wspeed3 = 0.3f;

	float rs0b = abs(sin((time*wspeed3/4.0) + (pos.s*wsize3) * 14.0) + 0.5);
	float rs1b = abs(sin((time*wspeed3/11.0) + (pos.t*wsize3) * 37.0 + (pos.z*1.0)) + 0.5);
	float rs2b = abs(sin((time*wspeed3/6.0) + (pos.t*wsize3) * 47.0 - cos(pos.s*wsize3) * 33.0 + rs0a + rs0b) + 0.5);
	float rs3b = abs(sin((time*wspeed3/14.0) - (pos.s*wsize3) * 13.0 + sin(pos.t*wsize3) * 98.0 + rs0 + rs1) + 0.5);

	float waves = (rs1 * rs0 + rs2 * rs3)/2.0f;
	float waves2 = (rs0a * rs1a + rs2a * rs3a)/2.0f;
	float waves3 = (rs0b + rs1b + rs2b + rs3b)*0.25;
	
	return (waves + waves2 + waves3)/3.0f;
}

#endif

float noiseX[4];
float noiseY[4];

float getShadow(vec2 coord){
	return texture2D(shadowtex0, coord).r;
}

void main() {
	vec3 color = texture2D(colortex0, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;
	float mat = texture2D(colortex1, texcoord).g;
	
	bool land = mat > 0.49;
	
	float shading = 1.0f;
	float allwaves = 0.0f;
	
	if(land) {
		vec4 fragPos = gbufferProjectionInverse * vec4(texcoord * 2.0f - 1.0f, depth * 2.0f - 1.0f, 1.0f);
		fragPos /= fragPos.w;
		
		vec4 worldPos = gbufferModelViewInverse * fragPos;
		
		#ifdef SHADOW
		
		float drawdistance = SHADOWDISTANCE;
		float drawdistancesquared = drawdistance * drawdistance;
		float xzDistanceSquared = fragPos.x * fragPos.x + fragPos.z * fragPos.z;
		float yDistanceSquared  = fragPos.y * fragPos.y;
		
		vec4 shadowPos = shadowModelView * worldPos;
		
		shadowPos = shadowProjection * shadowPos;
		shadowPos /= shadowPos.w;
		
		#ifdef SHADOWMAP_DISTORTION
		shadowPos.xy /= (sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y) * SHADOWMAP_BIAS + (1.0 - SHADOWMAP_BIAS));
		#endif
		
		shadowPos.xyz = shadowPos.xyz * 0.5f + 0.5f;
		
		float border = 1.0f / 256.0f;
		if(dimensionShadow != 0 && shadowPos.x > border && shadowPos.x < 1.0f - border && shadowPos.y > border && shadowPos.y < 1.0f - border && shadowPos.z > border && shadowPos.z < 1.0f - border) {
			
			float shadowBias = 0.0007f;
			shadowPos.x += shadowBias;
			
			#ifndef SHADOW_FILTER
			float shadowDepth = texture2D(shadowtex0, shadowPos.xy).r;
			float realDepth = shadowPos.z;
			
			shading = realDepth - shadowDepth;
			shading *= 256.0f;
			shading = 1.0f - shading;
			shading = clamp(shading, 0.0f, 1.0f);
			shading = mix(shading, 1.0f, 0.4f);
			#endif
			
			#ifdef SHADOW_FILTER
			
			float shadowMult = 1.0f;
			
			float zoffset = 0.00;
			float offsetx = 0.0000*BLURFACTOR*SHADOWOFFSET;
			float offsety = 0.0004*BLURFACTOR*SHADOWOFFSET;
			
			//shadow filtering
			
			float step = 1.0/2048.0;
			float diffthresh = 0.85;
			float bluramount = 0.00009*BLURFACTOR;
			
			float noiseamp = 0.4;
		
			float width2 = 1.0;
			float height2 = 1.0;
			
			float noiseX2 = ((fract(1.0-texcoord.s*(width2/2.0))*0.25)+(fract(texcoord.t*(height2/2.0))*0.75))*2.0-1.0;
			float noiseY2 = ((fract(1.0-texcoord.s*(width2/2.0))*0.75)+(fract(texcoord.t*(height2/2.0))*0.25))*2.0-1.0;
			
			noiseX2 = clamp(fract(sin(dot(texcoord ,vec2(12.9898,78.233))) * 43758.5453),0.0,1.0)*2.0-1.0;
			noiseY2 = clamp(fract(sin(dot(texcoord ,vec2(12.9898,78.233)*2.0)) * 43758.5453),0.0,1.0)*2.0-1.0;
			
			float width3 = 2.0;
			float height3 = 2.0;
			
			float noiseX3 = ((fract(1.0-texcoord.s*(width3/2.0))*0.25)+(fract(texcoord.t*(height3/2.0))*0.75))*2.0-1.0;
			float noiseY3 = ((fract(1.0-texcoord.s*(width3/2.0))*0.75)+(fract(texcoord.t*(height3/2.0))*0.25))*2.0-1.0;
			
			noiseX3 = clamp(fract(sin(dot(texcoord ,vec2(18.9898,28.633))) * 4378.5453),0.0,1.0)*2.0-1.0;
			noiseY3 = clamp(fract(sin(dot(texcoord ,vec2(11.9898,59.233)*2.0)) * 3758.5453),0.0,1.0)*2.0-1.0;
			
			float width4 = 3.0;
			float height4 = 3.0;
			
			float noiseX4 = ((fract(1.0-texcoord.s*(width4/2.0))*0.25)+(fract(texcoord.t*(height4/2.0))*0.75))*2.0-1.0;
			float noiseY4 = ((fract(1.0-texcoord.s*(width4/2.0))*0.75)+(fract(texcoord.t*(height4/2.0))*0.25))*2.0-1.0;
			
			noiseX4 = clamp(fract(sin(dot(texcoord ,vec2(16.9898,38.633))) * 41178.5453),0.0,1.0)*2.0-1.0;
			noiseY4 = clamp(fract(sin(dot(texcoord ,vec2(21.9898,66.233)*2.0)) * 9758.5453),0.0,1.0)*2.0-1.0;
			
			float width5 = 4.0;
			float height5 = 4.0;
			
			float noiseX5 = ((fract(1.0-texcoord.s*(width5/2.0))*0.25)+(fract(texcoord.t*(height5/2.0))*0.75))*2.0-1.0;
			float noiseY5 = ((fract(1.0-texcoord.s*(width5/2.0))*0.75)+(fract(texcoord.t*(height5/2.0))*0.25))*2.0-1.0;
			
			noiseX5 = clamp(fract(sin(dot(texcoord ,vec2(11.9898,68.633))) * 21178.5453),0.0,1.0)*2.0-1.0;
			noiseY5 = clamp(fract(sin(dot(texcoord ,vec2(26.9898,71.233)*2.0)) * 6958.5453),0.0,1.0)*2.0-1.0;
			
			noiseX[0] = noiseX2;
			noiseX[1] = noiseX3;
			noiseX[2] = noiseX4;
			noiseX[3] = noiseX5;
			
			noiseY[0] = noiseY2;
			noiseY[1] = noiseY3;
			noiseY[2] = noiseY4;
			noiseY[3] = noiseY5;
			
			shading = 0.0f;
			
			float samples = 0.0f;
			
			int amount = 1;
			for(float i=-amount; i <= amount; i++) {
				for(float j=-amount; j <= amount; j++) {
					float strength = (1 + abs(i) + abs(j)) / 3.0f;
					
					vec2 offset = vec2(i, j) * 0.01f;
					
					shading += 1.0f - clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX2, noiseY2) * 0.005f).r) * 2048.0f, 0.0f, 1.0f);
					shading += 1.0f - clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX3, noiseY3) * 0.005f).r) * 2048.0f, 0.0f, 1.0f);
					shading += 1.0f - clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX4, noiseY4) * 0.005f).r) * 2048.0f, 0.0f, 1.0f);
					shading += 1.0f - clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX5, noiseY5) * 0.005f).r) * 2048.0f, 0.0f, 1.0f);
					
					samples += 4;
				}
			}
			
			shading /= samples;
			shading = clamp(shading, 0.0f, 1.0f);
			
			shading = shading * 0.4f + 0.4f;
			
			//float shadingsharp = clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy).r) * 512.0f, 0.0f, 1.0f);
			float shadingsharp = 0.0f;
			samples = 0.0f;
			amount = 2;
			for(int i=0; i < amount; i++) {
				for(int j=0; j < amount; j++) {
					vec2 offset = vec2(i, j) * 0.0004f;
					
					//shadingsharp += clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset).r) * 512.0f, 0.0f, 1.0f);
					
					shadingsharp += clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX2, noiseY2) * 0.0002f).r) * 2048.0f, 0.0f, 1.0f);
					shadingsharp += clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX3, noiseY3) * 0.0002f).r) * 2048.0f, 0.0f, 1.0f);
					shadingsharp += clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX4, noiseY4) * 0.0002f).r) * 2048.0f, 0.0f, 1.0f);
					shadingsharp += clamp((shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset + vec2(noiseX5, noiseY5) * 0.0002f).r) * 2048.0f, 0.0f, 1.0f);
					
					samples += 4;
				}
			}
			shadingsharp /= samples;
			
			shading = mix(1.0f, shading, shadingsharp);
			
			//shading = (shading - 0.5f) * 2.0f;
			//shading = clamp(shading, 0.0f, 1.0f);
			
			#endif // SHADOW_FILTER
			
		}
		
		
		
		#endif // SHADOW
		
		#ifdef WATER_SHADER
		allwaves = getWaves(worldPos);
		#endif
	}
	
	#ifdef SSAO
	float lum = dot(color.rgb, vec3(1.0));
	vec3 luminance = vec3(lum);
	vec3 color_hold = vec3(color.rgb);
	float AO = 1.0;
	AO *= getSSAOFactor();

	//AO = mix(AO, AO * 0.5 + 0.5, shading);
	AO = AO * 0.5 + 0.5;
	
	if (land) {
		color.r *= AO;
		color.g *= AO;
		color.b *= AO;

		color.r *= (AO*0.5 + 0.5);
		color.g *= (AO*0.5 + 0.5);
		color.b *= (AO*0.5 + 0.5);
	}
	#endif
	
	// Vanilla SEUS
	// Sunrise 23000 - 24000 + 0 - 4000
	// Noon 0 - 4000 + 8000 - 12000
	// Sunset 8000 - 12000 + 12000 - 12750
	// Midnight 12000 - 12750 + 23000 - 24000
	
	/*
	const float noon = 0.00f;
	const float sunsetStart = 0.1f;
	const float sunset = 0.25f;
	const float sunsetEnd = 0.3f;
	const float midnight = 0.50f;
	const float sunriseStart = 0.7f;
	const float sunrise = 0.75f;
	const float sunriseEnd = 0.9f;
	*/
	
	const float noon = 0.00f;
	const float sunsetStart = 0.1f;
	const float sunset = 0.22f;
	const float sunsetEnd = 0.27f;
	const float midnight = 0.50f;
	const float sunriseStart = 0.75f;
	const float sunrise = 0.80f;
	const float sunriseEnd = 0.9f;
	
	//float time = texcoord.x;
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
	
	/*
	if(texcoord.y < 0.5){
		TimeSunrise = 0.0f;
		TimeSunset = 0.0f;
	}else {
		TimeNoon = 0.0f;
		TimeMidnight = 0.0f;
	}
	*/
	
	color = color *= shading;
	
	if(!land) {
		color = (color * 1.4 - 0.2) * (TimeSunrise + TimeSunset) + (color * 1.4 - 0.4) * TimeNoon + color * TimeMidnight;
		/*
		float colorboost = 0.05;
		color.r = (color.r)*(colorboost + 1.0) + (color.g + color.b)*(-colorboost);
		color.g = (color.g)*(colorboost + 1.0) + (color.r + color.b)*(-colorboost);
		color.b = (color.b)*(colorboost + 1.0) + (color.r + color.g)*(-colorboost);
		*/
	}
	
	#ifdef CORRECTSHADOWCOLORS
	vec3 sunrise_sun = vec3(0.90, 0.73, 0.40) * TimeSunrise;
	vec3 sunrise_amb = vec3(0.90, 0.90, 0.90) * TimeSunrise;
	
	vec3 noon_sun = vec3(1.00, 0.95, 0.80) * TimeNoon;
	vec3 noon_amb = vec3(0.80, 0.93, 1.00) * TimeNoon;
	
	vec3 sunset_sun = vec3(0.90, 0.73, 0.40) * TimeSunset;
	vec3 sunset_amb = vec3(0.90, 0.90, 0.90) * TimeSunset;
	
	vec3 midnight_sun = vec3(0.60, 0.65, 0.80) * TimeMidnight;
	vec3 midnight_amb = vec3(0.80, 0.85, 1.00) * TimeMidnight;
	
	vec3 sunlight = sunrise_sun + noon_sun + sunset_sun + midnight_sun;
	vec3 ambient = sunrise_amb + noon_amb + sunset_amb + midnight_amb;
	
	float sun_amb = clamp((shading - 0.3f) * 3.0f, 0.0f, 1.0f);
	
	color *= mix(ambient, sunlight, sun_amb);
	#endif
	
	//shading += 0.5f;
	
	//color.rgb = vec3(shading);
	//color.rgb = vec3(sun_amb);
	
	gl_FragData[0] = vec4(color, 1.0f);
	gl_FragData[1] = vec4(allwaves, mat, texture2D(colortex1, texcoord).b, 1.0f);
}