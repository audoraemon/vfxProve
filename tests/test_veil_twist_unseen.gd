extends RefCounted
## Unseen Hour's level-5 twist, Eyes Within (Veil ability levels, A3): from the fall to the rise the watch within radius + 4 is eyed (open-
## ended, unmarked as he leaves that ring); whoever was inside the circle and walks out is blind for 6 s; the rise and teardown close every eye
## and blind nobody. Level 4 is as today.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const UNSEEN := preload("res://src/fx/quiet/unseen_hour.gd")
const R := 5.4


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_eyes(t, made)
	_leavers(t, made)
	_the_rise(t, made)
	_rf1_two_veils(t, made)
	_level_four(t, made)
	_teardown(t, made)
	_bare(t)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


static func _fresh(made: Array) -> Vector2:
	var crowd: Crowd = made[0]
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	return EV._fresh(made)


## A veil at `at` run just past its fall.
static func _fall(ctx: FxContext, at: Vector2, level := 5) -> UnseenHourFx:
	var fx := FxTimeline.cast(UNSEEN, ctx, at, {"level": level}) as UnseenHourFx
	fx._process(UnseenHourFx.T_FALL + 0.05)
	return fx


static func _eyed(crowd: Crowd, p: Person) -> bool:
	var e := PaleEye.of(crowd)
	return e != null and e.is_eyed(p)


static func _move(p: Person, at: Vector2) -> void:
	p.ground_pos = at


