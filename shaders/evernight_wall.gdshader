// A wall of night (Veil): Evernight's front running out across the town (and, at dawn, rolling back); The Swallowing Dark's rim closing
// in. Drawn per pixel over one quad round the ring's bounds (EvernightSky.Wall), no mesh: for each pixel the shader finds where the
// ring's near and far sides stand at its x (the ring's ellipse on screen) and how far up each wall it is, shades both (far first, the
// near one over it) and blends them. The place along the ring runs out and back (|angle|), so there is no join and no seam anywhere.
// Near-solid black at the foot, boiling up into towers of smoke of different heights whose crowns catch a violet light; fine silver
// motes carried up in it. Keeps its own time (TIME).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float amount = 1.0;
uniform vec4 black : source_color = vec4(0.027, 0.020, 0.047, 1.0);
uniform vec4 dusk : source_color = vec4(0.231, 0.078, 0.439, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);
uniform vec4 silver : source_color = vec4(0.812, 0.827, 0.902, 1.0);
// The ring on screen (the node's own pixels): its centre, its semi-axes, the wall's height, noise tiles per radian along it.
uniform vec2 ring_c = vec2(0.0);
uniform float ring_a = 100.0;
uniform float ring_b = 50.0;
uniform float wall_h = 300.0;
uniform float tiles = 1.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

// A hash without the lattice's period (hash21 repeats on whole cells).
float hash_s(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// The wall's own smooth noise, about 0..1: a few warped sines at unrelated frequencies. (The shared value noise drew straight
// upright and diagonal cuts through this wall on the GPU, though a CPU copy of it is smooth; a sine-built crown drew none: fix round 1.)
float wn(vec2 p) {
	float w = sin(p.y * 1.3 + 0.7) * 1.4;
	return 0.5 + 0.2 * sin(p.x * 1.9 + w) + 0.15 * sin(p.y * 2.3 + p.x * 0.7 + 1.7)
		+ 0.09 * sin((p.x - p.y) * 3.7 + 4.1) + 0.06 * sin(p.x * 7.3 + p.y * 5.1 + w);
}

// One side of the ring (sgn +1 near, -1 far) at this pixel: colour and coverage.
vec4 side(float sgn, float cx, float y, vec2 fc, float time) {
	float sn = sqrt(max(1.0 - cx * cx, 0.0)) * sgn;
	float base_y = ring_c.y + ring_b * sn;
	float v = (base_y - y) / max(wall_h, 1.0);
	if (v < 0.0 || v > 1.3) return vec4(0.0);
	// Along the wall by the pixel's own x (noise tiles of WALL_TILE pixels), the far side offset so the two never match.
	float u = (cx * ring_a) / 240.0 + (sgn < 0.0 ? 17.3 : 0.0);
	// Both noises as wide as they are tall on screen (u counts 240-pixel tiles): sampled finer across the wall than up it, their
	// features stood as thin upright streaks and the crown's flanks went sheer (fix round 1).
	float up_tiles = v * wall_h / 240.0;
	float n = wn(vec2(u * 2.4, up_tiles * 2.4 - time * 0.7));
	float n2 = wn(vec2(u * 6.0 + 3.0, up_tiles * 6.0 - time * 1.5));
	// The crown: towers that lean as they rise (sampled along a slant) and never change height faster than the smoke can boil, so
	// no tower has a sheer side.
	float crown = 0.25 + 0.7 * wn(vec2(u * 1.5 + v * 0.7 + 5.0, time * 0.35));
	float lift = v + (n2 - 0.5) * 0.34 + (n - 0.5) * 0.18;
	float body = 1.0 - smoothstep(crown - 0.2, crown, lift);
	// Toward the ring's ends (where the wall turns away) it thins out, so its silhouette has no hard upright side.
	float ends = smoothstep(1.0, 0.8, abs(cx) + (n2 - 0.5) * 0.15);
	// Coverage follows the body alone, and the colour steps are dithered: a hard-stepped noise that runs mostly along the wall
	// would stand its step edges upright (fix round 1).
	float a = quant_d(body * ends, 5.0, fc);
	vec3 col = mix(black.rgb, dusk.rgb * 0.65, quant_d(n2 * v * 1.4, 3.0, fc));
	float edge = step(abs(lift - crown + 0.06), 0.035) * step(0.1, v);
	col = mix(col, veil.rgb * 0.75, edge);
	return vec4(col, a);
}

void fragment() {
	float cx = (local.x - ring_c.x) / max(ring_a, 1.0);
	if (abs(cx) >= 1.0) discard;
	vec4 far = side(-1.0, cx, local.y, FRAGCOORD.xy, TIME);
	vec4 near = side(1.0, cx, local.y, FRAGCOORD.xy, TIME);
	float a = near.a + far.a * (1.0 - near.a);
	vec3 col = mix(far.rgb, near.rgb, near.a);
	// Fine silver motes carried up in it.
	vec2 cell = floor((FRAGCOORD.xy + vec2(0.0, TIME * 45.0)) / 3.0);
	float mote = step(0.9985, hash_s(cell)) * step(0.25, a);
	col = mix(col, silver.rgb, mote);
	a = max(a, mote * 0.8) * amount;
	if (a <= 0.0) discard;
	COLOR = vec4(col, a);
}
