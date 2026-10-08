extends RefCounted
## The mission's limits: the slots' cooldowns, one power at a time, the clock, and what happens when a cast cannot
## go out. No Divine Power is spent in a mission (v0.08); the Temple's fall is a Divine Surge.


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

	t.near(rules.time_left, 360.0, 0.0001, "the manifestation lasts six minutes (%.1f)" % rules.time_left)
	t.check(rules.key(0) == "heaven" and rules.key(3) == "nova", "the loadout fills slots 1 to 4 in order")
	t.check(rules.refusal(0) == "" and rules.refusal(4) == "empty", "a fresh slot is ready and a fifth slot is empty")
	t.check(rules.get("dp") == null and not rules.has_method("cost"), "and the rules keep no Divine Power (v0.08)")

	# A cast starts its cooldown, and changes nothing else.
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var made: Array = []
	rules.cast_made.connect(func(slot: int, power_key: String, at: Vector2): made.append([slot, power_key, at]))
	rules.cast(0, Vector2(2.0, -3.0), {"dir": Vector2(1, 0)})
	t.check(rules.cooldown_left(1) == 0.0 and rules.cooldown_left(2) == 0.0 and rules.cooldown_left(3) == 0.0
		and rules.refusal(1) == "" and rules.refusal(3) == "",
		"a cast changes nothing but its own slot's cooldown (%s, %s)" % [rules.refusal(1), rules.refusal(3)])
	t.check(casts.size() == 1 and String(casts[0][0]).ends_with("heaven_splitter.gd"),
		"and reaches the world as its own effect script (%s)" % [casts])

	# One power at a time: while one plays, every other slot is busy until it has finished.
	var playing := FxTimeline.new()
	playing.duration = 8.0
	rules._playing = playing
	t.check(rules.refusal(1) == "busy" and is_equal_approx(rules.busy_left(), 8.0),
		"while a power plays, the others wait for it (%s, %.1f s)" % [rules.refusal(1), rules.busy_left()])
	rules.cast(1, Vector2.ZERO)
	t.check(refused.back() == [1, "busy"] and rules.cooldown_left(1) == 0.0,
		"a cast then is refused and starts no cooldown (%s)" % [refused])
	playing.t = 8.0
	playing.finished = true
	t.check(rules.busy_left() == 0.0 and rules.refusal(1) == "", "once it has finished, the next can go")
	playing.free()
	rules._playing = null
	refused.clear()
	t.check(made.size() == 1 and made[0][0] == 0 and made[0][1] == "heaven" and made[0][2] == Vector2(2.0, -3.0),
		"and is reported with its slot, power and place (%s)" % [made])
	t.near(rules.cooldown_left(0), 30.0, 0.0001, "the slot goes on its 30 s cooldown (%.1f)" % rules.cooldown_left(0))
	t.check(rules.refusal(0) == "cooldown", "so the slot refuses a second cast")
	rules.cast(0, Vector2(2.0, -3.0))
	t.check(casts.size() == 1 and refused == [[0, "cooldown"]],
		"a refused cast reaches nothing and says why (%s)" % [refused])

	# The cooldown runs off, and the clock runs down.
	var recharged: Array = []
	rules.recharged.connect(func(slot: int): recharged.append(slot))
	rules.advance(29.0)
	t.near(rules.cooldown_left(0), 1.0, 0.0001, "the cooldown counts down (%.1f)" % rules.cooldown_left(0))
	t.check(rules.refusal(0) == "cooldown", "and still refuses with a second to go")
	t.check(recharged.is_empty(), "a slot still cooling says nothing (%s)" % [recharged])
	rules.advance(1.0)
	t.check(rules.cooldown_left(0) == 0.0 and rules.refusal(0) == "", "then the slot is ready again")
	t.check(recharged == [0], "and says so, once: the HUD rings ui_ready on it (%s)" % [recharged])
	rules.advance(10.0)
	t.check(recharged == [0], "a ready slot says nothing more (%s)" % [recharged])
	t.near(rules.time_left, 360.0 - 40.0, 0.0001, "the clock has run 40 s (%.1f)" % rules.time_left)

	# Casting is never refused for Divine Power (v0.08): the Nova, the Barrage and the Tsunami go out back to back,
	# and the only refusal left is a slot's own cooldown.
	refused.clear()
	rules.cast(3, Vector2.ZERO)
	rules.cast(2, Vector2.ZERO)
	rules.cast(1, Vector2.ZERO, {"dir": Vector2(0, 1)})
	rules.cast(3, Vector2.ZERO)
	t.check(casts.size() == 4 and refused == [[3, "cooldown"]],
		"three casts in a row all go out, and a repeat is refused for its cooldown (%d, %s)" % [casts.size(), refused])
	var reasons := PackedStringArray()
	for slot in 5:
		reasons.append(rules.refusal(slot))
	t.check(not reasons.has("dp"), "and refusal() never answers \"dp\" (%s)" % [reasons])

	# The clock stops the mission dead: no more casting once it is out.
	rules.advance(Rules.MISSION_SECONDS)
	t.check(rules.time_left == 0.0, "the clock floors at zero (%.1f)" % rules.time_left)
	refused.clear()
	rules.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	t.check(refused == [[0, "over"]], "and a finished mission takes no more casts (%s)" % refused)

	# --- What a cast destroyed -------------------------------------------------------------------------
	var r0 := Rules.new().setup(loadout, null, env, field, crowd, town)
	var first_tower: Structure = null
	for s in env.structures():
		if s.role == &"tower" and not s.destroyed:
			first_tower = s
			break
	first_tower.destroy(first_tower.center(), &"nova")
	t.check(r0.buildings_down == 1, "a destroyed tower counts as a building (%d)" % r0.buildings_down)
	r0.free()

	var r2 := Rules.new().setup(loadout, null, env, field, crowd, town)
	var banners: Array = []
	r2.banner.connect(func(text: String): banners.append(text))
	var chains: Array = []
	r2.chained.connect(func(at: Vector2): chains.append(at))
	r2.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null

	# Nothing is credited to nobody: a destroyed building still counts.
	var towers: Array[Structure] = []
	for s in env.structures():
		if s.role == &"tower" and not s.destroyed:
			towers.append(s)
	var houses: Array[Structure] = []
	for s in env.structures():
		if s.role == &"house" and not s.destroyed:
			houses.append(s)
	t.check(towers.size() >= 4 and houses.size() >= 11, "the town still has towers and houses to break (%d, %d)" % [towers.size(), houses.size()])
	houses[0].destroy(houses[0].center(), &"nova")
	t.check(r2.buildings_down == 1, "a house counts as a building (%d)" % r2.buildings_down)
	towers[0].destroy(towers[0].center(), &"nova")
	t.check(r2.buildings_down == 2, "and so does a wall tower (%d)" % r2.buildings_down)

	# The Citadel's own parts are the Citadel's, not nine more buildings.
	var parts_before := r2.buildings_down
	town.citadel.parts[0].destroy(town.citadel.parts[0].center(), &"nova")
	t.check(r2.buildings_down == parts_before, "a fallen Citadel part is not counted as a building (%d)" % r2.buildings_down)

	# Credit goes to the running cast whose power deals that kind, and the latest one wins a tie.
	r2.cast(2, Vector2(1.0, 1.0))   # cinder: deals &"cinder" and &"stone"
	t.check(r2.credited_key(&"stone") == "cinder", "the Barrage is credited for falling stone (%s)" % r2.credited_key(&"stone"))
	t.check(r2.credited_key(&"ice") == "", "and nothing running deals ice (%s)" % r2.credited_key(&"ice"))

	# Six buildings from one cast is a chain, with its banner.
	for i in 6:
		houses[i + 1].destroy(houses[i + 1].center(), &"stone")
	t.check(chains.size() == 1, "six buildings from one cast is one chain (%d)" % chains.size())
	t.check(banners.has("CHAIN!"), "and says so (%s)" % [banners])
	t.check(r2.chains == 1, "the chain is kept for the score (%d)" % r2.chains)
	for i in range(7, 11):
		houses[i].destroy(houses[i].center(), &"stone")
	t.check(r2.chains == 1, "one cast only ever chains once (%d)" % r2.chains)

	# The Citadel falling has its own banner.
	# Radius 3.0, not 4.0: every Citadel part is within 2.6 of the origin, but the Temple's near edge is 3.5
	# away, and a blast that took it down as well would bring on the Divine Surge too.
	while not town.citadel.is_fallen():
		town.citadel.advance(1.01)
		env.damage_radius(TownLayout.CITADEL_ORIGIN, 3.0, 400.0, &"nova")
	t.check(banners.has("THE CITADEL FALLS") and not banners.has("DIVINE SURGE"),
		"the Citadel's fall is announced (%s)" % [banners])
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
	# v0.08: with no mission given, the rules play Last Judgement, decided by its three objectives.
	t.check(rules.mission.id == "last_judgement" and rules.objectives.size() == 3,
		"the rules play Last Judgement by its three objectives (%s, %d)" % [rules.mission.id, rules.objectives.size()])
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()
	_surge(t, loadout)
	_per_act(t, loadout)



