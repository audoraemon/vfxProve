// Tsunami wall painted like the concept: one long standing wall of water, low at the left end and tallest
// toward the right, with a row of curling hoods. Streaked face water sweeps up each hood and curls over its
// lip, a dark crescent hollow sits under the lip with foam hanging over it, a lumpy churning foam crest with spray, and a whitewater band at the base spilling forward.
// Quad: UV.x 0..1 along the wall (left -> right on screen), UV.y 0 top .. 1 bottom. Pixel space:
// x = UV.x * length_px, y = height above the baseline (negative below it, down to -bottom_px).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float length_px = 200.0;
uniform float top_px = 160.0;
uniform float bottom_px = 18.0;
uniform float max_height = 130.0;
// 0..1 rise and curl.
uniform float height = 1.0;
uniform float curl = 1.0;
uniform float hoods = 4.0;
uniform float fade = 1.0;
uniform float seed = 0.0;
// 1 mirrors the wall so its curls and tall end lean the way the wave travels on screen.
uniform float mirror = 0.0;
// 0 = face toward the camera (curls), 1 = the back of the wave as it travels away (smooth slope, foam over the top).
uniform float back_view = 0.0;

uniform vec4 navy : source_color = vec4(0.03, 0.07, 0.22, 1.0);
uniform vec4 deep : source_color = vec4(0.06, 0.18, 0.5, 1.0);
uniform vec4 royal : source_color = vec4(0.1, 0.34, 0.8, 1.0);
uniform vec4 blue : source_color = vec4(0.2, 0.55, 0.95, 1.0);
uniform vec4 cyan : source_color = vec4(0.42, 0.8, 1.0, 1.0);
uniform vec4 pale : source_color = vec4(0.76, 0.94, 1.0, 1.0);
uniform vec4 white : source_color = vec4(0.97, 1.0, 1.0, 1.0);

// Wall envelope along its length: low ramp on the left, tallest around 70-80%, short drop at the right.
float envelope(float u) {
	float ramp = mix(0.55, 1.0, smoothstep(0.0, 0.5, u));
	float right = sqrt(max(1.0 - pow(smoothstep(0.74, 1.0, u), 2.0), 0.0));
	return ramp * mix(0.12, 1.0, right) * smoothstep(0.0, 0.04, u) * smoothstep(1.0, 0.985, u);
}

vec3 water_ramp(float v) {
	if (v < 0.16) return navy.rgb;
	if (v < 0.34) return deep.rgb;
	if (v < 0.52) return royal.rgb;
	if (v < 0.7) return blue.rgb;
	if (v < 0.86) return cyan.rgb;
	return pale.rgb;
}

// Hood silhouette over one cell (fx 0..1 left to right): a broad rounded dome whose top leans left over the
// hollow, dipping between hoods.
float hood_shape(float fx) {
	float k = (fx - 0.42) / 0.62;
	return 0.8 + 0.2 * sqrt(max(1.0 - k * k, 0.0));
}

// Foam clumps: 1 bright top, 0.66 pale-blue shadow, 0.33 blue speck, 0 none. Blobs are lit from the upper left.
float foam_tone(vec2 p, float amount, float t) {
	vec2 q = p * 0.16 + vec2(-t * 0.7, t * 0.9);
	float v1 = fbm(q);
	float v2 = fbm(q + vec2(0.3, -0.3));
	float fine = vnoise(p * 0.55 + vec2(t * 2.0, -t));
	float v = v1 + (fine - 0.5) * 0.3 + (amount - 0.5) * 0.9;
	if (v < 0.42) return 0.0;
	if (v < 0.47) return 0.33;
	if (step(0.93, hash21(floor(p * 0.5) + floor(t * 3.0))) > 0.5 && v < 0.75) return 0.33;
	return (v1 + 0.03 >= v2 || v > 0.78) ? 1.0 : 0.66;
}

