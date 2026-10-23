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
	# (v0.11.1 R8) A body freed while afflicted is a dead key: the step drops it, and the looks and the scans skip it.
	var ghost := Person.new()
	m.afflicted[ghost] = {"stage": -1, "since": 0.0, "outcome": -1, "broken_at": -INF, "secondary": 0, "tic": 1.0, "concern": 1.0, "shove": 1.0}
	ghost.free()
	var n := m.afflicted.size()
	t.check(m._live().size() == n - 1 and m._maddened_near(alone) >= 0, "a freed afflicted body is skipped by the scans")
	m.step(0.1)
	t.check(m.afflicted.size() == n - 1 and m.afflicted.keys().all(func(k: Variant) -> bool: return is_instance_valid(k)), "and the next step drops its dead key")
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
	t.check(victim.health < Person.HEALTH_CITIZEN and victim.is_down(), "it goes for the nearest and strikes, and the victim is knocked down (%.2f)" % victim.health)
	guard.ground_pos = at + Vector2(20.0, 0.0)  # kept out of it, so the victim's fall is the frenzy's alone
	guard.fight_target = null
	guard.stop_fighting()
	# (People animations) Each blow knocks the bystander down and nobody is beaten on the ground, so the next blow
	# waits until it is up again: the fall takes a while.
	for k in 150:
		victim.ground_pos = mad.ground_pos + Vector2(0.2, 0.0)  # held in reach
		_run_for(crowd, [mad, victim], 0.1)
		if not victim.is_alive():
			break
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
	_people_animations(t)


## Scream then lurch, the swing on a blow, and nobody beaten while down.
static func _people_animations(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var m := crowd.madness
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var mad: Person
	for c in crowd.citizens:
		if c._design() == "resident_a":
			mad = c
			break
	t.check(mad != null, "a resident_a citizen to break (the pilot design)")
	mad.ground_pos = at
	mad.mind = Person.Mind.CALM
	var prey: Person
	for c in crowd.citizens:
		if c != mad:
			prey = c
			break
	prey.ground_pos = at + Vector2(1.4, 0.0)
	prey.mind = Person.Mind.CALM
	# Break into a frenzy: the outcome is a weighted draw, so find a seed that draws it.
	for seed_value in range(1, 200):
		m._rng.seed = seed_value
		if m._draw_outcome() == MadnessManager.Outcome.FRENZY:
			m._rng.seed = seed_value
			break
	mad.statuses[MadnessManager.STATUS] = 1.0
	var rec := {"stage": MadnessManager.Stage.BROKEN, "since": 0.0, "outcome": -1, "broken_at": -INF, "secondary": 0,
		"tic": 99.0, "concern": 99.0, "shove": 99.0}
	m.afflicted[mad] = rec
	m._enter(mad, rec, MadnessManager.Stage.BROKEN)
	t.check(int(rec.outcome) == MadnessManager.Outcome.FRENZY and mad.is_screaming() and mad._sprite_pose()[0] == &"scream",
		"breaking into a frenzy, it screams first")
	_run_for(crowd, [mad], 0.5)
	t.check(mad.mind != Person.Mind.FIGHT and mad.ground_pos == at and mad.is_screaming(),
		"for a second it screams on the spot, not yet fighting")
	_run_for(crowd, [mad], 1.0)
	t.check(mad.mind == Person.Mind.FIGHT and mad.fight_kind == &"madness" and not mad.is_screaming(),
		"then the frenzy starts, a madness fight")
	var lurched := false
	for k in 40:
		_run_for(crowd, [mad], 0.05, 0.05)
		if mad._stride and mad._sprite_pose()[0] == &"lurch":
			lurched = true
			break
	t.check(lurched, "going for its prey, it lurches")
	# A swing shows for SWING_SHOW after a blow.
	var swung := false
	for k in 60:
		prey.ground_pos = mad.ground_pos + Vector2(0.2, 0.0)
		_run_for(crowd, [mad, prey], 0.05, 0.05)
		if mad._swing_left > 0.0:
			swung = mad._sprite_pose()[0] == &"swing"
			break
	t.check(swung, "a blow shows the swing")
	_run_for(crowd, [mad], Person.SWING_SHOW + 0.2, 0.05)
	t.check(mad._swing_left <= 0.0 and mad._sprite_pose()[0] != &"swing", "which does not last")
	# Nobody is beaten on the ground: the attacker picks the one standing.
	var lying: Person = crowd.citizens[30]
	var standing: Person = crowd.citizens[31]
	var brute: Person = crowd.citizens[32]
	for q in [lying, standing, brute]:
		q.mind = Person.Mind.CALM
		q.health = Person.HEALTH_CITIZEN
	brute.ground_pos = at + Vector2(-6.0, 0.0)
	lying.ground_pos = brute.ground_pos + Vector2(0.3, 0.0)
	standing.ground_pos = brute.ground_pos + Vector2(0.9, 0.0)
	lying.knock_down()
	brute.fight(null, 10.0, 0.34, Person.FightRule.ANYONE, Person.FIGHT_SIGHT, &"madness")
	t.check(not brute._fightable(lying) and brute._fightable(standing), "a person lying down is not a target")
	for k in 8:
		_run_for(crowd, [brute], 0.1)
		standing.ground_pos = brute.ground_pos + Vector2(0.9, 0.0)
	t.check(brute.fight_target == standing and lying.health == Person.HEALTH_CITIZEN, "it goes for the one standing")
	var judge := Person.new()
	judge.fight(lying, 5.0, 0.34, Person.FightRule.TARGET_ONLY)
	t.check(judge._fightable(lying), "though a mob set on one person still goes for it")
	judge.free()
	_done(made)
