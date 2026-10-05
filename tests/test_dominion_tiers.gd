extends RefCounted
## Dominion, Tier III and IV: Oathbound binds a few to stay or to hold a place; Command Echo passes from one to the
## next; a Turncoat soldier fights its own and another sabotages; Manufactured Hatred accuses, then goes for one kind;
## Rewrite Priority sends a district to work, to worship, home, out, or makes it fear nothing; Mob Verdict brings down a
## person or a building; Collective Delusion frightens a district with nothing, or calms it with a lie.

const DIR := "res://src/fx/dominion/"
const KEYS := ["oath", "echo", "turncoat", "hatred", "priority", "verdict", "delusion"]


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


## Everyone far off in a corner, calm, with nothing laid on them.
static func _scatter(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p.side = 0
		p.clear_badge()
		p.stop_fighting()
		p.release_compulsion()
		p.fearless_left = 0.0
		p.wait = 0.0
		p.health = Person.HEALTH_SOLDIER if p.soldier else Person.HEALTH_CITIZEN
		if p.soldier:
			p.mind = Person.Mind.POST
		else:
			p.mind = Person.Mind.CALM
		i += 1


static func _cast(ctx: FxContext, file: String, at: Vector2, extra := {}) -> FxTimeline:
	return FxTimeline.cast(load(DIR + file), ctx, at, extra)


## The first citizens of a role, `count` of them.
static func _of_role(crowd: Crowd, role: CitizenProfile.Role, count: int) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.citizens:
		if out.size() < count and p.is_alive() and p.profile != null and p.profile.role == role:
			out.append(p)
	return out


static func run(t) -> void:
	var problems := []
	for key: String in KEYS:
		var b := PowerBook.get_power(key)
		if PowerBook.authority_of(key) != "dominion" or not PowerBook.is_quiet(key) or int(b.dp) < 2 or int(b.dp) > 4 \
				or PowerBook.icon(key) == null or PowerBook.hud_icon(key) == null or PowerBook.clip(key) == null \
				or not ResourceLoader.exists(String(b.path)) or not Targeting.AREAS.has(key):
			problems.append(key)
	t.check(problems.is_empty(), "the seven are quiet Dominion powers of 2-4 DP with their effect, icons, clip and area (%s)" % [problems])

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var residents := _of_role(crowd, CitizenProfile.Role.RESIDENT, 30)
	var a := residents[0]
	var b := residents[1]
	var c := residents[2]
	var guard: Person = crowd.soldiers[0]
	var guard2: Person = crowd.soldiers[1]

	# --- Oathbound
	_scatter(crowd)
	a.ground_pos = at
	guard.ground_pos = at + Vector2(0.5, 0.0)
	b.ground_pos = at + Vector2(OathboundFx.PICK_R + 0.6, 0.0)
	var oath: OathboundFx = _cast(ctx, "oathbound.gd", at, {"mode": "remain"})
	t.check(oath.bound.size() == 2 and a.held_by_will(Person.WILL_FIRM) and guard.mind == Person.Mind.COMPELLED
		and b.mind == Person.Mind.CALM and oath.busy == 1.0, "Oathbound binds the few at the click, a soldier too; nobody beyond")
	a.flee()
	a.go_duty(Vector2.ZERO)
	t.check(a.mind == Person.Mind.COMPELLED and a.anchor.distance_to(at) < 0.01 and oath.keeping() == 2,
		"bound to remain, no evacuation and no duty calls them away")
	a._think(OathboundFx.OATH_TIME + 0.1)
	t.check(a.mind == Person.Mind.RECOVER, "after its long time the oath is lifted")
	oath.free()
	_scatter(crowd)
	a.ground_pos = at
	var hold_at := grid.nearest_walkable(at + Vector2(5.0, 3.0))
	oath = _cast(ctx, "oathbound.gd", at, {"mode": "hold", "to": hold_at})
	t.check(a.mind == Person.Mind.COMPELLED and a.goal().distance_to(oath.place_at) < 2.5 and oath.place_at.distance_to(hold_at) < 2.5,
		"bound to hold a place, they go to it")
	oath.free()

	# --- Command Echo: a line of people, each within reach of the next.
	_scatter(crowd)
	for k in 12:
		residents[k].ground_pos = at + Vector2(1.0 * float(k), 0.0)
	var echo: CommandEchoFx = _cast(ctx, "command_echo.gd", at, {"mode": "home"})
	var seeded := echo.carriers.size()
	t.check(seeded >= 1 and seeded <= CommandEchoFx.SEED_MAX and residents[0].goal().distance_to(residents[0].profile.home) < 1.0,
		"Command Echo starts with the few at the click, sent home (%d)" % seeded)
	t.check(residents[8].mind == Person.Mind.CALM, "the rest have not heard it yet")
	for k in 16:
		echo._process(CommandEchoFx.ECHO_EVERY)
	t.check(echo.carriers.size() > seeded and echo.carriers.size() <= CommandEchoFx.ECHO_MAX and residents[6].mind == Person.Mind.COMPELLED,
		"it passes from one to the next along the line (%d carriers)" % echo.carriers.size())
	echo.free()

	# --- Turncoat: a soldier fights its own, and they strike back; another sabotages.
	_scatter(crowd)
	guard.ground_pos = at
	guard2.ground_pos = at + Vector2(1.0, 0.0)
	var turn: TurncoatFx = _cast(ctx, "turncoat.gd", at)
	t.check(turn.turned == guard and guard.mind == Person.Mind.FIGHT and guard.side == 2 and guard.badge_left > 0.0,
		"Turncoat turns the one at the click")
	guard.tick(0.1)
	guard.tick(0.1)
	t.check(guard.fight_target == guard2, "a turned soldier goes for the other soldiers")
	guard2.hurt(0.1, guard)
	guard2.state = DummyEnemy.State.WANDER
	t.check(guard2.mind == Person.Mind.FIGHT and guard2.fight_target == guard, "and a struck soldier strikes back at the traitor")
	turn._process(TurncoatFx.TURN_TIME + 0.1)
	t.check(guard.side == 0 and guard.mind == Person.Mind.POST, "when its time is up the turning is lifted")
	turn.free()
	_scatter(crowd)
	a.ground_pos = at
	var well := env.add_structure(Rect2(at + Vector2(2.0, 0.0), Vector2(0.5, 0.5)), 24.0, Structure.Kind.FOUNTAIN, &"decor", &"well")
	turn = _cast(ctx, "turncoat.gd", at)
	t.check(turn.turned == a and turn.aim == well and a.mind == Person.Mind.COMPELLED, "a turned citizen makes for the nearest thing of use")
	a.ground_pos = well.center() + Vector2(0.0, 0.6)
	for k in 12:
		turn._process(0.25)
	t.check(well.blighted and turn.ruined == 1, "and ruins it")
	turn._process(TurncoatFx.TURN_TIME)
	turn.free()

	# --- Manufactured Hatred: accusation, then they go for the hated kind and no one else.
	_scatter(crowd)
	a.ground_pos = at
	b.ground_pos = at + Vector2(0.5, 0.0)
	c.ground_pos = at + Vector2(1.5, 0.5)  # a bystander of no hated kind, in the group too
	guard.ground_pos = at + Vector2(2.0, 0.0)
	var hate: ManufacturedHatredFx = _cast(ctx, "manufactured_hatred.gd", at, {"mode": "soldier"})
	t.check(a in hate.group and not guard in hate.group and hate.first == guard and a.mind != Person.Mind.FIGHT and a.wait > 0.0,
		"Manufactured Hatred: the group first stops and accuses; the hated are not of it")
	hate._process(ManufacturedHatredFx.T_ACCUSE + 0.1)
	t.check(a.mind == Person.Mind.FIGHT and a.fight_target == guard and b.fight_target == guard, "then they go for the hated")
	guard.ground_pos = Vector2(-20.0, -20.0)  # gone from sight
	a.fight_target = null
	a.tick(0.1)
	a.tick(0.1)
	t.check(a.fight_target == null, "and for no one else: not for the neighbour beside them")
	hate.free()

	# --- Rewrite Priority.
	var worker: Person = null
	for p in crowd.citizens:
		if p.profile != null and p.profile.works():
			worker = p
			break
	for way: String in ["hide", "work", "ignore", "escape"]:
		_scatter(crowd)
		a.ground_pos = at
		worker.ground_pos = at + Vector2(0.5, 0.5)
		guard.ground_pos = at + Vector2(1.0, 0.0)
		var pri: RewritePriorityFx = _cast(ctx, "rewrite_priority.gd", at, {"mode": way})
		var before := a.mind
		pri._process(RewritePriorityFx.T_CAST + 0.1)
		match way:
			"hide":
				t.check(before == Person.Mind.CALM and a.mind == Person.Mind.COMPELLED and a.goal().distance_to(a.profile.home) < 1.0
					and guard.mind == Person.Mind.COMPELLED, "Rewrite Priority, Hide: after its cast each goes home, a soldier to its post")
			"work":
				t.check(worker.goal().distance_to(worker.profile.work) < 1.0, "Work: each goes to its work")
			"ignore":
				a.panic(a.ground_pos, 0.5)
				a.observe(a.ground_pos)
				t.check(a.mind == Person.Mind.CALM and a.fearless_left > 0.0, "Ignore: nothing frightens them and nothing makes them look")
			"escape":
				t.check(a.mind == Person.Mind.FLEE and guard.mind == Person.Mind.POST, "Escape: citizens make for a way out")
		pri.free()

	# --- Mob Verdict: a person, then a building.
	_scatter(crowd)
	a.ground_pos = at
	var center := at + Vector2(3.0, 0.0)
	b.ground_pos = center
	c.ground_pos = center + Vector2(0.5, 0.0)
	guard.ground_pos = center + Vector2(0.0, 0.5)
	var verdict: MobVerdictFx = _cast(ctx, "mob_verdict.gd", at, {"to": center})
	t.check(verdict.judged == a and verdict.mob.is_empty(), "Mob Verdict judges the one at the first click; the mob has not moved yet")
	verdict._process(MobVerdictFx.T_CAST + 0.1)
	t.check(verdict.mob.size() == 3 and b.fight_target == a and guard.fight_target == a and a.mind != Person.Mind.FIGHT,
		"the second click's circle turns on them, soldiers too (%d)" % verdict.mob.size())
	verdict.free()
	_scatter(crowd)
	var house: Structure = null
	for s in env.structures():
		if s.role == &"house" and not s.destroyed:
			house = s
			break
	center = grid.nearest_walkable(house.center() + Vector2(0.0, 2.5))
	for k in 6:
		residents[k].ground_pos = grid.nearest_walkable(center + Vector2(0.4 * float(k), 0.0))
	verdict = _cast(ctx, "mob_verdict.gd", house.center(), {"to": center})
	verdict._process(MobVerdictFx.T_CAST + 0.1)
	t.check(verdict.building == house and verdict.mob.size() == 6 and residents[0].is_running(), "judging a building, they run to its walls")
	for p in verdict.mob:
		p.ground_pos = p.goal()
	t.check(verdict.at_walls() == 6, "each to a spot of its own at the walls (%d)" % verdict.at_walls())
	var steps := 0
	while not house.destroyed and steps < 80:
		verdict._process(MobVerdictFx.HIT_EVERY)
		steps += 1
	t.check(house.destroyed and house.destroy_kind == &"mob", "and tear it down (%d s)" % steps)
	verdict._process(MobVerdictFx.HIT_EVERY)
	t.check(verdict.mob.is_empty() and residents[0].mind != Person.Mind.COMPELLED, "then they are let go")
	verdict.free()

	# --- Collective Delusion.
	_scatter(crowd)
	crowd.threats.clear()
	a.ground_pos = at + Vector2(1.0, 0.0)
	var dead := crowd.killed_citizens
	var lie: CollectiveDelusionFx = _cast(ctx, "collective_delusion.gd", at, {"mode": "danger"})
	t.check(crowd.threats.active_count() == 0 and a.mind == Person.Mind.CALM, "Collective Delusion: nothing until the belief lands")
	lie._process(CollectiveDelusionFx.T_CAST + 0.1)
	t.check(crowd.threats.active_count() == 1 and a.mind in [Person.Mind.PANIC, Person.Mind.SHELTER] and crowd.killed_citizens == dead,
		"False Danger: the town knows a danger that is not there, and runs or hides from it; nobody is harmed (threats %d, mind %d)"
		% [crowd.threats.active_count(), a.mind])
	lie.free()
	crowd.threats.clear()
	_scatter(crowd)
	a.ground_pos = at
	b.ground_pos = at + Vector2(0.5, 0.0)
	a.panic(at + Vector2(0.2, 0.0), 0.5)
	b.flee()
	crowd.add_alarm(20.0)
	var alarm := crowd.alarm
	lie = _cast(ctx, "collective_delusion.gd", at, {"mode": "calm"})
	lie._process(CollectiveDelusionFx.T_CAST + 0.1)
	t.check(a.mind == Person.Mind.RECOVER and b.mind == Person.Mind.RECOVER and a in lie.reassured
		and is_equal_approx(alarm - crowd.alarm, CollectiveDelusionFx.CALM_ALARM), "All Is Well: the frightened and the fleeing go back to their day, and the alarm falls")
	a.panic(at, 0.5)
	t.check(a.mind == Person.Mind.RECOVER, "nothing frightens them meanwhile")
	b._think(CollectiveDelusionFx.CALM_TIME + 0.1)
	t.check(b.mind == Person.Mind.FLEE, "and one who was leaving the town leaves again when the calm wears off")
	lie.free()
	_done(made)
