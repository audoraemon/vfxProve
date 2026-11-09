extends RefCounted
## Nobody stays stuck. An animal runs the streets' way round a building (Animal.route_to()) where the straight walk
## (walk_to()) gives up at the wall; a hound of the other side (Visitors) chases its prey round one. A person standing
## in a gap the walk grid has closed, rocking against a margin on the spot, steps back onto open ground on the
## footprints alone and walks on (Person's stuck watchdog); whoever is meant to stand still is never moved.

const DT := 1.0 / 60.0
## Aldermere: a gap between a house and an oak, ~0.31 across, where the stall probe found a citizen rocking for 85 s on
## its way to GOAL, its waypoint the cell WAYPOINT.
const TRAP := Vector2(5.73, -7.37)
const WAYPOINT := Vector2(5.75, -6.25)
const GOAL := Vector2(10.6, -9.2)


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	_route(t, env, grid)
	_people(t, env, grid)
	town.teardown()
	_hound(t)


## One side of a house to the other along its middle row: the straight walk meets the wall head on.
static func _across(env: EnvironmentField, grid: WalkGrid, k: int) -> Array:
	var found := 0
	for s: Structure in env.structures():
		if not is_instance_valid(s) or s.destroyed or s.kind != Structure.Kind.HOUSE:
			continue
		var r := s.footprint
		var y := grid.id_to_world(grid.world_to_id(r.get_center())).y
		var a := grid.id_to_world(grid.world_to_id(Vector2(r.position.x - 1.0, y)))
		var b := grid.id_to_world(grid.world_to_id(Vector2(r.end.x + 1.0, y)))
		if not grid.walkable(a) or not grid.walkable(b) or env.blocked(a) or env.blocked(b) or grid.clear_line(a, b):
			continue
		var path := grid.path(a, b)
		if path.is_empty() or float(path.size()) * WalkGrid.CELL > a.distance_to(b) * 4.0:
			continue
		if found == k:
			return [a, b]
		found += 1
	return []


static func _route(t, env: EnvironmentField, grid: WalkGrid) -> void:
	# The first house whose far side the straight walk cannot reach (the rule before routes).
	var pair := []
	var straight_failed := false
	for k in 30:
		pair = _across(env, grid, k)
		if pair.is_empty():
			break
		var w := Animal.new()
		w.breed = Animal.Breed.HOUND
		w.ground_pos = pair[0]
		var got := false
		for i in roundi(10.0 / DT):
			if w.walk_to(pair[1], DT, grid):
				got = not w.blocked
				break
		w.free()
		if not got:
			straight_failed = true
			break
	t.check(straight_failed, "before: a dog walking straight at the far side of a house gives up at its wall")
	if not straight_failed:
		return
	var a := Animal.new()
	a.breed = Animal.Breed.HOUND
	a.ground_pos = pair[0]
	var arrived := false
	var on_grid := true
	var took := 0.0
	while took < 15.0:
		took += DT
		if a.route_to(pair[1], DT, grid):
			arrived = not a.blocked
			break
		on_grid = on_grid and grid.walkable(a.ground_pos)
	t.check(arrived and a.ground_pos.distance_to(pair[1]) < 0.06,
		"routed, it goes round the house and gets to the far side (%.1f s, %.1f apart as the crow flies)"
		% [took, (pair[0] as Vector2).distance_to(pair[1])])
	t.check(on_grid, "and every step of the way is on walkable ground")
	# In plain sight, route_to is walk_to: the same step.
	var p := Animal.new()
	var q := Animal.new()
	p.ground_pos = pair[1]
	q.ground_pos = pair[1]
	var to: Vector2 = pair[1] + Vector2(0.0, 0.0)
	for d in [Vector2(0.5, 0.0), Vector2(-0.5, 0.0), Vector2(0.0, 0.5), Vector2(0.0, -0.5)]:
		if grid.clear_line(pair[1], pair[1] + d * 2.0):
			to = pair[1] + d * 2.0
			break
	p.route_to(to, DT, grid)
	q.walk_to(to, DT, grid)
	t.check(to != pair[1] and p.ground_pos == q.ground_pos and p.ground_pos != pair[1], "with its goal in plain sight it walks straight there, step for step as walk_to")
	# Nowhere to go: a goal sealed off (outside the map) is "cannot get there".
	var r := Animal.new()
	r.ground_pos = pair[0]
	var sealed := r.route_to(Vector2(9999.0, 9999.0), DT, grid)
	t.check(sealed and r.blocked, "a goal there is no route to is given up at once (blocked)")
	for n in [a, p, q, r]:
		n.free()


