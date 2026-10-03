class_name FallingStarFx
extends FxTimeline
## The Warning's omen (v0.08): a star streaks down from high above and lands at `origin` over FALL seconds, with a
## white-gold flash, a ring of sparks and a ground light that fades. A sign, not a power: it harms nobody, registers
## no threat, and neither stalls the frame (no impact frame, no hitstop) nor shakes the camera -- the scripted runs stay
## exact. Not a cast, so it locks no slot.

## How long the fall takes, and where it starts: screen pixels from the landing point.
const FALL := 0.6
const FROM := Vector2(-40.0, -160.0)
## Gold-white motes shed by the falling star, brightest first.
const TRAIL := [Color("ffffff"), Color("fff2c0"), Color("ffd27a"), Color("d8b23a"), Color(0.55, 0.42, 0.15, 0.5)]
const STAR_LIGHT := Color(1.0, 0.92, 0.7)
## Motes shed per second along the streak.
const TRAIL_RATE := 220.0

var _land_px := Vector2.ZERO
var _trail: PixelParticles
var _head: QuadFx
var _shed := 0.0


func _build() -> void:
	duration = 2.0
	busy = 0.0
	_land_px = Iso.ground_to_screen(origin)
	_trail = FxParts.particles(self, ctx.overhead, _land_px, PixelParticles.Shape.STREAK, TRAIL)
	_trail.drag = 2.0
	_trail.streak_len = 0.06
	_trail.auto_free = false
	_head = FxParts.bloom(self, _land_px + FROM, 7.0, STAR_LIGHT, 1.4)
	_head.life = FALL + 0.02
	ctx.play(&"grav_shimmer", origin, -16.0)
	at(FALL, _land)


## The star's head along its fall: from FROM above the landing point down to it, easing in.
func _head_at(k: float) -> Vector2:
	return FROM * (1.0 - k * k)


func _fx_process(delta: float) -> void:
	if t > FALL:
		return
	var k := clampf(t / FALL, 0.0, 1.0)
	var off := _head_at(k)
	if is_instance_valid(_head):
		_head.position = _land_px + off
	var dir := -FROM.normalized()
	_shed += TRAIL_RATE * delta
	while _shed >= 1.0:
		_shed -= 1.0
		_trail.burst(1, {"offset": off + Vector2(ctx.rng.randf_range(-1.5, 1.5), ctx.rng.randf_range(-1.5, 1.5)),
			"velocity": dir * ctx.rng.randf_range(10.0, 40.0), "life": Vector2(0.2, 0.5), "size": Vector2(1, 2)})


func _land() -> void:
	ctx.play(&"grav_shimmer", origin, -10.0)
	var bloom := FxParts.bloom(self, _land_px + Vector2(0, -4), 34.0, STAR_LIGHT, 1.2, 0.8)
	bloom.tween_param("intensity", 1.2, 0.0, 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.life = 0.72
	var burst := FxParts.screen_rays(self, _land_px + Vector2(0, -4), 40.0, STAR_LIGHT, 16.0, 0.6)
	burst.tween_param("intensity", 1.4, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.52
	var light := FxParts.ground_light(self, origin, 2.2, STAR_LIGHT)
	light.tween_param("intensity", 0.9, 0.0, 1.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 1.32
	FxParts.sparks(self, ctx.overhead, _land_px, 22, TRAIL, Vector2(40, 120), Vector2(20, 90))
