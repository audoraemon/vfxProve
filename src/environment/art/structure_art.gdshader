shader_type canvas_item;
// Lights a building's art on the GPU so its geometry is built once. Each art vertex carries its unlit material
// colour and, in UV.x, a code (ArtKit.LIT_LEFT/LIT_RIGHT/LIT_TOP/INK/EMIT). The maths is Structure._face_color's.
// Anything else the structure draws (its shadow, cracks, rubble; UVs within 0..1) passes through untouched.

uniform vec3 light_col = vec3(0.0);
uniform vec2 light_dir = vec2(0.0);
uniform float ambient = 1.0;
uniform float scorch = 0.0;
uniform float frost = 0.0;
// The world's light colour (LightField.tint): lit surfaces and ink take it, emissive glow does not.
uniform vec3 tint = vec3(1.0);
// This component's colour tuning (ArtTuning.tint): multiplies its materials before they are lit.
uniform vec3 art_tint = vec3(1.0);

// Wind: 1 in play, 0 stills it (component previews). See the vertex stage.
uniform float wind = 1.0;

const vec3 CHAR = vec3(0.078431, 0.066667, 0.070588);
const vec3 FROST = vec3(0.62, 0.78, 0.92);

// Art vertices whose UV.y carries a weight (ArtKit.wind_*) move with the wind, the rest stay: a positive weight is a
// slow sway, px across (a tree's crown); a negative one a ripple, mostly up and down along the edge (an awning, a
// banner). Whole pixels only, phased by where the structure stands so neighbours do not move in step. The same
// motion as shaders/wind.gdshader's, for decor and the forest: keep the two in step.
void vertex() {
	if (UV.x > 1.5 && UV.y != 0.0) {
		vec2 at = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
		float ph = at.x * 0.013 + at.y * 0.021 + VERTEX.x * 0.011 + VERTEX.y * 0.017;
		float w = abs(UV.y);
		vec2 off;
		if (UV.y > 0.0) {
			off = w * vec2(sin(TIME * 1.3 + ph), 0.0);
		} else {
			off = w * vec2(0.4 * sin(TIME * 2.1 + ph), sin(TIME * 6.0 + VERTEX.x * 0.45 + ph));
		}
		VERTEX += round(off * wind);
	}
}

void fragment() {
	float code = UV.x;
	if (code < 1.5) {
		COLOR = texture(TEXTURE, UV) * COLOR;
	} else if (code > 5.5) {
		// EMIT: window glow, the dark of a gateway.
	} else if (code > 4.5) {
		// INK: outlines darken with scorch only.
		COLOR.rgb = mix(COLOR.rgb, CHAR, scorch * 0.65) * tint;
	} else {
		vec3 base = min(COLOR.rgb * art_tint, vec3(1.0));
		vec2 n = code < 2.5 ? vec2(0.0, 1.0) : vec2(1.0, 0.0);
		float facing = 0.35;
		if (code > 3.5) {
			facing = 0.9;
		} else if (length(light_dir) > 0.001) {
			facing += 0.9 * clamp(dot(normalize(light_dir), n), 0.0, 1.0);
		}
		vec3 lit = light_col * facing;
		lit = lit / (1.0 + lit);
		float lum = dot(base, vec3(0.2126, 0.7152, 0.0722));
		float head = 1.0 - lum;
		float t = clamp((lum - 0.25) / 0.4, 0.0, 1.0);
		float gain = mix(4.0, 1.2, t) * head;
		float add = mix(0.35, 0.12, t) * head;
		vec3 c = min(base * ambient * (1.0 + lit * gain) + lit * add, vec3(1.0));
		c = mix(c, CHAR, scorch * 0.65);
		COLOR.rgb = mix(c, FROST, frost * 0.35) * tint;
	}
}
