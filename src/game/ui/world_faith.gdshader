shader_type canvas_item;
// The god's faith on the World Map: about each open town, a wash of the god's colour that stays on the land (it stops at the coast and
// the rivers) inside an inked, slightly wandering border. A town's reach grows with the part of its people that believe.

uniform sampler2D land : filter_linear, repeat_disable;  // white on land, black on water
uniform vec3 towns[4];                                   // page x, page y, reach (0: none)
uniform vec4 fill : source_color = vec4(0.9, 0.4, 0.2, 1.0);
uniform vec4 edge : source_color = vec4(0.3, 0.1, 0.05, 1.0);
uniform float time = 0.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 p = UV * vec2(640.0, 360.0);
	float field = -1000.0;
	float ang_at = 0.0;
	for (int i = 0; i < 4; i++) {
		float reach = towns[i].z;
		if (reach <= 0.0) {
			continue;
		}
		vec2 d = (p - towns[i].xy) * vec2(1.0, 1.45);
		float ang = atan(d.y, d.x);
		float wander = 1.0 + 0.09 * sin(ang * 5.0 + float(i) * 2.1) + 0.05 * sin(ang * 11.0 + 1.3 + float(i)) + 0.012 * sin(time * 0.7 + ang * 3.0);
		float f = reach * wander - length(d);
		if (f > field) {
			field = f;
			ang_at = ang + float(i) * 7.0;
		}
	}
	float coast = texture(land, UV).r;
	float on_land = smoothstep(0.42, 0.62, coast);
	float inside = smoothstep(0.0, 2.0, field) * on_land;
	float deep = smoothstep(0.0, 60.0, field);
	// a pen's line: it swells and thins along its way, and lifts off the vellum here and there
	float along = ang_at * 14.0;
	float seg = floor(along);
	float thick = 2.0 + 1.6 * hash(seg) + 0.8 * sin(along * 0.37);
	float lift = step(0.13, hash(seg + 31.0));
	float border = smoothstep(0.0, 0.9, field) * (1.0 - smoothstep(thick, thick + 1.3, field)) * lift;
	// ticks set inward from the border, as a mapmaker marks a realm
	float tick = step(0.82, fract(along * 0.5)) * smoothstep(thick + 1.0, thick + 1.6, field) * (1.0 - smoothstep(thick + 5.0, thick + 5.8, field));
	// the border also runs along the coast and the rivers inside the god's hold
	float shore = smoothstep(0.30, 0.48, coast) * (1.0 - smoothstep(0.55, 0.75, coast)) * smoothstep(0.0, 2.0, field);
	float line = max(max(border, tick * 0.8) * on_land, shore * 0.7);
	float wash = inside * (0.24 + 0.12 * deep);
	COLOR = vec4(mix(fill.rgb, edge.rgb, line), max(wash, line * 0.88));
}
