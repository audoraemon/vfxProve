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

	// Accretion disk: wispy spiral filaments from noise in a log-spiral frame.
	float an = atan(p.y, p.x) / TAU;
	float spiral = an * 2.0 + log(max(r, 0.02)) * 1.2 - u_time * (0.35 + strength * 0.12);
	float wisp = fbm(vec2(spiral * 5.0, r * 7.0 - u_time * 0.8));
	float disk = smoothstep(0.52, 0.8, wisp) * smoothstep(0.9, 0.2, r) * smoothstep(0.04, 0.16, r);
	float dq = quant_d(disk * arm_alpha * 1.3, 4.0, FRAGCOORD.xy);
	if (dq > 0.0) {
		vec3 dc = dq > 0.74 ? c4.rgb : (dq > 0.49 ? c3.rgb : (dq > 0.24 ? c2.rgb : c1.rgb));
		col = mix(col, dc, 0.35 + 0.5 * dq);
	}
	// Infalling radial filaments: dashed streaks sliding toward the center.
	float lane = floor((an + 0.5) * 150.0);
	float pick = step(0.86, hash21(vec2(lane, 3.7)));
	float dash = step(0.62, fract(r * 5.0 + u_time * (1.2 + strength * 0.5) + hash21(vec2(lane, 9.1))));
	float fil = pick * dash * smoothstep(1.0, 0.55, r) * step(0.12, r) * arm_alpha;
	col = mix(col, c3.rgb, quant(fil * 0.75, 2.0));
	// Sparse orbiting sparks.
	float spark = step(0.994, hash21(floor(vec2(an * 360.0 + u_time * 8.0 * (1.2 - r), r * 70.0))));
	col = mix(col, c4.rgb, spark * arm_alpha * step(0.15, r) * step(r, 0.9));

	// Hovering core sphere (round in screen space), raised above the ground point.
	vec2 pc = (UV - 0.5) * size_px;
	float cr = max(core_px, 0.001);
	vec2 cc = pc - vec2(0.0, -cr * 1.1);
	float d = length(cc) / cr;
	float out_a = alpha;
	if (core_px > 0.5) {
		float ca = atan(cc.y, cc.x);
		float wob = (vnoise(vec2(ca * 3.0, u_time * 6.0)) - 0.5) * 0.2;
		if (d < 1.0) {
			col = vec3(0.01, 0.0, 0.03);
			col += c1.rgb * 0.5 * step(0.8, d);
		} else if (d < 1.12) {
			// Photon ring: thin white-hot edge.
			col = c4.rgb;
		} else if (d < 1.32 + wob + rim_boost * 0.25) {
			col = mix(col, c3.rgb, 0.85);
		} else if (d < 2.4 + rim_boost * 0.6) {
			// Lensed halo, brighter on the near (lower) side like a tilted disk.
			float h = (2.4 + rim_boost * 0.6 - d) / 1.1;
			h *= 0.75 + 0.35 * sin(ca);
			float g = quant_d(h, 3.0, FRAGCOORD.xy);
			col = mix(col, c2.rgb, g * 0.75);
		}
	}
	COLOR = vec4(col, out_a);
}
