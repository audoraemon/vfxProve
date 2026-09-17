// Fire dragon skin. Vertex COLOR = (shade 0..1, heat 0..1, material, alpha).
// Materials: 0 scales, 0.25 belly plates, 0.5 wing membrane, 0.75 flat, 1 glow (mouth fire, eyes).
// Shade is perturbed by the material pattern and a living-flame flicker scaled by heat, then quantized
// with dithering into a 7-step ember palette.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float fade = 1.0;
uniform vec4 p0 : source_color = vec4(0.14, 0.03, 0.03, 1.0);
uniform vec4 p1 : source_color = vec4(0.38, 0.07, 0.04, 1.0);
uniform vec4 p2 : source_color = vec4(0.63, 0.15, 0.06, 1.0);
uniform vec4 p3 : source_color = vec4(0.87, 0.3, 0.1, 1.0);
uniform vec4 p4 : source_color = vec4(1.0, 0.53, 0.16, 1.0);
uniform vec4 p5 : source_color = vec4(1.0, 0.76, 0.29, 1.0);
uniform vec4 p6 : source_color = vec4(1.0, 0.95, 0.74, 1.0);

varying vec4 v_col;

void vertex() {
	v_col = COLOR;
}

vec3 pal(float q) {
	int i = int(round(q * 6.0));
	if (i <= 0) return p0.rgb;
	if (i == 1) return p1.rgb;
	if (i == 2) return p2.rgb;
	if (i == 3) return p3.rgb;
	if (i == 4) return p4.rgb;
	if (i == 5) return p5.rgb;
	return p6.rgb;
}

void fragment() {
	float t = u_time;
	float s = v_col.r;
	float heat = v_col.g;
	float m = v_col.b;
	vec2 uv = UV;
	float alpha = v_col.a;
	if (m < 0.12) {
		// Overlapping scales: rows across the body, each scale's rounded rim pointing down toward the tail.
		float row = floor(uv.x);
		vec2 cell = fract(vec2(uv.y + mod(row, 2.0) * 0.5, uv.x));
		float d = length((cell - vec2(0.5, 1.0)) * vec2(1.0, 0.9));
		s += d < 0.6 ? (0.1 - d * 0.18) : -0.2;
	} else if (m < 0.37) {
		// Belly plates with dark grooves between them.
		float f = fract(uv.x * 0.8);
		s += 0.06 - 0.32 * step(0.8, f);
	} else if (m < 0.62) {
		// Membrane veins.
		float vein = vnoise(uv * vec2(0.8, 2.6));
		s -= step(0.62, vein) * 0.12;
		s += (vnoise(uv * 3.0 + t * 0.5) - 0.5) * 0.1;
	} else if (m > 0.87) {
		s = max(s, 0.8) + (vnoise(uv * 2.0 + vec2(0.0, t * 6.0)) - 0.5) * 0.25;
	}
	// Living flame: heat makes the surface shimmer brighter in rising waves.
	float flick = fbm(vec2(uv.x * 0.35, uv.y * 0.35 + t * 1.6)) - 0.45;
	s += heat * flick * 0.35;
	float q = quant_d(clamp(s, 0.0, 1.0), 6.0, FRAGCOORD.xy);
	alpha *= fade;
	if (alpha <= 0.02) discard;
	COLOR = vec4(pal(q), alpha);
}
