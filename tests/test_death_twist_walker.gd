extends RefCounted
## Walking Corpse level 5, Borrowed Life (Death and Decree ability levels, Task 7): an ATTACK kill is &"borrowed" (no body, quiet,
## still a death); the walker takes the victim's design and lies down in the last victim's. Levels 1-4: &"grave" and a body.

const RD := preload("res://tests/test_raise_dead.gd")
const TW := preload("res://tests/test_walker.gd")


static func run(t) -> void:
	var made := RD._setup()
	_kill(t, made)
	_two(t, made)
	_level_4(t, made)
	_teardown(t, made)
	RD._done(made)


## A walker at `level` standing on an empty spot, its body citizen `n`'s.
static func _standing(made: Array, n: int, level: int) -> WalkingCorpseFx:
	RD._clear_all(made)
	var at := RD._empty(made)
	RD._body(made, n, at)
	var fx := FxTimeline.cast(WalkingCorpseFx, made[5], at, {"to": at, "level": level}) as WalkingCorpseFx
	RD._run(fx, WalkingCorpseFx.T_RISE + 0.3)
	return fx


## A soldier (a look no citizen wears) `d` off the walker, calm and about to fall to one blow.
static func _foe(made: Array, fx: WalkingCorpseFx, n: int, d := 3.0) -> Person:
	var foe: Person = (made[0] as Crowd).soldiers[n]
	foe.ground_pos = TW._spot(made, fx.walker.ground_pos, d)
	foe.mind = Person.Mind.CALM
	foe.health = 1.0
	return foe


## The attack order on `foe`, run until it ends.
static func _attack(fx: WalkingCorpseFx, foe: Person) -> bool:
	var taken := fx.follow_up(foe.ground_pos, {"order": "attack", "foe": foe})
	TW._until(fx, func() -> bool: return fx.order != "attack", 11.0)
	return taken


static func _kill(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var fx := _standing(made, 8, 5)
	var w := fx.walker
	var own := w.worn
	var foe := _foe(made, fx, 3)
	var look := foe._design()
	t.check(own != "" and look != "" and look != own, "setup: the walker's look (%s) is not the victim's (%s)" % [own, look])
	var deaths: Array = []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void: deaths.append([e, kind])
	field.enemy_killed.connect(on_kill)
	var killed := crowd.killed_soldiers + crowd.killed_citizens
	var rem0 := crowd.remains.all().size()
	var alarm := crowd.alarm
	var face := w.facing
	t.check(_attack(fx, foe), "level 5: the attack is taken")
	t.check(not foe.is_alive() and deaths == [[foe, &"borrowed"]] and fx.kills == 1, "the kill is the borrowed kind (%s)" % [deaths])
	t.check(crowd.remains.pick(foe.ground_pos, false, true) == null and crowd.remains.all().size() == rem0, "and leaves no remain")
	t.check(crowd.killed_soldiers + crowd.killed_citizens == killed + 1, "it counts as a death")
	t.check(Rules.POWER_KINDS["walker"].has(&"borrowed"), "Borrowed Life's kills are credited to the walker's power")
	RD._run(fx, 0.5)
	t.check(is_equal_approx(crowd.alarm, alarm), "no alarm (%.2f -> %.2f)" % [alarm, crowd.alarm])
	t.check(w.worn == look and fx.remain.design == look, "the walker's design and its remain's are the victim's")
	t.check(w.facing == face, "(its facing is kept)")
	field.enemy_killed.disconnect(on_kill)
	fx.give_way()
	var down := crowd.remains.pick(fx.remain.pos, false, true)
	t.check(down != null and down.design == look, "lying down, the remain at its spot has that design")
	fx.end_now()


static func _two(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var fx := _standing(made, 9, 5)
	var a := _foe(made, fx, 4)
	var citizen: Person = crowd.citizens[40]
	citizen.ground_pos = TW._spot(made, fx.walker.ground_pos, 3.0)
	citizen.mind = Person.Mind.CALM
	citizen.health = 1.0
	var la := a._design()
	var lb := citizen._design()
	t.check(la != lb, "setup: two different looks")
	_attack(fx, a)
	t.check(fx.walker.worn == la, "first victim: its design")
	_attack(fx, citizen)
	t.check(fx.kills == 2 and not citizen.is_alive() and fx.walker.worn == lb and fx.remain.design == lb,
		"two kills: the last victim's design (%s, %s)" % [fx.walker.worn, lb])
	fx.give_way()
	var down := crowd.remains.pick(fx.remain.pos, false, true)
	t.check(down != null and down.design == lb, "and it lies down as the last victim")
	fx.end_now()


static func _level_4(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var fx := _standing(made, 10, 4)
	var own := fx.walker.worn
	var foe := _foe(made, fx, 6)
	var deaths: Array = []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void: deaths.append([e, kind])
	field.enemy_killed.connect(on_kill)
	t.check(_attack(fx, foe), "level 4: the attack is taken")
	t.check(deaths == [[foe, &"grave"]] and crowd.remains.pick(foe.ground_pos, false, true) != null, "level 4: grave kill and a body")
	t.check(fx.walker.worn == own and fx.remain.design == own, "level 4: the walker keeps its look")
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	# Level 5 positive control on the same path, then both teardowns.
	var fx := _standing(made, 11, 5)
	var foe := _foe(made, fx, 7)
	var look := foe._design()
	_attack(fx, foe)
	t.check(fx.remain.design == look, "teardown control: level 5 borrowed the look")
	var remain := fx.remain
	fx.end_now()
	t.check(fx.finished and crowd.remains.pick(remain.pos, false, true) == remain and remain.design == look,
		"end_now(): lain down in the borrowed look, effect finished")
	fx.free()
	var fx2 := _standing(made, 12, 5)
	var foe2 := _foe(made, fx2, 8)
	_attack(fx2, foe2)
	var r2 := fx2.remain
	var look2 := foe2._design()
	fx2._exit_tree()
	var back := crowd.remains.pick(r2.pos, false, true)
	fx2.free()
	t.check(not is_instance_valid(fx2) and back == r2 and r2.design == look2,
		"freed without its end: the body is put back in the borrowed look")
