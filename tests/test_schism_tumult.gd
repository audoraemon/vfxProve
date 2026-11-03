extends RefCounted
## Divine Schism's fifth mode, TUMULT: each person the wave reaches is struck mad (fights anyone), frozen where they stand
## or panicked (runs wildly, new target every few seconds) for the rest of the 25 s; caregivers are never mad; the
## roll is ctx.rng's, so a seed gives the same states; at the end every survivor is released.

const PATH := "res://src/fx/dominion/divine_schism.gd"
const S = preload("res://tests/test_schism.gd")


## Park `list` round `at` on a spiral out to `reach` (nearest first in list order), calm, on no side.
static func _place(list: Array, at: Vector2, reach: float) -> void:
	var n := maxi(list.size(), 1)
	for i in list.size():
		var p: Person = list[i]
		p.ground_pos = at + Vector2.RIGHT.rotated(float(i) * 2.4) * (0.5 + (reach - 0.5) * sqrt(float(i) / float(n)))
		p.side = 0
		p.inside = false
		p.clear_badge()
		p.stop_fighting()
		p.release_compulsion()
		if not p.soldier:
			p.mind = Person.Mind.CALM


static func _everyone(crowd: Crowd) -> Array:
	var out: Array = []
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p) and p.is_alive():
			out.append(p)
	return out


static func _cast(ctx: FxContext, at: Vector2, seed_: int) -> DivineSchismFx:
	ctx.rng.seed = seed_
	return FxTimeline.cast(load(PATH), ctx, at, {"mode": "tumult"})


static func _states_of(fx: DivineSchismFx, list: Array) -> Array:
	var out: Array = []
	for p in list:
		out.append(fx.states.get(p, -1))
	return out


