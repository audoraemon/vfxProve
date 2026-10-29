extends RefCounted
## God P5 Task 1 (mission spec MS §1, R1-R9; plan Rulings P5-1 to P5-5): the real Lantern Hunts as rules and data -- HuntBook's five rows,
## the five frames on their tiers' numbers, the draw (a Hunt at Notice 100, whatever the seed), the def the god plays, a Hunt id kept in
## the save, P2's bank and forfeit with the real ids, and the Descent a Hunt keeps (open issue 4). No Hunt director exists yet (Tasks 4-8):
## the frames carry the do-nothing MissionDirector, and `_hunt_wishes` says so with a NOTE.

const FILE := "user://test_hunt_book_%s.cfg"
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## P2's titles and plates (GodNight.HUNTS before P5): the real Hunts keep them (open issue 9, ruling C9).
const TITLES := ["Hide the faithful", "Silence the witness", "Expel the inquisitor", "Break the hunt", "Face Halcyon"]
const PLATES := ["Lead your believers out before the inquisitors reach them", "Stop the runner carrying word of you to the Lantern",
	"Drive out or kill the Lantern's captain in the town", "Smash their standards before they reach your believers",
	"His Gaze is on the whole town, and a seen death fills it"]


static func run(t) -> void:
	GodTree.dev_fill = true
	_rows(t)
	_frames(t)
	_hunt_for_real(t)
	_hunt_def(t)
	_read_keeps_hunt(t)
	_bank_hunt_real(t)
	_descent(t)
	_hunt_wishes(t)
	GodTree.dev_fill = false


## The first ring type with two starting keys (as P2's R3): the fixture god.
static func _type() -> String:
	for type: String in GodTree.RING:
		if GodTree.starting(type).size() >= 2:
			return type
	return ""


static func _slot(tier := 1, seed_value := 5) -> GodSlot:
	var s := GodSlot.make(1, _type(), seed_value)
	s.tier = tier
	return s


## A report's "descend" as Descent.report() gives it, for the keys banking reads.
static func _outcome(main: bool, ascended: bool, earned := 0, kept := 0, tier := 1) -> Dictionary:
	return {"won": main, "descend": {"tier": tier, "main": main, "ascended": ascended, "kept": kept, "earned": earned,
		"main_time": 150.0 if main else 0.0}}


static func _rows(t) -> void:
	t.check(HuntBook.HUNTS.size() == 5, "five Hunts (%d)" % HuntBook.HUNTS.size())
	var ids := HuntBook.ids()
	t.check(ids == PackedStringArray([MissionBook.HIDE_FAITHFUL, MissionBook.SILENCE_WITNESS, MissionBook.EXPEL_INQUISITOR,
		MissionBook.BREAK_HUNT, MissionBook.FACE_HALCYON]), "ids() is the five in tier order (%s)" % [ids])
	for i in 5:
		var h: Dictionary = HuntBook.HUNTS[i]
		t.check(int(h.tier) == i + 1, "row %d is tier %d (%s)" % [i, i + 1, h.tier])
		t.check(h.title == TITLES[i] and h.plate == PLATES[i], "tier %d keeps P2's title and plate (%s / %s)" % [i + 1, h.title, h.plate])
		t.check(HuntBook.has(String(h.id)) and HuntBook.row(String(h.id)) == h, "has() and row() find %s" % h.id)
		t.check(HuntBook.at_tier(i + 1).id == h.id and HuntBook.at_tier(i + 1).tier == i + 1, "at_tier(%d) is it" % [i + 1])
		t.check(not TierBook.has(String(h.id)), "%s is not a board id" % h.id)
		t.check(GodNight.is_hunt(String(h.id)) and GodNight.HUNTS[i] == h, "GodNight.HUNTS aliases it, is_hunt() agrees")
	t.check(HuntBook.row("x").is_empty() and not HuntBook.has("x") and not HuntBook.has("first_taste") and not HuntBook.has("lost_lamb"),
		"an id that is no Hunt has no row")
	t.check(HuntBook.at_tier(0).tier == 1 and HuntBook.at_tier(-3).tier == 1 and HuntBook.at_tier(9).tier == 5, "at_tier clamps to 1-5")
	t.check(HuntBook.def("x") == null and HuntBook.def("lost_lamb") == null, "def() of a non-Hunt is null")
	var copy := HuntBook.at_tier(2)
	copy["title"] = "changed"
	t.check(HuntBook.HUNTS[1].title == TITLES[1], "at_tier() gives a copy")


