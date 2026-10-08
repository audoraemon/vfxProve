extends RefCounted
## v0.11 M1 board nights (spec §3.1, §4, §6): a mission played from the board is TierBook's version with the god's upgrades,
## one played in the campaign or alone is MissionBook's; F is the ascent's key and nothing else; the board's draft knows the
## locked powers, the campaign's does not; and a night's Descent sets its people aside before any director gathers its own.

const DT := 0.1


static func run(t) -> void:
	_versions(t)
	_flag(t)
	_reserved_escorts(t)
	_wiring_order(t)


static func _versions(t) -> void:
	var state := DescendState.new()
	state.dp_bought = 1
	var w := Mission.def_for("warning", true, state)
	t.check(w.director == StarfallDirector and w.dp_capacity == 7 and w.tier_floor == 1, "from the board: the three stars, +1 DP")
	t.check(Mission.def_for("warning", false, state).director == WarningDirector
		and Mission.def_for("feast_festival", true, state).id == "feast_festival", "in the campaign: MissionBook's own")
	t.check(Mission.def_for("festival", true, null).name == "The Festival", "the board's Festival is found by its id")
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_F
	echo.pressed = true
	echo.echo = true
	var g := InputEventKey.new()
	g.physical_keycode = KEY_G
	g.pressed = true
	var up := InputEventKey.new()
	up.physical_keycode = KEY_F
	t.check(Mission.ascends(f) and not Mission.ascends(echo) and not Mission.ascends(g) and not Mission.ascends(up),
		"F pressed ascends; an echo, a release or another key does not")
	var save := SaveFile.new()
	t.check(Game.locked_for(save, false).size() == 23 and Game.locked_for(save, true).is_empty(),
		"the board's draft greys the locked powers; the campaign's keeps its own rules")


## The scripted runs' --board flag (preflight ruling): with it the def is the board's version, the tier's clock and budget.
static func _flag(t) -> void:
	var on := Mission.wants_board(PackedStringArray(["--mission=warning", "--board", "--mission-test"]))
	var off := Mission.wants_board(PackedStringArray(["--mission=warning", "--mission-test"]))
	var def := Mission.def_for("warning", on, null)
	t.check(on and not off, "--board asks for the board's version; without it the scripted run is MissionBook's")
	t.check(def.director == StarfallDirector and def.tier == 1 and def.clock == TierBook.clock(1)
		and def.tier_floor == TierBook.readiness(1) and def.slots == TierBook.slots(1) and def.dp_capacity == TierBook.dp(1),
		"the flag's def has the tier's clock, readiness and budget")
	t.check(Mission.def_for("warning", off, null).director == WarningDirector, "and without it, The Warning's one star")


## A Procession world as Mission._build_act() sets it up: the act's Rules, the director made, `before` run on it (the Descent's
## reserving), then its setup().
static func _procession(before: Callable) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var def := TierBook.board("long_night").act("procession")
	def.night = NightState.new()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var d := def.make_director() as ProcessionDirector
	before.call(rules, crowd, d)
	d.setup(rules, crowd, town, null, def.night)
	rules.director = d
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": d}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


## Task 7's review: a Rescue wish's soldier is of the same pool as the Procession's escorts, and the director's send_to_post
## would turn him -- a free +15. The director leaves reserved soldiers alone, when it gathers its escorts and in its ticks.
static func _reserved_escorts(t) -> void:
	var control := _procession(func(_r: Rules, _c: Crowd, _d: ProcessionDirector) -> void: pass)
	var guard_at := (control.crowd as Crowd).soldiers.find((control.d as ProcessionDirector).escorts[0])
	_done(control)
	var s := _procession(func(_r: Rules, c: Crowd, d: ProcessionDirector) -> void:
		d.reserved.append(c.soldiers[guard_at]))
	var d: ProcessionDirector = s.d
	var guard: Person = (s.crowd as Crowd).soldiers[guard_at]
	t.check(guard_at >= 0 and not d.escorts.has(guard) and d.escorts.size() == ProcessionDirector.ESCORTS,
		"a reserved soldier is never gathered as an escort, and another takes his place (%d escorts)" % d.escorts.size())
	var anchor := guard.anchor
	d.escorts[0] = guard  # even set among the escorts, the ticks leave him be
	_run(s, 3.0)
	t.check(guard.anchor == anchor and guard.mind != Person.Mind.DUTY, "and the director's ticks never re-post him")
	_done(s)


## Descent.reserve() runs before the director's setup (Mission._build_act()): across several nights' wishes none of the
## people they set aside is the Prince, an attendant or an escort.
static func _wiring_order(t) -> void:
	var clashes := 0
	var heard := 0
	for night in 6:
		var descent := Descent.new().setup(TierBook.board("long_night"), Descent.seed_for(night, "long_night"))
		var s := _procession(func(r: Rules, _c: Crowd, d: ProcessionDirector) -> void:
			descent.reserve(r, d))
		var d: ProcessionDirector = s.d
		heard += descent.wishes.size()
		var taken: Array[Person] = [d.prince]
		taken.append_array(d.attendants)
		taken.append_array(d.escorts)
		for w in descent.wishes:
			for p in w.people():
				clashes += 1 if taken.has(p) else 0
				t.check(d.reserved.has(p), "a wish's person is reserved on the director before it sets up")
		descent.attach(s.rules, d)
		t.check(s.rules.descent == descent and not descent.wishes.is_empty() and d.reserved.size() >= descent.wishes.size(),
			"attach after setup keeps what reserve() heard: the wishes are heard once")
		descent.release()
		_done(s)
	t.check(heard > 0 and clashes == 0, "no wish's person is the Prince, an attendant or an escort (%d wishes, %d clashes)" % [heard, clashes])
