extends RefCounted
## Slumber's level-5 twist, Heavy Air (Veil ability levels, B1): the cast lasts to T_FALL + the sleep and its ring stays drawn; whoever
## walks into the circle after the fall sleeps the rest of it and is eyed (not those in it at the fall, not a man another power holds,
## nobody twice); a level-4 cast does none of it.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const FxStage := preload("res://tests/fx_stage.gd")
const DT := 0.05


static func _cast(ctx: FxContext, at: Vector2, dark := false, level := 5) -> SlumberFx:
	return FxTimeline.cast(load("res://src/fx/veil/slumber.gd"), ctx, at, {"dark": dark, "level": level}) as SlumberFx


## Runs the cast to clock `to` in steps of DT.
static func _until(fx: SlumberFx, to: float) -> void:
	while fx.t < to - 0.0001 and not fx.finished:
		fx._process(DT)


## A clean town (EV._fresh) with no Pale Eye left from an earlier case.
static func _fresh(made: Array) -> Vector2:
	var at := EV._fresh(made)
	var crowd: Crowd = made[0]
	if PaleEye.of(crowd) != null:
		PaleEye.of(crowd).free()
	crowd.pale_eye = null
	return at


static func _eyed(crowd: Crowd, p: Person) -> bool:
	return PaleEye.of(crowd) != null and PaleEye.of(crowd).is_eyed(p)


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_walker(t, made)
	_dark(t, made)
	_noted(t, made)
	_again(t, made)
	_rf3_held_walker(t, made)
	_rf1_two_circles(t, made)
	_rf5_slumber_mixed(t, made)
	_level_four(t, made)
	_ended(t, made)
	_teardown(t, made)
	await _looks(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)
	_bare(t)


