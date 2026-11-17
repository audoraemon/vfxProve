extends RefCounted
## Corpse Guise level 5, Deathless (Death and Decree ability levels, Task 6): a guised person who would die falls instead (no kill
## counted, no remain, no alarm), lies 5.0 s on a held pace, then rises at full health with the guise renewed to 10.0 s. Once per
## guised person per cast; the Gate's pit never; a person whose guise ended, or whose cast is gone, dies normally. Levels 1-4 do none.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func run(t) -> void:
	_next = 10
	var made := RD._setup()
	_fall(t, made)
	_second(t, made)
	_pit(t, made)
	_ended(t, made)
	_level_4(t, made)
	_two_casts(t, made)
	_teardown(t, made)
	RD._done(made)


## A cast at `level` over `n` citizens (ids from `first`) standing near an empty spot; returns the cast.
static var _next := 10


static func _cast(made: Array, level: int, n := 2) -> CorpseGuiseFx:
	var first := _next
	_next += n
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	for i in n:
		var c: Person = crowd.citizens[first + i]
		c.ground_pos = at + Vector2(0.3 * float(i), 0.0)
		c.health = Person.HEALTH_CITIZEN
		c.deathless = Callable()
	return FxTimeline.cast(CorpseGuiseFx, made[5], at, {"level": level}) as CorpseGuiseFx


static func _kill(made: Array, p: Person, kind := &"smite") -> bool:
	return (made[3] as EnemyField).kill(p, kind, p.ground_pos + Vector2(1.0, 0.0))


