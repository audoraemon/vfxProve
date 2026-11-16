// Pixel-art anti-aliasing for a texture drawn with linear filtering at a non-integer scale (a hosted world, WorldView):
// each texel is flat and only the last screen pixel at its edge blends with the neighbour, so a texel covering 2.75
// screen px never shows as 2 or 3 and never shimmers as the camera moves, yet stays sharp. At 1 screen px per texel
// (the references, a 1x root) the uv is unchanged.
vec2 pixel_aa(vec2 uv, vec2 texel) {
	vec2 t = uv / texel;
	vec2 seam = floor(t + 0.5);
	vec2 span = max(fwidth(t), vec2(1e-5));
	return (seam + clamp((t - seam) / span, -0.5, 0.5)) * texel;
}