static func _frames(t) -> void:
	var board_ids := TierBook.all()
	var tier_ids := PackedStringArray()
	for m in MissionBook.tier_missions():
		tier_ids.append(m.id)
	var dev_ids := PackedStringArray()
	for m in MissionBook.dev_missions():
		dev_ids.append(m.id)
	t.check(MissionBook.hunt_missions().size() == 5, "hunt_missions() lists five")
	for h: Dictionary in HuntBook.HUNTS:
		var id := String(h.id)
		var tier := int(h.tier)
		var def := HuntBook.def(id)
		t.check(def != null and def.id == id, "HuntBook.def(%s) is the mission" % id)
		if def == null:
			continue
		t.check(def.tier == tier and def.name == h.title, "%s: tier %d and its title (%d, %s)" % [id, tier, def.tier, def.name])
		t.check(is_equal_approx(def.clock, TierBook.clock(tier)) and def.slots == TierBook.slots(tier) and def.dp_capacity == TierBook.dp(tier),
			"%s: the tier's clock, slots and Might (%s, %d, %d)" % [id, def.clock, def.slots, def.dp_capacity])
		t.check(def.tier_floor == TierBook.readiness(tier) or (tier == 1 and def.profile == "unaware"),
			"%s: the tier's town (floor %d)" % [id, def.tier_floor])
		t.check(def.lantern == (LanternWatch.KIND_GAZE if tier == 5 else LanternWatch.KIND_WATCH), "%s: Lantern %s" % [id, def.lantern])
		t.check(def.mission_tags.has(TierBook.UNAWARE_TAG) == (tier == 1), "%s: the Unaware tag at Tier 1 only (%s)" % [id, def.mission_tags])
		t.check(def.goal.length() <= 91 and def.goal != "", "%s: goal fits the Informer's 91 characters (%d)" % [id, def.goal.length()])
		t.check(def.lose.length() <= 96 and def.lose != "", "%s: lose fits the Informer's 96 characters (%d)" % [id, def.lose.length()])
		t.check(def.goal_label != "" and def.brief.size() == 2 and def.city == &"aldermere", "%s: label, a two-line brief, Aldermere" % id)
		t.check(def.default_loadout.size() == 3 and def.make_objectives.is_valid() and def.director != null, "%s: a loadout, objectives, a director" % id)
		var objectives := def.objectives()
		t.check(objectives.size() >= 1 and objectives[objectives.size() - 1] is ClockObjective, "%s: the Dawn is last (%d)" % [id, objectives.size()])
		t.check(MissionBook.is_dev(id) and MissionBook.get_mission(id).id == id, "%s: dev-only and found by get_mission()" % id)
		t.check(not board_ids.has(id) and not tier_ids.has(id) and not dev_ids.has(id), "%s: on no tier list, not dev_missions()" % id)
		t.check(not TierBook.MISSIONS[tier - 1].has(id), "%s: not among tier %d's board missions" % [id, tier])
	t.check(HuntBook.def(MissionBook.HIDE_FAITHFUL).default_loadout == PackedStringArray(["whisper", "doom", "discord"]), "Hunt 1's loadout")
	t.check(HuntBook.def(MissionBook.SILENCE_WITNESS).default_loadout == PackedStringArray(["doom", "whisper", "discord"]), "Hunt 2's loadout")
	t.check(HuntBook.def(MissionBook.EXPEL_INQUISITOR).default_loadout == PackedStringArray(["doom", "smite", "whisper"]), "Hunt 3's loadout")
	t.check(HuntBook.def(MissionBook.BREAK_HUNT).default_loadout == PackedStringArray(["doom", "smite", "heaven"]), "Hunt 4's loadout")
	t.check(HuntBook.def(MissionBook.FACE_HALCYON).default_loadout == PackedStringArray(["whisper", "discord", "doom"]), "Hunt 5's loadout")
	t.check(not MissionBook.is_dev("lost_lamb") and not MissionBook.is_dev("warning"), "a board mission is still not dev-only")


static func _hunt_for_real(t) -> void:
	for tier in range(1, 6):
		var want := HuntBook.at_tier(tier)
		for seed_value in [1, 2, 3, 4, 5]:
			var s := _slot(tier, seed_value)
			s.notice = 100
			var h := GodNight.hunt_for(s)
			t.check(h.get("id", "") == want.id and int(h.get("tier", 0)) == tier and h.get("title", "") == want.title and h.get("plate", "") == want.plate,
				"tier %d, seed %d, Notice 100: hunt_for() is the real Hunt (%s)" % [tier, seed_value, h.get("id", "")])
			t.check(GodNight.draw(s) == want.id, "draw() is %s (%s)" % [want.id, GodNight.draw(s)])
			s.last_mission = String(want.id)
			t.check(GodNight.draw(s) == want.id, "draw() is it with the Hunt as the last mission")
			s.notice = 99
			t.check(GodNight.hunt_for(s).is_empty() and GodNight.draw(s) != want.id and TierBook.missions(tier).has(GodNight.draw(s)),
				"tier %d, seed %d, Notice 99: no Hunt, a board mission (%s)" % [tier, seed_value, GodNight.draw(s)])


