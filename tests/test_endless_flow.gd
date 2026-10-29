extends RefCounted
## God P1 Task 11 (spec §9.1, §14 P1, rulings C2, C7, C9, P9, P10, P14): the wiring of Endless Night into Game -- every new FLOW entry,
## a night banked to the god and never to the board's save, a slot found mid-night forfeited when it is opened, and the board's ENDLESS
## button. The screens themselves are proved by their own suites; the walk through them is FLOW's (Task 12).

const BASE := "user://test_endless_flow_"
const FILE := "user://test_endless_flow_1.cfg"


static func run(t) -> void:
	_clear()
	_flow_table(t)
	_bank_leaves_save(t)
	_load_god_forfeits(t)
	_load_god_hunt(t)
	_awaken_routes(t)
	_load_god_rite(t)
	_rite_bank_writes(t)
	_write_fails(t)
	_draw_survives_quit(t)
	_endless_button(t)
	_between_acts_levels(t)
	_god_seed(t)
	GodTree.dev_fill = false
	_clear()


static func _clear() -> void:
	for n in range(1, GodSlot.COUNT + 1):
		if FileAccess.file_exists(GodSlot.path(n, BASE)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(GodSlot.path(n, BASE)))


## A report's "descend" as Descent.report() gives it, for the keys banking reads (as test_god_night.gd).
static func _outcome(main: bool, kept: int, earned: int) -> Dictionary:
	return {"mission": "warning", "won": main, "descend": {"tier": 1, "main": main, "kept": kept, "earned": earned,
		"main_time": 150.0 if main else 0.0}}


static func _flow_table(t) -> void:
	var want := {
		"board:endless": Game.Screen.SLOTS, "slots:continue": Game.Screen.HUB, "slots:new": Game.Screen.GOD_SELECT,
		"slots:back": Game.Screen.BOARD, "god:chosen": Game.Screen.HUB, "god:back": Game.Screen.SLOTS,
		"hub:descend": Game.Screen.PREPARE, "hub:awaken": Game.Screen.PREPARE, "hub:tree": Game.Screen.TREE, "hub:faith": Game.Screen.FAITH,
		"hub:title": Game.Screen.TITLE, "tree:back": Game.Screen.HUB, "faith:back": Game.Screen.HUB,
		"prepare:hub": Game.Screen.HUB, "results:continue": Game.Screen.HUB, "results:tree": Game.Screen.TREE,
		"results:faith": Game.Screen.FAITH, "pause:abandon": Game.Screen.HUB, "interlude:hub": Game.Screen.HUB,
	}
	var wrong := PackedStringArray()
	for action: String in want:
		if Game.next_screen(action) != int(want[action]):
			wrong.append("%s=%d" % [action, Game.next_screen(action)])
	t.check(wrong.is_empty(), "every Endless Night action leads to its screen (wrong: %s)" % ", ".join(wrong))
	t.check(Game.Screen.TITLE == 0 and Game.Screen.BOARD == 1 and Game.Screen.UPGRADES == 8 and Game.Screen.SLOTS == 9
		and Game.Screen.FAITH == 13, "the old screens keep their values and the five new ones follow (SLOTS %d, FAITH %d)" % [
		Game.Screen.SLOTS, Game.Screen.FAITH])
	t.check(Game.next_screen("title:play") == Game.Screen.BOARD and Game.next_screen("prepare:back") == Game.Screen.BOARD
		and Game.next_screen("results:replay") == Game.Screen.MISSION and Game.next_screen("pause:restart") == Game.Screen.MISSION
		and Game.next_screen("interlude:missions") == Game.Screen.BOARD, "the old entries are unchanged")
	t.check(Game.next_screen("title:endless") == Game.Screen.SLOTS and Game.next_screen("slots:title") == Game.Screen.TITLE
		and Game.next_screen("title:slots") == -1, "the title's Endless Night leads to the slot select, whose title Back returns (god T1R, D7)")


