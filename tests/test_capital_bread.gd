extends RefCounted
## Plan "The Capital at every tier", Task 10: the Crown's Bread in the Capital (spec 6.2.3, decision 1: the market hall is the granary and the bakery is
## the mill, both in the old town; the bridge is the west stone bridge). The director's targets are found by tag (the market hall, the bakery) and by the
## crossing nearest `bridge_at`; with the tag vars empty (Aldermere) the same three structures as before are found; the town's overrides
## (src/game/town/cities/capital_missions/crowns_bread.gd) are valid and hold after setup; the target-to-target legs are in Aldermere's band (real grid
## walks); each night crew stands more than 1.6 apart; the words the player reads name no granary, mill or watermill; the intro camera keeps the
## targets clear of the padded HUD stack; the policies read `d.words`, not CrownsBreadDirector.WORDS.

const ID := "crowns_bread"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_reads_vars(t)
	_aldermere_targets(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	Cap.spots_land(t, cap, {"bridge_at": ov.director.bridge_at}, 1.0)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Bread test leaves Aldermere active")


## A fresh director holds each town var at its const (the tag vars empty, bridge_at INF); Aldermere's mission is untouched.
static func _seeded(t) -> void:
	var d := CrownsBreadDirector.new()
	t.check(d.granary_tag == &"" and d.mill_tag == &"" and d.bridge_at == Vector2.INF, "a fresh director's granary_tag and mill_tag are empty, bridge_at is INF")
	t.check(d.names == CrownsBreadDirector.NAMES and d.words == CrownsBreadDirector.WORDS and d.stage_labels == CrownsBreadDirector.STAGE_LABELS
		and d.stage_at == CrownsBreadDirector.STAGE_AT, "a fresh director's names, words, stage_labels and stage_at are their consts")
	t.check(Overrides.town_vars(d) == ["granary_tag", "mill_tag", "bridge_at", "names", "words", "stage_labels", "stage_at"],
		"the Crown's Bread's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(MissionBook.crowns_bread().camera_at == CrownsBreadDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")
	t.check(CrownsBreadDirector.STAGE_AT == [45.0, 115.0, 185.0] and CrownsBreadDirector.CHAIN == 45.0 and CrownsBreadDirector.CARTS_AT == 300.0,
		"STAGE_AT, CHAIN and CARTS_AT are untouched")


## With the tag vars empty (Aldermere) the three targets are the structures the old rule found: the farmhouse of barns()[3] by footprint, the art tag
## watermill, town.bridge (the old logic re-stated here).
static func _aldermere_targets(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.crowns_bread())
	var d: CrownsBreadDirector = s.d
	var town: Town = s.town
	var granary: Structure = null
	var mill: Structure = null
	var barn: Rect2 = City.current().barns()[3]
	for b: Structure in town._built:
		if not is_instance_valid(b):
			continue
		if b.role == &"farm" and b.kind == Structure.Kind.HOUSE and b.footprint.position.is_equal_approx(barn.position):
			granary = b
		elif b.art_tag == &"watermill":
			mill = b
	t.check(granary != null and mill != null and town.bridge != null, "Aldermere has the farmhouse, the watermill and the bridge")
	t.check(d.targets.size() == 3 and d.targets[0] == granary and d.targets[1] == mill and d.targets[2] == town.bridge,
		"Aldermere's three targets are the same structures as before (farmhouse, watermill, town.bridge)")
	t.check(d.targets.size() == 3 and d.targets[0].center().distance_to(Vector2(20.15, 17.95)) < 0.05 and d.targets[1].center().distance_to(Vector2(-5.7, 25.95)) < 0.05,
		"the granary and the mill stand where they did (20.15, 17.95) and (-5.7, 25.95)")
	t.check(d.names == ["GRANARY", "MILL", "BRIDGE"] and d.words == ["granary", "mill", "bridge"], "Aldermere's names and words are as ever")
	Kit.done(s)


## The Capital's three targets, the town's overrides after setup, the walks, the crews, the words.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var dov: Dictionary = ov.director
	var d := Cap.starts(t, ID) as CrownsBreadDirector
	t.check(d != null and d.granary_tag == dov.granary_tag and d.mill_tag == dov.mill_tag and d.bridge_at == dov.bridge_at and d.names == dov.names
		and d.words == dov.words and d.stage_labels == dov.stage_labels and d.stage_at == CrownsBreadDirector.STAGE_AT,
		"the director reads back the Capital's tags, bridge_at, names, words and stage_labels after setup")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-13.0, -2.0) and def.intro_from == Vector2(-13.0, 4.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.targets.size() == 3, "the Capital's night has three targets (%d)" % d.targets.size())
	if d.targets.size() == 3:
		var town: Town = d.town
		t.check(d.targets[0].art_tag == &"gpt_markethall" and d.targets[1].art_tag == &"gpt_bakery" and d.targets[2].kind == Structure.Kind.BRIDGE,
			"the targets are the market hall, the bakery and a bridge, in that order")
		t.check(d.targets[2] != town.bridge and d.targets[2] in town.bridges and d.targets[2].center().distance_to(dov.bridge_at) < 1.5,
			"the bridge is the west stone bridge by bridge_at %s, not town.bridge (%s)" % [dov.bridge_at, d.targets[2].center()])
		var tower := d._gate_tower()
		var west: Rect2 = City.current().gate_towers()[0]
		t.check(tower != null and tower.footprint.position.is_equal_approx(west.position) and d.waiting_in[2] == tower and d.waiting_in[0] == d.targets[0],
			"the bridge shift waits in gate_towers()[0]; the others in their own building")
		_crews(t, d)
		_walk_parity(t, d, cap, ald)
		City.use(&"capital")
		_words_true(t, d)


