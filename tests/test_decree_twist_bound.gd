extends RefCounted
## bound level 5 twist (Death and Decree ability levels, Task 15): Party to the Bond. The two BondEnds are an array; a person who
## strikes a bound one (his blow took health within the last frame, alive, not already bound) joins the bond, two to a cast, and
## then shares every fate; he carries LawMark BOUND under this cast's owner id. Seizures add no joiner (the director has no
## seizer_of: Ruling C5), stuns carry no source. Level 4 keeps the strikers outside. Everyone is unlinked on end_now and on free.

const PATH := "res://src/fx/decree/bound_in_law.gd"
const Bound := preload("res://tests/test_decree_bound.gd")
const Breath := preload("res://tests/test_decree_breath.gd")
const DT := 0.1


## A bound pair a, b (100 health) and four strikers s[0..3] standing apart, at `level`: [made, a, b, s, fx].
static func _world(level: int) -> Array:
	var made: Array = Breath._setup()
	var ab := Bound._pair(made)
	var a: Person = ab[0]
	var b: Person = ab[1]
	var crowd: Crowd = made[0]
	var s: Array = []
	for i in 4:
		var p: Person = crowd.soldiers[i]
		p.ground_pos = a.ground_pos + Vector2(0.0, 2.0 + float(i) * 0.7)
		p.health = 100.0
		s.append(p)
	var fx := FxTimeline.cast(load(PATH), made[5], a.ground_pos, {"to": b.ground_pos, "level": level})
	return [made, a, b, s, fx]


static func _step(fx: FxTimeline, seconds := DT) -> void:
	Breath._run([fx], seconds)


static func run(t) -> void:
	_level4(t)
	_one_joiner(t)
	_limit(t)
	_stale_and_stuns(t)
	_fate(t)
	_seizure(t)
	await _teardown(t)
	_overlap(t)


static func _level4(t) -> void:
	var w := _world(4)
	var a: Person = w[1]
	var b: Person = w[2]
	var s: Array = w[3]
	var fx: BoundFx = w[4]
	a.hurt(30.0, s[0])
	_step(fx)
	t.check(is_equal_approx(a.health, 70.0) and is_equal_approx(b.health, 70.0) and is_equal_approx((s[0] as Person).health, 100.0)
		and fx.joiners.is_empty() and LawMark.kind_of(s[0]) == &"",
		"bound level 4: the striker stays outside the bond (a 70, b 70, striker %.1f)" % (s[0] as Person).health)
	fx.end_now()
	Breath._done(w[0])
	# Control: the same blow at level 5 brings him in.
	var w5 := _world(5)
	var fx5: BoundFx = w5[4]
	(w5[1] as Person).hurt(30.0, w5[3][0])
	_step(fx5)
	t.check(fx5.joiners == [w5[3][0]] and LawMark.kind_of(w5[3][0]) == &"bound",
		"control: the same blow at level 5 makes him a joiner")
	fx5.end_now()
	Breath._done(w5[0])


static func _one_joiner(t) -> void:
	var w := _world(5)
	var a: Person = w[1]
	var b: Person = w[2]
	var s: Array = w[3]
	var fx: BoundFx = w[4]
	var sol: Person = s[0]
	a.hurt(30.0, sol)
	_step(fx)
	t.check(fx.joiners == [sol] and LawMark.kind_of(sol) == &"bound" and sol.law.laws.has(fx.get_instance_id()),
		"level 5: a soldier who strikes a bound one joins, with the BOUND mark under this cast's id")
	t.check(is_equal_approx(a.health, 70.0) and is_equal_approx(b.health, 70.0) and is_equal_approx(sol.health, 70.0),
		"A's hurt reaches B and the soldier: he strikes himself (a %.1f, b %.1f, soldier %.1f)" % [a.health, b.health, sol.health])
	_step(fx, 1.0)
	t.check(is_equal_approx(a.health, 70.0) and is_equal_approx(b.health, 70.0) and is_equal_approx(sol.health, 70.0),
		"once only: nothing passes back")
	# From now on the joiner's hurt reaches the others.
	sol.hurt(10.0, null)
	_step(fx)
	t.check(is_equal_approx(a.health, 60.0) and is_equal_approx(b.health, 60.0) and is_equal_approx(sol.health, 60.0),
		"the joiner struck for 10: a and b lose 10 too")
	# A bound striker is not a second joiner.
	a.hurt(10.0, sol)
	_step(fx)
	t.check(fx.joiners == [sol], "a bound striker is not joined twice")
	fx.end_now()
	Breath._done(w[0])


