extends RefCounted
## God P1 Task 4 (spec §4, §5.3, §6, §7, §8): the god's save slot -- its fields round-trip and read safely, ability points and costs,
## the tier gate, Might and slots, Divine Power and the level cap, Faith upgrades and respec, the draftable pool, starting abilities.

const FILE := "user://test_god_slot_%s.cfg"


static func run(t) -> void:
	GodTree.dev_fill = true
	_make(t)
	_round_trip(t)
	_bad_file(t)
	_costs(t)
	_tier_gate(t)
	_levels(t)
	_neighbour(t)
	_xp(t)
	_cap_stops(t)
	_max_level(t)
	_points_total(t)
	_faith_prices(t)
	_faith_short(t)
	_respec(t)
	_draftable(t)
	_ensure_starting(t)
	GodTree.dev_fill = false


static func _slot(type := "ruin") -> GodSlot:
	return GodSlot.make(1, type, 7)


static func _file(tag: String) -> String:
	return FILE % tag


## Writes `section` pairs into a file as a bare [god] section, reads it back through GodSlot.read, then removes the file.
static func _read_with(tag: String, pairs: Dictionary) -> GodSlot:
	var file := _file(tag)
	var cfg := ConfigFile.new()
	for k: String in pairs:
		cfg.set_value(GodSlot.SECTION, k, pairs[k])
	cfg.save(file)
	var s := GodSlot.read(file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	return s


static func _make(t) -> void:
	var s := GodSlot.make(1, "ruin", 7)
	t.check(s.level == 1 and s.tier == 1 and s.points == 0, "a new god: level 1, tier 1, no points (%d, %d, %d)" % [s.level, s.tier, s.points])
	t.check(s.learned == {"smite": 1, "ember": 1}, "its two Tier 1 abilities are learned at level 1, free (%s)" % [s.learned])
	t.check(s.faith == 0 and s.notice == 0 and s.night == 0, "no Faith, Notice or nights (%d, %d, %d)" % [s.faith, s.notice, s.night])
	t.check(s.slots() == 3 and s.max_might() == 6, "3 slots and 6 Might (%d, %d)" % [s.slots(), s.max_might()])
	t.check(s.need() == 50 and s.cap() == 10, "a level costs 50 and the cap is 10 (%d, %d)" % [s.need(), s.cap()])
	t.check(s.index == 1 and s.type == "ruin" and s.seed == 7 and s.name == "", "index, type and seed are kept, the name is empty")
	t.check(GodSlot.path(2) == "user://kak_god_2.cfg" and GodSlot.path(3, "user://x_") == "user://x_3.cfg", "path(): base + n + .cfg")
	t.check(s.starting() == PackedStringArray(["smite", "ember"]), "starting() is the type's Tier 1 (%s)" % [s.starting()])


static func _round_trip(t) -> void:
	var s := GodSlot.make(2, "decree", 12345)
	s.name = "Orrin"
	s.level = 17
	s.tier = 2
	s.divine_power = 61
	s.points = 4
	s.learned = {"noleave": 3, "belllies": 1, "magnify": 2}
	s.faith = 88
	s.bought = {"slot": 2, "might": 1, "clock": 3, "respec": 1}
	s.notice = 35
	s.sealed = "noleave"
	s.seal_nights = 2
	s.night = 9
	s.last_mission = "tax_collector"
	s.in_night = "warning"
	s.gifts = PackedStringArray(["watchful_bell", "walls_hold"])
	s.bests = {"warning": {"cleared": true, "fastest": 143.5, "most_wishes": 2}}
	s.carried = {"noleave": 5, "belllies": 2}
	s.loadout = PackedStringArray(["noleave", "magnify"])
	var file := _file("round")
	t.check(s.write(file) == OK, "write() saves")
	var r := GodSlot.read(file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	t.check(r != null, "the slot reads back")
	if r == null:
		return
	var same := r.index == s.index and r.name == s.name and r.type == s.type and r.level == s.level and r.divine_power == s.divine_power
	same = same and r.tier == s.tier and r.points == s.points and r.learned == s.learned and r.faith == s.faith and r.bought == s.bought
	same = same and r.notice == s.notice and r.sealed == s.sealed and r.seal_nights == s.seal_nights and r.night == s.night
	same = same and r.last_mission == s.last_mission and r.in_night == s.in_night and r.gifts == s.gifts and r.bests == s.bests
	same = same and r.carried == s.carried and r.loadout == s.loadout and r.seed == s.seed and r.version == s.version
	t.check(same, "index, name, type, level, divine_power, tier, points, learned, faith, bought, notice, sealed, seal_nights, night, "
		+ "last_mission, in_night, gifts, bests, carried, loadout, seed and version all round-trip (%s | %s)" % [r.learned, r.bests])


static func _bad_file(t) -> void:
	var gone := GodSlot.read(_file("missing"))
	t.check(gone == null, "a missing file reads as an empty slot")
	var wrong := _read_with("type", {"type": "nosuch", "level": 3})
	t.check(wrong == null, "an unknown type reads as an empty slot (Ruling P23)")
	var notype := _read_with("notype", {"level": 3})
	t.check(notype == null, "a file with no type reads as an empty slot")
	var intype := _read_with("inttype", {"type": 5})
	t.check(intype == null, "a type that is not a string reads as an empty slot")
	var s := _read_with("bad", {"type": "ruin", "level": 99, "faith": -5, "divine_power": 999,
		"learned": {"nosuch": 3, "smite": 9}, "bought": {"slot": 9, "might": -2}, "notice": 250, "last_mission": "nosuch",
		"loadout": PackedStringArray(["nosuch", "smite"])})
	t.check(s != null, "a hand-edited file reads")
	if s == null:
		return
	t.check(s.tier == 1 and s.level == s.cap() and s.level == 10, "level 99 at tier 1 reads as the cap, 10 (%d)" % s.level)
	var high := _read_with("high", {"type": "ruin", "tier": 9, "level": 99})
	t.check(high.tier == 5 and high.level == 50, "tier 9 reads as 5, and level 99 as 50 (%d, %d)" % [high.tier, high.level])
	t.check(s.faith == 0, "Faith -5 reads as 0 (%d)" % s.faith)
	t.check(s.notice == 100, "Notice 250 reads as 100 (%d)" % s.notice)
	t.check(s.last_mission == "", "an unknown last mission reads as none")
	t.check(s.loadout == PackedStringArray(["smite"]), "an unknown loadout key is dropped (%s)" % [s.loadout])
	t.check(s.learned == {"smite": 5, "ember": 1}, "an unknown power is dropped, level 9 reads as 5, a missing start is ensured (%s)" % [s.learned])
	t.check(s.bought == {"slot": 3, "might": 0}, "bought counts are pulled into their limits (%s)" % [s.bought])
	var bar := _read_with("bar", {"type": "ruin", "divine_power": 999})
	t.check(bar.divine_power == 50, "Divine Power 999 at tier 1 reads as the bar's need, 50 (%d)" % bar.divine_power)
	var junk := _read_with("junk", {"type": "death", "level": "x", "points": -4, "learned": 5, "bought": "y", "bests": {"nosuch": {}, "warning": 3},
		"sealed": "nosuch", "in_night": "nosuch", "gifts": 4, "night": -1})
	t.check(junk != null and junk.level == 1 and junk.points == 0 and junk.night == 0 and junk.sealed == "" and junk.in_night == ""
		and junk.bests.is_empty() and junk.gifts.is_empty() and junk.bought.is_empty(),
		"wrong kinds of value read as the default")
	var best := _read_with("best", {"type": "death", "bests": {"warning": {"cleared": true, "fastest": -3.0, "most_wishes": -1}}})
	t.check(best.bests == {"warning": {"cleared": true, "fastest": 0.0, "most_wishes": 0}}, "a best is pulled into range (%s)" % [best.bests])


static func _costs(t) -> void:
	var s := _slot()
	t.check(s.cost("smite") == 1, "an own-type spot costs 1 (%d)" % s.cost("smite"))
	t.check(s.cost("deathmark") == 2 and s.cost("whisper") == 2, "a neighbour's spot costs 2 (%d, %d)" % [s.cost("deathmark"), s.cost("whisper")])
	t.check(s.cost("doom") == 0 and s.refusal("doom") == "far", "a far type's spot is locked (%d, %s)" % [s.cost("doom"), s.refusal("doom")])
	t.check(s.refusal("congregation") == "unknown" and s.cost("congregation") == 0, "a key in no dev spot is unknown (%s)" % s.refusal("congregation"))
	t.check(s.spot_type("heaven") == "ruin" and s.spot_type("nosuch") == "", "spot_type() names the type or nothing")


static func _tier_gate(t) -> void:
	var s := _slot()
	s.points = 5
	t.check(s.refusal("heaven") == "tier", "a Tier 2 spot is refused at god tier 1 (%s)" % s.refusal("heaven"))
	s.awaken()
	t.check(s.learn("heaven") and s.level_of("heaven") == 1 and s.points == 6, "after Awaken it is learned at 1 for a point (%d, %d)" % [s.level_of("heaven"), s.points])
	var hold := _slot()
	hold.points = 5
	hold.learned["heaven"] = 1
	t.check(hold.refusal("heaven") == "", "raising is never tier-gated (%s)" % hold.refusal("heaven"))


static func _levels(t) -> void:
	var s := _slot()
	s.points = 4
	t.check(s.might_of("smite") == PowerBook.might("smite", 1), "Might at level 1 is the base (%d)" % s.might_of("smite"))
	var ok := true
	for i in 4:
		if i == 1:
			t.check(s.might_of("smite") == PowerBook.get_power("smite").dp, "at level 2 Might is the base (%d)" % s.might_of("smite"))
		ok = ok and s.learn("smite")
		if s.level_of("smite") == 3:
			t.check(s.might_of("smite") == PowerBook.get_power("smite").dp + 1, "at level 3 Might is one more (%d)" % s.might_of("smite"))
	t.check(ok and s.level_of("smite") == 5 and s.points == 0, "1 -> 5 costs 4 points (level %d, points %d)" % [s.level_of("smite"), s.points])
	t.check(s.refusal("smite") == "max" and not s.learn("smite"), "level 5 is the most (%s)" % s.refusal("smite"))
	t.check(s.might_of("smite") == PowerBook.get_power("smite").dp + 2, "at level 5 Might is the base + 2 (%d)" % s.might_of("smite"))
	var none := _slot()
	t.check(none.refusal("tornado") != "" and not none.learn("tornado") and none.level_of("tornado") == 0, "no points, no learning")


static func _neighbour(t) -> void:
	var s := _slot()
	s.tier = 2
	s.points = 10
	var ok := true
	for i in 5:
		ok = ok and s.learn("deathmark")
	t.check(ok and s.level_of("deathmark") == 5 and s.points == 0, "a neighbour's ability costs 2 x 5 = 10 (level %d, points %d)" % [s.level_of("deathmark"), s.points])
	var short := _slot()
	short.points = 1
	t.check(short.refusal("pestilence") == "points" and not short.learn("pestilence") and short.points == 1,
		"1 point is short of a neighbour's 2 (%s)" % short.refusal("pestilence"))


static func _xp(t) -> void:
	var s := _slot()
	var r := s.gain_dp(80)
	t.check(s.level == 2 and s.points == 1 and s.divine_power == 30, "80 Divine Power: level 2, 1 point, bar 30 (%d, %d, %d)" % [s.level, s.points, s.divine_power])
	t.check(r.levels == PackedInt32Array([2]) and r.points == 1 and r.lost == 0 and not r.capped, "the report says so (%s)" % [r])
	var f := _slot()
	var big := f.gain_dp(500)
	var want := PackedInt32Array([2, 3, 4, 5, 6, 7, 8, 9, 10])
	t.check(big.levels == want and f.points == 9 and big.points == 9, "500 crosses nine levels, a point each (%s, %d)" % [big.levels, f.points])
	t.check(f.divine_power == 50 and big.lost == 0 and big.capped and f.level == 10, "the leftover fills the bar and nothing is lost (%d, %d)" % [f.divine_power, big.lost])
	var more := f.gain_dp(30)
	t.check(more.lost == 30 and f.level == 10 and f.divine_power == 50 and more.levels.is_empty() and more.capped,
		"capped: 30 is lost and the bar stays full (%s)" % [more])
	var zero := _slot().gain_dp(-5)
	t.check(zero.lost == 0 and zero.levels.is_empty(), "a negative gain does nothing")


static func _cap_stops(t) -> void:
	var s := _slot()
	s.gain_dp(500)
	for amount in [1, 50, 400]:
		s.gain_dp(amount)
		t.check(s.level == 10 and s.divine_power == 50, "at level 10 a gain of %d leaves level 10, bar full (%d, %d)" % [amount, s.level, s.divine_power])
	var before := s.points
	s.awaken()
	t.check(s.tier == 2 and s.cap() == 20 and s.need() == 100 and s.points == before + 2 and s.divine_power == 50 and not s.capped(),
		"Awaken: tier 2, cap 20, need 100, 2 points, the bar kept (%d, %d, %d, %d, %d)" % [s.tier, s.cap(), s.need(), s.points - before, s.divine_power])
	var up := s.gain_dp(50)
	t.check(s.level == 11 and up.levels == PackedInt32Array([11]) and s.divine_power == 0, "the kept bar plus 50 makes level 11 at the new need (%d, %d)" % [s.level, s.divine_power])


static func _max_level(t) -> void:
	var s := _slot()
	s.tier = 5
	s.level = 49
	var r := s.gain_dp(100000)
	t.check(s.level == 50 and s.capped(), "tier 5 stops at level 50 (%d)" % s.level)
	t.check(r.lost > 0 and r.capped and s.divine_power == s.need() and r.levels == PackedInt32Array([50]), "the excess is lost (%s)" % [r])
	s.awaken()
	t.check(s.tier == 5, "Awaken does nothing past tier 5 (%d)" % s.tier)


static func _points_total(t) -> void:
	var s := _slot()
	for rite in 4:
		s.gain_dp(1000000)
		s.awaken()
	s.gain_dp(1000000)
	t.check(s.level == 50 and s.tier == 5, "four rites and a great deal of Divine Power: level 50, tier 5 (%d, %d)" % [s.level, s.tier])
	t.check(s.points_earned() == 57 and s.points == 57, "points earned are 49 + 8 = 57 (%d, %d)" % [s.points_earned(), s.points])
	t.check(_slot().points_earned() == 0, "a new god has earned none")


static func _faith_prices(t) -> void:
	var s := _slot()
	s.faith = 2000
	var prices := []
	for i in 3:
		prices.append(s.faith_price("slot"))
		s.buy("slot")
	t.check(prices == [150, 300, 450], "slots cost 150, 300, 450 (%s)" % [prices])
	t.check(s.faith_refusal("slot") == "limit" and not s.buy("slot") and s.slots() == 6, "a fourth slot is the limit, slots() is 6 (%s, %d)" % [s.faith_refusal("slot"), s.slots()])
	prices = []
	for i in 6:
		prices.append(s.faith_price("might"))
		s.buy("might")
	t.check(prices == [25, 50, 75, 100, 125, 150], "Might costs 25 x n (%s)" % [prices])
	t.check(s.faith_refusal("might") == "limit" and s.max_might() == 12, "a seventh is the limit, max Might 12 (%s, %d)" % [s.faith_refusal("might"), s.max_might()])
	prices = []
	for i in 4:
		prices.append(s.faith_price("clock"))
		s.buy("clock")
	t.check(prices == [40, 80, 120, 160], "the clock costs 40 x n (%s)" % [prices])
	t.check(s.faith_refusal("clock") == "limit" and s.extra_clock() == 60.0, "a fifth is the limit, +60 s (%s, %f)" % [s.faith_refusal("clock"), s.extra_clock()])
	t.check(s.faith == 2000 - 900 - 525 - 400, "Faith is spent (%d)" % s.faith)
	var r := _slot()
	t.check(r.faith_price("respec") == 100, "respec costs 100 first (%d)" % r.faith_price("respec"))
	r.faith = 500
	r.gain_dp(60)
	t.check(r.learn("smite"), "a point earned and spent")
	t.check(r.buy("respec") and r.faith_price("respec") == 200, "after one respec it costs 200 (%d)" % r.faith_price("respec"))
	t.check(r.faith_price("nosuch") == 0 and r.faith_refusal("nosuch") == "unknown" and not r.buy("nosuch"), "an unknown row is refused")


static func _faith_short(t) -> void:
	var s := _slot()
	s.faith = 10
	t.check(s.faith_refusal("might") == "faith", "10 Faith is short of 25 (%s)" % s.faith_refusal("might"))
	t.check(not s.buy("might") and s.faith == 10 and s.bought.get("might", 0) == 0, "a refused buy changes nothing (%d)" % s.faith)


static func _respec(t) -> void:
	var s := _slot()
	s.tier = 2
	s.learned = {"smite": 3, "ember": 1, "heaven": 2}
	s.points = 0
	s.faith = 100
	t.check(s.faith_refusal("respec") == "", "respec is possible once points are spent (%s)" % s.faith_refusal("respec"))
	t.check(s.buy("respec"), "respec buys")
	t.check(s.learned == {"smite": 1, "ember": 1}, "only the starting two stay, at level 1 (%s)" % [s.learned])
	t.check(s.points == s.points_earned() and s.points == 2, "points are everything earned (%d)" % s.points)
	t.check(s.faith == 0, "it cost the 100 Faith (%d)" % s.faith)
	var fresh := _slot()
	fresh.faith = 500
	t.check(fresh.faith_refusal("respec") == "nothing" and not fresh.buy("respec") and fresh.faith == 500,
		"a fresh god has nothing to reset (%s)" % fresh.faith_refusal("respec"))
	s.faith = 500
	t.check(s.faith_refusal("respec") == "nothing", "right after a respec there is nothing to reset (%s)" % s.faith_refusal("respec"))


static func _draftable(t) -> void:
	var s := _slot()
	s.learned = {"deathmark": 1, "smite": 1, "ember": 1}
	t.check(s.draftable() == PackedStringArray(["smite", "ember", "deathmark"]), "draftable follows spot order (%s)" % [s.draftable()])
	s.sealed = "smite"
	t.check(s.draftable() == PackedStringArray(["ember", "deathmark"]), "a sealed ability is not draftable (%s)" % [s.draftable()])
	s.learned["nosuch_spot"] = 2
	t.check(not s.draftable().has("nosuch_spot") and s.learned.has("nosuch_spot"), "a learned key in no spot is kept but not draftable")
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	t.check(s.draftable().is_empty(), "with the dev fill off and the real table empty nothing is draftable (%s)" % [s.draftable()])
	GodTree.use_table({})
	t.check(s.draftable() == PackedStringArray(["ember", "deathmark"]),
		"with the dev fill off the real Tier 1 fill drafts what is learned there, smite still sealed (%s)" % [s.draftable()])
	GodTree.dev_fill = true


static func _ensure_starting(t) -> void:
	var s := _read_with("start", {"type": "ruin", "points": 3, "learned": {}})
	t.check(s != null and s.learned == {"smite": 1, "ember": 1} and s.points == 3, "an old god gets its starting two free, points unchanged (%s)" % [s.learned if s else null])
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var bare := _read_with("start_off", {"type": "ruin", "learned": {}})
	t.check(bare.learned.is_empty(), "with no fill there is nothing to give")
	GodTree.use_table({})
	var real := _read_with("start_real", {"type": "ruin", "learned": {}})
	t.check(real.learned == {"smite": 1, "ember": 1}, "with the dev fill off the real Tier 1 fill gives its two (%s)" % [real.learned])
	GodTree.dev_fill = true
