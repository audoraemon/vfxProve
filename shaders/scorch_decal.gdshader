// Ground scorch / crater decal with cracks and cooling glowing edge.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec4 char_color : source_color = vec4(0.06, 0.045, 0.04, 0.9);
uniform vec4 edge_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 edge_hot : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float heat = 1.0;
uniform float fade = 1.0;
uniform float warp = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0) discard;
	float a = atan(p.y, p.x);
	float sa = a + warp * r * 5.0;
	float n = fbm(p * 3.0 + seed);
	float en = vnoise(vec2(sa * 2.5 + seed, r * 3.0));
	float rr = r + (n - 0.5) * 0.35 + (en - 0.5) * 0.2 - warp * 0.06 * sin(sa * 3.0);
	if (rr > 0.95) discard;

	float body = 1.0 - smoothstep(0.45, 0.95, rr);
	vec4 col = char_color;
	col.a *= quant_d(body * 1.1, 3.0, FRAGCOORD.xy);

	// Thin radial cracks: narrow angular lines wobbling with noise.
	float ca = fract(sa / TAU * 9.0 + (vnoise(p * 4.0 + seed) - 0.5) * 0.6);
	float crack = step(abs(ca - 0.5), 0.035) * step(0.15, rr) * step(rr, 0.8) * step(0.45, n);
	// Broken glowing rim.
	float edge = step(0.8, rr) * step(rr, 0.87) * step(0.5, en);
	float arms = warp * step(0.9, fract(sa / TAU * 3.0 - r * 0.5)) * step(0.3, rr);
	float glow = max(max(edge, crack), arms);
	if (glow > 0.5 && heat > 0.02) {
		float hot = step(0.65, heat) * step(0.6, n);
		vec4 ec = mix(edge_color, edge_hot, hot);
		// Cool from glowing toward char in two hard steps.
		float h = quant(heat * (0.7 + 0.5 * n), 2.0);
		col = mix(col, ec, h);
		col.a = max(col.a, h);
	}
	col.a *= fade;
	if (col.a <= 0.01) discard;
	COLOR = col;
}
