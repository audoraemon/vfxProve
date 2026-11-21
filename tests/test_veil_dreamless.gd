extends RefCounted
## Dreamless (Veil, Tier 3): the nearest 1 within 1.0 (light) / 4 within 2.0 (dark) sit against a wall, deep asleep, and for 20 s the
## town sees only people resting; then they are found dead (&"dreamless", a body). Anyone asleep at the sit is taken at once (&"dreamt",
## no body). Skips the gone; quiet; teardown with a control; the dusk; no crowd.

const FxStage := preload("res://tests/fx_stage.gd")


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
	crowd.dusk.enabled = true
	crowd.remains.enabled = true
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _cast(ctx: FxContext, at: Vector2, dark: bool) -> DreamlessFx:
	return FxTimeline.cast(load("res://src/fx/veil/dreamless.gd"), ctx, at, {"dark": dark}) as DreamlessFx


## A standing wall and a point 1.0 off one of its faces that is open ground (nothing within 0.3).
static func _wall(env: EnvironmentField) -> Array:
	for s in env.structures():
		if s.destroyed or s.walkable or s.footprint.size.x < 1.5 or s.footprint.size.y < 1.5:
			continue
		var c := s.footprint.get_center()
		for at: Vector2 in [Vector2(s.footprint.position.x - 1.0, c.y), Vector2(s.footprint.end.x + 1.0, c.y),
				Vector2(c.x, s.footprint.position.y - 1.0), Vector2(c.x, s.footprint.end.y + 1.0)]:
			if not env.blocked(at, 0.4) and s.distance_to(at) > 0.9 and s.distance_to(at) < 1.1:
				return [s, at]
	return []


## Everyone but `keep` goes far from the test ground.
static func _away(crowd: Crowd, keep: Array) -> void:
	var i := 0
	for p: Person in crowd.citizens + crowd.soldiers:
		if not keep.has(p) and p.is_alive():
			p.ground_pos = Vector2(-30.0 + float(i % 20) * 0.3, 30.0 + float(i / 20) * 0.3)
		i += 1


