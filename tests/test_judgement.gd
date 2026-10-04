extends RefCounted
## v0.09 Act III (JudgementDirector): the night's carry-overs at its start -- a broken festival's crowd fleeing into
## gates it jams, marshals already at the gates, a rallied or a leaderless Citadel, the Prince's escape cutting the
## escape limit to 40 -- and its windows: the clergy gather at 1:30 (a Prepared town), the boats sail at 2:00, the last
## ferry leaves at 2:30. The Dawn bonus falls once the clock is under 30 s.

const DT := 0.1


## A town spawned at `tier` and Act III's Rules for `night`, with no director yet (see _start()).
static func _setup(night: NightState, tier := ResponseProfile.Tier.PREPARED) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	var def := MissionBook.long_night().act("judgement")
	def.night = night
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "def": def,
		"banners": banners}


## Act III's director, set up as Mission does it.
static func _start(s: Dictionary, night: NightState) -> MissionDirector:
	var def: ActDef = s.def
	var d := (def.director.new() as MissionDirector).setup(s.rules, s.crowd, s.town, null, night)
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


static func _main_gate(town: Town) -> Structure:
	for g in town.gates:
		if g.footprint == TownLayout.MAIN_GATE:
			return g
	return null


static func _ids(d: MissionDirector) -> Array:
	var out := []
	for e in d.timeline.upcoming(9):
		out.append(String(e.id))
	return out


static func run(t) -> void:
	_broken(t)
	_held(t)
	_prince(t)
	_events(t)
	_close(t)
	_organized(t)
	_cathedral_gone(t)
	_dawn(t)
	_bare(t)
	_hud(t)


static func _broken(t) -> void:
	var night := NightState.new()
	night.festival = "broken"
	var s := _setup(night)
	var crowd: Crowd = s.crowd
	var gate := _main_gate(s.town)
	# Five festival-goers who broke, one of them dead by the time the act begins.
	for k in 5:
		night.festival_broke.append(crowd.citizens[40 + k])
	var dead: Person = night.festival_broke[4]
	dead.state = DummyEnemy.State.DEAD
	_start(s, night)
	var fleeing := 0
	for k in 4:
		if (night.festival_broke[k] as Person).mind == Person.Mind.FLEE:
			fleeing += 1
	t.check(fleeing == 4 and dead.mind != Person.Mind.FLEE, "a broken festival's living flee when the act begins (%d of 4)" % fleeing)
	# They jam the Main Gate: keep them at its mouth and nobody passes for 39 s, then somebody does.
	var spots := crowd.queue_spots(gate)
	var passing := 0
	for i in roundi(39.0 / DT):
		for k in 4:
			var p: Person = night.festival_broke[k]
			p.mind = Person.Mind.FLEE
			p.ground_pos = spots[k]
		crowd.advance(DT)
		for p in crowd.citizens:
			if is_instance_valid(p) and p.passing_gate == gate:
				passing += 1
	t.check(passing == 0, "the Main Gate lets nobody out for 39 s (%d passing)" % passing)
	for i in roundi(3.0 / DT):
		crowd.advance(DT)
		for p in crowd.citizens:
			if is_instance_valid(p) and p.passing_gate == gate:
				passing += 1
	t.check(passing > 0, "and then it does (%d)" % passing)
	_done(s)


static func _held(t) -> void:
	var night := NightState.new()
	night.festival = "held"
	var s := _setup(night, ResponseProfile.Tier.ORGANIZED)
	_start(s, night)
	t.check((s.crowd as Crowd).marshals.active, "a held festival: the marshals hold the gates from the start")
	_done(s)
	s = _setup(NightState.new(), ResponseProfile.Tier.ORGANIZED)
	_start(s, s.def.night)
	t.check(not (s.crowd as Crowd).marshals.active, "with no festival they wait for the alarm")
	_done(s)


static func _prince(t) -> void:
	var night := NightState.new()
	night.prince = "escaped"
	var s := _setup(night)
	_start(s, night)
	var crowd: Crowd = s.crowd
	var ringed := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			ringed += 1
	t.check(crowd._rallied and ringed > 0, "the Prince escaped: the Citadel is rallied, soldiers walk to the ring (%d)" % ringed)
	var limit := -1
	for o in (s.rules as Rules).objectives:
		if o is EscapeLimitObjective:
			limit = (o as EscapeLimitObjective).limit
	t.check(limit == 40, "and Act III's escape limit is 40 (%d)" % limit)
	_done(s)

	night = NightState.new()
	night.prince = "unseen"
	s = _setup(night)
	_start(s, night)
	crowd = s.crowd
	var rallied := []
	crowd.rallied.connect(func() -> void: rallied.append(true))
	crowd.rally()
	ringed = 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			ringed += 1
	t.check(crowd._rallied and ringed == 0 and rallied.is_empty(), "the Prince unseen: a City Emergency rallies nobody (%d)" % ringed)
	_done(s)

	night = NightState.new()
	night.prince = "seen"
	s = _setup(night)
	_start(s, night)
	t.check(not (s.crowd as Crowd)._rallied, "a Prince seen: the rally is left to the alarm")
	_done(s)


