extends RefCounted
## v0.11 M1 the main objective held (spec §6): on the board the first DONE holds the night -- THE NIGHT IS YOURS, the clock
## running -- until the god ascends (won) or is caught (won, the catch named: the bell, the Gaze, dawn); a deadline and the
## main objective itself never catch it; off the board the night ends at once, as before. The Descent: what the night earns,
## the lost wishes' words, the seed, The Long Night's acts (review focus 5) and Tier 5's Gaze.

const DT := 0.05


## The test's own objectives: one done at once, and one that fails when told to (a deadline or not).
class Done extends Objective:
	func _init() -> void:
		label = "Done"
		reason = "done"

	func check(_rules: Rules) -> Status:
		return Status.DONE


class Fails extends Objective:
	var on := false

	func _init(is_deadline := false) -> void:
		reason = "fails"
		deadline = is_deadline

	func check(_rules: Rules) -> Status:
		return Status.FAILED if on else Status.PENDING


static func run(t) -> void:
	_held(t)
	_caught(t)
	_deadline(t)
	_acts(t)
	_tier_gaze(t)
	_seed(t)


## A world for `def` with its director (made by the def) and, unless `board` is false, a Descent attached.
static func _world(def: MissionDef, board := true) -> Dictionary:
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
	var made := def.make_director()
	var director: MissionDirector = made.setup(rules, crowd, town, null) if made != null else null
	rules.director = director
	var descent: Descent = null
	if board:
		descent = Descent.new().setup(def, 7)
		descent.attach(rules, director)
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"descent": descent, "banners": banners}


static func _done(s: Dictionary) -> void:
	if s.descent != null:
		(s.descent as Descent).release()
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


## The board's Warning, its three warnings stopped: its main objective done.
static func _stop_all(s: Dictionary) -> void:
	for w in (s.d as StarfallDirector).stars:
		w.warning_dead = true


## A mission of the test's own objectives, `extra` after Done.
static func _test_def(extra: Array) -> MissionDef:
	var m := MissionDef.new()
	m.id = "test"
	m.clock = 60.0
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [Done.new()]
		for o in extra:
			out.append(o)
		return out
	return m


static func _held(t) -> void:
	var s := _world(TierBook.board("warning"))
	var rules: Rules = s.rules
	var d: Descent = s.descent
	var won := [0]
	rules.main_won.connect(func() -> void: won[0] += 1)
	t.check(not rules.ascend() and not rules.main_done, "nothing to ascend from before the main objective (review focus 4)")
	t.check(d.earned(rules) == 0 and d.lost_text(rules) == Descent.LOST_ANY, "nothing earned yet")
	_stop_all(s)
	_run(s, DT)
	t.check(rules.main_done and not rules.finished and won[0] == 1 and (s.banners as Array).has(Rules.MAIN_BANNER)
		and is_equal_approx(rules.main_time, DT), "the warnings stopped: THE NIGHT IS YOURS, and the night held open")
	var clock := rules.time_left
	_run(s, 1.0)
	t.check(rules.time_left < clock and not rules.finished and won[0] == 1, "the clock keeps running")
	t.check(d.earned(rules) == 10 and d.main_reward() == 10, "the main objective's 10 believers, at Tier 1")
	t.check(rules.ascend() and rules.finished and rules.won and rules.ascended and rules.over_reason == "warning"
		and rules.caught == "", "ascending ends it, won")
	t.check(not rules.ascend(), "and cannot be done twice (review focus 4)")
	var rep: Dictionary = d.report(rules).descend
	t.check(bool(rep.main) and bool(rep.ascended) and int(rep.earned) == 10 and String(rep.lost_text) == ""
		and int(rep.tier) == 1 and is_equal_approx(float(rep.main_time), DT), "the night's report (%s)" % [rep])
	_done(s)


