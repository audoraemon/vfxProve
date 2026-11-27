// The Swallowing Dark going under (Veil): over the town (ground, houses and people alike), the dark rising from the ground behind the
// rim as it closes in from the circle's edge to the middle: everything between the rim (`front`) and the edge goes black, churning
// violet at the rim. At the fold the black drains back down into the ground, from the edge inward (`drain`), leaving the bare earth.
// Works out the ground point under each pixel (world pixels -> ground units), so it reads the same at any zoom, from inside the
// circle as well as from outside it. Keeps its own time (TIME).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"
#include "res://shaders/veil_noise.gdshaderinc"

uniform vec2 center = vec2(0.0);
uniform float edge = 10.0;
uniform float front = 10.0;
uniform float drain = 0.0;
uniform float seed = 0.0;
uniform vec4 black : source_color = vec4(0.027, 0.020, 0.047, 1.0);
uniform vec4 dusk : source_color = vec4(0.231, 0.078, 0.439, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 g = vec2((world.x / 32.0 + world.y / 16.0) * 0.5, (world.y / 16.0 - world.x / 32.0) * 0.5);
	vec2 rel = g - center;
	float d = length(rel);
	// Noise by direction (never by angle: atan's jump would draw a seam along one ray).
	vec2 dir = d > 0.001 ? rel / d : vec2(1.0, 0.0);
	// The Veil's smooth noise (veil_noise.gdshaderinc), never the shared fbm: it cut straight sawtooth steps here (fix round 2).
	float ragged = (wn(dir * 2.6 + vec2(d * 0.4 - TIME * 1.6, seed)) - 0.5) * 1.6;
	// Behind the closing rim (between it and the edge), under the dark.
	float under = smoothstep(front - 0.3, front + 0.9, d + ragged);
	// The drain: the black left only inside a disc that shrinks to the middle.
	float keep_r = (edge + 1.0) * (1.0 - drain);
	float keep = 1.0 - smoothstep(keep_r - 1.2, keep_r, d - ragged * 0.6);
	float inside = 1.0 - smoothstep(edge - 0.1, edge + 0.4, d - ragged * 0.3);
	float a = under * keep * inside;
	// Churning violet just behind the rim and along the draining edge; slow dark swirl in the body.
	float rim = (1.0 - smoothstep(0.0, 1.6, d + ragged - front)) * step(0.001, under);
	float lip = (1.0 - smoothstep(0.0, 1.4, keep_r - d)) * step(0.001, drain);
	float ca = cos(TIME * 0.5);
	float sa = sin(TIME * 0.5);
	float swirl = wn(vec2(dir.x * ca - dir.y * sa, dir.x * sa + dir.y * ca) * 1.8 + vec2(d * 0.5 + seed, TIME * 0.3));
	vec3 col = mix(black.rgb, dusk.rgb * 0.7, quant(swirl * 0.6, 3.0));
	col = mix(col, veil.rgb * 0.7, quant(max(rim, lip) * (0.6 + 0.4 * swirl), 3.0));
	float alpha = quant_d(a, 5.0, FRAGCOORD.xy);
	if (alpha <= 0.0) discard;
	COLOR = vec4(col, alpha);
}
