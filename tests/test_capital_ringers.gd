extends RefCounted
## Plan "The Capital at every tier", Task 4: the Bell-Ringers in the Capital (spec 6.1.3). The three watch posts stand on the old town's west and north
## walls (the wall tower nearest each spot, never a gate tower or the bell tower); the town's overrides (src/game/town/cities/capital_missions/bell_ringers.gd)
## are valid and hold after setup; the mission is hostable; each post's door to the bell's foot is in Aldermere's band (real grid walks); each post is
## a distinct standing wall tower of the old town whose door is inside the ring; the door's face points toward the town's middle (a south-wall tower's
## north); the intro camera keeps the posts clear of the padded HUD stack; the tour tells the truth about the Capital; the policy reads the director.

const ID := "bell_ringers"
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
	for i in (ov.director.post_spots as Array).size():
		spots["post %d" % (i + 1)] = ov.director.post_spots[i]
	# A post's spot is a wall tower's place: the director takes the nearest tower, so the spot itself may sit on the wall.
	Cap.spots_land(t, cap, spots, 2.0)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Ringers test leaves Aldermere active")


## A fresh director holds every town var at its const.
static func _seeded(t) -> void:
	var d := BellRingersDirector.new()
	t.check(d.post_spots == BellRingersDirector.POST_SPOTS, "a fresh director's post_spots is POST_SPOTS (Aldermere's)")
	t.check(d.post_names == BellRingersDirector.POST_NAMES, "a fresh director's post_names is POST_NAMES")
	t.check(d.set_out_at == BellRingersDirector.SET_OUT_AT, "a fresh director's set_out_at is SET_OUT_AT")
	t.check(Overrides.town_vars(d) == ["post_spots", "post_names", "set_out_at"], "the Bell-Ringers' town vars (%s)" % [Overrides.town_vars(d)])
	t.check(BellRingersDirector.CHAIN_WAIT == 45.0 and BellRingersDirector.SET_OUT_AT == [40.0, 110.0, 180.0], "CHAIN_WAIT and SET_OUT_AT are untouched")
	t.check(MissionBook.bell_ringers().camera_at == BellRingersDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")
	# A silence witness (a subclass) builds its own names: none seeded from the Ringers' consts.
	t.check(SilenceWitnessDirector.new().post_names.is_empty(), "a fresh Silence Witness director starts with no post names")


## _begin, the tower search and the strip read the vars; the policy reads the director, no const and no TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission/bell_ringers_director.gd")
	var at := src.find("func _begin()")
	var body := src.substr(at) if at >= 0 else ""
	body = body.substr(0, body.find("\nfunc _tower_near"))
	t.check(at >= 0 and body.length() > 500, "_begin is found and sliced (%d chars)" % body.length())
	t.check("post_spots" in body and "post_names" in body and not "POST_SPOTS" in body and not "POST_NAMES" in body,
		"_begin reads post_spots and post_names, not the consts")
	var door_at := src.find("func _town_door(")
	var door := src.substr(door_at) if door_at >= 0 else ""
	door = door.substr(0, door.find("\nfunc _make_stone"))
	t.check(door_at >= 0 and door.length() > 200 and "town().get_center()" in door and not "map().get_center()" in door,
		"_town_door faces the town's middle (town(), not map())")
	var out_at := src.find("func out_at(")
	var out := src.substr(out_at) if out_at >= 0 else ""
	var out_end := out.find("\nfunc ", 5)
	out = out.substr(0, out_end) if out_end > 0 else ""
	t.check(out_at >= 0 and out.length() > 100 and not "SET_OUT_AT" in out, "out_at reads the set-out times from the var, not SET_OUT_AT")
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	var policy := ""
	var found := true
	var fns := ["func _ringers_act(", "func _ringers_hold_herald(", "func _ringers_prep(", "func _ringers_off(", "func _ringers_quiet("]
	for fn: String in fns:
		var f := bc.find(fn)
		found = found and f >= 0
		if f < 0:
			continue
		var rest := bc.substr(f + fn.length())
		var end := rest.find("\nfunc ")
		found = found and end > 0
		policy += rest.substr(0, end) if end > 0 else ""
	t.check(found and policy.length() > 1000, "the ringers policy functions are all found and sliced (%d chars)" % policy.length())
	t.check(not "POST_SPOTS" in policy and not "SET_OUT_AT" in policy and not "TownLayout." in policy and not "CAMERA_AT" in policy,
		"the ringers policy reads no post const, CAMERA_AT or TownLayout coordinate")


static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var d := Cap.starts(t, ID) as BellRingersDirector
	t.check(d != null and d.post_spots == ov.director.post_spots and d.set_out_at == BellRingersDirector.SET_OUT_AT,
		"the director reads back the Capital's post spots and set-out times after setup")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-14.0, -22.0) and def.intro_from == Vector2(-14.0, -16.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.posts.size() == 3 and d.doors.size() == 3 and d.post_names.size() == 3, "three posts stand, with doors and names (%d)" % d.posts.size())
	t.check(d.post_names == ov.director.post_names, "the posts are named as the Capital names them (%s)" % [d.post_names])
	t.check(d.tune_set_out_at == d.set_out_at, "the timeline's times are the var's")
	_spots_land(t, d)
	_walk_parity(t, d, cap, ald)
	_inward(t, d)
	City.use(&"capital")
	_words_true(t, d, cap)


