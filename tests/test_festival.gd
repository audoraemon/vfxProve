extends RefCounted
## v0.09 Act II-A (FestivalDirector): FESTIVAL_CROWD citizens fill the market square and stay, the Mayor is among the
## merchants (not the goers), the festival counts the dead and the broken, soldiers watch the square if the bell rang,
## and the Mayor and the Prince's noble have looks on both art paths.

const DT := 0.1
const R := CitizenProfile.Role


## A town spawned Unaware and the Festival's Rules for `night`, with no director yet (see _start()).
static func _setup(night: NightState) -> Dictionary:
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
	var def := MissionBook.long_night().act("festival")
	def.night = night
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "def": def}


## The Festival's director, set up as Mission does it.
static func _start(s: Dictionary, night: NightState) -> FestivalDirector:
	var def: ActDef = s.def
	var d := (def.director.new() as MissionDirector).setup(s.rules, s.crowd, s.town, null, night) as FestivalDirector
	(s.rules as Rules).director = d
	s["d"] = d
	return d


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


## `seconds` of the act, in the game's order: the crowd, then the rules (which step the director).
static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func run(t) -> void:
	_crowd_and_mayor(t)
	_counting(t)
	_guards(t)
	_looks(t)


## Eighty goers, none of them a responder or the Mayor, each staying and walking to a spot in the square.
static func _crowd_and_mayor(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var crowd: Crowd = s.crowd
	t.check(MissionBook.long_night().act("festival").director == FestivalDirector, "the Festival act's director is FestivalDirector")
	t.check(d.goers.size() == FestivalDirector.FESTIVAL_CROWD, "%d goers (%d)" % [FestivalDirector.FESTIVAL_CROWD, d.goers.size()])
	var clean := true
	var stays := true
	var placed := true
	var square := TownLayout.MARKET_SQUARE.grow(0.5)
	for p in d.goers:
		clean = clean and not p.profile.role in FestivalDirector.SKIP_ROLES and p != d.mayor
		stays = stays and p.stay_left > 100.0
		placed = placed and square.has_point(p.goal())
	t.check(clean, "no goer is the bellkeeper, the watchman, clergy, an engineer or the Mayor")
	t.check(stays and placed, "each stays on (stay_left > 100) and walks to a spot inside the square")
	t.check(d.mayor != null and d.mayor.profile.role == R.MAYOR and not d.goers.has(d.mayor),
		"the Mayor is a MAYOR and not a goer")
	var mayors := 0
	for p in crowd.citizens:
		if p.profile != null and p.profile.role == R.MAYOR:
			mayors += 1
	t.check(mayors == 1, "and there is one of him (%d)" % mayors)
	_run(s, 1.0)
	t.check(d.count() == 0 and not d.broken(), "a quiet square has lost nobody (%d)" % d.count())
	t.check(d.report().festival == "held" and d.timeline != null, "the report says held; the timeline exists")
	_done(s)


## The count is the dead plus the broken: panic and kill.
static func _counting(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var field: EnemyField = s.field
	var panicked: Array[Person] = []
	for p in d.goers.slice(0, 10):
		p.panic(p.ground_pos, 1.0)
		panicked.append(p)
	d._sample_in = 0.0
	d.step(0.0)
	var broke := 0
	for p in panicked:
		if p.mind in FestivalDirector.BROKE_MINDS:
			broke += 1
	t.check(broke == 10 and d.count() == 10 and d.broke_list().size() == 10,
		"panicking 10 goers breaks them, sampled: count() == 10 (%d broke, count %d)" % [broke, d.count()])
	var killed := 0
	for p in d.goers.slice(10, 15):
		if field.kill(p, &"fire"):
			killed += 1
	t.check(killed == 5 and d.count() == 15, "5 more killed: count() == 15 (killed %d, count %d)" % [killed, d.count()])
	t.check(d.broke_list().size() == 10 and not d.broken(), "the dead are not on the broke list; 15 < need")
	var n := NightState.new()
	d.carry(n)
	t.check(n.festival_broke.size() == 10, "carry hands Act III the 10 who broke and still live")
	d.need = 15
	t.check(d.broken() and d.report().festival == "broken" and d.report().festival_count == 15,
		"at the need the festival is broken")
	_done(s)


## The bell rang in Act I: GUARDS soldiers with no role post in the square. Otherwise none do.
static func _guards(t) -> void:
	var square := TownLayout.MARKET_SQUARE
	for rang in [false, true]:
		var n := NightState.new()
		n.bell_rang = rang
		var s := _setup(n)
		var crowd: Crowd = s.crowd
		var before := 0
		for p in crowd.soldiers:
			if square.has_point(p.anchor):
				before += 1
		_start(s, n)
		var at := 0
		for p in crowd.soldiers:
			if square.has_point(p.anchor):
				at += 1
		if rang:
			t.check(at - before == FestivalDirector.GUARDS,
				"the bell rang: %d soldiers post in the square (%d -> %d)" % [FestivalDirector.GUARDS, before, at])
		else:
			t.check(at == before, "the bell did not ring: nobody is posted (%d -> %d)" % [before, at])
		_done(s)


## The Mayor and the noble: a stand-in design each on the sprites, a chain and a crown over it, and a coat of their
## own on the procedural body.
static func _looks(t) -> void:
	t.check(PeopleArt.wanted(false, R.MAYOR, 0, 0.5) == "mayor" and PeopleArt.wanted(false, R.NOBLE, 0, 0.5) == "noble",
		"both have a design of their own to come")
	t.check(PeopleArt.design_for(false, R.MAYOR, 0, 0.0) == "merchant_a"
		and PeopleArt.design_for(false, R.NOBLE, 0, 0.9) == "resident_a",
		"until then the Mayor wears a merchant and the noble a resident")
	t.check(PeopleArt.CITIZEN.size() == R.size(), "PeopleArt.CITIZEN has an entry for every role")
	var w := RoutineManager.WEIGHTS
	t.check(w[R.MAYOR] == [0.3, 0.6, 0.1, 0.0] and w[R.NOBLE] == [0.9, 0.0, 0.1, 0.0], "both have routine weights")
	t.check(int(R.WATCHMAN) == 9 and int(R.MAYOR) == 10 and int(R.NOBLE) == 11, "the new roles are appended")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var made: Array[Person] = []
	for k in 3:
		var p := Person.new()
		p.rng.seed = 31 + k
		p.bounds = TownLayout.MAP
		p.setup_person(false, Vector2(2.7, 2.0), grid)
		made.append(p)
	var plain := made[0]
	var m := made[1]
	var nb := made[2]
	var pm := CitizenProfile.new()
	pm.role = R.MAYOR
	m.profile = pm
	var pn := CitizenProfile.new()
	pn.role = R.NOBLE
	nb.profile = pn
	t.check(m._is_mayor() and not m._is_noble() and nb._is_noble() and not nb._is_mayor() and not plain._is_mayor(),
		"only the Mayor wears the chain, only the noble the crown")
	for sprites in [true, false]:
		SpriteArt.set_enabled(sprites)
		t.check(typeof(m._art_signature()) == TYPE_INT and typeof(nb._art_signature()) == TYPE_INT,
			"both have a signature (sprites %s)" % sprites)
	SpriteArt.set_enabled(true)
	t.check(m._design() == "merchant_a" and nb._design() == "resident_a" and PeopleArt.has(m._design())
		and PeopleArt.has(nb._design()),
		"a Mayor and a noble in the town draw the stand-ins the atlas has (%s, %s)" % [m._design(), nb._design()])
	for p in made:
		p.free()
