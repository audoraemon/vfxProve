extends RefCounted
## Plan "The Capital at every tier", Task 8: the Vigil Flame in the Capital (spec 6.2.1). The Vigil walks Task 3's six shrine spots; Mira's shrine
## stands by Mira's house; the town's overrides (src/game/town/cities/capital_missions/vigil_flame.gd) are valid and hold after setup; the mission is
## hostable; the Vigil's round and Wren's carry are in Aldermere's band (real grid walks); the Relic Run inherits both town vars and changes nothing;
## the intro camera keeps the Temple door, the flame and Mira's shrine clear of the padded HUD stack; the words are true in the Capital; the policy
## reads the director and no Aldermere const.

const ID := "vigil_flame"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## Task 3's six Capital shrine spots, copied from capital_missions/broken_lanterns.gd (authoritative); the test asserts the two lists are equal.
const SPOTS := [Vector2(2.0, -11.5), Vector2(7.0, -14.5), Vector2(9.5, -11.5), Vector2(5.5, 0.0), Vector2(-3.0, -0.5), Vector2(-16.5, -14.5)]


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_reads_vars(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	t.check(ov.director.route_spots == SPOTS, "the Vigil's route_spots are Task 3's six Capital shrine spots (literal copy)")
	t.check(ov.director.route_spots == City.by_id(&"capital").mission_overrides("broken_lanterns").director.shrine_spots,
		"route_spots equal Broken Lanterns' shrine_spots in the Capital (source of truth)")
	var spots := {"mira_shrine": ov.director.mira_shrine}
	Cap.spots_land(t, cap, spots)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Flame test leaves Aldermere active")


## A fresh director holds each town var at its const, the Relic Run too (it inherits both and reads neither).
static func _seeded(t) -> void:
	var d := VigilFlameDirector.new()
	t.check(d.route_spots == BrokenLanternsDirector.SHRINE_SPOTS, "a fresh director's route_spots is SHRINE_SPOTS (Aldermere's)")
	t.check(d.mira_shrine == VigilFlameDirector.MIRA_SHRINE, "a fresh director's mira_shrine is MIRA_SHRINE (Aldermere's)")
	t.check(Overrides.town_vars(d) == ["route_spots", "mira_shrine"], "the Vigil Flame's town vars are route_spots and mira_shrine (%s)" % [Overrides.town_vars(d)])
	var r := RelicRunDirector.new()
	t.check(r.route_spots == BrokenLanternsDirector.SHRINE_SPOTS and r.mira_shrine == VigilFlameDirector.MIRA_SHRINE, "the Relic Run inherits both town vars at their consts")
	t.check(MissionBook.vigil_flame().camera_at == VigilFlameDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")
	t.check(VigilFlameDirector.WREN_AT == 50.0 and VigilFlameDirector.ROUTE_AT == 90.0, "WREN_AT and ROUTE_AT are untouched")


## The director places its route and shrine from the vars, and the policies read the director, not an Aldermere const or a TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission/vigil_flame_director.gd")
	src = src.replace("\r\n", "\n")
	var begin := _slice(src, "func _begin()", "\n\n\n")
	var vig := _slice(src, "func _start_vigil()", "\n\n\n")
	t.check(begin.length() > 200 and "mira_shrine" in begin and not "MIRA_SHRINE" in begin, "_begin reads mira_shrine, not MIRA_SHRINE")
	t.check(vig.length() > 200 and "route_spots" in vig and not "SHRINE_SPOTS" in vig, "_start_vigil reads route_spots, not SHRINE_SPOTS")
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	var policy := _slice(bc, "func _flame(", "\nfunc _flame_phase(") + _slice(bc, "func _flame_phase(", "\nfunc ")
	for fn: String in ["func _flame_swap(", "func _flame_carry(", "func _flame_wren_at(", "func _flame_beam_at(", "func _flame_clear(", "func _flame_threat("]:
		policy += _slice(bc, fn, "\nfunc ")
	t.check(policy.length() > 3000, "the flame policy functions are all found and sliced (%d chars)" % policy.length())
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier3_b.gd")
	var rb := _slice(route_b, "static func act_flame(", "static func act_festival(")
	t.check(rb.length() > 3000, "route b's flame functions are found and sliced (%d chars)" % rb.length())
	for body: String in [policy, rb]:
		t.check(not "SHRINE_SPOTS" in body and not "MIRA_SHRINE" in body and not "TownLayout." in body and not "CAMERA_AT" in body,
			"a flame policy reads no shrine const, MIRA_SHRINE, CAMERA_AT or TownLayout coordinate")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var d := Cap.starts(t, ID) as VigilFlameDirector
	t.check(d != null and d.route_spots == ov.director.route_spots and d.mira_shrine == ov.director.mira_shrine,
		"the director reads back the Capital's route_spots and mira_shrine after setup")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-3.0, -12.0) and def.intro_from == Vector2(-3.0, -6.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.vigil != null and d.vigil.route.size() == 6, "the Vigil walks six points")
	_in_reach(t, "the Capital", d.mira_shrine, d.searchlight.spire)
	t.check(d.shrine.distance_to(d.mira_shrine) <= 0.6 and cap.grid.walkable(d.shrine), "Mira's shrine %s lands on walkable ground (var %s)" % [d.shrine, d.mira_shrine])
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## The Vigil's round (the Temple door, then its six route points: six legs) and Wren's carry (the round point nearest Mira's shrine, to the shrine),
## Capital against Aldermere on the real grids (band 0.75-1.35).
static func _walk_parity(t, d: VigilFlameDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.vigil_flame())
	var ad: VigilFlameDirector = a.d
	Cap.parity(t, "the Vigil's round (six legs)", _round(cap.grid, d), _round(ald.grid, ad))
	Cap.parity(t, "Wren's carry (nearest round point to Mira's shrine)", _carry(cap.grid, d), _carry(ald.grid, ad))
	_in_reach(t, "Aldermere", ad.mira_shrine, ad.searchlight.spire)
	Kit.done(a)
	City.use(&"capital")


## Mira's shrine lies within the Searchlight's sweep of its spire (FAR, the beam's reach), as Aldermere's does (about 23 of 26): the carry's last stretch is under the Lantern's threat.
static func _in_reach(t, town: String, shrine: Vector2, spire: Vector2) -> void:
	t.check(spire != Vector2.INF and shrine.distance_to(spire) <= Searchlight.FAR, "%s: Mira's shrine is %.1f from the spire, inside the beams' reach %.0f" % [town, shrine.distance_to(spire), Searchlight.FAR])


static func _round(grid: WalkGrid, d: VigilFlameDirector) -> float:
	var way := 0.0
	var at := d.temple_door
	for p: Vector2 in d.vigil.route:
		way += Cap.walk(grid, at, p)
		at = p
	return way


static func _carry(grid: WalkGrid, d: VigilFlameDirector) -> float:
	var from := Vector2.INF
	for p: Vector2 in d.vigil.route:
		if from == Vector2.INF or p.distance_to(d.shrine) < from.distance_to(d.shrine):
			from = p
	return Cap.walk(grid, from, d.shrine)


## No line the player reads names a place of Aldermere or one the Capital lacks: the tour, the brief, the hints.
static func _words_true(t, d: VigilFlameDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	for phase in ["", "wren", "homeward", "carry"]:
		said.append(MissionHints.line(ID, phase))
	var wrong := false
	for line in said:
		for place in ["west quarter", "market square", "citadel", "old town", "forest"]:
			if place in line.to_lower():
				wrong = true
				print("CAPITAL flame line names '%s': %s" % [place, line])
	t.check(not wrong, "no line names a place of Aldermere or one the Capital lacks (%s)" % [said])
	t.check(d.tour().size() >= 3, "the tour has its stops (%d)" % d.tour().size())
	t.check("Mira's shrine" in String(d.tour()[1][1]) and d.tour()[1][0] == d.shrine, "the tour's second stop is Mira's shrine, where it stands")


## The Temple door, the flame's bearer and Mira's shrine (or its edge arrow) are clear of the padded HUD stack at the camera's resting place and
## at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as VigilFlameDirector
	var at: Array = [d.temple_door, d.shrine, d.vigil.bearer.ground_pos]
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
