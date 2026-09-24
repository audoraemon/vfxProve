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
	t.check(env.structures().size() == TownLayout.structures().size() + 9, "every layout building plus the 9 Citadel parts")
	t.check(counts.get(&"citadel", 0) == 9 and counts.get(&"house", 0) == 40 and counts.get(&"gate", 0) == 2,
		"roles carried over (%s)" % [counts])
	t.check(town.gates.size() == 2 and town.bridge != null and town.bridge.walkable, "gates and bridge found")
	t.check(town.citadel != null and town.citadel.fraction() == 1.0 and town.citadel.standing_parts() == 9, "the Citadel is intact")
	t.check(not env.blocked(Vector2(0, 8.7)) and not env.blocked(Vector2(8.7, 0)), "both gates are passable")
	t.check(not env.blocked(Vector2(0, 12.2)), "the bridge is passable")
	t.check(env.blocked(Vector2(0, -8.7)) and env.blocked(Vector2(-8.7, 3.0)), "the town walls block")
	t.check(town.floor_node == null, "no floor without a ground plane")
	var down: Array = []
	env.structure_destroyed.connect(func(s: Structure, _kind: StringName) -> void: down.append(s))
	env.damage_radius(Vector2(0, 12.2), 0.3, 99999.0, &"stone")
	t.check(town.bridge.destroyed and down == [town.bridge], "the bridge can be destroyed and reports it")
	# The floor hangs under the ground plane, so freeing the town must take it along even when the town
	# never entered the scene tree.
	var env2 := EnvironmentField.new()
	var ground := Node2D.new()
	var town2 := Town.new()
	town2.build(env2, ground)
	var floor_node: Node = town2.floor_node
	t.check(floor_node != null and ground.get_child_count() == 1, "the floor is added under the ground plane")
	town2.free()
	t.check(not is_instance_valid(floor_node) or floor_node.is_queued_for_deletion(), "freeing the town frees its floor")
	env2.clear()
	env2.free()
	ground.free()
	env.clear()
	env.free()
	town.free()
