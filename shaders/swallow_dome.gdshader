// The Swallowing Dark's fold (Veil): the dark rises out of the hole as a low dome over the whole circle, boiling, and closes
// back down into the ground. Screen space, over the town: its base is the circle's iso ellipse (half the quad's width across,
// `base_px` down), and it bulges `rise` * `dome_px` above it. Shaded as a ball lit from above: a cold crown, a black skirt, a
// silver line along the crown's edge, the smoke of its skin streaming up. Keeps its own time (TIME).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

// The base ellipse's vertical semi-axis and the dome's full height, in pixels; the quad is 2 * base_px + dome_px tall.
uniform float base_px = 100.0;
uniform float dome_px = 80.0;
// 0..1 how high it stands; 0..1 how strongly it shows.
uniform float rise = 0.0;
uniform float amount = 0.0;
uniform float seed = 0.0;
uniform vec4 black : source_color = vec4(0.027, 0.020, 0.047, 1.0);
uniform vec4 dusk : source_color = vec4(0.231, 0.078, 0.439, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);
uniform vec4 silver : source_color = vec4(0.812, 0.827, 0.902, 1.0);

void fragment() {
	float x = (UV.x - 0.5) * 2.0;
	float y = UV.y * (2.0 * base_px + dome_px) - (base_px + dome_px);
	float w2 = 1.0 - x * x;
	float h = dome_px * rise;
	float w = sqrt(max(w2, 0.0));
	float top = -sqrt(base_px * base_px + h * h) * w;
	float bottom = base_px * w;
	// A ragged, boiling skin along the crown.
	float boil = fbm(vec2(x * 7.0 + seed, TIME * 1.4));
	top += (boil - 0.5) * (10.0 + 14.0 * rise) * w;
	float inside = step(0.0, w2) * step(top, y) * step(y, bottom) * step(0.001, amount);
	// Height on the ball: 1 at the crown, 0 at the base ellipse's far edge and below.
	float v = clamp((y - top) / max(bottom - top, 1.0), 0.0, 1.0);
	vec3 n = normalize(vec3(x, -(1.0 - v) * 1.2 * rise - 0.15, 0.6));
	float lambert = clamp(dot(n, normalize(vec3(-0.35, -0.9, 0.4))), 0.0, 1.0);
	// The smoke of its skin streaming up the sides.
	float smoke = fbm(vec2(x * 4.0 + seed, v * 3.0 + TIME * 1.2));
	float lit = quant_d(lambert * (0.55 + 0.6 * smoke) * (0.4 + 0.6 * rise), 4.0, FRAGCOORD.xy);
	vec3 col = mix(black.rgb, dusk.rgb * 1.2, lit);
	col = mix(col, veil.rgb * 0.65, step(0.74, lit));
	// Thin violet cracks of light in the skin, a silver line along the crown.
	float crack = step(abs(vnoise(vec2(x * 22.0 - seed, v * 6.0 - TIME * 0.8)) - 0.5), 0.02) * step(0.62, smoke);
	col = mix(col, veil.rgb, crack * 0.6);
	float rim = step(y - top, 2.0 + 2.0 * rise) * step(0.05, rise);
	col = mix(col, silver.rgb, rim * (0.4 + 0.6 * w));
	float a = amount * quant_d(0.86 + 0.14 * v, 3.0, FRAGCOORD.xy) * inside;
	if (a <= 0.0) discard;
	COLOR = vec4(col, a);
}
