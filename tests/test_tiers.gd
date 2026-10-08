extends RefCounted
## v0.11 M1 the tiers (spec §3-§4): each tier's numbers as the spec's table gives them, its missions, the unlocking rule with
## the short-tier rule, the upgrade prices, banking a night won, lost or caught, and the [descend] save -- a round trip, a
## hand-edited file, and a v0.10 save's board wins carried over (review focus 3's counter only moves when banked).


static func run(t) -> void:
	_table(t)
	_unlock(t)
	_prices(t)
	_bank(t)
	_save(t)


static func _table(t) -> void:
	t.check(Array(TierBook.NAMES) == ["Whisper", "Omen", "Wrath", "Reckoning", "Ascendance"], "the five tiers' names")
	var rows := []
	for tier in range(1, 6):
		rows.append([TierBook.readiness(tier), TierBook.slots(tier), TierBook.dp(tier), TierBook.clock(tier),
			TierBook.wishes(tier), TierBook.multiplier(tier)])
	t.check(rows == [[1, 3, 6, 300.0, 2, 1.0], [2, 3, 8, 330.0, 2, 1.5], [3, 4, 10, 360.0, 3, 2.0], [4, 5, 13, 390.0, 3, 2.5],
		[4, 6, 16, 420.0, 3, 3.0]], "each tier's readiness, slots, DP, clock, wishes and multiplier (spec §4) (%s)" % [rows])
	t.check(Array(TierBook.missions(1)) == ["warning"] and Array(TierBook.missions(2)) == ["miras_house", "broken_lanterns"]
		and Array(TierBook.missions(3)) == ["vigil_flame", "festival"] and Array(TierBook.missions(4)) == ["procession"]
		and Array(TierBook.missions(5)) == ["last_judgement", "long_night"], "the eight ★ missions on their tiers (spec §8)")
	t.check(TierBook.all().size() == 8 and TierBook.tier_of("festival") == 3 and TierBook.tier_of("feast_festival") == 0
		and not TierBook.has("feast_festival") and TierBook.has("long_night"), "found by id; the campaign's Feast is not one")
	var needs := []
	for tier in range(1, 6):
		needs.append(TierBook.need(tier))
	t.check(needs == [1, 2, 2, 1, 2], "while tiers are short, all of a tier's missions open the next (%s)" % [needs])
	t.check(TierBook.believers(10, 1) == 10 and TierBook.believers(15, 2) == 23 and TierBook.believers(10, 5) == 30
		and TierBook.believers(5, 4) == 13, "believers times the multiplier, rounded")
	t.check(TierBook.type_of("warning") == "Intercept" and TierBook.type_of("last_judgement") == "Destroy"
		and TierBook.type_of("nowhere") == "", "each card's type")
	t.check(TierBook.mission_tags("warning").is_empty() and Array(TierBook.mission_tags("miras_house")) == ["spares_houses"]
		and TierBook.mission_tags("festival").is_empty(), "the mission tags declared (v0.11 M2: unaware_town is derived in board())")


static func _unlock(t) -> void:
	var s := DescendState.new()
	t.check(s.open_tier == 1 and s.is_open(1) and not s.is_open(2) and not s.is_open(0), "Tier 1 is open from the start")
	t.check(DescendState.lock_text(2) == "Clear 1 Whisper mission" and DescendState.lock_text(3) == "Clear 2 Omen missions",
		"a locked tier's rule (%s; %s)" % [DescendState.lock_text(2), DescendState.lock_text(3)])
	s.cleared.append("warning")
	t.check(s.refresh_open() == 2 and s.open_tier == 2, "The Warning cleared opens Omen")
	s.cleared.append("miras_house")
	t.check(s.refresh_open() == 0 and s.open_tier == 2, "one of Omen's two does not open Wrath")
	s.cleared.append("broken_lanterns")
	t.check(s.refresh_open() == 3 and s.open_tier == 3, "both open it")
	s.cleared.clear()
	t.check(s.refresh_open() == 0 and s.open_tier == 3, "a tier never closes again")
	var far := DescendState.new()
	far.cleared = PackedStringArray(["warning", "miras_house", "broken_lanterns", "vigil_flame", "festival", "procession"])
	t.check(far.refresh_open() == 5 and far.open_tier == 5, "tiers open one after another, up to Ascendance")
	t.check(far.progress_line(1) == "Whisper 1 / 1 cleared: Omen is open" and s.progress_line(3) == "Wrath 0 / 2 cleared: 2 more open Reckoning"
		and far.progress_line(5) == "Ascendance 0 / 2 cleared", "the results' tier line (%s; %s)" % [far.progress_line(1), s.progress_line(3)])
	var one := DescendState.new()
	one.cleared.append("warning")
	one.refresh_open()
	one.cleared.append("miras_house")
	t.check(one.progress_line(2) == "Omen 1 / 2 cleared: one more opens Wrath", "one more (%s)" % one.progress_line(2))


