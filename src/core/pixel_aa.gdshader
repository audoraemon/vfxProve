shader_type canvas_item;
// A plain texture draw with pixel-art anti-aliasing (pixel_aa.gdshaderinc): the town's baked floor.

#include "res://src/core/pixel_aa.gdshaderinc"

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, pixel_aa(UV, TEXTURE_PIXEL_SIZE)) * modulate;
}
