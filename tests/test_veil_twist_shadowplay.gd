extends RefCounted
## Shadow Play's level-5 twist (Veil ability levels, C2 The Shadows Keep Watch): from the rise to the end, anyone alive, out of doors and
## not held by another Veil power who comes within 1.0 of a shadow this cast owns becomes a shadow too (12 a cast at most, nearest the
## shadow first), eyed; the end treats them as the cast's own. Level 4 has none of it.

const SP := preload("res://tests/test_veil_shadowplay.gd")
const L5 := {"level": 5}
const R := 3.3  # the light radius at level 5
const RD_DARK := 7.2


static func run(t) -> void:
	var made := SP._setup()
	_joins(t, made)
	_end_light(t, made)
	_end_dark(t, made)
	_most(t, made)
	_rf3_held(t, made)
	_two_casts(t, made)
	_teardown(t, made)
	_level_four(t, made)
	SP._done(made)
	_bare(t)


static func _begin(made: Array, keep: Array) -> Vector2:
	var crowd: Crowd = made[0]
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	crowd.dusk.clear()
	SP._away(crowd, keep)
	for p: Person in keep:
		p.statuses.erase(&"shadow")
		p.statuses.erase(&"dread")
		if p.is_asleep():
			p.wake()
	return (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())


static func _cast(made: Array, at: Vector2, dark := false, level := 5) -> ShadowPlayFx:
	return FxTimeline.cast(ShadowPlayFx, made[5], at, {"level": level, "dark": dark}) as ShadowPlayFx


## The cast to its rise and a few polls past it.
static func _rise(fx: ShadowPlayFx) -> void:
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	for i in 8:
		fx._process(0.05)


