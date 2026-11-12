extends RefCounted
## Will-o-Wisp level 5 twist, Procession (Dominion ability levels, D11): while the light burns, a click sends it to a new spot; it drifts there at a
## walk. LURE: each lured person keeps its place round the light and is re-sent as it moves. ENTHRALL: the held and the ring move with it, and
## newcomers are taken round the light where it now is. Through Rules the click comes only after the cast's 1 s busy lock, without a cooldown.

const PATH := "res://src/fx/control/will_o_wisp.gd"
const S = preload("res://tests/test_schism.gd")
const E = preload("res://tests/test_wisp_enthrall.gd")


static func run(t) -> void:
	_lure(t)
	_enthrall(t)
	_stolen(t)
	_level_four(t)
	_rules(t)


static func _cast(ctx: FxContext, at: Vector2, extra: Dictionary) -> WillOWisp:
	return FxTimeline.cast(load(PATH), ctx, at, extra)


static func _people(crowd: Crowd, n: int) -> Array:
	var out: Array = []
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and out.size() < n:
			out.append(p)
	return out


## Step the light and the people together, `secs` in 0.1 s ticks.
static func _run(fx: WillOWisp, people: Array, secs: float) -> void:
	for k in int(round(secs * 10.0)):
		fx._process(0.1)
		for p in people:
			p.tick(0.1)


## The town's square is cluttered, and a walk through clutter proves nothing about the light: the open ground nearest the market that has
## nothing solid (the walk grid, or what a person cannot step onto) from 5 behind it to 11 east and 5 either side; the light is then sent east.
static var _arena_at := Vector2.INF


static func _arena(crowd: Crowd, grid: WalkGrid) -> Vector2:
	if _arena_at != Vector2.INF:
		return _arena_at
	var probe: Person = crowd.citizens[0]
	var home := probe.ground_pos
	var from := TownLayout.MARKET_SQUARE.get_center()
	var best := Vector2.INF
	var best_d := INF
	for ix in range(-28, 29, 2):
		for iy in range(-28, 29, 2):
			var c := Vector2(float(ix), float(iy))
			var d := c.distance_to(from)
			if d >= best_d:
				continue
			var clear := true
			for gx in range(-5, 12, 2):
				for gy in range(-5, 6, 2):
					var pt := c + Vector2(float(gx), float(gy))
					probe.ground_pos = pt
					clear = clear and grid.walkable(pt) and not probe._step_blocked(Vector2(0.2, 0.0)) and not probe._step_blocked(Vector2(0.0, 0.2)) 						and not probe._step_blocked(Vector2(-0.2, 0.0)) and not probe._step_blocked(Vector2(0.0, -0.2))
					if not clear:
						break
				if not clear:
					break
			if clear:
				best = c
				best_d = d
	probe.ground_pos = home
	_arena_at = best
	return best


