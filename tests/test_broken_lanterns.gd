extends RefCounted
## v0.10 M3 Broken Lanterns (BrokenLanternsDirector). Six wayside shrines stand on the Vigil's route. A broken shrine
## drains after 20 s, unless the flame-bearer reaches it first and relights it. All six drained win; the bell, a full
## Gaze or dawn lose. Task 6 adds the Faithful praying at the standing shrines, the Lantern Knights at 1:30, the
## kneelers at the last shrine, and the bonus.

const DT := 0.05
## Somewhere far from every shrine, where the tests park the Vigil so the flame relights nothing it is not meant to.
const AWAY := Vector2(14.0, -14.0)


static func _setup() -> Dictionary:
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
	# The town's alarm hushed: shrines falling in a test never call the bellkeeper (the bell's own case sets it rung).
	crowd.hush(9999.0)
	var def := MissionBook.broken_lanterns()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as BrokenLanternsDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners}


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


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## The Vigil's walkers parked far from every shrine.
static func _away(d: BrokenLanternsDirector) -> void:
	var i := 0
	for p in d.vigil.walkers():
		_arrive(p, AWAY + Vector2(float(i), 0.0))
		i += 1


## A blow no shrine stands through, unless a Knight guards it.
static func _break(sh: Structure) -> void:
	sh.damage(9999.0, sh.center(), &"stone")


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


