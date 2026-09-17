// Flood water left behind the tsunami, on the ground plane. Rippling blue body, a white foam network
// that drifts with the current, a churning foam band behind the wave front and ragged foamy banks.
// `length` / `width` are the quad size in ground units so the pattern stays put while the quad grows.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float length = 10.0;
uniform float width = 5.0;
uniform float fade = 1.0;
// 0 = rushing, 1 = settled calm water.
uniform float settle = 0.0;
uniform float seed = 0.0;
uniform vec4 deep : source_color = vec4(0.06, 0.2, 0.46, 0.9);
uniform vec4 body : source_color = vec4(0.12, 0.36, 0.7, 0.88);
uniform vec4 mid : source_color = vec4(0.24, 0.55, 0.86, 0.85);
uniform vec4 foam : source_color = vec4(0.93, 0.98, 1.0, 1.0);
uniform vec4 foam_shadow : source_color = vec4(0.62, 0.84, 0.97, 0.9);

void fragment() {
	vec2 p = vec2(UV.x * length, (UV.y - 0.5) * width);
	float t = u_time;
	float flow = mix(1.6, 0.25, settle);
	vec2 q = p + vec2(-t * flow + seed, sin(p.x * 0.7 + t) * 0.15);

	// Ragged banks: the water edge wobbles and is lined with foam.
	float bank = width * 0.5 - (fbm(vec2(p.x * 0.8 + seed, t * 0.3)) - 0.5) * 0.7 - 0.1;
	float edge_d = bank - abs(p.y);
	float rear = p.x - (fbm(vec2(p.y * 0.9 + seed, t * 0.3)) - 0.2) * 0.8;
	if (edge_d < 0.0 || rear < 0.0) discard;

	float ripple = fbm(q * vec2(1.4, 2.2)) + (vnoise(q * 5.0 + t * 0.5) - 0.5) * 0.25;
	float d = quant_d(clamp(ripple, 0.0, 1.0), 3.0, FRAGCOORD.xy);
	vec4 col = d < 0.34 ? deep : (d < 0.67 ? body : mid);

	// Foam streaks: a warped cell network stretched along the current and broken into fragments,
	// thinning out as the water calms.
	vec2 w = q + (vec2(fbm(q * 0.7), fbm(q * 0.7 + 5.2)) - 0.5) * 1.8;
	float net = cell_edge(w * vec2(0.9, 1.7), t * 0.5);
	float broken = smoothstep(0.42, 0.6, vnoise(w * 0.8 + vec2(-t * 0.3, 3.0)));
	float fine = cell_edge(w * vec2(2.2, 3.6) + 7.0, t * 0.8);
	float lines = (1.0 - smoothstep(0.0, mix(0.07, 0.04, settle), net)) * broken
		+ (1.0 - smoothstep(0.0, 0.05, fine)) * 0.55 * (1.0 - settle) * (1.0 - broken);
	// Swirling foam patches.
	lines = max(lines, smoothstep(0.66, 0.74, fbm(w * 1.1 - t * 0.2)) * (1.0 - 0.5 * settle));
	// Churn behind the moving front, foam along the banks and at the rear edge.
	float churn = smoothstep(length - 1.6, length, p.x) * (1.0 - settle);
	float banks = 1.0 - smoothstep(0.0, 0.35, min(edge_d, rear));
	float fw = max(lines * mix(0.75, 0.5, settle), max(churn, banks)) + (vnoise(q * 4.0 - t) - 0.5) * 0.5;
	if (fw > 0.62) {
		col = foam;
	} else if (fw > 0.5) {
		col = foam_shadow;
	}
	float sp = step(0.994, hash21(floor(FRAGCOORD.xy * 0.5) + floor(t * 6.0)));
	col = mix(col, vec4(1.0), sp);
	col.a *= fade * mix(1.0, 0.8, settle);
	if (col.a <= 0.01) discard;
	COLOR = col;
}