static func _hound(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var pair := []
	for k in 30:
		pair = _across(env, grid, k)
		if pair.is_empty() or (pair[0] as Vector2).distance_to(pair[1]) >= 2.5:
			break
	t.check(not pair.is_empty(), "a house to chase round")
	if not pair.is_empty():
		for p in crowd.citizens + crowd.soldiers:
			p.inside = true  # out of the hound's sight, all but its prey
		var prey: Person = crowd.citizens[0]
		prey.inside = false
		prey.mind = Person.Mind.CALM
		prey.ground_pos = pair[1]
		var visitors := Visitors.new().setup(field, crowd, grid, world)
		var mul := HoundGateFx.SPEED / (Animal.DOG_SPEED * Animal.RUN)
		var hound := visitors.summon(pair[0], Animal.Breed.HELLHOUND, 99, mul, 30.0, 0.5, 1.0, false)
		var rule: Visitors.Rule = visitors._rules[hound]
		var took := 0.0
		var skipped := false
		var bites := {"n": 0}
		visitors.bitten.connect(func(_v, _w, _f): bites.n += 1)
		while took < 4.0 and int(bites.n) == 0:
			visitors.step(DT)
			took += DT
			skipped = skipped or rule.skip_left > 0.0
		t.check(int(bites.n) > 0 and not skipped, "a hound of the other side runs round a house to the citizen behind it and bites (%.1f s, %.1f apart as the crow flies; never gave up on him)"
			% [took, (pair[0] as Vector2).distance_to(pair[1])])
		visitors.clear()
	town.teardown()
	crowd.clear()
	world.free()


## A person standing in the trap with its plan as the probe found it: waypoint WAYPOINT, then on to GOAL.
static func _trapped(env: EnvironmentField, grid: WalkGrid, seed_value: int) -> Person:
	var p := Person.new()
	p.rng.seed = seed_value
	p.bounds = TownLayout.MAP
	p.setup_person(false, TRAP, grid)
	p.block_env = env
	p.blocked = env.blocked
	p.env = env
	p._goal = GOAL
	p._path = grid.path(WAYPOINT, GOAL)
	p._leg = 0
	p._pick_target()
	return p


static func _people(t, env: EnvironmentField, grid: WalkGrid) -> void:
	t.check(not grid.walkable(TRAP) and not env.blocked(TRAP) and not grid.path(WAYPOINT, GOAL).is_empty(),
		"the probe's trap: ground a body may stand on in a cell the grid has closed, the way on from its waypoint open")
	var before := Person.unsticks
	var p := _trapped(env, grid, 5)
	var through := false
	var in_gap := true
	var took := 0.0
	# Ticked as an on-screen calm citizen is (every other frame).
	while took < Person.UNSTICK_AFTER - 0.2:
		p.tick(DT * 2.0)
		took += DT * 2.0
		in_gap = in_gap and not grid.walkable(p.ground_pos) and p.ground_pos.distance_to(TRAP) < 0.6
		through = through or env.blocked(p.ground_pos, 0.0)
	t.check(in_gap and p._goal == GOAL and Person.unsticks == before,
		"before the watchdog: on its way, it cannot leave the gap (never on open ground, never 0.6 from where it stood)")
	var moved_at := -1.0
	var from := p.ground_pos
	var closest := INF
	var margin_back := false
	while took < 40.0:
		p.tick(DT * 2.0)
		took += DT * 2.0
		through = through or env.blocked(p.ground_pos, 0.0)
		if moved_at < 0.0 and p.ground_pos.distance_to(from) > 0.3:
			moved_at = took
		if p._unstick_left <= 0.0 and Person.unsticks > before:
			margin_back = margin_back or p.step_margin == DummyEnemy.STEP_MARGIN
		closest = minf(closest, p.ground_pos.distance_to(GOAL))
		if p._goal == Vector2.INF and closest <= Person.GOAL_REACH + 0.05:
			break
	t.check(Person.unsticks > before and moved_at >= 0.0 and moved_at <= Person.UNSTICK_AFTER + Person.UNSTICK_FOR + 1.0,
		"stuck UNSTICK_AFTER, it steps out onto open ground and is moving again by %.1f s (moved at %.1f s, %d unstick(s))"
		% [Person.UNSTICK_AFTER + Person.UNSTICK_FOR + 1.0, moved_at, Person.unsticks - before])
	t.check(closest <= Person.GOAL_REACH + 0.05, "and walks on to its goal (%.2f from it at the nearest, %.1f s)" % [closest, took])
	t.check(not through, "in and out of the gap it never sets foot inside a footprint (blocked at margin 0.0 never true)")
	t.check(margin_back and p.step_margin == DummyEnemy.STEP_MARGIN, "out of the gap, its steps keep a body's margin again")
	p.free()

	# Meant to stand: queued at a gate, held, asleep, at its post -- in the same gap, none is ever moved.
	var still: Array[Person] = []
	var queued := _trapped(env, grid, 6)
	queued.queue_spot = queued.ground_pos
	still.append(queued)
	var held := _trapped(env, grid, 7)
	held.mind = Person.Mind.HOLD
	still.append(held)
	var sleeper := _trapped(env, grid, 8)
	sleeper.sleep(30.0)
	still.append(sleeper)
	var waiting := _trapped(env, grid, 9)
	still.append(waiting)  # a gate holds it back every frame (wait)
	var guard := Person.new()
	guard.rng.seed = 10
	guard.bounds = TownLayout.MAP
	guard.setup_person(true, grid.nearest_walkable(WAYPOINT), grid)
	guard.block_env = env
	guard.env = env
	guard.send_to_post(guard.ground_pos)
	still.append(guard)
	var count := Person.unsticks
	var at: Array[Vector2] = []
	for s in still:
		at.append(s.ground_pos)
	for i in roundi(8.0 / (DT * 2.0)):
		waiting.wait = 0.5
		for s in still:
			s.tick(DT * 2.0)
	var stayed := true
	for k in still.size() - 1:  # the guard shifts about his post
		stayed = stayed and still[k].ground_pos.distance_to(at[k]) < 0.15 and still[k]._unstick_left <= 0.0
	t.check(Person.unsticks == count and stayed,
		"queued, held, asleep, held back at a gate or standing at a post, nobody is unstuck in 8 s (%d unsticks)" % (Person.unsticks - count))
	for s in still:
		s.free()
