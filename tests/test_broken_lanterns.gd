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


## The first of the director's tags labelled `label`, or null.
static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label:
			return m
	return null


static func run(t) -> void:
	_cast(t)
	_drain(t)
	_relight(t)
	_ending(t)
	_prayers(t)
	_knights(t)
	_kneelers(t)
	_kneel_topup(t)
	_focus(t)
	_lines(t)
	_freed(t)


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
	var relight_ok := true
	for sh in d.shrines:
		var gap: float = sh.distance_to(d.relight_point(sh)) + VigilRoute.ARRIVE
		relight_ok = relight_ok and gap <= BrokenLanternsDirector.RELIGHT_REACH
		if gap > BrokenLanternsDirector.RELIGHT_REACH:
			print("  relight gap %.3f (limit %.2f) at %s" % [gap, BrokenLanternsDirector.RELIGHT_REACH, sh.center()])
	t.check(relight_ok, "arriving at the relight point (VigilRoute.ARRIVE short of it) is always within RELIGHT_REACH of the shrine")
	var faithful_ok := d.faithful.size() >= BrokenLanternsDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL
	t.check(faithful_ok, "the Faithful chosen (%d)" % d.faithful.size())
	t.check(d.vigil != null and d.vigil.active and d.vigil.loop and d.vigil.pass_flame and d.vigil.walkers().size() == 3
		and d.vigil.route.size() == d.shrines.size() and d.faithful.has(d.vigil.bearer),
		"the Vigil sets out round the six shrines, looping, the flame passing on")
	t.check(d.gaze != null and d.gaze.value == 0.0 and d.drain_left.is_empty() and d.drained_count() == 0,
		"the Gaze at 0, nothing broken")
	var lit := 0
	var first_six := true
	var tags := d.tags()
	for i in tags.size():
		var m := tags[i]
		lit += 1 if m.label == "LANTERN" and m.color == BrokenLanternsDirector.MARK_LIT and m.edge \
			and m.rise == BrokenLanternsDirector.SHRINE_H else 0
		if i < 6:
			first_six = first_six and m.rise == BrokenLanternsDirector.SHRINE_H
	t.check(lit == 6, "the HUD names the six standing shrines, each pointed at from the edge")
	t.check(first_six, "the shrines come first, so a crowded view keeps their labels (review focus 1)")
	var bearer := _tag(d, "FLAME-BEARER")
	t.check(bearer != null and bearer.at == d.vigil.bearer.ground_pos and not bearer.edge and d.hint_phase() == ""
		and d.timeline != null, "the flame-bearer is named, no arrow yet; the hint's own line; a timeline for the windows")
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
	var left := "DRAINING %d" % ceili(float(d.drain_left[sh]))
	var ember := _tag(d, left)
	t.check(left == "DRAINING 20" and ember != null and ember.at == sh.center()
		and ember.color == BrokenLanternsDirector.MARK_DRAINING and ember.edge, "the HUD shows it draining, 20 s left")
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 1.0)
	t.check(d.draining(sh) and d.drained_count() == 0, "still draining after 19 s")
	_run(s, 1.5)
	t.check(d.is_drained(sh) and d.drained_count() == 1 and not d.draining(sh), "drained after 20 s broken")
	var untagged := true
	for m in d.tags():
		untagged = untagged and m.at != sh.center()
	t.check(untagged, "a drained shrine has no tag")
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
	t.check(d.vigil.detour.distance_to(d.relight_point(sh)) < 0.01 and _tag(d, "FLAME-BEARER").edge,
		"the flame-bearer turns aside for the broken shrine, and the HUD points at him")
	_arrive(d.vigil.bearer, d.relight_point(sh))
	_run(s, DT * 2.0)
	t.check(not sh.destroyed and sh.hp == sh.max_hp and not d.draining(sh) and d.relit == 1
		and banners.has("THE FLAME RELIGHTS A LANTERN"), "reaching it before it drains, he relights it: it stands again")
	t.check(d.vigil.detour == Vector2.INF and not _tag(d, "FLAME-BEARER").edge and d.standing_shrines().has(sh),
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
	t.check(not d.vigil.active and _tag(d, "FLAME-BEARER") == null, "with all three dead the Vigil is over, and nobody is the flame-bearer")
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
	t.near(d5.gaze.value, GazeMeter.SEEN_DEATH * BrokenLanternsDirector.SEEN_DEATH_SCALE, 0.001,
		"a seen death adds SEEN_DEATH_SCALE of GazeMeter's 10 to the Gaze (%.2f)" % d5.gaze.value)
	_done(s5)


## Each shrine broken: PRAYERS Faithful to each standing shrine; at their places they pray, feeding the Gaze up to its
## cap; a held or frightened mind does not pray; one back on its feet goes back; a broken shrine keeps nobody praying.
static func _prayers(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	_away(d)
	t.check(d.praying.is_empty(), "nobody prays before a shrine breaks")
	_break(d.shrines[0])
	var per := {}
	var sent_ok := true
	for k: Variant in d.praying.keys():
		var e: Array = d.praying[k]
		per[e[0]] = int(per.get(e[0], 0)) + 1
		sent_ok = sent_ok and d.faithful.has(k) and not d.vigil.walkers().has(k) and (k as Person).mind == Person.Mind.DUTY
	sent_ok = sent_ok and not per.has(d.shrines[0])
	for i in range(1, 6):
		sent_ok = sent_ok and int(per.get(d.shrines[i], 0)) == BrokenLanternsDirector.PRAYERS
	t.check(sent_ok, "a shrine broken sends three Faithful to each standing shrine (%s)" % [per.values()])
	for k: Variant in d.praying.keys():
		_arrive(k as Person, d.praying[k][1])
	_run(s, DT)
	t.check(d.praying_count() == 5 * BrokenLanternsDirector.PRAYERS, "at their places they pray (%d)" % d.praying_count())
	var g0 := d.gaze.value
	_run(s, 1.0)
	t.near(d.gaze.value - g0, GazeMeter.PRAYER_CAP * BrokenLanternsDirector.PRAYER_SCALE, 0.05,
		"fifteen at prayer feed the Gaze at its cap")
	var ps: Array = d.praying.keys()
	for i in range(2, ps.size()):
		(ps[i] as Person).confuse(15.0)
	_run(s, DT)
	t.check(d.praying_count() == 2, "a mind the god holds does not pray (%d)" % d.praying_count())
	var p0 := ps[0] as Person
	p0.mind = Person.Mind.PANIC
	t.check(d.praying_count() == 1, "nor a frightened one")
	p0.mind = Person.Mind.RECOVER
	_run(s, BrokenLanternsDirector.TICK + DT)
	t.check(p0.mind == Person.Mind.DUTY and p0.anchor.distance_to(d.praying[p0][1]) < 0.01,
		"back on their feet, a prayer goes back to their place")
	_break(d.shrines[2])
	var on_broken := 0
	var per2 := {}
	for k: Variant in d.praying.keys():
		var sh: Structure = d.praying[k][0]
		on_broken += 1 if sh.destroyed else 0
		if _alive(k):
			per2[sh] = int(per2.get(sh, 0)) + 1
	t.check(on_broken == 0, "nobody is left praying at a broken shrine")
	var full := d.standing_shrines().size() == 4
	for sh in d.standing_shrines():
		full = full and int(per2.get(sh, 0)) == BrokenLanternsDirector.PRAYERS
	t.check(full, "the standing four are topped up to three each")
	_done(s)


## 1:30: the Knights come and guard; a guarded shrine takes no blow; its Knight killed first, it breaks; a Knight whose
## shrine fell guards another; with fewer standing shrines they double up, with none they guard nothing (review focus 3).
static func _knights(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var crowd: Crowd = s.crowd
	_away(d)
	var before := crowd.soldiers.size()
	d.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	t.check(d.knights.size() == BrokenLanternsDirector.KNIGHTS and crowd.soldiers.size() == before + BrokenLanternsDirector.KNIGHTS
		and (s.banners as Array).has("THE LANTERN KNIGHTS"), "1:30: four Lantern Knights come from the Temple")
	var kn_ok := true
	var guarded_shrines := {}
	for k in d.knights:
		var sh: Structure = d.guarding.get(k)
		kn_ok = kn_ok and k.soldier and k.corps == Person.Corps.KNIGHT and is_equal_approx(k.health, Person.HEALTH_KNIGHT) \
			and k.mind == Person.Mind.POST and sh != null and not sh.destroyed \
			and sh.distance_to(k.anchor) <= BrokenLanternsDirector.GUARD_REACH
		if sh != null:
			guarded_shrines[sh] = true
	t.check(kn_ok and guarded_shrines.size() == BrokenLanternsDirector.KNIGHTS,
		"each is sent to guard a different standing shrine (%d)" % guarded_shrines.size())
	var knight_tags := 0
	for m in d.tags():
		knight_tags += 1 if m.label == "KNIGHT" and m.color == BrokenLanternsDirector.MARK_KNIGHT and not m.edge else 0
	t.check(knight_tags == BrokenLanternsDirector.KNIGHTS and d.hint_phase() == "knights",
		"each Knight is named, and the hint says how to get past them")
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	t.check(hud.hint_text() == MissionHints.line(MissionBook.BROKEN_LANTERNS, "knights")
		and hud.hint_text() != MissionHints.line(MissionBook.BROKEN_LANTERNS), "the HUD shows the Knights' line, not the mission's own")
	hud.free()
	var k0 := d.knights[0]
	var sh0: Structure = d.guarding[k0]
	_arrive(k0, k0.anchor)
	_break(sh0)
	t.check(not sh0.destroyed and sh0.hp == sh0.max_hp and d.guarded(sh0) and d.guard_of(sh0) == k0,
		"a Knight beside it, the shrine shrugs off the blow")
	var guarded_tag := _tag(d, "GUARDED")
	t.check(guarded_tag != null and guarded_tag.at == sh0.center() and guarded_tag.color == BrokenLanternsDirector.MARK_KNIGHT,
		"the shrine he stands by shows GUARDED")
	crowd._field.kill(k0, &"lightning")
	_break(sh0)
	t.check(sh0.destroyed and d.draining(sh0), "its Knight struck down first, the shrine breaks")
	var still := 0
	for m in d.tags():
		still += 1 if m.label == "KNIGHT" else 0
	t.check(still == BrokenLanternsDirector.KNIGHTS - 1, "a Knight struck down is no longer tagged (review focus 2)")
	var k1 := d.knights[1]
	var sh1: Structure = d.guarding[k1]
	_break(sh1)
	_run(s, BrokenLanternsDirector.TICK + DT)
	var now: Structure = d.guarding.get(k1)
	t.check(sh1.destroyed and now != null and now != sh1 and not now.destroyed and now.distance_to(k1.anchor) <= BrokenLanternsDirector.GUARD_REACH,
		"a Knight not yet at his shrine when it falls goes to guard another")
	t.check(d.living_knights() == BrokenLanternsDirector.KNIGHTS - 1, "the HUD's count of Knights alive")
	_done(s)

	var s2 := _setup()
	var d2: BrokenLanternsDirector = s2.d
	_away(d2)
	for i in 4:
		_break(d2.shrines[i])
	d2.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	var per := {}
	for k in d2.knights:
		var sh: Structure = d2.guarding.get(k)
		if sh != null:
			per[sh] = int(per.get(sh, 0)) + 1
	t.check(per.size() == 2 and per.values().all(func(n: int) -> bool: return n == 2),
		"two shrines standing: the four Knights guard them two by two (%s)" % [per.values()])
	_done(s2)

	var s3 := _setup()
	var d3: BrokenLanternsDirector = s3.d
	_away(d3)
	for sh in d3.shrines:
		_break(sh)
	d3.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	_run(s3, BrokenLanternsDirector.TICK + DT)
	t.check(d3.knights.size() == BrokenLanternsDirector.KNIGHTS and d3.guarding.is_empty(),
		"with no shrine standing, the Knights come and guard nothing")
	_done(s3)


## Five drained: the kneelers ring the last shrine within BONUS_REACH. Broken with ten or more still there, the bonus;
## drawn away first, none.
static func _kneelers(t) -> void:
	for drawn_away in [false, true]:
		var s := _setup()
		var d: BrokenLanternsDirector = s.d
		var rules: Rules = s.rules
		_away(d)
		for i in 5:
			_break(d.shrines[i])
		_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
		var last := d.shrines[5]
		var placed := d.drained_count() == 5 and d.kneel_shrine == last and d.kneelers.size() == BrokenLanternsDirector.KNEELERS
		for p in d.kneelers:
			var spot: Vector2 = d.praying[p][1]
			placed = placed and spot.distance_to(last.center()) <= BrokenLanternsDirector.BONUS_REACH
		t.check(placed and (s.banners as Array).has("THE FAITHFUL KNEEL AT THE LAST LANTERN"),
			"five drained: fifteen Faithful kneel round the last shrine (%d)" % d.kneelers.size())
		for p in d.kneelers:
			var spot: Vector2 = d.praying[p][1]
			_arrive(p, spot if not drawn_away else last.center() + Vector2(5.0, 0.0))
		_run(s, DT)
		_break(last)
		_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
		var res := rules.result()
		var earned: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
		if not drawn_away:
			t.check(rules.won and d.last_kneelers >= ThroughFaithfulObjective.NEED and earned,
				"struck through ten or more kneelers: won, and Through the faithful (%d)" % d.last_kneelers)
		else:
			t.check(rules.won and d.last_kneelers == 0 and not earned, "drawn away first: won, without the bonus")
		_done(s)


## Task 8 fix: the kneelers are topped up every TICK. Few free at five drained, only those kneel; as the rest come back
## out they are called up to KNEELERS, and the dead are replaced. The Vigil's walkers and a Faithful the god holds are
## never taken, and every kneeler has a place of their own. (Breaks and deaths stir the crowd's minds even headless, so
## the test calms the rest by hand before each look, standing for their coming back to their feet.)
static func _kneel_topup(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var crowd: Crowd = s.crowd
	_away(d)
	var walking := d.vigil.walkers()
	var out: Array[Person] = []
	var held: Array[Person] = []
	for f in d.faithful:
		if walking.has(f):
			continue
		if out.size() < 4 and not f.inside and f.mind in BrokenLanternsDirector.RESUMABLE:
			out.append(f)
		else:
			f.inside = true
			held.append(f)
	for i in 5:
		_break(d.shrines[i])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
	var only_free := d.kneel_shrine == d.shrines[5] and not d.kneelers.is_empty() and d.kneelers.size() <= out.size()
	for p in d.kneelers:
		only_free = only_free and out.has(p)
	t.check(only_free, "five drained with four Faithful out: only the free kneel (%d)" % d.kneelers.size())
	for f in held:
		f.inside = false
	_calm(d, walking)
	var held_by_god := held[0]
	held_by_god.confuse(15.0)
	_run(s, BrokenLanternsDirector.TICK + DT)
	var room := {}  # place -> kneelers it still has room for (open ground may join two of the rings' places)
	for place in d._kneel_places(d.kneel_shrine):
		room[place] = int(room.get(place, 0)) + 1
	var own_place := true
	var busy_taken := false
	for p in d.kneelers:
		var at: Vector2 = d.praying[p][1]
		room[at] = int(room.get(at, 0)) - 1
		own_place = own_place and int(room[at]) >= 0
		busy_taken = busy_taken or walking.has(p) or p == held_by_god
	t.check(d.kneelers.size() == BrokenLanternsDirector.KNEELERS and own_place and not busy_taken,
		"back out, the rest are called up to fifteen, each to a place of their own, nobody busy taken (%d)"
		% d.kneelers.size())
	var lost: Array[Person] = []
	lost.assign(d.kneelers.slice(0, 3))
	for v in lost:
		crowd._field.kill(v, &"stone")
	_calm(d, walking)
	_run(s, BrokenLanternsDirector.TICK * 2.0 + DT)
	var refilled := d.kneelers.size() == BrokenLanternsDirector.KNEELERS
	for p in d.kneelers:
		refilled = refilled and _alive(p) and not lost.has(p) and d.praying.has(p) and p != held_by_god
	t.check(refilled, "kneelers killed are replaced by the free living (%d)" % d.kneelers.size())
	_done(s)


## The living Faithful not walking the Vigil, kneeling or held by the god, back on their feet (calm).
static func _calm(d: BrokenLanternsDirector, walking: Array[Person]) -> void:
	for f in d.faithful:
		if _alive(f) and not walking.has(f) and not d.kneelers.has(f) and f.mind != Person.Mind.CONFUSED:
			f.mind = Person.Mind.CALM


## Review focus 2 and 5: the last shrine already broken when the fifth drains; the Faithful run out.
static func _focus(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	_away(d)
	for i in 5:
		_break(d.shrines[i])
	_run(s, 10.0)
	_break(d.shrines[5])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 10.0 + 0.5)
	t.check(d.drained_count() == 5 and d.draining(d.shrines[5]) and d.kneel_shrine == null and d.kneelers.is_empty(),
		"the last shrine already broken when the fifth drains: nobody kneels")
	_arrive(d.vigil.bearer, d.relight_point(d.shrines[5]))
	_run(s, DT * 2.0)
	t.check(not d.shrines[5].destroyed and d.kneel_shrine == d.shrines[5] and d.kneelers.size() == BrokenLanternsDirector.KNEELERS,
		"relit, the kneelers come then")
	_done(s)

	var s2 := _setup()
	var d2: BrokenLanternsDirector = s2.d
	_away(d2)
	var walking := d2.vigil.walkers()
	for f in d2.faithful:
		if not walking.has(f):
			f.inside = true
	_break(d2.shrines[0])
	t.check(d2.praying.is_empty(), "with no Faithful free, a break sends nobody")
	for f in d2.faithful:
		f.inside = false
	_break(d2.shrines[1])
	var victims: Array[Person] = []
	for k: Variant in d2.praying.keys():
		if d2.praying[k][0] == d2.shrines[2]:
			victims.append(k as Person)
	for v in victims:
		(s2.crowd as Crowd)._field.kill(v, &"stone")
	_run(s2, BrokenLanternsDirector.TICK + DT)
	var ghosts := 0
	for k: Variant in d2.praying.keys():
		ghosts += 0 if _alive(k) else 1
	t.check(victims.size() == BrokenLanternsDirector.PRAYERS and ghosts == 0, "prayers killed at their shrine leave no ghosts")
	_done(s2)


## Cael's lines (v0.10 M5, spec §5.2): at the first shrine drained (review focus 3: once a night, never at a later one),
## and as the Knights come.
static func _lines(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var lines: Array = s.lines
	_away(d)
	_break(d.shrines[0])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 1.0)
	t.check(lines.is_empty(), "nothing while the first shrine drains (%s)" % [lines])
	_run(s, 1.5)
	t.check(lines == [CampaignText.cael_line(MissionBook.BROKEN_LANTERNS, "drained")],
		"the first shrine drained, Cael speaks (%s)" % [lines])
	_away(d)
	_break(d.shrines[1])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
	t.check(d.drained_count() == 2 and lines.size() == 1, "the second says nothing more (%d drained, %s)" % [d.drained_count(), lines])
	d.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	t.check(lines.size() == 2 and lines[1] == CampaignText.cael_line(MissionBook.BROKEN_LANTERNS, "knights"),
		"as the Knights come, he speaks again (%s)" % [lines])
	_done(s)


## A body is freed once its death fade ends, and the HUD asks for the tags every frame: a Knight or the flame-bearer freed
## is no longer tagged, the shrine he guarded is a LANTERN again, and nothing is raised for the freed body.
static func _freed(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	_away(d)
	d.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	var k0 := d.knights[0]
	var sh0: Structure = d.guarding[k0]
	_arrive(k0, k0.anchor)
	t.check(_tag(d, "GUARDED") != null and _tag(d, "GUARDED").at == sh0.center() and _tag(d, "FLAME-BEARER") != null,
		"a Knight at his shrine: GUARDED, and the flame-bearer named")
	k0.free()
	var knight_tags := 0
	var unguarded := false
	for m in d.tags():
		knight_tags += 1 if m.label == "KNIGHT" else 0
		unguarded = unguarded or (m.label == "LANTERN" and m.at == sh0.center())
	t.check(knight_tags == BrokenLanternsDirector.KNIGHTS - 1 and unguarded and _tag(d, "GUARDED") == null
		and d.living_knights() == BrokenLanternsDirector.KNIGHTS - 1 and d.hint_phase() == "knights",
		"a Knight's body freed: no tag, his shrine a LANTERN again, the others still tagged")
	d.vigil.bearer.free()
	t.check(_tag(d, "FLAME-BEARER") == null and _tag(d, "LANTERN") != null,
		"the flame-bearer's body freed: no tag, and the rest are still made")
	for k in d.knights:
		if _alive(k):
			k.free()
	t.check(d.living_knights() == 0 and _tag(d, "KNIGHT") == null and d.hint_phase() == "" and d.tags().size() == 6,
		"every Knight's body freed: no Knight tags, no hint phase, and the six shrines still tagged")
	_done(s)
