extends RefCounted
## v0.11 M1 the board's Warning (spec §7.2): three stars over three gates at 0:10, 1:30 and 3:00, each a WarningDirector set
## up 2 s before its star, so its watchman is appointed at its gate then; all three stopped wins, a bell rung loses; the
## stars' tags, phases and tour. The campaign's Warning keeps one star over the Main Gate.

const DT := 0.05


static func run(t) -> void:
	_stars(t)
	_bell(t)
	_forced(t)
	_runners(t)
	_runners_freed(t)
	_single(t)


static func _world() -> Dictionary:
	var def := TierBook.board("warning")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null) as StarfallDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


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


## The tags labelled `label`.
static func _labelled(d: MissionDirector, label: String) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for m in d.tags():
		if m.label == label:
			out.append(m)
	return out


static func _stars(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var rules: Rules = s.rules
	t.check(d.stars.size() == 3 and d.stars[0].rules == null and d.stopped() == 0 and d.hint_phase() == "",
		"three stars, none set up before its time")
	var next := _labelled(d, "NEXT STAR")
	t.check(next.size() == 1 and next[0].at == StarfallDirector.STARS[0][1] and next[0].edge, "the first star's gate is pointed at")
	var stops := d.tour()
	t.check(stops.size() == 4 and String(stops[0][1]) == "The Postern. A star falls here at 0:10."
		and String(stops[2][1]) == "The Side Gate. A star falls here at 3:00.", "the tour: the three gates, then the bellkeeper")
	t.check(rules.objectives[0].hud_text(rules) == "Warnings stopped 0 / 3", "the HUD counts them")
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	t.check(first.rules != null and d.stars[1].rules == null and is_instance_valid(first.watchman)
		and first.watchman.ground_pos.distance_to(StarfallDirector.STARS[0][1]) < 1.5,
		"at 0:08 the postern's watchman is appointed at his gate")
	_run(s, 2.2)
	t.check((s.banners as Array).has("A STAR FALLS OVER THE POSTERN") and first.omen_fallen, "at 0:10 its star falls")
	first.warning_dead = true
	first.phase = WarningDirector.Phase.OVER
	_run(s, DT)
	t.check(d.stopped() == 1 and not rules.finished and d.hint_phase() == "waiting" and d.running() == null,
		"one stopped: the night goes on, waiting for the next star")
	d._clock = 87.95
	_run(s, 2.3)
	t.check(d.stars[1].rules != null and (s.banners as Array).has("A STAR FALLS OVER THE MAIN GATE") and d.running() == d.stars[1],
		"at 1:30 the Main Gate's")
	d.stars[1].warning_dead = true
	d._clock = 177.95
	_run(s, 2.3)
	t.check((s.banners as Array).has("A STAR FALLS OVER THE SIDE GATE") and d.next_star() == -1, "at 3:00 the Side Gate's, the last")
	d.stars[2].warning_dead = true
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.over_reason == "warning" and d.report().stopped == 3,
		"all three stopped: won (%s)" % rules.over_reason)
	_done(s)


static func _bell(t) -> void:
	var s := _world()
	(s.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s, DT)
	t.check((s.rules as Rules).finished and not (s.rules as Rules).won and (s.rules as Rules).over_reason == "bell",
		"a warning reaching the bell loses the night")
	_done(s)


static func _forced(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	# A star already stopped is never set up.
	d.stars[1].warning_dead = true
	d.stars[2].warning_dead = true
	d._clock = 200.0
	_run(s, DT)
	t.check(d.stars[1].rules == null and d.stars[2].rules == null, "a star already stopped is never set up")
	# A star set up has its watchman on errand and the bell held for him; teardown lets the bell go.
	var s2 := _world()
	var d2: StarfallDirector = s2.d
	d2._clock = 7.95
	_run(s2, 0.1)
	t.check(d2.stars[0].rules != null and is_instance_valid(d2.stars[0].watchman)
		and (s2.crowd as Crowd).bell.hold_on_death == true, "a star set up holds the bell for its watchman")
	d2.teardown()
	t.check((s2.crowd as Crowd).bell.hold_on_death == false, "teardown lets the bell go")
	_done(s2)
	_done(s)


## Earlier stars' runners are reserved (preflight ruling): star 0 still running at 88 s, with its watchman standing at star 1's
## gate, does not lend him to star 1; and one kill stops only one warning.
static func _runners(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	var lent := first.watchman
	t.check(first.rules != null and is_instance_valid(lent) and not first.warning_dead, "star 0 is set up and running")
	d._clock = 87.9
	lent.ground_pos = StarfallDirector.STARS[1][1]
	_run(s, 0.2)
	var second := d.stars[1]
	t.check(second.rules != null and is_instance_valid(second.watchman) and second.watchman != first.watchman
		and second.watchman != first.messenger, "star 1's watchman is not star 0's watchman or messenger")
	t.check(first.watchman == lent and first.messenger == lent, "and star 0 still has its own")
	var at := second.messenger.ground_pos
	for group: Array[Person] in [(s.crowd as Crowd).citizens, (s.crowd as Crowd).soldiers]:
		for p in group:
			if is_instance_valid(p) and p != second.messenger and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 1.0:
				p.ground_pos = at + Vector2(Crowd.DOOM_WITNESS + 6.0, 0.0)
	(s.field as EnemyField).kill(second.messenger, &"doom")
	_run(s, DT)
	t.check(second.warning_dead and not first.warning_dead and d.stopped() == 1, "one kill stops only one warning")
	_done(s)


## A runner killed on an earlier star and freed after its fade is simply skipped when the next star is set up (and the log
## stays clean: no freed body is put in a typed array).
static func _runners_freed(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	var gone := first.watchman
	t.check(first.rules != null and is_instance_valid(gone), "star 0 is set up with a watchman")
	(s.crowd as Crowd).citizens.erase(gone)
	gone.free()
	t.check(not is_instance_valid(first.watchman), "its watchman is freed (a fade ended)")
	d._clock = 87.9
	_run(s, 0.2)
	var second := d.stars[1]
	t.check(second.rules != null and is_instance_valid(second.watchman), "star 1 is set up all the same, with a watchman of its own")
	_done(s)


static func _single(t) -> void:
	var w := WarningDirector.new()
	t.check(w.post == WarningDirector.GATE_SPOT and w.post_name == "THE MAIN GATE", "a lone Warning's star falls over the Main Gate")
	t.check(MissionBook.warning().director == WarningDirector, "and the campaign's Warning is the lone one")
	var b := TierBook.board("warning")
	var reasons := []
	for o in b.objectives():
		reasons.append(o.reason)
	t.check(b.director == StarfallDirector and b.stretch == 1.0 and reasons == ["warning", "bell", "dawn"]
		and b.goal_label == "The warnings die", "the board's: three stars, stop them all (%s)" % [reasons])
