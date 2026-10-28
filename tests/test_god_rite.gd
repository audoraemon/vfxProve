extends RefCounted
## God P3 Task 1 (mission spec MS §1, §4, §5; parent spec §9.3; plan Rulings P3-1 to P3-6, pre-flight B1): the Awaken rite's rules -- RiteBook's
## rows, when Awaken is offered, the rite's def at the god's numbers, the stolen gifts copied onto every later night's def (and never onto the
## board's), a rite banked won (tier + 1, +2 points, the gift once, Notice unchanged) or lost (Notice +25, still capped), an abandoned rite, and
## a rite left by closing the game still reading back as open. Keys come from the merged tree at test time (C2).

const FILE := "user://test_god_rite_%s.cfg"


static func run(t) -> void:
	GodTree.dev_fill = true
	_rite_book(t)
	_awaken_state(t)
	_rite_def(t)
	_gifts_copied(t)
	_board_no_gifts(t)
	_steal(t)
	_bank_rite_won(t)
	_bank_rite_twice(t)
	_bank_rite_lost(t)
	_forfeit_rite(t)
	_rite_draw_untouched(t)
	_rite_beats_hunt_flag(t)
	_mission_book_rite(t)
	_read_rite_in_night(t)
	GodTree.dev_fill = false


## The first ring type with two starting keys: "" when none, which the first check reports.
static func _type() -> String:
	for type: String in GodTree.RING:
		if GodTree.starting(type).size() >= 2:
			return type
	return ""


## A Tier 1 god at the cap with a full bar: the rite's fixture.
static func _slot(seed_value := 5) -> GodSlot:
	var s := GodSlot.make(1, _type(), seed_value)
	s.level = s.cap()
	s.divine_power = s.need()
	return s


static func _outcome(won: bool, shards := 0) -> Dictionary:
	return {"won": won, "rite": {"shards": shards}}


static func _rite_book(t) -> void:
	t.check(RiteBook.has("first_taste") and not RiteBook.has("warning") and not RiteBook.has(""), "RiteBook.has: the first rite only")
	t.check(String(RiteBook.at_level(10).get("id", "")) == "first_taste", "at_level(10) is The First Taste (%s)" % [RiteBook.at_level(10)])
	t.check(RiteBook.at_level(20) == {} and RiteBook.at_level(1) == {}, "no rite at level 20 or 1 in P3")
	t.check(RiteBook.row("x") == {}, "row of an unknown id is empty")
	var r := RiteBook.row("first_taste")
	t.check(r.shards == 3 and r.victims == 5 and r.gift == RiteBook.WATCHFUL_BELL and r.level == 10 and r.name == "The First Taste",
		"the first rite's numbers (%s)" % [r])
	r["shards"] = 99
	t.check(int(RiteBook.row("first_taste").shards) == 3, "row() is a copy")
	var lines := RiteBook.plate_lines("first_taste")
	t.check(lines.size() == 3 and lines[0] == "AWAKENED - OMEN" and lines[1] == "+2 ability points"
		and lines[2] == "Stolen: The Watchful Bell - a bell ringer takes 20% longer to start the toll", "the win plate's lines (%s)" % [lines])
	t.check(RiteBook.plate_lines("warning").is_empty(), "no plate for a non-rite")
	t.check(RiteBook.gift_name(RiteBook.WATCHFUL_BELL) == "The Watchful Bell" and RiteBook.gift_effect(RiteBook.WATCHFUL_BELL) == "The bell takes 20% longer to ring",
		"the gift's name and effect")
	t.check(RiteBook.gift_name("nosuch") == "" and RiteBook.gift_effect("nosuch") == "", "an unknown gift has no name or effect")
	t.check(RiteBook.climb_scale(PackedStringArray()) == 1.0, "no gifts: the climb scale is exactly 1.0")
	t.check(RiteBook.climb_scale(PackedStringArray([RiteBook.WATCHFUL_BELL])) == 1.2, "the Watchful Bell: 1.2")
	t.check(RiteBook.climb_scale(PackedStringArray(["nosuch"])) == 1.0, "an unknown gift: 1.0")
	t.check(RiteBook.def("first_taste") != null and RiteBook.def("first_taste").id == "first_taste", "def() builds the rite")
	t.check(RiteBook.def("warning") == null, "def() of a non-rite is null")