static func _hunt_def(t) -> void:
	for tier in range(1, 6):
		var s := _slot(tier)
		s.notice = 100
		s.bought["clock"] = 1
		var h := HuntBook.at_tier(tier)
		var def := GodNight.def_for(s, String(h.id))
		t.check(def != null and def.tier == tier and def.id == h.id and def.name == h.title and def.intro_banner == String(h.title).to_upper(),
			"tier %d Hunt: its tier, id, title and banner" % tier)
		if def == null:
			continue
		t.check(def.slots == s.slots() and def.dp_capacity == s.max_might() and def.pool == s.draftable(),
			"tier %d Hunt: the god's slots, Might and pool (%d, %d)" % [tier, def.slots, def.dp_capacity])
		t.check(absf(def.clock - (TierBook.clock(tier) + s.extra_clock())) < 0.001 and s.extra_clock() > 0.0,
			"tier %d Hunt: the tier's clock plus the Faith clock (%s)" % [tier, def.clock])
		t.check(def.gifts == s.gifts, "tier %d Hunt: the god's gifts" % tier)
		t.check(def.goal == HuntBook.def(String(h.id)).goal and def.lose == HuntBook.def(String(h.id)).lose, "tier %d Hunt: the Hunt's own goal and lose" % tier)
		t.check(Descent.new().setup(def, 1).tier == tier, "tier %d Hunt: the Descent plays it at the god tier" % tier)
		# A Hunt id builds the Hunt at any Notice (Ruling P5-2): a stale in_night, a test.
		s.notice = 12
		var stale := GodNight.def_for(s, String(h.id))
		t.check(stale != null and stale.name == h.title and stale.id == h.id, "tier %d: the Hunt id builds the Hunt at Notice 12 too" % tier)


static func _read_keeps_hunt(t) -> void:
	for h: Dictionary in HuntBook.HUNTS:
		var file := FILE % "r"
		var w := _slot(int(h.tier))
		w.in_night = String(h.id)
		w.last_mission = String(h.id)
		w.write(file)
		var back := GodSlot.read(file)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
		t.check(back != null and back.in_night == h.id and back.last_mission == h.id,
			"%s: in_night and last_mission read back (%s, %s)" % [h.id, back.in_night if back != null else "null", back.last_mission if back != null else "null"])
	var junk_file := FILE % "j"
	var cfg := ConfigFile.new()
	cfg.set_value(GodSlot.SECTION, "type", _type())
	cfg.set_value(GodSlot.SECTION, "in_night", "no_such_hunt")
	cfg.set_value(GodSlot.SECTION, "last_mission", "no_such_hunt")
	cfg.save(junk_file)
	var junk := GodSlot.read(junk_file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(junk_file))
	t.check(junk != null and junk.in_night == "" and junk.last_mission == "", "an unknown id still reads as \"\"")
	# A game closed mid-Hunt is a lost Hunt (R4).
	var s := _slot(3)
	s.notice = 100
	var keys := s.in_tree()
	s.carried[keys[0]] = 2
	var want := s.seal_target()
	s.in_night = MissionBook.EXPEL_INQUISITOR
	var out := GodNight.forfeit(s)
	t.check(s.sealed == want and s.seal_nights == 3 and s.notice == 50 and out.hunt.won == false and out.hunt.id == MissionBook.EXPEL_INQUISITOR,
		"forfeit() gives the lost Hunt: seal, Notice 50 (%s, %d)" % [s.sealed, s.notice])
	t.check(out.line.contains("the Hunt is lost") and s.last_mission == MissionBook.EXPEL_INQUISITOR, "its HUNT_ABANDONED line (%s)" % out.line)


