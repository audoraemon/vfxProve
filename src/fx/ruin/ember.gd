class_name EmberFx
extends FxTimeline
## Ember (Ruin, Tier I): one spark. It drifts down for T_LAND onto the nearest thing that burns within REACH of the
## click -- a house, a stall, a tree, the barracks, the cathedral (FireManager.burns()) -- and sets it alight at
## START_LEVEL. From there the fire is the town's own: it grows, spreads on the wind, and draws the fire brigade and
## the engineers away from whatever else they were doing. Nobody sees one spark fall: quiet when cast; the fire is
## seen. With nothing that burns in reach it gutters out on the ground.

const REACH := 1.0
const T_LAND := 0.7
const START_LEVEL := 0.45
const FALL := 150.0
## Level 5, Leaping Spark: LEAP_DELAY after it lands, a second spark leaps to the nearest other thing that burns within LEAP_R of the first.
const LEAP_R := 3.0
const LEAP_DELAY := 1.0
const SPARK := [Color("fff6d8"), Color("ffc14a"), Color("ff6a1a"), Color(0.6, 0.15, 0.05, 0.6)]

## What it lands on, or null.
var fuel: Structure
## Whether it took.
var lit := false
## This cast's reach and the strength of the fire it starts: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_reach := REACH
var lv_start_level := START_LEVEL
## What the second spark lit (level 5), or null.
var leapt: Structure


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


## Where a leaping spark from `from` comes down: the nearest standing thing that burns within LEAP_R of its centre, not `from` itself and not
## already burning (`fires` is the town's FireManager, or null when no town keeps fires). A tie goes to the env's order. Null when there is none.
static func leap_target(env: EnvironmentField, from: Structure, fires: FireManager = null) -> Structure:
	var centre := from.center()
	var best: Structure = null
	var best_d := LEAP_R
	for s in env.near(centre, LEAP_R):
		if s == from or not is_instance_valid(s) or s.destroyed or not FireManager.burns(s):
			continue
		if fires != null and fires.is_burning(s):
			continue
		var d := s.distance_to(centre)
		if d < best_d or (best == null and d <= best_d):
			best_d = d
			best = s
	return best


func _build() -> void:
	lv_reach = float(PowerBook.stat(extra, "ember", "REACH", REACH))
	lv_start_level = float(PowerBook.stat(extra, "ember", "START_LEVEL", START_LEVEL))
	duration = T_LAND + 1.6
	if PowerBook.twist_at(extra, "ember"):
		duration = T_LAND + LEAP_DELAY + 1.6
	busy = T_LAND
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
	return fuel.center() if fuel != null and is_instance_valid(fuel) else origin


func _land() -> void:
	var where := landing()
	if fuel != null and is_instance_valid(fuel) and not fuel.destroyed:
		if ctx.crowd != null:
			ctx.crowd.fires.ignite(fuel, lv_start_level)
			lit = ctx.crowd.fires.is_burning(fuel)
		else:
			# No town to keep the fire: the blow itself is fire's.
			fuel.damage(1.0, where, &"fire")
			lit = true
	ctx.play(&"q_ember_hit", where)
	if lit and PowerBook.twist_at(extra, "ember"):
		at(T_LAND + LEAP_DELAY, _leap)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(where) + Vector2(0, -(fuel.height * 0.5 if lit else 0.0))
	FxParts.sparks(self, ctx.overhead, sp, 14 if lit else 6, FxParts.FIRE_LIFE, Vector2(30, 120), Vector2(20, 120))
	var glow := FxParts.ground_light(self, where, 1.6, Color(1.0, 0.55, 0.2), 0.9 if lit else 0.3)
	glow.tween_param("intensity", 0.9 if lit else 0.3, 0.0, 1.2)
	glow.life = 1.25
	if lit:
		fuel.ignite(Vector2(0, -fuel.height * 0.5), 2.5)
	else:
		FxParts.smoke(self, sp, 3.0, 8.0, 0.4, Vector2(8, 20), Vector2(1, 3), Vector2(0.5, 0.9))


## The second spark (level 5): quiet like the first -- no fright, no alarm. It lights the next house at the level's START_LEVEL.
func _leap() -> void:
	if fuel == null or not is_instance_valid(fuel):
		return
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	var next := leap_target(ctx.env, fuel, fires)
	if next == null:
		return
	leapt = next
	if fires != null:
		fires.ignite(next, lv_start_level)
	else:
		next.damage(1.0, next.center(), &"fire")
	var where := next.center()
	ctx.play(&"q_ember_hit", where)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(where) + Vector2(0, -next.height * 0.5)
	FxParts.sparks(self, ctx.overhead, sp, 14, FxParts.FIRE_LIFE, Vector2(30, 120), Vector2(20, 120))
	var glow := FxParts.ground_light(self, where, 1.6, Color(1.0, 0.55, 0.2), 0.9)
	glow.tween_param("intensity", 0.9, 0.0, 1.2)
	glow.life = 1.25
	next.ignite(Vector2(0, -next.height * 0.5), 2.5)


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
		var to := Iso.ground_to_screen(fx.landing())
		if fx.fuel != null and is_instance_valid(fx.fuel):
			to += Vector2(0, -fx.fuel.height * 0.5)
		for i in 5:
			var kk := maxf(k - 0.03 * float(i), 0.0)
			var at := to + Vector2(sin(kk * 7.0) * 8.0 * (1.0 - kk) + 18.0 * (1.0 - kk), -FALL * (1.0 - kk) * (1.0 - kk))
			draw_rect(Rect2(at.round() - Vector2(1, 1) * float(i == 0), Vector2.ONE * (2.0 if i == 0 else 1.0)),
				Color(SPARK[mini(i, SPARK.size() - 1)], 1.0 - 0.18 * float(i)))
