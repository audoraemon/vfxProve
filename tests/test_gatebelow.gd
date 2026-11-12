extends RefCounted
## The Gate Below (Death, Tier IV): a click opens the ground into a pit of 3 ringed in bone for 12 s. Every 0.5 s pale arms
## take the nearest person within 6 who is out in the open, not guised and not caught yet, hold them (pace 0) and drag them to
## the pit's edge over 1.5 s, where they go under (killed as pit: no body is left). When the pit closes every soul it took
## climbs back out as a wraith that hunts soldiers for 20 s. Loud: the town panics.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func _cast(made: Array, at: Vector2) -> TheGateBelowFx:
	return FxTimeline.cast(TheGateBelowFx, made[5], at) as TheGateBelowFx


static func run(t) -> void:
	var made := RD._setup()
	_book(t)
	_grabs(t, made)
	_held_and_freed(t, made)
	_pit(t, made)
	_wraiths(t, made)
	_none(t, made)
	_prey(t, made)
	_loud(t, made)
	RD._done(made)


## Everyone back out in the open and unguised, then off in the corner (RD._clear_all).
static func _reset(made: Array) -> void:
	var crowd: Crowd = made[0]
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p):
			p.inside = false
			p.statuses.erase(&"guise")
	RD._clear_all(made)


## The nth citizen still alive (the pit kills some in every test), calm, at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


## The row, its tables, its icons, the brief's numbers.
static func _book(t) -> void:
	var b := PowerBook.get_power("gatebelow")
	t.check(not b.is_empty() and int(b.dp) == 5 and float(b.cooldown) == 90.0 and String(b.aim) == "click"
		and PowerBook.authority_of("gatebelow") == "death" and not PowerBook.is_quiet("gatebelow")
		and String(b.get("path", "")) == "res://src/fx/death/the_gate_below.gd",
		"The Gate Below: Death's 5 DP, 90 s, a click, loud (%s)" % [b])
	var area: Dictionary = Targeting.AREAS.get("gatebelow", {})
	t.check(PowerBook.REACH.has("gatebelow") and is_equal_approx(PowerBook.impact("gatebelow"), TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG)
		and PowerBook.family("gatebelow") == "death" and Rules.POWER_KINDS.get("gatebelow", []) == [&"pit"]
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), TheGateBelowFx.REACH)
		and Targeting.AREA_STATS.get("gatebelow", {}) == {"r": "REACH"},
		"its reach, impact (the first soul under), family, kills (pit) and area (the arms' reach)")
	t.check(PowerBook.icon("gatebelow") != null and PowerBook.hud_icon("gatebelow") != null, "it has its icons")
	t.check(TheGateBelowFx.PIT_R == 3.0 and TheGateBelowFx.REACH == 6.0 and TheGateBelowFx.SPAN == 12.0
		and TheGateBelowFx.GRAB_EVERY == 0.5 and TheGateBelowFx.DRAG == 1.5 and TheGateBelowFx.WRAITH_LIFE == 20.0,
		"the numbers of the brief")
	t.check(Sfx.CATALOG.has(&"gatebelow_open") and Sfx.CATALOG.has(&"gatebelow_close"), "its two cues are catalogued")


