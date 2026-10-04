extends RefCounted
## v0.09 Act II-B (ProcessionDirector): the Prince (a NOBLE resident) leaves the Citadel on foot for the dock, walking
## the route leg by leg and never running; six attendants walk round him and four soldiers of the Citadel's guard
## close in round him when he is frightened; after a fright he takes the route up again, not home; and a Prince killed
## in the act's first second raises no error.

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
		_run(s, ProcessionDirector.TICK + DT)
	t.check(seen == [1, 2, 3, 4], "he walks leg by leg: goal on route[1..4] in turn (%s)" % [seen])
	t.check(slow, "and never runs")
	t.check(d.leg == d.route.size() - 1 and not p.has_goal(), "at the boarding point he stops (leg %d)" % d.leg)
	_run(s, 2.0)
	t.check(not p.has_goal() and p.mind == Person.Mind.CALM, "and waits there, calm")
	_done(s)


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
