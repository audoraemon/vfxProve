// Energy beam. UV.x across width, UV.y along length (0 = far end / top).
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float intensity = 1.0;
uniform float flicker = 1.0;
uniform float bands = 10.0;
uniform float band_speed = 6.0;
// 1 = fade toward UV.y = 0.
uniform float taper = 1.0;

void fragment() {
	if (intensity <= 0.001) discard;
	float d = abs(UV.x - 0.5) * 2.0;
	float v = 1.0 - d / clamp(intensity, 0.05, 1.0);
	if (v <= 0.0) discard;
	v = pow(v, 0.6);
	float band = step(0.5, fract(UV.y * bands - u_time * band_speed));
	v *= 0.88 + 0.12 * band;
	float fl = 1.0 - flicker * 0.25 * step(0.6, hash21(vec2(floor(u_time * 30.0), 1.7)));
	v *= fl;
	v *= mix(1.0, smoothstep(0.0, 0.4, UV.y), taper);
	v *= 0.6 + 0.4 * intensity;
	float q = quant(v, 5.0);
	if (q <= 0.0) discard;
	COLOR = ramp5(q);
}
