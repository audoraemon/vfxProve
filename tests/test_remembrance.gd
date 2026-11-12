extends RefCounted
## Remembrance's mission side (Skill Tree wheel, Task 4): the def, Rules.free (no cooldown, no clock, no end), the level pick and the
## memory overlay's keys.


static func run(t) -> void:
	_def(t)
	_free_cast(t)
	_no_clock(t)
	_level_pick(t)
	_overlay_keys(t)
	_night_signal(t)
	_hud_text(t)
	_levels_copy(t)


static func _rules(free: bool, keys := ["heaven"]) -> Dictionary:
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
	var rules := Rules.new().setup(PackedStringArray(keys), null, env, field, crowd, town)
	rules.free_play = free
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	return {"rules": rules, "town": town, "crowd": crowd, "world": world}


static func _drop(b: Dictionary) -> void:
	(b.rules as Rules).teardown()
	(b.rules as Rules).free()
	(b.town as Town).teardown()
	(b.crowd as Crowd).clear()
	(b.world as Node).free()
	(b.town as Node).free()
	(b.crowd as Node).free()


static func _def(t) -> void:
	var d := MissionBook.remembrance()
	t.check(d.id == MissionBook.REMEMBRANCE and d.city == &"capital" and d.slots == 1 and d.objectives().is_empty() and d.name == "Remembrance",
		"Remembrance is the capital, one slot, no objectives")
	t.check(d.camera() == CapitalCity.MARKET_SQUARE.get_center(), "and rests on the great market (%s)" % [d.camera()])
	var listed := PackedStringArray()
	for m in MissionBook.dev_missions() + MissionBook.tier_missions() + MissionBook.all() + MissionBook.campaign_missions():
		listed.append(m.id)
	listed.append_array(TierBook.all())
	t.check(not MissionBook.REMEMBRANCE in listed, "it is on no list: not dev, tier, campaign or board")
	t.check(MissionBook.get_mission(MissionBook.REMEMBRANCE).id == MissionBook.REMEMBRANCE, "but it is reachable by id")
	t.check(not Rules.new().free_play, "Rules.free_play is off by default")


static func _free_cast(t) -> void:
	var b := _rules(true)
	var rules: Rules = b.rules
	var ok := rules.refusal(0) == ""
	rules.cast(0, Vector2.ZERO)
	t.check(ok and rules.cooldown_left(0) == 0.0 and rules.refusal(0) == "", "a free cast leaves no cooldown")
	rules.cast(0, Vector2.ZERO)
	t.check(rules.cooldown_left(0) == 0.0, "and casts again at once (%s)" % rules.refusal(0))
	_drop(b)
	b = _rules(false)
	rules = b.rules
	var refused: Array = []
	rules.cast_refused.connect(func(_slot: int, reason: String): refused.append(reason))
	rules.cast(0, Vector2.ZERO)
	rules.cast(0, Vector2.ZERO)
	t.check(rules.cooldown_left(0) > 0.0 and refused == ["cooldown"], "not free: the second cast is refused cooldown (%s)" % [refused])
	_drop(b)


static func _no_clock(t) -> void:
	var b := _rules(true)
	var rules: Rules = b.rules
	var left := rules.time_left
	for i in 40:
		rules.advance(10.0)
	t.check(rules.time_left == left and not rules.finished and not rules.won, "free: 400 s pass, the clock stands and nothing ends")
	_drop(b)
	b = _rules(false)
	rules = b.rules
	rules.advance(10.0)
	t.check(rules.time_left < 360.0, "not free: the clock still runs")
	_drop(b)


static func _level_pick(t) -> void:
	var b := _rules(true, ["wisp"])
	var m := Mission.new()
	m.remembrance = "wisp"
	m._rules = b.rules
	m.set_memory_level(5)
	t.check((b.rules as Rules).level_of(0) == 5 and m.levels.get("wisp") == 5, "set_memory_level(5) puts wisp at level 5")
	m.set_memory_level(9)
	t.check((b.rules as Rules).level_of(0) == 5, "and never above 5")
	m._rules = null
	m.free()
	_drop(b)
	b = _rules(true, ["thorns"])
	m = Mission.new()
	m.remembrance = "thorns"
	m._rules = b.rules
	m.set_memory_level(5)
	t.check((b.rules as Rules).level_of(0) == 1, "a power without level tables stays at level 1")
	m._rules = null
	m.free()
	_drop(b)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _overlay_keys(t) -> void:
	var o := MemoryOverlay.new().setup("Will-o'-Wisp", 5, 1, false)
	var picked: Array = []
	var nights: Array = []
	o.level_picked.connect(func(n: int): picked.append(n))
	o.night_toggled.connect(func(n: bool): nights.append(n))
	o._input(_key(KEY_3))
	t.check(picked == [3] and o.level == 3 and o.banner_text() == "REMEMBRANCE . Will-o'-Wisp . Level 3", "key 3 picks level 3 (%s)" % [picked])
	o._input(_key(KEY_N))
	o._input(_key(KEY_N))
	t.check(nights == [true, false], "N toggles to night, then back to day (%s)" % [nights])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = MemoryOverlay.box_rect(5).get_center()
	o._input(click)
	t.check(picked == [3, 5], "a click on the fifth box picks level 5 (%s)" % [picked])
	o.free()
	var one := MemoryOverlay.new().setup("Thornwall", 1, 3, false)
	var got: Array = []
	one.level_picked.connect(func(n: int): got.append(n))
	one._input(_key(KEY_4))
	t.check(got.is_empty() and one.level == 1, "boxes above the power's top level do nothing")
	one.free()


static func _night_signal(t) -> void:
	var b := _rules(true, ["wisp"])
	var m := Mission.new()
	m.remembrance = "wisp"
	m._rules = b.rules
	m._begin_memory()
	var nights: Array = []
	m.memory_night_toggled.connect(func(n: bool): nights.append(n))
	m._memory.press(KEY_N)
	m._memory.press(KEY_N)
	t.check(nights == [true, false], "Mission re-emits the night toggle (%s)" % [nights])
	m._memory.press(KEY_4)
	t.check((b.rules as Rules).level_of(0) == 4, "and handles the level pick itself")
	m._rules = null
	m.free()
	_drop(b)


static func _hud_text(t) -> void:
	for free in [true, false]:
		var b := _rules(free, ["wisp"])
		var hud := Hud.new().setup(b.rules, b.crowd, b.town, null)
		var want := "FREE" if free else PrepareScreen.cooldown_text((b.rules as Rules).power(0), (b.rules as Rules).level_of(0))
		t.check(hud.slot_cooldown_text(0) == want and (free or want.ends_with("s")),
			"the slot's cooldown line reads '%s' (free_play %s)" % [hud.slot_cooldown_text(0), free])
		t.check(hud.clock_shown() == not free, "the night's clock is %s (free_play %s)" % ["hidden" if free else "shown", free])
		hud.free()
		_drop(b)


static func _levels_copy(t) -> void:
	var b := _rules(true, ["wisp"])
	var god := {"wisp": 2}
	var m := Mission.new()
	m.remembrance = "wisp"
	m.levels = god
	m._rules = b.rules
	m._begin_memory()
	m.set_memory_level(5)
	t.check(god == {"wisp": 2} and m.levels.get("wisp") == 5 and (b.rules as Rules).level_of(0) == 5,
		"Mission never writes into the levels it was handed (%s)" % [god])
	m._rules = null
	m.free()
	_drop(b)
