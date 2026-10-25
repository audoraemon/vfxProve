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
	g += c * texture(light_tex, SCREEN_UV).rgb * light_warm * light_gain;
	float ember = smoothstep(0.6, 0.9, c.r) * smoothstep(0.2, 0.45, c.r - c.b) * keep_lit;
	// Clamped as TownGrade.grade_pixel() is (the framebuffer would clamp it anyway).
	COLOR = vec4(clamp(mix(g, c, ember), 0.0, 1.0), 1.0);
}
