extends RefCounted
## v0.11 M5 Tier 4 complete on the board: The Procession and the four new missions, each new one at Tier 4's numbers (6:30, 5 / 13,
## God-Resistant, no unaware_town, no bonuses, no stretch); three of Reckoning's five open Ascendance, and a save that opened it on The
## Procession alone keeps it (Decision 122); no timed wait over 60 s, no chain over 45 s, the first waits pinned; a board night's wishes
## reserved before each director gathers its people (review focus 5); The Bishop never hears the pyre, The Armoury never the pressed
## man (Decision 161); five cards on Reckoning's tab.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The four new Tier 4 missions.
const NEW := ["bishop", "armoury", "sermon", "relic_run"]


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
		t.check(m != null and m.id == id and m.tier == 4 and is_equal_approx(m.clock, 390.0) and m.slots == 5 and m.dp_capacity == 13
			and m.tier_floor == 4 and not m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "God-Resistant" and is_equal_approx(m.stretch, 1.0),
			"%s on the board: Tier 4, 6:30, 5 / 13, God-Resistant, no unaware_town, no bonuses, no stretch" % id)
	t.check(Array(TierBook.missions(4)) == ["procession"] + NEW and TierBook.need(4) == 3
		and DescendState.lock_text(5) == "Clear 3 Reckoning missions", "Reckoning: the ★ mission first, then the four new; three open Ascendance")
	t.check(TierBook.type_of("bishop") == "Kill" and TierBook.type_of("armoury") == "Destroy" and TierBook.type_of("sermon") == "Cult"
		and TierBook.type_of("relic_run") == "Cult" and Array(TierBook.board("bishop").mission_tags) == ["burns_temple"]
		and Array(TierBook.board("armoury").mission_tags) == ["razes_barracks"] and TierBook.board("sermon").mission_tags.is_empty()
		and TierBook.board("relic_run").mission_tags.is_empty(), "each card's type; The Bishop and The Armoury keep their clashing wishes away")


## Three cleared of each tier below Reckoning (v0.11 M5 tests).
const BELOW := ["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns", "bell_ringers", "vigil_flame", "festival",
	"crowns_bread"]


static func _open(t) -> void:
	var s := DescendState.new()
	s.cleared = PackedStringArray(BELOW + ["procession", "bishop"])
	s.refresh_open()
	t.check(s.open_tier == 4 and s.progress_line(4) == "Reckoning 2 / 3 cleared: one more opens Ascendance",
		"two of Reckoning's five leave Ascendance shut (%s)" % s.progress_line(4))
	s.cleared.append("armoury")
	t.check(s.refresh_open() == 5 and s.open_tier == 5, "three of them open Ascendance")
	var path := "user://test_tier4_board.cfg"
	var old := ConfigFile.new()
	old.set_value("descend", "open_tier", 5)
	old.set_value("descend", "cleared", BELOW + ["procession"])
	old.save(path)
	var kept := SaveFile.new().load_from(path).descend
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))  # at once, so nothing below that may stop the suite leaves it behind
	kept.refresh_open()
	t.check(kept.open_tier == 5 and kept.is_open(5) and kept.progress_line(4) == "Reckoning 1 / 3 cleared: Ascendance is open",
		"a save that opened Ascendance on The Procession alone keeps it open: a tier never closes (Decision 122)")


static func _waits(t) -> void:
	var waits := {
		"the bishop goes to ground": BishopDirector.ARRIVE_AT,
		"a Knight's relief": BishopDirector.RELIEF_AFTER,
		"the first horn": ArmouryDirector.STAGE_AT[0],
		"an armed man's return": ArmouryDirector.RETURN_AFTER,
		"an armed man's relief": ArmouryDirector.RELIEF_AFTER,
		"the slowest reinforcement": (ArmouryDirector.REINFORCE as Array).max(),
		"a reading": SermonDirector.READ,
		"a sentry's return": SermonDirector.RETURN_AFTER,
		"a sentry's relief": SermonDirector.RELIEF_AFTER,
		"the first wave": (SermonDirector.WAVE_AT as Array).min(),
		"the relic sets out": RelicRunDirector.SET_OUT_AT,
		"the longest halt": RelicRunDirector.HALT_MAX,
		"the count": RelicRunDirector.COUNT,
		"a warden's return": RelicRunDirector.RETURN_AFTER,
		"a warden's relief": RelicRunDirector.RELIEF_AFTER,
	}
	var chains := {"his flight": BishopDirector.CHAIN, "the next horn": ArmouryDirector.CHAIN, "the next wave": SermonDirector.CHAIN}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	for k: String in chains:
		if float(chains[k]) > 45.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Reckoning's new missions runs over 60 s, and no chain over 45 s (over: %s)" % [long])
	# The deadlines (the Knights' 5:00, the garrison's march, the sermon's end) are the clock's, not waits. The first waits and the chains
	# pinned exactly at the values Tasks 2-5's gates landed.
	t.check(is_equal_approx(BishopDirector.ARRIVE_AT, 45.0) and is_equal_approx(BishopDirector.CHAIN, 45.0)
		and is_equal_approx(ArmouryDirector.CHAIN, 40.0) and Array(ArmouryDirector.STAGE_AT) == [40.0, 110.0, 180.0]
		and Array(SermonDirector.WAVE_AT) == [0.0, 95.0, 185.0, 260.0] and is_equal_approx(SermonDirector.CHAIN, 45.0)
		and is_equal_approx(RelicRunDirector.SET_OUT_AT, 45.0) and is_equal_approx(RelicRunDirector.HALT_MAX, 50.0),
		"the first waits and the chains as tuned: the bishop 0:45 then 45, the horns 0:40 / 1:50 / 3:00 then 40, the first wave at once then 45, the cart 0:45 with halts up to 50")


