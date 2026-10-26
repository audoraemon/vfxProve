extends RefCounted
## God P1 Task 5 (spec §9.1, §8, §7): an Endless Night night -- the seeded draw with no repeat, the god's def (slots, Might, pool, clock),
## Divine Power and Faith banked, the lost and forfeited nights, and Mission's hooks.


static func run(t) -> void:
	GodTree.dev_fill = true
	_draw_no_repeat(t)
	_draw_seeded(t)
	_draw_tier(t)
	_def(t)
	_def_empty(t)
	_def_acts(t)
	_dp(t)
	_dp_caught(t)
	_dp_lost(t)
	_tier_scale(t)
	_forfeit(t)
	_wish_seed(t)
	_bests(t)
	_mission_hooks(t)
	GodTree.dev_fill = false


static func _slot(type := "ruin", seed_value := 3) -> GodSlot:
	return GodSlot.make(1, type, seed_value)


## A report's "descend" as Descent.report() gives it, for the keys banking reads.
static func _outcome(main: bool, kept: int, earned: int, main_time := 150.0, tier := 1) -> Dictionary:
	return {"won": main, "descend": {"tier": tier, "main": main, "kept": kept, "earned": earned, "main_time": main_time if main else 0.0}}


static func _draw_no_repeat(t) -> void:
	var s := _slot()
	var seen := {}
	var last := ""
	var repeats := 0
	for i in 40:
		var id := GodNight.draw(s)
		seen[id] = true
		if id == last:
			repeats += 1
		s.in_night = id
		GodNight.forfeit(s)
		last = id
	t.check(repeats == 0, "no night is drawn twice in a row (%d repeats in 40)" % repeats)
	var missing := []
	for id in TierBook.missions(1):
		if not seen.has(id):
			missing.append(id)
	t.check(missing.is_empty(), "every Tier 1 mission is drawn at least once in 40 nights (never drawn: %s)" % [missing])


static func _draw_seeded(t) -> void:
	var s := _slot()
	t.check(GodNight.draw(s) == GodNight.draw(s), "the same slot gives the same night (no state changes)")
	var copy := _slot()
	t.check(GodNight.draw(copy) == GodNight.draw(s), "a copy with the same seed and night draws the same")
	t.check(GodNight.night_seed(copy) == GodNight.night_seed(s), "the night seed is the same for the same seed and night")
	var runs: Array[String] = []
	for seed_value in [3, 4]:
		var g := _slot("ruin", seed_value)
		var run := ""
		for i in 10:
			var id := GodNight.draw(g)
			run += id + ","
			g.in_night = id
			GodNight.forfeit(g)
		runs.append(run)
	t.check(runs[0] != runs[1], "seeds 3 and 4 give different ten-night runs (%s | %s)" % [runs[0], runs[1]])


static func _draw_tier(t) -> void:
	var s := _slot()
	s.tier = 2
	var id := GodNight.draw(s)
	t.check(TierBook.missions(2).has(id), "a tier 2 god draws a tier 2 mission (%s)" % id)


static func _def(t) -> void:
	var s := _slot()
	s.bought = {"might": 2, "slot": 1, "clock": 2}
	var d := GodNight.def_for(s, "warning")
	t.check(d.slots == 4, "slots are the god's: 3 + 1 (%d)" % d.slots)
	t.check(d.dp_capacity == 8, "Might is the tier's 6 + 2 (%d)" % d.dp_capacity)
	t.check(d.pool == s.draftable(), "the pool is the god's draftable abilities (%s)" % [d.pool])
	t.check(is_equal_approx(d.clock, TierBook.clock(1) + 30.0), "the clock is the tier's + 30 s (%s)" % d.clock)
	t.check(is_equal_approx(d.stretch, TierBook.board("warning").stretch), "the event stretch keeps the tier's (%s)" % d.stretch)
	t.check(d.director == StarfallDirector, "The Warning keeps its StarfallDirector")
	t.check(d.tier == 1, "the night is on the god's tier (%d)" % d.tier)


static func _def_empty(t) -> void:
	GodTree.dev_fill = false
	var s := _slot()
	s.learned = {}
	var d := GodNight.def_for(s, "warning")
	t.check(d.pool == PackedStringArray([GodNight.NO_POWERS]), "a god with nothing to draft gets the sentinel pool (%s)" % [d.pool])
	t.check(not d.allows("smite"), "and no power is allowed (not every power)")
	GodTree.dev_fill = true


static func _def_acts(t) -> void:
	var s := _slot()
	s.tier = 5
	s.bought = {"might": 1, "slot": 2, "clock": 1}
	var d := GodNight.def_for(s, "long_night")
	var plain := TierBook.board("long_night")
	t.check(d.has_acts() and d.acts.size() == plain.acts.size(), "The Long Night keeps its acts (%d)" % d.acts.size())
	for i in d.acts.size():
		var a: ActDef = d.acts[i]
		var b: ActDef = plain.acts[i]
		t.check(a.slots == s.slots(), "act %s: the god's slots (%d)" % [a.id, a.slots])
		t.check(a.dp_capacity == s.max_might(), "act %s: the god's Might (%d)" % [a.id, a.dp_capacity])
		t.check(a.pool == s.draftable(), "act %s: the god's pool" % a.id)
		t.check(is_equal_approx(a.clock, b.clock + s.extra_clock()), "act %s: its board clock + the Faith clock (%s vs %s)" % [a.id, a.clock, b.clock])


