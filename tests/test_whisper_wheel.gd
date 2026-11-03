extends RefCounted
## Mind Whisper's order wheel (god/whisper-wheel): a press on a person opens a wheel of three slices -- WALK, ATTACK, BURN.
## A release beyond the wheel's edge is today's walk (same cast, same extra); a release on a slice picks the order and the
## aim waits for the target (a spot, a person within ATTACK_R, a building within BURN_R); the middle keeps the wheel open.
## The effect: attack sets the whispered one on that person alone for ATTACK_SECS, burn walks them to the building and, after
## BURN_SECS there, lights it at Ember's START_LEVEL; both wake as a whisper does and shake it off for 20 s. No order = today.


static func _crowd() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _think(p: Person, seconds: float) -> void:
	var step := 0.1
	var t := 0.0
	while t < seconds - 0.0001:
		p._think(step)
		t += step


## How many keys the cast's extra holds besides the "level" Rules adds to every cast.
static func _n(extra: Dictionary) -> int:
	return extra.size() - (1 if extra.has("level") else 0)


static func run(t) -> void:
	var made := _crowd()
	_geometry(t)
	_targeting(t, made)
	_rules(t, made)
	_attack(t, made)
	_burn(t, made)
	_done(made)


## Walkable ground with nobody within 7 units.
static func _empty(made: Array) -> Vector2:
	var grid: WalkGrid = made[4]
	var field: EnemyField = made[3]
	for i in 400:
		var at := grid.nearest_walkable(Vector2(-24.0 + float(i % 20) * 2.4, -24.0 + float(i / 20) * 2.4))
		if at != Vector2.INF and field.in_radius(at, 7.0).is_empty():
			return at
	return Vector2.INF


## A standing building that burns, and one that does not.
static func _houses(env: EnvironmentField) -> Array:
	var burns: Structure = null
	var stone: Structure = null
	for s in env.structures():
		if s.destroyed or s.walkable:
			continue
		if burns == null and FireManager.burns(s) and s.kind == Structure.Kind.HOUSE:
			burns = s
		elif stone == null and not FireManager.burns(s) and s.kind != Structure.Kind.TREE:
			stone = s
	return [burns, stone]


static func _geometry(t) -> void:
	t.check(Targeting.WHEEL_R == 1.2 and Targeting.WHEEL_HUB < Targeting.WHEEL_R, "the wheel is 1.2 units across its radius, with a hub")
	t.check(MindWhisperFx.ATTACK_R == 6.0 and MindWhisperFx.BURN_R == 6.0 and MindWhisperFx.ATTACK_SECS == 10.0
		and MindWhisperFx.BURN_SECS == 3.0, "the order numbers: reach 6 and 6, attack 10 s, burn 3 s")
	for name: String in ["walk", "attack", "burn"]:
		t.check(Targeting.wheel_slice(Targeting.wheel_dir(name) * 0.8) == name, "a point on the %s slice is the %s slice" % [name, name])
	t.check(Targeting.wheel_slice(Vector2(0.05, 0.0)) == "" and Targeting.wheel_slice(Vector2.ZERO) == "", "the middle is no slice")
	t.check(Targeting.wheel_slice(Targeting.wheel_dir("walk") * 1.3) == "out" and Targeting.wheel_slice(Vector2(0.0, 5.0)) == "out",
		"beyond the edge is outside the wheel")
	# The three slices are thirds: a point 30 degrees to either side of a slice's middle is still on it.
	var turn := deg_to_rad(25.0)
	t.check(Targeting.wheel_slice(Targeting.wheel_dir("attack").rotated(turn) * 0.9) == "attack"
		and Targeting.wheel_slice(Targeting.wheel_dir("attack").rotated(-turn) * 0.9) == "attack", "a slice is a third of the wheel")
	t.check(Targeting.wheel_slice(Targeting.wheel_dir("attack").rotated(deg_to_rad(95.0)) * 0.9) != "attack", "and the next third is another")


