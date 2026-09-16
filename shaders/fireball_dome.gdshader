// Fireball / plasma dome: a true hemisphere on the ground, projected for the 2:1 iso camera
// (30 degree elevation, orthographic). Every pixel finds its real 3D surface point, so the
// surface pattern wraps the whole visible dome: boiling plasma veins, meridians meeting at the
// top, pulses climbing the surface, a hot core low at the front and a bright rim.
// A fire ring burns on the ground around the base.
// Quad: width 2R*width_ratio, height R*(dome_ratio + base_ratio); anchor at the ground center.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float grow = 1.0;
uniform float heat = 1.0;
uniform float dissolve = 0.0;
// Screen height above the base center covered by the quad, in radii (dome top is cos(30deg) = 0.866).
uniform float dome_ratio = 1.0;
// Screen depth below the center covered by the quad (front of base circle is 0.5; extra for the fire ring).
uniform float base_ratio = 0.62;
// Half-width of the quad in radii (a little over 1 so the ground fire ring fits).
uniform float width_ratio = 1.16;
uniform float pattern = 1.0;
uniform float soot = 0.0;
uniform float seed = 0.0;

const float SIN_E = 0.5;
const float COS_E = 0.8660254;

void fragment() {
	float s = max(grow, 0.001);
	// Screen coordinates in dome radii: x right, y down.
	float sx = (UV.x - 0.5) * 2.0 * width_ratio / s;
	float sy = (UV.y * (dome_ratio + base_ratio) - dome_ratio) / s;
	float turb = fbm(vec2(sx * 3.0 + seed, sy * 3.0 + u_time * 1.8));
	float wobble = (turb - 0.5) * 0.12;

	// Ray against the unit sphere: front surface depth toward the camera.
	float disc = 1.0 + wobble * 2.0 - sx * sx - sy * sy;
	// World point on the surface: screen axes e_x=(1,0,0), e_y=(0,-cos,sin), toward camera c=(0,sin,cos).
	float depth = sqrt(max(disc, 0.0));
	vec3 P = vec3(sx, -sy * COS_E + depth * SIN_E, sy * SIN_E + depth * COS_E);
	bool on_dome = disc > 0.0 && P.y >= 0.0;

	// Ground plane under the pixel, for the fire ring around the base.
	float gz = sy / SIN_E;
	float ground_r = length(vec2(sx, gz));

	if (!on_dome) {
		// Fire ring on the ground just outside the dome's footprint.
		float ring = 1.0 - smoothstep(0.0, 0.14 + wobble, abs(ground_r - 1.02));
		ring *= step(0.0, sy + 0.05);
		float flick = fbm(vec2(atan(gz, sx) * 4.0 + seed, u_time * 2.0));
		float rv = ring * (0.55 + 0.6 * flick) * heat * (1.0 - dissolve);
		float rq = quant_d(rv, 5.0, FRAGCOORD.xy);
		if (rq <= 0.0) discard;
		COLOR = ramp5(rq);
	} else {
		float burn = fbm(vec2(P.x * 4.0 + 7.0 + seed, P.y * 4.0 - P.z * 2.0 - u_time * 0.7));
		if (burn < dissolve * 1.1 - 0.1 + (1.0 - depth) * dissolve * 0.3) discard;

		vec3 n = normalize(P);
		float lat = asin(clamp(n.y, 0.0, 1.0));
		float lon = atan(n.x, n.z);
		float facing = clamp(depth, 0.0, 1.0);

		// Hot core low on the front face, bright translucent rim.
		float core = exp(-(n.x * n.x * 3.0 + lat * lat * 4.0)) * facing;
		float rim = pow(1.0 - facing, 2.5);
		float v = 0.36 + 0.42 * core + 0.3 * rim;
		v *= 0.7 + 0.5 * turb;

		// Boiling plasma cells in (longitude, latitude) so they wrap the sphere.
		vec2 sp = vec2(lon * 2.4, lat * 3.0 - u_time * 0.35) + vec2(seed);
		float veins = 1.0 - smoothstep(0.0, 0.1, cell_edge(sp * 1.9, u_time));
		float cell_body = smoothstep(0.35, 0.05, cell_edge(sp * 1.9 + 0.5, u_time * 0.7));
		v += veins * 0.3 * pattern * (0.4 + 0.6 * facing);
		v -= cell_body * 0.08 * pattern;

		// Meridians meeting at the top pole; they thin out near the pole.
		float mer = abs(fract(lon * 7.0 / PI + 0.5) - 0.5);
		float mer_line = (1.0 - smoothstep(0.0, 0.07, mer)) * smoothstep(1.45, 0.9, lat) * facing;
		mer_line *= 0.45 + 0.55 * vnoise(vec2(lon * 9.0, lat * 5.0 - u_time * 2.5));
		// Pulses climbing from the ground to the top.
		float ring_l = abs(fract(lat * 2.4 - u_time * 1.1) - 0.5);
		float ring_line = (1.0 - smoothstep(0.0, 0.05, ring_l)) * smoothstep(0.02, 0.12, lat) * (0.6 + 0.4 * facing);
		float streak = step(0.8, vnoise(vec2(lon * 24.0 + seed, lat * 1.6 - u_time * 3.5)));
		v += (mer_line * 0.3 + ring_line * 0.22 + streak * 0.22) * pattern;

		// Molten contact band where the dome meets the ground.
		v += smoothstep(0.18, 0.0, lat) * 0.3;

		float soot_n = fbm(vec2(n.x * 5.0 + seed * 2.0, n.y * 5.0 + n.z * 3.0 + u_time * 0.4));
		v *= 1.0 - soot * smoothstep(0.45, 0.7, soot_n) * 0.8;
		v *= mix(1.0, 0.72, smoothstep(0.25, 0.0, facing));
		v *= heat;
		float qv = quant_d(v, 5.0, FRAGCOORD.xy);
		if (qv <= 0.0) discard;
		COLOR = ramp5(qv);
	}
}
