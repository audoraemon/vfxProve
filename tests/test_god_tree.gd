extends RefCounted
## God P1 Task 3 (spec §5.1-§5.2, §15): the god tree's ring, its 60 empty spots in one table, the validation (every key exists
## and appears once), and the dev fill kept apart from the real table (Ruling P2).


static func run(t) -> void:
	_shape(t)
	_valid(t)
	_problems_found(t)
	_ring(t)
	_dev_fill(t)
	_real_wins(t)
	_flavour(t)


static func _shape(t) -> void:
	var types := Array(GodTree.TABLE.keys())
	types.sort()
	var ring := GodTree.RING.duplicate()
	ring.sort()
	t.check(types == ring, "TABLE holds exactly the six RING types (%s)" % [types])
	t.check(GodTree.spots().size() == 60 and GodTree.SPOTS == 60, "60 spots (%d)" % GodTree.spots().size())
	var ok := true
	for type: String in GodTree.RING:
		ok = ok and GodTree.TABLE[type].size() == GodTree.TIERS
		for tier: Array in GodTree.TABLE[type]:
			ok = ok and tier.size() == GodTree.PER_TIER
	t.check(ok, "every type has five tiers of two")
	var first: Dictionary = GodTree.spots()[0]
	var last: Dictionary = GodTree.spots()[59]
	t.check(first == {"type": "ruin", "tier": 1, "i": 0, "key": ""} and last.type == "dominion" and last.tier == 5 and last.i == 1,
		"spots() runs in RING, tier, index order (%s .. %s)" % [first, last])
	var empty := true
	for key: String in GodTree.TABLE.keys():
		for tier: Array in GodTree.TABLE[key]:
			for k: String in tier:
				empty = empty and k == ""
	t.check(empty, "the real table is all empty in P1")


static func _valid(t) -> void:
	t.check(GodTree.problems(GodTree.TABLE).is_empty(), "the real table is valid (%s)" % [GodTree.problems(GodTree.TABLE)])
	t.check(GodTree.problems(GodTreeDev.TABLE).is_empty(), "the dev table is valid (%s)" % [GodTree.problems(GodTreeDev.TABLE)])
	GodTree.dev_fill = true
	var merged_problems := GodTree.problems(GodTree.table())
	GodTree.dev_fill = false
	t.check(merged_problems.is_empty(), "the table with the dev fill on is valid (%s)" % [merged_problems])


static func _copy(table: Dictionary) -> Dictionary:
	return table.duplicate(true)


static func _problems_found(t) -> void:
	var bad := _copy(GodTreeDev.TABLE)
	bad["ruin"][0][0] = "nosuch"
	var p1 := GodTree.problems(bad)
	t.check(not p1.is_empty() and p1[0].contains("nosuch"), "an unknown key is found, and named (%s)" % [p1])
	var twice := _copy(GodTreeDev.TABLE)
	twice["veil"][2][0] = "smite"
	var p2 := GodTree.problems(twice)
	t.check(not p2.is_empty() and p2[0].contains("smite"), "a key twice is found, and named (%s)" % [p2])
	var short := _copy(GodTreeDev.TABLE)
	short["ruin"].pop_back()
	var p3 := GodTree.problems(short)
	t.check(not p3.is_empty() and p3[0].contains("ruin"), "four tiers is found (%s)" % [p3])
	var wide := _copy(GodTreeDev.TABLE)
	wide["death"][0].append("")
	t.check(not GodTree.problems(wide).is_empty(), "three keys in a tier is found")
	var missing := _copy(GodTreeDev.TABLE)
	missing.erase("decree")
	var p4 := GodTree.problems(missing)
	t.check(not p4.is_empty() and p4[0].contains("decree"), "a missing type is found (%s)" % [p4])
	var extra := _copy(GodTreeDev.TABLE)
	extra["chaos"] = extra["ruin"]
	t.check(not GodTree.problems(extra).is_empty(), "a seventh type is found")


