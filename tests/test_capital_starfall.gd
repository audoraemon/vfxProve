extends RefCounted
## v0.12 M2 Task 9: the board's Warning (Starfall) in the Capital (spec 2.1; src/game/town/cities/capital_missions/warning.gd).
## Overrides valid and hostable; each post's walk to the bellkeeper's foot and the Herald's walk to the cathedral door within
## the band of Aldermere's (stars 0.75-1.6x, D27; the Herald's 0.75-1.35x); the posts land on open ground and stand apart;
## the first star's tag clears the padded HUD stack at the intro's camera; the tour names the town's own values.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The wider band of the stars' runs (the old town's gates are where they are, D27), and the narrower one of the Herald's walk.
const STAR_BAND := Vector2(0.75, 1.6)
const HERALD_BAND := Vector2(0.75, 1.35)


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	_hostable(t)
	var home := _world(&"aldermere")
	var town := _world(&"capital")
	_walk_parity(t, home, town)
	_spots_land(t, town)
	_camera_clear(t)
	_tour_true(t, town)
	Kit.done(home)
	Kit.done(town)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Starfall test leaves Aldermere active")


## The board's Warning put in `city` (Aldermere: as the board plays it), set up in a built town.
static func _world(city: StringName) -> Dictionary:
	City.use(city)
	var def := TierBook.board("warning")
	if city != &"aldermere":
		def = MissionBook.in_city(def, city)
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
	var director := def.make_director()
	director.setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": node, "crowd": crowd, "rules": rules, "d": director, "def": def}


## The town's overrides apply to a fresh def and a fresh director with nothing reported, and each value has the type of the var it sets.
static func _overrides_valid(t) -> void:
	var ov := City.by_id(&"capital").mission_overrides("warning")
	t.check(not ov.is_empty() and ov.keys().all(func(k: Variant) -> bool: return String(k) in Overrides.KEYS),
		"the Capital has overrides for the Warning, in the def and director sections only")
	var def := TierBook.board("warning")
	t.check(Overrides.apply(def, ov.get("def", {})).is_empty(), "the def overrides apply with nothing reported")
	var d := def.make_director()
	var dir_ov: Dictionary = ov.get("director", {})
	t.check(Overrides.apply(d, dir_ov, Overrides.town_vars(d)).is_empty(), "the director overrides apply with nothing reported")
	var typed := true
	for key: Variant in dir_ov:
		typed = typed and typeof(d.get(String(key))) == typeof(dir_ov[key])
	t.check(typed and d is StarfallDirector, "each director value has the type of the var it sets")
	var sf := d as StarfallDirector
	var shaped := sf.star_falls.size() == 3
	for s: Array in sf.star_falls:
		shaped = shaped and s.size() == 3 and s[0] is float and s[1] is Vector2 and s[2] is String
	t.check(shaped and is_equal_approx(sf.stop_wait, StarfallDirector.STOP_WAIT),
		"three stars [seconds, post, name]; the wait between stars is Aldermere's %.0f s" % StarfallDirector.STOP_WAIT)
	var times := PackedFloat32Array()
	for s: Array in sf.star_falls:
		times.append(float(s[0]))
	t.check(times[0] >= 5.0 and times[1] - times[0] <= 90.0 and times[2] - times[1] <= 90.0 and times[2] < 200.0,
		"the stars fall in order at %s (no gap over 90 s: each later star also follows the last stop by %.0f s)" % [times, StarfallDirector.STOP_WAIT])


static func _hostable(t) -> void:
	var capital := City.by_id(&"capital")
	t.check(MissionBook.hostable("warning", capital), "the Capital hosts the Warning (needs met, overrides present)")
	t.check(MissionBook.town_missions(&"capital").has("warning@capital"), "the Capital's town list has warning@capital")
	var def := Mission.def_for("warning@capital", true, null)
	t.check(def.city == &"capital" and def.director == StarfallDirector and def.camera_at != Vector2.INF,
		"warning@capital is the board's Starfall in the Capital with its own camera")


## The length of a walk from `a` to `b` on `grid` (the people's own path).
static func _walk(grid: WalkGrid, a: Vector2, b: Vector2) -> float:
	var p := grid.path(a, b)
	var n := 0.0
	for i in range(p.size() - 1):
		n += p[i].distance_to(p[i + 1])
	return n


