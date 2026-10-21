extends RefCounted
## v0.10 M4 The Vigil Flame (VigilFlameDirector). The flame-bearer walks the Vigil's route with two acolytes; at 0:50
## Wren comes to watch the lantern; whispered to it he swaps the real flame in 3 s, seen if a Faithful other than the
## bearer stands within Crowd.DOOM_WITNESS; left alone 30 s he tries it himself; at 1:30, while the flame is still in its
## lantern, the route shortens and the bearer home with the real flame loses; Wren carrying the flame to Mira's shrine
## wins. Task 5 adds Phase 2: the Searchlight, its touches, the Faithful's prayer in it, noise and the decoy, and the
## bonus.

const DT := 0.05
## Where the tests stage the swap and park watchers: beyond every beam's reach (Searchlight.FAR + POOL_R from the
## spire), so nothing the light does there is an accident.
const OUT := Vector2(-20.0, 18.0)
const AWAY := Vector2(22.0, 16.0)
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func _setup(board := false) -> Dictionary:
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
	# The town's alarm hushed: deaths in a test never call the bellkeeper (the bell's own case sets it rung).
	crowd.hush(9999.0)
	var def := TierBook.board("vigil_flame") if board else MissionBook.vigil_flame()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.make_director() if board else def.director.new() as MissionDirector).setup(rules, crowd, town, null) as VigilFlameDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var lines := []
	rules.subtitle.connect(func(text: String) -> void: lines.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners, "lines": lines}


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


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


## The first of the director's tags labelled `label`, or null.
static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label or m.label.begins_with(label + " - "):  # Wren's tag counts down to his own try (final review M7)
			return m
	return null


## The HUD shows the Vigil Flame's `phase` line under the objectives, not the mission's own: the director's phase word
## is a real MissionHints key (v0.10 M6).
static func _hint_is(s: Dictionary, phase: String) -> bool:
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	var line := MissionHints.line(MissionBook.VIGIL_FLAME, phase)
	var ok := line != "" and hud.hint_text() == line and line != MissionHints.line(MissionBook.VIGIL_FLAME)
	hud.free()
	return ok


static func _slot(rules: Rules, key: String) -> int:
	for i in rules.loadout.size():
		if rules.key(i) == key:
			return i
	return -1


## 0:50 now: Wren comes.
static func _wren_now(d: VigilFlameDirector) -> void:
	d.timeline.step(VigilFlameDirector.WREN_AT)


## The bearer set down at OUT, and the lantern with him (one step for the director to see it).
static func _bearer_out(s: Dictionary) -> void:
	_arrive((s.d as VigilFlameDirector).vigil.bearer, OUT)
	_run(s, DT)


## Every Faithful but the bearer parked AWAY, a little apart.
static func _clear_watchers(d: VigilFlameDirector) -> void:
	var i := 0
	for f in d.faithful:
		if f == d.vigil.bearer:
			continue
		_arrive(f, AWAY + Vector2(float(i % 8) * 0.6, floorf(float(i) / 8.0) * 0.6))
		i += 1


## Wren whispered to the lantern and set down beside it.
static func _bring_wren(d: VigilFlameDirector) -> void:
	var w := d.wren
	w.whisper(d.flame_at(), 8.0)
	_arrive(w, d.flame_at() + Vector2(0.5, 0.0))


## Wren comes and makes the swap unseen at OUT.
static func _do_swap(s: Dictionary) -> void:
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	_bring_wren(d)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)


