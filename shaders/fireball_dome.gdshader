// Fireball / plasma dome: hemisphere over an iso base ellipse.
// Mapped to sphere coordinates so its surface detail wraps the dome: boiling plasma cells,
// meridian energy lines, rising latitude pulses and streaks, hot core at the base, bright
// translucent rim, fire skirt on the ground and soot patches as it cools.
// Quad: width 2A, height A*(dome_ratio + base_ratio); anchor at base center.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float grow = 1.0;
uniform float heat = 1.0;
uniform float dissolve = 0.0;
uniform float dome_ratio = 0.85;
uniform float base_ratio = 0.5;
// Surface detail strength (0 = plain fireball).
uniform float pattern = 1.0;
// Dark cooling patches (0..1).
uniform float soot = 0.0;
uniform float seed = 0.0;

void fragment() {
	float s = max(grow, 0.001);
	float x = (UV.x - 0.5) * 2.0 / s;
	float y = (UV.y * (dome_ratio + base_ratio) - dome_ratio) / s;
	bool dome = y < 0.0;
	float h = dome ? -y / dome_ratio : 0.0;
	float q = dome ? x * x + h * h : x * x + (y / base_ratio) * (y / base_ratio);
	float turb = fbm(vec2(x * 3.0 + seed, y * 3.0 + u_time * 1.8));
	float qe = q + (turb - 0.5) * 0.22;
	if (qe > 1.0) discard;
	float burn = fbm(vec2(x * 4.0 + 7.0 + seed, y * 4.0 - u_time * 0.7));
	if (burn < dissolve * 1.1 - 0.1 + q * dissolve * 0.3) discard;

	float nz = sqrt(max(1.0 - q, 0.0));
	float lon = atan(x, max(nz, 0.001));
	float lat = dome ? asin(clamp(h, 0.0, 1.0)) : 0.0;

	// Hot core low in the middle, and a bright translucent rim.
	float core = exp(-(x * x * 3.0 + (h - 0.05) * (h - 0.05) * 5.0));
	float rim = pow(1.0 - nz, 2.5);
	float v = 0.36 + 0.42 * core + 0.3 * rim;
	v *= 0.7 + 0.5 * turb;

	// Boiling plasma cells: bright veins between darker cells.
	vec2 sp = vec2(lon * 2.4, lat * 3.0 - u_time * 0.35) + vec2(seed);
	float veins = 1.0 - smoothstep(0.0, 0.1, cell_edge(sp * 1.9, u_time));
	float cell_body = smoothstep(0.35, 0.05, cell_edge(sp * 1.9 + 0.5, u_time * 0.7));
	v += veins * 0.3 * pattern * (0.4 + 0.6 * nz);
	v -= cell_body * 0.08 * pattern;

	if (dome) {
		// Meridians converging toward the top.
		float mer = abs(fract(lon * 7.0 / PI + 0.5) - 0.5);
		float mer_line = (1.0 - smoothstep(0.0, 0.07, mer)) * smoothstep(0.02, 0.25, nz);
		mer_line *= 0.45 + 0.55 * vnoise(vec2(lon * 9.0, lat * 5.0 - u_time * 2.5));
		// Energy pulses climbing the dome.
		float ring = abs(fract(lat * 2.4 - u_time * 1.1) - 0.5);
		float ring_line = (1.0 - smoothstep(0.0, 0.05, ring)) * step(0.06, h) * (0.6 + 0.4 * nz);
		// Bright streaks shooting up the surface.
		float streak = step(0.8, vnoise(vec2(lon * 24.0 + seed, lat * 1.6 - u_time * 3.5)));
		v += (mer_line * 0.3 + ring_line * 0.22 + streak * 0.22) * pattern;
	} else {
		v += 0.12 * (1.0 - q);
	}
	// Fire skirt where the dome meets the ground.
	v += smoothstep(0.14, 0.0, abs(y)) * smoothstep(0.45, 1.0, x * x) * 0.35;

	float soot_n = fbm(vec2(x * 5.0 + seed * 2.0, y * 5.0 + u_time * 0.4));
	v *= 1.0 - soot * smoothstep(0.45, 0.7, soot_n) * 0.8;
	v *= mix(1.0, 0.7, smoothstep(0.8, 1.0, qe));
	v *= heat;
	float qv = quant_d(v, 5.0, FRAGCOORD.xy);
	if (qv <= 0.0) discard;
	COLOR = ramp5(qv);
}
