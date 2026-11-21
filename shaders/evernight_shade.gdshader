// Evernight's dark (Veil): multiplied over the whole town in view (the ground, the houses and the people), under the effects. A
// violet-black night inside the front (ground units round the click, its edge churning), deeper at the screen's edge (a
// vignette), a little lighter under the moon; each burning torch keeps a warm round island of the day's light. The quad is drawn
// over the whole town (EvernightSky.COVER, far past any view) and never reads its own UV: the world position (vertex()) gives the
// ground point under each pixel, SCREEN_UV the vignette and the moon.
shader_type canvas_item;
render_mode blend_mul, unshaded;
#include "res://shaders/common.gdshaderinc"

uniform vec2 center = vec2(0.0);
uniform float front = 0.0;
uniform float amount = 1.0;
uniform vec4 night : source_color = vec4(0.46, 0.43, 0.66, 1.0);
uniform vec4 edge_night : source_color = vec4(0.28, 0.25, 0.44, 1.0);
uniform vec4 warm : source_color = vec4(0.92, 0.80, 0.64, 1.0);
uniform float vignette = 1.0;
uniform vec2 torches[6];
uniform int torch_count = 0;
uniform float torch_r = 2.5;
uniform vec2 moon_uv = vec2(0.82, 0.16);
uniform float moon_light = 0.10;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 g = vec2((world.x / 32.0 + world.y / 16.0) * 0.5, (world.y / 16.0 - world.x / 32.0) * 0.5);
	float ragged = (fbm(g * 0.3 + vec2(TIME * 0.5, -TIME * 0.2)) - 0.5) * 3.0;
	float cover = (1.0 - smoothstep(front - 3.0, front, distance(g, center) + ragged)) * amount;
	cover = quant_d(cover, 6.0, FRAGCOORD.xy);
	vec2 suv = SCREEN_UV - 0.5;
	float edge = smoothstep(0.25, 0.72, length(suv * vec2(1.0, 1.25))) * vignette;
	vec3 shade = mix(night.rgb, edge_night.rgb, quant_d(edge, 4.0, FRAGCOORD.xy));
	float moon = 1.0 - smoothstep(0.0, 0.75, distance(SCREEN_UV * vec2(1.6, 1.0), moon_uv * vec2(1.6, 1.0)));
	shade = min(shade + vec3(0.8, 0.85, 1.0) * moon_light * moon, vec3(1.0));
	float lit = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= torch_count) break;
		float d = distance(g, torches[i]);
		lit = max(lit, 1.0 - smoothstep(torch_r * 0.35, torch_r * 1.25, d));
	}
	shade = mix(shade, warm.rgb, quant_d(lit, 4.0, FRAGCOORD.xy));
	COLOR = vec4(mix(vec3(1.0), shade, cover), 1.0);
}
