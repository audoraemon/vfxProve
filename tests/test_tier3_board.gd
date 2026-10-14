extends RefCounted
## v0.11 M4 Tier 3 complete on the board: The Vigil Flame, The Festival and the three new missions, each new one at Tier 3's numbers
## (6:00, 4 / 10, Prepared, no unaware_town, no bonuses, no stretch); three of Wrath's five open Reckoning, and a save that opened it on
## the two ★ missions keeps it (Decision 58); no timed wait over 60 s, no chain over 45 s, the first waits pinned; a board night's wishes
## reserved before each director gathers its people (review focus 6); The Crown's Bread never hears the barn wish (Decision 82); five
## cards on Wrath's tab.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The three new Tier 3 missions.
const NEW := ["crowns_bread", "prisoner", "heretic_hunt"]


static func run(t) -> void:
	_board(t)
	_open(t)
	_waits(t)
	_reserved(t)
	_wishes(t)
	_cards(t)


static func _board(t) -> void:
	for id: String in NEW:
		var m := TierBook.board(id)
		t.check(m != null and m.id == id and m.tier == 3 and is_equal_approx(m.clock, 360.0) and m.slots == 4 and m.dp_capacity == 10
			and m.tier_floor == 3 and not m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "Prepared" and is_equal_approx(m.stretch, 1.0),
			"%s on the board: Tier 3, 6:00, 4 / 10, Prepared, no unaware_town, no bonuses, no stretch" % id)
	t.check(Array(TierBook.missions(3)) == ["vigil_flame", "festival"] + NEW and TierBook.need(3) == 3
		and DescendState.lock_text(4) == "Clear 3 Wrath missions", "Wrath: the ★ missions first, then the three new; three open Reckoning")
	t.check(TierBook.type_of("crowns_bread") == "Destroy" and TierBook.type_of("prisoner") == "Protect"
		and TierBook.type_of("heretic_hunt") == "Protect" and Array(TierBook.board("crowns_bread").mission_tags) == ["razes_bread"]
		and TierBook.board("prisoner").mission_tags.is_empty() and TierBook.board("heretic_hunt").mission_tags.is_empty(),
		"each card's type; The Crown's Bread keeps the barn wish away")


static func _open(t) -> void:
	var s := DescendState.new()
	s.cleared = PackedStringArray(["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns", "bell_ringers",
		"vigil_flame", "festival"])
	s.refresh_open()
	t.check(s.open_tier == 3 and s.progress_line(3) == "Wrath 2 / 3 cleared: one more opens Reckoning",
		"two of Wrath's five leave Reckoning shut (%s)" % s.progress_line(3))
	s.cleared.append("prisoner")
	t.check(s.refresh_open() == 4 and s.open_tier == 4, "three of them open Reckoning")
	var path := "user://test_tier3_board.cfg"
	var old := ConfigFile.new()
	old.set_value("descend", "open_tier", 4)
	old.set_value("descend", "cleared", ["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns", "bell_ringers",
		"vigil_flame", "festival"])
	var saved := old.save(path)
	var loaded := SaveFile.new().load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))  # gone before any check reads it, so a failure leaves no file behind
	var kept: DescendState = loaded.descend if saved == OK and loaded != null else null
	if kept != null:
		kept.refresh_open()
	t.check(kept != null and kept.open_tier == 4 and kept.is_open(4) and kept.progress_line(3) == "Wrath 2 / 3 cleared: Reckoning is open",
		"a save that opened Reckoning on Wrath's two ★ missions keeps it open: a tier never closes (Decision 58)")


