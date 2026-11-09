extends RefCounted
## Nobody stays stuck. An animal runs the streets' way round a building (Animal.route_to()) where the straight walk
## (walk_to()) gives up at the wall; a hound of the other side (Visitors) chases its prey round one. A person standing
## in a gap the walk grid has closed, rocking against a margin on the spot, steps back onto open ground on the
## footprints alone and walks on (Person's stuck watchdog); whoever is meant to stand still is never moved. And nobody
## walks into such a gap in the first place: every straight walk with no route (a drift about its anchor, a fleeing
## scurry) goes only where a straight walk is open ground (Person.straight_clear()).

const DT := 1.0 / 60.0
## Aldermere: a gap between a house and an oak, ~0.31 across, where the stall probe found a citizen rocking for 85 s on
## its way to GOAL, its waypoint the cell WAYPOINT.
const TRAP := Vector2(5.73, -7.37)
const WAYPOINT := Vector2(5.75, -6.25)
const GOAL := Vector2(10.6, -9.2)
## The gap's east mouth, on open ground, level with the trap: walked straight west from here a body keeps clear of both
## margins all the way into the gap.
const MOUTH := Vector2(6.75, -7.37)
## Open cells round the trap that drifters are anchored on.
## Aldermere: a street spot by the tavern, and a home the stall probe saw a citizen there fail to route to.
const TAVERN_STREET := Vector2(-4.25, 2.25)
const SHUT_HOME := Vector2(-12.8, 14.8)
const AROUND: Array[Vector2] = [Vector2(6.75, -7.37), Vector2(6.75, -7.25), Vector2(7.25, -7.25), Vector2(4.25, -7.75),
	Vector2(5.75, -6.25), Vector2(5.75, -5.75)]


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	_route(t, env, grid)
	_people(t, env, grid)
	_straight(t, env, grid)
	_drifters(t, env, grid)
	_scurries(t, env, grid)
	_pocket(t, env, grid)
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


static func _person_at(env: EnvironmentField, grid: WalkGrid, at: Vector2, seed_value: int, is_soldier := false) -> Person:
	var p := Person.new()
	p.rng.seed = seed_value
	p.bounds = TownLayout.MAP
	p.block_env = env
	p.blocked = env.blocked
	p.env = env
	p.setup_person(is_soldier, at, grid)
	return p


const LINE := 1.5


## The first cell centre (scanning the map) with an open straight walk LINE long east of it: no closed cell, no margin.
static func _open_ground(env: EnvironmentField, grid: WalkGrid) -> Vector2:
	var m := City.current().map()
	var y := m.position.y + 4.25
	while y < m.end.y - 4.0:
		var x := m.position.x + 4.25
		while x < m.end.x - 6.0:
			var a := Vector2(x, y)
			var ok := grid.walkable(a) and grid.clear_line(a, a + Vector2(LINE, 0.0))
			var k := 0
			while ok and k <= 40:
				ok = not env.blocked(a + Vector2(LINE * float(k) / 40.0, 0.0), DummyEnemy.STEP_MARGIN)
				k += 1
			if ok:
				return a
			x += 0.5
		y += 0.5
	return Vector2.INF


## A straight walk is clear only over ground a body can really cross.
static func _straight(t, env: EnvironmentField, grid: WalkGrid) -> void:
	var margins_clear := true
	for k in 41:
		margins_clear = margins_clear and not env.blocked(MOUTH.lerp(TRAP, float(k) / 40.0), DummyEnemy.STEP_MARGIN)
	t.check(grid.walkable(MOUTH) and not env.blocked(MOUTH) and margins_clear and not grid.walkable(TRAP),
		"the gap's mouth is open ground, and the walk from it into the trap keeps a body's margin off the house and the oak all the way (the step rule would let it in)")
	var p := _person_at(env, grid, MOUTH, 11)
	t.check(not p.straight_clear(TRAP), "straight_clear: from the mouth into the gap is not clear -- the walk grid has it closed")
	t.check(not p.straight_clear(MOUTH + Vector2(-2.0, 0.0)), "nor straight through the gap and out beyond it")
	var a := _open_ground(env, grid)
	t.check(a != Vector2.INF, "open ground to walk on (%s)" % a)
	if a != Vector2.INF:
		p.ground_pos = a
		t.check(p.straight_clear(a + Vector2(LINE, 0.0)) and p.straight_clear(a + Vector2(LINE * 0.5, 0.0)),
			"on open ground a straight walk is clear")
		t.check(p.straight_clear(a), "and a walk of no length (standing) is clear")
	# Already in the gap (shoved there): it may walk out along the gap onto open ground, but not on into another closed cell.
	p.ground_pos = TRAP
	t.check(p.straight_clear(MOUTH), "one already standing in the gap may walk straight out of it onto open ground")
	t.check(not p.straight_clear(TRAP + Vector2(-0.3, 0.0)), "but not on to another closed cell of it")
	# Nothing to ask: anything goes.
	var bare := Person.new()
	bare.ground_pos = MOUTH
	t.check(bare.straight_clear(TRAP), "with no grid and no field to ask, every straight walk is clear")
	bare.free()
	p.free()