static func _eyes(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var near := EV._put(crowd, at + Vector2(9.0, 0.0), true)
	var far := EV._put(crowd, at + Vector2(0.0, 9.6), true)
	var citizen := EV._put(crowd, at + Vector2(-6.0, 0.0))
	var fx := _fall(ctx, at)
	t.check(is_equal_approx(fx.radius, R) and fx.veiled, "level 5 in the light: radius %s" % fx.radius)
	t.check(_eyed(crowd, near), "a soldier at 9.0 is eyed within one tick of the fall")
	t.check(not _eyed(crowd, far), "one at 9.6 is not")
	t.check(not _eyed(crowd, citizen), "a citizen at 6.0 is not")
	t.check(PaleEye.of(crowd).record[0]["key"] == "unseen", "the record's key is unseen")
	fx._process(1.0)
	t.check(_eyed(crowd, near), "he stays eyed while he stays in the ring (open-ended: well past 4 s)")
	fx._process(4.0)
	t.check(_eyed(crowd, near), "still, 5 s in")
	_move(near, at + Vector2(10.0, 0.0))
	fx._process(UnseenHourFx.TICK)
	t.check(not _eyed(crowd, near), "he walks to 10.0: unmarked")
	_move(far, at + Vector2(0.0, 9.0))
	fx._process(UnseenHourFx.TICK)
	t.check(_eyed(crowd, far), "and one who walks in to 9.0 is eyed")
	var alarm := crowd.alarm
	fx.end_now()
	t.check(not _eyed(crowd, far) and PaleEye.of(crowd).held_by(fx.get_instance_id()) == 0 and crowd.alarm == alarm, "end_now(): every eye of the cast closed")


static func _leavers(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var inside := EV._put(crowd, at + Vector2(3.0, 0.0))
	var out := EV._put(crowd, at + Vector2(0.0, 6.0))
	var victim := EV._put(crowd, at)
	var fx := _fall(ctx, at)
	t.check(not inside.is_blind() and not out.is_blind(), "nobody inside is blind while he stays inside, nor one who was outside")
	_move(inside, at + Vector2(6.0, 0.0))
	fx._process(UnseenHourFx.TICK)
	t.check(inside.is_blind() and is_equal_approx(inside._blind_left, 6.0), "an insider walking out to 6.0 is blind for 6 s (%.2f)" % inside._blind_left)
	t.check(not out.is_blind(), "one who was never inside is not")
	# He is passed over as a witness of a death beside him.
	_move(victim, at + Vector2(6.0, 0.5))
	var seen := crowd.nearest_witness(at + Vector2(6.0, 0.5), victim)
	t.check(seen != inside, "nearest_witness() of a death beside him passes him over")
	inside.tick(6.1)
	t.check(not inside.is_blind(), "not blind at 6.1 s")
	_move(inside, at + Vector2(7.0, 0.0))
	fx._process(UnseenHourFx.TICK)
	t.check(not inside.is_blind(), "he left the list when blinded: staying outside blinds him no more")
	fx.end_now()


static func _the_rise(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var inside := EV._put(crowd, at + Vector2(2.0, 0.0))
	var watcher := EV._put(crowd, at + Vector2(8.0, 0.0), true)
	var fx := _fall(ctx, at)
	t.check(_eyed(crowd, watcher), "control: the watcher is eyed")
	fx._process(fx.veil_time - 0.2)
	t.check(_eyed(crowd, watcher), "still eyed just before the rise")
	fx._process(0.3)
	t.check(not fx.veiled and not _eyed(crowd, watcher) and PaleEye.of(crowd).held_by(fx.get_instance_id()) == 0, "at the rise every eye is closed")
	_move(inside, at + Vector2(7.0, 0.0))
	fx._process(0.5)
	t.check(not inside.is_blind(), "one inside at the rise is not blind: the lift blinds nobody")
	fx.end_now()


static func _rf1_two_veils(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var b_at := at + Vector2(6.0, 0.0)
	var watcher := EV._put(crowd, at + Vector2(3.0, 7.0), true)
	var a := _fall(ctx, at)
	var b := _fall(ctx, b_at)
	var eye := PaleEye.of(crowd)
	t.check(_eyed(crowd, watcher) and eye.held_by(a.get_instance_id()) == 1 and eye.held_by(b.get_instance_id()) == 1, "_rf1_two_veils: a watcher eyed by veils A and B")
	a.end_now()
	t.check(_eyed(crowd, watcher) and eye.held_by(a.get_instance_id()) == 0 and eye.held_by(b.get_instance_id()) == 1, "A's end leaves him eyed by B")
	b.end_now()
	t.check(not _eyed(crowd, watcher) and eye.held_by(b.get_instance_id()) == 0, "B's end closes it")


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var watcher := EV._put(crowd, at + Vector2(8.0, 0.0), true)
	var inside := EV._put(crowd, at + Vector2(2.0, 0.0))
	var fx := _fall(ctx, at, 4)
	_move(inside, at + Vector2(7.0, 0.0))
	fx._process(1.0)
	t.check(PaleEye.of(crowd) == null and not inside.is_blind() and not watcher.is_blind(), "level 4: no eye, no blind")
	fx.end_now()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var watcher := EV._put(crowd, at + Vector2(8.0, 0.0), true)
	var fx := _fall(ctx, at)
	var id := fx.get_instance_id()
	fx.free()
	t.check(not _eyed(crowd, watcher) and PaleEye.of(crowd).held_by(id) == 0 and watcher.is_alive(), "freed off the tree mid-veil: every eye closed, nobody taken")
	# Freed before the fall: nothing.
	at = _fresh(made)
	var early := FxTimeline.cast(UNSEEN, ctx, at, {"level": 5})
	early._process(0.2)
	early.free()
	t.check(PaleEye.of(crowd) == null, "freed before the fall: no eye")


static func _bare(t) -> void:
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	var bare := FxContext.new()
	bare.env = env
	bare.field = field
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var fx := FxTimeline.cast(UNSEEN, bare, Vector2.ZERO, {"level": 5})
	fx._process(UnseenHourFx.T_FALL + 1.0)
	fx.end_now()
	var bare2 := FxContext.new()
	bare2.overhead = Node2D.new()
	var fx2 := FxTimeline.cast(UNSEEN, bare2, Vector2.ZERO, {"level": 5})
	fx2._process(UnseenHourFx.T_FALL + 1.0)
	fx2.end_now()
	t.check(fx.finished and fx2.finished, "bare (no crowd, no field): builds and finishes")
	bare.overhead.free()
	bare.ground.free()
	bare2.overhead.free()
