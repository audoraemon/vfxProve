// The Swallowing Dark's bare earth (Veil): where the dark closed, a shallow scorched bowl. Lives on the ground plane. The bowl's
// far slope faces the camera and is a shade lighter, its near slope a shade darker, the middle darkest; a low raised lip runs
// round it (lit on the far side), radial cracks and a few cold violet glints in the ash. Still: no time, nothing to feed.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float seed = 0.0;
uniform vec4 earth : source_color = vec4(0.102, 0.078, 0.063, 1.0);
uniform vec4 ash : source_color = vec4(0.24, 0.19, 0.17, 1.0);
uniform vec4 dusk : source_color = vec4(0.231, 0.078, 0.439, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);

const vec2 DN = vec2(0.70710678, 0.70710678);

vec4 shade(vec2 uv, vec2 fc, float time) {
	vec2 p = (uv - 0.5) * 2.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float edge = 0.96 + (vnoise(vec2(ang * 5.0, seed)) - 0.5) * 0.05;
	if (r > 1.0) return vec4(0.0);
	vec2 dir = r > 0.001 ? p / r : vec2(1.0, 0.0);
	float toward = dot(dir, DN);
	float n = fbm(p * 6.0 + seed);
	if (r > edge) {
		// The lip, raised a little: its far side lit, fading out onto the street.
		float k = (r - edge) / (1.0 - edge);
		float lit = smoothstep(0.3, -0.8, toward);
		vec3 lip = mix(earth.rgb, ash.rgb * 1.25, quant(lit, 3.0));
		return vec4(lip, quant_d((1.0 - k) * 0.9, 3.0, fc));
	}
	float k = r / edge;
	// The bowl: inner slopes shaded by which way they face; deepest and darkest in the middle.
	float slope = smoothstep(0.25, 1.0, k);
	float light = 0.55 + 0.45 * slope * (-toward) - 0.35 * (1.0 - k) + (n - 0.5) * 0.25;
	vec3 col = mix(earth.rgb * 0.55, ash.rgb, quant_d(clamp(light, 0.0, 1.0), 4.0, fc));
	// Rings of slumped ground and cracks running in toward the middle.
	float terrace = step(fract(k * 5.0 + (n - 0.5) * 0.4), 0.08) * step(0.2, k);
	col = mix(col, earth.rgb * 0.45, terrace * 0.8);
	float crack = step(abs(fract(ang / TAU * 22.0 + (vnoise(p * 4.0 + seed) - 0.5) * 0.9) - 0.5), 0.03) * step(0.35, k) * step(n, 0.6);
	col = mix(col, earth.rgb * 0.3, crack);
	// A few cold glints left in the ash.
	vec2 cell = floor(p * 110.0);
	float g = step(0.998, hash21(cell + seed)) * step(k, 0.85);
	col = mix(col, mix(dusk.rgb, veil.rgb, 0.4), g);
	return vec4(col, 0.95);
}

void fragment() {
	vec4 c = shade(UV, FRAGCOORD.xy, TIME);
	if (c.a <= 0.0) discard;
	COLOR = c;
}