static func _prices(t) -> void:
	var s := DescendState.new()
	var starting := 0
	for key in PowerBook.keys():
		starting += 1 if DescendState.starting(key) else 0
	t.check(starting == 15 and s.locked().size() == PowerBook.keys().size() - 15, "the 1 and 2 DP powers start unlocked: 15")
	t.check(s.is_unlocked("doom") and s.is_unlocked("heaven") and not s.is_unlocked("tsunami"), "Heaven Splitter (2 DP) is; Tsunami (4) is not")
	t.check(DescendState.unlock_price("tornado") == 45 and DescendState.unlock_price("tsunami") == 60
		and DescendState.unlock_price("voice") == 75 and DescendState.unlock_price("schism") == 90, "unlocking costs 15 x its DP")
	t.check(s.dp_price() == 25 and s.refusal("dp") == "believers" and not s.buy("dp"), "the first +1 DP is 25: too few believers")
	s.believers = 25
	t.check(s.buy("dp") and s.dp_bought == 1 and s.believers == 0 and s.dp_price() == 50, "bought for 25; the second is 50")
	s.believers = 10000
	for i in 5:
		s.buy("dp")
	t.check(s.dp_bought == DescendState.DP_LIMIT and s.refusal("dp") == "limit" and not s.buy("dp"), "six at most")
	t.check(s.buy("slot") and s.slot_bought == 1 and s.refusal("slot") == "limit", "one slot, once")
	var before := s.believers
	t.check(s.buy("tsunami") and s.unlocked.has("tsunami") and s.believers == before - 60 and s.refusal("tsunami") == "owned",
		"a power unlocked for its price, once")
	t.check(s.refusal("heaven") == "owned" and s.refusal("frog") == "unknown", "a starting power is owned; an unknown one refused")


static func _bank(t) -> void:
	var s := DescendState.new()
	var won := s.bank("warning", {"main": true, "main_time": 200.0, "earned": 10, "kept": 0})
	t.check(s.night == 1 and s.believers == 10 and s.cleared.has("warning") and bool(won.first_clear) and int(won.opened) == 2
		and String(won.progress) == "Whisper 1 / 1 cleared: Omen is open", "a night won: counted, banked, cleared, Omen open (%s)" % [won])
	t.check(Array(won.bests) == ["Fastest clear 3:20"] and is_equal_approx(float(s.fastest.warning), 200.0), "its time is a best")
	var lost := s.bank("warning", {"main": false, "main_time": 0.0, "earned": 0, "kept": 0})
	t.check(s.night == 2 and s.believers == 10 and not bool(lost.cleared) and (lost.bests as PackedStringArray).is_empty()
		and int(lost.night) == 2 and int(lost.total) == 10, "a night lost still counts, banks nothing")
	var slow := s.bank("warning", {"main": true, "main_time": 250.0, "earned": 10, "kept": 2})
	t.check(s.believers == 20 and not bool(slow.first_clear) and Array(slow.bests) == ["Most wishes granted: 2"]
		and int(s.most_wishes.warning) == 2, "a slower clear is no best; two wishes banked are")
	t.check(s.bank("warning", {"earned": -5}).believers == 0 and s.believers == 20, "a negative purse banks nothing")


static func _save(t) -> void:
	var path := "user://test_tiers.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	t.check(SaveFile.new().load_from(path).descend.night == 0, "no file: a fresh board")
	var save := SaveFile.new()
	save.descend.night = 4
	save.descend.believers = 77
	save.descend.cleared = PackedStringArray(["warning", "miras_house"])
	save.descend.dp_bought = 2
	save.descend.slot_bought = 1
	save.descend.unlocked = PackedStringArray(["tsunami"])
	save.descend.fastest = {"warning": 190.5}
	save.descend.most_wishes = {"warning": 2}
	save.descend.refresh_open()
	save.last_mission = "festival"
	save.save_to(path)
	var back := SaveFile.new().load_from(path).descend
	t.check(back.night == 4 and back.believers == 77 and Array(back.cleared) == ["warning", "miras_house"] and back.open_tier == 2
		and back.dp_bought == 2 and back.slot_bought == 1 and Array(back.unlocked) == ["tsunami"]
		and is_equal_approx(float(back.fastest.warning), 190.5) and int(back.most_wishes.warning) == 2, "the board comes back from the file")
	t.check(SaveFile.new().load_from(path).last_mission == "festival", "a board id is a mission the board remembers")

	var odd := ConfigFile.new()
	odd.set_value("descend", "night", -3)
	odd.set_value("descend", "open_tier", 9)
	odd.set_value("descend", "cleared", ["warning", "frog", "warning"])
	odd.set_value("descend", "dp_bought", 40)
	odd.set_value("descend", "unlocked", ["doom", "frog", "nova"])
	odd.set_value("descend", "fastest", {"frog": 5.0, "warning": "fast"})
	odd.set_value("descend", "most_wishes", 7)
	odd.save(path)
	var fixed := SaveFile.new().load_from(path).descend
	t.check(fixed.night == 0 and fixed.open_tier == 5 and Array(fixed.cleared) == ["warning"] and fixed.dp_bought == DescendState.DP_LIMIT
		and Array(fixed.unlocked) == ["nova"] and fixed.fastest.is_empty() and fixed.most_wishes.is_empty(),
		"a hand-edited board is pulled back into range, the unknown dropped")

	# A v0.10 save (spec §3.5): no [descend]; its board wins carry over as cleared, with no time.
	var old := ConfigFile.new()
	old.set_value("kak", "last_mission", "warning")
	old.set_value("mission.warning", "won", true)
	old.set_value("mission.last_judgement", "won", true)
	old.set_value("mission.last_judgement", "best_score", 9000)
	old.set_value("mission.long_night", "won", false)
	old.save(path)
	var carried := SaveFile.new().load_from(path).descend
	t.check(Array(carried.cleared) == ["warning", "last_judgement"] and carried.open_tier == 2 and carried.fastest.is_empty()
		and carried.night == 0 and carried.believers == 0, "a v0.10 save's wins carry over as cleared, Omen open, no time (%s)" % [carried.cleared])
	var with := ConfigFile.new()
	with.set_value("mission.warning", "won", true)
	with.set_value("descend", "night", 1)
	with.save(path)
	t.check(SaveFile.new().load_from(path).descend.cleared.is_empty(), "a save with its own [descend] carries nothing over")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
