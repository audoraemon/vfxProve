// Evernight's front (Veil): a towering wall of night standing on the front's ring and running out across the town (and, at dawn,
// rolling back). Drawn as a strip round the ring: UV.x runs along it (in noise tiles), UV.y from its foot (0) to its top (1).
// Near-solid black at the foot, boiling up into a ragged, thinning crown of smoke whose billows catch a violet light; fine
// silver motes are carried up in it. Keeps its own time (TIME).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float amount = 1.0;
uniform vec4 black : source_color = vec4(0.027, 0.020, 0.047, 1.0);
uniform vec4 dusk : source_color = vec4(0.231, 0.078, 0.439, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);
uniform vec4 silver : source_color = vec4(0.812, 0.827, 0.902, 1.0);

void fragment() {
	float v = UV.y;
	float n = fbm(vec2(UV.x * 2.4, v * 1.6 - TIME * 0.7));
	float n2 = fbm(vec2(UV.x * 6.0 + 3.0, v * 3.6 - TIME * 1.5));
	// Towers of smoke of different heights along the wall, boiling: the crown is ragged, never a lid.
	float crown = 0.15 + 1.0 * fbm(vec2(UV.x * 3.2 + 5.0, TIME * 0.35));
	float lift = v + (n2 - 0.5) * 0.22;
	float body = 1.0 - smoothstep(crown - 0.16, crown, lift);
	float a = quant_d(body * (0.82 + 0.3 * n), 5.0, FRAGCOORD.xy);
	vec3 col = mix(black.rgb, dusk.rgb * 0.65, quant(n2 * v * 1.4, 3.0));
	// The billows' edges along the crown catch a violet light.
	float edge = step(abs(lift - crown + 0.06), 0.035) * step(0.1, v);
	col = mix(col, veil.rgb * 0.75, edge);
	// Fine silver motes carried up in it.
	vec2 cell = floor((FRAGCOORD.xy + vec2(0.0, TIME * 45.0)) / 3.0);
	float mote = step(0.996, hash21(cell)) * step(0.25, a);
	col = mix(col, silver.rgb, mote);
	a = max(a, mote * 0.8) * amount;
	if (a <= 0.0) discard;
	COLOR = vec4(col, a);
}
