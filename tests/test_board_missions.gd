extends RefCounted
## v0.11 M1 board versions (spec §4, §7.2): each ★ mission at its tier's clock, readiness (a floor: raised, never lowered),
## base budget plus upgrades (six slots at most) and no bonuses; timelines stretched to the longer clock -- story time, so
## a director's own waits stretch with it; the Festival's raised need and its 4:30 close, a deadline; the Gaze objective at
## Tier 5; MissionBook's own missions untouched.

const DT := 0.05


static func run(t) -> void:
	_timeline(t)
	_profiles(t)
	_defs(t)
	_directors(t)


## A world for `def`: its town at the readiness the board sets, its director made by the def (stretched and tuned).
static func _world(def: MissionDef) -> Dictionary:
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
	var director := def.make_director().setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director}


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


static func _timeline(t) -> void:
	var plain := EventTimeline.new()
	plain.add(10.0, "a", "A")
	plain.step(10.0)
	t.check(Array(plain.fired_ids()) == ["a"] and plain.stretch_factor() == 1.0, "an unstretched timeline fires on time")
	var tl := EventTimeline.new().stretched(2.0)
	tl.add(10.0, "a", "A")
	tl.add(30.0, "b", "B")
	tl.step(19.9)
	t.check(tl.fired_ids().is_empty() and is_equal_approx(tl.elapsed(), 9.95), "stretched x2: not yet at 19.9 s (%f)" % tl.elapsed())
	var next: Dictionary = tl.upcoming(1)[0]
	t.check(is_equal_approx(float(next["in"]), 0.1) and is_equal_approx(float(next["at"]), 20.0),
		"the strip reads real seconds (%s)" % [next])
	tl.step(0.2)
	t.check(Array(tl.fired_ids()) == ["a"] and tl.has_come("a") and not tl.has_come("b") and tl.seconds_to("a") == 0.0
		and is_equal_approx(tl.seconds_to("b"), (30.0 - 10.05) * 2.0), "fired at 20 s; the next in real seconds")
	t.check(not tl.has_come("nowhere") and tl.seconds_to("nowhere") == 0.0, "an unknown event has not come")
	var obj := EventObjective.new("b", "Square closes", "closed")
	t.check(obj.deadline and obj.reason == "closed" and not Objective.new().deadline, "an event's objective is a deadline")


static func _profiles(t) -> void:
	var names := []
	for rank in range(0, 5):
		names.append(ResponseProfile.for_level(rank).tier_name())
	t.check(names == ["Unprepared", "Unaware", "Organized", "Prepared", "God-Resistant"], "a rank's profile (%s)" % [names])
	var aware := ResponseProfile.unaware()
	t.check(aware.at_least(2).tier_name() == "Organized" and aware.at_least(1) == aware and aware.at_least(-1) == aware,
		"a floor raises the town, never lowers it")
	var ready := ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT)
	t.check(ready.at_least(3) == ready, "a town above the floor stays as it is")


