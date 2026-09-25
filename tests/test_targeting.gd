extends RefCounted
## Aiming: the preview areas are the effects' own numbers, a click casts, a drag aims, and a lane power
## frightens the whole street it crosses.


static func run(t) -> void:
	# The preview table is the effects' constants, not a copy that can drift.
	var heaven: GDScript = load("res://src/fx/set2/heaven_splitter.gd")
	var tsunami: GDScript = load("res://src/fx/set2/tsunami_breaker.gd")
	var laser: GDScript = load("res://src/fx/walking_laser_grid.gd")
	var nova: GDScript = load("res://src/fx/nuclear_nova.gd")
	var cinder: GDScript = load("res://src/fx/set2/cinderfall_barrage.gd")
	var dragon: GDScript = load("res://src/fx/set2/dragonfire_parade.gd")
	var tornado: GDScript = load("res://src/fx/set2/tornado_tempest.gd")
	var h: Dictionary = Targeting.AREAS["heaven"]
	t.near(float(h.length), _k(heaven, "LINE_LENGTH"), 0.0001, "Heaven Splitter's lane is its LINE_LENGTH (%.1f)" % h.length)
	t.near(float(h.half), _k(heaven, "LINE_HALF_WIDTH"), 0.0001, "and its own half width (%.2f)" % h.half)
	var ts: Dictionary = Targeting.AREAS["tsunami"]
	t.near(float(ts.length), _k(tsunami, "LENGTH"), 0.0001, "the Tsunami's lane is its LENGTH (%.1f)" % ts.length)
	t.near(float(ts.half), _k(tsunami, "WIDTH") * 0.5, 0.0001, "and half the wall's WIDTH (%.1f)" % ts.half)
	var ls: Dictionary = Targeting.AREAS["laser"]
	t.near(float(ls.length), _k(laser, "LENGTH"), 0.0001, "the Laser Grid walks its LENGTH (%.1f)" % ls.length)
	t.near(float(ls.half), _k(laser, "KILL_HALF_WIDTH"), 0.0001, "in a KILL_HALF_WIDTH band (%.1f)" % ls.half)
	t.near(float(Targeting.AREAS["nova"].r), _k(nova, "RADIUS"), 0.0001, "the Nova's circle is its RADIUS")
	t.near(float(Targeting.AREAS["nova"].inner), _k(nova, "KILL_CORE"), 0.0001, "with its KILL_CORE inside")
	t.near(float(Targeting.AREAS["cinder"].r), _k(cinder, "RADIUS"), 0.0001, "the Barrage's circle is its RADIUS")
	t.near(float(Targeting.AREAS["dragon"].r), _k(dragon, "CONE_RADIUS"), 0.0001, "the dragon's cone is its CONE_RADIUS")
	t.near(float(Targeting.AREAS["dragon"].arc), _k(dragon, "SWEEP_ARC"), 0.0001, "over its SWEEP_ARC")
	t.near(float(Targeting.AREAS["tornado"].roam), _k(tornado, "WANDER_RADIUS"), 0.0001, "the tornado roams its WANDER_RADIUS")
	var missing := ""
	for key in PowerBook.keys():
		if not Targeting.AREAS.has(key):
			missing += " " + key
	t.check(missing == "", "every power has an area to show (missing:%s)" % missing)

	# Aiming: a click casts a point power where it was clicked, a drag casts along its direction.
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
	var rules := Rules.new().setup(PackedStringArray(["nova", "tsunami", "cinder", "heaven"]), null, env, field,
		crowd, town)
	var casts: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	var aim := Targeting.new().setup(rules, crowd)

	aim.pick(0)
	aim.press(Vector2(2.0, 2.0))
	t.check(not aim.aiming, "a click power does not start a drag")
	aim.release(Vector2(2.4, 2.1))
	t.check(casts.size() == 1 and casts[0][0] == Vector2(2.0, 2.0) and not casts[0][1].has("dir"),
		"a click power is cast where the button went down, with no direction (%s)" % [casts])

	aim.pick(1)
	aim.press(Vector2(-3.0, 0.0))
	t.check(aim.aiming, "a drag power starts aiming")
	aim.release(Vector2(0.0, 0.0))
	t.check(casts.size() == 2 and casts[1][0] == Vector2(-3.0, 0.0), "and is cast from where the drag started")
	t.check((casts[1][1].dir as Vector2).is_equal_approx(Vector2(1, 0)),
		"pointed the way it was dragged (%s)" % [casts[1][1].dir])
	t.check(not aim.aiming, "and the drag is done")

	aim.pick(3)
	aim.press(Vector2(0.0, 5.0))
	aim.cancel()
	t.check(not aim.aiming and casts.size() == 2, "cancelling a drag casts nothing (%d)" % casts.size())

	# A lane power frightens the people along it, not only at its start.
	var far: Person = crowd.citizens[0]
	var near: Person = crowd.citizens[1]
	var bystander: Person = crowd.citizens[2]
	far.ground_pos = Vector2(5.0, -8.0)
	near.ground_pos = Vector2(-1.0, -8.0)
	bystander.ground_pos = Vector2(-1.0, 3.0)
	for p in [far, near, bystander]:
		p.mind = Person.Mind.CALM
	crowd.on_cast(Vector2(-2.0, -8.0), Vector2(1, 0), 10.0)
	t.check(near.mind == Person.Mind.PANIC, "someone beside the lane's start panics")
	t.check(far.mind == Person.Mind.PANIC, "and so does someone seven units down it")
	t.check(bystander.mind == Person.Mind.CALM, "someone a street away does not")

	rules.free()
	aim.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()


## One constant out of an effect's script, by name.
static func _k(script: GDScript, name: String) -> float:
	return float(script.get_script_constant_map()[name])
