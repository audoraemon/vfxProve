extends RefCounted
## Town builds Aldermere into an EnvironmentField: every layout building with its role, the Citadel, and gates and
## a bridge that units can pass.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var counts := {}
	for s in env.structures():
		counts[s.role] = int(counts.get(s.role, 0)) + 1
	t.check(env.structures().size() == TownLayout.structures().size() + 9 + TownLayout.FOUNTAINS.size(),
		"every layout building plus the 9 Citadel parts and the fountains")
	t.check(counts.get(&"citadel", 0) == 9 and counts.get(&"house", 0) == 81 and counts.get(&"gate", 0) == 2,
		"roles carried over (%s)" % [counts])
	t.check(town.gates.size() == 2 and town.bridge != null and town.bridge.walkable, "gates and bridge found")
	t.check(town.citadel != null and town.citadel.fraction() == 1.0 and town.citadel.standing_parts() == 9, "the Citadel is intact")
	t.check(not env.blocked(TownLayout.MAIN_GATE.get_center()) and not env.blocked(TownLayout.SIDE_GATE.get_center()),
		"both gates are passable")
	t.check(not env.blocked(Vector2(2.7, 21.6)), "the bridge is passable")
	t.check(env.blocked(Vector2(0, -15.6)) and env.blocked(Vector2(-15.6, 3.0)), "the town walls block")
	t.check(town.floor_node == null, "no floor without a ground plane")
	var down: Array = []
	env.structure_destroyed.connect(func(s: Structure, _kind: StringName) -> void: down.append(s))
	env.damage_radius(Vector2(2.7, 21.6), 0.3, 99999.0, &"stone")
	t.check(town.bridge.destroyed and down == [town.bridge], "the bridge can be destroyed and reports it")
	# The floor hangs under the ground plane, so freeing the town must take it along even when the town
	# never entered the scene tree.
	var env2 := EnvironmentField.new()
	var ground := Node2D.new()
	var town2 := Town.new()
	town2.build(env2, ground)
	var floor_node: Node = town2.floor_node
	t.check(floor_node != null and ground.get_child_count() == 2 and ground.get_child(0) is TownFloor
		and ground.get_child(1) is ForestLayer, "the floor, then the forest layer over it, under the ground plane")
	t.check(not town2.forest.trees.is_empty() and town2.forest.trees.all(func(d): return d.kind in [Decor.Kind.OAK, Decor.Kind.PINE])
		and not town2.floor_node.baked_decor.any(func(d): return d.kind in [Decor.Kind.OAK, Decor.Kind.PINE]),
		"the baked trees go to the forest layer (%d), the rest stays in the floor" % town2.forest.trees.size())
	town2.free()
	t.check(not is_instance_valid(floor_node) or floor_node.is_queued_for_deletion(), "freeing the town frees its floor")
	env2.clear()
	env2.free()
	ground.free()

	# Each building comes down with its material's sound; the little posts, the fields and the fountain's
	# ornament do not.
	var cues := {}
	for s in env.structures():
		var key := "%s/%s" % [Structure.Kind.keys()[s.kind], s.role]
		cues[key] = Town.collapse_cue(s)
	t.check(cues.get("KEEP/tower") == &"collapse_stone" and cues.get("CASTLE_WALL/wall") == &"collapse_stone"
		and cues.get("GATE/gate") == &"collapse_stone" and cues.get("TEMPLE/temple") == &"collapse_stone"
		and cues.get("BARRACKS/barracks") == &"collapse_stone" and cues.get("KEEP/citadel") == &"collapse_stone",
		"stone for towers, walls, gates, the Temple, the barracks and the Citadel (%s)" % [cues])
	t.check(cues.get("HOUSE/house") == &"collapse_timber" and cues.get("MARKET_STALL/market") == &"collapse_timber"
		and cues.get("HOUSE/farm") == &"collapse_timber", "timber for houses, stalls and farm buildings")
	t.check(cues.get("TREE/decor") == &"collapse_tree", "a tree falls like a tree")
	t.check(cues.get("TORCH/decor") == &"" and cues.get("FARM_FIELD/farm") == &"",
		"torch and lamp posts and fields make no collapse sound")
	for cue in [&"collapse_stone", &"collapse_timber", &"collapse_tree"]:
		t.check(Sfx.CATALOG.has(cue) and Sfx.paths_for(cue).size() == 3, "%s has three variants" % cue)
	env.clear()
	env.free()
	town.free()
