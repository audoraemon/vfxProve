// A tagged person's outline where something stands in front of them (covered-outline, TagOutlines): the person's own sprite frame
// is drawn again over the finished world, and only its edge texels (opaque, with a see-through or out-of-frame 4-neighbour) that the
// occluder mask covers are kept, in the tag's colour. The mask is a small SubViewport that renders just the things drawn in front of
// that person (TagOutlines.Slot), aligned to the world viewport's device pixels: its texel at FRAGCOORD - mask_origin.
shader_type canvas_item;

// The occluders in front of this person, rendered at the world's device pixels (alpha only matters).
uniform sampler2D mask : filter_nearest;
// The mask's top-left in the world viewport's device px.
uniform vec2 mask_origin;
// The person's frame in the people atlas: texel x, y, width, height (the neighbours outside it count as empty).
uniform vec4 region;
uniform vec4 tag_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
// Covered: the occluders' alpha there at least this (a building's soft, linear-filtered edge lets the body show through below it, and a
// cast shadow or a glow is no cover).
const float MASK_SOLID = 0.9;

bool in_frame(ivec2 t) {
	return float(t.x) >= region.x && float(t.y) >= region.y && float(t.x) < region.x + region.z && float(t.y) < region.y + region.w;
}

void fragment() {
	// TEXTURE is read here, not handed to a function (a built-in sampler as a function argument is not supported everywhere).
	ivec2 t = ivec2(floor(UV / TEXTURE_PIXEL_SIZE));
	if (!in_frame(t) || texelFetch(TEXTURE, t, 0).a <= 0.5) {
		discard;
	}
	ivec2 r = t + ivec2(1, 0);
	ivec2 l = t - ivec2(1, 0);
	ivec2 d = t + ivec2(0, 1);
	ivec2 u = t - ivec2(0, 1);
	bool edge = !in_frame(r) || texelFetch(TEXTURE, r, 0).a <= 0.5 || !in_frame(l) || texelFetch(TEXTURE, l, 0).a <= 0.5
		|| !in_frame(d) || texelFetch(TEXTURE, d, 0).a <= 0.5 || !in_frame(u) || texelFetch(TEXTURE, u, 0).a <= 0.5;
	if (!edge) {
		discard;
	}
	ivec2 m = ivec2(floor(FRAGCOORD.xy - mask_origin));
	ivec2 size = textureSize(mask, 0);
	if (m.x < 0 || m.y < 0 || m.x >= size.x || m.y >= size.y || texelFetch(mask, m, 0).a < MASK_SOLID) {
		discard;
	}
	COLOR = vec4(tag_color.rgb, 1.0);
}
