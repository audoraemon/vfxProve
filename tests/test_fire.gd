extends RefCounted
## v0.04 P1 fire: fire-kind hits set burnable buildings burning; fires grow, eat their building and spread; nearby
## calm citizens fetch water from a fountain or well and douse them, and stand down when it is hopeless.


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


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
	var fm := crowd.fires
	# The fire brigade turns out from the profile's stage (Organized: Local Emergency).
	crowd.alarms.stage = crowd.profile.fire_from

	# Catching fire: a fire-kind hit on a house, not a stone wall and not a flood.
	var house: Structure = null
	var wall: Structure = null
	for s in env.structures():
		if house == null and s.kind == Structure.Kind.HOUSE and s.role == &"house" and s.center().distance_to(Vector2(-8, 2)) < 4.0:
			house = s
		if wall == null and s.kind == Structure.Kind.CASTLE_WALL:
			wall = s
	house.damage(5.0, house.center(), &"water")
	t.check(not fm.is_burning(house), "water does not light a fire")
	house.damage(5.0, house.center(), &"cinder")
	wall.damage(5.0, wall.center(), &"cinder")
	t.check(fm.is_burning(house) and not fm.is_burning(wall), "cinder sets a house burning, not a stone wall")

	# Burning: the fire grows and eats its building.
	var hp := house.hp
	var level := fm.intensity(house)
	fm._burn(1.0)
	t.check(fm.intensity(house) > level and house.hp < hp, "a fire grows and burns its building")

	# Responders: nearby calm citizens turn out, fetch water and douse it.
	for p in crowd.citizens:
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF
		# Everyone else well away, so the one placed beside the fire is surely in its crew.
		p.ground_pos = house.center() + Vector2(FireManager.RECRUIT_REACH + 5.0, 0.0)
	var near: Person = crowd.citizens[0]
	near.ground_pos = house.center() + Vector2(0.0, 2.0)
	fm._recruit()
	var crew: Array = fm.fires[house].responders
	t.check(crew.size() >= 1 and crew.size() <= FireManager.MAX_RESPONDERS and near in crew
		and near.intent() == Person.Intent.ASSIST, "nearby citizens turn out to fight it (%d)" % crew.size())
	var water := fm.nearest_water(house.center())
	t.check(near.goal().distance_to(water.center()) < 2.5, "and head for the nearest water")
	_arrive(near)
	fm._tend_responders(FireManager.ACT + 0.1)
	t.check(near.assist_full and near.goal().distance_to(house.center()) < 2.0, "they fill up and carry it to the fire")
	_arrive(near)
	var before := fm.intensity(house)
	fm._tend_responders(FireManager.ACT + 0.1)
	t.check(fm.intensity(house) < before or not fm.is_burning(house), "and douse it")
	fm.fires[house].intensity = 0.05
	fm.douse(house)
	t.check(not fm.is_burning(house) and near.mind != Person.Mind.ASSIST, "put out, the crew stands down")

	# Hopeless or evacuating: they stand down.
	fm.ignite(house, 0.5)
	fm._recruit()
	var p2: Person = fm.fires[house].responders[0]
	fm.fires[house].intensity = 0.95
	fm._tend_responders(0.1)
	t.check(p2.mind != Person.Mind.ASSIST, "a fire grown too big is left to burn")

	# Spreading: a big fire in a tornado's wind catches its neighbour.
	var a: Structure = null
	var b: Structure = null
	for s in env.structures():
		if s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed and s != house:
			for n in env.near(s.center(), FireManager.SPREAD_REACH):
				if n != s and n.kind in FireManager.BURNABLE and not n.destroyed and n.distance_to(s.center()) <= FireManager.SPREAD_REACH:
					a = s
					b = n
					break
		if a != null:
			break
	fm.fires.clear()
	fm.ignite(a, 1.0)
	crowd.threats.register(a.center(), 3.0, 0.6, 60.0, 8.0, 11.0, &"tornado")
	for k in 200:
		fm._burn(0.25)
		if fm.is_burning(b) or not is_instance_valid(a) or a.destroyed:
			break
	t.check(fm.is_burning(b) or a.destroyed, "a fire in the wind spreads to its neighbour (or burns out first)")
	crowd.clear()
	world.free()
