extends RefCounted
## God P2 Task 1 (spec §9.1, §10.1-§10.3; plan Rulings P2-1 to P2-10, P2-12): the Lantern's rules -- the Notice moves after every night,
## 100% brings the Hunt, a won Hunt resets the Notice and pays Faith, a lost (or abandoned) one seals the most-carried ability for
## 3 nights and sets the Notice to 50, the seal ticks and never traps the god, and a damaged file reads in range.
## Keys come from the merged tree at test time (C2): the fixture type is the first with two starting keys (preflight R3).

const FILE := "user://test_god_lantern_%s.cfg"


static func run(t) -> void:
	GodTree.dev_fill = true
	_notice_deltas(t)
	_notice_clamp(t)
	_forfeit_notice(t)
	_hunt_due(t)
	_hunt_draw(t)
	_hunt_won(t)
	_hunt_lost(t)
	_hunt_forfeit(t)
	_seal_target(t)
	_seal_ticks(t)
	_seal_replaced(t)
	_seal_never_traps(t)
	_stake(t)
	_bad_seal_file(t)
	GodTree.dev_fill = false


## The first ring type with two starting keys (preflight R3); "" when none, which the first check reports.
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


static func _pair(s: GodSlot) -> PackedStringArray:
	return s.in_tree()


static func _name(key: String) -> String:
	return String(PowerBook.get_power(key).name)


static func _notice_deltas(t) -> void:
	t.check(_type() != "", "a fixture type with two starting keys exists in the merged tree")
	var s := _slot()
	var out := GodNight.bank(s, "warning", PackedStringArray(), _outcome(false, false))
	t.check(s.notice == 25 and out.notice == 25 and out.notice_change == 25, "a lost night: Notice +25 (%d, %d)" % [s.notice, out.notice_change])
	s = _slot()
	out = GodNight.bank(s, "warning", PackedStringArray(), _outcome(true, false))
	t.check(s.notice == 10 and out.notice_change == 10, "a caught win (main, not ascended): +10 (%d)" % s.notice)
	s = _slot()
	s.notice = 20
	out = GodNight.bank(s, "warning", PackedStringArray(), _outcome(true, true))
	t.check(s.notice == 15 and out.notice_change == -5, "a clean win (ascended): -5 (%d, %d)" % [s.notice, out.notice_change])
	s = _slot()
	out = GodNight.bank(s, "warning", PackedStringArray(), _outcome(true, true))
	t.check(s.notice == 0 and out.notice_change == 0, "from 0 a clean win stays 0 with no change (%d, %d)" % [s.notice, out.notice_change])
	s = _slot()
	s.notice = 50
	GodNight.bank(s, "warning", PackedStringArray(), _outcome(true, true))
	t.check(s.notice == 45, "from 50 a clean win is 45 (%d)" % s.notice)
	s = _slot()
	s.notice = 90
	out = GodNight.bank(s, "warning", PackedStringArray(), _outcome(false, false))
	t.check(s.notice == 100 and out.notice_change == 10 and out.hunt_next == true,
		"from 90 a lost night is 100 (the clamp), changes 10, and the Hunt is next (%d, %d, %s)" % [s.notice, out.notice_change, out.hunt_next])
	t.check(out.hunt.is_empty() and out.unsealed == "", "a night that is not a Hunt reports no Hunt and no unsealing")
	t.check(GodNight.notice_delta({"main": false}) == 25, "notice_delta: not main is NOTICE_LOST")
	t.check(GodNight.notice_delta({"main": true, "ascended": false}) == 10, "notice_delta: main, caught, is NOTICE_CAUGHT")
	t.check(GodNight.notice_delta({"main": true, "ascended": true}) == -5, "notice_delta: main and ascended is NOTICE_CLEAN")


static func _notice_clamp(t) -> void:
	var s := _slot()
	s.notice = 10
	t.check(s.add_notice(-30) == -10 and s.notice == 0, "from 10, add_notice(-30) changes -10 (%d)" % s.notice)
	s.notice = 80
	t.check(s.add_notice(40) == 20 and s.notice == 100, "from 80, add_notice(40) changes 20 (%d)" % s.notice)


