extends RefCounted
## How a mission ends and what it is worth: the two ways to lose, the one way to win, the score's arithmetic
## and the rank thresholds.


static func run(t) -> void:
	# --- Losing on the clock ---------------------------------------------------------------------------
	var a := _mission()
	var rules: Rules = a.rules
	var ended: Array = []
	rules.over.connect(func(won: bool, reason: String): ended.append([won, reason]))
	rules.advance(Rules.MISSION_SECONDS + 1.0)
	t.check(ended == [[false, "timeout"]], "the clock running out loses the mission (%s)" % [ended])
	t.check(rules.finished and not rules.won, "and the mission is over")
	rules.advance(1.0)
	t.check(ended.size() == 1, "the end is announced once (%d)" % ended.size())
	t.check(rules.score() == 0, "a mission with nothing destroyed scores nothing (%d)" % rules.score())
	t.check(rules.rank() == "D", "which is a D (%s)" % rules.rank())
	_drop(a)

	# --- Losing to the escape ------------------------------------------------------------------------
	var b := _mission()
	rules = b.rules
	var crowd: Crowd = b.crowd
	ended = []
	rules.over.connect(func(won: bool, reason: String): ended.append([won, reason]))
	for i in Rules.ESCAPE_LIMIT:
		crowd.escaped_count += 1
	rules.advance(0.1)
	t.check(ended == [[false, "escapes"]], "38 citizens getting away loses it (%s)" % [ended])
	t.near(rules.time_left, Rules.MISSION_SECONDS - 0.1, 0.0001, "with time still on the clock (%.1f)" % rules.time_left)
	_drop(b)

	# --- Winning -------------------------------------------------------------------------------------
	var c := _mission()
	rules = c.rules
	crowd = c.crowd
	var env: EnvironmentField = c.env
	var town: Town = c.town
	ended = []
	rules.over.connect(func(won: bool, reason: String): ended.append([won, reason]))
	rules.advance(40.0)
	t.check(not rules.finished, "a mission with a standing city runs on")
	for s in env.structures():
		if not s.destroyed and s.role != &"citadel":
			s.destroy(s.center(), &"nova")
	for p in crowd.citizens.duplicate():
		if is_instance_valid(p) and p.is_alive():
			c.field.kill(p, &"nova")
	for p in crowd.soldiers.duplicate():
		if is_instance_valid(p) and p.is_alive():
			c.field.kill(p, &"nova")
	rules.advance(0.1)
	t.check(not rules.finished, "a razed town with the Citadel still up is not a win yet")
	# Radius 3.0, not 4.0: every Citadel part is within 2.6 of the origin, but the Temple's near edge is 3.5
	# away, and a blast that took it down as well would pay its 8 DP into the 15 being measured here.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	rules.advance(0.1)
	t.check(ended.size() == 1 and ended[0][0] == true and ended[0][1] == "citadel",
		"the Citadel down with stability at zero wins it (%s)" % [ended])
	t.near(rules.stability.total(), 0.0, 0.0001, "the city has fallen (%.3f)" % rules.stability.total())

	# The score is the spec's arithmetic, line by line.
	var seconds := int(roundf(rules.time_left))
	var dp_left := int(floorf(rules.dp))
	var expected := Rules.SCORE_WIN + seconds * Rules.SCORE_PER_SECOND + dp_left * Rules.SCORE_PER_DP \
		+ rules.buildings_down * Rules.SCORE_PER_BUILDING + crowd.killed_citizens * Rules.SCORE_PER_CITIZEN \
		+ crowd.killed_soldiers * Rules.SCORE_PER_SOLDIER + rules.chains * Rules.SCORE_PER_CHAIN
	t.check(rules.score() == expected, "the score adds up (%d, expected %d)" % [rules.score(), expected])
	t.check(rules.buildings_down >= 50 and crowd.killed_citizens == 110,
		"this run flattened the town and everyone in it (%d buildings, %d citizens)" % [rules.buildings_down, crowd.killed_citizens])
	var points := 0
	for line: Dictionary in rules.stat_lines():
		points += int(line.points)
	t.check(points == rules.score(), "and the results table adds up to the same (%d)" % points)
	t.check(rules.rank() == "S", "a flattened city on the first minute is an S (%s, %d)" % [rules.rank(), rules.score()])
	_drop(c)

	# --- The rank thresholds -------------------------------------------------------------------------
	# Driven through the real score, one chain at a time: 300 points each, so the thresholds land exactly.
	var d := _mission()
	rules = d.rules
	rules.chains = 40
	t.check(rules.score() == 12000 and rules.rank() == "S", "40 chains is 12,000 points and an S (%d, %s)" % [rules.score(), rules.rank()])
	rules.chains = 39
	t.check(rules.rank() == "A", "11,700 is an A (%s)" % rules.rank())
	rules.chains = 30
	t.check(rules.score() == 9000 and rules.rank() == "A", "9,000 is still an A (%d)" % rules.score())
	rules.chains = 29
	t.check(rules.rank() == "B", "8,700 is a B (%s)" % rules.rank())
	rules.chains = 20
	t.check(rules.score() == 6000 and rules.rank() == "B", "6,000 is still a B (%d)" % rules.score())
	rules.chains = 10
	t.check(rules.rank() == "C" and rules.score() == 3000, "3,000 is a C (%s)" % rules.rank())
	rules.chains = 9
	t.check(rules.rank() == "D", "2,700 is a D (%s)" % rules.rank())
	_drop(d)


## A fresh mission's world, with its own field and crowd so one test's kills never leak into another's.
static func _mission() -> Dictionary:
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
	var rules := Rules.new().setup(PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), null, env, field,
		crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	return {"env": env, "town": town, "field": field, "crowd": crowd, "rules": rules, "world": world}


static func _drop(m: Dictionary) -> void:
	var rules: Rules = m.rules
	rules.free()
	var crowd: Crowd = m.crowd
	crowd.clear()
	var field: EnemyField = m.field
	field.clear()
	field.free()
	var env: EnvironmentField = m.env
	env.clear()
	env.free()
	var town: Town = m.town
	town.free()
	crowd.free()
	var world: Node2D = m.world
	world.free()
