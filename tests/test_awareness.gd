extends RefCounted
## v0.11.2 awareness (spec §3): a loud power's danger counts from its first impact (PowerBook.IMPACT) -- at the cast the town
## only looks at the build-up -- and a frightened person freezes 0.4-0.8 s (Person.STARTLE, a hash of their own seed) before
## running. Directors that judge a cast as danger read Crowd.danger_landed.

const DT := 0.05
## Each loud power's impact and the effect-script constant(s) it is read from (spec §3.2).
const FROM := {
	"smite": ["T_STRIKE"], "heaven": ["T_STRIKE"], "tornado": ["T_FORM"], "dragon": ["T_ERUPT"], "tsunami": ["T_SWEEP"],
	"gravity": ["T_PULL"], "laser": ["T_WALK"], "orbital": ["T_SALVO_START", "AIM_TIME"], "cinder": ["T_RISE"],
	"judgement": ["T_RISE"], "glacial": ["T_ERUPT"], "solaris": ["T_CHARGE"], "schism": ["T_BREAK"], "nova": ["T_IMPACT"],
}


static func run(t) -> void:
	_table(t)
	_held(t)
	_smite_lands(t)
	_held_dies_with_act(t)
	_startle(t)
	_startle_deterministic(t)
	_directors(t)
	_unkeyed(t)


static func _world() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / DT):
		crowd.advance(DT)
		for p in crowd.citizens + crowd.soldiers:
			if is_instance_valid(p):
				p.tick(DT)