## "grabs the nearest each 0.5 s, never a guised one": the nearest fair one first, the next 0.5 s later; a guised one, one
## indoors and one past REACH are never taken; a tie goes to the lower instance id.
static func _grabs(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	t.check(at != Vector2.INF, "a spot with nobody near")
	var guised := _put(made, 0, at + Vector2(1.0, 0.0))
	guised.statuses[&"guise"] = 30.0
	var indoor := _put(made, 1, at + Vector2(0.0, 1.2))
	indoor.inside = true
	var first := _put(made, 2, at + Vector2(0.0, 2.5))
	var second := _put(made, 3, at + Vector2(-3.5, 0.0))
	var far := _put(made, 4, at + Vector2(0.0, 6.8))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN - 0.1)
	t.check(fx.grabbed.is_empty(), "nobody is taken before the pit is open")
	RD._run(fx, 0.15)
	t.check(fx.grabbed == [first], "the nearest fair one is taken first, not the guised one nearer (%s)" % [_names(fx.grabbed)])
	RD._run(fx, TheGateBelowFx.GRAB_EVERY - 0.1)
	t.check(fx.grabbed.size() == 1, "nobody else before the next 0.5 s")
	RD._run(fx, 0.1)
	t.check(fx.grabbed == [first, second], "the next nearest 0.5 s later (%s)" % [_names(fx.grabbed)])
	RD._run(fx, 4.0)
	t.check(fx.grabbed == [first, second] and guised.is_alive() and indoor.is_alive() and far.is_alive(),
		"never a guised one, nor one indoors, nor one past 6 (%s)" % [_names(fx.grabbed)])
	fx.end_now()
	guised.statuses.erase(&"guise")
	indoor.inside = false
	# A tie: two at the same distance, the lower instance id first.
	_reset(made)
	var a := _put(made, 5, at + Vector2(3.0, 0.0))
	var b := _put(made, 6, at + Vector2(-3.0, 0.0))
	var low := a if a.get_instance_id() < b.get_instance_id() else b
	var fx2 := _cast(made, at)
	RD._run(fx2, TheGateBelowFx.T_OPEN + 0.05)
	t.check(fx2.grabbed == [low], "a tie goes to the lower instance id")
	fx2.end_now()


static func _names(ps: Array) -> Array:
	return ps.map(func(p: Person) -> String: return String(p.name) if is_instance_valid(p) else "<freed>")


