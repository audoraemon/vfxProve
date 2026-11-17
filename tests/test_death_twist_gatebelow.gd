extends RefCounted
## The Gate Below, level 5 twist -- Graves Answer (Death and Decree ability levels, Task 8; DL8): while the rift is open the 8
## bodies nearest it within 12 each sprout a grave hand; each takes the nearest fair living person within 1.5 of its body, once
## (held where they stand for DRAG, then under as &"pit"), and the body sinks with them. Each is a soul for the close.

const RD := preload("res://tests/test_raise_dead.gd")
const GB := preload("res://tests/test_gatebelow.gd")


static func _cast(made: Array, at: Vector2, level: int) -> TheGateBelowFx:
	return FxTimeline.cast(TheGateBelowFx, made[5], at, {"level": level}) as TheGateBelowFx


static func _alive(made: Array) -> Array:
	return (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())


## Citizen `p` set down at `at` and killed as a mob death: the remain it leaves.
static func _corpse(made: Array, p: Person, at: Vector2) -> Remains.Remain:
	p.ground_pos = at
	(made[3] as EnemyField).kill(p, &"mob")
	return (made[0] as Crowd).remains.pick(at, false, false, 0.2)


static func _on(c: Vector2, i: int, n: int, r: float) -> Vector2:
	return c + Vector2.from_angle(TAU * float(i) / float(n)) * r


static func run(t) -> void:
	var made := RD._setup()
	_eight(t, made)
	_reach_and_cap(t, made)
	_level_four(t, made)
	RD._done(made)


## 10 bodies within 12, a person 1.0 outside each: 8 taken (the nearest 8 bodies), their remains taken, the two others stay;
## one more person within the pit's own reach: the rift's own soul, 9 in all; held where they stand, not dragged.
static func _eight(t, made: Array) -> void:
	GB._reset(made)
	var at := RD._empty(made)
	var pool := _alive(made)
	var rems: Array[Remains.Remain] = []
	var folk: Array[Person] = []
	for i in 10:
		var rad := 8.0 + float(i) * 0.3  # body i at 8.0 .. 10.7: the nearest eight are 0..7
		rems.append(_corpse(made, pool[i], _on(at, i, 10, rad)))
		var person: Person = pool[10 + i]
		person.ground_pos = _on(at, i, 10, rad + 1.0)
		person.mind = Person.Mind.CALM
		folk.append(person)
	var inner: Person = pool[20]
	inner.ground_pos = at + Vector2(2.0, 0.0)
	inner.mind = Person.Mind.CALM
	var fx := _cast(made, at, 5)
	t.check(fx.graves.size() == 8 and not rems.has(null), "level 5: eight bodies sprout a hand at the open (%d hands)" % fx.graves.size())
	RD._run(fx, TheGateBelowFx.T_OPEN + 0.05)
	t.check(fx.grabbed.size() == 2 and fx.grabbed[0] == inner, "the first tick: the rift's own grab and one grave hand (%d)" % fx.grabbed.size())
	var held: Person = fx.grabbed[1]
	var stood := held.ground_pos
	RD._run(fx, 0.5)
	t.check(held.is_alive() and held.pace_hold() == 0.0 and held.ground_pos.distance_to(stood) < 0.01,
		"a grave hand holds its one where he stands (%.2f)" % held.ground_pos.distance_to(stood))
	RD._run(fx, 8 * TheGateBelowFx.GRAB_EVERY + TheGateBelowFx.DRAG)
	var gone := 0
	for i in 8:
		if (made[0] as Crowd).remains.pick(rems[i].pos, false, false, 0.2) == null and not folk[i].is_alive():
			gone += 1
	t.check(gone == 8 and folk[8].is_alive() and folk[9].is_alive() and fx.grabbed.size() == 9,
		"the nearest eight bodies are taken with their persons, the two farther stay (%d of 8)" % gone)
	t.check((made[0] as Crowd).remains.pick(rems[8].pos, false, false, 0.2) != null and (made[0] as Crowd).remains.pick(rems[9].pos, false, false, 0.2) != null,
		"the two other bodies still lie there")
	t.check(fx.souls == 9 and fx.graves.is_empty(), "souls: the rift's own and eight (%d), no hand left waiting" % fx.souls)
	fx.end_now()


## A body at 12.5 sprouts nothing; 30 bodies in reach still give 8 hands (Review Focus 1).
static func _reach_and_cap(t, made: Array) -> void:
	GB._reset(made)
	var at := RD._empty(made)
	var pool := _alive(made)
	_corpse(made, pool[0], at + Vector2(12.5, 0.0))
	pool[1].ground_pos = at + Vector2(13.5, 0.0)
	pool[1].mind = Person.Mind.CALM
	var fx := _cast(made, at, 5)
	RD._run(fx, 6.0)
	t.check(fx.graves.is_empty() and fx.grabbed.is_empty() and pool[1].is_alive(), "a body at 12.5 sprouts no hand and nobody is taken")
	fx.end_now()
	GB._reset(made)
	pool = _alive(made)
	for i in 30:
		_corpse(made, pool[i], _on(at, i, 30, 8.0 + float(i % 4)))
	var fx2 := _cast(made, at, 5)
	t.check(fx2.graves.size() == 8, "30 bodies in reach: still 8 hands (%d)" % fx2.graves.size())
	fx2.end_now()


## Levels 1-4: the same layout takes nobody (no twist).
static func _level_four(t, made: Array) -> void:
	GB._reset(made)
	var at := RD._empty(made)
	var pool := _alive(made)
	_corpse(made, pool[0], at + Vector2(9.0, 0.0))
	var person: Person = pool[1]
	person.ground_pos = at + Vector2(10.0, 0.0)
	person.mind = Person.Mind.CALM
	var fx := _cast(made, at, 4)
	RD._run(fx, 6.0)
	t.check(fx.graves.is_empty() and fx.souls == 0 and person.is_alive(), "level 4: no grave hands, nobody taken")
	fx.end_now()
