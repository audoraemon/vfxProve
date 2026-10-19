extends RefCounted
## v0.11.2 death sounds (spec 2.2): every kill asks DeathVoices for a cue; a mass kill is one wave; and none of it touches the
## simulation (review focus 3).


## A stand-in for the battlefield's Sfx that writes down what it was asked to play.
class Rec extends Node:
	var played: Array = []

	func play(cue: StringName, at: Vector2, _db := 0.0) -> Variant:
		played.append([cue, at])
		return null

	## What was played that is a death (a frightened neighbour's yelp is not).
	func deaths() -> Array:
		return played.filter(func(c: Array) -> bool: return [&"cit_death", &"cit_fall", &"sol_death", &"crowd_death_wave"].has(c[0]))


## A DeathVoices that is never heard: the control for _no_draws.
class Deaf extends DeathVoices:
	func heard(_at: Vector2, _kind: StringName, _soldier: bool, _now: float) -> Array:
		return []


static func run(t) -> void:
	_one(t)
	_quiet(t)
	_wave(t)
	_rate(t)
	_reset(t)
	_crowd_plays(t)
	_no_draws(t)
	_cues_exist(t)


static func _count(cues: Array, cue: StringName) -> int:
	var n := 0
	for c: Array in cues:
		if c[0] == cue:
			n += 1
	return n


static func _one(t) -> void:
	var d := DeathVoices.new()
	var at := Vector2(3.0, 4.0)
	var got := d.heard(at, &"lightning", false, 0.0)
	t.check(got.size() == 1 and got[0][0] == &"cit_death" and got[0][1] == at, "a citizen's death is a cit_death at the body (%s)" % [got])
	got = d.heard(at, &"lightning", true, 1.0)
	t.check(got.size() == 1 and got[0][0] == &"sol_death", "a soldier's is a sol_death (%s)" % [got])
	t.check(d.voiced == 2 and d.waves == 0, "two voiced, no wave (%d, %d)" % [d.voiced, d.waves])


static func _quiet(t) -> void:
	for kind: StringName in DeathVoices.QUIET_KINDS:
		for soldier in [false, true]:
			var d := DeathVoices.new()
			var got := d.heard(Vector2.ONE, kind, soldier, 0.0)
			t.check(got.size() == 1 and got[0][0] == &"cit_fall", "%s (soldier %s) slumps, no cry (%s)" % [kind, soldier, got])
	t.check(DeathVoices.QUIET_KINDS == [&"doom", &"deathmark", &"plague"], "the quiet kinds are Doom, the Death Mark and the plague")
	# A quiet mass never roars: it is not a thing the town hears.
	var d := DeathVoices.new()
	var all := []
	for i in 30:
		all.append_array(d.heard(Vector2(float(i), 0.0), &"doom", false, 0.1))
	t.check(_count(all, &"crowd_death_wave") == 0 and d.waves == 0, "thirty quiet deaths make no roar")
	t.check(_count(all, &"cit_fall") <= DeathVoices.WAVE_VOICES, "and at most %d falls" % DeathVoices.WAVE_VOICES)


static func _wave(t) -> void:
	var d := DeathVoices.new()
	var all := []
	for i in 60:
		all.append_array(d.heard(Vector2(float(i % 10), float(i / 10)), &"nova", false, float(i) * 0.2 / 60.0))
	t.check(all.size() <= DeathVoices.WAVE_VOICES + 1, "sixty deaths in one wave are at most %d cues (%d)" % [DeathVoices.WAVE_VOICES + 1, all.size()])
	t.check(_count(all, &"crowd_death_wave") == 1, "exactly one crowd_death_wave (%d)" % _count(all, &"crowd_death_wave"))
	t.check(_count(all, &"cit_death") == DeathVoices.WAVE_VOICES, "and %d cries (%d)" % [DeathVoices.WAVE_VOICES, _count(all, &"cit_death")])
	t.check(d.waves == 1 and d.voiced == DeathVoices.WAVE_VOICES, "counted: one wave, %d voiced (%d, %d)" % [DeathVoices.WAVE_VOICES, d.waves, d.voiced])
	# The roar is at the mean of the deaths up to the MASS_AT-th.
	var d2 := DeathVoices.new()
	var roar := []
	for i in DeathVoices.MASS_AT:
		roar.append_array(d2.heard(Vector2(float(i), 0.0), &"nova", false, 0.0))
	var want := Vector2((DeathVoices.MASS_AT - 1) / 2.0, 0.0)
	t.check(roar.size() > 0 and roar[roar.size() - 1][0] == &"crowd_death_wave" and (roar[roar.size() - 1][1] as Vector2).is_equal_approx(want),
		"the roar plays at the MASS_AT-th death, at the mean of the deaths so far (%s)" % [roar])
	t.check(DeathVoices.MASS_AT == 6 and DeathVoices.WAVE_WINDOW == 0.25 and DeathVoices.TOKENS == 4.0 and DeathVoices.REFILL == 3.0, "the spec's numbers")
	# Inside the window a late death still belongs to the wave; after it a death is a new wave.
	var d3 := DeathVoices.new()
	var first := d3.heard(Vector2.ZERO, &"nova", false, 0.0)
	var in_wave := d3.heard(Vector2.ZERO, &"nova", false, DeathVoices.WAVE_WINDOW)
	t.check(first.size() == 1 and in_wave.size() == 1, "inside the window the wave still has voices")
	for i in 4:
		d3.heard(Vector2.ZERO, &"nova", false, 0.1)
	d3.step(1.0)
	var later := d3.heard(Vector2.ZERO, &"nova", false, 5.0)
	t.check(later.size() == 1, "a death 5 s later is a new wave and is voiced (%s)" % [later])


