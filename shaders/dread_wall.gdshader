shader_type canvas_item;
// Dread of the Dark's wall (Task G, VRG1): every tongue of every pillar of one half of the wall is one instance of a unit strip
// (UV.x -1 left .. 1 right; UV.y the rung's share of the height, -1 for the soft foot below the ground line), drawn as one
// MultiMesh. The shapes the shade used to rebuild each frame in GDScript are worked out here from the instance's data:
//   INSTANCE_CUSTOM: x the tongue's phase, y when its pillar starts to rise (the shade's clock), z the pillar's full height (px),
//                    w its width (px) + 1000 x its kind (0 the haze, 1 the left tongue, 2 the middle one with the rim, 3 the right).
//   COLOR (the instance's): the tongue's colour and alpha before the rise and the fade along it.
uniform float clock = 0.0;
// How much of the look shows (the shade's strength once lifted, else 1).
uniform float shown = 1.0;
uniform vec4 rim_color : source_color = vec4(0.725, 0.549, 1.0, 1.0);

const float RISE = 0.45;
const float FOOT = 6.0;

varying float rim;

void vertex() {
	float sp = INSTANCE_CUSTOM.x;
	float kind = floor(INSTANCE_CUSTOM.w / 1000.0 + 0.001);
	float w0 = INSTANCE_CUSTOM.w - kind * 1000.0;
	float up = smoothstep(0.0, 1.0, clamp((clock - INSTANCE_CUSTOM.y) / RISE, 0.0, 1.0)) * shown;
	float tall = INSTANCE_CUSTOM.z * up;
	float w = w0 * (0.7 + 0.3 * up);
	float wide = w * 0.5;
	float hi = tall;
	float xoff = 0.0;
	if (kind < 0.5) {
		wide = w * 1.5;
		hi = tall * 1.05;
	} else if (kind < 1.5) {
		hi = tall * (0.62 + 0.38 * (0.5 + 0.5 * sin(clock * 0.9 + sp)));
		xoff = -w * 0.28;
	} else if (kind < 2.5) {
		wide = w * 0.62;
		hi = tall * (0.9 + 0.1 * sin(clock * 1.3 + sp - 2.1));
	} else {
		hi = tall * (0.62 + 0.38 * (0.5 + 0.5 * sin(clock * 1.5 + sp)));
		xoff = w * 0.28;
	}
	float q = UV.y;
	float side = UV.x;
	float a = 0.0;
	if (q < 0.0) {
		VERTEX = vec2(side * wide * 0.55 + xoff, FOOT);
	} else {
		float sway = 4.0 * sin(clock * 2.0 + sp + q * 2.7) * q * q;
		float hw = wide * 0.5 * (1.0 - pow(q, 1.2)) * (1.0 + 0.1 * sin(clock * 3.7 + sp + q * 5.0));
		VERTEX = vec2(side * hw + sway + xoff, -hi * q);
		a = 1.0 - 0.85 * q * q;
	}
	COLOR.a *= a * up;
	rim = (kind > 1.5 && kind < 2.5) ? side : 0.0;
}

void fragment() {
	// The middle tongue's pale rim down its left side.
	if (rim < -0.8) {
		COLOR.rgb = mix(COLOR.rgb, rim_color.rgb, 0.4);
	}
}
