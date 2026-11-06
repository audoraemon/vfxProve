class_name SkyliftFx
extends FxTimeline
## Skylift (Passage, Tier I): a beam takes what stands in one place and sets it down in another. Two clicks: where it
## takes from, and where it sets down (extra "to"). A bright blue light stands on the first place for T_TAKE; then
## everyone within RADIUS of it -- any role; those inside a building are not reached -- is gone from there and stands
## at the second place, each as far from its middle as they stood from the first's (DummyEnemy.fold(): a person keeps
## what it meant to do, and walks on toward it from where it was set down). A second, shorter light marks the arrival.
## Nobody is hurt and nothing is broken. Quiet, but for the book entry's "alarm": a light from the sky is seen.

const RADIUS := 1.5
const T_TAKE := 1.2
const T_SET := 0.5
const BLUE := Color(0.45, 0.75, 1.0)
const PALE := Color(0.8, 0.92, 1.0)

## Where it sets them down, and how many it took.
var to := Vector2.ZERO
var taken := 0


## Whom a lift at `at` would take.
static func lifted_at(field: EnemyField, at: Vector2) -> Array:
	var out: Array = []
	for e in field.in_radius(at, RADIUS):
		var p := e as Person
		if p != null and p.inside:
			continue
		out.append(e)
	return out


func _build() -> void:
	to = extra.get("to", origin + Vector2(4.0, 0.0))
	duration = T_TAKE + T_SET + 0.8
	busy = T_TAKE
	at(T_TAKE, _take)
	ctx.play(&"q_skylift", origin)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	# The light comes down on the place: a column, a ring drawn in under it, the ground lit, motes drawn up into it.
	var column := Set2Parts.glow_column(self, sp, 64.0, 440.0, BLUE, 0.0, T_TAKE + 0.3)
	column.tween_param("intensity", 0.2, 1.5, T_TAKE * 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.tween_param("intensity", 1.5, 0.0, 0.3, T_TAKE)
	var core := Set2Parts.glow_column(self, sp, 22.0, 440.0, PALE, 0.0, T_TAKE + 0.2)
	core.tween_param("intensity", 0.0, 1.6, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	core.tween_param("intensity", 1.6, 0.0, 0.2, T_TAKE)
	var mark := FxParts.rings(self, origin, RADIUS, PALE, 2, 14.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_TAKE * 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = T_TAKE + 0.1
	var light := FxParts.ground_light(self, origin, RADIUS * 1.6, BLUE, 0.0)
	light.tween_param("intensity", 0.0, 1.4, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.tween_param("intensity", 1.4, 0.0, 0.3, T_TAKE)
	light.life = T_TAKE + 0.32
	var up := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, FxParts.ION_LIFE, 40.0, T_TAKE,
		{"radius": 20.0, "speed": Vector2(0, 6), "alt": Vector2(0, 10), "alt_speed": Vector2(120, 260), "life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})
	up.gravity = -60.0


## They are taken, and set down.
func _take() -> void:
	for e in lifted_at(ctx.field, origin):
		if e.fold(to + (e.ground_pos - origin)):
			taken += 1
	ctx.play(&"grav_shimmer", to, -4.0)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(0.7, 0.88, 1.0, 0.18), 0.25)
	var sp := Iso.ground_to_screen(origin)
	var dp := Iso.ground_to_screen(to)
	# Where they stood: the light snaps shut, a ring goes out, sparks fall.
	_ring(origin)
	FxParts.sparks(self, ctx.overhead, sp, 16, FxParts.ION_LIFE, Vector2(40, 160), Vector2(60, 220))
	# Where they are set down: the light comes down once more, shorter.
	var column := Set2Parts.glow_column(self, dp, 64.0, 440.0, BLUE, 1.5, T_SET)
	column.tween_param("intensity", 1.5, 0.0, T_SET, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var core := Set2Parts.glow_column(self, dp, 22.0, 440.0, PALE, 1.6, T_SET * 0.7)
	core.tween_param("intensity", 1.6, 0.0, T_SET * 0.7)
	_ring(to)
	var light := FxParts.ground_light(self, to, RADIUS * 1.6, BLUE, 1.4)
	light.tween_param("intensity", 1.4, 0.0, T_SET + 0.2)
	light.life = T_SET + 0.22
	FxParts.sparks(self, ctx.overhead, dp, 12, FxParts.ION_LIFE, Vector2(30, 120), Vector2(40, 160))


func _ring(at_ground: Vector2) -> void:
	var ring := FxParts.shockwave(self, at_ground, RADIUS + 0.6, FxParts.ION)
	ring.set_param("thickness", 0.1)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.16)
	ring.life = 0.38