## A caught one is held (pace 0) while dragged; the effect cut short lets them go with their pace back.
static func _held_and_freed(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var p := _put(made, 2, at + Vector2(4.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + 0.6)
	var d := p.ground_pos.distance_to(at)
	t.check(p.is_alive() and p.pace_hold() == 0.0 and d < 4.0 - 0.1 and d > TheGateBelowFx.EDGE,
		"a caught one is held (pace %.2f) and dragged toward the edge (%.2f from the middle)" % [p.pace_hold(), d])
	fx.end_now()
	t.check(p.is_alive() and p.pace_hold() == 1.0, "cut short, they are let go with their pace back (%.2f)" % p.pace_hold())
	# One the night puts indoors mid-drag is let go too, and never goes under.
	_reset(made)
	var q := _put(made, 2, at + Vector2(0.0, 4.0))
	var fx2 := _cast(made, at)
	RD._run(fx2, TheGateBelowFx.T_OPEN + 0.3)
	q.inside = true
	RD._run(fx2, TheGateBelowFx.DRAG)
	t.check(q.is_alive() and q.pace_hold() == 1.0 and fx2.souls == 0, "one put indoors mid-drag is let go (pace %.2f)" % q.pace_hold())
	q.inside = false
	fx2.end_now()


## "a grabbed person dies as pit, no remain": dragged to the edge over DRAG, then under: a pit death, no body.
static func _pit(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var p := _put(made, 2, at + Vector2(0.0, 4.5))
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == p:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG - 0.1)
	t.check(p.is_alive(), "still alive while the arms drag them")
	RD._run(fx, 0.15)
	t.check(not p.is_alive() and kinds == [&"pit"], "a grabbed person dies as pit (%s)" % [kinds])
	t.check(absf(p.ground_pos.distance_to(at) - TheGateBelowFx.EDGE) < 0.05,
		"at the pit's edge (%.2f from the middle, the edge %.2f)" % [p.ground_pos.distance_to(at), TheGateBelowFx.EDGE])
	t.check(crowd.remains.enabled and crowd.remains.all().is_empty() and crowd.remains.pick(p.ground_pos) == null,
		"no remain: no body is left")
	t.check(fx.souls == 1 and is_equal_approx(fx.first_soul_at, PowerBook.impact("gatebelow")),
		"one soul taken, at the power's impact (%.2f)" % fx.first_soul_at)
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## "at 12 s one wraith per soul taken": none before the close; at it one per soul, wraiths that go for soldiers; they last
## WRAITH_LIFE and are gone with the effect.
static func _wraiths(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	_put(made, 2, at + Vector2(2.0, 0.0))
	_put(made, 3, at + Vector2(0.0, 3.0))
	_put(made, 4, at + Vector2(-4.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.SPAN - 0.1)
	t.check(fx.souls == 3 and fx.visitors.living().is_empty(), "three souls taken, nobody back yet (%d souls)" % fx.souls)
	RD._run(fx, 0.15)
	var up := fx.visitors.living()
	var ok := up.size() == 3
	for a in up:
		var r: Visitors.Rule = fx.visitors._rules[a]
		ok = ok and a.breed == Animal.Breed.SPIRIT and r.soldiers_only and r.slow < 1.0 and r.phase and a.ground_pos.distance_to(at) < TheGateBelowFx.PIT_R
	t.check(ok, "at 12 s one wraith per soul taken, out of the pit (%d up)" % up.size())
	RD._run(fx, TheGateBelowFx.WRAITH_LIFE - 0.6)
	t.check(fx.visitors.living().size() == 3 and not fx.finished, "they last their 20 s")
	RD._run(fx, 0.6 + TheGateBelowFx.FADE + 0.4)
	t.check(fx.finished and fx.visitors.living().is_empty(), "then they are gone, and the effect with them")


## Nobody near: no soul, no wraith, and the effect ends with the close.
static func _none(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.SPAN + TheGateBelowFx.CLOSE + 0.3)
	t.check(fx.souls == 0 and fx.visitors.living().is_empty() and fx.finished, "nobody taken: no wraith, and it ends with the close")


## "wraiths go for soldiers, not a nearer citizen"
static func _prey(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	_put(made, 2, at + Vector2(3.0, 0.0))
	var s: Person = crowd.soldiers[0]
	s.ground_pos = at + Vector2(0.0, 7.0)
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.SPAN - 0.1)
	var near := _put(made, 3, at + Vector2(-1.5, 0.0))  # set down once the arms no longer take anyone
	RD._run(fx, 0.15)
	var up := fx.visitors.living()
	t.check(up.size() == 1 and near.is_alive(), "one wraith, and the citizen beside the pit is not taken")
	if up.size() != 1:
		fx.end_now()
		return
	var w := up[0]
	var before := w.ground_pos.distance_to(s.ground_pos)
	var near_before := w.ground_pos.distance_to(near.ground_pos)
	RD._run(fx, 2.0)
	var after := w.ground_pos.distance_to(s.ground_pos)
	t.check(w.target == s and after < before - 0.8 and near_before < before,
		"wraiths go for soldiers, not a nearer citizen (%.2f -> %.2f from the soldier; the citizen was %.2f)" % [before, after, near_before])
	fx.end_now()
	t.check(s.pace_hold() == 1.0, "cut short, the soldier it passed has his pace back")


## "loud: the town panics": the cast is held as a danger until its impact; people past the arms' reach flee the open pit;
## the first soul taken raises the alarm.
static func _loud(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var held := crowd.held_count()
	crowd.on_cast(at, Vector2.ZERO, 0.0, "gatebelow")
	t.check(crowd.held_count() == held + 1, "the cast is a danger the town sees (held for its impact)")
	crowd.drop_held()
	_put(made, 2, at + Vector2(3.0, 0.0))
	var watcher := _put(made, 3, at + Vector2(0.0, TheGateBelowFx.REACH + 1.5))
	var alarm := crowd.alarm
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG + 0.2)
	t.check(watcher.is_alive() and watcher.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]
		and crowd.threats.unsafe(watcher.ground_pos),
		"loud: the town panics (one 7.5 off, past the arms: %s, in the pit's danger)" % Person.Mind.keys()[watcher.mind])
	t.check(crowd.alarm > alarm, "the first soul taken raises the alarm (%.2f -> %.2f)" % [alarm, crowd.alarm])
	fx.end_now()
