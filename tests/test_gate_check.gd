extends RefCounted
## Soldier duties, slice e: the gate check. The wall guards at a gate (up to 2, corps NONE or MARSHAL) look over everyone who walks
## through it: a person who is guised or held by the god's hand and stands within the checker's sight is spotted (the guise or the
## hold ends, an incident, an alarm of 2.0, a banner and a "!" over the checker). A corps-NONE checker steps to a spot beside the
## mouth when anyone comes near and back after 5 s of nobody; the check never touches a gate's own clock.

const Corps := preload("res://tests/test_corps.gd")
const C := preload("res://tests/test_cordon.gd")
const GATE := GuardJobs.Kind.GATE
const STEP := 1.0 / 60.0


static func run(t) -> void:
	_checkers(t)
	_marshal_checks(t)
	_step_on_approach(t)
	_spot_guised(t)
	_spot_held(t)
	_unchecked_passes(t)
	_no_sight(t)
	_veiled(t)
	_never_slows(t)
	_fire_takes_checker(t)
	_once_per_ten(t)
	_mission_man_never(t)
	_capital_gates(t)
	_held_checker(t)
	_hushed(t)
	_freed_man(t)
	_clear_resets(t)
	_board_closed(t)
	_released_hook(t)
	_soldier_not_checked(t)
	_unmask_minds(t)
	_one_gate_one_charge(t)
	_director_release(t)
	_watch_same(t)
	_charge_not_spotted(t)
	_closed_board_checks_nothing(t)


static func _world() -> Array:
	City.use(&"aldermere")
	return Corps._crowd(ResponseProfile.Tier.PREPARED)


## The gate's mouth (where Crowd queues its crowd) and the way out.
static func _mouth(gate: Structure) -> Vector2:
	var o := Crowd.outward_of(gate)
	return gate.center() - o * (absf(gate.footprint.size.dot(o)) * 0.5 + Crowd.GATE_DOOR)


## The board's once-a-second tick, now.
static func _tick(crowd: Crowd) -> void:
	crowd.guard_jobs._tick_left = 0.0
	crowd.guard_jobs.step(0.0)


## The first standing gate that has a checker of `corps`; null for none.
static func _gate_of(crowd: Crowd, corps: Person.Corps) -> Structure:
	for g in crowd._town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			for p in crowd.gate_check.checkers(g):
				if p.corps == corps:
					return g
	return null


## The first standing gate whose checkers are all corps NONE (and there is one).
static func _none_gate(crowd: Crowd) -> Structure:
	for g in crowd._town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			var list := crowd.gate_check.checkers(g)
			var all_none := not list.is_empty()
			for p in list:
				all_none = all_none and p.corps == Person.Corps.NONE
			if all_none:
				return g
	return null


## `p` stands calm out of doors at `at`, no goal.
static func _calm_at(p: Person, at: Vector2) -> void:
	p.inside = false
	p.mind = Person.Mind.CALM
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


## Every citizen near the gate goes far off, so the gate is quiet.
static func _quiet(crowd: Crowd, gate: Structure) -> void:
	var mouth := _mouth(gate)
	var out := Crowd.outward_of(gate)
	for p in crowd.citizens:
		if p.ground_pos.distance_to(mouth) <= 9.0:
			_calm_at(p, mouth - out * 30.0)


## The checker `c` set down on the spot he was sent to.
static func _arrive(c: Person) -> void:
	c.ground_pos = c.anchor
	c._goal = Vector2.INF
	c._path = PackedVector2Array()
	c._target = c.anchor


## Where the gate's k-th checker stands.
static func _spot_of(crowd: Crowd, gate: Structure, k: int) -> Vector2:
	return crowd.marshals.spot(_mouth(gate), Crowd.outward_of(gate), crowd.profile.marshals_per_exit + k)


