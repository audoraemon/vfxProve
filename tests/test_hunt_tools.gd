extends RefCounted
## God P5 Task 3 (plan Task 3, MS §7, R37-R38; rulings C7-C9): the Hunt tools -- tools/dev/routes/god_hunts.gd and its five policy files, the
## loadout floor problems() holds every type to, behaviour_check's arms and hunt_gate.sh's shape (a type at a time, judged from saved lines).

const GodHunts := preload("res://tools/dev/routes/god_hunts.gd")
const GodT1 := preload("res://tools/dev/routes/god_t1.gd")

## The god types, in the ring's order.
const TYPES := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## The real tree's Tier 1 as the user filled it (P1 D2) and nothing above: the table the real-tree test pins, so a later fill of a higher tier by
## the user does not move the literal lists below (the computed check reads the live tree too).
const TIER1_ONLY := {
	"ruin": [["smite", "ember"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"death": [["deathmark", "pestilence"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"veil": [["doom", "blight"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"passage": [["thorns", "mirror"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"decree": [["noleave", "belllies"], ["", ""], ["", ""], ["", ""], ["", ""]],
	"dominion": [["whisper", "discord"], ["", ""], ["", ""], ["", ""], ["", ""]],
}

## The keys each Hunt's types play, written out (C7: a changed LOADOUT fails `_loadouts_real`): Hunt -> type -> keys.
const PLAYS := {
	"hide_faithful": {"ruin": "smite,ember", "death": "deathmark,pestilence", "veil": "doom,blight", "passage": "thorns,mirror",
		"decree": "noleave,belllies", "dominion": "whisper,discord"},
	"silence_witness": {"ruin": "smite,heaven,tornado", "death": "deathmark,pestilence,glacial", "veil": "doom,blight,tsunami",
		"passage": "thorns,mirror", "decree": "noleave,belllies,magnify", "dominion": "whisper,discord,madness"},
	"expel_inquisitor": {"ruin": "smite,heaven,tornado", "death": "deathmark,pestilence,glacial", "veil": "doom,blight,nova",
		"passage": "thorns,mirror", "decree": "noleave,belllies,magnify", "dominion": "whisper,discord,madness"},
	"break_hunt": {"ruin": "smite,heaven,orbital", "death": "deathmark,pestilence,glacial", "veil": "doom,blight,nova",
		"passage": "thorns,mirror", "decree": "noleave,belllies,magnify", "dominion": "whisper,discord,turncoat"},
	"face_halcyon": {"ruin": "smite,ember,heaven", "death": "deathmark,pestilence,glacial", "veil": "doom,blight,tsunami",
		"passage": "thorns,mirror", "decree": "noleave,belllies,magnify", "dominion": "whisper,discord,priority"},
}

## What each Hunt's loadout lacks in the Tier-1-only tree (C7), per type: the keys above Tier 1, in LOADOUT order. Passage's is empty on every
## Hunt (its two real Tier 1 keys); the whole of Hunt 1 is empty.
const LACKS := {
	"hide_faithful": {"ruin": "", "death": "", "veil": "", "passage": "", "decree": "", "dominion": ""},
	"silence_witness": {"ruin": "heaven,tornado", "death": "glacial", "veil": "tsunami", "passage": "", "decree": "magnify", "dominion": "madness"},
	"expel_inquisitor": {"ruin": "heaven,tornado", "death": "glacial", "veil": "nova", "passage": "", "decree": "magnify", "dominion": "madness"},
	"break_hunt": {"ruin": "heaven,orbital", "death": "glacial", "veil": "nova", "passage": "", "decree": "magnify", "dominion": "turncoat"},
	"face_halcyon": {"ruin": "heaven", "death": "glacial", "veil": "tsunami", "passage": "", "decree": "magnify", "dominion": "priority"},
}


static func run(t) -> void:
	_scenarios(t)
	_files(t)
	_loadouts_dev(t)
	_loadouts_real(t)
	_problems_might(t)
	_dispatch(t)
	_check_arms(t)
	_gate_flags(t)
	_gate_behaviour(t)
	GodTree.dev_fill = false
	GodTree.use_table({})


static func _keys(csv: String) -> PackedStringArray:
	return PackedStringArray(csv.split(",", false))


static func _scenarios(t) -> void:
	t.check(GodHunts.SCENARIOS == Array(HuntBook.ids()), "SCENARIOS is HuntBook.ids() in order (%s vs %s)" % [GodHunts.SCENARIOS, HuntBook.ids()])
	t.check(GodT1.SCENARIOS == ["warning", "tax", "harvest", "lamb", "prayers"], "GOD_T1.SCENARIOS is unchanged (%s)" % [GodT1.SCENARIOS])
	for i in GodHunts.SCENARIOS.size():
		t.check(GodHunts.tier_of(GodHunts.SCENARIOS[i]) == i + 1, "%s is a Tier %d Hunt (%d)" % [GodHunts.SCENARIOS[i], i + 1, GodHunts.tier_of(GodHunts.SCENARIOS[i])])
	t.check(GodHunts.tier_of("lamb") == 0, "a board mission has no Hunt tier (%d)" % GodHunts.tier_of("lamb"))
	t.check(GodHunts.GOD_T1 == GodT1, "the pieces are god_t1.gd's own, not copies")


static func _files(t) -> void:
	for id: String in GodHunts.SCENARIOS:
		t.check(GodHunts.FILES.has(id), "%s has a policy file" % id)
		if not GodHunts.FILES.has(id):
			continue
		var file: GDScript = GodHunts.FILES[id]
		var names := {}
		for m: Dictionary in file.get_script_method_list():
			names[m.name] = true
		var consts := file.get_script_constant_map()
		t.check(names.has("state") and names.has("act_shared"), "%s has state() and act_shared()" % id)
		t.check(consts.has("FILLED") and consts.has("LOADOUT"), "%s has FILLED and LOADOUT" % id)
		for type: String in TYPES:
			t.check(names.has("act_" + type), "%s has act_%s" % [id, type])
			t.check(GodHunts.has_policy(id, type), "has_policy(%s, %s)" % [id, type])
			t.check(consts.get("LOADOUT", {}).has(type), "%s names a loadout for %s" % [id, type])
		t.check(GodHunts.has_policy(id, ""), "has_policy(%s, \"\") is the shared plan" % id)
		t.check(GodHunts.has_policy(id, "bogus") == false, "no policy for a bogus type")
		for done in GodHunts.filled(id):
			t.check(TYPES.has(done), "%s FILLED names only god types (%s)" % [id, done])
	t.check(GodHunts.has_policy("lamb", "ruin") == false, "a board mission is not a Hunt file")
	t.check(GodHunts.state("lamb", null, {}) == "", "state of a non-Hunt is empty")


## Every Hunt x type loadout is playable at the Hunt's tier with the dev fill on (the gate's tree).
static func _loadouts_dev(t) -> void:
	GodTree.dev_fill = true
	for id: String in GodHunts.SCENARIOS:
		var tier := GodHunts.tier_of(id)
		for type: String in TYPES:
			var got := GodHunts.problems(id, type, tier)
			t.check(got.is_empty(), "dev fill: %s x %s at Tier %d has no problems (%s)" % [id, type, tier, got])
			t.check(GodHunts.loadout(id, type, tier) == _keys(PLAYS[id][type]), "%s x %s drafts %s (%s)" % [id, type, PLAYS[id][type], GodHunts.loadout(id, type, tier)])
	GodTree.dev_fill = false


## C7: in the real tree, `problems()` is exactly each loadout's keys the type has not learned -- computed from LOADOUT and written out.
static func _loadouts_real(t) -> void:
	GodTree.dev_fill = false
	# Computed from the live real tree (a tier the user fills later moves nothing wrong here).
	for id: String in GodHunts.SCENARIOS:
		var tier := GodHunts.tier_of(id)
		for type: String in TYPES:
			var want := PackedStringArray()
			var known := GodTree.keys_for(type, tier)
			for key in GodHunts.loadout(id, type, tier):
				if not known.has(key):
					want.append(key)
			var got := GodHunts.problems(id, type, tier)
			t.check(got == want, "real tree: %s x %s at Tier %d lacks exactly %s (%s)" % [id, type, tier, want, got])
	# Written out, against the Tier-1-only table as the user filled it.
	GodTree.use_table(TIER1_ONLY)
	for id: String in GodHunts.SCENARIOS:
		var tier := GodHunts.tier_of(id)
		for type: String in TYPES:
			var want := _keys(LACKS[id][type])
			var got := GodHunts.problems(id, type, tier)
			t.check(got == want, "Tier 1 tree: %s x %s lacks exactly [%s] (%s)" % [id, type, LACKS[id][type], got])
	t.check(GodHunts.problems("silence_witness", "passage", 2).is_empty(), "Passage's two real keys are enough on Hunt 2")
	t.check(GodHunts.problems("face_halcyon", "passage", 5).is_empty(), "Passage's two real keys are enough on Hunt 5")
	for type: String in TYPES:
		t.check(GodHunts.problems("hide_faithful", type, 1).is_empty(), "Tier 1 (the real tree): %s plays its own two keys (%s)" % [type, GodHunts.problems("hide_faithful", type, 1)])
	GodTree.use_table({})


## The loadout floor (C9): a list of more than GodSlot.BASE_SLOTS keys, or over TierBook.dp(tier) Might at level 1, or none, is named.
static func _problems_might(t) -> void:
	GodTree.dev_fill = true
	var heavy := PackedStringArray(["pestilence", "glacial", "solaris"])
	var sum := 0
	for key in heavy:
		sum += PowerBook.might(key, 1)
	t.check(sum > TierBook.dp(2), "the fake list is heavier than Tier 2's Might (%d vs %d)" % [sum, TierBook.dp(2)])
	var got := GodHunts.check("death", 2, heavy)
	t.check(got == PackedStringArray(["might %d>%d" % [sum, TierBook.dp(2)]]), "the over-Might list is named by its numbers (%s)" % [got])
	var four := PackedStringArray(["smite", "ember", "heaven", "tornado"])
	got = GodHunts.check("ruin", 5, four)
	t.check(got.has("slots 4>%d" % GodSlot.BASE_SLOTS), "a fourth key is named (%s)" % [got])
	got = GodHunts.check("ruin", 1, PackedStringArray(["smite", "heaven"]))
	t.check(got == PackedStringArray(["heaven"]), "a key outside the tree at the tier is named alone (%s)" % [got])
	got = GodHunts.check("ruin", 2, PackedStringArray())
	t.check(got == PackedStringArray(["no keys"]), "no keys is a problem (%s)" % [got])
	t.check(GodHunts.check("ruin", 2, PackedStringArray(["smite", "heaven", "tornado"])).is_empty(), "the floor Ruin plays at Tier 2 is within it")
	t.check(GodHunts.problems("nowhere", "ruin", 1) == PackedStringArray(["no such Hunt"]), "an unknown Hunt is named")
	GodTree.dev_fill = false


## The policy dispatch: a stub casts nothing and a missing file or type gives "".
static func _dispatch(t) -> void:
	for id: String in GodHunts.SCENARIOS:
		if GodHunts.filled(id).is_empty():
			for type: String in [""] + TYPES:
				t.check(GodHunts.act(id, type, null, {}) == "", "the stub act(%s, %s) casts nothing" % [id, type])
	t.check(GodHunts.act("lamb", "ruin", null, {}) == "", "act on a non-Hunt is empty")
	t.check(GodHunts.act("hide_faithful", "bogus", null, {}) == "", "act of a bogus type is empty")
	t.check(GodHunts.loadout("lamb", "ruin").is_empty(), "a non-Hunt has no loadout")


## behaviour_check's arms, read from its source (running it is the smoke test): the refusals, the arm and the hit-stop list.
static func _check_arms(t) -> void:
	var src := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	t.check(src.contains("const GOD_HUNTS := preload(\"res://tools/dev/routes/god_hunts.gd\")"), "behaviour_check preloads god_hunts.gd as GOD_HUNTS")
	t.check(src.contains("hunt_tier=%d"), "a tier other than the Hunt's is refused with hunt_tier=")
	t.check(src.contains("missing=%s"), "an unplayable loadout is refused with missing=")
	t.check(src.contains("_ when scenario in GOD_HUNTS.SCENARIOS:"), "the match has the Hunt arm")
	t.check(src.contains("func _god_hunt("), "behaviour_check has _god_hunt()")
	t.check(src.contains("or scenario in GOD_HUNTS.SCENARIOS"), "the Hunts join the hit-stop-off list")
	t.check(src.contains("GodTree.outside(god_type, god_tier, drafted)"), "the outside() refusal stays")
	# Milestone review M1: --route and --level are refused on a Hunt (each refusal prints, then quits, in the same block).
	var route_at := src.find("a Hunt takes --god, not --route")
	t.check(route_at >= 0 and src.substr(route_at, 160).contains("quit(1)"), "--route on a Hunt id is refused and quits")
	var level_at := src.find("a Hunt is played at level 1")
	t.check(level_at >= 0 and src.substr(level_at, 160).contains("quit(1)"), "--level other than 1 on a Hunt's own run is refused and quits")


## hunt_gate.sh's shape, from its source: the flags it parses and that no path runs more than one type.
static func _gate_flags(t) -> void:
	var src := FileAccess.get_file_as_string("res://tools/dev/hunt_gate.sh")
	t.check(not src.is_empty(), "tools/dev/hunt_gate.sh exists")
	for flag in ["--only=", "--type=", "--with-none", "--save=", "--judge=", "--except=", "--jobs="]:
		t.check(src.contains(flag + ")") or src.contains(flag + "*)"), "hunt_gate.sh parses %s" % flag)
	t.check(src.contains("--except") and src.contains("excepted"), "an excepted type prints `excepted`")
	# One gate.sh call, run for the one --type, with no loop around it.
	var calls := src.count("bash \"$HERE/gate.sh\"")
	t.check(calls == 1, "hunt_gate.sh calls gate.sh once (%d)" % calls)
	var at := src.find("# --- run one type")
	var call_at := src.find("bash \"$HERE/gate.sh\"")
	t.check(at >= 0 and call_at > at, "the run branch is marked")
	if at >= 0 and call_at > at:
		var between := src.substr(at, call_at - at)
		t.check(not between.contains("for ") and not between.contains("while "), "no loop between the marker and the gate.sh call")
	t.check(src.contains("neither --type nor --judge") or src.contains("needs --type=<type> or --judge=<dir>"), "a call with neither --type nor --judge is refused")
	# The refusal messages and their `exit 2` sit on one line (a bare `exit 2` anywhere would satisfy a loose check).
	for msg in ["needs --type=<type> or --judge=<dir>", "--except=$e is refused for $ONLY", "--except only goes with --judge"]:
		var at_msg := src.find(msg)
		var line := src.substr(at_msg, src.find("\n", at_msg) - at_msg) if at_msg >= 0 else ""
		t.check(line.contains("exit 2"), "the refusal `%s` exits 2 on its own line (%s)" % [msg, line.right(40)])
	t.check(src.contains("none_lost"), "the judge line carries none_lost")
	t.check(src.contains("180") and src.contains("240"), "the pooled median is judged against 180-240")


## hunt_gate.sh run for real (bash; skipped with a note when bash cannot be started): the judge reads only a gate line whose route is the
## type's own (milestone review, M1), and --except takes only Decree on Hunts 2-4. The saved files are two fakes in a user:// directory.
static func _gate_behaviour(t) -> void:
	var script := ProjectSettings.globalize_path("res://tools/dev/hunt_gate.sh")
	var probe: Array = []
	if OS.execute("bash", ["-c", "test -f '%s'" % script], probe) != 0:
		t.check(true, "bash cannot be started here, or cannot see the script: hunt_gate.sh's behaviour is left to the shell checks")
		return
	var dir := "user://test_hunt_tools_judge"
	DirAccess.make_dir_recursive_absolute(dir)
	var ok_line := "gate hide_faithful route=god:%s none_lost=3/3 wins=3/3 median=200 idle_max=30 PASS\n"
	# ruin.txt is right; death.txt carries the Ruin line (saved under the wrong name).
	for pair: Array in [["ruin", "ruin"], ["death", "ruin"]]:
		var f := FileAccess.open("%s/hide_faithful.%s.txt" % [dir, pair[0]], FileAccess.WRITE)
		f.store_string("hide_faithful play seed=1 won=true reason=faithful_out time=200 idle=30\n" + ok_line % pair[1])
		f.close()
	var judge := ProjectSettings.globalize_path(dir)
	var got := _sh(script, ["--only=hide_faithful", "--judge=" + judge])
	var rows := str(got[1]).split("\n")
	var ruin_row := ""
	var death_row := ""
	for row in rows:
		if row.begins_with("ruin"):
			ruin_row = row
		elif row.begins_with("death"):
			death_row = row
	t.check(ruin_row.contains("3/3") and ruin_row.ends_with("PASS"), "the judge reads the right-route file (%s)" % [ruin_row])
	t.check(death_row.contains("missing") and death_row.ends_with("FAIL"), "a file whose gate line is route=god:ruin is missing for death (%s)" % [death_row])
	t.check(int(got[0]) == 1 and str(got[1]).contains("FAIL"), "the judge fails with the wrong-route file (%s)" % [got[0]])
	got = _sh(script, ["--only=hide_faithful"])
	t.check(int(got[0]) == 2, "a call with neither --type nor --judge exits 2 (%s)" % [got[0]])
	got = _sh(script, ["--only=hide_faithful", "--judge=" + judge, "--except=decree"])
	t.check(int(got[0]) == 2, "--except=decree on Hunt 1 is refused with exit 2 (%s)" % [got[0]])
	got = _sh(script, ["--only=silence_witness", "--judge=" + judge, "--except=death"])
	t.check(int(got[0]) == 2, "--except=death on Hunt 2 is refused with exit 2 (%s)" % [got[0]])
	got = _sh(script, ["--only=face_halcyon", "--judge=" + judge, "--except=decree"])
	t.check(int(got[0]) == 2, "--except=decree on Hunt 5 is refused with exit 2 (%s)" % [got[0]])
	got = _sh(script, ["--only=break_hunt", "--judge=" + judge, "--except=decree"])
	t.check(int(got[0]) != 2 and str(got[1]).contains("decree") and str(got[1]).contains("excepted"), "--except=decree on Hunt 4 is accepted (%s)" % [got[0]])
	for name in ["ruin", "death"]:
		DirAccess.remove_absolute("%s/hide_faithful.%s.txt" % [dir, name])
	DirAccess.remove_absolute(dir)


## Runs `bash <script> <args>`; returns [exit code, stdout and stderr].
static func _sh(script: String, args: Array) -> Array:
	var out: Array = []
	var code := OS.execute("bash", [script] + args, out, true)
	return [code, "".join(out)]
