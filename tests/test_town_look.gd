extends RefCounted
## The town's lighting looks: chosen at build, CURRENT untouched, DAY and NIGHT baking the ground neutral.


static func run(t) -> void:
	_parse(t)
	_current_untouched(t)
	_neutral_bake(t)
	_cycle(t)
	await _night_ambient(t)


static func _parse(t) -> void:
	t.check(Town.look_from_args(PackedStringArray(["--look=day"])) == Town.Look.DAY, "--look=day is DAY")
	t.check(Town.look_from_args(PackedStringArray(["--look=night"])) == Town.Look.NIGHT, "--look=night is NIGHT")
	t.check(Town.look_from_args(PackedStringArray()) == Town.Look.CURRENT, "no argument is CURRENT")
	t.check(Town.look_from_args(PackedStringArray(["--look=x"])) == Town.Look.CURRENT, "an unknown look is CURRENT")


static func _build(look: Town.Look, ground: Node2D, env: EnvironmentField) -> Town:
	var town := Town.new()
	town.look = look
	town.build(env, ground)
	return town


static func _current_untouched(t) -> void:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := _build(Town.Look.CURRENT, ground, env)
	t.check(town.look_nodes().is_empty(), "a CURRENT town has no town_look nodes")
	t.check(town.floor_node.tint == Town.GROUND_EVENING, "CURRENT floor keeps GROUND_EVENING")
	t.check(Structure.cast_shadows, "CURRENT keeps the contact shadow")
	t.check(env.lights.tint == Town.EVENING and env.lights.ambient == 1.0, "CURRENT light is the warm evening")
	_free(town, env, ground)


static func _neutral_bake(t) -> void:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := _build(Town.Look.DAY, ground, env)
	var gold := TownLook.ground_tint(Town.Look.DAY)
	t.check(town.floor_node.tint == gold and town.plant_layer.modulate == gold
		and town.forest.modulate == gold, "a DAY town bakes floor, plants and forest in the low golden sun")
	t.check(env.lights.tint == TownLook.light_tint(Town.Look.DAY), "DAY sets the light tint")
	t.check(not Structure.cast_shadows, "DAY turns the contact shadow off")
	_free(town, env, ground)
	t.check(Structure.cast_shadows, "the contact shadow is back after a DAY town is torn down")
	var env2 := EnvironmentField.new()
	env2.lights = LightField.new()
	var g2 := Node2D.new()
	var night := _build(Town.Look.NIGHT, g2, env2)
	t.check(env2.lights.tint == TownLook.light_tint(Town.Look.NIGHT) and env2.lights.ambient == TownLook.ambient(Town.Look.NIGHT),
		"NIGHT sets the light tint and the build-time ambient (a Battlefield keeps it: see _night_ambient)")
	var lights := env2.lights
	_free(night, env2, g2)
	t.check(lights.ambient == 1.0 and lights.tint == Color.WHITE, "teardown puts the ambient and tint back")
	lights.free()


static func _cycle(t) -> void:
	var fresh := EnvironmentField.new()
	var fg := Node2D.new()
	var ft := _build(Town.Look.CURRENT, fg, fresh)
	var want := fresh.structures().size()
	var want_decor := fg.get_child_count()
	_free(ft, fresh, fg)
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town: Town
	for look in [Town.Look.CURRENT, Town.Look.DAY, Town.Look.NIGHT, Town.Look.CURRENT]:
		if town != null:
			town.teardown()
			town.free()
		town = _build(look, ground, env)
	t.check(town.look_nodes().is_empty(), "the cycle ends in CURRENT with no town_look nodes")
	t.check(env.structures().size() == want, "the cycle's CURRENT has a fresh build's structures (%d vs %d)" % [env.structures().size(), want])
	t.check(ground.get_child_count() == want_decor, "the cycle leaves no stray ground nodes")
	t.check(town.floor_node.tint == Town.GROUND_EVENING and env.lights.tint == Town.EVENING and Structure.cast_shadows,
		"the cycle's CURRENT is today's look")
	_free(town, env, ground)


static func _free(town: Town, env: EnvironmentField, ground: Node2D) -> void:
	town.teardown()
	town.free()
	env.clear()
	env.free()
	ground.free()


## Under a Battlefield (which rewrites the ambient every frame from the dim) a NIGHT town keeps its ambient, a CURRENT one
## stays at 1.0, and the effects' dim still darkens either from there.
static func _night_ambient(t) -> void:
	for look in [Town.Look.CURRENT, Town.Look.NIGHT]:
		var bf := Battlefield.new()
		t.root.add_child(bf)
		await t.process_frame
		var town := Town.new()
		town.look = look
		town.build(bf.ctx.env, bf.ground_plane)
		bf._process(0.016)
		var want := TownLook.ambient(look) if look == Town.Look.NIGHT else 1.0
		t.check(is_equal_approx(bf.ctx.lights.ambient, want),
			"%s town under a Battlefield keeps an ambient of %.2f after a frame (%.3f)" % [Town.Look.keys()[look], want, bf.ctx.lights.ambient])
		if look == Town.Look.NIGHT:
			t.check(want < 0.9, "NIGHT's ambient is below 0.9, not the 1.0 Battlefield used to write")
		town.teardown()
		bf._process(0.016)
		t.check(is_equal_approx(bf.ctx.lights.ambient, 1.0), "teardown puts the Battlefield's ambient back to 1.0")
		town.free()
		t.root.remove_child(bf)
		bf.free()
