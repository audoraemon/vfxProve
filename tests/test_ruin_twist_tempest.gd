extends RefCounted
## Wrath of the Sky level 5 twist, Called Bolts (Ruin ability levels): with the slot focused, a click on the ground while the storm rains drops
## a hard bolt exactly there after the usual omen, once in CALL_EVERY seconds. Rules.recast() is the route a click takes; level 4 has none.

const P := Vector2(7.0, 3.0)


## A bare context: no town, no stage (so nothing is drawn), a field and an environment.
static func _ctx() -> FxContext:
	var ctx := FxContext.new()
	ctx.env = EnvironmentField.new()
	ctx.field = EnemyField.new()
	ctx.field.env = ctx.env
	ctx.field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 5
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return ctx


static func _free(ctx: FxContext) -> void:
	ctx.overhead.free()
	ctx.ground.free()


static func _person(ctx: FxContext, at: Vector2) -> DummyEnemy:
	var d := DummyEnemy.new()
	d.ground_pos = at
	ctx.field.add(d)
	return d


static func run(t) -> void:
	_called_bolts(t)
	_level_four(t)
	_rules_route(t)
	_wiring(t)


static func _called_bolts(t) -> void:
	var ctx := _ctx()
	var fx: TempestFx = FxTimeline.cast(load("res://src/fx/ruin/tempest.gd"), ctx, Vector2.ZERO, {"level": 5})
	var victim := _person(ctx, P)
	t.check(not fx.can_call() and not fx.call_bolt(P) and fx.called == 0, "level 5: no bolt can be called while the storm gathers")
	fx._process(TempestFx.T_GATHER - 0.1)
	t.check(not fx.call_bolt(P), "nor an instant before it rains")
	fx._process(0.15)
	t.check(fx.storming() and fx.can_call(), "the rain begins and a bolt can be called")
	var before := fx.bolts
	var asked := fx.t
	t.check(fx.call_bolt(P) and fx.called == 1, "level 5: call_bolt during the storm is true")
	t.check(victim.is_alive(), "and nothing falls at once: the ground is told first")
	fx._process(TempestFx.LEAD - 0.01)
	t.check(victim.is_alive(), "not yet at LEAD less a hair")
	# The storm's own first volley was told at 5.2 s, so its first bolt falls after the called one (5.15 + LEAD): the fall at the spot is the called bolt's.
	fx._process(0.02)
	t.check(not victim.is_alive() and fx.last_at.is_equal_approx(P), "a person at the spot dies at +LEAD, to a bolt exactly there")
	t.check(fx.bolts == before + 1, "the called bolt counts in bolts (%d -> %d)" % [before, fx.bolts])
	# One second later: too soon. 3.1 s after the first call: allowed again.
	fx._process(maxf(asked + 1.0 - fx.t, 0.0))
	t.check(not fx.can_call() and not fx.call_bolt(P) and fx.called == 1, "a second call 1 s after the first is refused")
	fx._process(maxf(asked + TempestFx.CALL_EVERY + 0.1 - fx.t, 0.0))
	t.check(fx.can_call() and fx.call_bolt(P + Vector2(2.0, 0.0)) and fx.called == 2, "and one 3.1 s after is taken")
	# After the storm.
	fx._process(TempestFx.T_GATHER + fx.lv_storm_time - fx.t + 0.1)
	t.check(not fx.storming() and not fx.can_call() and not fx.call_bolt(P) and fx.called == 2, "after the storm no bolt can be called")
	_free(ctx)


static func _level_four(t) -> void:
	var ctx := _ctx()
	var fx: TempestFx = FxTimeline.cast(load("res://src/fx/ruin/tempest.gd"), ctx, Vector2.ZERO, {"level": 4})
	fx._process(TempestFx.T_GATHER + 1.0)
	t.check(fx.storming() and not fx.can_call() and not fx.call_bolt(P) and fx.called == 0, "level 4: call_bolt is always false")
	var plain := FxTimeline.cast(load("res://src/fx/ruin/tempest.gd"), ctx, Vector2.ZERO)
	plain._process(TempestFx.T_GATHER + 1.0)
	t.check(not plain.call_bolt(P), "and so is a cast with no level")
	_free(ctx)


