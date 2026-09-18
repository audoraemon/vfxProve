// Colossal lightning column (Heaven Splitter): a white-hot core wrapped in jagged lightning filaments that
// crackle and re-strike, over a blue glow, flaring where it hits the ground. The quad stands on its bottom edge:
// UV.x across the width, UV.y down (1 = ground). `intensity` 1 -> 0 thins and dims it out.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec2 size = vec2(170.0, 460.0);
uniform float core_px = 12.0;
uniform float intensity = 1.0;
uniform vec4 c_glow : source_color = vec4(0.16, 0.32, 0.9, 1.0);
uniform vec4 c_mid : source_color = vec4(0.36, 0.62, 1.0, 1.0);
uniform vec4 c_hi : source_color = vec4(0.74, 0.89, 1.0, 1.0);
uniform vec4 c_white : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Jagged offset in -1..1: a random value every `step_px` down the column joined by straight lines, re-rolled
// every crackle tick.
float jag(float y, float step_px, float seed, float tick) {
	float s = y / step_px;
	float i = floor(s);
	float a = hash21(vec2(i + seed * 17.3, tick * 0.37 + seed)) * 2.0 - 1.0;
	float b = hash21(vec2(i + 1.0 + seed * 17.3, tick * 0.37 + seed)) * 2.0 - 1.0;
	return mix(a, b, fract(s));
}

void fragment() {
	float I = clamp(intensity, 0.0, 1.0);
	float x = (UV.x - 0.5) * size.x;
	float y = UV.y * size.y;
	float above = size.y - y;
	float tick = floor(u_time * 20.0);
	// Core: wobbles a little and flares where it hits the ground.
	float cx = jag(y, 24.0, 0.5, tick) * 2.5;
	float flare = 1.0 + 1.3 * (1.0 - smoothstep(0.0, 40.0, above));
	float core_w = core_px * mix(0.2, 1.0, I) * flare;
	float dc = abs(x - cx);
	float top = smoothstep(0.0, 70.0, y) * mix(0.5, 1.0, I);
	// Soft blue glow, dithered so it fades out instead of ending in a hard edge.
	float glow = quant_d(exp(-dc / (6.0 + 20.0 * I)) * 0.5 * top, 5.0, FRAGCOORD.xy);
	float v = 0.0;
	// Lightning filaments winding loosely round the core; each breaks into gaps and re-rolls every tick.
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		float h = hash21(vec2(fi, 3.7));
		float spread = (core_w + 5.0 + 32.0 * h) * I;
		float off = cx + sin(y * (0.011 + 0.012 * h) + fi * 2.3 + u_time * (2.0 + 2.0 * h)) * spread;
		off += jag(y, 9.0 + 6.0 * h, fi + 1.0, tick + fi) * (4.0 + 6.0 * h);
		float w = h > 0.55 ? 1.4 : 0.7;
		float on = step(0.28, hash21(vec2(floor(y / (26.0 + 20.0 * h)) + fi * 7.0, tick)));
		v = max(v, step(abs(x - off), w) * on * (0.78 + 0.2 * h) * step(0.15, I));
	}
	v = max(v, smoothstep(core_w + 1.0, core_w - 1.0, dc) * 1.15);
	// Fades into the clouds at the top.
	float q = max(glow, quant(clamp(v * top, 0.0, 1.0), 6.0));
	if (q < 0.1 || I <= 0.001) discard;
	vec3 col = c_glow.rgb;
	if (q > 0.45) col = c_mid.rgb;
	if (q > 0.7) col = c_hi.rgb;
	if (q > 0.95) col = c_white.rgb;
	COLOR = vec4(col, q > 0.45 ? 1.0 : q * 1.8);
}