## C7: a night banked to a god changes the god and nothing of the board's save, in memory or on disk.
static func _bank_leaves_save(t) -> void:
	GodTree.dev_fill = true
	var save := SaveFile.new()
	save.descend.night = 3
	save.descend.believers = 40
	save.descend.cleared = PackedStringArray(["warning"])
	save.campaign = CampaignState.new()
	save.campaign.night = 2
	var disk := _file_bytes(SaveFile.PATH)
	var god := GodSlot.make(1, "ruin", 9)
	var kit := PackedStringArray(["smite"])
	var out := _outcome(true, 2, 30)
	Game.bank_god_night(god, "warning", kit, out)
	t.check(out.god.divine_power == 120, "main plus two wishes at tier 1 is 120 Divine Power (%s)" % [out.get("god")])
	t.check(out.god.faith == 30 and god.faith == 30 and god.night == 1 and god.last_mission == "warning",
		"the god banks the night: Faith %d, night %d, last %s" % [god.faith, god.night, god.last_mission])
	t.check(god.carried == {"smite": 1} and god.loadout == kit, "and carries the drafted ability (%s)" % [god.carried])
	t.check(out.best == false, "the results show no NEW BEST (the board's best is not touched)")
	t.check(save.descend.night == 3 and save.descend.believers == 40 and save.descend.cleared == PackedStringArray(["warning"]),
		"the board's night, believers and cleared are unchanged (%d, %d, %s)" % [save.descend.night, save.descend.believers, save.descend.cleared])
	t.check(save.campaign.night == 2, "and the campaign's night (%d)" % save.campaign.night)
	t.check(_file_bytes(SaveFile.PATH) == disk, "and nothing was written to the board's save file")
	t.check(not out.has("campaign"), "the night is not a campaign night")
	# A lost night banks nothing but still counts.
	var lost := GodSlot.make(1, "ruin", 9)
	var out2 := _outcome(false, 0, 0)
	Game.bank_god_night(lost, "warning", kit, out2)
	t.check(out2.god.divine_power == 0 and lost.night == 1 and lost.faith == 0 and lost.in_night == "",
		"a lost night earns nothing and counts (%d, night %d)" % [out2.god.divine_power, lost.night])
	GodTree.dev_fill = false


static func _file_bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()


## P9, C9: a slot opened with in_night set was left after its clock started -- it is forfeited at once, written, and the line says so.
static func _load_god_forfeits(t) -> void:
	_clear()
	var god := GodSlot.make(1, "ruin", 4)
	god.night = 2
	god.in_night = "tax_collector"
	god.faith = 12
	t.check(god.write(FILE) == OK, "the test slot is written")
	var got := Game.load_god(FILE)
	var s: GodSlot = got[0]
	t.check(s != null and s.night == 3 and s.in_night == "" and s.last_mission == "tax_collector",
		"a slot found mid-night is forfeited: night 3, nothing open, the mission remembered")
	t.check(got[1] == "Night 3 was abandoned: a lost night. Lantern Notice +25%.", "and the line says so (%s)" % got[1])
	t.check(s != null and s.faith == 12 and s.level == 1, "nothing is earned and nothing is lost")
	var again := GodSlot.read(FILE)
	t.check(again != null and again.night == 3 and again.in_night == "" and again.last_mission == "tax_collector",
		"the forfeit was written: the file says the same")
	var twice := Game.load_god(FILE)
	t.check(twice[1] == "" and twice[0].night == 3, "opened again, it is not forfeited twice (%s)" % [twice[1]])
	# A slot that was not mid-night is unchanged, with no line.
	var calm := GodSlot.make(1, "ruin", 4)
	calm.night = 5
	calm.write(FILE)
	var calm_got := Game.load_god(FILE)
	t.check(calm_got[1] == "" and calm_got[0].night == 5, "a slot that was not mid-night opens as it was (%s)" % [calm_got[1]])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	var none := Game.load_god(FILE)
	t.check(none[0] == null and none[1] == "", "a missing file gives no god and no line")


## The fixture type for P2's slots (R3): the first ring type with two starting keys on the merged table, or "" when none.
static func _lantern_type() -> String:
	for type: String in GodTree.RING:
		if GodTree.starting(type).size() >= 2:
			return type
	return ""


