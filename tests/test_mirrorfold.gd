extends RefCounted
## Mirrorfold Passage: the way in is a street-wide lane laid by a drag, the way out the same lane at the click after.
## Whoever steps onto the way in is at once on the matching spot of the way out -- as far along, as far across -- with
## the same mind, the same goal and a new path to it. One already standing there is left until it steps off and back on.
## Loads cross it (EnemyField.through) and fire crosses it (a blaze beside the way in lights a house beside the way out).
## The way out takes nobody back, and nobody notices: no alarm, no danger. When it is over, the ground is only ground.

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
	ctx.crowd = crowd
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
	t.check(PowerBook.authority_of("mirror") == "passage" and PowerBook.is_quiet("mirror") and String(p.aim) == "drag then click"
		and PowerBook.icon("mirror") != null and PowerBook.hud_icon("mirror") != null and PowerBook.clip("mirror") != null,
		"%s is a quiet Passage power aimed with a drag then a click, with its icons and clip" % p.name)

	# The lane: from its start along its direction, HALF to either side.
	var a := Vector2(2.75, 11.25)  # the Main Gate's plaza
	var dir := Vector2(1, 0)
	var side: Vector2 = MirrorfoldFx.side_of(dir)
	var len := 4.0
	t.check(MirrorfoldFx.on_way(a, dir, len, a + dir * 2.0 + side * (MirrorfoldFx.HALF - 0.1))
		and MirrorfoldFx.on_way(a, dir, len, a + dir * 2.0 - side * (MirrorfoldFx.HALF - 0.1))
		and MirrorfoldFx.on_way(a, dir, len, a + dir * 0.05) and MirrorfoldFx.on_way(a, dir, len, a + dir * (len - 0.05)),
		"the way in is a lane: anywhere along it, within HALF of its middle")
	t.check(not MirrorfoldFx.on_way(a, dir, len, a + dir * 2.0 + side * (MirrorfoldFx.HALF + 0.1))
		and not MirrorfoldFx.on_way(a, dir, len, a - dir * 0.1) and not MirrorfoldFx.on_way(a, dir, len, a + dir * (len + 0.1)),
		"and nowhere beside it, before its start or past its end")
	t.check(MirrorfoldFx.local(a, dir, a + dir * 1.5 + side * 0.4).is_equal_approx(Vector2(1.5, 0.4)),
		"a spot on it is known by how far along and how far across it lies")
	t.check(MirrorfoldFx.exit_for(a, dir, len, a + dir * 9.0) == a + dir * 9.0
		and MirrorfoldFx.exit_for(a, dir, len, a + side * 5.0) == a + side * 5.0,
		"the way out starts where the click landed when the two lanes lie clear of each other")
	t.check(MirrorfoldFx.exit_for(a, dir, len, a + dir * 1.0).is_equal_approx(a + dir * (len + MirrorfoldFx.MIN_APART))
		and MirrorfoldFx.exit_for(a, dir, len, a).is_equal_approx(a + dir * (len + MirrorfoldFx.MIN_APART)),
		"a click on the way in pushes the way out on along the lane until the two lie MIN_APART clear")
	t.check(MirrorfoldFx.exit_for(a, dir, len, a + side * 0.5).is_equal_approx(a + side * (MirrorfoldFx.HALF * 2.0 + MirrorfoldFx.MIN_APART)),
		"a click a step beside its start pushes it sideways clear")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var b := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center()) - dir * len * 0.5
	# Everyone out of the way, in a far corner.
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var stander: Person = crowd.citizens[0]
	stander.ground_pos = a + dir * 1.0
	var alarm := crowd.alarm

	var fx: MirrorfoldFx = FxTimeline.cast(load(PATH), ctx, a, {"dir": dir, "length": len, "to": b})
	t.check(fx.exit == b and fx.dir == dir and fx.length == len and fx.busy == 1.0 and fx.duration == MirrorfoldFx.MIRROR_TIME,
		"the way in runs the drag's way and length, the way out starts where the click landed; the cast locks the slots for 1 s, not its whole run")
	t.check(field.portals.has(fx), "while it runs, the passage is one of the field's portals")
	var on_in := a + dir * 2.5 + side * 0.3
	t.check(field.through(on_in).is_equal_approx(b + dir * 2.5 + side * 0.3), "so a load dropped on the way in comes down on the matching spot of the way out")
	t.check(field.through(a - dir * 1.0) == a - dir * 1.0 and field.through(b + dir * 1.0) == b + dir * 1.0,
		"and one dropped anywhere else -- the way out included -- lands where it was dropped")

	# An evacuee on its way out of the town walks onto the way in.
	var walker: Person = crowd.citizens[1]
	walker.ground_pos = a + dir * 2.0 + side * (MirrorfoldFx.HALF + 0.5)
	walker.flee()
	walker.set_goal(grid.nearest_exit(walker.ground_pos))
	var goal := walker.goal()
	var mind := walker.mind
	var intent := walker.intent()
	fx._process(0.05)
	t.check(walker.ground_pos.is_equal_approx(a + dir * 2.0 + side * (MirrorfoldFx.HALF + 0.5)) and fx.folded == 0,
		"beside the lane, nothing happens")
	var off := dir * 3.2 - side * 0.4
	walker.ground_pos = a + off
	fx._process(0.05)
	t.check(walker.ground_pos.distance_to(b + off) < 0.75, "stepping onto the way in, it is as far along and across the way out (%s)"
		% [walker.ground_pos - b])
	t.check(walker.is_alive() and walker.mind == mind and walker.intent() == intent and walker.goal() == goal,
		"with the same mind, the same intent and the same goal")
	t.check(not walker._path.is_empty() and walker._path[0].distance_to(walker.ground_pos) < 2.0,
		"and a new path to it from where it now stands")

	t.check(stander.ground_pos == a + dir * 1.0, "one already standing there when it was laid is left alone")
	stander.ground_pos = a + dir * 1.0 + side * (MirrorfoldFx.HALF + 0.6)
	fx._process(0.05)
	stander.ground_pos = a + dir * 1.0
	fx._process(0.05)
	t.check(stander.ground_pos.distance_to(b + dir * 1.0) < 0.75, "until it steps off and back on")

	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = a + dir * 0.5
	fx._process(0.05)
	t.check(guard.ground_pos.distance_to(b + dir * 0.5) < 0.75, "a soldier is folded like anyone")

	var queued: Person = crowd.citizens[2]
	queued.queue_spot = a + Vector2(3, 3)
	queued.queue_since = 1.0
	queued.ground_pos = a + dir * 1.5
	fx._process(0.05)
	t.check(queued.ground_pos.distance_to(b + dir * 1.5) < 0.75 and queued.queue_spot == Vector2.INF,
		"one waiting in a gate's queue gives up its place there")

	var thrown: Person = crowd.citizens[6]
	thrown.ground_pos = a + dir * 3.5
	thrown.knock(Vector2(2.0, 0.0))
	fx._process(0.05)
	t.check(thrown.state == DummyEnemy.State.KNOCKBACK and thrown.ground_pos.distance_to(b + dir * 3.5) < 1.0,
		"someone thrown onto it in a tumble crosses too (%s)" % [thrown.ground_pos - b])

	var back: Person = crowd.citizens[3]
	back.ground_pos = b + dir * 2.0
	var hidden: Person = crowd.citizens[4]
	hidden.inside = true
	hidden.ground_pos = a + dir * 2.0
	fx._process(0.05)
	t.check(back.ground_pos == b + dir * 2.0, "the way out takes nobody back")
	t.check(hidden.ground_pos == a + dir * 2.0, "someone inside a building is out of its reach")
	hidden.inside = false
	t.check(fx.folded == 5, "five folded (%d)" % fx.folded)
	t.check(crowd.alarm == alarm and crowd.threats.active_count() == 0, "and nobody notices: no alarm, no danger")

	# Fire crosses: a shed burning beside the way in lights the shed beside the way out, within FIRE_EVERY.
	var shed_in := env.add_structure(Rect2(a + dir * 1.7 + side * (MirrorfoldFx.HALF + 0.3), Vector2(0.6, 0.6)), 18.0,
		Structure.Kind.HOUSE, &"house")
	var shed_out := env.add_structure(Rect2(b + dir * 1.7 + side * (MirrorfoldFx.HALF + 0.3), Vector2(0.6, 0.6)), 18.0,
		Structure.Kind.HOUSE, &"house")
	var expected := _nearest_burnable(env, crowd, b, dir, len)
	t.check(expected != null and _burning_beside(env, crowd, b, dir, len).is_empty(),
		"something that burns stands beside the way out (the shed, or a market stall nearer), none of it alight")
	fx._process(MirrorfoldFx.FIRE_EVERY)
	t.check(_burning_beside(env, crowd, b, dir, len).is_empty() and fx.fires_crossed == 0,
		"with nothing burning beside the way in, nothing is lit beside the way out")
	crowd.fires.ignite(shed_in, 0.5)
	for _step in 21:
		fx._process((MirrorfoldFx.FIRE_EVERY + 0.1) / 21.0)
	var lit := _burning_beside(env, crowd, b, dir, len)
	t.check(lit.size() == 1 and fx.fires_crossed == 1,
		"a fire beside the way in lights one thing beside the way out within FIRE_EVERY (%d lit, %d crossed)" % [lit.size(), fx.fires_crossed])
	t.check(lit.size() == 1 and lit[0] == expected, "the one that burns nearest the way out's edge")
	t.check(crowd.fires.is_burning(shed_in), "and the first still burns: fire is carried, not moved")
	t.check(shed_out != null, "(the shed beside the way out stands %s)" % ("alight" if crowd.fires.is_burning(shed_out) else "unlit, a stall being nearer"))

	fx._process(MirrorfoldFx.MIRROR_TIME)
	var after: Person = crowd.citizens[5]
	after.ground_pos = a + dir * 2.0
	t.check(fx.finished, "after %d s it is gone" % roundi(MirrorfoldFx.MIRROR_TIME))
	t.check(not field.portals.has(fx) and field.through(on_in) == on_in, "no longer a portal: a load dropped there lands there")
	fx._process(0.05)
	t.check(after.ground_pos == a + dir * 2.0, "and the ground is only ground")
	fx.free()
	t.check(field.portals.is_empty(), "freed, it leaves nothing in the portals")

	# Cut short (an act ends), it leaves the portals at once.
	var fx2: MirrorfoldFx = FxTimeline.cast(load(PATH), ctx, a, {"dir": dir, "length": len, "to": b})
	t.check(field.portals.has(fx2), "a second passage is a portal while it runs")
	fx2.end_now()
	t.check(not field.portals.has(fx2) and fx2.finished, "and cut short, it is no portal any more")
	fx2.free()
	_done(made)


