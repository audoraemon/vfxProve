// Molten corridor behind the laser wall, in lane space: UV.x along the lane, UV.y across.
// Fresh lava right behind the wall, a glowing crack network that cools into dark crust further back,
// ragged burning edges and a white-hot front line.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float front = 0.0;
uniform float length_units = 10.0;
uniform float width_units = 5.0;
uniform float heat_mul = 1.0;
uniform float fade = 1.0;
uniform float seed = 0.0;

vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// Distance between nearest and second-nearest cell points: small along cell borders (cracks).
float worley_edge(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float f1 = 8.0;
	float f2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash22(i + g);
			o = 0.5 + 0.4 * sin(u_time * 0.35 + 6.2831 * o);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return sqrt(f2) - sqrt(f1);
}

void fragment() {
	float x = UV.x * length_units;
	float y = (UV.y - 0.5) * width_units;
	if (x > front) discard;
	float hw = width_units * 0.5;
	float side = y >= 0.0 ? 1.0 : -1.0;
	float e = abs(y) / hw;
	float limit = 0.8 + fbm(vec2(x * 1.3 + seed, side * 4.0)) * 0.3 + vnoise(vec2(x * 5.0, side * 9.0 + seed)) * 0.12;
	if (e > limit) discard;
	float behind = front - x + (vnoise(vec2(y * 3.0 + seed, u_time * 2.5)) - 0.5) * 0.35;
	if (behind < 0.0) discard;

	vec2 cp = vec2(x, y) * 2.3 + vec2(seed);
	// Cracks break up and vary in width so the network never reads as even tiles.
	float crack_w = 0.07 + 0.08 * vnoise(cp * 0.6 + 3.0);
	float crack = (1.0 - smoothstep(0.015, crack_w, worley_edge(cp))) * smoothstep(0.25, 0.45, vnoise(cp * 0.8 + 11.0));
	float fine = 1.0 - smoothstep(0.0, 0.06, worley_edge(cp * 2.4 + 17.0));
	float fresh = clamp(1.0 - behind / 1.7, 0.0, 1.0);
	float warm = clamp(1.0 - behind / 7.5, 0.0, 1.0);
	float rim = smoothstep(limit - 0.25, limit, e);
	float flow = fbm(vec2(x * 1.8 - u_time * 0.7, y * 2.2 + u_time * 0.4));

	float heat = fresh * fresh * (0.55 + 0.7 * flow);
	heat = max(heat, crack * (0.08 + 0.92 * warm * warm) * (0.7 + 0.45 * flow));
	heat = max(heat, fine * 0.55 * fresh);
	heat = max(heat, rim * warm * 0.85 * (0.45 + 0.55 * flow));
	heat *= 0.85 + 0.15 * vnoise(vec2(x * 6.0, u_time * 9.0));
	heat *= heat_mul;

	float plate = vnoise(cp * 1.4);
	vec3 col = mix(vec3(0.04, 0.03, 0.03), vec3(0.12, 0.085, 0.07), plate * (1.0 - crack));
	float q = quant_d(heat, 5.0, FRAGCOORD.xy);
	if (q > 0.0) {
		col = ramp5(q).rgb;
	}
	if (behind < 0.12 && heat_mul > 0.5) {
		col = c4.rgb;
	}
	COLOR = vec4(col, fade * (q > 0.0 ? 1.0 : 0.9));
}
