extends RefCounted
## v0.09 Crowd.raise_profile: between the acts of a night the town rises -- never lowers. The responses its old profile
## lacked turn on (the rite, the boats and the postern, the engineers, more marshals) unless their building is gone,
## and ones already due by the alarm stage start at once. Also a gate held shut for a while (the festival's crowd), and
## the leaderless town that never rallies.

const DT := 0.1


## A town spawned at `tier`, or as The Warning's Unaware town.
static func _crowd(tier := ResponseProfile.Tier.ORGANIZED, unaware := false) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware() if unaware else ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func _count(crowd: Crowd, corps: Person.Corps) -> int:
	var n := 0
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.corps == corps:
			n += 1
	return n


static func _prepared() -> ResponseProfile:
	return ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)


static func run(t) -> void:
	t.check(ResponseProfile.for_tier(ResponseProfile.Tier.UNPREPARED).level() == 0
		and ResponseProfile.unaware().level() == 1
		and ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED).level() == 2
		and _prepared().level() == 3
		and ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT).level() == 4,
		"the profiles rank Unprepared 0, Unaware 1, Organized 2, Prepared 3, God-Resistant 4")

	# Never lower: an Organized town offered Unaware keeps what it has.
	var made := _crowd()
	var crowd: Crowd = made[0]
	var before := crowd.profile
	var on := crowd.raise_profile(ResponseProfile.unaware())
	t.check(on.is_empty() and crowd.profile == before and crowd.profile.escorts_per_duty == 1,
		"a town is never lowered (%s)" % [on])
	_done(made)

	# Unaware to Organized: the responders get their escorts; nothing new turns on.
	made = _crowd(ResponseProfile.Tier.ORGANIZED, true)
	crowd = made[0]
	t.check(crowd.profile.escorts_per_duty == 0 and crowd.rite.off_by_profile and crowd.ferry.off_by_profile
		and _count(crowd, Person.Corps.ESCORT) == 0, "an Unaware town has no escorts, and no rite or boats by its profile")
	on = crowd.raise_profile(ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED))
	t.check(crowd.profile.escorts_per_duty == 1 and crowd.profile.tier_name() == "Organized"
		and _count(crowd, Person.Corps.ESCORT) == 1, "raised to Organized, its responders are escorted (v0.09.1: by 1)")
	t.check(on.is_empty(), "and nothing new turns on (%s)" % [on])
	_done(made)

	# Organized to Prepared: the rite, the boats (the postern opens), the engineers, more marshals.
	made = _crowd()
	crowd = made[0]
	var town: Town = made[5]
	var grid: WalkGrid = made[4]
	t.check(not town.postern.walkable and not grid.walkable(town.postern.center()), "an Organized town's postern is barred")
	t.check(crowd.engineers.teams.is_empty() and _count(crowd, Person.Corps.MARSHAL) == 3 * 2,
		"and it has no engineers, and 6 marshals")
	on = crowd.raise_profile(_prepared())
	t.check(on == PackedStringArray(["rite", "boats", "engineers", "marshals"]),
		"raised to Prepared: the rite, the boats, the engineers and more marshals turn on (%s)" % [on])
	t.check(crowd.rite.state == BanishingRite.State.IDLE and not crowd.rite.off_by_profile,
		"the rite waits for City Emergency (%s)" % BanishingRite.State.keys()[crowd.rite.state])
	t.check(crowd.ferry.state == RiverFerry.State.MOORED and crowd.evac.ferry == crowd.ferry
		and crowd.evac.boat_exit >= 0, "the boats are moored, and the dock is a way out")
	t.check(crowd.engineers.teams.size() == 2, "two teams of engineers (%d)" % crowd.engineers.teams.size())
	t.check(town.postern.walkable and grid.walkable(town.postern.center()), "the postern is open")
	var marshals := _count(crowd, Person.Corps.MARSHAL)
	t.check(marshals == 4 * 4, "4 marshals for each of 4 ways out (%d)" % marshals)
	var rescue := _count(crowd, Person.Corps.RESCUE)
	t.check(rescue == 3 * Crowd.RESCUE_SQUAD, "the rescue squads are not raised (%d)" % rescue)
	var escorts := _count(crowd, Person.Corps.ESCORT)
	t.check(escorts == 2 * (1 + 1 + 2), "the escorts are raised to what Prepared's duties use (v0.09.1: %d)" % escorts)
	# Raised again to the same level: nothing more.
	t.check(crowd.raise_profile(_prepared()).is_empty() and _count(crowd, Person.Corps.MARSHAL) == 16
		and _count(crowd, Person.Corps.ESCORT) == escorts, "raised again to Prepared, nothing more turns on")
	_done(made)

	# Responses already due: at City Emergency the rite gathers and the engineers turn out at once.
	made = _crowd()
	crowd = made[0]
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, 0.0)
	for i in 5:
		crowd.advance(DT)
	t.check(crowd.alarms.stage == AlarmManager.Stage.CITY_EMERGENCY, "the town is at City Emergency")
	on = crowd.raise_profile(_prepared())
	t.check(on.has("rite") and crowd.rite.state == BanishingRite.State.GATHERING,
		"raised then, the clergy gather at once (%s)" % BanishingRite.State.keys()[crowd.rite.state])
	t.check(on.has("engineers") and crowd.engineers.active, "and the engineers turn out")
	t.check(crowd.ferry.state == RiverFerry.State.MOORED, "the boats wait for the evacuation")
	_done(made)

	# And at the evacuation the boats take people at once, and the marshals take the ways out.
	made = _crowd()
	crowd = made[0]
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, 0.0)
	crowd.alarms.update(AlarmManager.EVAC_NO_BELL, 0, crowd.alarms.regroup_seconds + 1.0)
	t.check(crowd.alarms.stage == AlarmManager.Stage.EVACUATION and crowd.marshals.active,
		"the town is evacuating, its marshals posted")
	on = crowd.raise_profile(_prepared())
	t.check(on.has("boats") and crowd.ferry.state == RiverFerry.State.LOADING,
		"raised then, the boats take people at once (%s)" % RiverFerry.State.keys()[crowd.ferry.state])
	_done(made)

	# Review focus 3: the cathedral fallen and the dock ruined before the raise -- the rite and the boats are skipped.
	made = _crowd()
	crowd = made[0]
	town = made[5]
	var old_rite := crowd.rite
	var old_ferry := crowd.ferry
	crowd.rite.cathedral.destroy(crowd.rite.cathedral.center(), &"stone")
	crowd.ferry.dock.destroy(crowd.ferry.dock.center(), &"stone")
	t.check(crowd.rite.cathedral.destroyed and crowd.ferry.dock.destroyed, "the cathedral and the dock are down")
	on = crowd.raise_profile(_prepared())
	t.check(not on.has("rite") and crowd.rite == old_rite and crowd.rite.state == BanishingRite.State.ENDED,
		"a fallen cathedral holds no rite: it stays ended (%s)" % [on])
	t.check(not on.has("boats") and crowd.ferry == old_ferry and crowd.ferry.state == RiverFerry.State.ENDED
		and crowd.evac.boat_exit == -1, "a ruined dock runs no boats: they stay ended, no way out by the river")
	t.check(not town.postern.walkable, "and the postern stays barred")
	t.check(on.has("engineers") and on.has("marshals"), "the rest still turn on (%s)" % [on])
	_done(made)

	# A gate held shut for 5 s: its crowd grows and waits, then passes.
	made = _crowd()
	crowd = made[0]
	town = made[5]
	var gate: Structure = null
	for g in town.gates:
		if g.footprint == TownLayout.MAIN_GATE:
			gate = g
	var spots := crowd.queue_spots(gate)
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	crowd.hold_gate(gate, 5.0)
	for k in 4:
		var p: Person = crowd.citizens[40 + k]
		p.mind = Person.Mind.FLEE
		p.ground_pos = spots[k]
	var passing := 0
	var most := 0
	var grew := false
	for i in roundi(5.0 / DT) - 1:
		if i == 20:
			var first := crowd.waiting_at(gate)
			for k in 4:
				var p: Person = crowd.citizens[44 + k]
				p.mind = Person.Mind.FLEE
				p.ground_pos = spots[4 + k]
			crowd.advance(DT)
			grew = crowd.waiting_at(gate) > first
		else:
			crowd.advance(DT)
		most = maxi(most, crowd.waiting_at(gate))
		for p in crowd.citizens:
			if is_instance_valid(p) and p.passing_gate == gate:
				passing += 1
	t.check(passing == 0 and grew and most >= 8, "a held gate lets nobody through; its crowd grows (%d waiting)" % most)
	for i in roundi(3.0 / DT):
		crowd.advance(DT)
	var after := crowd.waiting_at(gate)
	t.check(after < most, "after 5 s it lets them through (%d still waiting)" % after)
	_done(made)

	# The leaderless town: a forgone rally sends nobody to the ring.
	made = _crowd()
	crowd = made[0]
	var rallied := []
	crowd.rallied.connect(func() -> void: rallied.append(true))
	crowd.forgo_rally()
	crowd.rally()
	var ringed := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			ringed += 1
	t.check(ringed == 0 and rallied.is_empty(), "after a forgone rally nobody rallies (%d)" % ringed)
	_done(made)
