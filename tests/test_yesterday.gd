extends RefCounted
## Yesterday's Door: a district steps back ten seconds. Everyone alive in the circle at the cast is put back where they
## stood ten seconds before it and, where it is theirs, doing what they did then; dazed a moment, they carry on from
## there. The dead stay dead, those outside the circle are untouched, those inside a building (then or now) are left,
## and a hold the god or the town has on someone is kept. The town's memory (TimeTrail) keeps only those ten seconds,
## and keeping it changes nothing.

const FX := "res://src/fx/control/yesterdays_door.gd"
## One frame of the tests' clock.
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


## The town's memory runs `seconds` on (people stand where they are put: nobody is stepped).
static func _age(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / DT):
		crowd.trail.step(DT, crowd.citizens, crowd.soldiers)


static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		fx._process(DT)


## Stand `p` at `at`, calm (a soldier at his post there), going nowhere.
static func _stand(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.anchor = at
	p.mind = Person.Mind.POST if p.soldier else Person.Mind.CALM
	if p.soldier:
		p.post = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.inside = false


static func _near(a: Vector2, b: Vector2, within := 0.05) -> bool:
	return a.distance_to(b) <= within


static func run(t) -> void:
	var b := PowerBook.get_power("yesterday")
	var area: Dictionary = Targeting.AREAS.get("yesterday", {})
	t.check(int(b.dp) == 4 and PowerBook.is_quiet("yesterday") and String(b.aim) == "click"
		and is_equal_approx(float(b.get("alarm", 0.0)), 1.0) and PowerBook.authority_of("yesterday") == "passage"
		and PowerBook.icon("yesterday") != null and PowerBook.hud_icon("yesterday") != null and PowerBook.clip("yesterday") != null
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), YesterdaysDoorFx.RADIUS)
		and Rules.POWER_KINDS.get("yesterday", null) == [] and PowerBook.family("yesterday") == "passage",
		"Yesterday's Door is Passage's 4 DP, quiet (alarm 1.0), a click on a circle of RADIUS, killing nothing, with icons, clip and a family")
	t.check(is_equal_approx(YesterdaysDoorFx.BACK, TimeTrail.KEEP) and is_equal_approx(YesterdaysDoorFx.KEEP_EVERY, TimeTrail.EVERY)
		and float(TimeTrail.SLOTS - 1) * TimeTrail.EVERY >= TimeTrail.KEEP,
		"the town remembers exactly BACK seconds, writing everyone down every KEEP_EVERY")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		_stand(person, Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3))
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var spot := func(off: Vector2) -> Vector2: return grid.nearest_walkable(at + off)

	# --- Recording changes nothing: one write of the whole town leaves every person and every random stream as it was.
	var before := []
	for p in crowd.citizens + crowd.soldiers:
		before.append([p.ground_pos, p.mind, p.rng.state, p._goal, p._target, p.anchor])
	var town_rng: int = crowd._rng.state
	crowd.trail.record(crowd.citizens, crowd.soldiers)
	var same := crowd._rng.state == town_rng
	var k := 0
	for p in crowd.citizens + crowd.soldiers:
		same = same and before[k] == [p.ground_pos, p.mind, p.rng.state, p._goal, p._target, p.anchor]
		k += 1
	t.check(same and crowd.trail.size() == crowd.citizens.size() + crowd.soldiers.size(),
		"writing the town down moves nobody, changes no mind and draws no random number; everyone living is remembered")
	crowd.trail.clear()

	# --- The scene, ten seconds before the cast.
	var walker: Person = crowd.citizens[0]
	var runner: Person = crowd.citizens[1]
	var held: Person = crowd.citizens[2]
	var dead: Person = crowd.citizens[3]
	var outsider: Person = crowd.citizens[4]
	var indoors: Person = crowd.citizens[5]
	var guard: Person = crowd.soldiers[0]
	var a0: Vector2 = spot.call(Vector2(-2.0, 0.0))
	var f0: Vector2 = spot.call(Vector2(1.0, -2.0))
	var w0: Vector2 = spot.call(Vector2(-1.0, 2.0))
	var d0: Vector2 = spot.call(Vector2(0.5, 0.5))
	var o0: Vector2 = spot.call(Vector2(0.0, 9.0))
	var j0: Vector2 = spot.call(Vector2(2.5, 1.0))
	var s0: Vector2 = spot.call(Vector2(-3.5, -2.0))
	_stand(walker, a0)
	_stand(runner, f0)
	_stand(held, w0)
	_stand(dead, d0)
	_stand(outsider, o0)
	_stand(indoors, j0)
	_stand(guard, s0)
	indoors.inside = true
	_age(crowd, 6.0)

	# --- Six seconds in: the town moves on.
	dead.die(&"stone")
	var a1: Vector2 = spot.call(Vector2(-2.0, 2.5))
	walker.ground_pos = a1
	var f1: Vector2 = spot.call(Vector2(3.5, -2.5))
	runner.flee()
	runner.ground_pos = f1
	var post: Vector2 = spot.call(Vector2(4.0, 3.0))
	guard.send_to_post(post, false, true)
	var s1: Vector2 = s0.lerp(post, 0.6)
	guard.ground_pos = grid.nearest_walkable(s1)
	guard.set_goal(post)
	var w1: Vector2 = spot.call(Vector2(-3.0, 3.0))
	held.compel(w1, 60.0, Person.WILL_FIRM, Color.GOLD)
	held.ground_pos = w1
	var o1: Vector2 = spot.call(Vector2(1.5, 9.5))
	outsider.ground_pos = o1
	var j1: Vector2 = spot.call(Vector2(2.5, 2.0))
	indoors.inside = false
	indoors.ground_pos = j1
	var n0: Vector2 = spot.call(Vector2(1.0, 3.5))
	var newcomer := crowd.add_soldier(n0)
	newcomer._goal = Vector2.INF
	_age(crowd, 4.0)
	var n1: Vector2 = spot.call(Vector2(-1.0, -3.0))
	newcomer.ground_pos = n1
	_age(crowd, 4.0)

	# --- The recorder keeps only BACK seconds.
	var span := crowd.trail.span(walker)
	t.check(span >= TimeTrail.KEEP - TimeTrail.EVERY and span <= TimeTrail.KEEP + 0.01,
		"the town's memory of a person reaches BACK seconds back and no further (%.2f s after 14 s)" % span)
	var oldest := crowd.trail.back(walker, 30.0)
	var ten := crowd.trail.back(walker, YesterdaysDoorFx.BACK)
	t.check(float(oldest.get("age", 99.0)) <= TimeTrail.KEEP + 0.01
		and absf(float(ten.get("age", 99.0)) - YesterdaysDoorFx.BACK) <= TimeTrail.EVERY * 0.5 + 0.01
		and _near(ten.get("pos", Vector2.INF), a0),
		"asked for thirty seconds ago it has only its oldest, BACK ago; BACK ago it has where she stood then")
	t.check(crowd.trail.back(dead, YesterdaysDoorFx.BACK).is_empty() and crowd.trail.size() == crowd.citizens.size() + crowd.soldiers.size() - 1,
		"the dead are forgotten at the next writing")
	var late := crowd.trail.back(newcomer, YesterdaysDoorFx.BACK)
	t.check(_near(late.get("pos", Vector2.INF), n0) and absf(float(late.get("age", 0.0)) - 8.0) <= TimeTrail.EVERY,
		"one who came into the town 8 s ago is remembered from when he came (%.2f s)" % float(late.get("age", 0.0)))

	# --- The cast.
	var threats := crowd.threats.active_count()
	var fx: YesterdaysDoorFx = FxTimeline.cast(load(FX), ctx, at)
	t.check(is_equal_approx(fx.busy, YesterdaysDoorFx.T_TURN) and fx.duration >= YesterdaysDoorFx.T_TURN + YesterdaysDoorFx.DAZE,
		"the cast is busy until the door turns, and lasts past the daze")
	t.check(walker in fx.chosen and runner in fx.chosen and guard in fx.chosen and held in fx.chosen and indoors in fx.chosen
		and newcomer in fx.chosen and not outsider in fx.chosen and not dead in fx.chosen,
		"everyone alive within RADIUS at the cast is taken; the dead and those outside the circle are not")
	_run(fx, YesterdaysDoorFx.T_TURN - 0.1)
	t.check(_near(walker.ground_pos, a1) and runner.mind == Person.Mind.FLEE and fx.stepped.is_empty(),
		"nothing moves until the door turns, T_TURN after the cast")
	_run(fx, 0.15)
	t.check(_near(walker.ground_pos, a0) and walker.mind == Person.Mind.CALM,
		"T_TURN after the cast, a calm walker is back where she stood BACK seconds ago, calm")
	t.check(_near(runner.ground_pos, f0) and runner.mind == Person.Mind.CALM and not runner.is_running() and not runner.has_goal(),
		"a citizen who had fled since is calm again where he stood, going nowhere")
	t.check(_near(guard.ground_pos, s0) and guard.mind == Person.Mind.POST and guard.goal() == post and guard.anchor == post,
		"a soldier who was walking to a new post is back where he set out from, his orders unchanged")
	t.check(_near(held.ground_pos, w0) and held.mind == Person.Mind.COMPELLED and held.goal() == w1,
		"a compelled citizen keeps the god's hold (it is its owner's to end): only her body steps back, and she walks on to it")
	t.check(not dead.is_alive() and _near(dead.ground_pos, d0), "the dead stay dead, where they fell")
	t.check(_near(outsider.ground_pos, o1), "someone outside the circle is untouched")
	t.check(_near(indoors.ground_pos, j1) and not indoors in fx.stepped,
		"someone who was inside a building BACK seconds ago is left where he is now")
	t.check(_near(newcomer.ground_pos, n0), "one who came into the town since goes back to the first moment it remembers him")
	t.check(crowd.threats.active_count() == threats and runner.mind != Person.Mind.PANIC and walker.mind != Person.Mind.PANIC,
		"quiet: the door raises no danger and frightens nobody")

	# --- Dazed DAZE, then free.
	t.check(guard.wait >= YesterdaysDoorFx.DAZE - 0.2, "each one turned back stands dazed (%.2f s)" % guard.wait)
	for n in roundi((YesterdaysDoorFx.DAZE - 0.25) / DT):
		guard.tick(DT)
	t.check(_near(guard.ground_pos, s0), "dazed, the soldier does not move")
	var gap := guard.ground_pos.distance_to(post)
	for n in roundi(2.0 / DT):
		guard.tick(DT)
	t.check(guard.ground_pos.distance_to(post) < gap - 0.5 and guard.mind == Person.Mind.POST,
		"after the daze he walks to his post again (%.2f nearer)" % (gap - guard.ground_pos.distance_to(post)))

	# --- The rule on its own (Person.rewind()).
	var was := crowd.trail.back(walker, 0.0)
	t.check(not walker.rewind({}) and not dead.rewind(was), "nothing to go back to, or dead: nobody is turned back")
	walker.inside = true
	t.check(not walker.rewind(was), "one inside a building now is left where he is")
	walker.inside = false
	was["inside"] = true
	t.check(not walker.rewind(was), "one inside a building then is left where he is")
	was["inside"] = false
	walker.freeze(3.0)
	t.check(not walker.rewind(was), "one frozen in ice is left where he is")

	# --- The crowd keeps its memory in its own frame, and not while time stands still.
	var records := crowd.trail.records
	crowd.advance(TimeTrail.EVERY + 0.01)
	var stepped := crowd.trail.records
	crowd.freeze(5.0)
	crowd.advance(TimeTrail.EVERY * 3.0)
	t.check(stepped > records and crowd.trail.records == stepped,
		"the crowd writes the town down as its clock runs, and not while time stands still")
	_done(made)
