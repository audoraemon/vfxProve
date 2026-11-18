extends RefCounted
## disorder level 5 twist (Death and Decree ability levels, Task 17): Bad Counsel. Whoever crosses out of the circle while it
## holds carries the disorder (Person.carried_laws, 8 s), once per person per cast: still in DISORDER 7 s on, not 8.1 s on.
## One they pass is not disordered. Two casts overlapping both carry, neither lifts the other. The effect leaves no state of
## its own: ended early or freed, it gives nobody a carried law (a law already carried runs out by itself).

const Kit := preload("res://tests/test_decree.gd")
const PATH := "res://src/fx/decree/disorder.gd"
const DT := 0.1


static func _cast(ctx: FxContext, at: Vector2, level: int) -> DisorderFx:
	return FxTimeline.cast(load(PATH), ctx, at, {"level": level})


static func _run(fxs: Array, walkers: Array, seconds: float) -> void:
	for i in int(roundf(seconds / DT)):
		for fx: FxTimeline in fxs:
			if is_instance_valid(fx):
				fx._process(DT)
		for p: Person in walkers:
			if p.is_alive():
				p.frame(DT)


static func _world() -> Array:
	var made: Array = Kit._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	return [made, crowd, made[5], grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())]


static func _carries(p: Person) -> bool:
	return float(p.carried_laws.get(LawZone.DISORDER, 0.0)) > 0.0


static func run(t) -> void:
	_level4(t)
	_level5(t)
	_overlap(t)
	await _teardown(t)


## Level 4: a leaver carries nothing. Control: the same walk at level 5 carries.
static func _level4(t) -> void:
	for level in [4, 5]:
		var w := _world()
		var crowd: Crowd = w[1]
		var at: Vector2 = w[3]
		var p: Person = crowd.citizens[0]
		p.ground_pos = at + Vector2(1.0, 0.0)
		var fx := _cast(w[2], at, level)
		_run([fx], [p], 1.0)
		p.ground_pos = at + Vector2(fx.lv_radius + 2.0, 0.0)
		_run([fx], [p], 0.3)
		if level == 4:
			t.check(not _carries(p) and not crowd.in_law(p, LawZone.DISORDER), "disorder level 4: a leaver carries nothing")
		else:
			t.check(_carries(p) and crowd.in_law(p, LawZone.DISORDER), "disorder level 5 control: the same leaver carries the disorder")
		fx.end_now()
		fx.free()
		Kit._done(w[0])


static func _level5(t) -> void:
	var w := _world()
	var crowd: Crowd = w[1]
	var at: Vector2 = w[3]
	var leaver: Person = crowd.citizens[0]
	var passed: Person = crowd.citizens[1]
	var stayer: Person = crowd.citizens[2]
	leaver.ground_pos = at + Vector2(1.0, 0.0)
	stayer.ground_pos = at + Vector2(-1.0, 0.0)
	var fx := _cast(w[2], at, 5)
	var out := at + Vector2(fx.lv_radius + 3.0, 0.0)
	var all := [leaver, passed, stayer]
	_run([fx], all, 5.0)
	t.check(not _carries(leaver) and crowd.in_law(leaver, LawZone.DISORDER), "disorder level 5: inside at 5 s, in the law itself, nothing carried yet")
	leaver.ground_pos = out
	_run([fx], all, DT)
	t.check(_carries(leaver) and float(leaver.carried_laws[LawZone.DISORDER]) > 7.0, "disorder level 5: crossing out gives the leaver DISORDER for 8 s")
	# Someone passes right by the leaver: nothing spreads.
	passed.ground_pos = out + Vector2(0.4, 0.0)
	_run([fx], all, 2.0)
	t.check(not _carries(passed) and not crowd.in_law(passed, LawZone.DISORDER), "disorder level 5: one who passes the leaver is not disordered")
	t.check(not _carries(stayer) and crowd.in_law(stayer, LawZone.DISORDER), "disorder level 5: one who stays is in the law, not carrying")
	_run([fx], all, 4.9)   # about 7 s since leaving
	t.check(crowd.in_law(leaver, LawZone.DISORDER), "disorder level 5: still in DISORDER 7 s on")
	_run([fx], all, 1.2)   # about 8.2 s
	t.check(not crowd.in_law(leaver, LawZone.DISORDER) and leaver.carried_laws.is_empty(), "disorder level 5: not in DISORDER 8.1 s on")
	leaver.ground_pos = at
	_run([fx], [leaver], 0.3)
	leaver.ground_pos = out
	_run([fx], [leaver], 0.3)
	t.check(not _carries(leaver), "disorder level 5: once per person per cast, a second crossing gives nothing")
	fx.end_now()
	fx.free()
	Kit._done(w[0])


