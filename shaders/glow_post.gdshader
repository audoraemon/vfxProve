// Screen-space glow: bright pixels bleed a soft halo onto their surroundings, like the painted concepts.
// Samples blurred mip levels of the screen, keeps only what is brighter than `threshold`, and adds it
// back dithered into a few steps so the halo stays pixel-art.
shader_type canvas_item;
render_mode blend_add;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float threshold = 0.8;
uniform float strength = 0.55;
uniform float saturation_boost = 1.25;

vec3 bright(vec3 c) {
	float lum = max(c.r, max(c.g, c.b));
	float k = max(lum - threshold, 0.0) / max(1.0 - threshold, 0.001);
	return c * k;
}

void fragment() {
	vec3 g = vec3(0.0);
	g += bright(textureLod(screen_tex, SCREEN_UV, 1.0).rgb) * 0.35;
	g += bright(textureLod(screen_tex, SCREEN_UV, 2.0).rgb) * 0.4;
	g += bright(textureLod(screen_tex, SCREEN_UV, 3.0).rgb) * 0.45;
	g += bright(textureLod(screen_tex, SCREEN_UV, 4.0).rgb) * 0.4;
	float lum = dot(g, vec3(0.299, 0.587, 0.114));
	g = mix(vec3(lum), g, saturation_boost);
	g = max(g, vec3(0.0)) * strength;
	// Quantize halo intensity with ordered dither so it reads as pixel steps, not a smooth blur.
	float m = max(g.r, max(g.g, g.b));
	if (m <= 0.004) discard;
	float q = quant_d(clamp(m, 0.0, 1.0), 6.0, FRAGCOORD.xy);
	COLOR = vec4(g / m * q, 1.0);
}