static func _ring(t) -> void:
	t.check(GodTree.neighbours("ruin") == PackedStringArray(["dominion", "death"])
		and GodTree.neighbours("veil") == PackedStringArray(["death", "passage"]), "the ring")
	t.check(GodTree.factor("ruin", "ruin") == 1 and GodTree.factor("ruin", "death") == 2 and GodTree.factor("ruin", "dominion") == 2
		and GodTree.factor("ruin", "veil") == 0 and GodTree.factor("ruin", "passage") == 0 and GodTree.factor("ruin", "decree") == 0,
		"1x own, 2x neighbours, far locked")
	t.check(GodTree.OWN_COST == 1 and GodTree.NEIGHBOUR_COST == 2 and GodTree.NOT_CHOSEN == "Not yet chosen", "the ring's constants")
	var round_trip := true
	for type: String in GodTree.RING:
		for n: String in GodTree.neighbours(type):
			round_trip = round_trip and GodTree.neighbours(n).has(type)
	t.check(round_trip, "neighbour is mutual all round the ring")


static func _dev_fill(t) -> void:
	GodTree.dev_fill = true
	t.check(GodTree.spot("ruin", 1, 0) == "smite", "dev fill: ruin Tier 1 spot 0 is smite (%s)" % GodTree.spot("ruin", 1, 0))
	t.check(GodTree.spot_of("smite") == {"type": "ruin", "tier": 1, "i": 0}, "spot_of(smite) (%s)" % [GodTree.spot_of("smite")])
	t.check(GodTree.spot_of("nosuch").is_empty(), "spot_of an unplaced key is empty")
	t.check(GodTree.starting("ruin") == PackedStringArray(["smite", "ember"]), "starting(ruin) (%s)" % [GodTree.starting("ruin")])
	t.check(GodTree.keys_for("ruin", 2) == PackedStringArray(["smite", "ember", "heaven", "tornado"]),
		"keys_for(ruin, 2) (%s)" % [GodTree.keys_for("ruin", 2)])
	t.check(GodTree.keys_for("death", 5) == PackedStringArray(["deathmark", "pestilence", "glacial", "solaris"]),
		"empty spots are left out of keys_for (%s)" % [GodTree.keys_for("death", 5)])
	t.check(GodTree.outside("ruin", 1, PackedStringArray(["smite", "doom"])) == PackedStringArray(["doom"]),
		"outside(ruin, 1, [smite, doom]) (%s)" % [GodTree.outside("ruin", 1, PackedStringArray(["smite", "doom"]))])
	t.check(GodTree.spot("ruin", 0, 0) == "" and GodTree.spot("ruin", 6, 0) == "" and GodTree.spot("ruin", 1, 2) == ""
		and GodTree.spot("nosuch", 1, 0) == "", "out of range is empty")
	t.check(GodTree.spots().size() == 60, "spots() is 60 with the fill on")
	GodTree.dev_fill = false
	t.check(GodTree.starting("ruin") == PackedStringArray(), "dev fill off: starting(ruin) is the real table's (empty in P1) (%s)"
		% [GodTree.starting("ruin")])
	t.check(GodTree.spot("ruin", 1, 0) == "", "dev fill off: the spot is empty")


static func _real_wins(t) -> void:
	var real := _copy(GodTree.TABLE)
	real["veil"][2][0] = "smite"
	real["veil"][0][0] = "doom"
	var merged := GodTree.merged(real, GodTreeDev.TABLE)
	t.check(merged["veil"][2][0] == "smite", "a real key stays where the real table put it (%s)" % [merged["veil"][2][0]])
	t.check(merged["ruin"][0][0] == "" and merged["ruin"][0][1] == "ember", "smite is not repeated: ruin T1 spot 0 stays empty (%s)"
		% [merged["ruin"][0]])
	t.check(merged["veil"][0][0] == "doom" and merged["veil"][0][1] == "blight", "doom stays at veil T1 spot 0; blight fills spot 1 (%s)"
		% [merged["veil"][0]])
	t.check(GodTree.problems(merged).is_empty(), "the merged table is valid (%s)" % [GodTree.problems(merged)])
	t.check(real["ruin"][0][0] == "" and GodTree.TABLE["ruin"][0][0] == "", "merged() changes neither input")


static func _flavour(t) -> void:
	var ok := GodTree.FLAVOUR.size() == 6
	for type: String in GodTree.RING:
		ok = ok and String(GodTree.FLAVOUR.get(type, "")) != ""
	t.check(ok, "each of the six types has a flavour line")
