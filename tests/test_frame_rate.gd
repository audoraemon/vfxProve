extends RefCounted
## The capital's frame rate levers (capital plan, Task 14), one check per lever, on a built capital crowd:
## - the gates look only at the fleeing and at those they let through: a calm town's gates examine nobody;
## - the crowd LOD: off screen, the capital's people update half as often as Aldermere's (CityDef.offscreen_every()).

const BenchProf := preload("res://src/core/bench_prof.gd")


static func run(t) -> void:
	var b := _build()
	_gates(t, b)
	_offscreen(t, b)
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


static func _build() -> Dictionary:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


## Lever 1, the gate pass: each open gate looked at all ~420 citizens twice a frame (1.2 ms of the capital's calm frame).
## It now looks only at the fleeing and the passing, found once a frame: none in a calm town, every gate for one who flees.
static func _gates(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	var town: Town = b.town
	crowd.advance(1.0 / 60.0)
	t.check(crowd.gate_visits == 0, "a calm capital's gates examine nobody (%d)" % crowd.gate_visits)
	var p: Person = crowd.citizens[0]
	p.mind = Person.Mind.FLEE
	var open := 0
	for g in town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			open += 1
	crowd.advance(1.0 / 60.0)
	t.check(open > 4 and crowd.gate_visits == open,
		"one fleeing citizen is examined once at each of the %d open gates (%d)" % [open, crowd.gate_visits])
	p.mind = Person.Mind.CALM


## Lever 2, the crowd LOD: with everyone off screen, a frame steps a sixth of the capital's people (every 6th frame
## each) where Aldermere's rate, every 3rd, would step a third. Aldermere keeps its 3 (its checksums ride on it).
static func _offscreen(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	t.check(City.by_id(&"aldermere").offscreen_every() == Person.OFFSCREEN_EVERY,
		"Aldermere's people off screen keep their rate (every %d frames)" % Person.OFFSCREEN_EVERY)
	t.check(City.by_id(&"capital").offscreen_every() == Person.OFFSCREEN_EVERY * 2,
		"the capital's people off screen update half as often (every %d frames)" % (Person.OFFSCREEN_EVERY * 2))
	var view := Person.view
	Person.view = Rect2(-100000.0, -100000.0, 10.0, 10.0)  # the camera far away: nobody on screen
	var ticked := 0
	var frames := 12
	for k in frames:
		BenchProf.reset()
		BenchProf.on = true
		crowd.step_people(1.0 / 60.0)
		BenchProf.on = false
		ticked += int(BenchProf._count.get(&"people_ticked", 0))
	var n := crowd.citizens.size() + crowd.soldiers.size()
	var share := float(ticked) / float(frames * n)
	t.check(share > 0.12 and share < 0.22,
		"off screen, a capital frame steps about a sixth of its %d calm people (%.2f), not a third" % [n, share])
	# The fleeing keep Aldermere's rate: at 6 the capital's evacuation jammed at its gates.
	for p: Person in crowd.citizens:
		p.mind = Person.Mind.FLEE
	BenchProf.reset()
	BenchProf.on = true
	crowd.step_people(1.0 / 60.0)
	BenchProf.on = false
	var fled := float(BenchProf._count.get(&"people_ticked", 0) - _soldiers_ticked(crowd)) / crowd.citizens.size()
	for p: Person in crowd.citizens:
		p.mind = Person.Mind.CALM
	Person.view = view
	t.check(fled > 0.25 and fled < 0.42, "off screen, the fleeing still step every 3rd frame (%.2f)" % fled)


## How many soldiers stepped in the frame just run: those whose stagger falls on it, at the rate their state asks.
static func _soldiers_ticked(crowd: Crowd) -> int:
	var n := 0
	var f := Engine.get_process_frames()
	for p: Person in crowd.soldiers:
		var every := Person.offscreen_every if p.unhurried() else Person.OFFSCREEN_EVERY
		if (f + p.stagger_key()) % every == 0:
			n += 1
	return n
