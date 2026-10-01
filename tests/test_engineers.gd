extends RefCounted
## v0.05 Engineers: a Prepared town's teams of two turn out at City Emergency and take the job scoring highest on
## priority less distance -- never the same one -- heal damaged buildings while both stand at the site, rebuild a
## fallen gate or the bridge, mend the Citadel only back to its last collapse, and are replaced when one is lost.


static func _crowd(tier := ResponseProfile.Tier.PREPARED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


## Everyone on a team walks straight to their place.
static func _arrive(e: EngineerManager) -> void:
	for team in e.teams:
		for i in team.members.size():
			var p: Person = team.members[i]
			p.ground_pos = team.spots[i]
			p._goal = Vector2.INF
			p._path = PackedVector2Array()


static func _house(env: EnvironmentField, near: Vector2) -> Structure:
	var best: Structure = null
	for s in env.structures():
		if s.role == &"house" and s.art_tag == &"" and (best == null or s.center().distance_to(near) < best.center().distance_to(near)):
			best = s
	return best


static func run(t) -> void:
	var made := _crowd(ResponseProfile.Tier.ORGANIZED)
	t.check((made[0] as Crowd).engineers.teams.is_empty(), "an Organized town has no engineers")
	_done(made)

	made = _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var town: Town = made[5]
	var e := crowd.engineers
	var all_engineers := true
	for team in e.teams:
		for p in team.members:
			all_engineers = all_engineers and (p as Person).profile.role == CitizenProfile.Role.ENGINEER
	t.check(e.teams.size() == 2 and all_engineers and e.workshop != null and grid.walkable(e.base) and not e.active,
		"a Prepared town has two teams of two engineers at the workshop")

	# Off duty until City Emergency.
	var house := _house(env, e.base)
	house.hp = house.max_hp * 0.4
	e.step(1.0)
	t.check(e.teams[0].job.is_empty(), "before City Emergency they go about their day")
	var out := []
	e.turned_out.connect(func() -> void: out.append(true))
	crowd._on_stage(AlarmManager.Stage.CITY_EMERGENCY, "test")
	e.step(0.1)
	t.check(e.active and out.size() == 1 and not e.teams[0].job.is_empty(), "City Emergency turns them out")

	# Scoring: priority less two a unit of travel.
	var job := {"type": EngineerManager.Job.HOUSE, "target": house, "site": e.base + Vector2(3, 4), "rebuild": false}
	t.near(e.score(job, e.base), 20.0 - 2.0 * 5.0, 0.001, "a job scores its priority less its distance")

	# The Citadel, damaged, comes first; the other team takes the house, never the same job.
	var c := town.citadel
	c.health = c.max_health * 0.95
	e.step(EngineerManager.RETHINK)
	var kinds := []
	for team in e.teams:
		kinds.append(team.job.get("type", EngineerManager.Job.NONE))
	t.check(EngineerManager.Job.CITADEL in kinds and EngineerManager.Job.HOUSE in kinds,
		"one team takes the Citadel, the other the house (%s)" % [kinds])
	var on_citadel: Dictionary = e.teams[kinds.find(EngineerManager.Job.CITADEL)]
	var on_house: Dictionary = e.teams[kinds.find(EngineerManager.Job.HOUSE)]

	# Working: only with both at the site; health back RATE a second.
	var before := c.health
	e.step(0.5)
	t.check(c.health == before and not on_citadel.working, "they must reach the site first")
	_arrive(e)
	e.step(1.0)
	t.near(c.health - before, EngineerManager.RATE * c.keep.max_hp, 0.01, "both there, the Citadel is mended")
	t.check(on_house.working and house.hp > house.max_hp * 0.4, "and the house too")
	var p0: Person = on_house.members[0]
	p0.shelters = null
	p0.panic(p0.ground_pos + Vector2(0.5, 0), 1.0, &"heaven")
	var hp := house.hp
	e.step(0.5)
	t.check(not on_house.working and house.hp == hp, "a frightened member stops the work")

	# The Citadel mends only back to its last collapse.
	c._marks = 1
	c.health = c.max_health * 0.85
	c.repair(c.max_health)
	t.near(c.fraction(), 0.9, 0.0001, "the Citadel is mended back to its last collapse, no further")

	# A house's cracks close as it mends.
	var shack := _house(env, Vector2(-10, 5))
	shack.hp = shack.max_hp * 0.3
	shack.crack()
	var cracked := not shack._cracks.is_empty()
	shack.repair(shack.max_hp * 0.5)
	t.check(cracked and shack._cracks.is_empty() and is_equal_approx(shack.hp, shack.max_hp * 0.8),
		"repairs close a building's cracks")
	_done(made)

	# A fallen gate is rebuilt, and the bridge's way across opens again.
	made = _crowd()
	crowd = made[0]
	grid = made[4]
	town = made[5]
	e = crowd.engineers
	var gate: Structure = null
	for g in town.gates:
		if g.footprint == TownLayout.MAIN_GATE:
			gate = g
	gate.destroy(gate.center(), &"nova")
	var rebuilt := []
	e.rebuilt.connect(func(s: Structure) -> void: rebuilt.append(s))
	e.begin()
	e.step(0.1)
	var on_gate: Dictionary = {}
	for team in e.teams:
		if team.job.get("target") == gate:
			on_gate = team
	t.check(not on_gate.is_empty() and on_gate.job.rebuild, "a team goes to rebuild the fallen Main Gate")
	_arrive(e)
	e.step(EngineerManager.REBUILD * 0.5)
	t.check(gate.destroyed and is_equal_approx(e.job_fraction(on_gate), 0.5), "rebuilding takes a while")
	e.step(EngineerManager.REBUILD * 0.5 + 0.1)
	t.check(not gate.destroyed and gate.hp == gate.max_hp and rebuilt == [gate], "then it stands again, as it was")
	# Once the town evacuates, a fallen gate is left open for the crowd.
	gate.destroy(gate.center(), &"nova")
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	var gate_jobs := 0
	for j: Dictionary in e.jobs():
		if j.target == gate:
			gate_jobs += 1
	t.check(gate_jobs == 0, "during the evacuation a fallen gate is left open")
	var bridge := town.bridge
	var mid := bridge.center()
	bridge.destroy(mid, &"nova")
	var cut := not grid.walkable(mid)
	bridge.restore()
	t.check(cut and grid.walkable(mid) and not grid.path(TownLayout.MARKET_SQUARE.get_center(), mid + Vector2(0, 3)).is_empty(),
		"a rebuilt bridge carries people across again")

	# Losses: a team with a dead member is lost; another comes from the workshop later.
	var lost := []
	e.team_lost.connect(func() -> void: lost.append(true))
	var victim: Person = e.teams[0].members[0]
	var survivor: Person = e.teams[0].members[1]
	(made[3] as EnemyField).kill(victim, &"test")
	e.step(0.1)
	t.check(e.teams.size() == 1 and lost.size() == 1 and e.replacing.size() == 1 and survivor.mind != Person.Mind.DUTY,
		"a team with a dead member is lost")
	survivor.mind = Person.Mind.CALM
	e.step(EngineerManager.REPLACE)
	var fresh: Array = e.teams[1].members if e.teams.size() == 2 else []
	t.check(fresh.size() == 2 and survivor in fresh and (fresh[1] as Person).profile.role == CitizenProfile.Role.ENGINEER,
		"%d s later the workshop sends another team" % roundi(EngineerManager.REPLACE))
	(made[3] as EnemyField).kill(fresh[0], &"test")
	e.workshop.destroy(e.workshop.center(), &"nova")
	e.step(EngineerManager.REPLACE + 1.0)
	t.check(e.teams.size() == 1, "but not once the workshop has fallen")
	_done(made)
