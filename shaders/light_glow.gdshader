// Additive light pool: dithered radial falloff that brightens whatever is underneath.
// On the ground plane it projects to an iso ellipse; in screen space it is a round bloom.
shader_type canvas_item;
render_mode blend_add;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.5, 0.15, 1.0);
uniform float intensity = 1.0;
uniform float falloff = 1.8;
uniform float flicker = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || intensity <= 0.0) discard;
	float v = pow(1.0 - r, falloff) * intensity;
	v *= 1.0 - flicker * 0.25 * hash21(vec2(floor(u_time * 20.0), 3.1));
	float q = quant_d(v, 6.0, FRAGCOORD.xy);
	if (q <= 0.0) discard;
	COLOR = vec4(color.rgb * q, 1.0);
}
