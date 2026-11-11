extends RefCounted
## Passage ability levels, Tier I: Skylift (RADIUS, T_TAKE; level 5's Stay Put) and Windfall (LENGTH, SEGMENTS,
## CLEAR_WORK; level 5's Heart of the Fall). Level 1 is today's power, read from the consts.

const SKYLIFT := "res://src/fx/control/skylift.gd"
const WINDFALL := "res://src/fx/control/windfall.gd"


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## Everyone alive is sent off to the corner, so a check starts with nobody about.
static func _clear_all(crowd: Crowd) -> void:
	for person in crowd.citizens + crowd.soldiers:
		if person.is_alive():
			person.ground_pos = Vector2(-27.0, -27.0)


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	_skylift(t, made)
	_clear_all(crowd)
	_windfall(t, made)
	_done(made)


# --- Skylift ---------------------------------------------------------------------------------------------------------

## A place about `near` with open ground and nothing but people to lift within `r`, open ground eight units south of it
## to set down on, and open ground at the spots the checks set people down.
static func _bare(env: EnvironmentField, grid: WalkGrid, near: Vector2, r: float) -> Vector2:
	for dy in range(-40, 41):
		for dx in range(-40, 41):
			var c := near + Vector2(float(dx), float(dy)) * 0.5
			var down := c + Vector2(0.0, 8.0)
			if not grid.walkable(c):
				continue
			var ok := true
			for off: Vector2 in [Vector2.ZERO, Vector2(1.0, 0.0), Vector2(3.2, 0.0), Vector2(-1.0, 0.0)]:
				ok = ok and grid.walkable(down + off) and not env.blocked(down + off, 0.0)
			if ok and SkyliftFx.goods_at(env, c, r).is_empty():
				return c
	return Vector2.INF


## Tick `people` for `seconds` (and the beam with them), in steps of 0.1 s.
static func _walk(people: Array, fx: FxTimeline, seconds: float) -> void:
	var n := int(round(seconds / 0.1))
	for k in n:
		if fx != null and not fx.finished:
			fx._process(0.1)
		for p in people:
			p.tick(0.1)


