// Dragon breath jet: a thick turbulent stream of fire from the mouth (UV.x = 0) to where it hits the
// ground (UV.x = 1). Widens along its length, white-hot core, orange body, red ragged edges that tear
// into licks, dark smoke fringe near the end. Quad anchored at its left-middle and rotated along the jet.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float length_px = 200.0;
uniform float width_px = 48.0;
uniform float fade = 1.0;
uniform float seed = 0.0;

void fragment() {
	float x = UV.x;
	float y = (UV.y - 0.5) * 2.0;
	float t = u_time;
	// Pixel-space coordinates scrolling toward the target so the fire rushes forward.
	vec2 p = vec2(x * length_px, y * width_px * 0.5);
	vec2 flow = vec2(p.x - t * 260.0 + seed, p.y);
	float turb = fbm(flow * vec2(0.035, 0.09));
	float lick = fbm(flow * vec2(0.08, 0.2) + 3.1);
	// Width profile: narrow at the mouth, billowing wider toward the end, wobbling.
	float w = mix(0.18, 1.0, pow(x, 0.6)) * (0.8 + 0.35 * turb);
	float wob = (vnoise(vec2(p.x * 0.02 - t * 3.0, seed)) - 0.5) * 0.25 * x;
	float d = abs(y - wob) / max(w, 0.001);
	float edge = 1.0 - smoothstep(0.55 + 0.45 * lick, 1.0, d);
	if (edge <= 0.0) discard;
	float v = (1.0 - d * 0.85) * (0.7 + 0.5 * turb) + lick * 0.15;
	// Hot near the mouth, cooling toward the far end; fade in at the lips.
	v *= mix(1.25, 0.8, x);
	v *= smoothstep(0.0, 0.05, x);
	float q = quant_d(clamp(v, 0.0, 1.0), 5.0, FRAGCOORD.xy);
	vec4 col = ramp5(max(q, 0.2));
	// Smoke fringe on the outer edge of the far half.
	float smoke = step(d, 1.0) * step(0.8, d) * smoothstep(0.5, 0.9, x) * step(0.5, turb);
	col = mix(col, vec4(0.16, 0.1, 0.09, 0.8), smoke);
	col.a *= edge > 0.35 ? 1.0 : step(0.5, hash21(floor(FRAGCOORD.xy * 0.5) + floor(t * 12.0)));
	col.a *= fade;
	if (col.a <= 0.01) discard;
	COLOR = col;
}
