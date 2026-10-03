extends RefCounted
## v0.08 Mind Whisper's mind: a whispered person drops whatever it was doing, walks (not runs) to the spot, lingers
## there, then resumes -- flight again if it was fleeing, else its day, where a duty's manager takes it back. Soldiers,
## anyone inside and the dead do not hear it.


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


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _think(p: Person, seconds: float) -> void:
	var step := 0.1
	var t := 0.0
	while t < seconds:
		p._think(step)
		t += step


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var p: Person = crowd.citizens[0]
	var to := grid.nearest_walkable(p.ground_pos + Vector2(3.0, 0.0))
	t.check(p.whisper(to, 8.0) and p.mind == Person.Mind.WHISPERED, "a calm citizen hears the whisper")
	t.check(p.goal().distance_to(to) < 0.01 and p.walk_speed <= Person.WALK_SPEED * p.pace + 0.001,
		"and walks to the spot (%.2f)" % p.walk_speed)
	t.check(p.intent() == Person.Intent.WHISPERED, "its intent reads WHISPERED")
	_think(p, 3.0)
	t.check(p.mind == Person.Mind.WHISPERED, "the linger does not start on the way")
	_arrive(p)
	_think(p, 7.0)
	t.check(p.mind == Person.Mind.WHISPERED, "it lingers there")
	_think(p, 1.5)
	t.check(p.mind == Person.Mind.RECOVER, "after 8 s it goes back to its day (%s)" % Person.Mind.keys()[p.mind])

	# Flight is picked up again.
	var f: Person = crowd.citizens[1]
	f.flee()
	f.whisper(grid.nearest_walkable(f.ground_pos + Vector2(0.0, 2.0)), 8.0)
	_arrive(f)
	_think(f, 8.5)
	t.check(f.mind == Person.Mind.FLEE, "a whispered evacuee flees again after")

	# A duty: the bell's keeper drops the climb and the bell waits for it.
	var keeper: Person = crowd.bell.keeper
	crowd.bell.call_keeper()
	t.check(keeper.mind == Person.Mind.DUTY, "the keeper is called")
	keeper.whisper(grid.nearest_walkable(keeper.ground_pos + Vector2(-3.0, 0.0)), 8.0)
	crowd.bell.step(0.1)
	t.check(crowd.bell.state == BellNetwork.State.WAITING, "the bell waits for its whispered keeper")
	for i in 30:
		crowd.bell.step(0.5)
	t.check(keeper.mind == Person.Mind.WHISPERED, "and does not take it back mid-whisper")

	# Immune: soldiers, the dead, anyone inside.
	t.check(not crowd.soldiers[0].whisper(Vector2.ZERO, 8.0), "soldiers do not hear it")
	var inside: Person = crowd.citizens[2]
	inside.inside = true
	t.check(not inside.whisper(Vector2.ZERO, 8.0), "nor does anyone inside")
	inside.inside = false
	var dead: Person = crowd.citizens[3]
	(made[3] as EnemyField).kill(dead, &"doom", dead.ground_pos)
	t.check(not dead.whisper(Vector2.ZERO, 8.0), "nor the dead")

	# The evacuation leaves a whispered person to its whisper, then it flees.
	var w: Person = crowd.citizens[4]
	w.whisper(grid.nearest_walkable(w.ground_pos + Vector2(2.0, 0.0)), 8.0)
	crowd._evacuate()
	t.check(w.mind == Person.Mind.WHISPERED, "the evacuation call does not break a whisper")
	_arrive(w)
	_think(w, 8.5)
	t.check(w.mind == Person.Mind.FLEE, "and it joins the flight after")
	_done(made)