## The cast's look (Veil review), staged in the tree: the dark breath on the ground out to the reach, a thread over each sitter that
## thins with the rest left (read from the effect) and snaps when he is found or woken; all gone at end_now() and with a freed cast.
static func _looks(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var s: Person = crowd.citizens[21]
	var w: Person = crowd.citizens[22]
	_away(crowd, [s, w])
	s.ground_pos = at + Vector2(0.2, 0.0)
	s.mind = Person.Mind.CALM
	var keep := [ctx.overhead, ctx.ground]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	stage.add_child(ctx.ground)
	stage.add_child(ctx.overhead)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var fx := _cast(ctx, at, false)
	t.check(fx.breath != null and fx.breath.get_parent() == ctx.ground and is_equal_approx((fx.breath as VeilCastLooks.Wave).r, 1.0)
		and fx.threads != null and fx.threads.get_parent() == ctx.overhead, "staged: the dark breath on the ground out to the light reach (1.0); the threads overhead")
	fx._process(DreamlessFx.T_SIT + 0.05)
	t.check(fx.resting == 1 and fx.threads.up() == 1 and fx.rests(s) and absf(fx.rest_left() - (DreamlessFx.REST - 0.05)) < 0.001,
		"staged: a thread rises over the sitter; the rest left is the effect's own (%.2f)" % fx.rest_left())
	fx._process(DreamlessFx.REST)
	fx.threads._process(0.01)
	t.check(not s.is_alive() and fx.threads.up() == 0 and fx.rest_left() == 0.0, "staged: found -- his thread snaps")
	var pieces: Array = [fx.breath, fx.threads]
	fx.end_now()
	await t.process_frame
	t.check(pieces.all(func(n: Variant) -> bool: return n == null or not is_instance_valid(n)), "staged: end_now takes every piece of the look")
	# Woken by a hurt: his thread snaps too.
	_away(crowd, [w])
	w.ground_pos = at + Vector2(0.2, 0.0)
	w.mind = Person.Mind.CALM
	var fx2 := _cast(ctx, at, false)
	fx2._process(DreamlessFx.T_SIT + 0.05)
	var up := fx2.threads.up()
	w.hurt(0.01, null)
	fx2._process(0.1)
	fx2.threads._process(0.01)
	t.check(up == 1 and fx2.threads.up() == 0 and w.is_alive(), "staged: woken by a hurt, his thread snaps")
	var th2: Node = fx2.threads
	fx2.free()
	await t.process_frame
	t.check(not is_instance_valid(th2), "staged: a freed cast leaves no thread")
	crowd.dusk.clear()
	ctx.impact = null
	stub.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	stage.free()


static func run(t) -> void:
	var b := PowerBook.get_power("dreamless")
	t.check(not b.is_empty() and PowerBook.authority_of("dreamless") == "veil" and ResourceLoader.exists(String(b.path))
		and DreamlessFx.REST == 20.0 and DreamlessFx.T_SIT == 0.8, "Dreamless is a Veil power with its effect and its constants")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var kinds: Array[StringName] = []
	field.enemy_killed.connect(func(_e: DummyEnemy, kind: StringName) -> void: kinds.append(kind))

	# --- who: light the nearest 1 within 1.0; dark the nearest 4 within 2.0, by distance then instance id
	var c: Array = crowd.citizens
	var a: Person = c[0]
	var bb: Person = c[1]
	var cc: Person = c[2]
	var dd: Person = c[3]
	var ee: Person = c[4]
	var ff: Person = c[5]
	var inn: Person = c[6]
	a.ground_pos = at + Vector2(0.4, 0.0)
	bb.ground_pos = at + Vector2(0.0, 0.7)
	cc.ground_pos = at + Vector2(-1.0, 0.0)
	dd.ground_pos = at + Vector2(0.0, -1.5)
	ee.ground_pos = at + Vector2(1.9, 0.0)
	ff.ground_pos = at + Vector2(2.1, 0.0)
	inn.ground_pos = at + Vector2(0.1, 0.0)
	inn.inside = true
	for p: Person in crowd.soldiers:
		p.ground_pos = Vector2(30.0, 30.0)
	var one := DreamlessFx.victims_at(field, at, 1.0, 1)
	t.check(one.size() == 1 and one[0] == a, "light: the nearest 1 within 1.0 (%d)" % one.size())
	var four := DreamlessFx.victims_at(field, at, 2.0, 4)
	t.check(four.size() == 4 and four[0] == a and four[1] == bb and four[2] == cc and four[3] == dd and not four.has(inn),
		"dark: the nearest 4 within 2.0, nearest first, nobody inside (%d)" % four.size())
	var all5 := DreamlessFx.victims_at(field, at, 2.0, 99)
	t.check(all5.size() == 5 and all5[4] == ee and not all5.has(ff), "within 2.0 only (2.1 is out)")
	# A tie: two at one distance go by instance id.
	bb.ground_pos = at + Vector2(0.4, 0.0).rotated(PI * 0.5)
	var tie := DreamlessFx.victims_at(field, at, 1.0, 2)
	t.check(tie.size() == 2 and tie[0].get_instance_id() < tie[1].get_instance_id(), "a tie goes by instance id")
	bb.ground_pos = at + Vector2(0.0, 0.7)

	# --- an awake victim: sits, deep asleep, the status; 20 s of rest; then found dead with a body
	for p: Person in [cc, dd, ee, ff]:
		p.ground_pos = at + Vector2(40.0, 40.0)
	var alarm := crowd.alarm
	var fx := _cast(ctx, at, false)
	t.check(not a.is_asleep() and crowd.dusk.count() == 1, "at the cast: nobody sits yet; the dusk is laid")
	fx._process(DreamlessFx.T_SIT + 0.05)
	t.check(fx.resting == 1 and a.is_deep_asleep() and a.statuses.has(&"dreamless") and not bb.is_asleep(),
		"by T_SIT: the nearest sits, deep asleep, status laid; the second (light) does not (%d)" % fx.resting)
	t.check(crowd.threats.active_count() == 0 and crowd.held_count() == 0 and is_equal_approx(crowd.alarm, alarm),
		"quiet: no danger, no alarm")
	# A watcher close by sees only someone resting.
	var watcher: Person = c[7]
	watcher.ground_pos = at + Vector2(0.6, 0.6)
	watcher.mind = Person.Mind.CALM
	for k in 19:
		fx._process(1.0)
	t.check(a.is_alive() and a.is_deep_asleep() and watcher.mind == Person.Mind.CALM and is_equal_approx(crowd.alarm, alarm)
		and crowd.threats.active_count() == 0 and kinds.is_empty(), "for 19 s: he rests; no witness reacts; alarm unchanged")
	var rem0 := crowd.remains.all().size()
	fx._process(1.0)
	t.check(not a.is_alive() and kinds == [&"dreamless"] and crowd.remains.all().size() == rem0 + 1,
		"at T_SIT + 20: dies with kind dreamless and leaves a remain (%s)" % str(kinds))
	t.check(Rules.POWER_KINDS["dreamless"].has(&"dreamless"), "credited to the caster's power")
	fx._process(3.0)
	t.check(fx.finished and not a.statuses.has(&"dreamless"), "the effect finishes; no status left")
	fx.free()
	crowd.dusk.clear()
	crowd.threats.clear()

	# --- already asleep at T_SIT: taken at once, dreamt, no remain, alarm unchanged
	kinds.clear()
	var sleeper: Person = c[8]
	var owner: Person = c[9]
	sleeper.ground_pos = at + Vector2(0.3, 0.0)
	owner.ground_pos = at + Vector2(0.0, 0.5)
	var fx2 := _cast(ctx, at, true)
	var vics := fx2._victims.size()
	sleeper.sleep(30.0, false)
	owner.statuses[&"shadow"] = 1.0
	var rem1 := crowd.remains.all().size()
	alarm = crowd.alarm
	fx2._process(DreamlessFx.T_SIT + 0.05)
	t.check(vics >= 2 and not sleeper.is_alive() and not owner.is_alive() and fx2.taken == 2 and kinds == [&"dreamt", &"dreamt"],
		"asleep at T_SIT and a shadow's owner: taken at once, dreamt (%d, %s)" % [fx2.taken, str(kinds)])
	t.check(crowd.remains.all().size() == rem1 and is_equal_approx(crowd.alarm, alarm), "no remain, alarm unchanged")
	fx2.free()
	crowd.dusk.clear()
	kinds.clear()

	# --- dies or goes indoors before T_SIT: skipped, no error
	var gone: Person = c[10]
	var home: Person = c[11]
	var stay: Person = c[12]
	gone.ground_pos = at + Vector2(0.2, 0.0)
	home.ground_pos = at + Vector2(0.0, 0.3)
	stay.ground_pos = at + Vector2(0.3, 0.3)
	_away(crowd, [gone, home, stay])
	var fx3 := _cast(ctx, at, true)
	field.kill(gone, &"doom")
	home.inside = true
	kinds.clear()
	fx3._process(DreamlessFx.T_SIT + 0.05)
	t.check(fx3.resting >= 1 and stay.is_deep_asleep() and not home.is_asleep() and kinds.is_empty(),
		"a victim dead or indoors before T_SIT is skipped (%d)" % fx3.resting)
	fx3.end_now()
	fx3.free()
	home.inside = false
	crowd.dusk.clear()

	# --- the wall: he walks at most 2.0 to the nearest wall and sits against it
	var wall := _wall(env)
	if wall.is_empty():
		t.check(false, "a wall to sit against was found in the town")
	else:
		var s: Structure = wall[0]
		var w: Person = c[13]
		w.ground_pos = wall[1]
		var fx4 := _cast(ctx, wall[1], false)
		fx4._process(DreamlessFx.T_SIT + 0.05)
		var off := INF
		for n in env.near(w.ground_pos, 1.0):
			if not n.walkable and not n.destroyed:
				off = minf(off, n.distance_to(w.ground_pos))
		t.check(w.is_deep_asleep() and off < 0.45 and w.ground_pos.distance_to(wall[1]) <= 2.0 and s.distance_to(wall[1]) < 1.1,
			"he sits against the nearest wall (%.2f off it)" % off)
		fx4.end_now()
		fx4.free()
		w.wake()
	crowd.dusk.clear()

	# --- dark: four at once, then found
	kinds.clear()
	var dark_four: Array[Person] = []
	_away(crowd, [c[14], c[15], c[16], c[17]])
	for i in 4:
		var p: Person = c[14 + i]
		p.ground_pos = at + Vector2(0.3 * float(i + 1), 0.0)
		p.mind = Person.Mind.CALM
		dark_four.append(p)
	var fx5 := _cast(ctx, at, true)
	fx5._process(DreamlessFx.T_SIT + 0.05)
	t.check(fx5.resting == 4 and dark_four.all(func(p: Person) -> bool: return p.is_deep_asleep()), "dark: four sit deep asleep (%d)" % fx5.resting)
	fx5._process(DreamlessFx.REST + 0.05)
	t.check(dark_four.all(func(p: Person) -> bool: return not p.is_alive()) and kinds.size() == 4, "dark: all four found dead")
	fx5.free()
	crowd.dusk.clear()

	# --- teardown: ended before the 20 s nobody dies, the status is lifted, the sleep ends; control: left to run they die
	kinds.clear()
	var u: Person = c[18]
	var v: Person = c[19]
	u.ground_pos = at + Vector2(0.2, 0.0)
	v.ground_pos = at + Vector2(0.0, 0.2)
	u.mind = Person.Mind.CALM
	v.mind = Person.Mind.CALM
	var cut := _cast(ctx, at, false)
	cut._process(DreamlessFx.T_SIT + 0.05)
	var sat: Person = u if u.is_deep_asleep() else v
	t.check(sat.is_deep_asleep() and sat.statuses.has(&"dreamless"), "teardown setup: one sits")
	cut._process(8.0)
	cut.end_now()
	t.check(cut.finished and not sat.statuses.has(&"dreamless") and not sat.is_asleep() and sat.is_alive(),
		"end_now: the status is lifted and the sleep ends")
	cut.free()
	t.check(sat.is_alive() and kinds.is_empty(), "teardown: nobody dies (%s)" % str(kinds))
	# Leaving the tree does the same.
	var tree_made := _cast(ctx, at, false)
	tree_made._process(DreamlessFx.T_SIT + 0.05)
	var sat2: Person = u if u.is_deep_asleep() else v
	var holds := sat2.statuses.has(&"dreamless")
	tree_made._exit_tree()
	t.check(holds and not sat2.statuses.has(&"dreamless") and not sat2.is_asleep(), "leaving the tree lifts it too")
	tree_made.free()
	t.check(not is_instance_valid(tree_made), "and the node is freed")
	crowd.dusk.clear()
	var ctl := _cast(ctx, at, false)
	ctl._process(DreamlessFx.T_SIT + 0.05)
	var sat3: Person = u if u.is_deep_asleep() else v
	ctl._process(DreamlessFx.REST + 0.05)
	t.check(not sat3.is_alive() and kinds == [&"dreamless"], "control: left to run, he dies (%s)" % str(kinds))
	ctl.free()
	crowd.dusk.clear()

	# --- woken by a hurt, then put into deep sleep again (a dark Slumber): no longer marked for the find, he lives (VB1)
	kinds.clear()
	var wk: Person = c[20]
	_away(crowd, [wk])
	wk.ground_pos = at + Vector2(0.2, 0.0)
	wk.mind = Person.Mind.CALM
	var fx6 := _cast(ctx, at, false)
	fx6._process(DreamlessFx.T_SIT + 0.05)
	t.check(wk.is_deep_asleep() and wk.statuses.has(&"dreamless"), "(he sits, marked)")
	wk.hurt(0.01, null)
	fx6._process(0.1)
	t.check(not wk.is_asleep() and not wk.statuses.has(&"dreamless"), "woken by a hurt: the status is gone with the sleep")
	wk.sleep(30.0, true)  # a dark Slumber's deep sleep
	fx6._process(DreamlessFx.REST)
	t.check(wk.is_alive() and kinds.is_empty() and not wk.statuses.has(&"dreamless"),
		"a later deep sleep is a plain sleep: the find does not kill him (%s)" % str(kinds))
	fx6.free()
	wk.wake()
	crowd.dusk.clear()
	await _looks(t, made, at)
	_done(made)

	# --- quiet, dusk laid, no crowd: builds and finishes
	var bare_env := EnvironmentField.new()
	var bare := FxContext.new()
	bare.env = bare_env
	bare.field = EnemyField.new()
	bare.field.env = bare_env
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var nb := _cast(bare, Vector2.ZERO, false)
	nb._process(DreamlessFx.T_SIT + 0.05)
	nb._process(DreamlessFx.REST + 2.0)
	t.check(nb.finished and nb.resting == 0, "no crowd: builds and finishes")
	nb.free()
	var nd := _cast(bare, Vector2.ZERO, true)
	nd.end_now()
	nd.free()
	t.check(true, "no crowd, dark: ends clean")
	bare.overhead.free()
	bare.ground.free()
