// Telegraph: dashed concentric rings, ticks, crosshair and scan sweep.
// Lives on the ground plane: quad is 2R x 2R ground units, so circles project to iso ellipses.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.23, 0.16, 1.0);
uniform float reveal = 1.0;
uniform float alpha = 1.0;
uniform float rings = 4.0;
uniform float dashes = 18.0;
uniform float scan = 1.0;
uniform float pulse = 1.0;
uniform float crosshair = 1.0;
uniform float fill = 0.12;
// One screen pixel (vertical) in normalized radius units.
uniform float px = 0.01;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float outer = max(reveal, 0.001);
	if (r > outer + px * 2.0) discard;
	float an = atan(p.y, p.x) / TAU + 0.5;
	float v = 0.0;

	// Solid outer ring.
	v = max(v, step(abs(r - outer + px), px * 1.2));
	// Dashed inner rings, alternating spin.
	for (int i = 1; i < 6; i++) {
		if (float(i) >= rings) break;
		float rr = outer * float(i) / rings;
		float spin = mod(float(i), 2.0) * 2.0 - 1.0;
		float n = max(floor(dashes * rr), 4.0);
		float dash = step(0.42, fract(an * n + spin * u_time * 0.12));
		v = max(v, step(abs(r - rr), px * 0.8) * dash * 0.8);
	}
	// Ticks just inside the outer ring.
	float tick_d = abs(fract(an * 16.0 + 0.5) - 0.5) / 16.0 * TAU * r;
	v = max(v, step(tick_d, px * 0.9) * step(outer - 0.09, r) * step(r, outer) * 0.9);
	// Crosshair with center gap.
	float cross_len = step(r, outer * 0.22) * step(outer * 0.05, r);
	v = max(v, crosshair * cross_len * max(step(abs(p.x), px * 0.7), step(abs(p.y), px * 0.7)));
	// Scan sweep: trailing wedge behind a moving edge.
	float sa = fract(an - u_time * 0.45);
	float wedge = (1.0 - sa / 0.18) * step(sa, 0.18) * step(r, outer);
	float scan_v = scan * wedge * 0.45;
	// Faint area fill, stronger toward the rim.
	float fill_v = fill * step(r, outer) * (0.5 + 0.5 * r / outer);

	float pulse_m = 1.0 - pulse * 0.3 * (0.5 + 0.5 * sin(u_time * 9.0));
	float line_v = v * pulse_m;
	float area_v = quant_d(max(scan_v, fill_v), 4.0, FRAGCOORD.xy);
	float a = max(quant(line_v, 3.0), area_v) * alpha;
	if (a <= 0.001) discard;
	vec3 rgb = mix(color.rgb, vec3(1.0, 0.9, 0.85), 0.45 * step(0.9, line_v));
	COLOR = vec4(rgb, a * color.a);
}
