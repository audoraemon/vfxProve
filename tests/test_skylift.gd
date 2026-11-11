extends RefCounted
## Skylift (Passage, Tier I): a beam takes whatever stands in one place -- people, goods, a stall -- and drops it in
## another; the goods land as a heap that crushes and bars the way.


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
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## A barrel standing at `at`, as the town builds its decor.
static func _barrel(env: EnvironmentField, at: Vector2) -> Decor:
	var d := Decor.new().setup(Decor.Kind.BARREL, at, Vector2.ZERO, 11)
	env.add_decor(d)
	return d


## The nearest place about `near` with open ground for a lift and nothing to lift but people, and open ground
## eight units south of it to set down on.
static func _bare(env: EnvironmentField, grid: WalkGrid, near: Vector2) -> Vector2:
	for dy in range(-16, 17):
		for dx in range(-16, 17):
			var c := near + Vector2(float(dx), float(dy)) * 0.5
			var down := c + Vector2(0.0, 8.0)
			if grid.walkable(c) and grid.walkable(down) and SkyliftFx.goods_at(env, c).is_empty() \
					and not env.blocked(down, 0.0):
				return c
	return Vector2.INF


static func run(t) -> void:
	# --- The book
	var lift := PowerBook.get_power("skylift")
	t.check(int(lift.dp) == 1 and PowerBook.is_quiet("skylift") and String(lift.aim) == "two clicks"
		and Rules.POWER_KINDS["skylift"] == [&"stone"] and float(Targeting.AREAS["skylift"].r) == SkyliftFx.RADIUS,
		"Skylift is Passage's 1 DP quiet two-click power; its kills are stone (the heap), its ring its RADIUS")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var town: Town = made[6]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var to := grid.nearest_walkable(at + Vector2(0.0, 8.0))
	var broken := [0]
	env.structure_destroyed.connect(func(_s, _k): broken[0] += 1)

	# --- The people, as before
	var a: Person = crowd.citizens[0]
	var guard: Person = crowd.soldiers[0]
	var left: Person = crowd.citizens[1]
	a.mind = Person.Mind.CALM
	a.ground_pos = at + Vector2(0.6, 0.2)
	guard.ground_pos = at + Vector2(-0.5, -0.4)
	left.mind = Person.Mind.CALM
	left.ground_pos = at + Vector2(SkyliftFx.RADIUS + 1.0, 0.0)
	var bound := grid.nearest_walkable(at + Vector2(5.0, 0.0))
	a.set_goal(bound)
	var mind := a.mind
	t.check(SkyliftFx.lifted_at(field, at).has(a) and SkyliftFx.lifted_at(field, at).has(guard) and not SkyliftFx.lifted_at(field, at).has(left),
		"Skylift would take whoever stands in its circle, a soldier too, and nobody beside it")
	# --- The goods: a barrel on the ground, and a market stall, both in the circle
	var barrel := _barrel(env, at + Vector2(0.5, -0.5))
	town._decor.append(barrel)
	var stall := env.add_structure(Rect2(at + Vector2(-1.6, 0.6), Vector2(0.8, 0.6)), 10.0, Structure.Kind.MARKET_STALL, &"market")
	var would := SkyliftFx.goods_at(env, at)
	t.check(would.has(barrel) and would.has(stall), "and the goods in it: a barrel on the ground, a market stall (%d things)" % would.size())
	var decor_taken := would.filter(func(x): return x is Decor).size()
	var built_taken := would.filter(func(x): return x is Structure).size()
	var decor_before := env.decor().size()
	var structures_before := env.structures().size()
	# --- Whoever stands where the goods come down
	var under: Person = crowd.citizens[2]
	var beside: Person = crowd.citizens[3]
	under.ground_pos = to
	beside.ground_pos = to + Vector2(SkyliftFx.HEAP * 0.5 + 0.4, 0.0)
	t.check(grid.walkable(to) and not env.blocked(to, 0.0), "the second place is open ground")

	var beam: SkyliftFx = FxTimeline.cast(load("res://src/fx/control/skylift.gd"), ctx, at, {"to": to})
	beam._process(SkyliftFx.T_TAKE - 0.1)
	t.check(beam.taken == 0 and a.ground_pos.distance_to(at) < SkyliftFx.RADIUS and env.decor().size() == decor_before and under.is_alive(),
		"the light stands on them; nobody and nothing is gone yet")
	beam._process(0.2)
	t.check(beam.taken == 2 and a.ground_pos.distance_to(to + Vector2(0.6, 0.2)) < 0.9 and guard.ground_pos.distance_to(to) < SkyliftFx.RADIUS + 0.9
		and left.ground_pos.distance_to(at) < SkyliftFx.RADIUS + 1.1, "then they stand at the other place, as they stood; the one beside it is where he was (%d)" % beam.taken)
	t.check(a.is_alive() and guard.is_alive() and a.mind == mind and a.goal().distance_to(bound) < 0.6, "unhurt, of the same mind, still bound for where they were going")
	t.check(SkyliftFx.goods_at(env, at).is_empty() and env.decor().size() == decor_before - decor_taken
		and town._decor.all(func(d): return is_instance_valid(d)),
		"the barrel is gone from the ground with the other goods there, and the town has forgotten them (%d decor, was %d)" % [env.decor().size(), decor_before])
	t.check(env.structures().size() == structures_before - built_taken + 1 and broken[0] == 0,
		"the stall is gone too -- lifted, not broken: nothing destroyed, no rubble (%d structures, %d broken)" % [env.structures().size() - structures_before, broken[0]])
	var kinds := []
	for g in beam.goods:
		kinds.append(g.kind)
	t.check(beam.goods.size() >= 4 and kinds.has(Decor.Kind.BARREL) and kinds.has(Decor.Kind.TABLE) and kinds.has(Decor.Kind.CRATES),
		"the heap holds the barrel and the stall's table, crates and barrel (%d pieces)" % beam.goods.size())
	t.check(beam.heap != null and beam.heap.role == &"windfall" and not beam.heap.destroyed and env.structures().has(beam.heap)
		and beam.heap.center().distance_to(to) < 0.01, "they land at the second place as one heap, a windfall pile the engineers clear")
	t.check(not grid.walkable(to), "the way under the heap is barred")
	t.check(not under.is_alive() and under._kind == &"stone" and beam.crushed == 1, "whoever stood where it came down is crushed by stone")
	t.check(beside.is_alive() and a.is_alive() and guard.is_alive(), "nobody a step away, and none of those the beam set down there")
	t.check(a.ground_pos.distance_to(to) >= SkyliftFx.HEAP * 0.5 and guard.ground_pos.distance_to(to) >= SkyliftFx.HEAP * 0.5,
		"those it set down on the heap's footprint are pushed clear of it (%.2f, %.2f)" % [a.ground_pos.distance_to(to), guard.ground_pos.distance_to(to)])
	beam._process(SkyliftFx.LIFE * 0.5)
	t.check(beam.heap != null and not grid.walkable(to), "untended, the heap stands")
	beam._process(SkyliftFx.LIFE * 0.5 + 0.5)
	t.check(beam.heap == null and grid.walkable(to) and not env.structures().any(func(s): return is_instance_valid(s) and s.role == &"windfall"),
		"and LIFE after the drop it is gone and the way is open")
	beam._process(1.0)
	beam.free()

	# --- A lift with only people leaves nothing behind
	var bare := _bare(env, grid, at + Vector2(6.0, 0.0))
	t.check(bare != Vector2.INF, "a place with people and no goods")
	var lone: Person = crowd.citizens[4]
	lone.ground_pos = bare
	var bare_to := grid.nearest_walkable(bare + Vector2(0.0, 8.0))
	var second: SkyliftFx = FxTimeline.cast(load("res://src/fx/control/skylift.gd"), ctx, bare, {"to": bare_to})
	second._process(SkyliftFx.T_TAKE + 0.1)
	t.check(second.taken == 1 and second.goods.is_empty() and second.heap == null and grid.walkable(bare_to)
		and second.duration < SkyliftFx.T_TAKE + 5.0, "a lift of people alone sets them down and leaves no heap; the beam is soon done")
	second._process(5.0)
	second.free()

	# --- The night ends with the heap still lying: it goes with the beam
	_barrel(env, bare + Vector2(0.3, 0.3))
	var third: SkyliftFx = FxTimeline.cast(load("res://src/fx/control/skylift.gd"), ctx, bare, {"to": bare_to})
	third._process(SkyliftFx.T_TAKE + 0.1)
	t.check(third.heap != null and not grid.walkable(bare_to), "a barrel alone makes a heap that bars the way")
	third.end_now()
	t.check(third.heap == null and grid.walkable(bare_to), "end_now() takes the heap away with the beam")
	third.free()

	# --- The heap does not land inside a building
	_barrel(env, bare + Vector2(0.3, -0.3))
	var house: Structure = null
	for s in env.structures():
		if is_instance_valid(s) and not s.destroyed and s.kind == Structure.Kind.HOUSE and not s.walkable:
			house = s
			break
	if house != null:
		var inside := house.center()
		var landing := SkyliftFx.landing_for(env, inside)
		t.check(landing != Vector2.INF and not env.blocked(landing, 0.0) and landing.distance_to(inside) <= SkyliftFx.SHIFT + 0.01,
			"aimed into a house, the heap takes the nearest open spot within SHIFT (%.2f away)" % landing.distance_to(inside))
		var fourth: SkyliftFx = FxTimeline.cast(load("res://src/fx/control/skylift.gd"), ctx, bare, {"to": inside})
		fourth._process(SkyliftFx.T_TAKE + 0.1)
		t.check(fourth.heap != null and fourth.heap.center().distance_to(landing) < 0.01, "and lands there")
		fourth.end_now()
		fourth.free()

	_done(made)
