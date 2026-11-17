extends RefCounted
## The Closing Cage, level 5 twist -- Dragged Cage (Death and Decree ability levels, Task 20; DL12): once while it closes a plain click moves
## the ring's centre up to 6.0 toward it over 2.0 s. Those it holds are carried with it, every frame still inside the bars; the buildings the
## ring crosses on the way are cracked and felled by the existing crush rule; a second click is refused; a follow-up starts no cooldown and
## sends no cast_made. Level 4 has no follow-up.

const CG := preload("res://tests/test_decree_cage.gd")
const C := CG.C
const DT := 0.1


static func _cast(ctx: FxContext, level: int, at := C) -> CageFx:
	return FxTimeline.cast(CageFx, ctx, at, {"level": level}) as CageFx


## The ground about C cleared for the test (wider than the cage's own test: the ring is 14 and travels 6), everyone parked far off.
static func _arena(made: Array) -> Dictionary:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var clear := Rect2(C - Vector2(24.0, 24.0), Vector2(48.0, 48.0))
	for s in env.structures().duplicate():
		if s.footprint.intersects(clear):
			env.remove(s, true, true)
	var d := {}
	d["east"] = env.add_structure(Rect2(C + Vector2(17.5, -0.5), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	d["rear"] = env.add_structure(Rect2(C + Vector2(-10.5, 3.0), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	d["away"] = env.add_structure(Rect2(C + Vector2(-20.5, -10.0), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	return d


## `n` people on the circle of `r` about C, away from the houses on the east-west line.
static func _ring_of(crowd: Crowd, n: int, r: float) -> Array[Person]:
	var out: Array[Person] = []
	var people: Array = crowd.citizens + crowd.soldiers
	for k in n:
		var ang := TAU * (0.04 + 0.92 * float(k) / float(n))
		var p: Person = people[10 + k]
		p.ground_pos = C + Vector2.from_angle(ang) * r
		out.append(p)
	return out


static func run(t) -> void:
	_level_four(t)
	_drag(t)
	_big_steps(t)
	_dies_and_short(t)
	_rules(t)
	_teardown(t)
	_two_casts(t)


static func _level_four(t) -> void:
	var made := CG._setup()
	var ctx: FxContext = made[5]
	_arena(made)
	var fx := _cast(ctx, 4)
	CG._run_to(fx, CageFx.T_LAND + 0.3)
	t.check(not fx._twist and not fx.can_follow_up() and not fx.follow_up(C + Vector2(10.0, 0.0), {}) and fx._c == C and fx.law.a == C,
		"level 4: no follow-up, the cage stays where it was cast")
	CG._run_to(fx, CageFx.T_LAND + 3.0)
	t.check(fx._c == C and fx.law.a == C, "and stays there while it closes")
	fx.end_now()
	fx.free()
	var f1 := _cast(ctx, 1)
	CG._run_to(f1, CageFx.T_LAND + 0.3)
	t.check(not f1.can_follow_up() and not f1.follow_up(C + Vector2(10.0, 0.0), {}), "level 1: none either")
	f1.end_now()
	f1.free()
	CG._done(made)


static func _drag(t) -> void:
	var made := CG._setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var b := _arena(made)
	var people: Array = crowd.citizens + crowd.soldiers
	var mid: Person = people[0]
	var west: Person = people[1]
	mid.ground_pos = C + Vector2(0.3, 0.2)
	west.ground_pos = C + Vector2(-10.0, 0.0)
	var ring := _ring_of(crowd, 8, 12.8)
	var mid0 := mid.ground_pos
	var west0 := west.ground_pos
	var fx := _cast(ctx, 5)
	t.check(fx._twist and not fx.can_follow_up(), "level 5: nothing to drag before the bars stand")
	CG._run_to(fx, CageFx.T_LAND + 0.05)
	t.check(fx.can_follow_up() and fx.law.members.has(mid) and fx.law.members.has(west) and is_equal_approx(fx.lv_radius, 14.0),
		"the bars stand at 14.0 and the cage can be dragged once")
	t.check(not b.east.destroyed and b.east._cracks.is_empty() and not b.rear.destroyed and b.rear._cracks.is_empty(),
		"the house on the path and the one behind are whole and uncracked")
	t.check(fx.follow_up_area().get("shape", "") == "circle" and is_equal_approx(float(fx.follow_up_area().get("r", 0.0)), fx.radius),
		"its preview is the ring as it stands")
	var click := C + Vector2(10.0, 0.0)
	t.check(fx.follow_up(click, {}) and fx.dragged and not fx.can_follow_up() and fx._c == C, "a click 10 away is taken; the centre has not moved yet")
	t.check(not fx.follow_up(C + Vector2(0.0, 5.0), {}) and not fx.can_follow_up(), "a second follow-up is refused")
	var slips := 0
	var frames := 0
	var t_end: float = fx.t + CageFx.DRAG_TIME + 0.001
	while fx.t < t_end and not fx.finished:
		fx._process(0.05)
		frames += 1
		for body: Variant in fx.law.members:
			if body.is_alive() and body.ground_pos.distance_to(fx._c) > fx.radius + 0.001:
				slips += 1
		if fx.law.a != fx._c or fx.law.b != fx._c:
			slips += 1000
	t.check(frames > 30 and slips == 0, "every frame of the move keeps every one held inside the bars of the centre now (%d slips in %d frames)" % [slips, frames])
	t.check(fx._c.distance_to(C + Vector2(6.0, 0.0)) < 0.001 and fx.law.a.distance_to(fx._c) < 0.001, "the centre moved 6.0 toward the click (%s)" % [fx._c - C])
	t.check(absf((mid.ground_pos - mid0).x - 6.0) < 0.05 and absf((mid.ground_pos - mid0).y) < 0.05 and mid.is_alive(),
		"a person at the middle ended 6.0 along (%s)" % [mid.ground_pos - mid0])
	t.check((west.ground_pos - west0).x > 5.0 and west.is_alive() and west.ground_pos.distance_to(fx._c) <= fx.radius + 0.001,
		"and one at the back was carried too, still inside (%s)" % [west.ground_pos - west0])
	var held := 0
	for p in ring:
		if p.is_alive() and p.ground_pos.distance_to(fx._c) <= fx.radius + 0.001 and fx.law.members.has(p):
			held += 1
	t.check(held == ring.size(), "the ring of people at the bars is held in it still (%d of %d)" % [held, ring.size()])
	t.check(b.east._cracks.size() > 0 and b.east.destroyed, "the house on the new ring's path is cracked and crushed (felled %d)" % fx.felled)
	t.check(b.rear.destroyed, "the house the old ring's back left is crushed as the bars sweep its middle")
	t.check(not b.away.destroyed and b.away._cracks.is_empty(), "a house the ring never reaches is whole")
	t.check(not fx.can_follow_up() and not fx.follow_up(C + Vector2(20.0, 0.0), {}) and fx._c.distance_to(C + Vector2(6.0, 0.0)) < 0.001,
		"after the drag a second click is still refused, and the centre stays")
	CG._run_to(fx, CageFx.T_LAND + fx.lv_close_time + DT)
	t.check(fx.shut and not mid.is_alive() and mid._kind == &"crushed" and not crowd.laws.has(fx.law),
		"the cage shuts at the new centre: the one carried there dies, and the law lifts")
	fx.free()
	CG._done(made)


## Frames of 1.0 s: the ring jumps 3.0 a frame; no building on the path is skipped.
static func _big_steps(t) -> void:
	var made := CG._setup()
	var ctx: FxContext = made[5]
	var b := _arena(made)
	var fx := _cast(ctx, 5)
	CG._run_to(fx, CageFx.T_LAND + 0.05)
	fx.follow_up(C + Vector2(10.0, 0.0), {})
	fx._process(1.0)
	fx._process(1.0)
	fx._process(0.1)
	t.check(fx._c.distance_to(C + Vector2(6.0, 0.0)) < 0.001 and b.east.destroyed and b.rear.destroyed and not b.away.destroyed,
		"with 1.0 s frames the ring still crushes the houses it crosses (east %s, rear %s)" % [b.east.destroyed, b.rear.destroyed])
	fx.end_now()
	fx.free()
	CG._done(made)


static func _dies_and_short(t) -> void:
	var made := CG._setup()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_arena(made)
	var people: Array = crowd.citizens + crowd.soldiers
	var doomed: Person = people[0]
	var other: Person = people[1]
	doomed.ground_pos = C + Vector2(1.0, 1.0)
	other.ground_pos = C + Vector2(1.0, -1.0)
	var fx := _cast(ctx, 5)
	CG._run_to(fx, CageFx.T_LAND + 0.05)
	fx.follow_up(C + Vector2(0.0, 12.0), {})  # south (+y), clamped to 6.0
	fx._process(0.5)
	var carried := other.ground_pos.y - (C.y - 1.0)
	t.check(carried > 1.4 and carried < 1.6 and fx._c.distance_to(C + Vector2(0.0, 1.5)) < 0.001,
		"a quarter of the way: the centre 1.5 along, the one held with it (%.3f)" % carried)
	t.check(field.kill(doomed, &"crushed", C) and not doomed.is_alive(), "one dies mid-drag")
	var where := doomed.ground_pos
	CG._run_to(fx, fx.t + 1.6)
	t.check(doomed.ground_pos == where and not fx.law.members.has(doomed), "he is skipped: not carried on, no longer held (%s)" % [doomed.ground_pos - where])
	t.check(fx._c.distance_to(C + Vector2(0.0, 6.0)) < 0.001 and absf(other.ground_pos.y - (C.y - 1.0) - 6.0) < 0.05 and other.is_alive(),
		"the others went the whole 6.0 (%.3f)" % (other.ground_pos.y - (C.y - 1.0)))
	fx.end_now()
	fx.free()
	# A click closer than 6 moves the centre to it; one on the centre is refused and keeps the drag.
	var fx2 := _cast(ctx, 5)
	CG._run_to(fx2, CageFx.T_LAND + 0.05)
	t.check(not fx2.follow_up(fx2._c, {}) and fx2.can_follow_up(), "a click on the centre is refused and keeps the drag")
	t.check(fx2.follow_up(C + Vector2(-2.5, 0.0), {}), "a click 2.5 away is taken")
	CG._run_to(fx2, fx2.t + 2.1)
	t.check(fx2._c.distance_to(C + Vector2(-2.5, 0.0)) < 0.001, "the centre goes to it, no further (%s)" % [fx2._c - C])
	fx2.end_now()
	fx2.free()
	CG._done(made)


## Through a real Rules.recast: it opens once the bars stand, sends no cast_made, starts no cooldown, and only the one click is taken.
static func _rules(t) -> void:
	var made := CG._setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	_arena(made)
	var rules := Rules.new().setup(PackedStringArray(["cage", "doom"]), ctx, made[1], made[3], crowd, crowd._town)
	rules.levels = {"cage": 5}
	var casts: Array = []
	var called: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _a: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): called.append([slot, key, p]))
	var fx := rules.cast(0, C) as CageFx
	var left := rules.cooldown_left(0)
	t.check(fx != null and casts.size() == 1 and left > 0.0 and fx._twist, "a level 5 cage cast through Rules")
	fx._process(0.3)
	t.check(not rules.recast(0, C + Vector2(8.0, 0.0)) and not rules.can_recast(0), "inside its busy lock a recast is false")
	fx._process(0.6)
	t.check(rules.can_recast(0) and is_equal_approx(float(rules.follow_up_area(0).get("r", 0.0)), fx.radius), "once the bars stand the slot takes a click")
	t.check(rules.recast(0, C + Vector2(8.0, 0.0)) and called.size() == 1 and casts.size() == 1 and is_equal_approx(rules.cooldown_left(0), left)
		and fx.dragged, "the recast is true, with no second cast_made and the cooldown untouched")
	t.check(not rules.recast(0, C + Vector2(8.0, 0.0)) and not rules.can_recast(0) and called.size() == 1, "a second recast is false")
	CG._run_to(fx, fx.t + 2.1)
	t.check(fx._c.distance_to(C + Vector2(6.0, 0.0)) < 0.001, "and the cage went 6.0 toward it")
	fx.end_now()
	fx.free()
	rules.free()
	# Level 4 through Rules: no recast.
	var r4 := Rules.new().setup(PackedStringArray(["cage", "doom"]), ctx, made[1], made[3], crowd, crowd._town)
	r4.levels = {"cage": 4}
	var f4 := r4.cast(0, C) as CageFx
	f4._process(1.0)
	t.check(f4 != null and not r4.can_recast(0) and not r4.recast(0, C + Vector2(8.0, 0.0)), "level 4 through Rules: no recast")
	f4.end_now()
	f4.free()
	r4.free()
	CG._done(made)


## end_now() and a freed node lift the law and leave the drag undone; a level 5 cast holds one before it (positive control).
static func _teardown(t) -> void:
	var made := CG._setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	_arena(made)
	var people: Array = crowd.citizens + crowd.soldiers
	var p: Person = people[0]
	p.ground_pos = C + Vector2(2.0, 0.0)
	var fx := _cast(ctx, 5)
	CG._run_to(fx, CageFx.T_LAND + 0.05)
	var law := fx.law
	fx.follow_up(C + Vector2(10.0, 0.0), {})
	CG._run_to(fx, fx.t + 0.5)
	t.check(crowd.laws.has(law) and law.alive() and fx._drag_on and law.members.has(p), "mid-drag the law holds, the person is held (positive control)")
	fx.end_now()
	var at := p.ground_pos
	fx._process(0.5)
	t.check(not crowd.laws.has(law) and not law.alive() and not fx._drag_on and fx.finished and p.ground_pos == at,
		"end_now(): the law is lifted, the drag is over, nobody is carried on")
	fx.free()
	t.check(not is_instance_valid(fx), "and the node is freed")
	var fx2 := _cast(ctx, 5)
	CG._run_to(fx2, CageFx.T_LAND + 0.05)
	var law2 := fx2.law
	fx2.follow_up(C + Vector2(10.0, 0.0), {})
	CG._run_to(fx2, fx2.t + 0.3)
	t.check(crowd.laws.has(law2) and law2.alive(), "a second cast mid-drag holds its law (positive control)")
	fx2.free()
	crowd.step_laws(0.1)
	t.check(not is_instance_valid(fx2) and not crowd.laws.has(law2) and not law2.alive(), "freed without end_now(): its law is gone with it")
	CG._done(made)


## Two level 5 casts: dragging one moves nothing of the other, and one ending leaves the other's law standing.
static func _two_casts(t) -> void:
	var made := CG._setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	_arena(made)
	var c2 := Vector2(-20.0, 20.0)
	var a := _cast(ctx, 5)
	var b := _cast(ctx, 5, c2)
	CG._run_to(a, CageFx.T_LAND + 0.05)
	CG._run_to(b, CageFx.T_LAND + 0.05)
	a.follow_up(C + Vector2(10.0, 0.0), {})
	CG._run_to(a, a.t + 2.1)
	CG._run_to(b, b.t + 2.1)
	t.check(a._c.distance_to(C + Vector2(6.0, 0.0)) < 0.001 and b._c == c2 and b.law.a == c2 and b.can_follow_up() and not b.dragged,
		"dragging one cage leaves the other's centre, law and drag alone")
	a.end_now()
	t.check(not crowd.laws.has(a.law) and crowd.laws.has(b.law) and b.law.alive(), "the first ending leaves the second's law standing")
	b.end_now()
	a.free()
	b.free()
	CG._done(made)
