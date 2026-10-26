extends RefCounted
## v0.11 M6 Tier 5 complete on the board, and the board complete: the ★ missions and the three new, each new one at Tier 5's numbers (7:00,
## 6 / 16, God-Resistant, no unaware_town, no bonuses, no stretch) with its one Gaze objective; Ascendance counts its five; with all 25
## cleared the results read "every tier is cleared" and the header "All 25 cleared"; no timed wait over 60 s, no chain over 45 s, the first
## waits pinned; a board night's wishes reserved before each director gathers its people (review focus 5); Exodus never hears the escape
## wishes, the Heart never the pyre; five cards on Ascendance's tab.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The three new Tier 5 missions.
const NEW := ["lantern_eye", "exodus", "heart_of_faith"]


static func run(t) -> void:
	_board(t)
	_lines(t)
	_complete(t)
	_m5_save(t)
	_waits(t)
	_reserved(t)
	_wishes(t)
	_cards(t)


static func _gazes(m: MissionDef) -> int:
	var n := 0
	for o in m.objectives():
		n += 1 if o is GazeObjective else 0
	return n


static func _board(t) -> void:
	for id: String in NEW:
		var m := TierBook.board(id)
		t.check(m != null and m.id == id and m.tier == 5 and is_equal_approx(m.clock, 420.0) and m.slots == 6 and m.dp_capacity == 16
			and m.tier_floor == 4 and not m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "God-Resistant" and is_equal_approx(m.stretch, 1.0) and _gazes(m) == 1,
			"%s on the board: Tier 5, 7:00, 6 / 16, God-Resistant, no unaware_town, no bonuses, no stretch, one Gaze objective" % id)
	t.check(Array(TierBook.missions(5)) == ["last_judgement", "long_night"] + NEW and TierBook.need(5) == 3 and TierBook.all().size() == 25
		and _gazes(TierBook.board("last_judgement")) == 1, "Ascendance: the ★ missions first, then the three new; 25 board missions; Last Judgement keeps its one Gaze")
	t.check(TierBook.type_of("lantern_eye") == "Anchors" and TierBook.type_of("exodus") == "Protect" and TierBook.type_of("heart_of_faith") == "Kill"
		and Array(TierBook.board("exodus").mission_tags) == ["shuts_gates"] and Array(TierBook.board("heart_of_faith").mission_tags) == ["burns_temple"]
		and TierBook.board("lantern_eye").mission_tags.is_empty(), "each card's type; Exodus and the Heart keep their clashing wishes away")
	t.check(TierBook.board("last_judgement").mission_tags.is_empty() and TierBook.board("long_night").mission_tags.is_empty()
		and not TierBook.MISSION_TAGS.has("last_judgement") and not TierBook.MISSION_TAGS.has("long_night"),
		"Last Judgement and The Long Night declare no tags on the board (no burns_temple): their wishes as they were (the final review's pin)")


## Three cleared of each tier below Ascendance (v0.11 M6 tests).
const BELOW := ["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns", "bell_ringers", "vigil_flame", "festival",
	"crowns_bread", "procession", "bishop", "armoury"]


static func _lines(t) -> void:
	var s := DescendState.new()
	s.cleared = PackedStringArray(BELOW + ["last_judgement", "lantern_eye"])
	s.refresh_open()
	t.check(s.open_tier == 5 and s.progress_line(5) == "Ascendance 2 / 5 cleared" and s.progress_line(4) == "Reckoning 3 / 3 cleared: Ascendance is open"
		and not s.all_cleared(), "the last tier counts its five; the tier below reads as before (%s)" % s.progress_line(5))


## An M5-era save (v0.11 M6's final review): written before Ascendance had its three new missions -- Ascendance open, Last Judgement and
## The Long Night cleared, bests on each -- it reads as it was, counts 2 / 5 in the last tier, and writes and reads back the same.
static func _m5_save(t) -> void:
	var path := "user://test_tier5_board.cfg"
	var old := ConfigFile.new()
	old.set_value("descend", "night", 30)
	old.set_value("descend", "believers", 400)
	old.set_value("descend", "open_tier", 5)
	old.set_value("descend", "cleared", BELOW + ["last_judgement", "long_night"])
	old.set_value("descend", "fastest", {"last_judgement": 250.5, "long_night": 300.0})
	old.set_value("descend", "most_wishes", {"long_night": 2})
	old.save(path)
	var kept := SaveFile.new().load_from(path).descend
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))  # at once, so nothing below that may stop the suite leaves it behind
	var again := ConfigFile.new()
	kept.write(again)
	var back := DescendState.read(again)
	t.check(kept.night == 30 and kept.believers == 400 and kept.open_tier == 5 and kept.cleared.size() == BELOW.size() + 2
		and is_equal_approx(float(kept.fastest.get("last_judgement", 0.0)), 250.5) and int(kept.most_wishes.get("long_night", 0)) == 2
		and kept.progress_line(5) == "Ascendance 2 / 5 cleared" and not kept.all_cleared(),
		"an M5-era save reads as it was, Ascendance 2 / 5 (%s)" % kept.progress_line(5))
	t.check(back.night == kept.night and back.believers == kept.believers and back.open_tier == kept.open_tier and back.cleared == kept.cleared
		and back.fastest == kept.fastest and back.most_wishes == kept.most_wishes and back.unlocked == kept.unlocked,
		"and writes and reads back the same")


