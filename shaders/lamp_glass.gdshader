shader_type canvas_item;
// A sprite house lantern's lit glass (Decor.LampGlass): the sprite street lamp's glass (Structure.draw_lamp_glass), a
// pale core inside a 1 px amber ring that burns deep orange one step in four, stepping on the idle clock
// (SpriteView.idle_time) at `hz`, `phase` steps out of step (Structure.lamp_glass_step()). The node draws one quad over
// `rect` (local px); this shader colours it by position, and writes COLOR outright: the decor layer's modulate (the
// ambient dimming, already in the vertex colour) is dropped, so the glass glows undimmed as the street lamps do.

global uniform float idle_time;
uniform vec4 rect = vec4(0.0, 0.0, 3.0, 5.0);
uniform float hz = 6.0;
uniform float phase = 0.0;
uniform vec4 core_color : source_color = vec4(1.0);
uniform vec4 ring_color : source_color = vec4(1.0);
uniform vec4 low_color : source_color = vec4(1.0);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	bool core = local.x >= rect.x + 1.0 && local.x < rect.x + rect.z - 1.0
		&& local.y >= rect.y + 1.0 && local.y < rect.y + rect.w - 1.0;
	float step_now = mod(floor(idle_time * hz + phase), 4.0);
	COLOR = core ? core_color : (step_now < 0.5 ? low_color : ring_color);
}
