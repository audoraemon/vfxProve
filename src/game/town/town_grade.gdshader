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

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float t = smoothstep(split - spread, split + spread, lum);
	vec3 g = c * gain * mix(cool, warm, t) + lift;
	float glum = dot(g, vec3(0.299, 0.587, 0.114));
	float blueness = smoothstep(0.04, 0.2, g.b - max(g.r, g.g));
	float dark = 1.0 - smoothstep(0.22, 0.5, glum);
	g = mix(g, vec3(glum) * vec3(0.92, 1.0, 1.1), calm * blueness * dark);
	float ember = smoothstep(0.6, 0.9, c.r) * smoothstep(0.2, 0.45, c.r - c.b) * keep_lit;
	COLOR = vec4(mix(g, c, ember), 1.0);
}
