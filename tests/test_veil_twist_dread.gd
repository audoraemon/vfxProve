extends RefCounted
## Dread of the Dark's level-5 twist (Veil ability levels, C1 The Dark Looks Back): from the fall to the lift, who stops at the edge of
## the dreaded ground (a step it refused him, or 2.0 s within 1.0 of it) is held there, eyed open-ended, 16 a cast at most, nearest the
## click first; the lift (or an early end, or a freed cast) lets every one of them go and closes the eyes. Level 4 has none of it.

const RD := preload("res://tests/test_raise_dead.gd")
const DD := preload("res://tests/test_veil_dread.gd")
const L5 := {"level": 5}
const L4 := {"level": 4}
const DT := 0.05


static func run(t) -> void:
	var made := RD._setup()
	_balked(t, made)
	_stand(t, made)
	_most(t, made)
	_rf1_two_dreads(t, made)
	_rf2_end_now_frozen(t, made)
	_rf3_held(t, made)
	_spared(t, made)
	_level_four(t, made)
	RD._done(made)
	_bare(t)


## A fresh town, no eye, a dusk patch D (radius 1.5) 4 from the click: returns [click, D].
static func _begin(made: Array) -> Array:
	var crowd: Crowd = made[0]
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	var at := DD._fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 600.0)
	return [at, d]


static func _cast(made: Array, at: Vector2, extra := L5) -> DreadOfTheDarkFx:
	return DD._cast(made[5], at, extra)


## Where a man stands `gap` outside D's rim, due south of it.
static func _rim(d: Vector2, gap: float) -> Vector2:
	return d + Vector2(0.0, 1.5 + gap)


## DD._put(), and his last refused step forgotten (the test crowd's clock stands still).
static func _pp(crowd: Crowd, n: int, at: Vector2) -> Person:
	var p := DD._put(crowd, n, at)
	p.dread_balked_at = -INF
	p.statuses.erase(&"shadow")
	return p


static func _held_by_edge(fx: DreadOfTheDarkFx, p: Person) -> bool:
	return fx._edge_ids.has(p.get_instance_id()) and p.is_dreaded()