static func _rate(t) -> void:
	# Three waves of three, 0.3 s apart, no refill: 4 tokens -- the first wave takes 3, the second the last, the third none.
	var d := DeathVoices.new()
	var per_wave := []
	for w in 3:
		var n := 0
		for i in 3:
			n += d.heard(Vector2(float(i), 0.0), &"lightning", false, 0.3 * w).size()
		per_wave.append(n)
	t.check(per_wave == [3, 1, 0], "the token budget caps the third wave (%s)" % [per_wave])
	d.step(1.0)
	t.check(d.heard(Vector2.ZERO, &"lightning", false, 0.9).size() == 1, "a second of refill voices one again")
	d.step(100.0)
	var burst := 0
	for i in 10:
		burst += d.heard(Vector2.ZERO, &"lightning", false, 5.0 + float(i) * 0.3).size()
	t.check(burst == int(DeathVoices.TOKENS), "the budget never holds more than TOKENS (%d)" % burst)


static func _reset(t) -> void:
	var d := DeathVoices.new()
	for i in 10:
		d.heard(Vector2.ZERO, &"nova", false, 0.0)
	d.reset()
	t.check(d.voiced == 0 and d.waves == 0 and d.heard(Vector2.ZERO, &"nova", false, 0.0).size() == 1, "reset() forgets the wave, the counts and the spent budget")


static func _world(seed_: int) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, seed_)
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _crowd_plays(t) -> void:
	var s := _world(5)
	var crowd: Crowd = s.crowd
	var field: EnemyField = s.field
	var rec := Rec.new()
	crowd.sfx = rec
	var c: Person = crowd.citizens[0]
	field.kill(c, &"lightning")
	t.check(rec.deaths().size() == 1 and rec.deaths()[0][0] == &"cit_death" and (rec.deaths()[0][1] as Vector2).is_equal_approx(c.ground_pos),
		"Crowd plays a citizen's cry at the body (%s)" % [rec.deaths()])
	rec.played.clear()
	crowd.advance(1.0)
	if not crowd.soldiers.is_empty():
		field.kill(crowd.soldiers[0], &"lightning")
		t.check(rec.deaths().size() == 1 and rec.deaths()[0][0] == &"sol_death", "and a soldier's grunt (%s)" % [rec.deaths()])
	rec.played.clear()
	crowd.advance(1.0)
	field.kill(crowd.citizens[1], &"doom")
	t.check(rec.deaths().size() == 1 and rec.deaths()[0][0] == &"cit_fall", "a Silent Doom death is a fall, no cry (%s)" % [rec.deaths()])
	rec.played.clear()
	crowd.advance(1.0)
	crowd.hush(5.0)
	field.kill(crowd.citizens[2], &"lightning")
	t.check(rec.deaths().size() == 1 and rec.deaths()[0][0] == &"cit_fall", "in a hushed town a death is a fall too (%s)" % [rec.deaths()])
	crowd.clear()
	t.check(crowd.deaths.voiced == 0 and crowd.deaths.waves == 0, "clear() resets the deaths")
	rec.free()
	_done(s)


## Review focus 3: sixty bodies fall in one frame with and without anyone listening; the crowd's rng and every person's rng
## end in the same state.
static func _no_draws(t) -> void:
	var states := []
	var counts := []
	for deaf in [false, true]:
		var s := _world(11)
		var crowd: Crowd = s.crowd
		if deaf:
			crowd.deaths = Deaf.new()
		var rec := Rec.new()
		crowd.sfx = rec
		var victims := crowd.citizens.slice(0, 60)
		for p: Person in victims:
			(s.field as EnemyField).kill(p, &"nova")
		var rngs := [crowd._rng.state]
		for p: Person in crowd.citizens + crowd.soldiers:
			if is_instance_valid(p):
				rngs.append(p.rng.state)
		states.append(rngs)
		counts.append([victims.size(), crowd.deaths.waves, rec.deaths().size()])
		rec.free()
		_done(s)
	t.check(counts[0][0] == 60, "sixty citizens fell (%d)" % counts[0][0])
	t.check(states[0] == states[1], "the crowd's rng and every person's rng are what they are without DeathVoices")
	t.check(counts[0][1] == 1 and counts[0][2] == DeathVoices.WAVE_VOICES + 1 and counts[1][2] == 0,
		"and the listening world heard one wave of %d cues (waves %d, cues %d; the deaf one %d)" % [DeathVoices.WAVE_VOICES + 1, counts[0][1], counts[0][2], counts[1][2]])


static func _cues_exist(t) -> void:
	for cue: StringName in [&"cit_death", &"cit_fall", &"sol_death", &"crowd_death_wave"]:
		t.check(Sfx.CATALOG.has(cue), "%s is in the catalog" % cue)
		for path in Sfx.paths_for(cue):
			t.check(ResourceLoader.exists(path), "%s exists" % path)
	t.check(Sfx.paths_for(&"cit_death").size() == 5 and Sfx.paths_for(&"cit_fall").size() == 4 and Sfx.paths_for(&"sol_death").size() == 3
		and Sfx.paths_for(&"crowd_death_wave").size() == 2, "5, 4, 3 and 2 variants")
	var voices := {&"cit_death": 4, &"cit_fall": 3, &"sol_death": 4, &"crowd_death_wave": 2}
	for cue: StringName in voices:
		t.check(Sfx.CATALOG[cue].get("voices", 0) == voices[cue] and float(Sfx.CATALOG[cue].get("jitter", 0.0)) > 0.0, "%s has %d voices and a jitter" % [cue, voices[cue]])
