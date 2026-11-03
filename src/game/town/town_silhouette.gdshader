// A sprite's shadow silhouette (TownShadows, round 4): its opaque texels in white, so the shadow group's colour
// (CanvasGroup self_modulate) gives the darkness once, however many silhouettes overlap.
shader_type canvas_item;

void fragment() {
	COLOR = vec4(1.0, 1.0, 1.0, step(0.5, texture(TEXTURE, UV).a));
}
