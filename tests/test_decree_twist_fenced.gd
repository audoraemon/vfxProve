extends RefCounted
## fenced level 5 twist (Death and Decree ability levels, Task 19): Third Clause. Once the law holds, a rule word from the order
## wheel (follow_up(at, {"order": word}), Rules.recast) adds that rule to the live LawZone for the time it has left: one clause only,
## a rule in force or a fourth refused; the orders are the three rule words not in force. It lifts with the fence (end_now and a freed
## node too), and one cast's clause never touches another's law. Level 4 takes none.

const F := preload("res://tests/test_decree_fenced.gd")
const DT := 0.1
const ALL := ["run", "arms", "doors", "sight", "leave"]
const W := FencedFx.ORDER_WORDS


static func _world() -> Array:
	var made: Array = F._setup()
	var crowd: Crowd = made[0]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.shelters = null
		i += 1
	return made


static func _at(made: Array) -> Vector2:
	return (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())


static func _cast(made: Array, level: int, mode := "run_arms", at := Vector2.INF) -> FencedFx:
	var where := _at(made) if at == Vector2.INF else at
	return FxTimeline.cast(load(F.PATH), made[5], where, {"level": level, "mode": mode}) as FencedFx


static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in int(roundf(seconds / DT)):
		fx._process(DT)


static func _landed(made: Array, level: int, mode := "run_arms", at := Vector2.INF) -> FencedFx:
	var fx := _cast(made, level, mode, at)
	_run(fx, FencedFx.T_LAND + DT)
	return fx


static func _end(fx: FencedFx) -> void:
	fx.end_now()
	fx.free()


static func run(t) -> void:
	_level4_and_control(t)
	_orders(t)
	_words(t)
	_clause(t)
	_refusals(t)
	_rules_route(t)
	await _teardown(t)
	_overlap(t)


static func _level4_and_control(t) -> void:
	var made := _world()
	var f4 := _landed(made, 4)
	t.check(not f4.can_follow_up() and not f4.follow_up(Vector2.ZERO, {"order": W["doors"]}) and f4.third == "" and f4.sigil == null
		and f4.follow_up_subject() == null and f4.law.kinds == [LawZone.NO_RUNNING, LawZone.NO_ARMS],
		"fenced level 4: no clause, no sigil, the law keeps its two")
	_end(f4)
	# Control: the same word at level 5 is taken.
	var f5 := _landed(made, 5)
	t.check(f5.can_follow_up() and f5.follow_up(Vector2.ZERO, {"order": W["doors"]}) and f5.third == "doors"
		and f5.law.kinds == [LawZone.NO_RUNNING, LawZone.NO_ARMS, LawZone.NO_DOORS],
		"fenced level 5: the same word adds NO DOORS (control)")
	_end(f5)
	F._done(made)


## The wheel's hooks: the wheel, the sigil subject, and the orders -- never a rule in force.
static func _orders(t) -> void:
	var made := _world()
	var fx := _cast(made, 5)
	t.check(fx.follow_up_wheel() and fx.sigil is Node2D and fx.follow_up_subject() == fx.sigil and fx.sigil.ground_pos.is_equal_approx(fx.origin),
		"level 5: the wheel opens on a sigil at the fence's centre")
	t.check(not fx.can_follow_up() and not bool(fx.sigil.is_alive()), "before the posts are in: no clause, the sigil is not a subject yet")
	_run(fx, FencedFx.T_LAND + DT)
	t.check(fx.can_follow_up() and bool(fx.sigil.is_alive()), "once the law holds: it takes a clause (control)")
	t.check(fx.follow_up_orders() == [W.doors, W.sight, W.leave], "NO RUNNING + NO ARMS: the orders are no doors, no sight, no exit (%s)" % [fx.follow_up_orders()])
	var never := true
	for m: Dictionary in PowerBook.get_power("fenced").modes:
		var f := _cast(made, 5, String(m.key))
		var orders: Array = f.follow_up_orders()
		never = never and orders.size() == 3
		for w in orders:
			never = never and ALL.has(W.find_key(w)) and not FencedFx.rules_of(String(m.key)).has(W.find_key(w))
		_end(f)
	t.check(never, "in all ten modes: three orders, none of them a rule in force")
	_end(fx)
	F._done(made)


