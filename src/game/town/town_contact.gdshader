// The contact shadows of the DAY and NIGHT looks (TownShadows' contact group): a band hugging every building's base and a
// small blob under every tree, whose vertex alpha (1 at the base, 0 at the band's edge) is cut into on/off pixels by a 4x4
// Bayer dither of world pixels. The group gives the darkness once (its self_modulate), so overlaps never stack.
shader_type canvas_item;

varying vec2 wpos;

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int b[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(b[i.y * 4 + i.x]) + 0.5) / 16.0;
}

void vertex() {
	wpos = VERTEX;
}

void fragment() {
	if (COLOR.a < bayer4(floor(wpos))) {
		discard;
	}
	COLOR = vec4(1.0);
}
