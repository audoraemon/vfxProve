// Additive soft beam halo. UV.x across width, UV.y along length.
shader_type canvas_item;
render_mode blend_add;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.22, 0.1, 1.0);
uniform float intensity = 1.0;

void fragment() {
	if (intensity <= 0.001) discard;
	float d = abs(UV.x - 0.5) * 2.0;
	float v = pow(max(1.0 - d, 0.0), 2.2) * intensity;
	v *= 0.9 + 0.1 * step(0.5, hash21(vec2(floor(u_time * 24.0), 5.3)));
	float q = quant_d(v, 4.0, FRAGCOORD.xy);
	if (q <= 0.0) discard;
	COLOR = vec4(color.rgb * q, 1.0);
}