## Two casts over the same ground: both give the leaver a carried law; neither lifts the other's.
static func _overlap(t) -> void:
	var w := _world()
	var crowd: Crowd = w[1]
	var at: Vector2 = w[3]
	var p: Person = crowd.citizens[0]
	var q: Person = crowd.citizens[1]
	p.ground_pos = at
	q.ground_pos = at
	var a := _cast(w[2], at, 5)
	var b := _cast(w[2], at, 5)
	_run([a, b], [p, q], 1.0)
	p.ground_pos = at + Vector2(a.lv_radius + 3.0, 0.0)
	_run([a, b], [p, q], DT)
	t.check(_carries(p) and crowd.in_law(p, LawZone.DISORDER), "disorder level 5: two overlapping casts, the leaver carries")
	a.end_now()
	a.free()
	_run([b], [p, q], 1.0)
	t.check(crowd.in_law(p, LawZone.DISORDER), "disorder level 5: one cast ended, the carried law is not lifted")
	q.ground_pos = at + Vector2(b.lv_radius + 3.0, 0.0)
	_run([b], [p, q], DT)
	t.check(_carries(q), "disorder level 5: the other cast still gives its leaver the law")
	b.end_now()
	b.free()
	Kit._done(w[0])


static func _teardown(t) -> void:
	var w := _world()
	var crowd: Crowd = w[1]
	var at: Vector2 = w[3]
	var p: Person = crowd.citizens[0]
	var q: Person = crowd.citizens[1]
	p.ground_pos = at
	q.ground_pos = at
	var fx := _cast(w[2], at, 5)
	_run([fx], [p, q], 1.0)
	fx.end_now()
	t.check(fx._members.is_empty() and fx._carried.is_empty() and fx.law != null and not fx.law.alive(),
		"disorder level 5: end_now drops the bookkeeping and lifts the law")
	p.ground_pos = at + Vector2(fx.lv_radius + 3.0, 0.0)
	fx._process(DT)
	t.check(not _carries(p), "disorder level 5: after end_now a leaver carries nothing")
	fx.free()
	# Freed (not ended) while holding: same, and the node is gone.
	var f2 := _cast(w[2], at, 5)
	q.ground_pos = at
	_run([f2], [q], 1.0)
	var seen := f2._members.size()
	f2.free()
	q.ground_pos = at + Vector2(10.0, 0.0)
	_run([], [q], 0.3)
	t.check(seen > 0 and not is_instance_valid(f2) and not _carries(q), "disorder level 5: a freed cast leaves no carried law (it saw %d inside)" % seen)
	# Control: an undisturbed cast does give its leaver the law (same path, positive).
	var f3 := _cast(w[2], at, 5)
	q.ground_pos = at
	_run([f3], [q], 1.0)
	q.ground_pos = at + Vector2(f3.lv_radius + 3.0, 0.0)
	_run([f3], [q], DT)
	t.check(_carries(q), "disorder level 5 control: an undisturbed cast gives its leaver the law")
	# Once the law has lifted of itself, a crossing gives nothing.
	q.carried_laws.clear()
	f3._process(f3.duration)
	q.ground_pos = at
	f3._process(DT)
	q.ground_pos = at + Vector2(f3.lv_radius + 3.0, 0.0)
	f3._process(DT)
	t.check(not _carries(q), "disorder level 5: once the law has lifted, a crossing gives nothing")
	f3.end_now()
	f3.free()
	Kit._done(w[0])
