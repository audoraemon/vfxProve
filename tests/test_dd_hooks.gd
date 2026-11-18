extends RefCounted
## The shared hooks the level-5 Death and Decree twists call (Death and Decree ability levels, Task 1b). Every one is inert
## until a twist uses it: this suite shows each works when called, and (in the other suites) that level 1 never calls one.
## Foul source (Person.plague_src, PlagueManager.foul / foul_from / foul_spots), carried law (Person.carried_laws,
## Crowd.in_law), struck-by memory (Person.struck_by / struck_at), the &"borrowed" kill, Person.deathless, --bench-level.


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	# Everyone far from the scene (a grid in the town's corner), so only the people a test moves in are near anything.
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.9, -27.0 + float(i / 20) * 0.9)
		i += 1
	return [crowd, env, field, world, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[3] as Node).free()


static func _sick_still(crowd: Crowd, p: Person, src: int, seconds := PlagueManager.PLAGUE_LIFE) -> void:
	p.infect(seconds)
	p.plague_src = src


static func run(t) -> void:
	_foul(t)
	_foul_rng(t)
	_carried_law(t)
	_struck_by(t)
	_borrowed(t)
	_deathless(t)
	_spared_plague(t)
	_bench_level(t)


## Foul Dead: the source is copied on by the spread; a foul death lays a spot that infects the nearest three within 1.2.
static func _foul(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var plague := crowd.plague
	var src := 4242
	t.check(plague.foul.is_empty() and plague.foul_spots.is_empty(), "no foul source and no foul spot by default")
	t.check(crowd.citizens[0].plague_src == 0, "a person's plague source is 0 by default")

	# The spread copies the source from the one who gave it on.
	var at := Vector2(6.0, 6.0)
	var giver: Person = crowd.citizens[0]
	giver.ground_pos = at
	_sick_still(crowd, giver, src)
	var group: Array[Person] = []
	for k in 6:
		var q: Person = crowd.citizens[1 + k]
		q.ground_pos = at + Vector2(0.1 * float(k + 1), 0.05)
		group.append(q)
	for s in 4:
		plague.step(PlagueManager.SPREAD_EVERY * 0.99)
		if giver.sick_left < 1.2:
			giver.sick_left = 3.0  # kept alive through the spreads
	var caught := 0
	var copied := true
	for q in group:
		if q.sick_left > 0.0:
			caught += 1
			copied = copied and q.plague_src == src
	t.check(caught > 0 and copied, "the plague passes its source on to each person it infects (%d caught)" % caught)
	t.check(giver.plague_src == src, "the giver keeps its own source")
	_done(made)

	# A foul death lays a spot; it infects at most 3, within 1.2, none at 1.3, and copies the source.
	made = _setup()
	crowd = made[0]
	plague = crowd.plague
	var p: Person = crowd.citizens[0]
	p.ground_pos = at
	_sick_still(crowd, p, src)
	plague.foul_from(src)
	t.check(plague.foul.has(src), "foul_from() marks a source foul")
	plague.foul_from(0)
	t.check(not plague.foul.has(0), "source 0 (no cast) is never foul")
	plague.step(0.1)
	plague.step(PlagueManager.PLAGUE_LIFE + 0.1)
	t.check(not p.is_alive() and plague.foul_spots.size() == 1, "a foul death lays one foul spot")
	var spot: Dictionary = plague.foul_spots[0]
	t.check(spot["pos"].is_equal_approx(at) and is_equal_approx(float(spot["left"]), 15.0) and int(spot["most"]) == 3,
		"the spot lies where they fell, 15 s, 3 infections")
	var near: Array[Person] = []
	for k in 4:
		var q: Person = crowd.citizens[1 + k]
		q.ground_pos = at + Vector2(1.0 + 0.05 * float(k), 0.0)
		near.append(q)
	var far1: Person = crowd.citizens[6]
	far1.ground_pos = at + Vector2(1.3, 0.0)
	var far2: Person = crowd.citizens[7]
	far2.ground_pos = at + Vector2(0.0, 1.31)
	var rng_before := plague._rng.state
	for k in 3:
		plague.step(PlagueManager.SCAN_EVERY + 0.01)
	var sick_near := 0
	for q in near:
		if q.sick_left > 0.0:
			sick_near += 1
			t.check(q.plague_src == src, "a spot's victim carries the same source (foul in turn)")
	t.check(sick_near == 3 and near[3].sick_left <= 0.0, "the spot infects the 3 nearest within 1.2 and no more (%d)" % sick_near)
	t.check(far1.sick_left <= 0.0 and far2.sick_left <= 0.0, "nobody 1.3 away is infected")
	t.check(plague._rng.state == rng_before, "the spot's infections draw no random number")
	t.check(plague.foul_spots.is_empty(), "a spot is gone once its three are spent")
	# A spot ages out after 15 s.
	for q in near:
		q.sick_left = 0.0  # cured, so no new death lays a spot of its own
	plague.foul_spots.append({"pos": at + Vector2(20.0, 20.0), "left": 15.0, "most": 3, "src": src})
	plague.step(14.0)
	var alive1 := plague.foul_spots.size() == 1
	plague.step(1.1)
	t.check(alive1 and plague.foul_spots.is_empty(), "a spot lasts 15 s")
	plague.clear()
	t.check(plague.foul.is_empty() and plague.foul_spots.is_empty(), "clear() forgets the foul sources and spots")
	_done(made)

	# A death from another line, or with nothing foul, lays none.
	for variant in 2:
		made = _setup()
		crowd = made[0]
		plague = crowd.plague
		p = crowd.citizens[0]
		p.ground_pos = at
		_sick_still(crowd, p, src)
		if variant == 1:
			plague.foul_from(src + 1)  # a different cast is foul, not this one
		plague.step(0.1)
		plague.step(PlagueManager.PLAGUE_LIFE + 0.1)
		t.check(not p.is_alive() and plague.foul_spots.is_empty(),
			"%s: a death not traced to a foul source lays no spot" % ["nothing foul", "another cast's source is foul"][variant])
		_done(made)


## With nothing to infect, a foul source changes no random draw: the plague's rng ends where an empty `foul` run ends.
static func _foul_rng(t) -> void:
	var states: Array[int] = []
	var deaths: Array[int] = []
	for variant in 2:
		var made := _setup()
		var crowd: Crowd = made[0]
		var plague := crowd.plague
		var at := Vector2(6.0, 6.0)
		for k in 4:
			var q: Person = crowd.citizens[k]
			q.ground_pos = at + Vector2(0.1 * float(k), 0.0)
			if k == 0:
				_sick_still(crowd, q, 777)
		if variant == 1:
			plague.foul_from(777)
		var s := 0.0
		while s < 10.0:
			plague.step(0.1)
			s += 0.1
		states.append(plague._rng.state)
		deaths.append(plague.deaths)
		_done(made)
	t.check(states[0] == states[1] and deaths[0] == deaths[1] and deaths[0] > 0,
		"10 s of plague draws the same numbers with a foul source set as with `foul` empty (%d / %d)" % [states[0], states[1]])


## Bad Counsel: a carried law makes in_law() true for its seconds, then it is erased.
static func _carried_law(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var p: Person = crowd.citizens[0]
	p.ground_pos = Vector2(6.0, 6.0)
	t.check(not crowd.in_law(p, LawZone.DISORDER), "no law without a zone or a carried one")
	p.carried_laws[LawZone.DISORDER] = 8.0
	t.check(crowd.in_law(p, LawZone.DISORDER) and not crowd.in_law(p, LawZone.NO_SIGHT), "a carried DISORDER holds for that kind only")
	t.check(crowd.law_of(p, LawZone.DISORDER) == null, "law_of() is unchanged: it returns zones, not carried laws")
	for k in 7:
		p.tick(1.0)
	t.check(crowd.in_law(p, LawZone.DISORDER) and float(p.carried_laws[LawZone.DISORDER]) > 0.0, "still carried after 7 s")
	p.tick(1.1)
	t.check(not crowd.in_law(p, LawZone.DISORDER) and p.carried_laws.is_empty(), "gone after 8 s, and erased")
	t.check(not crowd.in_law(null, LawZone.DISORDER), "in_law(null) is still false")
	_done(made)


## Party to the Bond: hurt(amount, by) remembers who struck and when.
static func _struck_by(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.ground_pos = Vector2(6.0, 6.0)
	b.ground_pos = Vector2(6.5, 6.0)
	t.check(a.struck_by == null and a.struck_at < 0.0, "nobody has struck a fresh person")
	crowd.advance(0.5)
	a.hurt(0.1, b)
	t.check(a.struck_by != null and a.struck_by.get_ref() == b and is_equal_approx(a.struck_at, crowd.clock()),
		"hurt(x, by) remembers the striker and the crowd clock")
	var c: Person = crowd.citizens[2]
	c.ground_pos = Vector2(6.0, 7.0)
	c.hurt(0.1, null)
	t.check(c.struck_by == null and c.struck_at < 0.0, "a blow with no source remembers no one")
	_done(made)


## Borrowed Life: a &"borrowed" kill leaves no remain, raises no alarm, is quiet, and counts as a death.
static func _borrowed(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[2]
	var rem := crowd.remains
	rem.enabled = true
	t.check(not Remains.BODY_KINDS.has(&"borrowed") and DeathVoices.QUIET_KINDS.has(&"borrowed"),
		"borrowed is no body kind, and a quiet one")
	var p: Person = crowd.citizens[0]
	p.ground_pos = Vector2(6.0, 6.0)
	var alarm0 := crowd.alarm
	var n0 := crowd.killed_citizens
	var scared := crowd.citizens[1]
	scared.ground_pos = Vector2(6.5, 6.0)
	var mind0 := scared.mind
	var killed := field.kill(p, &"borrowed", p.ground_pos)
	t.check(killed and not p.is_alive() and rem.all().is_empty(), "a borrowed death leaves no remain")
	t.check(is_equal_approx(crowd.alarm, alarm0) and scared.mind == mind0 and crowd.threats.active_count() == 0,
		"no alarm and nobody stirs")
	t.check(crowd.killed_citizens == n0 + 1, "it counts as a citizen killed")
	rem.enabled = false
	_done(made)


## A person Deathless spares from a plague death is no longer foul: a later sickness is not inherited from the old source.
static func _spared_plague(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var plague: PlagueManager = crowd.plague
	var src := 4242
	plague.foul_from(src)
	var kept: Person = crowd.citizens[0]
	kept.ground_pos = Vector2(6.0, 6.0)
	kept.deathless = func(_w: Person, _k: StringName) -> bool: return true
	_sick_still(crowd, kept, src)
	plague.step(0.1)
	plague.step(PlagueManager.PLAGUE_LIFE + 0.1)
	t.check(kept.is_alive() and kept.plague_src == 0, "spared from a plague death: the foul source is cleared")
	var gone: Person = crowd.citizens[1]
	gone.ground_pos = Vector2(8.0, 8.0)
	_sick_still(crowd, gone, src)
	plague.step(0.1)
	plague.step(PlagueManager.PLAGUE_LIFE + 0.1)
	t.check(not gone.is_alive() and plague.foul_spots.size() == 1, "control: one not spared dies foul and lays its spot")
	_done(made)


## The deathless fall: a callable that returns true spares the death (down, alive, nothing counted); false lets it happen.
static func _deathless(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[2]
	var rem := crowd.remains
	rem.enabled = true
	var at := Vector2(6.0, 6.0)
	t.check(not crowd.citizens[0].deathless.is_valid(), "no one is deathless by default")

	var spared: Person = crowd.citizens[0]
	spared.ground_pos = at
	var asked: Array = []
	spared.deathless = func(who: Person, kind: StringName) -> bool:
		asked.append([who, kind])
		return true
	var n0 := crowd.killed_citizens
	var alarm0 := crowd.alarm
	var died := field.kill(spared, &"frenzy", at)
	t.check(not died and spared.is_alive() and spared.is_down(), "a spared death leaves them alive and knocked down")
	t.check(crowd.killed_citizens == n0 and rem.all().is_empty() and is_equal_approx(crowd.alarm, alarm0),
		"nothing else happens: no kill counted, no remain, no alarm")
	t.check(asked.size() == 1 and asked[0][0] == spared and asked[0][1] == &"frenzy", "the callable is asked with (person, kind)")
	# Struck dead by a blow: the same fall.
	spared.health = 0.0
	spared.hurt(1.0, crowd.citizens[1])
	t.check(spared.is_alive() and crowd.killed_citizens == n0, "a blow that would kill is caught too")

	# The kinds it never catches (the rite counts its shard, so it must not be cancelled).
	for kind in [&"pit", &"gone", &"rite"]:
		var q: Person = crowd.citizens[{&"pit": 2, &"gone": 3, &"rite": 7}[kind]]
		q.ground_pos = at + Vector2(1.0, 0.0)
		var asks := [0]
		q.deathless = func(_w: Person, _k: StringName) -> bool:
			asks[0] += 1
			return true
		field.kill(q, kind, at)
		t.check(not q.is_alive() and asks[0] == 0, "%s is never caught" % kind)

	# False lets it happen.
	var no: Person = crowd.citizens[4]
	no.ground_pos = at + Vector2(2.0, 0.0)
	no.deathless = func(_w: Person, _k: StringName) -> bool: return false
	t.check(field.kill(no, &"frenzy", at) and not no.is_alive(), "a callable that says false lets the death happen")
	# Empty changes nothing.
	var plain: Person = crowd.citizens[5]
	plain.ground_pos = at + Vector2(3.0, 0.0)
	var n1 := crowd.killed_citizens
	t.check(field.kill(plain, &"frenzy", at) and not plain.is_alive() and crowd.killed_citizens == n1 + 1, "an empty callable changes nothing")
	rem.enabled = false
	_done(made)


## --bench-level parsing, and Remain.design (the owner's to rewrite: Borrowed Life).
static func _bench_level(t) -> void:
	t.check(Mission.bench_level_arg(PackedStringArray(["--bench", "--bench-cast=pale", "--bench-level=5"])) == 5, "--bench-level=5 parses")
	t.check(Mission.bench_level_arg(PackedStringArray(["--bench-cast=pale"])) == 1, "no --bench-level means level 1")
	t.check(Mission.bench_level_arg(PackedStringArray(["--bench-level=9"])) == PowerBook.MAX_LEVEL
		and Mission.bench_level_arg(PackedStringArray(["--bench-level=0"])) == 1, "--bench-level is held to 1-5")
	var made := _setup()
	var crowd: Crowd = made[0]
	var rem := crowd.remains
	rem.enabled = true
	var p: Person = crowd.citizens[0]
	p.ground_pos = Vector2(6.0, 6.0)
	(made[2] as EnemyField).kill(p, &"deathmark", p.ground_pos)
	var r := rem.pick(p.ground_pos)
	r.design = "rewritten"
	t.check(rem.pick(p.ground_pos).design == "rewritten", "a Remain's design can be rewritten by its owner")
	rem.enabled = false
	_done(made)
