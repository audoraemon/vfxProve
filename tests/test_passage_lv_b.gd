extends RefCounted
## Passage ability levels, part B: Hound Gate (HOUNDS, HUNT, BLOWS; level-5 twist Quarry) and Hellmouth Spark (RADIUS,
## OPEN; level-5 twist Wandering Mouth). Level 1 plays exactly as before; level 5 has the table's numbers and the twist;
## level 4 has no twist. Fixtures as tests/test_houndgate.gd and tests/test_hellspark.gd.

const DT := 0.05
const HOUND := "res://src/fx/control/hound_gate.gd"
const SPARK := "res://src/fx/control/hellmouth_spark.gd"


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
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		fx._process(DT)


## A calm citizen standing at `at`, with nothing of his own to do.
static func _stand(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


static func run(t) -> void:
	_hound_gate(t)
	_hellmouth(t)


static func _hound_gate(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- Level 1 (no level given, and level 1): today's numbers, no twist.
	for extra in [{}, {"level": 1}]:
		var fx: HoundGateFx = FxTimeline.cast(load(HOUND), ctx, at, extra)
		t.check(fx.lv_hounds == HoundGateFx.HOUNDS and fx.lv_hounds == 4 and is_equal_approx(fx.lv_hunt, 30.0) and fx.lv_blows == 4
			and is_equal_approx(fx.hunt_end(), HoundGateFx.T_OPEN + 4.0 * HoundGateFx.OUT_EVERY + 30.0)
			and is_equal_approx(fx.duration, fx.hunt_end() + HoundGateFx.BURN + 0.1),
			"Hound Gate level 1 %s: 4 hounds, a 30 s hunt, 4 blows, today's timings" % str(extra))
		_run(fx, HoundGateFx.T_OPEN + 4.0 * HoundGateFx.OUT_EVERY + 0.1)
		var hp_ok := true
		for a in fx.visitors.living():
			hp_ok = hp_ok and is_equal_approx(a.health, 4.0)
		t.check(fx.out == 4 and fx.visitors.living().size() == 4 and hp_ok and not fx.can_follow_up()
			and not fx.follow_up(at, {}),
			"level 1: four hounds out, each takes 4 blows, and a click is no follow-up")
		fx.end_now()
		fx.free()

	# --- Level 5: six hounds, a 38 s hunt, 5 blows.
	var near_one: Person = crowd.citizens[0]
	var far_one: Person = crowd.citizens[1]
	var five: HoundGateFx = FxTimeline.cast(load(HOUND), ctx, at, {"level": 5})
	t.check(five.lv_hounds == 6 and is_equal_approx(five.lv_hunt, 38.0) and five.lv_blows == 5
		and is_equal_approx(five.hunt_end(), HoundGateFx.T_OPEN + 6.0 * HoundGateFx.OUT_EVERY + 38.0)
		and is_equal_approx(five.last_out(), HoundGateFx.T_OPEN + 5.0 * HoundGateFx.OUT_EVERY),
		"Hound Gate level 5: 6 hounds, a 38 s hunt, 5 blows, the timings follow")
	t.check(not five.can_follow_up() and not five.follow_up(at, {}), "Quarry: no mark before the hounds are out")
	_run(five, HoundGateFx.T_OPEN + 6.0 * HoundGateFx.OUT_EVERY + 0.05)
	var hp5 := true
	for a in five.visitors.living():
		hp5 = hp5 and is_equal_approx(a.health, 5.0)
	t.check(five.out == 6 and five.visitors.living().size() == 6 and hp5, "level 5: six hounds out, each takes 5 blows")

	# --- Quarry: one standing far beyond the hounds' reach is marked, and every hound runs for them; a nearer one is
	# left alone.
	_stand(near_one, grid.nearest_walkable(at + Vector2(2.0, 0.0)))
	_stand(far_one, grid.nearest_walkable(at + Vector2(12.0, 0.0)))
	var far_gap := INF
	for a in five.visitors.living():
		far_gap = minf(far_gap, a.ground_pos.distance_to(far_one.ground_pos))
	t.check(far_gap > HoundGateFx.SEEK_R, "the far one stands beyond every hound's reach (%.1f)" % far_gap)
	t.check(five.can_follow_up() and not five.follow_up(at + Vector2(0.0, -20.0), {}) and five.quarry == null,
		"Quarry: a click on empty ground marks nobody")
	t.check(five.follow_up(far_one.ground_pos + Vector2(0.5, 0.0), {}) and five.quarry == far_one
		and five.visitors.marked() == far_one and five.marks == 1,
		"Quarry: a click half a unit from the far one marks them")
	_run(five, 1.0)
	var all_far := true
	var moved_off := 0
	for a in five.visitors.living():
		all_far = all_far and a.target == far_one
		if a.ground_pos.distance_to(at) > 1.5:
			moved_off += 1
	t.check(all_far and five.visitors.living().size() == 6 and moved_off == 6 and near_one.is_alive(),
		"every hound runs for the marked one, by the streets (%d of 6 off the gate), and the near one is left alone" % moved_off)
	# A new mark replaces the old.
	t.check(five.follow_up(near_one.ground_pos, {}) and five.quarry == near_one and five.visitors.marked() == near_one
		and five.marks == 2, "Quarry: a new mark replaces the old")
	_run(five, DT)
	var all_near := true
	for a in five.visitors.living():
		all_near = all_near and a.target == near_one
	t.check(all_near, "every hound turns to the new mark")
	var took := 0.0
	while near_one.is_alive() and took < 10.0:
		five._process(DT)
		took += DT
	t.check(not near_one.is_alive() and five.visitors.marked() == null and far_one.is_alive(),
		"the marked one is run down (%.2f s), and the mark is gone with them" % took)
	# Marked again from beyond their reach, the far one is run down too, wherever they stand.
	far_gap = INF
	for a in five.visitors.living():
		far_gap = minf(far_gap, a.ground_pos.distance_to(far_one.ground_pos))
	t.check(far_gap > HoundGateFx.SEEK_R and five.follow_up(far_one.ground_pos, {}), "the far one, beyond reach again (%.1f), is marked" % far_gap)
	took = 0.0
	while far_one.is_alive() and took < 20.0:
		five._process(DT)
		took += DT
	t.check(not far_one.is_alive() and far_one._kind == &"frenzy" and five.visitors.marked() == null,
		"the hounds cross the town by the streets and bite the far one dead (%.2f s)" % took)
	five.end_now()
	five.free()

	# --- Level 4: no Quarry.
	var four: HoundGateFx = FxTimeline.cast(load(HOUND), ctx, at, {"level": 4})
	_run(four, HoundGateFx.T_OPEN + 6.0 * HoundGateFx.OUT_EVERY + 0.05)
	_stand(far_one, grid.nearest_walkable(at + Vector2(12.0, 0.0)))
	t.check(four.lv_hounds == 6 and four.lv_blows == 5 and four.hunting() and not four.can_follow_up()
		and not four.follow_up(far_one.ground_pos, {}) and four.visitors.marked() == null and four.quarry == null,
		"Hound Gate level 4 refuses the follow-up: no mark")
	four.end_now()
	four.free()
	_done(made)


static func _hellmouth(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	ctx.world = null
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	crowd.fires.clear()

	# --- Level 1: today's numbers, no twist.
	var edge: Person = crowd.citizens[0]
	for extra in [{}, {"level": 1}]:
		var fx: HellmouthSparkFx = FxTimeline.cast(load(SPARK), ctx, at, extra)
		_stand(edge, at + Vector2(1.9, 0.0))
		t.check(is_equal_approx(fx.lv_radius, 1.5) and is_equal_approx(fx.lv_open, 6.0)
			and is_equal_approx(fx.duration, HellmouthSparkFx.T_OPEN + 6.0 + HellmouthSparkFx.AFTER),
			"Hellmouth Spark level 1 %s: a 1.5 mouth open 6 s" % str(extra))
		fx._process(HellmouthSparkFx.T_OPEN + 0.05)
		t.check(fx.open() and edge.is_alive() and not fx.can_follow_up() and not fx.follow_up(at + Vector2(3.0, 0.0), {})
			and fx.mouth == at, "level 1: one 1.9 off is not reached, and a click does not move the mouth")
		fx._process(6.0)
		t.check(not fx.open(), "level 1: shut 6 s after it opened")
		fx.free()
		crowd.fires.clear()

	# --- Level 5: a 2.1 mouth open 8 s.
	crowd.threats.clear()  # the level-1 casts' dangers (the crowd is not stepped here, so they never run out)
	var five: HellmouthSparkFx = FxTimeline.cast(load(SPARK), ctx, at, {"level": 5})
	_stand(edge, at + Vector2(1.9, 0.0))
	t.check(is_equal_approx(five.lv_radius, 2.1) and is_equal_approx(five.lv_open, 8.0)
		and is_equal_approx(five.duration, HellmouthSparkFx.T_OPEN + 8.0 + HellmouthSparkFx.AFTER),
		"Hellmouth Spark level 5: a 2.1 mouth open 8 s")
	t.check(not five.can_follow_up() and not five.follow_up(at + Vector2(3.0, 0.0), {}),
		"Wandering Mouth: no move while the paving still tears")
	five._process(HellmouthSparkFx.T_OPEN + 0.05)
	t.check(five.open() and not edge.is_alive() and edge._kind == &"fire", "level 5: one 1.9 off burns")
	var fire_at := func(p: Vector2) -> int:
		return crowd.threats.nearby(p, 0.0).filter(func(th: Dictionary) -> bool: return th.kind == &"fire").size()
	t.check(fire_at.call(at) == 1, "the open mouth is a fire danger where it stands")

	# --- Wandering Mouth: a click 10 off moves it 4 that way; a second click is refused.
	var old_spot: Person = crowd.citizens[1]
	var new_spot: Person = crowd.citizens[2]
	t.check(five.can_follow_up() and five.follow_up(at + Vector2(10.0, 0.0), {}) and five.moved
		and five.mouth.is_equal_approx(at + Vector2(4.0, 0.0)),
		"Wandering Mouth: a click moves the open mouth, no farther than 4 (%s)" % str(five.mouth - at))
	t.check(not five.can_follow_up() and not five.follow_up(at, {}) and five.mouth.is_equal_approx(at + Vector2(4.0, 0.0)),
		"Wandering Mouth: once a cast -- a second click is refused")
	t.check(five.open() and fire_at.call(at + Vector2(4.0, 0.0)) == 1 and fire_at.call(at) == 0,
		"the danger moves with the mouth: none left where it was")
	_stand(old_spot, at + Vector2(0.2, 0.1))
	_stand(new_spot, at + Vector2(4.0, 0.0) + Vector2(-0.3, 0.2))
	var burned := five.burned
	five._process(HellmouthSparkFx.BURN_EVERY)
	t.check(not new_spot.is_alive() and new_spot._kind == &"fire" and old_spot.is_alive() and five.burned == burned + 1,
		"the next tick burns at the new place and not at the old")
	# It stays open for the rest of its time at the new place, and shuts on time.
	five._process(five.shut_at() - five.t - 0.1)
	t.check(five.open() and old_spot.is_alive(), "it stays open for the rest of its time")
	five._process(0.2)
	t.check(not five.open(), "and shuts at its own time")
	five.free()
	crowd.fires.clear()

	# --- Level 4: no Wandering Mouth.
	var four: HellmouthSparkFx = FxTimeline.cast(load(SPARK), ctx, at, {"level": 4})
	four._process(HellmouthSparkFx.T_OPEN + 0.05)
	t.check(four.open() and is_equal_approx(four.lv_radius, 1.95) and not four.can_follow_up()
		and not four.follow_up(at + Vector2(3.0, 0.0), {}) and four.mouth == at,
		"Hellmouth Spark level 4 refuses the follow-up: the mouth stays")
	four.free()
	crowd.fires.clear()
	_done(made)

