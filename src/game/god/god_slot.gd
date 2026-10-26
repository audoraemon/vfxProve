class_name GodSlot
extends RefCounted
## One save slot, one god (god P1, spec §4): its type, level and Divine Power, tier, ability points, learned abilities and their
## levels, Faith and the Faith upgrades bought, the Lantern Notice, the seal, the night counter, the stolen gifts and its own bests.
## One file per slot, `user://kak_god_<n>.cfg`; the board's save is never touched (C7). This class holds the rules every screen
## shows: points and costs (§5.3), tier gate (§5.2), Might and slots (§6), Faith (§7), Divine Power and the level cap (§8).

## Slots the player has (spec §4, my call).
const COUNT := 3
## A slot's file is PATH_BASE + n + ".cfg" (n 1-3).
const PATH_BASE := "user://kak_god_"
## The config section a slot is written under.
const SECTION := "god"
## The file's format version, written with every slot.
const VERSION := 1
## The highest god level (spec §8).
const MAX_LEVEL := 50
## God levels a god tier holds: level 10, 20, 30 and 40 end a tier (spec §8).
const LEVELS_PER_TIER := 10
## Divine Power one level costs per god tier: `XP_PER_LEVEL x tier` (spec §8; *tunable*).
const XP_PER_LEVEL := 50
## Points an Awaken rite gives (spec §5.3).
const AWAKEN_POINTS := 2
## Slots every god starts with, before Faith upgrades (spec §6).
const BASE_SLOTS := 3
## The Notice's highest value, in percent (spec §10.1).
const NOTICE_MAX := 100
## Faith one banked believer gives (spec §7, my call: 1:1).
const FAITH_PER_BELIEVER := 1
## Seconds one +15 S DESCENT upgrade adds to the descent clock (spec §7).
const CLOCK_STEP := 15.0
## A bought count the file may not exceed for an upgrade with no limit (a hand-edited file).
const UNLIMITED_CAP := 999

## The Faith screen's rows (spec §7; prices *tunable*; new rows are data). `prices` lists each purchase's price in turn; `step` makes
## the n-th cost `step x n`; `limit` is the most purchases, 0 for none.
const FAITH := [
	{"key": "slot", "name": "+1 SLOT", "prices": [150, 300, 450], "limit": 3},
	{"key": "might", "name": "+1 MIGHT", "step": 25, "limit": 6},
	{"key": "clock", "name": "+15 S DESCENT", "step": 40, "limit": 4},
	{"key": "respec", "name": "RESET ABILITY POINTS", "step": 100, "limit": 0},
]

## Which slot this is (1-3); 0 when the file did not say.
var index := 0
## The god's name; empty in P1 (a slot shows its type's title: Ruling P15).
var name := ""
## The god's type, one of GodTree.RING; chosen once when the slot is made (spec §4).
var type := ""
## The god level (1-50).
var level := 1
## Divine Power toward the next level (spec §8): the bar.
var divine_power := 0
## The god tier (1-5); an Awaken rite raises it.
var tier := 1
## Unspent ability points.
var points := 0
## Learned abilities: PowerBook key -> level 1-5.
var learned := {}
## Faith (spec §7).
var faith := 0
## Faith upgrades bought: FAITH key -> count (a key appears once it is bought, or read from a file).
var bought := {}
## The Lantern Notice, in percent (written and read in P1; always 0 until P2: C9).
var notice := 0
## The sealed ability's key, or "" (P2).
var sealed := ""
## Nights the seal has left (P2).
var seal_nights := 0
## Nights played.
var night := 0
## The last mission played, a board mission id, or "".
var last_mission := ""
## The mission whose clock has started and not yet ended, or "" (Ruling P9: no escape by quitting).
var in_night := ""
## Stolen gifts won by Awaken rites (P3-P4); ids as strings.
var gifts := PackedStringArray()
## Per-mission bests for this god: mission id -> {"cleared": bool, "fastest": float, "most_wishes": int}.
var bests := {}
## Nights each ability was drafted: PowerBook key -> count (Ruling P16, for P2's most-carried).
var carried := {}
## The last drafted loadout.
var loadout := PackedStringArray()
## Made once at creation; the night draw reads it (Task 5).
var seed := 0
## The file's format version.
var version := VERSION


## The file for slot `n` (1-3) under `base`.
static func path(n: int, base := PATH_BASE) -> String:
	return "%s%d.cfg" % [base, n]


## The generator behind fresh_seed(), made on first use.
static var _seeds: RandomNumberGenerator


