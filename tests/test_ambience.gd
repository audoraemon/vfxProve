extends RefCounted
## Natural sound pass 2: the town's ambience beds, distance, and variants that never repeat back to back.


static func run(t) -> void:
	# The beds: the time of day's bed, dipped under panic; the fire bed by how much burns.
	var day := Ambience.targets(false, 0.0, 0.0)
	t.check(day.amb_day == 1.0 and day.amb_night == 0.0 and day.amb_fire == 0.0, "a calm day hears the day bed only (%s)" % [day])
	var night := Ambience.targets(true, 0.0, 0.0)
	t.check(night.amb_night == 1.0 and night.amb_day == 0.0, "a calm night hears the night bed only (%s)" % [night])
	var panic := Ambience.targets(false, 1.0, 0.0)
	t.check(is_equal_approx(panic.amb_day, 1.0 - Ambience.PANIC_DIP), "a panicking town dips the day bed (%s)" % [panic])
	var burning := Ambience.targets(false, 0.0, Ambience.FIRE_FULL * 0.5)
	t.check(is_equal_approx(burning.amb_fire, 0.5), "half the fire it takes, half the fire bed (%s)" % [burning])
	t.check(Ambience.targets(true, 0.0, 99.0).amb_fire == 1.0, "and a town ablaze is no louder than full")
	for cue: StringName in [&"amb_day", &"amb_night", &"amb_fire"]:
		t.check(Sfx.CATALOG.has(cue) and bool(Sfx.CATALOG[cue].get("loop", false)), "%s is a loop in the catalog" % cue)
	t.check(Sfx.paths_for(&"amb_bird").size() == 4 and Sfx.paths_for(&"amb_night_call").size() == 3,
		"four bird calls by day, three calls by night")

	# Distance: near the screen's centre the plain SFX bus, further out duller, off screen the far bus.
	t.check(Sfx.bus_at(0.2) == Sfx.BUS and Sfx.bus_at(0.6) == Sfx.BUS_MID and Sfx.bus_at(1.3) == Sfx.BUS_FAR,
		"a sound's bus follows its distance (%s, %s, %s)" % [Sfx.bus_at(0.2), Sfx.bus_at(0.6), Sfx.bus_at(1.3)])
	for bus: StringName in [&"Ambience", Sfx.BUS_MID, Sfx.BUS_FAR]:
		var i := AudioServer.get_bus_index(bus)
		t.check(i >= 0 and AudioServer.get_bus_send(i) == Sfx.BUS, "the %s bus feeds SFX, so the Sounds slider rules it" % bus)

	# Variants: a cue with several never plays the same one twice in a row, and every one of them gets played.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var last: AudioStream = null
	var repeats := 0
	var heard := {}
	for i in 200:
		var s := Sfx.load_stream(&"cf_impact", rng)
		repeats += 1 if s == last else 0
		heard[s] = true
		last = s
	t.check(repeats == 0 and heard.size() == Sfx.paths_for(&"cf_impact").size(),
		"Cinderfall's impacts never repeat back to back, and all %d are heard (%d repeats, %d heard)" % [
			Sfx.paths_for(&"cf_impact").size(), repeats, heard.size()])
	for cue: StringName in [&"collapse_stone", &"collapse_timber", &"collapse_tree"]:
		t.check(Sfx.paths_for(cue).size() == 5, "%s has five takes" % cue)

	# The crowd in a panic (pass 3): the murmur first, the running crowd next, chaos last; cries more often the more it panics.
	var calm := Ambience.targets(false, 0.0, 0.0)
	t.check(calm.crowd_unrest == 0.0 and calm.crowd_panic == 0.0 and calm.crowd_chaos == 0.0, "a calm town hears no crowd (%s)" % [calm])
	var uneasy := Ambience.targets(false, 0.2, 0.0)
	t.check(uneasy.crowd_unrest > 0.5 and uneasy.crowd_panic < 0.1 and uneasy.crowd_chaos == 0.0,
		"a few running: mostly the murmur (%s)" % [uneasy])
	var stampede := Ambience.targets(false, 1.0, 0.0)
	t.check(stampede.crowd_panic == 1.0 and stampede.crowd_chaos == 1.0 and is_equal_approx(stampede.crowd_unrest, 1.0 - Ambience.UNREST_DIP),
		"the whole town running: the running crowd and chaos full, the murmur thinned (%s)" % [stampede])
	var rising := true
	for i in 10:
		var a := Ambience.targets(false, i / 10.0, 0.0)
		var b := Ambience.targets(false, (i + 1) / 10.0, 0.0)
		rising = rising and b.crowd_panic >= a.crowd_panic and b.crowd_chaos >= a.crowd_chaos
	t.check(rising, "the running crowd and chaos only swell as the panic rises")
	for cue: StringName in [&"crowd_unrest", &"crowd_panic", &"crowd_chaos"]:
		t.check(Sfx.CATALOG.has(cue) and bool(Sfx.CATALOG[cue].get("loop", false)), "%s is a loop in the catalog" % cue)
	t.check(Sfx.paths_for(&"crowd_cry").size() == 18, "eighteen different cries")
	t.check(Ambience.cry_gap(0.0) == INF and Ambience.cry_gap(Ambience.CRY_FROM) == Ambience.CRY_SLOW
		and is_equal_approx(Ambience.cry_gap(1.0), Ambience.CRY_FAST), "no cries in a calm town, then faster as it panics")

	# Ducking (pass 3): a big hit pulls the music and the beds down, then lets them back up; a small one does not.
	for bus: StringName in Sfx.DUCK_BUSES:
		var i := AudioServer.get_bus_index(bus)
		var found := false
		for k in AudioServer.get_bus_effect_count(i):
			found = found or AudioServer.get_bus_effect(i, k) is AudioEffectAmplify
		t.check(found, "the %s bus has the Duck effect" % bus)
	var sfx := Sfx.new()
	sfx.duck_by(-6.0)
	for i in 3:
		sfx._process(0.02)
	t.check(sfx.duck_db <= -5.9, "a big hit ducks within a few frames (%.1f dB)" % sfx.duck_db)
	sfx.duck_by(-2.0)
	t.check(sfx.duck_db <= -5.9, "and a smaller one does not lift it (%.1f dB)" % sfx.duck_db)
	for i in 200:
		sfx._process(0.02)
	t.check(sfx.duck_db == 0.0, "then it comes back up (%.1f dB)" % sfx.duck_db)
	sfx.free()
	t.check(not Sfx.DUCKS.has(&"cit_yelp") and Sfx.DUCKS.has(&"nova_boom"), "only big hits duck")