static func _complete(t) -> void:
	var s := DescendState.new()
	s.cleared = TierBook.all()
	s.refresh_open()
	s.night = 41
	s.believers = 990
	t.check(s.all_cleared() and s.progress_line(5) == "Ascendance 5 / 5 cleared: every tier is cleared"
		and s.progress_line(1) == "Whisper 3 / 3 cleared: Omen is open", "all 25 cleared: every tier is cleared (%s)" % s.progress_line(5))
	var save := SaveFile.new()
	save.descend = s
	var board := MissionBoard.new().setup(save, "last_judgement")
	t.check(board.header_text() == MissionBoard.TEST_HEADER and board.best_line("last_judgement") == "Cleared",
		"the test mode's header is the same with all 25 cleared; the cards keep their ticks (%s)" % board.header_text())
	board.free()
	var short := SaveFile.new()
	short.descend.night = 3
	var b2 := MissionBoard.new().setup(short, "warning")
	t.check(b2.header_text() == MissionBoard.TEST_HEADER, "and before then (the night and believers are no longer shown)")
	b2.free()


static func _waits(t) -> void:
	var waits := {
		"the first mirror": LanternEyeDirector.STEP_AT[0],
		"a drain": LanternEyeDirector.DRAIN,
		"a re-hanging": LanternEyeDirector.REHANG,
		"the Eye's countdown": LanternEyeDirector.EYE_OPENS,
		"a guard's return": LanternEyeDirector.RETURN_AFTER,
		"a guard's relief": LanternEyeDirector.RELIEF_AFTER,
		"the first household": ExodusDirector.OUT_AT[0],
		"the searchers": ExodusDirector.HUNT_AFTER,
		"a watchman's return": ExodusDirector.RETURN_AFTER,
		"a watchman's relief": ExodusDirector.RELIEF_AFTER,
		"the first stage": HeartOfFaithDirector.STAGE_AT[0],
		"a Knight's relief": HeartOfFaithDirector.RELIEF_AFTER,
		"the rite": HeartOfFaithDirector.RITE,
	}
	var chains := {"the next mirror": LanternEyeDirector.CHAIN, "the next household": ExodusDirector.CHAIN,
		"the Temple": HeartOfFaithDirector.CHAIN, "Odran": HeartOfFaithDirector.ODRAN_CHAIN}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	for k: String in chains:
		if float(chains[k]) > 45.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Ascendance's new missions runs over 60 s, and no chain over 45 s (over: %s)" % [long])
	t.check(HeartOfFaithDirector.ODRAN_CHAIN < 45.0, "Odran's chain is never a pure 45 s (M4's captain ruling)")
	# The first waits and the chains pinned at the values Tasks 5-7 landed (deadlines are not counted).
	t.check(is_equal_approx(float(LanternEyeDirector.STEP_AT[0]), 40.0) and is_equal_approx(LanternEyeDirector.CHAIN, 30.0),
		"the first mirror at 0:40, the next every 30 s")
	t.check(is_equal_approx(float(ExodusDirector.OUT_AT[0]), 15.0) and is_equal_approx(ExodusDirector.CHAIN, 25.0),
		"the first household at 0:15, the next every 25 s")
	t.check(is_equal_approx(float(HeartOfFaithDirector.STAGE_AT[0]), 45.0) and is_equal_approx(HeartOfFaithDirector.CHAIN, 45.0)
		and is_equal_approx(HeartOfFaithDirector.ODRAN_CHAIN, 30.0), "the oil-house in use at 0:45, the Temple 45 s on, Odran 30 s after the Temple")