## A seed for a new god (Ruling P17, final review M9): from the operating system's entropy, not the engine clock, which counts from launch
## and would give two gods made at the same moment the same draws. One generator of its own, seeded once from the system (a new one
## per call can be seeded by the same tick twice), so the game's global one is not reseeded and each call is another number.
static func fresh_seed() -> int:
	if _seeds == null:
		_seeds = RandomNumberGenerator.new()
		_seeds.randomize()
	return (int(_seeds.randi()) << 31) ^ int(_seeds.randi())


## A new god: level 1, tier 1, its two Tier 1 abilities learned at level 1 for free (spec §4).
static func make(n: int, god_type: String, p_seed: int) -> GodSlot:
	var s := GodSlot.new()
	s.index = n
	s.type = god_type
	s.seed = p_seed
	s.ensure_starting()
	return s


## The god in `file`, or null when the file is missing or unreadable, or its type is not one of GodTree.RING (Ruling P23: a
## damaged god reads as an empty slot and is replaced only through New's confirm). A hand-edited value out of range is pulled back
## into it; an unknown power or mission is dropped; then the starting abilities are ensured (Ruling P4).
static func read(file: String) -> GodSlot:
	var cfg := ConfigFile.new()
	if cfg.load(file) != OK or not cfg.has_section(SECTION):
		return null
	var god_type: Variant = cfg.get_value(SECTION, "type", "")
	if not (god_type is String) or not GodTree.RING.has(god_type):
		return null
	var s := GodSlot.new()
	s.type = god_type
	s.index = clampi(_int(cfg.get_value(SECTION, "index", 0)), 0, COUNT)
	s.name = _string(cfg.get_value(SECTION, "name", ""))
	s.version = _int(cfg.get_value(SECTION, "version", VERSION), VERSION)
	s.tier = clampi(_int(cfg.get_value(SECTION, "tier", 1), 1), 1, TierBook.NAMES.size())
	s.level = clampi(_int(cfg.get_value(SECTION, "level", 1), 1), 1, s.cap())
	s.divine_power = clampi(_int(cfg.get_value(SECTION, "divine_power", 0)), 0, s.need())
	s.points = maxi(_int(cfg.get_value(SECTION, "points", 0)), 0)
	s.faith = maxi(_int(cfg.get_value(SECTION, "faith", 0)), 0)
	s.notice = clampi(_int(cfg.get_value(SECTION, "notice", 0)), 0, NOTICE_MAX)
	s.seal_nights = maxi(_int(cfg.get_value(SECTION, "seal_nights", 0)), 0)
	s.night = maxi(_int(cfg.get_value(SECTION, "night", 0)), 0)
	s.seed = _int(cfg.get_value(SECTION, "seed", 0))
	var sealed_key := _string(cfg.get_value(SECTION, "sealed", ""))
	s.sealed = sealed_key if _is_power(sealed_key) else ""
	var last := _string(cfg.get_value(SECTION, "last_mission", ""))
	s.last_mission = last if TierBook.has(last) else ""
	var open := _string(cfg.get_value(SECTION, "in_night", ""))
	s.in_night = open if TierBook.has(open) else ""
	s.gifts = _strings(cfg.get_value(SECTION, "gifts", PackedStringArray()))
	for key in _strings(cfg.get_value(SECTION, "loadout", PackedStringArray())):
		if _is_power(key):
			s.loadout.append(key)
	var learned_in: Variant = cfg.get_value(SECTION, "learned", {})
	if learned_in is Dictionary:
		for key: Variant in learned_in:
			if _is_power(str(key)) and (learned_in[key] is int or learned_in[key] is float):
				s.learned[str(key)] = clampi(int(learned_in[key]), 1, PowerBook.MAX_LEVEL)
	var bought_in: Variant = cfg.get_value(SECTION, "bought", {})
	if bought_in is Dictionary:
		for row: Dictionary in FAITH:
			var k: String = row.key
			if bought_in.has(k) and (bought_in[k] is int or bought_in[k] is float):
				var most := int(row.limit) if int(row.limit) > 0 else UNLIMITED_CAP
				s.bought[k] = clampi(int(bought_in[k]), 0, most)
	var carried_in: Variant = cfg.get_value(SECTION, "carried", {})
	if carried_in is Dictionary:
		for key: Variant in carried_in:
			if _is_power(str(key)) and (carried_in[key] is int or carried_in[key] is float):
				s.carried[str(key)] = maxi(int(carried_in[key]), 0)
	var bests_in: Variant = cfg.get_value(SECTION, "bests", {})
	if bests_in is Dictionary:
		for id: Variant in bests_in:
			if TierBook.has(str(id)) and bests_in[id] is Dictionary:
				s.bests[str(id)] = _best(bests_in[id])
	s.ensure_starting()
	return s


