extends RefCounted
## Dreamless's level-5 twist, Found by No One (Veil ability levels, B3): at the find each sitter is looked for by the witness search
## (every sitter and resting finder skipped). Nobody near: taken. A finder who is not the god's: the sitter is taken, the finder is eyed
## and rests, then is judged by the same search. A finder who is spared: eyed only, the sitter dies a body as today. Level 4: as today.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const REST := 28.0
const HALF := 14.0


static func _cast(ctx: FxContext, at: Vector2, level := 5) -> DreamlessFx:
	return FxTimeline.cast(load("res://src/fx/veil/dreamless.gd"), ctx, at, {"level": level}) as DreamlessFx


static func _fresh(made: Array) -> Vector2:
	var at := EV._fresh(made)
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	if PaleEye.of(crowd) != null:
		PaleEye.of(crowd).free()
	crowd.pale_eye = null
	return at


static func _eyed(crowd: Crowd, p: Person) -> bool:
	return PaleEye.of(crowd) != null and PaleEye.of(crowd).is_eyed(p)


## Casts at `at` over the sitters `spots` (offsets), runs it to just after the sit and returns the cast.
static func _sat(crowd: Crowd, ctx: FxContext, at: Vector2, spots: Array, level := 5) -> DreamlessFx:
	for o: Vector2 in spots:
		EV._put(crowd, at + o)
	var fx := _cast(ctx, at, level)
	fx._process(DreamlessFx.T_SIT + 0.05)
	return fx


## Runs the cast to just after the find, the dusk long gone (it ran out in 22 s).
static func _find(crowd: Crowd, fx: DreamlessFx, rest := REST) -> void:
	crowd.dusk.clear()
	fx._process(DreamlessFx.T_SIT + rest - fx.t + 0.01)


static func _bodies(crowd: Crowd) -> int:
	return crowd.remains.all().size()


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_nobody(t, made)
	_finder(t, made)
	_judged_seen(t, made)
	_believer(t, made)
	_one_finder(t, made)
	_rf3_sleeping_finder(t, made)
	_level_four(t, made)
	_ended(t, made)
	_freed(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)
	_bare(t)


static func _nobody(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0), Vector2(0.0, 0.4)])
	t.check(is_equal_approx(fx.duration, DreamlessFx.T_SIT + REST * 1.5 + 1.0) and fx.resting == 2, "level 5: two sit; the duration covers the finders' rest (%.1f)" % fx.duration)
	var sitters: Array[Person] = fx._sat.duplicate()
	var alarm := crowd.alarm
	var rem := _bodies(crowd)
	_find(crowd, fx)
	t.check(fx.taken == 2 and not sitters[0].is_alive() and not sitters[1].is_alive() and _bodies(crowd) == rem
		and is_equal_approx(crowd.alarm, alarm) and fx.finders == 0, "nobody near: both sitters taken (they never name each other), no remain, alarm unchanged")
	t.check(PaleEye.of(crowd) == null, "and nobody is eyed")
	fx.end_now()
	fx.free()


static func _finder(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)])
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	var rem := _bodies(crowd)
	_find(crowd, fx)
	t.check(not s.is_alive() and _bodies(crowd) == rem and fx.taken == 1, "a citizen W at 1.5: the sitter is taken, no body")
	var eye := PaleEye.of(crowd)
	t.check(eye != null and eye.is_eyed(w) and eye.record.size() == 1 and eye.record[0].key == "dreamless"
		and eye.record[0].fx == fx.get_instance_id(), "W is eyed, the record's key is dreamless")
	t.check(w.is_deep_asleep() and w.statuses.has(&"dreamless") and absf(w.sleep_left() - (REST * 0.5 + 5.0)) < 0.5 and fx.finders == 1,
		"W rests deep for half the rest and 5 s more (%.1f)" % w.sleep_left())
	fx._process(HALF + 0.2)
	t.check(not w.is_alive() and _bodies(crowd) == rem and fx.taken == 2, "at +14 s with nobody near W: taken, no body")
	fx.end_now()
	fx.free()