static func _waits(t) -> void:
	var waits := {
		"the granary's stage": CrownsBreadDirector.STAGE_AT[0],
		"an engineer's return": CrownsBreadDirector.RETURN_AFTER,
		"an engineer's relief": CrownsBreadDirector.RELIEF_AFTER,
		"a rebuild with one engineer": CrownsBreadDirector.REBUILD_ONE,
		"the Citadel's hounds": PrisonerDirector.HUE_AFTER,
		"the postern's change": EscortDirector.WATCH_CHANGE,
		"the postern clear": EscortDirector.WATCH_GAP,
		"between changes": EscortDirector.WATCH_CYCLE - EscortDirector.WATCH_GAP,
		"the first sweep": HereticHuntDirector.STEP_AT[0],
		"a guard's return": HereticHuntDirector.RETURN_AFTER,
		"a guard's relief": HereticHuntDirector.RELIEF_AFTER,
		"a door searched": HereticHuntDirector.CAPTAIN_STOP,
	}
	var chains := {"the next target": CrownsBreadDirector.CHAIN, "the next sweep": HereticHuntDirector.CHAIN, "the captain": HereticHuntDirector.HEAD_CHAIN}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	for k: String in chains:
		if float(chains[k]) > 45.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Wrath's new missions runs over 60 s, and no chain over 45 s (over: %s)" % [long])
	# The first waits and the chains pinned exactly at their tuned values (M3's deferred minor: _waits bounded them only). The Prisoner's
	# 2:00 FREE_BY is a deadline, not a wait, so it is not among them.
	t.check(is_equal_approx(float(CrownsBreadDirector.STAGE_AT[0]), 45.0), "the first wait as tuned: the granary 0:45")
	t.check(is_equal_approx(float(HereticHuntDirector.STEP_AT[0]), 60.0), "the first wait as tuned: the first sweep 1:00")
	t.check(is_equal_approx(PrisonerDirector.HUE_AFTER, 30.0), "the first wait as tuned: the hounds 0:30")
	t.check(is_equal_approx(EscortDirector.WATCH_CHANGE, 30.0), "the first wait as tuned: the postern's change 0:30")
	t.check(is_equal_approx(CrownsBreadDirector.CHAIN, 45.0) and is_equal_approx(HereticHuntDirector.CHAIN, 45.0)
		and is_equal_approx(HereticHuntDirector.HEAD_CHAIN, 30.0), "the chains as tuned: the bread's and the sweeps' 45 s, the captain's 30 s")


## The people and the buildings `d` has claimed (v0.11 M4).
static func _actors(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	if d is CrownsBreadDirector:
		var cb := d as CrownsBreadDirector
		for list: Array in cb.crews:
			for c: CrownsBreadDirector.Crew in list:
				people.append(c.man)
		places.append(cb.waiting_in[2])
	elif d is PrisonerDirector:
		var pr := d as PrisonerDirector
		people.append(pr.charge)
		people.append_array(pr._watchers())
		people.append_array(pr.searchers)
	elif d is HereticHuntDirector:
		var hh := d as HereticHuntDirector
		for st in hh.steps:
			for g: HuntDirector.Guard in st.party:
				people.append(g.man)
		people.append(hh.head)
		people.append_array(hh.escorts)
		places.append(hh.cellar)
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
	var a := Kit.world(TierBook.board("crowns_bread"))
	var b := Kit.world(TierBook.board("prisoner"))
	var bare := TierBook.board("crowns_bread")
	bare.mission_tags = PackedStringArray()
	var heard := {}
	var control := {}
	var untagged := {}
	for night in 60:
		for row: Array in [[TierBook.board("crowns_bread"), a, heard], [TierBook.board("prisoner"), b, control], [bare, a, untagged]]:
			var def: MissionDef = row[0]
			var d := Descent.new().setup(def, Descent.seed_for(night, def.id))
			d.hear((row[1] as Dictionary).crowd, (row[1] as Dictionary).town)
			for w in d.wishes:
				(row[2] as Dictionary)[w.def.id] = true
			d.release()
	t.check(not heard.has("barn") and not heard.is_empty() and control.has("barn") and control.has("sergeant"),
		"sixty draws on The Crown's Bread's night never hear the barn wish; The Prisoner's do, and the sergeant (%s / %s)" % [
		heard.keys(), control.keys()])
	t.check(untagged.has("barn"), "the control: the same sixty draws on The Crown's Bread's own night, its tags cleared, hear it (%s)" % [
		untagged.keys()])
	Kit.done(a)
	Kit.done(b)


static func _cards(t) -> void:
	var save := SaveFile.new()
	save.descend.open_tier = 3
	var board := MissionBoard.new().setup(save, "crowns_bread")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var long := {}
	for id in board.missions():
		if board.brief_lines(id, room).size() > MissionBoard.BRIEF_LINES:
			long[id] = board.brief_lines(id, room).size()
	t.check(board.tier == 3 and board.missions().size() == 5 and long.is_empty(),
		"Wrath's tab: five cards, each brief wrapped to %d lines or fewer (over: %s)" % [MissionBoard.BRIEF_LINES, long])
	board.free()
