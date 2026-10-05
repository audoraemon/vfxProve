// Solar column: a wide pillar of sunfire standing on an iso ellipse. UV.x across, UV.y down (0 = the sky).
// The quad reaches `foot` of its height below the ellipse's centre line, and the pillar ends on the ellipse's near arc.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec2 size_px = vec2(200.0, 600.0);
// 0..1: how far the pillar has opened, from a needle to its whole width.
uniform float intensity = 1.0;
uniform float foot = 0.08;
// How fast the fire pours down.
uniform float flow = 3.0;
uniform float seed = 0.0;

void fragment() {
	if (intensity <= 0.001) discard;
	float x = (UV.x - 0.5) * 2.0;
	float w = clamp(intensity, 0.03, 1.0);
	vec2 px = UV * size_px;
	float d = abs(x) / w;
	// The foot: the near half of the ground ellipse.
	float base = 1.0 - foot;
	if (UV.y > base) {
		float fy = (UV.y - base) / foot;
		if (fy > sqrt(max(1.0 - d * d, 0.0))) discard;
	}
	// A ragged, pouring edge.
	float edge = fbm(vec2(x * 3.0 + seed, px.y * 0.03 - u_time * flow * 1.4)) - 0.5;
	d += edge * 0.2 * (0.35 + 0.65 * d);
	if (d >= 1.0) discard;

	float v = pow(1.0 - d, 0.45);
	// Sheets of fire falling through the body, fine grain over broad.
	float sheet = fbm(vec2(x * 8.0 + seed * 3.1, px.y * 0.018 - u_time * flow * 3.0));
	float grain = vnoise(vec2(x * 24.0 + seed, px.y * 0.07 - u_time * flow * 6.0));
	v *= 0.66 + 0.4 * sheet + 0.12 * grain;
	// The white-hot core never breaks up.
	v = max(v, smoothstep(0.6, 0.2, d) * (0.92 + 0.08 * grain));
	v *= 1.0 - 0.07 * step(0.7, hash21(vec2(floor(u_time * 24.0), 4.2)));
	// Out of the sky: nothing at the very top, whole a little way down.
	v *= smoothstep(0.0, 0.22, UV.y);
	v *= 0.5 + 0.5 * intensity;
	float q = quant_d(v, 5.0, FRAGCOORD.xy);
	if (q <= 0.0) discard;
	COLOR = ramp5(q);
}
