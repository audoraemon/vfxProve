extends RefCounted
## v0.07 Rescue squads: a collapsing shelter traps some of those inside instead of killing them all; a squad from the
## barracks goes to the rubble and digs one out every DIG_TIME; the untended die after TRAPPED_LIFE; an idle squad
## turns out to a fire.


static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
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


## `n` citizens put inside `s` as ShelterManager would.
static func _shelter(crowd: Crowd, s: Structure, n: int) -> Array[Person]:
	var inside: Array[Person] = []
	for p in crowd.citizens:
		if p.is_alive() and not p.inside and inside.size() < n:
			inside.append(p)
	for p in inside:
		crowd.shelters._enter(p, s)
		(crowd.shelters.shelters[s].inside as Array).append(p)
	return inside


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var r := crowd.rescue
	t.check(r.squads.size() == crowd.profile.rescue_squads, "%d rescue squads from the barracks" % r.squads.size())

	# A shelter collapses on ten people: some are trapped, the rest die.
	var s: Structure = crowd.shelters.shelters.keys()[0]
	var inside := _shelter(crowd, s, 10)
	var killed := crowd.killed_citizens
	s.destroy(s.center(), &"nova")
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.3)
	var trapped := r.trapped_at(s)
	t.check(trapped > 0 and trapped < 10 and crowd.killed_citizens - killed == 10 - trapped,
		"a collapse traps %d of the 10 inside; the rest die" % trapped)

	# A squad goes to the rubble and digs them out, one every DIG_TIME.
	var firsts := []
	r.first_rescue.connect(func() -> void: firsts.append(true))
	r.step(0.6)
	var squad: Dictionary = {}
	for sq in r.squads:
		if sq.site == s:
			squad = sq
	t.check(not squad.is_empty(), "a squad goes to the rubble")
	var running := not squad.is_empty()
	for m in squad.get("members", []):
		running = running and (m as Person).hurrying and (m as Person).mind == Person.Mind.POST
	t.check(running, "the squad runs to the rubble")
	for m in squad.get("members", []):
		var p: Person = m
		p.ground_pos = squad.spot
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
	r.step(RescueManager.DIG_TIME + 0.1)
	var freed: Person = null
	for p in inside:
		if p.is_alive() and not p.inside:
			freed = p
	t.check(r.rescued == 1 and freed != null and freed.visible and firsts.size() == 1,
		"one dug out after %d s, frightened and alive" % roundi(RescueManager.DIG_TIME))

	# Untended, the trapped die.
	for m in squad.members:
		(made[3] as EnemyField).kill(m, &"test")
	# (the squad is not given new work yet) A squad wiped out gives up its site for another to take.
	r._in = 10.0
	r.step(0.1)
	t.check(squad.site == null, "a squad wiped out frees its site")
	var left := r.trapped_at(s)
	r.step(RescueManager.TRAPPED_LIFE + 0.1)
	t.check(left > 0 and r.trapped_at(s) == 0 and r.died == left, "left untended, the trapped die (%d died)" % r.died)
	crowd.clear()
	(made[2] as Node).free()

	# An idle squad turns out to a fire.
	made = _crowd()
	crowd = made[0]
	r = crowd.rescue
	var house: Structure = null
	var yard := TownLayout.BARRACKS_YARD.get_center()
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and st.kind == Structure.Kind.HOUSE and (house == null
				or st.center().distance_to(yard) < house.center().distance_to(yard)):
			house = st
	crowd.alarms.stage = AlarmManager.Stage.CONCERN
	crowd.fires.ignite(house, 0.4)
	r.step(0.6)
	var at_fire := 0
	for sq in r.squads:
		for m in sq.members:
			if (m as Person).mind == Person.Mind.ASSIST and (m as Person).assist_fire == house:
				at_fire += 1
	t.check(at_fire >= Crowd.RESCUE_SQUAD and (crowd.fires.fires[house].responders as Array).size() >= Crowd.RESCUE_SQUAD,
		"an idle squad turns out to a fire (%d soldiers)" % at_fire)
	crowd.clear()
	(made[2] as Node).free()