static func _walker(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var w := EV._put(crowd, at + Vector2(4.0, 0.0))
	var fx := _cast(ctx, at)
	t.check(is_equal_approx(fx.duration, SlumberFx.T_FALL + 28.0), "level 5: the cast lasts to T_FALL + the sleep (%.1f)" % fx.duration)
	_until(fx, 10.0)
	t.check(not w.is_asleep() and PaleEye.of(crowd) == null, "nobody walks in: nobody sleeps, no eye")
	w.ground_pos = at + Vector2(1.2, 0.0)
	_until(fx, 10.4)
	t.check(w.is_asleep() and not w.is_deep_asleep() and absf(w.sleep_left() - 18.6) < 0.7 and fx.caught == 1,
		"a walker entering at t 10 sleeps with about 18.6 s left, light (%.2f)" % w.sleep_left())
	var eye := PaleEye.of(crowd)
	t.check(eye != null and eye.is_eyed(w) and eye.record.size() == 1 and eye.record[0].key == "slumber"
		and eye.record[0].fx == fx.get_instance_id(), "he is eyed, the record's key is slumber")
	crowd.fright(w.ground_pos + Vector2(5.0, 0.0), 1.0, 0.5, 5.0, 3.0, 6.5, &"collapse")
	crowd.threats.clear()
	t.check(not w.is_asleep(), "light: a blow wakes him")
	# He may walk out and in again: caught once.
	w.ground_pos = at + Vector2(4.0, 0.0)
	_until(fx, fx.t + 0.5)
	w.ground_pos = at + Vector2(1.0, 0.0)
	_until(fx, fx.t + 0.6)
	t.check(not w.is_asleep() and fx.caught == 1, "a woken walker re-entering is not slept again")
	fx.end_now()
	fx.free()
	crowd.dusk.clear()


static func _dark(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var w := EV._put(crowd, at + Vector2(6.0, 0.0))
	var fx := _cast(ctx, at, true)
	_until(fx, 10.0)
	w.ground_pos = at + Vector2(4.2, 0.0)
	_until(fx, 10.4)
	t.check(w.is_deep_asleep() and _eyed(crowd, w), "dark (r 4.5): the same walker sleeps deep and is eyed")
	fx.end_now()
	fx.free()
	crowd.dusk.clear()


static func _noted(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var inside := _put_in(crowd, at + Vector2(0.5, 0.0))
	var fx := _cast(ctx, at)
	_until(fx, SlumberFx.T_FALL + 0.1)
	t.check(inside.is_asleep(), "controls: the one in the circle at the fall sleeps (the cast itself)")
	inside.wake()
	_until(fx, 5.0)
	t.check(not inside.is_asleep() and not _eyed(crowd, inside) and fx.caught == 0,
		"one in the circle at the fall, woken and standing in it: never slept by the twist, never eyed")
	fx.end_now()
	fx.free()
	crowd.dusk.clear()


static func _put_in(crowd: Crowd, at: Vector2) -> Person:
	return EV._put(crowd, at)


static func _again(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var w := EV._put(crowd, at + Vector2(4.0, 0.0))
	var fx := _cast(ctx, at)
	_until(fx, 3.0)
	w.ground_pos = at + Vector2(1.0, 0.0)
	_until(fx, 3.4)
	t.check(w.is_asleep(), "controls: he walked in and sleeps")
	w.wake()
	w.ground_pos = at + Vector2(4.0, 0.0)
	_until(fx, 4.0)
	w.ground_pos = at + Vector2(0.5, 0.0)
	_until(fx, 5.0)
	t.check(not w.is_asleep() and fx.caught == 1, "woken and back in the circle: not slept again")
	fx.end_now()
	fx.free()
	crowd.dusk.clear()


static func _rf3_held_walker(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var shade := EV._put(crowd, at + Vector2(5.0, 0.0))
	var dread := EV._put(crowd, at + Vector2(5.0, 1.0))
	var fx := _cast(ctx, at)
	_until(fx, 2.0)
	shade.statuses[&"shadow"] = 100.0
	dread.statuses[&"dread"] = 100.0
	shade.ground_pos = at + Vector2(0.5, 0.0)
	dread.ground_pos = at + Vector2(0.0, 0.5)
	_until(fx, 3.0)
	t.check(not shade.is_asleep() and not dread.is_asleep() and fx.caught == 0 and PaleEye.of(crowd) == null,
		"_rf3_held_walker: a shadow and a dreaded walking in are not slept, not eyed")
	fx.end_now()
	fx.free()
	shade.statuses.clear()
	dread.statuses.clear()
	crowd.dusk.clear()


static func _rf1_two_circles(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var other := at + Vector2(5.0, 0.0)
	var w := EV._put(crowd, at + Vector2(2.5, 3.0))
	var a := _cast(ctx, at)
	var b := _cast(ctx, other)
	_until(a, 3.0)
	_until(b, 3.0)
	w.ground_pos = at + Vector2(0.5, 0.0)
	_until(a, 3.4)
	_until(b, 3.4)
	var left := w.sleep_left()
	t.check(w.is_asleep() and a.caught == 1, "_rf1_two_circles: the first circle sleeps him")
	w.ground_pos = other + Vector2(0.5, 0.0)
	_until(a, 4.4)
	_until(b, 4.4)
	var recs := 0
	for r in PaleEye.of(crowd).record:
		if r.id == w.get_instance_id():
			recs += 1
	t.check(b.caught == 0 and recs == 1 and w.is_asleep() and is_equal_approx(w.sleep_left(), left) and PaleEye.of(crowd).record[0].fx == a.get_instance_id(),
		"walking into the second circle: still the first's sleep, not eyed again")
	a.end_now()
	b.end_now()
	a.free()
	b.free()
	crowd.dusk.clear()


static func _rf5_slumber_mixed(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var other := at + Vector2(6.0, 0.0)
	var low := _cast(ctx, at, false, 4)
	var high := _cast(ctx, other)
	var a := EV._put(crowd, at + Vector2(3.0, 4.0))
	var b := EV._put(crowd, other + Vector2(3.0, 4.0))
	_until(low, 0.8)
	_until(high, 2.0)
	a.ground_pos = at + Vector2(0.4, 0.0)
	_until(low, 1.7)
	b.ground_pos = other + Vector2(0.4, 0.0)
	_until(high, 3.0)
	t.check(not a.is_asleep() and b.is_asleep() and not _eyed(crowd, a) and _eyed(crowd, b),
		"_rf5_slumber_mixed: into the level-4 circle: awake; into the level-5 one: asleep, eyed")
	low.end_now()
	high.end_now()
	low.free()
	high.free()
	crowd.dusk.clear()


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var w := EV._put(crowd, at + Vector2(4.0, 0.0))
	var fx := _cast(ctx, at, false, 4)
	t.check(is_equal_approx(fx.duration, SlumberFx.T_FALL + 1.2), "level 4: the cast is as today (%.1f)" % fx.duration)
	_until(fx, 0.8)
	w.ground_pos = at + Vector2(0.5, 0.0)
	_until(fx, 1.7)
	t.check(not w.is_asleep() and fx.caught == 0 and PaleEye.of(crowd) == null, "level 4: nobody walking in sleeps; no eye")
	fx.free()
	crowd.dusk.clear()


static func _ended(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var early := EV._put(crowd, at + Vector2(0.8, 3.0))
	var late := EV._put(crowd, at + Vector2(4.0, 3.0))
	var fx := _cast(ctx, at)
	_until(fx, 3.0)
	early.ground_pos = at + Vector2(0.5, 0.0)
	_until(fx, 10.0)
	t.check(early.is_asleep(), "controls: the first walker sleeps")
	fx.end_now()
	late.ground_pos = at + Vector2(0.5, 0.0)
	for i in 20:
		fx._process(0.25)
	t.check(not late.is_asleep() and early.is_asleep(), "end_now() at t 10: no more catches; the sleeper sleeps on")
	fx.free()
	early.wake()
	crowd.dusk.clear()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var w := EV._put(crowd, at + Vector2(4.0, 0.0))
	var living := 0
	for p in crowd.citizens + crowd.soldiers:
		living += 1 if p.is_alive() else 0
	var fx := _cast(ctx, at)
	var id := fx.get_instance_id()
	_until(fx, 2.0)
	w.ground_pos = at + Vector2(0.5, 0.0)
	_until(fx, 2.5)
	fx.end_now()
	PaleEye.of(crowd).step(PaleEye.TIME + 0.1)  # the eyes are timed: they run out by themselves, none is open-ended
	t.check(PaleEye.of(crowd).held_by(id) == 0 and w.is_asleep(), "teardown: end_now() leaves no eye open; the sleeper is his own")
	fx.free()
	var fx2 := _cast(ctx, at)
	var id2 := fx2.get_instance_id()
	_until(fx2, 3.0)
	PaleEye.of(crowd).step(PaleEye.TIME + 0.1)
	fx2.get_parent().remove_child(fx2)
	fx2.free()
	t.check(PaleEye.of(crowd).held_by(id2) == 0, "teardown: freed off the tree, nothing held")
	var after := 0
	for p in crowd.citizens + crowd.soldiers:
		after += 1 if p.is_alive() else 0
	t.check(after == living, "nobody taken by the twist")
	w.wake()
	crowd.dusk.clear()


static func _looks(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var keep := [ctx.overhead, ctx.ground]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	stage.add_child(ctx.ground)
	stage.add_child(ctx.overhead)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var fx := _cast(ctx, at)
	var ring := fx.heavy_ring
	t.check(ring != null and ring.get_parent() == ctx.ground, "staged: Heavy Air keeps its ring on the ground")
	fx._process(SlumberFx.T_FALL + 5.0)
	t.check(is_instance_valid(ring) and not ring.is_queued_for_deletion(), "the ring is still drawn long after the fall")
	fx.end_now()
	await t.process_frame
	t.check(not is_instance_valid(ring) or ring.is_queued_for_deletion(), "the ring goes with the cast")
	var low := _cast(ctx, at, false, 4)
	t.check(low.heavy_ring == null, "level 4: no ring")
	low.free()
	crowd.dusk.clear()
	ctx.impact = null
	stub.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	stage.free()


static func _bare(t) -> void:
	var env := EnvironmentField.new()
	var bare := FxContext.new()
	bare.env = env
	bare.field = EnemyField.new()
	bare.field.env = env
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var fx := _cast(bare, Vector2.ZERO)
	for i in 40:
		fx._process(1.0)
	t.check(fx.finished and fx.caught == 0, "bare (no crowd): builds and finishes")
	fx.free()
	bare.field = null
	var fx2 := _cast(bare, Vector2.ZERO)
	for i in 40:
		fx2._process(1.0)
	t.check(fx2.finished, "bare (no field): builds and finishes")
	fx2.free()
	bare.overhead.free()
	bare.ground.free()
