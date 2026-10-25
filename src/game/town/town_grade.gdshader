// The DAY and NIGHT colour grade (TownGrade): a per-pixel colour transform of the finished world, so every edge stays
// as crisp as it was. Highlights take `warm`, darks take `cool`, split at `split` luminance; `gain` and `lift` set the
// overall light; calm greys the dark blues (water). keep_lit saves bright warm pixels (lit windows, flames) from the grade, so at night they still glow.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 lift = vec3(0.0);
uniform vec3 gain = vec3(1.0);
uniform vec3 warm = vec3(1.0);
uniform vec3 cool = vec3(1.0);
uniform float split = 0.5;
uniform float spread = 0.3;
uniform float keep_lit = 0.0;
// calm: how far dark, strongly blue pixels (the river under the moon) are pulled toward a grey-blue of their own light.
uniform float calm = 0.0;
// shoulder: the brightest graded pixels are pulled down by up to this fraction (a soft shoulder from `knee` luminance up),
// keeping their hue, so sunlit paving does not clip to a flat yellow. 0 = off.
uniform float shoulder = 0.0;
uniform float knee = 0.45;
// The light map (TownPools' buffer, the view at half resolution): every lamp, torch and lit window's light. It lights the
// ungraded colour (lit = graded + base * light * light_warm * light_gain), so near a lamp a wall, a roof or a person turns
// warm while its dark side, dark in the art, stays dark.
uniform sampler2D light_tex : hint_default_black, filter_linear;
uniform float light_gain = 0.0;
uniform vec3 light_warm = vec3(1.0);
// The view (TownGrade.follow_view): the viewport's size and its canvas transform (origin, zoom), so the light map is read
// once per world pixel and cut into light_steps levels through a 4x4 Bayer dither locked to the world: crisp pixels, no
// rings. Below zoom 1 a dither cell is ceil(1 / zoom) world pixels, at least one screen pixel.
uniform vec2 view_size = vec2(640.0, 360.0);
uniform vec2 view_origin = vec2(0.0);
uniform float view_zoom = 1.0;
uniform float light_steps = 16.0;
// The atmosphere (TownLook.atmosphere(), set per look and city by TownGrade). All off by default.
// Haze: a warm, half-desaturated fog thickening from haze_start to haze_end ground units outside the town (keep_out,
// keep_out2: ground rects, as the mist's), so the edge forest reads far away.
uniform vec4 keep_out = vec4(0.0);
uniform vec4 keep_out2 = vec4(0.0);
uniform float haze = 0.0;
uniform float haze_start = 3.0;
uniform float haze_end = 24.0;
uniform vec3 haze_col = vec3(0.95, 0.85, 0.66);
// Sunbeams outside the town walls (the town's own beams lie in its ground plane, TownMist): wide warm stripes slanting
// down and right from the sun, one every beam_period world px across, laid out from beam_origin as TownLook.beam_stripe()
// does, cut out of the town's ground rect (beam_keep, grown by a pad) and stepped through the world-locked dither.
uniform float beam = 0.0;
uniform vec2 beam_origin = vec2(0.0);
uniform float beam_slant = 0.55;
uniform float beam_period = 150.0;
uniform float beam_width = 40.0;
uniform vec4 beam_keep = vec4(0.0);
uniform vec3 beam_col = vec3(1.0, 0.9, 0.62);
// A sun glow in the screen's top left corner (screen space), and a vignette (both looks; NIGHT's a little stronger).
uniform float sun = 0.0;
uniform vec2 sun_at = vec2(0.0, 0.0);
uniform float sun_radius = 0.45;
uniform vec3 sun_col = vec3(1.0, 0.86, 0.55);
uniform float vignette = 0.0;

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int b[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(b[i.y * 4 + i.x]) + 0.5) / 16.0;
}

// The light at this fragment: the map read at its world cell's centre, then stepped through the dither.
vec3 light_at(vec2 screen_uv) {
	float k = max(ceil(1.0 / view_zoom - 0.001), 1.0);
	vec2 wp = (screen_uv * view_size - view_origin) / view_zoom;
	vec2 cell = floor(wp / k);
	vec2 uv = ((cell + 0.5) * k * view_zoom + view_origin) / view_size;
	vec3 l = texture(light_tex, uv).rgb;
	float m = max(l.r, max(l.g, l.b));
	if (m <= 0.0) {
		return vec3(0.0);
	}
	float q = floor(m * light_steps + bayer4(cell)) / light_steps;
	return l * (q / m);
}

