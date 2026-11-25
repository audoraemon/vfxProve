extends RefCounted
## Silent Doom's level-5 twist, No Witness (Veil ability levels, A1): each victim's nearest witness, named at the settle, is eyed and
## silenced too (once, one hop), unless the town spares him (eyed only); level 4 is as today; teardown leaves no answer registered.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const DOOM := preload("res://src/fx/quiet/silent_doom.gd")
const UNSEEN := preload("res://src/fx/quiet/unseen_hour.gd")


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_alone(t, made)
	_two_witnesses(t, made)
	_two_victims(t, made)
	_no_second_hop(t, made)
	_spared(t, made)
	_sleeper(t, made)
	_rf5_doom_mixed(t, made)
	_inside_a_veil(t, made)
	_level_four(t, made)
	_teardown(t, made)
	_bare(t)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


## A cast at `level` struck (run just past T_STRIKE), not yet settled.
static func _strike(ctx: FxContext, at: Vector2, level := 5) -> FxTimeline:
	var fx := FxTimeline.cast(DOOM, ctx, at, {"level": level})
	fx._process(SilentDoom.T_STRIKE + 0.05)
	return fx


## A fresh town with no eye (EV._fresh() plus a ledger of its own).
static func _fresh(made: Array) -> Vector2:
	var crowd: Crowd = made[0]
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	return EV._fresh(made)


static func _eyed(crowd: Crowd, p: Person) -> bool:
	var e := PaleEye.of(crowd)
	return e != null and e.is_eyed(p)