## A game closed mid-Hunt is a lost Hunt when the slot is opened (god P2, Ruling P2-4, P2-9): the most-carried ability is sealed, the
## Notice is 50, the night counts, the line says all three, the file agrees and a second opening changes nothing.
static func _load_god_hunt(t) -> void:
	_clear()
	GodTree.dev_fill = true
	var type := _lantern_type()
	t.check(type != "", "a god type with two starting keys exists (R3)")
	if type == "":
		GodTree.dev_fill = false
		return
	var god := GodSlot.make(1, type, 4)
	god.notice = 100
	god.night = 6
	var keys := god.in_tree()
	t.check(keys.size() >= 2, "the fixture god has two keys in the tree (%s)" % [keys])
	if keys.size() < 2:
		GodTree.dev_fill = false
		return
	god.carried = {keys[0]: 2, keys[1]: 5}
	god.in_night = GodNight.HUNTS[0].id
	var want := god.seal_target()
	t.check(want == keys[1], "the most-carried key is the target (%s)" % want)
	t.check(god.write(FILE) == OK, "the Hunt slot is written")
	var got := Game.load_god(FILE)
	var s: GodSlot = got[0]
	var name: String = PowerBook.get_power(want).name
	t.check(s != null and s.sealed == want and s.seal_nights == 3 and s.notice == 50 and s.night == 7 and s.in_night == "",
		"a slot left mid-Hunt: %s sealed 3 nights, Notice 50, night counted" % want)
	var line: String = GodNight.HUNT_ABANDONED % 7 + " " + GodNight.SEALS % [name, "3 nights"] + " " + GodNight.NOTICE_AT % 50
	t.check(got[1] == line, "and the line says so (%s)" % got[1])
	var back := GodSlot.read(FILE)
	t.check(back != null and back.sealed == want and back.seal_nights == 3 and back.notice == 50 and back.night == 7 and back.in_night == "",
		"the file agrees")
	var again := Game.load_god(FILE)
	t.check(again[1] == "" and again[0].sealed == want and again[0].seal_nights == 3 and again[0].notice == 50 and again[0].night == 7,
		"opened again, nothing changes (%s)" % [again[1]])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	GodTree.dev_fill = false


## A tier-1 god at its cap with a full bar, its type's two starting keys known (god P3, Task 8's fixture).
static func _capped(seed_value := 5) -> GodSlot:
	var g := GodSlot.make(1, _lantern_type(), seed_value)
	g.level = g.cap()
	g.divine_power = g.need()
	g.notice = 50
	g.night = 4
	g.last_mission = "warning"
	return g


## Awaken opens the rite, the Hunt first (god P3, MS §1, Ruling P3-21; Review Focus 1): `Game.awaken_target()` is the id Awaken's Prepare
## would draw -- the rite at the cap, the Hunt while the Notice is full (exactly Descend's path), nothing below the cap, at level 50 or
## where no rite is written yet, and nothing for a god with nothing to draft.
static func _awaken_routes(t) -> void:
	GodTree.dev_fill = true
	var g := _capped()
	t.check(g.draftable().size() > 0, "the fixture god has something to draft (%s)" % [g.draftable()])
	t.check(Game.awaken_target(g) == RiteBook.FIRST_TASTE, "capped at level 10: Awaken opens the First Taste (%s)" % Game.awaken_target(g))
	g.notice = 100
	var hunt := GodNight.draw(g)
	t.check(Game.awaken_target(g) == hunt and hunt == String(GodNight.HUNTS[0].id) and GodNight.is_rite(hunt) == false,
		"capped with the Notice full: the Hunt first, exactly Descend's draw (%s)" % Game.awaken_target(g))
	g.notice = 50
	var up := _capped()
	up.level = 9
	t.check(Game.awaken_target(up) == "", "below the cap Awaken opens nothing (%s)" % Game.awaken_target(up))
	up.notice = 100
	t.check(Game.awaken_target(up) == "", "and the Hunt does not make it open (%s)" % Game.awaken_target(up))
	var none := _capped()
	none.tier = 2
	none.level = none.cap()
	t.check(GodNight.awaken_state(none) == "unwritten" and Game.awaken_target(none) == "",
		"capped at level 20, no rite written: nothing (%s)" % Game.awaken_target(none))
	none.notice = 100
	t.check(Game.awaken_target(none) == String(GodNight.HUNTS[1].id), "but the Hunt is still due first (%s)" % Game.awaken_target(none))
	var top := _capped()
	top.tier = 5
	top.level = GodSlot.MAX_LEVEL
	t.check(Game.awaken_target(top) == "", "at level 50 there is nothing to awaken to (%s)" % Game.awaken_target(top))
	var empty := _capped()
	empty.learned = {}
	t.check(empty.draftable().is_empty() and Game.awaken_target(empty) == "",
		"a god with nothing to draft opens nothing, as Descend does (%s)" % Game.awaken_target(empty))
	GodTree.dev_fill = false


