// Expanding ground ring: sharp leading edge, glowing trail inward, noisy breakup.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float progress = 0.0;
uniform float thickness = 0.12;
uniform float fade = 1.0;
uniform float inner_heat = 0.18;
uniform float px = 0.01;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || progress <= 0.0) discard;
	float d = progress - r;
	float v;
	if (d < 0.0) {
		v = 1.0 - smoothstep(0.0, px * 3.0, -d);
	} else {
		v = exp(-d / thickness);
	}
	float a = atan(p.y, p.x);
	float n = vnoise(vec2(a * 7.0 + 3.0, r * 9.0 - u_time * 3.0));
	v *= 0.55 + 0.6 * n;
	v = max(v, inner_heat * step(r, progress) * (1.0 - progress) * (0.6 + 0.4 * n));
	v *= fade;
	float q = quant_d(v, 5.0, FRAGCOORD.xy);
	if (q <= 0.0) discard;
	COLOR = ramp5(q);
}