static func _dp(t) -> void:
	var s := _slot()
	var out := GodNight.bank(s, "warning", PackedStringArray(["smite"]), _outcome(true, 2, 30))
	t.check(out.divine_power == 120, "main plus two wishes at tier 1 is 120 Divine Power (%d)" % out.divine_power)
	t.check(s.level == 3 and out.level == 3, "120 Divine Power is level 3 (%d)" % s.level)
	t.check(s.points == 2 and out.points == 2, "two levels, two points (%d)" % s.points)
	t.check(s.faith == 30 and out.faith == 30 and out.faith_total == 30, "30 believers are 30 Faith (%d)" % s.faith)
	t.check(s.night == 1 and out.night == 1, "the night counts (%d)" % s.night)
	t.check(s.last_mission == "warning", "the mission is remembered (%s)" % s.last_mission)
	t.check(s.carried == {"smite": 1}, "the drafted ability is carried once (%s)" % [s.carried])
	t.check(s.loadout == PackedStringArray(["smite"]), "the loadout is the last draft")
	t.check(out.bar == [s.divine_power, s.need()], "the bar is the god's (%s)" % [out.bar])
	t.check(out.notice == 0 and out.notice_change == 0, "the Notice does not move in P1")
	t.check(out.believers == 30, "believers banked: 30 (%d)" % out.believers)


static func _dp_caught(t) -> void:
	var s := _slot()
	var out := GodNight.bank(s, "warning", PackedStringArray(["smite"]), _outcome(true, 0, 10))
	t.check(out.divine_power == 80, "caught after the main objective: only the main's 80 (%d)" % out.divine_power)
	t.check(s.faith == 10, "its believers still bank (%d)" % s.faith)


static func _dp_lost(t) -> void:
	var s := _slot()
	var out := GodNight.bank(s, "warning", PackedStringArray(["smite"]), _outcome(false, 0, 0))
	t.check(out.divine_power == 0 and s.faith == 0, "a lost night earns nothing (%d, %d)" % [out.divine_power, s.faith])
	t.check(s.night == 1 and s.last_mission == "warning", "but it counts and is remembered (%d, %s)" % [s.night, s.last_mission])


static func _tier_scale(t) -> void:
	var s := _slot()
	s.tier = 3
	var out := GodNight.bank(s, "tax_collector", PackedStringArray(), _outcome(true, 1, 0, 150.0, 3))
	t.check(out.divine_power == 300, "tier 3, main, one wish: 240 + 60 = 300 (%d)" % out.divine_power)
	t.check(GodNight.divine_power({"tier": 3, "main": true, "kept": 1}) == 300, "divine_power() reads a report's descend")


static func _forfeit(t) -> void:
	var s := _slot()
	s.in_night = "tax_collector"
	s.faith = 7
	var level := s.level
	var out := GodNight.forfeit(s)
	t.check(s.night == 1 and s.last_mission == "tax_collector" and s.in_night == "", "a forfeit counts the night and closes it (%d, %s, %s)" % [s.night, s.last_mission, s.in_night])
	t.check(s.faith == 7 and s.level == level, "and earns nothing")
	t.check(out.line == "Night 1 was abandoned: a lost night." and out.night == 1, "its line (%s)" % out.line)


static func _wish_seed(t) -> void:
	var s := _slot()
	var a := GodNight.wish_seed(s, "warning")
	t.check(a == GodNight.wish_seed(_slot(), "warning"), "the wish seed is stable for the same slot, night and id")
	t.check(a != GodNight.wish_seed(s, "tax_collector"), "and differs by mission")
	s.night += 1
	t.check(a != GodNight.wish_seed(s, "warning"), "and differs after the night counts")


static func _bests(t) -> void:
	var s := _slot()
	GodNight.bank(s, "warning", PackedStringArray(["smite"]), _outcome(true, 1, 5, 200.0))
	var out := GodNight.bank(s, "warning", PackedStringArray(["smite"]), _outcome(true, 2, 5, 150.0))
	t.check(s.bests.get("warning", {}) == {"cleared": true, "fastest": 150.0, "most_wishes": 2}, "the bests keep the fastest and the most wishes (%s)" % [s.bests])
	t.check(out.bests.size() == 2, "both are reported as new (%s)" % [out.bests])
	t.check(s.carried.get("smite", 0) == 2, "two nights, carried twice")


static func _mission_hooks(t) -> void:
	var s := _slot()
	var m := Mission.new()
	m.night_def = func() -> MissionDef: return GodNight.def_for(s, "warning")
	t.check(m._mission_def(PackedStringArray()).pool == s.draftable(), "night_def replaces the mission's def")
	t.check(m.restart_locked == false, "R restarts unless locked")
	t.check(m.has_signal("clock_started"), "the mission announces its clock starting")
	m.free()
