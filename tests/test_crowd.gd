extends RefCounted
## The crowd: who spawns where, what frightens them, the alarm's thresholds, the gate queue, escapes, the
## soldiers' rally, and what happens once the Citadel falls.


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

	t.check(crowd.citizens.size() == Crowd.CITIZENS and crowd.soldiers.size() == Crowd.SOLDIERS,
		"%d citizens and %d soldiers (%d / %d)" % [Crowd.CITIZENS, Crowd.SOLDIERS, crowd.citizens.size(), crowd.soldiers.size()])
	var off_grid := 0
	for p in crowd.citizens + crowd.soldiers:
		if not grid.walkable(p.ground_pos):
			off_grid += 1
	t.check(off_grid == 0, "everyone stands on walkable ground (%d do not)" % off_grid)
	# Every citizen has a profile: roles in the spec's shares, a walkable home, work for the working roles, leisure.
	var roles := {}
	var profiles_ok := true
	var outside := 0
	for p in crowd.citizens:
		var pr: CitizenProfile = p.profile
		roles[pr.role] = int(roles.get(pr.role, 0)) + 1
		profiles_ok = profiles_ok and grid.walkable(pr.home) and not pr.leisure.is_empty()
		profiles_ok = profiles_ok and pr.works() == CitizenProfile.WORK.has(pr.role)
		if pr.works():
			profiles_ok = profiles_ok and grid.walkable(pr.work)
			if not TownLayout.TOWN.has_point(pr.work):
				outside += 1
	var shares_ok := true
	for sh in CitizenProfile.SHARES:
		shares_ok = shares_ok and absi(int(roles.get(sh[0], 0)) - roundi(float(sh[1]) * Crowd.CITIZENS)) <= 1
	t.check(profiles_ok and shares_ok, "citizens' roles in the spec's shares, with walkable homes, work and leisure (%s)"
		% [roles])
	# Their day: once a citizen's stay is over, RoutineManager sends it to one of its own places.
	var routine_ok := crowd.routine != null
	var sent := 0
	for i in 20:
		var p := crowd.citizens[i]
		p._goal = Vector2.INF
		crowd.routine.visit(i, 100.0)
		if p.has_goal():
			sent += 1
			var pr: CitizenProfile = p.profile
			routine_ok = routine_ok and (p.anchor == pr.home or p.anchor == pr.work or p.anchor in pr.leisure
				or p.anchor in crowd.routine._stalls)
	# The roster shrinks as people escape or die; the manager's place in it must follow.
	var full := crowd.citizens.duplicate()
	crowd.routine._at = crowd.citizens.size() - 1
	crowd.citizens = crowd.citizens.slice(0, 10)
	crowd.routine.step(1.0)
	t.check(crowd.routine._at < 10, "the routine keeps its place within a shrunken roster")
	crowd.citizens = full
	t.check(routine_ok and sent == 20, "a citizen whose stay is over is sent to one of its places (%d of 20)" % sent)
	t.check(outside >= Crowd.CITIZENS * 0.08 and outside <= Crowd.CITIZENS * 0.2,
		"about a tenth work outside the walls (%d)" % outside)
	# Soldiers are posted in order: the yard's first, then walls, Citadel and patrols. A patrol's post on the east
	# street can land beside the yard, so the yard is checked by who was posted there, not by who stands near it.
	var in_yard := 0
	var at_citadel := 0
	for i in crowd.soldiers.size():
		var p := crowd.soldiers[i]
		if i < Crowd.POST_YARD:
			if TownLayout.BARRACKS_YARD.grow(0.6).has_point(p.anchor):
				in_yard += 1
		elif p.anchor.distance_to(TownLayout.CITADEL_ORIGIN) <= Crowd.RING_RADIUS + 1.2:
			at_citadel += 1
	t.check(in_yard == Crowd.POST_YARD, "%d soldiers drill in the yard (%d)" % [Crowd.POST_YARD, in_yard])
	t.check(at_citadel >= 10, "at least 10 guard the Citadel (%d)" % at_citadel)
	var soldiers_calm := true
	for p in crowd.soldiers:
		soldiers_calm = soldiers_calm and p.mind == Person.Mind.POST
	t.check(soldiers_calm, "soldiers start at their posts")

	# A cast frightens the people near it and nobody else.
	var near := crowd.citizens[0]
	near.ground_pos = Vector2(0.0, 0.0)
	var far := crowd.citizens[1]
	far.ground_pos = Vector2(0.0, 8.0)
	crowd.on_cast(Vector2(0.0, 0.0))
	t.check(near.mind == Person.Mind.PANIC, "a cast nearby starts a panic")
	t.check(far.mind != Person.Mind.PANIC and far.mind != Person.Mind.FLEE,
		"one 8 units away is not frightened (it stops to look: %s)" % Person.Mind.keys()[far.mind])

	# A building falling frightens the people beside it and raises the alarm.
	var alarm_before := crowd.alarm
	var market: Structure = null
	for s in env.structures():
		if s.role == &"market":
			market = s
			break
	var beside := crowd.citizens[2]
	beside.ground_pos = market.center() + Vector2(1.0, 0.0)
	market.destroy(market.center() + Vector2(2.0, 0.0), &"stone")
	t.near(crowd.alarm - alarm_before, Crowd.ALARM_BUILDING * Crowd.UNWARNED_ALARM, 0.001,
		"a destroyed building is worth 2 alarm -- half until the bell has rung")
	t.check(beside.mind == Person.Mind.PANIC or beside.mind == Person.Mind.SHELTER,
		"and frightens the people beside it (run or take cover)")

	# The Citadel's parts do not each count as a building, but the first hit on it is worth 10 and rallies.
	alarm_before = crowd.alarm
	town.citadel.parts[0].destroy(TownLayout.CITADEL_ORIGIN, &"stone")
	t.near(crowd.alarm, alarm_before, 0.001, "a Citadel part is not counted as a building")
	town.citadel.keep.damage(20.0, TownLayout.CITADEL_ORIGIN, &"stone")
	t.check(crowd.alarm >= alarm_before + Crowd.ALARM_CITADEL_HIT * Crowd.UNWARNED_ALARM,
		"the first hit on the Citadel is worth 10 (half before the bell)")
	var rallying := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			rallying += 1
	t.check(rallying == crowd.soldiers.size(), "every soldier rallies to the Citadel (%d)" % rallying)

	# Kills raise the alarm and are counted by kind (after the bell, events count in full).
	crowd.alarms.bell_rung = true
	alarm_before = crowd.alarm
	field.kill(crowd.citizens[3], &"nova")
	field.kill(crowd.soldiers[0], &"nova")
	t.near(crowd.alarm - alarm_before, Crowd.ALARM_KILL * 2.0, 0.001, "each death is worth half a point once the bell has rung")
	t.check(crowd.killed_citizens == 1 and crowd.killed_soldiers == 1, "deaths are counted per kind")

	# Without the bell, the evacuation comes at 90 alarm, once families have had time to regroup: every citizen runs.
	crowd.add_alarm(AlarmManager.EVAC_NO_BELL)
	crowd._clock += AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(0.001)
	# Households regrouped at home leave together, at the latest after their wait.
	var households := crowd._households.size()
	crowd._clock += Crowd.HOUSEHOLD_WAIT
	crowd._tend_households()
	crowd.shelters.step(1.0)
	t.check(households > 0 and crowd._households.is_empty(), "regrouped households wait, then leave together (%d)" % households)
	var still_calm := 0
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.mind != Person.Mind.FLEE:
			still_calm += 1
	t.check(still_calm == 0 and crowd.alarms.stage >= AlarmManager.Stage.EVACUATION,
		"at 90%% alarm with no bell the town evacuates: nobody stays (%d did)" % still_calm)

	# A gate's waiting crowd: everyone waiting gets a spot of their own in front of the doorway, spread out
	# rather than stacked, and one person at a time is let through.
	var gate: Structure = town.gates[0]
	var spots := crowd.queue_spots(gate)
	t.check(spots.size() >= 20, "a gate has room for a crowd in front of it (%d spots)" % spots.size())
	# Nothing built in town may eat into a gate's queue: each keeps at least the room it had before the density
	# pass (Main Gate 219 spots, Side Gate 213), and no queue spot lies in anything TownLayout builds near it.
	var side_spots := crowd.queue_spots(town.gates[1])
	t.check(spots.size() >= 219 and side_spots.size() >= 213,
		"the gates keep their queue room (%d, %d spots)" % [spots.size(), side_spots.size()])
	var fans := TownLayout.queue_fans(0.2)
	var in_fan := 0
	for p: Vector2 in spots + side_spots:
		for fan in fans:
			if Geometry2D.is_point_in_polygon(p, fan):
				in_fan += 1
				break
	t.check(in_fan == spots.size() + side_spots.size(), "every queue spot lies inside its gate's fan (%d of %d)"
		% [in_fan, spots.size() + side_spots.size()])
	var tightest := INF
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			tightest = minf(tightest, spots[i].distance_to(spots[j]))
	t.check(tightest >= Crowd.QUEUE_SPACING * 0.8, "and the spots are spread out (closest pair %.2f)" % tightest)
	var spots_off_grid := 0
	for s in spots:
		if not grid.walkable(s):
			spots_off_grid += 1
	t.check(spots_off_grid == 0, "every spot is somewhere a person can stand (%d are not)" % spots_off_grid)

	var queue: Array[Person] = []
	for i in 12:
		var p: Person = crowd.citizens[10 + i]
		p.ground_pos = gate.center() - gate.center().normalized() * 1.0 + Vector2(0.02 * i, 0.0)
		queue.append(p)
	# Everyone else waits at the market -- far enough that nobody else reaches this gate during the test, so the
	# crowd at it is exactly these twelve.
	for p in crowd.citizens:
		if is_instance_valid(p) and not queue.has(p):
			p.ground_pos = TownLayout.MARKET_SQUARE.get_center()
	crowd.advance(0.0)
	var released := 0
	var placed: Array[Vector2] = []
	for p in queue:
		if p.queue_spot == Vector2.INF:
			released += 1
		else:
			placed.append(p.queue_spot)
	t.check(released == 1, "one person is let through at a time (%d were)" % released)
	var doubled := 0
	for i in placed.size():
		for j in range(i + 1, placed.size()):
			if placed[i].is_equal_approx(placed[j]):
				doubled += 1
	t.check(placed.size() == 11 and doubled == 0, "the other eleven wait on eleven different spots (%d shared)" % doubled)
	t.check(crowd.waiting_at(gate) == 11, "and the gate counts them (%d)" % crowd.waiting_at(gate))

	# Walk them: after two intervals they have spread onto their spots and the queue has moved on by one.
	for i in int(Crowd.GATE_INTERVAL * 2.0 * 60.0) + 30:
		crowd.advance(1.0 / 60.0)
		for p in queue:
			if is_instance_valid(p):
				p.tick(1.0 / 60.0)
	# Only people standing on their spot count as waiting: everyone started at the gate, the queue has moved
	# everyone on by a spot each time someone was let through, and a few are still on their way out to the fan's
	# far edge, passing others as they go.
	var settled: Array[Person] = []
	var waiting := 0
	for p in queue:
		if is_instance_valid(p) and p.queue_spot != Vector2.INF:
			waiting += 1
			# At its spot: within 0.6 of a spacing of it (still shuffling in); the stacking check below then asks
			# whether any two of them stand on top of each other.
			if p.ground_pos.distance_to(p.queue_spot) <= Crowd.QUEUE_SPACING * 0.6:
				settled.append(p)
	t.check(settled.size() >= 3, "some of the waiting crowd stands on its spots (%d of %d)" % [settled.size(), waiting])
	var stacked := 0
	for i in settled.size():
		for j in range(i + 1, settled.size()):
			if settled[i].ground_pos.distance_to(settled[j].ground_pos) < Crowd.QUEUE_SPACING * 0.5:
				stacked += 1
	t.check(stacked == 0, "waiting people stand apart instead of on top of each other (%d pairs stacked)" % stacked)
	t.check(crowd.waiting_at(gate) <= 10, "and the gate has let more through (%d still waiting)" % crowd.waiting_at(gate))

	# This synthetic crowd is done with the gate: send it away and forget the gate's pass, so the throughput test
	# below starts with an idle gate.
	for p in queue:
		if is_instance_valid(p):
			p.release_from_queue()
			p.ground_pos = gate.center() - gate.center().normalized() * (Crowd.QUEUE_DEPTH0 + Crowd.QUEUE_REACH + 3.0)
	crowd._gate_next.erase(gate)
	crowd.advance(0.0)

	# Reaching an exit escapes.
	var runner: Person = crowd.citizens[20]
	var before_count := crowd.citizens.size()
	runner.ground_pos = TownLayout.EXITS[1]
	runner.set_goal(TownLayout.EXITS[1])
	var reported: Array = []
	crowd.escaped.connect(func(p: Person): reported.append(p))
	crowd.advance(0.1)
	t.check(crowd.escaped_count == 1 and reported.size() == 1, "reaching an exit counts as an escape")
	t.check(crowd.citizens.size() == before_count - 1, "and takes them off the streets")

	# Once the Citadel falls the soldiers hold its rubble.
	for i in 12:
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 4.0, 99999.0, &"nova")
	t.check(town.citadel.is_fallen(), "the Citadel fell")
	var holding := true
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive():
			holding = holding and p.mind == Person.Mind.HOLD
	t.check(holding, "the surviving soldiers hold their ground")

	# Throughput: one person through a gate every GATE_INTERVAL. Walk whoever holds the pass for five intervals.
	var flow_gate: Structure = town.gates[0]
	var middle := flow_gate.center()
	var walkers: Array[Person] = []
	for i in 6:
		var w: Person = crowd.citizens[30 + i]
		w.ground_pos = middle + Vector2(0.0, -0.2 - 0.1 * float(i))
		w.wait = 0.0
		walkers.append(w)
	var through := 0
	for step in int(Crowd.GATE_INTERVAL * 5.0 * 60.0):
		crowd.advance(1.0 / 60.0)
		for w in walkers:
			if w.queue_spot == Vector2.INF:
				w.ground_pos += Vector2(0.0, 1.2 / 60.0)
		for w in walkers.duplicate():
			# Counted at the doorway itself: a finish line further out would measure the walk to it as well.
			if w.ground_pos.y > middle.y:
				walkers.erase(w)
				through += 1
	# Five turns fit in five intervals, and each walker spends part of its own turn stepping up to the middle,
	# so four is the floor the gate has to clear.
	t.check(through >= 4, "about one person every %.1f s gets through the gate (%d in five intervals)" % [Crowd.GATE_INTERVAL, through])

	# Milestone 3 reads these: the spawned population, and a destroy that says what killed it.
	t.check(crowd.spawned_citizens == Crowd.CITIZENS and crowd.spawned_soldiers == Crowd.SOLDIERS,
		"the spawned population is recorded (%d / %d)" % [crowd.spawned_citizens, crowd.spawned_soldiers])
	var kinds: Array = []
	env.structure_destroyed.connect(func(s: Structure, kind: StringName): kinds.append([s.role, kind]))
	var victim: Structure = null
	for s in env.structures():
		if s.role == &"house" and not s.destroyed:
			victim = s
			break
	victim.destroy(victim.center() + Vector2(1.0, 0.0), &"cinder")
	t.check(kinds.size() == 1 and kinds[0][0] == &"house" and kinds[0][1] == &"cinder",
		"a destroyed building reports the damage kind that did it (%s)" % [kinds])

	crowd.clear()
	t.check(crowd.citizens.is_empty() and crowd.soldiers.is_empty(), "clear() empties the town")
	t.check(crowd.spawned_citizens == 0 and crowd.spawned_soldiers == 0, "clear() forgets the spawned population")
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
