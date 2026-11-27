// The Veil's own smooth noise (Evernight's wall, The Swallowing Dark's going-under): a few warped sines at unrelated frequencies,
// about 0..1. The shared value noise (common.gdshaderinc fbm) drew straight upright and diagonal cuts through these large quads on
// the GPU (fix round 1); this has no lattice, so it cannot.
float wn(vec2 p) {
	float w = sin(p.y * 1.3 + 0.7) * 1.4;
	return 0.5 + 0.2 * sin(p.x * 1.9 + w) + 0.15 * sin(p.y * 2.3 + p.x * 0.7 + 1.7)
		+ 0.09 * sin((p.x - p.y) * 3.7 + 4.1) + 0.06 * sin(p.x * 7.3 + p.y * 5.1 + w);
}
