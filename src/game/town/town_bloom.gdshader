// The glow of the DAY and NIGHT looks (TownBloom): the bright pixels of the finished, graded world (flames, lit windows,
// lamp glass, the sun) spread into a soft warm halo, added on top. The blur is the screen's own mipmaps (each level a
// half-resolution copy, filtered): the bright pass is taken on levels 1 to 3 (half, quarter and eighth resolution) and
// summed over a few taps each. It only adds light, so the art under a halo stays as sharp as it was.
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D screen_mip : hint_screen_texture, filter_linear_mipmap;
// Brightest channel above which a pixel blooms, and the soft knee over which it fades in.
uniform float threshold = 0.6;
uniform float knee = 0.25;
// How much a warm pixel is preferred: 1 = only warm (red over blue) pixels bloom, 0 = any bright one.
uniform float warm_only = 0.8;
uniform float strength = 0.6;
// 1: a pixel's brightness is its luminance (DAY: a red roof is not a highlight), 0: its brightest channel (NIGHT: a flame).
uniform float use_lum = 0.0;
uniform vec3 tint = vec3(1.0, 0.8, 0.55);
uniform vec2 view_size = vec2(640.0, 360.0);

// A source: bright, and (as warm_only asks) warm and saturated as a flame or a lit window is, so lamplit paving, pale
// stone and white canvas do not bloom.
vec3 bright(vec3 c) {
	float m = max(c.r, max(c.g, c.b));
	float b = mix(m, dot(c, vec3(0.299, 0.587, 0.114)), use_lum);
	float sat = (m - min(c.r, min(c.g, c.b))) / max(m, 0.001);
	float w = smoothstep(0.04, 0.25, c.r - c.b) * smoothstep(0.35, 0.6, sat);
	return c * smoothstep(threshold, threshold + knee, b) * mix(1.0 - warm_only, 1.0, w);
}

vec3 level(vec2 uv, float lod, float r) {
	vec2 px = r / view_size;
	vec3 s = bright(textureLod(screen_mip, uv, lod).rgb) * 2.0;
	s += bright(textureLod(screen_mip, uv + vec2(px.x, 0.0), lod).rgb);
	s += bright(textureLod(screen_mip, uv - vec2(px.x, 0.0), lod).rgb);
	s += bright(textureLod(screen_mip, uv + vec2(0.0, px.y), lod).rgb);
	s += bright(textureLod(screen_mip, uv - vec2(0.0, px.y), lod).rgb);
	return s / 6.0;
}

void fragment() {
	vec3 h = level(SCREEN_UV, 1.0, 2.0) * 0.5 + level(SCREEN_UV, 2.0, 4.0) * 0.8 + level(SCREEN_UV, 3.0, 8.0) * 0.9;
	COLOR = vec4(h * tint * strength, 1.0);
}