## A quiet gate with a calm walker near its mouth; the board ticked until its first NONE checker is out on his spot (set down
## there). Returns that checker (null when no NONE checker came).
static func _ready_gate(crowd: Crowd, gate: Structure) -> Person:
	_quiet(crowd, gate)
	var out := Crowd.outward_of(gate)
	_calm_at(crowd.citizens[0], _mouth(gate) - out * 1.0)
	for i in 3:
		_tick(crowd)
	for p in crowd.gate_check.checkers(gate):
		if p.corps == Person.Corps.NONE and crowd.guard_jobs.kind_of(p) == GATE:
			_arrive(p)
			return p
	return null


## `p` guised for 60 s, standing `d` in from the gate's mouth.
static func _guised_at(crowd: Crowd, gate: Structure, i: int, d := 0.8) -> Person:
	var p: Person = crowd.citizens[i]
	_calm_at(p, _mouth(gate) - Crowd.outward_of(gate) * d)
	p.statuses[&"guise"] = 60.0
	return p


static func _texts(crowd: Crowd) -> Array[String]:
	var out: Array[String] = []
	crowd.duty_event.connect(func(_k: int, text: String, _at: Vector2) -> void: out.append(text))
	return out


static func _has_tag(crowd: Crowd, gate: Structure) -> bool:
	for tag in crowd.guard_jobs.tags():
		if tag.label == GateCheck.TAG and tag.at.is_equal_approx(gate.center()):
			return true
	return false