## The people and the buildings `d` has claimed (v0.11 M5).
static func _actors(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	if d is BishopDirector:
		var b := d as BishopDirector
		people.append(b.quarries[0].target)
		places.append_array(b.refuges.slice(0, 2))
	elif d is ArmouryDirector:
		var a := d as ArmouryDirector
		for list: Array in a.armed:
			for x: ArmouryDirector.Armed in list:
				people.append(x.man)
		people.append_array(a.reserve)
		places.append_array(a.targets.slice(0, 2))
	elif d is SermonDirector:
		var se := d as SermonDirector
		for l: SermonDirector.Listener in se.listeners:
			people.append(l.man)
		people.append(se.preacher)
		people.append_array(se.acolytes)
		for st: SermonDirector.Sentry in se.sentries:
			people.append(st.man)
		places.append(se.house)
	elif d is RelicRunDirector:
		var r := d as RelicRunDirector
		people.append_array([r.wren, r.carter])
		people.append_array(r.escorts)
		for w: RelicRunDirector.Warden in r.wardens:
			people.append(w.man)
		places.append(r.drop_house)
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
	for id: String in ["bishop", "armoury", "sermon"]:
		worlds[id] = Kit.world(TierBook.board(id))
	var heard := {"bishop": {}, "armoury": {}, "sermon": {}, "bishop_untagged": {}, "armoury_untagged": {}}
	for night in 60:
		for id: String in worlds:
			var d := Descent.new().setup(TierBook.board(id), Descent.seed_for(night, id))
			d.hear((worlds[id] as Dictionary).crowd, (worlds[id] as Dictionary).town)
			for w in d.wishes:
				(heard[id] as Dictionary)[w.def.id] = true
			d.release()
		# The controls: the same two nights and worlds with the tags taken off. The clashing wishes are then heard, so the empty sets
		# above are the tags' doing, not a draw that never reaches them.
		for id: String in ["bishop", "armoury"]:
			var bare := TierBook.board(id)
			bare.mission_tags = PackedStringArray()
			var c := Descent.new().setup(bare, Descent.seed_for(night, id))
			c.hear((worlds[id] as Dictionary).crowd, (worlds[id] as Dictionary).town)
			for w in c.wishes:
				(heard[id + "_untagged"] as Dictionary)[w.def.id] = true
			c.release()
	t.check(not (heard.bishop as Dictionary).has("heretic") and not (heard.armoury as Dictionary).has("pressed")
		and (heard.sermon as Dictionary).has("heretic") and (heard.sermon as Dictionary).has("pressed") and (heard.sermon as Dictionary).has("family_out"),
		"sixty draws: The Bishop never hears the pyre, The Armoury never the pressed man; The Sermon hears all three (%s / %s / %s)" % [
		(heard.bishop as Dictionary).keys(), (heard.armoury as Dictionary).keys(), (heard.sermon as Dictionary).keys()])
	t.check((heard.bishop_untagged as Dictionary).has("heretic") and (heard.armoury_untagged as Dictionary).has("pressed"),
		"control: with burns_temple and razes_barracks taken off, the same sixty draws do hear the pyre and the pressed man (%s / %s)" % [
		(heard.bishop_untagged as Dictionary).keys(), (heard.armoury_untagged as Dictionary).keys()])
	for id: String in worlds:
		Kit.done(worlds[id])


static func _cards(t) -> void:
	var save := SaveFile.new()
	save.descend.open_tier = 4
	var board := MissionBoard.new().setup(save, "bishop")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var long := {}
	for id in board.missions():
		if board.brief_lines(id, room).size() > MissionBoard.BRIEF_LINES:
			long[id] = board.brief_lines(id, room).size()
	t.check(board.tier == 4 and board.missions().size() == 5 and long.is_empty(),
		"Reckoning's tab: five cards, each brief wrapped to %d lines or fewer (over: %s)" % [MissionBoard.BRIEF_LINES, long])
	board.free()
