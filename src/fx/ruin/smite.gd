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
## Level 5, Gathered Storm: the press is held and dragged, and the bolt grows by s = grow_for(drag) -- 1 + drag / GROW_PER, GROW_MAX at
## most. It kills within KILL_R * s, every building within HIT_R * s takes DAMAGE, and the bolt, flash and light are drawn s times larger. A
## click, or a twitch under Targeting.DRAG_MIN, is the plain bolt.
const GROW_PER := 1.5
const GROW_MAX := 2.5

## How many it struck down.
var struck := 0
## This cast's kill radius and building blow: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_kill_r := KILL_R
var lv_damage := DAMAGE
## How much larger this bolt is (grow_of()): 1.0 but for a level 5 drag.
var grow := 1.0


## The bolt's growth for a drag `drag_len` long: 1 + drag_len / GROW_PER, never below 1.0 or above GROW_MAX.
static func grow_for(drag_len: float) -> float:
	return clampf(1.0 + drag_len / GROW_PER, 1.0, GROW_MAX)


## The growth a cast at `at` carries: grow_for() its drag (to extra["to"], where Targeting's drag ended) at level 5; 1.0 below level 5,
## with no drag, or for a twitch under Targeting.DRAG_MIN.
static func grow_of(extra: Dictionary, at: Vector2) -> float:
	if not PowerBook.twist_at(extra, "smite") or not extra.has("to"):
		return 1.0
	var drag := at.distance_to(extra["to"] as Vector2)
	return grow_for(drag) if drag >= Targeting.DRAG_MIN else 1.0


func _build() -> void:
	lv_kill_r = float(PowerBook.stat(extra, "smite", "KILL_R", KILL_R))
	lv_damage = float(PowerBook.stat(extra, "smite", "DAMAGE", DAMAGE))
	grow = grow_of(extra, origin)
	duration = 2.2
	at(T_STRIKE, _strike)
	ctx.play(&"smite_call", origin, -4.0)
	if DominionParts.staged(self):
		var mark := FxParts.rings(self, origin, lv_kill_r * grow, Color("cfe8ff"), 2, 6.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.2, 1.0, T_STRIKE * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_STRIKE + 0.1


func _strike() -> void:
	for e in ctx.field.in_radius(origin, lv_kill_r * grow):
		var p := e as Person
		if p != null and p.inside:
			continue
		if ctx.field.kill(e, &"lightning", origin):
			struck += 1
	ctx.env.damage_radius(origin, HIT_R * grow, lv_damage, &"smite")
	ctx.play(&"smite_strike", origin, -3.0)
	if grow > 1.0:
		ctx.play(&"smite_crack", origin, -5.0)  # the level 5 twist's own cue (the sound pass's, once the fork's): a gathered storm cracks
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	ctx.flash.call(Color(0.85, 0.92, 1.0, minf(0.3 * grow, 0.6)), 0.25)  # a gathered storm lights the screen brighter, never blinding
	ctx.impact.hitstop(0.04)
	ctx.impact.aberration(1.6, 0.2)
	ctx.shake.add_trauma(0.4)
	ctx.shake.kick(Vector2(0, 3))
	# The bolt, twice over, from far above; the light it throws; the mark it leaves -- all `grow` times larger for a gathered storm.
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-30.0, 30.0) * grow, -420.0), sp, 0.32, 2.0 * grow, 3, BOLT)
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-12.0, 12.0) * grow, -420.0), sp, 0.2, 1.2 * grow, 1, Color("f0f8ff"))
	var glow := FxParts.bloom(self, sp + Vector2(0, -6), 34.0 * grow, LIGHT, 1.2, 0.8)
	glow.tween_param("intensity", 1.2, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.42
	var light := FxParts.ground_light(self, origin, 2.2 * grow, LIGHT, 1.4)
	light.tween_param("intensity", 1.4, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.62
	var ring := FxParts.shockwave(self, origin, 1.4 * grow, FxParts.ION)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.28, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.18, 0.14)
	ring.life = 0.36
	var scorch := FxParts.decal(self, origin, 0.75 * grow, Color("6aa8ff"), Color("e8f4ff"))
	scorch.tween_param("heat", 1.0, 0.0, 1.2)
	scorch.tween_param("fade", 1.0, 0.0, 0.6, 1.2)
	FxParts.sparks(self, ctx.overhead, sp, 18, FxParts.ION_LIFE, Vector2(60, 220), Vector2(30, 200))
	FxParts.smoke(self, sp, 5.0, 12.0, 0.5, Vector2(14, 36), Vector2(2, 4), Vector2(0.6, 1.1))
