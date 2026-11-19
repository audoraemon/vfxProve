class_name EmberFx
extends FxTimeline
## Ember (Ruin, Tier I): one spark. It drifts down for T_LAND onto a living person out in the open within PERSON_R of the
## click (the nearest; a guised one is passed over, as Death's undead pass them) and sets him alight (Crowd.burn(): the
## Burning status -- he screams, runs, lights what he brushes and dies as fire at Burning.BURN_FOR); with nobody there,
## onto the nearest thing that burns within REACH of the click -- a house, a stall, a tree, the barracks, the cathedral
## (FireManager.burns()) -- and sets it alight at START_LEVEL. From there the fire is the town's own: it grows, spreads on
## the wind, and draws the fire brigade and the engineers away from whatever else they were doing. Nobody sees one spark
## fall: quiet when cast; the fire, and the burning man, are seen. With nothing in reach it gutters out on the ground.

const REACH := 1.0
const T_LAND := 0.7
const START_LEVEL := 0.45
const FALL := 150.0
## A person within this of the click takes the spark before any building.
const PERSON_R := 0.6
## Level 5, Fire Trail: burning ground (FireManager.lay) one patch every TRAIL_STEP -- round a house as it catches, about
## RING_OUT outside its footprint; behind a burning man as he runs, TRAIL_MOST at most, the first where he caught fire.
const TRAIL_STEP := 1.0
const TRAIL_MOST := 8
const RING_OUT := 0.6
const SPARK := [Color("fff6d8"), Color("ffc14a"), Color("ff6a1a"), Color(0.6, 0.15, 0.05, 0.6)]
## How high on a person the spark comes down (screen pixels).
const PERSON_LIFT := 10.0

## What it lands on, or null.
var fuel: Structure
## Who it lands on, or null (a person is chosen before any building).
var victim: Person
## Whether it took.
var lit := false
## This cast's reach and the strength of the fire it starts: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_reach := REACH
var lv_start_level := START_LEVEL


## What an ember at `at` would light: the nearest standing thing that burns within `reach`, or null.
static func target(env: EnvironmentField, at: Vector2, reach := REACH) -> Structure:
	var best: Structure = null
	var best_d := reach
	for s in env.near(at, reach):
		if not is_instance_valid(s) or s.destroyed or not FireManager.burns(s):
			continue
		var d := s.distance_to(at)
		if d <= best_d:
			best_d = d
			best = s
	return best


## Who an ember at `at` would set alight: the nearest living person (citizen or soldier) within PERSON_R, out in the open
## and not guised; a tie goes to the lower instance id. Null when there is none.
static func pick_person(field: EnemyField, at: Vector2) -> Person:
	if field == null:
		return null
	var best: Person = null
	var best_d := INF
	for e in field.in_radius(at, PERSON_R):
		var p := e as Person
		if p == null or p.inside or p.guised():
			continue
		var d := p.ground_pos.distance_to(at)
		if d < best_d or (d == best_d and p.get_instance_id() < best.get_instance_id()):
			best_d = d
			best = p
	return best


## The ring of burning ground round `s` (pure): points about RING_OUT outside its footprint, round the rectangle grown by
## RING_OUT, spaced `step` along it (evenly, so the ring closes), starting at its top-left corner. With `env`, a point inside
## another building is left out.
static func ring_spots(s: Structure, step: float, env: EnvironmentField = null) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var r := s.footprint.grow(RING_OUT)
	var perim := 2.0 * (r.size.x + r.size.y)
	var n := maxi(roundi(perim / maxf(step, 0.01)), 4)
	var corners: Array[Vector2] = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var sides: Array[float] = [r.size.x, r.size.y, r.size.x, r.size.y]
	for k in n:
		var along := perim * float(k) / float(n)
		var i := 0
		while i < 3 and along > sides[i]:
			along -= sides[i]
			i += 1
		var g := corners[i].lerp(corners[(i + 1) % 4], clampf(along / sides[i], 0.0, 1.0))
		if env != null and env.blocked(g, 0.0):
			continue
		out.append(g)
	return out


