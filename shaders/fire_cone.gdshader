// Dragon breath cone on the ground plane. The swept sector from `start` through `sweep` radians burns:
// the leading edge (just swept) is a roaring white-yellow flame front, the area behind cools to
// flickering orange, then embers and charred ground. Quad: 2R x 2R ground units centered on the dragon.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float start = 0.0;
uniform float sweep = 0.0;
uniform float inner = 0.12;
uniform float heat = 1.0;
uniform float fade = 1.0;
uniform float seed = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float rel = mod(ang - start + TAU * 4.0, TAU);
	if (rel > sweep + 0.12 || r < inner) discard;
	// Ragged outer edge licking in and out.
	float edge = 0.92 + (fbm(vec2(ang * 5.0 + seed, u_time * 2.5)) - 0.5) * 0.22;
	if (r > edge) discard;
	float behind = max(sweep - rel, 0.0);
	float front = 1.0 - smoothstep(0.0, 0.5, behind);
	float lick = smoothstep(sweep + 0.12, sweep - 0.02, rel);
	float flames = fbm(vec2(r * 7.0 - u_time * 5.0 + seed, ang * 9.0 + u_time * 0.8));
	float tongues = fbm(vec2(r * 14.0 - u_time * 8.0, ang * 20.0 + seed));
	float v = (0.35 + 0.75 * flames + 0.25 * tongues) * (0.25 + 0.95 * front) * lick;
	v *= smoothstep(inner, inner + 0.12, r) * (1.0 - smoothstep(edge - 0.12, edge, r) * 0.5);
	v *= heat;
	float q = quant_d(clamp(v, 0.0, 1.0), 5.0, FRAGCOORD.xy);
	vec4 col;
	if (q > 0.0) {
		col = ramp5(q);
	} else {
		// Charred ground with ember specks behind the flame front.
		float ember = step(0.93, hash21(floor(FRAGCOORD.xy * 0.5) + floor(u_time * 6.0 + seed)));
		col = vec4(mix(vec3(0.08, 0.04, 0.03), vec3(1.0, 0.5, 0.15), ember), 0.75 * lick);
	}
	col.a *= fade;
	if (col.a <= 0.01) discard;
	COLOR = col;
}