## People anchored all round the trap, milling about their spot for a minute, never once stand in a cell the grid has
## closed -- and so are never stuck there.
static func _drifters(t, env: EnvironmentField, grid: WalkGrid) -> void:
	var before := Person.unsticks
	var people: Array[Person] = []
	var open := true
	for i in AROUND.size():
		open = open and grid.walkable(AROUND[i]) and not env.blocked(AROUND[i])
		for s in 2:
			people.append(_person_at(env, grid, AROUND[i], 100 + i * 7 + s))
	t.check(open, "the drifters' anchors round the trap are open ground")
	var in_closed := 0
	var where := Vector2.INF
	var moved := 0.0
	var near_trap := INF
	for k in roundi(60.0 / (DT * 2.0)):
		for p in people:
			var was := p.ground_pos
			p.tick(DT * 2.0)
			moved += was.distance_to(p.ground_pos)
			near_trap = minf(near_trap, p.ground_pos.distance_to(TRAP))
			if not grid.walkable(p.ground_pos):
				in_closed += 1
				where = p.ground_pos
	t.check(moved > float(people.size()) * 5.0, "%d calm citizens anchored round the trap mill about for 60 s (%.0f units walked between them)"
		% [people.size(), moved])
	t.check(in_closed == 0, "and none ever stands in a cell the walk grid has closed (%d ticks in one, last at %s; came within %.2f of the trap)"
		% [in_closed, where, near_trap])
	t.check(Person.unsticks == before, "so the stuck watchdog never has to step one out (%d unsticks)" % (Person.unsticks - before))
	for p in people:
		p.free()


## A fleeing person's scurry (a hop with no route) lands only where a straight walk gets to: never in a closed cell, never
## across a footprint -- here with the danger behind it and the gap (or a house, or an oak) ahead, all round the trap.
static func _scurries(t, env: EnvironmentField, grid: WalkGrid) -> void:
	var hops := 0
	var bad := 0
	var stood := 0
	var old_bad := 0
	var n := 0
	for at in AROUND:
		for d in 8:
			var away := Vector2.RIGHT.rotated(TAU * float(d) / 8.0)
			var p := _person_at(env, grid, at, 300 + n)
			n += 1
			p.mind = Person.Mind.FLEE
			p._threat = at - away
			for i in 12:
				p.ground_pos = at
				p._target = at
				var replay := RandomNumberGenerator.new()
				replay.state = p.rng.state
				p._scurry()
				# The rule before: the first of the three turns whose end cell is open.
				var dir := away.rotated(replay.randf_range(-0.8, 0.8))
				for turn in [0.0, PI * 0.5, -PI * 0.5]:
					var was := at + dir.rotated(turn) * Person.SCURRY
					if grid.walkable(was):
						old_bad += 0 if _crossable(env, grid, at, was) else 1
						break
				if p._target == at:
					stood += 1
					continue
				hops += 1
				bad += 0 if _crossable(env, grid, at, p._target) else 1
			p.free()
	t.check(old_bad > 0, "before: the old hop (only its end cell checked) went through a closed cell or a footprint %d times here" % old_bad)
	t.check(hops > 0 and bad == 0, "a scurry hops only where a straight walk gets to: %d hops, %d through a closed cell or a footprint (%d times it kept its target)"
		% [hops, bad, stood])