static func _put(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.mind = Person.Mind.CALM


static func _joins(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var c: Array = crowd.citizens
	var s0: Person = c[0]
	var w: Person = c[1]
	var w2: Person = c[2]
	var at := _begin(made, [s0, w, w2])
	_put(s0, at + Vector2(3.25, 0.0))
	_put(w, at + Vector2(4.15, 0.0))
	_put(w2, at + Vector2(3.25, 1.1))
	var fx := _cast(made, at)
	_rise(fx)
	var eye := PaleEye.of(crowd)
	t.check(s0.is_shadow() and w.is_shadow() and w.statuses[&"shadow"] == fx.get_instance_id() and fx.joined == 1,
		"a walker at 0.9 from a shadow becomes a shadow of this cast (joined %d)" % fx.joined)
	t.check(not w2.is_shadow(), "at 1.1: not")
	t.check(eye != null and eye.is_eyed(w) and not eye.is_eyed(w2) and eye.held_by(fx.get_instance_id()) == 1 and eye.record[0]["key"] == "shadowplay",
		"the joined is eyed, the record's key is shadowplay")
	t.check(w.self_modulate == VeilParts.BLACK, "black, as _rise() makes one")
	fx.end_now()
	fx.free()


static func _end_light(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var c: Array = crowd.citizens
	var s0: Person = c[0]
	var w: Person = c[1]
	var at := _begin(made, [s0, w])
	_put(s0, at + Vector2(3.25, 0.0))
	_put(w, at + Vector2(4.15, 0.0))
	var fx := _cast(made, at)
	_rise(fx)
	t.check(w.is_shadow(), "(joined)")
	fx._process(ShadowPlayFx.SPAN + 40.0)
	t.check(fx.finished and fx.lain == 2 and fx.taken == 0 and not w.is_shadow() and not s0.is_shadow() and w.self_modulate == Color.WHITE,
		"at the end in the light he lies down and wakes: lain counts him (%d)" % fx.lain)
	t.check(PaleEye.of(crowd).eyed().is_empty(), "his eye is closed")
	fx.free()


static func _end_dark(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var s0: Person = crowd.citizens[0]
	var cit: Person = crowd.citizens[1]
	var sol: Person = crowd.soldiers[0]
	var at := _begin(made, [s0, cit, sol])
	_put(s0, at + Vector2(7.1, 0.0))
	_put(sol, at + Vector2(8.0, 0.0))
	_put(cit, at + Vector2(7.74, 0.64))
	var fx := _cast(made, at, true)
	_rise(fx)
	t.check(sol.is_shadow() and cit.is_shadow() and fx.joined == 2, "dark: the soldier and the citizen joined (%d)" % fx.joined)
	fx._process(ShadowPlayFx.SPAN + 40.0)
	t.check(fx.taken == 1 and fx.lain == 2 and not cit.is_shadow() and cit.is_alive(),
		"in the dark a joined soldier is taken (taken %d), a joined citizen wakes (lain %d)" % [fx.taken, fx.lain])
	fx.free()
	crowd.dusk.clear()


static func _most(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var keep: Array = []
	for i in 16:
		keep.append(crowd.citizens[i])
	var at := _begin(made, keep)
	var s0: Person = keep[0]
	_put(s0, at + Vector2(3.25, 0.0))
	for i in 15:
		var a := deg_to_rad(-70.0 + 10.0 * float(i))
		_put(keep[i + 1], s0.ground_pos + Vector2(0.9, 0.0).rotated(a))
	var fx := _cast(made, at)
	_rise(fx)
	var n := 0
	var first_twelve := true
	var ids: Array = []
	for i in 15:
		ids.append((keep[i + 1] as Person).get_instance_id())
	ids.sort()
	for i in 15:
		var p: Person = keep[i + 1]
		if p.is_shadow():
			n += 1
		if p.is_shadow() != (ids.find(p.get_instance_id()) < 12):
			first_twelve = false
	t.check(n == 12 and fx.joined == 12, "15 walkers: 12 join (%d)" % n)
	t.check(first_twelve, "... the 12 lowest ids (all at one distance)")
	fx.end_now()
	fx.free()


static func _rf3_held(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var c: Array = crowd.citizens
	var s0: Person = c[0]
	var sleeper: Person = c[1]
	var dreaded: Person = c[2]
	var other: Person = c[3]
	var control: Person = c[4]
	var at := _begin(made, [s0, sleeper, dreaded, other, control])
	_put(s0, at + Vector2(3.25, 0.0))
	_put(sleeper, at + Vector2(3.8, 0.0))
	sleeper.sleep(200.0, true)
	_put(dreaded, at + Vector2(3.9, -0.4))
	dreaded.statuses[&"dread"] = 50.0
	_put(other, at + Vector2(3.8, 0.5))
	other.statuses[&"shadow"] = 777777
	_put(control, at + Vector2(4.15, 0.0))
	var fx := _cast(made, at)
	_rise(fx)
	t.check(control.is_shadow() and fx.joined == 1, "(the control joined)")
	t.check(not sleeper.is_shadow() and not dreaded.is_shadow() and int(other.statuses[&"shadow"]) == 777777,
		"a Slumber sleeper and a dreaded man near a shadow: not joined; another cast's shadow: not taken over")
	fx.end_now()
	fx.free()
	other.statuses.erase(&"shadow")
	dreaded.statuses.erase(&"dread")
	sleeper.wake()


static func _two_casts(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var c: Array = crowd.citizens
	var sa: Person = c[0]
	var wa: Person = c[1]
	var sb: Person = c[2]
	var wb: Person = c[3]
	var at := _begin(made, [sa, wa, sb, wb])
	var at_b := at + Vector2(-14.0, 0.0)
	_put(sa, at + Vector2(3.25, 0.0))
	_put(wa, at + Vector2(4.15, 0.0))
	_put(sb, at_b + Vector2(3.25, 0.0))
	_put(wb, at_b + Vector2(4.15, 0.0))
	var a := _cast(made, at)
	var b := _cast(made, at_b)
	_rise(a)
	_rise(b)
	t.check(wa.statuses[&"shadow"] == a.get_instance_id() and wb.statuses[&"shadow"] == b.get_instance_id() and a.joined == 1 and b.joined == 1,
		"two level-5 casts: each joined its own")
	a.end_now()
	t.check(not wa.is_shadow() and wb.is_shadow() and wb.statuses[&"shadow"] == b.get_instance_id() and a.lain == 0 and b.lain == 0,
		"A ends: only A's go (B's joined is still B's shadow)")
	b._process(ShadowPlayFx.SPAN + 40.0)
	t.check(not wb.is_shadow() and b.lain == 2 and a.lain == 0, "B's end treats only B's (lain %d)" % b.lain)
	a.free()
	b.free()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var c: Array = crowd.citizens
	var s0: Person = c[0]
	var w: Person = c[1]
	var at := _begin(made, [s0, w])
	_put(s0, at + Vector2(3.25, 0.0))
	_put(w, at + Vector2(4.15, 0.0))
	var fx := _cast(made, at)
	_rise(fx)
	var id := fx.get_instance_id()
	var eye := PaleEye.of(crowd)
	t.check(w.is_shadow() and eye.held_by(id) == 1, "(joined and eyed)")
	var kills := crowd.soldiers.filter(func(p: Person) -> bool: return not p.is_alive()).size()
	fx.end_now()
	t.check(not w.is_shadow() and not s0.is_shadow() and eye.held_by(id) == 0 and fx.edges() == 0 and fx.taken == 0 and fx.lain == 0,
		"end_now(): the joined let go, nobody taken, nobody laid down, no eye, edges() == 0")
	t.check(crowd.soldiers.filter(func(p: Person) -> bool: return not p.is_alive()).size() == kills, "(nobody died)")
	fx.free()
	# Freed off the tree without finishing.
	var at2 := _begin(made, [s0, w])
	_put(s0, at2 + Vector2(3.25, 0.0))
	_put(w, at2 + Vector2(4.15, 0.0))
	var fx2 := _cast(made, at2)
	_rise(fx2)
	var id2 := fx2.get_instance_id()
	t.check(w.is_shadow(), "(joined again)")
	fx2.free()
	t.check(not w.is_shadow() and not s0.is_shadow() and PaleEye.of(crowd).held_by(id2) == 0 and w.self_modulate == Color.WHITE,
		"freed off the tree: the joined let go, the eyes closed")


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var s0: Person = crowd.citizens[0]
	var w: Person = crowd.citizens[1]
	var at := _begin(made, [s0, w])
	_put(s0, at + Vector2(3.25, 0.0))
	_put(w, at + Vector2(4.15, 0.0))
	var fx := _cast(made, at, false, 4)
	_rise(fx)
	t.check(s0.is_shadow() and not w.is_shadow() and fx.joined == 0 and PaleEye.of(crowd) == null, "level 4: nobody joins, no eye")
	fx.end_now()
	fx.free()


static func _bare(t) -> void:
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var fx := FxTimeline.cast(ShadowPlayFx, bare, Vector2.ZERO, L5) as ShadowPlayFx
	fx._process(ShadowPlayFx.T_RISE + 0.05)
	fx._process(ShadowPlayFx.SPAN + 40.0)
	t.check(fx.finished and fx.joined == 0, "bare (no crowd, no field): builds and finishes")
	fx.free()
	bare.overhead.free()
	bare.ground.free()
