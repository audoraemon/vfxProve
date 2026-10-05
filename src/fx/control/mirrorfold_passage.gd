class_name MirrorfoldFx
extends FxTimeline
## Mirrorfold Passage: two mirrors laid on the ground, thin as a film -- the way in at the first click (origin) and the
## way out at the second (exit). Each is a long oval, HALF_WIDE across the screen by HALF_DEEP. Anyone who walks onto
## the way in -- citizen, soldier, responder -- is that instant standing on the same spot of the way out, still
## walking, still meaning to go where they were going (DummyEnemy.fold()). Nobody in the town notices: no danger and
## no alarm. To the player each shows as a hairline rim with a glint drifting round it, a faint reflection, a slow
## ripple, a sheen crossing it now and then, and a few motes; a crossing flares both, with the walker drawn into the
## way in and let out of the way out in a scatter of light. It is one way: the way out takes nobody back. Those already
## standing on the way in when it is laid are left alone until they step off and back on. After MIRROR_TIME both are
## gone. It locks the other slots only while it is cast (busy).

const MIRROR_TIME := 30.0
## The oval's half-lengths in ground units: along the screen's horizontal, and along its vertical.
const HALF_WIDE := 2.4
const HALF_DEEP := 1.0
## The two never overlap: the way out is at least this far from the way in.
const MIN_APART := HALF_WIDE * 2.0 + 0.2
## Seconds the surface takes to settle when laid, and to lift at the end.
const LAY := 0.7
const LIFT := 0.9
## A sheen crosses each surface every SHEEN_EVERY seconds, taking SHEEN seconds.
const SHEEN_EVERY := 4.5
const SHEEN := 1.2
## Seconds a crossing's ripple runs, and its flare fades.
const PULSE := 0.6
const FLASH := 0.5
const SHADER := preload("res://shaders/mirror_fold.gdshader")
## Ground directions of the oval's long and short axes: across the screen, and down it.
const ACROSS := Vector2(0.70710678, -0.70710678)
const DOWN := Vector2(0.70710678, 0.70710678)
const GLASS := [Color("f0faff"), Color("b8e4ff"), Color("78b8e0"), Color(0.35, 0.6, 0.8, 0.5)]
const GLASS_LIGHT := Color(0.6, 0.85, 1.0)

## Where the way out lies.
var exit := Vector2.ZERO
## How many have been folded through.
var folded := 0

## Who stood on the way in at the last step, by instance id: only stepping onto it folds.
var _within := {}
var _faces: Array[QuadFx] = []
var _pulse_age: Array[float] = [PULSE, PULSE]
var _flash_age: Array[float] = [FLASH, FLASH]


## `g` as the oval at `center` sees it: x across it and y down it, each -1..1 inside.
static func local(center: Vector2, g: Vector2) -> Vector2:
	var rel := g - center
	return Vector2(rel.dot(ACROSS) / HALF_WIDE, rel.dot(DOWN) / HALF_DEEP)


## Whether `g` lies on a mirror centred on `center`.
static func on_mirror(center: Vector2, g: Vector2) -> bool:
	return local(center, g).length_squared() <= 1.0


## Where the way out goes for a way in at `from` and a second click at `to`: at `to`, or MIN_APART along the way
## when that is too near.
static func exit_for(from: Vector2, to: Vector2) -> Vector2:
	var drag := to - from
	if drag.length() >= MIN_APART:
		return to
	return from + (drag.normalized() if drag.length() > 0.01 else Vector2(1, 0)) * MIN_APART


