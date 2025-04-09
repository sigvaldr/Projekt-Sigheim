#version 120

#define SEUS_V8

#ifdef SEUS_V3
	#define BRIGHTMULT 1.25
	#define COLOR_BOOST	0.1
#endif

#ifdef SEUS_V4
	#define BRIGHTMULT 1.1
	#define DARKMULT 0.02
	#define COLOR_BOOST 0.2
	#define GAMMA 0.95
#endif

#ifdef SEUS_V5
	#define BRIGHTMULT 1.24
	#define DARKMULT 0.02
	#define COLOR_BOOST 0.20
	#define GAMMA 0.92
#endif

#ifdef SEUS_V8
	#define BRIGHTMULT 1.20
	#define DARKMULT 0.03
	#define COLOR_BOOST 0.10
	#define GAMMA 0.66
#endif

#define MOTIONBLUR
#define MOTIONBLUR_AMOUNT 1.5

//#define GLARE
#define GLARE_AMOUNT 0.2
#define GLARE_RANGE 3.0

//#define BLOOM
#define BLOOM_AMOUNT 1.0
#define BLOOM_RANGE 3

#define VIGNETTE
#define VIGNETTE_STRENGTH 1.3

#define CROSSPROCESS
#define HIGHDESATURATE

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

varying vec2 texcoord;

