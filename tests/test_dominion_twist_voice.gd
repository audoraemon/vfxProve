extends RefCounted
## Voice of God level 5 twist, Second Word (Dominion ability levels, D17): while the first command holds, a click speaks a second (the Q/E
## command shown); when the first ends, everyone it reached takes the second at once, with the click as its place. No rng is drawn for it.

const PATH := "res://src/fx/dominion/voice_of_god.gd"
const S = preload("res://tests/test_schism.gd")


static func run(t) -> void:
	_second(t)
	_flee_rng(t)
	_gather(t)
	_judge(t)
	_return(t)
	_level_four(t)
	_wiring(t)


## A level 5 cast of `cmd` at the market with four people placed round it (everyone else far off in a corner).
static func _begin(cmd: String, level := 5) -> Array:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	S._scatter(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var group: Array = crowd.citizens.slice(0, 4)
	for i in group.size():
		var p: Person = group[i]
		p.ground_pos = at + Vector2.RIGHT.rotated(float(i) * 1.6) * (1.0 + 0.5 * float(i))
		p.mind = Person.Mind.CALM
		p.inside = false
	var fx: VoiceOfGodFx = FxTimeline.cast(load(PATH), ctx, at, {"mode": cmd, "level": level})
	return [made, fx, group, at]


static func _end(made: Array, fx: VoiceOfGodFx) -> void:
	fx.free()
	S._done(made)


static func _second(t) -> void:
	var b := _begin("kneel")
	var made: Array = b[0]
	var fx: VoiceOfGodFx = b[1]
	var group: Array = b[2]
	var at: Vector2 = b[3]
	var click := at + Vector2(3.0, 3.0)
	t.check(is_equal_approx(fx.seconds, 16.8), "level 5 KNEEL holds 16.8 s")
	t.check(not fx.can_follow_up() and not fx.follow_up(click, {"mode": "halt"}), "before T_SPEAK a follow-up is false")
	fx._process(VoiceOfGodFx.T_SPEAK + 3.0)
	var kneeling := 0
	for p in group:
		kneeling += 1 if p.mind == Person.Mind.COMPELLED and p.compel_pose == &"kneel" else 0
	t.check(kneeling == 4, "the first command has reached them (%d kneel)" % kneeling)
	t.check(fx.can_follow_up() and fx.follow_up(click, {"mode": "halt"}), "at T_SPEAK + 3.0 follow_up(click, halt) is true")
	t.check(not fx.can_follow_up() and not fx.follow_up(click, {"mode": "halt"}), "a second call is false (once per cast)")
	t.check(is_equal_approx(fx.duration, VoiceOfGodFx.T_SPEAK + 12.0 * 1.4 * 2.0 + 1.0), "the cast now runs both commands (%s)" % fx.duration)
	fx._process(VoiceOfGodFx.T_SPEAK + 16.0 - fx.t)
	var still := 0
	for p in group:
		still += 1 if p.compel_pose == &"kneel" else 0
	t.check(still == 4 and fx.second == "halt", "until the first ends they still kneel")
	fx._process(VoiceOfGodFx.T_SPEAK + 16.9 - fx.t)
	var held := 0
	for p in group:
		held += 1 if p.mind == Person.Mind.COMPELLED and p.compel_pose == &"" and is_equal_approx(p._compel_left, 16.8) else 0
	t.check(held == 4, "at T_SPEAK + 16.9 the reached are COMPELLED with no kneel pose, holding for 16.8 s (%d)" % held)
	_end(made, fx)

	# Someone the first never reached (inside) is not touched; the dead are not either.
	var b2 := _begin("kneel")
	var fx2: VoiceOfGodFx = b2[1]
	var group2: Array = b2[2]
	var inner: Person = group2[0]
	inner.inside = true
	var dead: Person = group2[1]
	var fx3 := fx2
	fx3.free()
	fx2 = FxTimeline.cast(load(PATH), b2[0][5], b2[3], {"mode": "kneel", "level": 5})
	fx2._process(VoiceOfGodFx.T_SPEAK + 3.0)
	fx2.follow_up(b2[3], {"mode": "halt"})
	dead.state = DummyEnemy.State.DEAD
	fx2._process(VoiceOfGodFx.T_SPEAK + 16.9 - fx2.t)
	t.check(dead.compel_pose == &"kneel" and group2[2].compel_pose == &"", "the dead person is untouched by the second word (still as the first left them)")
	t.check(inner.mind != Person.Mind.COMPELLED and group2[2].mind == Person.Mind.COMPELLED and group2[2].compel_pose == &"",
		"a person the first never reached (inside) is not touched; the others take the second")
	_end(b2[0], fx2)


static func _flee_rng(t) -> void:
	var b := _begin("kneel")
	var made: Array = b[0]
	var fx: VoiceOfGodFx = b[1]
	var group: Array = b[2]
	var at: Vector2 = b[3]
	var on_click: Person = group[0]
	on_click.ground_pos = at + Vector2(2.0, 0.0)
	fx._process(VoiceOfGodFx.T_SPEAK + 3.0)
	t.check(fx.follow_up(at + Vector2(2.0, 0.0), {"mode": "flee"}), "a second FLEE is taken")
	fx._process(VoiceOfGodFx.T_SPEAK + fx.seconds - 0.05 - fx.t)
	var state: int = fx.ctx.rng.state
	fx._process(0.1)
	t.check(fx.ctx.rng.state == state, "a second FLEE from a person exactly on the click draws no rng")
	t.check(on_click.mind == Person.Mind.COMPELLED and on_click.compel_pose == &"" and on_click.is_running(), "and sends them running")
	_end(made, fx)


static func _gather(t) -> void:
	var b := _begin("kneel")
	var made: Array = b[0]
	var fx: VoiceOfGodFx = b[1]
	var group: Array = b[2]
	var at: Vector2 = b[3]
	var click := at + Vector2(-4.0, 2.0)
	fx._process(VoiceOfGodFx.T_SPEAK + 3.0)
	t.check(fx.follow_up(click, {"mode": "gather"}), "a second GATHER is taken")
	fx._process(VoiceOfGodFx.T_SPEAK + fx.seconds + 0.1 - fx.t)
	var within := 0
	for p in group:
		within += 1 if p.mind == Person.Mind.COMPELLED and (p.anchor in fx._spots2 or p.anchor == fx._place.get("at", Vector2.INF)) else 0
	var distinct := {}
	for p in group:
		distinct["%.2f,%.2f" % [p.anchor.x, p.anchor.y]] = true
	t.check(within == 4 and distinct.size() == 4 and fx._spots2.size() == mini(fx.lv_gather_capacity, fx.obeyed), "each of the reached walks to a spot of its own at the click (%d of 4, %d spots)" % [within, distinct.size()])
	_end(made, fx)


static func _judge(t) -> void:
	var b := _begin("kneel")
	var made: Array = b[0]
	var fx: VoiceOfGodFx = b[1]
	var group: Array = b[2]
	var at: Vector2 = b[3]
	fx._process(VoiceOfGodFx.T_SPEAK + 3.0)
	t.check(not fx.follow_up(at + Vector2(0.0, -9.0), {"mode": "judge"}) and fx.second == "", "a second JUDGE with nobody near the click is false")
	var victim: Person = group[0]
	t.check(fx.follow_up(victim.ground_pos + Vector2(0.2, 0.0), {"mode": "judge"}), "a JUDGE with someone at the click is taken")
	fx._process(VoiceOfGodFx.T_SPEAK + fx.seconds + 0.1 - fx.t)
	var turned := 0
	for p in group:
		turned += 1 if p != victim and p.mind == Person.Mind.FIGHT and p.fight_target == victim else 0
	t.check(turned == 3 and fx._second_judged == victim, "the others turn on the one picked at the click (%d)" % turned)
	_end(made, fx)


## A second-word RETURN sends a person (no home, no post) back to where they stood before the first command laid its spot.
static func _return(t) -> void:
	var b := _begin("gather")
	var made: Array = b[0]
	var fx: VoiceOfGodFx = b[1]
	var group: Array = b[2]
	var at: Vector2 = b[3]
	var before := {}
	for p in group:
		p.profile = null
		p.post = Vector2.INF
		p.anchor = p.ground_pos
		before[p] = p.ground_pos
	fx._process(VoiceOfGodFx.T_SPEAK + 3.0)
	t.check(fx.follow_up(at, {"mode": "return"}), "a second RETURN is taken")
	fx._process(VoiceOfGodFx.T_SPEAK + fx.seconds + 0.1 - fx.t)
	var home := 0
	for p in group:
		home += 1 if p.mind == Person.Mind.COMPELLED and p.anchor.distance_to(before[p]) < 0.01 else 0
	t.check(home == 4, "RETURN sends each person to where they stood before the first command (%d of 4)" % home)
	_end(made, fx)


static func _level_four(t) -> void:
	var b := _begin("kneel", 4)
	var fx: VoiceOfGodFx = b[1]
	fx._process(VoiceOfGodFx.T_SPEAK + 3.0)
	t.check(not fx.can_follow_up() and not fx.follow_up(b[3], {"mode": "halt"}) and fx.second == "", "level 4: no follow-up")
	_end(b[0], fx)


## Through Rules and Targeting: with the Voice slot focused and Q/E on HALT, a click during the KNEEL is the second word.
static func _wiring(t) -> void:
	var made := S._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	S._scatter(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var rules := Rules.new().setup(PackedStringArray(["voice", "doom"]), ctx, made[1], made[3], crowd, crowd._town)
	rules.levels = {"voice": 5}
	var casts: Array = []
	var called: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _a: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): called.append([slot, key, p]))
	var aim := Targeting.new().setup(rules, crowd)
	aim.pick(0)
	aim.press(at)
	aim.release(at)
	var fx := rules.live_fx("voice") as VoiceOfGodFx
	t.check(fx != null and casts == [[0, "voice"]] and fx.command == "kneel", "a first click casts the Voice on KNEEL")
	var left := rules.cooldown_left(0)
	fx._process(0.5 + VoiceOfGodFx.T_SPEAK - fx.t)
	t.check(not rules.recast(0, at + Vector2(2.0, 0.0), {"mode": "halt"}) and not rules.can_recast(0), "at T_SPEAK + 0.5 (inside its busy lock) a recast is false")
	fx._process(3.0 + VoiceOfGodFx.T_SPEAK - fx.t)
	aim.pick(0)
	aim.step_mode(1)
	t.check(aim.mode().key == "halt", "Q/E is on HALT")
	var click := at + Vector2(2.0, 2.0)
	aim.press(click)
	aim.release(click)
	t.check(called == [[0, "voice", click]] and casts.size() == 1 and fx.second == "halt" and is_equal_approx(rules.cooldown_left(0), left),
		"the click during the KNEEL is the second word: recast_made, no cast_made, cooldown untouched (%s)" % [called])
	fx.end_now()
	fx.free()
	rules.free()
	aim.free()
	S._done(made)