static func _caught(t) -> void:
	var s := _world(TierBook.board("warning"))
	var rules: Rules = s.rules
	_stop_all(s)
	_run(s, DT)
	(s.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s, DT)
	t.check(rules.finished and rules.won and not rules.ascended and rules.caught == "bell" and rules.over_reason == "warning",
		"the bell after the main objective: caught, the main win standing")
	t.check((s.descent as Descent).earned(rules) == 10 and (s.descent as Descent).lost_text(rules) == "lost: the bell tolled",
		"its believers banked, the wishes lost to the bell")
	_done(s)

	var s2 := _world(TierBook.board("warning"))
	_stop_all(s2)
	_run(s2, DT)
	(s2.rules as Rules).time_left = 0.01
	_run(s2, DT)
	t.check((s2.rules as Rules).finished and (s2.rules as Rules).won and (s2.rules as Rules).caught == "dawn"
		and (s2.descent as Descent).lost_text(s2.rules) == Descent.LOST_DAWN, "dawn after the main objective: caught by dawn")
	_done(s2)

	var s3 := _world(TierBook.board("warning"))
	(s3.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s3, DT)
	t.check((s3.rules as Rules).finished and not (s3.rules as Rules).won and not (s3.rules as Rules).main_done
		and (s3.descent as Descent).earned(s3.rules) == 0, "a loss before the main objective earns nothing")
	_done(s3)


static func _deadline(t) -> void:
	var s := _world(_test_def([Fails.new(true), Fails.new(false)]))
	var rules: Rules = s.rules
	_run(s, DT)
	t.check(rules.main_done and not rules.finished, "the test's main objective holds the night")
	(rules.objectives[1] as Fails).on = true
	_run(s, DT)
	t.check(not rules.finished, "a deadline failing after the main objective does not catch it")
	(rules.objectives[2] as Fails).on = true
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.caught == "fails", "any other failing does")
	_done(s)

	var off := _world(_test_def([]), false)
	_run(off, DT)
	t.check((off.rules as Rules).finished and (off.rules as Rules).won and not (off.rules as Rules).main_done,
		"off the board the first DONE ends the mission at once, as before")
	_done(off)


static func _acts(t) -> void:
	var ln := TierBook.board("long_night")
	var d := Descent.new().setup(ln, 1)
	t.check(not d.holds(ln.act("omen")) and not d.holds(ln.act("festival")) and d.holds(ln.act("judgement"))
		and d.holds(TierBook.board("warning")), "a night holds only in its last act (review focus 5)")
	t.check(d.tier == 5 and d.main_reward() == 30 and Descent.new().setup(TierBook.board("miras_house"), 1).main_reward() == 15,
		"the main objective pays 10 at the tier's multiplier")


static func _tier_gaze(t) -> void:
	var s := _world(TierBook.board("last_judgement"))
	var rules: Rules = s.rules
	var d: Descent = s.descent
	t.check(rules.director.gaze != null and rules.director.gaze == d.gaze and d.gaze is Descent.TierGaze,
		"a Tier 5 director that keeps no Gaze gets the night's")
	var crowd: Crowd = s.crowd
	var victim: Person = null
	var witness: Person = null
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside:
			if victim == null:
				victim = p
			elif witness == null:
				witness = p
	witness.ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(victim, &"doom")
	_run(s, DT)
	t.near(d.gaze.value, GazeMeter.SEEN_DEATH * TierBook.GAZE_SHARE, 0.001, "a seen death adds 0.5 at Tier 5")
	var other := MissionDirector.new()
	d.attach(rules, other)
	t.check(other.gaze == d.gaze, "the next act's director shares the night's Gaze (review focus 5)")
	d.gaze.fill()
	_run(s, DT)
	t.check(rules.finished and not rules.won and rules.over_reason == "gaze" and d.lost_text(rules) == "lost: Halcyon saw you",
		"a full Gaze loses the night")
	_done(s)
	var low := _world(TierBook.board("procession"))
	t.check((low.d as MissionDirector).gaze == null and (low.descent as Descent).gaze == null, "below Tier 5 no Gaze is added")
	_done(low)


static func _seed(t) -> void:
	t.check(Descent.seed_for(3, "warning") == Descent.seed_for(3, "warning") and Descent.seed_for(3, "warning") != Descent.seed_for(4, "warning")
		and Descent.seed_for(3, "warning") != Descent.seed_for(3, "festival"),
		"the same night of the same mission draws alike; a counted night redraws (review focus 3)")
	var d := Descent.new().setup(TierBook.board("long_night"), 1)
	var def := _test_def([])
	var s := _world(def, false)
	(s.rules as Rules)._elapsed = 70.0
	d.next_act(s.rules)
	(s.rules as Rules).main_done = true
	(s.rules as Rules).main_time = 30.0
	t.check(is_equal_approx(float(d.report(s.rules).descend.main_time), 100.0), "a night's time counts its earlier acts")
	_done(s)
