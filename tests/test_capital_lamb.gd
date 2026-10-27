extends RefCounted
## v0.12 M2 Task 12: The Lost Lamb in the Capital (spec 2.4). The acolyte hides by the civic square's fountain and is led out of the
## old town by its west gate; the cathedral's door is where a seizer takes him. The town's overrides (src/game/town/cities/
## capital_missions/lost_lamb.gd) are valid and hold after setup; the mission is hostable; its key walks are in Aldermere's band (D26,
## R19); every spot lands on walkable ground; the watch, posts and patrols keep Aldermere's spread; no beat comes near the door where a
## seizure loses in seconds; the intro camera keeps the acolyte, the gate and the door clear of the padded HUD stack; the tour tells the
## truth about the Capital's hiding place and the searchers' time.

const ID := "lost_lamb"
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The parity band (spec 2.0, D26): the Capital's walk over Aldermere's.
const BAND_LO := 0.75
const BAND_HI := 1.35
## No beat point nearer the Temple's door than this (Aldermere moved a beat for it; spec 2.4).
const BEAT_FROM_DOOR := 6.0
## The spread of the mission's own people: two posts or two beat ends apart (the escort type's hearing: more than 1.6).
const SPREAD := 1.6


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	_hostable(t)
	# One Capital and one Aldermere, built once for the checks that need a grid.
	var cap := _town(&"capital")
	var ald := _town(&"aldermere")
	_walk_parity(t, cap, ald)
	_spots_land(t, cap)
	_beats(t, cap)
	_free(cap)
	_free(ald)
	_setup_holds(t)
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Lamb test leaves Aldermere active")


## A town of `city` with its walk grid.
static func _town(city: StringName) -> Dictionary:
	City.use(city)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	return {"env": env, "town": town, "grid": WalkGrid.new().setup(env, town)}


static func _free(b: Dictionary) -> void:
	(b.env as EnvironmentField).clear()
	(b.env as EnvironmentField).free()
	(b.town as Town).free()


## The length of the walk `from` -> `to` on `grid`, both snapped to walkable ground as the director snaps its spots.
static func _walk(grid: WalkGrid, from: Vector2, to: Vector2) -> float:
	var a := _snap(grid, from)
	var b := _snap(grid, to)
	var way := 0.0
	var at := a
	for step in grid.path(a, b):
		way += at.distance_to(step)
		at = step
	return way


static func _snap(grid: WalkGrid, g: Vector2) -> Vector2:
	var w := grid.nearest_walkable(g)
	return w if w != Vector2.INF else g


## The Capital's overrides for the Lamb, as the town files them.
static func _ov() -> Dictionary:
	return City.by_id(&"capital").mission_overrides(ID)


static func _overrides_valid(t) -> void:
	var ov := _ov()
	t.check(ov.has("def") and ov.has("director"), "the Capital has overrides for the Lost Lamb (a def and a director section)")
	var def := MissionBook.lost_lamb()
	var d := LostLambDirector.new()
	var bad_def := Overrides.apply(def, ov.get("def", {}))
	var bad_dir := Overrides.apply(d, (ov.get("director", {}) as Dictionary).duplicate(true), Overrides.town_vars(d))
	t.check(bad_def.is_empty() and bad_dir.is_empty(), "the overrides apply cleanly to a fresh def and director (refused %s %s)" % [bad_def, bad_dir])
	var okay := true
	for key: Variant in ov.get("director", {}):
		var now: Variant = LostLambDirector.new().get(String(key))
		okay = okay and typeof(now) == typeof(ov.director[key])
	t.check(okay, "every overridden value has the type of the var it sets")
	var dv: Dictionary = ov.director
	t.check(d.charge_start == dv.charge_start and d.gate_at == dv.gate_at and d.exit_at == dv.exit_at and d.return_to == dv.return_to
		and d.watch_posts.size() == 2 and d.beat_spots.size() == 2 and d.hunt_at == LostLambDirector.HUNT_AT
		and is_equal_approx(d.charge_pace, LostLambDirector.CHARGE_PACE), "the director reads back the Capital's spots and keeps Aldermere's tuned numbers")
	t.check(def.camera_at == Vector2(-12.0, -2.0) and def.intro_from == def.camera_at + Vector2(0.0, 6.0),
		"camera_at and intro_from are overridden together (C9)")


