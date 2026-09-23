extends RefCounted
## The Aldermere building kinds: health, walkability, and how fields and trees come down.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var kinds := [Structure.Kind.TEMPLE, Structure.Kind.BARRACKS, Structure.Kind.MARKET_STALL, Structure.Kind.GATE,
		Structure.Kind.BRIDGE, Structure.Kind.FARM_FIELD, Structure.Kind.TREE]
	var ok := true
	for k in kinds:
		var s := env.add_structure(Rect2(k * 4, 30, 1, 1), 20.0, k)
		ok = ok and s.max_hp > 0.0 and s.hp == s.max_hp
	t.check(ok, "every new kind has health")

	var gate := env.add_structure(Rect2(0, 0, 2.8, 1.0), 40.0, Structure.Kind.GATE)
	var bridge := env.add_structure(Rect2(0, 5, 2.0, 2.4), 6.0, Structure.Kind.BRIDGE)
	var field := env.add_structure(Rect2(0, 10, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD)
	var temple := env.add_structure(Rect2(10, 0, 2.7, 3.1), 56.0, Structure.Kind.TEMPLE)
	var stall := env.add_structure(Rect2(10, 5, 0.9, 0.7), 10.0, Structure.Kind.MARKET_STALL)
	t.check(gate.walkable and bridge.walkable and field.walkable, "gate, bridge and field are walkable")
	t.check(not temple.walkable and not stall.walkable, "temple and stall are not")
	t.check(not env.blocked(Vector2(1.4, 0.5)) and not env.blocked(Vector2(1, 6.2)), "units pass the gate and the bridge")
	t.check(env.blocked(Vector2(11.3, 1.5)) and env.blocked(Vector2(10.45, 5.35)), "units walk round the temple and stalls")

	# Fields burn flat: no rubble, no collapse, fully charred.
	field.destroy(Vector2(1, 11), &"cinder")
	t.check(field.destroyed and field._rubble.is_empty() and field._collapse < 0.0, "a field burns flat without rubble")
	t.near(field.scorch, 1.0, 0.001, "a burnt field is fully charred")
	var frozen := env.add_structure(Rect2(4, 10, 2.6, 1.8), 3.0, Structure.Kind.FARM_FIELD)
	frozen.destroy(Vector2(5, 11), &"ice")
	t.near(frozen.frost, 1.0, 0.001, "a frozen field is iced over")

	# Trees are felled to a stump among leaves: no cracks, no collapse, and a laser does not slice them.
	var tree := env.add_structure(Rect2(20, 0, 0.7, 0.7), 26.0, Structure.Kind.TREE)
	tree.damage(tree.max_hp * 0.5, Vector2(19, 0), &"fire")
	t.check(tree._cracks.is_empty(), "trees do not crack")
	tree.destroy(Vector2(19, 0), &"laser")
	t.check(tree.destroyed and not tree._rubble.is_empty() and tree._top_piece.is_empty() and tree._collapse < 0.0,
		"a tree is felled into leaves, not sliced or collapsed")

	# Big buildings still collapse into rubble.
	temple.destroy(Vector2(9, 0), &"stone")
	t.check(temple._collapse == 0.0 and not temple._rubble.is_empty(), "the temple collapses into rubble")
	t.check(Structure.WALKABLE.size() == 3, "three walkable kinds")
	env.clear()
	env.free()
