extends RefCounted
## The capital's frame rate levers (capital plan, Task 14), one check per lever, on a built capital crowd:
## - the gates look only at the fleeing and at those they let through: a calm town's gates examine nobody;
## - the crowd LOD: off screen, the capital's people update half as often as Aldermere's (CityDef.offscreen_every()).

const BenchProf := preload("res://src/core/bench_prof.gd")


static func run(t) -> void:
	var b := _build()
	_gates(t, b)
	_offscreen(t, b)
	_long_steps(t, b)
	_evac_at_30(t, b)
	(b.crowd as Crowd).clear()
	t.check(Person.offscreen_every == Person.OFFSCREEN_EVERY,
		"a capital crowd torn down leaves Person.offscreen_every at Aldermere's %d (%d)" % [Person.OFFSCREEN_EVERY,
			Person.offscreen_every])
	(b.world as Node).free()
	(b.town as Node).free()
	Person.offscreen_every = Person.OFFSCREEN_EVERY
	Person.frame_no = -1
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
	# Twelve successive frames (Person.frame_no: the test runner never advances the engine's own count), the people
	# stepped as the crowd's ticker steps them.
	var frames := 12
	var everyone := _out_of_doors(crowd.citizens + crowd.soldiers)
	var n := everyone.size()
	var share := float(_ticks(everyone, frames)) / float(frames * n)
	t.check(share > 0.12 and share < 0.22,
		"off screen, a capital frame steps about a sixth of its %d calm people (%.2f), not a third" % [n, share])
	# The fleeing keep Aldermere's rate: at 6 the capital's evacuation jammed at its gates. Counted over the citizens alone.
	for p: Person in crowd.citizens:
		p.mind = Person.Mind.FLEE
	var fleeing := _out_of_doors(crowd.citizens)
	var fled := float(_ticks(fleeing, frames)) / float(frames * fleeing.size())
	for p: Person in crowd.citizens:
		p.mind = Person.Mind.CALM
	Person.view = view
	t.check(fled > 0.28 and fled < 0.39, "off screen, the fleeing still step every 3rd frame (%.2f)" % fled)


## Those the crowd's ticker steps (nobody indoors).
static func _out_of_doors(people: Array) -> Array:
	return people.filter(func(p: Person) -> bool: return is_instance_valid(p) and not p.inside)


## How many of `people` stepped over `frames` successive frames: each one's frame() run once a frame, as the crowd's
## ticker runs it, and its steps counted where frame() counts them (BenchProf's people_ticked).
static func _ticks(people: Array, frames: int) -> int:
	var ticked := 0
	for f in frames:
		Person.frame_no = 1000 + f
		BenchProf.reset()
		BenchProf.on = true
		for p: Person in people:
			p.frame(1.0 / 60.0)
		BenchProf.on = false
		ticked += int(BenchProf._count.get(&"people_ticked", 0))
	Person.frame_no = -1
	return ticked


