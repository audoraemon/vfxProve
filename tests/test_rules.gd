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
	t.near(rules.time_left, 360.0, 0.0001, "the manifestation lasts six minutes (%.1f)" % rules.time_left)
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
	t.near(rules.time_left, 360.0 - 30.0, 0.0001, "the clock has run 30 s (%.1f)" % rules.time_left)

	# Too little DP is its own refusal, and the cost is not taken.
	rules.cast(3, Vector2.ZERO)
	rules.cast(2, Vector2.ZERO)
	t.near(rules.dp, 100.0 - 40.0 - 25.0, 0.0001, "two casts spend both costs (%.1f)" % rules.dp)
	rules.dp = 15.0   # the Tsunami (slot index 1) costs 20, and that slot has not been cast yet
	refused.clear()
	rules.cast(1, Vector2.ZERO, {"dir": Vector2(0, 1)})
	t.check(refused == [[1, "dp"]] and rules.dp == 15.0, "20 DP is out of reach on 15 and nothing is spent (%s)" % refused)

	# The clock stops the mission dead: no more casting once it is out.
	rules.advance(Rules.MISSION_SECONDS)
	t.check(rules.time_left == 0.0, "the clock floors at zero (%.1f)" % rules.time_left)
	refused.clear()
	rules.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	t.check(refused == [[0, "over"]], "and a finished mission takes no more casts (%s)" % refused)

	# --- What a cast destroyed -------------------------------------------------------------------------
	# Since the milestone 4 playtest the mission runs on regeneration alone: destroying things pays nothing.
	var r0 := Rules.new().setup(loadout, null, env, field, crowd, town)
	t.check(not r0.dp_recovery, "Divine Power comes back only by regeneration by default")
	r0.dp = 50.0
	var first_tower: Structure = null
	for s in env.structures():
		if s.role == &"tower" and not s.destroyed:
			first_tower = s
			break
	first_tower.destroy(first_tower.center(), &"nova")
	t.check(r0.dp == 50.0 and r0.buildings_down == 1,
		"a destroyed tower pays nothing but still counts as a building (%.1f DP, %d)" % [r0.dp, r0.buildings_down])
	r0.free()

	var r2 := Rules.new().setup(loadout, null, env, field, crowd, town)
	r2.dp_recovery = true  # the table is kept, switched off; this block proves it still pays when switched on
	var gains: Array = []
	r2.dp_gained.connect(func(amount: float, at: Vector2): gains.append([amount, at]))
	var banners: Array = []
	r2.banner.connect(func(text: String): banners.append(text))
	var chains: Array = []
	r2.chained.connect(func(at: Vector2): chains.append(at))
	r2.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	r2.dp = 50.0   # spend first: a gain cannot show on a bar that is already full

	# Nothing is credited to nobody: a destroyed building still pays its DP.
	var towers: Array[Structure] = []
	for s in env.structures():
		if s.role == &"tower" and not s.destroyed:
			towers.append(s)
	var houses: Array[Structure] = []
	for s in env.structures():
		if s.role == &"house" and not s.destroyed:
			houses.append(s)
	t.check(towers.size() >= 4 and houses.size() >= 11, "the town still has towers and houses to break (%d, %d)" % [towers.size(), houses.size()])
	var dp_before := r2.dp
	houses[0].destroy(houses[0].center(), &"nova")
	t.check(r2.dp == dp_before and r2.buildings_down == 1, "a house is worth no DP but counts as a building (%.1f, %d)" % [r2.dp, r2.buildings_down])
	towers[0].destroy(towers[0].center(), &"nova")
	t.near(r2.dp, dp_before + 3.0, 0.0001, "a wall tower pays 3 DP (%.1f)" % r2.dp)
	t.check(gains.size() == 1 and gains[0][0] == 3.0, "and the gain is reported for its popup (%s)" % [gains])

	# The Citadel's own parts are the Citadel's, not nine more buildings.
	var parts_before := r2.buildings_down
	town.citadel.parts[0].destroy(town.citadel.parts[0].center(), &"nova")
	t.check(r2.buildings_down == parts_before, "a fallen Citadel part is not counted as a building (%d)" % r2.buildings_down)

	# A soldier pays, a citizen does not.
	dp_before = r2.dp
	var soldier: Person = null
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive():
			soldier = p
			break
	field.kill(soldier, &"nova")
	t.near(r2.dp, dp_before + Rules.DP_SOLDIER, 0.0001, "a dead soldier pays 0.4 DP (%.1f)" % r2.dp)
	dp_before = r2.dp
	var citizen: Person = null
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive():
			citizen = p
			break
	field.kill(citizen, &"nova")
	t.check(r2.dp == dp_before, "a dead citizen pays nothing (%.1f)" % r2.dp)

	# Credit goes to the running cast whose power deals that kind, and the latest one wins a tie.
	r2.cast(2, Vector2(1.0, 1.0))   # cinder: deals &"cinder" and &"stone"
	t.check(r2.credited_key(&"stone") == "cinder", "the Barrage is credited for falling stone (%s)" % r2.credited_key(&"stone"))
	t.check(r2.credited_key(&"ice") == "", "and nothing running deals ice (%s)" % r2.credited_key(&"ice"))

	# Six buildings from one cast is a chain: +6 DP and the banner.
	var dp_chain := r2.dp
	for i in 6:
		houses[i + 1].destroy(houses[i + 1].center(), &"stone")
	t.check(chains.size() == 1, "six buildings from one cast is one chain (%d)" % chains.size())
	t.near(r2.dp - dp_chain, Rules.CHAIN_DP, 0.0001, "worth 6 DP (%.1f)" % (r2.dp - dp_chain))
	t.check(banners.has("CHAIN!"), "and says so (%s)" % [banners])
	t.check(r2.chains == 1, "the chain is kept for the score (%d)" % r2.chains)
	for i in range(7, 11):
		houses[i].destroy(houses[i].center(), &"stone")
	t.check(r2.chains == 1, "one cast only ever chains once (%d)" % r2.chains)

	# The Citadel falling is worth 15 DP and its own banner.
	dp_before = r2.dp
	# Radius 3.0, not 4.0: every Citadel part is within 2.6 of the origin, but the Temple's near edge is 3.5
	# away, and a blast that took it down as well would pay its 8 DP into the 15 being measured here.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	t.near(r2.dp - dp_before, Rules.CITADEL_DP, 0.0001, "the Citadel's fall pays 15 DP (%.1f)" % (r2.dp - dp_before))
	t.check(banners.has("THE CITADEL FALLS"), "and is announced (%s)" % [banners])
	r2.free()

	# An effect freed without finishing (its layer cleared, say) must not trip the crediting: before the fix, reading
	# it into a typed variable raised and aborted the pruning, so old casts were never forgotten.
	var r3 := Rules.new().setup(loadout, null, env, field, crowd, town)
	var gone := FxTimeline.new()
	r3.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return gone
	r3.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	gone.free()
	r3.advance(Rules.CAST_GRACE + 0.1)
	t.check(r3.credited_key(&"lightning") == "", "a cast whose effect was freed is forgotten once its grace runs out")
	r3.free()
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
