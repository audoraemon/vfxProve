// Tornado funnel volume, modelled on the concept: a dense silver funnel built from stacked horizontal wind
// ribbons that wrap around it. The quad stands on the ground (bottom margin `base_margin` px below the ground
// point); every pixel row is a slice of a trumpet-shaped cone. Front ribbons bow down across the front, the
// back ribbons show through the gaps between them, bright white streaks race around each ribbon, the rim
// glows, warm dust light fills the base and a wide spiral cloud cap swirls on top.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform vec2 size = vec2(400.0, 400.0);
uniform float base_margin = 30.0;
uniform float height_px = 300.0;
uniform float base_r = 16.0;
uniform float top_r = 150.0;
uniform float grow = 1.0;
uniform float fade = 1.0;
uniform float lean = 0.0;
uniform float spin = 1.0;
uniform vec4 white : source_color = vec4(0.97, 0.98, 1.0, 1.0);
uniform vec4 light_col : source_color = vec4(0.8, 0.83, 0.88, 1.0);
uniform vec4 haze_col : source_color = vec4(0.58, 0.62, 0.68, 1.0);
uniform vec4 dark_col : source_color = vec4(0.32, 0.34, 0.4, 1.0);
uniform vec4 warm_col : source_color = vec4(1.0, 0.82, 0.52, 1.0);

float center_x(float k, float t) {
	return sin(t * 1.3 + k * 2.4) * 8.0 * k + lean * k * k;
}

float radius(float k) {
	return mix(base_r, top_r, pow(clamp(k, 0.0, 1.2), 1.35)) * mix(0.35, 1.0, grow);
}

vec3 ramp(float v) {
	if (v < 0.36) return dark_col.rgb;
	if (v < 0.56) return haze_col.rgb;
	if (v < 0.8) return light_col.rgb;
	return white.rgb;
}

// Ribbon field at screen height y for a point on the funnel surface at angle a (front: a in -pi/2..pi/2).
// Returns (inside ribbon 0/1, position across the ribbon 0..1, ribbon index). Ribbons are thin streaks that wrap
// around the funnel on ellipses (bowing down across the front), drift along with the spin and taper to points.
vec3 ribbons(float y, float a, float r, float t) {
	float ry = r * 0.3;
	float spacing = mix(8.0, 15.0, clamp(r / max(top_r, 1.0), 0.0, 1.0));
	float phase = (y + ry * cos(a)) / spacing + a / TAU * 0.6 + t * spin * 0.25;
	phase += (fbm(vec2(a * 1.1 + t * spin * 0.6, y * 0.03)) - 0.5) * 0.5;
	float idx = floor(phase);
	float band = fract(phase);
	float along = fbm(vec2(a * 1.8 - t * spin * 1.6 + idx * 2.3, idx * 0.61));
	float taper = smoothstep(0.36, 0.6, along);
	float thick = (0.3 + 0.25 * hash21(vec2(idx, 3.1))) * taper;
	float cover = step(abs(band - 0.5), thick * 0.5);
	return vec3(cover, clamp((band - 0.5) / max(thick, 0.001) + 0.5, 0.0, 1.0), idx);
}

void fragment() {
	float t = u_time;
	vec2 P = vec2((UV.x - 0.5) * size.x, (1.0 - UV.y) * size.y - base_margin);
	float h = height_px * grow;
	float k = P.y / max(h, 1.0);
	vec4 col = vec4(0.0);

	if (k > -0.02 && k < 1.02) {
		float r = radius(k);
		float u = (P.x - center_x(k, t)) / r;
		// Ragged silhouette where ribbon ends flare out.
		float edge_n = (fbm(vec2(k * 14.0 - t * 2.2, sign(u) * 3.0)) - 0.5) * 0.22;
		if (abs(u) < 1.0 + edge_n) {
			float uc = clamp(u, -0.999, 0.999);
			float af = asin(uc);
			vec3 front = ribbons(P.y, af, r, t);
			vec3 back = ribbons(P.y, 3.14159 - af, r, t);
			float rim = 1.0 - sqrt(max(1.0 - uc * uc, 0.0));
			// Translucent silver body: lighter toward the rim and the top, churning darker streaks inside.
			float churn = fbm(vec2(af * 2.0 - t * spin * 1.2, P.y * 0.05));
			float lum = 0.44 + 0.22 * rim + 0.1 * k + (churn - 0.5) * 0.24;
			float a = 0.86 + 0.12 * rim;
			if (back.x > 0.5) {
				lum = max(lum, 0.6 + 0.1 * (1.0 - back.y));
			}
			if (front.x > 0.5) {
				// Front ribbon: white core, pale edges.
				lum = 0.74 + 0.3 * (1.0 - abs(front.y - 0.45) * 2.0);
				a = 1.0;
			}
			// Warm dust light at the base.
			float warm = 1.0 - smoothstep(0.0, 0.42, k);
			vec3 c = ramp(quant(clamp(lum, 0.0, 1.0), 8.0));
			c = mix(c, warm_col.rgb, warm * 0.75);
			a = max(a, warm);
			a *= smoothstep(1.0 + edge_n, 0.86 + edge_n, abs(u));
			col = vec4(c, a);
		}
	}

	// Spiral cloud cap on top.
	vec2 cap_c = vec2(center_x(1.0, t), h);
	float rx = radius(1.0) * 1.35;
	vec2 d = (P - cap_c) / vec2(rx, rx * 0.3);
	float rr = length(d);
	if (rr < 1.0) {
		float ang = atan(d.y, d.x);
		float arms = fract(ang / TAU * 2.0 + log(rr + 0.08) * 0.9 - t * spin * 0.35 + fbm(d * 3.0 + t * 0.2) * 0.4);
		float arm = smoothstep(0.0, 0.12, arms) * smoothstep(0.5, 0.2, arms);
		float a = (0.55 + arm * 0.45) * (1.0 - smoothstep(0.6, 1.0, rr));
		float lum = 0.4 + arm * 0.55;
		vec3 c = ramp(quant(lum, 8.0));
		float qa = a;
		// Front half of the cap covers the funnel top, the back half sits behind it.
		if (d.y < 0.0 || col.a < qa) {
			col = vec4(mix(col.rgb, c, qa), max(col.a, qa));
		}
	}
	col.a *= fade;
	if (col.a <= 0.02) discard;
	COLOR = col;
}
