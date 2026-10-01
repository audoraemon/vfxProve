extends RefCounted
## v0.07 Escorts: the patrol soldiers guard the responders on duty -- the bellkeeper, the clergy's rite, each engineer
## team -- profile.escorts_per_duty each; a bellkeeper killed before the bell rang is replaced by an escort (a slower
## climb), an engineer by one of its team's; a guarded responder confused near its escort comes to sooner; when the
## duty ends they go back to their posts.


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
	var home := bell_escorts.size() == per and not bell_escorts.has(new_keeper)
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
