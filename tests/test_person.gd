extends RefCounted
## A person walks the grid's paths, panics away from a blow, flees to an exit and escapes there; a soldier
## ignores all of that, marches to its rally ring and holds its ground.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)

	# A citizen walks to a goal across town.
	var goal := Vector2(0.0, 6.0)
	var c := Person.new()
	c.rng.seed = 11
	c.bounds = TownLayout.MAP
	c.setup_person(false, Vector2(0.0, 2.0), grid)
	c.set_goal(goal)
	var steps := 0
	while steps < 2400 and c.ground_pos.distance_to(goal) > 0.5:
		c.tick(1.0 / 60.0)
		steps += 1
	t.check(c.ground_pos.distance_to(goal) <= 0.5, "a citizen walks to its goal (%s after %d steps)" % [c.ground_pos, steps])

	# Panic runs away from the blow, then turns into flight.
	var start := c.ground_pos
	c.panic(start + Vector2(0.0, -1.0))
	c.tick(1.0 / 60.0)
	t.check(c.mind == Person.Mind.PANIC and c.walk_speed > DummyEnemy.WALK_SPEED, "panic runs faster than a stroll")
	for i in 200:
		c.tick(1.0 / 60.0)
	t.check(c.ground_pos.y >= start.y - 0.05, "it runs away from the blow, not into it")
	for i in 240:
		c.tick(1.0 / 60.0)
	t.check(c.mind == Person.Mind.FLEE, "panic turns into flight")
	var fled := 0
	while fled < 9000 and not c.has_escaped():
		c.tick(1.0 / 60.0)
		fled += 1
	t.check(c.has_escaped(), "it reaches an exit (%s after %d steps)" % [c.ground_pos, fled])
	t.near(c.walk_speed, 1.2, 0.001, "fleeing at the spec's 1.2 units per second")

	# Soldiers never flee; they march where they are posted and then hold.
	var s := Person.new()
	s.rng.seed = 12
	s.bounds = TownLayout.MAP
	s.setup_person(true, TownLayout.BARRACKS_YARD.get_center(), grid)
	t.check(s.mind == Person.Mind.POST, "a soldier starts at its post")
	s.panic(s.ground_pos + Vector2(1.0, 0.0))
	s.flee()
	t.check(s.mind == Person.Mind.POST, "and ignores panic and flight")
	var ring := TownLayout.CITADEL_ORIGIN + Vector2(0.0, 3.6)
	s.send_to_post(ring, true)
	t.check(s.mind == Person.Mind.RALLY, "the rally moves it")
	var marched := 0
	while marched < 6000 and s.ground_pos.distance_to(ring) > 0.6:
		s.tick(1.0 / 60.0)
		marched += 1
	t.check(s.ground_pos.distance_to(ring) <= 0.6, "it reaches the rally ring (%s after %d steps)" % [s.ground_pos, marched])
	s.hold_ground()
	var held := s.ground_pos
	for i in 120:
		s.tick(1.0 / 60.0)
	t.check(s.ground_pos.distance_to(held) < 0.3, "and holds its ground")

	# A frozen person cannot walk, and a queued one stands still until the gate lets it through.
	c.freeze(1.0)
	var frozen_at := c.ground_pos
	for i in 30:
		c.tick(1.0 / 60.0)
	t.check(c.ground_pos == frozen_at, "a frozen person cannot walk")

	var w := Person.new()
	w.rng.seed = 13
	w.bounds = TownLayout.MAP
	w.setup_person(false, Vector2(0.0, 7.0), grid)
	w.set_goal(Vector2(0.0, 10.0))
	w.wait = 0.5
	var waited := w.ground_pos
	for i in 20:
		w.tick(1.0 / 60.0)
	t.check(w.ground_pos.distance_to(waited) < 0.05, "a queued person stands still")
	for i in 90:
		w.tick(1.0 / 60.0)
	t.check(w.ground_pos.distance_to(waited) > 0.05, "and walks on when the gate lets it through")

	# Everything the effects do to a unit still applies.
	t.check(w.is_alive() and w is DummyEnemy, "people are ordinary units")
	w.die(&"nova", w.ground_pos + Vector2(1, 0))
	t.check(not w.is_alive(), "and they die like units")
	# A goal inside a building parks the walker at its doorstep; it must not stay parked forever.
	var parked := Person.new()
	parked.rng.seed = 21
	parked.bounds = TownLayout.MAP
	parked.setup_person(false, Vector2(-6.0, 2.0), grid)
	parked.set_goal(TownLayout.TEMPLE.get_center())
	var ticks := 0
	while ticks < 6000 and parked._goal != Vector2.INF:
		parked.tick(1.0 / 60.0)
		ticks += 1
	t.check(parked._goal == Vector2.INF, "an unreachable goal is dropped instead of parking forever (%d ticks)" % ticks)
	var parked_at := parked.ground_pos
	for i in 240:
		parked.tick(1.0 / 60.0)
	t.check(parked.ground_pos.distance_to(parked_at) > 0.05, "and the citizen goes back to wandering")
	parked.free()
	env.clear()
	env.free()
	town.free()
	c.free()
	s.free()
	w.free()
