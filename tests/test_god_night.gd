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
	_bank_conquest(t)
	_bank_no_conquest(t)
	_faith_not_doubled(t)
	_hunt_no_conquest(t)
	_forfeit_alive(t)
	_believer_seed(t)
	_results_conquest_line(t)
	_conquer_bonus(t)
	_draw_town(t)
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
		s.notice = 0  # P1's draw only: the Hunt is P2's and is proved in test_god_lantern
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
			g.notice = 0  # P1's draw only: the Hunt is P2's and is proved in test_god_lantern
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
	t.check(out.notice == 10 and out.notice_change == 10, "this fixture has no ascent, so it is a caught win: Notice +10 (%d)" % out.notice)
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
	t.check(out.line == "Night 1 was abandoned: a lost night. Lantern Notice +25%." and out.night == 1, "its line (%s)" % out.line)


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
	t.check(m.has_signal("decided") and m.report_on_decision == false, "the mission can report when a run is decided; off unless Endless sets it (review M1)")
	m.free()


static func _conquest_entry(alive: int, lost := 2) -> Dictionary:
	return {"town": "aldermere", "carried_alive": alive, "named": 0, "fill": 0, "lost": lost}


static func _bank_conquest(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 50
	var out := _outcome(true, 0, 30)
	out.descend["main"] = true
	out["conquest"] = _conquest_entry(48)
	var res := GodNight.bank(s, "tax_collector", PackedStringArray(["smite"]), out)
	t.check(int(s.believers.aldermere) == 48 and int(res.conquest.count) == 48, "the roll's 48 survivors become the town's count (%s)" % [s.believers])
	t.check(int(res.faith) == 30 * GodSlot.FAITH_PER_BELIEVER and s.faith == int(res.faith), "Faith is still exactly what was earned (%s)" % [res.faith])


static func _bank_no_conquest(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 50
	var res := GodNight.bank(s, "tax_collector", PackedStringArray(["smite"]), _outcome(true, 0, 5))
	t.check(int(s.believers.aldermere) == 50 and res.conquest == {}, "an outcome without a conquest leaves the counts alone and says {} (%s)" % [res.conquest])


static func _hunt_no_conquest(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 50
	s.notice = 100
	t.check(GodNight.is_hunt(GodNight.draw(s)), "the Hunt is due")
	var out := _outcome(true, 0, 5)
	out["conquest"] = _conquest_entry(10)
	var res := GodNight.bank(s, GodNight.draw(s), PackedStringArray(["smite"]), out)
	t.check(int(s.believers.aldermere) == 50 and res.conquest == {}, "a Hunt changes no town count (%s)" % [s.believers])


static func _forfeit_alive(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 50
	s.last_town = "aldermere"
	s.in_night = "tax_collector"
	var out := GodNight.forfeit(s, 41)
	t.check(int(s.believers.aldermere) == 41 and int(out.conquest.count) == 41 and out.conquest.town == "aldermere", "a forfeit keeps who was alive (%s)" % [s.believers])
	var s2 := _slot()
	s2.believers["aldermere"] = 50
	s2.in_night = "tax_collector"
	var out2 := GodNight.forfeit(s2)
	t.check(int(s2.believers.aldermere) == 50 and int(out2.conquest.count) == 50, "no count given keeps the saved one (%s)" % [s2.believers])


static func _believer_seed(t) -> void:
	var s := _slot()
	var a := GodNight.believer_seed(s, "warning")
	t.check(a == GodNight.believer_seed(_slot(), "warning") and a != GodNight.wish_seed(s, "warning"), "the believer seed is stable and its own")
	s.night += 1
	t.check(a != GodNight.believer_seed(s, "warning"), "and differs by night")


static func _results_conquest_line(t) -> void:
	var base := {"god": {"divine_power": 5, "levels": [], "capped": false, "believers": 1, "faith": 1, "faith_total": 1, "notice": 0, "night": 2}}
	var plain := ResultsScreen.god_lines(base)
	var with_c := base.duplicate(true)
	with_c.god["conquest"] = {"town": "aldermere", "percent": 12, "converts": 4, "lost": 1}
	var got := ResultsScreen.god_lines(with_c)
	t.check(got.size() == plain.size() + 1 and got[got.size() - 2] == "Aldermere 12%   converts +4   believers lost 1" and got[got.size() - 1] == "Night 2",
		"the conquest line sits before the Night line (%s)" % [got])
	t.check(ResultsScreen.god_lines(base) == plain, "without it the lines are as before")


static func _faith_not_doubled(t) -> void:
	var s := _slot()
	s.believers["aldermere"] = 0
	var out := _outcome(true, 0, 40)
	out.descend["main"] = true
	out["conquest"] = {"town": "aldermere", "carried_alive": 30, "named": 2, "fill": 6, "lost": 0}
	var before := s.faith
	var res := GodNight.bank(s, "tax_collector", PackedStringArray(["smite"]), out)
	t.check(int(res.faith) == 46 * GodSlot.FAITH_PER_BELIEVER and s.faith == before + int(res.faith), "Faith is the earned plus the fill (%s)" % [res.faith])
	t.check(int(res.conquest.count) == 38 and int(res.conquest.converts) == 8, "the count is 38 (%s)" % [res.conquest])
	var s2 := _slot()
	var o2 := _outcome(true, 0, 40)
	o2.descend["main"] = true
	var r2 := GodNight.bank(s2, "tax_collector", PackedStringArray(["smite"]), o2)
	t.check(int(r2.faith) == 40 * GodSlot.FAITH_PER_BELIEVER, "with no conquest entry, Faith is the earned alone (%s)" % [r2.faith])


## A conquered town pays Faith on a banked ordinary night, over what the night earned and the fill paid.
static func _conquer_bonus(t) -> void:
	var s := _slot()
	var pop := Conquest.population("aldermere")
	var out := _outcome(true, 0, 30)
	out["conquest"] = {"town": "aldermere", "carried_alive": pop - 5, "named": 0, "fill": 5, "lost": 0}
	var res := GodNight.bank(s, "tax_collector", PackedStringArray(["smite"]), out)
	t.check(Conquest.conquered(s, "aldermere") and int(res.conquer_faith) == Conquest.CONQUER_FAITH, "the night fills the town: conquered, bonus 5 (%s)" % [res.get("conquer_faith")])
	t.check(int(res.faith) == (30 + 5) * GodSlot.FAITH_PER_BELIEVER + Conquest.CONQUER_FAITH and s.faith == int(res.faith),
		"the night pays earned + fill + the conquered bonus (%s)" % [res.faith])
	var plain := _slot()
	var res2 := GodNight.bank(plain, "tax_collector", PackedStringArray(["smite"]), _outcome(true, 0, 30))
	t.check(int(res2.conquer_faith) == 0, "no conquered town: no bonus")
	var lines := ResultsScreen.god_lines({"god": res})
	t.check(lines.has("Conquered towns: Faith +5"), "the results say it (%s)" % [lines])


## Only Aldermere draws a night until Task 6; its draw is as it was.
static func _draw_town(t) -> void:
	var same := true
	for night in range(0, 31):
		for sd in range(1, 21):
			var s := _slot("ruin", sd)
			s.night = night
			same = same and GodNight.draw(s) == GodNight.draw(s, "aldermere")
	t.check(same, "draw(slot) is draw(slot, aldermere) for nights 0..30 and seeds 1..20")
	t.check(GodNight.draw(_slot(), "capital") == "", "the Capital draws no night yet")