## A calm citizen standing at `at`, with no task of his own.
static func _calm(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


static func _table(t) -> void:
	for key in PowerBook.keys():
		t.check(PowerBook.IMPACT.has(key) != PowerBook.is_quiet(key), "%s: an impact iff it is loud" % key)
	t.check(PowerBook.impact("doom") == 0.0 and PowerBook.impact("") == 0.0 and PowerBook.impact("smite") == 0.35,
		"impact(): 0.0 for any other key")
	for key: String in FROM:
		var c: Dictionary = (load(String(PowerBook.get_power(key).path)) as GDScript).get_script_constant_map()
		var want := 0.0
		for name: String in FROM[key]:
			want += float(c.get(name, 99.0))
		t.check(is_equal_approx(float(PowerBook.IMPACT[key]), want), "%s: impact %.2f = its script's %s (%.2f)" % [key, PowerBook.IMPACT[key], FROM[key], want])
	t.check(PowerBook.IMPACT.size() == FROM.size(), "fourteen loud powers")


## v0.11.2: at the cast a Smite is a build-up: nobody is frightened, the people who see it look; at the impact the danger is
## registered and those it reaches run -- the same people as always.
static func _held(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var at := Vector2(0.8, 2.0)
	var p: Person = crowd.citizens[0]
	var q: Person = crowd.citizens[1]
	var far: Person = crowd.citizens[2]
	_calm(p, at)
	_calm(q, at + Vector2(4.0, 0.0))  # inside Smite's sight (5.0), outside its radius
	_calm(far, at + Vector2(0.0, 30.0))
	var landed := []
	crowd.danger_landed.connect(func(key: String, points: Array[Vector2]) -> void: landed.append([key, points]))
	crowd.on_cast(at, Vector2.ZERO, 0.0, "smite")
	t.check(crowd.threats.active_count() == 0 and p.mind == Person.Mind.OBSERVE and q.mind == Person.Mind.OBSERVE
		and far.mind == Person.Mind.CALM and crowd.held_count() == 1 and landed.is_empty(),
		"v0.11.2: at the cast no danger, the build-up is looked at (%s %s)" % [Person.Mind.keys()[p.mind], Person.Mind.keys()[q.mind]])
	_run(crowd, PowerBook.impact("smite") - 0.1)
	t.check(crowd.threats.active_count() == 0 and landed.is_empty(), "and nothing lands before the impact")
	_run(crowd, 0.2)
	t.check(crowd.threats.active_count() > 0 and p.mind == Person.Mind.PANIC and crowd.held_count() == 0 and landed.size() == 1
		and landed[0][0] == "smite" and (landed[0][1] as Array).size() == 1,
		"v0.11.2: at the impact, the danger and the fright, and danger_landed once")
	t.check(q.mind != Person.Mind.PANIC, "one outside the radius only looks")
	# A lane power: the held danger keeps every point of the lane.
	var dir := Vector2(1.0, 0.0)
	crowd.on_cast(at + Vector2(0.0, 10.0), dir, float(Targeting.AREAS.heaven.length), "heaven")
	t.check(crowd.held_count() == 1, "a Heaven Splitter is held as one danger")
	_run(crowd, PowerBook.impact("heaven") + 0.1)
	t.check(landed.size() == 2 and (landed[1][1] as Array).size() > 2, "which lands with all its lane points (%d)" % (landed[1][1] as Array).size())
	# A quiet power is held for nothing.
	crowd.on_cast(at, Vector2.ZERO, 0.0, "doom")
	t.check(crowd.held_count() == 0, "a quiet power holds nothing")
	_done(s)


## The user's report, closed: a Smite on a calm citizen who stands there kills him -- he looks up, he does not run clear first.
static func _smite_lands(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at: Vector2 = (s.grid as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	_calm(a, at + Vector2(0.2, 0.0))
	var smite: SmiteFx = FxTimeline.cast(load("res://src/fx/ruin/smite.gd"), ctx, at)
	crowd.on_cast(at, Vector2.ZERO, 0.0, "smite")  # as Targeting does
	for k in 10:
		crowd.advance(DT)
		a.tick(DT)
		smite._process(DT)
	t.check(not a.is_alive() and smite.struck >= 1, "v0.11.2: a Smite on a calm citizen standing there kills him (struck %d)" % smite.struck)
	smite._process(3.0)
	smite.free()
	ctx.overhead.free()
	ctx.ground.free()
	_done(s)


## Review focus 1: a Heaven cast 0.2 s before its act ends frightens no one in the next. clear() drops held dangers, and so does
## drop_held() (Mission.next_act(): the crowd outlives an act).
static func _held_dies_with_act(t) -> void:
	for how in ["clear", "drop_held"]:
		var s := _world()
		var crowd: Crowd = s.crowd
		var at := Vector2(0.8, 2.0)
		var p: Person = crowd.citizens[0]
		_calm(p, at)
		crowd.on_cast(at, Vector2.ZERO, 0.0, "heaven")
		_run(crowd, 0.2)
		t.check(crowd.held_count() == 1 and p.mind == Person.Mind.OBSERVE, "%s: a Heaven cast is held at 0.2 s" % how)
		if how == "clear":
			crowd.clear()
			t.check(crowd.held_count() == 0, "clear() drops the held danger")
			crowd.spawn()
			crowd.citizens[0].ground_pos = at
		else:
			crowd.drop_held()
			t.check(crowd.held_count() == 0, "drop_held() drops it")
		_run(crowd, 2.0)
		var panicked := 0
		for c in crowd.citizens:
			panicked += 1 if c.mind == Person.Mind.PANIC else 0
		t.check(panicked == 0 and crowd.threats.active_count() == 0, "%s: nobody is frightened by it later (%d)" % [how, panicked])
		_done(s)


static func _startle(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var p: Person = crowd.citizens[0]
	var at := Vector2(0.8, 2.0)
	_calm(p, at)
	var wait := p.startle_seconds()
	t.check(wait >= Person.STARTLE.x and wait <= Person.STARTLE.y, "startle_seconds() is in [0.4, 0.8] (%.2f)" % wait)
	p.panic(at + Vector2(0.5, 0.0), 1.0)
	t.check(p.mind == Person.Mind.PANIC and p.startled(), "v0.11.2: frightened, he is startled")
	var start := p.ground_pos
	var ticks := int((wait - 0.1) / DT)
	var still := true
	for i in ticks:
		p.tick(DT)
		still = still and p.ground_pos == start
	t.check(still, "and stands still for the startle (%d ticks, moved %.2f)" % [ticks, p.ground_pos.distance_to(start)])
	for i in int(0.6 / DT):
		p.tick(DT)
	t.check(not p.startled() and p.ground_pos.distance_to(start) > 0.1, "then runs (moved %.2f)" % p.ground_pos.distance_to(start))
	# Frightened again while running: no new freeze.
	p.panic(p.ground_pos + Vector2(0.5, 0.0), 1.0)
	t.check(not p.startled(), "a second fright while already in flight does not freeze him again")
	# A soldier freezes too.
	var sol: Person = crowd.soldiers[0]
	sol.ground_pos = at + Vector2(10.0, 0.0)
	sol.mind = Person.Mind.POST
	sol.panic(sol.ground_pos + Vector2(0.5, 0.0), 1.0)
	t.check(sol.mind == Person.Mind.PANIC and sol.startled() and sol.startle_seconds() >= Person.STARTLE.x,
		"soldiers freeze as citizens do")
	_done(s)


## Review focus 2: the startle reads rng.seed and draws nothing.
static func _startle_deterministic(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var p: Person = crowd.citizens[0]
	var state := p.rng.state
	var a := p.startle_seconds()
	var b := p.startle_seconds()
	t.check(a == b and p.rng.state == state, "startle_seconds() is the same twice and draws nothing")
	# The same fright with and without the startle (one already in PANIC takes none) draws the same numbers.
	var q: Person = crowd.citizens[1]
	for who in [p, q]:
		_calm(who, Vector2(0.8, 2.0))
		who.rng.seed = 12345
		who.shelters = null  # a sturdy building nearby would take him in
	q.mind = Person.Mind.PANIC
	p.panic(Vector2(1.3, 2.0), 1.0)
	q.panic(Vector2(1.3, 2.0), 1.0)
	t.check(p.startled() and not q.startled() and p.rng.state == q.rng.state, "panic()'s startle shifts no random stream")
	var lo := INF
	var hi := -INF
	for k in 50:
		p.rng.seed = 1000 + k * 7
		var x := p.startle_seconds()
		lo = minf(lo, x)
		hi = maxf(hi, x)
	t.check(hi - lo > 0.2, "across 50 people the values spread (%.2f-%.2f)" % [lo, hi])
	_done(s)


## The directors that judge a loud cast as danger read the impact: a Tax Collector's quarry is alarmed, a Festival goer broken,
## only when it lands.
static func _directors(t) -> void:
	var tc = load("res://tests/test_tax_collector.gd")
	var s: Dictionary = tc._world(PackedStringArray(["smite", "doom", "discord"]))
	var d: TaxCollectorDirector = s.d
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	d._set_out(q)
	tc._run(s, DT)
	var at: Vector2 = q.target.ground_pos
	crowd.on_cast(at, Vector2.ZERO, 0.0, "smite")
	d._on_cast(0, "smite", at)
	tc._run(s, DT)
	t.check(q.state == AssassinateDirector.State.WALKING and q.alarms == 0, "v0.11.2: a loud cast at a walking collector's feet does not alarm him at the cast")
	tc._run(s, PowerBook.impact("smite") + 0.1)
	t.check(q.alarms == 1 and q.state == AssassinateDirector.State.FLEEING, "but at its impact he is alarmed")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "doom")
	tc._run(s, 1.0)
	t.check(q.alarms == 1, "a quiet cast never alarms")
	d.teardown()
	t.check(not crowd.danger_landed.is_connected(d._on_danger), "teardown lets go of the crowd's dangers")
	tc._done(s)

	# The smoke-out at the hideout door stays at the cast.
	s = tc._world()
	d = s.d
	tc._run(s, 10.0)
	d._on_cast(0, "whisper", d.hide_door + Vector2(TaxCollectorDirector.ALARM_REACH - 0.5, 0.0))
	t.check(d.quarries[0].state == AssassinateDirector.State.WALKING, "the smoke-out at the door still sets out at the cast")
	tc._done(s)

	# The Festival: a goer in a Heaven lane is broken only after the impact.
	var fe = load("res://tests/test_festival.gd")
	var fs: Dictionary = fe._setup(NightState.new())
	var fd: FestivalDirector = fe._start(fs, null)
	var fcrowd: Crowd = fs.crowd
	fd.need = 1000
	var goer: Person = fd.goers[0]
	var spot := TownLayout.FOUNTAIN.get_center()
	goer.ground_pos = spot
	fcrowd.on_cast(spot, Vector2.ZERO, 0.0, "heaven")
	fe._run(fs, 0.5)
	t.check(fd.broke_list().is_empty() or not fd.broke_list().has(goer), "v0.11.2: a goer in a Heaven lane is not broken at the cast")
	fe._run(fs, PowerBook.impact("heaven"))
	fd._sample_in = 0.0
	fd.step(0.0)
	t.check(fd._broke.has(goer) or fd.broke_list().has(goer), "but at its impact he is")
	fd.teardown()
	t.check(not fcrowd.danger_landed.is_connected(fd._on_danger), "and teardown lets go of the crowd's dangers")
	fe._done(fs)


## A key with no impact (a scripted test's "", the sandbox, crowd_check) lands at once, as it always did.
static func _unkeyed(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var p: Person = crowd.citizens[0]
	_calm(p, Vector2(0.8, 2.0))
	var landed := []
	crowd.danger_landed.connect(func(key: String, _points: Array[Vector2]) -> void: landed.append(key))
	crowd.on_cast(Vector2(0.8, 2.0))
	t.check(p.mind == Person.Mind.PANIC and crowd.held_count() == 0 and landed == [""], "an unkeyed cast frightens at once")
	_done(s)
