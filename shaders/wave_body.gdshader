// Breaking wave surface. Vertex COLOR carries shading: r = light 0..1, g = foam weight 0..1,
// b = 1 for the ground foam skirt (alpha from foam only), b = 0.5 for the hollow inside a curl
// (UV.x angle 0..1 around the curl, UV.y 0 center .. 1 rim). UV.x across the wall, UV.y along the profile.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float fade = 1.0;
uniform vec4 deep : source_color = vec4(0.04, 0.12, 0.36, 1.0);
uniform vec4 body : source_color = vec4(0.09, 0.3, 0.68, 1.0);
uniform vec4 mid : source_color = vec4(0.16, 0.5, 0.88, 1.0);
uniform vec4 light : source_color = vec4(0.42, 0.78, 0.98, 1.0);
uniform vec4 foam_shadow : source_color = vec4(0.7, 0.88, 0.98, 1.0);
uniform vec4 foam : source_color = vec4(0.96, 0.99, 1.0, 1.0);

varying vec4 v_col;

vec4 surface(vec2 uv, float t, float shade, float foam_w, float skirt, vec2 fc) {
	// Flowing surface: large swells, running veins down the face.
	float swell = fbm(vec2(uv.x * 1.3, uv.y * 0.8 - t * 0.9));
	shade += (swell - 0.5) * 0.25;
	float vein = vnoise(vec2(uv.x * 7.0 + sin(uv.y * 2.0 + t) * 0.4, uv.y * 0.9 - t * 1.8));
	float vein_line = 1.0 - smoothstep(0.0, 0.05, abs(vein - 0.55));
	float q = quant_d(clamp(shade, 0.0, 1.0), 4.0, fc);
	vec3 col = q < 0.26 ? deep.rgb : (q < 0.51 ? body.rgb : (q < 0.76 ? mid.rgb : light.rgb));
	col = mix(col, light.rgb, step(0.5, vein_line) * 0.85);
	// Thin white foam threads streaming over the surface.
	float thread = vnoise(vec2(uv.x * 11.0 + sin(uv.y * 3.0 - t * 1.5) * 0.6, uv.y * 0.6 - t * 1.4));
	col = mix(col, foam.rgb, step(0.5, 1.0 - smoothstep(0.0, 0.02, abs(thread - 0.5))) * step(0.6, shade));

	// Foam clumps: lumpy cells that boil, with a pale blue shadow rim around each clump.
	float clump = fbm(vec2(uv.x * 3.2 - t * 0.4, uv.y * 2.4 - t * 1.2)) + (vnoise(uv * vec2(9.0, 7.0) + t) - 0.5) * 0.3;
	float f = foam_w + (clump - 0.5) * 0.9;
	float alpha = 1.0;
	if (f > 0.62) {
		col = foam.rgb;
	} else if (f > 0.48) {
		col = foam_shadow.rgb;
	}
	if (skirt > 0.5) {
		// Ground foam fades out ragged in front of the wave.
		alpha = step(0.48, f);
		float spot = step(0.5, hash21(floor(fc * 0.5) + floor(t * 8.0)));
		alpha *= mix(spot, 1.0, step(0.6, f));
	}
	return vec4(col, alpha * fade);
}

void vertex() {
	v_col = COLOR;
}

void fragment() {
	float t = u_time;
	vec2 uv = UV;
	float shade = v_col.r;
	float foam_w = v_col.g;
	float skirt = v_col.b;

	if (skirt > 0.25 && skirt < 0.75) {
		// Hollow inside the curl: deep water with bright bands spiralling in toward the center.
		float band = fract(uv.y * 3.2 + uv.x * 2.0 - t * 0.7 + vnoise(uv * 6.0) * 0.3);
		float d = quant_d(clamp(0.1 + uv.y * 0.5, 0.0, 1.0), 3.0, FRAGCOORD.xy);
		vec3 hc = d < 0.34 ? deep.rgb : body.rgb;
		hc = mix(hc, mid.rgb, step(0.82, band));
		hc = mix(hc, light.rgb, step(0.94, band) * step(0.5, uv.y));
		if (fade <= 0.02) discard;
		COLOR = vec4(hc, fade);
	} else {
		vec4 sc = surface(uv, t, shade, foam_w, skirt, FRAGCOORD.xy);
		if (sc.a <= 0.02) discard;
		COLOR = sc;
	}
}