## Writes the slot to `file`: every var under [god], with its own name as the key.
func write(file: String) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "version", VERSION)
	cfg.set_value(SECTION, "index", index)
	cfg.set_value(SECTION, "name", name)
	cfg.set_value(SECTION, "type", type)
	cfg.set_value(SECTION, "level", level)
	cfg.set_value(SECTION, "divine_power", divine_power)
	cfg.set_value(SECTION, "tier", tier)
	cfg.set_value(SECTION, "points", points)
	cfg.set_value(SECTION, "learned", learned)
	cfg.set_value(SECTION, "faith", faith)
	cfg.set_value(SECTION, "bought", bought)
	cfg.set_value(SECTION, "notice", notice)
	cfg.set_value(SECTION, "sealed", sealed)
	cfg.set_value(SECTION, "seal_nights", seal_nights)
	cfg.set_value(SECTION, "night", night)
	cfg.set_value(SECTION, "last_mission", last_mission)
	cfg.set_value(SECTION, "in_night", in_night)
	cfg.set_value(SECTION, "gifts", gifts)
	cfg.set_value(SECTION, "bests", bests)
	cfg.set_value(SECTION, "carried", carried)
	cfg.set_value(SECTION, "loadout", loadout)
	cfg.set_value(SECTION, "seed", seed)
	return cfg.save(file)


## A best as the file may hold it, pulled into shape.
static func _best(v: Dictionary) -> Dictionary:
	var fastest := 0.0
	if v.get("fastest", 0.0) is float or v.get("fastest", 0.0) is int:
		fastest = maxf(float(v.get("fastest", 0.0)), 0.0)
	var wishes := 0
	if v.get("most_wishes", 0) is int or v.get("most_wishes", 0) is float:
		wishes = maxi(int(v.get("most_wishes", 0)), 0)
	return {"cleared": v.get("cleared", false) == true, "fastest": fastest, "most_wishes": wishes}


static func _int(v: Variant, fallback := 0) -> int:
	return int(v) if v is int or v is float else fallback


static func _string(v: Variant) -> String:
	return v if v is String else ""


