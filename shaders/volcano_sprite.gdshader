// Volcano sprite (PixelLab art): rises out of / sinks into the ground by being clipped at the ground
// line, rock darkens with the scene's ambient light while the lava stays bright, the lava pulses and flickers, and
// `heat` cools it toward a dull crust.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

// Local y below which nothing is drawn (the ground line), and the scene's ambient light on the rock.
uniform float clip_y = 0.0;
uniform float ambient = 1.0;
uniform float heat = 1.0;
// Lifts the sprite's very dark rock, warmed a little by the lava light, so its slabs read in game.
uniform float rock_gain = 1.15;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	if (local_y > clip_y) discard;
	// COLOR already holds the texture colour times the vertex colour.
	vec4 c = COLOR;
	if (c.a <= 0.01) discard;
	// Lava: hot, saturated oranges and yellows.
	float lava = smoothstep(0.25, 0.5, c.r - c.b) * smoothstep(0.45, 0.8, max(c.r, c.g));
	// Slow pulse rolling down the slopes plus a quick flicker, only on the lava.
	float pulse = 0.5 + 0.5 * sin(u_time * 3.0 + UV.y * 9.0 + UV.x * 4.0);
	float flick = hash21(vec2(floor(UV.x * 40.0), floor(UV.y * 40.0) + floor(u_time * 10.0)));
	vec3 hot = c.rgb * (1.0 + lava * (0.18 * pulse + 0.08 * flick));
	// Cooling: lava dulls to a dark red crust.
	hot = mix(hot, c.rgb * vec3(0.5, 0.18, 0.12), lava * (1.0 - heat));
	// Rock is lifted and warmed, then takes the scene light; lava glows on its own.
	hot *= mix(rock_gain * vec3(1.08, 0.97, 0.92), vec3(1.0), lava);
	hot *= mix(ambient, 1.0, lava * heat);
	COLOR = vec4(hot, c.a);
}
