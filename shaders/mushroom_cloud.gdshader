// Nuclear mushroom cloud: billowing toroidal cap on a turbulent stem, lit from the upper left,
// fire glowing through the underside and core while hot, cooling to grey smoke.
// A brief condensation ring (Wilson cloud) can wrap the stem.
// Quad: size_px, anchored bottom-center on the ground point; p.y is height above ground.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec2 size_px = vec2(280.0, 240.0);
uniform float rise = 60.0;
uniform float cap_rx = 50.0;
uniform float cap_ry = 22.0;
uniform float stem_w = 10.0;
uniform float base_w = 26.0;
// Low dust skirt on the ground (half width px); 0 disables.
uniform float skirt_rx = 0.0;
uniform float heat = 1.0;
uniform float fade = 1.0;
uniform float ring = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * size_px.x, (1.0 - UV.y) * size_px.y);
	float t = u_time;
	float density = 0.0;
	float tex = 0.0;
	float light = 0.0;
	float glow = 0.0;

	// Cap: flattened, lobed ellipsoid rolling outward over its top.
	vec2 d = vec2(p.x / cap_rx, (p.y - rise) / cap_ry);
	float a = atan(d.y, d.x);
	// Flatter underside, taller domed top.
	float under = d.y < 0.0 ? 1.4 : 0.72;
	float rc = length(vec2(d.x, d.y * under));
	// Billowy lobes, gentler over the crown so the top stays rounded.
	float crown = smoothstep(0.3, 1.0, sin(a));
	float lobes = ((fbm(vec2(a * 2.2 + seed, t * 0.25)) - 0.5) * 0.45 + 0.07 * sin(a * 7.0 + t * 0.6 + seed)) * (1.0 - 0.6 * crown);
	float cap_edge = 1.0 + lobes;
	if (rc < cap_edge) {
		// Dithered soft silhouette instead of a hard cut.
		density = rc > cap_edge - 0.08 ? step(0.5, bayer4(FRAGCOORD.xy)) : 1.0;
		// Cartesian texture space (polar coordinates pinch into a web at the center),
		// drifting outward and up so the cap appears to roll.
		vec2 cq = vec2(d.x * 2.6 * (1.0 - 0.08 * sin(t * 0.5)), d.y * 4.0 - t * 0.35) + vec2(seed);
		float roll = fbm(cq * 1.3 + vec2(-d.x * t * 0.15, 0.0));
		float edge = cell_edge(cq, t * 0.4);
		float puffs = smoothstep(0.0, 0.45, edge);
		// Soft, broken creases between billows (cauliflower read without a tile pattern).
		float crease = (1.0 - smoothstep(0.0, 0.1, edge)) * smoothstep(0.35, 0.65, vnoise(cq * 1.7 + 4.0));
		tex = roll * 0.72 + puffs * 0.28 - crease * 0.12;
		vec3 n = normalize(vec3(d.x, d.y * under, sqrt(max(1.0 - rc * rc, 0.0)) + 0.25));
		light = clamp(dot(n, normalize(vec3(-0.5, 0.7, 0.6))), 0.0, 1.0);
		// Underside sits in its own shadow once the fire dies.
		light *= d.y < 0.0 ? mix(0.45, 1.0, clamp(heat, 0.0, 1.0)) : 1.0;
		glow = heat * (smoothstep(0.4, -0.9, d.y) * 0.8 + (1.0 - rc) * 0.45) * (0.5 + 0.65 * tex);
	}

	// Stem: turbulent column rising into the cap, flaring into a skirt at the ground.
	if (density <= 0.0 && p.y >= 0.0 && p.y <= rise) {
		float k = p.y / max(rise, 1.0);
		float w = mix(base_w, stem_w, smoothstep(0.0, 0.35, k));
		w += (fbm(vec2(p.y * 0.06 - t * 0.8, seed)) - 0.5) * w * 0.45;
		w += base_w * 0.35 * exp(-p.y / 6.0);
		// Neck: the stem flares as it feeds into the cap's underside.
		float below_cap = (rise - cap_ry * 0.6) - p.y;
		w += stem_w * 1.3 * exp(-max(below_cap, 0.0) / 9.0);
		if (abs(p.x) < w) {
			density = 1.0;
			float sx = p.x / w;
			tex = fbm(vec2(sx * 2.0 + seed, p.y * 0.07 - t * 1.3));
			// Vertical churning streaks.
			tex = tex * 0.7 + vnoise(vec2(sx * 6.0 + seed, p.y * 0.03 - t * 1.6)) * 0.4 - 0.1;
			light = clamp(0.6 - sx * 0.55, 0.0, 1.0);
			glow = heat * (0.35 + 0.9 * tex) * (1.0 - abs(sx) * 0.6) * (0.55 + 0.45 * (1.0 - k));
		}
	}

	// Low dust skirt rolling outward along the ground around the foot.
	if (density <= 0.0 && skirt_rx > 1.0) {
		vec2 sd = vec2(p.x / skirt_rx, (p.y - skirt_rx * 0.12) / (skirt_rx * 0.26));
		float srr = length(sd) + (fbm(vec2(atan(sd.y, sd.x) * 2.5 + seed, t * 0.3)) - 0.5) * 0.4;
		if (srr < 1.0) {
			density = srr > 0.82 ? step(bayer4(FRAGCOORD.xy), (1.0 - srr) / 0.18) : 1.0;
			// Rolling billows churning outward.
			vec2 sq2 = vec2(sd.x * 4.0 - t * 0.25 * sign(sd.x), sd.y * 3.0) + seed;
			float billow = smoothstep(0.0, 0.4, cell_edge(sq2, t * 0.3));
			tex = fbm(sq2) * 0.6 + billow * 0.4 - 0.2;
			light = clamp(0.35 + sd.y * 0.45 - sd.x * 0.15, 0.0, 1.0);
			glow = heat * 0.45 * (1.0 - srr) * (0.5 + tex);
		}
	}

	// Condensation ring hanging around the stem.
	float ring_v = 0.0;
	if (ring > 0.0) {
		vec2 rd = vec2(p.x / (cap_rx * 1.3), (p.y - rise * 0.55) / (cap_ry * 0.45));
		float band = abs(length(rd) - 1.0);
		ring_v = (1.0 - smoothstep(0.0, 0.2, band)) * ring;
		ring_v *= 0.5 + 0.5 * vnoise(vec2(atan(rd.y, rd.x) * 6.0 + seed, t));
		// The back half of the ring hides behind the stem.
		if (density > 0.0 && rd.y > 0.0) ring_v = 0.0;
	}
	if (density <= 0.0 && ring_v <= 0.02) discard;

	vec3 col;
	float alpha = fade;
	float ring_q = quant_d(ring_v, 3.0, FRAGCOORD.xy);
	if (density > 0.0 && ring_q <= 0.0) {
		float shade = light * 0.6 + tex * 0.6 - 0.1;
		float sq = quant_d(shade, 5.0, FRAGCOORD.xy);
		vec3 smoke = mix(vec3(0.09, 0.085, 0.095), vec3(0.5, 0.45, 0.42), sq);
		smoke = mix(smoke, smoke * vec3(1.3, 0.78, 0.55), clamp(heat, 0.0, 1.0) * 0.5);
		float gq = quant_d(glow, 5.0, FRAGCOORD.xy);
		col = (glow > 0.28 && gq > 0.0) ? ramp5(gq).rgb : smoke;
	} else {
		col = vec3(0.86, 0.86, 0.9);
		alpha *= ring_q;
	}
	COLOR = vec4(col, alpha);
}
