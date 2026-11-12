extends RefCounted
## Discord level 5 twist, Tangled Threads: for 5 s after the cast, anyone within 1.0 of a person the cast confused (who is still confused) is
## confused for the full time too, one hop only. Level 4 has no threads.


static func _ctx() -> Array:
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
	ctx.ground = Node2D.new()
	ctx.overhead = Node2D.new()
	ctx.crowd = crowd
	return [ctx, crowd, world]


static func _free(made: Array) -> void:
	var ctx: FxContext = made[0]
	ctx.ground.free()
	ctx.overhead.free()
	(made[1] as Crowd).clear()
	(made[2] as Node).free()


## Step the effect to `to` seconds in 0.1 s frames.
static func _to(fx: DiscordFx, to: float) -> void:
	while fx.t < to - 0.001 and not fx.finished:
		fx._process(0.1)


static func run(t) -> void:
	var made := _ctx()
	var ctx: FxContext = made[0]
	var crowd: Crowd = made[1]
	var at := Vector2(0.8, 2.0)
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var c: Person = crowd.citizens[2]
	var d: Person = crowd.citizens[3]
	var s: Person = crowd.soldiers[0]
	for i in range(4, crowd.citizens.size()):
		(crowd.citizens[i] as Person).ground_pos = Vector2(-40.0, -40.0)
	for i in range(1, crowd.soldiers.size()):
		(crowd.soldiers[i] as Person).ground_pos = Vector2(-40.0, -40.0)
	a.ground_pos = at
	b.ground_pos = Vector2(-20.0, -20.0)
	c.ground_pos = Vector2(-22.0, -20.0)
	d.ground_pos = Vector2(-24.0, -20.0)
	s.ground_pos = Vector2(-26.0, -20.0)
	var fx := FxTimeline.cast(DiscordFx, ctx, at, {"level": 5}) as DiscordFx
	t.check(a.mind == Person.Mind.CONFUSED and a in fx.confused, "level 5: the click confuses A as ever")
	t.near(fx.duration, DiscordFx.TANGLE_TIME + 0.2, 0.001, "and the effect lasts TANGLE_TIME + 0.2")
	t.near(fx.busy, 0.6, 0.001, "busy stays 0.6")
	_to(fx, 2.0)
	b.ground_pos = at + Vector2(0.8, 0.0)
	_to(fx, 2.2)
	t.check(b.mind == Person.Mind.CONFUSED and fx.caught.has(b), "B placed 0.8 from A at 2.0 s is caught")
	t.near(b.confused_left(), 20.0 - 0.1, 0.25, "for the full 20 s")
	c.ground_pos = b.ground_pos + Vector2(0.8, 0.0)
	_to(fx, 3.5)
	t.check(c.mind != Person.Mind.CONFUSED and not fx.caught.has(c), "C 0.8 from B (1.6 from A) is not: one hop")
	c.ground_pos = Vector2(-22.0, -20.0)
	s.ground_pos = at + Vector2(0.0, 0.8)
	_to(fx, 3.7)
	t.check(s.mind == Person.Mind.CONFUSED and fx.caught.has(s), "a soldier near A is caught")
	_to(fx, 5.0)
	d.ground_pos = at + Vector2(-0.8, 0.0)
	_to(fx, 5.4)
	t.check(d.mind != Person.Mind.CONFUSED and not fx.caught.has(d), "D placed at 5.3 s is not: the window is over")
	fx.free()

	# A recovered A passes nothing.
	var e: Person = crowd.citizens[4]
	e.ground_pos = Vector2(-10.0, -10.0)
	a._come_to()
	a.ground_pos = Vector2(5.0, 5.0)
	var fx2 := FxTimeline.cast(DiscordFx, ctx, a.ground_pos, {"level": 5}) as DiscordFx
	a._come_to()
	e.ground_pos = a.ground_pos + Vector2(0.8, 0.0)
	_to(fx2, 1.0)
	t.check(a.mind != Person.Mind.CONFUSED and e.mind != Person.Mind.CONFUSED and fx2.caught.is_empty(),
		"A recovered passes nothing")
	fx2.free()

	# Level 4: no threads.
	var g: Person = crowd.citizens[5]
	var h: Person = crowd.citizens[6]
	g.ground_pos = Vector2(10.0, 10.0)
	h.ground_pos = Vector2(-30.0, -30.0)
	var fx4 := FxTimeline.cast(DiscordFx, ctx, g.ground_pos, {"level": 4}) as DiscordFx
	h.ground_pos = g.ground_pos + Vector2(0.8, 0.0)
	_to(fx4, 2.0)
	t.check(g.mind == Person.Mind.CONFUSED and h.mind != Person.Mind.CONFUSED and fx4.caught.is_empty(),
		"level 4: B is not confused")
	t.near(fx4.duration, 1.2, 0.001, "and duration == 1.2")
	t.near(fx4.busy, 0.6, 0.001, "busy == 0.6")
	fx4.free()
	_free(made)
