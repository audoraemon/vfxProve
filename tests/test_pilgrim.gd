extends RefCounted
## Pilgrim Road: the road itself travels -- everyone on the lane is carried along it at a run, into whatever stands at
## its end.


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


## A calm citizen standing at `at`, with nothing of his own to walk to.
static func _stand(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


## Whether the ground is open (no structure, walkable) the whole lane long from `spot` along (1, 0), with a margin
## past the end and to either side.
static func _open(env: EnvironmentField, grid: WalkGrid, spot: Vector2, sides: Array) -> bool:
	var along := 0.0
	while along <= PilgrimRoadFx.LENGTH + PilgrimRoadFx.THROW + 0.9:
		for across: float in sides:
			var g := spot + Vector2(along, across)
			if env.blocked(g, 0.0) or not grid.walkable(g):
				return false
		along += 0.5
	return true


static func run(t) -> void:
	var b := PowerBook.get_power("pilgrim")
	var area: Dictionary = Targeting.AREAS.get("pilgrim", {})
	t.check(int(b.dp) == 2 and not PowerBook.is_quiet("pilgrim") and String(b.aim) == "drag" and PowerBook.authority_of("pilgrim") == "passage"
		and PowerBook.icon("pilgrim") != null and PowerBook.hud_icon("pilgrim") != null and PowerBook.clip("pilgrim") != null
		and String(area.get("shape", "")) == "lane" and is_equal_approx(float(area.get("length", 0.0)), PilgrimRoadFx.LENGTH)
		and is_equal_approx(float(area.get("half", 0.0)), PilgrimRoadFx.HALF) and Rules.POWER_KINDS.get("pilgrim", [1]) == []
		and is_equal_approx(PowerBook.impact("pilgrim"), PilgrimRoadFx.T_FLOW) and PowerBook.family("pilgrim") != "",
		"Pilgrim Road is Passage's 2 DP, loud, a drag along a lane LENGTH by HALF, kills nothing, its impact the flow, with icons, clip and a family")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	# Open ground for the whole lane running from the spot along (1, 0), with room beside it and past its end.
	var spot := Vector2.INF
	for wide: Array in [[-0.9, 0.0, 0.9], [0.0]]:
		for dy in range(-12, 13):
			for dx in range(-12, 13):
				if spot != Vector2.INF:
					break
				var cand := at + Vector2(float(dx), float(dy)) * 0.5
				if _open(env, grid, cand, wide):
					spot = cand
	t.check(spot != Vector2.INF, "open ground for a road about the market")
	var dir := Vector2(1, 0)
	var road_end := spot + dir * PilgrimRoadFx.LENGTH
	t.check(PilgrimRoadFx.on_lane(spot, dir, spot + Vector2(3.0, PilgrimRoadFx.HALF - 0.05))
		and not PilgrimRoadFx.on_lane(spot, dir, spot + Vector2(3.0, PilgrimRoadFx.HALF + 0.05))
		and not PilgrimRoadFx.on_lane(spot, dir, spot + Vector2(-0.1, 0.0))
		and not PilgrimRoadFx.on_lane(spot, dir, spot + Vector2(PilgrimRoadFx.LENGTH + 0.1, 0.0)),
		"the lane runs from the press along the drag, LENGTH long and HALF to each side")

	var walker: Person = crowd.citizens[2]
	var beside: Person = crowd.citizens[3]
	var faller: Person = crowd.citizens[4]
	var downed: Person = crowd.citizens[5]
	var soldier: Person = crowd.soldiers[0]
	_stand(walker, spot + Vector2(1.0, 0.0))
	_stand(beside, spot + Vector2(1.0, PilgrimRoadFx.HALF + 0.3))
	_stand(faller, spot + Vector2(PilgrimRoadFx.LENGTH - 0.1, 0.0))
	_stand(downed, spot + Vector2(2.0, 0.0))
	downed.knock_down()
	soldier.ground_pos = spot + Vector2(1.5, 0.0)
	var soldier_mind := soldier.mind
	var fx: PilgrimRoadFx = FxTimeline.cast(load("res://src/fx/control/pilgrim_road.gd"), ctx, spot, {"dir": dir})
	var threats := crowd.threats.active_count()
	fx._process(PilgrimRoadFx.T_FLOW - 0.1)
	t.check(not fx.flowing() and walker.ground_pos == spot + Vector2(1.0, 0.0) and fx.carried == 0,
		"Pilgrim Road: nobody moves while the road wakes")
	fx._process(0.2)
	t.check(fx.flowing() and crowd.threats.active_count() == threats + 1, "then the paving flows, and the lane is a danger the town walks round")
	# Thrown once a crossing: one who is still at the end a moment after his throw is not thrown again and again.
	var thrown_was := fx.thrown
	faller.ground_pos = spot + Vector2(PilgrimRoadFx.LENGTH - 0.05, 0.0)
	fx._process(0.05)
	t.check(thrown_was == 1 and fx.thrown == thrown_was and (faller.ground_pos - spot).dot(dir) > PilgrimRoadFx.LENGTH,
		"one carried off the end is thrown once, not every frame he lies there")
	var from := walker.ground_pos
	var soldier_from := soldier.ground_pos
	var downed_from := downed.ground_pos
	for k in 20:
		fx._process(0.05)
	var moved := (walker.ground_pos - from).dot(dir)
	t.check(absf(moved - PilgrimRoadFx.SPEED) <= 0.5 and absf((walker.ground_pos - from).dot(dir.orthogonal())) < 0.01
		and walker.mind == Person.Mind.CALM,
		"a citizen standing on it is carried SPEED a second along the drag, not across it, his mind his own (%.2f)" % moved)
	t.check(beside.ground_pos == spot + Vector2(1.0, PilgrimRoadFx.HALF + 0.3), "one a step beside the lane does not move")
	var soldier_moved := (soldier.ground_pos - soldier_from).dot(dir)
	t.check(soldier_moved >= PilgrimRoadFx.SPEED * 0.8 and soldier.mind == soldier_mind,
		"a soldier on it is carried too, and keeps his post in mind (%.2f)" % soldier_moved)
	var downed_moved := (downed.ground_pos - downed_from).dot(dir)
	t.check(downed.is_down() and downed_moved >= PilgrimRoadFx.SPEED * 0.8, "one lying knocked down on it keeps sliding (%.2f)" % downed_moved)
	t.check(faller.is_down() and (faller.ground_pos - spot).dot(dir) > PilgrimRoadFx.LENGTH and faller.is_alive() and fx.thrown == 1,
		"one carried past the open end tumbles off it: knocked down, lying beyond the end, alive")
	t.check(fx.carried == 4 and fx.blows == 0, "it carried the four on it and struck no wall (%d carried)" % fx.carried)
	fx.free()
	# Left to himself, the one thrown comes to rest, lies his time and gets up: nothing is stuck on him.
	for k in 70:
		faller.tick(0.05)
	t.check(not faller.is_down() and faller.state == DummyEnemy.State.WANDER and faller.is_alive(),
		"the knock wears off as any knock does: he gets up again")
	for p: Person in [walker, beside, faller, downed, soldier]:
		p.ground_pos = Vector2(-27.0, -27.0)  # out of the next road's way

	# --- A wall at the end: a shed just past it.
	var shed := env.add_structure(Rect2(road_end + dir * (PilgrimRoadFx.THROW + 0.2) - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 18.0,
		Structure.Kind.HOUSE, &"house")
	var hp := shed.hp
	var victim: Person = crowd.citizens[6]
	_stand(victim, spot + Vector2(PilgrimRoadFx.LENGTH - 0.1, 0.0))
	var second: PilgrimRoadFx = FxTimeline.cast(load("res://src/fx/control/pilgrim_road.gd"), ctx, spot, {"dir": dir})
	second._process(PilgrimRoadFx.T_FLOW + 0.1)
	t.check(victim.is_down() and victim.is_alive() and (victim.ground_pos - spot).dot(dir) <= PilgrimRoadFx.LENGTH
		and victim.ground_pos.distance_to(road_end) < 0.6,
		"one carried into a wall is thrown against it: knocked down where the road ends (%.2f from the end)" % victim.ground_pos.distance_to(road_end))
	t.check(shed.hp < hp and is_equal_approx(hp - shed.hp, PilgrimRoadFx.WALL_HIT) and second.blows == 1 and not crowd.fires.is_burning(shed),
		"and the wall takes a blow of WALL_HIT, without a fire (%.0f of %.0f)" % [hp - shed.hp, hp])
	for k in 10:
		second._process(0.05)
	t.check(second.blows == 1 and victim.is_down(), "one lying against the wall is held there, not battered every frame")
	# The flow stops on time: the road is a road again.
	second._process(PilgrimRoadFx.SPAN - 0.6 + 0.1)
	t.check(not second.flowing(), "after T_FLOW + SPAN the paving stands still")
	var late: Person = crowd.citizens[7]
	_stand(late, spot + Vector2(1.0, 0.0))
	var victim_at := victim.ground_pos
	second._process(0.2)
	t.check(late.ground_pos == spot + Vector2(1.0, 0.0) and victim.ground_pos == victim_at and second.blows == 1,
		"and nobody on it moves any more")
	second._process(1.0)
	t.check(second.finished, "the road is gone soon after")
	env.remove(shed)
	_done(made)
