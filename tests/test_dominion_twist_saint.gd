extends RefCounted
## Saint or Sinner, level 5: Passed Mark (SINNER passes the noose on once; SAINT's guards answer in full).


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


## A fresh scene: the chosen at `at`, four of the mob round them, B 2.0 away, C 3.5 away; everyone else parked far off.
static func _scene(made: Array) -> Dictionary:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		person.stop_fighting()
		person.release_compulsion()
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var chosen: Person = crowd.citizens[0]
	chosen.ground_pos = at
	chosen.health = Person.HEALTH_CITIZEN
	var mob: Array[Person] = []
	for k in 4:
		var p: Person = crowd.citizens[1 + k]
		p.ground_pos = at + Vector2(-1.0, 0.3 * float(k) - 0.4)
		mob.append(p)
	var b: Person = crowd.citizens[6]
	b.ground_pos = at + Vector2(0.0, 2.0)
	var c: Person = crowd.citizens[7]
	c.ground_pos = at + Vector2(3.5, 0.0)
	return {"at": at, "chosen": chosen, "mob": mob, "b": b, "c": c}


## B and C stand outside the mob for the test: the cast took them (they are within reach); let them go.
static func _bystanders(fx: SaintFx, b: Person, c: Person) -> void:
	for p in [b, c]:
		fx.people.erase(p)
		p.stop_fighting()
		p.clear_badge()


static func _kill(made: Array, p: Person) -> void:
	(made[3] as EnemyField).kill(p, &"frenzy", Vector2.INF)


static func _sinner(ctx: FxContext, at: Vector2, level: int) -> SaintFx:
	var fx: SaintFx = FxTimeline.cast(load("res://src/fx/dominion/saint_or_sinner.gd"), ctx, at, {"mode": "sinner", "level": level})
	fx._process(SaintFx.T_CAST + 0.05)
	return fx


static func run(t) -> void:
	# --- SINNER, level 5: the mark is passed once
	var made := _setup()
	var ctx: FxContext = made[5]
	var s := _scene(made)
	var chosen: Person
	var b: Person
	var c: Person
	var fx: SaintFx
	made = _setup()
	ctx = made[5]
	s = _scene(made)
	chosen = s.chosen
	b = s.b
	c = s.c
	fx = _sinner(ctx, s.at, 5)
	t.check(fx.people.size() >= 6 and fx.passed_to == null, "Passed Mark: the sinner mob forms as ever (%d)" % fx.people.size())
	_bystanders(fx, b, c)
	_kill(made, chosen)
	fx._process(0.1)
	var all_on_b := true
	for p in fx.people:
		if p.is_alive() and not (p.mind == Person.Mind.FIGHT and p.fight_target == b):
			all_on_b = false
	t.check(fx.passed_to == b and fx.chosen == b and b.badge_left > 0.0 and all_on_b and not fx.people.is_empty(),
		"Passed Mark: the dead chosen's noose goes to the nearest bystander, and every living hunter is set on them")
	_kill(made, b)
	fx._process(0.1)
	t.check(fx.passed_to == b and fx.chosen == b, "and it is passed once: B's death passes nothing")
	fx.free()
	_done(made)

	# Nobody within 3: nothing.
	made = _setup()
	ctx = made[5]
	s = _scene(made)
	chosen = s.chosen
	s.b.ground_pos = chosen.ground_pos + Vector2(0.0, 5.0)
	s.c.ground_pos = chosen.ground_pos + Vector2(5.0, 0.0)
	fx = _sinner(ctx, s.at, 5)
	_bystanders(fx, s.b, s.c)
	_kill(made, chosen)
	fx._process(0.1)
	t.check(fx.passed_to == null, "nobody within 3 of where they fell: the mark goes nowhere")
	fx.free()
	_done(made)

	# Level 4: no pass.
	made = _setup()
	ctx = made[5]
	s = _scene(made)
	chosen = s.chosen
	fx = _sinner(ctx, s.at, 4)
	_bystanders(fx, s.b, s.c)
	var rng_before := ctx.rng.state
	_kill(made, chosen)
	fx._process(0.1)
	t.check(fx.passed_to == null and fx.chosen == chosen and ctx.rng.state == rng_before, "level 4: no pass, no rng drawn")
	fx.free()
	_done(made)

	# --- SAINT, level 5: every idle guard answers a threat; level 4: three
	for level in [5, 4]:
		made = _setup()
		ctx = made[5]
		s = _scene(made)
		chosen = s.chosen
		var crowd: Crowd = made[0]
		var extra_guards: Array[Person] = []
		for k in 2:
			var g: Person = crowd.citizens[8 + k]
			g.ground_pos = chosen.ground_pos + Vector2(1.0, 0.4 * float(k))
		var saint: SaintFx = FxTimeline.cast(load("res://src/fx/dominion/saint_or_sinner.gd"), ctx, s.at, {"mode": "saint", "level": level})
		saint._process(SaintFx.T_CAST + 0.05)
		var foe: Person = crowd.citizens[12]
		foe.ground_pos = chosen.ground_pos + Vector2(0.0, -1.5)
		saint.people.erase(foe)
		foe.fight(chosen, 20.0, SaintFx.CIVIL_BLOW, Person.FightRule.TARGET_ONLY)
		var idle := 0
		for p in saint.people:
			if p.is_alive() and p.mind != Person.Mind.FIGHT:
				idle += 1
		saint._process(SaintFx.RETHINK + 0.05)
		var on_foe := 0
		for p in saint.people:
			if p.mind == Person.Mind.FIGHT and p.fight_target == foe:
				on_foe += 1
		var want := idle if level == 5 else SaintFx.GUARDS_PER_THREAT
		t.check(on_foe == want and idle > SaintFx.GUARDS_PER_THREAT, "SAINT level %d: %d of %d idle guards set on the attacker" % [level, on_foe, idle])
		saint.free()
		_done(made)
