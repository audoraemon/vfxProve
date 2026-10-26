extends RefCounted
## Ability levels (god P1, spec §5.4, §6): Might rises with a power's level, a power's `levels` table is read through
## PowerBook.stat(), the Draft and the Rules know each pick's level, and every cast carries extra["level"] on a copy of its extra.
## No POWERS row has a table in P1, so a fixture stands in for one.

## A power row with a table: radius 1.0 .. 1.5, and the level-5 twist.
const FIXTURE := {"key": "fx", "name": "Fixture", "dp": 2, "levels": [
	{"radius": 1.0}, {"radius": 1.1}, {"radius": 1.2}, {"radius": 1.3},
	{"radius": 1.5, "twist": true, "twist_text": "Jumps to the next house"}]}


static func run(t) -> void:
	_might(t)
	_no_tables(t)
	_fixture_table(t)
	_draft_levels(t)
	_cast_level(t)
	_mission_keeps(t)


static func _might(t) -> void:
	t.check(PowerBook.might("doom") == 1 and PowerBook.might("doom", 2) == 1 and PowerBook.might("doom", 3) == 2
		and PowerBook.might("doom", 4) == 2 and PowerBook.might("doom", 5) == 3, "Might rises +1 at levels 3 and 5")
	t.check(PowerBook.might("schism", 5) == 8 and PowerBook.might("nosuch", 5) == 0 and PowerBook.might("doom", 9) == 3
		and PowerBook.might("doom", -2) == 1,
		"Might is clamped to levels 1-5 and an unknown key is 0 (%d, %d)" % [PowerBook.might("schism", 5), PowerBook.might("doom", 9)])


static func _no_tables(t) -> void:
	var any := false
	for key in PowerBook.keys():
		any = any or PowerBook.has_levels(key)
	t.check(not any, "no POWERS row has a levels table in P1")
	t.check(PowerBook.level_stat("ember", 5, "radius", 1.5) == 1.5, "without a table a stat is the effect's own number")
	t.check(PowerBook.level_change("ember", 2) == PowerBook.NO_LEVELS and PowerBook.twist("ember") == "",
		"without a table: level_change says so and there is no twist")
	t.check(PowerBook.stat({"level": 5}, "ember", "radius", 2.5) == 2.5 and PowerBook.stat({}, "nosuch", "radius", 7) == 7,
		"PowerBook.stat() hands back base for a power with no table, or no power")


static func _fixture_table(t) -> void:
	t.check(is_equal_approx(float(PowerBook.stat_in(FIXTURE, 3, "radius", 9.0)), 1.2)
		and is_equal_approx(float(PowerBook.stat_in(FIXTURE, 3, "damage", 9.0)), 9.0)
		and is_equal_approx(float(PowerBook.stat_in(FIXTURE, 99, "radius", 9.0)), 1.5)
		and is_equal_approx(float(PowerBook.stat_in(FIXTURE, 0, "radius", 9.0)), 1.0),
		"stat_in reads the table at the level (clamped), and base for a stat it does not name")
	t.check(PowerBook.levels_problems(FIXTURE).is_empty(), "the fixture is valid (%s)" % [PowerBook.levels_problems(FIXTURE)])
	t.check(PowerBook.twist_in(FIXTURE) == "Jumps to the next house", "the twist is the level-5 text")
	t.check(PowerBook.level_change_in(FIXTURE, 2) == "radius 1.0 -> 1.1",
		"level_change names what changed (%s)" % [PowerBook.level_change_in(FIXTURE, 2)])
	t.check(PowerBook.level_change_in(FIXTURE, 5) == "radius 1.3 -> 1.5, Jumps to the next house",
		"at 5 the change carries the twist text (%s)" % [PowerBook.level_change_in(FIXTURE, 5)])
	var short: Dictionary = FIXTURE.duplicate(true)
	(short.levels as Array).pop_back()
	t.check(not PowerBook.levels_problems(short).is_empty(), "four tables are not valid")
	var no_text: Dictionary = FIXTURE.duplicate(true)
	(no_text.levels as Array)[4].erase("twist_text")
	t.check(not PowerBook.levels_problems(no_text).is_empty(), "a level 5 without twist_text is not valid")
	var early: Dictionary = FIXTURE.duplicate(true)
	(early.levels as Array)[1]["twist"] = true
	t.check(not PowerBook.levels_problems(early).is_empty(), "a twist at level 2 is not valid")
	var missing: Dictionary = FIXTURE.duplicate(true)
	(missing.levels as Array)[3].erase("radius")
	t.check(not PowerBook.levels_problems(missing).is_empty(), "radius missing at level 4 is not valid")
	var mixed: Dictionary = FIXTURE.duplicate(true)
	(mixed.levels as Array)[2]["radius"] = "wide"
	t.check(not PowerBook.levels_problems(mixed).is_empty(), "a stat with two types is not valid")
	t.check(not PowerBook.levels_problems({"key": "x"}).is_empty(), "a row with no table is not valid as a table")


