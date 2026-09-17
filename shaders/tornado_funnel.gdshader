// Tornado funnel volume. The quad stands on the ground (bottom margin `base_margin` px below the ground
// point). Each pixel row is a horizontal slice of a cone: soft spiral wind streaks wrap the front and back
// surfaces (back dimmer), streaks bunch up and glow along the silhouette edges, a dusty haze fills the body,
// warm light glows at the base and a wide spiral cloud cap swirls on top.
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
uniform vec4 streak_col : source_color = vec4(0.96, 0.98, 1.0, 1.0);
uniform vec4 haze_col : source_color = vec4(0.62, 0.68, 0.78, 1.0);
uniform vec4 dark_col : source_color = vec4(0.36, 0.39, 0.46, 1.0);
uniform vec4 warm_col : source_color = vec4(1.0, 0.86, 0.6, 1.0);

float center_x(float k, float t) {
	return sin(t * 1.3 + k * 2.4) * 8.0 * k + lean * k * k;
}

float radius(float k) {
	return mix(base_r, top_r, pow(clamp(k, 0.0, 1.2), 1.4)) * mix(0.35, 1.0, grow);
}

// Soft spiral streak bands at surface angle a (radians) and height k.
float streaks(float a, float k, float t) {
	float n = fbm(vec2(a * 1.5, k * 9.0 - t * 0.7));
	float s = fract(a / TAU * 3.0 + k * 2.6 - t * spin * 0.9 + n * 0.6);
	float band = smoothstep(0.0, 0.1, s) * smoothstep(0.45, 0.15, s);
	float fine = step(0.72, fbm(vec2(a * 5.0 - t * spin * 3.0, k * 30.0)));
	return clamp(band * 0.85 + fine * 0.45, 0.0, 1.0);
}

void fragment() {
	float t = u_time;
	vec2 P = vec2((UV.x - 0.5) * size.x, (1.0 - UV.y) * size.y - base_margin);
	float h = height_px * grow;
	float k = P.y / max(h, 1.0);
	vec4 col = vec4(0.0);

	// Funnel body.
	if (k > -0.02 && k < 1.02) {
		float r = radius(k);
		float u = (P.x - center_x(k, t)) / r;
		// Ragged silhouette.
		float edge_n = (fbm(vec2(k * 12.0 - t * 2.0, sign(u) * 3.0)) - 0.5) * 0.25;
		if (abs(u) < 1.0 + edge_n) {
			float uc = clamp(u, -0.999, 0.999);
			float af = asin(uc);
			float front = streaks(af, k, t);
			float back = streaks(PI - af, k, t) * 0.45;
			float rim = clamp(0.35 / sqrt(max(1.0 - uc * uc, 0.04)), 0.0, 1.6);
			float body = clamp(0.42 + 0.25 * rim, 0.0, 0.85);
			float bright = max(front * (0.65 + 0.35 * rim), back);
			float a = clamp(body + bright * 0.6, 0.0, 0.95) * smoothstep(1.0 + edge_n, 0.85 + edge_n, abs(u));
			float lum = clamp(0.3 + bright * 0.8 - (1.0 - rim) * 0.1, 0.0, 1.0);
			float q = quant_d(lum, 4.0, FRAGCOORD.xy);
			vec3 c = q < 0.3 ? dark_col.rgb : (q < 0.6 ? haze_col.rgb : (q < 0.85 ? mix(haze_col.rgb, streak_col.rgb, 0.6) : streak_col.rgb));
			// Warm glow and dust at the base.
			float warm = (1.0 - smoothstep(0.0, 0.22, k));
			c = mix(c, warm_col.rgb, warm * 0.55);
			a = max(a, warm * 0.6 * (1.0 - abs(uc)));
			col = vec4(c, quant_d(a, 4.0, FRAGCOORD.xy + 1.0));
		}
	}

	// Spiral cloud cap on top.
	vec2 cap_c = vec2(center_x(1.0, t), h);
	float rx = radius(1.0) * 1.4;
	vec2 d = (P - cap_c) / vec2(rx, rx * 0.32);
	float rr = length(d);
	if (rr < 1.0) {
		float ang = atan(d.y, d.x);
		float arms = fract(ang / TAU * 2.0 + log(rr + 0.08) * 0.9 - t * spin * 0.35 + fbm(d * 3.0 + t * 0.2) * 0.4);
		float arm = smoothstep(0.0, 0.12, arms) * smoothstep(0.5, 0.2, arms);
		float a = (0.35 + arm * 0.65) * (1.0 - smoothstep(0.55, 1.0, rr));
		float lum = 0.35 + arm * 0.6;
		float q = quant_d(lum, 4.0, FRAGCOORD.xy);
		vec3 c = q < 0.4 ? haze_col.rgb : (q < 0.8 ? mix(haze_col.rgb, streak_col.rgb, 0.6) : streak_col.rgb);
		float qa = quant_d(a, 4.0, FRAGCOORD.xy + 1.0);
		// Front half of the cap covers the funnel top, the back half sits behind it.
		if (d.y < 0.0 || col.a < qa) {
			col = vec4(mix(col.rgb, c, qa), max(col.a, qa));
		}
	}
	col.a *= fade;
	if (col.a <= 0.02) discard;
	COLOR = col;
}
