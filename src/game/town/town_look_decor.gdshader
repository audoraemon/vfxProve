// The DAY and NIGHT looks' extra lights (TownLookDecor): every prop and its flame drawn from one atlas, so neighbouring
// props batch. The atlas's top rows are the prop sprites (torch post, lamp post, house lantern), lit as decor is (the
// node's modulate, in the vertex colour). Below `band_v` lie the animated rows: four frames a row, cell_u wide each.
// A quad drawn from a band cell starts on the frame in that cell (its phase, chosen per prop), and steps through the
// row's four frames on the idle clock at `hz`. A flame or a lantern's glass writes its colour outright: the decor
// layer's dimming never reaches it, so it glows as the street lamps do (lamp_glass.gdshader).
shader_type canvas_item;

global uniform float idle_time;
uniform float band_v = 0.5;
uniform float cell_u = 0.125;
uniform float hz = 10.0;

void fragment() {
	vec2 uv = UV;
	if (uv.y >= band_v) {
		float col0 = floor(uv.x / cell_u);
		float f = mod(col0 + floor(idle_time * hz), 4.0);
		uv.x += (f - col0) * cell_u;
		COLOR = texture(TEXTURE, uv);
	} else {
		COLOR = texture(TEXTURE, uv) * COLOR;
	}
}
