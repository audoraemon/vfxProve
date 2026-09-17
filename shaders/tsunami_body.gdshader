// Tsunami wave body behind the painted front face: the churning top of the wave just behind the crest and
// the long back slope running down to the ground. Vertex COLOR = (depth 0 front .. 1 back, height 0..1,
// along 0..1, 0). UV = pixel-ish coordinates across (x) and down the slope (y) for streaks.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float fade = 1.0;
uniform vec4 navy : source_color = vec4(0.03, 0.07, 0.22, 1.0);
uniform vec4 deep : source_color = vec4(0.06, 0.18, 0.5, 1.0);
uniform vec4 royal : source_color = vec4(0.12, 0.42, 0.86, 1.0);
uniform vec4 blue : source_color = vec4(0.26, 0.62, 0.98, 1.0);
uniform vec4 cyan : source_color = vec4(0.5, 0.84, 1.0, 1.0);
uniform vec4 pale : source_color = vec4(0.76, 0.94, 1.0, 1.0);
uniform vec4 white : source_color = vec4(0.97, 1.0, 1.0, 1.0);

varying vec4 v_col;

void vertex() {
	v_col = COLOR;
}

vec3 water_ramp(float v) {
	if (v < 0.16) return navy.rgb;
	if (v < 0.34) return deep.rgb;
	if (v < 0.52) return royal.rgb;
	if (v < 0.7) return blue.rgb;
	if (v < 0.86) return cyan.rgb;
	return pale.rgb;
}

void fragment() {
	float t = u_time;
	float depth = v_col.r;
	float h = clamp(v_col.g, 0.0, 1.0);
	vec2 p = floor(UV);

	// Broad swells rolling over the slope, streaks running down it toward the crest.
	float swell = fbm(vec2(p.x * 0.025 + t * 0.15, p.y * 0.04 + t * 0.6));
	float across = p.x + (fbm(vec2(p.x * 0.05, p.y * 0.06 - t * 0.5)) - 0.5) * 10.0;
	float stripe = fract(across / 5.0);
	float dash = step(0.38, vnoise(vec2(floor(across / 5.0) * 3.1, p.y * 0.08 + t * 1.8)));
	float streak = step(abs(stripe - 0.5), 0.15) * dash;
	float light = 0.24 + 0.46 * pow(h, 0.8) + (swell - 0.5) * 0.35 + streak * 0.3;
	vec3 c = water_ramp(quant(clamp(light, 0.0, 1.0), 6.0));

	// Foam: churning over the top behind the crest, trails streaming down the slope, patches, ragged ground edge.
	vec2 q = p * 0.14 + vec2(t * 0.6, -t * 1.1);
	float v1 = fbm(q);
	float v2 = fbm(q + vec2(0.3, -0.3));
	float top = (1.0 - smoothstep(0.06, 0.4, depth)) * smoothstep(0.3, 0.75, h);
	float trail = streak * step(0.62, vnoise(vec2(floor(across / 5.0) * 1.7, p.y * 0.03 + t * 0.9))) * 0.75;
	float patch = smoothstep(0.66, 0.8, fbm(p * 0.045 + vec2(0.0, t * 0.5))) * 0.7;
	float ragged = (fbm(vec2(p.x * 0.09, t * 0.7)) - 0.5) * 0.16;
	float ground = (1.0 - smoothstep(0.0, 0.12, h + ragged)) * 0.8;
	float amount = max(max(top, trail), max(patch, ground));
	float fv = v1 + (vnoise(p * 0.5 + t * 2.0) - 0.5) * 0.3 + (amount - 0.5) * 0.9;
	float alpha = fade;
	if (amount > 0.02 && fv > 0.42) {
		c = fv < 0.47 ? blue.rgb : ((v1 + 0.03 >= v2 || fv > 0.78) ? white.rgb : pale.rgb);
	}
	// Ragged hem where the slope meets the ground.
	float hem = h + ragged + (vnoise(p * 0.35 + t) - 0.5) * 0.06;
	if (hem < 0.06) {
		alpha = 0.0;
	}
	if (alpha <= 0.02) discard;
	COLOR = vec4(c, alpha);
}
