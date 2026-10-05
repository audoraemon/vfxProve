shader_type canvas_item;
// Wind for decor and the forest layer: vertices whose UV.y carries a weight (ArtKit.wind_*) move, the rest stay.
// The same motion as structure_art.gdshader's (keep the two in step): a positive weight is a slow sway, px across; a
// negative one a ripple (cloth, flags), mostly up and down along the edge. Offsets are whole pixels, and the phase
// comes from where the vertex's node stands, so neighbours do not move in step. `wind` 0 stills everything.
// A textured quad (ArtKit.tex, a decor sprite) carries the texture's UV instead: it sways by its height in the sprite,
// `sprite_sway` px at its top (per material: Decor.MOTION), or with `bob` > 0 the whole quad rises and falls that many
// px instead (a boat on the water; no shear). Untextured (procedural) pieces move as before, whatever the material.
// An animated decor set (DecorSprites: a horizontal strip, `anim_frames` frames each `frame_u` wide in UV) draws frame
// 0's rect; its quad's UVs step along the strip to frame floor(idle_time * anim_fps + phase) mod anim_frames. The
// step runs on the idle clock (SpriteView.idle_time, advanced by EnvironmentField), so it holds while the mission is
// frozen; the phase is from where the node stands, so a herd does not step in time. It shifts UV.x only, so the sway
// weight (1 - UV.y) and a mirrored quad (its u's swapped within frame 0) hold.

global uniform float idle_time;
uniform float wind = 1.0;
uniform float sprite_sway = 1.5;
uniform float bob = 0.0;
uniform int anim_frames = 1;
uniform float anim_fps = 0.0;
uniform float frame_u = 0.0;

void vertex() {
	vec2 at = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	// The forest is one node: there its trees' own positions set their phases.
	float ph = at.x * 0.013 + at.y * 0.021 + VERTEX.x * 0.011 + VERTEX.y * 0.017;
	if (TEXTURE_PIXEL_SIZE.x < 1.0) {
		// A decor sprite's quad (ArtKit.tex): UV is the texture's, so the weight is the vertex's height in the sprite.
		if (anim_frames > 1) {
			// The node's own phase, the same at every corner (a hash: neighbours a few px apart step apart).
			float aph = fract(sin(dot(floor(at), vec2(12.9898, 78.233))) * 43758.5453) * float(anim_frames);
			UV.x += mod(floor(idle_time * anim_fps + aph), float(anim_frames)) * frame_u;
		}
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
