extends RefCounted
## v0.04 gate routing: distance fields to each exit, the choice by route length, queue and known danger, rerouting
## with a margin, and danger costed into the walk grid for everyone's paths.


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
	var ev := crowd.evac
	var south := ev.exits.find(TownLayout.EXITS[0])
	var east := ev.exits.find(TownLayout.EXITS[1])

	# The distance field matches the walk grid's own path, give or take its diagonals.
	var from := Vector2(0.8, 2.0)
	var path := grid.path(from, ev.exits[south])
	var along := 0.0
	for k in range(1, path.size()):
		along += path[k].distance_to(path[k - 1])
	var field_len := float(ev._dist(south, from)) * WalkGrid.CELL
	t.check(field_len >= along * 0.95 and field_len <= along * 1.45,
		"the distance field's route length (%.1f) matches the path's (%.1f)" % [field_len, along])

	# By distance alone, people take the nearer way out.
	var p: Person = crowd.citizens[0]
	p.ground_pos = Vector2(2.7, 12.0)
	t.check(ev.choose(p) == ev.exits[south], "near the Main Gate: the south road")
	p.ground_pos = Vector2(13.0, 9.0)
	t.check(ev.choose(p) == ev.exits[east], "near the Side Gate: the east road")

	# Somewhere between the two, a danger at the Main Gate's approach sends it east.
	p.ground_pos = Vector2(4.0, 9.0)
	var before := ev.choose(p)
	crowd.threats.register(Vector2(2.7, 12.0), 2.5, 0.8, 30.0, 8.0, 12.0, &"test")
	var after := ev.choose(p)
	t.check(before == ev.exits[south] and after == ev.exits[east],
		"a danger on the way to the Main Gate sends it to the Side Gate (%s -> %s)" % [before, after])
	crowd.threats.clear()

	# A long queue at the Main Gate does the same.
	var main_gate: Structure = ev.gates[south]
	var spots := crowd.queue_spots(main_gate)
	for k in 40:
		crowd.citizens[10 + k].queue_spot = spots[k]
	t.check(ev.choose(p) == ev.exits[east], "a long queue at the Main Gate sends it to the Side Gate")
	for k in 40:
		crowd.citizens[10 + k].queue_spot = Vector2.INF

	# Rerouting: an evacuee re-checks, and switches when another way is clearly better -- not within 4 s of choosing.
	p.flee()
	p.set_goal(ev.exits[south])
	p.route_since = ev._clock
	crowd.threats.register(Vector2(2.7, 12.0), 2.5, 0.8, 30.0, 8.0, 12.0, &"test")
	ev._recheck(p)
	t.check(p.goal() == ev.exits[south], "not straight after choosing")
	ev._clock += EvacuationManager.SWITCH_WAIT + 0.1
	ev._recheck(p)
	t.check(p.goal() == ev.exits[east] and p.intent() == Person.Intent.REROUTE, "then it reroutes, and shows it")

	# The danger weighs on everyone's paths.
	ev.step(0.0)
	var id := grid.world_to_id(Vector2(2.7, 12.0))
	t.check(is_equal_approx(grid.grid.get_point_weight_scale(id), EvacuationManager.DANGER_WEIGHT),
		"cells in danger cost more to walk through")
	crowd.threats.clear()
	ev.step(0.0)
	t.check(is_equal_approx(grid.grid.get_point_weight_scale(id), 1.0), "and stop once it is gone")

	# Two zones overlapping: when one goes, what the other still covers stays weighted, what only it covered is free again.
	var za := Vector2(2.7, 12.0)
	var zb := Vector2(4.2, 12.0)
	var ida := crowd.threats.register(za, 2.5, 0.8, 30.0, 8.0, 12.0, &"test")
	crowd.threats.register(zb, 2.5, 0.8, 30.0, 8.0, 12.0, &"test")
	ev.step(0.0)
	var cells_a := ev._zone_cells(za, 2.5)
	var cells_b := ev._zone_cells(zb, 2.5)
	var both: Array[Vector2i] = []
	var only_a: Array[Vector2i] = []
	for c in cells_a:
		if cells_b.has(c):
			both.append(c)
		else:
			only_a.append(c)
	t.check(not both.is_empty() and not only_a.is_empty(), "(the two zones overlap, and each has cells of its own)")
	crowd.threats.end(ida)
	crowd.threats.step(ThreatManager.RECENT + 0.1)  # it lingers as a recent impact for RECENT s, then is gone
	ev.step(0.0)
	var shared_ok := true
	for c in both:
		shared_ok = shared_ok and is_equal_approx(grid.grid.get_point_weight_scale(c), EvacuationManager.DANGER_WEIGHT)
	var freed_ok := true
	for c in only_a:
		freed_ok = freed_ok and is_equal_approx(grid.grid.get_point_weight_scale(c), 1.0)
	t.check(shared_ok, "cells the other zone still covers stay at DANGER_WEIGHT")
	t.check(freed_ok, "cells only the gone zone covered go back to 1.0")
	crowd.threats.clear()
	ev.step(0.0)
	crowd.clear()
	world.free()