## A Rules with a real caster: a level 5 Wrath cast through Rules.cast(), then the click's route.
static func _rules_route(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	var ctx := _ctx()
	ctx.env = env
	ctx.field = field
	var rules := Rules.new().setup(PackedStringArray(["tempest", "smite"]), ctx, env, field, crowd, town)
	rules.levels = {"tempest": 5}
	var called: Array = []
	rules.recast_made.connect(func(slot: int, key: String, at: Vector2): called.append([slot, key, at]))
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	t.check(not rules.recast(0, P) and not rules.can_recast(0) and called.is_empty(), "with no storm running, recast is false")
	var fx := rules.cast(0, TownLayout.MARKET_SQUARE.get_center()) as TempestFx
	var left := rules.cooldown_left(0)
	t.check(fx != null and rules.live_fx("tempest") == fx and left > 900.0, "Rules.cast starts the level 5 storm on its once-only cooldown")
	t.check(not rules.recast(0, P), "while it gathers, recast is false")
	fx._process(TempestFx.T_GATHER + 0.5)
	t.check(rules.can_recast(0) and rules.recast(0, P), "once it rains, recast(slot, p) is true")
	t.check(called.size() == 1 and called[0][0] == 0 and called[0][1] == "tempest" and called[0][2] == P and fx.called == 1,
		"and sends recast_made with the slot, the key and the spot")
	t.check(is_equal_approx(rules.cooldown_left(0), left), "the cooldown is not touched")
	t.check(not rules.can_recast(0) and not rules.recast(0, P) and called.size() == 1, "a second click at once is not the storm's")
	rules.cast(0, P)
	t.check(refused.back() == [0, "cooldown"], "so cast() refuses it as a cooldown")
	t.check(not rules.recast(1, P) and not rules.recast(7, P) and not rules.can_recast(-1), "another slot, an empty one or none is never recast")
	# The storm over (or cut short): no recast, and the slot refuses as a cooldown.
	fx.end_now()
	t.check(not rules.recast(0, P) and not rules.can_recast(0), "after the storm recast is false again")
	rules.free()
	crowd.clear()
	world.free()
	_free(ctx)


## The click reaches the storm through a real Targeting (press / release), before the cast: a level 5 Wrath, the slot focused. While the
## storm gathers the click is a plain cast attempt (refused, a cooldown); once it rains the click is a called bolt: recast_made fires, no
## cast_made does, the slot stays focused and the cooldown is untouched; the very next click is refused again.
static func _wiring(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	var ctx := _ctx()
	ctx.env = env
	ctx.field = field
	var rules := Rules.new().setup(PackedStringArray(["tempest", "smite"]), ctx, env, field, crowd, town)
	rules.levels = {"tempest": 5}
	var casts: Array = []
	var called: Array = []
	var refused: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, _key: String, at: Vector2): called.append([slot, at]))
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var aim := Targeting.new().setup(rules, crowd)
	var home := TownLayout.MARKET_SQUARE.get_center()
	aim.pick(0)
	aim.press(home)
	aim.release(home)
	var fx := rules.live_fx("tempest") as TempestFx
	t.check(casts == [[0, "tempest"]] and fx != null and aim.slot == -1, "a first click casts the storm, and the cast unfocuses (as every cast does)")
	var left := rules.cooldown_left(0)
	aim.pick(0)
	aim.press(P)
	aim.release(P)
	t.check(called.is_empty() and casts.size() == 1 and refused.back() == [0, "cooldown"] and aim.slot == 0,
		"while the storm gathers a click is no bolt: it is refused as a cooldown, the slot still focused (%s)" % [refused])
	fx._process(TempestFx.T_GATHER + 0.5)
	aim.press(P)
	aim.release(P)
	t.check(called == [[0, P]] and casts.size() == 1 and aim.slot == 0 and is_equal_approx(rules.cooldown_left(0), left) and fx.called == 1,
		"once it rains a click is a called bolt: recast_made, no cast_made, still focused, cooldown untouched (%s)" % [called])
	var refusals := refused.size()
	aim.press(P)
	aim.release(P)
	t.check(called.size() == 1 and refused.size() == refusals + 1 and refused.back() == [0, "cooldown"] and aim.slot == 0,
		"a second click at once is refused (the call is once in CALL_EVERY seconds)")
	# A drag power never takes the route: a different slot, even with the storm running, casts as it always did.
	aim.pick(1)
	aim.press(P)
	aim.release(P)
	t.check(called.size() == 1 and (casts.size() == 2 or refused.back()[0] == 1), "another slot's click is its own cast (or its own refusal)")
	rules.free()
	aim.free()
	crowd.clear()
	world.free()
	_free(ctx)