static func _forfeit_notice(t) -> void:
	var s := _slot()
	s.notice = 25
	s.in_night = "warning"
	var out := GodNight.forfeit(s)
	t.check(s.notice == 50 and out.notice == 50 and out.notice_change == 25, "from 25 a forfeit is 50 (%d)" % s.notice)
	t.check(out.line == "Night 1 was abandoned: a lost night. Lantern Notice +25%.", "its line (%s)" % out.line)
	t.check(out.hunt.is_empty() and out.hunt_next == false and out.unsealed == "", "an ordinary forfeit reports no Hunt")


static func _hunt_due(t) -> void:
	for tier in range(1, 6):
		var s := _slot(tier)
		s.notice = 100
		var h := GodNight.hunt_for(s)
		var want: Dictionary = GodNight.HUNTS[tier - 1]
		t.check(s.hunt_due() and h.get("id", "") == want.id and h.get("title", "") == want.title and h.get("plate", "") == want.plate
			and int(h.get("tier", 0)) == tier, "at 100%% a tier %d god's Hunt is HUNTS[%d] with its tier (%s)" % [tier, tier - 1, h])
	var s := _slot()
	s.notice = 99
	t.check(not s.hunt_due() and GodNight.hunt_for(s).is_empty(), "at 99% there is no Hunt")
	t.check(GodNight.HUNTS.size() == 5, "five Hunts")
	t.check(GodNight.HUNTS[0].id == MissionBook.LOST_LAMB and GodNight.HUNTS[1].id == MissionBook.BELL_RINGERS
		and GodNight.HUNTS[2].id == MissionBook.INFORMER and GodNight.HUNTS[3].id == MissionBook.ARMOURY
		and GodNight.HUNTS[4].id == MissionBook.HEART_OF_FAITH, "the stand-ins are the MissionBook ids")
	for h2: Dictionary in GodNight.HUNTS:
		t.check(TierBook.has(h2.id), "the stand-in %s is on the board" % h2.id)


static func _hunt_draw(t) -> void:
	for tier in range(1, 6):
		var id: String = GodNight.HUNTS[tier - 1].id
		for seed_value in [3, 4, 99]:
			var s := _slot(tier, seed_value)
			s.notice = 100
			s.last_mission = id
			t.check(GodNight.draw(s) == id, "tier %d, seed %d, 100%%: draw() is the Hunt even when it was the last mission (%s)" % [tier, seed_value, GodNight.draw(s)])
			s.night = 7
			t.check(GodNight.draw(s) == id, "and on another night")
		var plain := _slot(tier)
		plain.notice = 99
		plain.last_mission = id
		var drawn := GodNight.draw(plain)
		t.check(drawn != id and TierBook.missions(tier).has(drawn), "tier %d at 99%%: a tier mission other than the last (%s)" % [tier, drawn])


static func _hunt_won(t) -> void:
	var s := _slot(2)
	s.notice = 100
	var keys := _pair(s)
	var id: String = GodNight.HUNTS[1].id
	var d := _outcome(true, false, 30, 0, 2)
	var out := GodNight.bank(s, id, PackedStringArray([keys[0]]), d)
	t.check(s.notice == 0 and out.notice == 0 and out.notice_change == -100, "a won Hunt sets the Notice to 0 (%d, %d)" % [s.notice, out.notice_change])
	t.check(s.faith == 130 and out.faith == 30 and out.faith_total == 130, "30 believers plus 50 x tier 2 Faith (%d, %d, %d)" % [s.faith, out.faith, out.faith_total])
	t.check(out.hunt.won == true and out.hunt.faith == 100 and out.hunt.id == id and out.hunt.tier == 2 and out.hunt.title == GodNight.HUNTS[1].title,
		"the Hunt result: won, 100 Faith (%s)" % [out.hunt])
	t.check(out.divine_power == GodNight.divine_power(d["descend"]) and out.divine_power > 0, "Divine Power as any night (%d)" % out.divine_power)
	t.check(not s.bests.has(id) and out.bests.is_empty(), "no best is kept for a Hunt (%s)" % [s.bests])
	t.check(s.last_mission == id and s.night == 1 and s.in_night == "", "the stand-in is the last mission and the night counts")
	t.check(int(s.carried.get(keys[0], 0)) == 1, "the Hunt's draft is carried")
	t.check(out.hunt_next == false and s.sealed == "", "no Hunt next and nothing sealed")
	t.check(out.hunt.sealed == "" and out.hunt.seal_nights == 0, "a won Hunt seals nothing")


