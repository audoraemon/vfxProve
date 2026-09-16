// Frozen ground: ice plates with bright cracks spreading outward from the center, a frosty
// rim on the advancing edge, sparkles, and a slow fade. Lives on the ground plane.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

// Reveal radius 0..1.
uniform float progress = 1.0;
uniform float fade = 1.0;
uniform float seed = 0.0;
uniform vec4 plate : source_color = vec4(0.55, 0.78, 0.95, 0.42);
uniform vec4 crack : source_color = vec4(0.8, 0.93, 1.0, 0.55);
uniform vec4 rim : source_color = vec4(0.95, 1.0, 1.0, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float edge = progress + (fbm(vec2(a * 3.0 + seed, progress * 4.0)) - 0.5) * 0.14 + (vnoise(vec2(a * 14.0, seed)) - 0.5) * 0.05;
	if (r > edge || progress <= 0.0) discard;

	vec2 cp = p * 5.5 + vec2(seed) + (vec2(vnoise(p * 3.0 + seed), vnoise(p * 3.0 - seed)) - 0.5) * 0.8;
	float plates = cell_edge(cp, 0.0);
	float fine = cell_edge(cp * 2.6 + 9.0, 0.0);
	float crack_v = 1.0 - smoothstep(0.0, 0.07, plates);
	float fine_v = (1.0 - smoothstep(0.0, 0.05, fine)) * 0.6;
	// Radial frost streaks from the center.
	float streak = step(0.93, vnoise(vec2(a * 26.0 + seed, r * 2.0))) * smoothstep(0.1, 0.5, r);

	float body = quant_d((0.55 + 0.45 * vnoise(cp * 0.7)) * (1.0 - smoothstep(0.75, 1.0, r / max(edge, 0.001)) * 0.4), 3.0, FRAGCOORD.xy);
	vec4 col = vec4(plate.rgb * (0.85 + 0.25 * body), plate.a * body);
	float line_v = max(max(crack_v, fine_v), streak * 0.8);
	if (line_v > 0.45) {
		col = vec4(crack.rgb, crack.a * step(0.45, line_v));
	}
	// Bright frosty rim on the advancing edge.
	float rim_v = smoothstep(edge - 0.07, edge, r) * step(progress, 0.999);
	if (rim_v > 0.3) {
		col = vec4(rim.rgb, rim.a * quant(rim_v, 2.0));
	}
	// Sparkles.
	float sp = step(0.992, hash21(floor(FRAGCOORD.xy * 0.5) + floor(u_time * 6.0)));
	col = mix(col, vec4(1.0), sp * 0.9);
	col.a *= fade;
	if (col.a <= 0.01) discard;
	COLOR = col;
}
