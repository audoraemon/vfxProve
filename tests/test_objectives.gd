extends RefCounted
## v0.08 objectives: each reports PENDING, DONE or FAILED from the mission's state. The Citadel's is done once it has
## fallen and the city is broken; the escape limit fails at 50 escaped; the clock fails at 0:00, or -- for a mission
## that asks it to (The Warning) -- succeeds then.


static func _rules() -> Array:
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
	var rules := Rules.new().setup(PackedStringArray(["heaven"]), null, env, field, crowd, town)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	return [rules, crowd, world, town, env, field]


## Every part of the city's stability at zero, as if the city had been broken.
static func _break(s: Stability) -> void:
	s.population = 0.0
	s.infrastructure = 0.0
	s.leadership = 0.0
	s.military = 0.0
	s.resources = 0.0


static func run(t) -> void:
	var made := _rules()
	var rules: Rules = made[0]
	var crowd: Crowd = made[1]
	var town: Town = made[3]
	var env: EnvironmentField = made[4]
	var field: EnemyField = made[5]
	var P := Objective.Status.PENDING
	var D := Objective.Status.DONE
	var F := Objective.Status.FAILED

	var citadel := CitadelObjective.new()
	t.check(citadel.check(rules) == P and citadel.reason == "citadel", "the Citadel standing is pending")
	var escape := EscapeLimitObjective.new()
	t.check(escape.check(rules) == P, "no escapes is pending")
	crowd.escaped_count = Rules.ESCAPE_LIMIT - 1
	t.check(escape.check(rules) == P, "49 escaped is still pending")
	crowd.escaped_count = Rules.ESCAPE_LIMIT
	t.check(escape.check(rules) == F and escape.reason == "escapes", "50 escaped fails it")
	crowd.escaped_count = 0

	var lose_clock := ClockObjective.new()
	var win_clock := ClockObjective.new(true, "Omen fades", "omen")
	t.check(lose_clock.check(rules) == P and win_clock.check(rules) == P, "both clocks are pending while time is left")
	rules.time_left = 0.0
	t.check(lose_clock.check(rules) == F and lose_clock.reason == "timeout", "at 0:00 the clock fails by default")
	t.check(win_clock.check(rules) == D and win_clock.reason == "omen", "or succeeds when the mission asks it to")
	rules.time_left = 83.0
	t.check(win_clock.hud_text(rules) == "Omen fades 1:23", "the clock's line shows the time (%s)" % win_clock.hud_text(rules))
	t.check(lose_clock.hud_text(rules) == "", "a clock with no label stays off the panel")

	# A broken city with the Citadel still standing is not enough.
	_break(rules.stability)
	t.check(citadel.check(rules) == P, "a broken city with the Citadel standing is still pending")
	# The Citadel down, the way test_rules brings it down: its rolling budget lets it lose a share a second.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	rules.stability.measure(env, crowd, town.citadel)
	t.check(not rules.stability.is_broken(), "the Citadel alone does not break the city (%.2f)" % rules.stability.total())
	t.check(citadel.check(rules) == P, "so the Citadel down with the city standing is still pending")
	_break(rules.stability)
	t.check(citadel.check(rules) == D, "the Citadel down and the city broken is done")

	rules.teardown()
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	(made[2] as Node).free()