static func _hunt_lost(t) -> void:
	var s := _slot()
	s.notice = 100
	var keys := _pair(s)
	s.carried[keys[0]] = 3
	s.faith = 4
	var want := s.seal_target()
	t.check(want == keys[0], "the target is the most carried (%s)" % want)
	var id: String = GodNight.HUNTS[0].id
	var out := GodNight.bank(s, id, PackedStringArray([keys[0], keys[1]]), _outcome(false, false, 6))
	t.check(s.sealed == want and s.seal_nights == 3, "a lost Hunt seals the target for 3 nights (%s, %d)" % [s.sealed, s.seal_nights])
	t.check(s.notice == 50 and out.notice == 50 and out.notice_change == -50, "and sets the Notice to 50, no +25 on top (%d, %d)" % [s.notice, out.notice_change])
	t.check(not s.loadout.has(want) and s.loadout.has(keys[1]), "the sealed key leaves the remembered loadout (%s)" % [s.loadout])
	t.check(out.hunt.won == false and out.hunt.sealed == want and out.hunt.seal_nights == 3 and out.hunt.faith == 0, "the Hunt result: lost, sealed (%s)" % [out.hunt])
	t.check(s.faith == 10 and out.faith == 6 and out.faith_total == 10, "no bonus Faith, the believers bank (%d)" % s.faith)
	t.check(out.divine_power == 0, "no Divine Power")
	t.check(not s.draftable().has(want) and s.in_tree().has(want), "the key is out of draftable() and still in_tree()")
	t.check(out.unsealed == "" and out.hunt_next == false, "nothing unsealed, no Hunt next")


static func _hunt_forfeit(t) -> void:
	var s := _slot()
	s.notice = 100
	var keys := _pair(s)
	s.carried[keys[1]] = 2
	var want := s.seal_target()
	s.in_night = GodNight.HUNTS[0].id
	var out := GodNight.forfeit(s)
	t.check(s.sealed == want and s.seal_nights == 3 and s.notice == 50, "an abandoned Hunt seals and sets 50 (%s, %d, %d)" % [s.sealed, s.seal_nights, s.notice])
	var line := "Night 1 was abandoned: the Hunt is lost. The Lantern seals %s for 3 nights. Lantern Notice 50%%." % _name(want)
	t.check(out.line == line, "its line (%s)" % out.line)
	t.check(out.hunt.won == false and out.hunt.sealed == want and out.notice == 50 and out.notice_change == -50, "the result (%s)" % [out.hunt])
	t.check(s.last_mission == GodNight.HUNTS[0].id and s.in_night == "" and s.night == 1, "the night counts and closes")
	t.check(s.carried == {keys[1]: 2}, "a forfeit carries nothing (%s)" % [s.carried])


## Two keys in the merged tree (any type) whose level 1 Might is equal; the earlier first in spot order. Empty when none.
static func _equal_might_pair() -> PackedStringArray:
	var keys := PackedStringArray()
	for sp: Dictionary in GodTree.spots():
		if sp.key != "":
			keys.append(sp.key)
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			if PowerBook.might(keys[i], 1) == PowerBook.might(keys[j], 1):
				return PackedStringArray([keys[i], keys[j]])
	return PackedStringArray()


