// Tsunami wave wall seen from the side-front: rising water body with vertical flow streaks,
// a curling lip that overhangs forward, a thick foam crest, a translucent lower skirt and
// spray breaking off the top. UV.x along the wall, UV.y 0 top .. 1 ground.
// `height` 0..1 scales how tall the wave has risen; `curl` how far the lip has thrown forward.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float height = 1.0;
uniform float curl = 0.6;
uniform float fade = 1.0;
uniform float seed = 0.0;
uniform vec4 deep : source_color = vec4(0.05, 0.22, 0.48, 1.0);
uniform vec4 body : source_color = vec4(0.12, 0.45, 0.78, 1.0);
uniform vec4 light : source_color = vec4(0.45, 0.78, 0.95, 1.0);
uniform vec4 foam : source_color = vec4(0.92, 0.98, 1.0, 1.0);

void fragment() {
	float x = UV.x;
	float y = 1.0 - UV.y;
	float t = u_time;
	// Crest profile along the wall: rolling bumps traveling sideways.
	float bumps = (fbm(vec2(x * 4.0 + seed, t * 0.6)) - 0.5) * 0.5 + sin(x * 13.0 + t * 2.5 + seed) * 0.06;
	float top = height * (0.8 + bumps);
	// Ends of the wall taper down.
	top *= smoothstep(0.0, 0.08, x) * smoothstep(1.0, 0.92, x);
	if (y > top + 0.06 || top <= 0.01) discard;

	// Height within the wave column, 0 ground .. 1 crest.
	float k = clamp(y / max(top, 0.001), 0.0, 1.3);
	// Curl band: the lip near the top reads as the dark hollow under a pale overhang.
	float lip_start = 1.0 - 0.34 * curl;
	float in_lip = smoothstep(lip_start - 0.04, lip_start, k);
	float hollow = smoothstep(lip_start - 0.2, lip_start - 0.02, k) * (1.0 - in_lip) * curl;

	float flow = fbm(vec2(x * 14.0 + seed, y * 3.0 - t * 1.6));
	float streak = step(0.62, vnoise(vec2(x * 60.0 + seed, y * 2.0 - t * 2.2)));
	float shade = mix(0.3, 0.95, k) + (flow - 0.5) * 0.45 + streak * 0.2 - hollow * 0.8;
	float q = quant_d(clamp(shade, 0.0, 1.0), 4.0, FRAGCOORD.xy);
	vec3 col = q < 0.26 ? deep.rgb : (q < 0.51 ? body.rgb : (q < 0.76 ? mix(body.rgb, light.rgb, 0.5) : light.rgb));

	// Foam: crest band, lip overhang edge, and breaking whitecaps.
	// Thick rolling foam crest that thickens where the wave peaks.
	float crest = smoothstep(top - 0.14 - bumps * 0.12, top - 0.03, y);
	float cap = step(0.55, fbm(vec2(x * 22.0 + seed, y * 12.0 - t * 3.0))) * smoothstep(lip_start - 0.05, 1.0, k);
	float foam_v = max(crest, cap * in_lip);
	// Foam streaks running down the face.
	foam_v = max(foam_v, step(0.8, vnoise(vec2(x * 40.0, y * 8.0 - t * 4.0 + seed))) * (0.35 + 0.65 * k) * 0.8);
	float fq = quant_d(foam_v, 2.0, FRAGCOORD.xy);
	col = mix(col, foam.rgb, fq);

	// Spray dots breaking above the crest.
	float alpha = 1.0;
	if (y > top) {
		float spray = step(0.72, hash21(floor(FRAGCOORD.xy * 0.5) + floor(t * 12.0)));
		alpha = spray * (1.0 - (y - top) / 0.06);
		col = foam.rgb;
	}
	// Translucent skirt near the ground.
	alpha *= mix(0.72, 1.0, smoothstep(0.0, 0.12, k));
	alpha *= fade;
	if (alpha <= 0.02) discard;
	COLOR = vec4(col, alpha);
}
