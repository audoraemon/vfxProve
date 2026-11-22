extends RefCounted
## Plan "The Capital at every tier", Task 3: Broken Lanterns in the Capital (spec 6.1.2). The six shrines stand round the Temple in the Vigil's order;
## the town's overrides (src/game/town/cities/capital_missions/broken_lanterns.gd) are valid and hold after setup; the mission is hostable; the Vigil's
## round and each shrine's walk to the Temple door are in Aldermere's band (real grid walks); no shrine stands on a road or in a building, and
## the two Knights' posts of a shrine are more than 1.6 apart; the intro camera keeps the Temple door and every shrine's arrow clear of the padded
## HUD stack; the tour tells the truth about the Capital; the policy reads the director and no Aldermere const.

const ID := "broken_lanterns"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_reads_vars(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var spots := {}
	for i in (ov.director.shrine_spots as Array).size():
		spots["shrine %d" % (i + 1)] = ov.director.shrine_spots[i]
	Cap.spots_land(t, cap, spots)
	Cap.spread(t, ov.director.shrine_spots)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Lanterns test leaves Aldermere active")


## A fresh director holds the town var at its const.
static func _seeded(t) -> void:
	var d := BrokenLanternsDirector.new()
	t.check(d.shrine_spots == BrokenLanternsDirector.SHRINE_SPOTS, "a fresh director's shrine_spots is SHRINE_SPOTS (Aldermere's)")
	t.check(Overrides.town_vars(d) == ["shrine_spots"], "Broken Lanterns' town vars are shrine_spots (%s)" % [Overrides.town_vars(d)])
	t.check(BrokenLanternsDirector.KNIGHTS_AT == 90.0, "KNIGHTS_AT is untouched")
	t.check(MissionBook.broken_lanterns().camera_at == BrokenLanternsDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")


## The director places its shrines from the var, and the policy reads the director, not SHRINE_SPOTS or a TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission/broken_lanterns_director.gd")
	var place := src.substr(src.find("func _place_shrines()"))
	place = place.substr(0, place.find("\n\n\n"))
	t.check("shrine_spots" in place and not "SHRINE_SPOTS" in place, "_place_shrines reads shrine_spots, not SHRINE_SPOTS")
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	var policy := bc.substr(bc.find("func _lanterns("))
	policy = policy.substr(0, policy.find("func _slot_ready("))
	for fn in ["func _lantern_doom_target(", "func _lantern_line(", "func _lantern_target("]:
		var body := bc.substr(bc.find(fn))
		policy += body.substr(0, body.find("\nfunc ", 10))
	t.check(not "SHRINE_SPOTS" in policy and not "TownLayout." in policy and not "CAMERA_AT" in policy,
		"the lanterns policy reads no shrine const, CAMERA_AT or TownLayout coordinate")


static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var spots: Array = ov.director.shrine_spots
	var d := Cap.starts(t, ID) as BrokenLanternsDirector
	t.check(d != null and d.shrine_spots == spots, "the director reads back the Capital's shrine spots after setup")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-4.0, -6.0) and def.intro_from == def.camera_at + Vector2(0.0, 6.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.shrines.size() == 6, "six shrines stand (%d)" % d.shrines.size())
	_spots_land(t, d, cap)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)
	for s in d.shrines:
		t.check(not cap.grid.path(d.temple_door, d.relight_point(s)).is_empty(), "the bearer can walk from the Temple to the shrine at %s" % [s.center()])


## No shrine's footprint overlaps a road (avenue or lane) or a building, and the two Knights' posts of each shrine are more than 1.6 apart.
static func _spots_land(t, d: BrokenLanternsDirector, cap: Dictionary) -> void:
	var roads: Array = City.current().roads()
	var clear := true
	var tight := INF
	for s in d.shrines:
		var foot := Rect2(s.center() - BrokenLanternsDirector.SHRINE_SIZE * 0.5, BrokenLanternsDirector.SHRINE_SIZE)
		for r: Rect2 in roads:
			if r.intersects(foot):
				clear = false
				print("CAPITAL lanterns shrine %s is on road %s" % [s.center(), r])
		for b: Structure in (cap.town as Town)._built:
			if b != s and b.footprint.intersects(foot):
				clear = false
				print("CAPITAL lanterns shrine %s overlaps a building %s" % [s.center(), b.footprint])
		var offs: Array = BrokenLanternsDirector.GUARD_OFFSETS
		var p0: Vector2 = d._walkable(s.center() + (offs[0] as Vector2))
		var p1: Vector2 = d._walkable(s.center() + (offs[1] as Vector2))
		tight = minf(tight, p0.distance_to(p1))
	t.check(clear, "no shrine footprint overlaps a road or a building")
	# GUARD_OFFSETS put the posts exactly 1.6 apart; a post the grid snapped would be nearer.
	t.check(tight >= 1.6 - 0.001, "the two Knights' posts of each shrine stand the full 1.6 apart, none snapped nearer (%.3f)" % tight)


## The Vigil's round (the Temple door, then the six relight points in order: six legs) and each shrine's walk to the Temple door, Capital against
## Aldermere on the real grids (ruling, Task 2: band 0.75-1.35).
static func _walk_parity(t, d: BrokenLanternsDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.broken_lanterns())
	var ad: BrokenLanternsDirector = a.d
	var cw := _round(cap.grid, d)
	var aw := _round(ald.grid, ad)
	Cap.parity(t, "the Vigil's round (six legs)", cw, aw)
	var csum := 0.0
	var asum := 0.0
	for i in 6:
		var c := Cap.walk(cap.grid, d.relight_point(d.shrines[i]), d.temple_door)
		var l := Cap.walk(ald.grid, ad.relight_point(ad.shrines[i]), ad.temple_door)
		csum += c
		asum += l
		print("CAPITAL lanterns shrine %d to the Temple door: capital %.1f, aldermere %.1f" % [i + 1, c, l])
	Cap.parity(t, "the six shrines to the Temple door (total)", csum, asum)
	Kit.done(a)
	City.use(&"capital")


static func _round(grid: WalkGrid, d: BrokenLanternsDirector) -> float:
	var way := 0.0
	var at := d.temple_door
	for s in d.shrines:
		var to := d.relight_point(s)
		way += Cap.walk(grid, at, to)
		at = to
	return way


## No line of the Capital's tour names a place of another town.
static func _words_true(t, d: BrokenLanternsDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var wrong := false
	for line in said:
		for place in ["west quarter", "market square", "citadel", "old town"]:
			wrong = wrong or place in line.to_lower()
	t.check(not wrong, "no tour line names a place of Aldermere (%s)" % [said])
	t.check(d.tour().size() >= 2, "the tour has its stops (%d)" % d.tour().size())


## The Temple door and every shrine's arrow are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as BrokenLanternsDirector
	var at: Array = [d.temple_door]
	for s in d.shrines:
		at.append(s.center())
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
