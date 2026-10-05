// The Light of Solaris's pit: a hole burned straight down through the ground, with a scorched apron round it.
// Lives on the ground plane, so the quad's circle projects to an iso ellipse. Looking down into it only the far wall
// shows, shaded into the dark; the near lip hides its own. Keeps its own time (TIME): nothing feeds it once it is cold.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

// The hole's radius as a share of the quad's; the rest is the apron.
uniform float hole = 0.74;
// 0..1: the hole opening under the beam.
uniform float open = 1.0;
// 1 molten .. 0 cold.
uniform float heat = 1.0;
uniform float seed = 0.0;
uniform vec4 rock : source_color = vec4(0.36, 0.31, 0.27, 1.0);
uniform vec4 char_color : source_color = vec4(0.05, 0.04, 0.04, 0.92);
uniform vec4 molten : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 molten_hot : source_color = vec4(1.0, 0.92, 0.58, 1.0);
uniform vec4 ember : source_color = vec4(0.5, 0.09, 0.03, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0) discard;
	vec2 dir = r > 0.001 ? p / r : vec2(1.0, 0.0);
	// Screen-down across the ground plane: +1 at the lip nearest the camera.
	float toward = (dir.x + dir.y) * 0.70710678;
	float h = hole * open * (1.0 + (vnoise(dir * 2.6 + seed) - 0.5) * 0.12);
	float n = fbm(p * 5.0 + seed);

	if (r > h) {
		// The apron: char thinning outward, cracks and the lip glowing while the rock is hot.
		float k = (r - h) / max(1.0 - h, 0.001);
		vec4 col = char_color;
		col.a *= quant_d(1.0 - smoothstep(0.1, 1.0, k + (n - 0.5) * 0.5), 3.0, FRAGCOORD.xy);
		float ca = fract(atan(p.y, p.x) / TAU * 14.0 + (vnoise(p * 4.0 + seed) - 0.5) * 0.7);
		float crack = step(abs(ca - 0.5), 0.05) * step(k, 0.25 + 0.5 * n) * step(0.001, open);
		float lip = step(k, 0.08) * step(0.001, open);
		if (max(lip, crack) > 0.5) {
			float hq = quant(heat * (0.75 + 0.5 * n), 3.0);
			vec4 hot = mix(molten, molten_hot, step(0.7, heat) * step(0.5, n));
			// Cold: the lip is bare rock, lit on the side facing the camera; a crack is a dark line.
			vec4 cold = lip > 0.5 ? vec4(rock.rgb * mix(0.5, 1.25, smoothstep(-0.4, 0.6, toward)), 1.0)
				: vec4(0.02, 0.015, 0.015, 0.9);
			col = mix(cold, hot, hq);
		}
		if (col.a <= 0.01) discard;
		COLOR = col;
	} else {
		// Down the hole. u runs across the screen, v down it, both -1..1 inside the rim.
		float u = (p.x - p.y) * 0.70710678 / h;
		float v = (p.x + p.y) * 0.70710678 / h;
		// How far below the far rim this pixel sits: 0 at the rim, 1 looking straight down past the near lip.
		float depth = (v + sqrt(max(1.0 - u * u, 0.0))) * 0.5;
		float column = vnoise(vec2(u * 9.0 + seed, 0.5));
		float strata = vnoise(vec2(u * 2.0 + seed, depth * 16.0));
		float lit = exp(-depth * 2.3) * (0.65 + 0.35 * column) * (0.8 + 0.3 * strata);
		// The walls to either side turn away from the light.
		lit *= 0.45 + 0.55 * (1.0 - u * u);
		vec3 col = rock.rgb * 1.3 * quant_d(lit, 6.0, FRAGCOORD.xy);
		// The top of the wall glows while the rock is hot, and the glow draws up to the rim as it cools.
		float band = 1.0 - smoothstep(0.0, 0.06 + 0.4 * heat, depth);
		float hq = quant_d(heat * band * (0.7 + 0.5 * strata), 3.0, FRAGCOORD.xy);
		col = mix(col, mix(molten.rgb, molten_hot.rgb, step(0.75, hq)), hq);
		// Far below, something still burns: a slow breath that never goes out.
		float deep = smoothstep(0.4, 0.95, depth) * (1.0 - u * u) * (0.55 + 0.25 * sin(TIME * 0.7 + seed));
		col += ember.rgb * quant_d(deep * 0.6, 3.0, FRAGCOORD.xy) * (0.6 + 0.4 * heat);
		COLOR = vec4(col, 1.0);
	}
}
