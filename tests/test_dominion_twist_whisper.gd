extends RefCounted
## Mind Whisper level 5 twist, Held String: a whisper (walk, attack or burn) leaves no shake-off when it wears off, so the same one can be
## whispered again once the 6 s cooldown is over. Level 4 shakes it off as ever. Rules.cast() is the route; the real caster makes the effect.


static func _crowd() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _empty(made: Array) -> Vector2:
	var grid: WalkGrid = made[4]
	var field: EnemyField = made[3]
	for i in 400:
		var at := grid.nearest_walkable(Vector2(-24.0 + float(i % 20) * 2.4, -24.0 + float(i / 20) * 2.4))
		if at != Vector2.INF and field.in_radius(at, 7.0).is_empty():
			return at
	return Vector2.INF


static func _ctx(made: Array) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = made[1]
	ctx.field = made[3]
	ctx.rng = RandomNumberGenerator.new()
	ctx.ground = Node2D.new()
	ctx.overhead = Node2D.new()
	ctx.crowd = made[0]
	return ctx


static func _think(p: Person, seconds: float, hold: Vector2 = Vector2.INF) -> void:
	var t := 0.0
	while t < seconds:
		if hold != Vector2.INF:
			p.ground_pos = hold
		p._think(0.1)
		t += 0.1


static func _arrive(p: Person) -> void:
	if p.goal() != Vector2.INF:
		p.ground_pos = p.goal()
		p._goal = Vector2.INF
		p._path = PackedVector2Array()


## A rules book with the whisper in slot 0 at `level`.
static func _rules(made: Array, ctx: FxContext, level: int) -> Rules:
	var rules := Rules.new().setup(PackedStringArray(["whisper"]), ctx, made[1], made[3], made[0], made[5])
	rules.levels = {"whisper": level}
	return rules


static func run(t) -> void:
	_walk(t)
	_attack(t)
	_mixed(t)


static func _walk(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var ctx := _ctx(made)
	var base := _empty(made)
	var refused: Array = []
	var p: Person = crowd.citizens[10]
	p.ground_pos = base
	var to: Vector2 = (made[4] as WalkGrid).nearest_walkable(base + Vector2(2.0, 0.0))

	# Level 5: the walk whisper leaves no shake-off.
	var rules := _rules(made, ctx, 5)
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	var fx := rules.cast(0, p.ground_pos, {"to": to, "target": p})
	t.check(fx != null and p.mind == Person.Mind.WHISPERED, "level 5: the walk whisper takes")
	t.near(rules.cooldown_left(0), 6.0, 0.001, "and the cooldown still runs (6.0)")
	_arrive(p)
	_think(p, 8.6, p.ground_pos)
	t.check(p.mind != Person.Mind.WHISPERED and not p.shaken(), "level 5: after the whisper wears off the person is not shaken")
	fx._process(0.1)
	fx._process(1.0)  # the effect fades out with the whisper and frees the one-power lock
	rules.advance(6.1)
	var again := rules.cast(0, p.ground_pos, {"to": to, "target": p})
	t.check(again != null and refused.is_empty() and p.mind == Person.Mind.WHISPERED,
		"and after the cooldown the same one is whispered again (%s)" % [refused])
	rules.free()

	# Level 4: shaken as ever.
	var q: Person = crowd.citizens[11]
	q.ground_pos = base + Vector2(0.0, 1.0)
	var r4 := _rules(made, ctx, 4)
	var refused4: Array = []
	r4.cast_refused.connect(func(s: int, why: String) -> void: refused4.append([s, why]))
	var to4: Vector2 = (made[4] as WalkGrid).nearest_walkable(q.ground_pos + Vector2(2.0, 0.0))
	var fx4 := r4.cast(0, q.ground_pos, {"to": to4, "target": q})
	_arrive(q)
	_think(q, 8.6, q.ground_pos)
	t.check(q.shaken(), "level 4: the person is shaken when it wears off")
	fx4._process(0.1)
	fx4._process(1.0)
	r4.advance(8.1)
	t.check(r4.cast(0, q.ground_pos, {"to": to4, "target": q}) == null and refused4 == [[0, "shaken"]] and r4.refused_who == q,
		"and a second whisper is refused as shaken, naming them (%s)" % [refused4])
	r4.free()
	ctx.ground.free()
	ctx.overhead.free()
	crowd.clear()
	(made[2] as Node).free()


static func _attack(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var ctx := _ctx(made)
	var base := _empty(made)
	var who: Person = crowd.citizens[50]
	var foe: Person = crowd.citizens[51]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(0.3, 0.0)
	var rules := _rules(made, ctx, 5)
	var fx := rules.cast(0, who.ground_pos, {"target": who, "order": "attack", "foe": foe})
	t.check(fx != null and who.mind == Person.Mind.FIGHT, "level 5 attack: the whispered one is set on the foe")
	var foe_h := foe.health
	for k in 160:
		who.ground_pos = base
		foe.ground_pos = base + Vector2(0.3, 0.0)
		foe.health = foe_h
		who._think(0.1)
	t.check(who.mind != Person.Mind.FIGHT and who.mind != Person.Mind.WHISPERED, "the fight is over")
	t.check(not who.shaken(), "level 5 attack: after the fight the person is not shaken")
	rules.free()
	ctx.ground.free()
	ctx.overhead.free()
	crowd.clear()
	(made[2] as Node).free()


## A level 5 whisper and then a level 4 one: the later one's wake shakes as today.
static func _mixed(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var ctx := _ctx(made)
	var base := _empty(made)
	var p: Person = crowd.citizens[10]
	p.ground_pos = base
	var to: Vector2 = (made[4] as WalkGrid).nearest_walkable(base + Vector2(2.0, 0.0))
	var r5 := _rules(made, ctx, 5)
	var r4 := _rules(made, ctx, 4)
	r5.cast(0, p.ground_pos, {"to": to, "target": p})
	r4.cast(0, p.ground_pos, {"to": to, "target": p})  # still whispered: a new whisper is heard, and clears the flag
	_arrive(p)
	_think(p, 8.6, p.ground_pos)
	t.check(p.shaken(), "a level 5 whisper then a level 4 one: shaken after the second")
	r5.free()
	r4.free()
	ctx.ground.free()
	ctx.overhead.free()
	crowd.clear()
	(made[2] as Node).free()