static func _awaken_state(t) -> void:
	t.check(_type() != "", "a fixture type with two starting keys exists in the merged tree")
	var s := _slot()
	s.level = 9
	t.check(GodNight.awaken_state(s) == "" and GodNight.rite_for(s).is_empty(), "level 9: no Awaken")
	s.level = 10
	t.check(GodNight.awaken_state(s) == "rite" and String(GodNight.rite_for(s).get("id", "")) == "first_taste", "level 10 capped: the rite")
	s.tier = 2
	s.level = 20
	t.check(GodNight.awaken_state(s) == "unwritten" and GodNight.rite_for(s).is_empty(), "tier 2 at level 20: not yet written")
	s.tier = 5
	s.level = 50
	t.check(GodNight.awaken_state(s) == "", "level 50: no Awaken")
	t.check(GodNight.is_rite("first_taste") and not GodNight.is_rite("warning"), "is_rite")


static func _rite_def(t) -> void:
	var s := _slot()
	s.bought["clock"] = 1
	var d := GodNight.def_for(s, "first_taste")
	t.check(d != null and d.id == "first_taste" and d.tier == 1, "the rite's def: id and tier 1")
	if d == null:
		return
	t.check(d.slots == s.slots() and d.dp_capacity == s.max_might() and d.pool == s.draftable(), "the god's slots, Might and pool (%d, %d)" % [d.slots, d.dp_capacity])
	t.check(is_equal_approx(d.clock, TierBook.clock(1) + s.extra_clock()) and is_equal_approx(d.clock, 315.0), "clock 300 + one Faith clock (%f)" % d.clock)
	t.check(d.lantern == "watch" and d.profile == "unaware", "the Watch's bell and the Unaware town (%s, %s)" % [d.lantern, d.profile])
	t.check(d.gifts == s.gifts, "the god's gifts ride on it")
	var again := GodNight.def_for(s, "first_taste")
	t.check(again != d, "each call a fresh def")
	# A rite is the rite even when the Hunt is due.
	s.notice = 100
	var h := GodNight.def_for(s, "first_taste")
	t.check(h != null and h.id == "first_taste" and h.name == "The First Taste", "a due Hunt does not dress the rite (%s)" % [h.name if h != null else "null"])


static func _gifts_copied(t) -> void:
	var s := _slot()
	s.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL])
	var plain := GodNight.def_for(s, "warning")
	t.check(plain != null and plain.gifts == s.gifts, "an ordinary night carries the god's gifts (%s)" % [plain.gifts if plain != null else "null"])
	t.check(plain != null and not plain.gifts.is_empty(), "and not empty")
	plain.gifts.append("x")
	t.check(s.gifts.size() == 1, "the def's list is a copy")
	var hunt := _slot()
	hunt.gifts = s.gifts.duplicate()
	hunt.notice = 100
	var hid := String(GodNight.hunt_for(hunt).id)
	var hd := GodNight.def_for(hunt, hid)
	t.check(hd != null and hd.gifts == hunt.gifts, "a Hunt carries them")
	var acted := ""
	for id in TierBook.all():
		if TierBook.board(id).has_acts():
			acted = id
			break
	t.check(acted != "", "the board has a night with acts")
	if acted != "":
		var ad := GodNight.def_for(s, acted)
		var all_have := ad != null and ad.gifts == s.gifts and not ad.acts.is_empty()
		for a: ActDef in ad.acts:
			all_have = all_have and a.gifts == s.gifts
		t.check(all_have, "the mission and each act of a multi-act night carry them")
	var bare := GodNight.def_for(_slot(), "warning")
	t.check(bare != null and bare.gifts.is_empty(), "a god without gifts: empty")


static func _board_no_gifts(t) -> void:
	var clean := true
	for id in TierBook.all():
		var b := TierBook.board(id)
		var m := Mission.def_for(id, true, null)
		clean = clean and b != null and b.gifts.is_empty() and m != null and m.gifts.is_empty()
	t.check(clean, "no board def carries a gift")
	t.check(MissionBook.first_taste().gifts.is_empty() and MissionBook.warning().gifts.is_empty(), "nor the campaign's or the rite's own defs")
	t.check(MissionDef.new().gifts.is_empty(), "the default is empty")


static func _steal(t) -> void:
	var s := _slot()
	t.check(s.steal("watchful_bell") and s.gifts == PackedStringArray(["watchful_bell"]), "steal appends")
	t.check(not s.steal("watchful_bell") and s.gifts.size() == 1, "once only")
	t.check(not s.steal("") and s.gifts.size() == 1, "an empty id is refused")


