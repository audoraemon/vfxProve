shader_type canvas_item;
// Wind for decor and the forest layer: vertices whose UV.y carries a weight (ArtKit.wind_*) move, the rest stay.
// The same motion as structure_art.gdshader's (keep the two in step): a positive weight is a slow sway, px across; a
// negative one a ripple (cloth, flags), mostly up and down along the edge. Offsets are whole pixels, and the phase
// comes from where the vertex's node stands, so neighbours do not move in step. `wind` 0 stills everything.
// A textured quad (ArtKit.tex, a decor sprite) carries the texture's UV instead: it sways by its height in the sprite,
// `sprite_sway` px at its top (per material: Decor.MOTION), or with `bob` > 0 the whole quad rises and falls that many
// px instead (a boat on the water; no shear). Untextured (procedural) pieces move as before, whatever the material.

uniform float wind = 1.0;
uniform float sprite_sway = 1.5;
uniform float bob = 0.0;

void vertex() {
	vec2 at = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	// The forest is one node: there its trees' own positions set their phases.
	float ph = at.x * 0.013 + at.y * 0.021 + VERTEX.x * 0.011 + VERTEX.y * 0.017;
	if (TEXTURE_PIXEL_SIZE.x < 1.0) {
		// A decor sprite's quad (ArtKit.tex): UV is the texture's, so the weight is the vertex's height in the sprite.
		if (bob > 0.0) {
			// The node's phase only: ph's vertex terms differ corner to corner and would shear the quad.
			float bph = at.x * 0.013 + at.y * 0.021;
			VERTEX.y += round(bob * sin(TIME * 2.1 + bph) * wind);
		} else {
			VERTEX.x += round(sprite_sway * (1.0 - UV.y) * sin(TIME * 1.3 + ph) * wind);
		}
	} else if (UV.y != 0.0) {
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