static func _judged_seen(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)])
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	var x := EV._put(crowd, w.ground_pos + Vector2(1.0, 0.0))
	var rem := _bodies(crowd)
	_find(crowd, fx)
	t.check(not s.is_alive() and w.is_deep_asleep() and not _eyed(crowd, x) and not x.is_asleep(),
		"X beyond the sitter's reach: W is the finder; X is not eyed, awake")
	fx._process(HALF + 0.2)
	t.check(not w.is_alive() and _bodies(crowd) == rem + 1 and fx.taken == 1, "judged with X at 1.0: W killed, a remain")
	t.check(not _eyed(crowd, x) and x.is_alive(), "X is never eyed")
	fx.end_now()
	fx.free()


static func _believer(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)])
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	w.profile.faith = CitizenProfile.Faith.BELIEVER
	var rem := _bodies(crowd)
	_find(crowd, fx)
	t.check(not s.is_alive() and _bodies(crowd) == rem + 1 and _eyed(crowd, w) and not w.is_asleep() and fx.finders == 0 and fx.taken == 0,
		"W a believer: eyed only, the sitter is a body, W does not rest")
	fx._process(HALF + 0.2)
	t.check(w.is_alive(), "and W is never judged")
	fx.end_now()
	fx.free()
	w.profile.faith = CitizenProfile.Faith.NONE


static func _one_finder(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0), Vector2(0.0, 0.4)])
	var w := EV._put(crowd, at + Vector2(1.2, 0.4))
	_find(crowd, fx)
	t.check(fx.finders == 1 and fx.taken == 2 and w.is_deep_asleep() and PaleEye.of(crowd).record.size() == 1,
		"two sitters, one W: W rests once (%d finders), both sitters taken" % fx.finders)
	fx.end_now()
	fx.free()


static func _rf3_sleeping_finder(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)])
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	w.sleep(400.0, false)  # Slumber's sleeper is the nearest witness, as today
	_find(crowd, fx)
	t.check(not s.is_alive() and w.is_deep_asleep() and w.statuses.has(&"dreamless") and _eyed(crowd, w),
		"_rf3_sleeping_finder: a sleeper who is the nearest witness rests deep and is eyed")
	fx._process(HALF + 0.2)
	t.check(not w.is_alive(), "and is then judged (nobody near: taken)")
	fx.end_now()
	fx.free()


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)], 4)
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	var rem := _bodies(crowd)
	_find(crowd, fx, 26.0)
	t.check(not s.is_alive() and _bodies(crowd) == rem + 1 and not w.is_asleep() and fx.finders == 0 and fx.taken == 0
		and PaleEye.of(crowd) == null, "level 4: a body as today; nobody rests, nobody eyed")
	fx.free()


static func _ended(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)])
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	_find(crowd, fx)
	t.check(w.is_deep_asleep(), "controls: W rests")
	var rem := _bodies(crowd)
	fx.end_now()
	t.check(w.is_alive() and not w.is_asleep() and not w.statuses.has(&"dreamless") and _bodies(crowd) == rem,
		"end_now() while W rests: awake, the status gone, nobody taken")
	fx.free()
	var at2 := _fresh(made)
	var fx2 := _sat(crowd, ctx, at2, [Vector2(0.3, 0.0)])
	var s2: Person = fx2._sat[0]
	var w2 := EV._put(crowd, s2.ground_pos + Vector2(1.5, 0.0))
	_find(crowd, fx2)
	fx2.get_parent().remove_child(fx2)
	fx2.free()
	t.check(w2.is_alive() and not w2.is_asleep() and not w2.statuses.has(&"dreamless"), "freed off the tree: W awake, the status gone")


static func _freed(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var fx := _sat(crowd, ctx, at, [Vector2(0.3, 0.0)])
	var id := fx.get_instance_id()
	var s: Person = fx._sat[0]
	var w := EV._put(crowd, s.ground_pos + Vector2(1.5, 0.0))
	_find(crowd, fx)
	w.hurt(0.05, null)  # a hurt wakes a resting finder
	fx._process(HALF + 0.2)
	t.check(w.is_alive() and not w.is_asleep() and not w.statuses.has(&"dreamless"), "a finder woken by a hurt is not judged")
	PaleEye.of(crowd).step(PaleEye.TIME + 0.1)
	t.check(PaleEye.of(crowd).held_by(id) == 0, "no eye held at the end")
	fx.end_now()
	fx.free()


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
	for i in 80:
		fx._process(1.0)
	t.check(fx.finished and fx.finders == 0 and fx.taken == 0, "bare (no crowd): builds and finishes")
	fx.free()
	bare.overhead.free()
	bare.ground.free()