func _build() -> void:
	lv_reach = float(PowerBook.stat(extra, "ember", "REACH", REACH))
	lv_start_level = float(PowerBook.stat(extra, "ember", "START_LEVEL", START_LEVEL))
	duration = T_LAND + 1.6
	busy = T_LAND
	victim = pick_person(ctx.field, origin)
	if victim == null:
		fuel = target(ctx.env, origin, lv_reach)
	at(T_LAND, _land)
	ctx.play(&"q_ember", origin)
	if DominionParts.staged(self):
		var spark := Spark.new()
		spark.fx = self
		spark.z_index = 6
		track(spark, ctx.overhead)


## Where it comes down.
func landing() -> Vector2:
	if victim != null and is_instance_valid(victim):
		return victim.ground_pos
	return fuel.center() if fuel != null and is_instance_valid(fuel) else origin


## How high above the ground it comes down (screen pixels): on a person's chest, a building's middle, else the ground.
func landing_lift() -> float:
	if victim != null and is_instance_valid(victim):
		return PERSON_LIFT
	return fuel.height * 0.5 if fuel != null and is_instance_valid(fuel) else 0.0


func _land() -> void:
	var where := landing()
	var lift := landing_lift()
	var twist := PowerBook.twist_at(extra, "ember")
	if victim != null:
		# On a person: he burns, if he is still out in the open to burn (Burning.lay()).
		if is_instance_valid(victim) and ctx.crowd != null:
			lit = ctx.crowd.burn(victim, Burning.BURN_FOR, where, lv_start_level)
			if lit and twist:
				ctx.crowd.burning.trail(victim, ctx.crowd.fires.lay, TRAIL_STEP, TRAIL_MOST)
	elif fuel != null and is_instance_valid(fuel) and not fuel.destroyed:
		if ctx.crowd != null:
			ctx.crowd.fires.ignite(fuel, lv_start_level)
			lit = ctx.crowd.fires.is_burning(fuel)
			if lit and twist:
				for g in ring_spots(fuel, TRAIL_STEP, ctx.env):
					ctx.crowd.fires.lay(g)
		else:
			# No town to keep the fire: the blow itself is fire's.
			fuel.damage(1.0, where, &"fire")
			lit = true
	ctx.play(&"q_ember_hit", where)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(where) + Vector2(0, -(lift if lit else 0.0))
	FxParts.sparks(self, ctx.overhead, sp, 14 if lit else 6, FxParts.FIRE_LIFE, Vector2(30, 120), Vector2(20, 120))
	var glow := FxParts.ground_light(self, where, 1.6, Color(1.0, 0.55, 0.2), 0.9 if lit else 0.3)
	glow.tween_param("intensity", 0.9 if lit else 0.3, 0.0, 1.2)
	glow.life = 1.25
	if lit and fuel != null:
		fuel.ignite(Vector2(0, -fuel.height * 0.5), 2.5)
	elif not lit:
		FxParts.smoke(self, sp, 3.0, 8.0, 0.4, Vector2(8, 20), Vector2(1, 3), Vector2(0.5, 0.9))


## The spark itself: a point of fire drifting down on the wind with a short tail.
class Spark extends Node2D:
	var fx: EmberFx

	func _process(_delta: float) -> void:
		if fx.t >= T_LAND:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(fx.t / T_LAND, 0.0, 1.0)
		var to := Iso.ground_to_screen(fx.landing()) + Vector2(0, -fx.landing_lift())
		for i in 5:
			var kk := maxf(k - 0.03 * float(i), 0.0)
			var at := to + Vector2(sin(kk * 7.0) * 8.0 * (1.0 - kk) + 18.0 * (1.0 - kk), -FALL * (1.0 - kk) * (1.0 - kk))
			draw_rect(Rect2(at.round() - Vector2(1, 1) * float(i == 0), Vector2.ONE * (2.0 if i == 0 else 1.0)),
				Color(SPARK[mini(i, SPARK.size() - 1)], 1.0 - 0.18 * float(i)))
