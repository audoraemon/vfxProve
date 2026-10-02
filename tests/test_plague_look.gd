extends RefCounted
## v0.07.1 Pestilence looks: the sick go through SICK_STAGES steps from green to red as death nears, and their sprite
## redraws at each; while anyone is sick the crowd's drawers show (the rings under them); each infection passed on
## raises a green puff, never more than PUFF_MAX at once.


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

	# Stages, green to red.
	var p: Person = crowd.citizens[0]
	t.check(p.sick_stage() == 0, "the healthy are at stage 0")
	p.infect(PlagueManager.PLAGUE_LIFE)
	var sig_first := p._art_signature()
	t.check(p.sick_stage() == 1 and p.sick_color() == Person.SICK_TINT, "just caught: stage 1, green")
	p.sick_left = PlagueManager.PLAGUE_LIFE * 0.5
	t.check(p.sick_stage() == 3 and p._art_signature() != sig_first, "half way: stage 3, and the sprite redraws")
	p.sick_left = 0.1
	t.check(p.sick_stage() == Person.SICK_STAGES and p.sick_color().is_equal_approx(Person.SICK_RED), "about to die: the last stage, red")
	var s: Person = crowd.soldiers[0]
	s.infect(PlagueManager.PLAGUE_LIFE)
	t.check(s.sick_stage() == 1, "a sick soldier shows it too")

	# While anyone is sick, the drawers show (the rings).
	var drawer := crowd._ground_drawer as Crowd.ResponseDrawer
	plague.step(0.01)
	t.check(drawer.showing(), "the rings show while anyone is sick")
	for q in crowd.citizens + crowd.soldiers:
		q.sick_left = 0.0
	plague.step(0.01)
	t.check(not drawer.showing(), "and stop when nobody is")

	# Each infection passed on raises a puff, PUFF_MAX at most.
	var at := Vector2(0.8, 2.0)
	var packed: Array[Person] = []
	for k in 60:
		var q: Person = crowd.citizens[20 + k]
		q.ground_pos = at + Vector2(0.08 * float(k % 8), 0.08 * float(k / 8))
		packed.append(q)
	for k in 10:
		packed[k].infect(PlagueManager.PLAGUE_LIFE)
	plague._collect(true)
	var before := plague._puffs.size()
	plague._spread()
	var caught := 0
	for q in packed.slice(10):
		if q.sick_left > 0.0:
			caught += 1
	t.check(caught > 0 and plague._puffs.size() - before == mini(caught, PlagueManager.PUFF_MAX - before),
		"a puff for each one who caught it (%d caught, %d puffs)" % [caught, plague._puffs.size() - before])
	for k in 5:
		plague._spread()
	t.check(plague._puffs.size() <= PlagueManager.PUFF_MAX, "never more than %d puffs" % PlagueManager.PUFF_MAX)
	crowd.clear()
	world.free()
