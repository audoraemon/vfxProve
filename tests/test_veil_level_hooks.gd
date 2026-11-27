extends RefCounted
## The shared hooks the Veil's level-5 twists stand on (Veil ability levels, Task G2), each inert until a twist calls it: the watch
## (Crowd.is_watch(), a director's watches()), the blind (Person.blind_for() and what reads veil_blind()), the witness search's skip list,
## Silent Doom's answers (Crowd.answer_doom()), the step a dread refused (dread_balked_at), the watch turned away (turn_away()) and
## VeilParts.held().

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const DT := 0.1


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_is_watch(t, made)
	_blind(t, made)
	_skip(t, made)
	_answer_doom(t, made)
	_balked(t, made)
	_turn_away(t, made)
	_held(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


static func _tick(p: Person, seconds: float) -> void:
	for i in roundi(seconds / DT):
		p.tick(DT)


static func _is_watch(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	var every := true
	for corps in [Person.Corps.NONE, Person.Corps.MARSHAL, Person.Corps.ESCORT, Person.Corps.RESCUE, Person.Corps.KNIGHT]:
		var s := EV._put(crowd, at, true)
		s.corps = corps
		every = every and crowd.is_watch(s)
		s.corps = Person.Corps.NONE
	t.check(every, "a soldier of each Corps is the watch")
	var c := EV._put(crowd, at + Vector2(1.0, 0.0))
	t.check(not crowd.is_watch(c) and not crowd.is_watch(null), "a citizen is not; nor nobody")
	var d := MissionDirector.new()
	d.setup(null, crowd, made[6], made[5])
	d.faithful.append(c)
	t.check(d.watches(c) and not d.watches(EV._put(crowd, at + Vector2(2.0, 0.0))), "a director's watches() is its faithful")
	t.check(crowd.is_watch(c) and crowd.mission_watch.size() == 1, "the faithful are the watch through mission_watch")
	crowd.clear_mission_hooks()
	t.check(not crowd.is_watch(c) and crowd.mission_watch.is_empty(), "false again after clear_mission_hooks()")


static func _blind(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	var p := EV._put(crowd, at)
	var near := EV._put(crowd, at + Vector2(1.5, 0.0))
	var s := EV._put(crowd, at + Vector2(0.0, 6.0), true)
	t.check(s.on_watch() and crowd.nearest_witness(at) == p, "controls: the soldier is on watch; he is the nearest witness")
	var rep := TempleReport.new(near, at)
	rep.skip = func(_q: Person) -> bool: return false
	var d := MissionDirector.new()
	t.check(rep._witness(crowd, at) == p and d._sees(p, at, 5.0, null), "controls: the relay's witness; the faithful's sight")
	p.blind_for(6.0)
	t.check(p.is_blind() and p.veil_blind() and p.statuses.has(&"blind"), "blind_for(6): is_blind, veil_blind, the status")
	s.blind_for(6.0)
	t.check(not s.on_watch(), "a blind soldier is not on watch")
	t.check(crowd.nearest_witness(at) == near and rep._witness(crowd, at) == near, "nearest_witness and the relay's witness pass him over")
	t.check(not d._sees(p, at, 5.0, null), "the faithful's _sees() is false for him")
	_tick(p, 5.9)
	t.check(p.is_blind(), "still blind at 5.9 s")
	_tick(p, 0.2)
	t.check(not p.is_blind() and not p.veil_blind() and not p.statuses.has(&"blind") and p.statuses.is_empty(), "after 6.1 s: not blind, the status gone")
	p.ground_pos = at  # (ticking let him wander)
	t.check(crowd.nearest_witness(at) == p, "and a witness again")
	# He still flees and fights.
	var q := EV._put(crowd, at + Vector2(0.0, -6.0))
	q.blind_for(6.0)
	q.panic(q.ground_pos + Vector2(1.0, 0.0), 3.0)
	t.check(q.is_blind() and (q.mind == Person.Mind.PANIC or q.mind == Person.Mind.FLEE), "a blind man still flees when panic()ed (mind %s)" % q.mind)
	var foe := EV._put(crowd, at + Vector2(0.0, -7.0))
	s.send_to_post(s.ground_pos)
	s.fight(foe, 10.0, 0.5)
	t.check(s.is_blind() and s.mind == Person.Mind.FIGHT, "a blind soldier still fights")
	# The longest wins.
	var r := EV._put(crowd, at + Vector2(-3.0, 0.0))
	r.blind_for(5.0)
	r.blind_for(2.0)
	_tick(r, 3.0)
	t.check(r.is_blind(), "blind_for(2) with 5 left keeps the 5")
	_tick(r, 2.1)
	t.check(not r.is_blind(), "and it runs out at 5")
	var dead := EV._put(crowd, at + Vector2(-4.0, 0.0))
	dead.die(&"doom")
	dead.blind_for(6.0)
	t.check(not dead.is_blind() and dead.statuses.is_empty(), "the dead get none")


static func _skip(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	var a := EV._put(crowd, at + Vector2(0.6, 0.0))
	var b := EV._put(crowd, at + Vector2(1.0, 0.0))
	var c := EV._put(crowd, at + Vector2(1.5, 0.0))
	t.check(crowd.nearest_witness(at) == a and crowd.nearest_witness(at, null, {}) == a, "empty skip == today's answer")
	t.check(crowd.nearest_witness(at, null, {a.get_instance_id(): true}) == b, "the nearest in skip -> the next")
	t.check(crowd.nearest_witness(at, null, {a.get_instance_id(): true, b.get_instance_id(): true}) == c, "two skipped -> the third")
	t.check(crowd.nearest_witness(at, null, {a.get_instance_id(): true, b.get_instance_id(): true, c.get_instance_id(): true}) == null, "all skipped -> nobody")
	t.check(crowd.nearest_witness(at, a, {b.get_instance_id(): true}) == c, "exclude and skip together")


static func _answer_doom(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var calls: Array = []
	var answer := func(w: Person) -> void: calls.append(w)
	# One registered victim, his nearest witness answered once.
	var at := EV._fresh(made)
	var v := EV._put(crowd, at)
	var w := EV._put(crowd, at + Vector2(1.0, 0.0))
	var far := EV._put(crowd, at + Vector2(1.8, 0.0))
	crowd.answer_doom(v, answer)
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(calls == [w], "a registered victim: called once with his nearest witness (%s)" % [calls.size()])
	t.check(crowd.alarm > 0.0, "and today's loop ran unchanged: he was seen, the alarm rose")
	# Two registered victims, one witness: once.
	at = EV._fresh(made)
	calls.clear()
	var v1 := EV._put(crowd, at)
	var v2 := EV._put(crowd, at + Vector2(0.4, 0.0))
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	crowd.answer_doom(v1, answer)
	crowd.answer_doom(v2, answer)
	field.kill(v1, &"doom", at)
	field.kill(v2, &"doom", at)
	crowd._settle_doom()
	t.check(calls == [w], "two registered victims, one witness: once")
	# Naming before answering: an answer that kills never moves the next victim's witness (one hop).
	at = EV._fresh(made)
	calls.clear()
	v1 = EV._put(crowd, at)
	v2 = EV._put(crowd, at + Vector2(0.4, 0.0))
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	var w2 := EV._put(crowd, at + Vector2(-1.2, 0.0))
	var killer := func(x: Person) -> void:
		calls.append(x)
		field.kill(x, &"doom", at)
	crowd.answer_doom(v1, killer)
	crowd.answer_doom(v2, killer)
	field.kill(v1, &"doom", at)
	field.kill(v2, &"doom", at)
	crowd._settle_doom()
	t.check(calls == [w] and not w.is_alive() and w2.is_alive(), "both name the same witness first: he alone falls, the farther one lives (R6)")
	# An unregistered death.
	at = EV._fresh(made)
	calls.clear()
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(calls.is_empty(), "an unregistered death: not called")
	# An answer that kills the witness: the victim's death is judged with him gone.
	at = EV._fresh(made)
	calls.clear()
	var before := crowd.alarm
	var threats := crowd.threats.active_count()
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	crowd.answer_doom(v, killer)
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(calls == [w] and not w.is_alive() and crowd.alarm == before and crowd.threats.active_count() == threats,
		"an answer that kills the witness: the victim's death is judged after, with him gone: no alarm")
	crowd._settle_doom()
	t.check(crowd.alarm == before, "and the witness's own death, judged at the next settle, is seen by nobody either")
	# unanswer_doom.
	at = EV._fresh(made)
	calls.clear()
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	crowd.answer_doom(v, answer)
	crowd.unanswer_doom(answer)
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(calls.is_empty(), "unanswer_doom: not called")
	# A callable whose object is freed after the registration: skipped, no error.
	at = EV._fresh(made)
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	var holder := Node.new()
	crowd.answer_doom(v, Callable(holder, "queue_free"))
	holder.free()
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(w.is_alive() and crowd._doom_answers.is_empty(), "a freed object's callable is skipped without error")
	crowd.answer_doom(v, Callable())
	t.check(crowd._doom_answers.is_empty(), "an invalid callable is never registered")
	# No registration: today's settle.
	at = EV._fresh(made)
	before = crowd.alarm
	v = EV._put(crowd, at)
	w = EV._put(crowd, at + Vector2(1.0, 0.0))
	field.kill(v, &"doom", at)
	crowd._settle_doom()
	t.check(crowd.alarm > before and w.is_alive(), "no registration: _settle_doom as today (seen, alarm up, the witness lives)")
	t.check(far != null, "(the far witness stood by)")


static func _balked(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	crowd.dusk.enabled = true
	var dpt := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(dpt, 1.5, 60.0)
	var p := EV._put(crowd, dpt + Vector2(1.6, 0.0))
	var into := Vector2(-0.2, 0.0)
	t.check(p.dread_balked_at == -INF, "no dread: -INF")
	t.check(not p._step_blocked(into) and p.dread_balked_at == -INF, "no dread, the step is free: still -INF")
	crowd.dread(at, 6.0, 25.0)
	crowd._clock += 3.0
	t.check(p._step_blocked(into) and p.dread_balked_at == crowd.clock(), "a step into dreaded ground is refused and stamps the crowd clock")
	var stamp := p.dread_balked_at
	crowd._clock += 1.0
	t.check(not p._step_blocked(-into) and p.dread_balked_at == stamp, "a step away is not refused and stamps nothing")
	crowd.dreads.clear()


static func _turn_away(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	var s := EV._put(crowd, at, true)
	var post := at + Vector2(3.0, 0.0)
	s.post = post
	var foe := EV._put(crowd, at + Vector2(1.0, 0.0))
	s._fight_rule = Person.FightRule.HOSTILES
	foe.mind = Person.Mind.FIGHT
	t.check(s._fightable(foe), "control: a fighting citizen is the watch's to fight")
	s.fight(foe, 10.0, 0.5, Person.FightRule.HOSTILES)
	t.check(s.mind == Person.Mind.FIGHT, "control: the soldier fights")
	t.check(s.turn_away(6.0), "turn_away: true")
	t.check(s.mind == Person.Mind.POST and s.fight_target == null and s.has_goal() and s.anchor.is_equal_approx(post),
		"a fighting soldier: not fighting, mind POST, goal his post")
	t.check(s.is_blind() and not s.on_watch(), "blind for the seconds, on watch no more")
	s._fight_rule = Person.FightRule.HOSTILES
	t.check(not s._fightable(foe), "he takes up no new target while turned")
	_tick(s, 5.9)
	t.check(not s._fightable(foe) and s.is_blind(), "still turned at 5.9 s")
	_tick(s, 0.2)
	t.check(s._fightable(foe) and not s.is_blind(), "after 6.1 s he may fight again")
	# One of the watch who is no soldier: calm, no goal.
	var f := EV._put(crowd, at + Vector2(-2.0, 0.0))
	f.set_goal(at + Vector2(-8.0, 0.0))
	f.mind = Person.Mind.OBSERVE
	t.check(f.turn_away(6.0) and f.mind == Person.Mind.CALM and not f.has_goal() and f.is_blind(), "a faithful: CALM, no goal, blind")
	var dead := EV._put(crowd, at + Vector2(-4.0, 0.0))
	dead.die(&"doom")
	var inside := EV._put(crowd, at + Vector2(-5.0, 0.0))
	inside.inside = true
	t.check(not dead.turn_away(6.0) and not inside.turn_away(6.0) and not inside.is_blind(), "the dead and the indoors: false")
	t.check(not f.turn_away(0.0), "no seconds: false")


static func _held(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	var p := EV._put(crowd, at)
	t.check(not VeilParts.held(p) and not VeilParts.held(null), "control: nobody is held")
	p.sleep(10.0)
	t.check(VeilParts.held(p), "asleep: held")
	p.wake()
	p.statuses[&"shadow"] = 10.0
	t.check(VeilParts.held(p), "a shadow: held")
	p.statuses.erase(&"shadow")
	p.statuses[&"dread"] = 10.0
	t.check(VeilParts.held(p), "dreaded: held")
	p.statuses.erase(&"dread")
	p.statuses[&"cloak"] = 10.0
	t.check(not VeilParts.held(p), "cloaked: not held")
	p.statuses.erase(&"cloak")
	p.blind_for(5.0)
	t.check(not VeilParts.held(p), "blind: not held")
	var q := EV._put(crowd, at + Vector2(1.0, 0.0))
	q.make_ill(5.0)
	t.check(not VeilParts.held(q), "sick: not held")
