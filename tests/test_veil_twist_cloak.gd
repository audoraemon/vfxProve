extends RefCounted
## Cloak of Night's level-5 twist, Averted Eyes (Veil ability levels, B2): while the cast keeps anyone cloaked, the watch that comes
## within 2.0 of one of them is eyed and turned away for 6 s (once per cast); a level-4 cast does none of it.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const DT := 0.05


static func _cast(ctx: FxContext, at: Vector2, level := 5) -> CloakOfNightFx:
	return FxTimeline.cast(CloakOfNightFx, ctx, at, {"level": level}) as CloakOfNightFx


static func _until(fx: CloakOfNightFx, to: float) -> void:
	while fx.t < to - 0.0001 and not fx.finished:
		fx._process(DT)


## `p` runs `seconds` of his own clock.
static func _tick(p: Person, seconds: float) -> void:
	for i in roundi(seconds / DT):
		p.tick(DT)


static func _fresh(made: Array) -> Vector2:
	var at := EV._fresh(made)
	var crowd: Crowd = made[0]
	if PaleEye.of(crowd) != null:
		PaleEye.of(crowd).free()
	crowd.pale_eye = null
	return at


static func _eyed(crowd: Crowd, p: Person) -> bool:
	return PaleEye.of(crowd) != null and PaleEye.of(crowd).is_eyed(p)


## A soldier at `x` with a post of his own, fighting a citizen `foe`.
static func _fighter(crowd: Crowd, x: Vector2, foe: Person) -> Person:
	var s := EV._put(crowd, x, true)
	s.post = x
	s.fight(foe, 60.0, 0.0, Person.FightRule.HOSTILES)
	return s


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_turn(t, made)
	_again(t, made)
	_others(t, made)
	_rf3_held_walker(t, made)
	_spared(t, made)
	_held_duty(t, made)
	_two_casts(t, made)
	_level_four(t, made)
	_ended(t, made)
	_teardown(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)
	_bare(t)


