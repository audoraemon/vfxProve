extends RefCounted
## The Folded Ward (Passage, Tier IV): a square of side 2 * HALF about the click, folded so its edges meet, for SPAN once
## it has folded (T_FOLD). NO WAY OUT: whoever walks out across an edge comes back in at the opposite edge, EDGE_IN inside
## it, on the same line, still walking the same way to the same goal; walking in is free. NO WAY IN: whoever walks in
## comes out past the opposite edge, EDGE_IN outside it; leaving is free. A spot that is not open ground gives the
## nearest open cell within FoldWard.SEEK on the right side, or a stop at the edge. People, soldiers, dogs and visitors
## alike; the dead and those indoors untouched; no fright, no danger, no luck.

const FX := "res://src/fx/control/the_folded_ward.gd"
const DT := 0.05
## A stretch of open ground in Aldermere (outside the east wall): the square and a band round it are all open.
const C := Vector2(22.0, 5.0)
## Where a body is put to be out of the square's sight (its record dropped).
const AWAY := Vector2(-27.0, 20.0)


static func _setup() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var pack := AnimalPack.new().setup(crowd, grid, world, 5)
	crowd.animals = pack
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	# Everyone parked in a far corner, standing, to be placed one by one (only those placed are stepped).
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos
		i += 1
	return {"crowd": crowd, "env": env, "grid": grid, "field": field, "world": world, "ctx": ctx, "pack": pack}


static func _done(s: Dictionary) -> void:
	(s.pack as AnimalPack).clear()
	(s.crowd as Crowd).clear()
	var ctx: FxContext = s.ctx
	ctx.overhead.free()
	ctx.ground.free()
	(s.world as Node).free()


## The ward cast at C in `mode`, its clock run until it has folded.
static func _cast(s: Dictionary, mode: String) -> FoldedWardFx:
	var fx: FoldedWardFx = FxTimeline.cast(load(FX), s.ctx, C, {"mode": mode})
	for k in roundi(FoldedWardFx.T_FOLD / DT) + 1:
		fx._process(DT)
	return fx


