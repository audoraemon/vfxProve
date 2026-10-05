extends RefCounted
## v0.09 Act II-B (ProcessionDirector): the Prince (a NOBLE resident) leaves the Citadel on foot for the dock, walking
## the route leg by leg and never running; six attendants walk round him and four soldiers of the Citadel's guard
## close in round him when he is frightened; after a fright he takes the route up again, not home; and a Prince killed
## in the act's first second raises no error. And the act's windows (the blessing, the ship, the tide), his boarding, and
## his death judged seen or unseen (PrinceObjective, QuietSuccessionObjective).

const DT := 0.1
const R := CitizenProfile.Role


## A town spawned Unaware, the Procession's Rules and its director, as Mission sets them up (no effects: ctx null).
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
	var def := MissionBook.long_night().act("procession")
	def.night = NightState.new()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var d := (def.director.new() as MissionDirector).setup(rules, crowd, town, null, def.night) as ProcessionDirector
	rules.director = d
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"def": def, "d": d}


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


## `seconds` of the act, in the game's order: the crowd, then the rules (which step the director).
static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


## The person has walked the whole way to its goal.
static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func run(t) -> void:
	_cast(t)
	_walk(t)
	_escort(t)
	_after_a_fright(t)
	_prince_dead_early(t)
	_blessing(t)
	_ship(t)
	_unseen_kill(t)
	_seen_kill(t)
	_dead_before_events(t)
	_tide(t)
	_prince_freed(t)
	_escaped_other_way(t)
	_doom_before_judging(t)
	_escort_balance(t)
	_let_go(t)


