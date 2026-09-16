// Additive radial light rays: thin pixel streaks of varying length bursting from the center.
shader_type canvas_item;
render_mode blend_add;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.25, 1.0);
uniform float intensity = 1.0;
uniform float count = 64.0;
// Max ray reach (0..1 of radius) and inner start.
uniform float reach = 1.0;
uniform float inner = 0.0;
// Approximate screen pixels across the radius, for pixel-width rays.
uniform float radius_px = 200.0;
uniform float twinkle = 12.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || intensity <= 0.0 || r < inner) discard;
	float an = atan(p.y, p.x) / TAU + 0.5;
	float id = floor(an * count);
	float h = hash21(vec2(id, 7.3));
	float h2 = hash21(vec2(id, 1.9));
	// Distance from ray center line, in screen pixels of arc.
	float d = abs(fract(an * count) - (0.3 + 0.4 * h2)) / count * TAU * r * radius_px;
	float width = 0.6 + 1.4 * h;
	float ray = step(d, width);
	float len = reach * (0.35 + 0.65 * hash21(vec2(id, 4.1)));
	if (r > len) discard;
	float fade = 1.0 - r / max(len, 0.001);
	float tw = 0.55 + 0.45 * hash21(vec2(id, floor(u_time * twinkle)));
	float v = ray * fade * tw * intensity * (0.6 + 0.8 * h);
	float q = quant(v, 4.0);
	if (q <= 0.0) discard;
	COLOR = vec4(color.rgb * q, 1.0);
}
