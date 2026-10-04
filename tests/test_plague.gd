extends RefCounted
## v0.06 Pestilence, retuned in v0.07.1: up to three caught at the cast, soldiers too; the sick slow down, pass it each
## second to those packed near them, and die PLAGUE_LIFE (5 s) later as ordinary deaths -- a soldier's counted as a
## soldier killed; never more than PLAGUE_MAX sick; it spreads inside a shelter, and one who dies in there is carried
## out first. The cast is no danger the town can see.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var plague := crowd.plague
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.9, -27.0 + float(i / 20) * 0.9)
		i += 1
	var at := Vector2(0.8, 2.0)

	# The cast: the three nearest healthy people, soldiers too.
	var group: Array[Person] = []
	for k in 5:
		var p: Person = crowd.citizens[k]
		p.ground_pos = at + Vector2(0.12 * k, 0.0)
		group.append(p)
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at
	var victims := PestilenceFx.victims_at(field, at)
	t.check(victims.size() == PestilenceFx.INFECT_MAX and soldier in victims and group[3] not in victims
		and group[4] not in victims, "it catches the three nearest people, soldiers too")
	t.check(soldier.infect(PlagueManager.PLAGUE_LIFE) and soldier.sick_left > 0.0, "soldiers catch it (v0.07.1)")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "pestilence")
	t.check(crowd.threats.active_count() == 0, "the cast is no danger the town can see")

	# The sick slow down.
	var sick: Person = group[0]
	var pace := sick._mind_speed()
	sick.infect(PlagueManager.PLAGUE_LIFE)
	t.check(is_equal_approx(sick._mind_speed(), pace * Person.SICK_PACE), "the sick move at 70% of their pace")

	# Spread through a packed group.
	for k in range(1, 5):
		group[k].ground_pos = sick.ground_pos + Vector2(0.1 * k, 0.05)
	for k in 6:
		var p: Person = crowd.citizens[10 + k]
		p.ground_pos = sick.ground_pos + Vector2(-0.08 * k, 0.1)
		group.append(p)
	# Nothing spreads before SPREAD_EVERY has passed; the next step takes it past.
	plague.step(PlagueManager.SPREAD_EVERY * 0.5)
	var early := 0
	for p in group:
		if p != sick and p.sick_left > 0.0:
			early += 1
	t.check(early == 0, "nobody catches it before %.0f s have passed (%d did)" % [PlagueManager.SPREAD_EVERY, early])
	plague.step(PlagueManager.SPREAD_EVERY * 0.6)
	t.check(soldier in plague.sick, "a soldier infected outside the spread is on the sick list once a scan has run")
	var caught := 0
	for p in group:
		if p != sick and p.sick_left > 0.0:
			caught += 1
	t.check(caught > 0 and caught < group.size() - 1, "a sick person passes it to some of those packed round it (%d of %d)"
		% [caught, group.size() - 1])
	# It passes to a soldier packed beside the sick, too.
	var s2: Person = crowd.soldiers[1]
	s2.ground_pos = sick.ground_pos + Vector2(0.05, -0.05)
	for k in 20:
		if s2.sick_left > 0.0:
			break
		plague._spread()
	t.check(s2.sick_left > 0.0, "it spreads to soldiers")

	# Deaths, 5 s after catching it, as ordinary deaths -- a soldier's too.
	var killed := crowd.killed_citizens
	var killed_soldiers := crowd.killed_soldiers
	plague.step(PlagueManager.PLAGUE_LIFE - PlagueManager.SPREAD_EVERY - 0.5)
	t.check(sick.is_alive(), "still alive just before its time")
	plague.step(1.0)
	t.check(not sick.is_alive(), "the sick die %.0f s after catching it" % PlagueManager.PLAGUE_LIFE)
	plague.step(PlagueManager.PLAGUE_LIFE)
	t.check(crowd.killed_citizens - killed >= 1 + caught and plague.deaths >= 1 + caught,
		"as ordinary deaths (%d dead)" % (crowd.killed_citizens - killed))
	t.check(crowd.killed_soldiers - killed_soldiers >= 1, "a soldier dies of it too, counted as a soldier killed")

	# Never more than PLAGUE_MAX sick.
	var n := 0
	for p in crowd.citizens:
		if p.is_alive() and n < PlagueManager.PLAGUE_MAX:
			p.infect(PlagueManager.PLAGUE_LIFE)
			p.ground_pos = at + Vector2(0.05 * float(n % 10), 0.05 * float(n / 10))
			n += 1
	plague.step(PlagueManager.SPREAD_EVERY)
	var all_sick := 0
	for p in crowd.citizens:
		if p.is_alive() and p.sick_left > 0.0:
			all_sick += 1
	t.check(all_sick == PlagueManager.PLAGUE_MAX, "never more than %d sick at once (%d)" % [PlagueManager.PLAGUE_MAX, all_sick])
	for p in crowd.citizens:
		p.sick_left = 0.0
	plague.step(0.1)

	# Inside a shelter it spreads too, and a death inside is carried out first.
	var shelter: Structure = crowd.shelters.shelters.keys()[0]
	var inside: Array[Person] = []
	for p in crowd.citizens:
		if p.is_alive() and inside.size() < 6:
			inside.append(p)
	for p in inside:
		crowd.shelters._enter(p, shelter)
		(crowd.shelters.shelters[shelter].inside as Array).append(p)
	inside[0].infect(PlagueManager.PLAGUE_LIFE)
	for k in 3:
		plague.step(PlagueManager.SPREAD_EVERY)
	var caught_inside := 0
	for p in inside.slice(1):
		if p.sick_left > 0.0:
			caught_inside += 1
	t.check(caught_inside > 0, "people sheltering together pass it on (%d of 5)" % caught_inside)
	plague.step(PlagueManager.PLAGUE_LIFE)
	t.check(not inside[0].inside and not inside[0].is_alive(), "and one who dies in there is carried out first")
	crowd.clear()
	world.free()
