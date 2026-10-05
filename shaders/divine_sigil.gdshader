// Divine Congregation's sigil: rings, spokes and a slowly turning star drawn in light over the ground, rising and
// fading. Lives on the ground plane, so it projects to an iso ellipse.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.88, 0.55, 1.0);
// 0..1: how far out from the middle it has been drawn.
uniform float reveal = 1.0;
uniform float alpha = 1.0;
// One screen pixel (vertical) in normalized radius units.
uniform float px = 0.01;

float line(float d, float w) {
	return 1.0 - smoothstep(w, w * 2.0, abs(d));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || r > reveal + px * 3.0 || alpha <= 0.0) discard;
	float a = atan(p.y, p.x);
	float v = 0.0;
	// Three rings, the outer one solid, the inner two dashed.
	v = max(v, line(r - 0.98, px * 1.2));
	v = max(v, line(r - 0.62, px) * step(0.5, fract(a / TAU * 24.0 + u_time * 0.2)));
	v = max(v, line(r - 0.3, px) * step(0.5, fract(a / TAU * 12.0 - u_time * 0.25)));
	// Twelve spokes between the inner rings.
	float spoke = abs(fract(a / TAU * 12.0 + 0.5) - 0.5) * TAU / 12.0 * r;
	v = max(v, line(spoke, px * 0.9) * step(0.3, r) * step(r, 0.62) * 0.7);
	// A six-pointed star, turning: two triangles' edges as lines.
	float t = u_time * 0.15;
	for (int i = 0; i < 6; i++) {
		float ea = t + float(i) * TAU / 6.0;
		vec2 n = vec2(cos(ea), sin(ea));
		float d = dot(p, n) - 0.48;
		v = max(v, line(d, px * 0.9) * step(r, 0.98));
	}
	// A soft glow in the middle.
	v = max(v, (1.0 - smoothstep(0.0, 0.25, r)) * 0.4);
	v *= alpha;
	float q = quant_d(v, 4.0, FRAGCOORD.xy);
	if (q <= 0.0) discard;
	COLOR = vec4(color.rgb, color.a * q);
}
