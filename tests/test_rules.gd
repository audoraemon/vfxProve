extends RefCounted
## The mission's economy: Divine Power and its regeneration, the four slots' costs and cooldowns, the clock,
## and what happens when a cast cannot be paid for.


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

	var loadout := PackedStringArray(["heaven", "tsunami", "cinder", "nova"])
	var rules := Rules.new().setup(loadout, null, env, field, crowd, town)
	# No effects in a headless test: remember what would have been cast and hand back nothing.
	var casts: Array = []
	rules.caster = func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([script.resource_path, ground, extra])
		return null

	t.check(rules.dp == Rules.DP_MAX and rules.dp == 100.0, "the mission starts on a full 100 DP (%.1f)" % rules.dp)
	t.near(rules.time_left, 240.0, 0.0001, "the manifestation lasts four minutes (%.1f)" % rules.time_left)
	t.check(rules.key(0) == "heaven" and rules.key(3) == "nova", "the loadout fills slots 1 to 4 in order")
	t.check(rules.cost(0) == 10 and rules.cost(3) == 40, "each slot costs its power's DP (%d, %d)" % [rules.cost(0), rules.cost(3)])
	t.check(rules.refusal(0) == "" and rules.refusal(4) == "empty", "a paid-up slot is ready and a fifth slot is empty")

	# A cast spends its cost and starts its cooldown.
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var made: Array = []
	rules.cast_made.connect(func(slot: int, power_key: String, at: Vector2): made.append([slot, power_key, at]))
	rules.cast(0, Vector2(2.0, -3.0), {"dir": Vector2(1, 0)})
	t.check(rules.dp == 90.0, "casting Heaven Splitter spends its 10 DP (%.1f)" % rules.dp)
	t.check(casts.size() == 1 and String(casts[0][0]).ends_with("heaven_splitter.gd"),
		"and reaches the world as its own effect script (%s)" % [casts])
	t.check(made.size() == 1 and made[0][0] == 0 and made[0][1] == "heaven" and made[0][2] == Vector2(2.0, -3.0),
		"and is reported with its slot, power and place (%s)" % [made])
	t.near(rules.cooldown_left(0), 20.0, 0.0001, "the slot goes on its 20 s cooldown (%.1f)" % rules.cooldown_left(0))
	t.check(rules.refusal(0) == "cooldown", "so the slot refuses a second cast")
	rules.cast(0, Vector2(2.0, -3.0))
	t.check(rules.dp == 90.0 and casts.size() == 1 and refused == [[0, "cooldown"]],
		"a refused cast costs nothing and says why (%.1f DP, %s)" % [rules.dp, refused])

	# The cooldown runs off, DP creeps back at half a point a second, and the clock runs down.
	rules.advance(19.0)
	t.near(rules.cooldown_left(0), 1.0, 0.0001, "the cooldown counts down (%.1f)" % rules.cooldown_left(0))
	t.check(rules.refusal(0) == "cooldown", "and still refuses with a second to go")
	rules.advance(1.0)
	t.check(rules.cooldown_left(0) == 0.0 and rules.refusal(0) == "", "then the slot is ready again")
	t.near(rules.dp, 100.0, 0.0001, "20 s of regeneration at 0.5/s tops the bar back up (%.1f)" % rules.dp)
	rules.advance(10.0)
	t.check(rules.dp == 100.0, "and DP never passes 100 (%.1f)" % rules.dp)
	t.near(rules.time_left, 240.0 - 30.0, 0.0001, "the clock has run 30 s (%.1f)" % rules.time_left)

	# Too little DP is its own refusal, and the cost is not taken.
	rules.cast(3, Vector2.ZERO)
	rules.cast(2, Vector2.ZERO)
	t.near(rules.dp, 100.0 - 40.0 - 25.0, 0.0001, "two casts spend both costs (%.1f)" % rules.dp)
	rules.dp = 15.0   # the Tsunami (slot index 1) costs 20, and that slot has not been cast yet
	refused.clear()
	rules.cast(1, Vector2.ZERO, {"dir": Vector2(0, 1)})
	t.check(refused == [[1, "dp"]] and rules.dp == 15.0, "20 DP is out of reach on 15 and nothing is spent (%s)" % refused)

	# The clock stops the mission dead: no more casting once it is out.
	rules.advance(300.0)
	t.check(rules.time_left == 0.0, "the clock floors at zero (%.1f)" % rules.time_left)
	refused.clear()
	rules.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	t.check(refused == [[0, "over"]], "and a finished mission takes no more casts (%s)" % refused)

	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
