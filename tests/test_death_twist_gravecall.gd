extends RefCounted
## Gravecall level 5, Swelling Host (Death and Decree ability levels, Task 5): while the wraiths haunt, a death inside HAUNT_R of the
## haunt spot raises one more wraith (DeathParts.haunt()) at the body, 4 at most per cast; they haunt until the cast's haunt ends.
## Levels 1-4 do none of it; two overlapping casts each count their own; a finished or freed cast listens to nothing.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func run(t) -> void:
	var made := RD._setup()
	_host(t, made)
	_edge(t, made)
	_before_haunt(t, made)
	_level_4(t, made)
	_two_casts(t, made)
	_teardown(t, made)
	RD._done(made)


static func _cast(made: Array, from: Vector2, to: Vector2, level: int) -> GravecallFx:
	return FxTimeline.cast(GravecallFx, made[5], from, {"to": to, "level": level}) as GravecallFx


## A cast run until its wraiths haunt the spot.
static func _haunting(made: Array, level: int) -> GravecallFx:
	RD._clear_all(made)
	var at := RD._empty(made)
	var to := at + Vector2(0.0, 2.0)
	var fx := _cast(made, at, to, level)
	RD._run(fx, GravecallFx.T_RISE + 0.1)
	for i in 400:
		if fx.haunting:
			break
		RD._run(fx, 0.5)
	return fx


## Citizen number `i` stands at `p` and dies there; returns whether the field counted the death.
static func _die_at(made: Array, i: int, p: Vector2) -> bool:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var c: Person = crowd.citizens[i]
	c.ground_pos = p
	return field.kill(c, &"smite")


static func _host(t, made: Array) -> void:
	var fx := _haunting(made, 5)
	var to: Vector2 = fx._to
	var base := fx.lv_spirits
	t.check(fx.haunting and fx.visitors.living().size() == base, "level 5: %d wraiths haunt at first (%d)" % [base, fx.visitors.living().size()])
	var first := fx.spirits.duplicate()
	var bodies: Array[Vector2] = []
	for i in 5:
		var p := to + Vector2.from_angle(float(i) * 1.2) * 2.0
		bodies.append(p)
		t.check(_die_at(made, 10 + i, p), "(death %d counted)" % i)
	var living := fx.visitors.living()
	t.check(living.size() == base + GravecallFx.HOST_MAX, "level 5: 5 deaths inside -> 4 more wraiths (%d of %d)" % [living.size(), base + 4])
	var risen: Array[Animal] = []
	for a in living:
		if not first.has(a):
			risen.append(a)
	var near := risen.size() == 4
	for k in risen.size():
		near = near and risen[k].breed == Animal.Breed.WRAITH and risen[k].ground_pos.distance_to(bodies[k]) < 0.1
	t.check(near, "they rise at the first four bodies, as wraiths")
	# They haunt until the cast's haunt ends, then thin away with the rest.
	RD._run(fx, fx._started + fx.lv_haunt - 1.0 - fx.t)
	t.check(not fx.finished and fx.visitors.living().size() == base + 4, "still haunting before the haunt is up")
	RD._run(fx, 1.0 + GravecallFx.FADE + 0.4)
	t.check(fx.finished and fx.visitors.living().is_empty(), "gone when the haunt ends")


static func _edge(t, made: Array) -> void:
	var fx := _haunting(made, 5)
	var to: Vector2 = fx._to
	var base := fx.visitors.living().size()
	t.check(_die_at(made, 20, to + Vector2(GravecallFx.HAUNT_R + 0.1, 0.0)), "(outer death counted)")
	t.check(fx.visitors.living().size() == base, "a death at HAUNT_R + 0.1 raises none")
	t.check(_die_at(made, 21, to + Vector2(GravecallFx.HAUNT_R - 0.1, 0.0)), "(inner death counted)")
	t.check(fx.visitors.living().size() == base + 1, "control: a death at HAUNT_R - 0.1 raises one")
	fx.end_now()