static func _alone(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	var dead := crowd.killed_citizens
	var alarm := crowd.alarm
	var threats := crowd.threats.active_count()
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(not v.is_alive() and not w.is_alive() and crowd.killed_citizens == dead + 2, "No Witness: the witness falls with him (+2 dead: %d)" % (crowd.killed_citizens - dead))
	t.check(_eyed(crowd, w) and PaleEye.of(crowd).record.size() == 1 and PaleEye.of(crowd).record[0]["key"] == "doom", "he was eyed, the record's key is doom")
	t.check(crowd.alarm == alarm and crowd.threats.active_count() == threats, "nobody left to see it: no alarm, no doom threat (V unseen)")
	crowd._settle_doom()
	t.check(crowd.alarm == alarm, "and the witness's own death is seen by nobody")
	fx.end_now()


static func _two_witnesses(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	# Today's alarm for a seen death (a level-4 cast, the same ground).
	var at := _fresh(made)
	EV._put(crowd, at)
	EV._put(crowd, at + Vector2(1.0, 0.0))
	var base_alarm := crowd.alarm
	var base := _strike(ctx, at, 4)
	crowd._settle_doom()
	var today := crowd.alarm - base_alarm
	base.end_now()
	at = _fresh(made)
	var v := EV._put(crowd, at)
	var w1 := EV._put(crowd, at + Vector2(1.0, 0.0))
	var w2 := EV._put(crowd, at + Vector2(1.15, 0.0))
	var alarm := crowd.alarm
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(not w1.is_alive() and w2.is_alive() and not _eyed(crowd, w2), "two witnesses: the nearer falls, the other lives and is not eyed")
	t.check(not v.is_alive() and today > 0.0 and is_equal_approx(crowd.alarm - alarm, today), "and V is seen by the second: the alarm rises as today (%.2f)" % (crowd.alarm - alarm))
	fx.end_now()


static func _two_victims(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var v1 := EV._put(crowd, at)
	var v2 := EV._put(crowd, at + Vector2(0.0, 0.3))
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	var dead := crowd.killed_citizens
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(not v1.is_alive() and not v2.is_alive() and not w.is_alive() and crowd.killed_citizens == dead + 3,
		"two victims, one witness: he falls once (+3 dead: %d)" % (crowd.killed_citizens - dead))
	t.check(PaleEye.of(crowd).record.size() == 1, "eyed once")
	fx.end_now()


static func _no_second_hop(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w1 := EV._put(crowd, at + Vector2(1.0, 0.0))
	var x := EV._put(crowd, at + Vector2(2.0, 0.0))
	var alarm := crowd.alarm
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(not w1.is_alive() and x.is_alive() and not _eyed(crowd, x), "no second hop: W1's witness lives and is not eyed")
	var after_first := crowd.alarm
	crowd._settle_doom()
	t.check(x.is_alive() and not _eyed(crowd, x) and crowd.alarm >= after_first and not v.is_alive(),
		"and W1's own death is judged at the next settle by today's rule, answering nobody (alarm %.2f -> %.2f)" % [alarm, crowd.alarm])
	fx.end_now()


static func _spared(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	# A believer.
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	w.profile.faith = CitizenProfile.Faith.BELIEVER
	var alarm := crowd.alarm
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(w.is_alive() and _eyed(crowd, w) and not v.is_alive() and crowd.alarm > alarm, "a believer witness: eyed, alive, and V is seen")
	fx.end_now()
	w.profile.faith = CitizenProfile.Faith.NONE
	# One the mission keeps alive.
	at = _fresh(made)
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	var keep := func(p: Person) -> bool: return p == w
	crowd.mission_keeps.append(keep)
	alarm = crowd.alarm
	fx = _strike(ctx, at)
	crowd._settle_doom()
	t.check(w.is_alive() and _eyed(crowd, w) and not v.is_alive() and crowd.alarm > alarm, "a witness the mission keeps: eyed, alive, V seen")
	fx.end_now()
	crowd.mission_keeps.clear()


## R4: a sleeper who counts as a witness today is answerable.
static func _sleeper(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	w.sleep(200.0, true)
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(not w.is_alive() and _eyed(crowd, w) and not v.is_alive(), "a sleeping witness dies to No Witness (R4)")
	fx.end_now()


static func _rf5_doom_mixed(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var far := at + Vector2(14.0, 0.0)
	var v4 := EV._put(crowd, at)
	var w4 := EV._put(crowd, at + Vector2(1.0, 0.0))
	var v5 := EV._put(crowd, far)
	var w5 := EV._put(crowd, far + Vector2(1.0, 0.0))
	var f4 := FxTimeline.cast(DOOM, ctx, at, {"level": 4})
	var f5 := FxTimeline.cast(DOOM, ctx, far, {"level": 5})
	f4._process(SilentDoom.T_STRIKE + 0.05)
	f5._process(SilentDoom.T_STRIKE + 0.05)
	crowd._settle_doom()
	t.check(not v4.is_alive() and not v5.is_alive() and w4.is_alive() and not w5.is_alive() and not _eyed(crowd, w4),
		"_rf5_doom_mixed: a level-4 and a level-5 cast struck in one frame: only the level-5 one's witness falls")
	f4.end_now()
	f5.end_now()


static func _inside_a_veil(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	var veil := FxTimeline.cast(UNSEEN, ctx, at, {"level": 5})
	veil._process(UnseenHourFx.T_FALL + 0.05)
	var fx := _strike(ctx, at)
	crowd._settle_doom()
	t.check(not v.is_alive() and w.is_alive() and not _eyed(crowd, w), "a death inside an Unseen Hour veil names nobody")
	fx.end_now()
	veil.end_now()


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	var alarm := crowd.alarm
	var fx := _strike(ctx, at, 4)
	crowd._settle_doom()
	t.check(not v.is_alive() and w.is_alive() and PaleEye.of(crowd) == null and crowd.alarm > alarm, "level 4: nothing of the twist, no eye, V seen as today")
	fx.end_now()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var field: EnemyField = made[3]
	# Freed before the strike: nothing registered.
	var at := _fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	var fx := FxTimeline.cast(DOOM, ctx, at, {"level": 5})
	fx._process(0.2)
	fx.free()
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(w.is_alive() and crowd._doom_answers.is_empty() and PaleEye.of(crowd) == null, "freed before T_STRIKE: no answer left registered, nobody falls")
	# Ended between the strike and the settle.
	at = _fresh(made)
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	fx = _strike(ctx, at)
	t.check(not crowd._doom_answers.is_empty(), "control: the strike registered its answer")
	fx.end_now()
	crowd._settle_doom()
	t.check(w.is_alive() and crowd._doom_answers.is_empty(), "end_now() before the settle: the answer is taken back, the witness lives")
	# Freed off the tree between the strike and the settle.
	at = _fresh(made)
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	fx = _strike(ctx, at)
	fx.free()
	crowd._settle_doom()
	t.check(w.is_alive() and crowd._doom_answers.is_empty(), "freed off the tree before the settle: the same")


static func _bare(t) -> void:
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	var bare := FxContext.new()
	bare.env = env
	bare.field = field
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var fx := FxTimeline.cast(DOOM, bare, Vector2.ZERO, {"level": 5})
	fx._process(SilentDoom.T_STRIKE + 0.1)
	fx.end_now()
	t.check(fx.finished and PaleEye.of(null) == null, "bare (no crowd): builds and finishes")
	bare.overhead.free()
	bare.ground.free()
