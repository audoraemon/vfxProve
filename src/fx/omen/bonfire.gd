class_name BonfireFx
extends FxTimeline
## The Feast of Lanterns' bonfire (v0.09, FestivalDirector): a stack of logs at `origin` burns for `extra.seconds`
## with flames and drifting embers over a warm, flickering ground light. Light only: it harms nobody, registers no
## threat, and neither stalls the frame (no impact frame, no hitstop) nor shakes the camera, so the scripted runs stay
## exact. Not a cast, so it locks no slot.

## The pool of light on the ground, in ground units, and its warmth.
const LIGHT_RADIUS := 3.2
const LIGHT := Color(1.0, 0.62, 0.26)
## Seconds the fire takes to catch and to die down.
const CATCH := 1.5
const DIE := 2.0
## The logs: a dark stack, in screen pixels from the origin.
const LOG_DARK := Color("3a2616")
const LOG_LIGHT := Color("5a3a22")

var _light: QuadFx


func _build() -> void:
	duration = float(extra.get("seconds", 150.0))
	busy = 0.0
	var at_px := Iso.ground_to_screen(origin)
	_light = FxParts.ground_light(self, origin, LIGHT_RADIUS, LIGHT, 0.0)
	FxParts.emitter(self, ctx.overhead, at_px + Vector2(0, -3), PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 26.0,
		duration, {"radius": 3.0, "speed": Vector2(1, 4), "alt": Vector2(0, 2), "alt_speed": Vector2(14, 30),
		"life": Vector2(0.4, 0.8), "size": Vector2(2, 4), "size_end_mul": 0.4})
	var embers := FxParts.emitter(self, ctx.overhead, at_px + Vector2(0, -8), PixelParticles.Shape.SQUARE,
		FxParts.EMBER_LIFE, 5.0, duration, {"radius": 3.0, "speed": Vector2(2, 10), "alt": Vector2(0, 6),
		"alt_speed": Vector2(10, 30), "life": Vector2(0.8, 1.8), "size": Vector2(1, 1)})
	embers.gravity = -6.0
	queue_redraw()


func _fade() -> float:
	return clampf(minf(t / CATCH, (duration - t) / DIE), 0.0, 1.0)


## The light breathes with the flames.
func _fx_process(_delta: float) -> void:
	if is_instance_valid(_light):
		_light.set_param("intensity", 0.55 * _fade() * (0.85 + 0.15 * sin(t * 9.0) * sin(t * 3.7)))


func _draw() -> void:
	var at := Iso.ground_to_screen(origin).round()
	draw_rect(Rect2(at + Vector2(-4, -3), Vector2(8, 2)), LOG_DARK)
	draw_rect(Rect2(at + Vector2(-3, -4), Vector2(6, 1)), LOG_LIGHT)
	draw_rect(Rect2(at + Vector2(-2, -5), Vector2(4, 1)), LOG_DARK)