static func _seal_target(t) -> void:
	var s := _slot()
	s.learned = {}
	var pair := _equal_might_pair()
	t.check(pair.size() == 2, "the merged tree has two keys of equal Might (needed by this test)")
	if pair.size() != 2:
		return
	s.learned = {pair[0]: 1, pair[1]: 1}
	t.check(s.in_tree() == pair, "in_tree() is the learned keys in spot order (%s)" % [s.in_tree()])
	t.check(s.seal_target() == pair[0], "equal on carried and Might: the earlier in the tree (%s)" % s.seal_target())
	s.carried[pair[1]] = 1
	t.check(s.seal_target() == pair[1], "the most carried wins (%s)" % s.seal_target())
	s.carried = {pair[0]: 2, pair[1]: 2}
	t.check(s.seal_target() == pair[0], "a tie on carried and Might goes to the earlier (%s)" % s.seal_target())
	s.learned[pair[1]] = PowerBook.MAX_LEVEL
	t.check(s.might_of(pair[1]) > s.might_of(pair[0]) and s.seal_target() == pair[1], "a tie on carried goes to the higher Might (%d vs %d)" % [s.might_of(pair[1]), s.might_of(pair[0])])
	s.learned[pair[1]] = 1
	# A learned key in no spot is never a target, however often it was carried.
	var outside := ""
	for key in PowerBook.keys():
		if GodTree.spot_of(key).is_empty():
			outside = key
			break
	if outside != "":
		s.learned[outside] = 1
		s.carried[outside] = 50
		t.check(s.seal_target() == pair[0] and not s.in_tree().has(outside), "a learned key in no spot is not in the tree and is never sealed")
	# The Hunt's own draft is counted after the target is chosen (Ruling P2-7).
	var f := _slot()
	f.notice = 100
	var two := f.in_tree()
	f.carried = {two[0]: 2, two[1]: 2}
	var target := f.seal_target()
	var other := two[1] if target == two[0] else two[0]
	GodNight.bank(f, GodNight.HUNTS[0].id, PackedStringArray([other]), _outcome(false, false))
	t.check(f.sealed == target and int(f.carried[other]) == 3 and other != target,
		"the Hunt's draft is counted after: %s is sealed, not %s, though %s now has 3 (%s)" % [target, other, other, f.sealed])
	var one := _slot()
	one.learned = {two[0]: 1}
	t.check(one.in_tree().size() == 1 and one.seal_target() == "", "one key in the tree: nothing to seal")


static func _seal_ticks(t) -> void:
	var s := _slot()
	var keys := _pair(s)
	var k := keys[0]
	s.seal(k)
	t.check(s.sealed == k and s.seal_nights == 3, "seal() seals for 3 nights")
	s.loadout = PackedStringArray([k, keys[1]])
	s.seal(k)
	t.check(not s.loadout.has(k), "seal() drops the key from the loadout")
	var out := GodNight.bank(s, "warning", PackedStringArray(), _outcome(true, true))
	t.check(s.seal_nights == 2 and out.unsealed == "" and not s.draftable().has(k) and s.in_tree().has(k), "bank: 2 nights left (%d)" % s.seal_nights)
	s.in_night = "warning"
	var f := GodNight.forfeit(s)
	t.check(s.seal_nights == 1 and f.unsealed == "" and not s.draftable().has(k), "forfeit: 1 night left (%d)" % s.seal_nights)
	t.check(not String(f.line).ends_with("no longer sealed."), "the forfeit line does not yet say it ended (%s)" % f.line)
	out = GodNight.bank(s, "warning", PackedStringArray(), _outcome(true, true))
	t.check(s.seal_nights == 0 and s.sealed == "" and out.unsealed == k and s.draftable().has(k), "the third night ends the seal (%s, %d)" % [s.sealed, s.seal_nights])
	# A forfeit on the last night says so on its line.
	var g := _slot()
	g.seal(k)
	g.seal_nights = 1
	g.in_night = "warning"
	var line := String(GodNight.forfeit(g).line)
	t.check(line == "Night 1 was abandoned: a lost night. Lantern Notice +25%%. %s is no longer sealed." % _name(k),
		"a forfeit on the last night ends with the unsealed line (%s)" % line)
	t.check(g.sealed == "", "and the seal is gone")
	t.check(g.tick_seal() == "", "tick_seal() with no seal does nothing")


static func _seal_replaced(t) -> void:
	var s := _slot()
	var keys := _pair(s)
	s.seal(keys[0])
	s.seal_nights = 1
	s.notice = 100
	s.carried = {keys[1]: 4}
	var out := GodNight.bank(s, GodNight.HUNTS[0].id, PackedStringArray([keys[0]]), _outcome(false, false))
	t.check(s.sealed == keys[1] and s.seal_nights == 3, "a lost Hunt on a seal's last night replaces it with a fresh 3 (%s, %d)" % [s.sealed, s.seal_nights])
	t.check(out.unsealed == "", "and reports no unsealing")
	t.check(s.draftable().has(keys[0]) and not s.draftable().has(keys[1]), "the old key is free again")


