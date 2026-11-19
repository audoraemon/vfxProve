class_name SlumberFx
extends FxTimeline
## Slumber (Veil, Tier 2): a hush that settles on the click. T_FALL after the cast everyone out in the open within the circle
## (VeilRules: 1.5 light / 3.5 dark) -- citizens, watchmen, soldiers -- sleeps where they stand for SLEEP_TIME (Person.sleep()). In the
## light a loud blow or a hurt wakes a sleeper, as with Curfew; in the dark it is a deep sleep that noise does not wake, only a hurt.
## Quiet: no danger, no fright, no alarm. Its dusk is laid at the cast, under the settling hush (VeilParts.land(); VB0). The sleep is the sleeper's own timer,
## so the effect holds nothing to undo: ending it early wakes nobody, and a second cast on a sleeper only runs the sleep to the later end.

const SLEEP_TIME := 20.0
const T_FALL := 0.6
const LID := [Color("b98cff"), Color("5a2aa8"), Color("2a1050"), Color(0.04, 0.02, 0.09, 0.5)]

## How many fell asleep.
var asleep := 0
var _dark := false
var _r := 0.0


func _build() -> void:
	_dark = VeilParts.dark(self)
	_r = VeilParts.size(self, "slumber", "RADIUS")
	duration = T_FALL + 1.2
	busy = T_FALL
	at(T_FALL, _fall)
	VeilParts.land(self, origin, _r)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, _r, VeilParts.VEIL, 2, 30.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_FALL, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	mark.life = T_FALL + 0.1
	# Dusk settles from above, slowly.
	var down := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -34), PixelParticles.Shape.PUFF, LID)
	down.drag = 1.4
	down.gravity = 18.0
	down.burst(14, {"radius": _r * 12.0, "speed": Vector2(2, 8), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 6),
		"alt_speed": Vector2(-8, 0), "life": Vector2(0.6, 0.9), "size": Vector2(2, 3), "size_end_mul": 0.4})


## The living out in the open within `r` of `at`, nearest first and then by instance id (no luck): who Slumber puts to sleep.
static func sleepers_at(field: EnemyField, at: Vector2, r: float) -> Array[Person]:
	var out := DominionParts.near(field, at, r)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if is_equal_approx(da, db):
			return a.get_instance_id() < b.get_instance_id()
		return da < db)
	return out


func _fall() -> void:
	var staged := DominionParts.staged(self)
	if ctx.field != null:
		for p in sleepers_at(ctx.field, origin, _r):
			if p.sleep(SLEEP_TIME, _dark):
				asleep += 1
				if staged:
					DominionParts.motes(self, p.ground_pos, LID, 4)
	if not staged:
		return
	# A slow violet hush: a soft ring settles to the edge. No flash.
	var w := FxParts.shockwave(self, origin, _r, FxParts.VOID)
	w.set_param("thickness", 0.1)
	w.tween_param("progress", 0.05, 1.0, 0.9, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	w.tween_param("fade", 1.0, 0.0, 0.5, 0.5)
	w.life = 1.05