void fragment() {
	float t = u_time;
	vec2 fc = FRAGCOORD.xy;
	float x = floor(UV.x * length_px);
	if (mirror > 0.5) {
		x = length_px - 1.0 - x;
	}
	// Curl detail fades out when we see the back of the wave.
	float cv = curl * (1.0 - back_view);
	float y = floor((1.0 - UV.y) * (top_px + bottom_px) - bottom_px);
	float u = x / length_px;
	float hmax = max_height * height;
	if (hmax < 2.0) discard;

	float cells = u * hoods + seed;
	float ci = floor(cells);
	float fx = fract(cells);
	float cell_px = length_px / hoods;
	float env = envelope(u);
	float shape = mix(0.86, hood_shape(fx), mix(cv, curl * 0.5, back_view));
	float crest = hmax * env * shape;
	vec2 p = vec2(x, y);
	// Ragged churning top edge.
	crest += (fbm(vec2(x * 0.08 + seed * 3.0, t * 0.9)) - 0.5) * hmax * 0.1 * env;
	crest += (vnoise(vec2(x * 0.4, t * 3.0 + seed)) - 0.5) * 5.0 * env;

	// Bubbly foam clumps bulging above the crest line.
	float bulge = smoothstep(0.52, 0.8, fbm(vec2(x * 0.1 - t * 0.5, t * 0.6 + seed * 5.0))) * 9.0 * env * height;
	if (y > crest && y <= crest + bulge) {
		float tone = foam_tone(p, 0.95, t);
		if (tone <= 0.0) discard;
		COLOR = vec4(tone > 0.9 ? white.rgb : (tone > 0.5 ? pale.rgb : cyan.rgb), fade);
	} else if (y > crest) {
		// Spray droplets just above the crest.
		float above = y - crest - bulge;
		float dot_on = step(0.88, hash21(floor(fc * 0.5) + floor(t * 10.0) + ci));
		float a = dot_on * (1.0 - smoothstep(0.0, 24.0 * height, above)) * step(0.08, env);
		if (a <= 0.0) discard;
		COLOR = vec4(mix(pale.rgb, white.rgb, step(0.5, hash21(floor(fc * 0.5) + 7.0))), a * fade);
	} else if (y < 0.0) {
		// Whitewater spilling forward in front of the base.
		float depth = -y / bottom_px;
		float tone = foam_tone(p + vec2(0.0, t * 20.0), 0.85 - depth * 0.9, t);
		if (tone <= 0.0 || env < 0.03) discard;
		COLOR = vec4(tone > 0.9 ? white.rgb : (tone > 0.5 ? pale.rgb : blue.rgb), fade);
	} else {
		float d = crest - y;
		float crest_env = max(hmax * env * shape, 1.0);
		float yn = clamp(y / crest_env, 0.0, 1.0);
		// Curling barrel of this hood. Streamlines rise almost straight from the base and bend further toward the
		// lip the higher they go, so the water sweeps up the face and curls over, like the concept.
		float lx = fx * cell_px;
		float lean = cell_px * (0.95 * pow(yn, 1.7) * cv + 0.1 * yn * (1.0 - cv));
		// Lines passing over a hollow wrap around its top, bending hardest right above it.
		vec2 wr = vec2((lx - cell_px * 0.34) / (cell_px * 0.26), (y - crest_env * 0.5) / (crest_env * 0.3));
		wr.x -= wr.y * 0.45;
		float wrap = (1.0 - smoothstep(0.9, 2.4, length(wr))) * smoothstep(-0.4, 0.8, wr.y) * cv;
		lean += cell_px * 0.35 * wrap * smoothstep(-1.5, 1.0, wr.x);
		float across = x + lean + (fbm(vec2(x * 0.06 + seed, y * 0.05 - t * 0.3)) - 0.5) * 4.0;
		float stripe = fract(across / 4.5);
		// Dashes flow up along each streamline toward the crest.
		float dash = step(0.34, vnoise(vec2(floor(across / 4.5) * 2.9 + ci, y * 0.06 - t * 1.8)));
		float streak = step(abs(stripe - 0.5), 0.17) * dash;

		// Hollow under the lip: a leaning crescent on the lip side of the hood, darkest toward its lower left.
		vec2 rel = vec2((lx - cell_px * 0.34) / (cell_px * 0.26), (y - crest_env * 0.5) / (crest_env * 0.3));
		rel.x -= rel.y * 0.45;
		float e = length(rel);
		float hollow = (1.0 - smoothstep(0.35, 1.0, e)) * cv;
		hollow *= 0.6 + 0.4 * smoothstep(-0.6, 0.6, -rel.x - rel.y);

		float light = 0.24 + 0.44 * yn + 0.1 * smoothstep(0.45, 1.0, fx) * yn;
		// Back of the wave: a smooth darker slope brightening toward the crest.
		light = mix(light, 0.2 + 0.42 * yn * yn, back_view);
		light += streak * mix(0.34, 0.2, hollow);
		light -= hollow * 0.46;
		light -= (1.0 - smoothstep(0.0, 0.35, yn)) * 0.08;
		vec3 c = water_ramp(quant(clamp(light, 0.0, 1.0), 6.0));

		// Foam: thick churning crest, foam curling over the lip and hanging down the hollow's outer edge, base.
		float band = crest_env * (0.2 + 0.12 * fbm(vec2(x * 0.05 + seed, t * 0.3))) * (1.0 + 0.6 * back_view);
		float crest_foam = (1.0 - smoothstep(band * 0.25, band, d)) * 0.95;
		float over = clamp(smoothstep(-0.1, 0.5, rel.y) + smoothstep(0.2, 0.8, -rel.x), 0.0, 1.0);
		float lip_arc = smoothstep(0.85, 1.0, e) * (1.0 - smoothstep(1.0, 1.25, e)) * over * cv;
		float base_band = crest_env * 0.2 + 8.0 * fbm(vec2(x * 0.05 - t * 0.5, seed));
		float base_foam = 1.0 - smoothstep(base_band * 0.3, base_band, y);
		float amount = max(max(crest_foam, lip_arc * 0.8), base_foam);
		amount = max(amount, smoothstep(0.7, 0.82, fbm(p * 0.05 + vec2(seed * 9.0, -t * 0.25))) * 0.65);
		if (amount > 0.02) {
			float tone = foam_tone(p, amount, t);
			if (tone > 0.9) {
				c = white.rgb;
			} else if (tone > 0.5) {
				c = pale.rgb;
			} else if (tone > 0.2) {
				c = blue.rgb;
			}
		}
		float fleck = step(mix(0.99, 0.96, streak), hash21(floor(p * 0.5) + ci + floor(t * 2.0))) * (1.0 - hollow);
		c = mix(c, white.rgb, fleck);
		COLOR = vec4(c, smoothstep(0.02, 0.12, env * height) * fade);
	}
	if (COLOR.a <= 0.01) discard;
}
