// Shared helpers for pixel VFX shaders.
uniform float u_time = 0.0;

// Palette ramp, darkest (c0) to brightest (c4).
uniform vec4 c0 : source_color = vec4(0.35, 0.04, 0.03, 0.55);
uniform vec4 c1 : source_color = vec4(0.70, 0.14, 0.06, 1.0);
uniform vec4 c2 : source_color = vec4(1.00, 0.42, 0.10, 1.0);
uniform vec4 c3 : source_color = vec4(1.00, 0.76, 0.29, 1.0);
uniform vec4 c4 : source_color = vec4(1.00, 0.96, 0.85, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

float bayer4(vec2 fc) {
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	int x = int(mod(fc.x, 4.0));
	int y = int(mod(fc.y, 4.0));
	return (m[x + y * 4] + 0.5) / 16.0;
}

// Quantize 0..1 into `steps` levels.
float quant(float v, float steps) {
	return clamp(floor(v * steps + 0.5) / steps, 0.0, 1.0);
}

// Quantize with ordered dithering (pixel-art gradients).
float quant_d(float v, float steps, vec2 fc) {
	return clamp(floor(v * steps + bayer4(fc)) / steps, 0.0, 1.0);
}

// Map a 5-step quantized value to the palette. q == 0 is transparent.
vec4 ramp5(float q) {
	int i = int(round(q * 5.0));
	if (i <= 0) return vec4(0.0);
	if (i == 1) return c0;
	if (i == 2) return c1;
	if (i == 3) return c2;
	if (i == 4) return c3;
	return c4;
}
