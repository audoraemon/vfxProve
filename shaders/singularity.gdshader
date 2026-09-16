// Gravity singularity: swirls and pinches whatever is already on screen inside an iso ellipse,
// tints it violet, adds flattened accretion arms and a hovering black core with a bright rim.
// Quad: 2A x 2B screen px centered on the ground point.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 size_px = vec2(400.0, 200.0);
uniform float strength = 0.0;
uniform float pinch = 0.0;
uniform float core_px = 0.0;
uniform float arm_alpha = 0.0;
uniform float tint = 0.6;
uniform float rim_boost = 0.0;
uniform float alpha = 1.0;

vec2 rot(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0) discard;
	float fall = (1.0 - r) * (1.0 - r);

	// Screen-space lensing.
	vec2 q = rot(p, strength * fall + sin(u_time * 3.0 + r * 8.0) * 0.03 * strength);
	q *= 1.0 + pinch * (1.0 - r);
	vec2 offset_px = (q - p) * size_px * 0.5;
	vec3 col = texture(screen_tex, SCREEN_UV + offset_px * SCREEN_PIXEL_SIZE).rgb;
	float t = tint * fall * alpha;
	col = mix(col, col * vec3(0.55, 0.35, 0.9) + vec3(0.12, 0.02, 0.22), quant(t, 4.0));

	// Accretion arms (flattened with the ellipse): thin, broken streaks.
	float an = atan(p.y, p.x) / TAU;
	float arm = fract(an * 3.0 - r * 3.5 + u_time * (0.6 + strength * 0.25));
	float breakup = vnoise(vec2(an * 48.0 + r * 6.0, r * 22.0 - u_time * 5.0));
	float band = step(0.88, arm) * step(0.5, breakup) * step(0.1, r) * step(r, 0.8);
	float arm_v = band * (1.0 - r / 0.8) * arm_alpha * 1.4;
	float aq = quant(arm_v, 3.0);
	if (aq > 0.0) {
		col = mix(col, aq > 0.6 ? c3.rgb : (aq > 0.3 ? c2.rgb : c1.rgb), 0.8);
	}
	// Sparse orbiting sparks.
	float spark = step(0.993, hash21(floor(vec2(an * 360.0 + u_time * 8.0 * (1.2 - r), r * 70.0))));
	col = mix(col, c4.rgb, spark * arm_alpha * step(0.15, r) * step(r, 0.9));

	// Hovering core sphere (round in screen space), raised above the ground point.
	vec2 pc = (UV - 0.5) * size_px;
	float cr = max(core_px, 0.001);
	float d = length(pc - vec2(0.0, -cr * 1.1)) / cr;
	float out_a = alpha;
	if (core_px > 0.5) {
		float wob = (vnoise(vec2(atan(pc.y + cr * 1.1, pc.x) * 3.0, u_time * 6.0)) - 0.5) * 0.25;
		if (d < 1.0) {
			col = vec3(0.02, 0.0, 0.05);
			// Faint inner speck.
			col += c2.rgb * step(0.97, hash21(floor(pc) + floor(u_time * 8.0))) * 0.6;
		} else if (d < 1.28 + wob + rim_boost * 0.3) {
			col = mix(c3.rgb, c4.rgb, step(d, 1.12));
		} else if (d < 1.9 + rim_boost * 0.5) {
			float g = quant_d((1.9 + rim_boost * 0.5 - d) / 0.7, 2.0, FRAGCOORD.xy);
			col = mix(col, c2.rgb, g * 0.7);
		}
	}
	COLOR = vec4(col, out_a);
}