## Each post is a distinct standing wall tower of the old town's ring, neither a gate tower nor the bell tower, and its door is inside the ring.
static func _spots_land(t, d: BellRingersDirector) -> void:
	var inner: Rect2 = City.current().town()
	var gates: Array = City.current().gate_towers()
	var distinct := {}
	for i in d.posts.size():
		var p := d.posts[i]
		distinct[p] = true
		var c := p.center()
		var on_ring := inner.grow(1.5).has_point(c) and not inner.grow(-1.5).has_point(c)
		var gate := false
		for g: Rect2 in gates:
			gate = gate or g.intersects(p.footprint)
		var bell_tower: Structure = d.crowd.bell.tower if d.crowd.bell != null else null
		t.check(on_ring and not gate and p != bell_tower and not p.destroyed and RuinWish.fits(p, "tower"),
			"%s post %s is a standing wall tower of the old town (not a gate tower, not the bell tower)" % [d.post_names[i], c])
		t.check(inner.has_point(d.doors[i]), "%s post's door %s is inside the ring" % [d.post_names[i], d.doors[i]])
		print("CAPITAL ringers post %d %s: tower %s door %s" % [i + 1, d.post_names[i], c, d.doors[i]])
	t.check(distinct.size() == 3, "the three posts are three distinct towers (%d)" % distinct.size())


## Each post's town door to the bell's foot, Capital against Aldermere on the real grids (band 0.75-1.35).
static func _walk_parity(t, d: BellRingersDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.bell_ringers())
	var ad: BellRingersDirector = a.d
	var cfoot: Vector2 = d.crowd.bell.foot
	var afoot: Vector2 = ad.crowd.bell.foot
	var csum := 0.0
	var asum := 0.0
	for i in 3:
		var c := Cap.walk(cap.grid, d.doors[i], cfoot)
		var l := Cap.walk(ald.grid, ad.doors[i], afoot)
		csum += c
		asum += l
		Cap.parity(t, "post %d (%s) door to the bell's foot" % [i + 1, d.post_names[i]], c, l)
	Cap.parity(t, "the three posts to the bell's foot (total)", csum, asum)
	Kit.done(a)
	City.use(&"capital")


## The door's face points toward the town's middle: a south-wall tower of the old town gets its door on the north.
static func _inward(t, d: BellRingersDirector) -> void:
	City.use(&"capital")
	var inner: Rect2 = City.current().town()
	var tower: Structure = null
	for s: Structure in d.town._built:
		if RuinWish.fits(s, "tower") and absf(s.center().y - inner.end.y) < 1.5 and (tower == null or absf(s.center().x - inner.get_center().x) < absf(tower.center().x - inner.get_center().x)):
			tower = s
	t.check(tower != null, "the old town has a standing south-wall tower to test")
	if tower == null:
		return
	var door := d._town_door(tower, d.crowd.bell.foot)
	t.check(door != Vector2.INF and door.y < tower.center().y, "a south-wall tower %s gets its door on the north: %s" % [tower.center(), door])


## No line of the Capital's tour names a post of Aldermere or claims a way is the shortest when it is not.
static func _words_true(t, d: BellRingersDirector, cap: Dictionary) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var wrong := false
	for line in said:
		for place in ["north-east", "east post", "market square", "citadel"]:
			wrong = wrong or place in line.to_lower()
	t.check(not wrong, "no tour line names a post of Aldermere (%s)" % [said])
	t.check(d.tour().size() >= 4, "the tour has its stops (%d)" % d.tour().size())
	var shortest := 0
	var best := INF
	for i in 3:
		var w := Cap.walk(cap.grid, d.doors[i], d.crowd.bell.foot)
		if w < best:
			best = w
			shortest = i
	var claims := -1
	for i in 3:
		if "shortest" in said[i].to_lower():
			claims = i
	t.check(claims < 0 or claims == shortest, "the tour calls a post's way the shortest only if it is (claims post %d, shortest is post %d)" % [claims, shortest])


## The bell's foot and every post's arrow are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as BellRingersDirector
	var at: Array = []
	for p in d.posts:
		at.append(p.center())
	at.append(d.crowd.bell.foot)
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