static func _limit(t) -> void:
	var w := _world(5)
	var a: Person = w[1]
	var b: Person = w[2]
	var s: Array = w[3]
	var fx: BoundFx = w[4]
	a.hurt(10.0, s[0])
	_step(fx)
	b.hurt(10.0, s[1])
	_step(fx)
	t.check(fx.joiners == [s[0], s[1]] and LawMark.kind_of(s[1]) == &"bound", "a second striker (on the other end) joins")
	a.hurt(10.0, s[2])
	_step(fx)
	t.check(fx.joiners.size() == 2 and LawMark.kind_of(s[2]) == &"" and is_equal_approx((s[2] as Person).health, 100.0),
		"a third striker does not join: two to a cast (and takes nothing)")
	t.check(is_equal_approx(a.health, 70.0) and is_equal_approx((s[1] as Person).health, 80.0),
		"the bond still holds the four: a 70, the second joiner 80 (he joined after the first blow)")
	fx.end_now()
	Breath._done(w[0])


static func _stale_and_stuns(t) -> void:
	var w := _world(5)
	var a: Person = w[1]
	var s: Array = w[3]
	var fx: BoundFx = w[4]
	# An old blow (struck_at long ago) and a new hurt with no source: nobody joins.
	a.hurt(5.0, s[0])
	a.struck_at = -50.0
	a.health = 100.0
	_step(fx)
	a.hurt(10.0, null)
	_step(fx)
	a.stun(2.0)
	_step(fx)
	t.check(fx.joiners.is_empty() and LawMark.kind_of(s[0]) == &"",
		"a stale blow, a hurt with no source and a stun add no one")
	# Control: a fresh blow from the same man joins.
	a.hurt(10.0, s[0])
	_step(fx)
	t.check(fx.joiners == [s[0]], "control: a fresh blow from him joins")
	# A striker who is dead never joins.
	var dead: Person = s[1]
	a.hurt(10.0, dead)
	dead.die(&"test")
	_step(fx)
	t.check(not fx.joiners.has(dead), "a striker who is dead does not join")
	fx.end_now()
	Breath._done(w[0])


static func _fate(t) -> void:
	var w := _world(5)
	var a: Person = w[1]
	var b: Person = w[2]
	var s: Array = w[3]
	var fx: BoundFx = w[4]
	var sol: Person = s[0]
	a.hurt(10.0, sol)
	_step(fx)
	# A joiner who goes indoors still shares fate.
	sol.inside = true
	b.hurt(10.0, null)
	_step(fx)
	t.check(is_equal_approx(sol.health, 80.0) and is_equal_approx(a.health, 80.0),
		"a joiner indoors still takes what befalls the bound (soldier %.1f)" % sol.health)
	sol.hurt(15.0, null)
	_step(fx)
	t.check(is_equal_approx(a.health, 65.0) and is_equal_approx(b.health, 65.0), "and what befalls him reaches them")
	# One dies: all die.
	sol.die(&"test")
	_step(fx)
	t.check(not a.is_alive() and not b.is_alive() and a._kind == &"bound" and not fx.linked,
		"the joiner dies: a and b die too (kind bound) and the bond is over")
	fx.end_now()
	Breath._done(w[0])
	# Control: a dies, the joiner dies.
	var w2 := _world(5)
	var fx2: BoundFx = w2[4]
	(w2[1] as Person).hurt(10.0, w2[3][0])
	_step(fx2)
	(w2[1] as Person).die(&"test")
	_step(fx2)
	t.check(not (w2[3][0] as Person).is_alive() and not (w2[2] as Person).is_alive(), "control: a dies, the joiner and b die")
	fx2.end_now()
	Breath._done(w2[0])