static func _bank_rite_won(t) -> void:
	var s := _slot()
	s.faith = 7
	s.notice = 40
	s.last_mission = "warning"
	s.before_hunt = "lost_lamb"
	s.in_night = "first_taste"
	s.night = 3
	s.points = 1
	var keys := s.in_tree()
	var want := _slot()
	want.awaken()
	var out := GodNight.bank(s, "first_taste", PackedStringArray([keys[0]]), _outcome(true, 3))
	t.check(s.tier == 2 and s.points == 3 and not s.capped() and s.cap() == 20, "won: tier 2, +2 points, the cap lifts (%d, %d, %d)" % [s.tier, s.points, s.cap()])
	t.check(s.gifts == PackedStringArray(["watchful_bell"]), "the gift is stolen (%s)" % [s.gifts])
	t.check(s.notice == 40 and out.notice == 40 and out.notice_change == 0, "Notice unchanged (%d)" % s.notice)
	t.check(s.faith == 7 and out.faith == 0 and out.believers == 0 and out.divine_power == 0 and out.levels.is_empty(), "no Faith, believers or Divine Power")
	t.check(s.divine_power == want.divine_power and s.level == want.level, "the bar is kept and re-levelled by awaken() (%d, %d)" % [s.divine_power, s.level])
	t.check(s.night == 4 and s.in_night == "", "the night counts and closes")
	t.check(s.last_mission == "warning" and s.before_hunt == "lost_lamb", "last_mission and before_hunt are untouched")
	t.check(s.bests.is_empty() and out.bests.is_empty(), "no best is kept")
	t.check(int(s.carried.get(keys[0], 0)) == 1 and s.loadout == PackedStringArray([keys[0]]), "the draft is carried and remembered")
	t.check(out.rite.won == true and out.rite.tier == 2 and out.rite.points == 2 and out.rite.gift == "watchful_bell" and out.rite.shards == 3
		and out.rite.need == 3 and out.rite.id == "first_taste" and out.rite.name == "The First Taste", "the rite result (%s)" % [out.rite])
	t.check(out.points == 2 and out.hunt.is_empty() and out.hunt_next == false and out.night == 4 and out.level == s.level, "the result's other keys")
	t.check(out.capped == false and out.bar == [s.divine_power, s.need()] and out.unsealed == "", "capped, bar, unsealed")


static func _bank_rite_twice(t) -> void:
	var s := _slot()
	s.gifts = PackedStringArray(["watchful_bell"])
	var out := GodNight.bank(s, "first_taste", PackedStringArray(), _outcome(true, 3))
	t.check(s.gifts.size() == 1 and s.tier == 2, "a second won rite adds the gift no more (%s)" % [s.gifts])
	t.check(out.rite.gift == "", "and reports no gift stolen (%s)" % [out.rite.gift])


static func _bank_rite_lost(t) -> void:
	var s := _slot()
	s.points = 4
	var out := GodNight.bank(s, "first_taste", PackedStringArray(), _outcome(false, 2))
	t.check(s.tier == 1 and s.capped() and s.points == 4 and s.gifts.is_empty(), "lost: still Tier 1, still capped, no points, no gift")
	t.check(s.notice == 25 and out.notice == 25 and out.notice_change == 25, "Notice +25 (%d)" % s.notice)
	t.check(out.rite.won == false and out.rite.shards == 2 and out.rite.tier == 1 and out.rite.points == 0 and out.rite.gift == "", "the rite result (%s)" % [out.rite])
	t.check(out.points == 0 and out.capped == true and s.night == 1, "the result: no points, capped, the night counts")
	var h := _slot()
	h.notice = 80
	out = GodNight.bank(h, "first_taste", PackedStringArray(), _outcome(false))
	t.check(h.notice == 100 and out.notice_change == 20 and out.hunt_next == true and out.rite.shards == 0, "from 80: 100, change 20, the Hunt is next (%d)" % h.notice)
	var m := _slot()
	out = GodNight.bank(m, "first_taste", PackedStringArray(), {"won": false})
	t.check(out.rite.shards == 0 and m.notice == 25, "an outcome with no rite entry reads 0 shards")


static func _forfeit_rite(t) -> void:
	var s := _slot()
	s.notice = 25
	s.last_mission = "warning"
	s.in_night = "first_taste"
	var out := GodNight.forfeit(s)
	t.check(s.notice == 50 and out.notice == 50 and out.notice_change == 25, "an abandoned rite: Notice 25 -> 50 (%d)" % s.notice)
	t.check(out.line == "Night 1 was abandoned: the rite is lost. Lantern Notice +25%.", "its line (%s)" % out.line)
	t.check(s.last_mission == "warning" and s.in_night == "" and s.night == 1 and s.tier == 1 and s.capped(), "last_mission untouched, the night counts, still capped")
	t.check(out.rite.won == false and out.hunt.is_empty() and out.hunt_next == false and out.unsealed == "", "the result (%s)" % [out.rite])
	var g := _slot()
	var keys := g.in_tree()
	g.seal(keys[0])
	g.seal_nights = 1
	g.in_night = "first_taste"
	var line := String(GodNight.forfeit(g).line)
	var name := String(PowerBook.get_power(keys[0]).name)
	t.check(line == "Night 1 was abandoned: the rite is lost. Lantern Notice +25%%. %s is no longer sealed." % name, "a seal on its last night ends with its line (%s)" % line)
	var full := _slot()
	full.notice = 100
	full.in_night = "first_taste"
	var f := GodNight.forfeit(full)
	t.check(full.notice == 100 and f.hunt.is_empty() and f.line == "Night 1 was abandoned: the rite is lost." and f.hunt_next == true,
		"from 100 the Notice stays and no rise is claimed (%s)" % f.line)


