extends RefCounted
## Endless Night's look and the night's rules (NightRules): the roll, the Mission that takes it, sight, the people indoors and the walk.

const LOADOUT := ["heaven", "tsunami", "cinder", "nova"]


static func run(t) -> void:
	_roll(t)
	await _missions(t)
	_sight(t)
	_routine(t)
	_wiring(t)
	_prepare(t)


static func _slot(night := 1, seed_value := 11) -> GodSlot:
	var s := GodSlot.make(1, "ruin", seed_value)
	s.night = night
	return s


static func _roll(t) -> void:
	var a := GodNight.look_for(_slot(4), "warning")
	t.check(a == GodNight.look_for(_slot(4), "warning"), "look_for is the same for the same seed, night and mission")
	var day := 0
	var night := 0
	var differ := false
	for n in 200:
		var l := GodNight.look_for(_slot(n), "warning")
		if l == Town.Look.NIGHT:
			night += 1
		elif l == Town.Look.DAY:
			day += 1
		differ = differ or l != GodNight.look_for(_slot(n), "festival")
	t.check(day + night == 200 and day > 70 and night > 70, "both looks occur, about even (day %d, night %d of 200)" % [day, night])
	t.check(differ, "two missions on the same night can differ")


## A Mission started in the tree with `look` (-1: none), seed 7; the caller frees it.
static func _start(t, look: int) -> Mission:
	City.use(&"aldermere")
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.look_override = look
	t.root.add_child(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(PackedStringArray(LOADOUT), 7)
	return m


static func _inside(m: Mission) -> Array[Person]:
	var out: Array[Person] = []
	for p in m._crowd.citizens:
		if p.inside:
			out.append(p)
	return out


static func _missions(t) -> void:
	var m: Mission = await _start(t, Town.Look.NIGHT)
	var c := m._crowd
	var n := c.citizens.size()
	var kept_out: Array = m._director.reserved.duplicate() if m._director != null else []
	var eligible := 0
	for p in c.citizens:
		if p.inside or NightRules.eligible(p, kept_out):
			eligible += 1
	var inside := _inside(m)
	t.check(m._town.look == Town.Look.NIGHT and c.sight_scale == NightRules.NIGHT_SIGHT and c.sight_scale == 0.6,
		"a NIGHT run: the town is NIGHT and the crowd sees at 0.6")
	t.check(c.routine.night, "a NIGHT run: the routine's night flag is on")
	t.check(not inside.is_empty() and absi(inside.size() - roundi(0.4 * eligible)) <= 1,
		"about 40%% of the eligible citizens are indoors (%d of %d eligible)" % [inside.size(), eligible])
	var clean := true
	for p in inside:
		clean = clean and not p.visible and not p.soldier and p.profile.faith == CitizenProfile.Faith.NONE \
			and not p.profile.role in Wish.NOT_LAY and not kept_out.has(p) and c.citizens.has(p)
	for s in c.soldiers:
		clean = clean and not s.inside
	t.check(clean, "those indoors are hidden ordinary citizens still in the crowd; no soldier, no named person")
	t.check(c.citizens.size() == n, "the alive count is unchanged")
	var kept := _inside(m).size()
	for i in 60:
		c.step_people(0.1)
		c.advance(0.1)
	t.check(_inside(m).size() == kept, "nobody indoors comes out")
	m.queue_free()
	await t.process_frame

	var d: Mission = await _start(t, Town.Look.DAY)
	t.check(d._town.look == Town.Look.DAY and d._crowd.sight_scale == 1.0 and _inside(d).is_empty() and not d._crowd.routine.night,
		"a DAY run: DAY, sight 1.0, nobody indoors, no night flag")
	d.queue_free()
	await t.process_frame

	var cur: Mission = await _start(t, -1)
	t.check(cur._town.look == Town.Look.CURRENT and cur._crowd.sight_scale == 1.0 and _inside(cur).is_empty()
		and not cur._crowd.routine.night, "no override: CURRENT and nothing changed")
	cur.queue_free()
	await t.process_frame


static func _crowd() -> Crowd:
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
	return crowd


static func _sight(t) -> void:
	var crowd := _crowd()
	var p: Person = crowd.citizens[0]
	var reach: Array = PowerBook.REACH.get("heaven", PowerBook.REACH_DEFAULT)
	var sight := float(reach[0])
	var at := Vector2(0.0, 0.0)
	var cast: Array[Vector2] = [at]
	for scale in [1.0, 0.6]:
		crowd.sight_scale = scale
		for frac in [0.8, 0.5]:
			p.ground_pos = at + Vector2(sight * frac, 0.0)
			p.mind = Person.Mind.CALM
			p.awareness = Person.Awareness.UNAWARE
			crowd._look(cast, sight * crowd.sight_scale)
			var saw := p.mind == Person.Mind.OBSERVE
			t.check(saw == (frac <= scale), "at sight scale %.1f a calm person at %.1f x the power's sight %s the build-up"
				% [scale, frac, "looks at" if saw else "does not see"])
	crowd.sight_scale = 1.0
	t.check(crowd.doom_witness() == Crowd.DOOM_WITNESS, "the witness distance is DOOM_WITNESS by day")
	crowd.sight_scale = 0.6
	t.near(crowd.doom_witness(), 1.2, 0.0001, "and 1.2 at night")
	for q in crowd.citizens:
		if q != p:
			q.inside = true
	for q in crowd.soldiers:
		q.inside = true
	p.inside = false
	p.ground_pos = Vector2(1.5, 0.0)
	crowd.sight_scale = 1.0
	t.check(crowd.nearest_witness(Vector2.ZERO) == p, "a kill witnessed at 1.5 counts at CURRENT")
	crowd.sight_scale = 0.6
	t.check(crowd.nearest_witness(Vector2.ZERO) == null, "and not at NIGHT")


static func _routine(t) -> void:
	var crowd := _crowd()
	var pr: CitizenProfile = (crowd.citizens[0] as Person).profile
	var r := crowd.routine
	var homes := [0, 0]
	for night in [false, true]:
		r.night = night
		r._rng.seed = 5
		for i in 600:
			if r.pick(pr, -1) == RoutineManager.Place.HOME:
				homes[1 if night else 0] += 1
	t.check(homes[1] > homes[0], "at night more picks are home (%d against %d)" % [homes[1], homes[0]])


static func _wiring(t) -> void:
	var game := FileAccess.get_file_as_string("res://src/game/game.gd")
	t.check(game.contains("mission.look_override = GodNight.look_for(god, mission_id)"), "Game gives an Endless Night's Mission the rolled look")
	var block := game.find("if _in_endless and god != null:")
	var at := game.find("mission.look_override")
	t.check(block >= 0 and at > block and at < game.find("add_child(mission)", block),
		"and inside the Endless Night block, before the Mission is added")
	t.check(game.count("look_override") == 1, "no other path sets it (the board, the campaign, the sandbox)")
	var m := Mission.new()
	t.check(m.look_override == -1, "a Mission has no look of its own until given one")
	m.free()


static func _prepare(t) -> void:
	var god := _slot(3)
	GodTree.dev_fill = true
	var prep := PrepareScreen.new()
	prep.god = god
	prep.look = Town.Look.NIGHT
	prep.setup(GodNight.def_for(god, GodNight.draw(god)), PackedStringArray(), ResponseProfile.DEFAULT)
	t.check(prep.look_text() == "Night", "Endless Night's Prepare says Night")
	prep.look = Town.Look.DAY
	t.check(prep.look_text() == "Day", "or Day")
	prep.free()
	var board := PrepareScreen.new()
	board.setup(MissionBook.last_judgement(), PackedStringArray())
	t.check(board.look_text() == "", "the board's Prepare says neither")
	board.free()
	var game := FileAccess.get_file_as_string("res://src/game/game.gd")
	t.check(game.contains("prep.look = GodNight.look_for(god, mission_id)") and game.count("prep.look =") == 1,
		"Game sets it on the Endless Night branch only")
	GodTree.dev_fill = false