static func run(t) -> void:
	_cast(t)
	_drain(t)
	_relight(t)
	_ending(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var town: Town = s.town
	var grid: WalkGrid = s.grid
	var placed := d.shrines.size() == BrokenLanternsDirector.SHRINE_SPOTS.size()
	for i in d.shrines.size():
		var sh := d.shrines[i]
		placed = placed and sh.kind == Structure.Kind.SHRINE and sh.role == BrokenLanternsDirector.ROLE and not sh.destroyed \
			and town._built.has(sh) and sh.damage_filter.is_valid() \
			and sh.center().distance_to(BrokenLanternsDirector.SHRINE_SPOTS[i]) < 2.0
	t.check(placed, "six wayside shrines stand on the Vigil's route, the town's to take away")
	t.check(not Rules.BUILDING_ROLES.has(BrokenLanternsDirector.ROLE), "a shrine is not a building for the tally or the score")
	var reach := true
	for sh in d.shrines:
		reach = reach and grid.walkable(d.relight_point(sh)) and not grid.path(d.temple_door, d.relight_point(sh)).is_empty()
	t.check(reach, "the bearer can walk from the Temple to every shrine's side")
	var faithful_ok := d.faithful.size() >= BrokenLanternsDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL
	t.check(faithful_ok, "the Faithful chosen (%d)" % d.faithful.size())
	t.check(d.vigil != null and d.vigil.active and d.vigil.loop and d.vigil.pass_flame and d.vigil.walkers().size() == 3
		and d.vigil.route.size() == d.shrines.size() and d.faithful.has(d.vigil.bearer),
		"the Vigil sets out round the six shrines, looping, the flame passing on")
	t.check(d.gaze != null and d.gaze.value == 0.0 and d.drain_left.is_empty() and d.drained_count() == 0,
		"the Gaze at 0, nothing broken")
	var lit := d.marks().size() == 6
	for m: Array in d.marks():
		lit = lit and (m[1] as Color) == BrokenLanternsDirector.MARK_LIT
	t.check(lit, "the HUD marks the six standing shrines")
	t.check(d.marker() == Vector2.INF and d.timeline != null, "no arrow yet, and a timeline for the night's windows")
	_done(s)


static func _drain(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var rules: Rules = s.rules
	_away(d)
	var sh := d.shrines[0]
	_break(sh)
	t.check(sh.destroyed and d.draining(sh) and not d.is_drained(sh), "a broken shrine starts draining")
	t.check(rules.buildings_down == 0, "and is not counted as a building")
	var ember := false
	for m: Array in d.marks():
		ember = ember or ((m[0] as Vector2) == sh.center() and (m[1] as Color) == BrokenLanternsDirector.MARK_DRAINING)
	t.check(ember, "the HUD marks it draining")
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 1.0)
	t.check(d.draining(sh) and d.drained_count() == 0, "still draining after 19 s")
	_run(s, 1.5)
	t.check(d.is_drained(sh) and d.drained_count() == 1 and not d.draining(sh), "drained after 20 s broken")
	t.check(ShrinesObjective.new().hud_text(rules) == "Shrines drained 1 / 6" and (s.banners as Array).has("A LANTERN IS DRAINED (1 / 6)"),
		"the objective and a banner count it")
	_arrive(d.vigil.bearer, d.relight_point(sh))
	_run(s, DT * 2.0)
	t.check(sh.destroyed and d.relit == 0, "the flame cannot relight a drained shrine")
	_done(s)


## Relighting, a shrine broken twice (review focus 4), and the flame passing on until nobody is left (review focus 1).
static func _relight(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var banners: Array[String] = s.banners
	_away(d)
	var sh := d.shrines[1]
	_break(sh)
	t.check(d.vigil.detour.distance_to(d.relight_point(sh)) < 0.01 and d.marker() == d.vigil.bearer.ground_pos,
		"the flame-bearer turns aside for the broken shrine, and the HUD points at him")
	_arrive(d.vigil.bearer, d.relight_point(sh))
	_run(s, DT * 2.0)
	t.check(not sh.destroyed and sh.hp == sh.max_hp and not d.draining(sh) and d.relit == 1
		and banners.has("THE FLAME RELIGHTS A LANTERN"), "reaching it before it drains, he relights it: it stands again")
	t.check(d.vigil.detour == Vector2.INF and d.marker() == Vector2.INF and d.standing_shrines().has(sh),
		"he goes back to his round; the relit shrine stands")
	_away(d)
	_run(s, 5.0)
	_break(sh)
	t.check(d.draining(sh) and is_equal_approx(float(d.drain_left[sh]), BrokenLanternsDirector.DRAIN_SECONDS),
		"broken again, it drains from the start")
	var first: Person = d.vigil.bearer
	var acolyte: Person = d.vigil.acolytes[0]
	(s.crowd as Crowd)._field.kill(first, &"doom")
	_run(s, VigilRoute.TICK + DT)
	t.check(d.vigil.active and d.vigil.bearer == acolyte and banners.has("AN ACOLYTE TAKES UP THE FLAME"),
		"the bearer killed, an acolyte takes up the flame")
	for p in d.vigil.walkers():
		(s.crowd as Crowd)._field.kill(p, &"doom")
	_run(s, VigilRoute.TICK * 3.0)
	t.check(not d.vigil.active and d.marker() == Vector2.INF, "with all three dead the Vigil is over")
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS)
	t.check(d.is_drained(sh), "and nobody relights the shrine")
	_done(s)


static func _ending(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var rules: Rules = s.rules
	_away(d)
	for sh in d.shrines:
		_break(sh)
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
	t.check(rules.finished and rules.won and rules.over_reason == "drained" and d.drained_count() == 6,
		"six drained win the night (%s)" % rules.over_reason)
	t.check(int(rules.result().get("drained", -1)) == 6 and ResultsScreen.title_for(true, "drained") == "THE LANTERNS ARE DARK",
		"the results report the shrines, under their title")
	_done(s)

	var s2 := _setup()
	var crowd2: Crowd = s2.crowd
	if crowd2.bell != null:
		crowd2.bell.state = BellNetwork.State.RUNG
	_run(s2, DT * 2.0)
	t.check(crowd2.bell == null or ((s2.rules as Rules).finished and (s2.rules as Rules).over_reason == "bell"
		and (s2.d as BrokenLanternsDirector).gaze.is_full()), "the bell loses the night, and fills the Gaze")
	_done(s2)

	var s3 := _setup()
	(s3.d as BrokenLanternsDirector).gaze.fill()
	_run(s3, DT)
	t.check((s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "gaze", "a full Gaze loses it")
	_done(s3)

	var s4 := _setup()
	(s4.rules as Rules).time_left = DT
	_run(s4, DT * 2.0)
	t.check((s4.rules as Rules).finished and not (s4.rules as Rules).won and (s4.rules as Rules).over_reason == "relit"
		and ResultsScreen.title_for(false, "relit") == "THE LANTERNS BURN ON", "dawn with a shrine still lit loses it")
	_done(s4)

	var s5 := _setup()
	var d5: BrokenLanternsDirector = s5.d
	var victim := d5.faithful[5]
	d5.faithful[6].ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s5.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s5, DT * 3.0)
	t.near(d5.gaze.value, GazeMeter.SEEN_DEATH, 0.001, "a seen death adds 10 to the Gaze")
	_done(s5)