## Not haunting yet (the wraiths are still on their way): a death in the circle raises none; the same death once they haunt does.
static func _before_haunt(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	var to := at + Vector2(0.0, 3.0)
	var fx := _cast(made, at, to, 5)
	RD._run(fx, GravecallFx.T_RISE + 0.1)
	var base := fx.visitors.living().size()
	t.check(not fx.haunting, "(wraiths still on their way after the rise)")
	t.check(_die_at(made, 30, to + Vector2(1.0, 0.0)), "(early death counted)")
	t.check(fx.visitors.living().size() == base, "no wraith rises from a death before they haunt")
	for i in 400:
		if fx.haunting:
			break
		RD._run(fx, 0.5)
	t.check(_die_at(made, 31, to + Vector2(1.0, 0.0)) and fx.visitors.living().size() == base + 1,
		"control: once they haunt, the same death raises one")
	fx.end_now()


static func _level_4(t, made: Array) -> void:
	var fx := _haunting(made, 4)
	var to: Vector2 = fx._to
	var base := fx.visitors.living().size()
	var field: EnemyField = made[3]
	t.check(fx.haunting and base == fx.lv_spirits, "level 4 haunts")
	for i in 5:
		_die_at(made, 40 + i, to + Vector2.from_angle(float(i)) * 1.5)
	t.check(fx.visitors.living().size() == base, "level 4: 5 deaths inside raise none")
	t.check(not field.enemy_killed.is_connected(fx._on_killed), "level 4: no signal connected")
	fx.end_now()


## Two casts whose circles overlap: a body in both raises one wraith for each; each stops at its own 4; a body in one raises for that one.
static func _two_casts(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	var to_a := at + Vector2(0.0, 2.0)
	var to_b := to_a + Vector2(2.0, 0.0)
	var a := _cast(made, at, to_a, 5)
	var b := _cast(made, at + Vector2(0.0, 0.5), to_b, 5)
	for i in 400:
		if a.haunting and b.haunting:
			break
		RD._run(a, 0.5)
		RD._run(b, 0.5)
	t.check(a.haunting and b.haunting, "both casts haunt")
	var ba := a.visitors.living().size()
	var bb := b.visitors.living().size()
	var mid := to_a + Vector2(1.0, 0.0)  # within HAUNT_R of both spots
	t.check(_die_at(made, 50, mid), "(overlap death counted)")
	t.check(a.visitors.living().size() == ba + 1 and b.visitors.living().size() == bb + 1, "a death in both circles raises one for each")
	var only_b := to_b + Vector2(GravecallFx.HAUNT_R - 0.2, 0.0)
	t.check(only_b.distance_to(to_a) > GravecallFx.HAUNT_R, "(a spot only B covers)")
	t.check(_die_at(made, 51, only_b), "(B-only death counted)")
	t.check(a.visitors.living().size() == ba + 1 and b.visitors.living().size() == bb + 2, "a death in B's circle alone raises one for B only")
	for i in 5:
		_die_at(made, 52 + i, mid)
	t.check(a.visitors.living().size() == ba + 4 and b.visitors.living().size() == bb + 4,
		"each stops at its own 4 (%d, %d)" % [a._hosted, b._hosted])
	a.end_now()
	var bn := b.visitors.living().size()
	_die_at(made, 60, mid)
	t.check(bn == bb + 4 and b.visitors.living().size() == bn, "B at its cap raises no more once A is gone")
	b.end_now()


## A finished cast and a freed one listen to nothing; a standing level-5 cast does (the control).
static func _teardown(t, made: Array) -> void:
	var field: EnemyField = made[3]
	var base := field.enemy_killed.get_connections().size()
	var fx := _haunting(made, 5)
	t.check(field.enemy_killed.get_connections().size() == base + 1 and field.enemy_killed.is_connected(fx._on_killed), "control: a level-5 cast listens")
	var to: Vector2 = fx._to
	var pack := fx.visitors
	fx.end_now()
	t.check(field.enemy_killed.get_connections().size() == base and not field.enemy_killed.is_connected(fx._on_killed), "end_now() stops the listening")
	_die_at(made, 70, to)
	t.check(pack.living().is_empty(), "a death after end_now() raises nothing")
	# Freed without _finish.
	var g := _haunting(made, 5)
	t.check(field.enemy_killed.get_connections().size() == base + 1, "control: the second level-5 cast listens")
	var gp := g.visitors
	g.free()
	var left := gp.living().size()  # the pack is only queued for freeing
	t.check(field.enemy_killed.get_connections().size() == base, "a freed cast no longer listens")
	t.check(not is_instance_valid(g), "the cast node is freed")
	_die_at(made, 71, to)
	t.check(gp.living().size() == left, "a death after the free raises nothing")
	# Ended by its own haunt time, not end_now().
	var h := _haunting(made, 5)
	RD._run(h, h._started + h.lv_haunt + GravecallFx.FADE + 0.5 - h.t)
	t.check(h.finished and field.enemy_killed.get_connections().size() == base, "the haunt's own end stops the listening")
