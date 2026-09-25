extends RefCounted
## Draw order between people and buildings: a person in front of a long building sorts after it, one behind
## sorts before it, a person whose own feet already do stays put, a contradiction is left alone, and flat
## things people walk on are drawn under them.


static func run(t) -> void:
	# A long, low building running east-west: its south-east corner sorts at (4 + 1) * 16 = 80.
	var long := Structure.new().setup(Rect2(0.0, 0.0, 4.0, 1.0), 40.0, Structure.Kind.BLOCK, 1)
	var near: Array[Structure] = [long]

	# In front of its south face, near the WEST end: the case the playtest saw.
	var front := Vector2(0.5, 1.6)
	var own := (front.x + front.y) * 16.0
	var bias := Person.sort_bias_for(front, near)
	t.check(own < long.position.y, "the person's own feet sort before the building (%.1f < %.1f)" % [own, long.position.y])
	t.check(bias > 0.0 and own + bias > long.position.y, "so the person is lifted past it (+%.1f)" % bias)

	# Behind it: the feet already sort before it, nothing to do.
	t.check(Person.sort_bias_for(Vector2(2.0, -0.6), near) == 0.0, "a person behind the building is left behind it")
	# In front of the east end, far enough that the feet already sort after it: nothing to do either.
	t.check(Person.sort_bias_for(Vector2(4.5, 1.2), near) == 0.0, "a person whose own feet already sort in front is left alone")

	# A contradiction: in front of the long building and behind a small one whose key is lower. No single key
	# can be both, so nothing changes rather than guessing.
	var small := Structure.new().setup(Rect2(0.8, 1.9, 0.6, 0.5), 30.0, Structure.Kind.BLOCK, 2)
	var both: Array[Structure] = [long, small]
	t.check(Person.sort_bias_for(front, both) == 0.0, "a person who would have to be both in front and behind is left alone")

	# Things people walk on and rubble do not constrain anyone.
	var bridge := Structure.new().setup(Rect2(0.0, 0.0, 4.0, 1.0), 20.0, Structure.Kind.BRIDGE, 3)
	var only_bridge: Array[Structure] = [bridge]
	t.check(Person.sort_bias_for(front, only_bridge) == 0.0, "a bridge does not lift anyone: it is drawn under them instead")
	t.check(bridge.z_index < 0, "and a bridge is drawn under the people on it (z %d)" % bridge.z_index)
	var field := Structure.new().setup(Rect2(0.0, 0.0, 2.0, 2.0), 4.0, Structure.Kind.FARM_FIELD, 4)
	var house := Structure.new().setup(Rect2(0.0, 0.0, 1.0, 1.0), 30.0, Structure.Kind.HOUSE, 5)
	t.check(field.z_index < 0 and house.z_index == 0, "so is a field, and a house is not")
	long.destroyed = true
	t.check(Person.sort_bias_for(front, near) == 0.0, "rubble does not lift anyone")

	# The shift moves the sort key, not the body.
	var p := Person.new()
	p.ground_pos = front
	p.sort_bias = 20.0
	p._sync_position()
	var feet := Iso.ground_to_screen(front).round()
	t.check(p.position.y == feet.y + 20.0 and p._draw_origin.y == -20.0,
		"a biased person sorts 20 px later and is still drawn at its feet (%.0f, %.0f)" % [p.position.y, p._draw_origin.y])

	for n: Node in [long, small, bridge, field, house, p]:
		n.free()
