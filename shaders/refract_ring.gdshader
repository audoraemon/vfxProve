// Expanding refraction shock ring: pushes screen pixels outward along a thin band, faint tinted edge.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 size_px = vec2(400.0, 200.0);
uniform float progress = 0.0;
uniform float width = 0.08;
uniform float strength = 10.0;
uniform vec4 tint : source_color = vec4(0.8, 0.65, 1.0, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || progress <= 0.0) discard;
	float d = (r - progress) / width;
	float band = exp(-d * d);
	if (band < 0.02) discard;
	vec2 dir = r > 0.001 ? p / r : vec2(0.0);
	vec2 offset = round(-dir * band * strength * vec2(1.0, size_px.y / size_px.x));
	vec3 col = texture(screen_tex, SCREEN_UV + offset * SCREEN_PIXEL_SIZE).rgb;
	float edge = quant_d(band * (1.0 - progress) * 0.8, 3.0, FRAGCOORD.xy);
	COLOR = vec4(mix(col, tint.rgb, edge * 0.6), 1.0);
}
