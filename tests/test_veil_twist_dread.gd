extends RefCounted
## Dread of the Dark's level-5 twist (The Dark Takes Who Looks): from the fall to the lift, who stops at the edge of the dreaded ground
## (a step it refused him, or 2.0 s within 1.0 of it) is eyed, held, slid PULL_DRIFT toward the click over PULL while he fades, and then
## taken (no body); 16 a cast at most, nearest the click first. The spared are eyed and never taken. An early end lets the ones in the
## pull go and closes the eyes. Level 4 has none of it.

const RD := preload("res://tests/test_raise_dead.gd")
const DD := preload("res://tests/test_veil_dread.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const L5 := {"level": 5}
const L4 := {"level": 4}
const DT := 0.05


static func run(t) -> void:
	# Each case builds its own town: a taken citizen is gone for good, and the next case wants him again.
	for each: Callable in [_edge_stopper_taken, _stander_taken, _cap_16, _two_dreads, _spared_eyed_never_taken, _held_soldier_taken,
			_pull_drifts_and_fades, _teardown_mid_pull, _shadow_sleeper_passed_over, _level4_no_twist]:
		var made := RD._setup()
		each.call(t, made)
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
	p.modulate.a = 1.0
	return p


static func _taken(fx: DreadOfTheDarkFx, p: Person) -> bool:
	return not p.is_alive() and fx.taken_at_edge.has(p.get_instance_id())


## Whether any body was laid within 3 of `g` (the ledger is on).
static func _body_near(crowd: Crowd, g: Vector2) -> bool:
	return not crowd.remains.near(g, 3.0).is_empty()


static func _both(a: FxTimeline, b: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		for fx in [a, b]:
			if fx != null and is_instance_valid(fx) and not fx.finished:
				fx._process(DT)


## Steps the cast until `p`'s pull has begun (at most `limit` s).
static func _until_pull(fx: DreadOfTheDarkFx, p: Person, limit := 6.0) -> bool:
	var spent := 0.0
	while not fx._pulls.has(p.get_instance_id()) and spent < limit:
		DD._go(fx, DT)
		spent += DT
	return fx._pulls.has(p.get_instance_id())


static func _edge_stopper_taken(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var w := _pp(crowd, 20, d + Vector2(0.0, 3.5))
	var goal := d + Vector2(0.0, -3.5)
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	w.set_goal(goal)
	var spent := 0.0
	while w.dread_balked_at < fx._fall_clock and spent < 8.0:
		DD._go(fx, DT, [w], d)
		spent += DT
	t.check(w.dread_balked_at >= fx._fall_clock and w.is_alive(), "stopper: the edge stopped him (%.2f s)" % spent)
	var spot := w.ground_pos
	DD._go(fx, DreadOfTheDarkFx.PULL + DreadOfTheDarkFx.TICK + 0.1)
	var eye := PaleEye.of(crowd)
	t.check(_taken(fx, w) and fx.taken_at_edge.size() == 1, "stopper: taken within PULL + TICK + 0.1 of the stop, his id kept")
	t.check(not _body_near(crowd, spot), "... no body laid")
	var keyed := false
	if eye != null:
		for r in eye.record:
			keyed = keyed or r["key"] == "dread"
	t.check(keyed, "... and he was eyed (record key dread)")
	fx.end_now()
	fx.free()


static func _stander_taken(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var near := _pp(crowd, 20, _rim(d, 0.8))
	var far := _pp(crowd, 21, _rim(d, 1.2))
	var fx := _cast(made, pt[0])
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx, DreadOfTheDarkFx.EDGE_STAND - 0.4)
	t.check(near.is_alive(), "stander: 1.6 s at 0.8 from the edge: still here")
	DD._go(fx, 0.4 + DreadOfTheDarkFx.TICK + DreadOfTheDarkFx.PULL + 0.2)
	t.check(_taken(fx, near) and not _body_near(crowd, near.ground_pos), "stander: EDGE_STAND at 0.8 from the edge: taken, no body")
	DD._go(fx, 4.0)
	t.check(far.is_alive() and not far.is_dreaded() and not PaleEye.of(crowd).is_eyed(far), "at 1.2 from the edge: never eyed, never taken")
	fx.end_now()
	fx.free()


static func _cap_16(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var people: Array[Person] = []
	for i in 20:
		people.append(_pp(crowd, 20 + i, d + Vector2(2.3, 0.0).rotated(deg_to_rad(7.0 + 18.0 * float(i)))))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx, 9.0)
	var order := people.duplicate()
	order.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		return a.get_instance_id() < b.get_instance_id() if is_equal_approx(da, db) else da < db)
	var gone := 0
	var nearest_ok := true
	var rest_free := true
	for i in order.size():
		var p := order[i] as Person
		if not p.is_alive():
			gone += 1
		elif p.is_dreaded() or p.has_meta(DreadOfTheDarkFx.OWNERS):
			rest_free = false
		if (i < 16) == p.is_alive():
			nearest_ok = false
	t.check(gone == 16 and fx.taken_at_edge.size() == 16, "20 candidates: exactly 16 taken (%d)" % gone)
	t.check(nearest_ok, "... the 16 nearest the click first")
	t.check(rest_free, "... the other 4 alive and not frozen by the twist")
	fx.end_now()
	t.check(PaleEye.of(crowd).eyed().is_empty(), "at the end no eye is open")
	fx.free()


## Two casts at one man: he is taken once, the other pull ends quietly.
static func _two_dreads(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var m := _pp(crowd, 20, _rim(d, 0.8))
	var a := _cast(made, pt[0])
	var b := _cast(made, pt[0])
	_both(a, b, DreadOfTheDarkFx.T_FALL + DT)
	_both(a, b, 4.0)
	t.check(not m.is_alive() and a.taken_at_edge.size() + b.taken_at_edge.size() == 1, "two dreads: one man, taken once")
	t.check(a._pulls.is_empty() and b._pulls.is_empty(), "... both pulls over, nothing breaks")
	a.end_now()
	b.end_now()
	t.check(crowd.dreads.is_empty(), "... and both dreads end")
	a.free()
	b.free()


static func _spared_eyed_never_taken(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var believer := _pp(crowd, 20, _rim(d, 0.8) + Vector2(-0.6, 0.0))
	var faith := believer.profile.faith
	believer.profile.faith = CitizenProfile.Faith.BELIEVER
	var kept := _pp(crowd, 21, _rim(d, 0.8) + Vector2(0.6, 0.0))
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == kept)
	var control := _pp(crowd, 22, _rim(d, 0.8))
	var fx := _cast(made, pt[0])
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx, DreadOfTheDarkFx.EDGE_STAND + DreadOfTheDarkFx.PULL + 1.0)
	var eye := PaleEye.of(crowd)
	t.check(_taken(fx, control) and fx.taken_at_edge.size() == 1, "(the control at the edge is taken, the only one)")
	t.check(believer.is_alive() and kept.is_alive() and not believer.is_dreaded() and not kept.is_dreaded() and believer.modulate.a == 1.0,
		"a believer and a mission-kept man at the edge: alive after the stand and the pull, never frozen or faded")
	var eyed := 0
	if eye != null:
		for r in eye.record:
			eyed += 1
	t.check(eye != null and eyed >= 3, "... but eyed (%d records)" % eyed)
	fx.end_now()
	fx.free()
	believer.profile.faith = faith
	crowd.mission_keeps.clear()


static func _held_soldier_taken(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var s: Person = crowd.soldiers[1]
	Kit.arrive(s, _rim(d, 0.8))
	s.dread_balked_at = -INF
	s.send_to_post(s.ground_pos)
	var fx := _cast(made, pt[0])
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	DD._go(fx, DreadOfTheDarkFx.EDGE_STAND + DreadOfTheDarkFx.TICK + DreadOfTheDarkFx.PULL + 0.4, [s], d)
	t.check(_taken(fx, s), "a soldier on a duty at the edge is taken like anyone")
	fx.end_now()
	fx.free()


static func _pull_drifts_and_fades(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var at: Vector2 = pt[0]
	var d: Vector2 = pt[1]
	var w := _pp(crowd, 20, _rim(d, 0.8))
	var fx := _cast(made, at)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(_until_pull(fx, w), "(the pull begins)")
	var d0 := w.ground_pos.distance_to(at)
	DD._go(fx, DreadOfTheDarkFx.PULL * 0.5)
	var gain := d0 - w.ground_pos.distance_to(at)
	t.check(absf(gain - DreadOfTheDarkFx.PULL_DRIFT * 0.5) <= 0.15, "halfway: nearer the click by about half the drift (%.2f)" % gain)
	t.check(w.modulate.a < 1.0 and w.modulate.a > 0.0, "... and fading (alpha %.2f)" % w.modulate.a)
	fx.end_now()
	fx.free()
	w.modulate.a = 1.0


static func _teardown_mid_pull(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var w := _pp(crowd, 20, _rim(d, 0.8))
	var fx := _cast(made, pt[0])
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(_until_pull(fx, w), "(the pull begins)")
	DD._go(fx, 0.2)
	var id := fx.get_instance_id()
	fx.end_now()
	DD._go(null, 1.0, [w])
	var eye := PaleEye.of(crowd)
	t.check(w.is_alive() and not w.is_dreaded() and not w.has_meta(DreadOfTheDarkFx.OWNERS) and w.modulate.a == 1.0 and fx.taken_at_edge.is_empty(),
		"end_now() mid-pull: alive, let go, opaque, nothing taken")
	t.check(eye.held_by(id) == 0 and eye.eyed().is_empty(), "... no eye open for the cast")
	fx.free()


static func _shadow_sleeper_passed_over(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var shadow := _pp(crowd, 20, _rim(d, 0.8) + Vector2(-0.6, 0.0))
	shadow.statuses[&"shadow"] = 424242
	var sleeper := _pp(crowd, 21, _rim(d, 0.8) + Vector2(0.6, 0.0))
	sleeper.sleep(200.0, true)
	var fx := _cast(made, pt[0])
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT + 5.0)
	t.check(shadow.is_alive() and sleeper.is_alive() and fx.taken_at_edge.is_empty(), "a shadow and a sleeper at the edge: never taken")
	fx.end_now()
	fx.free()
	shadow.statuses.erase(&"shadow")
	sleeper.wake()


static func _level4_no_twist(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var pt := _begin(made)
	var d: Vector2 = pt[1]
	var w := _pp(crowd, 20, _rim(d, 0.8))
	var fx := _cast(made, pt[0], L4)
	DD._go(fx, DreadOfTheDarkFx.T_FALL + DT + 6.0)
	t.check(w.is_alive() and not w.is_dreaded() and fx.taken_at_edge.is_empty() and PaleEye.of(crowd) == null,
		"level 4: a man at the edge waits, never taken, no eye")
	fx.end_now()
	fx.free()


static func _bare(t) -> void:
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var fx := FxTimeline.cast(DreadOfTheDarkFx, bare, Vector2.ZERO, L5) as DreadOfTheDarkFx
	fx._process(1.0)
	fx.end_now()
	t.check(fx.finished and fx._edge_ids.is_empty() and fx.taken_at_edge.is_empty(), "bare (no crowd, no field): builds and finishes")
	fx.free()
	bare.overhead.free()
	bare.ground.free()