static func _seal_never_traps(t) -> void:
	var s := _slot()
	s.notice = 100
	var keys := _pair(s)
	s.learned = {keys[0]: 1, keys[1]: 1}
	var out := GodNight.bank(s, GodNight.HUNTS[0].id, PackedStringArray([keys[0]]), _outcome(false, false))
	t.check(s.sealed != "" and s.draftable().size() == 1, "two keys: one sealed, one left to draft (%s, %s)" % [s.sealed, s.draftable()])
	t.check(out.hunt.sealed == s.sealed, "the result names the seal")
	var one := _slot()
	one.learned = {keys[0]: 1}
	one.notice = 100
	one.in_night = GodNight.HUNTS[0].id
	var f := GodNight.forfeit(one)
	t.check(one.sealed == "" and one.seal_nights == 0 and one.notice == 50 and f.hunt.sealed == "", "one key: nothing sealed, Notice 50 (%s, %d)" % [one.sealed, one.notice])
	t.check(f.line == "Night 1 was abandoned: the Hunt is lost. The Lantern found nothing to seal. Lantern Notice 50%.", "the forfeit line says nothing was sealed (%s)" % f.line)
	var b := _slot()
	b.learned = {keys[0]: 1}
	b.notice = 100
	var out2 := GodNight.bank(b, GodNight.HUNTS[0].id, PackedStringArray([keys[0]]), _outcome(false, false))
	t.check(b.sealed == "" and out2.hunt.sealed == "" and b.notice == 50 and b.draftable().size() == 1, "banked likewise")


static func _stake(t) -> void:
	var s := _slot()
	s.notice = 100
	var target := s.seal_target()
	t.check(GodNight.hunt_stake(s) == "The Lantern will seal %s for 3 nights" % _name(target), "the stake names the ability and the nights (%s)" % GodNight.hunt_stake(s))
	s.learned = {target: 1}
	t.check(GodNight.hunt_stake(s) == "The Lantern has nothing to seal", "one key: nothing to seal (%s)" % GodNight.hunt_stake(s))
	t.check(GodSlot.nights_text(1) == "1 night" and GodSlot.nights_text(3) == "3 nights", "nights_text")


## Writes `pairs` into a bare [god] section, reads it through GodSlot.read, removes the file.
static func _read_with(tag: String, pairs: Dictionary) -> GodSlot:
	var file := FILE % tag
	var cfg := ConfigFile.new()
	for k: String in pairs:
		cfg.set_value(GodSlot.SECTION, k, pairs[k])
	cfg.save(file)
	var s := GodSlot.read(file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	return s


static func _bad_seal_file(t) -> void:
	var key := _pair(_slot())[0]
	var s := _read_with("a", {"type": _type(), "sealed": key, "seal_nights": 9})
	t.check(s != null and s.sealed == key and s.seal_nights == GodSlot.SEAL_NIGHTS, "seal_nights 9 reads as 3 (%d)" % [s.seal_nights if s != null else -1])
	s = _read_with("b", {"type": _type(), "sealed": key, "seal_nights": 0})
	t.check(s != null and s.sealed == "" and s.seal_nights == 0, "a key with 0 nights reads as no seal")
	s = _read_with("c", {"type": _type(), "sealed": "", "seal_nights": 2})
	t.check(s != null and s.sealed == "" and s.seal_nights == 0, "nights with no key read as no seal")
	s = _read_with("d", {"type": _type(), "notice": -5})
	t.check(s != null and s.notice == 0, "notice -5 reads as 0")
	s = _read_with("e", {"type": _type(), "notice": 400})
	t.check(s != null and s.notice == 100, "notice 400 reads as 100")
	var file := FILE % "f"
	GodSlot.make(1, _type(), 3).write(file)
	var p1 := GodSlot.read(file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	t.check(p1 != null and p1.notice == 0 and p1.sealed == "" and p1.seal_nights == 0 and p1.version == 1, "a P1 slot reads with Notice 0 and no seal")
	var w := _slot()
	w.seal(key)
	w.notice = 100
	w.write(file)
	var back := GodSlot.read(file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	t.check(back != null and back.sealed == key and back.seal_nights == 3 and back.notice == 100 and back.hunt_due(), "a seal and the Notice round-trip")