## A game closed in the middle of a rite is a lost rite when the slot is opened (god P3, MS §1, pre-flight B1; Review Focus 2): the file
## written by the clock start (`in_night = "first_taste"`) is read back, Notice +25, the night counts, the tier and `last_mission` stay,
## the line is RITE_ABANDONED's, the file agrees and a second opening changes nothing.
static func _load_god_rite(t) -> void:
	_clear()
	GodTree.dev_fill = true
	var g := _capped(4)
	g.in_night = RiteBook.FIRST_TASTE
	t.check(g.write(FILE) == OK, "the mid-rite slot is written")
	var got := Game.load_god(FILE)
	var s: GodSlot = got[0]
	t.check(s != null and s.notice == 75 and s.night == 5 and s.in_night == "" and s.tier == 1 and s.capped() and s.last_mission == "warning",
		"a slot left mid-rite: Notice 75, the night counted, still tier 1 and capped, last_mission untouched")
	t.check(got[1] == GodNight.RITE_ABANDONED % 5 + " Lantern Notice +25%.", "and the line says the rite is lost (%s)" % got[1])
	t.check(s != null and s.gifts.is_empty() and GodNight.awaken_state(s) == "rite", "nothing is stolen and Awaken is offered again")
	var back := GodSlot.read(FILE)
	t.check(back != null and back.notice == 75 and back.night == 5 and back.in_night == "" and back.tier == 1 and back.last_mission == "warning",
		"the forfeit was written: the file says the same")
	var again := Game.load_god(FILE)
	t.check(again[1] == "" and again[0].notice == 75 and again[0].night == 5, "opened again, nothing more is charged (%s)" % [again[1]])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	GodTree.dev_fill = false


## A won rite banked and written (god P3, MS §1 R2; Review Focus 2): the file reads tier 2, the gift, the points and the same Notice,
## and the night is closed. (Game banks at the decision and writes at once: `_on_night_decided`.)
static func _rite_bank_writes(t) -> void:
	_clear()
	GodTree.dev_fill = true
	var g := _capped(6)
	g.points = 1
	g.faith = 9
	g.in_night = RiteBook.FIRST_TASTE
	var keys := g.in_tree()
	var out := {"won": true, "reason": "shards", "rite": {"shards": 3}}
	Game.bank_god_night(g, RiteBook.FIRST_TASTE, PackedStringArray([keys[0]]), out)
	t.check(Game.write_god(g, FILE) == "", "the banked god is written")
	var s := GodSlot.read(FILE)
	t.check(s != null and s.tier == 2 and s.points == 3 and s.gifts == PackedStringArray(["watchful_bell"]) and s.notice == 50 and s.night == 5
		and s.in_night == "" and s.last_mission == "warning" and s.faith == 9 and s.cap() == 20 and not s.capped(),
		"the file reads tier 2, +2 points, the gift, Notice 50, Night 5, Faith as before, the cap lifted")
	t.check(out.god.rite.won == true and out.god.rite.gift == "watchful_bell" and out.best == false, "the result carries the rite for the results screen (%s)" % [out.god.rite])
	var lost := _capped(6)
	lost.in_night = RiteBook.FIRST_TASTE
	var out2 := {"won": false, "reason": "dawn", "rite": {"shards": 1}}
	Game.bank_god_night(lost, RiteBook.FIRST_TASTE, PackedStringArray([keys[0]]), out2)
	Game.write_god(lost, FILE)
	var l := GodSlot.read(FILE)
	t.check(l != null and l.tier == 1 and l.capped() and l.notice == 75 and l.night == 5 and l.gifts.is_empty() and l.in_night == "",
		"a lost rite writes: tier 1, still capped, Notice 75, no gift")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	GodTree.dev_fill = false


## A failed write of the god's file is told, not swallowed (god P2, Ruling P2-13, pre-flight G1): write_god() gives "" when saved and
## WRITE_FAILED's line otherwise, and load_god() writes through it, so a quit that escapes the Notice by a disk error shows on the hub.
static func _write_fails(t) -> void:
	_clear()
	var slot := GodSlot.make(1, "ruin", 4)
	var bad := Game.write_god(slot, "user://no_such_dir_p2/x.cfg")
	t.check(bad.begins_with("The god could not be saved (error "), "a write to a missing place says so (%s)" % bad)
	t.check(Game.write_god(slot, FILE) == "", "a write that works says nothing")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	var src := FileAccess.get_file_as_string("res://src/game/game.gd")
	t.check(src.contains("write_god(slot, file)"), "load_god() writes through write_god() (pre-flight G1)")
	# The hub's line is joined, never doubled, whatever number of writes fail before it is shown (review I1, I2).
	var f := Game.WRITE_FAILED % 7
	t.check(Game.join_lines("", f) == f, "a failure on an empty hub line is the line (%s)" % Game.join_lines("", f))
	t.check(Game.join_lines("a", f) == "a " + f, "a failure after another line is appended (%s)" % Game.join_lines("a", f))
	t.check(Game.join_lines(f, f) == f, "the same failure twice is shown once (%s)" % Game.join_lines(f, f))
	t.check(Game.join_lines("a " + f, f) == "a " + f, "even after another line (%s)" % Game.join_lines("a " + f, f))
	t.check(Game.join_lines("a", "") == "a" and Game.join_lines("", "") == "", "nothing to add changes nothing")


