// Mirrorfold: a mirror lying thin as a film on the ground, a whole street long. The quad is laid into the iso ground
// by its node's transform, so UV.x runs along the lane and UV.y across it. No frame and no glow: what shows inside is
// the screen itself, nudged by a slow ripple and laid over with a faint reflection flipped about the long axis. A
// hairline runs round the rim with brighter glints drifting along the long edges, a soft sheen crosses the surface now
// and then, and a crossing flares it.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
// The surface's extents on screen, in pixels (along, across): the rim is drawn a few pixels wide whatever the lane.
uniform vec2 size_px = vec2(220.0, 46.0);
// 0..1: the whole surface, in and out.
uniform float presence = 1.0;
// How much of the reflection shows over the ground.
uniform float reflect_mix = 0.2;
// The ripple's reach in pixels.
uniform float ripple = 1.5;
// 0..1: the sheen crossing the surface; 0 and 1 are none.
uniform float shimmer = 0.0;
// The rim's hairline and the glints drifting along it.
uniform float rim_alpha = 0.3;
uniform float glint = 0.5;
// 0..1: a crossing's flare, fading.
uniform float flash = 0.0;
// The last crossing: where (-1..1 along and across the surface) and its ripple's age 0..1 (1 = none).
uniform vec2 pulse_at = vec2(0.0);
uniform float pulse = 1.0;
uniform vec4 tint : source_color = vec4(0.82, 0.92, 1.0, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	if (abs(p.x) > 1.0 || abs(p.y) > 1.0 || presence <= 0.0) discard;
	// Pixels in from the nearest edge, and which edge that is.
	vec2 hs = size_px * 0.5;
	vec2 in_px = hs - abs(p) * hs;
	float edge_px = min(in_px.x, in_px.y);
	float inside = smoothstep(0.0, 5.0, edge_px);
	vec2 fc = FRAGCOORD.xy;
	vec2 n = vec2(vnoise(fc * 0.045 + vec2(u_time * 0.35, 0.0)), vnoise(fc * 0.045 + vec2(7.3, u_time * 0.3))) - 0.5;
	vec2 off = n * 2.0 * ripple;
	// Someone crossed: one ring of refraction spreading from where they stepped, round on the ground.
	vec2 pd = (p - pulse_at) * vec2(1.0, size_px.y / size_px.x);
	float pr = length(pd);
	float reach = pulse * 0.35;
	float ring = exp(-pow((pr - reach) / 0.03, 2.0)) * (1.0 - pulse);
	off += (pr > 0.001 ? pd / pr : vec2(0.0)) * ring * 4.0;
	off = round(off * inside * presence);
	vec3 base = texture(screen_tex, SCREEN_UV + off * SCREEN_PIXEL_SIZE).rgb;
	// The reflection: the screen flipped about the surface's long axis, whichever way the lane lies on screen and
	// whatever the camera's zoom -- the across-coordinate's screen gradient says which way and how far that is.
	vec2 gy = vec2(dFdx(p.y), dFdy(p.y));
	float g2 = dot(gy, gy);
	vec2 flip = g2 > 0.00000001 ? -2.0 * p.y * gy / g2 : vec2(0.0);
	vec3 refl = texture(screen_tex, SCREEN_UV + (flip + off) * SCREEN_PIXEL_SIZE).rgb;
	vec3 col = mix(base, refl * tint.rgb, reflect_mix * inside * presence);
	// A cool cast over the glass, stronger as it flares.
	col = mix(col, col * tint.rgb + tint.rgb * 0.08, inside * presence * (0.35 + 0.65 * flash));
	float band = exp(-pow((p.x * 0.8 + p.y * 0.3 - (shimmer * 2.8 - 1.4)) / 0.16, 2.0))
		* step(0.001, shimmer) * step(shimmer, 0.999);
	col += tint.rgb * quant_d(band * 0.3 * inside, 3.0, fc);
	// The rim: a hairline two pixels in; glints drifting along both long edges, one each way, and round the ends.
	float rim = smoothstep(1.0, 2.0, edge_px) * (1.0 - smoothstep(3.0, 4.0, edge_px));
	float on_long = step(in_px.y, in_px.x);
	float g_a = fract(u_time * 0.12) * 2.4 - 1.2;
	float g_b = 1.2 - fract(u_time * 0.12 + 0.5) * 2.4;
	float arc = on_long * (exp(-pow((p.x - g_a) / 0.08, 2.0)) * step(0.0, p.y) + exp(-pow((p.x - g_b) / 0.08, 2.0)) * step(p.y, 0.0))
		+ (1.0 - on_long) * exp(-pow(sin((atan(p.y, p.x) - u_time * 0.45) * 0.5) / 0.3, 2.0));
	col += tint.rgb * rim * presence * (rim_alpha + arc * glint + flash * 0.9);
	col += tint.rgb * quant_d(ring * 0.5 * inside, 3.0, fc);
	COLOR = vec4(col, 1.0);
}
