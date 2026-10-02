shader_type canvas_item;
// A building sprite (SpriteView), lit as structure_art.gdshader lights the procedural art, but with one even facing:
// a sprite has no per-face normals. Bright warm pixels (lit windows, a forge) glow: they skip the dim, the light and
// the char. cut_mode clips the sprite along its footprint's front ground line raised by cut_lift (sprite px): 1 keeps
// what is above the line (a building sinking into the ground, a sliced-off top), -1 what is below (the stump), whose
// top edge glows molten while `molten` lasts.

uniform vec3 light_col = vec3(0.0);
uniform float ambient = 1.0;
uniform float scorch = 0.0;
uniform float frost = 0.0;
// The world's light colour (LightField.tint).
uniform vec3 tint = vec3(1.0);
uniform int cut_mode = 0;
uniform float cut_lift = 0.0;
uniform float molten = 0.0;
// The drawn frame's top-left in the texture (px), the footprint's front corner within the frame (px), and the
// footprint's left and right corners relative to that front corner (px, the sprite's own unmirrored space).
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 anchor = vec2(0.0);
uniform vec2 corner_left = vec2(-32.0, -16.0);
uniform vec2 corner_right = vec2(32.0, -16.0);

const vec3 CHAR = vec3(0.078431, 0.066667, 0.070588);
const vec3 FROST = vec3(0.62, 0.78, 0.92);
const vec3 MOLTEN = vec3(1.0, 0.690196, 0.25098);
// The procedural art's facing is 0.35 away from a light and up to 1.25 toward it; a sprite takes the middle.
const float FACING = 0.62;

// The footprint's front edges: down from the left corner to the front corner, up to the right one; flat beyond.
float ground_y(float x) {
	if (x < 0.0) {
		return corner_left.y * clamp(x / corner_left.x, 0.0, 1.0);
	}
	return corner_right.y * clamp(x / corner_right.x, 0.0, 1.0);
}

bool glows(vec3 c) {
	return c.r > 0.85 && c.g > 0.5 && c.b < 0.55 && c.r - c.b > 0.4;
}

void fragment() {
	vec4 px = texture(TEXTURE, UV);
	vec2 p = floor(UV / TEXTURE_PIXEL_SIZE) + 0.5 - frame_origin - anchor;
	float line = ground_y(p.x) - cut_lift;
	if ((cut_mode == 1 && p.y > line) || (cut_mode == -1 && p.y < line)) {
		discard;
	}
	vec3 c = px.rgb;
	if (!glows(c)) {
		vec3 lit = light_col * FACING;
		lit = lit / (1.0 + lit);
		float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
		float head = 1.0 - lum;
		float t = clamp((lum - 0.25) / 0.4, 0.0, 1.0);
		float gain = mix(4.0, 1.2, t) * head;
		float add = mix(0.35, 0.12, t) * head;
		c = min(c * ambient * (1.0 + lit * gain) + lit * add, vec3(1.0));
		c = mix(c, CHAR, scorch * 0.65);
		c = mix(c, FROST, frost * 0.35) * tint;
	}
	if (cut_mode == -1 && p.y < line + 2.0) {
		c = mix(c, MOLTEN, molten);
	}
	COLOR = vec4(c, px.a) * COLOR;
}