static func _fall(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var fx := _cast(made, 5)
	var p: Person = fx.marked[0]
	t.check(fx.marked.size() == 2 and p.guised() and p.deathless.is_valid(), "level 5: the guised carry the hook")
	var n0 := crowd.killed_citizens
	var rem0 := crowd.remains.all().size()
	var alarm0 := crowd.alarm
	p.health = 0.0
	t.check(not _kill(made, p), "a guised person struck to death: no death counted by the field")
	t.check(p.is_alive() and p.is_down() and crowd.killed_citizens == n0 and crowd.remains.all().size() == rem0
		and is_equal_approx(crowd.alarm, alarm0), "lies down alive: no kill, no remain, no alarm")
	t.check(not p.deathless.is_valid(), "the hook is spent")
	RD._run(fx, 4.9)
	t.check(p.is_alive() and p.health <= 0.0 and p.pace_hold() == 0.0 and p.guised(), "still lying at 4.9 s on a held pace, still guised")
	RD._run(fx, 0.2)
	t.check(is_equal_approx(p.health, Person.HEALTH_CITIZEN) and p.pace_hold() == 1.0, "up at 5.0 s at full health, pace free")
	t.check(p.guised() and float(p.statuses[CorpseGuiseFx.KEY]) > 9.8 and float(p.statuses[CorpseGuiseFx.KEY]) <= 10.0,
		"the guise renewed to 10 s from the rise (%s)" % [p.statuses[CorpseGuiseFx.KEY]])
	t.check(fx.duration >= fx.t + 9.8, "the cast lives to cover it")
	RD._run(fx, 9.6)
	t.check(p.guised(), "still guised at +9.6")
	RD._run(fx, 0.6)
	t.check(not p.guised(), "the guise ends at +10")
	fx.end_now()


static func _second(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var fx := _cast(made, 5)
	var p: Person = fx.marked[0]
	_kill(made, p)
	RD._run(fx, 5.2)
	var n0 := crowd.killed_citizens
	t.check(_kill(made, p) and not p.is_alive() and crowd.killed_citizens == n0 + 1, "a second death in the same cast kills (after the rise)")
	var q: Person = fx.marked[1]
	_kill(made, q)
	var n1 := crowd.killed_citizens
	t.check(_kill(made, q) and not q.is_alive() and crowd.killed_citizens == n1 + 1, "a second death while lying kills too")
	t.check(q.pace_hold() == 1.0 or not q.is_alive(), "(a dead one's hold does not matter)")
	fx.end_now()


static func _pit(t, made: Array) -> void:
	var fx := _cast(made, 5)
	var p: Person = fx.marked[0]
	t.check(p.deathless.is_valid(), "control: the hook is on")
	t.check(_kill(made, p, &"pit") and not p.is_alive(), "taken by the Gate (pit) is not caught")
	var q: Person = fx.marked[1]
	var held := _kill(made, q, &"smite")
	t.check(not held and q.is_alive(), "control: the same person's other kind is caught")
	fx.end_now()


## A guise that ended: the person dies normally; with a positive control that the same path catches while guised.
static func _ended(t, made: Array) -> void:
	var fx := _cast(made, 5)
	var p: Person = fx.marked[0]
	RD._run(fx, fx.lv_span + 0.3)
	t.check(not p.guised() and not p.deathless.is_valid(), "the guise ended: the hook is gone")
	t.check(_kill(made, p) and not p.is_alive(), "a person whose guise ended dies normally")
	var g := _cast(made, 5)
	var q: Person = g.marked[0]
	t.check(not _kill(made, q) and q.is_alive(), "control: a guised person is caught on the same path")
	g.end_now()


static func _level_4(t, made: Array) -> void:
	var fx := _cast(made, 4)
	var p: Person = fx.marked[0]
	t.check(fx.marked.size() > 0 and p.guised() and not p.deathless.is_valid(), "level 4: no hook")
	t.check(_kill(made, p) and not p.is_alive(), "level 4: a guised person dies")
	fx.end_now()


## Two casts: a later one takes the guise over; the earlier one's hook and fall go with it, and ending one leaves the other's.
static func _two_casts(t, made: Array) -> void:
	var a := _cast(made, 5)
	var p: Person = a.marked[0]
	var b := FxTimeline.cast(CorpseGuiseFx, made[5], p.ground_pos, {"level": 4}) as CorpseGuiseFx
	t.check(b.marked.has(p) and not p.deathless.is_valid(), "a level-4 cast taking over clears the earlier hook")
	t.check(_kill(made, p) and not p.is_alive(), "taken over by level 4: dies")
	a.end_now()
	b.end_now()
	var c := _cast(made, 5, 1)
	var q: Person = c.marked[0]
	var d := FxTimeline.cast(CorpseGuiseFx, made[5], q.ground_pos, {"level": 5}) as CorpseGuiseFx
	t.check(q.deathless == Callable(d, "_spare"), "a later level-5 cast owns the hook")
	c.end_now()
	t.check(q.deathless == Callable(d, "_spare") and q.guised(), "the earlier cast ending leaves the later one's hook and guise")
	_kill(made, q)
	t.check(q.is_alive() and q.is_down(), "and the later one's hook still catches")
	d.end_now()
	t.check(q.pace_hold() == 1.0 and not q.deathless.is_valid() and q.is_alive(), "its end lets the fallen up and clears the hook")


static func _teardown(t, made: Array) -> void:
	var fx := _cast(made, 5)
	var p: Person = fx.marked[0]
	var q: Person = fx.marked[1]
	t.check(p.deathless.is_valid() and q.deathless.is_valid(), "control: a level-5 cast sets them")
	p.health = 0.0
	_kill(made, p)
	t.check(p.pace_hold() == 0.0, "control: a fallen one is held")
	fx.end_now()
	t.check(fx.finished and not p.deathless.is_valid() and not q.deathless.is_valid(), "end_now() clears every hook")
	t.check(p.pace_hold() == 1.0 and is_equal_approx(p.health, Person.HEALTH_CITIZEN) and p.is_alive(), "end_now() lets a fallen one up at full health")
	t.check(_kill(made, q) and not q.is_alive(), "after end_now() a death is a death")
	# Freed without finishing.
	var g := _cast(made, 5)
	var r: Person = g.marked[0]
	var s: Person = g.marked[1]
	r.health = 0.0
	_kill(made, r)
	g.free()
	t.check(not is_instance_valid(g), "the cast node is freed")
	t.check(not r.deathless.is_valid() and not s.deathless.is_valid() and r.pace_hold() == 1.0 and r.is_alive(), "a freed cast leaves no hook and no held pace")
	t.check(_kill(made, s) and not s.is_alive(), "after the free a death is a death")
