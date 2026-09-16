// Heat shimmer: rising, whole-pixel screen offsets inside a soft ellipse.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength = 2.0;
uniform float scale = 0.09;
uniform float speed = 5.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float mask = 1.0 - smoothstep(0.35, 1.0, r);
	if (mask <= 0.01 || strength <= 0.0) discard;
	vec2 fc = FRAGCOORD.xy * scale;
	vec2 n = vec2(vnoise(fc + vec2(0.0, u_time * speed)), vnoise(fc + vec2(5.2, u_time * speed * 1.3))) - 0.5;
	vec2 offset = round(n * 2.0 * strength * mask);
	COLOR = vec4(texture(screen_tex, SCREEN_UV + offset * SCREEN_PIXEL_SIZE).rgb, 1.0);
}
