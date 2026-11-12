extends RefCounted
## Divine Schism level 5 twist, Turn the Tide (Dominion ability levels, D18): while the sides fight, a click on a fighter moves it to the other side,
## up to ten times in all. Not in TUMULT (no sides); not before the busy lock ends nor after the schism lifts; level 4 has none.

const PATH := "res://src/fx/dominion/divine_schism.gd"
const S = preload("res://tests/test_schism.gd")


static func run(t) -> void:
	_faction(t)
	_ten(t)
	_purge(t)
	_closed(t)
	_wiring(t)


static func _cast(ctx: FxContext, at: Vector2, extra: Dictionary) -> DivineSchismFx:
	return FxTimeline.cast(load(PATH), ctx, at, extra)


## `n` citizens who fight, parked on a line 1.6 apart from `at` (everyone else far off in a corner).
static func _line(crowd: Crowd, at: Vector2, n: int) -> Array:
	S._scatter(crowd)
	var out: Array = []
	var k := 0
	while out.size() < n and k < crowd.citizens.size():
		var p: Person = crowd.citizens[k]
		k += 1
		if DivineSchismFx.fights(p):
			p.ground_pos = at + Vector2(1.6 * float(out.size()) - 8.0, 0.0)
			out.append(p)
	return out


static func _faction(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var line := _line(crowd, at, 3)
	var a: Person = line[0]
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = at + Vector2(-8.0, 3.0)
	var fx := _cast(ctx, at, {"mode": "faction", "level": 5})
	fx._process(DivineSchismFx.T_BREAK + 0.5)
	t.check(not fx.can_follow_up() and not fx.follow_up(a.ground_pos, {}), "before T_BREAK + 1.0 (the busy lock) the click is not taken")
	fx._process(0.7)
	t.check(a.side == 1 and guard.side == 2 and fx.can_follow_up(), "after the wave the sides are laid and the schism takes orders")
	var c1: int = fx.counts[1]
	var c2: int = fx.counts[2]
	t.check(not fx.follow_up(a.ground_pos + Vector2(0.0, 1.5), {}) and fx.turns == 0, "a click 1.5 from any member is false")
	t.check(fx.follow_up(a.ground_pos + Vector2(0.3, 0.0), {}), "a click on a citizen (side 1) is taken")
	t.check(a.side == 2 and fx.counts[1] == c1 - 1 and fx.counts[2] == c2 + 1 and fx.turns == 1, "it is on side 2, the counts moved by one each way")
	t.check(a.badge_color == DivineSchismFx.CRIMSON and a.mind == Person.Mind.FIGHT and a._fight_rule == Person.FightRule.OTHER_SIDE,
		"it wears the crimson badge and fights the other side")
	t.check(a in fx.members and fx.members.count(a) == 1, "and is still a member once")
	# A soldier (side 2) goes the other way.
	t.check(fx.follow_up(guard.ground_pos, {}) and guard.side == 1 and guard.badge_color == DivineSchismFx.GOLD and guard.mind == Person.Mind.FIGHT,
		"a soldier turned goes over to side 1")
	fx._process(DivineSchismFx.T_BREAK + fx.lv_duration - fx.t + 0.1)
	t.check(not fx.can_follow_up() and not fx.follow_up(a.ground_pos, {}), "after the schism lifts the click is false")
	fx.free()
	S._done(made)


static func _ten(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var line := _line(crowd, at, 12)
	var fx := _cast(ctx, at, {"mode": "faction", "level": 5})
	fx._process(DivineSchismFx.T_BREAK + 1.1)
	var ok := 0
	for i in 10:
		ok += 1 if fx.follow_up(line[i].ground_pos, {}) else 0
	t.check(ok == 10 and fx.turns == 10 and not fx.can_follow_up(), "ten turns are taken")
	t.check(not fx.follow_up(line[10].ground_pos, {}) and line[10].side == 1 and fx.turns == 10, "the eleventh is not")
	fx.free()
	S._done(made)


static func _purge(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var line := _line(crowd, at, 2)
	var condemned: Person = line[0]
	var hunter: Person = line[1]
	condemned.ground_pos = at
	hunter.ground_pos = at + Vector2(4.0, 0.0)
	var fx := _cast(ctx, at, {"mode": "purge", "level": 5})
	fx._process(DivineSchismFx.T_BREAK + 1.1)
	t.check(condemned.side == 2 and condemned.mind != Person.Mind.FIGHT and hunter.side == 1 and hunter.mind == Person.Mind.FIGHT, "PURGE: the condemned runs, the hunter fights")
	t.check(fx.follow_up(condemned.ground_pos, {}) and condemned.side == 1 and condemned.mind == Person.Mind.FIGHT, "a turned condemned citizen fights")
	t.check(fx.follow_up(hunter.ground_pos, {}) and hunter.side == 2 and hunter.mind != Person.Mind.FIGHT, "a turned hunter citizen runs")
	fx.free()
	S._done(made)


static func _closed(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var line := _line(crowd, at, 2)
	var fx := _cast(ctx, at, {"mode": "tumult", "level": 5})
	fx._process(DivineSchismFx.T_BREAK + 1.1)
	t.check(not fx.can_follow_up() and not fx.follow_up(line[0].ground_pos, {}), "TUMULT: no follow-up (there are no sides)")
	fx.free()
	var fx4 := _cast(ctx, at, {"mode": "faction", "level": 4})
	fx4._process(DivineSchismFx.T_BREAK + 1.1)
	t.check(line[0].side == 1 and not fx4.can_follow_up() and not fx4.follow_up(line[0].ground_pos, {}) and fx4.turns == 0, "level 4: no follow-up")
	fx4.free()
	S._done(made)


## Through Rules and Targeting: the focused Schism slot aims as a click while the schism is live, even in CUSTOM (two clicks).
static func _wiring(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var line := _line(crowd, at, 3)
	var rules := Rules.new().setup(PackedStringArray(["schism", "doom"]), ctx, made[1], made[3], crowd, crowd._town)
	rules.levels = {"schism": 5}
	var called: Array = []
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): called.append([slot, key, p]))
	var fx := rules.cast(0, at, {"mode": "custom", "to": at + Vector2(6.0, 0.0)}) as DivineSchismFx
	var left := rules.cooldown_left(0)
	var aim := Targeting.new().setup(rules, crowd)
	aim.pick(0)
	aim.step_mode(2)
	t.check(aim.mode().key == "custom" and aim._aim_kind() != "click", "CUSTOM aims as its own two clicks before the schism is live")
	fx._process(DivineSchismFx.T_BREAK + 1.1)
	t.check(aim._aim_kind() == "click" and rules.can_recast(0), "while live the focused Schism slot aims as a click")
	var victim: Person = null
	for p in fx.members:
		if is_instance_valid(p) and p.is_alive():
			victim = p
			break
	var side := victim.side if victim != null else 0
	var click := victim.ground_pos if victim != null else at
	aim.press(click)
	aim.release(click)
	t.check(victim != null and called == [[0, "schism", click]] and victim.side == 3 - side and is_equal_approx(rules.cooldown_left(0), left),
		"the click turns a fighter: recast_made, the cooldown untouched")
	fx.end_now()
	fx.free()
	rules.free()
	aim.free()
	S._done(made)