## The people and the buildings `d` has claimed (v0.11 M6).
static func _actors(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	if d is LanternEyeDirector:
		var e := d as LanternEyeDirector
		for st in e.steps:
			for g: HuntDirector.Guard in st.party:
				people.append(g.man)
		for crew: Array in e.wrights:
			for w: HuntDirector.Guard in crew:
				people.append(w.man)
		places.append_array(e.towers)
	elif d is ExodusDirector:
		var x := d as ExodusDirector
		for c in x.charges:
			people.append(c.man)
		people.append_array(x.watch)
		for squad: Array in x.patrols:
			people.append_array(squad)
		for h: ExodusDirector.Household in x.households:
			people.append_array(h.searchers)
			places.append(h.house)
	elif d is HeartOfFaithDirector:
		var h := d as HeartOfFaithDirector
		people.append(h.odran)
		places.append(h.oil_house)
	return {"people": people, "places": places}


static func _reserved(t) -> void:
	for id: String in NEW:
		var a := Kit.world(TierBook.board(id))
		var first := _actors(a.d)
		var people_ix := []
		for p: Variant in first.people:
			people_ix.append((a.crowd as Crowd).citizens.find(p))
		var place_ix := []
		for s: Variant in first.places:
			place_ix.append((a.town as Town)._built.find(s))
		Kit.done(a)
		var hold := func(d: MissionDirector, rules: Rules) -> void:
			for i: int in people_ix:
				if i >= 0:
					d.reserved.append(rules.crowd().citizens[i])
			for i: int in place_ix:
				if i >= 0:
					d.reserved_places.append(rules.town()._built[i])
		var b := Kit.world(TierBook.board(id), null, hold)
		var second := _actors(b.d)
		var clash := []
		for p: Variant in second.people:
			if people_ix.has((b.crowd as Crowd).citizens.find(p)):
				clash.append(p)
		for s: Variant in second.places:
			if s != null and place_ix.has((b.town as Town)._built.find(s)):
				clash.append(s)
		t.check(clash.is_empty() and not second.people.is_empty(),
			"%s: the people and buildings a first night claimed, reserved, are never claimed again (%d clashes)" % [id, clash.size()])
		Kit.done(b)
		var heard := 0
		var hit := 0
		for night in 4:
			var descent := Descent.new().setup(TierBook.board(id), Descent.seed_for(night, id))
			var n := Kit.world(TierBook.board(id), null, func(d: MissionDirector, rules: Rules) -> void: descent.reserve(rules, d))
			var mine := _actors(n.d)
			for w in descent.wishes:
				heard += 1
				for p in w.people():
					hit += 1 if (mine.people as Array).has(p) else 0
				for st in w.places():
					hit += 1 if (mine.places as Array).has(st) else 0
			descent.release()
			Kit.done(n)
		t.check(heard > 0 and hit == 0, "%s: four seeded board nights' wishes, reserved first, never become its people or buildings" % id)


static func _wishes(t) -> void:
	var worlds := {}
	for id: String in ["exodus", "heart_of_faith", "lantern_eye"]:
		worlds[id] = Kit.world(TierBook.board(id))
	var heard := {"exodus": {}, "heart_of_faith": {}, "lantern_eye": {}, "exodus_untagged": {}, "heart_of_faith_untagged": {}}
	for night in 60:
		for id: String in worlds:
			var d := Descent.new().setup(TierBook.board(id), Descent.seed_for(night, id))
			d.hear((worlds[id] as Dictionary).crowd, (worlds[id] as Dictionary).town)
			for w in d.wishes:
				(heard[id] as Dictionary)[w.def.id] = true
			d.release()
		# The controls: the same nights and worlds with the tags taken off. The clashing wishes are then heard, so the empty sets above
		# are the tags' doing, not a draw that never reaches them.
		for id: String in ["exodus", "heart_of_faith"]:
			var bare := TierBook.board(id)
			bare.mission_tags = PackedStringArray()
			var c := Descent.new().setup(bare, Descent.seed_for(night, id))
			c.hear((worlds[id] as Dictionary).crowd, (worlds[id] as Dictionary).town)
			for w in c.wishes:
				(heard[id + "_untagged"] as Dictionary)[w.def.id] = true
			c.release()
	t.check(not (heard.exodus as Dictionary).has("brother") and not (heard.exodus as Dictionary).has("family_out")
		and not (heard.heart_of_faith as Dictionary).has("heretic") and (heard.lantern_eye as Dictionary).has("brother"),
		"sixty draws: Exodus never hears the escape wishes, the Heart never the pyre; The Lantern's Eye hears them (%s / %s / %s)" % [
		(heard.exodus as Dictionary).keys(), (heard.heart_of_faith as Dictionary).keys(), (heard.lantern_eye as Dictionary).keys()])
	t.check(((heard.exodus_untagged as Dictionary).has("brother") or (heard.exodus_untagged as Dictionary).has("family_out"))
		and (heard.heart_of_faith_untagged as Dictionary).has("heretic"),
		"control: with shuts_gates and burns_temple taken off, the same sixty draws do hear the escape wishes and the pyre (%s / %s)" % [
		(heard.exodus_untagged as Dictionary).keys(), (heard.heart_of_faith_untagged as Dictionary).keys()])
	for id: String in worlds:
		Kit.done(worlds[id])


static func _cards(t) -> void:
	var save := SaveFile.new()
	save.descend.open_tier = 5
	var board := MissionBoard.new().setup(save, "lantern_eye")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var long := {}
	for id in board.missions():
		if board.brief_lines(id, room).size() > MissionBoard.BRIEF_LINES:
			long[id] = board.brief_lines(id, room).size()
	t.check(board.tier == 5 and board.missions().size() == 5 and long.is_empty(),
		"Ascendance's tab: five cards, each brief wrapped to %d lines or fewer (over: %s)" % [MissionBoard.BRIEF_LINES, long])
	board.free()