static func _draft_levels(t) -> void:
	var d := Draft.new()
	d.slots = 4
	d.capacity = 6
	d.picks = PackedStringArray(["smite", "tornado"])
	d.levels = {"tornado": 5}
	t.check(d.spent() == 1 + 5, "a level-5 Tornado costs 5 Might (%d)" % d.spent())
	t.check(d.level_of("smite") == 1 and d.level_of("tornado") == 5, "level_of: absent is 1")
	var why := d.set_level("smite", 3)
	t.check(why == "dp" and d.level_of("smite") == 1,
		"Smite to 3 would be 7 Might of 6: refused, level unchanged ('%s', %d)" % [why, d.level_of("smite")])
	t.check(d.set_level("smite", 2) == "" and d.level_of("smite") == 2 and d.spent() == 6, "level 2 costs nothing more")
	t.check(d.set_level("heaven", 2) == "pool", "a power not picked has no level to set")
	var lj := Draft.new().for_mission(MissionBook.last_judgement())
	lj.preselect(MissionBook.last_judgement().default_loadout)
	t.check(lj.levels.is_empty() and lj.spent() == 14, "with no levels Last Judgement's default four cost 14 (%d)" % lj.spent())
	var lv := Draft.new().for_mission(MissionBook.last_judgement())
	lv.preselect(PackedStringArray(["doom"]))
	lv.levels = {"doom": 5}
	t.check(lv.refusal("nova") == "" and lv.spent() == 3, "refusal uses the Might the picks cost (%d)" % lv.spent())
	lv.capacity = 6
	t.check(lv.refusal("nova") == "dp", "doom 5 (3) + nova (4) is over 6 ('%s')" % lv.refusal("nova"))


## The Rules a cast test needs: a caster that records the extra it is handed.
static func _cast_level(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var rules := Rules.new().setup(PackedStringArray(["smite", "ember"]), null, env, field, crowd, town, MissionBook.last_judgement())
	var seen: Array[Dictionary] = []
	rules.caster = func(_s: GDScript, _g: Vector2, e: Dictionary) -> FxTimeline:
		seen.append(e)
		return null
	t.check(rules.level_of(0) == 1 and rules.level_of(1) == 1 and rules.level_of(7) == 1, "with no levels every slot is level 1")
	rules.cast(0, Vector2(10, 10))
	t.check(seen.size() == 1 and seen[0].get("level") == 1, "no levels: the cast's extra has level 1 (%s)" % [seen])
	rules.levels = {"smite": 4, "ember": 9}
	t.check(rules.level_of(0) == 4 and rules.level_of(1) == 5,
		"level_of reads the slot's key, clamped 1-5 (%d, %d)" % [rules.level_of(0), rules.level_of(1)])
	rules.advance(20.0)
	var mine := {"mode": "x"}
	rules.cast(0, Vector2(10, 10), mine)
	t.check(seen.size() == 2 and seen[1].get("level") == 4 and seen[1].get("mode") == "x",
		"levels {smite: 4}: the cast's extra has level 4 (%s)" % [seen])
	t.check(not mine.has("level"), "the caller's extra is never changed (%s)" % [mine])
	rules.advance(20.0)
	rules.cast(0, Vector2(10, 10), {"level": 2})
	t.check(seen.size() == 3 and seen[2].get("level") == 2, "a caller that set level keeps it (%s)" % [seen[2]])
	rules.teardown()
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()


static func _mission_keeps(t) -> void:
	var m := Mission.new()
	t.check(m.levels.is_empty(), "a new Mission has no levels")
	m.levels = {"smite": 3}
	t.check(m.levels == {"smite": 3}, "and keeps what is set on it")
	var src := FileAccess.get_file_as_string("res://src/game/mission.gd")
	t.check(src.contains("_rules.levels = levels"), "_build_act() hands the Mission's levels to its Rules")
	m.free()
