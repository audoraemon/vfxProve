// Nuclear fireball: a boiling hemisphere on the ground, projected for the 2:1 iso camera
// (30 degree elevation, orthographic).
// Surface is a temperature field, not decoration: warped 3D cellular billows (cauliflower puffs,
// hot centers, sooty creases) churn outward and upward; a white-hot core burns low in the middle;
// the limb is denser and smokier; as `heat` drops, dark smoke creeps in from the creases.
// A fire ring burns on the ground around the base.
// Quad: width 2R*width_ratio, height R*(dome_ratio + base_ratio); anchor at the ground center.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float grow = 1.0;
uniform float heat = 1.0;
uniform float dissolve = 0.0;
uniform float dome_ratio = 1.0;
uniform float base_ratio = 0.62;
uniform float width_ratio = 1.16;
// Billow strength (0 = smooth fireball).
uniform float pattern = 1.0;
// Billow count multiplier: raise for big fireballs so puffs stay a similar pixel size.
uniform float detail = 1.0;
// Extra smoke coverage (0..1) on top of natural cooling.
uniform float soot = 0.0;
uniform float seed = 0.0;
uniform vec4 smoke_hot : source_color = vec4(0.22, 0.1, 0.06, 1.0);
uniform vec4 smoke_cold : source_color = vec4(0.1, 0.085, 0.08, 1.0);

const float SIN_E = 0.5;
const float COS_E = 0.8660254;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1, 0, 0));
	float n010 = hash31(i + vec3(0, 1, 0));
	float n110 = hash31(i + vec3(1, 1, 0));
	float n001 = hash31(i + vec3(0, 0, 1));
	float n101 = hash31(i + vec3(1, 0, 1));
	float n011 = hash31(i + vec3(0, 1, 1));
	float n111 = hash31(i + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float fbm3(vec3 p) {
	return vnoise3(p) * 0.55 + vnoise3(p * 2.1 + 3.1) * 0.3 + vnoise3(p * 4.3 + 7.7) * 0.15;
}

// Nearest-feature distance of animated 3D cells: small at a puff's center.
float cells3(vec3 p, float t) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d1 = 8.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 g = vec3(float(x), float(y), float(z));
				vec3 o = hash33(i + g);
				o = 0.5 + 0.38 * sin(t * 0.9 + 6.2831 * o);
				vec3 r = g + o - f;
				d1 = min(d1, dot(r, r));
			}
		}
	}
	return sqrt(d1);
}

void fragment() {
	float s = max(grow, 0.001);
	float sx = (UV.x - 0.5) * 2.0 * width_ratio / s;
	float sy = (UV.y * (dome_ratio + base_ratio) - dome_ratio) / s;
	float t = u_time;

	// Lumpy silhouette: puffs push the outline in and out.
	float lump = (fbm(vec2(sx * 1.7 + seed, sy * 1.7 - t * 0.7)) - 0.5) + (vnoise(vec2(sx * 5.0, sy * 5.0 - t * 1.2) + seed) - 0.5) * 0.35;
	float disc = 1.0 + lump * 0.5 - sx * sx - sy * sy;
	float depth = sqrt(max(disc, 0.0));
	vec3 P = vec3(sx, -sy * COS_E + depth * SIN_E, sy * SIN_E + depth * COS_E);
	bool on_ball = disc > 0.0 && P.y >= -0.02;

	float gz = sy / SIN_E;
	float ground_r = length(vec2(sx, gz));

	if (!on_ball) {
		// Fire ring on the ground just outside the fireball's footprint.
		float ring = 1.0 - smoothstep(0.0, 0.16, abs(ground_r - 1.04 - lump * 0.1));
		ring *= step(0.0, sy + 0.05);
		float flick = fbm(vec2(atan(gz, sx) * 4.0 + seed, t * 2.0));
		float rv = ring * (0.5 + 0.6 * flick) * heat * (1.0 - dissolve);
		float rq = quant_d(rv, 5.0, FRAGCOORD.xy);
		if (rq <= 0.0) discard;
		COLOR = ramp5(rq);
	} else {
		vec3 n = normalize(P);
		float facing = clamp(depth, 0.0, 1.0);

		// Surface flow: billows expand outward and roll upward.
		vec3 q = n * 2.1 * detail * (1.0 - 0.12 * sin(t * 0.3)) + vec3(0.0, -t * 0.55, 0.0) + vec3(seed);
		vec3 warp = vec3(fbm3(q + 1.7), fbm3(q + 9.2), fbm3(q + 4.1)) - 0.5;
		vec3 qw = q + warp * 0.7;

		// Cauliflower: bright puff centers, dark creases, two scales.
		float d_big = cells3(qw * 1.6, t);
		float d_small = cells3(qw * 3.4 + 5.0, t * 1.4);
		float big = 1.0 - smoothstep(0.05, 0.7, d_big);
		float small = 1.0 - smoothstep(0.0, 0.6, d_small);
		// Deep creases where puffs press together: soot shows through.
		float crease = smoothstep(0.62, 0.9, d_big) * 0.7 + smoothstep(0.55, 0.8, d_small) * 0.3;
		float billow = mix(0.5, big * 0.7 + small * 0.3 - crease * 0.55, pattern);
		float churn = fbm3(qw * 2.3 - vec3(0.0, t * 0.4, 0.0));

		// Temperature: white-hot core low in the middle, cooler smoky limb.
		float lat = asin(clamp(n.y, 0.0, 1.0));
		float core = exp(-(n.x * n.x * 2.2 + lat * lat * 2.6)) * facing;
		float temp = 0.18 + 0.62 * core + 0.55 * billow + 0.22 * churn;
		temp *= mix(0.62, 1.0, smoothstep(0.0, 0.45, facing));
		temp -= soot * smoothstep(0.35, 0.7, churn + (0.5 - billow) * 0.8) * 0.5;
		temp *= heat;

		float burn = fbm3(qw * 1.8 + 11.0);
		if (burn < dissolve * 1.15 - 0.12 + (1.0 - facing) * dissolve * 0.3) discard;

		// Heat bands (dithered) -> fire ramp; below the fire range it's smoke.
		float tq = quant_d(clamp(temp, 0.0, 1.2) / 1.2, 7.0, FRAGCOORD.xy);
		vec3 col;
		if (tq >= 6.0 / 7.0) col = c4.rgb;
		else if (tq >= 5.0 / 7.0) col = c3.rgb;
		else if (tq >= 4.0 / 7.0) col = c2.rgb;
		else if (tq >= 3.0 / 7.0) col = c1.rgb;
		else if (tq >= 2.0 / 7.0) col = mix(c0.rgb, smoke_hot.rgb, 0.35);
		else if (tq >= 1.0 / 7.0) col = smoke_hot.rgb;
		else col = smoke_cold.rgb;
		// Smoke catches a little fire light from below.
		col += smoke_hot.rgb * 0.15 * (1.0 - n.y) * step(tq, 2.0 / 7.0) * heat;
		COLOR = vec4(col, 1.0);
	}
}