## The Divine Surge (v0.08): the Temple's fall resets every cooldown, once a mission, with its banner.
static func _surge(t, loadout: PackedStringArray) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	var rules := Rules.new().setup(loadout, null, env, field, crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	var surges: Array = []
	rules.surged.connect(func(): surges.append(true))
	var banners: Array = []
	rules.banner.connect(func(text: String): banners.append(text))
	var recharged: Array = []
	rules.recharged.connect(func(slot: int): recharged.append(slot))
	# The order the HUD counts on: it rings ui_surge on surged and keeps the banner that follows quiet.
	var order: Array = []
	rules.surged.connect(func(): order.append("surged"))
	rules.banner.connect(func(text: String): order.append(text))
	var temple: Structure = null
	var house: Structure = null
	for s in env.structures():
		if s.role == &"temple":
			temple = s
		elif s.role == &"house" and house == null:
			house = s
	rules.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	rules.cast(3, Vector2.ZERO)
	t.check(rules.cooldown_left(0) > 0.0 and rules.cooldown_left(3) > 0.0 and not rules.surged_once,
		"two slots are on cooldown (%.1f, %.1f)" % [rules.cooldown_left(0), rules.cooldown_left(3)])
	house.destroy(house.center(), &"nova")
	t.check(rules.cooldown_left(0) > 0.0 and surges.is_empty(), "a house's fall resets nothing")
	temple.destroy(temple.center(), &"nova")
	t.check(rules.cooldown_left(0) == 0.0 and rules.cooldown_left(3) == 0.0 and rules.refusal(0) == "",
		"the Temple's fall resets both cooldowns (%.1f, %.1f)" % [rules.cooldown_left(0), rules.cooldown_left(3)])
	t.check(surges.size() == 1 and rules.surged_once and banners.has("DIVINE SURGE"),
		"and is a Divine Surge, announced (%d, %s)" % [surges.size(), banners])
	t.check(order == ["surged", "DIVINE SURGE"], "surged comes first, its banner straight after (%s)" % [order])
	t.check(recharged.is_empty(), "the surge's reset is not a recharge: it rings ui_surge, not ui_ready (%s)" % [recharged])
	# Once a mission. The town has one Temple, so its fall is reported a second time to stand in for another.
	rules.cast(0, Vector2.ZERO, {"dir": Vector2(1, 0)})
	var left := rules.cooldown_left(0)
	var second: Structure = null
	for s in env.structures():
		if s.role == &"temple" and s != temple:
			second = s
	if second != null:
		second.destroy(second.center(), &"nova")
	else:
		rules._on_structure_destroyed(temple, &"nova")
	t.check(left > 0.0 and is_equal_approx(rules.cooldown_left(0), left) and surges.size() == 1
		and banners.count("DIVINE SURGE") == 1,
		"a second fall resets nothing (%.1f s left, %d surges)" % [rules.cooldown_left(0), surges.size()])
	rules.free()
	crowd.free()
	world.free()
	field.free()
	env.clear()
	env.free()
	town.free()



## v0.09: a Rules built on a crowd that has already lived through an act counts from its own start, and a tool
## can end the act.
static func _per_act(t, loadout: PackedStringArray) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	crowd.escaped_count = 7
	crowd.killed_citizens = 3
	crowd.killed_soldiers = 2
	var rules := Rules.new().setup(loadout, null, env, field, crowd, town)
	t.check(rules.escaped_this_act() == 0 and rules.citizens_killed_this_act() == 0
		and rules.soldiers_killed_this_act() == 0,
		"a new act starts from zero (%d, %d, %d)" % [rules.escaped_this_act(), rules.citizens_killed_this_act(),
		rules.soldiers_killed_this_act()])
	t.check(rules.score() == 0, "and the score counts none of the earlier act's kills (%d)" % rules.score())
	crowd.escaped_count += 2
	crowd.killed_citizens += 1
	crowd.killed_soldiers += 1
	t.check(rules.escaped_this_act() == 2 and rules.citizens_killed_this_act() == 1
		and rules.soldiers_killed_this_act() == 1,
		"later escapes and kills count (%d, %d, %d)" % [rules.escaped_this_act(), rules.citizens_killed_this_act(),
		rules.soldiers_killed_this_act()])
	t.check(rules.score() == Rules.SCORE_PER_CITIZEN + Rules.SCORE_PER_SOLDIER,
		"the score counts only the new ones (%d)" % rules.score())
	var escaped_line := ""
	for l in rules.stat_lines():
		if l.label == "Citizens escaped":
			escaped_line = String(l.value)
	t.check(escaped_line == "2", "the table's escapes are this act's (%s)" % escaped_line)
	t.check(EscapeLimitObjective.new(2).check(rules) == Objective.Status.FAILED,
		"a limit of 2 is met by two escapes")
	t.check(EscapeLimitObjective.new(3).check(rules) == Objective.Status.PENDING,
		"a limit of 3 is not")
	var overs: Array = []
	rules.over.connect(func(won: bool, reason: String) -> void: overs.append([won, reason]))
	rules.force_end(true, "test")
	t.check(rules.finished and rules.won and rules.over_reason == "test" and overs.size() == 1,
		"force_end ends the act as asked, once (%s)" % [overs])
	rules.force_end(false, "again")
	t.check(rules.won and rules.over_reason == "test" and overs.size() == 1,
		"a second force_end does nothing")
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
