extends RefCounted
## The flinch (fair life, 2026-11-20): a steadied person (fearless_left > 0) no longer ignores a blow. He freezes his own
## startle_seconds() facing it, a duty-bound citizen steps FLINCH_STEP away, he stares until FLINCH_SECONDS from the start
## and carries on -- his mind, anchor and awareness untouched, a warden and a soldier never moved off their place. A god's
## absolute hold still beats it, and the dead, the frightened and those indoors do not flinch.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func run(t) -> void:
	var made := RD._setup()
	_consts(t)
	_steadied_flinch(t, made)
	_observe_flinch(t, made)
	_warden_no_step(t, made)
	_flinch_refused(t, made)
	_absolute_wins(t, made)
	RD._done(made)


## Seconds of the town, his feet moving between its steps.
static func _advance(crowd: Crowd, people: Array, seconds: float) -> void:
	for i in roundi(seconds / DT):
		for p in people:
			(p as Person).frame(DT)
		crowd.advance(DT)


## The nth living citizen, calm, out in the open at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.inside = false
	p.mind = Person.Mind.CALM
	return p


## A citizen on duty at `at`, standing at his anchor, steadied for `fear` seconds.
static func _on_duty(made: Array, n: int, at: Vector2, fear := 30.0) -> Person:
	var p := _put(made, n, at)
	p.go_duty(at)
	_advance(made[0], [p], 0.5)
	p.fearless_left = fear
	return p


static func _consts(t) -> void:
	t.check(Person.FLINCH_STEP == 0.5 and Person.FLINCH_SECONDS == 2.0, "the brief's numbers: a half-tile step, a two-second stare")


static func _steadied_flinch(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var p := _on_duty(made, 20, (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center()), 5.0)
	var anchor := p.anchor
	var from := p.ground_pos + Vector2(1.0, 0.0)
	var start := p.ground_pos
	t.check(p.mind == Person.Mind.DUTY and not p.flinching(), "set up: on duty at his anchor, not yet flinching")
	p.panic(from, 1.0)
	t.check(p.flinching() and p.mind == Person.Mind.DUTY and p.fearless_left > 0.0,
		"a steadied man's fright is a flinch: still on duty, still steadied (mind %d)" % p.mind)
	_advance(crowd, [p], p.startle_seconds() + 0.6)
	var d := p.ground_pos.distance_to(anchor)
	t.check(d > 0.2 and d < Person.FLINCH_STEP + 0.05 and p.ground_pos.distance_to(from) > start.distance_to(from) + 0.15,
		"he steps back from it, no more than half a tile (%.2f from his anchor)" % d)
	_advance(crowd, [p], Person.FLINCH_SECONDS + 3.0)
	t.check(p.ground_pos.distance_to(anchor) < 0.3 and not p.flinching() and p.mind == Person.Mind.DUTY,
		"then he is back at his anchor, done flinching (%.2f off)" % p.ground_pos.distance_to(anchor))


static func _observe_flinch(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var p := _on_duty(made, 21, RD._empty(made))
	p.observe(p.ground_pos + Vector2(0.0, 1.5))
	t.check(p.flinching() and p.mind == Person.Mind.DUTY, "a steadied man made to look flinches and keeps his duty (mind %d)" % p.mind)
	var c := _put(made, 22, p.ground_pos + Vector2(3.0, 3.0))
	c.fearless_left = 10.0
	c.observe(c.ground_pos + Vector2(1.0, 0.0))
	t.check(c.flinching() and c.mind == Person.Mind.CALM, "a calm steadied man flinches and stays calm (mind %d)" % c.mind)
	_advance(crowd, [p, c], Person.FLINCH_SECONDS + 1.0)
	t.check(not p.flinching() and not c.flinching(), "both are done after the stare")


## A warden and a soldier at his post are steadied too, and stand where they stood.
static func _warden_no_step(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var w := _on_duty(made, 23, RD._empty(made))
	w.profile.role = CitizenProfile.Role.WATCHMAN
	var wat_from := w.ground_pos
	w.panic(w.ground_pos + Vector2(1.0, 0.0), 1.0)
	var s: Person = crowd.soldiers.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())[0]
	s.ground_pos = w.ground_pos + Vector2(4.0, 4.0)
	s.mind = Person.Mind.POST
	s.anchor = s.ground_pos
	s.fearless_left = 30.0
	var s_from := s.ground_pos
	s.panic(s.ground_pos + Vector2(1.0, 0.0), 1.0)
	t.check(w.flinching() and s.flinching() and w.mind == Person.Mind.DUTY and s.mind == Person.Mind.POST,
		"the warden and the soldier flinch and keep their minds (%d, %d)" % [w.mind, s.mind])
	var wmax := 0.0
	var smax := 0.0
	for i in roundi(Person.FLINCH_SECONDS / DT) - 2:
		_advance(crowd, [w, s], DT)
		wmax = maxf(wmax, w.ground_pos.distance_to(wat_from))
		smax = maxf(smax, s.ground_pos.distance_to(s_from))
	t.check(wmax <= 0.05 and smax <= 0.05, "neither is moved off his place (warden %.2f, soldier %.2f)" % [wmax, smax])
	w.profile.role = CitizenProfile.Role.RESIDENT


static func _flinch_refused(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p := _put(made, 24, at)
	p.fearless_left = 30.0
	p.flinch(at + Vector2(1.0, 0.0))
	_advance(crowd, [p], 1.0)
	p.flinch(at + Vector2(-1.0, 0.0))  # a second one does not restart the first
	_advance(crowd, [p], Person.FLINCH_SECONDS - 1.0 + 0.3)
	t.check(not p.flinching(), "a flinch while flinching does not restart it")
	var panicked := _put(made, 25, at + Vector2(5.0, 0.0))
	panicked.mind = Person.Mind.PANIC
	var fled := _put(made, 26, at + Vector2(0.0, 5.0))
	fled.mind = Person.Mind.FLEE
	var dead := _put(made, 27, at + Vector2(5.0, 5.0))
	dead.die(&"mob")
	var inside := _put(made, 28, at + Vector2(-5.0, 0.0))
	inside.inside = true
	for q in [panicked, fled, dead, inside]:
		q.flinch(at)
	var fighter := _put(made, 30, at + Vector2(-5.0, 5.0))
	fighter.mind = Person.Mind.FIGHT
	fighter.fearless_left = 30.0
	fighter.panic(at, 1.0)
	fighter.observe(at)
	var runner: Person = crowd.soldiers.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())[1]
	runner.ground_pos = at + Vector2(8.0, 8.0)
	runner.mind = Person.Mind.POST
	runner.hurrying = true
	runner.fearless_left = 30.0
	runner.observe(at)
	runner.panic(at, 1.0)
	t.check(not fighter.flinching() and not runner.flinching(),
		"a fearless fighter and a soldier hurrying to his post do not flinch, by observe() or panic()")
	t.check(not (panicked.flinching() or fled.flinching() or dead.flinching() or inside.flinching()),
		"the frightened, the fleeing, the dead and those indoors do not flinch")


static func _absolute_wins(t, made: Array) -> void:
	RD._clear_all(made)
	var p := _put(made, 29, RD._empty(made))
	p.fearless_left = 30.0
	p.compel(p.ground_pos, 20.0, Person.WILL_ABSOLUTE, Color.WHITE, false, &"")
	p.panic(p.ground_pos + Vector2(1.0, 0.0), 1.0)
	p.observe(p.ground_pos + Vector2(1.0, 0.0))
	t.check(not p.flinching() and p.mind != Person.Mind.PANIC, "held absolutely he neither panics nor flinches (mind %d)" % p.mind)
