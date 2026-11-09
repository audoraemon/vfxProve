extends RefCounted
## Clear Mind level 5 twist, Sleepwalk (Dominion ability levels, D12): while the trance holds, a click sends everyone entranced to a spot of
## their own at the click; they walk calmly, sense nothing still, and stand there until the trance ends. Level 4 has none.

const PATH := "res://src/fx/dominion/clear_mind.gd"
const S = preload("res://tests/test_schism.gd")
const W = preload("res://tests/test_dominion_twist_wisp.gd")
const E = preload("res://tests/test_wisp_enthrall.gd")


static func run(t) -> void:
	_sleepwalk(t)
	_level_four(t)
	_rules(t)


static func _cast(ctx: FxContext, at: Vector2, extra: Dictionary) -> ClearMindFx:
	return FxTimeline.cast(load(PATH), ctx, at, extra)


static func _walk(fx: ClearMindFx, people: Array, secs: float) -> void:
	for k in int(round(secs * 10.0)):
		fx._process(0.1)
		for p in people:
			p.tick(0.1)


static func _sleepwalk(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := W._arena(crowd, grid)
	S._scatter(crowd)
	var folk := W._people(crowd, 6)
	var group := folk.slice(0, 3)
	E._place(group, at, 1.2)
	for p in folk:
		p.pace = 1.0
	var joiner: Person = folk[4]
	joiner.ground_pos = at + Vector2(-20.0, 0.0)
	joiner.mind = Person.Mind.CALM
	var fx := _cast(ctx, at, {"level": 5})
	t.check(not fx.can_follow_up() and not fx.follow_up(at, {}), "before T_CAST nobody is entranced: no follow-up")
	fx._process(ClearMindFx.T_CAST + 1.0)
	var click := at + Vector2(6.0, 0.0)
	t.check(fx.taken == 3 and fx.can_follow_up() and fx.follow_up(click, {}), "at T_CAST + 1.0 the click is taken (taken %d)" % fx.taken)
	var spots := {}
	var all := true
	for p in group:
		all = all and p.mind == Person.Mind.COMPELLED and p.fearless_left > 0.0 and not p.is_running() and p.anchor.distance_to(click) < 3.0
		spots["%.2f,%.2f" % [p.anchor.x, p.anchor.y]] = true
	t.check(all and spots.size() == 3 and fx.walks == 1 and fx.walkers.size() == 3,
		"all three are COMPELLED, still fearless, not running, on three different spots at the click (%d spots)" % spots.size())
	# A fright laid at their feet neither frightens nor stops them.
	_walk(fx, group, 3.0)
	crowd.fright(group[0].ground_pos, 1.5, 0.6, 5.0, 4.0, 8.0, &"frenzy")
	var calm := true
	for p in group:
		calm = calm and p.mind == Person.Mind.COMPELLED
	t.check(calm, "a fright laid at their feet frightens none of them and breaks no walk")
	# Someone who joins after the click is entranced but not sent.
	joiner.ground_pos = at + Vector2(0.0, 2.0)
	_walk(fx, group, 0.6)
	t.check(fx.entranced.has(joiner) and not fx.walkers.has(joiner) and joiner.mind != Person.Mind.COMPELLED, "a latecomer is entranced and waits for the next click")
	_walk(fx, group, 9.0)
	var there := 0
	for p in group:
		there += 1 if p.ground_pos.distance_to(p.anchor) < 0.6 else 0
	t.check(there == 3, "after 12 s each stands within 0.6 of its spot (a walker stops inside GOAL_REACH 0.45) (%d of 3)" % there)
	# A second click re-sends everyone entranced now, the latecomer too.
	var click2 := at + Vector2(-6.0, 0.0)
	t.check(fx.follow_up(click2, {}) and fx.walks == 2 and fx.walkers.has(joiner) and joiner.mind == Person.Mind.COMPELLED, "a second click re-sends them, the latecomer with them")
	var moved := true
	for p in group:
		moved = moved and p.anchor.distance_to(click2) < 3.0
	t.check(moved, "to the new click")
	# The trance ends: the walkers are let go, and the follow-up is closed.
	fx._process(ClearMindFx.T_CAST + fx.lv_trance_time + 0.1 - fx.t)
	var freed := true
	for p in group + [joiner]:
		freed = freed and p.mind != Person.Mind.COMPELLED
	t.check(freed and not fx.holding() and not fx.can_follow_up() and not fx.follow_up(click, {}), "at the end none is COMPELLED by it and the follow-up is false")
	fx.free()
	# end_now() mid-walk releases them.
	var fx2 := _cast(ctx, at, {"level": 5})
	fx2._process(ClearMindFx.T_CAST + 1.0)
	fx2.follow_up(click, {})
	var held := 0
	for p in group:
		held += 1 if p.mind == Person.Mind.COMPELLED else 0
	fx2.end_now()
	var left := 0
	for p in group:
		left += 1 if p.mind == Person.Mind.COMPELLED else 0
	t.check(held >= 1 and left == 0, "end_now() mid-walk releases them (%d held, %d left)" % [held, left])
	fx2.free()
	S._done(made)


static func _level_four(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := W._arena(crowd, grid)
	S._scatter(crowd)
	var group := W._people(crowd, 3)
	E._place(group, at, 2.5)
	var fx := _cast(ctx, at, {"level": 4})
	fx._process(ClearMindFx.T_CAST + 1.0)
	var before: Array = []
	for p in group:
		before.append(p.mind)
	t.check(fx.taken == 3 and not fx.can_follow_up() and not fx.follow_up(at + Vector2(6.0, 0.0), {}) and fx.walks == 0,
		"level 4: entranced, but no follow-up")
	var same := true
	for i in group.size():
		same = same and group[i].mind == before[i] and group[i].mind != Person.Mind.COMPELLED
	t.check(same, "and nobody is made to walk")
	fx.end_now()
	fx.free()
	S._done(made)


## Through Rules: the click comes only after the cast's 0.9 s busy lock; no cooldown change, no second cast_made.
static func _rules(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := W._arena(crowd, grid)
	S._scatter(crowd)
	var group := W._people(crowd, 3)
	E._place(group, at, 2.5)
	var rules := Rules.new().setup(PackedStringArray(["clearmind", "doom"]), ctx, made[1], made[3], crowd, crowd._town)
	rules.levels = {"clearmind": 5}
	var casts: Array = []
	var called: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _a: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): called.append([slot, key, p]))
	var fx := rules.cast(0, at) as ClearMindFx
	var left := rules.cooldown_left(0)
	t.check(fx != null and casts.size() == 1 and left > 0.0, "a level 5 Clear Mind cast through Rules")
	fx._process(ClearMindFx.T_CAST + 0.1)
	t.check(rules.can_recast(0) and rules.recast(0, at + Vector2(6.0, 0.0)) and called.size() == 1 and casts.size() == 1
		and is_equal_approx(rules.cooldown_left(0), left), "after its busy lock the recast is true, with no second cast_made and the cooldown untouched")
	fx.end_now()
	fx.free()
	rules.free()
	S._done(made)