static func run(t) -> void:
	var book := PowerBook.get_power("schism")
	var modes: Array = book.modes
	t.check(modes.size() == 5 and modes[4].key == "tumult" and modes[4].name == "TUMULT",
		"Divine Schism has a fifth mode, TUMULT")
	t.check(DivineSchismFx.MAD == 0 and DivineSchismFx.FROZEN == 1 and DivineSchismFx.PANIC == 2
		and DivineSchismFx.PANIC_REPICK == Vector2(3.0, 4.0), "the three states and the panic re-pick span")

	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var everyone := _everyone(crowd)
	var fighters: Array = []
	var carers: Array = []
	for p in everyone:
		if DivineSchismFx.fights(p):
			fighters.append(p)
		else:
			carers.append(p)
	t.check(carers.size() >= 3 and fighters.size() >= 100, "the test town has caregivers and fighters (%d, %d)" % [carers.size(), fighters.size()])

	# A small crowd: 30 in the region, one beyond it, one indoors.
	S._scatter(crowd)
	var group: Array = fighters.slice(0, 30)
	_place(group, at, 10.0)
	var far: Person = fighters[40]
	far.ground_pos = at + Vector2(DivineSchismFx.REGION + 2.0, 0.0)
	var indoors: Person = fighters[41]
	indoors.ground_pos = at + Vector2(1.0, 1.0)
	indoors.inside = true
	var fx := _cast(ctx, at, 11)
	t.check(fx.mode == "tumult" and fx.states.is_empty(), "nobody is struck as it is cast")
	fx._process(DivineSchismFx.T_BREAK - 0.1)
	t.check(fx.states.is_empty() and group[0].mind != Person.Mind.FIGHT, "while the sigil strains nobody is struck")
	fx._process(1.1)
	var struck := 0
	var counted := [0, 0, 0]
	var one_each := true
	for p in group:
		if fx.states.has(p):
			struck += 1
			counted[fx.states[p]] += 1
		else:
			one_each = false
	t.check(one_each and struck == 30 and fx.states.size() == 30, "every one in reach has exactly one state (%d of 30, %d recorded)" % [struck, fx.states.size()])
	t.check(fx.counts_tumult[0] + fx.counts_tumult[1] + fx.counts_tumult[2] == 30 and fx.counts_tumult == counted,
		"the three counts add up to the number reached (%s)" % [fx.counts_tumult])
	t.check(not fx.states.has(far) and far.mind != Person.Mind.FIGHT and far.mind != Person.Mind.COMPELLED
		and not fx.states.has(indoors) and indoors.mind != Person.Mind.FIGHT and indoors.mind != Person.Mind.COMPELLED,
		"beyond the region and indoors are untouched")

	# What each state does.
	var mad: Array = []
	var frozen: Array = []
	var panic: Array = []
	for p in group:
		match fx.states[p]:
			DivineSchismFx.MAD: mad.append(p)
			DivineSchismFx.FROZEN: frozen.append(p)
			DivineSchismFx.PANIC: panic.append(p)
	t.check(not mad.is_empty() and not frozen.is_empty() and not panic.is_empty(), "all three states turn up in 30 (%d/%d/%d)" % [mad.size(), frozen.size(), panic.size()])
	var all_mad := true
	for p in mad:
		all_mad = all_mad and p.mind == Person.Mind.FIGHT and p._fight_rule == Person.FightRule.ANYONE and p.badge_left > 0.0
	t.check(all_mad, "the mad fight anyone, wearing their mark")
	var spots := {}
	var all_frozen := true
	for p in frozen:
		spots[p] = p.ground_pos
		all_frozen = all_frozen and p.mind == Person.Mind.COMPELLED and p.anchor.is_equal_approx(p.ground_pos) \
			and p.compel_will >= Person.WILL_ABSOLUTE and not p.is_running() and p.badge_left > 0.0
	t.check(all_frozen, "the frozen are held where they stand")
	var goals := {}
	var all_panic := true
	for p in panic:
		goals[p] = p.anchor
		all_panic = all_panic and p.mind == Person.Mind.COMPELLED and p.is_running() and p.compel_will >= Person.WILL_ABSOLUTE \
			and p.anchor.distance_to(at) <= DivineSchismFx.REGION + 1.0 and p.badge_left > 0.0
	t.check(all_panic, "the panicked run, held by a will, to a point inside the region")
	for k in 30:
		for p in frozen:
			p.tick(0.1)
	var stayed := true
	for p in frozen:
		stayed = stayed and p.ground_pos.distance_to(spots[p]) < 1.0 and p.mind == Person.Mind.COMPELLED
	t.check(stayed, "and they do not move over 3 s")
	# One reaches its point early: it picks the next at once instead of standing until the re-pick.
	var runner: Person = panic[0]
	var reached: Vector2 = runner.anchor
	runner.ground_pos = reached
	fx._process(0.05)
	t.check(runner.anchor != reached and runner.mind == Person.Mind.COMPELLED and runner.is_running(),
		"a panicked one that reaches its point runs on to a new one at once")
	goals[runner] = runner.anchor
	fx._process(DivineSchismFx.PANIC_REPICK.y + 0.2)
	var repicked := true
	for p in panic:
		repicked = repicked and p.anchor != goals[p] and p.mind == Person.Mind.COMPELLED and p.is_running() \
			and p.anchor.distance_to(at) <= DivineSchismFx.REGION + 1.0
	t.check(repicked, "the panicked get a new target after 4 s and keep running")
	# One dies; the end lifts the rest and leaves the dead dead.
	var victim: Person = mad[0]
	victim.state = DummyEnemy.State.DEAD
	fx._process(DivineSchismFx.DURATION + 1.0)
	var released := true
	for p in group:
		if p == victim:
			continue
		released = released and p.mind != Person.Mind.FIGHT and p.mind != Person.Mind.COMPELLED and p.badge_left == 0.0
	t.check(released and victim.state == DummyEnemy.State.DEAD, "after its time every survivor is released, and the dead stay dead")
	fx.free()

	# Determinism: the same seed, the same states for the same people.
	S._scatter(crowd)
	group = fighters.slice(50, 80) + carers.slice(0, 3)
	_place(group, at, 10.0)
	fx = _cast(ctx, at, 77)
	fx._process(DivineSchismFx.T_BREAK + 1.0)
	var first := _states_of(fx, group)
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()
	_place(group, at, 10.0)
	fx = _cast(ctx, at, 77)
	fx._process(DivineSchismFx.T_BREAK + 1.0)
	var second := _states_of(fx, group)
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()
	_place(group, at, 10.0)
	fx = _cast(ctx, at, 78)
	fx._process(DivineSchismFx.T_BREAK + 1.0)
	var third := _states_of(fx, group)
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()
	t.check(first == second and not first.has(-1) and first != third, "the same seed gives the same states, another seed other ones")

	# A caregiver is never mad, over several seeds; it is frozen or panicked.
	var never_mad := true
	var carer_states := [0, 0, 0]
	for sd in 8:
		S._scatter(crowd)
		_place(carers, at, 6.0)
		fx = _cast(ctx, at, 100 + sd)
		fx._process(DivineSchismFx.T_BREAK + 1.0)
		for p in carers:
			var s: int = fx.states.get(p, -1)
			if s < 0:
				never_mad = false
			else:
				carer_states[s] += 1
			if s == DivineSchismFx.MAD or p.mind == Person.Mind.FIGHT:
				never_mad = false
		fx._process(DivineSchismFx.DURATION + 1.0)
		fx.free()
	t.check(never_mad and carer_states[1] > 0 and carer_states[2] > 0, "a caregiver is never mad, only frozen or panicked (%s)" % [carer_states])

	# A big sample: about 40 / 30 / 30, and no more than MAX_FIGHTERS are taken, the nearest first.
	S._scatter(crowd)
	var many := _everyone(crowd)
	_place(many, at, DivineSchismFx.REGION - 1.0)
	fx = _cast(ctx, at, 5)
	fx._process(DivineSchismFx.T_BREAK + 1.0)
	var taken := mini(many.size(), DivineSchismFx.MAX_FIGHTERS)
	t.check(fx.states.size() == taken, "no more than MAX_FIGHTERS are struck (%d of %d, cap %d)" % [fx.states.size(), many.size(), DivineSchismFx.MAX_FIGHTERS])
	var nearest: Array = many.duplicate()
	nearest.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	var cut_ok := true
	for i in nearest.size():
		cut_ok = cut_ok and (fx.states.has(nearest[i]) == (i < taken))
	t.check(cut_ok, "the ones past the cap, the farthest, are left alone")
	var rolled := [0, 0, 0]
	var carers_in := 0
	for p in fx.states:
		rolled[fx.states[p]] += 1
		if not DivineSchismFx.fights(p):
			carers_in += 1
	var n := float(fx.states.size())
	t.check(float(rolled[0]) / n > 0.25 and float(rolled[0]) / n < 0.55 and float(rolled[1]) / n > 0.15 and float(rolled[1]) / n < 0.45
		and float(rolled[2]) / n > 0.15 and float(rolled[2]) / n < 0.45,
		"roughly 40 / 30 / 30 (%s of %d, %d of them caregivers)" % [rolled, fx.states.size(), carers_in])
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()
	S._done(made)
