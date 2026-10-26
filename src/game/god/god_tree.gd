class_name GodTree
extends RefCounted
## The god's ability tree (god P1, spec §5.1-§5.2): six types on a ring, five tiers of two spots each -- 60 spots in one table, all
## empty in P1. Filling the tree is editing TABLE and nothing else (spec §5.2); the dev fill (GodTreeDev) sits beside it for tests and
## scripted play and never replaces a real key (Ruling P2). The ring's order is the spec's, not the draft's tab order
## (PowerBook.AUTHORITIES stays as it is: Ruling P1).

## The six god types in ring order: a type's neighbours are the two beside it (spec §5.1).
const RING := ["ruin", "death", "veil", "passage", "decree", "dominion"]
## Tiers per type; the god's first tier is index 0 of a type's list.
const TIERS := 5
## Spots per tier.
const PER_TIER := 2
## Spots in the whole tree (6 types x 5 tiers x 2).
const SPOTS := 60
## What the Hub shows for a god that has not picked a type yet (spec §5.1).
const NOT_CHOSEN := "Not yet chosen"
## What a spot of the god's own type costs, as a multiple of its base: one (spec §5.1).
const OWN_COST := 1
## What a spot of a neighbouring type costs: double (spec §5.1). A far type's spots cannot be learned (factor 0).
const NEIGHBOUR_COST := 2

## One line of flavour per type, shown when a god is made. First guesses for the user to rewrite (Ruling P19).
const FLAVOUR := {
	"ruin": "What stands, falls.",
	"death": "Every life is a loan.",
	"veil": "Unseen, unheard, unanswered.",
	"passage": "Every way is yours to open or to close.",
	"decree": "Your word is law, and the law is yours.",
	"dominion": "Every mind bends.",
}

## The real tree: type -> five tiers (index 0 = Tier 1) of two PowerBook keys, "" for a spot not filled yet. All empty in P1.
const TABLE := {
	"ruin": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]],
	"death": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]],
	"veil": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]],
	"passage": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]],
	"decree": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]],
	"dominion": [["", ""], ["", ""], ["", ""], ["", ""], ["", ""]],
}

## Test and scripted play: take GodTreeDev's key for every empty real spot (Ruling P2). Both test runners reset it per suite.
static var dev_fill := false

static var _merged_cache: Dictionary = {}


## The table every lookup reads: the real one, or the real one with the dev fill merged over its empty spots.
static func table() -> Dictionary:
	if not dev_fill:
		return TABLE
	if _merged_cache.is_empty():
		_merged_cache = merged(TABLE, GodTreeDev.TABLE)
	return _merged_cache


## The real table with `dev` merged over its empty spots (Ruling P2; pure, neither input changes): a real key stays where it is, and a
## dev key already used anywhere in the real table is not repeated.
static func merged(real: Dictionary, dev: Dictionary) -> Dictionary:
	var out: Dictionary = real.duplicate(true)
	var used := {}
	for type: String in out.keys():
		for tier: Array in out[type]:
			for key: String in tier:
				if key != "":
					used[key] = true
	for type: String in out.keys():
		if not dev.has(type):
			continue
		var tiers: Array = out[type]
		for t in tiers.size():
			if t >= dev[type].size():
				break
			var row: Array = tiers[t]
			for i in row.size():
				if row[i] != "" or i >= dev[type][t].size():
					continue
				var key: String = dev[type][t][i]
				if key != "" and not used.has(key):
					row[i] = key
					used[key] = true
	return out


## The key in a spot (tier 1-5, i 0-1), or "" for an empty or out-of-range spot.
static func spot(type: String, tier: int, i: int) -> String:
	var tbl := table()
	if not tbl.has(type) or tier < 1 or tier > tbl[type].size():
		return ""
	var row: Array = tbl[type][tier - 1]
	if i < 0 or i >= row.size():
		return ""
	return String(row[i])


## All 60 spots as {"type", "tier", "i", "key"}, in RING, tier, index order.
static func spots() -> Array:
	var out := []
	for type: String in RING:
		for tier in range(1, TIERS + 1):
			for i in PER_TIER:
				out.append({"type": type, "tier": tier, "i": i, "key": spot(type, tier, i)})
	return out


## Where a key sits, as {"type", "tier", "i"}, or {} when it is in no spot.
static func spot_of(key: String) -> Dictionary:
	if key == "":
		return {}
	for s: Dictionary in spots():
		if s.key == key:
			return {"type": s.type, "tier": s.tier, "i": s.i}
	return {}


## A type's two ring neighbours, [left, right] (ruin -> [dominion, death]); empty for an unknown type.
static func neighbours(type: String) -> PackedStringArray:
	var at := RING.find(type)
	if at < 0:
		return PackedStringArray()
	return PackedStringArray([RING[(at + RING.size() - 1) % RING.size()], RING[(at + 1) % RING.size()]])


## What a spot of `spot_type` costs a god of `god_type`, as a multiple of its base: OWN_COST, NEIGHBOUR_COST, or 0 (a far type: locked).
static func factor(god_type: String, spot_type: String) -> int:
	if god_type == spot_type:
		return OWN_COST
	if neighbours(god_type).has(spot_type):
		return NEIGHBOUR_COST
	return 0


## A type's non-empty Tier 1 keys: what a new god of that type starts with (spec §5.1).
static func starting(type: String) -> PackedStringArray:
	return keys_for(type, 1)


## A type's non-empty keys on tiers 1..max_tier, in spot order.
static func keys_for(type: String, max_tier: int) -> PackedStringArray:
	var out := PackedStringArray()
	for tier in range(1, mini(max_tier, TIERS) + 1):
		for i in PER_TIER:
			var key := spot(type, tier, i)
			if key != "":
				out.append(key)
	return out


## The keys not in keys_for(type, max_tier): what a policy restricted to one type's learned abilities must not use (spec §5.2, C6).
static func outside(type: String, max_tier: int, keys: PackedStringArray) -> PackedStringArray:
	var allowed := keys_for(type, max_tier)
	var out := PackedStringArray()
	for key in keys:
		if not allowed.has(key):
			out.append(key)
	return out


## What is wrong with a table, one line each; empty when valid: the six RING types, five tiers of two, each key "" or a PowerBook
## key, no key twice. A key's Authority is not checked against its spot (spec §5.2).
static func problems(tbl: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for type: String in RING:
		if not tbl.has(type):
			out.append("type %s is missing" % type)
	for type: Variant in tbl.keys():
		if not RING.has(type):
			out.append("type %s is not on the ring" % type)
	var seen := {}
	var known := PowerBook.keys()
	for type: String in RING:
		if not tbl.has(type):
			continue
		var tiers: Array = tbl[type]
		if tiers.size() != TIERS:
			out.append("%s has %d tiers, not %d" % [type, tiers.size(), TIERS])
		for t in tiers.size():
			var row: Array = tiers[t]
			if row.size() != PER_TIER:
				out.append("%s tier %d has %d spots, not %d" % [type, t + 1, row.size(), PER_TIER])
			for i in row.size():
				var key := String(row[i])
				if key == "":
					continue
				var where := "%s tier %d spot %d" % [type, t + 1, i]
				if not known.has(key):
					out.append("%s: \"%s\" is not a power" % [where, key])
				elif seen.has(key):
					out.append("%s: \"%s\" is also at %s" % [where, key, seen[key]])
				else:
					seen[key] = where
	return out
