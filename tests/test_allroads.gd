extends RefCounted
## All Roads Lead Here (Passage, Tier IV): for SPAN seconds every road in a district of RADIUS ends at the click. The
## MAX_PEOPLE nearest keep their own minds, but every route they plan leads there (Person.bend_roads()). Quiet: nobody is
## compelled or frightened by it.

const DT := 0.05


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
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## Everyone parked out of the way, far from any click (they are not stepped).
static func _park(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p.queue_spot = Vector2.INF
		i += 1


## A calm one standing at `at`, its street there, no errand pending for a long while.
static func _calm(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.anchor = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.stay_left = 999.0


## Steps `who` (only them), the crowd's gates and clock, and the effect, `seconds` in DT ticks.
static func _step(who: Array[Person], crowd: Crowd, fx: FxTimeline, seconds: float) -> void:
	for k in roundi(seconds / DT):
		for p in who:
			if is_instance_valid(p) and p.is_alive() and not p.inside:
				p.tick(DT)
		crowd.advance(DT)
		if is_instance_valid(fx) and not fx.finished:
			fx._process(DT)


static func run(t) -> void:
	var b := PowerBook.get_power("allroads")
	var area: Dictionary = Targeting.AREAS.get("allroads", {})
	t.check(int(b.dp) == 4 and PowerBook.is_quiet("allroads") and String(b.aim) == "click"
		and PowerBook.authority_of("allroads") == "passage" and PowerBook.icon("allroads") != null
		and PowerBook.hud_icon("allroads") != null and PowerBook.clip("allroads") != null and area.get("shape", "") == "circle"
		and is_equal_approx(float(area.get("r", 0.0)), AllRoadsLeadHereFx.RADIUS)
		and Rules.POWER_KINDS.get("allroads", null) == [&"gone"] and PowerBook.family("allroads") == "passage",
		"All Roads Lead Here is Passage's 4 DP, quiet, a click on a circle of RADIUS, it kills nobody, with icons, clip and a family")

	_selection(t)
	_behaviour(t)


## Who is caught: the MAX_PEOPLE nearest within RADIUS, soldiers too; minds untouched.
static func _selection(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_park(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# Nothing for a power never cast: nobody's roads are bent, and a route leads to its own goal.
	var anyone_bent := false
	for p in crowd.citizens + crowd.soldiers:
		anyone_bent = anyone_bent or p.roads_bent()
	var plain: Person = crowd.citizens[0]
	_calm(plain, grid.nearest_walkable(at + Vector2(-2.0, 0.0)))
	var own := grid.nearest_walkable(at + Vector2(2.0, 2.0))
	plain.set_goal(own)
	t.check(not anyone_bent and plain.bent_to() == Vector2.INF and not plain._path.is_empty()
		and plain._path[plain._path.size() - 1].distance_to(own) < 0.6,
		"before any cast nobody's roads are bent, and a route leads to its own goal")
	plain._goal = Vector2.INF
	plain._path = PackedVector2Array()

	# 90 people round the click at growing distances (every tenth a soldier), one more just outside the district.
	var near: Array[Person] = []
	var ci := 0
	var si := 0
	while near.size() < 90 and (ci < crowd.citizens.size() or si < crowd.soldiers.size()):
		var p: Person
		if near.size() % 10 == 5 and si < crowd.soldiers.size():
			p = crowd.soldiers[si]
			si += 1
		elif ci < crowd.citizens.size():
			p = crowd.citizens[ci]
			ci += 1
		else:
			p = crowd.soldiers[si]
			si += 1
		var j := near.size()
		p.ground_pos = at + Vector2.RIGHT.rotated(float(j) * 2.39996) * (1.0 + 0.09 * float(j))
		near.append(p)
	var outside: Person = crowd.citizens[ci] if ci < crowd.citizens.size() else null
	if outside != null:
		outside.ground_pos = at + Vector2(0.0, AllRoadsLeadHereFx.RADIUS + 1.0)
	var minds := {}
	for p in near:
		minds[p] = p.mind
	var alarm := crowd.alarm
	var fx: AllRoadsLeadHereFx = FxTimeline.cast(load("res://src/fx/control/all_roads_lead_here.gd"), ctx, at)
	t.check(near.size() == 90 and fx.caught.size() == AllRoadsLeadHereFx.MAX_PEOPLE,
		"a crowded district: MAX_PEOPLE are caught (%d of %d)" % [fx.caught.size(), near.size()])
	var first_bent := true
	var rest_free := true
	var soldiers_caught := 0
	for j in near.size():
		var p := near[j]
		if j < AllRoadsLeadHereFx.MAX_PEOPLE:
			first_bent = first_bent and p.roads_bent() and p.bent_to() == fx.spot and fx.caught.has(p)
			soldiers_caught += 1 if p.soldier else 0
		else:
			rest_free = rest_free and not p.roads_bent()
	t.check(first_bent and rest_free, "the caught are the nearest MAX_PEOPLE to the click; the farther ten are not")
	t.check(soldiers_caught >= 7, "soldiers are caught as citizens are (%d)" % soldiers_caught)
	t.check(outside == null or not outside.roads_bent(), "one standing just outside the district is not caught")
	var same := true
	for p in near:
		same = same and p.mind == minds[p] and p.mind != Person.Mind.COMPELLED and p.mind != Person.Mind.PANIC \
			and p.compel_will == 0.0
	t.check(same and is_equal_approx(crowd.alarm, alarm),
		"every caught mind is unchanged: none compelled, none frightened, no alarm from the cast itself")
	t.check(fx.spot.distance_to(at) < 0.01 and is_equal_approx(fx.busy, AllRoadsLeadHereFx.T_BEND)
		and fx.duration >= AllRoadsLeadHereFx.SPAN,
		"the roads lead to the click itself; the cast is busy for T_BEND and lasts SPAN")
	fx.end_now()
	var any_left := false
	for p in near:
		any_left = any_left or p.roads_bent()
	t.check(not any_left and fx.caught.is_empty(), "cut short, it lets everyone go")
	_done(made)


## What the caught do: they go about their own business, and every road brings them to the click.
static func _behaviour(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_park(crowd)
	var at := grid.nearest_walkable(Vector2(2.7, 6.5))

	# A calm citizen in its street, five steps off.
	var calm: Person = crowd.citizens[0]
	_calm(calm, grid.nearest_walkable(at + Vector2(-5.0, 0.0)))
	var calm_home := calm.anchor
	# A soldier on his way back to his post on the far side.
	var guard: Person = null
	for s in crowd.soldiers:
		if guard == null and s.corps == Person.Corps.NONE:
			guard = s  # a plain guard: no corps manager sends him elsewhere
	var post := grid.nearest_walkable(at + Vector2(0.0, -5.0))
	guard.send_to_post(post)
	guard.ground_pos = grid.nearest_walkable(at + Vector2(-3.0, -3.0))
	guard.set_goal(post)
	# One told to flee the town.
	var runner: Person = crowd.citizens[1]
	_calm(runner, grid.nearest_walkable(at + Vector2(4.0, -2.0)))
	runner.flee()
	# One frightened by a danger beside it.
	var fright: Person = crowd.citizens[2]
	_calm(fright, grid.nearest_walkable(at + Vector2(3.0, 2.0)))
	# One waiting in a jammed gate's crowd.
	var gate: Structure = null
	for g in crowd._town.gates:
		if g.footprint.intersects(TownLayout.MAIN_GATE):
			gate = g
	gate.blighted = true
	var spots := crowd.queue_spots(gate)
	var queued: Person = crowd.citizens[3]
	_calm(queued, spots[2])
	queued.flee()
	queued.set_goal(grid.nearest_exit(queued.ground_pos))
	crowd.advance(DT)
	var was_queued := queued.queue_spot != Vector2.INF
	# One inside a building, walking somewhere when it went in.
	var indoors: Person = crowd.citizens[4]
	_calm(indoors, grid.nearest_walkable(at + Vector2(-2.0, 3.0)))
	indoors.set_goal(calm_home)
	indoors.inside = true
	var indoor_path := indoors._path
	# One who will die while caught, where nobody sees it.
	var doomed: Person = crowd.citizens[5]
	_calm(doomed, grid.nearest_walkable(at + Vector2(2.0, -6.0)))
	crowd.veil(doomed.ground_pos, 1.5, 999.0)
	var who: Array[Person] = [calm, guard, runner, fright, queued, doomed]

	var fx: AllRoadsLeadHereFx = FxTimeline.cast(load("res://src/fx/control/all_roads_lead_here.gd"), ctx, at)
	var spot := fx.spot
	t.check(was_queued and queued.queue_spot == Vector2.INF and queued.roads_bent() and queued.mind == Person.Mind.FLEE,
		"one waiting in a gate's crowd is let out of it: its way out leads here")
	t.check(guard.roads_bent() and guard.goal() == post and not guard._path.is_empty()
		and guard._path[guard._path.size() - 1].distance_to(spot) < 0.6,
		"a soldier on his way to his post still means to go there, but his route leads to the click")
	t.check(indoors.roads_bent() and indoors._path == indoor_path, "one inside is caught, but nothing changes until it comes out")
	fright.panic(fright.ground_pos + Vector2(0.4, 0.4), 1.0)

	_step(who, crowd, fx, 14.0)
	t.check(queued.queue_spot == Vector2.INF and queued.ground_pos.distance_to(spot) < 2.5,
		"the one from the gate stays out of its crowd and comes to the click (%.2f away)" % queued.ground_pos.distance_to(spot))
	t.check(runner.mind == Person.Mind.FLEE and crowd.citizens.has(runner) and runner.ground_pos.distance_to(spot) < 2.5,
		"one told to flee still flees, and its way out ends at the click (%.2f away)" % runner.ground_pos.distance_to(spot))
	t.check(fright.ground_pos.distance_to(spot) < 2.5,
		"one frightened runs from the danger, and runs to the click (%.2f away)" % fright.ground_pos.distance_to(spot))
	t.check(guard.ground_pos.distance_to(spot) < 2.0 and guard.anchor == post,
		"the soldier walks to his post and arrives at the click instead (%.2f away)" % guard.ground_pos.distance_to(spot))

	# There: they notice, plan again, and the road brings them back. The calm mill about the click.
	var calm_far := 0.0
	var guard_far := 0.0
	var guard_planned := false
	for k in 8:
		_step(who, crowd, fx, 1.0)
		calm_far = maxf(calm_far, calm.ground_pos.distance_to(spot))
		guard_far = maxf(guard_far, guard.ground_pos.distance_to(spot))
		guard_planned = guard_planned or guard.goal() == post
	t.check(calm.mind == Person.Mind.CALM and calm.anchor == calm_home and calm_far <= AllRoadsLeadHereFx.GATHER_R + 0.5,
		"the calm one, its own street unchanged, mills about the click within GATHER_R (at most %.2f away)" % calm_far)
	t.check(guard_planned and guard_far < 2.0 and guard.mind == Person.Mind.POST,
		"the soldier plans for his post again and again, and every route keeps him at the click (at most %.2f away)" % guard_far)

	# Coming out while it lasts: caught.
	indoors.inside = false
	indoors.set_goal(calm_home)
	t.check(indoors._path.size() > 0 and indoors._path[indoors._path.size() - 1].distance_to(spot) < 0.6,
		"one coming out of a building while it lasts is caught: its first route leads to the click")

	# A caught one who dies is let go.
	field.kill(doomed, &"stone")
	_step(who, crowd, fx, DT)
	t.check(not doomed.roads_bent() and not fx.caught.has(doomed), "one who dies while caught is let go at once")

	# The end: everyone's roads run true, and each goes about its own business again.
	_step(who, crowd, fx, AllRoadsLeadHereFx.SPAN - fx.t + 0.1)
	var still := false
	for p in who + [indoors]:
		still = still or (is_instance_valid(p) and p.roads_bent())
	t.check(not still and fx.caught.is_empty(), "when the span ends everyone's roads run true again")
	_step(who, crowd, fx, 16.0)
	t.check(guard.ground_pos.distance_to(post) < 1.0,
		"the soldier goes back to his own post (%.2f from it)" % guard.ground_pos.distance_to(post))
	t.check(calm.ground_pos.distance_to(calm_home) < 1.5,
		"the calm one goes back to its own street (%.2f from it)" % calm.ground_pos.distance_to(calm_home))
	var runner_gone := not crowd.citizens.has(runner) or runner.ground_pos.distance_to(spot) > 4.0
	t.check(runner_gone, "the one fleeing makes for the gate again")
	_done(made)
