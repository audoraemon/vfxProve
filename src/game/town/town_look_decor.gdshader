// The DAY and NIGHT looks' extra lights (TownLookDecor): every prop and its flame drawn from one atlas, so neighbouring
// props batch. The atlas's top rows are the prop sprites (torch post, lamp post, house lantern), lit as decor is (the
// node's modulate, in the vertex colour). Below `band_v` lie the animated rows: four frames a row, cell_u wide each.
// A quad drawn from a band cell starts on the frame in that cell (its phase, chosen per prop), and steps through the
// row's four frames on the idle clock at `hz`. A flame or a lantern's glass writes its colour outright: the decor
// layer's dimming never reaches it, so it glows as the street lamps do (lamp_glass.gdshader).
// Round 3: a post takes its own lamp's warm light (self_lit: rgb its colour, a how far, 0 off), and fades out below the
// camera zoom post_zoom.x (gone) .. post_zoom.y (whole), so at overview zoom only the flames and glasses show.
shader_type canvas_item;

global uniform float idle_time;
uniform float band_v = 0.5;
uniform float cell_u = 0.125;
uniform float hz = 10.0;
uniform vec4 self_lit = vec4(0.0);
uniform vec2 post_zoom = vec2(0.0);

varying float post_alpha;

void vertex() {
	float zoom = length(CANVAS_MATRIX[0].xy);
	post_alpha = post_zoom.y > 0.0 ? smoothstep(post_zoom.x, post_zoom.y, zoom) : 1.0;
}

void fragment() {
	vec2 uv = UV;
	if (uv.y >= band_v) {
		float col0 = floor(uv.x / cell_u);
		float f = mod(col0 + floor(idle_time * hz), 4.0);
		uv.x += (f - col0) * cell_u;
		COLOR = texture(TEXTURE, uv);
	} else {
		vec4 t = texture(TEXTURE, uv);
		vec4 c = t * COLOR;
		c.rgb = mix(c.rgb, t.rgb * self_lit.rgb, self_lit.a);
		c.a *= post_alpha;
		COLOR = c;
	}
}