## Every standing gate has 1 to 2 checkers: wall group, town post within 2.5, corps NONE or MARSHAL, nearest first.
static func _checkers(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var all_ok := true
	var any := false
	for g in crowd._town.gates:
		var list := crowd.gate_check.checkers(g)
		any = any or not list.is_empty()
		all_ok = all_ok and list.size() >= 1 and list.size() <= GateCheck.PER_GATE
		var last := -1.0
		for p in list:
			var d := p.town_post.distance_to(g.center())
			all_ok = all_ok and p.post_group == 1 and d <= GateCheck.POST_REACH and d >= last \
					and (p.corps == Person.Corps.NONE or p.corps == Person.Corps.MARSHAL)
			last = d
	t.check(any and all_ok, "Aldermere: every gate has 1..2 checkers, wall group, post within 2.5, nearest first")
	C._done(made)


## A gate whose in-gate guards are marshals is checked: no board job for a marshal, he sees from 4.0 and has the eye badge.
static func _marshal_checks(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _gate_of(crowd, Person.Corps.MARSHAL)
	t.check(gate != null, "(a gate with a marshal checker)")
	if gate == null:
		C._done(made)
		return
	var marshal: Person = null
	for p in crowd.gate_check.checkers(gate):
		if p.corps == Person.Corps.MARSHAL:
			marshal = p
			break
	C._only_free(crowd, [marshal])
	_quiet(crowd, gate)
	var mouth := _mouth(gate)
	C._place(marshal, mouth + Vector2(0.4, 0.0))
	marshal.mind = Person.Mind.POST
	var g := _guised_at(crowd, gate, 1)
	t.check(crowd.gate_check.checked(gate), "a marshal within 2.5 of the mouth, free: the gate is checked")
	t.check(not crowd.guard_jobs.on_job(marshal), "a marshal holds no board record")
	crowd.alarms.bell_rung = true
	_tick(crowd)
	t.check(not g.guised(), "the guised citizen is seen through by the marshal")
	t.check(marshal.watch_far, "a marshal at his gate sees to WATCH_SIGHT")
	t.check(crowd.guard_jobs.live(GATE).is_empty(), "and no GATE job was posted for him")
	C._done(made)


## A calm walker within 2.5 of the mouth: the NONE checker walks to his spot (one send_to_post); 5 s after nobody, back to his post.
static func _step_on_approach(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _gate_of(crowd, Person.Corps.NONE)
	t.check(gate != null, "(a gate with a NONE checker)")
	if gate == null:
		C._done(made)
		return
	_quiet(crowd, gate)
	_tick(crowd)
	var c: Person = null
	var k := 0
	for i in crowd.gate_check.checkers(gate).size():
		var p: Person = crowd.gate_check.checkers(gate)[i]
		if p.corps == Person.Corps.NONE and c == null:
			c = p
			k = i
	t.check(crowd.guard_jobs.kind_of(c) == GATE, "a NONE checker holds a GATE record")
	t.check(c.anchor.is_equal_approx(c.post) and c.post.is_equal_approx(c.town_post) and not crowd.guard_jobs.mission_man(c),
			"quiet gate: he stays at his post and is not a mission man")
	var post := c.post
	var w: Person = crowd.citizens[0]
	_calm_at(w, _mouth(gate) - Crowd.outward_of(gate) * 1.0)
	_tick(crowd)
	t.check(c.anchor.is_equal_approx(_spot_of(crowd, gate, k)), "a walker at the mouth: the checker is sent to his spot")
	t.check(c.post.is_equal_approx(post) and c.town_post.is_equal_approx(post) and not crowd.guard_jobs.mission_man(c),
			"his post and town post never change, and he does not look like a mission man")
	_arrive(c)
	C._run_for(crowd, 1.2, [w])
	t.check(c.watch_far and c.badge_left > 0.0 and c.badge_glyph == GuardJobs.GLYPH_EYE, "on his spot: sees to 4.0, the eye badge")
	t.check(crowd.gate_check.checked(gate), "the gate is checked")
	t.check(c.talk_left > 0.0 and c.stand_face != Vector2.INF, "he faces the walker, talking")
	_calm_at(w, _mouth(gate) - Crowd.outward_of(gate) * 30.0)
	C._run_for(crowd, 3.0)
	t.check(c.anchor.is_equal_approx(_spot_of(crowd, gate, k)), "3 s without anyone: still on his spot")
	C._run_for(crowd, 3.6)
	t.check(c.anchor.is_equal_approx(post), "5 s without anyone: back to his post")
	t.check(not c.watch_far and c.stand_face == Vector2.INF and c.talk_left <= 0.0, "and the flags are off")
	t.check(crowd.guard_jobs.kind_of(c) == GATE, "he keeps his record while he waits")
	C._done(made)


## A guised citizen at a checked gate: the guise goes, incident +1, alarm +2.0 (x UNWARNED before the bell), the banner, the "!".
static func _spot_guised(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	t.check(gate != null, "(a gate checked by NONE men only)")
	if gate == null:
		C._done(made)
		return
	var c := _ready_gate(crowd, gate)
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var texts := _texts(crowd)
	var district := AlarmManager.district_of(gate.center())
	var g := _guised_at(crowd, gate, 1)
	crowd.alarms.bell_rung = true
	var events := int(crowd.alarms._events.get(district, 0))
	var alarm := crowd.alarm
	_tick(crowd)
	t.check(not g.guised(), "the guise is gone")
	t.check(int(crowd.alarms._events.get(district, 0)) == events + 1, "one incident at the gate")
	t.near(crowd.alarm - alarm, GateCheck.GATE_SPOT_ALARM, 0.001, "the alarm rises by 2.0 (bell rung)")
	t.check(texts.has(GateCheck.BANNER), "the banner: THE GATE GUARD SEES THROUGH IT")
	t.check(c.badge_left > 0.0 and c.badge_glyph == GuardJobs.GLYPH_ALERT, "the checker wears the \"!\" badge")
	crowd.alarms.bell_rung = false
	var g2 := _guised_at(crowd, gate, 2)
	alarm = crowd.alarm
	_tick(crowd)
	t.check(not g2.guised(), "a second guised citizen is seen too")
	t.near(crowd.alarm - alarm, 0.0, 0.001, "one charge per gate per 10 s: the second spot adds no alarm")
	_run_for_ten(crowd)
	crowd.alarms.bell_rung = false
	var g3 := _guised_at(crowd, gate, 3)
	alarm = crowd.alarm
	_tick(crowd)
	t.check(not g3.guised(), "a third is seen after 10 s")
	t.near(crowd.alarm - alarm, GateCheck.GATE_SPOT_ALARM * Crowd.UNWARNED_ALARM, 0.001, "before the bell the alarm counts half")
	C._done(made)


## Ten seconds on (the checker's spot and the walker stay put).
static func _run_for_ten(crowd: Crowd) -> void:
	C._run_for(crowd, GateCheck.REPEAT_SECONDS + 0.5)


## A whispered citizen at a checked gate is no longer held by the god (and is left in a sane mind).
static func _spot_held(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var p: Person = crowd.citizens[1]
	_calm_at(p, _mouth(gate) - Crowd.outward_of(gate) * 0.8)
	t.check(p.whisper(p.ground_pos, 30.0) and p.held_by_god(), "(whispered)")
	_tick(crowd)
	t.check(not p.held_by_god() and p.mind != Person.Mind.WHISPERED, "released from the whisper at the checked gate")
	var q: Person = crowd.citizens[2]
	_calm_at(q, _mouth(gate) - Crowd.outward_of(gate) * 0.9)
	q.confuse(30.0)
	_tick(crowd)
	t.check(not q.held_by_god(), "a confused one comes to")
	var r: Person = crowd.citizens[3]
	_calm_at(r, _mouth(gate) - Crowd.outward_of(gate) * 1.0)
	t.check(r.compel(r.ground_pos, 30.0, 1.0, Color.WHITE) and r.held_by_god(), "(compelled)")
	_tick(crowd)
	t.check(not r.held_by_god(), "a compelled one is let go")
	var s: Person = crowd.citizens[4]
	_calm_at(s, _mouth(gate) - Crowd.outward_of(gate) * 1.1)
	t.check(s.lure(s.ground_pos + Vector2(0.3, 0.0), 30.0) and s.held_by_god(), "(lured)")
	_tick(crowd)
	for i in 5:
		s.tick(STEP)
	t.check(not s.held_by_god() and s.mind != Person.Mind.OBSERVE, "a lured one stops staring")
	C._done(made)


## Checkers killed: the same guised citizen passes, and no tag shows.
static func _unchecked_passes(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	_tick(crowd)
	t.check(_has_tag(crowd, gate), "a checked gate shows the tag GATE CHECK")
	for p in crowd.gate_check.checkers(gate):
		(made[3] as EnemyField).kill(p, &"mob")
	var g := _guised_at(crowd, gate, 1)
	_tick(crowd)
	t.check(g.guised(), "no checker left: the guise passes")
	t.check(not crowd.gate_check.checked(gate) and not _has_tag(crowd, gate), "and the gate shows no tag")
	C._done(made)


## NO SIGHT on the checker: a person 2.5 away is not seen (and without it he is).
static func _no_sight(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var g1 := crowd.citizens[1]
	_calm_at(g1, c.ground_pos + Vector2(2.5, 0.0))
	g1.statuses[&"guise"] = 60.0
	t.check(crowd.gate_check.check(g1, gate) and not g1.guised(), "2.5 away, clear sight: seen")
	crowd.add_law(LawZone.circle(c.ground_pos, 8.0, [LawZone.NO_SIGHT], 60.0))
	var g2 := crowd.citizens[2]
	_calm_at(g2, c.ground_pos + Vector2(0.0, 2.5))
	g2.statuses[&"guise"] = 60.0
	t.check(not crowd.gate_check.check(g2, gate) and g2.guised(), "NO SIGHT: 2.5 away is not seen")
	C._done(made)


## A veil over the person: nothing is spotted.
static func _veiled(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var g := _guised_at(crowd, gate, 1)
	crowd.veil(g.ground_pos, 2.0, 60.0)
	var texts := _texts(crowd)
	_tick(crowd)
	t.check(g.guised() and not crowd.gate_check.check(g, gate) and texts.is_empty(), "a veiled person is not spotted, no banner")
	C._done(made)


## A fleeing queue at a gate with the check on and off: the same release clocks and queue, whatever the check does.
static func _queue_trace(checks_on: bool, confused := false) -> Dictionary:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate: Structure = (made[5] as Town).gates[0]
	if not checks_on:
		C._only_free(crowd, [])
	var spots := crowd.queue_spots(gate)
	var group: Array[Person] = []
	for k in 8:
		var p: Person = crowd.citizens[k]
		p.inside = false
		p.mind = Person.Mind.FLEE
		p.ground_pos = spots[k]
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		if k % 2 == 0:
			p.statuses[&"guise"] = 90.0
		group.append(p)
	if confused:
		var q: Person = crowd.citizens[8]
		q.inside = false
		q.confuse(120.0)
		q.ground_pos = spots[8]
		q.queue_spot = spots[8]
		group.append(q)
	var trace := []
	var last := -2.0
	for i in roundi(60.0 / STEP):
		C._step(crowd)
		var next := float(crowd._gate_next.get(gate, -1.0))
		if next != last:
			last = next
			trace.append([roundi(next * 1000.0), group.filter(func(p: Person) -> bool: return p.passing_gate == gate).size()])
	var queue := []
	for p in group:
		queue.append([roundi(p.queue_since * 1000.0), p.queue_spot])
	var left := 0
	for p in group:
		left += 1 if p.guised() else 0
	var out := {"trace": trace, "queue": queue, "alarm": crowd.alarm, "guised": left}
	C._done(made)
	return out


static func _never_slows(t) -> void:
	var c_on := _queue_trace(true, true)
	var c_off := _queue_trace(false, true)
	t.check(c_on.trace == c_off.trace and c_on.queue == c_off.queue,
			"a queued confused non-fleer: the same release clocks, turns and escapes with and without the check")
	var on := _queue_trace(true)
	var off := _queue_trace(false)
	t.check(not (on.trace as Array).is_empty() and on.trace == off.trace, "the gate's release clocks are the same with and without the check (%d releases)" % (on.trace as Array).size())
	t.check(on.queue == off.queue, "and so is the queue")
	t.check(int(on.guised) < int(off.guised) and float(on.alarm) > float(off.alarm), "while the check did spot guised ones (%d of 4 left; alarm %.1f vs %.1f)" % [int(on.guised), float(on.alarm), float(off.alarm)])


## A fire's pick takes a NONE checker (his GATE job ends, flags cleared); a marshal is never free.
static func _fire_takes_checker(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var gj := crowd.guard_jobs
	var mate: Person = null
	for p in crowd.gate_check.checkers(gate):
		if p != c:
			mate = p
	var men: Array = [c]
	if mate != null:
		men.append(mate)
	C._only_free(crowd, men)
	t.check(gj.is_free(c), "a checker on his spot is a free man (the lowest job)")
	var picked := gj.pick(c.ground_pos, 20.0, 0, 3)
	t.check(picked.has(c) or (mate != null and picked.has(mate)), "a fire's pick takes a checker")
	var job: GuardJobs.Job = gj.job_of(c)
	var house: Structure = null
	for s in (made[1] as EnvironmentField).structures():
		if s.role == &"house":
			house = s
			break
	gj.take(c, house)
	t.check(gj.kind_of(c) == GuardJobs.Kind.FIRE and not job.crew.has(c), "he is on the fire's record and off the GATE job")
	t.check(not c.watch_far and c.badge_left <= 0.0 and c.stand_face == Vector2.INF, "his flags are cleared")
	_tick(crowd)
	t.check(not gj.live(GATE).has(job), "the emptied GATE job is gone")
	gj.release(c)
	var marshal: Person = null
	for p in crowd.soldiers:
		if p.corps == Person.Corps.MARSHAL:
			marshal = p
			break
	t.check(marshal != null and not gj.is_free(marshal), "a marshal is never free for a job")
	C._done(made)


## A person standing at the mouth is spotted once in 10 s.
static func _once_per_ten(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var texts := _texts(crowd)
	var g := _guised_at(crowd, gate, 1)
	_tick(crowd)
	t.check(not g.guised() and texts.size() == 1, "(spotted)")
	g.statuses[&"guise"] = 60.0
	_tick(crowd)
	t.check(g.guised() and texts.size() == 1, "guised again at once: not checked again within 10 s")
	C._run_for(crowd, 9.0)
	t.check(g.guised() and texts.count(GateCheck.BANNER) == 1, "still not checked 9 s on")
	C._run_for(crowd, 1.5)
	t.check(not g.guised() and texts.count(GateCheck.BANNER) == 2, "after 10 s he is checked again (%s)" % str(texts))
	C._done(made)


## A director's man (no town post, or stationed away) is never a checker and never takes a record.
static func _mission_man_never(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var list := crowd.gate_check.checkers(gate)
	var m := crowd.add_soldier(gate.center() + Vector2(0.3, 0.3))
	var stationed: Person = list[0]
	stationed.send_to_post(stationed.post + Vector2(4.0, 0.0))
	t.check(crowd.guard_jobs.mission_man(m) and crowd.guard_jobs.mission_man(stationed), "(both are mission men)")
	var now := crowd.gate_check.checkers(gate)
	t.check(not now.has(m) and not now.has(stationed), "neither is a checker")
	_tick(crowd)
	t.check(not crowd.guard_jobs.on_job(m) and not crowd.guard_jobs.on_job(stationed), "and neither holds a GATE record")
	C._done(made)


## Every Capital gate has a marshal checker.
static func _capital_gates(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var cap := Crowd.new().setup(field, env, town, grid, world, 5)
	cap.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	cap.spawn()
	var b := {"world": world, "town": town}
	var all_marshal := true
	var n := 0
	for g in (b.town as Town).gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			n += 1
			var has := false
			for p in cap.gate_check.checkers(g):
				has = has or p.corps == Person.Corps.MARSHAL
			all_marshal = all_marshal and has
	t.check(n >= 8 and all_marshal, "the Capital: each of its %d gates has a marshal checker" % n)
	cap.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## A checker the god holds does not check, and his gate is not checked.
static func _held_checker(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	for p in crowd.gate_check.checkers(gate):
		t.check(p.whisper(p.ground_pos, 30.0), "(a checker whispered)")
	t.check(not crowd.gate_check.checked(gate), "a held checker: the gate is not checked")
	var g := _guised_at(crowd, gate, 1)
	_tick(crowd)
	t.check(g.guised(), "and the guise passes")
	t.check(not c.watch_far, "a held checker sees no farther than anyone")
	C._done(made)


## A hushed town: the spot still ends the guise and shows the banner, but raises no alarm and no incident.
static func _hushed(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var district := AlarmManager.district_of(gate.center())
	crowd.hush(30.0)
	var texts := _texts(crowd)
	var alarm := crowd.alarm
	var events := int(crowd.alarms._events.get(district, 0))
	var g := _guised_at(crowd, gate, 1)
	_tick(crowd)
	t.check(not g.guised() and texts.has(GateCheck.BANNER) and c.badge_glyph == GuardJobs.GLYPH_ALERT, "hushed: he is still seen, the banner and badge show")
	t.near(crowd.alarm, alarm, 0.0001, "but no alarm is raised")
	t.check(int(crowd.alarms._events.get(district, 0)) == events, "and no incident is written")
	C._done(made)


## A checker freed between ticks does not break the duty.
static func _freed_man(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	crowd.soldiers.erase(c)
	c.free()
	_tick(crowd)
	C._run_for(crowd, 2.5)
	var dead_records := 0
	for job in crowd.guard_jobs.live(GuardJobs.Kind.GATE):
		for m in job.crew:
			if not is_instance_valid(m):
				dead_records += 1
	t.check(dead_records == 0, "a freed checker: the board went on and holds no dead crew record of him")
	t.check(not crowd.gate_check.checked(gate) or not crowd.gate_check.checkers(gate).has(c), "and he is no checker")
	C._done(made)


## guard_jobs.clear() (a new crowd or act) takes every flag off every checker.
static func _clear_resets(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	C._run_for(crowd, 1.2, [crowd.citizens[0]])
	t.check(c.watch_far and c.badge_left > 0.0, "(flags on)")
	crowd.guard_jobs.clear()
	t.check(not c.watch_far and c.badge_left <= 0.0 and c.talk_left <= 0.0 and c.stand_face == Vector2.INF,
			"cleared: no far sight, badge, talk or facing")
	t.check(crowd.guard_jobs.live(GATE).is_empty() and not crowd.guard_jobs.on_job(c), "and no record")
	C._done(made)


## The Citadel falls (the board closes): every marshal's flags come off too.
static func _board_closed(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _gate_of(crowd, Person.Corps.MARSHAL)
	var marshal: Person = null
	for p in crowd.gate_check.checkers(gate):
		if p.corps == Person.Corps.MARSHAL:
			marshal = p
			break
	C._only_free(crowd, [marshal])
	C._place(marshal, _mouth(gate) + Vector2(0.4, 0.0))
	marshal.mind = Person.Mind.POST
	_tick(crowd)
	t.check(marshal.watch_far, "(a marshal at his gate sees far)")
	crowd.guard_jobs.close()
	t.check(not marshal.watch_far and marshal.badge_left <= 0.0, "the board closed: his flags are off")
	C._done(made)


## The release hook: the one let out of the queue at a checked gate is looked at; the gate's clock is not touched.
static func _released_hook(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate: Structure = (made[5] as Town).gates[0]
	var marshal: Person = null
	for p in crowd.gate_check.checkers(gate):
		if p.corps == Person.Corps.MARSHAL:
			marshal = p
	t.check(marshal != null, "(the main gate has a marshal checker)")
	if marshal == null:
		C._done(made)
		return
	C._place(marshal, _mouth(gate) + Vector2(0.4, 0.0))
	marshal.mind = Person.Mind.POST
	var spots := crowd.queue_spots(gate)
	var p: Person = crowd.citizens[1]
	p.inside = false
	p.mind = Person.Mind.FLEE
	p.ground_pos = spots[0]
	p.statuses[&"guise"] = 60.0
	crowd._gate_next.erase(gate)
	crowd._gates()
	t.check(p.passing_gate == gate and not p.guised(), "released at a checked gate, the guised one is seen through")
	t.near(float(crowd._gate_next[gate]) - crowd._clock, Crowd.GATE_INTERVAL / crowd.marshals.speed_at(_mouth(gate)), 0.001, "and the gate's clock is its own")
	C._done(made)


## Soldiers are not checked (a whispered gate guard is not unmasked by his mate).
static func _soldier_not_checked(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var other := crowd.add_soldier(_mouth(gate) - Crowd.outward_of(gate) * 0.8)
	other.statuses[&"guise"] = 60.0
	t.check(not crowd.gate_check.check(other, gate) and other.guised(), "a soldier passing is not checked")
	C._done(made)


## unmask(): the guise comes off; each hold of the god ends as it would have worn off; true when anything ended.
static func _unmask_minds(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var p: Person = crowd.citizens[0]
	_calm_at(p, Vector2(0.0, 0.0))
	t.check(not p.unmask(), "nothing to unmask: false")
	p.statuses[&"guise"] = 30.0
	t.check(p.unmask() and not p.guised(), "a guised citizen: true, the guise off")
	p.whisper(p.ground_pos, 30.0)
	t.check(p.unmask() and p.mind == Person.Mind.RECOVER, "a whispered one: true, he recovers")
	C._done(made)


## Four guised people crossing one checked gate together: all four unmasked, one incident, one alarm of 2.0, one banner, four "!" shown.
static func _one_gate_one_charge(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var texts := _texts(crowd)
	var district := AlarmManager.district_of(gate.center())
	var four: Array[Person] = []
	for i in 4:
		four.append(_guised_at(crowd, gate, 1 + i, 0.8 + 0.1 * float(i)))
	crowd.alarms.bell_rung = true
	var events := int(crowd.alarms._events.get(district, 0))
	var alarm := crowd.alarm
	_tick(crowd)
	var gone := 0
	for p in four:
		gone += 0 if p.guised() else 1
	t.check(gone == 4, "all four lose the guise (%d)" % gone)
	t.check(int(crowd.alarms._events.get(district, 0)) == events + 1, "one incident")
	t.near(crowd.alarm - alarm, GateCheck.GATE_SPOT_ALARM, 0.001, "one alarm of 2.0")
	t.check(texts.count(GateCheck.BANNER) == 1, "one banner")
	t.check(c.badge_glyph == GuardJobs.GLYPH_ALERT and c.badge_left > 0.0, "and the \"!\" shows")
	C._done(made)


## A director takes a checker (release(): no on_dropped) and gives him back: no dead job, and he checks again.
static func _director_release(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var gj := crowd.guard_jobs
	_tick(crowd)
	gj.release(c)
	_tick(crowd)
	var dead := false
	for job in gj.live(GATE):
		for m in job.crew:
			dead = dead or gj.job_of(m) != job
	t.check(not dead and not c.watch_far, "released by a director: no job holds him dead, his flags are off")
	c.send_to_post(c.post)
	_arrive(c)
	for i in 3:
		_tick(crowd)
	t.check(gj.kind_of(c) == GATE, "given back: he holds a new GATE job")
	for job in gj.live(GATE):
		for m in job.crew:
			dead = dead or gj.job_of(m) != job
	t.check(not dead, "and no dead record is left")
	C._run_for(crowd, 1.5, [crowd.citizens[0]])
	_arrive(c)
	var g := _guised_at(crowd, gate, 1)
	_tick(crowd)
	t.check(not g.guised(), "and he checks again")
	C._done(made)


## A gate guard's watch is the same at his post and on his spot.
static func _watch_same(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	t.check(c.on_watch() and c.watch_at().is_equal_approx(c.town_post), "on his spot: he watches, judged at his post")
	var there := c.ground_pos
	c.ground_pos = c.post + Vector2(0.0, 3.0)
	t.check(c.on_watch() and c.watch_at().is_equal_approx(c.town_post), "mid-step, far from both: still the same watch")
	c.ground_pos = there
	crowd.guard_jobs.release(c)
	c.send_to_post(c.post)
	_arrive(c)
	for i in 3:
		_tick(crowd)
	t.check(c.on_watch() and c.watch_at().is_equal_approx(c.town_post), "at his post: the same")
	var other: Person = null
	for p in crowd.soldiers:
		if p != c and not crowd.guard_jobs.on_job(p):
			other = p
			break
	t.check(other.watch_at().is_equal_approx(other.ground_pos), "a man with no record is judged where he stands")
	C._done(made)


## A director's charge (answers_lure) is never spotted, whispered or guised; anyone else is.
static func _charge_not_spotted(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _none_gate(crowd)
	var c := _ready_gate(crowd, gate) if gate != null else null
	t.check(c != null, "(a checker on his spot)")
	if c == null:
		C._done(made)
		return
	var charge: Person = crowd.citizens[1]
	_calm_at(charge, _mouth(gate) - Crowd.outward_of(gate) * 0.8)
	charge.answers_lure = true
	t.check(charge.whisper(charge.ground_pos, 30.0), "(the charge is whispered)")
	var guised: Person = crowd.citizens[2]
	_calm_at(guised, _mouth(gate) - Crowd.outward_of(gate) * 0.9)
	guised.answers_lure = true
	guised.statuses[&"guise"] = 60.0
	var plain: Person = crowd.citizens[3]
	_calm_at(plain, _mouth(gate) - Crowd.outward_of(gate) * 1.0)
	plain.whisper(plain.ground_pos, 30.0)
	_tick(crowd)
	t.check(charge.held_by_god() and guised.guised(), "a charge passes the checked gate untouched")
	t.check(not plain.held_by_god(), "while an ordinary whispered man is seen")
	C._done(made)


## A closed board checks nothing and shows no tag.
static func _closed_board_checks_nothing(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var gate := _gate_of(crowd, Person.Corps.MARSHAL)
	var marshal: Person = null
	for p in crowd.gate_check.checkers(gate):
		if p.corps == Person.Corps.MARSHAL:
			marshal = p
			break
	C._only_free(crowd, [marshal])
	_quiet(crowd, gate)
	C._place(marshal, _mouth(gate) + Vector2(0.4, 0.0))
	marshal.mind = Person.Mind.POST
	_tick(crowd)
	t.check(_has_tag(crowd, gate), "(the tag shows)")
	crowd.guard_jobs.close()
	var g := _guised_at(crowd, gate, 1)
	t.check(not crowd.gate_check.check(g, gate) and g.guised(), "a closed board: nothing is checked")
	t.check(not _has_tag(crowd, gate), "and no tag shows")
	C._done(made)
