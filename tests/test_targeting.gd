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
	t.check(float(Targeting.AREAS["mirror"].wide) == MirrorfoldFx.HALF_WIDE and float(Targeting.AREAS["mirror"].deep) == MirrorfoldFx.HALF_DEEP,
		"the mirrors lie HALF_WIDE by HALF_DEEP")
	t.check(float(Targeting.AREAS["solaris"].r) == LightOfSolaris.RADIUS, "the Light of Solaris covers its RADIUS")
	t.near(float(Targeting.AREAS["dragon"].r), _k(dragon, "CONE_RADIUS"), 0.0001, "the dragon's cone is its CONE_RADIUS")
	t.near(float(Targeting.AREAS["dragon"].arc), _k(dragon, "SWEEP_ARC"), 0.0001, "over its SWEEP_ARC")
	t.near(float(Targeting.AREAS["tornado"].roam), _k(tornado, "WANDER_RADIUS"), 0.0001, "the tornado roams its WANDER_RADIUS")
	var missing := ""
	for key in PowerBook.keys():
		if not Targeting.AREAS.has(key):
			missing += " " + key
	t.check(missing == "", "every power has an area to show (missing:%s)" % missing)

	# The Heaven Splitter's line is centred on the cast (heaven_splitter.gd lays its lane from
	# origin - dir * LINE_LENGTH / 2); the Tsunami and the Laser Grid start at it.
	t.check(bool(Targeting.AREAS["heaven"].get("centred", false)), "the Heaven Splitter's lane is centred on the cast")
	t.check(not bool(Targeting.AREAS["tsunami"].get("centred", false)) and not bool(Targeting.AREAS["laser"].get("centred", false)),
		"the Tsunami's and the Laser Grid's start at it")
	var mid := Targeting.lane_start("heaven", Vector2(2.0, 2.0), Vector2(1.0, 0.0))
	t.check(mid.is_equal_approx(Vector2(-3.0, 2.0)), "so a Heaven Splitter at (2, 2) pointing east starts 5 units west (%s)" % mid)
	t.check(Targeting.lane_start("tsunami", Vector2(2.0, 2.0), Vector2(1.0, 0.0)) == Vector2(2.0, 2.0), "and a Tsunami starts where it is cast")

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
	var rules := Rules.new().setup(PackedStringArray(["nova", "tsunami", "cinder", "heaven", "mirror"]), null, env, field,
		crowd, town)
	var casts: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	var aim := Targeting.new().setup(rules, crowd)
	t.check(aim.slot == -1 and aim.area().is_empty(), "nothing is focused when a mission starts, so nothing is drawn")
	aim.press(Vector2(1.0, 1.0))
	aim.release(Vector2(1.0, 1.0))
	t.check(casts.is_empty() and not aim.armed, "a click with nothing focused casts nothing")

	aim.pick(0)
	t.check(aim.slot == 0 and not aim.area().is_empty(), "pressing a slot's key focuses it and shows its area")
	aim.pick(0)
	t.check(aim.slot == -1, "pressing it again unfocuses it")

	# A click power: cast where the button went down, then unfocused.
	aim.pick(0)
	aim.press(Vector2(2.0, 2.0))
	t.check(aim.armed and not aim.aiming, "a click power arms on press without starting a drag")
	aim.release(Vector2(2.4, 2.1))
	t.check(casts.size() == 1 and casts[0][0] == Vector2(2.0, 2.0) and not casts[0][1].has("dir"),
		"a click power is cast where the button went down, with no direction (%s)" % [casts])
	t.check(aim.slot == -1 and not aim.armed, "and a cast that goes out unfocuses (%d)" % aim.slot)

	# A drag power: cast from where the drag started, along the drag.
	aim.pick(1)
	aim.press(Vector2(-3.0, 0.0))
	t.check(aim.aiming, "a drag power starts aiming")
	aim.release(Vector2(0.0, 0.0))
	t.check(casts.size() == 2 and casts[1][0] == Vector2(-3.0, 0.0), "and is cast from where the drag started")
	t.check((casts[1][1].dir as Vector2).is_equal_approx(Vector2(1, 0)),
		"pointed the way it was dragged (%s)" % [casts[1][1].dir])
	t.check(casts[1][1].to == Vector2(0.0, 0.0), "and told where the drag ended, for a power with two places (%s)" % [casts[1][1].get("to")])
	t.check(not aim.aiming and aim.slot == -1, "and the drag is done")

	# Right-click while the button is held calls the cast off; the power stays focused.
	aim.pick(3)
	aim.press(Vector2(0.0, 5.0))
	t.check(aim.cancel(), "calling off a held press reports that it did")
	aim.release(Vector2(1.0, 5.0))
	t.check(casts.size() == 2 and aim.slot == 3, "the release after it casts nothing, and the power stays focused (%d)" % casts.size())
	t.check(not aim.cancel(), "with nothing held there is nothing to call off")
	aim.unfocus()
	t.check(aim.slot == -1 and aim.area().is_empty(), "and unfocusing takes the area away")

	# A two-click power: the first click sets its first place, the second casts from there and tells where it landed.
	aim.pick(4)
	aim.press(Vector2(2.0, 3.0))
	aim.release(Vector2(2.0, 3.0))
	t.check(casts.size() == 2 and aim.placed and aim.first == Vector2(2.0, 3.0) and aim.slot == 4,
		"the first click of a two-click power casts nothing: it sets the first place and the power stays focused")
	aim.press(Vector2(8.0, 3.0))
	aim.release(Vector2(8.0, 3.0))
	t.check(casts.size() == 3 and casts[2][0] == Vector2(2.0, 3.0) and casts[2][1].to == Vector2(8.0, 3.0) and not aim.placed,
		"the second casts from the first place, told where the second landed (%s)" % [casts])
	t.check(aim.slot == -1, "and the cast unfocuses")
	aim.pick(4)
	aim.press(Vector2(2.0, 3.0))
	aim.release(Vector2(2.0, 3.0))
	t.check(aim.cancel() and not aim.placed and aim.slot == 4, "a right-click after the first place calls it off; the power stays focused")
	aim.unfocus()

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

	_whisper(t, crowd, field, grid, env, town)

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


