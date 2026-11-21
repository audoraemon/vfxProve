// The Swallowing Dark's hole (Veil): not a disc but a drop into the ground. Lives on the ground plane, so the quad's circle
// projects to an iso ellipse. Inside the rim a funnel sinks toward the middle: its rings (terraces of the wall) are packed
// toward the near lip and spread over the far wall, which faces the camera and catches a cold light; the rings sink, and a slow
// swirl turns down into the black at the bottom. The far lip is lit silver, the near lip a dark violet edge. Round the rim an
// apron of darkened, cracked ground whose dust streams in over the edge. Keeps its own time (TIME).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

// The hole's radius as a share of the quad's (grows with the cast).
uniform float hole = 0.5;
// The apron's width round the rim, as a share of the quad's radius.
uniform float apron = 0.2;
// 0..1: the circle opening (its first half second).
uniform float open = 1.0;
// 0..1: the ground heaving just before the fold.
uniform float heave = 0.0;
// 0..1: the fold; the hole closes under the dome.
uniform float fold = 0.0;
uniform float seed = 0.0;
uniform vec4 black : source_color = vec4(0.027, 0.020, 0.047, 1.0);
uniform vec4 dusk : source_color = vec4(0.231, 0.078, 0.439, 1.0);
uniform vec4 veil : source_color = vec4(0.725, 0.549, 1.0, 1.0);
uniform vec4 silver : source_color = vec4(0.812, 0.827, 0.902, 1.0);
uniform vec4 dust : source_color = vec4(0.36, 0.31, 0.27, 1.0);

const vec2 DN = vec2(0.70710678, 0.70710678);
// How far the funnel's rings slide toward the near lip as they sink, and how much they narrow, in rim radii.
const float SLIDE = 0.72;
const float NARROW = 0.86;
const int STEPS = 22;

vec4 shade(vec2 uv, vec2 fc, float time) {
	float h = hole * open;
	if (h <= 0.001) return vec4(0.0);
	vec2 p = (uv - 0.5) * 2.0;
	vec2 q = p / h;
	float rr = length(q);
	vec2 dir = rr > 0.001 ? q / rr : vec2(1.0, 0.0);
	float toward = dot(dir, DN);
	float ang = atan(q.y, q.x);
	float shake = heave * 0.05 * sin(ang * 6.0 + time * 14.0 + seed);
	float edge = 1.0 + (vnoise(vec2(ang * 4.0, seed)) - 0.5) * 0.07 + shake;
	float alpha = 1.0 - fold;
	if (rr > edge) {
		// The apron: char and cracks thinning outward, dust drawn in toward the rim in streaks.
		float k = (rr - edge) * h / max(apron, 0.001);
		if (k > 1.0) return vec4(0.0);
		float n = fbm(q * 3.0 + seed);
		float dark = quant_d((1.0 - smoothstep(0.0, 1.0, k + (n - 0.5) * 0.6)) * (0.62 + 0.25 * heave), 4.0, fc);
		vec4 col = vec4(black.rgb, dark);
		float bin = floor(fract(ang / TAU + 0.5) * 72.0);
		float streak = step(0.55, hash21(vec2(bin, seed))) * step(fract(k * 2.5 + time * (0.5 + 0.4 * hash21(vec2(bin, 3.0)))), 0.22);
		float crack = step(abs(fract(ang / TAU * 18.0 + (vnoise(q * 3.0 + seed) - 0.5) * 0.8) - 0.5), 0.035) * step(k, 0.3 + 0.5 * n);
		if (crack > 0.5) col = vec4(black.rgb * 0.6, 0.95);
		if (streak > 0.5) col = vec4(mix(dust.rgb, dusk.rgb, 0.25 + 0.4 * k), (1.0 - k) * 0.85);
		// The heave: the ground at the rim lifts and catches the light.
		col.rgb = mix(col.rgb, dusk.rgb * 1.4, heave * step(k, 0.18) * 0.6);
		col.a *= alpha;
		if (col.a <= 0.01) return vec4(0.0);
		return col;
	}
	// The lip: lit silver where the far side faces the camera, a dark violet edge on the near side.
	if (rr > edge - 0.045) {
		float far = smoothstep(0.2, -0.7, toward);
		vec3 lip = mix(dusk.rgb * 0.9, silver.rgb, quant(far, 3.0));
		return vec4(lip, alpha * (0.75 + 0.25 * far));
	}
	// Down the funnel: the first ring (from the rim down) whose wall this pixel meets.
	float s = 1.0;
	bool wall = false;
	// Then between that ring and the one above it, where the wall crosses (linear): `s` runs on smoothly, not in 22 steps (stepped,
	// its light and swirl drew stair-step edges through the funnel: fix round 2).
	float prev_d = length(q) - 1.0;
	for (int i = 1; i <= STEPS; i++) {
		float si = float(i) / float(STEPS);
		float di = length(q - DN * si * SLIDE) - (1.0 - NARROW * si);
		if (di >= 0.0) {
			float sp = float(i - 1) / float(STEPS);
			s = sp + (si - sp) * clamp(-prev_d / max(di - prev_d, 1e-4), 0.0, 1.0);
			wall = true;
			break;
		}
		prev_d = di;
	}
	vec3 col = black.rgb;
	if (wall) {
		vec2 c = q - DN * s * SLIDE;
		float facing = -dot(normalize(c + vec2(0.0001)), DN);
		float a2 = atan(c.y, c.x);
		// The far wall faces the camera and holds a cold light that dies with depth; the near wall is in shadow.
		float light = exp(-s * 3.0) * (0.25 + 0.75 * max(facing, 0.0));
		float lit = quant_d(light, 5.0, fc);
		col = mix(black.rgb, dusk.rgb * 0.9, lit);
		col = mix(col, mix(veil.rgb, silver.rgb, 0.3) * 0.55, step(0.79, lit));
		// The wall's terraces, sinking: lines packed toward the near lip, spread over the far wall.
		float ring = fract(s * 8.0 - time * (0.35 + heave * 1.6));
		float line = step(ring, 0.13);
		col = mix(col, mix(veil.rgb * 0.5, silver.rgb * 0.75, light), line * (0.3 + 0.7 * light));
		// The swirl: violet arms turning down into the dark.
		float arm = step(0.78, 0.5 + 0.5 * sin(a2 * 3.0 + s * 14.0 - time * (0.9 + heave * 3.0) + seed));
		col = mix(col, dusk.rgb * 1.4, arm * 0.55 * (1.0 - light));
	} else {
		// The bottom: a black that breathes, a faint violet turning in it.
		vec2 c = q - DN * SLIDE;
		float a2 = atan(c.y, c.x);
		float arm = step(0.82, 0.5 + 0.5 * sin(a2 * 2.0 + length(c) * 18.0 - time * 1.3 + seed));
		col = mix(black.rgb, dusk.rgb * 0.5, arm * (0.4 + 0.2 * sin(time * 0.9)));
	}
	return vec4(col, alpha);
}

void fragment() {
	vec4 c = shade(UV, FRAGCOORD.xy, TIME);
	if (c.a <= 0.0) discard;
	COLOR = c;
}
