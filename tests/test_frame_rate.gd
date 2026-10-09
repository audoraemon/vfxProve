extends RefCounted
## The capital's frame rate levers (capital plan, Task 14), one check per lever, on a built capital crowd:
## - the gates look only at the fleeing and at those they let through: a calm town's gates examine nobody.


static func run(t) -> void:
	var b := _build()
	_gates(t, b)
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


static func _build() -> Dictionary:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


## Lever 1, the gate pass: each open gate looked at all ~420 citizens twice a frame (1.2 ms of the capital's calm frame).
## It now looks only at the fleeing and the passing, found once a frame: none in a calm town, every gate for one who flees.
static func _gates(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	var town: Town = b.town
	crowd.advance(1.0 / 60.0)
	t.check(crowd.gate_visits == 0, "a calm capital's gates examine nobody (%d)" % crowd.gate_visits)
	var p: Person = crowd.citizens[0]
	p.mind = Person.Mind.FLEE
	var open := 0
	for g in town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			open += 1
	crowd.advance(1.0 / 60.0)
	t.check(open > 4 and crowd.gate_visits == open,
		"one fleeing citizen is examined once at each of the %d open gates (%d)" % [open, crowd.gate_visits])
	p.mind = Person.Mind.CALM