static func _targeting(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[4]
	var town: Town = made[5]
	var rules := Rules.new().setup(PackedStringArray(["whisper", "heaven"]), null, env, field, crowd, town)
	var casts: Array = []
	var refused: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	var aim := Targeting.new().setup(rules, crowd)
	var base := _empty(made)
	t.check(base != Vector2.INF, "a spot with nobody within 7 units")
	var who: Person = crowd.citizens[40]
	var foe: Person = crowd.citizens[41]
	var far: Person = crowd.citizens[42]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(3.0, 0.0)
	far.ground_pos = base + Vector2(-7.0, 0.0)

	# The press opens the wheel; the quick drag past its edge is today's walk.
	aim.pick(0)
	t.check(not aim.wheel_open() and aim.picking_order() == "", "before a press there is no wheel")
	aim.press(base + Vector2(0.2, 0.0))
	t.check(aim.wheel_open() and aim.armed and aim.aiming and aim.picking_order() == "", "a press on a person opens the wheel")
	var spot := base + Vector2(4.0, 0.0)
	aim.release(spot)
	t.check(casts.size() == 1 and casts[0][0] == who.ground_pos, "a release past the edge casts at the person (%s)" % [casts])
	var extra: Dictionary = casts[0][1] if casts.size() == 1 else {}
	t.check(_n(extra) == 2 and extra.get("target") == who and extra.has("to") and not extra.has("order") and not extra.has("foe"),
		"with exactly today's extra: the target and where to (%s)" % [extra])
	t.check((extra.get("to", Vector2.INF) as Vector2).distance_to(MindWhisperFx.clamp_to(grid, who.ground_pos, spot)) < 0.001,
		"sent to the clamped spot")
	t.check(not aim.wheel_open() and aim.slot == -1, "and the wheel is gone with the focus")

	# A press on nobody is refused as before: no wheel.
	rules._cooldowns[0] = 0.0
	refused.clear()
	aim.pick(0)
	aim.press(base + Vector2(0.0, 2.0))
	t.check(not aim.wheel_open() and not aim.armed and refused == [[0, "nobody"]], "a press on nobody opens no wheel (%s)" % [refused])

	# The middle keeps the wheel open.
	casts.clear()
	refused.clear()
	aim.press(base)
	aim.release(base + Vector2(0.1, 0.0))
	t.check(aim.wheel_open() and not aim.armed and aim.picking_order() == "" and casts.is_empty() and refused.is_empty(),
		"a release in the middle casts nothing and keeps the wheel open")
	# A press on a slice then picks it; the wheel is replaced by the pick step.
	aim.press(base + Targeting.wheel_dir("attack") * 0.8)
	t.check(aim.wheel_open() and aim.armed, "a press inside the open wheel is held on it")
	aim.release(base + Targeting.wheel_dir("attack") * 0.8)
	t.check(aim.picking_order() == "attack" and not aim.wheel_open() and aim.slot == 0 and casts.is_empty(),
		"a release on the ATTACK slice picks the order, the power stays focused, nothing is cast (%s)" % aim.picking_order())

	# The pick step: refusals keep it going.
	for bad in [["nobody there", base + Vector2(0.0, -2.0)], ["the whispered one", base], ["too far", far.ground_pos]]:
		refused.clear()
		aim.press(bad[1])
		aim.release(bad[1])
		t.check(refused == [[0, "foe"]] and casts.is_empty() and aim.picking_order() == "attack",
			"attack: %s is refused and the pick goes on (%s)" % [bad[0], refused])
	# Escape (cancel) leaves the step; the power is still focused.
	t.check(aim.cancel() and aim.picking_order() == "" and not aim.wheel_open() and aim.slot == 0 and casts.is_empty(),
		"Escape calls off the pick, the power stays focused")
	t.check(not aim.cancel(), "and a second Escape has nothing left to call off")

	# A valid foe.
	aim.press(base)
	aim.release(base + Targeting.wheel_dir("attack") * 0.8)
	aim.press(foe.ground_pos + Vector2(0.2, 0.1))
	aim.release(foe.ground_pos + Vector2(0.2, 0.1))
	t.check(casts.size() == 1 and casts[0][0] == who.ground_pos, "a click on a person within reach casts at the whispered one")
	extra = casts[0][1] if casts.size() == 1 else {}
	t.check(_n(extra) == 3 and extra.get("target") == who and extra.get("order") == "attack" and extra.get("foe") == foe,
		"with the target, the order and the foe (%s)" % [extra])
	t.check(aim.slot == -1 and aim.picking_order() == "" and not aim.wheel_open(), "and the aim is done")

	# WALK: pick the slice, then click a spot -- today's extra exactly.
	rules._cooldowns[0] = 0.0
	casts.clear()
	aim.pick(0)
	aim.press(base)
	aim.release(base + Targeting.wheel_dir("walk") * 0.8)
	t.check(aim.picking_order() == "walk", "the WALK slice picks the walk")
	var to := base + Vector2(0.0, 5.0)
	aim.press(to)
	aim.release(to)
	extra = casts[0][1] if casts.size() == 1 else {}
	t.check(_n(extra) == 2 and extra.get("target") == who and not extra.has("order")
		and (extra.get("to", Vector2.INF) as Vector2).distance_to(MindWhisperFx.clamp_to(grid, who.ground_pos, to)) < 0.001,
		"a click casts today's {to, target} (%s)" % [extra])

	# BURN.
	var hs := _houses(env)
	var house: Structure = hs[0]
	var stone: Structure = hs[1]
	t.check(house != null and stone != null, "the town has a house and something that does not burn")
	var spot_h := grid.nearest_walkable(house.center() + Vector2(3.0, 0.0), 6)
	who.ground_pos = spot_h
	var d_h := house.distance_to(who.ground_pos)
	t.check(d_h <= MindWhisperFx.BURN_R, "the whispered one stands within BURN_R of the house (%.2f)" % d_h)
	rules._cooldowns[0] = 0.0
	casts.clear()
	refused.clear()
	aim.pick(0)
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Targeting.wheel_dir("burn") * 0.8)
	t.check(aim.picking_order() == "burn", "the BURN slice picks the burn")
	var bare := who.ground_pos + Vector2(0.0, -4.0)
	if house.distance_to(bare) < 1.0:
		bare = who.ground_pos + Vector2(0.0, 4.0)
	aim.press(bare)
	aim.release(bare)
	t.check(refused == [[0, "building"]] and casts.is_empty() and aim.picking_order() == "burn", "burn: bare ground is refused (%s)" % [refused])
	refused.clear()
	# A building out of reach, and one that does not burn.
	var out_of_reach: Structure = null
	for s in env.structures():
		if not s.destroyed and not s.walkable and FireManager.burns(s) and s.distance_to(who.ground_pos) > MindWhisperFx.BURN_R + 1.0:
			out_of_reach = s
			break
	t.check(out_of_reach != null, "a burnable building out of BURN_R")
	aim.press(out_of_reach.center())
	aim.release(out_of_reach.center())
	t.check(refused == [[0, "building"]] and aim.picking_order() == "burn", "burn: a building too far away is refused")
	refused.clear()
	who.ground_pos = grid.nearest_walkable(stone.center() + Vector2(2.0, 0.0), 6)
	aim.press(stone.center())
	aim.release(stone.center())
	t.check(refused == [[0, "building"]] and casts.is_empty(), "burn: a building that does not burn is refused")
	who.ground_pos = spot_h
	refused.clear()
	aim.press(house.center())
	aim.release(house.center())
	extra = casts[0][1] if casts.size() == 1 else {}
	t.check(_n(extra) == 3 and extra.get("target") == who and extra.get("order") == "burn" and extra.get("building") == house,
		"a click on a standing house in reach casts the burn (%s)" % [extra])
	t.check(casts.size() == 1 and casts[0][0] == who.ground_pos, "at the whispered one")

	# A press on a person who then cannot hear: the pick step refuses with "nobody" and ends.
	rules._cooldowns[0] = 0.0
	casts.clear()
	refused.clear()
	aim.pick(0)
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Targeting.wheel_dir("attack") * 0.8)
	who.inside = true
	aim.press(foe.ground_pos)
	aim.release(foe.ground_pos)
	who.inside = false
	t.check(refused == [[0, "nobody"]] and casts.is_empty() and aim.picking_order() == "", "one who went inside meanwhile hears nothing: refused")
	# Focusing another slot, or unfocusing, drops the pick.
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Targeting.wheel_dir("attack") * 0.8)
	aim.unfocus()
	t.check(aim.picking_order() == "" and not aim.wheel_open(), "unfocusing drops the pick step")
	aim.pick(0)
	aim.press(who.ground_pos)
	aim.pick(1)
	aim.pick(0)
	t.check(not aim.wheel_open() and not aim.armed, "and so does picking another power")
	aim.free()
	rules.free()


