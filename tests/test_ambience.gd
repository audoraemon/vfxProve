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
	sfx.follow(&"jg_crumble", Vector2.ZERO)
	sfx.follow(&"hs_fissure", Vector2.ONE)
	t.check(sfx._after.size() == 1 and sfx._after[0][1] == &"debris_big", "a big hit's debris is queued once, not twice at once")
	sfx._clock += Sfx.AFTER_REST
	sfx.follow(&"cf_impact", Vector2.ZERO)
	t.check(sfx._after.size() == 2 and sfx._after[1][1] == &"debris_small", "a barrage's impact gets its own patter")
	for cue: StringName in Sfx.AFTERMATH:
		t.check(Sfx.CATALOG.has(cue) and Sfx.CATALOG.has(Sfx.AFTERMATH[cue][0]), "%s has an aftermath in the catalog" % cue)
	sfx.free()
	t.check(not Sfx.DUCKS.has(&"cit_yelp") and Sfx.DUCKS.has(&"nova_boom"), "only big hits duck")

	# Animals (pass 5): a dog barks, a cat meows; a breed has its own pitch; a pack cannot drown the town.
	for cue: StringName in [&"dog_bark", &"dog_growl", &"dog_yelp", &"cat_meow", &"cat_hiss", &"cat_yowl"]:
		t.check(Sfx.paths_for(cue).size() >= 3, "%s has at least three takes" % cue)
	t.check(Sfx.paths_for(&"dog_bark").size() == 10 and Sfx.paths_for(&"cat_meow").size() == 8, "ten barks, eight meows")
	var all_pitched := true
	for b in Animal.DOGS + Animal.CATS:
		all_pitched = all_pitched and AnimalVoices.PITCH.has(b)
	t.check(all_pitched, "every town breed has its own voice (a visitor such as a hellhound speaks at 1.0)")
	t.check(float(AnimalVoices.PITCH[Animal.Breed.WOLFHOUND]) < 1.0 and float(AnimalVoices.PITCH[Animal.Breed.TERRIER]) > 1.0,
		"a wolfhound is low, a terrier high")
	var av := AnimalVoices.new()
	t.check(av.pick(1, true, AnimalVoices.Act.DIE) == &"dog_yelp" and av.pick(2, false, AnimalVoices.Act.DIE) == &"cat_yowl",
		"a dying dog yelps, a dying cat yowls")
	t.check(av.pick(1, true, AnimalVoices.Act.ANGRY) == &"", "an animal that just made a sound rests")
	t.check(av.pick(3, true, AnimalVoices.Act.ANGRY) == &"dog_growl" and av.pick(4, false, AnimalVoices.Act.ANGRY) == &"cat_yowl",
		"a turned dog growls, a turned cat yowls")
	t.check(av.pick(5, true, AnimalVoices.Act.DIE) == &"", "the budget is spent after four")
	av.step(2.0)
	t.check(av.pick(6, true, AnimalVoices.Act.CALL) == &"dog_bark" and av.pick(7, false, AnimalVoices.Act.CALL) == &"cat_meow",
		"a call near the camera is always heard: a bark or a meow")
	# Fire where it burns (pass 6): louder as it grows; a bucket is heard.
	t.check(FireSounds.voice_db(0.0) < FireSounds.voice_db(0.5) and FireSounds.voice_db(0.5) < FireSounds.voice_db(1.0),
		"a burning building gets louder as its fire grows")
	t.check(FireSounds.doused(0.6, 0.45) and not FireSounds.doused(0.6, 0.62), "a bucket's drop is a douse, growth is not")
	for cue: StringName in [&"fire_catch", &"fire_crack", &"fire_douse"]:
		t.check(Sfx.paths_for(cue).size() >= 3, "%s has takes" % cue)
	t.check(bool(Sfx.CATALOG[&"fire_burn"].get("loop", false)) and Sfx.paths_for(&"fire_burn").size() == 2, "two burning loops")
	t.check(Ambience.ANIMAL_DAY.y <= 15.0 and Ambience.ANIMAL_NIGHT.y <= 18.0, "a dog or cat calls every few seconds, day and night")
	av.step(1.0)
	t.check(av.pick(5, true, AnimalVoices.Act.DIE) == &"dog_yelp", "and it refills")
	var idle := 0
	var av2 := AnimalVoices.new()
	for i in 200:
		av2.step(1.0)
		if av2.pick(100 + i, false, AnimalVoices.Act.IDLE) == &"cat_meow":
			idle += 1
	t.check(idle > 100 and idle < 180, "a cat at rest meows most of the time, not always (%d of 200)" % idle)

	# Soldiers (pass 5): a soldier's blow is a spear, anyone else's a fist; orders rest; the horn; the march.
	var sv := SoldierVoices.new()
	t.check(sv.blow(true, 0.0) == &"sol_strike" and sv.blow(false, 0.0) == &"cit_blow", "a spear for a soldier, a fist for the rest")
	for i in 3:
		sv.blow(true, 0.0)
	t.check(sv.blow(true, 0.0) == &"", "a brawl spends the blow budget")
	t.check(sv.blow(true, 0.5) == &"sol_strike", "and it refills")
	t.check(sv.order(10.0) and not sv.order(12.0) and sv.order(14.5), "an order at most every few seconds")
	t.check(sv.order(1.0), "and a restarted clock may shout again")
	var field := EnemyField.new()
	var struck := Person.new()
	struck.field = field
	var blows_heard := []
	field.enemy_struck.connect(func(e: DummyEnemy, by: DummyEnemy) -> void: blows_heard.append([e, by]))
	struck.hurt(0.1, null)
	t.check(blows_heard.size() == 1 and blows_heard[0][0] == struck, "a blow that lands is heard by the field")
	struck.free()
	field.free()
	for cue: StringName in [&"sol_step", &"sol_strike", &"cit_blow", &"sol_order", &"town_horn"]:
		t.check(Sfx.CATALOG.has(cue), "%s is in the catalog" % cue)
	t.check(Ambience.marching(0.1, Ambience.MARCH_EVERY) and not Ambience.marching(0.01, Ambience.MARCH_EVERY)
		and not Ambience.marching(0.1, 0.0), "a walking soldier marches, one at its post does not")
	t.check(not Ambience.march_heard(AlarmManager.Stage.NORMAL) and Ambience.march_heard(AlarmManager.Stage.CONCERN),
		"a calm town's patrols are silent; the march is heard once the alarm rises")
