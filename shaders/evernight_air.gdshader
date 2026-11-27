// Evernight's air (Veil): over the town in view, inside the night's front. A slow violet mist drifting over the roofs; silver
// stars glittering where the night has fallen (fixed to the town, each on its own beat); now and then a star falling across the
// screen; motes of dark rising off the ground, each ringed in faint violet. The quad covers the whole town (EvernightSky.COVER) and never reads its own UV: the world position and SCREEN_UV place everything, in world
// pixels. Everything is a hash of a fixed grid and the time: no luck.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec2 center = vec2(0.0);
uniform float front = 0.0;
uniform float amount = 1.0;
uniform vec4 mist : source_color = vec4(0.50, 0.45, 0.70, 1.0);
uniform vec4 silver : source_color = vec4(0.812, 0.827, 0.902, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);
uniform vec4 black : source_color = vec4(0.027, 0.020, 0.047, 1.0);
uniform float mist_amount = 0.42;
// A falling star every this many seconds (two lanes, out of step).
uniform float fall_every = 2.6;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// A star at the middle of its cell (px from it): a bright core and four arms that grow as it glitters.
float star(vec2 d, float tw) {
	vec2 a = abs(d);
	float core = step(max(a.x, a.y), 0.75);
	float arms = (step(a.x, 0.5) * step(a.y, 0.6 + 2.5 * tw) + step(a.y, 0.5) * step(a.x, 0.6 + 2.5 * tw)) * step(0.55, tw) * tw;
	return max(core * (0.3 + 0.7 * tw), arms);
}

void fragment() {
	vec2 wp = floor(world);
	vec2 g = vec2((wp.x / 32.0 + wp.y / 16.0) * 0.5, (wp.y / 16.0 - wp.x / 32.0) * 0.5);
	float ragged = (fbm(g * 0.3 + vec2(TIME * 0.5, -TIME * 0.2)) - 0.5) * 3.0;
	float cover = (1.0 - smoothstep(front - 3.0, front, distance(g, center) + ragged)) * amount;
	vec4 col = vec4(0.0);
	// The mist: two layers drifting at different speeds, thin and broken.
	vec2 w = wp / 260.0;
	float m1 = fbm(w + vec2(TIME * 0.035, TIME * 0.012));
	float m2 = fbm(w * 1.8 + vec2(-TIME * 0.05, TIME * 0.025) + 7.3);
	float m = smoothstep(0.38, 0.8, m1 * 0.65 + m2 * 0.45);
	col = vec4(mist.rgb, quant_d(m * mist_amount, 4.0, FRAGCOORD.xy));
	// Motes of dark rising: one in some cells, rising off its ground point and fading, a violet ring round a black heart.
	vec2 mc = floor(wp / 44.0);
	float hm = hash21(mc + 11.0);
	if (hm > 0.55) {
		float period = 3.0 + 3.0 * hash21(mc + 4.0);
		float k = fract(TIME / period + hm * 7.0);
		vec2 base = (mc + vec2(0.25 + 0.5 * hash21(mc + 2.0), 0.6 + 0.3 * hash21(mc + 5.0))) * 44.0;
		vec2 at = base + vec2(sin(TIME * 1.3 + hm * 20.0) * 3.0, -k * 70.0);
		float d = length(wp - floor(at));
		float fade = sin(k * 3.14159);
		if (d < 1.6) col = vec4(black.rgb, 0.9 * fade);
		else if (d < 2.6) col = vec4(veil.rgb * 0.7, 0.55 * fade);
	}
	// Stars glittering over the town.
	vec2 sc = floor(wp / 40.0);
	float hs = hash21(sc + 3.1);
	if (hs > 0.70) {
		vec2 sp = (sc + 0.5) * 40.0 + floor((vec2(hash21(sc + 1.7), hash21(sc + 9.2)) - 0.5) * 30.0);
		float tw = 0.5 + 0.5 * sin(TIME * (1.2 + 2.8 * hash21(sc + 6.6)) + hs * 40.0);
		tw = tw * tw * tw * tw;
		float s = star(wp - sp, tw);
		if (s > 0.0) col = vec4(mix(silver.rgb, vec3(1.0), tw), s * (0.55 + 0.45 * tw));
	}
	// Falling stars, in screen space so one is always seen: two lanes, each a streak once every fall_every seconds.
	vec2 px = SCREEN_UV / SCREEN_PIXEL_SIZE;
	vec2 screen = 1.0 / SCREEN_PIXEL_SIZE;
	for (int lane = 0; lane < 2; lane++) {
		float tl = TIME / fall_every + float(lane) * 0.5;
		float slot = floor(tl);
		float k = fract(tl) / 0.3;
		if (k < 1.0) {
			vec2 start = vec2(0.15 + 0.7 * hash21(vec2(slot, float(lane) + 1.0)), 0.05 + 0.3 * hash21(vec2(float(lane) + 4.0, slot))) * screen;
			vec2 dir = normalize(vec2(-0.8 + 1.6 * step(0.5, hash21(vec2(slot, 9.0 + float(lane)))), 0.55));
			float len = 0.22 * screen.y;
			vec2 head = start + dir * k * 0.35 * screen.y;
			vec2 rel = px - head;
			float along = dot(rel, -dir);
			float across = abs(dot(rel, vec2(-dir.y, dir.x)));
			if (along >= 0.0 && along < len && across < 1.0) {
				float tail = 1.0 - along / len;
				col = vec4(mix(veil.rgb, silver.rgb, tail), tail * sin(k * 3.14159));
			}
		}
	}
	col.a *= cover;
	if (col.a <= 0.004) discard;
	COLOR = col;
}
