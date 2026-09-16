// Full-screen impact post: inverted high-contrast "impact frame" and RGB split.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
// 0..1 blend toward a two-tone inverted silhouette frame.
uniform float impact_frame = 0.0;
uniform vec4 frame_light : source_color = vec4(1.0, 0.97, 0.9, 1.0);
uniform vec4 frame_dark : source_color = vec4(0.05, 0.02, 0.02, 1.0);
// Horizontal RGB split in whole pixels.
uniform float aberration = 0.0;
uniform vec2 focus = vec2(0.5, 0.5);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 dir = normalize(SCREEN_UV - focus + vec2(0.0001));
	float split = round(aberration * clamp(length(SCREEN_UV - focus) * 2.2, 0.35, 1.0));
	vec3 col;
	if (split >= 1.0) {
		col.r = texture(screen_tex, SCREEN_UV + dir * split * px).r;
		col.g = texture(screen_tex, SCREEN_UV).g;
		col.b = texture(screen_tex, SCREEN_UV - dir * split * px).b;
	} else {
		col = texture(screen_tex, SCREEN_UV).rgb;
	}
	if (impact_frame > 0.0) {
		float lum = dot(col, vec3(0.299, 0.587, 0.114));
		// Bright things become dark silhouettes, everything else floods with light.
		vec3 frame = lum > 0.45 ? frame_dark.rgb : frame_light.rgb;
		col = mix(col, frame, step(0.5, impact_frame));
	}
	COLOR = vec4(col, 1.0);
}