static func _hostable(t) -> void:
	var capital := City.by_id(&"capital")
	t.check(MissionBook.hostable(ID, capital), "the Capital hosts the Lost Lamb")
	t.check(MissionBook.town_missions(&"capital").has("lost_lamb@capital"), "the Capital's list has lost_lamb@capital")
	var m := MissionBook.get_mission("lost_lamb@capital")
	t.check(m.city == &"capital" and m.director == LostLambDirector, "lost_lamb@capital is the Lamb, in the Capital")
	t.check(Array(MissionNeeds.of(ID)) == ["temple"], "the Lamb needs only the temple (%s)" % [MissionNeeds.of(ID)])


## Key walks in the Capital against Aldermere's (D26): printed, then asserted in the band.
static func _walk_parity(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = _ov().director
	var cg: WalkGrid = cap.grid
	var ag: WalkGrid = ald.grid
	var rows := [
		["start -> gate mouth", _walk(cg, ov.charge_start, ov.gate_at), _walk(ag, LostLambDirector.START, LostLambDirector.GATE_MOUTH)],
		["gate mouth -> guardhouse", _walk(cg, ov.gate_at, ov.guardhouse), _walk(ag, LostLambDirector.GATE_MOUTH, LostLambDirector.GUARDHOUSE)],
		["gate mouth -> exit", _walk(cg, ov.gate_at, ov.exit_at), _walk(ag, LostLambDirector.GATE_MOUTH, LostLambDirector.EXIT)],
		["start -> temple door", _walk(cg, ov.charge_start, ov.return_to), _walk(ag, LostLambDirector.START, LostLambDirector.TEMPLE_DOOR)],
	]
	for k in 2:
		rows.append(["beat %d" % k, _walk(cg, ov.beat_spots[k][0], ov.beat_spots[k][1]),
			_walk(ag, LostLambDirector.BEATS[k][0], LostLambDirector.BEATS[k][1])])
	for r: Array in rows:
		var ratio: float = r[1] / maxf(r[2], 0.01)
		print("CAPITAL LAMB parity %s: capital %.1f, aldermere %.1f (%.2fx)" % [r[0], r[1], r[2], ratio])
		# The short ones (a post to the wall, an exit) are not walks the night turns on: only the long legs are banded.
		if r[0] in ["start -> gate mouth", "gate mouth -> guardhouse", "beat 0", "beat 1"]:
			t.check(ratio >= BAND_LO and ratio <= BAND_HI, "%s: %.1f vs Aldermere's %.1f is %.2fx, in %.2f-%.2f" % [r[0], r[1], r[2], ratio, BAND_LO, BAND_HI])
		else:
			t.check(r[1] > 0.0, "%s: a walk exists (%.1f)" % [r[0], r[1]])


## Every spot snaps within 0.6 of itself, and a path joins the acolyte's hiding place to the gate and the gate to the door.
static func _spots_land(t, cap: Dictionary) -> void:
	var grid: WalkGrid = cap.grid
	var ov: Dictionary = _ov().director
	var spots := {"charge_start": ov.charge_start, "gate_at": ov.gate_at, "exit_at": ov.exit_at, "guardhouse": ov.guardhouse,
		"return_to": ov.return_to}
	for k in ov.watch_posts.size():
		spots["watch_posts[%d]" % k] = ov.watch_posts[k]
	for k in ov.beat_spots.size():
		for j in (ov.beat_spots[k] as Array).size():
			spots["beat %d.%d" % [k, j]] = ov.beat_spots[k][j]
	for label: String in spots:
		var at: Vector2 = spots[label]
		var landed := grid.nearest_walkable(at)
		t.check(landed != Vector2.INF and landed.distance_to(at) <= 0.6, "%s %s lands on walkable ground (snaps %.2f)" % [label, at,
			landed.distance_to(at) if landed != Vector2.INF else -1.0])
	t.check(grid.path(_snap(grid, ov.charge_start), _snap(grid, ov.gate_at)).size() > 1, "a path joins the hiding place to the gate")
	t.check(grid.path(_snap(grid, ov.gate_at), _snap(grid, ov.exit_at)).size() > 0, "a path joins the gate to the way out")
	t.check(grid.path(_snap(grid, ov.gate_at), _snap(grid, ov.return_to)).size() > 1, "a path joins the gate and the cathedral's door")


## The posts and the beats' ends are more than SPREAD apart (the watch is two men, not a knot), and no beat comes within 6 of the door.
static func _beats(t, cap: Dictionary) -> void:
	var grid: WalkGrid = cap.grid
	var ov: Dictionary = _ov().director
	var posts: Array = ov.watch_posts
	t.check(_snap(grid, posts[0]).distance_to(_snap(grid, posts[1])) > SPREAD, "the two posts stand more than %.1f apart (%.2f)" % [SPREAD,
		_snap(grid, posts[0]).distance_to(_snap(grid, posts[1]))])
	# God T1R (Problem 10 (a)): the second post is the outer one, just outside the gate on the road, so every point within ESCAPE_REACH of the way
	# out is in its sight (as Aldermere's).
	var outer := _snap(grid, posts[1])
	t.check(outer.distance_to(_snap(grid, ov.exit_at)) <= EscortDirector.SIGHT - EscortDirector.ESCAPE_REACH
		and outer.distance_to(_snap(grid, ov.gate_at)) > _snap(grid, posts[0]).distance_to(_snap(grid, ov.gate_at)),
		"the second post stands just outside the gate: all of the way out is in its sight (%.2f from it)" % outer.distance_to(_snap(grid, ov.exit_at)))
	var ends := []
	for b: Array in ov.beat_spots:
		for p: Vector2 in b:
			ends.append(_snap(grid, p))
	var tight := INF
	for i in ends.size():
		for j in range(i + 1, ends.size()):
			tight = minf(tight, (ends[i] as Vector2).distance_to(ends[j]))
	t.check(tight > SPREAD, "no two beat ends are within %.1f of each other (%.2f)" % [SPREAD, tight])
	var door: Vector2 = _snap(grid, ov.return_to)
	var near := INF
	for b: Array in ov.beat_spots:
		var a: Vector2 = b[0]
		var z: Vector2 = b[1]
		near = minf(near, Geometry2D.get_closest_point_to_segment(door, a, z).distance_to(door))
	t.check(near >= BEAT_FROM_DOOR, "no beat comes within %.1f of the cathedral's door (nearest %.2f)" % [BEAT_FROM_DOOR, near])
	var guard := INF
	for p: Vector2 in posts:
		guard = minf(guard, door.distance_to(p))
	t.check(guard >= BEAT_FROM_DOOR, "the gate's posts are far from the cathedral's door (%.1f)" % guard)


## A Capital world for `def` on the Capital's map (Kit.world's bounds are Aldermere's).
static func _world(def: MissionDef) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, node, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director: MissionDirector = def.make_director()
	director.setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": node, "crowd": crowd, "rules": rules, "d": director}


## The set-up director in the Capital: the town's values hold after setup (snapped where the base snaps), the acolyte is a cleric near
## the civic fountain, the posts and patrols stand where the town says, and the tour tells the truth.
static func _setup_holds(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("lost_lamb@capital")
	var s := _world(def)
	var d: LostLambDirector = s.d
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var ov: Dictionary = _ov().director
	t.check(d.hunt_at == LostLambDirector.HUNT_AT and is_equal_approx(d.charge_pace, LostLambDirector.CHARGE_PACE) and d.charge_start == ov.charge_start,
		"the town's numbers and hiding place survive setup")
	t.check(d.gate_at == d._walkable(ov.gate_at) and d.exit_at == d._walkable(ov.exit_at) and d.return_to == d._walkable(ov.return_to)
		and d.guardhouse == d._walkable(ov.guardhouse), "the gate, exit, door and guardhouse are the town's, snapped to walkable ground")
	t.check(d.beats.size() == 2 and d.beats[0][0] == d._walkable(ov.beat_spots[0][0]) and d.beats[1][1] == d._walkable(ov.beat_spots[1][1]),
		"the beats are built from the town's beat spots")
	var c := d.charge
	var cleric := c != null and is_instance_valid(c) and c.profile.role == CitizenProfile.Role.CLERGY
	t.check(cleric and c.ground_pos.distance_to(ov.charge_start) < 0.6,
		"the acolyte is a cleric of the Capital, hiding near the civic square's fountain (%.1f away)" % (c.ground_pos.distance_to(ov.charge_start) if c != null else -1.0))
	t.check(d.watch.size() == 2 and d.patrols.size() == 2, "two on the watch and two patrol pairs (%d, %d)" % [d.watch.size(), d.patrols.size()])
	var posted := true
	for k in d.watch.size():
		posted = posted and (d.watch[k] as Person).ground_pos.distance_to(d.watch_posts[k]) < 6.0
	t.check(posted, "the watch stands at the west gate's posts")
	var stops := d.tour()
	t.check(stops.size() == 3 and stops[1][0] == d.gate_at and stops[2][0] == d.return_to, "the tour stops: him, the gate, the door")
	t.check(String(stops[0][1]) == "The runaway acolyte hides by the civic square's fountain.",
		"the tour names the Capital's hiding place, not Aldermere's (%s)" % [stops[0][1]])
	t.check(String(stops[2][1]) == "The Temple. At %s it sends searchers after him." % UiTheme.clock(d.hunt_at), "the tour prints the searchers' time")
	var timed := false
	for e in d.timeline.upcoming(6):
		timed = timed or (String(e.id) != "" and is_equal_approx(float(e["at"]), d.hunt_at))
	t.check(timed, "the strip lists the searchers at the town's time")
	t.check(grid.path(d.charge.ground_pos, d.gate_at).size() > 1, "the acolyte has a way to the gate")
	Kit.done(s)
	City.use(&"aldermere")
	var plain := MissionBook.lost_lamb().make_director() as LostLambDirector
	t.check(plain.hideout_name == "the north-east fountain", "Aldermere's tour keeps its words")


## The intro camera's resting place keeps the first target's tag (the acolyte), the gate and the door clear of the padded HUD stack.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("lost_lamb@capital")
	var ov: Dictionary = _ov().director
	var cam := def.camera()
	var zone := Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	t.check(def.intro_from == cam + Vector2(0.0, 6.0), "the intro starts 6 south of where it rests")
	t.check(Kit.clear_of_stack(ov.charge_start, cam, zone), "the acolyte's tag (or its arrow) is clear of the padded stack at %s" % [cam])
	t.check(Kit.clear_of_stack(ov.gate_at, cam, zone) and Kit.clear_of_stack(ov.exit_at, cam, zone), "the west gate's tag is clear of the padded stack")
	t.check(Kit.clear_of_stack(ov.return_to, cam, zone), "the cathedral door's tag is clear of the padded stack")
	t.check(Kit.shown_at(ov.charge_start, def.intro_from) != Vector2.INF and Kit.clear_of_stack(ov.charge_start, def.intro_from, zone),
		"the acolyte is clear of the stack at the intro's start too")
	City.use(&"aldermere")