static func _bank_hunt_real(t) -> void:
	for tier in range(1, 6):
		var h := HuntBook.at_tier(tier)
		var id := String(h.id)
		var before := "warning"
		var s := _slot(tier)
		s.notice = 100
		s.last_mission = before
		var keys := s.in_tree()
		var out := GodNight.bank(s, id, PackedStringArray([keys[0]]), _outcome(true, false, 30, 0, tier))
		t.check(s.notice == 0 and out.notice == 0 and out.hunt.won == true and out.hunt.faith == 50 * tier and out.hunt.id == id,
			"tier %d won: Notice 0, %d Faith (%d, %s)" % [tier, 50 * tier, s.notice, out.hunt])
		t.check(s.faith == 30 + 50 * tier and out.faith_total == s.faith, "tier %d won: believers plus the bonus (%d)" % [tier, s.faith])
		t.check(s.last_mission == id and s.before_hunt == before and s.night == 1 and s.in_night == "", "tier %d: the Hunt is the last mission, the night before it is kept" % tier)
		t.check(not s.bests.has(id) and out.bests.is_empty() and out.hunt.sealed == "", "tier %d won: no best, nothing sealed" % tier)
		var lost := _slot(tier)
		lost.notice = 100
		lost.carried[keys[1]] = 3
		var target := lost.seal_target()
		var back := GodNight.bank(lost, id, PackedStringArray([keys[0]]), _outcome(false, false, 6, 0, tier))
		t.check(lost.notice == 50 and lost.sealed == target and lost.seal_nights == 3 and back.hunt.won == false and back.hunt.faith == 0,
			"tier %d lost: Notice 50, %s sealed 3 nights (%d, %s)" % [tier, target, lost.notice, lost.sealed])
		t.check(lost.last_mission == id and not lost.bests.has(id), "tier %d lost: the Hunt is the last mission, no best" % tier)


static func _descent(t) -> void:
	for h: Dictionary in HuntBook.HUNTS:
		var def := HuntBook.def(String(h.id))
		t.check(Mission.has_descent(def, true), "%s has a Descent on a board night" % h.id)
		t.check(not Mission.has_descent(def, false), "%s has none off the board" % h.id)
		t.check(not Mission.has_descent(MissionBook.in_city(HuntBook.def(String(h.id)), &"capital"), true), "%s has none in another town" % h.id)
	t.check(Mission.has_descent(TierBook.board("warning"), true) and Mission.has_descent(TierBook.board("lost_lamb"), true), "a board mission still has one")
	t.check(not Mission.has_descent(MissionBook.first_taste(), true) and not Mission.has_descent(MissionBook.capital_sandbox(), true),
		"a rite and the sandbox still have none")


## The people and buildings a director holds in its own members (a Person, or a Structure, or an Array or Dictionary of them), found by
## reading its script variables: the director's own people, whatever their names. `reserved` and the Faithful belong to the base.
static func _own(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	for prop: Dictionary in d.get_property_list():
		if not (int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) or ["reserved", "reserved_places", "faithful"].has(String(prop.name)):
			continue
		_collect(d.get(String(prop.name)), people, places, 0)
	return {"people": people, "places": places}


static func _collect(v: Variant, people: Array, places: Array, depth: int) -> void:
	if depth > 3:
		return
	if v is Array:
		for x: Variant in v:
			_collect(x, people, places, depth + 1)
	elif v is Dictionary:
		for k: Variant in v:
			_collect(v[k], people, places, depth + 1)
	elif v is Object and is_instance_valid(v):
		if v is Person:
			people.append(v)
		elif v is Structure:
			places.append(v)


## Open issue 4's promise: each Hunt hears the tier's wishes on nights 0-3 and none lands on the director's own people or buildings (P2's
## `_informer_t3_wishes` is the model). While the frame's director is the empty MissionDirector (this task) there is nothing to hit: a NOTE.
static func _hunt_wishes(t) -> void:
	for h: Dictionary in HuntBook.HUNTS:
		var id := String(h.id)
		var tier := int(h.tier)
		var heard := 0
		var hit := 0
		var empty := false
		for night in 4:
			var def := HuntBook.def(id)
			var descent := Descent.new().setup(def, Descent.seed_for(night, id))
			var n := Kit.world(HuntBook.def(id), null, func(d: MissionDirector, rules: Rules) -> void: descent.reserve(rules, d))
			empty = n.d.get_script() == MissionDirector
			var mine := _own(n.d)
			for w in descent.wishes:
				heard += 1
				for p in w.people():
					hit += 1 if (mine.people as Array).has(p) else 0
				for st in w.places():
					hit += 1 if (mine.places as Array).has(st) else 0
			t.check(descent.wishes.size() >= 1 and descent.wishes.size() <= TierBook.wishes(tier),
				"%s, night %d: 1-%d wishes are heard (%d)" % [id, night, TierBook.wishes(tier), descent.wishes.size()])
			descent.release()
			Kit.done(n)
		t.check(heard > 0 and hit == 0, "%s: wishes heard (%d), none on the director's own people or buildings (%d)" % [id, heard, hit])
		if empty:
			print("NOTE: %s still has the empty MissionDirector: its own people are checked once its task builds the director" % id)