## How far a structure stands from a lane's edge, the lane's middle line sampled every tenth of a unit.
static func _edge_distance(s: Structure, start: Vector2, dir: Vector2, len: float) -> float:
	var best := INF
	for i in roundi(len * 10.0) + 1:
		best = minf(best, s.distance_to(start + dir * float(i) * 0.1))
	return maxf(best - MirrorfoldFx.HALF, 0.0)


## The structure that can burn, is not burning and stands nearest a lane, within FIRE_R of its edge; null for none.
static func _nearest_burnable(env: EnvironmentField, crowd: Crowd, start: Vector2, dir: Vector2, len: float) -> Structure:
	var best: Structure = null
	var best_d := MirrorfoldFx.FIRE_R
	for s: Structure in env.structures():
		if s.destroyed or not FireManager.burns(s) or crowd.fires.is_burning(s):
			continue
		var d := _edge_distance(s, start, dir, len)
		if d < best_d:
			best_d = d
			best = s
	return best


## The structures burning within FIRE_R of a lane's edge.
static func _burning_beside(env: EnvironmentField, crowd: Crowd, start: Vector2, dir: Vector2, len: float) -> Array:
	var out := []
	for s: Structure in env.structures():
		if crowd.fires.is_burning(s) and _edge_distance(s, start, dir, len) <= MirrorfoldFx.FIRE_R:
			out.append(s)
	return out