## A step longer than twice the arrival reach (DummyEnemy.ARRIVE): an off-screen runner at 30 fps steps every 3rd frame, a
## tenth of a second at once. Overshooting its waypoint by more than the reach each way, it rocked about it for ever and
## never arrived (Task 15: the capital's evacuation jammed at 30 fps). It lands on the waypoint instead.
static func _long_steps(t, b: Dictionary) -> void:
	var e := DummyEnemy.new()
	e.bounds = Rect2(-100.0, -100.0, 200.0, 200.0)
	e.ground_pos = Vector2.ZERO
	e._target = Vector2(0.18, 0.0)
	e.walk_speed = 1.2
	var target := e._target
	var nearest := INF
	for k in 6:
		e.tick(0.1)
		nearest = minf(nearest, e.ground_pos.distance_to(target))
	t.check(nearest < 0.05, "a walker stepping 0.12 a tick reaches a waypoint 0.18 away (nearest %.3f)" % nearest)
	# A waypoint it cannot reach for a margin in the way (x < 0.8 blocked): sliding the step's whole length along y, it
	# crossed the waypoint's line to and fro for ever. Stopping on the line, the next slide has nowhere to go, and the
	# walker gives that waypoint up for another (DummyEnemy._move()'s hit).
	e.ground_pos = Vector2(0.8247, -3.8342)
	e._target = Vector2(0.75, -3.75)
	e._idle = 0.0
	e.walk_speed = 1.44
	e.blocked = func(g: Vector2) -> bool: return g.x < 0.8
	var stuck_on := e._target
	var gave_up := false
	for k in 6:
		e.tick(0.1)
		gave_up = gave_up or e._target != stuck_on
	t.check(gave_up, "a walker stepping 0.14 a tick against a margin gives up a waypoint it cannot reach (at %s)" % e.ground_pos)
	e.free()
	# A fleeing citizen ticked at 10 Hz runs its whole way out of the capital, waypoint by waypoint.
	var grid: WalkGrid = b.grid
	var exit: Vector2 = City.current().exits()[0]
	var p := Person.new()
	p.rng.seed = 3
	p.bounds = City.current().map()
	p.setup_person(false, Vector2(5.0, 24.0), grid)
	p.mind = Person.Mind.FLEE
	p.walk_speed = p._mind_speed()
	p.set_goal(exit)
	var steps := 0
	while steps < 3000 and p.ground_pos.distance_to(exit) > Person.GOAL_REACH:
		p.tick(0.1)
		steps += 1
	t.check(p.ground_pos.distance_to(exit) <= Person.GOAL_REACH,
		"a fleeing citizen ticked every tenth of a second reaches the south exit (%s after %d ticks)" % [p.ground_pos, steps])
	p.free()


## The capital's evacuation at 30 fps (Task 15), as play runs it: the crowd every frame, everyone off screen, so each
## person steps by the crowd LOD (every 3rd frame when fleeing, a tenth of a second at once). At 60 fps 419 of 422 got
## out in the behaviour check; at 30 fps 92 did, and 358 stood rocking on a waypoint. Nobody may stand stuck, and the
## town empties as it does at 60 fps (this run at a 60 fps step: 300 out in 90 s, at 30 fps 294).
const EVAC_STEP := 1.0 / 30.0
const EVAC_SECONDS := 90.0
const STUCK_SECONDS := 10.0


static func _evac_at_30(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	var c := City.current() as CapitalCity
	var old_town := c.landmark(&"old_town_houses")
	crowd.alarms.regroup_seconds = 0.0
	for k in AlarmManager.LOCAL_EVENTS:
		crowd.alarms.incident(old_town.get_center())
	crowd.alarms.bell_rung = true
	crowd.add_alarm(100.0)
	var view := Person.view
	Person.view = Rect2(-100000.0, -100000.0, 10.0, 10.0)  # the camera far away: nobody on screen
	var start := crowd.citizens.size()
	var still_at := {}
	var still_since := {}
	var stuck := {}
	var clock := 0.0
	for f in roundi(EVAC_SECONDS / EVAC_STEP):
		Person.frame_no = f
		crowd.step_people(EVAC_STEP)
		crowd.advance(EVAC_STEP)
		clock += EVAC_STEP
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or not p.is_alive():
				continue
			if p.mind == Person.Mind.FLEE and p.queue_spot == Vector2.INF and p.passing_gate == null:
				if not still_at.has(p) or (still_at[p] as Vector2).distance_to(p.ground_pos) > 0.5:
					still_at[p] = p.ground_pos
					still_since[p] = clock
				elif clock - float(still_since[p]) > STUCK_SECONDS:
					stuck[p] = "%s at %s goal %s" % [p.profile.job, p.ground_pos.snapped(Vector2(0.1, 0.1)), p.goal()]
			else:
				still_at.erase(p)
	Person.frame_no = -1
	Person.view = view
	print("capital evac at 30 fps: escaped %d of %d in %d s, stuck %d" % [crowd.escaped_count, start, EVAC_SECONDS,
		stuck.size()])
	t.check(stuck.is_empty(), "at 30 fps nobody stands stuck for %d s (%d: %s)" % [STUCK_SECONDS, stuck.size(),
		stuck.values().slice(0, 4)])
	t.check(crowd.escaped_count >= 270, "at 30 fps the capital empties (%d of %d out in %d s)" % [crowd.escaped_count,
		start, EVAC_SECONDS])