## Each star's run from its post to the bellkeeper's foot, and the Herald's from the foot to the cathedral's door (the lantern
## door), in a built town (its city active).
static func _runs(s: Dictionary) -> Array:
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = crowd._grid
	var foot := crowd.bell.foot
	var out := []
	for st: Array in d.star_falls:
		out.append(_walk(grid, d._walkable(st[1]), foot))
	var temple := City.current().landmark(&"temple")
	out.append(_walk(grid, foot, Vector2(temple.get_center().x, temple.end.y + 0.6)))
	return out


static func _walk_parity(t, home: Dictionary, town: Dictionary) -> void:
	City.use(&"aldermere")
	var a := _runs(home)
	City.use(&"capital")
	var c := _runs(town)
	City.use(&"aldermere")
	print("STARFALL parity (post -> bell foot x3, bell foot -> cathedral door): aldermere %s capital %s" % [a, c])
	var ok := true
	var shown := []
	for i in 4:
		var band := STAR_BAND if i < 3 else HERALD_BAND
		var r: float = c[i] / a[i]
		shown.append("%.2f" % r)
		ok = ok and r >= band.x and r <= band.y
	t.check(ok, "the runs are within the band of Aldermere's (stars %s, Herald %s): ratios %s" % [STAR_BAND, HERALD_BAND, shown])


## Every post lands on open ground within 0.6 of itself and the three stand more than 1.6 apart (the watchmen are the mission's
## own people: spread).
static func _spots_land(t, town: Dictionary) -> void:
	var d: StarfallDirector = town.d
	var grid: WalkGrid = (town.crowd as Crowd)._grid
	var worst := 0.0
	var apart := INF
	for i in d.star_falls.size():
		var p: Vector2 = d.star_falls[i][1]
		var snapped := grid.nearest_walkable(p)
		worst = maxf(worst, snapped.distance_to(p) if snapped != Vector2.INF else INF)
		for j in range(i + 1, d.star_falls.size()):
			apart = minf(apart, p.distance_to(d.star_falls[j][1]))
	t.check(worst <= 0.6, "each post snaps within 0.6 of itself (worst %.2f)" % worst)
	t.check(apart > 1.6, "the three posts stand more than 1.6 apart (%.1f)" % apart)


## The first target (the first star's gate, pointed at or shown) is clear of the padded HUD stack at the intro's camera, and
## the intro sweeps in from 6 south of it.
static func _camera_clear(t) -> void:
	var def := Mission.def_for("warning@capital", true, null)
	var d := def.make_director() as StarfallDirector
	Overrides.apply(d, City.by_id(&"capital").mission_overrides("warning").director, Overrides.town_vars(d))
	var zone := Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	var cam := def.camera()
	var first: Vector2 = d.star_falls[0][1]
	t.check(Kit.clear_of_stack(first, cam, zone), "the first star's gate (or its arrow) is clear of the padded stack at the camera (%s)" % [Kit.shown_at(first, cam)])
	t.check(def.intro_from.is_equal_approx(cam + Vector2(0.0, 6.0)), "the intro sweeps in from 6 south of the camera's rest")
	t.check(cam.is_equal_approx(first.lerp(City.by_id(&"capital").landmark(&"bell_tower").get_center(), 0.35)), "the camera rests a third of the way from the first post to the tower")


## A set-up director keeps the town's values and its tour names them.
static func _tour_true(t, town: Dictionary) -> void:
	var d: StarfallDirector = town.d
	var stops := d.tour()
	var want := ["The Harbour Gate. A star falls here at %s." % UiTheme.clock(10.0), "The West River Gate. A star falls here by %s." % UiTheme.clock(90.0),
		"The West Gate. A star falls here by %s." % UiTheme.clock(180.0)]
	var ok := stops.size() == 4
	for i in 3:
		ok = ok and String(stops[i][1]) == want[i] and (stops[i][0] as Vector2).is_equal_approx(d._walkable(d.star_falls[i][1]))
	t.check(ok, "the tour names the Capital's three gates and times, then the bellkeeper (%s)" % [stops.map(func(x: Array) -> String: return String(x[1]))])
	var next := d.tags().filter(func(m: MapTag) -> bool: return m.label == "NEXT STAR")
	t.check(next.size() == 1 and (next[0] as MapTag).at.is_equal_approx(d.star_falls[0][1]) and (next[0] as MapTag).edge,
		"the first NEXT STAR tag points at the harbour gate")
	t.check(d.stars.size() == 3 and d.star_falls[0][2] == "THE HARBOUR GATE", "setup kept the town's stars")
