extends RefCounted
## v0.07 Escorts: the patrol soldiers guard the responders on duty -- the bellkeeper, the clergy's rite, each engineer
## team -- profile.escorts_per_duty each; a bellkeeper killed before the bell rang is replaced by an escort (a slower
## climb), an engineer by one of its team's; a guarded responder confused near its escort comes to sooner; when the
## duty ends they go back to their posts. Once the soldiers have rallied, an escort killed is replaced from the ring.

const CorpsTest := preload("res://tests/test_corps.gd")


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


## Whether no person is in `people` twice.
static func _distinct(people: Array) -> bool:
	for i in people.size():
		if people.find(people[i]) != i:
			return false
	return true


static func _arrive(p: Person) -> void:
	if p.goal() != Vector2.INF:
		p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var esc := crowd.escorts
	var per := crowd.profile.escorts_per_duty

	# The bell: escorts join the bellkeeper when it is called.
	var bell := crowd.bell
	bell.call_keeper()
	esc.step(1.0)
	var guards: Array = esc.guards.get("bell", [])
	var near := true
	for g: Person in guards:
		near = near and g.corps == Person.Corps.ESCORT and g.goal().distance_to(bell.keeper.ground_pos) <= EscortManager.REACH + 0.5
	t.check(guards.size() == per and near, "%d escorts join the bellkeeper" % guards.size())
	t.check(_distinct(guards), "each of them a different soldier")
	# They run to their charge as the bellkeeper does, not at a soldier's walk.
	var gap := 0.0
	for g: Person in guards:
		gap = maxf(gap, absf(g._mind_speed() - Person.PANIC_SPEED * g.pace))
	t.near(gap, 0.0, 0.001, "the escorts run to the bellkeeper (%.1f u/s)" % (Person.PANIC_SPEED * guards[0].pace))

	# The bellkeeper killed before the bell rang: an escort takes over, its climb slower.
	var replaced := []
	bell.keeper_replaced.connect(func() -> void: replaced.append(true))
	var climb := bell.climb
	field.kill(bell.keeper, &"test")
	# The escorts' own look at the duties can come between the keeper's death and the bell's next step (Crowd steps the
	# bell first, but the death can fall inside the same frame): they must keep their duty for the bell to find them.
	esc.step(1.0)
	t.check(esc.guards.has("bell") and (esc.guards["bell"] as Array).size() == per,
		"the escorts keep the bell's duty while its keeper lies dead")
	bell.step(0.1)
	t.check(bell.keeper != null and bell.keeper.soldier and bell.state == BellNetwork.State.CALLED and replaced.size() == 1
		and is_equal_approx(bell.climb, climb * BellNetwork.ESCORT_CLIMB),
		"an escort takes the bell rope (climb %.1f s)" % bell.climb)
	var new_keeper := bell.keeper
	esc.step(1.0)
	var bell_escorts: Array = (esc.guards.get("bell", []) as Array).duplicate()
	_arrive(new_keeper)
	bell.step(0.1)
	bell.step(bell.climb + 0.1)
	t.check(bell.state == BellNetwork.State.RUNG and crowd.alarms.bell_rung, "and the bell still rings")
	esc.step(1.0)
	t.check(not esc.guards.has("bell") and new_keeper.mind == Person.Mind.POST and new_keeper.anchor == new_keeper.post,
		"the bell rung, the stand-in goes back to its post")
	# Every escort that was still guarding the bell goes back to its post, and no longer at a run.
	# (The stand-in came from the guard and was not replaced from the town's other escorts: per - 1 are left.)
	var home := bell_escorts.size() == per - 1 and not bell_escorts.has(new_keeper)
	var slow := 0.0
	for g: Person in bell_escorts:
		home = home and g.mind == Person.Mind.POST and g.anchor == g.post and not g.hurrying
		slow = maxf(slow, absf(g._mind_speed() - Person.WALK_SPEED * g.pace))
	t.check(home, "and the %d escorts still on guard go back to their posts" % bell_escorts.size())
	t.near(slow, 0.0, 0.001, "at a walk again")

	# Engineers: escorts join a team; an engineer killed is replaced by one of them.
	var e := crowd.engineers
	e.begin()
	e.step(0.1)
	esc.step(1.0)
	var team: Dictionary = e.teams[0]
	var key := "team:%d" % int(team.id)
	t.check((esc.guards.get(key, []) as Array).size() == per, "escorts join each engineer team")
	var all_guards := []
	for k in esc.guards:
		all_guards.append_array(esc.guards[k])
	t.check(_distinct(all_guards), "no soldier guards two places at once")
	var lost := []
	e.team_lost.connect(func() -> void: lost.append(true))
	var teams := e.teams.size()
	var dead: Person = team.members[0]
	field.kill(dead, &"test")
	e.step(0.1)
	var stand_in: Person = team.members[0]
	t.check(e.teams.size() == teams and lost.is_empty() and stand_in.soldier and stand_in.mind == Person.Mind.DUTY,
		"an engineer killed is replaced by an escort; the team goes on")

	# A guarded responder confused near its escort comes to sooner.
	var guarded: Person = team.members[1]
	for g: Person in esc.guards.get(key, []):
		g.ground_pos = guarded.ground_pos + Vector2(0.5, 0.0)
	guarded.confuse(15.0)
	esc.step(1.0)
	t.check(guarded._confused_left <= EscortManager.STEADY_TIME, "a guarded engineer confused near its escort comes to sooner")
	crowd.clear()
	(made[2] as Node).free()
	_bell_takeovers(t)
	_top_up(t)
	_silenced(t)
	_hurry(t)
	_reserve(t)


