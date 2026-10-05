extends RefCounted
## v0.09 Act II-A (FestivalDirector): FESTIVAL_CROWD citizens fill the market square and stay, the Mayor is among the
## merchants (not the goers), the festival counts the dead and the broken, soldiers watch the square if the bell rang,
## and the Mayor and the Prince's noble have looks on both art paths.

const DT := 0.1
const R := CitizenProfile.Role


## A town spawned Unaware and the Festival's Rules for `night`, with no director yet (see _start()). `rung`: the bell has
## rung before the act begins (Act I's alarm).
static func _setup(night: NightState, rung := false) -> Dictionary:
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
	if rung:
		crowd.bell.state = BellNetwork.State.RUNG
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
	_bonfire(t)
	_address(t)
	_mayor_death(t)
	_mayor_early_and_missing(t)
	_mayor_and_goer_freed(t)
	_clock(t)
	_objectives(t)
	_bell_quiet(t)
	_mayor_frightened(t)
	_report_at_end(t)
	_let_go(t)


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


## The banners a Rules sends, collected as it goes.
static func _banners(s: Dictionary) -> Array[String]:
	var out: Array[String] = []
	(s.rules as Rules).banner.connect(func(text: String) -> void: out.append(text))
	return out


## 0:45: every calm goer is sent to a spot within PACK_R of the fountain.
static func _bonfire(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var banners := _banners(s)
	var fountain := TownLayout.FOUNTAIN.get_center()
	_run(s, 44.0)
	t.check(not d.timeline.fired_ids().has("bonfire") and banners.is_empty(), "nothing has lit at 0:44")
	_run(s, 1.5)
	t.check(d.timeline.fired_ids().has("bonfire") and banners.has("THE BONFIRE LIGHTS"), "the bonfire lights at 0:45 (%s)" % [banners])
	var calm := 0
	var packed := true
	var goals := true
	for p in d.goers:
		if p.is_alive() and p.mind == Person.Mind.CALM:
			calm += 1
			packed = packed and p.anchor.distance_to(fountain) <= FestivalDirector.PACK_R + 0.5
			goals = goals and (not p.has_goal() or p.goal().distance_to(fountain) <= FestivalDirector.PACK_R + 0.5)
	t.check(calm >= 60, "most of the goers are calm at 0:46 (%d)" % calm)
	t.check(packed and goals, "each calm goer's spot and goal lie within PACK_R + 0.5 of the fountain")
	_done(s)


## 1:30 the Mayor takes the fountain on duty and the calm goers look at him; at 2:00 he is let go.
static func _address(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var banners := _banners(s)
	var fountain := TownLayout.FOUNTAIN.get_center()
	_run(s, 91.0)
	t.check(banners.has("THE MAYOR'S ADDRESS"), "the address is announced at 1:30 (%s)" % [banners])
	t.check(d.mayor.mind == Person.Mind.DUTY and d.mayor.anchor.distance_to(fountain) <= 2.0,
		"the Mayor is on duty at the fountain (%s, %.2f away)" % [d.mayor.mind, d.mayor.anchor.distance_to(fountain)])
	var looking := 0
	for p in d.goers:
		if p.mind == Person.Mind.OBSERVE:
			looking += 1
	t.check(looking >= 60, "the calm goers look at him (%d of %d)" % [looking, d.goers.size()])
	_run(s, 30.0)
	t.check(d.mayor.mind != Person.Mind.DUTY and banners.has("THE ADDRESS ENDS"),
		"at 2:00 he is off duty (%s) and the end is announced" % d.mayor.mind)
	_run(s, 30.0)
	t.check(d.timeline.fired_ids().has("close") and not d.broken(), "the guard closes the square at 2:30, no callback")
	_done(s)


## The Mayor killed at 1:35: every living goer panics at once, the banner shows and the festival is broken.
static func _mayor_death(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var banners := _banners(s)
	var field: EnemyField = s.field
	_run(s, 95.0)
	t.check(not (s.rules as Rules).finished, "the act is still on at 1:35")
	t.check(field.kill(d.mayor, &"fire"), "the Mayor dies")
	_run(s, 0.1)
	var living := 0
	var panicking := 0
	var shelter := 0
	for p in d.goers:
		if p.is_alive():
			living += 1
			if p.mind in FestivalDirector.BROKE_MINDS:
				panicking += 1
				shelter += int(p.mind == Person.Mind.SHELTER)
	t.check(living > 0 and panicking == living and living - shelter > living / 2,
		"every living goer is frightened -- panicking, or (as Person.panic() may) running for a roof (%d of %d, %d sheltering)" % [panicking, living, shelter])
	t.check(banners.has("THE MAYOR FALLS - THE FEAST BREAKS"), "the banner shows (%s)" % [banners])
	t.check(d.count() >= d.need and d.broken(), "the festival is broken: %d of %d" % [d.count(), d.need])
	var rules: Rules = s.rules
	t.check(rules.finished and rules.won and rules.over_reason == "festival", "and the act is won (%s %s)" % [rules.won, rules.over_reason])
	t.check(d.report().festival == "broken", "the report says broken")
	_done(s)


## Review focus 1: the Mayor dead before his address (and none at all): the later events run quietly, nobody dead is sent.
static func _mayor_early_and_missing(t) -> void:
	for missing in [false, true]:
		var s := _setup(NightState.new())
		var d := _start(s, null)
		var banners := _banners(s)
		var field: EnemyField = s.field
		d.need = 1000  # the act runs on whatever the panic breaks
		_run(s, 10.0)
		if missing:
			d.mayor = null
		else:
			t.check(field.kill(d.mayor, &"fire"), "the Mayor dies at 0:10")
			var panicked := 0
			var living := 0
			for p in d.goers:
				if p.is_alive():
					living += 1
					if p.mind in FestivalDirector.BROKE_MINDS:
						panicked += 1
			t.check(living > 0 and panicked == living, "the panic happened at 0:10 (%d of %d)" % [panicked, living])
			t.check(banners.has("THE MAYOR FALLS - THE FEAST BREAKS"), "with its banner")
		_run(s, 125.0)
		var ids := d.timeline.fired_ids()
		t.check(ids.has("bonfire") and not ids.has("address") and not ids.has("address_end"),
			"the bonfire lit, the address and its end were dropped (%s, missing=%s)" % [ids, missing])
		t.check(not banners.has("THE MAYOR'S ADDRESS") and not banners.has("THE ADDRESS ENDS"), "and never shown")
		t.check(d.mayor == null or (d.mayor.mind != Person.Mind.DUTY and not d.mayor.is_alive()), "nobody dead was sent anywhere")
		t.check(not (s.rules as Rules).finished, "the act runs on to its clock")
		_done(s)


## The clock: 2:30 with the festival unbroken loses the act ("closed").
static func _clock(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var rules: Rules = s.rules
	_run(s, 149.0)
	t.check(not rules.finished, "the square is open at 2:29")
	_run(s, 2.0)
	t.check(rules.finished and not rules.won and rules.over_reason == "closed", "at 2:30 it closes: lost (%s %s)" % [rules.won, rules.over_reason])
	t.check(d.report().festival == "held", "the report says held")
	_done(s)


## The act's objectives, bonus and events as the book lists them, and the Festival objective's line.
static func _objectives(t) -> void:
	var def := MissionBook.long_night().act("festival")
	var os := def.objectives()
	t.check(os.size() == 2 and os[0] is FestivalObjective and os[1] is ClockObjective and os[1].reason == "closed",
		"the act's objectives: the festival, then the clock (closed)")
	var bs := def.bonuses()
	t.check(bs.size() == 1 and bs[0] is BellQuietObjective and bs[0].label == "Before the bell" and bs[0].reason == "bell_quiet",
		"one bonus, Before the bell")
	t.check(def.events_text == PackedStringArray(["0:45 The bonfire lights", "1:30 The Mayor's address",
		"2:30 The guard closes the square"]), "the card lists the three events (%s)" % [def.events_text])
	t.check(def.card_line(NightState.new()) == "The town suspects nothing.", "the card line stays")
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var f := FestivalObjective.new()
	t.check(f.label == "Break the festival" and f.reason == "festival", "label and reason")
	t.check(f.check(s.rules) == Objective.Status.PENDING and f.hud_text(s.rules) == "Break the festival 0/%d" % d.need,
		"pending, and the line counts (%s)" % f.hud_text(s.rules))
	d.need = 0
	t.check(f.check(s.rules) == Objective.Status.DONE, "done when the director says broken")
	_done(s)


## Before the bell: a bell already rung when the act starts does not count against it; one that rings in the act does --
## even before the act's first look (v0.09 final review: the intro holds the Rules, not the town, so a bell rung during
## it was taken for Act I's).
static func _bell_quiet(t) -> void:
	for case in ["rung_before", "rings_in_intro", "rings_during", "never"]:
		var s := _setup(NightState.new(), case == "rung_before")
		_start(s, null)
		var crowd: Crowd = s.crowd
		var rules: Rules = s.rules
		var bonus := rules.bonuses[0]
		if case == "rings_in_intro":
			crowd.bell.state = BellNetwork.State.RUNG
			t.check(bonus.check(rules) == Objective.Status.FAILED, "rung after the act began, before its first look: failed")
		else:
			t.check(bonus.check(rules) == Objective.Status.PENDING, "%s: pending at the first look" % case)
		if case == "rings_during":
			crowd.bell.state = BellNetwork.State.RUNG
			t.check(bonus.check(rules) == Objective.Status.FAILED, "it fails once the bell rings in the act")
		rules.force_end(true, "forced")
		var earned := bool(rules.result().bonuses[0].earned)
		t.check(earned == (case == "rung_before" or case == "never"), "%s: earned on a win is %s" % [case, earned])
		_done(s)


## A Mayor already frightened when his address falls due is not pulled back to the fountain on duty (v0.09 final review).
static func _mayor_frightened(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	d.need = 1000  # the act runs on whatever the fright breaks
	_run(s, 89.5)
	t.check(WarningDirector._alive(d.mayor), "the Mayor lives at 1:29")
	d.mayor.panic(d.mayor.ground_pos + Vector2(0.5, 0.0), 1.0, &"test")
	var scared := d.mayor.mind
	_run(s, 0.6)
	t.check(not scared in WarningDirector.RESUMABLE and d.mayor.mind != Person.Mind.DUTY,
		"frightened at 1:29 (%s), he is not on duty at 1:30 (%s)" % [Person.Mind.keys()[scared], Person.Mind.keys()[d.mayor.mind]])
	_done(s)


## The act's report is what stood when it ended (v0.09 final review): the slow-motion ending runs on for seconds before
## Mission reads it, and a goer dying in it must not turn a closed square into a broken feast.
static func _report_at_end(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var rules: Rules = s.rules
	_run(s, 151.0)
	t.check(rules.finished and rules.over_reason == "closed" and not d.broken(), "the square closes unbroken (%d of %d)" %
		[d.count(), d.need])
	var field: EnemyField = s.field
	for p in d.goers:
		if WarningDirector._alive(p):
			field.kill(p, &"fire")
	t.check(d.broken(), "every goer killed in the ending would break it now (%d)" % d.count())
	t.check(rules.result().festival == "held", "but the act's result still says held (%s)" % rules.result().festival)
	_done(s)


## The director is let go once the act is over (v0.09 final review): its timeline's lambdas no longer hold it.
static func _let_go(t) -> void:
	var s := _setup(NightState.new())
	var w: WeakRef = weakref(_start(s, null))
	s.erase("d")
	_run(s, 1.0)
	_done(s)
	t.check(w.get_ref() == null, "the Festival's director is freed after teardown")


## The Mayor and a goer killed and then freed (a killed citizen frees itself when its death fade ends) while the director,
## the HUD's event strip and the count still hold them: the address and its end are dropped, nothing raises.
static func _mayor_and_goer_freed(t) -> void:
	var s := _setup(NightState.new())
	var d := _start(s, null)
	var field: EnemyField = s.field
	d.need = 1000
	_run(s, 10.0)
	var mayor := d.mayor
	var goer: Person = d.goers[0]
	field.kill(mayor, &"fire")
	field.kill(goer, &"fire")
	for p: Person in [mayor, goer]:
		(s.crowd as Crowd).citizens.erase(p)
		field.remove(p)
		p.free()
	t.check(d.timeline.upcoming(3).size() == 2 and d.count() >= 1, "freed: the strip lists bonfire and close, the count still reads")
	_run(s, 40.0)
	_run(s, 45.0)
	t.check(d.timeline.upcoming(3).size() == 1 and "bonfire" in d.timeline.fired_ids() and not "address" in d.timeline.fired_ids(),
		"past 0:45 and 1:30 the address is dropped and nothing raises (%s)" % [d.timeline.fired_ids()])
	_done(s)
