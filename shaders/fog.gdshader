// Drifting dithered fog/haze on the ground plane.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.45, 1.0, 0.3, 0.5);
uniform float density = 1.0;
uniform float fade = 1.0;
uniform float scale = 2.5;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0) discard;
	float n = fbm(p * scale + vec2(u_time * 0.18, -u_time * 0.11));
	float n2 = fbm(p * scale * 2.1 - vec2(u_time * 0.25, u_time * 0.05));
	float v = (n * 0.7 + n2 * 0.3) * (1.0 - smoothstep(0.35, 1.0, r)) * density;
	float q = quant_d(v * 1.5 - 0.3, 3.0, FRAGCOORD.xy);
	if (q <= 0.0) discard;
	COLOR = vec4(color.rgb * (0.75 + 0.35 * q), color.a * q * fade);
}
