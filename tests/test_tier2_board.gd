extends RefCounted
## v0.11 M3 Tier 2 complete on the board: Mira's House, Broken Lanterns and the three new missions, each new one at Tier 2's numbers
## (5:30, 3 / 8, Organized, no unaware_town, no bonuses, no stretch); three of Omen's five open Wrath, and a save that opened Wrath
## on the two ★ missions keeps it (Decision 2); no timed wait over 60 s, no chain over 45 s; a board night's wishes reserved before
## each director gathers its people (review focus 3); The Informer's night never hears the informer wish; five cards on Omen's tab.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The three new Tier 2 missions.
const NEW := ["bell_ringers", "market_panic", "informer"]


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
		t.check(m != null and m.id == id and m.tier == 2 and is_equal_approx(m.clock, 330.0) and m.slots == 3 and m.dp_capacity == 8
			and m.tier_floor == 2 and not m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "Organized" and is_equal_approx(m.stretch, 1.0),
			"%s on the board: Tier 2, 5:30, 3 / 8, Organized, no unaware_town, no bonuses, no stretch" % id)
	t.check(Array(TierBook.missions(2)) == ["miras_house", "broken_lanterns"] + NEW and TierBook.need(2) == 3
		and DescendState.lock_text(3) == "Clear 3 Omen missions", "Omen: the ★ missions first, then the three new; three open Wrath")
	t.check(TierBook.type_of("bell_ringers") == "Intercept" and TierBook.type_of("market_panic") == "Break"
		and TierBook.type_of("informer") == "Kill" and Array(TierBook.board("informer").mission_tags) == ["hunts_informer"],
		"each card's type; The Informer keeps the informer wish away")


static func _open(t) -> void:
	var s := DescendState.new()
	s.cleared = PackedStringArray(["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns"])
	s.refresh_open()
	t.check(s.open_tier == 2 and s.progress_line(2) == "Omen 2 / 3 cleared: one more opens Wrath",
		"two of Omen's five leave Wrath shut (%s)" % s.progress_line(2))
	s.cleared.append("informer")
	t.check(s.refresh_open() == 3 and s.open_tier == 3, "three of them open Wrath")
	var path := "user://test_tier2_board.cfg"
	var old := ConfigFile.new()
	old.set_value("descend", "open_tier", 3)
	old.set_value("descend", "cleared", ["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns"])
	old.save(path)
	var kept := SaveFile.new().load_from(path).descend
	kept.refresh_open()
	t.check(kept.open_tier == 3 and kept.is_open(3) and kept.progress_line(2) == "Omen 2 / 3 cleared: Wrath is open",
		"a save that opened Wrath on Omen's two ★ missions keeps it open: a tier never closes (Decision 2)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _waits(t) -> void:
	var waits := {
		"the first ringer sets out": BellRingersDirector.SET_OUT_AT[0],
		"the ringers light their lanterns": RingerDirector.OUT_PAUSE,
		"a ringer's climb": ResponseProfile.for_level(2).bell_climb * BellNetwork.ESCORT_CLIMB,
		"a climber pulled off tries again": BellNetwork.RETRY,
		"the first crowd": MarketPanicDirector.WAVE_AT[0],
		"a warden's return": HarvestDirector.RETURN_AFTER,
		"a warden's relief": HarvestDirector.RELIEF_AFTER,
		"the first visit": InformerDirector.VISIT_AT[0],
		"his hiding": InformerDirector.HIDE_SECONDS,
		"the names after the third visit": InformerDirector.FOUND_LIMIT,
		"a whisper seen, before the contact hears another": Person.SHAKE_OFF + MindWhisperFx.LINGER,
		"Free the pressed man's clock": RescueWish.SECONDS,
	}
	var chains := {"the next post": BellRingersDirector.CHAIN_WAIT, "the next crowd": MarketPanicDirector.CHAIN,
		"the next visit": InformerDirector.CHAIN_WAIT}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	for k: String in chains:
		if float(chains[k]) > 45.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Omen's new missions runs over 60 s, and no chain over 45 s (over: %s)" % [long])
	t.check(is_equal_approx(float(BellRingersDirector.SET_OUT_AT[0]), 40.0) and is_equal_approx(float(MarketPanicDirector.WAVE_AT[0]), 0.0)
		and is_equal_approx(float(InformerDirector.VISIT_AT[0]), 45.0),
		"the first waits pinned (v0.11 M3 final review): the first ringer at 0:40, the first crowd at once, the first visit at 0:45")


## The people and the buildings `d` has claimed (v0.11 M3).
static func _actors(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	if d is BellRingersDirector:
		for r in (d as BellRingersDirector).ringers:
			people.append(r.watchman)
			people.append_array(r.mates)
		places.append_array((d as BellRingersDirector).posts)
	elif d is MarketPanicDirector:
		people.append_array((d as MarketPanicDirector).goers)
		for w in (d as MarketPanicDirector).wards:
			people.append(w.man)
	elif d is InformerDirector:
		var inf := d as InformerDirector
		for c in inf.contacts:
			people.append(c.man)
			people.append_array(c.company)
			places.append(c.house)
		people.append(inf.quarries[0].target)
		places.append(inf.lodging)
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
			if place_ix.has((b.town as Town)._built.find(s)):
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
	var a := Kit.world(TierBook.board("informer"))
	var b := Kit.world(TierBook.board("market_panic"))
	var heard := {}
	var control := {}
	for night in 60:
		for pair: Array in [["informer", a, heard], ["market_panic", b, control]]:
			var d := Descent.new().setup(TierBook.board(pair[0]), Descent.seed_for(night, pair[0]))
			d.hear((pair[1] as Dictionary).crowd, (pair[1] as Dictionary).town)
			for w in d.wishes:
				(pair[2] as Dictionary)[w.def.id] = true
			d.release()
	t.check(not heard.has("informer") and not heard.is_empty() and control.has("informer") and control.has("bully")
		and control.has("pressed"), "sixty draws on The Informer's night never hear the informer wish; Market Panic's do, and Omen's two (%s / %s)" % [
		heard.keys(), control.keys()])
	Kit.done(a)
	Kit.done(b)


static func _cards(t) -> void:
	var save := SaveFile.new()
	save.descend.open_tier = 2
	var board := MissionBoard.new().setup(save, "bell_ringers")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var long := {}
	for id in board.missions():
		if board.brief_lines(id, room).size() > MissionBoard.BRIEF_LINES:
			long[id] = board.brief_lines(id, room).size()
	t.check(board.tier == 2 and board.missions().size() == 5 and long.is_empty(),
		"Omen's tab: five cards, each brief wrapped to %d lines or fewer (over: %s)" % [MissionBoard.BRIEF_LINES, long])
	board.free()