void main() {
	vec3 color = texture2D(colortex0, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;
	float mat = texture2D(colortex1, texcoord).g;
	
	#ifdef MOTIONBLUR
	float noblur = float(mat > 0.95f); // Hand
	
	vec4 pos = vec4(texcoord * 2.0f - 1.0f, depth * 2.0f - 1.0f, 1.0f);
	
	vec4 fragPos = gbufferProjectionInverse * pos;
	fragPos /= fragPos.w;
	fragPos = gbufferModelViewInverse * fragPos;
	fragPos.xyz += cameraPosition;
	
	vec4 prevPos = fragPos;
	prevPos.xyz -= previousCameraPosition;
	prevPos = gbufferPreviousModelView * prevPos;
	prevPos = gbufferPreviousProjection * prevPos;
	prevPos /= prevPos.w;
	
	vec2 velocity = (pos - prevPos).xy * 0.007 * MOTIONBLUR_AMOUNT;
	
	int samples = 1;

	if (noblur < 0.5) {
		vec2 coord = texcoord.xy + velocity;

		for (int i = 0; i < 15; ++i, coord += velocity) {
			if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) {
				break;
			}
			
			color += texture2D(colortex0, coord).rgb;
			++samples;
		}
		color /= samples;
	}
	#endif
	
	#ifdef BLOOM
	color = color * 0.8;
	
	float blm_radius = 0.002;
	float blm_amount = 0.02 * BLOOM_AMOUNT;
	float sc = 20.0;
	
	int i = 0;
	int bloomsamples = 1;
	
	vec4 blm_clr = vec4(0.0);
	
	for (i = -10; i < 10; i++) {
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(i,i))*blm_radius)*sc;
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(i,-i))*blm_radius)*sc;
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(-i,i))*blm_radius)*sc;
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(-i,-i))*blm_radius)*sc;
		
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(0.0,i))*blm_radius)*sc;
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-i))*blm_radius)*sc;
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(-i,0.0))*blm_radius)*sc;
		blm_clr += texture2D(colortex0, texcoord.st + (vec2(i,0.0))*blm_radius)*sc;
		
		++bloomsamples;
		sc = sc - 1.0;
	}
	
	blm_clr = (blm_clr/8.0)/bloomsamples;
	
	color += blm_clr.rgb * blm_amount;
	#endif
	
	#ifdef GLARE
	float radius = 0.002 * GLARE_RANGE;
	float radiusv = 0.002;
	float bloomintensity = 0.1 * GLARE_AMOUNT;
	
	vec4 clr = vec4(0.0);
	
	clr += texture2D(colortex0, texcoord.st);
	
	//horizontal (70 taps)
	
	clr += texture2D(colortex0, texcoord.st + (vec2(10.0,0.0))*radius)*10.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(9.0,0.0))*radius)*11.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(8.0,0.0))*radius)*12.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(7.0,0.0))*radius)*13.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(6.0,0.0))*radius)*14.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(5.0,0.0))*radius)*15.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(4.0,0.0))*radius)*16.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(3.0,0.0))*radius)*17.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(2.0,0.0))*radius)*18.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(1.0,0.0))*radius)*19.0;
	
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,0.0))*radius)*20.0;
	
	clr += texture2D(colortex0, texcoord.st + (vec2(-1.0,0.0))*radius)*19.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-2.0,0.0))*radius)*18.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-3.0,0.0))*radius)*17.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-4.0,0.0))*radius)*16.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-5.0,0.0))*radius)*15.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-6.0,0.0))*radius)*14.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-7.0,0.0))*radius)*13.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-8.0,0.0))*radius)*12.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-9.0,0.0))*radius)*11.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(-10.0,0.0))*radius)*10.0;
	
	//vertical
	
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,10.0))*radius)*10.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,9.0))*radius)*11.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,8.0))*radius)*12.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,7.0))*radius)*13.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,6.0))*radius)*14.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,5.0))*radius)*15.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,4.0))*radius)*16.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,3.0))*radius)*17.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,2.0))*radius)*18.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,1.0))*radius)*19.0;
	
	
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-10.0))*radius)*10.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-9.0))*radius)*11.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-8.0))*radius)*12.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-7.0))*radius)*13.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-6.0))*radius)*14.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-5.0))*radius)*15.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-4.0))*radius)*16.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-3.0))*radius)*17.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-2.0))*radius)*18.0;
	clr += texture2D(colortex0, texcoord.st + (vec2(0.0,-1.0))*radius)*19.0;
	
	clr = (clr/20.0)/5.0;
	clr.r = pow(clr.r, 1.2)*1.6 - (clr.g + clr.b)*0.6;
	clr.g = pow(clr.g, 1.2)*1.6 - (clr.r + clr.b)*0.6;
	clr.b = pow(clr.b, 1.2)*1.9 - (clr.r + clr.g)*0.9;
	
	clr = clamp((clr), 0.0, 1.0);
	
	color.r = color.r + (clr.r*1.5)*bloomintensity;
	color.g = color.g + (clr.g*1.5)*bloomintensity;
	color.b = color.b + (clr.b*4.0)*bloomintensity;
	color = max(color, 0.0);
	#endif

	#ifdef VIGNETTE
	float dv = distance(texcoord.xy, vec2(0.5, 0.5));

	dv *= VIGNETTE_STRENGTH;

	dv = 1.0 - dv;

	dv = pow(dv, 0.2);

	dv *= 1.9;
	dv -= 0.9;

	color.r = color.r * dv;
	color.g = color.g * dv;
	color.b = color.b * dv;
	#endif
	
	#ifdef SEUS_V3
		#ifdef CROSSPROCESS
			//pre-gain
			color.r = color.r * BRIGHTMULT;
			color.g = color.g * BRIGHTMULT;
			color.b = color.b * BRIGHTMULT;

			//compensate for low-light artifacts
			color = color+0.025;

			//calculate double curve
			float dbr = -color.r + 1.4;
			float dbg = -color.g + 1.4;
			float dbb = -color.b + 1.4;

			//fade between simple gamma up curve and double curve
			float pr = mix(dbr, 0.55, 0.7);
			float pg = mix(dbg, 0.55, 0.7);
			float pb = mix(dbb, 0.85, 0.7);

			color.r = pow((color.r * 0.99 - 0.02), pr);
			color.g = pow((color.g * 0.99 - 0.015), pg);
			color.b = pow((color.b * 0.7 + 0.04), pb);
		#endif

		#ifdef HIGHDESATURATE
			//desaturate technique (choose one)

			//average
			float rgb = max(color.r, max(color.g, color.b))/2 + min(color.r, min(color.g, color.b))/2;

			//adjust black and white image to be brighter
			float bw = pow(rgb, 0.7);

			//mix between per-channel analysis and average analysis
			float rgbr = mix(rgb, color.r, 0.7);
			float rgbg = mix(rgb, color.g, 0.7);
			float rgbb = mix(rgb, color.b, 0.7);

			//calculate crossfade based on lum
			float mixfactorr = max(0.0, (rgbr*3 - 2));
			float mixfactorg = max(0.0, (rgbg*3 - 2));
			float mixfactorb = max(0.0, (rgbb*3 - 2));

			//crossfade between saturated and desaturated image
			float mixr = mix(color.r, bw, mixfactorr);
			float mixg = mix(color.g, bw, mixfactorg);
			float mixb = mix(color.b, bw, mixfactorb);

			//adjust level of desaturation
			color.r = clamp((mix(mixr, color.r, 0.2)), 0.0, 1.0);
			color.g = clamp((mix(mixg, color.g, 0.2)), 0.0, 1.0);
			color.b = clamp((mix(mixb, color.b, 0.2)), 0.0, 1.0);


			//hold color values for color boost
			//vec4 hld = color;


			//Color boosting
			color.r = (color.r)*(COLOR_BOOST + 1.0) + (color.g + color.b)*(-COLOR_BOOST);
			color.g = (color.g)*(COLOR_BOOST + 1.0) + (color.r + color.b)*(-COLOR_BOOST);
			color.b = (color.b)*(COLOR_BOOST + 1.0) + (color.r + color.g)*(-COLOR_BOOST);

			//color.r = mix(((color.r)*(COLOR_BOOST + 1.0) + (hld.g + hld.b)*(-COLOR_BOOST)), hld.r, (max(((1-rgb)*2 - 1), 0.0)));
			//color.g = mix(((color.g)*(COLOR_BOOST + 1.0) + (hld.r + hld.b)*(-COLOR_BOOST)), hld.g, (max(((1-rgb)*2 - 1), 0.0)));
			//color.b = mix(((color.b)*(COLOR_BOOST + 1.0) + (hld.r + hld.g)*(-COLOR_BOOST)), hld.b, (max(((1-rgb)*2 - 1), 0.0)));

			//undo artifact compensation
			color = max(((color*1.13)-0.03), 0.0);
			color = color*1.02 - 0.02;
		#endif
	#endif
	
	#ifdef SEUS_V4
		#ifdef CROSSPROCESS
			//pre-gain
			color.r = color.r * (BRIGHTMULT + 0.0) + 0.03;
			color.g = color.g * (BRIGHTMULT + 0.0) + 0.03;
			color.b = color.b * (BRIGHTMULT + 0.0) + 0.03;

			//compensate for low-light artifacts
			color = color+0.029;

			//calculate double curve
			float dbr = -color.r + 1.4;
			float dbg = -color.g + 1.4;
			float dbb = -color.b + 1.4;

			//fade between simple gamma up curve and double curve
			float pr = mix(dbr, 0.65, 0.7);
			float pg = mix(dbg, 0.65, 0.7);
			float pb = mix(dbb, 0.75, 0.7);

			color.r = pow((color.r * 0.99 - 0.02), pr);
			color.g = pow((color.g * 0.99 - 0.015), pg);
			color.b = pow((color.b * 0.90 + 0.01), pb);
		#endif

		#ifdef HIGHDESATURATE
			//desaturate technique (choose one)
			
			//average
			float rgb = max(color.r, max(color.g, color.b))/2 + min(color.r, min(color.g, color.b))/2;

			//adjust black and white image to be brighter
			float bw = pow(rgb, 0.7);

			//mix between per-channel analysis and average analysis
			float rgbr = mix(rgb, color.r, 0.7);
			float rgbg = mix(rgb, color.g, 0.7);
			float rgbb = mix(rgb, color.b, 0.7);

			//calculate crossfade based on lum
			float mixfactorr = max(0.0, (rgbr*2 - 1));
			float mixfactorg = max(0.0, (rgbg*2 - 1));
			float mixfactorb = max(0.0, (rgbb*2 - 1));

			//crossfade between saturated and desaturated image
			float mixr = mix(color.r, bw, mixfactorr);
			float mixg = mix(color.g, bw, mixfactorg);
			float mixb = mix(color.b, bw, mixfactorb);

			//adjust level of desaturation
			color.r = clamp((mix(mixr, color.r, 0.1)), 0.0, 1.0);
			color.g = clamp((mix(mixg, color.g, 0.1)), 0.0, 1.0);
			color.b = clamp((mix(mixb, color.b, 0.1)), 0.0, 1.0);

			//desaturate blue channel
			color.b = color.b*0.9 + ((color.r + color.g)/2.0)*0.1;
			
			//Color boosting
			color.r = (color.r)*(COLOR_BOOST + 1.0) + (color.g + color.b)*(-COLOR_BOOST);
			color.g = (color.g)*(COLOR_BOOST + 1.0) + (color.r + color.b)*(-COLOR_BOOST);
			color.b = (color.b)*(COLOR_BOOST + 1.0) + (color.r + color.g)*(-COLOR_BOOST);
			
			//undo artifact compensation
			color = max(((color*1.10) - 0.06), 0.0);

			color = color * BRIGHTMULT;

			color.r = pow(color.r, GAMMA);
			color.g = pow(color.g, GAMMA);
			color.b = pow(color.b, GAMMA);

			color = color*(1.0 + DARKMULT) - DARKMULT;
		#endif
	#endif
	
	#ifdef SEUS_V5
		#ifdef CROSSPROCESS
			//pre-gain
			color = color * (BRIGHTMULT + 0.0) + 0.03;

			//compensate for low-light artifacts
			color = color+0.029;

			//calculate double curve
			float dbr = -color.r + 1.4;
			float dbg = -color.g + 1.4;
			float dbb = -color.b + 1.4;

			//fade between simple gamma up curve and double curve
			float pr = mix(dbr, 0.65, 0.7);
			float pg = mix(dbg, 0.65, 0.7);
			float pb = mix(dbb, 0.65, 0.7);

			color.r = pow((color.r * 0.95 - 0.02), pr);
			color.g = pow((color.g * 0.95 - 0.015), pg);
			color.b = pow((color.b * 0.99 + 0.01), pb);
		#endif

		#ifdef HIGHDESATURATE
			//desaturate technique (choose one)

			//average
			float rgb = max(color.r, max(color.g, color.b))/2 + min(color.r, min(color.g, color.b))/2;

			//adjust black and white image to be brighter
			float bw = pow(rgb, 0.7);

			//mix between per-channel analysis and average analysis
			float rgbr = mix(rgb, color.r, 0.7);
			float rgbg = mix(rgb, color.g, 0.7);
			float rgbb = mix(rgb, color.b, 0.7);

			//calculate crossfade based on lum
			float mixfactorr = max(0.0, (rgbr*2 - 1));
			float mixfactorg = max(0.0, (rgbg*2 - 1));
			float mixfactorb = max(0.0, (rgbb*2 - 1));

			//crossfade between saturated and desaturated image
			float mixr = mix(color.r, bw, mixfactorr);
			float mixg = mix(color.g, bw, mixfactorg);
			float mixb = mix(color.b, bw, mixfactorb);

			//adjust level of desaturation
			color.r = clamp((mix(mixr, color.r, 0.1)), 0.0, 1.0);
			color.g = clamp((mix(mixg, color.g, 0.1)), 0.0, 1.0);
			color.b = clamp((mix(mixb, color.b, 0.1)), 0.0, 1.0);

			//desaturate blue channel
			color.b = color.b*0.9 + ((color.r + color.g)/2.0)*0.1;
			
			//Color boosting
			color.r = (color.r)*(COLOR_BOOST + 1.0) + (color.g + color.b)*(-COLOR_BOOST);
			color.g = (color.g)*(COLOR_BOOST + 1.0) + (color.r + color.b)*(-COLOR_BOOST);
			color.b = (color.b)*(COLOR_BOOST + 1.0) + (color.r + color.g)*(-COLOR_BOOST);
			
			//undo artifact compensation
			color = max(((color*1.10) - 0.06), 0.0);

			color = color * BRIGHTMULT;

			color.r = pow(color.r, GAMMA);
			color.g = pow(color.g, GAMMA);
			color.b = pow(color.b, GAMMA);

			color = color*(1.0 + DARKMULT) - DARKMULT;
		#endif
	#endif
	
	#ifdef SEUS_V8
		color = color * BRIGHTMULT;

		#ifdef CROSSPROCESS
			//pre-gain
			color = color * (BRIGHTMULT + 0.0) + 0.03;
			
			//compensate for low-light artifacts
			color = color+0.029;
			
			//calculate double curve
			float dbr = -color.r + 1.4;
			float dbg = -color.g + 1.4;
			float dbb = -color.b + 1.4;
			
			//fade between simple gamma up curve and double curve
			float pr = mix(dbr, 0.65, 0.5);
			float pg = mix(dbg, 0.65, 0.5);
			float pb = mix(dbb, 0.65, 0.5);
			
			color.r = pow((color.r * 0.95 - 0.002), pr);
			color.g = pow((color.g * 0.95 - 0.002), pg);
			color.b = pow((color.b * 0.99 + 0.000), pb);
		#endif
			
		//Color boosting
		color.r = (color.r)*(COLOR_BOOST + 1.0) + (color.g + color.b)*(-COLOR_BOOST);
		color.g = (color.g)*(COLOR_BOOST + 1.0) + (color.r + color.b)*(-COLOR_BOOST);
		color.b = (color.b)*(COLOR_BOOST + 1.0) + (color.r + color.g)*(-COLOR_BOOST);
		
		#ifdef HIGHDESATURATE
			//average
			float rgb = max(color.r, max(color.g, color.b))/2 + min(color.r, min(color.g, color.b))/2;

			//adjust black and white image to be brighter
			float bw = pow(rgb, 0.7);

			//mix between per-channel analysis and average analysis
			float rgbr = mix(rgb, color.r, 0.7);
			float rgbg = mix(rgb, color.g, 0.7);
			float rgbb = mix(rgb, color.b, 0.7);

			//calculate crossfade based on lum
			float mixfactorr = max(0.0, (rgbr*2 - 1));
			float mixfactorg = max(0.0, (rgbg*2 - 1));
			float mixfactorb = max(0.0, (rgbb*2 - 1));

			//crossfade between saturated and desaturated image
			float mixr = mix(color.r, bw, mixfactorr);
			float mixg = mix(color.g, bw, mixfactorg);
			float mixb = mix(color.b, bw, mixfactorb);

			//adjust level of desaturation
			color.r = clamp((mix(mixr, color.r, 0.0)), 0.0, 1.0);
			color.g = clamp((mix(mixg, color.g, 0.0)), 0.0, 1.0);
			color.b = clamp((mix(mixb, color.b, 0.0)), 0.0, 1.0);

			//desaturate blue channel
			color.b = color.b*0.8 + ((color.r + color.g)/2.0)*0.2;
			
			//undo artifact compensation
			color = max(((color*1.10) - 0.06), 0.0);
			
			color.r = pow(color.r, GAMMA);
			color.g = pow(color.g, GAMMA);
			color.b = pow(color.b, GAMMA);
			
			color = color*(1.0 + DARKMULT) - DARKMULT;
		#endif

		//color *= 1.1;
	#endif
	
	gl_FragData[0] = vec4(color, 1.0);
}