func _build() -> void:
	duration = MIRROR_TIME
	busy = 1.0
	exit = exit_for(origin, extra.get("to", origin + (extra.get("dir", Vector2(1, 0)) as Vector2) * MIN_APART))
	for e in ctx.field.alive():
		if on_mirror(origin, e.ground_pos):
			_within[e.get_instance_id()] = true
	ctx.play(&"grav_shimmer", origin, -14.0)
	if ctx.distort == null:
		return
	var size := Vector2(HALF_WIDE, HALF_DEEP) * Vector2(FxParts.PX_PER_UNIT_MAJOR, FxParts.PX_PER_UNIT_MINOR) * 2.0
	for center: Vector2 in [origin, exit]:
		var q := FxParts.quad(self, SHADER, size, ctx.distort)
		q.position = Iso.ground_to_screen(center)
		q.set_param("size_px", size)
		q.set_param("presence", 0.0)
		_faces.append(q)
		# A few motes drifting up off the glass, so an eye can find it.
		var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(center), PixelParticles.Shape.SQUARE, GLASS,
			3.0, MIRROR_TIME - LIFT, {"radius": size.x * 0.42, "speed": Vector2(1, 4), "alt": Vector2(0, 3),
			"alt_speed": Vector2(5, 12), "life": Vector2(1.0, 1.8), "size": Vector2(1, 1)})
		motes.gravity = -4.0
		# The glass laid down: a soft light under it for a moment.
		var light := FxParts.ground_light(self, center, HALF_WIDE * 0.9, GLASS_LIGHT, 0.0)
		light.tween_param("intensity", 0.5, 0.0, LAY + 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		light.life = LAY + 0.65


func _fx_process(delta: float) -> void:
	_fold_step()
	var presence := clampf(minf(t / LAY, (duration - t) / LIFT), 0.0, 1.0)
	# The sheen crosses once as it is laid, once as it lifts, and now and then between.
	var shimmer := 0.0
	if t < LAY:
		shimmer = t / LAY
	elif duration - t < LIFT:
		shimmer = clampf(1.0 - (duration - t) / LIFT, 0.0, 1.0)
	else:
		var cycle := fmod(t - LAY, SHEEN_EVERY)
		shimmer = cycle / SHEEN if cycle < SHEEN else 0.0
	for i in _faces.size():
		_pulse_age[i] = minf(_pulse_age[i] + delta, PULSE)
		_flash_age[i] = minf(_flash_age[i] + delta, FLASH)
		var q := _faces[i]
		if not is_instance_valid(q):
			continue
		q.set_param("presence", presence)
		q.set_param("shimmer", shimmer)
		q.set_param("pulse", _pulse_age[i] / PULSE)
		q.set_param("flash", 1.0 - _flash_age[i] / FLASH)


## Everyone who has stepped onto the way in since the last step comes out of the way out.
func _fold_step() -> void:
	var now := {}
	for e in ctx.field.alive():
		if not on_mirror(origin, e.ground_pos):
			continue
		var id := e.get_instance_id()
		if _within.has(id):
			now[id] = true
			continue
		var at := local(origin, e.ground_pos)
		var from := e.ground_pos
		if e.fold(exit + (e.ground_pos - origin)):
			folded += 1
			_crossing(at, from, e.ground_pos)
		else:
			now[id] = true  # nowhere to set it down: it walks on across, as if nothing lay there
	_within = now


## A crossing: both faces flare and ripple from where they stepped; light is drawn into the way in after the walker
## and scatters off the way out ahead of it.
func _crossing(at: Vector2, from: Vector2, to: Vector2) -> void:
	for i in _faces.size():
		if is_instance_valid(_faces[i]):
			_faces[i].set_param("pulse_at", at)
			_pulse_age[i] = 0.0
			_flash_age[i] = 0.0
	if ctx.distort == null:
		return
	ctx.play(&"grav_arc", to, -6.0)
	var sink := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(from) + Vector2(0, -8), PixelParticles.Shape.STREAK, GLASS)
	sink.drag = 1.0
	sink.burst(14, {"radius": 12.0, "speed": Vector2(40, 90), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 14),
		"alt_speed": Vector2(-30, -8), "life": Vector2(0.25, 0.45), "size": Vector2(1, 2)})
	var rise := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(to), PixelParticles.Shape.SQUARE, GLASS)
	rise.gravity = -30.0
	rise.drag = 1.4
	rise.burst(18, {"radius": 5.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 16),
		"alt_speed": Vector2(10, 40), "life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})
	var glow := FxParts.bloom(self, Iso.ground_to_screen(to) + Vector2(0, -8), 18.0, GLASS_LIGHT, 0.8, 0.8)
	glow.tween_param("intensity", 0.8, 0.0, 0.45, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.5
