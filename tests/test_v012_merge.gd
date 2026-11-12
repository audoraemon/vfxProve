extends RefCounted
## v0.12 Task 1: the merge of feat/capital-city. Clergy tests count the Capital's monks, the barracks' door is the city's, the
## sandbox is a dev mission of the Capital, and Aldermere's head count is still PEOPLE.

static func run(t) -> void:
	_clergy(t)
	_pressed_door(t)
	_sandbox(t)
	_aldermere_people(t)
	_river_rules(t)
	_long_steps(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the merge test leaves Aldermere the active city")


## A monk is clergy; no "is this person clergy" test compares the role to CLERGY by == or != in mission/descend/the rite.
## (A role table such as SKIP_ROLES or NOT_LAY, and an exact role pick -- _citizen_near(at, Role.CLERGY) -- stay.)
static func _clergy(t) -> void:
	t.check(CitizenProfile.is_clergy(CitizenProfile.Role.MONK) and CitizenProfile.is_clergy(CitizenProfile.Role.CLERGY),
		"monks and clergy are clergy")
	t.check(not CitizenProfile.is_clergy(CitizenProfile.Role.MAYOR), "a mayor is not")
	var files: Array[String] = ["res://src/game/crowd/banishing_rite.gd"]
	_scripts_under("res://src/game/mission", files)
	_scripts_under("res://src/game/descend", files)
	var re := RegEx.create_from_string("role\\s*(==|!=)\\s*CitizenProfile\\.Role\\.CLERGY")
	var found := PackedStringArray()
	for p: String in files:
		for line: String in FileAccess.get_file_as_string(p).split("\n"):
			if re.search(line.get_slice("#", 0)) != null:
				found.append(p.get_file())
	t.check(found.is_empty(), "no clergy test by == or != Role.CLERGY (found in %s)" % ", ".join(found))


## The barracks' door is the middle of the city's barracks' front: in Aldermere, the value v0.11.2 gave on TownLayout.BARRACKS.
static func _pressed_door(t) -> void:
	City.use(&"aldermere")
	var crowd := Crowd.new()
	var door := PressedWish.barracks_door(crowd)
	crowd.free()
	var r := TownLayout.BARRACKS
	t.check(door == Vector2(r.get_center().x, r.end.y + 0.5), "Aldermere's barracks door is the old expression (%s)" % door)


## The capital's sandbox is a dev mission whose city is the Capital; no board mission is dev.
static func _sandbox(t) -> void:
	var m := MissionBook.get_mission(MissionBook.CAPITAL_SANDBOX)
	t.check(m.id == MissionBook.CAPITAL_SANDBOX and m.city == &"capital", "the sandbox is the Capital's")
	t.check(MissionBook.is_dev("capital_sandbox"), "the sandbox is dev-only")
	t.check(not MissionBook.is_dev(MissionBook.TAX_COLLECTOR) and not MissionBook.is_dev(MissionBook.WARNING), "board missions are not dev")
	t.check(MissionBook.get_mission(MissionBook.TAX_COLLECTOR).city == &"aldermere", "a board mission is Aldermere's by default")


## Aldermere's head count is the v0.11 constant: 220 citizens and 100 soldiers.
static func _aldermere_people(t) -> void:
	City.use(&"aldermere")
	var c := City.current()
	t.check(c.citizens() + c.soldiers() == Mission.PEOPLE and Mission.PEOPLE == 320, "Aldermere keeps 220 + 100 people")


## The capital's walkers' river rules (no step into the water, wade ashore from a fallen span) are the Capital's: Aldermere's
## v0.11 nights ran without them and their checksums ride on it (D5, R8).
static func _river_rules(t) -> void:
	t.check(not City.by_id(&"aldermere").river_rules(), "Aldermere's walkers have no river rules")
	t.check(City.by_id(&"capital").river_rules(), "the Capital's walkers have them")
	_walker_obeys(t)


## The capital's long-step rule (a step that would overshoot its waypoint by ARRIVE or more lands on it, and a slide stops on the
## waypoint's line) is the Capital's (C8): Aldermere's real-play walking is as before the merge, whatever the frame time.
static func _long_steps(t) -> void:
	t.check(not City.by_id(&"aldermere").long_steps() and City.by_id(&"capital").long_steps(), "only the Capital lands long steps")
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		var e := DummyEnemy.new()
		e.bounds = Rect2(-100.0, -100.0, 200.0, 200.0)
		e.ground_pos = Vector2.ZERO
		e._target = Vector2(0.18, 0.0)
		e.walk_speed = 1.2
		e.tick(0.1)
		e.tick(0.1)
		# 0.12 a tick: the second step would carry it 0.06 past the waypoint.
		var want := 0.18 if id == &"capital" else 0.24
		t.check(is_equal_approx(e.ground_pos.x, want), "%s: two 0.12 steps toward a waypoint 0.18 away end at x=%.2f (got %.3f)" % [id, want, e.ground_pos.x])
		# A slide against a margin: the capital's stops on the waypoint's line, Aldermere's takes the step's whole length.
		e.ground_pos = Vector2(0.8247, -3.8342)
		e._target = Vector2(0.75, -3.75)
		e._idle = 0.0
		e.walk_speed = 1.44
		e.blocked = func(g: Vector2) -> bool: return g.x < 0.8
		e.tick(0.1)
		var want_y := -3.75 if id == &"capital" else -3.8342 + 0.144
		t.check(absf(e.ground_pos.y - want_y) < 0.001, "%s: a long slide ends at y=%.4f (got %.4f)" % [id, want_y, e.ground_pos.y])
		if id == &"capital":
			# (god T1R follow-up) A short step (under twice ARRIVE) past a free waypoint into a margin stops on the waypoint: sliding,
			# it rocked across the waypoint for ever (the Capital's Tax deputy, seed 2).
			e.ground_pos = Vector2.ZERO
			e._target = Vector2(0.06, 0.04)
			e._idle = 0.0
			e.walk_speed = 0.9
			e.blocked = func(g: Vector2) -> bool: return g.x > 0.065
			e.tick(0.1)
			t.check(e.ground_pos.distance_to(Vector2(0.06, 0.04)) < 0.001,
				"capital: a 0.09 step past a free waypoint 0.072 away, the overshoot blocked, stops on it (got %s)" % e.ground_pos)
		e.free()
	City.use(&"aldermere")


## A walker on Aldermere's bank stepping into its river: Person obeys the flag. Off (Aldermere's own city), the step is not
## blocked, as in v0.11.2; with the flag on (Aldermere's def with river_rules() true) the same step is.
static func _walker_obeys(t) -> void:
	City.use(&"aldermere")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var from := Vector2.INF
	var step := Vector2.ZERO
	for r: Rect2 in TownLayout.RIVERS:
		for side in [Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
			var edge_y := r.position.y if side.y < 0.0 else r.end.y
			var x := r.position.x + 1.0
			while x < r.end.x - 1.0 and from == Vector2.INF:
				var dry := Vector2(x, edge_y + side.y * 0.1)
				var wet := Vector2(x, edge_y - side.y * 0.1)
				if grid.walkable(dry) and not grid.walkable(wet):
					from = dry
					step = wet - dry
				x += 0.5
	t.check(from != Vector2.INF, "Aldermere has a bank to step off (%s)" % from)
	if from != Vector2.INF:
		var p := Person.new().setup_person(false, from, grid)
		t.check(not p._step_blocked(step), "an Aldermere walker steps into the river as before")
		var wet_city := WetAldermere.new()
		City.active = wet_city
		t.check(p._step_blocked(step), "with the river rules on, the same step is blocked")
		City.use(&"aldermere")
		p.free()
	town.free()
	env.free()
	City.use(&"aldermere")


## Aldermere with the capital's river rules on: only to show Person reads the flag.
class WetAldermere extends AldermereCity:
	func river_rules() -> bool:
		return true


static func _scripts_under(dir: String, out: Array[String]) -> void:
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in DirAccess.get_directories_at(dir):
		_scripts_under(dir.path_join(sub), out)