## Mind Whisper's aim (v0.08 M3): the press picks a citizen or is refused, the release sends them, clamped to REACH.
static func _whisper(t, crowd: Crowd, field: EnemyField, grid: WalkGrid, env: EnvironmentField, town: Town) -> void:
	var rules := Rules.new().setup(PackedStringArray(["whisper", "heaven"]), null, env, field, crowd, town)
	var casts: Array = []
	var refused: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	var aim := Targeting.new().setup(rules, crowd)
	# A citizen out in the open, and walkable ground three units or more from anyone.
	var c: Person = null
	for p: Person in crowd.citizens.slice(10):
		if p.is_alive() and not p.inside:
			c = p
			break
	var empty := Vector2.INF
	for i in 200:
		var at := grid.nearest_walkable(Vector2(-20.0 + float(i % 20) * 2.0, -20.0 + float(i / 20) * 4.0))
		if at != Vector2.INF and field.in_radius(at, 3.0).is_empty():
			empty = at
			break
	t.check(c != null and empty != Vector2.INF, "a citizen to whisper to, and a spot three units from anyone")
	t.near(float(Targeting.AREAS["whisper"].r), MindWhisperFx.PICK_R, 0.0001, "the whisper's ring is its PICK_R")

	aim.pick(0)
	aim.press(empty)
	t.check(not aim.armed and not aim.aiming and refused == [[0, "nobody"]],
		"a whisper pressed three units from anyone arms nothing and is refused with \"nobody\" (%s)" % [refused])
	aim.release(empty + Vector2(2.0, 0.0))
	t.check(casts.is_empty() and rules.cooldown_left(0) == 0.0, "and its release casts nothing")

	aim.press(c.ground_pos + Vector2(0.3, 0.0))
	t.check(aim.armed and aim.aiming, "a press on a citizen arms the whisper and starts aiming it")
	var spot := grid.nearest_walkable(c.ground_pos + Vector2(4.0, 0.0))
	aim.release(spot)
	t.check(not aim.aiming, "and the release ends the aim")
	t.check(casts.size() == 1 and casts[0][0] == c.ground_pos, "a release casts once, at the citizen (%s)" % [casts])
	var extra: Dictionary = casts[0][1] if casts.size() == 1 else {}
	t.check(extra.get("target") == c, "the cast names the citizen pressed on")
	t.check(extra.has("to") and (extra.to as Vector2).distance_to(spot) < 0.01,
		"and sends them to the walkable spot where the button came up (%s, %s)" % [extra.get("to"), spot])

	rules._cooldowns[0] = 0.0
	aim.pick(0)
	aim.press(c.ground_pos)
	aim.release(c.ground_pos + Vector2(20.0, 0.0))
	var to: Vector2 = casts[1][1].to if casts.size() == 2 else Vector2.INF
	t.check(to.distance_to(c.ground_pos) <= MindWhisperFx.REACH + 0.001 and grid.walkable(to),
		"a release twenty units away sends them no further than REACH, on walkable ground (%.2f)"
		% to.distance_to(c.ground_pos))

	# The shake-off (v0.08.1): someone a whisper has just let go is ringed red, and a press on them is refused with
	# "shaken" -- nothing armed, no cooldown spent; a release on someone who became shaken meanwhile is refused too.
	rules._cooldowns[0] = 0.0
	t.check(Targeting.whisper_pick_color(c) == Targeting.COL_INNER, "the preview rings a citizen who can hear it as usual")
	c._shaken_left = Person.SHAKE_OFF
	t.check(Targeting.whisper_pick_color(c) == Targeting.COL_BAD, "and one still shaking a whisper off in red")
	refused.clear()
	aim.pick(0)
	aim.press(c.ground_pos)
	t.check(not aim.armed and refused == [[0, "shaken"]] and casts.size() == 2 and rules.cooldown_left(0) == 0.0,
		"a press on them arms nothing and is refused with \"shaken\", the cooldown untouched (%s)" % [refused])
	c._shaken_left = 0.0
	refused.clear()
	aim.press(c.ground_pos)
	c._shaken_left = Person.SHAKE_OFF
	aim.release(c.ground_pos + Vector2(2.0, 0.0))
	t.check(refused == [[0, "shaken"]] and casts.size() == 2 and rules.cooldown_left(0) == 0.0,
		"a release on someone shaken since the press is refused the same way (%s)" % [refused])
	c._shaken_left = 0.0
	aim.free()
	rules.free()


## One constant out of an effect's script, by name.
static func _k(script: GDScript, name: String) -> float:
	return float(script.get_script_constant_map()[name])
