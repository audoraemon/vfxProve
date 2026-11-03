extends RefCounted
## Will-o'-Wisp's second mode, ENTHRALL: everyone near the light walks to a ring spot and stands still for 30 s (calm, panicked or
## fleeing alike; a charge only within its lure reach; no fighters), newcomers join every 0.5 s, the end lifts it. LURE (and a cast with
## no mode) is today's wisp. And the per-mode cooldown it brought: a mode row's "cooldown" is the slot's when cast in that mode.

const PATH := "res://src/fx/control/will_o_wisp.gd"
const S = preload("res://tests/test_schism.gd")


static func _cast(ctx: FxContext, at: Vector2, extra := {}) -> WillOWisp:
	return FxTimeline.cast(load(PATH), ctx, at, extra)


## Park `list` round `at` on a spiral out to `reach`, calm, in the open, on no side.
static func _place(list: Array, at: Vector2, reach: float) -> void:
	var n := maxi(list.size(), 1)
	for i in list.size():
		var p: Person = list[i]
		p.ground_pos = at + Vector2.RIGHT.rotated(float(i) * 2.4) * (0.5 + (reach - 0.5) * sqrt(float(i) / float(n)))
		p.side = 0
		p.inside = false
		p.release_compulsion()
		p.stop_fighting()
		p.answers_lure = false
		p.hurrying = false
		if not p.soldier:
			p.mind = Person.Mind.CALM


## `list` as a skip Dictionary.
static func spots_of(list: Array) -> Dictionary:
	var out := {}
	for p in list:
		out[p] = true
	return out


static func _key(v: Vector2) -> String:
	return "%.2f,%.2f" % [v.x, v.y]


static func run(t) -> void:
	_modes(t)
	_cooldowns(t)
	_enthrall(t)
	_lure(t)


static func _modes(t) -> void:
	var book := PowerBook.get_power("wisp")
	var modes: Array = book.get("modes", [])
	t.check(modes.size() == 2 and modes[0].key == "lure" and modes[0].name == "LURE" and not modes[0].has("cooldown")
		and modes[1].key == "enthrall" and modes[1].name == "ENTHRALL" and is_equal_approx(float(modes[1].area.r), 4.0)
		and is_equal_approx(float(modes[1].cooldown), 75.0), "the wisp has LURE first and ENTHRALL (r 4, cooldown 75)")
	t.check(WillOWisp.ENTHRALL_R == 4.0 and WillOWisp.ENTHRALL_TIME == 30.0 and WillOWisp.ENTHRALL_SCAN == 0.5
		and WillOWisp.LURE_MAX == 25 and WillOWisp.LURE_REACH == 6.0 and WillOWisp.WISP_TIME == 12.0,
		"the ENTHRALL numbers, the LURE ones unchanged")
	t.check(is_equal_approx(PowerBook.mode_cooldown("wisp", "enthrall"), 75.0) and PowerBook.mode_cooldown("wisp", "lure") < 0.0
		and PowerBook.mode_cooldown("wisp", "") < 0.0 and PowerBook.mode_cooldown("doom", "x") < 0.0,
		"only the ENTHRALL mode carries a cooldown")


static func _cooldowns(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["wisp", "belllies", "smite", "doom"]), made[5], made[1], made[3], crowd, crowd._town)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var g := Vector2(0.0, 8.0)
	rules.cast(0, g, {"mode": "enthrall"})
	t.check(is_equal_approx(rules.cooldown_left(0), 75.0) and is_equal_approx(rules.cooldown_of(0), 75.0),
		"casting ENTHRALL sets the slot cooldown to 75")
	rules.advance(10.0)
	t.check(is_equal_approx(rules.cooldown_left(0), 65.0) and is_equal_approx(rules.cooldown_of(0), 75.0), "and it counts down from 75")
	rules._cooldowns[0] = 0.0
	rules.cast(0, g, {"mode": "lure"})
	t.check(is_equal_approx(rules.cooldown_left(0), 30.0) and is_equal_approx(rules.cooldown_of(0), 30.0), "LURE: 30")
	rules._cooldowns[0] = 0.0
	rules.cast(0, g)
	t.check(is_equal_approx(rules.cooldown_left(0), 30.0) and is_equal_approx(rules.cooldown_of(0), 30.0), "no mode: 30")
	rules.cast(1, g, {"mode": "guard"})
	t.check(is_equal_approx(rules.cooldown_left(1), 60.0), "another power with modes and no mode cooldown keeps its own")
	rules.levels["smite"] = 3
	rules.cast(2, g)
	t.check(is_equal_approx(rules.cooldown_left(2), 9.0), "a Ruin power at level 3 still gets its level cooldown")
	rules.cast(3, g)
	t.check(is_equal_approx(rules.cooldown_left(3), 10.0), "and a plain power its own")
	S._done(made)


