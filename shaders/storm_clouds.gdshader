// Storm clouds over the whole town (Tempest): two layers of drifting fbm, dithered to the pixel grid, that thicken from
// `cover` 0 (clear) to 1 (a dark ceiling), lit from inside by sheet lightning (`flicker`). The quad hangs over the map in
// world space; the edge softens toward the quad's rim so the cover never shows a hard border.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec4 dark : source_color = vec4(0.05, 0.05, 0.09, 1.0);
uniform vec4 lit : source_color = vec4(0.42, 0.4, 0.55, 1.0);
uniform float cover = 0.0;
uniform float flicker = 0.0;
uniform float scale = 3.0;
uniform float drift = 0.05;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float rim = 1.0 - smoothstep(0.55, 1.0, max(abs(p.x), abs(p.y)));
	vec2 q = vec2(p.x, p.y * 2.0) * scale;
	float n = fbm(q + vec2(u_time * drift, u_time * drift * 0.3));
	float n2 = fbm(q * 1.9 - vec2(u_time * drift * 1.6, u_time * drift * 0.2));
	float cloud = n * 0.65 + n2 * 0.35;
	// The cover eats into the clear sky: thin wisps first, then the whole ceiling.
	float v = smoothstep(0.62 - cover * 0.6, 0.78 - cover * 0.3, cloud) * cover * rim;
	float q3 = quant_d(v, 3.0, FRAGCOORD.xy);
	if (q3 <= 0.0) discard;
	vec3 col = mix(dark.rgb, lit.rgb, clamp((cloud - 0.35) * 1.6, 0.0, 1.0) + flicker * 0.9);
	COLOR = vec4(col, min(q3 * 0.8, 0.8));
}
