// The mist of the DAY and NIGHT looks (TownMist): drifting value noise, snapped to a grid of world pixels and cut into a
// few hard alpha steps, so it stays crisp pixel art (no blur, no smooth gradient). A ring zone thins toward the town
// (keep_out, keep_out2: ground rects, and `fade` units out from them); a water zone thins toward its own edges (zone, edge_fade).
shader_type canvas_item;

uniform vec4 mist_col : source_color = vec4(0.9, 0.9, 0.9, 0.4);
uniform vec4 keep_out = vec4(0.0);
uniform vec4 keep_out2 = vec4(0.0);
uniform float fade = 5.0;
uniform vec4 zone = vec4(0.0);
uniform float edge_fade = 0.0;
uniform float cell = 3.0;
uniform float scale = 90.0;
uniform vec2 drift = vec2(7.0, 2.5);
uniform float steps = 3.0;
uniform float floor_level = 0.28;

varying vec2 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(wpos / cell) * cell;
	vec2 q = p + drift * TIME;
	float n = 0.62 * vnoise(q / scale) + 0.38 * vnoise(q / (scale * 0.37) + vec2(17.0, 5.0));
	// Ground units from world pixels (Iso: x = (gx - gy) * 32, y = (gx + gy) * 16).
	float a = p.x / 32.0;
	float b = p.y / 16.0;
	vec2 g = vec2(a + b, b - a) * 0.5;
	float m = 1.0;
	if (keep_out.z > 0.0) {
		vec2 dd = max(max(keep_out.xy - g, g - (keep_out.xy + keep_out.zw)), vec2(0.0));
		m *= clamp(max(dd.x, dd.y) / fade, 0.0, 1.0);
	}
	if (keep_out2.z > 0.0) {
		vec2 dd = max(max(keep_out2.xy - g, g - (keep_out2.xy + keep_out2.zw)), vec2(0.0));
		m *= clamp(max(dd.x, dd.y) / fade, 0.0, 1.0);
	}
	if (zone.z > 0.0 && edge_fade > 0.0) {
		float e = min(min(g.x - zone.x, zone.x + zone.z - g.x), min(g.y - zone.y, zone.y + zone.w - g.y));
		m *= clamp(e / edge_fade, 0.0, 1.0);
	}
	float v = clamp((n * (0.55 + 0.45 * m) - floor_level) / (1.0 - floor_level), 0.0, 0.999) * m;
	float level = floor(v * (steps + 1.0)) / steps;
	COLOR = vec4(mist_col.rgb, min(level, 1.0) * mist_col.a);
}
