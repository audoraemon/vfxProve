extends RefCounted
## v0.11 M2 First Prayers (spec §4, FirstPrayersDirector on MirasHouseDirector): the old well shrine -- a drawn shrine post at
## the market's west edge, which a blow only shakes (review focus 4) -- and the eight poor of the south-west quarter. A poor
## citizen whispered to its door goes down to pray, hidden, PRAY_SECONDS, one at a time, and comes out a Believer; three out
## win. Few Faithful (three clergy, three lay, no Inquisitor); the market fills at MARKET_AT and the priests come at PRIESTS_AT,
## Faithful at the door each time, none of them a wait over a minute. Mira's House keeps its own numbers.

const DT := 0.05


static func run(t) -> void:
	_setup(t)
	_pray(t)
	_win(t)
	_market(t)
	_priests(t)
	_freed(t)
	_waits(t)
	_miras_same(t)
	_mission(t)


static func _world() -> Dictionary:
	var def := MissionBook.first_prayers()
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director := def.make_director().setup(rules, crowd, town, null) as FirstPrayersDirector
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


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


## Every Faithful within sight of the shrine's door moved well away (as test_miras_house's _blind()).
static func _blind(d: MirasHouseDirector) -> void:
	for f in d.faithful:
		if is_instance_valid(f) and f.ground_pos.distance_to(d.door) <= MirasHouseDirector.SIGHT + 1.0:
			f.ground_pos = d.door + Vector2(MirasHouseDirector.SIGHT + 8.0, 0.0)


## One of the poor whispered to the shrine's door.
static func _bring(d: MirasHouseDirector, g: Person) -> void:
	g.mind = Person.Mind.WHISPERED
	_arrive(g, d.door)


static func _labels(d: MissionDirector) -> Array:
	var out := []
	for m in d.tags():
		if m.label != "":
			out.append(m.label)
	return out


static func _setup(t) -> void:
	var s := _world()
	var d: FirstPrayersDirector = s.d
	var shrine := d.house
	t.check(shrine != null and shrine.kind == Structure.Kind.SHRINE and shrine.role == FirstPrayersDirector.ROLE
		and shrine.center().distance_to(FirstPrayersDirector.SHRINE_AT) <= 2.5, "the old well shrine: a shrine post by the market")
	var hp := shrine.hp
	shrine.damage(500.0, shrine.center(), &"fire")
	t.check(not shrine.destroyed and is_equal_approx(shrine.hp, hp), "a blow only shakes it (review focus 4)")
	var poor_ok := d.grieving.size() == FirstPrayersDirector.POOR
	for g in d.grieving:
		poor_ok = poor_ok and g.profile.faith == CitizenProfile.Faith.GRIEVING and g.ground_pos.distance_to(FirstPrayersDirector.POOR_SPOT) < 12.0
	t.check(poor_ok, "the eight poor, from the south-west quarter")
	var clergy := 0
	for f in d.faithful:
		clergy += 1 if f.profile.role == CitizenProfile.Role.CLERGY else 0
	t.check(d.venn == null and clergy <= FirstPrayersDirector.FAITHFUL_CLERGY
		and d.faithful.size() <= FirstPrayersDirector.FAITHFUL_CLERGY + FirstPrayersDirector.FAITHFUL_LAY and d.faithful.size() >= 3,
		"few Faithful (%d, %d of them clergy), and no Inquisitor" % [d.faithful.size(), clergy])
	t.check(d.need == FirstPrayersDirector.NEED and is_equal_approx(d.read_seconds, FirstPrayersDirector.PRAY_SECONDS) and d.one_at_a_time,
		"three must pray, PRAY_SECONDS (%.0f) each, one at a time" % [FirstPrayersDirector.PRAY_SECONDS])
	var at := []
	for e in d.timeline.upcoming(2):
		at.append(float(e.at))
	t.check(at == [FirstPrayersDirector.MARKET_AT, FirstPrayersDirector.PRIESTS_AT], "the market at MARKET_AT, the priests at PRIESTS_AT (%s)" % [at])
	_blind(d)
	t.check(_labels(d) == ["OLD WELL SHRINE", "DOOR - CLEAR"] and d.hint_phase() == "",
		"tagged: the shrine and its clear door (%s)" % [_labels(d)])
	var stops := d.tour()
	t.check(stops.size() == 3 and String(stops[0][1]) == "The old well shrine, by the market. Lead the poor here."
		and String(stops[2][1]) == "The Temple. A Faithful who sees you runs here.", "the tour: the shrine, the poor, the Temple")
	t.check((s.banners as Array).has("LEAD THE POOR TO THE OLD WELL"), "its opening banner")
	_done(s)


static func _pray(t) -> void:
	var s := _world()
	var d: FirstPrayersDirector = s.d
	_blind(d)
	var a: Person = d.grieving[0]
	var b: Person = d.grieving[1]
	_bring(d, a)
	_run(s, DT * 2.0)
	t.check(a.inside and d.inside().size() == 1, "whispered to the door, one goes down to pray")
	_bring(d, b)
	_run(s, DT * 2.0)
	t.check(not b.inside and d.inside().size() == 1, "the next waits at the door: one at a time")
	_run(s, FirstPrayersDirector.PRAY_SECONDS - 1.0)
	t.check(a.inside and not d.believers.has(a), "a prayer takes PRAY_SECONDS")
	_run(s, 1.5)
	t.check(not a.inside and d.believers.has(a) and a.profile.faith == CitizenProfile.Faith.BELIEVER and b.inside,
		"out a Believer, and the next goes in")
	_done(s)