## Target to target (the faces the player looks at), Capital against Aldermere on the real grids (band 0.75-1.35): printed, the player's travel.
static func _walk_parity(t, d: CrownsBreadDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.crowns_bread())
	var ad: CrownsBreadDirector = a.d
	for k in 2:
		Cap.parity(t, "leg %d (%s to %s)" % [k + 1, d.words[k], d.words[k + 1]], Cap.walk(cap.grid, d.faces[k], d.faces[k + 1]),
			Cap.walk(ald.grid, ad.faces[k], ad.faces[k + 1]))
	Kit.done(a)
	City.use(&"capital")


## Each target's crew (the night crew and its shift) stands more than 1.6 apart, and each crew is whole.
static func _crews(t, d: CrownsBreadDirector) -> void:
	for i in d.targets.size():
		var posts: Array = []
		for c: CrownsBreadDirector.Crew in d.crews[i]:
			posts.append(c.post)
		t.check(posts.size() == CrownsBreadDirector.NIGHT_CREW + CrownsBreadDirector.SHIFT, "target %d has its crew's posts (%d)" % [i, posts.size()])
		Cap.spread(t, posts)


## The policies read the director's words and no Aldermere const or coordinate.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _bread_act(", "\nfunc ")
	var clear := _slice(bc, "func _bread_clear(", "\nfunc ")
	t.check(act.length() > 800 and clear.length() > 800, "the bread policy functions are found and sliced (%d, %d chars)" % [act.length(), clear.length()])
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier3_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func act_bread(", "static func state_bread(")
	t.check(rb.length() > 1500, "route b's bread function is found and sliced (%d chars)" % rb.length())
	for body: String in [act, clear, rb]:
		t.check(not "WORDS" in body and not "NAMES" in body and not "STAGE_AT" in body and not "CAMERA_AT" in body and not "TownLayout." in body,
			"a bread policy reads no WORDS, NAMES, STAGE_AT, CAMERA_AT or TownLayout coordinate")
	t.check("d.words" in act and "d.words" in clear and "d.words" in rb, "each bread policy reads d.words")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a granary, a mill or a watermill, or a place of Aldermere: the tour, the brief, the goal, the hints, the strip's labels,
## the tags' names.
static func _words_true(t, d: CrownsBreadDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	for phase in ["", "not_yet", "engineers", "open"]:
		said.append(MissionHints.line(ID, phase))
	said.append_array(PackedStringArray(d.names))
	said.append_array(PackedStringArray(d.stage_labels))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	var re := RegEx.create_from_string("\\b(granary|granaries|mill|watermill|east road|south bank|across the river)\\b")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL bread line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names a granary, a mill, a watermill or a place of Aldermere (%s)" % [said])
	t.check(d.tour().size() == 3 and "market hall" in String(d.tour()[0][1]).to_lower() and "bakery" in String(d.tour()[1][1]).to_lower(),
		"the tour names the market hall and the bakery (%s)" % [d.tour()])
	t.check(MissionHints.line(ID, "not_yet") != "" and said.size() >= 14, "the lines were gathered (%d)" % said.size())


## The three targets (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as CrownsBreadDirector
	var at: Array = []
	for s in d.targets:
		at.append(s.center())
	t.check(at.size() == 3, "three target points for the camera check (%d)" % at.size())
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