static func run(t) -> void:
	_cast(t)
	_wren(t)
	_swap(t)
	_own_try(t)
	_lured_wren(t)
	_board_wren(t)
	_route(t)
	_carry(t)
	_ending(t)
	_focus(t)
	_light(t)
	_touches(t)
	_prayer(t)
	_heard(t)
	_bonus(t)
	_teardown(t)
	_lines(t)
	_tags(t)
	_freed_bearer(t)
	_fallen_homeward(t)
	_loose_ends(t)
	_lantern(t)
	_mission_time(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var grid: WalkGrid = s.grid
	var faithful_ok := d.faithful.size() >= VigilFlameDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL
	t.check(faithful_ok, "the Faithful chosen (%d)" % d.faithful.size())
	var route_ok := d.vigil != null and d.vigil.route.size() == BrokenLanternsDirector.SHRINE_SPOTS.size()
	if route_ok:
		for i in BrokenLanternsDirector.SHRINE_SPOTS.size():
			route_ok = route_ok and d.vigil.route[i].distance_to(BrokenLanternsDirector.SHRINE_SPOTS[i]) < 2.0
	t.check(route_ok and d.vigil.active and d.vigil.loop and d.vigil.pass_flame and d.vigil.walkers().size() == 3
		and d.faithful.has(d.vigil.bearer), "the Vigil sets out on the six shrines' route, looping, the flame passing on")
	var slow := true
	for p in d.vigil.walkers():
		slow = slow and p.pace <= Person.PACE_RANGE.y * VigilFlameDirector.VIGIL_PACE + 0.001
	t.check(slow, "its three walk at the Vigil's solemn pace")
	var beside := d.vigil.acolytes.size() == 2
	for a in d.vigil.acolytes:
		beside = beside and d.vigil.bearer.pace <= a.pace * VigilFlameDirector.BEARER_LEAD + 0.001
	t.check(beside, "the bearer walks a step slower than his slowest acolyte, so both keep beside him")
	var reach := grid.walkable(d.shrine) and d.shrine.distance_to(VigilFlameDirector.MIRA_SHRINE) < 2.0 and d.shrine.x < -12.0
	for pt in d.vigil.route:
		reach = reach and not grid.path(pt, d.shrine).is_empty()
	t.check(reach, "Mira's shrine stands at the west edge, and Wren can walk to it from anywhere on the route")
	t.check(d.gaze != null and d.gaze.value == 0.0 and d.wren == null and not d.appeared and not d.swapped
		and d.searchlight != null and not d.searchlight.on, "the Gaze at 0, no Wren yet, the light asleep")
	var tags := d.tags()
	t.check(tags.size() == 2 and tags[0].label == "HALCYON'S FLAME" and tags[0].at == d.vigil.bearer.ground_pos
		and tags[0].color == VigilFlameDirector.MARK_FLAME and tags[0].edge and tags[1].label == "MIRA'S SHRINE"
		and tags[1].at == d.shrine and tags[1].color == VigilFlameDirector.MARK_SHRINE and tags[1].edge,
		"the HUD names the flame and Mira's shrine, both pointed at from the edge")
	# The flame's tag follows its bearer between the director's steps (it does not step during the intro's tour).
	_arrive(d.vigil.bearer, OUT)
	var flame := _tag(d, "HALCYON'S FLAME")
	t.check(flame != null and flame.at == OUT, "the flame's tag follows its bearer even between the director's steps")
	var next := d.timeline.upcoming(2)
	t.check(d.hint_phase() == "" and next.size() == 2 and next[0].id == "wren" and next[1].id == "route",
		"before Wren, the mission's own line; the strip shows Wren coming and the route shortening")
	t.check(OUT.distance_to(d.searchlight.spire) > Searchlight.FAR + Searchlight.POOL_R
		and AWAY.distance_to(d.searchlight.spire) > Searchlight.FAR + Searchlight.POOL_R, "the tests' staging lies beyond the light")
	# A beam must be able to keep to its path (the tests aim at it): it outruns the fastest the sweep ever moves it, the
	# spin at the far reach plus the reach swinging in and out.
	var sweep_max := Searchlight.SPIN * Searchlight.FAR + (Searchlight.FAR - Searchlight.NEAR) * PI / Searchlight.REACH_PERIOD
	t.check(Searchlight.BEAM_SPEED > sweep_max, "a beam outruns its own sweep (%.1f over %.1f)" % [Searchlight.BEAM_SPEED, sweep_max])
	_done(s)


static func _wren(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	var w := d.wren
	t.check(d.appeared and _alive(w) and not d.faithful.has(w) and w.profile.faith == CitizenProfile.Faith.NONE
		and (s.banners as Array).has("A BOY WATCHES THE LANTERN"), "0:50: Wren comes, a citizen not of the Faith")
	_run(s, VigilFlameDirector.TICK + DT)
	t.check(w.mind == Person.Mind.DUTY and absf(w.anchor.distance_to(d.flame_at()) - VigilFlameDirector.WATCH_DIST) < 1.0,
		"he keeps watch a few steps from the lantern (%.1f)" % w.anchor.distance_to(d.flame_at()))
	var wt := _tag(d, "WREN")
	t.check(wt != null and wt.at == w.ground_pos and wt.color == VigilFlameDirector.MARK_WREN and wt.edge
		and d.hint_phase() == "wren", "the HUD names him and points at him; the hint says whisper him to the flame")
	t.check(_hint_is(s, "wren"), "and the HUD shows that line, under the objectives")
	t.check(String(wt.label).begins_with("WREN - TRIES THE LANTERN 0:"), "M7: his tag counts down to his own try (%s)" % wt.label)
	w.whisper(d.flame_at() + Vector2(0.5, 0.0), MindWhisperFx.LINGER)
	_run(s, DT)
	t.check(_tag(d, "WREN") != null and _tag(d, "WREN").label == "WREN", "whispered, it is his name alone")
	_done(s)


static func _swap(t) -> void:
	# Unseen: nobody of the Faith near but the bearer, and the bearer, robbed, sees nothing.
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	_bring_wren(d)
	_run(s, DT * 2.0)
	t.check(d.swapping and d.whispered and d.wren.mind == Person.Mind.DUTY, "whispered to the lantern, Wren takes hold")
	_run(s, VigilFlameDirector.SWAP_SECONDS - 0.5)
	t.check(d.swapping and not d.swapped, "the swap takes 3 s")
	_run(s, 0.6)
	t.check(d.swapped and not d.swap_seen and d.reports.is_empty() and (s.banners as Array).has("THE FLAME IS TAKEN"),
		"then he has the real flame, unseen (the bearer at his side sees nothing)")
	t.check(d.wren.mind == Person.Mind.DUTY and d.wren.anchor.distance_to(d.shrine) < 0.01 and d.flame_at() == d.wren.ground_pos
		and d.wren.pace <= Person.PACE_RANGE.y * VigilFlameDirector.WREN_PACE + 0.001,
		"and carries it carefully toward Mira's shrine")
	var lantern_marked := false
	for m in d.tags():
		lantern_marked = lantern_marked or m.color == VigilFlameDirector.MARK_FLAME
	t.check(not lantern_marked, "the HUD no longer marks the lantern")
	_done(s)

	# Seen: an acolyte at Wren's side runs to the Temple; the flame is taken all the same; the report home fills the Gaze.
	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	_bearer_out(s2)
	_clear_watchers(d2)
	var acolyte: Person = d2.vigil.acolytes[0]
	_bring_wren(d2)
	_arrive(acolyte, d2.wren.ground_pos + Vector2(0.0, 1.2))
	_run(s2, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d2.swapped and d2.swap_seen and d2.reports.size() == 1 and d2.reports[0].carrier == acolyte
		and (s2.banners as Array).has("A FAITHFUL RUNS TO THE TEMPLE"),
		"a swap an acolyte sees is reported, and the flame is taken all the same")
	_arrive(acolyte, d2.temple_door)
	_run(s2, DT * 2.0)
	t.check((s2.rules as Rules).finished and (s2.rules as Rules).over_reason == "gaze" and d2.gaze.is_full(),
		"the report reaching the Temple fills the Gaze: the night is lost")
	_done(s2)

	# Held: an acolyte at his side, but confused by Discord, sees nothing.
	var s3 := _setup()
	var d3: VigilFlameDirector = s3.d
	_wren_now(d3)
	_bearer_out(s3)
	_clear_watchers(d3)
	var held: Person = d3.vigil.acolytes[0]
	_bring_wren(d3)
	_arrive(held, d3.wren.ground_pos + Vector2(0.0, 1.2))
	held.confuse(15.0)
	_run(s3, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d3.swapped and not d3.swap_seen and d3.reports.is_empty(), "an acolyte held by Discord sees nothing")
	_done(s3)


## A Wisp cast at `at` in the staged world (v0.11.1 tests): the real effect, so it draws whom it would.
static func _wisp_at(s: Dictionary, at: Vector2) -> FxTimeline:
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rules = s.rules
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return FxTimeline.cast(load("res://src/fx/control/will_o_wisp.gd"), ctx, at)


## v0.11.1 (spec §7.2 row 11): Wren answers a Wisp. One cast within CHARGE_LURE_R of him draws him from his duty to its light, the director
## leaves him to it (a lure is the god's hand as a whisper is), and the lantern coming near the light he stands in, he takes hold; one cast
## 5.0 away does not move him.
static func _lured_wren(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	var w := d.wren
	t.check(w.answers_lure, "Wren answers a lure from the moment he comes")
	_run(s, VigilFlameDirector.TICK + DT)
	var lantern := d.flame_at()
	_arrive(w, lantern + Vector2(2.5, 0.0))
	var far := _wisp_at(s, lantern + Vector2(7.5, 0.0))
	_run(s, 1.0)
	t.check(w.mind == Person.Mind.DUTY and not w.held_by_god() and not d.whispered, "a Wisp cast 5.0 away does not move him")
	far.free()
	var near := _wisp_at(s, lantern)
	t.check(w.mind == Person.Mind.OBSERVE and w.held_by_god(), "a Wisp within 3.0 of him draws him to its light")
	_run(s, VigilFlameDirector.TICK * 3.0)
	t.check(w.mind == Person.Mind.OBSERVE and w.has_goal(), "and the director leaves him to it (no errand sent over the lure)")
	_arrive(w, w.goal())  # (headless people do not walk their goals in this world: he stands at the ring spot the lure gave him)
	_run(s, 0.6)
	t.check(d.whispered and (d.swapping or d.swapped), "at the lantern's side he takes hold as a whispered one does (%s)" % d.hint_phase())
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.5)
	t.check(d.swapped and d.wren.mind == Person.Mind.DUTY and d.wren.anchor.distance_to(d.shrine) < 0.01,
		"and carries the flame to Mira's shrine")
	near.free()
	# The Searchlight does not hear the Wisp that drew him.
	d.searchlight.hear(Vector2.INF)
	d._on_cast(0, "wisp", w.ground_pos)
	t.check(d.searchlight.noise == Vector2.INF, "a Wisp that draws Wren is no noise to the light")
	d._on_cast(0, "wisp", w.ground_pos + Vector2(8.0, 0.0))
	t.check(d.searchlight.noise != Vector2.INF, "a Wisp farther off still is")
	_done(s)


static func _own_try(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_run(s, VigilFlameDirector.WREN_OWN_AFTER - 1.0)
	t.check(not d.attempting, "left alone, Wren only watches at first")
	_run(s, 1.0 + VigilFlameDirector.TICK + DT)
	t.check(d.attempting and d.wren.mind == Person.Mind.DUTY and d.wren.anchor.distance_to(d.flame_at()) < 0.6
		and (s.banners as Array).has("THE BOY TRIES FOR THE LANTERN"), "30 s without a whisper, he goes for the lantern himself")
	_arrive(d.wren, d.flame_at() + Vector2(0.5, 0.0))
	_run(s, DT * 2.0)
	t.check(d.swapping, "and takes hold of it without the god")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	_run(s2, DT)
	d2.wren.whisper(d2.wren.ground_pos + Vector2(1.0, 0.0), 8.0)
	_run(s2, DT)
	t.check(d2.whispered, "whispered once, he is the god's")
	_run(s2, VigilFlameDirector.WREN_OWN_AFTER + 1.0)
	t.check(not d2.attempting, "and never tries on his own")
	_done(s2)


## Final review, item 3 (the user's rule: no wait over 60 s): on the board the other events stretch with the clock, but Wren's
## arrival (WREN_AT) and his own-try wait (WREN_OWN_AFTER) run in real seconds.
static func _board_wren(t) -> void:
	var s := _setup(true)
	var d: VigilFlameDirector = s.d
	t.check(d.stretch > 1.5 and d.timeline.stretch_factor() == d.stretch, "(set-up) the board's Vigil Flame stretches its timeline (x%.2f)" % d.stretch)
	t.near(d.timeline.seconds_to("route"), VigilFlameDirector.ROUTE_AT * d.stretch, 0.01, "the other events keep their stretch (the route)")
	_run(s, VigilFlameDirector.WREN_AT - 1.0)
	t.check(not d.appeared, "on the board Wren has not come at 0:49")
	_run(s, 1.0 + DT * 2.0)
	t.check(d.appeared and d.wren != null, "and comes at 0:50, not at %.0f s" % (VigilFlameDirector.WREN_AT * d.stretch))
	_run(s, VigilFlameDirector.WREN_OWN_AFTER - 1.0)
	t.check(not d.attempting, "left alone, he only watches until 30 s after")
	_run(s, 1.0 + VigilFlameDirector.TICK + DT)
	t.check(d.attempting and (s.banners as Array).has("THE BOY TRIES FOR THE LANTERN"), "and tries the lantern himself 30 s after he came")
	_done(s)


static func _route(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	d.timeline.step(VigilFlameDirector.ROUTE_AT)
	t.check(d.homeward and d.vigil.route.size() == 1 and d.vigil.route[0] == d.temple_door and not d.vigil.loop
		and (s.banners as Array).has("THE ROUTE SHORTENS"), "1:30: a suspicious priest sends the Vigil straight home")
	_arrive(d.vigil.bearer, d.temple_door)
	_run(s, DT)
	t.check(rules.finished and not rules.won and rules.over_reason == "kept" and d.kept
		and ResultsScreen.title_for(false, "kept") == "THE FLAME IS KEPT", "the bearer home with the real flame: the night is lost")
	_done(s)

	# The route shortens only while the flame is still in its lantern (v0.10 M5), so the Vigil is already on its way home when
	# Wren takes the flame, and the bearer reaches the Temple with the false one.
	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	d2.timeline.step(VigilFlameDirector.ROUTE_AT)
	_bearer_out(s2)
	_clear_watchers(d2)
	_bring_wren(d2)
	_run(s2, VigilFlameDirector.SWAP_SECONDS + 0.2)
	_arrive(d2.vigil.bearer, d2.temple_door)
	_run(s2, DT)
	t.check(d2.swapped and d2.homeward and not d2.kept and not (s2.rules as Rules).finished, "home with the false flame, nothing is lost")
	t.check(d2.hint_phase() == "carry" and _tag(d2, "TEMPLE") == null,
		"swapped on the way home: the hint says carry it, and the Temple is not tagged (it holds only the false flame)")
	_done(s2)


static func _carry(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	_do_swap(s)
	var w := d.wren
	w.whisper(w.ground_pos + Vector2(1.0, 0.0), 8.0)
	_run(s, VigilFlameDirector.TICK + DT)
	t.check(w.mind == Person.Mind.WHISPERED, "whispered on his way, Wren is the god's to steer")
	w.mind = Person.Mind.RECOVER
	_run(s, VigilFlameDirector.TICK + DT)
	t.check(w.mind == Person.Mind.DUTY and w.anchor.distance_to(d.shrine) < 0.01, "back on his feet, he makes for the shrine again")
	_arrive(w, d.shrine)
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.over_reason == "flame" and d.home
		and (s.banners as Array).has("MIRA'S SHRINE BURNS AGAIN") and ResultsScreen.title_for(true, "flame") == "THE FLAME IS STOLEN",
		"the flame at Mira's shrine wins the night")
	t.check(bool(rules.result().get("home", false)) and bool(rules.result().get("swapped", false)), "the results report it")
	t.check(_tag(d, "WREN") == null, "the flame home, Wren is no longer tagged")
	_done(s)


static func _ending(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	(s.crowd as Crowd)._field.kill(d.wren, &"doom")
	_run(s, DT * 3.0)
	t.check((s.rules as Rules).finished and (s.rules as Rules).over_reason == "wren"
		and ResultsScreen.title_for(false, "wren") == "THE BOY IS DEAD", "Wren dead loses the night")
	_done(s)

	var s2 := _setup()
	(s2.d as VigilFlameDirector).gaze.fill()
	_run(s2, DT)
	t.check((s2.rules as Rules).finished and (s2.rules as Rules).over_reason == "gaze", "a full Gaze loses it")
	_done(s2)

	var s3 := _setup()
	(s3.rules as Rules).time_left = DT
	_run(s3, DT * 2.0)
	t.check((s3.rules as Rules).finished and not (s3.rules as Rules).won and (s3.rules as Rules).over_reason == "late"
		and ResultsScreen.title_for(false, "late") == "DAWN FINDS THE FLAME", "dawn first loses it")
	_done(s3)

	var s4 := _setup()
	var crowd4: Crowd = s4.crowd
	if crowd4.bell != null:
		crowd4.bell.state = BellNetwork.State.RUNG
	_run(s4, DT * 2.0)
	t.check(not (s4.d as VigilFlameDirector).gaze.is_full() and not (s4.rules as Rules).finished,
		"v0.11.2: a rung bell no longer fills the Gaze by itself (the Lantern's toll adds 40: _lantern)")
	_done(s4)

	var s5 := _setup()
	var d5: VigilFlameDirector = s5.d
	var victim := d5.faithful[5]
	d5.faithful[6].ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s5.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s5, DT * 3.0)
	t.near(d5.gaze.value, GazeMeter.SEEN_DEATH * VigilFlameDirector.SEEN_DEATH_SCALE, 0.001, "a seen death adds to the Gaze")
	_done(s5)


## Review focus 1-3: the Vigil struck down before the swap; Wren held mid-swap; nobody left to be Wren.
static func _focus(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var crowd: Crowd = s.crowd
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	var acolyte: Person = d.vigil.acolytes[0]
	var trailing: Person = d.vigil.acolytes[1]
	# The acolyte who will take the flame up is the brisker of the two: his own pace would leave the other behind.
	acolyte.pace = 1.0
	trailing.pace = 0.4
	crowd._field.kill(d.vigil.bearer, &"doom")
	_run(s, VigilRoute.TICK + DT)
	t.check(d.vigil.bearer == acolyte and (s.banners as Array).has("AN ACOLYTE TAKES UP THE FLAME"),
		"the bearer struck down, an acolyte takes up the flame")
	t.check(acolyte.pace <= trailing.pace * VigilFlameDirector.BEARER_LEAD + 0.001,
		"the new bearer too walks a step slower than the acolyte left (%.2f vs %.2f)" % [acolyte.pace, trailing.pace])
	_arrive(acolyte, OUT + Vector2(2.0, 0.0))
	_run(s, DT)
	var fell := acolyte.ground_pos
	for p in d.vigil.walkers():
		crowd._field.kill(p, &"doom")
	_run(s, VigilRoute.TICK * 2.0)
	var marked := false
	for m in d.tags():
		marked = marked or (m.at == fell and m.color == VigilFlameDirector.MARK_FLAME)
	t.check(not d.vigil.active and d.flame_at() == fell and marked,
		"all three dead, the lantern lies where its last bearer fell, still marked")
	_bring_wren(d)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d.swapped and not d.swap_seen, "Wren takes the flame from the fallen lantern")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_wren_now(d2)
	_bearer_out(s2)
	_clear_watchers(d2)
	_bring_wren(d2)
	_run(s2, 1.0)
	t.check(d2.swapping and d2.swap_left < VigilFlameDirector.SWAP_SECONDS, "a swap under way")
	d2.wren.confuse(5.0)
	_run(s2, DT)
	t.check(not d2.swapping and not d2.swapped, "Wren held by Discord mid-swap: it is broken")
	_bring_wren(d2)
	_run(s2, DT * 2.0)
	t.check(d2.swapping and d2.swap_left > VigilFlameDirector.SWAP_SECONDS - 0.2, "whispered back, it starts again from the beginning")
	_done(s2)

	var s3 := _setup()
	var d3: VigilFlameDirector = s3.d
	for p in (s3.crowd as Crowd).citizens:
		if not d3.faithful.has(p):
			p.inside = true
	_wren_now(d3)
	_run(s3, DT)
	t.check(d3.no_wren and d3.wren == null and (s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "wren",
		"with nobody left to be Wren, the night is lost")
	_done(s3)


## The swap wakes the Searchlight: one beam, a second 30 s on, the strip's search in the clock's last 20 s.
static func _light(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var banners: Array = s.banners
	_do_swap(s)
	t.check(d.searchlight.on and d.searchlight.beams() == 1 and banners.has("THE SPIRE FLARES"),
		"the swap wakes the Searchlight: one beam")
	_run(s, Searchlight.SECOND_AFTER)
	t.check(d.searchlight.beams() == 2 and banners.has("A SECOND BEAM"), "30 s on, a second")
	(s.rules as Rules).time_left = Searchlight.SEARCH_LAST
	d.timeline.step(200.0)
	_run(s, DT)
	t.check(banners.has("THE LIGHT SEARCHES"), "in the last 20 s the light searches")
	_done(s)


## A beam on Wren adds TOUCH_GAZE once each time he comes into the light (review focus 4: a beam resting on him counts
## once); found twice, the Gaze is full.
static func _touches(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_do_swap(s)
	var w := d.wren
	_arrive(w, d.searchlight.aim(0))
	_run(s, DT)
	t.check(d.touches == 1 and is_equal_approx(d.gaze.value, VigilFlameDirector.TOUCH_GAZE)
		and (s.banners as Array).has("THE LIGHT FINDS THE BOY"), "a beam touching Wren adds 50 to the Gaze")
	for i in 20:
		_arrive(w, d.searchlight.aim(0))
		_run(s, DT)
	t.check(d.touches == 1 and is_equal_approx(d.gaze.value, VigilFlameDirector.TOUCH_GAZE),
		"a beam resting on him counts once, until he leaves the light")
	_arrive(w, OUT)
	_run(s, DT)
	_arrive(w, d.searchlight.aim(0))
	_run(s, DT)
	t.check(d.touches == 2 and d.gaze.is_full() and (s.rules as Rules).finished and (s.rules as Rules).over_reason == "gaze",
		"found twice, the Gaze is full: the night is lost")
	_done(s)


## A Faithful a beam touches stops and prays PRAY_SECONDS where he stands, feeding the Gaze; one held does not.
static func _prayer(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_do_swap(s)
	var free: Array[Person] = []
	for x in d.faithful:
		if not d.vigil.walkers().has(x):
			free.append(x)
	var f := free[0]
	_arrive(f, d.searchlight.aim(0))
	_run(s, DT)
	t.check(d.praying.has(f) and f.mind == Person.Mind.DUTY and f.anchor.distance_to(f.ground_pos) < 0.01
		and d.praying_count() == 1, "a Faithful the beam touches stops and prays where he stands")
	var g0 := d.gaze.value
	_run(s, 1.0)
	t.near(d.gaze.value - g0, GazeMeter.PRAYER_PER_SECOND * VigilFlameDirector.PRAYER_SCALE, 0.06, "his prayer feeds the Gaze")
	_run(s, VigilFlameDirector.PRAY_SECONDS)
	t.check(not d.praying.has(f) and f.mind != Person.Mind.DUTY, "his prayer done, he goes back to his day")
	var h := free[1]
	h.confuse(15.0)
	_arrive(h, d.searchlight.aim(0))
	_run(s, DT)
	t.check(not d.praying.has(h), "one held by Discord does not pray")
	_done(s)


## What the light hears: a cast (even before it wakes), not a whisper; a Will-o'-Wisp is a decoy and a noise; a death
## is a noise.
static func _heard(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var at := Vector2(4.0, 6.0)
	rules.cast(_slot(rules, "discord"), at)
	t.check(d.searchlight.noise == at, "a cast is a noise, heard even before the light wakes")
	var c: Person = crowd.citizens[3]
	rules.cast(_slot(rules, "whisper"), c.ground_pos, {"target": c, "to": c.ground_pos + Vector2(1.0, 0.0)})
	t.check(d.searchlight.noise == at, "a Mind Whisper is unheard")
	_do_swap(s)
	var lure_at := d.searchlight.aim(0) + Vector2(3.0, 0.0)
	rules.cast(_slot(rules, "wisp"), lure_at)
	t.check(d.searchlight.decoy_beam == 0 and d.searchlight.decoy == lure_at and d.searchlight.noise == lure_at,
		"a Will-o'-Wisp is a decoy the beam follows, and a noise")
	var victim: Person = null
	for p in crowd.citizens:
		if _alive(p) and p != d.wren and not p.inside:
			victim = p
			break
	crowd._field.kill(victim, &"doom")
	t.check(d.searchlight.noise == victim.ground_pos, "a death is a noise")
	_done(s)


## Home with no beam ever on Wren: won, with Unseen hands, and the light dies; found once on the way: won without it.
static func _bonus(t) -> void:
	for touched in [false, true]:
		var s := _setup()
		var d: VigilFlameDirector = s.d
		var rules: Rules = s.rules
		_do_swap(s)
		if touched:
			_arrive(d.wren, d.searchlight.aim(0))
			_run(s, DT)
		_arrive(d.wren, d.shrine)
		_run(s, DT)
		var res := rules.result()
		var earned: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
		if not touched:
			t.check(rules.won and earned and res.bonuses[0].label == "Unseen hands" and not d.searchlight.on,
				"home unseen by any beam: won, and Unseen hands; the light dies")
		else:
			t.check(rules.won and not earned and int(res.get("touches", 0)) == 1, "found once on the way: won, without the bonus")
		_done(s)


## Review focus 5: let go mid-Phase 2, the light is out, the prayers get up, and the world's signals are let go.
static func _teardown(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var rules: Rules = s.rules
	_do_swap(s)
	var f: Person = null
	for x in d.faithful:
		if not d.vigil.walkers().has(x):
			f = x
			break
	_arrive(f, d.searchlight.aim(0))
	_run(s, DT)
	d.teardown()
	t.check(not d.searchlight.on and d.praying.is_empty() and f.mind != Person.Mind.DUTY
		and not rules.cast_made.is_connected(d._on_cast)
		and not (s.crowd as Crowd)._field.enemy_killed.is_connected(d._on_killed),
		"let go mid-search: the light out, the prayers released, the world's signals let go")
	_done(s)


## Cael's lines (v0.10 M5, spec §5.2): as Wren comes, and as the light wakes at the swap. Review focus 2: with nobody
## left to be Wren, nothing is said of the boy.
static func _lines(t) -> void:
	var s := _setup()
	var lines: Array = s.lines
	_wren_now(s.d)
	t.check(lines == [CampaignText.cael_line(MissionBook.VIGIL_FLAME, "wren")], "as Wren comes, Cael speaks (%s)" % [lines])
	_done(s)

	var s2 := _setup()
	_do_swap(s2)
	var lines2: Array = s2.lines
	t.check(lines2.size() == 2 and lines2[1] == CampaignText.cael_line(MissionBook.VIGIL_FLAME, "light"),
		"as the swap wakes the light, he speaks again (%s)" % [lines2])
	_done(s2)

	var s3 := _setup()
	var d3: VigilFlameDirector = s3.d
	for p in (s3.crowd as Crowd).citizens:
		if not d3.faithful.has(p):
			p.inside = true
	_wren_now(d3)
	t.check(d3.no_wren and (s3.lines as Array).is_empty(), "with nobody to be Wren, nothing is said of him (%s)" % [s3.lines])
	_done(s3)


## v0.10 M6 (spec §4.3): while Wren may be seen taking it, each Faithful near enough to see him is marked red, never the
## bearer; the Temple is tagged while the Vigil takes the real flame home; once swapped the hint says carry it, and the
## flame's and the Temple's tags go; dead, Wren is not tagged (review focus 2).
static func _tags(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	_bring_wren(d)
	var reds := 0
	for m in d.tags():
		reds += 1 if m.color == VigilFlameDirector.MARK_WATCHED and m.label == "" else 0
	t.check(reds == 0, "the bearer alone by Wren: nobody marked red")
	var acolyte := d.vigil.acolytes[0]
	_arrive(acolyte, d.wren.ground_pos + Vector2(0.5, 0.0))
	var marked := false
	for m in d.tags():
		marked = marked or (m.at == acolyte.ground_pos and m.color == VigilFlameDirector.MARK_WATCHED and m.label == "")
	t.check(marked, "an acolyte beside him: marked red, a witness")
	d.timeline.step(VigilFlameDirector.ROUTE_AT - VigilFlameDirector.WREN_AT)
	var temple := _tag(d, "TEMPLE")
	t.check(d.homeward and temple != null and temple.at == d.temple_door and temple.edge and d.hint_phase() == "homeward",
		"the Vigil turned for home: the Temple is tagged, and the hint says hurry")
	t.check(_hint_is(s, "homeward"), "and the HUD shows that line")
	(s.crowd as Crowd)._field.kill(d.wren, &"doom")
	t.check(_tag(d, "WREN") == null, "dead, Wren is not tagged (review focus 2)")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_do_swap(s2)
	t.check(d2.swapped and d2.hint_phase() == "carry" and _tag(d2, "HALCYON'S FLAME") == null and _tag(d2, "TEMPLE") == null
		and _tag(d2, "MIRA'S SHRINE") != null and _tag(d2, "WREN") != null,
		"swapped: the hint says carry it home; Wren and Mira's shrine stay tagged, the lantern's flame does not")
	t.check(_hint_is(s2, "carry"), "and the HUD shows that line")
	_arrive(d2.vigil.acolytes[0], d2.wren.ground_pos + Vector2(0.5, 0.0))
	var late := 0
	for m in d2.tags():
		late += 1 if m.color == VigilFlameDirector.MARK_WATCHED and m.label == "" else 0
	t.check(late == 0, "the flame taken, a Faithful beside Wren is no witness: nobody is marked red")
	_done(s2)


## v0.10 M6: the whole Vigil fallen and the last bearer's body freed, the witnesses are still tagged and the swap still
## judged (a freed person passed on as a Person would abort both calls).
static func _freed_bearer(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var crowd: Crowd = s.crowd
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	var walkers := d.vigil.walkers()
	for p in walkers:
		crowd._field.kill(p, &"doom")
	_run(s, VigilRoute.TICK * 3.0)
	var last := d.vigil.bearer
	t.check(not d.vigil.active and is_instance_valid(last) and not walkers.is_empty(),
		"the whole Vigil has fallen; the lantern lies where the last bearer fell")
	last.free()
	var f: Person = null
	for p in d.faithful:
		if is_instance_valid(p) and p.is_alive() and not walkers.has(p):
			f = p
			break
	_bring_wren(d)
	_arrive(f, d.wren.ground_pos + Vector2(0.5, 0.0))
	var red := false
	for m in d.tags():
		red = red or (m.at == f.ground_pos and m.color == VigilFlameDirector.MARK_WATCHED and m.label == "")
	t.check(red, "the last bearer's body freed: the Faithful beside Wren is still tagged a witness")
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d.swapped and d.swap_seen, "and the swap is still seen")
	_done(s)


## v0.10 M6: the route has shortened, then the whole Vigil falls before the swap -- nobody is going home, so the Temple is
## not tagged and the hint no longer says hurry.
static func _fallen_homeward(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	var crowd: Crowd = s.crowd
	d.timeline.step(VigilFlameDirector.ROUTE_AT)
	t.check(d.homeward and _tag(d, "TEMPLE") != null and d.hint_phase() == "homeward", "the Vigil turned for home: the Temple")
	for p in d.vigil.walkers():
		crowd._field.kill(p, &"doom")
	_run(s, VigilRoute.TICK * 3.0)
	t.check(not d.vigil.active and _tag(d, "TEMPLE") == null and d.hint_phase() != "homeward",
		"the whole Vigil fallen: no Temple tag, and the hint no longer says hurry (%s)" % d.hint_phase())
	_done(s)


## v0.10 M5: the Faithful who sees the swap runs to the Temple at his own pace, not the Vigil's; after the swap there is
## no route home and no acolyte "taking up the flame" -- the flame is gone.
static func _loose_ends(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	var aco := d.vigil.acolytes[0]
	var own := float(d._walk_pace[aco])
	# The pace kept for him is a citizen's own (Person.PACE_RANGE), taken before the Vigil slowed him: a slowed one is at
	# most 1.2 x VIGIL_PACE, so this fails if the snapshot is taken after the slowing, whatever the restore then does.
	t.check(own >= Person.PACE_RANGE.x and own > aco.pace,
		"the pace kept for an acolyte is his own, from before the Vigil slowed him (own %.2f, now %.2f, least %.2f)"
		% [own, aco.pace, Person.PACE_RANGE.x])
	_arrive(aco, OUT + Vector2(0.0, 1.0))
	_bring_wren(d)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 0.2)
	t.check(d.swap_seen and not d.reports.is_empty() and d.reports[0].carrier == aco and is_equal_approx(aco.pace, own),
		"the acolyte who saw the swap runs at his own pace (%.2f, own %.2f)" % [aco.pace, own])
	# The bearer then falls with the report still on the road: the flame passes to the carrier, who is not slowed to the
	# Vigil's pace (he is off the Vigil).
	(s.crowd as Crowd)._field.kill(d.vigil.bearer, &"doom")
	_run(s, VigilRoute.TICK + DT)
	t.check(d.vigil.bearer == aco and d._carrying(aco) and is_equal_approx(aco.pace, own),
		"the flame passing to him on the road does not slow him (%.2f, own %.2f)" % [aco.pace, own])
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	var banners: Array = s2.banners
	_do_swap(s2)
	d2.timeline.step(VigilFlameDirector.ROUTE_AT)
	_run(s2, DT)
	t.check(not d2.homeward and not banners.has("THE ROUTE SHORTENS"), "after the swap the route never shortens")
	(s2.crowd as Crowd)._field.kill(d2.vigil.bearer, &"doom")
	_run(s2, VigilRoute.TICK + DT)
	t.check(not banners.has("AN ACOLYTE TAKES UP THE FLAME"), "nor does an acolyte take up a flame that is false")
	_done(s2)


## A board Vigil Flame (the campaign's town has no bell) with the Lantern its mission asks for, not hushed.
static func _lantern_world() -> Dictionary:
	var def := TierBook.board(MissionBook.VIGIL_FLAME)
	var s := Kit.world(def)
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, def.lantern)
	(s.rules as Rules).lantern = lw
	s["lw"] = lw
	return s


## The bell tolls as it does in play: a keeper on the rope, the climb done.
static func _toll(s: Dictionary) -> void:
	var bell: BellNetwork = (s.crowd as Crowd).bell
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()


## v0.11.2 Task 18: The Vigil Flame is a gaze night -- the toll adds LanternWatch.GAZE_TOLL (40) to the Gaze instead of filling it, the clock
## runs 1.5 times as fast, and the Lantern's own beam (a separate light) costs no Gaze.
static func _lantern(t) -> void:
	t.check(MissionBook.vigil_flame().lantern == "gaze" and TierBook.board(MissionBook.VIGIL_FLAME).lantern == "gaze",
		"the Vigil Flame is a gaze night, campaign and board")
	var s := _lantern_world()
	var d: VigilFlameDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var crowd: Crowd = s.crowd
	t.check(crowd.bell != null and crowd.bell.state == BellNetwork.State.IDLE, "(the board's town has a bell, still asleep)")
	_toll(s)
	Kit.run_for(s, 3.0)
	t.check(lw.tolled and is_equal_approx(d.gaze.value, LanternWatch.GAZE_TOLL) and not d.gaze.is_full() and not r.finished,
		"the toll adds 40 to the Gaze: the night goes on (it used to lose)")
	t.check(is_equal_approx(r.clock_rate, 1.5) and lw.stage == LanternWatch.Stage.STIRRING, "and the Lantern Stirs: the clock at x1.5")
	crowd.unring_bell()
	_toll(s)
	Kit.run_for(s, 0.5)
	t.check(is_equal_approx(d.gaze.value, LanternWatch.GAZE_TOLL), "a second toll (the bell unrung) adds nothing")
	Kit.done(s)
	# The Lantern's beam is its own light: Wren in it adds nothing to the Gaze, Stirring or Burning.
	var b := _lantern_world()
	var bd: VigilFlameDirector = b.d
	var bl: LanternWatch = b.lw
	bd.timeline.step(VigilFlameDirector.WREN_AT)  # Wren has come
	_toll(b)
	Kit.run_for(b, 0.5)
	var spot := bl.light.aim(0)
	Kit.arrive(bd.wren, spot)
	Kit.run_for(b, 0.1)
	t.check(bl.light.touches(bd.wren.ground_pos) and bd.touches == 0 and is_equal_approx(bd.gaze.value, LanternWatch.GAZE_TOLL),
		"Wren in the Lantern's beam adds nothing to the Gaze (the Vigil's own light is not lit yet)")
	bl.burn()
	Kit.arrive(bd.wren, bl.light.aim(0))
	Kit.run_for(b, 0.1)
	t.check(bd.touches == 0 and is_equal_approx(bd.gaze.value, LanternWatch.GAZE_TOLL), "nor when the Lantern burns")
	Kit.done(b)


## The Lantern-Bearer and his escorts are never Wren, and Wren is never one of them (D20 and the pre-flight's busy()); a clock at x2 brings the
## night's first event in half the time and leaves the reflexes alone (D20).
static func _mission_time(t) -> void:
	var s := _lantern_world()
	var d: VigilFlameDirector = s.d
	var lw: LanternWatch = s.lw
	_toll(s)
	var left := LanternBearer.AFTER + 2.0
	while lw.bearer == null and left > 0.0:
		Kit.run_for(s, 0.5)
		left -= 0.5
	t.check(lw.bearer != null, "(the Bearer set out)")
	if lw.bearer != null:
		d._wren_comes()
		t.check(d.wren != null and not lw.has_errand(d.wren), "Wren is nobody the Lantern sent: not the Bearer, not an escort")
		t.check(d.busy(d.wren) and not d.busy(lw.bearer.carrier), "busy(): Wren, nobody else")
	Kit.done(s)
	# Forced to x2.0 from the start (a world with no Lantern keeps a forced rate): Wren comes at half his time.
	var f := _setup()
	var fd: VigilFlameDirector = f.d
	(f.rules as Rules).clock_rate = 2.0
	_run(f, VigilFlameDirector.WREN_AT / 2.0 - 1.0)
	t.check(not fd.appeared, "at x2.0 Wren has not come a second before half his time")
	_run(f, 2.0)
	t.check(fd.appeared, "and has come a second after it (his 0:50 is mission time)")
	_run(f, 2.0)
	var label := _tag(fd, "WREN").label
	# He came 25 real seconds in; 3 real seconds later 6 mission seconds of his 30 are gone.
	t.check(label.ends_with(UiTheme.clock(VigilFlameDirector.WREN_OWN_AFTER - 6.0)) or label.ends_with(UiTheme.clock(VigilFlameDirector.WREN_OWN_AFTER - 5.0)),
		"his own-try tag counts down in mission seconds (%s)" % label)
	_done(f)
	# The swap is a reflex: SWAP_SECONDS of real time, whatever the clock's rate.
	var w := _setup()
	var wd: VigilFlameDirector = w.d
	(w.rules as Rules).clock_rate = 2.0
	wd.timeline.step(VigilFlameDirector.WREN_AT / 2.0)
	_bearer_out(w)
	_clear_watchers(wd)
	_bring_wren(wd)
	_run(w, VigilFlameDirector.SWAP_SECONDS - 0.5)
	t.check(wd.swapping and not wd.swapped, "at x2.0 the swap still takes its SWAP_SECONDS of real time (a reflex)")
	_run(w, 1.0)
	t.check(wd.swapped, "and is done after them")
	_done(w)
