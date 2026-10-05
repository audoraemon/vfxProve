extends RefCounted
## v0.10 Mira's House (MirasHouseDirector): ten grieving near her door, Halcyon's Faithful about the town; a grieving
## citizen whispered or lured to the door goes in, reads for 10 s and comes out a Believer; a Faithful who sees someone
## go in turns them away and reports, one who sees a Believer come out reports; a report delivered, a seen death or the
## bell fills the Gaze; five Believers out at dawn win.

const DT := 0.05


static func _setup() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var def := MissionBook.miras_house()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as MirasHouseDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## Every Faithful moved well away from `at` (nobody of the Faith can see there).
static func _blind(d: MirasHouseDirector, at: Vector2) -> void:
	for f in d.faithful:
		if is_instance_valid(f) and f.ground_pos.distance_to(at) <= MirasHouseDirector.SIGHT + 1.0:
			f.ground_pos = at + Vector2(MirasHouseDirector.SIGHT + 8.0, 0.0)


## Grieving `g` whispered to the door and standing there.
static func _bring(d: MirasHouseDirector, g: Person) -> void:
	g.whisper(d.door, 8.0)
	_arrive(g, d.door)


static func run(t) -> void:
	_cast(t)
	_reading(t)
	_seen(t)
	_gaze(t)
	_ending(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	t.check(d.house != null and d.house.kind == Structure.Kind.HOUSE and d.door != Vector2.INF
		and d.door.distance_to(d.house.center()) < 3.0, "Mira's house is a west-quarter house with a door")
	t.check(d.grieving.size() == MirasHouseDirector.GRIEVING and d.gaze != null and d.gaze.value == 0.0,
		"ten grieving, and the Gaze at 0")
	var faithful_ok := d.faithful.size() >= MirasHouseDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL and not d.grieving.has(f)
	t.check(faithful_ok, "at least twenty Faithful, none of them grieving (%d)" % d.faithful.size())
	t.check(d.venn != null and d.faithful.has(d.venn), "the Inquisitor is one of the Faithful")
	t.check(d.marks().size() == MirasHouseDirector.GRIEVING, "the HUD marks the ten grieving")
	t.check(d.timeline != null, "the night keeps a timeline for its windows")
	_done(s)


static func _reading(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var g := d.grieving[0]
	_blind(d, d.door)
	_bring(d, g)
	_run(s, DT * 2.0)
	t.check(g.inside and not g.visible and d.inside().has(g), "a whispered grieving citizen at the door goes in")
	_run(s, MirasHouseDirector.READ_SECONDS - 1.0)
	t.check(g.inside and d.believers.is_empty(), "still reading after 9 s")
	_blind(d, d.door)
	_run(s, 1.5)
	t.check(not g.inside and g.visible and d.believers.has(g) and g.profile.faith == CitizenProfile.Faith.BELIEVER
		and d.journal == g and d.believers_outside() == 1, "after 10 s they come out a Believer, carrying the journal")
	t.check(d.reports.is_empty(), "nobody of the Faith saw")
	var marked_believer := false
	for m: Array in d.marks():
		marked_believer = marked_believer or ((m[0] as Vector2) == g.ground_pos and (m[1] as Color) == MirasHouseDirector.MARK_BELIEVER)
	t.check(marked_believer, "the Believer wears the ember mark")

	# Review focus 5: a grieving citizen walking past on their own day does not go in.
	var h := d.grieving[1]
	_blind(d, d.door)
	_arrive(h, d.door)
	h.mind = Person.Mind.CALM
	_run(s, DT * 2.0)
	t.check(not h.inside and d.reports.is_empty(), "a grieving citizen passing the door on their own day stays out")
	_done(s)


static func _seen(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var g := d.grieving[0]
	_blind(d, d.door)
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.0, 0.0)
	_bring(d, g)
	_run(s, DT * 2.0)
	t.check(not g.inside and d.reports.size() == 1 and d.reports[0].carrier == f,
		"a Faithful who sees someone go in turns them away and runs to report")
	_run(s, 1.0)
	t.check(not g.inside and d.reports.size() == 1, "the turned-away reader does not slip in while still at the door")

	# A Faithful held by Discord sees nothing.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var g2 := d2.grieving[0]
	_blind(d2, d2.door)
	var f2 := d2.faithful[0]
	f2.ground_pos = d2.door + Vector2(2.0, 0.0)
	f2.confuse(10.0)
	_bring(d2, g2)
	_run(s2, DT * 2.0)
	t.check(g2.inside and d2.reports.is_empty(), "a Faithful confused by Discord sees nothing")
	# Seen coming out.
	_run(s2, MirasHouseDirector.READ_SECONDS - 0.5)
	var f3 := d2.faithful[1]
	f3.ground_pos = d2.door + Vector2(-2.0, 0.0)
	_run(s2, 1.0)
	t.check(d2.believers.has(g2) and d2.reports.size() == 1, "a Believer seen coming out is reported, but believes")
	_done(s)
	_done(s2)


static func _gaze(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.0, 0.0)
	_bring(d, d.grieving[0])
	_run(s, DT * 2.0)
	t.check(d.reports.size() == 1, "a report is on its way")
	_arrive(d.reports[0].carrier, d.temple_door)
	_run(s, DT * 3.0)
	t.check(d.gaze.is_full() and rules.finished and not rules.won and rules.over_reason == "gaze",
		"a report reaching the Temple fills the Gaze, and the night is lost (%s)" % rules.over_reason)
	_done(s)

	# A seen death adds 10.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var victim := d2.faithful[3]
	var near := d2.faithful[4]
	near.ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s2.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s2, DT * 3.0)
	t.near(d2.gaze.value, GazeMeter.SEEN_DEATH, 0.001, "a seen death adds 10 to the Gaze")
	_done(s2)

	# Review focus 4: the bell, rung by the town's own alarm, fills it.
	var s3 := _setup()
	var d3: MirasHouseDirector = s3.d
	var crowd3: Crowd = s3.crowd
	if crowd3.bell != null:
		crowd3.bell.state = BellNetwork.State.RUNG
	_run(s3, DT * 2.0)
	t.check(crowd3.bell == null or ((s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "gaze"),
		"the bell filling the Gaze loses the night")
	_done(s3)


static func _ending(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	for i in BelieversObjective.NEED:
		var g := d.grieving[i]
		g.profile.faith = CitizenProfile.Faith.BELIEVER
		d.believers.append(g)
	d.journal = d.grieving[0]
	rules.time_left = DT
	_run(s, DT * 2.0)
	t.check(rules.finished and rules.won and rules.over_reason == "believers", "five Believers out at dawn win the night")
	var res := rules.result()
	t.check(int(res.get("believers", -1)) == 5, "the results count them")
	var earned := []
	for b: Dictionary in res.bonuses:
		earned.append(bool(b.earned))
	t.check(earned == [true, true], "no death and the journal out: both bonuses (%s)" % [earned])
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	for i in BelieversObjective.NEED - 1:
		d2.believers.append(d2.grieving[i])
	(s2.rules as Rules).time_left = DT
	_run(s2, DT * 2.0)
	t.check((s2.rules as Rules).finished and not (s2.rules as Rules).won and (s2.rules as Rules).over_reason == "few",
		"four at dawn lose it")
	_done(s2)
