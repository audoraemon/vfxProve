extends RefCounted
## Madness Bloom: the cast lays a madness on those in the circle that grows through its stages on its own, faster
## among the maddened, and spreads to the people beside them (capped). Broken, most turn on whoever is near and strike
## until they fall (a frenzy the town sees, that raises the alarm and brings a soldier), others run, wander or freeze.
## Soldiers mostly resist. After its time it ends.

const PATH := "res://src/fx/curse/madness_bloom.gd"


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


## Step the madness and the people for `seconds`, in small steps.
static func _run_for(crowd: Crowd, people: Array, seconds: float, dt := 0.1) -> void:
	var left := seconds
	while left > 0.0:
		for p: Person in people:
			if is_instance_valid(p) and p.is_alive():
				p.tick(dt)
		crowd.madness.step(dt)
		crowd.threats.step(dt)
		left -= dt


static func run(t) -> void:
	var book := PowerBook.get_power("madness")
	t.check(PowerBook.authority_of("madness") == "dominion" and PowerBook.is_quiet("madness") and float(book.alarm) > 0.0
		and PowerBook.icon("madness") != null and PowerBook.hud_icon("madness") != null and PowerBook.clip("madness") != null,
		"%s is a quiet Dominion power with its icons and clip" % book.name)
	t.check(Rules.POWER_KINDS["madness"] == [&"frenzy"], "its casts are credited with the frenzy's dead")
	t.check(MadnessManager.stage_of(0.1) == MadnessManager.Stage.UNEASY and MadnessManager.stage_of(0.5) == MadnessManager.Stage.DISTURBED
		and MadnessManager.stage_of(0.7) == MadnessManager.Stage.UNSTABLE and MadnessManager.stage_of(0.95) == MadnessManager.Stage.BROKEN,
		"the four stages by value")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var m := crowd.madness
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var alone: Person = crowd.citizens[0]
	alone.ground_pos = at
	alone.mind = Person.Mind.CALM
	var bystander: Person = crowd.citizens[1]
	bystander.ground_pos = at + Vector2(MadnessBloomFx.RADIUS + 0.5, 0.0)
	bystander.mind = Person.Mind.CALM

	# Alone: it grows through the stages in about eight seconds and nothing is seen until it breaks.
	var alarm := crowd.alarm
	var fx: MadnessBloomFx = FxTimeline.cast(load(PATH), ctx, at)
	t.check(fx.afflicted == [alone] and alone.statuses.has(MadnessManager.STATUS) and not bystander.statuses.has(MadnessManager.STATUS),
		"the cast lays the madness on those in the circle (%d)" % fx.afflicted.size())
	crowd.on_cast(at, Vector2.ZERO, 0.0, "madness")
	t.check(crowd.threats.active_count() == 0 and is_equal_approx(crowd.alarm - alarm, float(book.alarm)),
		"the town sees no danger and is barely unsettled")
	_run_for(crowd, [alone], 1.0)
	t.check(m.afflicted.has(alone) and MadnessManager.stage_of(m.value_of(alone)) == MadnessManager.Stage.UNEASY,
		"a second in, it is uneasy (%.2f)" % m.value_of(alone))
	_run_for(crowd, [alone], 3.0)
	t.check(MadnessManager.stage_of(m.value_of(alone)) == MadnessManager.Stage.DISTURBED,
		"four seconds in, disturbed (%.2f)" % m.value_of(alone))
	_run_for(crowd, [alone], 2.0)
	t.check(MadnessManager.stage_of(m.value_of(alone)) == MadnessManager.Stage.UNSTABLE,
		"six seconds in, unstable (%.2f)" % m.value_of(alone))
	_run_for(crowd, [alone], 3.0)
	t.check(MadnessManager.stage_of(m.value_of(alone)) == MadnessManager.Stage.BROKEN and m.broken == 1,
		"nine seconds in, broken (%.2f)" % m.value_of(alone))
	var outcome: int = m.afflicted[alone].outcome
	t.check(outcome >= 0 and outcome < MadnessManager.Outcome.size(), "with one of the outcomes (%d)" % outcome)
	fx._process(3.0)
	fx.free()
	m.clear()
	alone.statuses.clear()
	alone.mind = Person.Mind.CALM

	# A crowd: the maddened hurry each other on and pass it to the people beside them, within the caps.
	var group: Array[Person] = []
	for k in 6:
		var c: Person = crowd.citizens[2 + k]
		c.ground_pos = at + Vector2(0.3 * float(k % 3), 0.3 * float(k / 3))
		c.mind = Person.Mind.CALM
		c.statuses[MadnessManager.STATUS] = MadnessBloomFx.SEED
		group.append(c)
	var neighbours: Array[Person] = []
	for k in 4:
		var c: Person = crowd.citizens[8 + k]
		c.ground_pos = at + Vector2(0.9, 0.3 * float(k))
		c.mind = Person.Mind.CALM
		neighbours.append(c)
	_run_for(crowd, group + neighbours, 3.0)
	t.check(m.value_of(group[0]) > 0.3 * 1.1 + MadnessBloomFx.SEED, "in a crowd the madness grows faster (%.2f after 3 s)" % m.value_of(group[0]))
	var caught := 0
	for c in neighbours:
		if c.statuses.has(MadnessManager.STATUS):
			caught += 1
	t.check(caught >= 1, "and passes to the people beside them (%d of 4)" % caught)
	var secondary_ok := true
	for p: Person in m.afflicted:
		secondary_ok = secondary_ok and int(m.afflicted[p].secondary) <= MadnessManager.MAX_SECONDARY_TARGETS
	t.check(secondary_ok and m.afflicted.size() <= MadnessManager.MAX_AFFLICTED, "never past the caps")
	for c in group + neighbours:
		c.statuses.clear()
		c.mind = Person.Mind.CALM
	m.clear()

	# A frenzy: strikes until the victim falls; the town sees a danger and a soldier at its post comes.
	var mad: Person = crowd.citizens[20]
	var victim: Person = crowd.citizens[21]
	var guard: Person = crowd.soldiers[0]
	mad.ground_pos = at
	victim.ground_pos = at + Vector2(0.3, 0.0)
	guard.ground_pos = at + Vector2(2.0, 0.0)
	guard.mind = Person.Mind.POST
	mad.mind = Person.Mind.CALM
	victim.mind = Person.Mind.CALM
	alarm = crowd.alarm
	mad.fight(null, MadnessManager.FRENZY_DURATION, MadnessManager.ATTACK_DAMAGE)
	m._outbreak(mad)
	t.check(mad.mind == Person.Mind.FIGHT and mad.intent() == Person.Intent.FRENZY, "broken into a frenzy")
	t.check(crowd.threats.active_count() == 1 and crowd.alarm > alarm, "the town sees a danger and the alarm rises")
	t.check(guard.mind == Person.Mind.FIGHT and guard.fight_target == mad, "the nearest soldier at its post comes for them")
	var kills := crowd.killed_citizens
	_run_for(crowd, [mad, victim], 0.3)
	t.check(mad.fight_target == victim and victim.health < Person.HEALTH_CITIZEN, "it goes for the nearest and strikes (%.2f)" % victim.health)
	guard.ground_pos = at + Vector2(20.0, 0.0)  # kept out of it, so the victim's fall is the frenzy's alone
	guard.fight_target = null
	guard.stop_fighting()
	for k in 30:
		victim.ground_pos = mad.ground_pos + Vector2(0.2, 0.0)  # held in reach
		_run_for(crowd, [mad, victim], 0.1)
	t.check(not victim.is_alive() and victim._kind == &"frenzy" and crowd.killed_citizens == kills + 1,
		"three blows and the victim falls, a death the town counts")
	for k in 10:
		mad.tick(MadnessManager.FRENZY_DURATION / 10.0)
	t.check(mad.mind != Person.Mind.FIGHT, "the frenzy ends on its own")

	# Soldiers mostly resist; a struck soldier turns on its attacker.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var resisted := 0
	for k in 100:
		if MadnessManager.resists(guard, rng):
			resisted += 1
	t.check(resisted > 60 and resisted < 95, "a soldier resists most of the time (%d of 100)" % resisted)
	guard.ground_pos = at
	guard.mind = Person.Mind.POST
	var brute: Person = crowd.citizens[22]
	brute.ground_pos = at + Vector2(0.2, 0.0)
	brute.mind = Person.Mind.CALM
	guard.hurt(0.3, brute)
	t.check(guard.mind == Person.Mind.FIGHT and guard.fight_target == brute and guard.health < Person.HEALTH_SOLDIER,
		"a struck soldier turns on its attacker")
	_done(made)
