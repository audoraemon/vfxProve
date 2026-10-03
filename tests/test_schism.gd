extends RefCounted
## Divine Schism: the people of the region are set on two sides and fight the other one, as what they are; those who
## cannot fight run; when its time is up only the sides are lifted. Faction Split sets citizens against soldiers,
## Purge condemns the few at the click, Custom divides two regions, Spreading draws bystanders in.

const PATH := "res://src/fx/dominion/divine_schism.gd"


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## Everyone far off in a corner and calm, on no side.
static func _scatter(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p.side = 0
		p.clear_badge()
		p.stop_fighting()
		if not p.soldier:
			p.mind = Person.Mind.CALM
		i += 1


## A citizen who fights (not one of the roles that run).
static func _fighter(crowd: Crowd, from: int) -> Person:
	for k in range(from, crowd.citizens.size()):
		if DivineSchismFx.fights(crowd.citizens[k]):
			return crowd.citizens[k]
	return null


static func run(t) -> void:
	var book := PowerBook.get_power("schism")
	t.check(PowerBook.authority_of("schism") == "dominion" and int(book.dp) == 6 and not PowerBook.is_quiet("schism")
		and float(book.cooldown) > Rules.MISSION_SECONDS and (book.modes as Array).size() == 4 and PowerBook.REACH.has("schism")
		and PowerBook.icon("schism") != null and PowerBook.hud_icon("schism") != null and PowerBook.clip("schism") != null,
		"%s: Dominion, 6 DP, once a descent, four modes, seen by the town, its icons and clip" % book.name)
	t.check(Rules.POWER_KINDS["schism"] == [&"frenzy"], "its casts are credited with the dead of the fighting")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# Faction Split: citizens against soldiers, each fighting the other as what it is; the roles that cannot fight run.
	_scatter(crowd)
	var a := _fighter(crowd, 0)
	var b := _fighter(crowd, a.stagger + 1)
	var guard: Person = crowd.soldiers[0]
	var carer: Person = null
	for p in crowd.citizens:
		if not DivineSchismFx.fights(p):
			carer = p
			break
	a.ground_pos = at
	b.ground_pos = at + Vector2(0.4, 0.0)
	guard.ground_pos = at + Vector2(0.0, 1.2)  # out of a first blow's reach, so it looks before it is struck
	carer.ground_pos = at + Vector2(0.4, 0.4)
	var bystander: Person = _fighter(crowd, b.stagger + 1)
	bystander.ground_pos = at + Vector2(DivineSchismFx.REGION + 2.0, 0.0)
	var fx: DivineSchismFx = FxTimeline.cast(load(PATH), ctx, at, {"mode": "faction"})
	t.check(fx.busy == 2.0 and a.side == 0, "the cast locks the slots for 2 s; nobody is on a side yet")
	fx._process(1.0)
	t.check(a.side == 1 and b.side == 1 and guard.side == 2 and bystander.side == 0, "citizens on one side, soldiers on the other; beyond the region, no one")
	t.check(a.mind == Person.Mind.FIGHT and guard.mind == Person.Mind.FIGHT and a.badge_color == DivineSchismFx.GOLD
		and guard.badge_color == DivineSchismFx.CRIMSON, "each wears its side's mark and fights")
	t.check(carer.side == 1 and carer.mind != Person.Mind.FIGHT, "one who cannot fight is on a side too, and runs")
	a.tick(0.1)
	a.tick(0.1)
	guard.tick(0.1)
	guard.tick(0.1)
	t.check(a.fight_target == guard and guard.fight_target != null and guard.fight_target.side == 1,
		"they go for the other side, never their own (a: mind %d target %s side %s; guard target %s)" % [a.mind, a.fight_target,
		a.fight_target.side if a.fight_target != null else -1, guard.fight_target])
	var before := guard.health
	for k in 12:
		a.ground_pos = guard.ground_pos + Vector2(0.2, 0.0)
		a.state = DummyEnemy.State.WANDER
		a.tick(0.1)
	t.check(guard.health < before and is_equal_approx(before - guard.health, DivineSchismFx.CIVIL_BLOW * roundf((before - guard.health) / DivineSchismFx.CIVIL_BLOW)),
		"a citizen strikes a citizen's blow (%.2f)" % (before - guard.health))
	fx._process(DivineSchismFx.DURATION)
	t.check(a.side == 0 and guard.side == 0 and a.badge_left == 0.0 and a.mind != Person.Mind.FIGHT and guard.mind == Person.Mind.POST,
		"when its time is up only the sides are lifted: a citizen comes round, a soldier goes back to its post")
	fx._process(1.0)
	fx.free()

	# Purge: the few at the click are condemned and hunted; a condemned citizen runs.
	_scatter(crowd)
	a.ground_pos = at
	b.ground_pos = at + Vector2(4.0, 0.0)
	t.check(DivineSchismFx.condemned_at(ctx.field, at) == [a], "Purge condemns those at the click")
	fx = FxTimeline.cast(load(PATH), ctx, at, {"mode": "purge"})
	fx._process(1.0)
	t.check(a.side == 2 and a.mind != Person.Mind.FIGHT and b.side == 1 and b.mind == Person.Mind.FIGHT,
		"the condemned is on its own side and runs; the rest hunt it")
	b.tick(0.1)
	b.tick(0.1)
	t.check(b.fight_target == a, "they go for the condemned")
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()

	# Custom Division: those round the first click against those round the second.
	_scatter(crowd)
	var other := at + Vector2(7.0, 0.0)
	a.ground_pos = at + Vector2(0.5, 0.0)
	b.ground_pos = other - Vector2(0.5, 0.0)
	bystander.ground_pos = at + Vector2(0.0, DivineSchismFx.CUSTOM_R + 3.0)
	fx = FxTimeline.cast(load(PATH), ctx, at, {"mode": "custom", "to": other})
	fx._process(1.0)
	t.check(a.side == 1 and b.side == 2 and bystander.side == 0, "Custom: the first region on one side, the second on the other, nobody else")
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()

	# Spreading Conflict: a few at the click split in two, and the people beside the fighters are drawn in.
	_scatter(crowd)
	a.ground_pos = at
	b.ground_pos = at + Vector2(0.3, 0.0)
	var near: Array[Person] = []
	for k in 6:
		var q := _fighter(crowd, 60 + k * 3)
		q.ground_pos = at + Vector2(DivineSchismFx.SEED_R + 0.4, 0.3 * float(k))
		near.append(q)
	a.ground_pos = at + Vector2(DivineSchismFx.SEED_R - 0.3, 0.6)  # a seed standing beside them
	fx = FxTimeline.cast(load(PATH), ctx, at, {"mode": "spreading"})
	fx._process(0.5)
	t.check(a.side != 0 and b.side != 0 and a.side != b.side and near[0].side == 0, "Spreading: the few at the click split in two")
	for k in 8:
		a.ground_pos = at + Vector2(DivineSchismFx.SEED_R - 0.3, 0.6)
		fx._process(DivineSchismFx.RECRUIT_EVERY)
	var drawn := 0
	for q in near:
		if q.side != 0:
			drawn += 1
	t.check(drawn >= 2 and fx.members.size() <= DivineSchismFx.SPREAD_MAX, "and the people beside the fighters are drawn in (%d of 6)" % drawn)
	fx._process(DivineSchismFx.DURATION + 1.0)
	fx.free()
	_done(made)