## The reserve (v0.09.1): once the soldiers have rallied, an escort killed on duty is replaced by the nearest soldier on
## the ring -- it takes the role and the dead one's post, and the duty's guard is whole again with it.
static func _reserve(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var esc := crowd.escorts
	var per := crowd.profile.escorts_per_duty
	var bell := crowd.bell
	bell.call_keeper()
	esc.step(1.0)
	crowd.rally()
	CorpsTest.ring(crowd)
	var ring := CorpsTest.on_ring(crowd)
	var dead: Person = (esc.guards["bell"] as Array)[0]
	var nearest: Person = ring[0]
	for p in ring:
		if p.ground_pos.distance_to(dead.ground_pos) < nearest.ground_pos.distance_to(dead.ground_pos):
			nearest = p
	field.kill(dead, &"test")
	t.check(nearest.corps == Person.Corps.ESCORT and nearest.post == dead.post and not crowd.on_ring(nearest),
		"an escort killed on duty: the nearest soldier on the ring takes its role and its post")
	var guards: Array = esc.guards["bell"]
	t.check(guards.has(nearest) and not guards.has(dead) and guards.size() == per and esc.guarding(nearest),
		"and guards the bell in its place")
	t.check(nearest.mind == Person.Mind.POST and nearest.hurrying
		and nearest.goal().distance_to(bell.keeper.ground_pos) <= EscortManager.REACH + 0.5,
		"running to the bellkeeper")
	esc.step(1.0)
	guards = esc.guards["bell"]
	t.check(guards.has(nearest) and guards.size() == per and CorpsTest.on_ring(crowd).size() == ring.size() - 1,
		"the duty keeps it, and is not topped up past its %d; the ring is one fewer" % per)
	crowd.clear()
	(made[2] as Node).free()


## Notes every soldier guarding the bell in `ever`.
static func _note(ever: Dictionary, esc: EscortManager) -> void:
	for g in esc.guards.get("bell", []):
		ever[g] = true


## A duty is given its escorts once, over its whole life: killing the bellkeeper again and again meets the escorts one
## by one and then the bell is silenced, whatever other escorts the town has.
static func _bell_takeovers(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var esc := crowd.escorts
	var bell := crowd.bell
	var per := crowd.profile.escorts_per_duty
	var free := 0
	for p in crowd.soldiers:
		free += 1 if p.corps == Person.Corps.ESCORT else 0
	var ever := {}  # every soldier that guarded the bell, at any step
	bell.call_keeper()
	esc.step(1.0)
	_note(ever, esc)
	t.check(per == 2 and ever.size() == per and free > per + 1,
		"the bell is called and %d of the town's %d escorts join it" % [ever.size(), free])
	for n in per:
		field.kill(bell.keeper, &"test")
		esc.step(1.0)
		_note(ever, esc)
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.CALLED and bell.keeper.soldier and bell.keeper.is_alive(),
			"killed, the keeper is replaced by escort %d of %d" % [n + 1, per])
		esc.step(1.0)  # (the look that used to top the duty back up from the town's free escorts)
		_note(ever, esc)
		t.check((esc.guards.get("bell", []) as Array).size() == per - 1 - n,
			"the stand-in is not replaced on the guard (%d left)" % (esc.guards.get("bell", []) as Array).size())
	field.kill(bell.keeper, &"test")
	esc.step(1.0)
	_note(ever, esc)
	bell.step(0.1)
	t.check(bell.state == BellNetwork.State.SILENCED and not crowd.alarms.bell_rung,
		"with its escorts gone, the keeper killed once more silences the bell")
	esc.step(1.0)
	_note(ever, esc)
	t.check(ever.size() == per, "and no escort beyond the %d the duty began with ever joined it" % ever.size())
	crowd.clear()
	(made[2] as Node).free()


## A duty that started with too few free escorts tops up later, but never beyond its share; a guard that falls is not
## made up.
static func _top_up(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var esc := crowd.escorts
	var per := crowd.profile.escorts_per_duty
	var escorts: Array[Person] = []
	for p in crowd.soldiers:
		if p.corps == Person.Corps.ESCORT:
			escorts.append(p)
	for p in escorts:
		p.corps = Person.Corps.NONE  # none free
	crowd.bell.call_keeper()
	esc.step(1.0)
	t.check((esc.guards.get("bell", []) as Array).is_empty(), "a duty with no free escorts starts with none")
	for p in escorts:
		p.corps = Person.Corps.ESCORT
	esc.step(1.0)
	var mine: Array = (esc.guards.get("bell", []) as Array).duplicate()
	t.check(mine.size() == per, "and tops up from the escorts free later (%d)" % mine.size())
	field.kill(mine[0], &"test")
	esc.step(1.0)
	t.check((esc.guards.get("bell", []) as Array).size() == per - 1, "a guard that falls is not made up")
	crowd.clear()
	(made[2] as Node).free()


## A keeper still on the rope when the bell is silenced (the tower cracks under it) is let go: an escort stand-in goes
## back to its post, a citizen to its day.
static func _silenced(t) -> void:
	for soldier in [false, true]:
		var made := _crowd()
		var crowd: Crowd = made[0]
		var bell := crowd.bell
		bell.call_keeper()
		if soldier:
			(made[3] as EnemyField).kill(bell.keeper, &"test")
			crowd.escorts.step(1.0)
			bell.step(0.1)
		var keeper := bell.keeper
		t.check(keeper.mind == Person.Mind.DUTY and keeper.soldier == soldier,
			"%s on the rope" % ("an escort" if soldier else "the bellkeeper"))
		(made[1] as EnvironmentField).blight(bell.tower)
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.SILENCED and keeper.mind != Person.Mind.DUTY,
			"the bell cracked and silenced, the keeper is let go")
		if soldier:
			t.check(keeper.mind == Person.Mind.POST and keeper.anchor == keeper.post and not crowd.escorts.guarding(keeper),
				"an escort back at its post, free for another duty")
		crowd.clear()
		(made[2] as Node).free()


## A soldier hurrying to its post stays at a run until it is there: a route that closes under it drops the goal, and
## the re-path to the post is as quick as the first leg. At its post it shifts about at a walk. (Drives _pick_target()
## and _think() on one soldier, with its path set by hand, not a walk through the town.)
static func _hurry(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var s: Person = null
	for p in crowd.soldiers:
		if p.corps == Person.Corps.ESCORT:
			s = p
			break
	var here := s.ground_pos
	var spot := crowd._spot_near(here + Vector2(6.0, 0.0), 0.2)
	t.check(spot.distance_to(here) > 3.0, "a post the soldier is well away from")
	var shut := Vector2.INF
	for st in (made[1] as EnvironmentField).structures():
		if st.role == &"house" and not grid.walkable(st.center()):
			shut = st.center()
			break
	t.check(shut != Vector2.INF, "a way that is closed (a house's middle)")

	s.send_to_post(spot, false, true)
	t.check(s.hurrying and not s.unhurried(), "sent at a run, a soldier is hurrying and not calm")
	s._path = PackedVector2Array([shut])
	s._leg = 0
	s._pick_target()
	t.check(s._goal == Vector2.INF and s.hurrying,
		"its way closed under it, the goal is dropped and it is still hurrying")
	s._repath_in = 0.0
	s._think(0.1)
	t.check(s.has_goal() and s.goal().distance_to(spot) < 0.01 and is_equal_approx(s._mind_speed(), Person.PANIC_SPEED * s.pace),
		"and the re-path to its post is at a run")

	s._goal = Vector2.INF
	s._path = PackedVector2Array()
	s._leg = 0
	s.ground_pos = spot
	s._pick_target()
	t.check(not s.hurrying and is_equal_approx(s._mind_speed(), Person.WALK_SPEED * s.pace),
		"at its post, it is at a walk again")
	t.check(s.unhurried(), "and calm again")
	crowd.clear()
	(made[2] as Node).free()