static func _both(a: FxTimeline, b: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		for fx in [a, b]:
			if fx != null and is_instance_valid(fx) and not fx.finished:
				fx._process(DT)


static func _balked(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var w := _pp(crowd, 20, d + Vector2(0.0, 3.5))
	var goal := d + Vector2(0.0, -3.5)
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	w.set_goal(goal)
	DD._go(fx, 5.0, [w], d)
	var eye := PaleEye.of(crowd)
	t.check(_held_by_edge(fx, w) and w.ground_pos.distance_to(d) > 1.5 - 0.01 and fx._ids.is_empty(),
		"balked: a walker with a goal across stops at the edge and is held there by the edge, not by the ground (%.2f)" % w.ground_pos.distance_to(d))
	t.check(eye != null and eye.is_eyed(w) and eye.record.size() == 1 and eye.record[0]["key"] == "dread" and eye.held_by(fx.get_instance_id()) == 1,
		"balked: eyed, the record's key is dread")
	var from := w.ground_pos
	DD._go(fx, 5.0, [w], d)
	t.check(w.ground_pos.distance_to(from) < 0.001 and eye.is_eyed(w), "held: he does not move and the eye stays open (open-ended)")
	fx.end_now()
	t.check(not w.is_dreaded() and not w.has_meta(DreadOfTheDarkFx.OWNERS) and not eye.is_eyed(w) and eye.held_by(fx.get_instance_id()) == 0,
		"the lift: free, unmarked, the eye closed")
	fx.free()


static func _stand(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var near := _pp(crowd, 20, _rim(d, 0.8))
	var far := _pp(crowd, 21, _rim(d, 1.2))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx, 1.6)
	t.check(not near.is_dreaded(), "standing 0.8 from the edge for under 2 s (1.9): not held")
	DD._go(fx, 0.5)
	t.check(_held_by_edge(fx, near), "... and 2.1 s: held")
	DD._go(fx, 6.0)
	t.check(not far.is_dreaded() and not PaleEye.of(crowd).is_eyed(far), "at 1.2 from the edge: never held, never eyed")
	fx.end_now()
	fx.free()
	# The timer resets when he steps away.
	var pt2 := _begin(made)
	var p := _pp(crowd, 22, _rim(pt2[1], 0.8))
	var fx2 := _cast(made, pt2[0])
	DD._go(fx2, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx2, 1.5)
	p.ground_pos = _rim(pt2[1], 1.5)
	DD._go(fx2, 0.5)
	p.ground_pos = _rim(pt2[1], 0.8)
	DD._go(fx2, 1.5)
	t.check(not p.is_dreaded(), "his stand starts over when he is away from the edge")
	DD._go(fx2, 0.8)
	t.check(p.is_dreaded(), "... and holds him 2 s after he is back")
	fx2.end_now()
	fx2.free()


static func _most(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var people: Array[Person] = []
	for i in 20:
		people.append(_pp(crowd, 20 + i, d + Vector2(2.3, 0.0).rotated(deg_to_rad(7.0 + 18.0 * float(i)))))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx, 3.0)
	var order := people.duplicate()
	order.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		return a.get_instance_id() < b.get_instance_id() if is_equal_approx(da, db) else da < db)
	var held := 0
	var nearest_ok := true
	for i in order.size():
		if (order[i] as Person).is_dreaded():
			held += 1
		if (i < 16) != (order[i] as Person).is_dreaded():
			nearest_ok = false
	t.check(held == 16 and fx._edge_ids.size() == 16, "20 candidates: 16 held (%d)" % held)
	t.check(nearest_ok, "... the 16 nearest the click")
	fx.end_now()
	var left := 0
	for p in people:
		if p.is_dreaded() or p.has_meta(DreadOfTheDarkFx.OWNERS):
			left += 1
	t.check(left == 0 and PaleEye.of(crowd).eyed().is_empty(), "at the lift every edge-held man is free and unmarked")
	fx.free()


static func _rf1_two_dreads(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var m := _pp(crowd, 20, _rim(d, 0.8))
	var a := _cast(made, at)
	DD._go(a, 10.0)
	var b := _cast(made, at)
	_both(a, b, 4.0)
	var owners: Dictionary = m.get_meta(DreadOfTheDarkFx.OWNERS, {})
	t.check(m.is_dreaded() and owners.size() == 2 and a._edge_ids.has(m.get_instance_id()) and b._edge_ids.has(m.get_instance_id()),
		"two dreads: one man held at the edge by both casts, per cast id")
	var eye := PaleEye.of(crowd)
	t.check(eye.held_by(a.get_instance_id()) == 1 and eye.held_by(b.get_instance_id()) == 1, "... and eyed by each")
	_both(a, b, 22.5)  # A is at 36.5 s: its dread lifted at 35.8; B (cast 10 s later) is at 26.5
	t.check(a.finished or a._lifted, "(A has lifted)")
	t.check(m.is_dreaded() and not a._edge_ids.has(m.get_instance_id()) and eye.held_by(a.get_instance_id()) == 0 and eye.held_by(b.get_instance_id()) == 1,
		"A lifts: still held (by B), A's eye closed, B's open")
	b.end_now()
	t.check(not m.is_dreaded() and not m.has_meta(DreadOfTheDarkFx.OWNERS) and eye.held_by(b.get_instance_id()) == 0, "B lifts: free")
	a.free()
	b.free()


static func _rf2_end_now_frozen(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var three: Array[Person] = []
	for i in 3:
		three.append(_pp(crowd, 20 + i, _rim(d, 0.8) + Vector2(0.4 * float(i), 0.0)))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT + 3.0)
	t.check(three.all(func(p: Person) -> bool: return p.is_dreaded()) and fx._edge_ids.size() == 3, "(three men held at the edge)")
	fx.end_now()
	var eye := PaleEye.of(crowd)
	t.check(three.all(func(p: Person) -> bool: return not p.is_dreaded() and not p.has_meta(DreadOfTheDarkFx.OWNERS)) and crowd.dreads.is_empty(),
		"end_now(): all free, the dread gone")
	t.check(eye.eyed().is_empty() and eye.held_by(fx.get_instance_id()) == 0 and not crowd.in_dark(at), "no eye open, no dusk laid at the click")
	fx.free()
	# Freed without finishing (off the tree).
	var pt2 := _begin(made)
	var q := _pp(crowd, 23, _rim(pt2[1], 0.8))
	var fx2 := _cast(made, pt2[0])
	DD._go(fx2, DreadOfTheDarkFx.T_FALL + DT + 3.0)
	var id := fx2.get_instance_id()
	t.check(q.is_dreaded(), "(held)")
	fx2.free()
	t.check(not q.is_dreaded() and not q.has_meta(DreadOfTheDarkFx.OWNERS) and PaleEye.of(crowd).held_by(id) == 0 and crowd.dreads.is_empty(),
		"freed off the tree: the hold lifted, the eye closed, the dread ended")


static func _rf3_held(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var shadow := _pp(crowd, 20, _rim(d, 0.8) + Vector2(-0.6, 0.0))
	shadow.statuses[&"shadow"] = 424242
	var sleeper := _pp(crowd, 21, _rim(d, 0.8) + Vector2(0.6, 0.0))
	sleeper.sleep(200.0, true)
	var control := _pp(crowd, 22, _rim(d, 0.8))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT + 4.0)
	t.check(_held_by_edge(fx, control), "(the control at the edge is held)")
	t.check(not shadow.is_dreaded() and not sleeper.is_dreaded() and not sleeper.has_meta(DreadOfTheDarkFx.OWNERS) and fx._edge_ids.size() == 1,
		"a shadow and a sleeper at the edge: never held")
	fx.end_now()
	fx.free()
	shadow.statuses.erase(&"shadow")
	sleeper.wake()


## The spared at the edge (a believer, a man the mission keeps alive) are eyed (timed, not open-ended), never frozen, and use up none of
## the 16.
static func _spared(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var believer := _pp(crowd, 20, _rim(d, 0.8) + Vector2(-0.6, 0.0))
	var faith := believer.profile.faith
	believer.profile.faith = CitizenProfile.Faith.BELIEVER
	var kept := _pp(crowd, 21, _rim(d, 0.8) + Vector2(0.6, 0.0))
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == kept)
	var control := _pp(crowd, 22, _rim(d, 0.8))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT + 4.0)
	var eye := PaleEye.of(crowd)
	t.check(_held_by_edge(fx, control) and fx._edge_ids.size() == 1, "(the control at the edge is held, the only one counted)")
	t.check(not believer.is_dreaded() and not kept.is_dreaded() and not believer.has_meta(DreadOfTheDarkFx.OWNERS) and not kept.has_meta(DreadOfTheDarkFx.OWNERS),
		"a believer and a mission-kept man at the edge: never frozen")
	t.check(eye != null and eye.is_eyed(believer) and eye.is_eyed(kept) and eye.record.size() == 3,
		"... but eyed, once each (%d records)" % (eye.record.size() if eye != null else -1))
	fx.end_now()
	t.check(eye.is_eyed(believer) and eye.is_eyed(kept) and not eye.is_eyed(control),
		"the lift closes the held man's open eye; the spared's timed eyes run on")
	eye.step(PaleEye.TIME + 0.1)
	t.check(not eye.is_eyed(believer) and not eye.is_eyed(kept), "... and run out")
	fx.free()
	believer.profile.faith = faith
	crowd.mission_keeps.clear()


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var w := _pp(crowd, 20, _rim(d, 0.8))
	var fx := _cast(made, at, L4)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT + 6.0)
	t.check(not w.is_dreaded() and fx._edge_ids.is_empty() and PaleEye.of(crowd) == null, "level 4: its edge holds nobody, no eye")
	fx.end_now()
	fx.free()


static func _bare(t) -> void:
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var fx := FxTimeline.cast(DreadOfTheDarkFx, bare, Vector2.ZERO, L5) as DreadOfTheDarkFx
	fx._process(1.0)
	fx.end_now()
	t.check(fx.finished and fx._edge_ids.is_empty(), "bare (no crowd, no field): builds and finishes")
	fx.free()
	bare.overhead.free()
	bare.ground.free()
