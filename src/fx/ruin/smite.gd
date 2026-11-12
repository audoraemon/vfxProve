class_name SmiteFx
extends FxTimeline
## Smite (Ruin, Tier I): one bolt from the sky on one spot. T_STRIKE after the cast it lands: whoever stands within
## KILL_R is struck down (damage kind lightning), and whatever stands within HIT_R takes DAMAGE -- a blow to one
## building, not its fall, and never a fire (damage kind smite: fire is Ember's). Seen and heard like any stroke of Ruin, only small
## (PowerBook.REACH). Precise and cheap: for the bellkeeper on the stair, a rite's ring, a wall already cracked.

const KILL_R := 0.6
const HIT_R := 0.7
const DAMAGE := 45.0
const T_STRIKE := 0.35
const BOLT := Color("9fd0ff")
const LIGHT := Color(0.7, 0.85, 1.0)
## Level 5, Forked Bolt: FORK_DELAY after the strike a full bolt leaps to the nearest person within FORK_R of the click.
const FORK_R := 2.5
const FORK_DELAY := 0.12

## How many it struck down.
var struck := 0
## This cast's kill radius and building blow: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_kill_r := KILL_R
var lv_damage := DAMAGE
## Where the fork struck (Vector2.INF: it did not fork -- below level 5, or nobody within FORK_R).
var forked_at := Vector2.INF


func _build() -> void:
	lv_kill_r = float(PowerBook.stat(extra, "smite", "KILL_R", KILL_R))
	lv_damage = float(PowerBook.stat(extra, "smite", "DAMAGE", DAMAGE))
	duration = 2.2
	at(T_STRIKE, _strike)
	ctx.play(&"smite_call", origin, -4.0)
	if DominionParts.staged(self):
		var mark := FxParts.rings(self, origin, lv_kill_r, Color("cfe8ff"), 2, 6.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.2, 1.0, T_STRIKE * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_STRIKE + 0.1


func _strike() -> void:
	for e in ctx.field.in_radius(origin, lv_kill_r):
		var p := e as Person
		if p != null and p.inside:
			continue
		if ctx.field.kill(e, &"lightning", origin):
			struck += 1
	ctx.env.damage_radius(origin, HIT_R, lv_damage, &"smite")
	ctx.play(&"smite_strike", origin, -3.0)
	if PowerBook.twist_at(extra, "smite"):
		var next := _fork_target()
		if next != null:
			var where := next.ground_pos
			at(t + FORK_DELAY, _fork.bind(where))
			if DominionParts.staged(self):
				# The bolt runs on from the first spot to the second before it falls.
				Set2Parts.bolt(self, ctx.overhead, Iso.ground_to_screen(origin), Iso.ground_to_screen(where), FORK_DELAY + 0.1, 1.4, 1, BOLT)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	ctx.flash.call(Color(0.85, 0.92, 1.0, 0.3), 0.25)
	ctx.impact.hitstop(0.04)
	ctx.impact.aberration(1.6, 0.2)
	ctx.shake.add_trauma(0.4)
	ctx.shake.kick(Vector2(0, 3))
	# The bolt, twice over, from far above; the light it throws; the mark it leaves.
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-30.0, 30.0), -420.0), sp, 0.32, 2.0, 3, BOLT)
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-12.0, 12.0), -420.0), sp, 0.2, 1.2, 1, Color("f0f8ff"))
	var glow := FxParts.bloom(self, sp + Vector2(0, -6), 34.0, LIGHT, 1.2, 0.8)
	glow.tween_param("intensity", 1.2, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.42
	var light := FxParts.ground_light(self, origin, 2.2, LIGHT, 1.4)
	light.tween_param("intensity", 1.4, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.62
	var ring := FxParts.shockwave(self, origin, 1.4, FxParts.ION)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.28, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.18, 0.14)
	ring.life = 0.36
	var scorch := FxParts.decal(self, origin, 0.75, Color("6aa8ff"), Color("e8f4ff"))
	scorch.tween_param("heat", 1.0, 0.0, 1.2)
	scorch.tween_param("fade", 1.0, 0.0, 0.6, 1.2)
	FxParts.sparks(self, ctx.overhead, sp, 18, FxParts.ION_LIFE, Vector2(60, 220), Vector2(30, 200))
	FxParts.smoke(self, sp, 5.0, 12.0, 0.5, Vector2(14, 36), Vector2(2, 4), Vector2(0.6, 1.1))


## The nearest living person in the open within FORK_R of the click who was not struck (the struck are dead); a tie goes to the field's order.
func _fork_target() -> DummyEnemy:
	var best: DummyEnemy = null
	var best_d := INF
	for e in ctx.field.in_radius(origin, FORK_R):
		var p := e as Person
		if p != null and p.inside:
			continue
		var d := e.ground_pos.distance_squared_to(origin)
		if d < best_d:
			best = e
			best_d = d
	return best


## The fork lands: a full bolt where that person stood.
func _fork(where: Vector2) -> void:
	forked_at = where
	for e in ctx.field.in_radius(where, lv_kill_r):
		var p := e as Person
		if p != null and p.inside:
			continue
		if ctx.field.kill(e, &"lightning", where):
			struck += 1
	ctx.env.damage_radius(where, HIT_R, lv_damage, &"smite")
	ctx.play(&"hs_strike", where, -5.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(where)
	ctx.shake.add_trauma(0.2)
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(0.0, -420.0), sp, 0.26, 1.6, 2, BOLT)
	var ring := FxParts.shockwave(self, where, 1.0, FxParts.ION)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.24, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.16, 0.12)
	ring.life = 0.3
