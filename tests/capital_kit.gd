extends RefCounted
## The shared kit of the Capital's mission tests (plan "The Capital at every tier", Task 1): static helpers, no run(), factored from
## test_capital_lamb.gd. A town with its walk grid, the parity band, the overrides and hostable checks, spots that land, the
## spread, the intro camera clear of the HUD stack, and a director set up in the Capital from the god's own def.
##   const Cap := preload("res://tests/capital_kit.gd")

const T2 := preload("res://tests/test_tier2_groundwork.gd")
## The parity band (spec 2.0, D26): the Capital's walk over Aldermere's.
const BAND_LO := 0.75
const BAND_HI := 1.35

## The worlds `starts()` has built, let go by `release()`.
static var _worlds: Array[Dictionary] = []


## A town of `city` with its walk grid: {env, town, grid}. Leaves `city` the active one.
static func town(city: StringName) -> Dictionary:
	City.use(city)
	var env := EnvironmentField.new()
	var tn := Town.new()
	tn.build(env)
	return {"env": env, "town": tn, "grid": WalkGrid.new().setup(env, tn)}


static func drop(b: Dictionary) -> void:
	(b.env as EnvironmentField).clear()
	(b.env as EnvironmentField).free()
	(b.town as Town).free()


## `g` snapped to walkable ground as the director snaps its spots.
static func snap(grid: WalkGrid, g: Vector2) -> Vector2:
	var w := grid.nearest_walkable(g)
	return w if w != Vector2.INF else g


## The length of the walk `from` -> `to` on `grid`, both snapped to walkable ground as the director snaps them.
static func walk(grid: WalkGrid, from: Vector2, to: Vector2) -> float:
	var a := snap(grid, from)
	var b := snap(grid, to)
	var way := 0.0
	var at := a
	for step in grid.path(a, b):
		way += at.distance_to(step)
		at = step
	return way


## Prints the two walks and checks the Capital's over Aldermere's is in the band.
static func parity(t, label: String, cap_walk: float, ald_walk: float, lo := BAND_LO, hi := BAND_HI) -> void:
	var ratio := cap_walk / maxf(ald_walk, 0.01)
	print("CAPITAL parity %s: capital %.1f, aldermere %.1f (%.2fx)" % [label, cap_walk, ald_walk, ratio])
	t.check(ratio >= lo and ratio <= hi, "%s: %.1f vs Aldermere's %.1f is %.2fx, in %.2f-%.2f" % [label, cap_walk, ald_walk, ratio, lo, hi])


## The mission's overrides in the Capital apply cleanly to a fresh def and a fresh director, and every overridden value has the type of
## the var it sets.
static func overrides_valid(t, id: String) -> void:
	var ov := City.by_id(&"capital").mission_overrides(id)
	t.check(ov.has("def") and ov.has("director"), "the Capital has overrides for %s (a def and a director section)" % id)
	var def := MissionBook.get_mission(id)
	var d := def.make_director()
	var bad_def := Overrides.apply(def, ov.get("def", {}))
	var bad_dir := Overrides.apply(d, (ov.get("director", {}) as Dictionary).duplicate(true), Overrides.town_vars(d))
	t.check(bad_def.is_empty() and bad_dir.is_empty(), "%s: the overrides apply cleanly to a fresh def and director (refused %s %s)" % [id, bad_def, bad_dir])
	var okay := true
	for key: Variant in ov.get("director", {}):
		var now: Variant = def.make_director().get(String(key))
		okay = okay and typeof(now) == typeof(ov.director[key])
	t.check(okay, "%s: every overridden value has the type of the var it sets" % id)


## The Capital hosts mission `id`: its list has `<id>@capital`, which is the mission in the Capital.
static func hostable(t, id: String) -> void:
	var capital := City.by_id(&"capital")
	t.check(MissionBook.hostable(id, capital), "the Capital hosts %s" % id)
	t.check(MissionBook.town_missions(&"capital").has("%s@capital" % id), "the Capital's list has %s@capital" % id)
	var m := MissionBook.get_mission("%s@capital" % id)
	t.check(m != null and m.city == &"capital", "%s@capital is the mission, in the Capital" % id)


## Every spot snaps within `max_snap` of itself on `b`'s grid (`spots`: label -> ground point).
static func spots_land(t, b: Dictionary, spots: Dictionary, max_snap := 0.6) -> void:
	var grid: WalkGrid = b.grid
	for label: String in spots:
		var at: Vector2 = spots[label]
		var landed := grid.nearest_walkable(at)
		t.check(landed != Vector2.INF and landed.distance_to(at) <= max_snap, "%s %s lands on walkable ground (snaps %.2f)" % [label, at,
			landed.distance_to(at) if landed != Vector2.INF else -1.0])


## No two of `points` are within `min` of each other (more than `min` apart).
static func spread(t, points: Array, min := 1.6) -> void:
	var tight := INF
	for i in points.size():
		for j in range(i + 1, points.size()):
			tight = minf(tight, (points[i] as Vector2).distance_to(points[j]))
	t.check(tight > min, "no two of %d points are within %.1f of each other (%.2f)" % [points.size(), min, tight])


## The intro camera keeps every tag in `tag_at` (or its edge arrow) clear of the padded HUD stack, at its resting place and at the intro's
## start (pattern test_exodus.gd).
static func camera_clear(t, def: MissionDef, tag_at: Array) -> void:
	var cam := def.camera()
	var zone := Rect2(T2.STACK.position, T2.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	var clear := true
	var clear_at_start := true
	for g: Vector2 in tag_at:
		clear = clear and T2.clear_of_stack(g, cam, zone)
		clear_at_start = clear_at_start and T2.clear_of_stack(g, def.intro_from, zone)
	t.check(clear, "%s: the %d tags are clear of the padded stack at the camera %s" % [def.id, tag_at.size(), cam])
	t.check(clear_at_start, "%s: the tags are clear of the padded stack at the intro's start %s" % [def.id, def.intro_from])


## A Capital world for mission `id` from the god's own def (GodNight.def_for in the Capital, the mission's tier), the director set up:
## the caller reads its vars, then calls release(). Leaves the Capital active. `tier`: the god's tier for an id MissionBook.get_mission() does not
## know (the Festival: a board act), 0 = the mission's own.
static func starts(t, id: String, tier := 0) -> MissionDirector:
	City.use(&"capital")
	var slot := GodSlot.make(1, "ruin", 3)
	slot.tier = tier if tier > 0 else MissionBook.get_mission(id).tier
	var def := GodNight.def_for(slot, id, "capital")
	t.check(def != null and def.city == &"capital", "%s: the god's def in the Capital is the Capital's" % id)
	var env := EnvironmentField.new()
	var tn := Town.new()
	tn.build(env)
	var grid := WalkGrid.new().setup(env, tn)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, tn, grid, node, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, tn, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director: MissionDirector = def.make_director()
	director.setup(rules, crowd, tn, null)
	rules.director = director
	_worlds.append({"env": env, "town": tn, "field": field, "world": node, "crowd": crowd, "rules": rules, "d": director})
	return director


## Lets the worlds `starts()` built go, and Aldermere back in.
static func release() -> void:
	for s: Dictionary in _worlds:
		T2.done(s)
	_worlds.clear()
	City.use(&"aldermere")
