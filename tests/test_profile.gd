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