static func _turn(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var c := EV._put(crowd, at)
	var foe := EV._put(crowd, at + Vector2(0.0, 12.0))
	foe.mind = Person.Mind.FIGHT
	var s := _fighter(crowd, at + Vector2(9.0, 0.0), foe)
	var fx := _cast(ctx, at)
	t.check(c.hidden_from_watch() and not s.hidden_from_watch(), "controls: the click cloaks the man, not the soldier far off")
	t.check(s.mind == Person.Mind.FIGHT, "controls: the soldier fights")
	s.ground_pos = at + Vector2(2.1, 0.0)
	_until(fx, 1.0)
	t.check(s.mind == Person.Mind.FIGHT and not s.is_blind() and PaleEye.of(crowd) == null and fx.turned == 0,
		"at 2.1: nothing")
	s.ground_pos = at + Vector2(1.9, 0.0)
	_until(fx, 1.4)
	var eye := PaleEye.of(crowd)
	t.check(eye != null and eye.is_eyed(s) and eye.record.size() == 1 and eye.record[0].key == "cloak"
		and eye.record[0].fx == fx.get_instance_id(), "at 1.9: eyed, the record's key is cloak")
	t.check(s.mind == Person.Mind.POST and s.fight_target == null and not s.on_watch() and s.is_blind() and fx.turned == 1,
		"not fighting, mind POST, off watch")
	_tick(s, 5.9)
	t.check(not s.on_watch() and s._turn_left > 0.0, "off watch for 6 s (5.9)")
	s.ground_pos = s.anchor
	_tick(s, 0.3)
	s.ground_pos = s.anchor
	t.check(s.on_watch() and not s.is_blind() and s._turn_left == 0.0, "after 6.1 s he is on watch again and may fight")
	# The same soldier again: not turned twice by this cast.
	s.ground_pos = at + Vector2(1.0, 0.0)
	s.fight(foe, 60.0, 0.0, Person.FightRule.HOSTILES)
	_until(fx, 2.5)
	t.check(s.mind == Person.Mind.FIGHT and fx.turned == 1 and eye.record.size() == 1, "the same soldier again: not turned twice")
	fx.end_now()
	fx.free()


static func _again(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var s := EV._put(crowd, at + Vector2(1.5, 0.0), true)
	var fx := _cast(ctx, at)
	t.check(s.hidden_from_watch(), "controls: a soldier within the mark is cloaked himself")
	_until(fx, 1.0)
	t.check(fx.turned == 1 and s.is_blind(), "a cloaked soldier near another cloaked man is still turned (by the other)")
	fx.end_now()
	fx.free()


static func _others(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var cit := EV._put(crowd, at + Vector2(3.0, 0.0))
	var f := EV._put(crowd, at + Vector2(0.0, 6.0))
	var d := MissionDirector.new()
	d.setup(null, crowd, made[6], ctx)
	d.faithful.append(f)
	var fx := _cast(ctx, at)
	_until(fx, 0.5)
	f.ground_pos = at + Vector2(1.2, 0.0)
	cit.ground_pos = at + Vector2(0.0, 1.2)
	_until(fx, 1.2)
	t.check(not cit.is_blind() and not _eyed(crowd, cit), "a citizen near: nothing")
	t.check(f.mind == Person.Mind.CALM and f.is_blind() and _eyed(crowd, f) and not f.has_goal(), "a faithful: CALM, blind, eyed")
	_tick(f, 6.2)
	t.check(not f.is_blind() and f._turn_left == 0.0, "a faithful's sight returns after 6.1 s")
	crowd.clear_mission_hooks()
	fx.end_now()
	fx.free()


static func _rf3_held_walker(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var dreaded := EV._put(crowd, at + Vector2(8.0, 0.0), true)
	var asleep := EV._put(crowd, at + Vector2(8.0, 3.0), true)
	var fx := _cast(ctx, at)
	dreaded.statuses[&"dread"] = 100.0
	asleep.sleep(100.0, true)
	dreaded.ground_pos = at + Vector2(1.0, 0.0)
	asleep.ground_pos = at + Vector2(0.0, 1.0)
	_until(fx, 1.0)
	t.check(not dreaded.is_blind() and not asleep.is_blind() and fx.turned == 0 and PaleEye.of(crowd) == null,
		"_rf3_held_walker: a dreaded and a sleeping soldier near: skipped")
	fx.end_now()
	fx.free()
	dreaded.statuses.clear()
	asleep.wake()


## The spared (a man the mission keeps alive) near the cloaked are eyed, never turned.
static func _spared(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var kept := EV._put(crowd, at + Vector2(9.0, 0.0), true)
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == kept)
	var fx := _cast(ctx, at)
	kept.ground_pos = at + Vector2(1.5, 0.0)
	_until(fx, 2.0)
	t.check(_eyed(crowd, kept) and PaleEye.of(crowd).record.size() == 1, "a mission-kept soldier near: eyed, once (not again every tick)")
	t.check(not kept.is_blind() and fx.turned == 0 and kept.mind == Person.Mind.POST, "... and not turned away, not blind, still at his post")
	fx.end_now()
	fx.free()
	crowd.mission_keeps.clear()


## A soldier the god holds (Dominion), one the mission holds (a seizer with his charge) and one on a duty are eyed only: no turn_away,
## his mind and his hold unchanged, not blind, not counted as turned.
static func _held_duty(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var god := EV._put(crowd, at + Vector2(9.0, 0.0), true)
	var seizer := EV._put(crowd, at + Vector2(9.0, 3.0), true)
	var duty := EV._put(crowd, at + Vector2(9.0, 6.0), true)
	var fx := _cast(ctx, at)
	god.mind = Person.Mind.WHISPERED
	seizer.mind = Person.Mind.FIGHT
	duty.mind = Person.Mind.DUTY
	crowd.mission_holds.append(func(p: Person) -> bool: return p == seizer)
	t.check(god.held_by_god() and crowd.held_by_mission(seizer), "controls: held by the god, held by the mission")
	god.ground_pos = at + Vector2(1.5, 0.0)
	seizer.ground_pos = at + Vector2(0.0, 1.5)
	duty.ground_pos = at + Vector2(-1.5, 0.0)
	_until(fx, 2.0)
	t.check(_eyed(crowd, god) and _eyed(crowd, seizer) and _eyed(crowd, duty), "the held and the one on a duty are eyed")
	t.check(not god.is_blind() and not seizer.is_blind() and not duty.is_blind() and fx.turned == 0, "... and neither blind nor turned")
	t.check(god.mind == Person.Mind.WHISPERED and god.held_by_god() and seizer.mind == Person.Mind.FIGHT
		and crowd.held_by_mission(seizer) and duty.mind == Person.Mind.DUTY, "... and his mind, his hold and his duty are as they were")
	fx.end_now()
	fx.free()
	crowd.mission_holds.clear()
	for p in [god, seizer, duty]:
		p.mind = Person.Mind.CALM


static func _two_casts(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var other := at + Vector2(3.0, 0.0)
	EV._put(crowd, at)
	EV._put(crowd, other)
	var s := EV._put(crowd, at + Vector2(9.0, 5.0), true)
	var a := _cast(ctx, at)
	var b := _cast(ctx, other)
	s.ground_pos = at + Vector2(1.5, 0.0)
	_until(a, 3.0)
	_until(b, 3.0)
	t.check(a.turned == 1 and b.turned == 1, "two level-5 casts: the soldier is turned once by each (%d, %d)" % [a.turned, b.turned])
	a.end_now()
	b.end_now()
	a.free()
	b.free()


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var s := EV._put(crowd, at + Vector2(9.0, 0.0), true)
	var fx := _cast(ctx, at, 4)
	s.ground_pos = at + Vector2(1.5, 0.0)
	_until(fx, 2.0)
	t.check(not s.is_blind() and fx.turned == 0 and PaleEye.of(crowd) == null, "level 4: the watch near is not turned; no eye")
	fx.end_now()
	fx.free()


static func _ended(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	EV._put(crowd, at)
	var first := EV._put(crowd, at + Vector2(9.0, 0.0), true)
	var late := EV._put(crowd, at + Vector2(9.0, 4.0), true)
	var fx := _cast(ctx, at)
	first.ground_pos = at + Vector2(1.5, 0.0)
	_until(fx, 1.0)
	t.check(first.is_blind(), "controls: the first soldier is turned")
	fx.end_now()
	late.ground_pos = at + Vector2(1.5, 0.0)
	for i in 20:
		fx._process(0.25)
	t.check(first.is_blind() and not late.is_blind() and fx.turned == 1,
		"end_now(): the ticks stop; the turned stay turned (their own timer)")
	_tick(first, 6.2)
	t.check(not first.is_blind(), "and the turned man's own timer runs out")
	fx.free()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _fresh(made)
	var c := EV._put(crowd, at)
	var s := EV._put(crowd, at + Vector2(9.0, 0.0), true)
	var fx := _cast(ctx, at)
	var id := fx.get_instance_id()
	s.ground_pos = at + Vector2(1.5, 0.0)
	_until(fx, 1.0)
	fx.get_parent().remove_child(fx)
	fx.free()
	PaleEye.of(crowd).step(PaleEye.TIME + 0.1)
	t.check(PaleEye.of(crowd).held_by(id) == 0 and not c.hidden_from_watch() and c.is_alive() and s.is_alive(),
		"teardown: freed off the tree: the cloak lifted, no eye held, nobody taken")


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
	t.check(fx.finished and fx.turned == 0, "bare (no crowd): builds and finishes")
	fx.free()
	bare.field = null
	var fx2 := _cast(bare, Vector2.ZERO)
	for i in 40:
		fx2._process(1.0)
	t.check(fx2.finished, "bare (no field): builds and finishes")
	fx2.free()
	bare.overhead.free()
	bare.ground.free()