## Task 5's carry: the seeded draw survives a quit. A god written before its Prepare and read back draws the same night.
static func _draw_survives_quit(t) -> void:
	_clear()
	GodTree.dev_fill = true
	var god := GodSlot.make(1, "ruin", 31337)
	god.night = 4
	god.last_mission = "warning"
	var before := GodNight.draw(god)
	t.check(god.write(FILE) == OK, "the slot is written before the player quits")
	var back: GodSlot = Game.load_god(FILE)[0]
	t.check(back != null and GodNight.draw(back) == before and back.night == 4,
		"read back, the same night is drawn (%s, %s)" % [GodNight.draw(back) if back != null else "-", before])
	# Quit mid-night: the next opening forfeits it, and the draw moves on (the night counted).
	back.in_night = before
	back.write(FILE)
	var after: GodSlot = Game.load_god(FILE)[0]
	t.check(after.night == 5 and after.last_mission == before and GodNight.draw(after) != before,
		"after a forfeit the night counted and the next draw is another mission (%s)" % GodNight.draw(after))
	GodTree.dev_fill = false


## P14: the board's header has an ENDLESS button beside DEV, with --dev only.
static func _endless_button(t) -> void:
	var at := MissionBoard.ENDLESS_RECT.get_center()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(SaveFile.new(), "warning")
	t.check(board.hit(at) == "endless", "with dev, the point on ENDLESS hits it (%s)" % board.hit(at))
	t.check(not MissionBoard.ENDLESS_RECT.intersects(MissionBoard.DEV_RECT) and Rect2(0, 0, 640, 360).encloses(MissionBoard.ENDLESS_RECT),
		"ENDLESS sits beside DEV, on screen")
	var got := []
	board.action.connect(func(what: String) -> void: got.append(what))
	board.click(at)
	t.check(got == ["endless"], "a click emits endless (%s)" % [got])
	t.check(board.hit(MissionBoard.dev_rect().get_center()) == "tab:%d" % MissionBoard.DEV_TIER, "DEV still opens its tab")
	board.free()
	var plain := MissionBoard.new()
	plain.setup(SaveFile.new(), "warning")
	var plain_got := []
	plain.action.connect(func(what: String) -> void: plain_got.append(what))
	plain.click(at)
	t.check(plain.hit(at) == "" and plain_got.is_empty(), "without dev there is no ENDLESS (%s, %s)" % [plain.hit(at), plain_got])
	plain.free()


## M1 (final review): a campaign's between-acts Prepare never shows the board's levels left in Game.levels; a board night's does.
static func _between_acts_levels(t) -> void:
	var left := {"smite": 4}
	t.check(Game.between_acts_levels(true, left).is_empty(), "the campaign re-draft shows no board levels (%s)" % [Game.between_acts_levels(true, left)])
	t.check(Game.between_acts_levels(false, left) == left, "a board night's re-draft shows the levels chosen so far (%s)" % [Game.between_acts_levels(false, left)])


## M9 (final review): a new god's seed is not the engine clock, so two gods made at once do not share their draws (Ruling P17).
static func _god_seed(t) -> void:
	var seen := {}
	for i in 64:
		seen[GodSlot.fresh_seed()] = true
	t.check(seen.size() == 64, "64 fresh seeds are all different (%d)" % seen.size())
	var text := FileAccess.get_file_as_string("res://src/game/game.gd")
	t.check(text.contains("GodSlot.make(god_slot, pick.chosen_type, GodSlot.fresh_seed())"),
		"Game makes a new god from fresh_seed()")
	t.check(not text.contains("GodSlot.make(god_slot, pick.chosen_type, Time.get_ticks_usec())"), "and no longer from the engine clock")
