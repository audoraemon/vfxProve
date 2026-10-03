// Mirrorfold: a mirror lying thin as a film on the ground. No frame and no glow: what shows inside is the screen
// itself, nudged by a slow ripple and laid over with a faint upside-down reflection. A hairline runs round the rim
// with a brighter glint drifting along it, a soft sheen crosses the surface now and then, and a crossing flares it.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 size_px = vec2(220.0, 46.0);
// 0..1: the whole surface, in and out.
uniform float presence = 1.0;
// How much of the reflection shows over the ground.
uniform float reflect_mix = 0.2;
// The ripple's reach in pixels.
uniform float ripple = 1.5;
// 0..1: the sheen crossing the surface; 0 and 1 are none.
uniform float shimmer = 0.0;
// The rim's hairline and the glint drifting along it.
uniform float rim_alpha = 0.3;
uniform float glint = 0.5;
// 0..1: a crossing's flare, fading.
uniform float flash = 0.0;
// The last crossing: where (-1..1 across the surface) and its ripple's age 0..1 (1 = none).
uniform vec2 pulse_at = vec2(0.0);
uniform float pulse = 1.0;
uniform vec4 tint : source_color = vec4(0.82, 0.92, 1.0, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || presence <= 0.0) discard;
	float inside = 1.0 - smoothstep(0.88, 1.0, r);
	vec2 fc = FRAGCOORD.xy;
	vec2 n = vec2(vnoise(fc * 0.045 + vec2(u_time * 0.35, 0.0)), vnoise(fc * 0.045 + vec2(7.3, u_time * 0.3))) - 0.5;
	vec2 off = n * 2.0 * ripple;
	// Someone crossed: one ring of refraction spreading from where they stepped.
	vec2 pd = p - pulse_at;
	float pr = length(pd);
	float ring = exp(-pow((pr - pulse * 0.9) / 0.1, 2.0)) * (1.0 - pulse);
	off += (pr > 0.001 ? pd / pr : vec2(0.0)) * ring * 4.0 * vec2(1.0, size_px.y / size_px.x);
	off = round(off * inside * presence);
	vec3 base = texture(screen_tex, SCREEN_UV + off * SCREEN_PIXEL_SIZE).rgb;
	// The reflection: the screen flipped about the surface's long axis, whatever the camera's zoom.
	float per_px = dFdy(p.y);
	float flip = abs(per_px) > 0.00001 ? -2.0 * p.y / per_px : 0.0;
	vec3 refl = texture(screen_tex, SCREEN_UV + (vec2(0.0, flip) + off) * SCREEN_PIXEL_SIZE).rgb;
	vec3 col = mix(base, refl * tint.rgb, reflect_mix * inside * presence);
	// A cool cast over the glass, stronger as it flares.
	col = mix(col, col * tint.rgb + tint.rgb * 0.08, inside * presence * (0.35 + 0.65 * flash));
	float band = exp(-pow((p.x * 0.8 + p.y * 0.3 - (shimmer * 2.8 - 1.4)) / 0.16, 2.0))
		* step(0.001, shimmer) * step(shimmer, 0.999);
	col += tint.rgb * quant_d(band * 0.3 * inside, 3.0, fc);
	float rim = smoothstep(0.93, 0.96, r) * (1.0 - smoothstep(0.975, 1.0, r));
	float arc = exp(-pow(sin((atan(p.y, p.x) - u_time * 0.45) * 0.5) / 0.2, 2.0));
	col += tint.rgb * rim * presence * (rim_alpha + arc * glint + flash * 0.9);
	col += tint.rgb * quant_d(ring * 0.5 * inside, 3.0, fc);
	COLOR = vec4(col, 1.0);
}
