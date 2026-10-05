class_name EmberFx
extends FxTimeline
## Ember (Ruin, Tier I): one spark. It drifts down for T_LAND onto the nearest thing that burns within REACH of the
## click -- a house, a stall, a tree, the barracks, the cathedral (FireManager.BURNABLE) -- and sets it alight at
## START_LEVEL. From there the fire is the town's own: it grows, spreads on the wind, and draws the fire brigade and
## the engineers away from whatever else they were doing. Nobody sees one spark fall: quiet when cast; the fire is
## seen. With nothing that burns in reach it gutters out on the ground.

const REACH := 1.0
const T_LAND := 0.7
const START_LEVEL := 0.45
const FALL := 150.0
const SPARK := [Color("fff6d8"), Color("ffc14a"), Color("ff6a1a"), Color(0.6, 0.15, 0.05, 0.6)]

## What it lands on, or null.
var fuel: Structure
## Whether it took.
var lit := false


## What an ember at `at` would light: the nearest standing thing that burns within REACH, or null.
static func target(env: EnvironmentField, at: Vector2) -> Structure:
	var best: Structure = null
	var best_d := REACH
	for s in env.near(at, REACH):
		if not is_instance_valid(s) or s.destroyed or not s.kind in FireManager.BURNABLE:
			continue
		var d := s.distance_to(at)
		if d <= best_d:
			best_d = d
			best = s
	return best


func _build() -> void:
	duration = T_LAND + 1.6
	busy = T_LAND
	fuel = target(ctx.env, origin)
	at(T_LAND, _land)
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
			ctx.crowd.fires.ignite(fuel, START_LEVEL)
			lit = ctx.crowd.fires.is_burning(fuel)
		else:
			# No town to keep the fire: the blow itself is fire's.
			fuel.damage(1.0, where, &"fire")
			lit = true
	ctx.play(&"dr_ignite", where, -8.0)
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