## Every 0.02 along the walk: an open cell, outside every footprint.
static func _crossable(env: EnvironmentField, grid: WalkGrid, a: Vector2, b: Vector2) -> bool:
	var n := maxi(ceili(a.distance_to(b) / 0.02), 1)
	for k in range(1, n + 1):
		var q := a.lerp(b, float(k) / float(n))
		if not grid.walkable(q) or env.blocked(q, 0.0):
			return false
	return true


## Hemmed in (a ring of closed cells round the one it stands in): no drift is open, so it stands -- every time, with the
## same two numbers drawn for the spot as ever.
static func _pocket(t, env: EnvironmentField, grid: WalkGrid) -> void:
	var a := _open_ground(env, grid)
	if a == Vector2.INF:
		return
	var c := grid.world_to_id(a)
	var closed: Array[Vector2i] = []
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var id := c + Vector2i(dx, dy)
			if maxi(absi(dx), absi(dy)) >= 1 and not grid.grid.is_point_solid(id):
				grid.grid.set_point_solid(id, true)
				closed.append(id)
	var centre := grid.id_to_world(c)
	var p := _person_at(env, grid, centre, 21)
	var stood := 0
	var would_leave := 0
	var two_draws := true
	var tries := 40
	for i in tries:
		var replay := RandomNumberGenerator.new()
		replay.state = p.rng.state
		p._drift()
		var off := Vector2(replay.randf_range(-Person.CALM_SPREAD, Person.CALM_SPREAD), replay.randf_range(-Person.CALM_SPREAD, Person.CALM_SPREAD))
		two_draws = two_draws and replay.state == p.rng.state
		var was := grid.nearest_walkable(centre + off, 3)
		if was != Vector2.INF and grid.world_to_id(was) != c:
			would_leave += 1
		if p._target == p.ground_pos:
			stood += 1
	t.check(would_leave > 0, "before: hemmed in, the drawn drift spot lay outside the ring %d times in %d" % [would_leave, tries])
	t.check(stood == tries, "with no drift open, it stands where it is (%d of %d drifts)" % [stood, tries])
	t.check(two_draws, "and every drift draws its two numbers and no more, whatever it tried")
	var still := true
	for k in roundi(10.0 / (DT * 2.0)):
		p.tick(DT * 2.0)
		still = still and p.ground_pos == centre
	t.check(still, "ten seconds on, it has not moved off its spot")
	p.free()
	for id in closed:
		grid.grid.set_point_solid(id, false)
	# Out of its street with its home across the houses: a calm citizen walks home by the streets, never straight at it.
	var straight := 0
	var routed := 0
	var wrong := 0
	for i in 20:
		var q := _person_at(env, grid, WAYPOINT, 40 + i)
		q.anchor = GOAL
		q._drift()
		if q.has_goal():
			routed += 1
			wrong += 0 if q.goal() == GOAL and not q._path.is_empty() else 1
		else:
			straight += 1
			wrong += 0 if q.straight_clear(q._target) and q._target.distance_to(GOAL) <= Person.CALM_SPREAD * 1.5 + 1.5 else 1
		q.free()
	t.check(routed > 0 and wrong == 0, "far from home with no straight way there, a calm citizen walks home by a route (%d routed, %d drifted straight, %d otherwise)"
		% [routed, straight, wrong])
	# Home in a corner the grid has shut off (the stall probe's: no route in from the street by the tavern): it mills
	# about where it stands instead.
	var street := TAVERN_STREET
	t.check(grid.walkable(street) and grid.path(street, SHUT_HOME).is_empty(), "(no route from the street by the tavern to that home)")
	var milled := 0
	var held := 0
	for i in 20:
		var q := _person_at(env, grid, street, 70 + i)
		q.anchor = SHUT_HOME
		for k in 2:
			q.ground_pos = street
			q._drift()
			var ok := not q.has_goal() and q.straight_clear(q._target)
			held += 0 if ok else 1
			# Asked once, the anchor with no route is remembered: the second drift mills about its feet straight away.
			if ok and q._no_route_to == SHUT_HOME and q._target != q.ground_pos and q._target.distance_to(street) <= Person.CALM_SPREAD * 1.5 + 1.5:
				milled += 1
		q.free()
	t.check(milled > 0 and held == 0, "with no route home, a calm citizen mills about where it stands, open ground only, holding no goal (%d of 40 drifts milled, %d otherwise)"
		% [milled, held])