## The Prince, six attendants and four escorts; a route of walkable points.
static func _cast(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var grid: WalkGrid = s.grid
	t.check(MissionBook.long_night().act("procession").director == ProcessionDirector, "the Procession act's director is ProcessionDirector")
	t.check(d.prince != null and d.prince.profile.role == R.NOBLE, "the Prince is a NOBLE")
	t.check(d.route.size() == 5, "a route of five points (%d)" % d.route.size())
	var walkable := true
	for at in d.route:
		walkable = walkable and grid.walkable(at)
	t.check(walkable, "every route point is walkable (%s)" % [d.route])
	t.check(d.prince.ground_pos.distance_to(d.route[0]) <= 0.01 and d.prince.stay_left > 100.0,
		"he stands at the Citadel's exit and stays (%s)" % [d.prince.ground_pos])
	t.check(d.attendants.size() == ProcessionDirector.ATTENDANTS, "%d attendants (%d)" % [ProcessionDirector.ATTENDANTS, d.attendants.size()])
	var plain := true
	for a in d.attendants:
		plain = plain and a != d.prince and a.profile.role == R.RESIDENT and a.ground_pos.distance_to(d.prince.ground_pos) <= ProcessionDirector.ATTEND_R + 0.8
	t.check(plain, "each a resident, standing about him")
	t.check(d.escorts.size() == ProcessionDirector.ESCORTS, "%d escorts (%d)" % [ProcessionDirector.ESCORTS, d.escorts.size()])
	var guard := true
	for e in d.escorts:
		guard = guard and e.soldier and e.corps == Person.Corps.NONE and e.mind == Person.Mind.POST
	t.check(guard, "each a soldier with no corps, sent to his post")
	t.check(not d.frightened() and not d.boarded and not d.judged, "calm, unboarded, unjudged")
	_done(s)


## With each arrival forced, the goal moves along the route leg by leg, at a walk.
static func _walk(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var p := d.prince
	var slow := true
	var seen: Array[int] = []
	_run(s, DT)
	for want in range(1, d.route.size()):
		slow = slow and p.walk_speed <= Person.WALK_SPEED * p.pace + 0.01
		if p.goal().distance_to(d.route[want]) <= 0.01 and d.leg == want:
			seen.append(want)
		_arrive(p)
		_hurry(d, d._hold_until(want))  # the blessing and the ship's wait are the windows' tests
		_run(s, ProcessionDirector.TICK + DT)
	t.check(seen == [1, 2, 3, 4], "he walks leg by leg: goal on route[1..4] in turn (%s)" % [seen])
	t.check(slow, "and never runs")
	t.check(d.leg == d.route.size() - 1 and d.boarded, "at the boarding point he boards (leg %d)" % d.leg)
	_done(s)


## The act's clock moved on to `at` seconds with nothing else happening.
static func _hurry(d: ProcessionDirector, at: float) -> void:
	if d.timeline.elapsed() < at:
		d.timeline.step(at - d.timeline.elapsed())


## A fright: the escort closes in to within ESCORT_CLOSE of him.
static func _escort(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	_run(s, 1.0)
	var p := d.prince
	d._tick()
	var wide := true
	for e in d.escorts:
		wide = wide and e.anchor.distance_to(p.ground_pos) <= ProcessionDirector.ESCORT_R + 0.8
	t.check(wide, "calm, the escort keeps within ESCORT_R (+ the grid's snap) of him")
	p.panic(p.ground_pos + Vector2(1.0, 0.0))
	t.check(d.frightened(), "a fright is a fright (%s)" % Person.Mind.keys()[p.mind])
	d._tick()
	var close := true
	var worst := 0.0
	for e in d.escorts:
		worst = maxf(worst, e.anchor.distance_to(p.ground_pos))
		close = close and e.anchor.distance_to(p.ground_pos) <= ProcessionDirector.ESCORT_CLOSE + 0.4
	t.check(close, "after one tick each escort is within ESCORT_CLOSE + 0.4 of him (%.2f)" % worst)
	var hurried := true
	for e in d.escorts:
		hurried = hurried and e.hurrying
	t.check(hurried, "and runs to it")
	_done(s)


## Back on his feet he walks his route again, from the leg he was on, not home.
static func _after_a_fright(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var p := d.prince
	_run(s, DT)
	_arrive(p)
	_hurry(d, d._hold_until(1))
	_run(s, ProcessionDirector.TICK + DT)
	t.check(d.leg == 2, "on the second leg (%d)" % d.leg)
	p.panic(p.ground_pos + Vector2(1.0, 0.0))
	_run(s, 1.0)
	t.check(p.mind != Person.Mind.CALM, "frightened, he walks no route (%s)" % Person.Mind.keys()[p.mind])
	p._recover(3.0)
	_run(s, ProcessionDirector.TICK + DT)
	t.check(p.mind == Person.Mind.CALM and p.stay_left > 100.0, "come round, he is calm again and stays (%s)" % Person.Mind.keys()[p.mind])
	t.check(p.goal().distance_to(d.route[d.leg]) <= 0.01 and d.leg == 2,
		"walking route[%d] again, not home (%s)" % [d.leg, p.goal()])
	_done(s)


## Review focus 1: the Prince dead in the act's first second (at 0.1 s, and before the director's first look). Nothing
## raises; the director goes quiet and the escort is left standing.
static func _prince_dead_early(t) -> void:
	for first in [0.1, 0.0]:
		var s := _setup()
		var d: ProcessionDirector = s.d
		_run(s, first)
		var p := d.prince
		(s.field as EnemyField).kill(p, &"doom", p.ground_pos)
		t.check(not p.is_alive(), "the Prince is dead at %.1f s" % first)
		_run(s, 5.0)
		var alive := 0
		for e in d.escorts:
			alive += int(e.is_alive())
		t.check(not d.frightened() and d.leg <= 1 and alive == d.escorts.size(),
			"five seconds on, the director is quiet and raises nothing (leg %d, %d escorts alive)" % [d.leg, alive])
		_done(s)


## Advance to `at` seconds on the act's clock.
static func _to(s: Dictionary, at: float) -> void:
	_run(s, at - (s.d as ProcessionDirector).timeline.elapsed())


## Everyone within `reach` of `at` but `keep` moved out of earshot of it (as test_warning's _clear_round).
static func _clear_round(s: Dictionary, at: Vector2, reach: float, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + (p.ground_pos - at).normalized() * (reach + 6.0) if p.ground_pos != at \
					else at + Vector2(reach + 6.0, 0.0)


## The blessing: arriving at the steps at 30 s he stays until 80 s, then leaves; at 60 s the citizens near the steps look on.
static func _blessing(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var p := d.prince
	var steps := d.route[ProcessionDirector.STEPS_LEG]
	_to(s, 30.0)
	t.check(d.leg == 1 and p.goal().distance_to(steps) <= 0.01, "walking to the steps at 30 s (leg %d)" % d.leg)
	_arrive(p)
	# Twelve calm citizens come by the steps just before the blessing; ten may watch.
	var crowd: Crowd = s.crowd
	_to(s, 59.0)
	var near := 0
	for c in crowd.citizens:
		if near < 12 and c != p and not d.attendants.has(c) and is_instance_valid(c) and c.is_alive() and not c.inside:
			c.ground_pos = steps + Vector2.from_angle(float(near)) * 3.0
			c.mind = Person.Mind.CALM
			c._goal = Vector2.INF
			c._path = PackedVector2Array()
			near += 1
	_to(s, 60.5)
	var watching := 0
	for c in d.onlookers:
		watching += int(c.mind == Person.Mind.OBSERVE)
	t.check(d.onlookers.size() == ProcessionDirector.ONLOOKERS and watching == d.onlookers.size(),
		"at 60 s %d onlookers, each OBSERVE (%d of %d)" % [ProcessionDirector.ONLOOKERS, watching, d.onlookers.size()])
	var party := d.onlookers.has(p)
	for a in d.attendants:
		party = party or d.onlookers.has(a)
	t.check(not party, "the Prince's own party is not among them")
	t.check("blessing" in d.timeline.fired_ids(), "the event fired")
	_to(s, 79.0)
	t.check(d.leg == 1 and not p.has_goal() and p.ground_pos.distance_to(steps) <= 0.01, "he holds at the steps at 79 s (leg %d)" % d.leg)
	_to(s, 81.0)
	t.check(d.leg == 2 and p.goal().distance_to(d.route[2]) <= 0.01, "and leaves at 80 s (leg %d)" % d.leg)
	_done(s)


## The ship: at the waiting ground at 100 s he waits until 120 s, goes on to the boarding point, boards, and the act is lost.
static func _ship(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var p := d.prince
	_to(s, 30.0)
	_arrive(p)
	_to(s, 82.0)
	_arrive(p)
	_to(s, 83.0)
	t.check(d.leg == 3, "on the third leg after the blessing (%d)" % d.leg)
	_to(s, 100.0)
	_arrive(p)
	_to(s, 119.0)
	t.check(d.leg == 3 and not p.has_goal() and not d.boarded, "waiting at the dock until the ship (leg %d)" % d.leg)
	_to(s, 121.0)
	t.check(d.leg == 4 and p.goal().distance_to(d.route[4]) <= 0.01, "then on to the boarding point (leg %d)" % d.leg)
	var before := crowd.escaped_count
	_arrive(p)
	_to(s, 122.0)
	t.check(d.boarded and crowd.escaped_count == before + 1 and rules.escaped_this_act() == 1,
		"he boards and counts as an escape (%d)" % rules.escaped_this_act())
	t.check(rules.finished and not rules.won and rules.over_reason == "sailed", "the act is lost (%s)" % rules.over_reason)
	t.check(d.report().prince == "escaped", "and he escaped (%s)" % [d.report()])
	_done(s)


## The Prince killed with &"doom" at 20 s, everyone but `near` (who stand 1.0 from him) cleared away, two steps on.
static func _kill(s: Dictionary, near: Array) -> void:
	var d: ProcessionDirector = s.d
	var p := d.prince
	_to(s, 20.0)
	_clear_round(s, p.ground_pos, Crowd.DOOM_WITNESS + 1.0, [p])
	for c in near:
		(c as Person).ground_pos = p.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(p, &"doom", p.ground_pos)
	_run(s, DT * 2.0)


static func _unseen_kill(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	_kill(s, [])
	t.check(d.judged and d.unseen and d.fallen(), "nobody near: judged, unseen")
	t.check(rules.finished and rules.won and rules.over_reason == "prince", "the act is won (%s)" % rules.over_reason)
	var result := rules.result()
	var earned: bool = result.bonuses.size() == 1 and result.bonuses[0].label == "A quiet succession" and result.bonuses[0].earned
	t.check(earned, "A quiet succession is earned (%s)" % [result.bonuses])
	t.check(d.report().prince == "unseen", "and he fell unseen (%s)" % [d.report()])
	_done(s)


static func _seen_kill(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	var witness: Person = null
	for c in (s.crowd as Crowd).citizens:
		if c != d.prince and not d.attendants.has(c) and c.is_alive() and not c.inside:
			witness = c
			break
	_kill(s, [witness])
	t.check(d.judged and not d.unseen, "a citizen at 1.0: judged, seen")
	t.check(rules.finished and rules.won and rules.over_reason == "prince", "the act is won all the same (%s)" % rules.over_reason)
	var result := rules.result()
	t.check(not result.bonuses[0].earned, "A quiet succession is not earned (%s)" % [result.bonuses])
	t.check(d.report().prince == "seen", "and he fell seen (%s)" % [d.report()])
	_done(s)


## Review focus 1: he dies before the blessing. His events are dropped, off the strip, the onlookers are not called, and
## nothing raises, driven on through the ship and the tide (the act itself is won, so the director is stepped by hand).
static func _dead_before_events(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var seen_events: Array[String] = []
	d.timeline.fired.connect(func(id: String, _label: String) -> void: seen_events.append(id))
	_run(s, 1.0)
	(s.field as EnemyField).kill(d.prince, &"doom", d.prince.ground_pos)
	_run(s, 1.0)
	t.check((s.rules as Rules).finished and (s.rules as Rules).won, "dead in the first seconds: the act is won")
	t.check(d.timeline.upcoming(3).is_empty(), "and the strip lists none of his events")
	for i in 160:
		d.step(1.0)
	t.check(seen_events.is_empty() and d.onlookers.is_empty() and d.timeline.fired_ids().is_empty(),
		"the blessing, the ship and the tide do nothing (%s)" % [seen_events])
	_done(s)


## The clock: at 150 s with him alive and unboarded the act is lost with reason "tide".
static func _tide(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	_to(s, 100.0)
	t.check(not rules.finished and not d.boarded, "alive and unboarded at 100 s")
	_to(s, 149.0)
	t.check(not rules.finished, "the act runs until the tide")
	_to(s, 150.5)
	t.check(rules.finished and not rules.won and rules.over_reason == "tide", "at 150 s: lost to the tide (%s)" % rules.over_reason)
	t.check(d.report().prince == "escaped", "and he escaped (%s)" % [d.report()])
	_done(s)


## A Prince already freed (a boarded one at once, a fallen one when its fade ends) while the director and the HUD still look
## at it: nothing raises, and he is reported as he was.
static func _prince_freed(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	_run(s, 1.0)
	(s.field as EnemyField).kill(d.prince, &"doom", d.prince.ground_pos)
	_run(s, 0.3)
	t.check(rules.finished and rules.won and d.judged, "the Prince is dead and judged")
	(s.crowd as Crowd).citizens.erase(d.prince)
	(s.field as EnemyField).remove(d.prince)
	d.prince.free()
	t.check(d.timeline.upcoming(3).is_empty() and not d.frightened() and d.fallen(), "freed: the strip, the fright and the fall still answer")
	d.step(1.0)
	d._tick()
	t.check(d.report().prince in ["unseen", "seen"] and PrinceObjective.new().check(rules) == Objective.Status.DONE,
		"and the report and the objective still read it (%s)" % [d.report()])
	_done(s)


## He leaves the town some way other than the ship's gangway (a river boat, an exit he fled to): Crowd.escape without
## `boarded` set. That is his escape, not his death: the act is lost.
static func _escaped_other_way(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	var p := d.prince
	_run(s, 1.0)
	(s.field as EnemyField).remove(p)
	(s.crowd as Crowd).escape(p)
	t.check(not d.fallen(), "he is gone, not killed")
	_run(s, DT * 2.0)
	t.check(rules.finished and not rules.won and rules.over_reason == "sailed", "the act is lost (%s %s)" % [rules.won, rules.over_reason])
	t.check(d.report().prince == "escaped" and rules.escaped_this_act() == 1, "and he escaped (%s)" % [d.report()])
	_done(s)


## A Silent Doom kill with a witness at 1.0 that lands between the crowd's step and the rules' (so the doomed are not yet
## judged): the act is not won until his death is judged, and the bonus is not earned.
static func _doom_before_judging(t) -> void:
	var s := _setup()
	var d: ProcessionDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var witness: Person = null
	for c in crowd.citizens:
		if c != d.prince and not d.attendants.has(c) and c.is_alive() and not c.inside:
			witness = c
			break
	_to(s, 20.0)
	_clear_round(s, d.prince.ground_pos, Crowd.DOOM_WITNESS + 1.0, [d.prince, witness])
	witness.ground_pos = d.prince.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(d.prince, &"doom", d.prince.ground_pos)
	t.check(not crowd._doomed.is_empty(), "the doom is waiting to be judged")
	rules.advance(DT)
	t.check(not d.judged and not rules.finished, "rules step first: not judged, the act is not won yet")
	_run(s, DT * 2.0)
	var result := rules.result()
	t.check(d.judged and not d.unseen and rules.finished and rules.won and rules.over_reason == "prince",
		"judged seen, then won (%s %s)" % [d.unseen, rules.over_reason])
	t.check(not result.bonuses[0].earned and d.report().prince == "seen", "the bonus is not earned (%s)" % [result.bonuses])
	_done(s)


## The escort's balance (v0.09 Task 19), pinned: a calm escort stands past the witness distance, so an unseen kill turns on
## the attendants; a frightened one closes in to within reach of him.
static func _escort_balance(t) -> void:
	t.check(ProcessionDirector.ESCORT_R > Crowd.DOOM_WITNESS, "a calm escort stands past the witness distance (%.1f > %.1f)" %
		[ProcessionDirector.ESCORT_R, Crowd.DOOM_WITNESS])
	t.check(ProcessionDirector.ESCORT_CLOSE <= 1.0, "a frightened one closes within 1.0 (%.1f)" % ProcessionDirector.ESCORT_CLOSE)


## The director is let go once the act is over (v0.09 final review): its timeline's lambdas no longer hold it.
static func _let_go(t) -> void:
	var s := _setup()
	var w: WeakRef = weakref(s.d)
	s.erase("d")
	_run(s, 1.0)
	_done(s)
	t.check(w.get_ref() == null, "the Procession's director is freed after teardown")
