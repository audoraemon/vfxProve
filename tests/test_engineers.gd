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

	_fires(t)
	_fire_before_mending(t)
	_return_after_fright(t)


## v0.08.2: a team with nothing to mend fights the nearest fire, through the evacuation too, and goes back to
## mending when there is a job.
static func _fires(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var e := crowd.engineers
	var fm := crowd.fires
	e.begin()
	e.step(0.1)
	var idle := true
	for team in e.teams:
		idle = idle and team.job.is_empty() and (team.members[0] as Person).mind == Person.Mind.DUTY
	t.check(idle and e.jobs().is_empty(), "with nothing to mend and nothing burning, the teams stand by")

	var house := _house(env, e.base)
	fm.ignite(house, 0.4)
	t.check(e.jobs().is_empty(), "a burning house is no job to mend")
	e.step(EngineerManager.RETHINK)
	var all_on := true
	for team in e.teams:
		for p in team.members:
			var m: Person = p
			all_on = all_on and m.mind == Person.Mind.ASSIST and m.assist_fire == house and m.assist_stays \
				and (fm.fires[house].responders as Array).has(m)
	t.check(all_on, "with nothing to mend, every team turns out to the fire")
	var water := fm.nearest_water(house.center())
	var first: Person = e.teams[0].members[0]
	t.check(first.goal().distance_to(water.center()) < 2.5, "and fetches water like the brigade")
	e.step(0.5)
	t.check(first.mind == Person.Mind.ASSIST, "the team leaves them to their round between rethinks")

	# The evacuation: the brigade stands down, the engineers fight on.
	var brigade: Person = null
	for p in crowd.citizens:
		if p.profile != null and p.profile.role != CitizenProfile.Role.ENGINEER and p.mind == Person.Mind.CALM:
			brigade = p
			break
	brigade.assist(house)
	(fm.fires[house].responders as Array).append(brigade)
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	crowd._evacuate()
	fm._tend_responders(0.1)
	t.check(brigade.mind != Person.Mind.ASSIST and first.mind == Person.Mind.ASSIST,
		"at the evacuation the brigade stands down and runs, the engineers fight on")

	# A job that outranks a fire (v0.09.1: a house no longer does; here the bridge): one team leaves the fire to mend
	# it; the other stays on.
	var shack := (made[5] as Town).bridge
	shack.hp = shack.max_hp * 0.4
	e.step(EngineerManager.RETHINK)
	var mending: Dictionary = {}
	var firefighting: Dictionary = {}
	for team in e.teams:
		if not team.job.is_empty() and team.job.target == shack:
			mending = team
		elif team.job.is_empty():
			firefighting = team
	var back := not mending.is_empty()
	if back:
		for p in mending.members:
			back = back and (p as Person).mind == Person.Mind.DUTY and (p as Person).assist_fire == null \
				and (p as Person).anchor in mending.spots
	t.check(back, "a job to mend calls the first team free back off the fire")
	t.check(not firefighting.is_empty() and (firefighting.members[0] as Person).mind == Person.Mind.ASSIST,
		"the other team stays at the fire")

	# Out: they come back to the workshop.
	fm.fires[house].intensity = 0.05
	fm.douse(house)
	e.step(0.1)
	var home := not firefighting.is_empty()
	if home:
		for i in firefighting.members.size():
			var m: Person = firefighting.members[i]
			home = home and m.mind == Person.Mind.DUTY and m.anchor == firefighting.spots[i] \
				and m.anchor.distance_to(e.base) < 1.0
	t.check(home, "the fire out, the team goes back to the workshop, on call")
	_done(made)

	# An Organized town has no engineers: its fires are the brigade's alone (crowd_check and the Organized checksums).
	made = _crowd(ResponseProfile.Tier.ORGANIZED)
	crowd = made[0]
	crowd.fires.ignite(_house(made[1], Vector2(0, 0)), 0.4)
	crowd.engineers.begin()
	crowd.engineers.step(EngineerManager.RETHINK)
	var assisting := 0
	for p in crowd.citizens:
		assisting += 1 if p.mind == Person.Mind.ASSIST else 0
	t.check(assisting == 0, "an Organized town sends no engineers to a fire")
	_done(made)


## v0.09.1: a burning building outranks mending a damaged house, so a team with nothing better to do fights the fire
## even while houses wait; a gate, the bridge or the dock being rebuilt (and the Citadel, a Thornwall and the landmarks)
## still come first.
static func _fire_before_mending(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var town: Town = made[5]
	var e := crowd.engineers
	var fm := crowd.fires
	var damaged := _house(env, e.base)
	damaged.hp = damaged.max_hp * 0.4
	var burning := _other_house(env, e.base, damaged)
	fm.ignite(burning, 0.4)
	e.begin()
	e.step(0.1)
	var at_fire := 0
	for team in e.teams:
		var m: Person = team.members[0]
		if team.job.is_empty() and m.mind == Person.Mind.ASSIST and m.assist_fire == burning:
			at_fire += 1
	t.check(e.jobs().size() == 1 and e.jobs()[0].target == damaged and at_fire == e.teams.size(),
		"with a damaged house and a burning one in reach, the idle teams go to the fire (%d of %d)" % [at_fire, e.teams.size()])
	t.check(damaged.hp == damaged.max_hp * 0.4, "and the house waits")

	# The fire out, the house is mended after all.
	fm.fires[burning].intensity = 0.05
	fm.douse(burning)
	for k in 6:
		e.step(EngineerManager.RETHINK)
	var mending := 0
	for team in e.teams:
		mending += 1 if not team.job.is_empty() and team.job.target == damaged else 0
	t.check(mending == 1, "the fire out, a team goes back to mend the house")
	_done(made)

	# A team already mending a house leaves it for a fire at the next rethink.
	made = _crowd()
	crowd = made[0]
	env = made[1]
	e = crowd.engineers
	fm = crowd.fires
	damaged = _house(env, e.base)
	damaged.hp = damaged.max_hp * 0.4
	e.begin()
	e.step(0.1)
	var on_house: Dictionary = {}
	for team in e.teams:
		if not team.job.is_empty() and team.job.target == damaged:
			on_house = team
	t.check(not on_house.is_empty(), "a team starts mending the damaged house")
	burning = _other_house(env, e.base, damaged)
	fm.ignite(burning, 0.4)
	e.step(EngineerManager.RETHINK)
	t.check(on_house.job.is_empty() and (on_house.members[0] as Person).mind == Person.Mind.ASSIST
		and (on_house.members[0] as Person).assist_fire == burning, "at the next rethink it leaves the house for the fire")
	_done(made)

	# A rebuild keeps its priority over the fire and the house: one team takes the fallen gate, the other the fire.
	made = _crowd()
	crowd = made[0]
	env = made[1]
	town = made[5]
	e = crowd.engineers
	fm = crowd.fires
	damaged = _house(env, e.base)
	damaged.hp = damaged.max_hp * 0.4
	burning = _other_house(env, e.base, damaged)
	fm.ignite(burning, 0.4)
	var gate: Structure = null
	for g in town.gates:
		if g.footprint == TownLayout.MAIN_GATE:
			gate = g
	gate.destroy(gate.center(), &"nova")
	e.begin()
	e.step(0.1)
	var on_gate := 0
	var on_fire := 0
	for team in e.teams:
		on_gate += 1 if not team.job.is_empty() and team.job.target == gate and team.job.rebuild else 0
		on_fire += 1 if team.job.is_empty() and (team.members[0] as Person).mind == Person.Mind.ASSIST else 0
	t.check(on_gate == 1 and on_fire == 1, "a fallen gate is rebuilt before the fire is fought (%d on it, %d at the fire)"
		% [on_gate, on_fire])
	_done(made)


## A house within FIRE_REACH of `near` that is not `not_this`.
static func _other_house(env: EnvironmentField, near: Vector2, not_this: Structure) -> Structure:
	for s in env.structures():
		if s.role == &"house" and s.art_tag == &"" and s != not_this and s.center().distance_to(near) < EngineerManager.FIRE_REACH:
			return s
	return null


## v0.09.1: an engineer frightened off its team goes back to it once calm, in the evacuation too (it used to run for
## the gates and be lost). When its team is lost, the one left flees as before.
static func _return_after_fright(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var e := crowd.engineers
	var house := _house(env, e.base)
	house.hp = house.max_hp * 0.4
	e.begin()
	e.step(0.1)
	var team: Dictionary = {}
	for tm in e.teams:
		if not tm.job.is_empty():
			team = tm
	var m: Person = team.members[0]
	var job: Dictionary = team.job
	# Frightened just as the evacuation is called.
	m.shelters = null
	m.panic(m.ground_pos + Vector2(0.5, 0), 1.0, &"heaven")
	t.check(m.mind == Person.Mind.PANIC, "(set-up) the engineer is frightened")
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	crowd._evacuate()
	t.check(m.mind == Person.Mind.PANIC, "frightened as the town evacuates, an engineer is not sent to the gates")
	m._recover(0.5)
	e.step(0.1)
	t.check(m.mind == Person.Mind.DUTY and m.anchor == team.spots[0] and team.job == job,
		"it calms and goes back to its team's job, not to flight")

	# Frightened during the evacuation, it still goes back.
	m.panic(m.ground_pos + Vector2(0.5, 0), 1.0, &"heaven")
	t.check(m.mind == Person.Mind.PANIC, "(set-up) frightened again, after the evacuation was called")
	m._recover(0.5)
	e.step(0.1)
	t.check(m.mind == Person.Mind.DUTY and team.job == job, "frightened after the evacuation, it goes back too")

	# Out of a shelter it ran into while the town evacuates.
	m.mind = Person.Mind.SHELTER
	m.leave_shelter(true)
	t.check(m.mind != Person.Mind.FLEE, "out of a shelter during the evacuation it does not flee")
	e.step(0.1)
	t.check(m.mind == Person.Mind.DUTY, "and goes back to its team")

	# A citizen who is no engineer is sent to the gates from the same states.
	var other: Person = null
	for p in crowd.citizens:
		if p.profile != null and p.profile.role != CitizenProfile.Role.ENGINEER:
			other = p
			break
	other.mind = Person.Mind.SHELTER
	other.leave_shelter(true)
	t.check(other.mind == Person.Mind.FLEE, "anyone else out of a shelter during the evacuation flees")

	# The team stands down (a member dies after the evacuation): the one left, recovering, flees as before.
	var partner: Person = team.members[1]
	m._recover(5.0)
	(made[3] as EnemyField).kill(partner, &"test")
	e.step(0.1)
	t.check(m.mind == Person.Mind.FLEE, "when its team is lost in the evacuation, the one left flees")
	_done(made)