static func _strings(v: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if v is PackedStringArray or v is Array:
		for item: Variant in v:
			if item is String:
				out.append(item)
	return out


static func _is_power(key: String) -> bool:
	return not PowerBook.get_power(key).is_empty()


## Divine Power one level costs now: `XP_PER_LEVEL x tier` (spec §8).
func need() -> int:
	return XP_PER_LEVEL * tier


## The highest level this tier allows: tier x 10, never above MAX_LEVEL (spec §8).
func cap() -> int:
	return mini(tier * LEVELS_PER_TIER, MAX_LEVEL)


## True at the cap: the bar stops at full until the next Awaken (spec §8).
func capped() -> bool:
	return level >= cap()


## Adds Divine Power (spec §8). One large gain crosses several levels, one point each. At the cap the bar fills to need() and stops;
## the rest is lost (Ruling P6). Returns {"levels": PackedInt32Array (the levels reached), "points": int, "lost": int,
## "capped": bool}.
func gain_dp(amount: int) -> Dictionary:
	divine_power += maxi(amount, 0)
	var out := _fill()
	out["capped"] = capped()
	return out


## Turns a full bar into levels while below the cap, then trims a capped bar to need(); {"levels", "points", "lost"}.
func _fill() -> Dictionary:
	var reached := PackedInt32Array()
	while level < cap() and divine_power >= need():
		divine_power -= need()
		level += 1
		points += 1
		reached.append(level)
	var lost := 0
	if capped() and divine_power > need():
		lost = divine_power - need()
		divine_power = need()
	return {"levels": reached, "points": reached.size(), "lost": lost}


## The dev/test hook for P3's Awaken rite win: the tier rises by one (5 at most), AWAKEN_POINTS points come, the bar is kept and
## re-levelled at the new need (spec §8, Ruling P6). At tier 5 nothing happens (no rite is left to win).
func awaken() -> void:
	if tier >= TierBook.NAMES.size():
		return
	tier += 1
	points += AWAKEN_POINTS
	_fill()


## Points earned so far, derived: one per level after the first, AWAKEN_POINTS per tier after the first (Ruling P5; 57 at level 50).
func points_earned() -> int:
	return (level - 1) + AWAKEN_POINTS * (tier - 1)


## The type of the tree spot `key` sits in, or "" when it is in no spot.
func spot_type(key: String) -> String:
	return str(GodTree.spot_of(key).get("type", ""))


## What one point step of `key` costs this god: 1 for its own type's spot, 2 for a neighbour's, 0 for a key in no spot or a far
## type (spec §5.3).
func cost(key: String) -> int:
	var where := spot_type(key)
	return 0 if where == "" else GodTree.factor(type, where)


## The level `key` is learned at, 0 when it is not learned.
func level_of(key: String) -> int:
	return int(learned.get(key, 0))


## Why learning or raising `key` is refused: "unknown" (in no spot), "far", "tier" (learning a spot above the god's tier; raising is
## never tier-gated, spec §5.2), "max" (level 5), "points", or "" when it can be done.
func refusal(key: String) -> String:
	var where: Dictionary = GodTree.spot_of(key)
	if where.is_empty():
		return "unknown"
	if cost(key) == 0:
		return "far"
	var have := level_of(key)
	if have >= PowerBook.MAX_LEVEL:
		return "max"
	if have == 0 and int(where.tier) > tier:
		return "tier"
	if points < cost(key):
		return "points"
	return ""


## Learns `key` at level 1, or raises it by one, spending cost(key) points; false (nothing changes) when refused.
func learn(key: String) -> bool:
	if refusal(key) != "":
		return false
	points -= cost(key)
	learned[key] = level_of(key) + 1
	return true


## The Might `key` costs at its learned level (spec §6).
func might_of(key: String) -> int:
	return PowerBook.might(key, level_of(key))


## The most Might a draft may spend: the god tier's budget plus the Faith upgrades (spec §6).
func max_might() -> int:
	return TierBook.dp(tier) + int(bought.get("might", 0))


## Slots in a draft: BASE_SLOTS plus the Faith upgrades, never above TierBook.MAX_SLOTS (spec §6).
func slots() -> int:
	return mini(BASE_SLOTS + int(bought.get("slot", 0)), TierBook.MAX_SLOTS)


## Seconds the Faith upgrades add to the descent clock (spec §7).
func extra_clock() -> float:
	return CLOCK_STEP * int(bought.get("clock", 0))


## Learned keys that sit in a spot and are not sealed, in GodTree.spots() order. A learned key in no spot is kept in the file but not
## drafted (Ruling P4).
func draftable() -> PackedStringArray:
	var out := PackedStringArray()
	for s: Dictionary in GodTree.spots():
		var key: String = s.key
		if key != "" and learned.has(key) and key != sealed:
			out.append(key)
	return out


## What this god's type starts with: its Tier 1 abilities (spec §4).
func starting() -> PackedStringArray:
	return GodTree.starting(type)


## Gives the starting abilities, free at level 1, to any the god lacks (Ruling P4: a fill landed after the slot was made must not
## strand a god). Points do not change.
func ensure_starting() -> void:
	for key in starting():
		if not learned.has(key):
			learned[key] = 1


## Row `what` of FAITH, or {} when there is none.
func _faith_row(what: String) -> Dictionary:
	for row: Dictionary in FAITH:
		if row.key == what:
			return row
	return {}


## The price of the next purchase of `what` ("prices[n]" or "step x (n + 1)" for the (n + 1)-th); 0 for an unknown row or past the end
## of a price list.
func faith_price(what: String) -> int:
	var row := _faith_row(what)
	if row.is_empty():
		return 0
	var n := int(bought.get(what, 0))
	if row.has("prices"):
		return int(row.prices[n]) if n < row.prices.size() else 0
	return int(row.step) * (n + 1)


## True when at least one ability point is spent: something is learned beyond the free starting abilities at level 1, or the points
## held are below those earned (Ruling P5).
func points_spent() -> bool:
	var base := {}
	for key in starting():
		base[key] = 1
	return learned != base or points < points_earned()


## Why `what` cannot be bought: "unknown", "limit", "nothing" (respec with no point spent), "faith", or "" when it can.
func faith_refusal(what: String) -> String:
	var row := _faith_row(what)
	if row.is_empty():
		return "unknown"
	var limit := int(row.limit)
	if limit > 0 and int(bought.get(what, 0)) >= limit:
		return "limit"
	if what == "respec" and not points_spent():
		return "nothing"
	if faith < faith_price(what):
		return "faith"
	return ""


## Buys one of `what`, spending its price; false (nothing changes) when refused. "respec" resets `learned` to the starting abilities
## at level 1 and `points` to points_earned() (Ruling P5).
func buy(what: String) -> bool:
	if faith_refusal(what) != "":
		return false
	faith -= faith_price(what)
	bought[what] = int(bought.get(what, 0)) + 1
	if what == "respec":
		learned = {}
		ensure_starting()
		points = points_earned()
	return true
