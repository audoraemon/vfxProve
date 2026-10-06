extends RefCounted
## v0.10 M4 The Vigil Flame (VigilFlameDirector). The flame-bearer walks the Vigil's route with two acolytes; at 0:50
## Wren comes to watch the lantern; whispered to it he swaps the real flame in 3 s, seen if a Faithful other than the
## bearer stands within Crowd.DOOM_WITNESS; left alone 30 s he tries it himself; at 1:30 the route shortens and the
## bearer home with the real flame loses; Wren carrying the flame to Mira's shrine wins. Task 5 adds Phase 2: the
## Searchlight, its touches, the Faithful's prayer in it, noise and the decoy, and the bonus.

const DT := 0.05
## Where the tests stage the swap and park watchers: beyond every beam's reach (Searchlight.FAR + POOL_R from the
## spire), so nothing the light does there is an accident.
const OUT := Vector2(-20.0, 18.0)
const AWAY := Vector2(22.0, 16.0)


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
	# The town's alarm hushed: deaths in a test never call the bellkeeper (the bell's own case sets it rung).
	crowd.hush(9999.0)
	var def := MissionBook.vigil_flame()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as VigilFlameDirector
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
	_loose_ends(t)


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
	var marks := d.marks()
	t.check(marks.size() == 2 and (marks[0][1] as Color) == VigilFlameDirector.MARK_SHRINE
		and (marks[1][0] as Vector2) == d.vigil.bearer.ground_pos and (marks[1][1] as Color) == VigilFlameDirector.MARK_FLAME,
		"the HUD marks Mira's shrine and the lantern")
	var next := d.timeline.upcoming(2)
	t.check(d.marker() == Vector2.INF and next.size() == 2 and next[0].id == "wren" and next[1].id == "route",
		"no arrow yet; the strip shows Wren coming and the route shortening")
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
	var seen := false
	for m: Array in d.marks():
		seen = seen or ((m[0] as Vector2) == w.ground_pos and (m[1] as Color) == VigilFlameDirector.MARK_WREN)
	t.check(seen and d.marker() == w.ground_pos, "the HUD marks him, and points at him")
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
	for m: Array in d.marks():
		lantern_marked = lantern_marked or (m[1] as Color) == VigilFlameDirector.MARK_FLAME
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
	t.check(crowd4.bell == null or ((s4.d as VigilFlameDirector).gaze.is_full() and (s4.rules as Rules).over_reason == "gaze"),
		"the bell fills the Gaze")
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
	for m: Array in d.marks():
		marked = marked or ((m[0] as Vector2) == fell and (m[1] as Color) == VigilFlameDirector.MARK_FLAME)
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