static func _clause(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var at := _at(made)
	var runner: Person = crowd.citizens[0]
	runner.ground_pos = (made[2] as WalkGrid).nearest_walkable(at + Vector2(2.0, 1.0))
	var fx := _landed(made, 5)
	var law := fx.law
	t.check(not crowd.in_law(runner, LawZone.NO_DOORS) and crowd.in_law(runner, LawZone.NO_RUNNING), "before: NO RUNNING holds, NO DOORS does not")
	var left := law.left
	t.check(fx.follow_up(at, {"order": W["doors"]}), "the order doors is taken")
	t.check(law.kinds == [LawZone.NO_RUNNING, LawZone.NO_ARMS, LawZone.NO_DOORS] and fx.third == "doors" and crowd.laws.count(law) == 1,
		"all three hold in the one live law (no second zone)")
	t.check(crowd.in_law(runner, LawZone.NO_DOORS) and crowd.in_law(runner, LawZone.NO_RUNNING) and crowd.in_law(runner, LawZone.NO_ARMS)
		and not crowd.in_law(runner, LawZone.NO_SIGHT) and is_equal_approx(law.left, left),
		"NO RUNNING, NO ARMS and NO DOORS hold on the runner; NO SIGHT does not; the time left is the law's own")
	# The old rules still work after the clause: a runner inside only walks.
	runner.panic(runner.ground_pos + Vector2(1.0, 0.0), 1.0, &"", false)
	_run(fx, DT * 2.0)
	t.check(runner.walk_speed <= Person.WALK_SPEED * runner.pace + 0.001 and not runner.pace_holds.is_empty(), "NO RUNNING keeps holding the runner")
	# A third clause that is NO LEAVING is held by the zone itself.
	var fx2 := _landed(made, 5, "run_arms", at + Vector2(20.0, 0.0))
	var leaver: Person = crowd.citizens[1]
	leaver.ground_pos = fx2.origin + Vector2(7.0, 0.0)
	t.check(fx2.follow_up(fx2.origin, {"order": W["leave"]}) and fx2.law.holds(LawZone.NO_LEAVING), "NO LEAVING is added as a third clause")
	_run(fx2, DT)
	leaver.ground_pos = fx2.origin + Vector2.RIGHT * (fx2.law.radius + 0.5)
	var pushed := leaver.ground_pos.distance_to(fx2.origin)
	_run(fx2, DT)
	t.check(leaver.ground_pos.distance_to(fx2.origin) <= fx2.law.radius + 0.01, "and holds one at the edge (%.2f of %.2f, pushed to %.2f)" % [leaver.ground_pos.distance_to(fx2.origin), fx2.law.radius, pushed])
	_end(fx2)
	_end(fx)
	F._done(made)


## The wheel reads the rules, not commands, and each word takes its own rule.
static func _words(t) -> void:
	var made := _world()
	t.check(W == {"run": "no run", "arms": "no arms", "doors": "no doors", "sight": "no sight", "leave": "no exit"},
		"the wheel's words: NO RUN / NO ARMS / NO DOORS / NO SIGHT / NO EXIT once upper-cased")
	var maps := true
	for r in ALL:
		var mode := "doors_sight" if r == "run" or r == "arms" or r == "leave" else "run_arms"
		var fx := _landed(made, 5, mode)
		maps = maps and fx.follow_up(Vector2.ZERO, {"order": W[r]}) and fx.third == r and fx.law.holds(FencedFx.KINDS[r]) and fx.law.kinds.size() == 3
		_end(fx)
	t.check(maps, "each wheel word adds its own rule (all five, as a third clause)")
	var fx2 := _landed(made, 5, "arms_doors")
	var runner: Person = (made[0] as Crowd).citizens[0]
	runner.ground_pos = (made[2] as WalkGrid).nearest_walkable(fx2.origin + Vector2(2.0, 1.0))
	runner.panic(runner.ground_pos + Vector2(1.0, 0.0), 1.0, &"", false)
	_run(fx2, DT)
	var free_run := runner.walk_speed > Person.WALK_SPEED * runner.pace + 0.01 and runner.pace_holds.is_empty()
	t.check(fx2.follow_up(Vector2.ZERO, {"order": W.run}), "a late NO RUNNING clause (arms + doors) is taken")
	_run(fx2, DT * 2.0)
	t.check(free_run and runner.walk_speed <= Person.WALK_SPEED * runner.pace + 0.001 and not runner.pace_holds.is_empty(),
		"and holds a runner inside to a walk (he ran before it)")
	_end(fx2)
	F._done(made)


static func _refusals(t) -> void:
	var made := _world()
	var fx := _landed(made, 5)
	# Refused words change nothing.
	var bad := true
	for w in ["run", "arms", "", "nonsense", "walk", W.run, W.arms]:
		bad = bad and not fx.follow_up(Vector2.ZERO, {"order": w})
	t.check(bad and fx.third == "" and fx.law.kinds.size() == 2 and fx.can_follow_up(),
		"a rule already in force, no word and an unknown word are refused and change nothing")
	t.check(not fx.follow_up(Vector2.ZERO, {}) and fx.law.kinds.size() == 2, "a click with no order is refused")
	t.check(fx.follow_up(Vector2.ZERO, {"order": W["sight"]}) and fx.law.kinds.size() == 3, "while a fresh word is taken (control)")
	# A fourth is refused, and the orders have none left to give a rule in force.
	var fourth := false
	for w in ALL:
		fourth = fourth or fx.follow_up(Vector2.ZERO, {"order": W[w]})
	t.check(not fourth and fx.law.kinds.size() == 3 and fx.third == "sight" and not fx.can_follow_up(),
		"a fourth rule is refused: three hold, no more are taken")
	t.check(fx.follow_up_orders() == [W.doors, W.leave], "and the orders never offer a rule in force (%s)" % [fx.follow_up_orders()])
	_end(fx)
	F._done(made)


## The click through a real Rules: recast_made, no cast_made, no new cooldown.
static func _rules_route(t) -> void:
	var made := _world()
	var ctx: FxContext = made[5]
	var at := _at(made)
	var rules := Rules.new().setup(PackedStringArray(["fenced", "smite"]), ctx, made[1], made[3], made[0], made[6])
	rules.levels = {"fenced": 5}
	var casts: Array = []
	var recasts: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): recasts.append([slot, key, p]))
	var fx := rules.cast(0, at, {"mode": "run_arms"}) as FencedFx
	var left := rules.cooldown_left(0)
	t.check(fx != null and casts.size() == 1 and left > 0.0 and not rules.can_recast(0), "Rules.cast starts the cast; before the posts are in no recast")
	_run(fx, FencedFx.T_LAND + 0.4)  # past the busy lock
	t.check(rules.can_recast(0) and not rules.recast(0, at, {"order": W["run"]}) and recasts.is_empty(), "a rule in force is refused through Rules")
	t.check(rules.recast(0, at, {"order": W["doors"]}) and fx.third == "doors" and fx.law.holds(LawZone.NO_DOORS),
		"recast(slot, at, {order: doors}) adds the third clause")
	t.check(recasts == [[0, "fenced", at]] and casts.size() == 1 and rules.cooldown_left(0) <= left and rules.cooldown_left(0) > left - 2.0,
		"it sends recast_made, no second cast_made, and starts no cooldown")
	t.check(not rules.can_recast(0) and not rules.recast(0, at, {"order": W["sight"]}) and recasts.size() == 1, "a second clause is refused through Rules")
	_end(fx)
	rules.free()
	F._done(made)


