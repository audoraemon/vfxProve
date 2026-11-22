extends RefCounted
## The crowd's voices: a panic is heard from the few people nearest the blow, a town-wide budget stops a
## crowd drowning the powers, the budget refills, and every crowd cue exists.


static func run(t) -> void:
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

	# Gather a crowd around one spot and frighten it: only the nearest few cry out.
	for i in 30:
		crowd.citizens[i].ground_pos = Vector2(float(i % 6) * 0.3, float(i / 6) * 0.3)
	crowd.on_cast(Vector2(0.8, 0.6))
	var heard := crowd.voices_played
	t.check(heard >= 1 and heard <= Crowd.VOICES_PER_CAST, "thirty frightened people are heard as a few voices (%d)" % heard)

	# The budget itself: however many voices ask at once, no more than it holds. (Casting again at the same
	# spot would not test this -- everyone there is already panicking, so nobody new cries out.)
	for i in 10:
		crowd._voice(crowd.citizens[40], &"cit_shout")
	t.check(crowd.voices_played <= int(Crowd.VOICE_BUDGET),
		"ten more voices at once stop at the budget (%d of %d)" % [crowd.voices_played, int(Crowd.VOICE_BUDGET)])
	var spent := crowd.voices_played
	crowd.advance(1.0)
	crowd._voice(crowd.citizens[40], &"cit_shout")
	t.check(crowd.voices_played == spent + 1, "a second later the budget has refilled (%d -> %d)" % [spent, crowd.voices_played])

	var missing := ""
	for cue: StringName in [&"cit_yelp", &"cit_shout", &"cit_scream", &"sol_rally"]:
		if not Sfx.CATALOG.has(cue):
			missing += " %s" % cue
	t.check(missing == "", "every crowd cue is in the catalog (missing:%s)" % missing)
	t.check(ResourceLoader.exists("res://assets/audio/citizen/cit_yelp_4.wav") and ResourceLoader.exists("res://assets/audio/citizen/sol_rally.wav")
		and ResourceLoader.exists("res://assets/audio/citizen/cit_scream_3.wav"),
		"and on disk")

	# The bed: silent with nobody running, full at BED_FULL, never louder.
	t.check(Crowd.bed_level_for(0) == 0.0, "nobody running, no crowd noise")
	t.near(Crowd.bed_level_for(int(Crowd.BED_FULL / 2.0)), 0.5, 0.001, "half the full crowd, half the level")
	t.check(Crowd.bed_level_for(500) == 1.0, "and a stampede is no louder than full")
	t.check(Sfx.CATALOG.has(&"crowd_panic") and bool(Sfx.CATALOG[&"crowd_panic"].get("loop", false))
		and ResourceLoader.exists("res://assets/audio/citizen/crowd_panic.wav"), "the crowd bed is a loop in the catalog and on disk")

	# The music: the theme, the town's calm pieces, and the battle's three stems and the tension stem, all four the same
	# length so they stay in step.
	var lengths: Array[float] = []
	for cue: StringName in [&"music_theme", &"music_battle_base", &"music_battle_drums", &"music_battle_lead", Music.TENSION]:
		var stream := Sfx.load_stream(cue) if Sfx.CATALOG.has(cue) else null
		lengths.append(stream.get_length() if stream != null else -1.0)
	t.check(lengths[0] > 20.0, "the theme is a long loop (%.1f s)" % lengths[0])
	t.check(lengths[1] > 0.0 and is_equal_approx(lengths[1], lengths[2]) and is_equal_approx(lengths[1], lengths[3])
		and is_equal_approx(lengths[1], lengths[4]), "the battle's three stems and the tension stem are the same length (%s)" % [lengths])
	for cue: StringName in Music.CALM:
		var s := Sfx.load_stream(cue) if Sfx.CATALOG.has(cue) else null
		t.check(s != null and s.get_length() > 30.0 and bool(Sfx.CATALOG[cue].get("loop", false)), "%s is a long loop" % cue)
	t.check(Music.calm_cue(false, false) == &"music_town_day" and Music.calm_cue(true, false) == &"music_town_night"
		and Music.calm_cue(false, true) == &"music_capital_day" and Music.calm_cue(true, true) == &"music_town_night",
		"the calm piece: the town by day, by night (the Capital's too), the Capital's own by day")

	# Music by situation: panic and the alarm heat the music before a building falls; it cools slowly; a chase has its own
	# two stems in step; a festival and a rite play their own calm piece.
	t.check(Music.heat(0.0, AlarmManager.Stage.NORMAL, 0.0) == 0.0, "a quiet town is calm")
	t.check(Music.heat(0.0, AlarmManager.Stage.NORMAL, 0.4) > 0.22 and Music.stem_gains(Music.heat(0.0, 0, 0.4))[0] > 0.0,
		"a cast that sets people running brings the tension and the battle's base in, the city still standing")
	t.check(Music.heat(0.0, AlarmManager.Stage.CITY_EMERGENCY, 0.0) >= 0.33, "a City Emergency brings the drums in")
	t.check(Music.heat(0.9, AlarmManager.Stage.NORMAL, 0.0) == 0.9 and Music.heat(0.0, AlarmManager.Stage.COLLAPSE, 0.0) == 1.0,
		"the city's fall and its collapse still lead")
	t.check(Music.cool(0.2, 0.6, 0.5) == 0.6 and is_equal_approx(Music.cool(0.6, 0.0, 10.0), 0.6 - 10.0 * Music.COOL_RATE)
		and Music.cool(0.6, 0.0, 100.0) == 0.0, "the heat rises at once and cools slowly")
	t.check(Music.chasing(&"chase", 0.3) and not Music.chasing(&"chase", Music.CHASE_UNTIL) and not Music.chasing(&"", 0.0),
		"the chase plays while a pursuit is on, until the city is falling")
	var chase_len: Array[float] = []
	for cue: StringName in Music.CHASE:
		var cs := Sfx.load_stream(cue) if Sfx.CATALOG.has(cue) else null
		chase_len.append(cs.get_length() if cs != null else -1.0)
	t.check(chase_len[0] > 20.0 and is_equal_approx(chase_len[0], chase_len[1]), "the chase's two stems are one length (%s)" % [chase_len])
	t.check(Music.calm_cue(true, false, &"festival") == &"music_calm_festival" and Music.calm_cue(false, true, &"rite") == &"music_calm_rite"
		and Music.calm_cue(false, false, &"chase") == &"music_town_day", "a festival and a rite play their own calm piece")
	t.check(FestivalDirector.new().music_mood() == &"festival" and MarketPanicDirector.new().music_mood() == &""
		and RiteDirector.new().music_mood() == &"rite" and SermonDirector.new().music_mood() == &"rite"
		and RelicRunDirector.new().music_mood() == &"" and MissionDirector.new().music_mood() == &"",
		"the festival dances, the rites chant, the market and the relic's road keep the town's own")
	t.check(HuntDirector.new().music_mood() == &"" and EscortDirector.new().music_mood() == &""
		and WarningDirector.new().music_mood() == &"" and AssassinateDirector.new().music_mood() == &"",
		"a pursuit mission is calm until its chase is on")

	# God's Paths: the temple piece, and over it one layer per school whose length divides the piece's, so every layer
	# stays in step with it; only the picked god's layer sounds, and none away from the god select.
	var base := Sfx.load_stream(Music.PATHS) if Sfx.CATALOG.has(Music.PATHS) else null
	t.check(base != null and base.get_length() > 30.0 and bool(Sfx.CATALOG[Music.PATHS].get("loop", false)), "the paths piece is a long loop")
	for type: String in GodTree.RING:
		var cue: StringName = Music.PATH_LAYERS.get(type, &"")
		var s := Sfx.load_stream(cue) if Sfx.CATALOG.has(cue) else null
		var fits := s != null and base != null and bool(Sfx.CATALOG[cue].get("loop", false)) \
			and int(round(base.get_length() * 44100.0)) % int(round(s.get_length() * 44100.0)) == 0
		t.check(fits, "%s has its paths layer %s, a loop that divides the piece (%s)" % [type, cue, s.get_length() if s != null else -1.0])
	var on := Music.layer_gains(&"paths", "death")
	t.check(on["death"] == 1.0 and on.values().count(1.0) == 1, "on God's Paths only the picked god's layer plays (%s)" % [on])
	t.check(Music.layer_gains(&"theme", "death").values().count(0.0) == GodTree.RING.size(), "and none plays away from it")

	# The layers: a standing city hears its calm piece only; as it slips the tension comes in and the calm goes; then
	# the battle's base, the drums from a third of the way down, the lead from two thirds.
	var calm := Music.stem_gains(0.0)
	var half := Music.stem_gains(0.5)
	var falling := Music.stem_gains(1.0)
	t.check(calm == [0.0, 0.0, 0.0] and Music.calm_gain(0.0) == 1.0 and Music.tension_gain(0.0) == 0.0,
		"a standing city hears its calm piece and no battle (%s)" % [calm])
	t.check(Music.tension_gain(0.2) > 0.5 and Music.calm_gain(0.2) < 0.5 and Music.stem_gains(0.2)[0] == 0.0,
		"a city starting to slip: the tension over a fading calm, no battle yet")
	t.check(Music.calm_gain(0.33) == 0.0 and Music.tension_gain(0.33) == 1.0 and is_equal_approx(Music.stem_gains(0.33)[0], 1.0),
		"a third of the way down: the calm gone, the battle's base in over the tension")
	# is_equal_approx(), not ==: (0.5 - 0.33) / 0.17 lands at 0.9999999999999999 in double precision, a hair
	# under the clamp's ceiling, so it never hits the exact 1.0 that clamping an out-of-range value would give.
	t.check(is_equal_approx(half[1], 1.0) and half[2] == 0.0, "half fallen adds the drums (%s)" % [half])
	t.check(falling[0] == 1.0 and falling[1] == 1.0 and falling[2] == 1.0, "and a city falling hears all three (%s)" % [falling])

	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
