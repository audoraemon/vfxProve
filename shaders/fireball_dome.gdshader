// Nuclear fireball dome: hemisphere over an iso base ellipse, turbulent banded heat.
// Quad: width 2A, height A*(dome_ratio + base_ratio); anchor at base center.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform float grow = 1.0;
uniform float heat = 1.0;
uniform float dissolve = 0.0;
uniform float dome_ratio = 0.85;
uniform float base_ratio = 0.5;

void fragment() {
	float s = max(grow, 0.001);
	float x = (UV.x - 0.5) * 2.0 / s;
	float y = (UV.y * (dome_ratio + base_ratio) - dome_ratio) / s;
	float q;
	float h = 0.0;
	if (y < 0.0) {
		q = x * x + (y / dome_ratio) * (y / dome_ratio);
		h = -y / dome_ratio;
	} else {
		q = x * x + (y / base_ratio) * (y / base_ratio);
	}
	float turb = fbm(vec2(x * 3.0, y * 3.0 + u_time * 1.8));
	q += (turb - 0.5) * 0.22;
	if (q > 1.0) discard;
	float burn = fbm(vec2(x * 4.0 + 7.0, y * 4.0 - u_time * 0.7));
	if (burn < dissolve * 1.1 - 0.1 + q * dissolve * 0.3) discard;

	float nz = sqrt(max(1.0 - q, 0.0));
	float v = nz * 0.55 + 0.35;
	v += (1.0 - h) * 0.12;
	v *= 0.72 + 0.55 * turb;
	// Vertical energy streaks on the dome surface.
	float streak = step(0.8, vnoise(vec2(x * 14.0, h * 2.0 - u_time * 3.0))) * smoothstep(0.3, -0.1, y);
	v += streak * 0.25;
	// Hot seam where dome meets the ground, only at the outer rim.
	v += step(abs(y), 0.08) * step(0.8, x * x) * 0.3;
	// Darker crust near the edge.
	v *= mix(1.0, 0.65, smoothstep(0.75, 1.0, q));
	v *= heat;
	float qv = quant_d(v, 5.0, FRAGCOORD.xy);
	if (qv <= 0.0) discard;
	COLOR = ramp5(qv);
}