static func _defs(t) -> void:
	for id in TierBook.all():
		var def := TierBook.board(id)
		var tier := TierBook.tier_of(id)
		var ok := def != null and def.id == id and def.tier == tier and def.slots == TierBook.slots(tier)
		ok = ok and def.dp_capacity == TierBook.dp(tier) and not def.chooses_difficulty() and def.bonuses().is_empty()
		ok = ok and def.response_profile(ResponseProfile.Tier.UNPREPARED).level() >= TierBook.readiness(tier)
		if not def.has_acts():
			ok = ok and is_equal_approx(def.clock, TierBook.clock(tier))
		t.check(ok, "%s at Tier %d: its clock, readiness and budget, no bonuses, no difficulty" % [id, tier])
	t.check(TierBook.board("feast_festival") == null and TierBook.board("nowhere") == null, "no board version off the board")
	t.check(TierBook.board("miras_house").response_profile(ResponseProfile.DEFAULT).tier_name() == "Organized"
		and TierBook.board("warning").response_profile(ResponseProfile.DEFAULT).tier_name() == "Unaware"
		and TierBook.board("last_judgement").response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "God-Resistant",
		"Mira's House is raised to Organized; The Warning stays Unaware; Last Judgement ignores a chosen difficulty")
	var ln := TierBook.board("long_night")
	var acts_ok := ln.scored and ln.acts.size() == 4
	for a: ActDef in ln.acts:
		acts_ok = acts_ok and a.slots == 6 and a.dp_capacity == 16 and a.tier_floor == 4
	t.check(acts_ok and ln.first_act().town(NightState.new()).tier_name() == "God-Resistant"
		and is_equal_approx(ln.act("judgement").clock, 300.0), "The Long Night: every act at the tier's budget and readiness, its own clocks")
	var stretches := [TierBook.board("miras_house").stretch, TierBook.board("broken_lanterns").stretch,
		TierBook.board("vigil_flame").stretch, TierBook.board("procession").stretch, TierBook.board("festival").stretch]
	t.check(is_equal_approx(stretches[0], 2.2) and is_equal_approx(stretches[1], 330.0 / 180.0) and is_equal_approx(stretches[2], 2.0)
		and is_equal_approx(stretches[3], 2.6) and is_equal_approx(stretches[4], 1.8), "event times stretch with the clock (%s)" % [stretches])
	var state := DescendState.new()
	state.dp_bought = 2
	state.slot_bought = 1
	var w := TierBook.board("warning", state)
	var lj := TierBook.board("last_judgement", state)
	t.check(w.slots == 4 and w.dp_capacity == 8 and lj.slots == TierBook.MAX_SLOTS and lj.dp_capacity == 18,
		"upgrades add to the base; six slots at most (%d)" % lj.slots)
	t.check(Array(TierBook.board("warning").mission_tags) == ["unaware_town"] and TierBook.board("festival").mission_tags.is_empty(),
		"each carries its mission tags")
	var gazes := []
	for o in lj.objectives():
		gazes.append(o is GazeObjective)
	var omen_gaze := false
	for o in ln.act("omen").objectives():
		omen_gaze = omen_gaze or o is GazeObjective
	var judged := false
	for o in ln.act("judgement").objectives():
		judged = judged or o is GazeObjective
	var t4 := false
	for o in TierBook.board("procession").objectives():
		t4 = t4 or o is GazeObjective
	t.check(gazes == [false, false, false, true] and omen_gaze and judged and not t4, "Tier 5 keeps the Gaze, in every act; Tier 4 does not")
	t.check(lj.goal == "Destroy the Citadel and break the city before dawn", "Last Judgement's goal no longer names 6:00")
	var fest := TierBook.board("festival")
	var reasons := []
	for o in fest.objectives():
		reasons.append([o.reason, o.deadline])
	t.check(reasons == [["festival", false], ["closed", true]] and fest.name == "The Festival" and fest.director == FestivalDirector,
		"the Festival: break it before the square closes, a deadline (%s)" % [reasons])
	var act_reasons := []
	for o in MissionBook.long_night().act("festival").objectives():
		act_reasons.append([o.reason, o.deadline])
	t.check(act_reasons == [["festival", false], ["closed", false]], "The Long Night's own Festival is untouched (%s)" % [act_reasons])
	var book := MissionBook.miras_house()
	t.check(is_equal_approx(book.clock, 150.0) and book.stretch == 1.0 and book.tier_floor == -1 and not book.bonuses().is_empty(),
		"MissionBook's own Mira's House is left as it was")


static func _directors(t) -> void:
	var s := _world(TierBook.board("miras_house"))
	var m: MirasHouseDirector = s.d
	var venn: Dictionary = m.timeline.upcoming(1)[0]
	t.check(m.stretch == 2.2 and String(venn.id) == "venn" and is_equal_approx(float(venn["in"]), 88.0),
		"Mira's House: the Inquisitor searches at 1:28, not 0:40 (%s)" % [venn])
	_done(s)

	var f := _world(TierBook.board("festival"))
	var fd: FestivalDirector = f.d
	var close := (f.rules as Rules).objectives[1]
	t.check(fd.need == TierBook.FESTIVAL_NEED and fd.crowd_size == TierBook.FESTIVAL_CROWD and fd.goers.size() > TierBook.FESTIVAL_NEED
		and is_equal_approx(fd.timeline.seconds_to("close"), TierBook.FESTIVAL_CLOSE) and close.hud_text(f.rules) == "Square closes 4:30",
		"the Festival: %d goers, %d needed, the square closing at 4:30" % [fd.goers.size(), fd.need])
	fd.timeline.step(TierBook.FESTIVAL_CLOSE + DT)  # real seconds: the timeline divides by its stretch itself
	t.check(close.check(f.rules) == Objective.Status.FAILED, "the close fails it once it comes")
	_done(f)

	var v := _world(TierBook.board("vigil_flame"))
	var vd: VigilFlameDirector = v.d
	# Read from the events themselves: the strip leaves the search off while the light sleeps (its guard).
	var search := -1.0
	for e: Dictionary in vd.timeline._events:
		if String(e.id) == "search":
			search = float(e.at) * vd.timeline.stretch_factor()
	t.check(absf(search - (360.0 - Searchlight.SEARCH_LAST)) < 0.01, "the Vigil Flame's search keeps the clock's last 20 s (%f)" % search)
	_done(v)

	var book := _world(MissionBook.miras_house())
	t.check((book.d as MirasHouseDirector).stretch == 1.0
		and is_equal_approx(float((book.d as MirasHouseDirector).timeline.upcoming(1)[0]["in"]), MirasHouseDirector.VENN_AT),
		"the campaign's Mira's House searches at 0:40 as before")
	_done(book)