## Seizures add no joiner without seizer_of (Ruling C5); the held one is held as before.
static func _seizure(t) -> void:
	t.check(not MissionDirector.new().has_method("seizer_of"), "the director has no seizer_of (Ruling C5)")
	var w := _world(5)
	var a: Person = w[1]
	var fx: BoundFx = w[4]
	a.chained = true
	_step(fx, 0.5)
	t.check(fx.joiners.is_empty() and (w[2] as Person).pace_hold() == 0.0, "a seizure adds no joiner; the other is still held")
	fx.end_now()
	Breath._done(w[0])


static func _teardown(t) -> void:
	var w := _world(5)
	var a: Person = w[1]
	var s: Array = w[3]
	var fx: BoundFx = w[4]
	var ctx: FxContext = w[0][5]
	(t.root as Node).add_child(ctx.overhead)
	await t.process_frame
	a.hurt(10.0, s[0])
	_step(fx)
	LawMark.set_law(s[0], LawMark.NOBODY, 20.0, 99)
	t.check(fx.joiners == [s[0]] and (s[0] as Person).law.laws.has(fx.get_instance_id()),
		"teardown control: the joiner is bound before the cast ends")
	fx.end_now()
	t.check(not (s[0] as Person).law.laws.has(fx.get_instance_id()) and (s[0] as Person).law.laws.has(99)
		and LawMark.kind_of(a) == &"" and not fx.linked, "end_now lifts the joiner's mark too; another owner's law stays")
	fx.free()
	# A freed node (in the tree) unlinks everyone.
	var w2 := _world(5)
	var ctx2: FxContext = w2[0][5]
	var fx2: BoundFx = w2[4]
	(t.root as Node).add_child(ctx2.overhead)
	await t.process_frame
	(w2[1] as Person).hurt(10.0, w2[3][1])
	_step(fx2)
	t.check((w2[3][1] as Person).law.laws.has(fx2.get_instance_id()), "teardown control: a second cast's joiner holds")
	var id := fx2.get_instance_id()
	fx2.free()
	t.check(not is_instance_valid(fx2) and LawMark.kind_of(w2[3][1]) == &"" and LawMark.kind_of(w2[1]) == &"",
		"a freed cast lifts every mark, the joiner's too")
	(t.root as Node).remove_child(ctx2.overhead)
	(t.root as Node).remove_child(ctx.overhead)
	Breath._done(w2[0])
	Breath._done(w[0])


static func _overlap(t) -> void:
	var w := _world(5)
	var made: Array = w[0]
	var a: Person = w[1]
	var s: Array = w[3]
	var f1: BoundFx = w[4]
	var crowd: Crowd = made[0]
	var c: Person = crowd.citizens[2]
	var d: Person = crowd.citizens[3]
	c.ground_pos = a.ground_pos + Vector2(0.0, -4.0)
	d.ground_pos = c.ground_pos + Vector2(2.0, 0.0)
	c.health = 100.0
	d.health = 100.0
	var f2 := FxTimeline.cast(load(PATH), made[5], c.ground_pos, {"to": d.ground_pos, "level": 5}) as BoundFx
	a.hurt(10.0, s[0])
	c.hurt(10.0, s[1])
	Breath._run([f1, f2], DT)
	t.check(f1.joiners == [s[0]] and f2.joiners == [s[1]] and (s[0] as Person).law.laws.has(f1.get_instance_id())
		and (s[1] as Person).law.laws.has(f2.get_instance_id()), "overlap: each cast has its own joiner")
	f1.end_now()
	t.check(LawMark.kind_of(s[0]) == &"" and LawMark.kind_of(s[1]) == &"bound" and LawMark.kind_of(c) == &"bound",
		"ending the first lifts only its own marks")
	f2.end_now()
	t.check(LawMark.kind_of(s[1]) == &"" and LawMark.kind_of(c) == &"", "and the second its own")
	f1.free()
	f2.free()
	Breath._done(made)