static func _lure(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := _arena(crowd, grid)
	S._scatter(crowd)
	var group := _people(crowd, 3)
	E._place(group, at, 3.0)
	for p in group:
		p.pace = 1.0  # a person's own pace varies; the walks below should not
	var east := Vector2.RIGHT
	var fx := _cast(ctx, at, {"level": 5})
	var drawn := 0
	for p in group:
		drawn += 1 if p.lured() else 0
	t.check(drawn == 3 and fx.light_at == at, "level 5 LURE: three calm people drawn, the light at the cast point")
	t.check(fx.can_follow_up() and fx.follow_up(at + east * 4.0, {}), "follow_up(spot) is true while the light burns")
	fx._process(3.0)
	t.check(fx.light_at.distance_to(at + east * 1.8) < 0.05, "after 3 s the light has drifted 1.8 east at a walk (%s)" % [fx.light_at - at])
	var near := 0
	for p in group:
		var want: Vector2 = grid.nearest_walkable(fx.light_at + fx._offsets[p], 6)
		near += 1 if p.goal().distance_to(want) < 0.5 or (p.goal() == Vector2.INF and p.ground_pos.distance_to(want) < 0.5) else 0
	t.check(near == 3, "each lured person's goal is its own place round the light (within 0.5) (%d of 3)" % near)
	# A second click replaces the destination; the light turns.
	t.check(fx.follow_up(at + east * 1.8 + east.rotated(PI * 0.5) * 3.0, {}), "a second follow_up is taken (any number of times)")
	fx._process(1.0)
	t.check((fx.light_at - at).dot(east) < 1.85 and (fx.light_at - at).dot(east.rotated(PI * 0.5)) > 0.5, "and replaces the destination (%s)" % [fx.light_at - at])
	t.check(fx.follow_up(at + east * 4.0, {}), "sent back east")
	_run(fx, group, 8.0)
	t.check(fx.light_at.distance_to(at + east * 4.0) < 0.001, "the light stops at the spot")
	var placed := 0
	for p in group:
		var want: Vector2 = grid.nearest_walkable(fx.light_at + fx._offsets[p], 6)
		placed += 1 if p.lured() and p.ground_pos.distance_to(want) < 1.0 else 0
	t.check(placed >= 3, "and a lured person stands within 1.0 of its new place round it (%d of 3)" % placed)
	fx._process(maxf(fx.duration - 1.5 - fx.t, 0.0))
	t.check(fx.t < fx.duration - 1.0 and fx.can_follow_up(), "still open before the last second")
	fx._process(0.6)
	t.check(not fx.can_follow_up() and not fx.follow_up(at, {}), "false in the light's last second")
	fx.end_now()
	t.check(not fx.can_follow_up(), "and after it is out")
	fx.free()
	S._done(made)


static func _enthrall(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := _arena(crowd, grid)
	S._scatter(crowd)
	var folk := _people(crowd, 10)
	var group := folk.slice(0, 6)
	E._place(group, at, 3.0)
	for p in group:
		p.pace = 1.0  # a person's own pace varies; the walks below should not
	var late: Person = folk[8]
	late.ground_pos = at + Vector2(-20.0, 0.0)
	late.mind = Person.Mind.CALM
	var east := Vector2.RIGHT
	var fx := _cast(ctx, at, {"level": 5, "mode": "enthrall"})
	var held := 0
	for p in group:
		held += 1 if p.mind == Person.Mind.COMPELLED else 0
	t.check(held == 6 and fx.can_follow_up(), "level 5 ENTHRALL: six held, the light takes orders")
	var anchors := {}
	for p in group:
		anchors[p] = p.anchor
	t.check(fx.follow_up(at + east * 6.0, {}), "follow_up sends the light east")
	_run(fx, group, 5.0)
	t.check(fx.light_at.distance_to(at + east * 3.0) < 0.05, "it drifts at a walk (%s)" % [fx.light_at - at])
	var follows := true
	for p in group:
		follows = follows and p.mind == Person.Mind.COMPELLED and (p.anchor - anchors[p]).dot(east) > 2.0 and p.anchor.distance_to(fx.light_at) < 5.1
	t.check(follows, "a held person's anchor moves with the light")
	# Someone near the new spot (and far from the old) is taken at the next scan.
	late.ground_pos = fx.light_at + Vector2(2.0, 1.0)
	_run(fx, group, 0.6)
	t.check(late.mind == Person.Mind.COMPELLED and late.anchor.distance_to(fx.light_at) < 5.1, "a person standing near the new spot is taken at the next scan")
	_run(fx, group, 12.0)
	t.check(fx.light_at.distance_to(at + east * 6.0) < 0.001, "the light stops at the spot")
	var there := 0
	for p in group:
		there += 1 if p.ground_pos.distance_to(p.anchor) < 1.0 else 0
	t.check(there >= 5, "and the held walk to stand round it (%d of 6)" % there)
	fx.end_now()
	var freed := true
	for p in group:
		freed = freed and p.mind != Person.Mind.COMPELLED
	t.check(freed, "cutting it short releases them")
	fx.free()
	S._done(made)


## A held person another power has since compelled elsewhere is left alone by Procession (the ownership guard of _release_all()).
static func _stolen(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := _arena(crowd, grid)
	S._scatter(crowd)
	var group := _people(crowd, 3)
	E._place(group, at, 3.0)
	var fx := _cast(ctx, at, {"level": 5, "mode": "enthrall"})
	var thief: Person = group[0]
	var elsewhere := at + Vector2(-5.0, 2.0)
	thief.compel(elsewhere, 30.0, Person.WILL_ABSOLUTE, Color.WHITE, false, &"")
	fx.follow_up(at + Vector2.RIGHT * 4.0, {})
	fx._process(1.0)
	t.check(thief.anchor == elsewhere and thief.goal().distance_to(elsewhere) < 0.6 and not fx._held.has(thief),
		"a held person re-compelled elsewhere is left alone by the moving light")
	t.check(group[1].anchor.distance_to(fx.light_at) < 5.1 and fx._held.has(group[1]), "and the others still follow it")
	fx._process(1.0)
	t.check(thief.anchor == elsewhere, "and is not taken again at the next scan")
	fx.end_now()
	fx.free()
	S._done(made)


## Level 4: no follow-up, the light never leaves the cast point.
static func _level_four(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := _arena(crowd, grid)
	S._scatter(crowd)
	var group := _people(crowd, 3)
	E._place(group, at, 3.0)
	for p in group:
		p.pace = 1.0  # a person's own pace varies; the walks below should not
	var east := Vector2.RIGHT
	var fx := _cast(ctx, at, {"level": 4})
	t.check(not fx.can_follow_up() and not fx.follow_up(at + east * 4.0, {}) and fx.light_at == at, "level 4: no follow-up, the light stays at the cast point")
	fx._process(3.0)
	t.check(fx.light_at == at, "and stays there")
	fx.free()
	var fx2 := _cast(ctx, at, {"level": 4, "mode": "enthrall"})
	t.check(not fx2.can_follow_up() and fx2.light_at == at, "level 4 ENTHRALL: the same")
	fx2.end_now()
	fx2.free()
	S._done(made)


## Through Rules: the click comes only after the cast's 1 s busy lock; no cooldown change, no second cast_made.
static func _rules(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := _arena(crowd, grid)
	S._scatter(crowd)
	var rules := Rules.new().setup(PackedStringArray(["wisp", "doom"]), ctx, made[1], made[3], crowd, crowd._town)
	rules.levels = {"wisp": 5}
	var casts: Array = []
	var called: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _a: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): called.append([slot, key, p]))
	var east := Vector2.RIGHT
	var fx := rules.cast(0, at) as WillOWisp
	var left := rules.cooldown_left(0)
	t.check(fx != null and casts.size() == 1 and left > 0.0, "a level 5 wisp cast through Rules")
	fx._process(0.5)
	t.check(not rules.recast(0, at + east * 3.0) and not rules.can_recast(0), "at t = 0.5 (inside its busy lock) a recast is false")
	fx._process(0.6)
	t.check(rules.can_recast(0) and is_equal_approx(float(rules.follow_up_area(0).get("r", 0.0)), 1.6), "at t = 1.1 the slot takes an order")
	t.check(rules.recast(0, at + east * 3.0) and called.size() == 1 and casts.size() == 1 and is_equal_approx(rules.cooldown_left(0), left),
		"the recast is true, with no second cast_made and the cooldown untouched")
	fx.end_now()
	fx.free()
	rules.free()
	S._done(made)