static func _win(t) -> void:
	var s := _world()
	var d: FirstPrayersDirector = s.d
	var rules: Rules = s.rules
	for i in FirstPrayersDirector.NEED - 1:
		var g := d.grieving[i]
		g.profile.faith = CitizenProfile.Faith.BELIEVER
		d.believers.append(g)
	_run(s, DT * 2.0)
	t.check(not rules.finished and rules.objectives[1].hud_text(rules) == "Believers 2 / 3", "two Believers out: the night goes on")
	var third := d.grieving[FirstPrayersDirector.NEED - 1]
	third.profile.faith = CitizenProfile.Faith.BELIEVER
	d.believers.append(third)
	_run(s, DT * 2.0)
	t.check(rules.finished and rules.won and rules.over_reason == "believers" and rules.time_left > 200.0,
		"the third Believer out wins at once")
	_done(s)


static func _market(t) -> void:
	var s := _world()
	var d: FirstPrayersDirector = s.d
	_blind(d)
	_run(s, FirstPrayersDirector.MARKET_AT + DT * 2.0)
	var ok := not d.liners.is_empty() and d.liners.size() <= MirasHouseDirector.LINE_SPOTS.size()
	for f in d.liners:
		ok = ok and f.mind == Person.Mind.DUTY and f.anchor.distance_to(d.door) <= MirasHouseDirector.SIGHT
		_arrive(f, f.anchor)
	t.check(ok and (s.banners as Array).has("THE MARKET FILLS"), "MARKET_AT: the market fills, Faithful stand by the shrine's door")
	t.check(d.hint_phase() == "watched" and _labels(d).has("DOOR - WATCHED"), "the door is watched")
	_run(s, FirstPrayersDirector.MARKET_SECONDS + 1.0)
	t.check(d.liners.is_empty(), "MARKET_SECONDS later they go about their day")
	_done(s)


static func _priests(t) -> void:
	var s := _world()
	var d: FirstPrayersDirector = s.d
	_run(s, FirstPrayersDirector.PRIESTS_AT + DT * 2.0)
	var ok := d.liners.size() <= FirstPrayersDirector.PRIEST_SPOTS.size()
	for f in d.liners:
		ok = ok and f.profile.role == CitizenProfile.Role.CLERGY and f.mind == Person.Mind.DUTY
	t.check(ok and (s.banners as Array).has("THE PRIESTS COME TO THE WELL"), "PRIESTS_AT: the priests come to the well")
	_done(s)


## The bodies of a poor citizen, a Believer and a Faithful freed after their death fade (the freed-bodies lesson): the director
## steps and tags, hints, tours and reports without touching them.
static func _freed(t) -> void:
	var s := _world()
	var d: FirstPrayersDirector = s.d
	var crowd: Crowd = s.crowd
	_blind(d)
	var poor: Variant = d.grieving[0]
	var believer: Variant = d.grieving[1]
	(believer as Person).profile.faith = CitizenProfile.Faith.BELIEVER
	d.believers.append(believer)
	var watcher: Variant = d.faithful[0]
	for body: Variant in [poor, believer, watcher]:
		crowd._field.kill(body, &"fire")
		crowd._field.remove(body)
		crowd.citizens.erase(body)
		body.free()
	d.step(DT)
	d.step(DT)
	var labels := _labels(d)
	t.check(d.believers_outside() == 0 and d.hint_phase() == "" and labels == ["OLD WELL SHRINE", "DOOR - CLEAR"]
		and d.tour().size() == 3 and int(d.report().believers) == 0 and d.inside().is_empty(),
		"a poor one's, a Believer's and a Faithful's bodies freed: nothing touched, nothing tagged (%s)" % [labels])
	var next: Person = d.grieving[2]
	_bring(d, next)
	_run(s, DT * 2.0)
	t.check(next.inside, "and the next of the poor still goes in")
	_done(s)


## Every wait of the night is a minute or less (the no-waiting rule, spec section 0).
static func _waits(t) -> void:
	t.check(FirstPrayersDirector.PRAY_SECONDS <= 60.0 and FirstPrayersDirector.MARKET_SECONDS <= 60.0
		and FirstPrayersDirector.PRIESTS_SECONDS <= 60.0,
		"no wait over a minute: a prayer %.0f s, the market %.0f s, the priests %.0f s" % [FirstPrayersDirector.PRAY_SECONDS,
			FirstPrayersDirector.MARKET_SECONDS, FirstPrayersDirector.PRIESTS_SECONDS])


static func _miras_same(t) -> void:
	var m := MirasHouseDirector.new()
	t.check(m.need == BelieversObjective.NEED and m.need == 4 and is_equal_approx(m.read_seconds, MirasHouseDirector.READ_SECONDS)
		and not m.one_at_a_time and m._opening_banner() == "LEAD THE GRIEVING TO MIRA'S HOUSE",
		"Mira's House keeps its own numbers: four, 8 s, all at once")


static func _mission(t) -> void:
	var m := MissionBook.first_prayers()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.id == "first_prayers" and m.tier == 1 and m.director == FirstPrayersDirector and is_equal_approx(m.clock, 300.0)
		and m.profile == "unaware" and reasons == ["gaze", "believers"] and m.bonuses().is_empty(),
		"First Prayers: Tier 1's numbers, its director; the Gaze, three believe (%s)" % [reasons])
	t.check(MissionBook.get_mission("first_prayers").id == "first_prayers", "found by id")
