extends RefCounted
## Madness Bloom level 5 twist, Directed Frenzy: the cast's seeds who reach Broken all frenzy (no roll) and go for the nearest soldier in
## sight first; a person the madness spread to is not directed. Level 4 directs nobody and draws the manager's rng as ever.


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
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.crowd = crowd
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	return [crowd, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[4]
	ctx.overhead.free()
	ctx.ground.free()
	(made[3] as Node).free()


static func _run_for(crowd: Crowd, people: Array, seconds: float, dt := 0.1) -> void:
	var left := seconds
	while left > 0.0:
		for p: Person in people:
			if is_instance_valid(p) and p.is_alive():
				p.tick(dt)
		crowd.madness.step(dt)
		left -= dt


## Run until each seed first turns to FIGHT (checked right after the manager's step, before their own thinking can retarget); returns seed -> target then.
static func _first_targets(crowd: Crowd, seeds: Array, limit: float) -> Dictionary:
	var out := {}
	var left := limit
	while left > 0.0 and out.size() < seeds.size():
		_run_for(crowd, seeds, 0.1)
		for p: Person in seeds:
			if not out.has(p) and p.mind == Person.Mind.FIGHT:
				out[p] = p.fight_target
		left -= 0.1
	return out


## Six citizens round `at`, mind CALM, and the cast at `level`. Returns the effect.
static func _cast(made: Array, at: Vector2, level: int) -> MadnessBloomFx:
	var crowd: Crowd = made[0]
	for k in 6:
		var c: Person = crowd.citizens[k]
		c.ground_pos = at + Vector2(0.3 * float(k % 3), 0.3 * float(k / 3))
		c.mind = Person.Mind.CALM
	return FxTimeline.cast(load("res://src/fx/curse/madness_bloom.gd"), made[4], at + Vector2(0.3, 0.15), {"level": level})


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var m := crowd.madness
	var at := (made[1] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var near_s: Person = crowd.soldiers[0]
	var far_s: Person = crowd.soldiers[1]
	near_s.ground_pos = at + Vector2(1.5, 0.0)
	far_s.ground_pos = at + Vector2(0.0, 2.5)
	var fx := _cast(made, at, 5)
	var seeds: Array = fx.afflicted.duplicate()
	t.check(seeds.size() >= 4 and m.directed.size() == seeds.size(), "level 5: every afflicted seed is directed (%d)" % seeds.size())
	for p: Person in seeds:
		p.statuses[MadnessManager.STATUS] = 0.89
	# A person the madness spreads to is not directed.
	var other: Person = crowd.citizens[20]
	other.ground_pos = at + Vector2(0.5, 0.5)
	m.afflict(other, 0.1)
	t.check(not m.directed.has(other), "a spread (afflict) is not directed")
	var first := _first_targets(crowd, seeds, 4.0)
	var all_frenzy := true
	for p: Person in seeds:
		all_frenzy = all_frenzy and int(m.afflicted[p].outcome) == MadnessManager.Outcome.FRENZY
	t.check(all_frenzy and m.broken >= seeds.size(), "all directed seeds take FRENZY at Broken")
	var on_near := 0
	for p: Person in first:
		if first[p] == near_s:
			on_near += 1
	t.check(first.size() == seeds.size() and on_near == seeds.size(), "each goes for the nearest soldier in sight (%d of %d on him)" % [on_near, seeds.size()])
	fx.free()
	m.clear()

	# No soldier in sight: no target, as today.
	var made2 := _setup()
	var crowd2: Crowd = made2[0]
	var at2 := (made2[1] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var fx2 := _cast(made2, at2, 5)
	var seeds2: Array = fx2.afflicted.duplicate()
	for p: Person in seeds2:
		p.statuses[MadnessManager.STATUS] = 0.89
	var first2 := _first_targets(crowd2, seeds2, 4.0)
	var blind := true
	for p: Person in first2:
		blind = blind and first2[p] == null
	t.check(first2.size() == seeds2.size() and blind, "with no soldier in sight they frenzy on no one in particular")
	fx2.free()
	_done(made2)

	# Level 4: nobody directed, and the manager's rng is drawn exactly as a cast with no level draws it.
	var made4 := _setup()
	var crowd4: Crowd = made4[0]
	var fx4 := _cast(made4, at, 4)
	t.check(crowd4.madness.directed.is_empty() and not fx4.afflicted.is_empty(), "level 4: directed is empty")
	var seeds4: Array = fx4.afflicted.duplicate()
	for p: Person in seeds4:
		p.statuses[MadnessManager.STATUS] = 0.5
	_run_for(crowd4, seeds4, 3.0)
	var state4 := crowd4.madness._rng.state
	fx4.free()
	_done(made4)
	var made1 := _setup()
	var crowd1: Crowd = made1[0]
	var fx1 := _cast(made1, at, 1)
	var seeds1: Array = fx1.afflicted.duplicate()
	for p: Person in seeds1:
		p.statuses[MadnessManager.STATUS] = 0.5
	_run_for(crowd1, seeds1, 3.0)
	t.check(crowd1.madness.directed.is_empty() and crowd1.madness._rng.state == state4, "and the rng state after the same steps is a level-1 cast's")
	fx1.free()
	_done(made1)
	m.clear()
	_done(made)
