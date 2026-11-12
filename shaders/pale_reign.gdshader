// Pale Reign: the colour drained out of an iso circle -- the street, the houses and the people standing in it go to the
// grey of their own light, cooled a little toward ash. `amount` 0..1 fades it in and out; the rim is dithered, so the edge
// of the grey stays pixel-sharp.
shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount = 0.0;
uniform vec4 ash : source_color = vec4(0.86, 0.88, 0.9, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0 || amount <= 0.0) discard;
	float rim = 1.0 - smoothstep(0.78, 1.0, r);
	float k = quant_d(amount * rim, 6.0, FRAGCOORD.xy);
	if (k <= 0.0) discard;
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(col, vec3(l) * ash.rgb, k), 1.0);
}
