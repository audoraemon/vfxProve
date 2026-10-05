// Divine Schism's sigil: the Dominion sigil drawn in light over the ground and split in two along a jagged crack --
// one half white-gold, the other crimson -- the halves drawn apart as it breaks. Lives on the ground plane.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color_a : source_color = vec4(1.0, 0.92, 0.66, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.25, 0.22, 1.0);
// 0..1: how far out from the middle it has been drawn.
uniform float reveal = 1.0;
// 0..1: how far the halves have been driven apart.
uniform float split = 0.0;
// 0..1: how far the second half has turned to its own colour (0: both halves the first colour).
uniform float sundered = 1.0;
// Drawn on the screen (the sigil in the sky) rather than the ground plane: the crack runs straight down it.
uniform bool screen = false;
uniform float alpha = 1.0;
// One screen pixel (vertical) in normalized radius units.
uniform float px = 0.01;

float line(float d, float w) {
	return 1.0 - smoothstep(w, w * 2.0, abs(d));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	if (alpha <= 0.0) discard;
	// The crack runs down the screen through the middle (ground x = y), zigzagging.
	float across = screen ? p.x : (p.x - p.y) * 0.70710678;
	float along = screen ? p.y : (p.x + p.y) * 0.70710678;
	float zig = (abs(fract(along * 3.0) - 0.5) - 0.25) * 0.22 + (vnoise(vec2(along * 9.0, 1.3)) - 0.5) * 0.08;
	float side = sign(across - zig);
	// Each half slides away from the crack.
	vec2 away = (screen ? vec2(1.0, 0.0) : vec2(0.70710678, -0.70710678)) * side * split * 0.12;
	vec2 q = p - away;
	float r = length(q);
	if (r > 1.0 || r > reveal + px * 3.0) discard;
	float gap = abs(across - zig);
	if (gap < split * 0.05) discard;
	float a = atan(q.y, q.x);
	float v = 0.0;
	v = max(v, line(r - 0.98, px * 1.2));
	v = max(v, line(r - 0.62, px) * step(0.5, fract(a / TAU * 24.0 + u_time * 0.2 * side)));
	v = max(v, line(r - 0.3, px) * step(0.5, fract(a / TAU * 12.0 - u_time * 0.25 * side)));
	float spoke = abs(fract(a / TAU * 12.0 + 0.5) - 0.5) * TAU / 12.0 * r;
	v = max(v, line(spoke, px * 0.9) * step(0.3, r) * step(r, 0.62) * 0.7);
	float t = u_time * 0.15 * side;
	for (int i = 0; i < 6; i++) {
		float ea = t + float(i) * TAU / 6.0;
		float d = dot(q, vec2(cos(ea), sin(ea))) - 0.48;
		v = max(v, line(d, px * 0.9) * step(r, 0.98));
	}
	// The crack's lips burn bright.
	v = max(v, (1.0 - smoothstep(split * 0.05, split * 0.05 + px * 4.0, gap)) * step(0.001, split));
	v = max(v, (1.0 - smoothstep(0.0, 0.25, r)) * 0.4);
	v *= alpha;
	float qv = quant_d(v, 4.0, FRAGCOORD.xy);
	if (qv <= 0.0) discard;
	vec4 col = side > 0.0 ? mix(color_a, color_b, sundered) : color_a;
	COLOR = vec4(col.rgb, col.a * qv);
}