## `p` standing calm at `at`, at twice the walk, nowhere to go and nothing to do for a long while.
static func _stand(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p.pace = 2.0
	p.inside = false
	p.stay_left = 999.0
	p.anchor = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p._idle = 0.0
	p.walk_speed = p._mind_speed()


## `p` at `at`, walking to `goal`.
static func _walker(p: Person, at: Vector2, goal: Vector2) -> void:
	_stand(p, at)
	p.anchor = goal
	p.set_goal(goal)


## A body walked by hand: out of sight, then at `from` (seen there), then at `to` (seen there); where it is now.
static func _cross(fx: FoldedWardFx, body: Object, from: Vector2, to: Vector2) -> Vector2:
	body.ground_pos = AWAY
	fx._process(DT)
	body.ground_pos = from
	fx._process(DT)
	body.ground_pos = to
	fx._process(DT)
	return body.ground_pos


## Whether `g` is inside the square at C.
static func _in(g: Vector2) -> bool:
	return absf(g.x - C.x) <= FoldedWardFx.HALF and absf(g.y - C.y) <= FoldedWardFx.HALF


static func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.001


## `p` walked `seconds` by its own mind (only it), the ward looking every frame. Returns what happened, frame by frame:
## {"folds": [[from, to, x a frame later, state when folded]], "inside_after": every frame's inside-ness after the look}.
static func _walk(s: Dictionary, fx: FoldedWardFx, p: Person, seconds: float) -> Dictionary:
	var crowd: Crowd = s.crowd
	var folds: Array = []
	var inside: Array[bool] = []
	var pending: Array = []
	for k in roundi(seconds / DT):
		fx._process(DT)
		for w: Array in fx.ward.wrapped:
			if w[0] == p:
				pending.append([w[1], w[2], p.state])
		inside.append(_in(p.ground_pos))
		if p.is_alive() and not p.inside:
			p.tick(DT)
		crowd.advance(DT)
		for f: Array in pending:
			folds.append([f[0], f[1], p.ground_pos, f[2]])
		pending.clear()
	return {"folds": folds, "inside": inside}


static func run(t) -> void:
	var b := PowerBook.get_power("foldward")
	var modes: Array = b.get("modes", [])
	var area: Dictionary = Targeting.AREAS.get("foldward", {})
	t.check(int(b.dp) == 4 and float(b.cooldown) == 90.0 and String(b.aim) == "click" and PowerBook.is_quiet("foldward")
		and float(b.get("alarm", 0.0)) == 1.0 and PowerBook.authority_of("foldward") == "passage"
		and PowerBook.family("foldward") == "passage" and modes.size() == 2 and String(modes[0].key) == "out"
		and String(modes[0].name) == "NO WAY OUT" and String(modes[1].key) == "in" and String(modes[1].name) == "NO WAY IN"
		and PowerBook.icon("foldward") != null and PowerBook.hud_icon("foldward") != null and PowerBook.clip("foldward") != null
		and String(area.get("shape", "")) == "square" and float(area.get("half", 0.0)) == FoldedWardFx.HALF
		and Rules.POWER_KINDS.get("foldward", null) == [],
		"The Folded Ward is Passage's 4 DP, 90 s, quiet (alarm 1), a click on a square of HALF, NO WAY OUT or NO WAY IN, kills nobody, with icons and clip")
	t.check(FoldedWardFx.HALF == 3.0 and FoldedWardFx.SPAN == 25.0 and FoldedWardFx.T_FOLD == 0.8 and FoldedWardFx.EDGE_IN == 0.3
		and FoldWard.SEEK == 1.0, "a square of 6, standing 25 s once folded over 0.8 s; back in 0.3 from the edge; open ground looked for within 1")
	_rule(t)
	_no_way_out(t)
	_no_way_in(t)
	_everyone(t)
	_blocked(t)
	_span(t)
	_quiet(t)
	var one := _loop_run()
	t.check(one != "" and one == _loop_run(), "two casts on the same town fold the same walkers the same way, to the hundredth (%s)" % one.left(80))


## The fold as a rule, on bare ground (no grid, no buildings).
static func _rule(t) -> void:
	var out := FoldWard.new(Vector2.ZERO, 3.0, FoldWard.Mode.OUT, null, null)
	t.check(out.crosses(Vector2(2.9, 1.0), Vector2(3.05, 1.0)) and out.folded(Vector2(2.9, 1.0), Vector2(3.05, 1.0)) == Vector2(-2.7, 1.0)
		and out.folded(Vector2(-2.9, -1.5), Vector2(-3.02, -1.5)) == Vector2(2.7, -1.5)
		and out.folded(Vector2(0.5, 2.95), Vector2(0.5, 3.1)) == Vector2(0.5, -2.7),
		"NO WAY OUT: out across x = +3 at y, in at x = -3 + 0.3 at the same y; the same for every edge")
	t.check(out.folded(Vector2(2.9, 2.9), Vector2(3.1, 3.1)) == Vector2(-2.7, -2.7)
		and out.folded(Vector2(-2.9, 2.9), Vector2(-3.1, 3.05)) == Vector2(2.7, -2.7),
		"NO WAY OUT: out across a corner, in at the opposite corner (both ways at once)")
	t.check(not out.crosses(Vector2(-3.1, 0.0), Vector2(-2.9, 0.0)) and not out.crosses(Vector2(4.0, 0.0), Vector2(4.1, 0.0))
		and not out.crosses(Vector2(1.0, 1.0), Vector2(1.1, 1.0)),
		"NO WAY OUT: walking in, walking about outside and walking about inside are free")
	t.check(not out.crosses(Vector2(2.9, 0.0), Vector2(4.5, 0.0)),
		"a jump of more than JUMP (a power setting someone down elsewhere) is not a walk across the edge")
	var inn := FoldWard.new(Vector2.ZERO, 3.0, FoldWard.Mode.IN, null, null)
	t.check(inn.crosses(Vector2(-3.1, 1.0), Vector2(-2.95, 1.0)) and inn.folded(Vector2(-3.1, 1.0), Vector2(-2.95, 1.0)) == Vector2(3.3, 1.0)
		and inn.folded(Vector2(0.2, 3.05), Vector2(0.2, 2.9)) == Vector2(0.2, -3.3)
		and inn.folded(Vector2(-3.1, -3.1), Vector2(-2.9, -2.9)) == Vector2(3.3, 3.3),
		"NO WAY IN: in across x = -3 at y, out at x = +3 + 0.3 at the same y; across a corner, out past the opposite corner")
	t.check(not inn.crosses(Vector2(2.9, 0.0), Vector2(3.1, 0.0)) and not inn.crosses(Vector2(0.0, 0.0), Vector2(0.1, 0.0)),
		"NO WAY IN: leaving and walking about inside are free")


## NO WAY OUT on the town's ground, with people walking by their own minds.
static func _no_way_out(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var fx := _cast(s, "out")
	var h := FoldedWardFx.HALF
	var edge_in := FoldedWardFx.EDGE_IN

	# By hand: one walks out across the east edge.
	var p: Person = crowd.citizens[0]
	_walker(p, C + Vector2(2.9, 0.4), C + Vector2(4.5, 0.4))
	var goal := p.goal()
	var at := _cross(fx, p, C + Vector2(2.9, 0.4), C + Vector2(3.04, 0.4))
	t.check(_near(at, C + Vector2(-h + edge_in, 0.4)) and p.goal() == goal and not p._path.is_empty()
		and p._path[p._path.size() - 1].distance_to(goal) < 0.6,
		"walking out of the east edge she is back in 0.3 inside the west edge on the same line, still bound for her goal by a way planned from there (%s)" % (at - C))
	at = _cross(fx, p, C + Vector2(2.92, 2.93), C + Vector2(3.03, 3.05))
	t.check(_near(at, C + Vector2(-h + edge_in, -h + edge_in)), "out across the south-east corner, in at the north-west corner (%s)" % (at - C))

	# Walked by her own mind: east to a goal outside, for 15 s at twice the walk. She keeps walking out and coming in.
	var before := Person.unsticks
	_walker(p, C + Vector2(0.0, 0.4), C + Vector2(4.5, 0.4))
	goal = p.goal()
	fx.ward.forget()
	var run := _walk(s, fx, p, 15.0)
	var folds: Array = run.folds
	var same_line := true
	var heading := true
	var landed_open := true
	for f: Array in folds:
		var from: Vector2 = f[0]
		var to: Vector2 = f[1]
		same_line = same_line and absf(from.y - to.y) < 0.001 and absf(to.x - (C.x - h + edge_in)) < 0.001
		heading = heading and (f[2] as Vector2).x > to.x
		landed_open = landed_open and fx.ward.open_ground(to)
	var always_in: bool = not (run.inside as Array).has(false)
	t.check(folds.size() >= 2 and same_line and always_in,
		"walking east to a goal outside she walks out of the east edge and comes back in at the west, on the same line, again and again; never out (%d folds)" % folds.size())
	t.check(heading and p.goal() == goal and landed_open,
		"each time she comes back in still walking east, still bound for the same goal, on open ground")
	t.check(Person.unsticks == before and _in(p.ground_pos),
		"the stuck watchdog never takes her for stuck, and nothing walks or plans her out (%d unsticks)" % (Person.unsticks - before))

	# One outside walks in freely: the trap fills up.
	var q: Person = crowd.citizens[1]
	_walker(q, C + Vector2(-5.0, -1.2), C + Vector2(4.5, -1.2))
	run = _walk(s, fx, q, 7.0)
	var first_in: int = (run.inside as Array).find(true)
	var folded_in := false
	for f: Array in run.folds:
		folded_in = folded_in or not _in(f[0])
	t.check(first_in >= 0 and not folded_in and _in(q.ground_pos) and not (run.inside as Array).slice(first_in).has(false),
		"one walking in from outside is let in, and then cannot leave")

	# Someone thrown out across the edge is folded in mid-flight and lands inside.
	var r: Person = crowd.citizens[2]
	_stand(r, C + Vector2(2.4, -0.6))
	fx.ward.forget()
	fx._process(DT)
	r.knock(Vector2(4.5, 0.0))
	run = _walk(s, fx, r, 1.5)
	t.check(run.folds.size() == 1 and int(run.folds[0][3]) == DummyEnemy.State.KNOCKBACK and _in(r.ground_pos),
		"one thrown out across the edge is carried across in mid-flight and comes down inside (%d folds)" % run.folds.size())
	_done(s)


## NO WAY IN on the town's ground.
static func _no_way_in(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var fx := _cast(s, "in")
	var h := FoldedWardFx.HALF
	var edge_in := FoldedWardFx.EDGE_IN

	var p: Person = crowd.citizens[0]
	_walker(p, C + Vector2(-3.1, 0.6), C + Vector2(4.5, 0.6))
	var goal := p.goal()
	var at := _cross(fx, p, C + Vector2(-3.06, 0.6), C + Vector2(-2.95, 0.6))
	t.check(_near(at, C + Vector2(h + edge_in, 0.6)) and p.goal() == goal,
		"walking in across the west edge he comes out 0.3 past the east edge on the same line, still bound for his goal (%s)" % (at - C))
	var q: Person = crowd.citizens[1]
	_stand(q, C + Vector2(2.9, -1.0))
	at = _cross(fx, q, C + Vector2(2.9, -1.0), C + Vector2(3.05, -1.0))
	t.check(_near(at, C + Vector2(3.05, -1.0)), "one inside walks out freely")

	# A passer-by: from west of it to east of it, across in an instant. The 9.5 units at 1.2 a second would take 8 s;
	# folded across the square it is there inside 4.
	_walker(p, C + Vector2(-5.0, 0.6), C + Vector2(4.5, 0.6))
	fx.ward.forget()
	var run := _walk(s, fx, p, 4.0)
	t.check(run.folds.size() == 1 and not run.inside.has(true) and p.ground_pos.distance_to(C + Vector2(4.5, 0.6)) <= Person.GOAL_REACH + 0.05,
		"a passer-by walking through is across in an instant, never inside, and is where it was going inside 4 s (%s)" % (p.ground_pos - C))

	t.check(not p.held_off() and fx.turned == 0, "a passer-by bound beyond the square is not turned away")

	# One whose goal is inside is turned away for good: put out once, it walks on outward, then mills outside -- no
	# flip-flop across the square -- and when the ward is gone it walks in to its goal.
	var before := Person.unsticks
	var r: Person = crowd.citizens[2]
	_walker(r, C + Vector2(-5.0, -0.8), C + Vector2(0.0, -0.8))
	var inner := r.goal()
	run = _walk(s, fx, r, 4.0)
	var put_out: Vector2 = run.folds[0][1] if not run.folds.is_empty() else Vector2.INF
	var after_turn := r.ground_pos
	t.check(run.folds.size() == 1 and r.held_off() and r.bound_for() == inner and after_turn.x > put_out.x + 0.5,
		"one bound for a spot inside is put out past the far edge once, and walks on outward the way it came out (%s -> %s)" % [put_out - C, after_turn - C])
	var more := _walk(s, fx, r, 10.0)
	t.check(more.folds.is_empty() and not (run.inside as Array).has(true) and not (more.inside as Array).has(true)
		and r.held_off() and r.bound_for() == inner and maxf(absf(r.ground_pos.x - C.x), absf(r.ground_pos.y - C.y)) <= h + 3.0,
		"then it mills about outside, never trying to get in again, still meaning to go there (%s)" % (r.ground_pos - C))
	t.check(Person.unsticks == before, "the stuck watchdog does not take it for stuck (%d)" % (Person.unsticks - before))
	var guard: Person = crowd.soldiers[0]
	_stand(guard, C + Vector2(1.0, 5.0))
	guard.post = C + Vector2(1.0, 1.0)
	guard.send_to_post(C + Vector2(1.0, 1.0))
	var post := guard.goal()
	var g_run := _walk(s, fx, guard, 6.0)
	t.check(g_run.folds.size() == 1 and not (g_run.inside as Array).has(true) and guard.held_off() and guard.bound_for() == post,
		"a soldier whose post is inside is turned away from it once and kept off it (%d folds, in %s, held %s, %s)" % [g_run.folds.size(),
		(g_run.inside as Array).has(true), guard.held_off(), guard.ground_pos - C])
	# Past the span: the ward is gone and each walks in to where it meant to be.
	while not fx.finished:
		fx._process(DT)
	run = _walk(s, fx, r, 9.0)
	t.check(not r.held_off() and _in(r.ground_pos) and r.ground_pos.distance_to(inner) <= 1.0,
		"when the ward is gone, the one turned away walks in to its goal, and mills there (%s)" % (r.ground_pos - C))
	_done(s)

	# A hellhound hunting someone inside circles outside: put out once, it waits at the edge nearest its prey.
	s = _setup()
	crowd = s.crowd
	fx = _cast(s, "in")
	var prey: Person = crowd.citizens[0]
	_stand(prey, C + Vector2(0.5, 0.0))
	var visitors := Visitors.new().setup(s.field, crowd, s.grid, s.world)
	var hound := visitors.summon(C + Vector2(-5.0, 0.2), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	var hound_folds := 0
	var hound_in := false
	for k in roundi(8.0 / DT):
		fx._process(DT)
		for w: Array in fx.ward.wrapped:
			if w[0] == hound:
				hound_folds += 1
		hound_in = hound_in or _in(hound.ground_pos)
		visitors.step(DT)
	t.check(hound_folds == 1 and not hound_in and hound.held_off() and prey.is_alive()
		and maxf(absf(hound.ground_pos.x - C.x), absf(hound.ground_pos.y - C.y)) <= h + 1.0,
		"a hellhound hunting someone inside is put out once and then circles outside at the edge, never getting in (%d folds, %s)" % [hound_folds, hound.ground_pos - C])
	visitors.clear()
	_done(s)


## Soldiers, the town's dogs and the visitors fold too; the dead and those indoors do not.
static func _everyone(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = s.grid
	var fx := _cast(s, "out")
	var h := FoldedWardFx.HALF
	var edge_in := FoldedWardFx.EDGE_IN

	var guard: Person = crowd.soldiers[0]
	_stand(guard, C + Vector2(0.0, 2.9))
	var at := _cross(fx, guard, C + Vector2(1.0, 2.9), C + Vector2(1.0, 3.06))
	t.check(_near(at, C + Vector2(1.0, -h + edge_in)), "a soldier walking out of the south edge comes back in at the north (%s)" % (at - C))

	var dog := Animal.new()
	dog.breed = Animal.Breed.HOUND
	dog.ground_pos = C
	dog.home = C
	dog.goal = C + Vector2(8.0, 0.0)
	dog.sync_position()
	(s.world as Node2D).add_child(dog)
	(s.pack as AnimalPack).animals.append(dog)
	at = _cross(fx, dog, C + Vector2(-2.95, -1.0), C + Vector2(-3.05, -1.0))
	t.check(_near(at, C + Vector2(h - edge_in, -1.0)) and dog.goal == C + Vector2(8.0, 0.0),
		"a town dog running out of the west edge comes back in at the east, still running for its goal")

	var visitors := Visitors.new().setup(s.field, crowd, grid, s.world)
	var hound := visitors.summon(C + Vector2(2.0, 2.0), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	at = _cross(fx, hound, C + Vector2(0.5, -2.95), C + Vector2(0.5, -3.05))
	t.check(crowd.visitors.has(visitors) and _near(at, C + Vector2(0.5, h - edge_in)),
		"a hellhound from Hound Gate running out of the north edge comes back in at the south")
	visitors.clear()
	t.check(not crowd.visitors.has(visitors), "a cleared pack of visitors is no longer walking the town")

	var dead: Person = crowd.citizens[3]
	_stand(dead, C + Vector2(2.9, 0.0))
	dead.ground_pos = AWAY
	fx._process(DT)
	dead.ground_pos = C + Vector2(2.9, 0.0)
	fx._process(DT)
	(s.field as EnemyField).kill(dead, &"stone")
	dead.ground_pos = C + Vector2(3.1, 0.0)
	fx._process(DT)
	t.check(_near(dead.ground_pos, C + Vector2(3.1, 0.0)), "the dead are not moved")
	var indoors: Person = crowd.citizens[4]
	_stand(indoors, C + Vector2(2.9, 1.0))
	indoors.inside = true
	at = _cross(fx, indoors, C + Vector2(2.9, 1.0), C + Vector2(3.05, 1.0))
	indoors.inside = false
	t.check(_near(at, C + Vector2(3.05, 1.0)), "one inside a building is not touched")
	var set_down: Person = crowd.citizens[5]
	_stand(set_down, C)
	at = _cross(fx, set_down, C + Vector2(2.5, 0.0), C + Vector2(4.0, 0.0))
	t.check(_near(at, C + Vector2(4.0, 0.0)), "one set down by another power beyond the edge (a jump, not a walk) is let be")
	_done(s)


## A far side that is not open ground: the nearest open cell on the right side within 1, else stopped at the edge.
static func _blocked(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var env: EnvironmentField = s.env
	var h := FoldedWardFx.HALF
	# Crates on the west edge where a walk out of the east edge at y = 0 would come back in.
	env.add_structure(Rect2(C + Vector2(-3.0, -0.2), Vector2(0.6, 0.4)), 0.5, Structure.Kind.CRATES)
	# A long stack along the north edge, deep enough that nothing open lies within 1 inside it.
	env.add_structure(Rect2(C + Vector2(-2.0, -3.0), Vector2(4.0, 2.2)), 0.5, Structure.Kind.CRATES)
	var fx := _cast(s, "out")
	var p: Person = crowd.citizens[0]
	_walker(p, C + Vector2(2.9, 0.0), C + Vector2(4.5, 0.0))
	var spot := fx.ward.folded(C + Vector2(2.9, 0.0), C + Vector2(3.04, 0.0))
	var at := _cross(fx, p, C + Vector2(2.9, 0.0), C + Vector2(3.04, 0.0))
	t.check(not fx.ward.open_ground(spot) and fx.ward.open_ground(at) and _in(at) and at.distance_to(spot) <= FoldWard.SEEK
		and at.x < C.x and p.goal() == C + Vector2(4.5, 0.0),
		"where the far side is not open ground she comes in on the nearest open cell inside within 1 of it (%s), off every building's margin" % (at - C))
	var q: Person = crowd.citizens[1]
	_walker(q, C + Vector2(0.0, 2.9), C + Vector2(0.0, 9.0))
	at = _cross(fx, q, C + Vector2(0.0, 2.9), C + Vector2(0.0, 3.05))
	t.check(_near(at, C + Vector2(0.0, 2.9)) and fx.stops >= 1,
		"where nothing within 1 inside the far edge is open, he is simply stopped at the edge, where he stood")
	_done(s)
	# NO WAY IN onto a blocked far side: the nearest open cell outside.
	s = _setup()
	env = s.env
	env.add_structure(Rect2(C + Vector2(3.0, -0.2), Vector2(0.6, 0.4)), 0.5, Structure.Kind.CRATES)
	fx = _cast(s, "in")
	var r: Person = (s.crowd as Crowd).citizens[0]
	_walker(r, C + Vector2(-3.1, 0.0), C + Vector2(4.5, 0.0))
	at = _cross(fx, r, C + Vector2(-3.05, 0.0), C + Vector2(-2.95, 0.0))
	t.check(fx.ward.open_ground(at) and not _in(at) and at.x > C.x + h,
		"NO WAY IN onto a blocked far side: out on the nearest open cell outside it (%s)" % (at - C))
	_done(s)


## Nothing before it folds, nothing after the span.
static func _span(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var fx: FoldedWardFx = FxTimeline.cast(load(FX), s.ctx, C, {"mode": "out"})
	var p: Person = crowd.citizens[0]
	_stand(p, C)
	var at := _cross(fx, p, C + Vector2(2.9, 0.0), C + Vector2(3.05, 0.0))
	t.check(fx.t < FoldedWardFx.T_FOLD and _near(at, C + Vector2(3.05, 0.0)), "before it has folded, walking out is free")
	while fx.t < FoldedWardFx.T_FOLD + FoldedWardFx.SPAN + 0.1:
		fx._process(DT)
	at = _cross(fx, p, C + Vector2(2.9, 0.0), C + Vector2(3.05, 0.0))
	t.check(not fx.holding and _near(at, C + Vector2(3.05, 0.0)), "after SPAN the square is only ground again")
	_done(s)


## No fright and no danger come of it.
static func _quiet(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var p: Person = crowd.citizens[0]
	var q: Person = crowd.citizens[1]
	_walker(p, C + Vector2(0.0, 0.4), C + Vector2(4.5, 0.4))
	_stand(q, C + Vector2(-1.0, -1.0))
	var threats := crowd.threats._active.size()
	var alarm := crowd.alarm
	var fx := _cast(s, "out")
	_walk(s, fx, p, 6.0)
	t.check(crowd.threats._active.size() == threats and crowd.alarm == alarm and p.mind == Person.Mind.CALM and q.mind == Person.Mind.CALM
		and fx.folds >= 1, "no danger, no alarm and no fright come of it: the folded walk on calm, and those beside them stay calm")
	_done(s)


## One whole NO WAY OUT and NO WAY IN on a town laid out the same way: every fold, to the hundredth.
static func _loop_run() -> String:
	var out := ""
	for mode in ["out", "in"]:
		var s := _setup()
		var crowd: Crowd = s.crowd
		var who: Array[Person] = []
		for k in 4:
			var p: Person = crowd.citizens[k]
			var y := -2.0 + float(k)
			if mode == "out":
				_walker(p, C + Vector2(-1.0 + float(k) * 0.5, y), C + Vector2(4.5 - float(k) * 0.3, y + 0.5))
			else:
				_walker(p, C + Vector2(-5.0, y), C + Vector2(float(k) - 1.5, y))
			who.append(p)
		var fx := _cast(s, mode)
		for f in roundi(10.0 / DT):
			fx._process(DT)
			for w: Array in fx.ward.wrapped:
				out += "%s(%.2f,%.2f)" % [mode, (w[2] as Vector2).x, (w[2] as Vector2).y]
			for p in who:
				p.tick(DT)
			crowd.advance(DT)
		out += "|%d;" % fx.folds
		_done(s)
	return out
