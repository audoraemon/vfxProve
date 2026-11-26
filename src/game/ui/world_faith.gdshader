shader_type canvas_item;
// The god's faith on the World Map: about each open town, a wash of the god's colour that stays on the land (it stops at the coast and
// the rivers) inside an inked, slightly wandering border. A town's reach grows with the part of its people that believe.

uniform sampler2D land : filter_linear, repeat_disable;  // white on land, black on water
uniform vec3 towns[4];                                   // page x, page y, reach (0: none)
uniform vec4 fill : source_color = vec4(0.9, 0.4, 0.2, 1.0);
uniform vec4 edge : source_color = vec4(0.3, 0.1, 0.05, 1.0);
uniform float time = 0.0;

void fragment() {
	vec2 p = UV * vec2(640.0, 360.0);
	float field = -1000.0;
	for (int i = 0; i < 4; i++) {
		float reach = towns[i].z;
		if (reach <= 0.0) {
			continue;
		}
		vec2 d = (p - towns[i].xy) * vec2(1.0, 1.45);
		float ang = atan(d.y, d.x);
		float wander = 1.0 + 0.09 * sin(ang * 5.0 + float(i) * 2.1) + 0.05 * sin(ang * 11.0 + 1.3 + float(i)) + 0.012 * sin(time * 0.7 + ang * 3.0);
		field = max(field, reach * wander - length(d));
	}
	float on_land = smoothstep(0.42, 0.62, texture(land, UV).r);
	float inside = smoothstep(0.0, 2.0, field) * on_land;
	float deep = smoothstep(0.0, 60.0, field);
	float border = smoothstep(0.0, 1.2, field) * (1.0 - smoothstep(2.4, 4.2, field));
	// the border also runs along the coast and the rivers inside the god's hold
	float shore = smoothstep(0.30, 0.48, texture(land, UV).r) * (1.0 - smoothstep(0.55, 0.75, texture(land, UV).r)) * smoothstep(0.0, 2.0, field);
	float line = max(border * on_land, shore * 0.8);
	float wash = inside * (0.24 + 0.12 * deep);
	COLOR = vec4(mix(fill.rgb, edge.rgb, line), max(wash, line * 0.85));
}