static func _enthrall(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	S._scatter(crowd)
	var folk: Array = []
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive():
			folk.append(p)
	var group: Array = folk.slice(0, 40)
	_place(group, at, WillOWisp.ENTHRALL_R - 0.3)
	for i in group.size():
		var p: Person = group[i]
		p.mind = [Person.Mind.CALM, Person.Mind.PANIC, Person.Mind.FLEE][i % 3]
	var far: Person = folk[40]
	far.ground_pos = at + Vector2(5.0, 0.0)
	var fighter: Person = folk[41]
	fighter.ground_pos = at + Vector2(1.0, 1.0)
	fighter.mind = Person.Mind.FIGHT
	var indoors: Person = folk[42]
	indoors.ground_pos = at + Vector2(1.0, -1.0)
	indoors.inside = true
	var charge_far: Person = folk[43]
	charge_far.ground_pos = at + Vector2(3.5, 0.0)
	charge_far.answers_lure = true
	var charge_near: Person = folk[44]
	charge_near.ground_pos = at + Vector2(0.0, 2.5)
	charge_near.answers_lure = true
	var walker: Person = folk[45]
	walker.ground_pos = at + Vector2(0.0, -8.0)
	var victim: Person = group[7]
	var posted: Person = null
	var hurried: Person = null
	for s in crowd.soldiers:
		if not is_instance_valid(s) or not s.is_alive():
			continue
		if posted == null:
			posted = s
		elif hurried == null:
			hurried = s
	posted.ground_pos = at + Vector2(-1.0, 0.5)
	posted.mind = Person.Mind.POST
	hurried.ground_pos = at + Vector2(-1.5, 0.5)
	hurried.mind = Person.Mind.POST
	hurried.hurrying = true

	var fx := _cast(ctx, at, {"mode": "enthrall"})
	t.check(is_equal_approx(fx.duration, WillOWisp.ENTHRALL_TIME), "ENTHRALL burns 30 s")
	var all_held := true
	var spots := {}
	for p in group:
		all_held = all_held and p.mind == Person.Mind.COMPELLED and p.compel_will >= Person.WILL_ABSOLUTE
		spots[_key(p.anchor)] = true
	t.check(all_held, "all 40 near the light - calm, panicked, fleeing - are compelled")
	t.check(spots.size() == 40, "each to its own spot (%d distinct)" % spots.size())
	var ringed := true
	for p in group:
		ringed = ringed and p.anchor.distance_to(at) > 0.3
	t.check(ringed, "on rings round the light")
	t.check(far.mind == Person.Mind.CALM, "one at 5 is not taken")
	t.check(fighter.mind == Person.Mind.FIGHT, "a fighter is not taken")
	t.check(indoors.mind != Person.Mind.COMPELLED, "nor one indoors")
	t.check(charge_far.mind != Person.Mind.COMPELLED, "a mission charge at 3.5 (beyond CHARGE_LURE_R) is not taken")
	t.check(charge_near.mind == Person.Mind.COMPELLED, "one at 2.5 is")
	t.check(posted.mind == Person.Mind.COMPELLED and hurried.mind != Person.Mind.COMPELLED,
		"a soldier at his post joins, a hurrying one does not")
	var preview := WillOWisp.enthralled(field, at)
	t.check(far not in preview and fighter not in preview and indoors not in preview and charge_far not in preview and charge_near in preview
		and hurried not in preview and WillOWisp.enthralled(field, at, spots_of(group)).size() <= 3, "the preview lists who it would take (%d)" % preview.size())

	# They walk there and stand still.
	for k in 230:
		for p in group:
			p.tick(0.1)
	var at_spot := 0
	var before := {}
	for p in group:
		before[p] = p.ground_pos
		if p.ground_pos.distance_to(p.anchor) < 0.6:
			at_spot += 1
	t.check(at_spot >= 36, "after 23 s they stand at their spots (%d of 40)" % at_spot)
	for k in 30:
		for p in group:
			p.tick(0.1)
	var still := true
	for p in group:
		still = still and p.ground_pos.distance_to(before[p]) < 0.5 and p.mind == Person.Mind.COMPELLED
	t.check(still, "and stand still")

	# Newcomers every 0.5 s: one outside the circle is left alone, then walks in to 3 and joins at the next look.
	fx._process(0.5)
	t.check(walker.mind != Person.Mind.COMPELLED, "one outside the circle is not taken")
	walker.ground_pos = at + Vector2(0.0, -3.0)
	fx._process(0.2)
	t.check(walker.mind != Person.Mind.COMPELLED, "not between two looks")
	fx._process(0.4)
	t.check(walker.mind == Person.Mind.COMPELLED and walker.anchor.distance_to(at) > 0.3, "a person walking in to 3 joins at the next look")
	var dup := {}
	for p in group + [walker, charge_near, posted]:
		dup[_key(p.anchor)] = true
	t.check(dup.size() == 43, "on a spot of its own (%d distinct of 43)" % dup.size())
	t.check(fx.busy >= 0.0 and fx.busy < 5.0, "it locks the other slots only a moment, like the wisp")

	# The end lifts it; the dead stay dead.
	victim.state = DummyEnemy.State.DEAD
	fx._process(WillOWisp.ENTHRALL_TIME)
	var released := true
	for p in group:
		if p != victim:
			released = released and p.mind != Person.Mind.COMPELLED
	t.check(released and walker.mind != Person.Mind.COMPELLED and charge_near.mind != Person.Mind.COMPELLED
		and posted.mind != Person.Mind.COMPELLED and victim.state == DummyEnemy.State.DEAD,
		"at 30 s every one still held is released, and the dead stay dead")
	t.check(fx.finished, "and the light goes out")
	fx.free()
	S._done(made)


static func _lure(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	S._scatter(crowd)
	var group: Array = crowd.citizens.slice(0, 40)
	for mode in ["", "lure"]:
		_place(group, at, 5.0)
		var fx := _cast(ctx, at, {} if mode == "" else {"mode": mode})
		var lured := 0
		var held := 0
		for p in group:
			if p.mind == Person.Mind.OBSERVE:
				lured += 1
			if p.mind == Person.Mind.COMPELLED:
				held += 1
		t.check(is_equal_approx(fx.duration, WillOWisp.WISP_TIME) and lured == WillOWisp.LURE_MAX and held == 0,
			"%s: a plain wisp - 12 s, %d lured, none compelled" % ["no mode" if mode == "" else mode, lured])
		fx.free()
		for p in group:
			p.mind = Person.Mind.CALM
	S._done(made)