static func _events(t) -> void:
	var night := NightState.new()
	night.prince = "seen"
	var s := _setup(night)
	var crowd: Crowd = s.crowd
	var d := _start(s, night)
	t.check(_ids(d) == ["rite", "boats", "last_ferry"], "a Prepared town lists the three windows (%s)" % [_ids(d)])
	var labels := []
	for e in d.timeline.upcoming(9):
		labels.append(String(e.label))
	t.check(labels == ["The clergy gather", "The boats sail", "The last ferry leaves"], "by name (%s)" % [labels])
	_run(s, 89.0)
	t.check(crowd.rite.state == BanishingRite.State.IDLE and crowd.ferry.state == RiverFerry.State.MOORED,
		"nothing has happened by 1:29")
	_run(s, 2.0)
	t.check(crowd.rite.state == BanishingRite.State.GATHERING, "at 1:30 the rite is gathering (%s)" %
		BanishingRite.State.keys()[crowd.rite.state])
	t.check((s.banners as Array).has("THE CLERGY GATHER"), "with its banner (%s)" % [s.banners])
	_run(s, 29.5)
	t.check(crowd.ferry.state == RiverFerry.State.LOADING or crowd.ferry.state == RiverFerry.State.AWAY,
		"at 2:00 the ferry is loading or away (%s)" % RiverFerry.State.keys()[crowd.ferry.state])
	_run(s, 30.0)  # 2:31: the clock's 0.1 s steps sum a hair short of 2:30
	t.check(crowd.ferry.state == RiverFerry.State.ENDED, "at 2:30 the last ferry has left and the boats are closed (%s)" %
		RiverFerry.State.keys()[crowd.ferry.state])
	t.check(d.timeline.upcoming(9).is_empty(), "and the strip is empty")
	_done(s)


## RiverFerry.close(): the boats stop for good, though the dock stands.
static func _close(t) -> void:
	var night := NightState.new()
	var s := _setup(night)
	var crowd: Crowd = s.crowd
	var f := crowd.ferry
	f.begin()
	var closed := []
	f.closed.connect(func(why: String) -> void: closed.append(why))
	f.close("the last ferry")
	t.check(f.state == RiverFerry.State.ENDED and not f.open() and closed == ["the last ferry"],
		"close() ends the boats with its reason (%s)" % [closed])
	_run(s, 1.0)
	t.check(f.state == RiverFerry.State.ENDED, "and the standing dock does not reopen them")
	f.close("again")
	t.check(closed.size() == 1, "closing twice says nothing twice")
	_done(s)


static func _organized(t) -> void:
	var night := NightState.new()
	var s := _setup(night, ResponseProfile.Tier.ORGANIZED)
	var d := _start(s, night)
	t.check(_ids(d) == [], "an Organized town has none of the windows (%s)" % [_ids(d)])
	_run(s, 3.0)
	t.check((s.crowd as Crowd).rite.state == BanishingRite.State.ENDED
		and (s.crowd as Crowd).ferry.state == RiverFerry.State.ENDED, "and its rite and boats stay off")
	_done(s)


## Review focus 3: the cathedral had fallen before the town rose to Prepared, so it has no rite to gather.
static func _cathedral_gone(t) -> void:
	var night := NightState.new()
	var s := _setup(night, ResponseProfile.Tier.ORGANIZED)
	var crowd: Crowd = s.crowd
	crowd.rite.cathedral.destroyed = true
	crowd.raise_profile(ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED))
	var d := _start(s, night)
	t.check(not _ids(d).has("rite") and _ids(d).has("boats"),
		"a rite that cannot be held has no event, the boats still do (%s)" % [_ids(d)])
	_run(s, 95.0)
	t.check(crowd.rite.state == BanishingRite.State.ENDED, "and the act runs past 1:30 without a rite")
	_done(s)


static func _dawn(t) -> void:
	var s := _setup(NightState.new())
	var rules: Rules = s.rules
	rules.time_left = 31.0
	rules.force_end(true, "citadel")
	var r := rules.result()
	t.check(r.bonuses.size() == 1 and r.bonuses[0].label == "Dawn never comes" and bool(r.bonuses[0].earned),
		"won with 31 s left, Dawn never comes is earned (%s)" % [r.bonuses])
	_done(s)
	s = _setup(NightState.new())
	rules = s.rules
	rules.time_left = 29.0
	rules.force_end(true, "citadel")
	r = rules.result()
	t.check(not bool(r.bonuses[0].earned), "won with 29 s left it is not (%s)" % [r.bonuses])
	_done(s)


## A director set up with no night at all begins as a quiet night, with the windows its town allows.
static func _bare(t) -> void:
	var s := _setup(NightState.new())
	var d := (MissionBook.long_night().act("judgement").director.new() as MissionDirector).setup(s.rules, s.crowd, s.town, null)
	t.check(d.timeline != null and _ids(d) == ["rite", "boats", "last_ferry"], "with no night it starts as a quiet one")
	_done(s)


## The HUD's "Escaped N / limit" reads this act: its escapes against its objective's limit; a single mission reads 0 / 50.
static func _hud(t) -> void:
	var night := NightState.new()
	night.prince = "escaped"
	var s := _setup(night)
	var crowd: Crowd = s.crowd
	crowd.escaped_count = 12  # the night's earlier escapes
	var rules := Rules.new().setup(PackedStringArray(["whisper"]), null, s.env, s.field, crowd, s.town, s.def)
	var hud := Hud.new().setup(rules, crowd, s.town, null)
	crowd.escaped_count = 15
	t.check(hud.escape_limit() == 40 and rules.escaped_this_act() == 3,
		"Act III after an escaped Prince counts its own escapes against 40 (%d of %d)" % [rules.escaped_this_act(), hud.escape_limit()])
	hud.free()
	rules.teardown()
	rules.free()
	_done(s)
	s = _setup(NightState.new())
	var single := Rules.new().setup(PackedStringArray(["whisper"]), null, s.env, s.field, s.crowd, s.town)
	var hud2 := Hud.new().setup(single, s.crowd, s.town, null)
	t.check(hud2.escape_limit() == Rules.ESCAPE_LIMIT and single.escaped_this_act() == 0,
		"a single mission still reads 0 against 50")
	hud2.free()
	single.teardown()
	single.free()
	_done(s)
