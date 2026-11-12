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
	_tier1_real(t)


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
	t.check(first == {"type": "ruin", "tier": 1, "i": 0, "key": "smite"} and last.type == "dominion" and last.tier == 5 and last.i == 1,
		"spots() runs in RING, tier, index order (%s .. %s)" % [first, last])
	# The user's Tier 1 fill (2026-10-27): every Tier 1 spot holds a key; Tiers 2-5 are still empty except Ruin's (2026-11-02).
	var tier1_full := true
	var rest_empty := true
	for key: String in GodTree.TABLE.keys():
		var tiers: Array = GodTree.TABLE[key]
		for k: String in tiers[0]:
			tier1_full = tier1_full and k != ""
		if key == "ruin":
			continue
		for i in range(1, tiers.size()):
			if key == "dominion" or key == "passage" or key == "death":
				continue
			for k: String in tiers[i]:
				rest_empty = rest_empty and k == ""
	t.check(tier1_full, "every Tier 1 spot of the real table is filled")
	t.check(rest_empty, "Tiers 2-5 of the real table are still empty, Ruin's, Dominion's, Passage's and Death's aside")
	t.check(GodTree.TABLE.dominion.slice(1) == [["madness", "wisp"], ["clearmind", "saint"], ["sanctuary", "anathema"], ["voice", "schism"]],
		"Dominion's Tiers 2-5 hold the user's picks (%s)" % [GodTree.TABLE.dominion])
	t.check(GodTree.TABLE.passage.slice(1) == [["houndgate", "hellspark"], ["deep", "mirror"], ["allroads", "foldward"], ["deaddoors", "heavendoor"]],
		"Passage's Tiers 2-5 hold the user's picks (%s)" % [GodTree.TABLE.passage])
	t.check(GodTree.TABLE.death.slice(1) == [["pestilence", "gravecall"], ["guise", "walker"], ["gatebelow", "pale"], ["serpent", "gravetide"]],
		"Death's Tiers 2-5 hold the user's picks (%s)" % [GodTree.TABLE.death])
	t.check(GodTree.TABLE.ruin.slice(1) == [["tornado", "scatter"], ["solaris", "dragon"], ["tsunami", "cinder"], ["tempest", "shatter"]],
		"Ruin's Tiers 2-5 hold the user's picks, with Scatter Strike, Wrath of the Sky and Earthshatter in the spots kept for them (%s)" % [GodTree.TABLE.ruin.slice(1)])
	t.check(GodTree.TABLE.ruin[0] == ["smite", "ember"] and GodTree.TABLE.death[0] == ["deathmark", "raise"]
		and GodTree.TABLE.veil[0] == ["doom", "blight"] and GodTree.TABLE.passage[0] == ["skylift", "windfall"]
		and GodTree.TABLE.decree[0] == ["noleave", "belllies"] and GodTree.TABLE.dominion[0] == ["whisper", "discord"],
		"Tier 1 holds the user's picks")


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
	t.check(GodTree.RING == ["ruin", "passage", "veil", "decree", "death", "dominion"]
		and GodTree.neighbours("ruin") == PackedStringArray(["dominion", "passage"])
		and GodTree.neighbours("veil") == PackedStringArray(["passage", "decree"]), "the ring (the user's order, 2026-11-06)")
	t.check(GodTree.factor("ruin", "ruin") == 1 and GodTree.factor("ruin", "passage") == 2 and GodTree.factor("ruin", "dominion") == 2
		and GodTree.factor("ruin", "veil") == 0 and GodTree.factor("ruin", "death") == 0 and GodTree.factor("ruin", "decree") == 0,
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
	t.check(GodTree.keys_for("ruin", 2) == PackedStringArray(["smite", "ember", "tornado", "scatter"]),
		"keys_for(ruin, 2) (%s)" % [GodTree.keys_for("ruin", 2)])
	t.check(GodTree.keys_for("death", 5) == PackedStringArray(["deathmark", "raise", "pestilence", "gravecall", "guise", "walker", "gatebelow", "pale", "serpent", "gravetide"]),
		"empty spots are left out of keys_for (%s)" % [GodTree.keys_for("death", 5)])
	t.check(GodTree.outside("ruin", 1, PackedStringArray(["smite", "doom"])) == PackedStringArray(["doom"]),
		"outside(ruin, 1, [smite, doom]) (%s)" % [GodTree.outside("ruin", 1, PackedStringArray(["smite", "doom"]))])
	t.check(GodTree.spot("ruin", 0, 0) == "" and GodTree.spot("ruin", 6, 0) == "" and GodTree.spot("ruin", 1, 2) == ""
		and GodTree.spot("nosuch", 1, 0) == "", "out of range is empty")
	t.check(GodTree.spots().size() == 60, "spots() is 60 with the fill on")
	GodTree.dev_fill = false
	t.check(GodTree.starting("ruin") == PackedStringArray(["smite", "ember"]), "dev fill off: starting(ruin) is the real table's (%s)"
		% [GodTree.starting("ruin")])
	t.check(GodTree.spot("ruin", 2, 1) == "scatter" and GodTree.spot("ruin", 5, 0) == "tempest" and GodTree.spot("ruin", 5, 1) == "shatter",
		"dev fill off: Ruin's Tier 2 holds Scatter Strike, its Tier 5 Wrath of the Sky and Earthshatter")
	GodTree.use_table(GodTree.blank())
	t.check(GodTree.starting("ruin") == PackedStringArray() and GodTree.spot("ruin", 1, 0) == "",
		"use_table(blank()): the tree reads empty (%s)" % [GodTree.starting("ruin")])
	GodTree.use_table({})


static func _real_wins(t) -> void:
	var real := GodTree.blank()
	real["veil"][2][0] = "smite"
	real["veil"][0][0] = "doom"
	var merged := GodTree.merged(real, GodTreeDev.TABLE)
	t.check(merged["veil"][2][0] == "smite", "a real key stays where the real table put it (%s)" % [merged["veil"][2][0]])
	t.check(merged["ruin"][0][0] == "" and merged["ruin"][0][1] == "ember", "smite is not repeated: ruin T1 spot 0 stays empty (%s)"
		% [merged["ruin"][0]])
	t.check(merged["veil"][0][0] == "doom" and merged["veil"][0][1] == "blight", "doom stays at veil T1 spot 0; blight fills spot 1 (%s)"
		% [merged["veil"][0]])
	t.check(GodTree.problems(merged).is_empty(), "the merged table is valid (%s)" % [GodTree.problems(merged)])
	t.check(real["ruin"][0][0] == "" and GodTree.TABLE["ruin"][0][0] == "smite", "merged() changes neither input")


static func _flavour(t) -> void:
	var ok := GodTree.FLAVOUR.size() == 6
	for type: String in GodTree.RING:
		ok = ok and String(GodTree.FLAVOUR.get(type, "")) != ""
	t.check(ok, "each of the six types has a flavour line")


## The real tree's Tier 1 is the user's D2 picks, in spot order (god T1R Task 7): the table the 30-pair gate plays.
static func _tier1_real(t) -> void:
	var want := {"ruin": ["smite", "ember"], "death": ["deathmark", "raise"], "veil": ["doom", "blight"],
		"passage": ["skylift", "windfall"], "decree": ["noleave", "belllies"], "dominion": ["whisper", "discord"]}
	var real := GodTree.real()
	for type: String in GodTree.RING:
		t.check(Array(real[type][0]) == want[type], "real tree Tier 1 of %s is %s, in spot order (%s)" % [type, want[type], real[type][0]])
