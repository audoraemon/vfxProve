extends RefCounted
## Mirrorfold Passage: whoever steps onto the way in is at once on the same spot of the way out, with the same mind, the
## same goal and a new path to it. One already standing there is left until it steps off and back on. The way out
## takes nobody back, and nobody notices: no alarm, no danger. When it is over, the ground is only ground.

const PATH := "res://src/fx/control/mirrorfold_passage.gd"


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
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[4] as Node).free()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()


static func run(t) -> void:
	var p := PowerBook.get_power("mirror")
	t.check(PowerBook.authority_of("mirror") == "passage" and PowerBook.is_quiet("mirror") and String(p.aim) == "two clicks"
		and PowerBook.icon("mirror") != null and PowerBook.hud_icon("mirror") != null and PowerBook.clip("mirror") != null,
		"%s is a quiet Passage power aimed with two clicks, with its icons and clip" % p.name)

	# The oval: long across the screen, short down it.
	var a := Vector2(2.75, 11.25)  # the Main Gate's plaza
	var across: Vector2 = MirrorfoldFx.ACROSS
	var down: Vector2 = MirrorfoldFx.DOWN
	t.check(MirrorfoldFx.on_mirror(a, a + across * (MirrorfoldFx.HALF_WIDE - 0.1))
		and not MirrorfoldFx.on_mirror(a, a + across * (MirrorfoldFx.HALF_WIDE + 0.1))
		and MirrorfoldFx.on_mirror(a, a + down * (MirrorfoldFx.HALF_DEEP - 0.1))
		and not MirrorfoldFx.on_mirror(a, a + down * (MirrorfoldFx.HALF_DEEP + 0.1)), "the mirror is an oval, wide by deep")
	t.check(MirrorfoldFx.exit_for(a, a + Vector2(9, 0)) == a + Vector2(9, 0)
		and MirrorfoldFx.exit_for(a, a + Vector2(1, 0)).is_equal_approx(a + Vector2(MirrorfoldFx.MIN_APART, 0))
		and MirrorfoldFx.exit_for(a, a).is_equal_approx(a + Vector2(MirrorfoldFx.MIN_APART, 0)),
		"the way out lies where the drag ended, never nearer than the two can lie apart")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var b := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	# Everyone out of the way, in a far corner.
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var stander: Person = crowd.citizens[0]
	stander.ground_pos = a
	var alarm := crowd.alarm

	var fx: MirrorfoldFx = FxTimeline.cast(load(PATH), ctx, a, {"dir": (b - a).normalized(), "to": b})
	t.check(fx.exit == b and fx.busy == 1.0 and fx.duration == MirrorfoldFx.MIRROR_TIME,
		"the way out is where the second click landed; the cast locks the slots for 1 s, not its whole run")

	# An evacuee on its way out of the town walks onto the way in.
	var walker: Person = crowd.citizens[1]
	walker.ground_pos = a + down * (MirrorfoldFx.HALF_DEEP + 0.5)
	walker.flee()
	walker.set_goal(grid.nearest_exit(walker.ground_pos))
	var goal := walker.goal()
	var mind := walker.mind
	var intent := walker.intent()
	fx._process(0.05)
	t.check(walker.ground_pos.is_equal_approx(a + down * (MirrorfoldFx.HALF_DEEP + 0.5)) and fx.folded == 0,
		"beside the mirror, nothing happens")
	var off := down * 0.5 + across * 0.8
	walker.ground_pos = a + off
	fx._process(0.05)
	t.check(walker.ground_pos.distance_to(b + off) < 0.75, "stepping onto the way in, it is on the same spot of the way out (%s)"
		% [walker.ground_pos - b])
	t.check(walker.is_alive() and walker.mind == mind and walker.intent() == intent and walker.goal() == goal,
		"with the same mind, the same intent and the same goal")
	t.check(not walker._path.is_empty() and walker._path[0].distance_to(walker.ground_pos) < 2.0,
		"and a new path to it from where it now stands")

	t.check(stander.ground_pos == a, "one already standing there when it was laid is left alone")
	stander.ground_pos = a + down * (MirrorfoldFx.HALF_DEEP + 0.6)
	fx._process(0.05)
	stander.ground_pos = a
	fx._process(0.05)
	t.check(stander.ground_pos.distance_to(b) < 0.75, "until it steps off and back on")

	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = a + across
	fx._process(0.05)
	t.check(guard.ground_pos.distance_to(b + across) < 0.75, "a soldier is folded like anyone")

	var queued: Person = crowd.citizens[2]
	queued.queue_spot = a + Vector2(3, 3)
	queued.queue_since = 1.0
	queued.ground_pos = a - across
	fx._process(0.05)
	t.check(queued.ground_pos.distance_to(b - across) < 0.75 and queued.queue_spot == Vector2.INF,
		"one waiting in a gate's queue gives up its place there")

	var back: Person = crowd.citizens[3]
	back.ground_pos = b
	var hidden: Person = crowd.citizens[4]
	hidden.inside = true
	hidden.ground_pos = a
	fx._process(0.05)
	t.check(back.ground_pos == b, "the way out takes nobody back")
	t.check(hidden.ground_pos == a, "someone inside a building is out of its reach")
	hidden.inside = false
	t.check(fx.folded == 4, "four folded (%d)" % fx.folded)
	t.check(crowd.alarm == alarm and crowd.threats.active_count() == 0, "and nobody notices: no alarm, no danger")

	fx._process(MirrorfoldFx.MIRROR_TIME)
	var after: Person = crowd.citizens[5]
	after.ground_pos = a
	t.check(fx.finished, "after %d s it is gone" % roundi(MirrorfoldFx.MIRROR_TIME))
	fx._process(0.05)
	t.check(after.ground_pos == a, "and the ground is only ground")
	fx.free()
	_done(made)