static func _teardown(t) -> void:
	var made := _world()
	var ctx: FxContext = made[5]
	(t.root as Node).add_child(ctx.overhead)
	await t.process_frame
	var crowd: Crowd = made[0]
	var at := _at(made)
	var who: Person = crowd.citizens[0]
	who.ground_pos = (made[2] as WalkGrid).nearest_walkable(at + Vector2(1.0, 1.0))
	# Control: left alone, the third clause holds on the person inside, and the fence's own lift ends it.
	var f1 := _landed(made, 5)
	f1.follow_up(at, {"order": W["sight"]})
	var law1 := f1.law
	t.check(crowd.in_law(who, LawZone.NO_SIGHT) and crowd.laws.has(law1) and not f1.finished, "teardown control: the third clause holds while the fence stands")
	_run(f1, 38.0)  # to the lift (level 5: 38 s of law)
	t.check(not crowd.laws.has(law1) and not law1.alive() and not crowd.in_law(who, LawZone.NO_SIGHT) and not f1.can_follow_up()
		and not f1.follow_up(at, {"order": W["leave"]}), "the third clause lifts with the fence")
	_run(f1, 1.0)
	t.check(f1.finished and not crowd.in_law(who, LawZone.NO_RUNNING), "and the fence's own end leaves no rule")
	f1.free()
	# end_now() lifts the clause.
	var f2 := _landed(made, 5)
	f2.follow_up(at, {"order": W["doors"]})
	var law2 := f2.law
	var s2 := f2.sigil
	t.check(crowd.in_law(who, LawZone.NO_DOORS), "end_now control: NO DOORS holds before")
	f2.end_now()
	t.check(f2.finished and not law2.alive() and not crowd.laws.has(law2) and not crowd.in_law(who, LawZone.NO_DOORS), "end_now lifts the third clause with the law")
	f2.free()
	await t.process_frame
	t.check(not is_instance_valid(s2), "and the sigil node is freed")
	# A freed cast lifts it too (_exit_tree).
	var f3 := _landed(made, 5)
	f3.follow_up(at, {"order": W["leave"]})
	var law3 := f3.law
	var s3 := f3.sigil
	t.check(crowd.in_law(who, LawZone.NO_LEAVING), "freed-cast control: NO LEAVING holds before")
	f3.free()
	await t.process_frame
	t.check(not law3.alive() and not crowd.laws.has(law3) and not crowd.in_law(who, LawZone.NO_LEAVING) and not is_instance_valid(s3),
		"a freed cast lifts the law, the third clause and the sigil")
	(t.root as Node).remove_child(ctx.overhead)
	F._done(made)


## Two level-5 fences: a clause on one never reaches the other, and ending one leaves the other's law.
static func _overlap(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var at := _at(made)
	var a := _landed(made, 5, "run_arms", at)
	var b := _landed(made, 5, "run_arms", at)
	a.follow_up(at, {"order": W["doors"]})
	t.check(a.law != b.law and a.law.holds(LawZone.NO_DOORS) and not b.law.holds(LawZone.NO_DOORS) and b.can_follow_up(),
		"two casts: a clause on one is not on the other")
	var who: Person = crowd.citizens[0]
	who.ground_pos = (made[2] as WalkGrid).nearest_walkable(at + Vector2(1.0, 1.0))
	b.follow_up(at, {"order": W["leave"]})
	a.end_now()
	t.check(not a.law.alive() and b.law.alive() and b.law.holds(LawZone.NO_LEAVING) and crowd.in_law(who, LawZone.NO_LEAVING)
		and not crowd.in_law(who, LawZone.NO_DOORS) and is_instance_valid(b.sigil),
		"ending one leaves the other's law, its clause and its sigil")
	_end(b)
	a.free()
	F._done(made)
