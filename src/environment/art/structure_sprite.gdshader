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
// A playing idle strip (SpriteView.play_idle()): the frame is floor(idle_time * idle_fps + idle_phase) mod idle_frames,
// stepped here from the shared clock so no view processes; the draw is frame 0's, shifted frame_w px per frame.
// idle_frames 1: a plain still or a held frame.
global uniform float idle_time;
uniform int idle_frames = 1;
uniform float idle_fps = 1.0;
uniform float idle_phase = 0.0;
uniform float frame_w = 0.0;

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

// A lit window or a fire: warm (red strongest, some green), very bright and strongly saturated. Pale warm stone (the
// cathedral's sandstone, saturation ~0.5) must stay out, or whole walls ignore the dim and never char.
// tools/dev/check_sprite_glow.py holds the same rule: change both together.
bool glows(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	return c.r >= mx && mx > 0.93 && (mx - mn) / mx > 0.55 && c.g > 0.45;
}

// The draw's modulate (the blight's tint, a fade) alone: the fragment's COLOR comes in already multiplied by the
// texture, which the lighting below has used once.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec2 uv = UV;
	if (idle_frames > 1) {
		float f = mod(floor(idle_time * idle_fps + idle_phase), float(idle_frames));
		uv.x += f * frame_w * TEXTURE_PIXEL_SIZE.x;
	}
	vec4 px = texture(TEXTURE, uv);
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
	COLOR = vec4(c, px.a) * modulate;
}