static func _rules(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var field: EnemyField = made[3]
	var town: Town = made[5]
	var rules := Rules.new().setup(PackedStringArray(["whisper", "heaven"]), null, env, field, crowd, town)
	var casts: Array = []
	var refused: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	var base := _empty(made)
	var who: Person = crowd.citizens[43]
	var foe: Person = crowd.citizens[44]
	var far: Person = crowd.citizens[45]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(2.0, 0.0)
	far.ground_pos = base + Vector2(8.0, 0.0)
	rules.cast(0, base, {"target": who, "order": "attack"})
	t.check(refused == [[0, "foe"]] and casts.is_empty() and rules.cooldown_left(0) == 0.0, "an attack order with no foe is refused, no cooldown (%s)" % [refused])
	refused.clear()
	rules.cast(0, base, {"target": who, "order": "attack", "foe": far})
	t.check(refused == [[0, "foe"]] and casts.is_empty(), "and one with a foe out of reach")
	refused.clear()
	rules.cast(0, base, {"target": who, "order": "attack", "foe": who})
	t.check(refused == [[0, "foe"]] and casts.is_empty(), "and one against itself")
	refused.clear()
	rules.cast(0, base, {"target": who, "order": "burn"})
	t.check(refused == [[0, "building"]] and casts.is_empty() and rules.cooldown_left(0) == 0.0, "a burn order with no building is refused")
	refused.clear()
	rules.cast(0, base, {"target": who, "order": "attack", "foe": foe})
	t.check(refused.is_empty() and casts.size() == 1 and rules.cooldown_left(0) == 8.0, "an attack order with a foe in reach casts, 8 s cooldown")
	rules._cooldowns[0] = 0.0
	rules.cast(0, base, {"target": who, "to": base + Vector2(3.0, 0.0)})
	rules._cooldowns[0] = 0.0
	rules.cast(0, base, {"target": who, "order": "walk", "to": base + Vector2(3.0, 0.0)})
	t.check(casts.size() == 3 and refused.is_empty(), "today's walk casts, with or without the word")
	rules.free()


static func _fx_ctx(made: Array, with_town := true) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = made[1]
	ctx.field = made[3]
	ctx.rng = RandomNumberGenerator.new()
	ctx.ground = Node2D.new()
	ctx.overhead = Node2D.new()
	if with_town:
		ctx.crowd = made[0]
	return ctx


static func _free_ctx(ctx: FxContext) -> void:
	ctx.ground.free()
	ctx.overhead.free()


static func _attack(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx := _fx_ctx(made)
	var base := _empty(made)
	var who: Person = crowd.citizens[50]
	var foe: Person = crowd.citizens[51]
	var beside: Person = crowd.citizens[52]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(0.3, 0.0)
	beside.ground_pos = base + Vector2(0.0, 0.3)
	var foe_h := foe.health
	var beside_h := beside.health
	var fx := FxTimeline.cast(MindWhisperFx, ctx, who.ground_pos, {"target": who, "order": "attack", "foe": foe})
	fx._process(0.1)
	t.check(who.mind == Person.Mind.FIGHT and who.fight_target == foe, "attack: the whispered one is set on the foe")
	t.check(not fx.finished, "the effect lives while the order does")
	var struck := 0.0
	for k in 95:
		who.ground_pos = base
		foe.ground_pos = base + Vector2(0.3, 0.0)
		beside.ground_pos = base + Vector2(0.0, 0.3)
		who._think(0.1)
		fx._process(0.1)
		if k == 0:
			struck = foe_h - foe.health
		foe.health = foe_h  # the foe is not to fall: this is the clock
		foe.state = DummyEnemy.State.WANDER
		beside.state = DummyEnemy.State.WANDER
	t.near(struck, MindWhisperFx.CIVIL_BLOW, 0.001, "a civilian strikes with the civil blow")
	t.check(beside.health == beside_h and who.mind == Person.Mind.FIGHT and who.fight_target == foe,
		"9.5 s on: the one beside is never struck, the fight goes on")
	for k in 12:
		who.ground_pos = base
		who._think(0.1)
		fx._process(0.1)
	t.check(who.mind != Person.Mind.FIGHT and who.mind != Person.Mind.WHISPERED, "after 10 s the whispered one comes to (%s)" % Person.Mind.keys()[who.mind])
	t.check(who.shaken() and not who.whisper(base, 8.0), "and shakes the whisper off like any whisper: no new one for %d s" % roundi(Person.SHAKE_OFF))
	fx._process(2.0)
	t.check(fx.finished, "the effect is done with it")
	fx.free()

	# A soldier strikes as a soldier.
	var s: Person = crowd.soldiers[3]
	var foe2: Person = crowd.citizens[53]
	s.ground_pos = base
	foe2.ground_pos = base + Vector2(0.3, 0.0)
	var h2 := foe2.health
	var fx2 := FxTimeline.cast(MindWhisperFx, ctx, s.ground_pos, {"target": s, "order": "attack", "foe": foe2})
	fx2._process(0.1)
	s._think(0.1)
	t.near(h2 - foe2.health, Person.SOLDIER_BLOW, 0.001, "a soldier strikes with the soldier's blow")
	fx2.free()
	s.stop_fighting()

	# The foe falls early: the order is over at once, and the shake-off applies.
	var w: Person = crowd.citizens[54]
	var f3: Person = crowd.citizens[55]
	w.ground_pos = base + Vector2(1.0, 1.0)
	f3.ground_pos = w.ground_pos + Vector2(0.3, 0.0)
	var fx3 := FxTimeline.cast(MindWhisperFx, ctx, w.ground_pos, {"target": w, "order": "attack", "foe": f3})
	for k in 80:
		w.ground_pos = base + Vector2(1.0, 1.0)
		if f3.is_alive():
			f3.ground_pos = w.ground_pos + Vector2(0.3, 0.0)
			f3.state = DummyEnemy.State.WANDER
		w._think(0.1)
		fx3._process(0.1)
	t.check(not f3.is_alive() and w.mind != Person.Mind.FIGHT and w.shaken(), "a foe who falls ends the order: shaken (%s)" % Person.Mind.keys()[w.mind])
	fx3.free()

	# An evacuee set on someone flees again once it is over.
	var e: Person = crowd.citizens[56]
	var f4: Person = crowd.citizens[57]
	e.ground_pos = base + Vector2(-1.0, 1.0)
	f4.ground_pos = e.ground_pos + Vector2(0.3, 0.0)
	e.flee()
	var fx4 := FxTimeline.cast(MindWhisperFx, ctx, e.ground_pos, {"target": e, "order": "attack", "foe": f4})
	fx4._process(0.1)
	var f4_h := f4.health
	for k in 110:
		e.ground_pos = base + Vector2(-1.0, 1.0)
		f4.ground_pos = e.ground_pos + Vector2(0.3, 0.0)
		f4.health = f4_h
		f4.state = DummyEnemy.State.WANDER
		e._think(0.1)
		fx4._process(0.1)
	t.check(e.mind == Person.Mind.FLEE, "an evacuee set on someone flees again afterwards (%s)" % Person.Mind.keys()[e.mind])
	fx4.free()

	# Another power taking the mind over ends the order without a stale wake: a later fight is an ordinary fight.
	var o: Person = crowd.citizens[58]
	var f5: Person = crowd.citizens[59]
	o.ground_pos = base + Vector2(2.0, 2.0)
	f5.ground_pos = o.ground_pos + Vector2(0.3, 0.0)
	var fx5 := FxTimeline.cast(MindWhisperFx, ctx, o.ground_pos, {"target": o, "order": "attack", "foe": f5})
	fx5._process(0.1)
	o.fight(null, 5.0, Person.SOLDIER_BLOW, Person.FightRule.ANYONE)
	o.stop_fighting()
	t.check(not o.shaken(), "a fight some other power set is not a whisper's: no shake-off when it ends")
	fx5.free()
	_free_ctx(ctx)


static func _burn(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var ctx := _fx_ctx(made)
	var house: Structure = _houses(env)[0]
	var who: Person = crowd.citizens[60]
	who.ground_pos = grid.nearest_walkable(house.center() + Vector2(3.0, 0.0), 6)
	var fires: FireManager = crowd.fires
	t.check(not fires.is_burning(house), "the house is not burning")
	var fx := FxTimeline.cast(MindWhisperFx, ctx, who.ground_pos, {"target": who, "order": "burn", "building": house})
	fx._process(0.1)
	t.check(who.mind == Person.Mind.WHISPERED and who.goal() != Vector2.INF, "burn: the whispered one is on their way")
	t.check(who.goal().distance_to(house.center()) < house.footprint.size.length() * 0.5 + 2.5, "to the house's edge (%.2f from the middle)"
		% who.goal().distance_to(house.center()))
	# Walking: nothing lit however long it takes.
	for k in 100:
		fx._process(0.1)
	t.check(not fires.is_burning(house), "it is not lit while they are still on the way")
	_arrive(who)
	for k in 25:
		who._think(0.1)
		fx._process(0.1)
	t.check(not fires.is_burning(house), "2.5 s at the house: not yet")
	for k in 8:
		who._think(0.1)
		fx._process(0.1)
	t.check(fires.is_burning(house) and is_equal_approx(fires.intensity(house), EmberFx.START_LEVEL),
		"after 3 s the house burns at Ember's START_LEVEL (%.2f)" % fires.intensity(house))
	for k in 10:
		who._think(0.1)
		fx._process(0.1)
	t.check(who.mind != Person.Mind.WHISPERED and who.shaken(), "then they come to and shake the whisper off (%s)" % Person.Mind.keys()[who.mind])
	fx._process(2.0)
	t.check(fx.finished, "the effect ends")
	fx.free()
	fires.clear()

	# The house is gone when they arrive: nothing.
	var h2: Structure = null
	for s in env.structures():
		if s != house and not s.destroyed and not s.walkable and s.kind == Structure.Kind.HOUSE and FireManager.burns(s):
			h2 = s
			break
	var w: Person = crowd.citizens[61]
	w.ground_pos = grid.nearest_walkable(h2.center() + Vector2(3.0, 0.0), 6)
	var fx2 := FxTimeline.cast(MindWhisperFx, ctx, w.ground_pos, {"target": w, "order": "burn", "building": h2})
	fx2._process(0.1)
	h2.destroyed = true
	_arrive(w)
	for k in 45:
		w._think(0.1)
		fx2._process(0.1)
	t.check(not fires.is_burning(h2) and fires.fires.is_empty(), "a house that fell on the way is not lit")
	fx2.free()
	h2.destroyed = false

	# Diverted on the way (another power's hold): nobody lights anything.
	var h3: Structure = null
	for s in env.structures():
		if s != house and s != h2 and not s.destroyed and not s.walkable and s.kind == Structure.Kind.HOUSE and FireManager.burns(s):
			h3 = s
			break
	var d: Person = crowd.citizens[62]
	d.ground_pos = grid.nearest_walkable(h3.center() + Vector2(3.0, 0.0), 6)
	var fx3 := FxTimeline.cast(MindWhisperFx, ctx, d.ground_pos, {"target": d, "order": "burn", "building": h3})
	fx3._process(0.1)
	_arrive(d)
	fx3._process(1.0)
	d.panic(d.ground_pos + Vector2(1.0, 0.0), 0.5, &"test")
	for k in 40:
		fx3._process(0.1)
	t.check(not fires.is_burning(h3), "one frightened off the order lights nothing")
	fx3.free()

	# No town to keep fires: nothing happens, nothing breaks.
	var ctx2 := _fx_ctx(made, false)
	var w2: Person = crowd.citizens[63]
	w2.ground_pos = grid.nearest_walkable(house.center() + Vector2(3.0, 0.0), 6)
	var fx4 := FxTimeline.cast(MindWhisperFx, ctx2, w2.ground_pos, {"target": w2, "order": "burn", "building": house})
	fx4._process(0.1)
	_arrive(w2)
	for k in 45:
		w2._think(0.1)
		fx4._process(0.1)
	t.check(not fires.is_burning(house), "with no town fires the burn does nothing")
	fx4.free()
	_free_ctx(ctx2)

	# Walk = today's whisper, order word or none.
	var c: Person = crowd.citizens[64]
	var to := grid.nearest_walkable(c.ground_pos + Vector2(3.0, 0.0))
	var fx5 := FxTimeline.cast(MindWhisperFx, ctx, c.ground_pos, {"to": to, "target": c})
	fx5._process(0.1)
	t.check(c.mind == Person.Mind.WHISPERED and c.goal().distance_to(to) < 0.01 and c.whispered_left() > MindWhisperFx.LINGER - 0.5,
		"walk: a cast with {to, target} whispers with the 8 s linger as ever (%.1f)" % c.whispered_left())
	t.check(not fx5.finished and ctx.ground.get_child_count() >= 2, "and marks the spot")
	fx5.free()
	_free_ctx(ctx)