float hash1(float k) {
	return fract(k * 0.6180340 + 0.31);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Ground units outside a ground rect (Chebyshev; 0 inside), or a large number for no rect.
float outside(vec2 g, vec4 r) {
	if (r.z <= 0.0) {
		return 1.0e4;
	}
	vec2 dd = max(max(r.xy - g, g - (r.xy + r.zw)), vec2(0.0));
	return max(dd.x, dd.y);
}

// The haze, beams, sun and vignette over the graded colour `o`.
vec3 atmosphere(vec3 o, vec2 screen_uv) {
	float k = max(ceil(1.0 / view_zoom - 0.001), 1.0);
	vec2 cell = floor((screen_uv * view_size - view_origin) / view_zoom / k);
	vec2 wp = (cell + 0.5) * k;
	// Ground units from world pixels (Iso: x = (gx - gy) * 32, y = (gx + gy) * 16).
	vec2 g = vec2(wp.x / 32.0 + wp.y / 16.0, wp.y / 16.0 - wp.x / 32.0) * 0.5;
	float dith = bayer4(cell);
	if (haze > 0.0) {
		float d = min(outside(g, keep_out), outside(g, keep_out2));
		float h = smoothstep(haze_start, haze_end, d) * haze;
		h = floor(h * 24.0 + dith) / 24.0;
		float l = dot(o, vec3(0.299, 0.587, 0.114));
		o = mix(o, mix(vec3(l), o, 0.5) * 0.45 + haze_col * 0.55, h);
	}
	if (beam > 0.0 && outside(g, beam_keep) > 0.0) {
		float u = wp.x - beam_origin.x - (wp.y - beam_origin.y) * beam_slant;
		float n = floor(u / beam_period + 0.5);
		float centre = n * beam_period + (hash1(n) - 0.5) * beam_period * 0.3;
		float hw = beam_width * (0.6 + 0.8 * hash1(n + 3.0));
		float p = 1.0 - smoothstep(hw * 0.25, hw, abs(u - centre));
		// Brighter toward the sun, broken by the drifting mist it cuts through.
		float toward = 1.0 - smoothstep(0.25, 1.05, screen_uv.x * 0.55 + screen_uv.y * 0.75);
		float mist = 0.65 + 0.35 * vnoise(g * 0.35 + vec2(TIME * 0.05, 0.0));
		float a = p * (0.55 + 0.45 * hash1(n + 7.0)) * toward * mist * beam;
		a = floor(a * 10.0 + dith) / 10.0;
		o = 1.0 - (1.0 - o) * (1.0 - beam_col * a);
	}
	if (sun > 0.0) {
		vec2 q = (screen_uv - sun_at) * vec2(view_size.x / view_size.y, 1.0);
		float r = length(q) / sun_radius;
		float s = sun * (exp(-r * r * 2.5) * 0.85 + 0.15 * exp(-r * 6.0));
		s = floor(s * 24.0 + bayer4(floor(screen_uv * view_size))) / 24.0;
		o = 1.0 - (1.0 - o) * (1.0 - sun_col * s);
	}
	if (vignette > 0.0) {
		vec2 q = (screen_uv - 0.5) * 2.0;
		float v = smoothstep(0.55, 1.5, length(q * vec2(1.0, 0.92)));
		o *= 1.0 - vignette * v;
	}
	return o;
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float t = smoothstep(split - spread, split + spread, lum);
	vec3 g = c * gain * mix(cool, warm, t) + lift;
	g *= 1.0 - shoulder * smoothstep(knee, 1.0, dot(g, vec3(0.299, 0.587, 0.114)));
	float glum = dot(g, vec3(0.299, 0.587, 0.114));
	// Water is found on the ungraded colour: the night grade makes every mid-dark pixel blue, so measuring after it would
	// grey the whole scene. Only what was already saturated blue qualifies (TownGrade.grade_pixel is the same formula).
	float blueness = smoothstep(0.08, 0.22, c.b - max(c.r, c.g));
	float dark = 1.0 - smoothstep(0.55, 0.95, lum);
	g = mix(g, vec3(glum) * vec3(0.92, 1.0, 1.1), calm * blueness * dark);
	// Soft roll-off: two lights overlapping warm the art more, but never blow it to white.
	vec3 lg = light_at(SCREEN_UV) * light_gain;
	g += c * lg / (1.0 + 1.0 * lg) * light_warm;
	float ember = smoothstep(0.6, 0.9, c.r) * smoothstep(0.2, 0.45, c.r - c.b) * keep_lit;
	// Clamped as TownGrade.grade_pixel() is (the framebuffer would clamp it anyway).
	vec3 o = clamp(mix(g, c, ember), 0.0, 1.0);
	COLOR = vec4(clamp(atmosphere(o, SCREEN_UV), 0.0, 1.0), 1.0);
}