static func _skylift(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	_clear_all(crowd)
	var market := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var at := _bare(env, grid, market, 3.4)
	t.check(at != Vector2.INF, "Skylift levels: open ground with nothing but people to lift within 3.4")
	if at == Vector2.INF:
		return
	var to := at + Vector2(0.0, 8.0)
	var near_one: Person = crowd.citizens[0]
	var far_one: Person = crowd.soldiers[0]  # a soldier, at 3.2: past the circle at levels 1-4, in it at level 5
	var bound := grid.nearest_walkable(at + Vector2(5.0, 0.0))
	var bound2 := grid.nearest_walkable(at + Vector2(-5.0, 0.0))

	# Level 1 is today's Skylift, with no level as with level 1: the consts, the same timing, the same circle.
	for extra: Dictionary in [{"to": to}, {"to": to, "level": 1}]:
		_clear_all(crowd)
		near_one.ground_pos = at + Vector2(1.0, 0.0)
		far_one.ground_pos = at + Vector2(3.2, 0.0)
		var beam: SkyliftFx = FxTimeline.cast(load(SKYLIFT), made[5], at, extra)
		t.check(beam.lv_radius == SkyliftFx.RADIUS and beam.lv_t_take == SkyliftFx.T_TAKE and not beam.stay_put
			and is_equal_approx(beam.duration, SkyliftFx.T_TAKE + SkyliftFx.T_SET + 0.8) and is_equal_approx(beam.busy, SkyliftFx.T_TAKE),
			"Skylift %s: RADIUS %.1f and T_TAKE %.1f, no Stay Put" % [extra, beam.lv_radius, beam.lv_t_take])
		beam._process(SkyliftFx.T_TAKE - 0.05)
		t.check(beam.taken == 0, "Skylift %s: nobody is taken before T_TAKE" % [extra])
		beam._process(0.1)
		t.check(beam.taken == 1 and near_one.ground_pos.distance_to(to + Vector2(1.0, 0.0)) < 0.6
			and far_one.ground_pos.distance_to(at + Vector2(3.2, 0.0)) < 0.01,
			"Skylift %s: the one at 1.0 is taken, the soldier at 3.2 (past RADIUS) is not (%d taken)" % [extra, beam.taken])
		t.check(near_one.pace_holds.is_empty() and beam.rooted_until < 0.0, "Skylift %s: those set down are not rooted" % [extra])
		beam.end_now()
		beam.free()

	# Level 4: a wider circle (3.1, still short of 3.2), a quicker take; those set down walk on at once.
	_clear_all(crowd)
	near_one.mind = Person.Mind.CALM
	near_one.ground_pos = at + Vector2(1.0, 0.0)
	near_one.set_goal(bound)
	far_one.ground_pos = at + Vector2(3.2, 0.0)
	var four: SkyliftFx = FxTimeline.cast(load(SKYLIFT), made[5], at, {"to": to, "level": 4})
	t.check(is_equal_approx(four.lv_radius, 3.1) and is_equal_approx(four.lv_t_take, 1.1) and not four.stay_put,
		"Skylift level 4: RADIUS 3.1, T_TAKE 1.1, no twist")
	four._process(1.05)
	t.check(four.taken == 0, "level 4: nobody is taken before its T_TAKE")
	four._process(0.1)
	var landed := near_one.ground_pos
	t.check(four.taken == 1 and near_one.pace_holds.is_empty(), "level 4: the one at 1.0 is taken (the soldier at 3.2 is not), and not rooted")
	_walk([near_one], four, 2.0)
	t.check(near_one.ground_pos.distance_to(landed) > 0.3, "level 4: set down, they walk straight on (%.2f in 2 s)" % near_one.ground_pos.distance_to(landed))
	four.end_now()
	four.free()

	# Level 5: the circle 3.3 takes the soldier at 3.2 too, the take comes at 1.0 -- and Stay Put roots them both.
	_clear_all(crowd)
	near_one.mind = Person.Mind.CALM
	near_one.ground_pos = at + Vector2(1.0, 0.0)
	near_one.set_goal(bound)
	near_one.statuses[&"slow"] = 0.5  # slowed by something else before: given back as it was
	far_one.ground_pos = at + Vector2(3.2, 0.0)
	far_one.set_goal(bound2)
	var five: SkyliftFx = FxTimeline.cast(load(SKYLIFT), made[5], at, {"to": to, "level": 5})
	t.check(is_equal_approx(five.lv_radius, 3.3) and is_equal_approx(five.lv_t_take, 1.0) and five.stay_put,
		"Skylift level 5: RADIUS 3.3, T_TAKE 1.0, Stay Put")
	five._process(0.95)
	t.check(five.taken == 0, "level 5: nobody is taken before 1.0 s")
	five._process(0.1)
	var took := five.taken
	t.check(took == 2 and far_one.ground_pos.distance_to(to + Vector2(3.2, 0.0)) < 0.6,
		"level 5: the larger circle takes the soldier at 3.2 too (%d taken)" % took)
	t.check(absf(five.rooted_until - five.t - SkyliftFx.STAY) < 0.001,
		"Stay Put: the hold runs %.0f s from the take (until %.2f)" % [SkyliftFx.STAY, five.rooted_until])
	t.check(near_one.pace_hold() == 0.0 and far_one.pace_hold() == 0.0
		and near_one.walk_speed == 0.0 and far_one.walk_speed == 0.0,
		"Stay Put: both set down -- the soldier too -- have no pace of their own")
	var here := near_one.ground_pos
	var there := far_one.ground_pos
	_walk([near_one, far_one], five, 9.0)
	t.check(near_one.ground_pos.distance_to(here) < 0.02 and far_one.ground_pos.distance_to(there) < 0.02 and near_one.is_alive(),
		"Stay Put: nine seconds on they stand where they landed (%.3f, %.3f), goals or not" % [near_one.ground_pos.distance_to(here), far_one.ground_pos.distance_to(there)])
	t.check(near_one.goal().distance_to(bound) < 0.6, "and still mean to go where they were going")
	_walk([near_one, far_one], five, 1.2)
	t.check(is_equal_approx(float(near_one.statuses.get(&"slow", 1.0)), 0.5) and near_one.pace_holds.is_empty() and far_one.pace_holds.is_empty(),
		"after %.0f s the hold lifts: each has the pace they had back (0.5 and none)" % SkyliftFx.STAY)
	var freed := near_one.ground_pos
	_walk([near_one], five, 2.0)
	t.check(near_one.ground_pos.distance_to(freed) > 0.15, "and they walk on to what they meant (%.2f in 2 s)" % near_one.ground_pos.distance_to(freed))
	near_one.statuses.erase(&"slow")
	five.end_now()
	five.free()

	# Cut short while they are rooted: the hold goes with the beam.
	_clear_all(crowd)
	near_one.ground_pos = at + Vector2(1.0, 0.0)
	var cut: SkyliftFx = FxTimeline.cast(load(SKYLIFT), made[5], at, {"to": to, "level": 5})
	cut._process(1.1)
	t.check(near_one.pace_hold() == 0.0 and cut.duration >= 1.0 + SkyliftFx.STAY,
		"a beam that roots lasts until the hold lifts (%.1f s)" % cut.duration)
	cut.end_now()
	t.check(near_one.pace_holds.is_empty() and near_one.walk_speed > 0.0, "cut short (end_now()), nobody is left rooted")
	cut.free()


# --- Windfall --------------------------------------------------------------------------------------------------------

## Open ground about the market for a level-5 line along x (all LENGTH 4.8 / 8 segments), its boulder, a shed's spot
## 2 south of its middle, and the spots the checks stand people on.
static func _line_spot(env: EnvironmentField, grid: WalkGrid, near: Vector2) -> Vector2:
	for dy in range(-40, 41):
		for dx in range(-40, 41):
			var cand := near + Vector2(float(dx), float(dy)) * 0.5
			var ok := true
			for r in WindfallFx.rects(cand, Vector2(1, 0), 4.8, 8):
				ok = ok and not env.blocked(r.get_center(), 0.0) and grid.walkable(r.get_center())
			for off: Vector2 in [Vector2(0.9, 0.9), Vector2(-0.9, 0.9), Vector2(0.9, -0.9), Vector2(-0.9, -0.9),
					Vector2(0.0, -1.0), Vector2(0.0, -1.6), Vector2(0.0, 2.0), Vector2(0.0, 0.75)]:
				ok = ok and not env.blocked(cand + off, 0.3)
			if ok:
				return cand
	return Vector2.INF


static func _windfall(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var market := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var spot := _line_spot(env, grid, market)
	t.check(spot != Vector2.INF, "Windfall levels: open ground for a level-5 line, its boulder and a shed")
	if spot == Vector2.INF:
		return
	var people: Array = crowd.citizens.duplicate()
	var used := 0

	# Level 1 is today's Windfall, with no level as with level 1.
	for extra: Dictionary in [{"dir": Vector2(1, 0)}, {"dir": Vector2(1, 0), "level": 1}]:
		var fx: WindfallFx = FxTimeline.cast(load(WINDFALL), ctx, spot, extra)
		t.check(fx.lv_length == WindfallFx.LENGTH and fx.lv_segments == WindfallFx.SEGMENTS and fx.lv_clear_work == WindfallFx.CLEAR_WORK
			and fx.work_left == WindfallFx.CLEAR_WORK and not fx.heart, "Windfall %s: LENGTH, SEGMENTS, CLEAR_WORK, no Heart of the Fall" % [extra])
		fx._process(WindfallFx.T_DROP + 0.1)
		fx._process(3.0)
		t.check(fx.piles.size() == WindfallFx.SEGMENTS and fx.boulder == null and fx.meteor_at == Vector2.INF,
			"Windfall %s: %d segments, and no meteor" % [extra, fx.piles.size()])
		fx.end_now()
		fx.free()

	# Level 4: a longer line (4.5, 8 segments), more work, and still no meteor.
	_clear_all(crowd)
	var spared: Person = people[used]
	used += 1
	spared.ground_pos = spot + Vector2(0.0, -1.0)
	var four: WindfallFx = FxTimeline.cast(load(WINDFALL), ctx, spot, {"dir": Vector2(1, 0), "level": 4})
	t.check(is_equal_approx(four.lv_length, 4.5) and four.lv_segments == 8 and is_equal_approx(four.work_left, 195.0) and not four.heart,
		"Windfall level 4: LENGTH 4.5, 8 segments, CLEAR_WORK 195, no twist")
	four._process(WindfallFx.T_DROP + 0.1)
	var ends := four.centres()
	t.check(four.piles.size() == 8 and ends.size() == 8 and is_equal_approx(ends[0].distance_to(ends[7]), 4.5 * 7.0 / 8.0),
		"level 4: eight segments along 4.5 (ends %.2f apart)" % (ends[0].distance_to(ends[7]) if ends.size() == 8 else -1.0))
	four._process(4.0)
	t.check(four.boulder == null and four.meteor_at == Vector2.INF and spared.is_alive(), "level 4: no meteor; the one a step off the line lives")
	four.end_now()
	four.free()

	# Level 5, STONE: the line, then Heart of the Fall.
	_clear_all(crowd)
	var victim: Person = people[used]
	var survivor: Person = people[used + 1]
	used += 2
	victim.ground_pos = spot + Vector2(0.0, -1.0)   # off the line (beyond KILL_R of any segment), within M_KILL_R of the middle
	survivor.ground_pos = spot + Vector2(0.0, -1.6)  # beyond M_KILL_R
	var shed := env.add_structure(Rect2(spot + Vector2(-0.3, 1.7), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	shed.max_hp = 500.0  # stout enough to show the whole blow
	shed.hp = 500.0
	var hp := shed.hp
	var fx5: WindfallFx = FxTimeline.cast(load(WINDFALL), ctx, spot, {"dir": Vector2(1, 0), "level": 5})
	t.check(is_equal_approx(fx5.lv_length, 4.8) and fx5.lv_segments == 8 and is_equal_approx(fx5.lv_clear_work, 210.0) and fx5.heart,
		"Windfall level 5: LENGTH 4.8, 8 segments, CLEAR_WORK 210, Heart of the Fall")
	fx5._process(WindfallFx.T_DROP + 0.1)
	# A point inside the boulder's footprint but off the line: open after the line is down, barred once the boulder is.
	var probe := Vector2.INF
	for d: float in [0.75, 0.7, 0.8, 0.65]:
		if probe == Vector2.INF and grid.walkable(spot + Vector2(0.0, d)):
			probe = spot + Vector2(0.0, d)
	t.check(fx5.piles.size() == 8 and victim.is_alive() and fx5.boulder == null and probe != Vector2.INF,
		"level 5: the line is down, the meteor not yet, and the ground beside the middle is open")
	var lands := fx5._meteor_leave + WindfallFx.M_FLIGHT
	t.check(is_equal_approx(fx5._meteor_leave, fx5.last_land()), "the meteor leaves the portal as the last piece lands (%.2f s)" % fx5._meteor_leave)
	fx5._process(lands - 0.05 - fx5.t)
	var work_before := fx5.work_left
	t.check(victim.is_alive() and fx5.boulder == null and fx5.meteor_at == Vector2.INF, "while it falls, nothing has happened yet")
	fx5._process(0.1)
	t.check(not victim.is_alive() and victim._kind == &"stone" and survivor.is_alive() and fx5.meteor_kills == 1,
		"Heart of the Fall: whoever stands within %.1f of the middle is crushed by stone, and nobody past it" % WindfallFx.M_KILL_R)
	t.check(is_equal_approx(hp - shed.hp, WindfallFx.M_DAMAGE) and not crowd.fires.is_burning(shed),
		"what stands within %.1f takes %.0f, without a fire (%.0f)" % [WindfallFx.M_HIT_R, WindfallFx.M_DAMAGE, hp - shed.hp])
	var b := fx5.boulder
	t.check(b != null and b.role == &"windfall" and env.structures().has(b) and b.footprint.size.is_equal_approx(Vector2(1.8, 1.8))
		and b.center().distance_to(spot) < 0.01 and fx5.piles.size() == 8,
		"it stays as a boulder 1.8 across on the middle, a windfall pile; the line's segments are spared")
	t.check(probe != Vector2.INF and not grid.walkable(probe), "the boulder bars the walk grid about the middle")
	t.check(is_equal_approx(fx5._boulder_work, 2.0 * 210.0 / 8.0) and fx5.work_left > work_before + fx5._boulder_work - 3.01
		and fx5.work_left <= work_before + fx5._boulder_work, "it is twice a segment's clearing work (%.1f more, %.1f in all)" % [fx5._boulder_work, fx5.work_left])
	# The line comes down first, the boulder last.
	fx5.work_left = fx5._boulder_work
	fx5._process(1.0)
	t.check(fx5.piles.is_empty() and fx5.boulder != null and fx5.standing() and not grid.walkable(probe),
		"cleared from its ends, the line goes first; the boulder stands until its own share is worked off")
	fx5.work_left = 0.0
	fx5._process(1.0)
	t.check(fx5.boulder == null and not fx5.standing() and fx5.cleared and grid.walkable(probe), "then the boulder goes, and the way is open")
	fx5.free()
	env.remove(shed)

	# Level 5 cut short before the meteor: no meteor, nothing left behind.
	_clear_all(crowd)
	var cut: WindfallFx = FxTimeline.cast(load(WINDFALL), ctx, spot, {"dir": Vector2(1, 0), "level": 5})
	cut._process(WindfallFx.T_DROP + 0.1)
	cut.end_now()
	t.check(cut.boulder == null and not cut.standing() and grid.walkable(spot), "cut short before the meteor, nothing is left on the ground")
	cut.free()

	# Level 5, OIL: the meteor bursts and burns as a segment does; nothing is set down.
	_clear_all(crowd)
	var oil_victim: Person = people[used]
	used += 1
	oil_victim.ground_pos = spot + Vector2(0.0, -1.0)
	var oil: WindfallFx = FxTimeline.cast(load(WINDFALL), ctx, spot, {"dir": Vector2(1, 0), "mode": "oil", "level": 5})
	oil._process(oil._meteor_leave + WindfallFx.M_FLIGHT + 0.05)
	t.check(not oil_victim.is_alive() and oil_victim._kind == &"fire" and oil.meteor_kills == 1 and oil.boulder == null
		and oil.piles.is_empty() and grid.walkable(probe) and oil._line.has(spot) and oil.burning(),
		"OIL: the meteor bursts in fire on whoever is near, sets nothing down, and its spot burns with the line")
	oil._process(1.0)
	var walker: Person = people[used]
	used += 1
	walker.ground_pos = spot
	oil._process(0.3)
	t.check(not walker.is_alive() and walker._kind == &"fire", "one who walks onto the meteor's spot burns")
	oil.end_now()
	oil.free()

	# Level 5, GOODS: the meteor is stone.
	_clear_all(crowd)
	var goods: WindfallFx = FxTimeline.cast(load(WINDFALL), ctx, spot, {"dir": Vector2(1, 0), "mode": "goods", "level": 5})
	goods._process(goods._meteor_leave + WindfallFx.M_FLIGHT + 0.05)
	t.check(goods.boulder != null and goods.boulder.role == &"windfall" and not grid.walkable(probe), "GOODS: the meteor is stone and leaves its boulder")
	goods.end_now()
	t.check(goods.boulder == null and grid.walkable(probe), "and end_now() takes the boulder with the line")
	goods.free()
