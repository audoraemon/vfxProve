extends RefCounted
## v0.05 difficulty: the tiers' Defense Profiles, the save remembering the choice, the Prepare screen's selector,
## and the fire brigade and bell following the profile.


static func run(t) -> void:
	var u := ResponseProfile.for_tier(ResponseProfile.Tier.UNPREPARED)
	var o := ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)
	var p := ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	var g := ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT)
	t.check(not u.bell and u.fire_crew == 2 and u.fire_from == AlarmManager.Stage.CITY_EMERGENCY,
		"Unprepared: no bell, a late and small fire brigade")
	t.check(o.bell and o.fire_crew == 4 and o.engineer_teams == 0 and not o.boats and not o.rite,
		"Organized: the bell and the fire brigade only")
	t.check(p.engineer_teams == 2 and p.boats and p.rite, "Prepared: engineers, boats and the rite too")
	t.check(g.bell_climb < p.bell_climb and g.rite_time < p.rite_time and g.engineer_teams > p.engineer_teams
		and g.fire_crew > p.fire_crew, "God-Resistant: all of it, faster")
	# v0.08.2: God-Resistant is clearly harder than Prepared -- bigger boats, a quicker postern, more clergy -- and
	# every other tier keeps the numbers it had.
	t.check(g.boat_load == 10 and is_equal_approx(g.postern_interval, 1.5) and g.rite_clergy == 6
		and is_equal_approx(g.regroup_seconds, 8.0),
		"God-Resistant: boats of 10, a postern every 1.5 s, six clergy for the rite, the evacuation 8 s after City Emergency")
	var kept := true
	for x in [u, o, p]:
		kept = kept and x.boat_load == RiverFerry.LOAD and x.postern_interval == Crowd.POSTERN_INTERVAL \
			and x.rite_clergy == BanishingRite.CALL and x.regroup_seconds == AlarmManager.REGROUP_SECONDS
	t.check(kept and is_equal_approx(p.rite_time, 45.0) and p.engineer_teams == 2,
		"Unprepared, Organized and Prepared keep boats of 6, a 3-s postern, four clergy and 15 s to regroup")
	t.check(g.lines().has("River Boats x10") and g.lines().has("Banishing Rite x6, 35 s")
		and p.lines().has("River Boats x6") and p.lines().has("Banishing Rite x4, 45 s"),
		"the Defense Profile shows the boats and the clergy (%s)" % [g.lines()])
	var widest := 0.0
	for tier in ResponseProfile.Tier.values():
		widest = maxf(widest, PrepareScreen.PROFILE_LEFT + UiTheme.width("DEFENSE PROFILE", UiTheme.SIZE_SMALL) + 8.0
			+ UiTheme.width(ResponseProfile.for_tier(tier).blurb(), UiTheme.SIZE_SMALL))
	t.check(widest <= PrepareScreen.PROFILE_RIGHT, "every tier's blurb fits beside its label (%.1f)" % widest)
	t.check([u.marshals_per_exit, o.marshals_per_exit, p.marshals_per_exit, g.marshals_per_exit] == [2, 3, 4, 5]
		and [u.escorts_per_duty, o.escorts_per_duty, p.escorts_per_duty, g.escorts_per_duty] == [1, 1, 2, 2]
		and [u.rescue_squads, o.rescue_squads, p.rescue_squads, g.rescue_squads] == [2, 3, 4, 5],
		"the soldiers' roles grow with the tier (v0.07)")
	# Every line of every tier's Defense Profile fits the strip on the Prepare screen.
	var worst := 0.0
	for tier in ResponseProfile.Tier.values():
		var lines := ResponseProfile.for_tier(tier).lines()
		var cols := PrepareScreen.profile_columns(lines, PrepareScreen.PROFILE_LEFT, PrepareScreen.PROFILE_RIGHT)
		for i in lines.size():
			worst = maxf(worst, cols[i % 3] + UiTheme.width(lines[i], UiTheme.SIZE_SMALL))
	t.check(worst > 0.0 and worst <= PrepareScreen.PROFILE_RIGHT + 0.01 and PrepareScreen.PROFILE_RIGHT < PrepareScreen.STRIP.end.x,
		"every Defense Profile line fits the Prepare strip (rightmost edge %.1f of %.1f)" % [worst, PrepareScreen.STRIP.end.x])
	t.check(ResponseProfile.DEFAULT == ResponseProfile.Tier.ORGANIZED and ResponseProfile.tier_named("prepared")
		== ResponseProfile.Tier.PREPARED and ResponseProfile.tier_named("nonsense") == ResponseProfile.DEFAULT,
		"Organized by default; named tiers from the command line")
	t.check(u.lines().size() == 3 and p.lines().size() == 6, "the Defense Profile lists each response (%s)" % [p.lines()])

	# The Warning's town (v0.08): Organized's bell and fire brigade, marshals and rescue squads, but no escorts.
	var w := ResponseProfile.unaware()
	t.check(w.bell and is_equal_approx(w.bell_climb, 8.0) and w.fire_crew == o.fire_crew and w.fire_from == o.fire_from
		and w.engineer_teams == 0 and not w.boats and not w.rite,
		"Unaware: a bell with an 8 s climb and Organized's fire brigade")
	t.check(w.escorts_per_duty == 0 and w.marshals_per_exit == o.marshals_per_exit and w.rescue_squads == o.rescue_squads,
		"Unaware: no escorts; marshals and rescue squads as at Organized")
	t.check(w.tier_name() == "Unaware" and o.tier_name() == "Organized" and w.lines().size() == o.lines().size(),
		"Unaware has its own name and a Defense Profile (%s)" % [w.lines()])
	var wm := MissionDef.new()
	wm.profile = "unaware"
	t.check(wm.response_profile(ResponseProfile.Tier.GOD_RESISTANT).tier_name() == "Unaware"
		and MissionDef.new().response_profile(ResponseProfile.Tier.PREPARED).tier == ResponseProfile.Tier.PREPARED,
		"a mission's own profile overrides the chosen difficulty; otherwise the choice holds")

	# The save remembers the difficulty.
	var path := "user://test_profile_save.cfg"
	var save := SaveFile.new()
	save.difficulty = ResponseProfile.Tier.GOD_RESISTANT
	save.save_to(path)
	t.check(SaveFile.new().load_from(path).difficulty == ResponseProfile.Tier.GOD_RESISTANT, "the save keeps the difficulty")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	t.check(SaveFile.new().load_from(path).difficulty == ResponseProfile.DEFAULT, "a fresh save starts Organized")

	# The Prepare screen's selector steps through the tiers, wrapping.
	var prep := PrepareScreen.new()
	prep.difficulty = ResponseProfile.Tier.UNPREPARED
	prep.step_difficulty(-1)
	t.check(prep.difficulty == ResponseProfile.Tier.GOD_RESISTANT, "stepping left from Unprepared wraps to God-Resistant")
	prep.step_difficulty(1)
	prep.step_difficulty(1)
	t.check(prep.difficulty == ResponseProfile.Tier.ORGANIZED, "and right steps back up")
	t.check(prep.hit(PrepareScreen.arrow_rect(1).get_center()) == "diff_next"
		and prep.hit(PrepareScreen.arrow_rect(-1).get_center()) == "diff_prev", "the arrows can be clicked")
	prep.free()

	# The town follows the profile: an Unprepared town rings no bell.
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = u
	crowd.spawn()
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	t.check(crowd.alarms.stage == AlarmManager.Stage.CITY_EMERGENCY and crowd.bell.state == BellNetwork.State.SILENCED
		and crowd.bell.keeper == null, "an Unprepared town reaches City Emergency with nobody to ring a bell")
	crowd.clear()
	world.free()

	# v0.08.2: the town follows God-Resistant's numbers, and Prepared's stay as they were.
	for tier in [ResponseProfile.Tier.PREPARED, ResponseProfile.Tier.GOD_RESISTANT]:
		env = EnvironmentField.new()
		town = Town.new()
		town.build(env)
		grid = WalkGrid.new().setup(env, town)
		field = EnemyField.new()
		field.env = env
		field.bounds = TownLayout.MAP
		world = Node2D.new()
		crowd = Crowd.new().setup(field, env, town, grid, world, 5)
		crowd.profile = ResponseProfile.for_tier(tier)
		crowd.spawn()
		var want := crowd.profile.rite_clergy
		var gr: bool = tier == ResponseProfile.Tier.GOD_RESISTANT
		t.check(crowd.rite.places.size() == want and crowd.rite.living_clergy() >= want
			and crowd.ferry.capacity == crowd.profile.boat_load,
			"%s: %d clergy and %d places on the steps, boats of %d" % [crowd.profile.tier_name(), crowd.rite.living_clergy(),
				crowd.rite.places.size(), crowd.ferry.capacity])
		if not gr:
			# The ring's four places as before v0.08.2: centre-out, k = 1, 2, 0, 3.
			var c := crowd.rite.centre
			var first := c + Vector2(-0.5 * BanishingRite.PLACE_GAP, -0.1)
			t.check(crowd.rite.places[0] == (first if grid.walkable(first) else grid.nearest_walkable(first)),
				"Prepared's ring keeps its places")
		crowd.add_alarm(AlarmManager.CITY_ALARM)
		crowd.advance(0.1)
		t.check(crowd.rite.circle.size() == want, "%s: the rite calls %d clergy" % [crowd.profile.tier_name(), want])
		t.check(crowd.alarms.regroup_seconds == crowd.profile.regroup_seconds,
			"%s: the evacuation waits %.0f s after City Emergency" % [crowd.profile.tier_name(), crowd.alarms.regroup_seconds])
		crowd.clear()
		world.free()
