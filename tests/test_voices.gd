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
	for cue: StringName in [&"cit_yelp", &"cit_shout", &"sol_rally"]:
		if not Sfx.CATALOG.has(cue):
			missing += " %s" % cue
	t.check(missing == "", "every crowd cue is in the catalog (missing:%s)" % missing)
	t.check(ResourceLoader.exists("res://assets/audio/crowd/cit_yelp_4.wav") and ResourceLoader.exists("res://assets/audio/crowd/sol_rally.wav"),
		"and on disk")

	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