static func _rite_draw_untouched(t) -> void:
	var s := _slot(9)
	s.last_mission = "warning"
	s.night = 4
	GodNight.bank(s, "first_taste", PackedStringArray(), _outcome(false, 1))
	var twin := _slot(9)
	twin.last_mission = "warning"
	twin.night = s.night
	t.check(GodNight.draw(s) == GodNight.draw(twin), "the draw after a rite is as if it had not been played (%s, %s)" % [GodNight.draw(s), GodNight.draw(twin)])
	var w := _slot(9)
	w.last_mission = "warning"
	w.night = 4
	GodNight.bank(w, "first_taste", PackedStringArray(), _outcome(true, 3))
	var twin2 := _slot(9)
	twin2.tier = 2
	twin2.last_mission = "warning"
	twin2.night = w.night
	t.check(GodNight.draw(w) == GodNight.draw(twin2) and TierBook.missions(2).has(GodNight.draw(w)), "and after a won rite it draws at the new tier (%s)" % GodNight.draw(w))


static func _rite_beats_hunt_flag(t) -> void:
	var s := _slot()
	s.notice = 100
	s.carried = {}
	var out := GodNight.bank(s, "first_taste", PackedStringArray(), _outcome(false, 0))
	t.check(out.hunt.is_empty() and s.sealed == "" and s.notice == 100 and out.notice_change == 0 and out.hunt_next == true,
		"a rite banked at Notice 100 is a rite, not a Hunt: no seal, Notice stays (%s)" % [out.hunt])


static func _mission_book_rite(t) -> void:
	var m := MissionBook.get_mission("first_taste")
	t.check(m.id == "first_taste" and m.tier == 1 and m.lantern == "watch" and m.slots == 3 and m.dp_capacity == 6, "get_mission finds the rite's frame")
	t.check(m.default_loadout == PackedStringArray(["doom", "whisper", "smite"]) and m.goal_label == "Three Lantern shards", "its loadout and goal label")
	t.check(m.objectives().size() == 2 and m.director == null, "two objectives and no director yet (Task 4)")
	t.check(MissionBook.is_dev("first_taste") and MissionBook.is_dev("capital_sandbox") and not MissionBook.is_dev("warning"), "is_dev: the rite and the sandbox")
	t.check(MissionBook.rite_missions().size() == 1 and MissionBook.rite_missions()[0].id == "first_taste", "rite_missions")
	var in_dev := false
	for d in MissionBook.dev_missions():
		in_dev = in_dev or RiteBook.has(d.id)
	t.check(not in_dev and MissionBook.dev_missions().size() == 1, "dev_missions() is unchanged (the sandbox)")
	var listed := false
	for d in MissionBook.tier_missions():
		listed = listed or RiteBook.has(d.id)
	for d in MissionBook.all():
		listed = listed or RiteBook.has(d.id)
	for d in MissionBook.campaign_missions():
		listed = listed or RiteBook.has(d.id)
	t.check(not listed and not TierBook.has("first_taste") and not TierBook.all().has("first_taste"), "no rite on the board, the campaign or the list")
	t.check(m.needs() == PackedStringArray(["temple"]), "the rite needs the Temple (%s)" % [m.needs()])


## Pre-flight B1: a rite left by closing the game must still read back as open, so the load forfeits it.
static func _read_rite_in_night(t) -> void:
	var file := FILE % "in_night"
	var s := _slot()
	s.in_night = "first_taste"
	t.check(s.write(file) == OK, "the file writes")
	var back := GodSlot.read(file)
	t.check(back != null and back.in_night == "first_taste", "a rite in the night reads back open (%s)" % [back.in_night if back != null else "null"])
	s.in_night = "nosuch"
	s.write(file)
	back = GodSlot.read(file)
	t.check(back != null and back.in_night == "", "an unknown id is still dropped")
	s.in_night = "warning"
	s.write(file)
	back = GodSlot.read(file)
	t.check(back != null and back.in_night == "warning", "a board mission still reads back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
