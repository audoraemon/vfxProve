extends RefCounted
## Plan "The Capital at every tier", Task 1: the Capital names its west river gate's towers (spec 3, decision 9: the old town's
## INNER_GATES[1]) so the Armoury and the Crowns' Bread find the "gate_towers" they need. The two rects are built towers west to east
## beside (-14, 4); the Capital has the places of both missions but hosts neither yet (no overrides file); Aldermere's are untouched.

const Cap := preload("res://tests/capital_kit.gd")


static func run(t) -> void:
	City.use(&"capital")
	_two_towers(t)
	_needs(t)
	City.use(&"aldermere")
	t.check(City.current().gate_towers().size() == TownLayout.GATE_TOWERS.size(), "Aldermere keeps its own gate towers")


static func _two_towers(t) -> void:
	var capital := City.by_id(&"capital")
	var towers := capital.gate_towers()
	t.check(towers.size() == 2, "the Capital has two gate towers (%d)" % towers.size())
	if towers.size() != 2:
		return
	t.check(towers[0].position.x < towers[1].position.x, "the west tower is first (%s, %s)" % [towers[0], towers[1]])
	var gate := Vector2(-14.0, 4.0)
	for r: Rect2 in towers:
		t.check(r.get_center().distance_to(gate) <= 3.0, "the tower %s stands within 3 of the west river gate %s (%.2f)" % [r, gate, r.get_center().distance_to(gate)])
	# Built in a Capital, each rect is a tower structure of the keep kind.
	var b := Cap.town(&"capital")
	var found := [false, false]
	for s: Structure in (b.env as EnvironmentField).structures():
		for k in 2:
			if s.footprint == towers[k] and s.role == &"tower" and s.kind == Structure.Kind.KEEP:
				found[k] = true
	t.check(found[0] and found[1], "each gate tower is a built KEEP structure with role tower (%s)" % [found])
	Cap.drop(b)
	City.use(&"capital")
	t.check(capital.gate_towers() == towers, "the gate towers are cached and stable")


static func _needs(t) -> void:
	var capital := City.by_id(&"capital")
	t.check(Places.can_host("crowns_bread", capital), "the Capital has the places of the Crowns' Bread")
	t.check(Places.can_host("armoury", capital), "the Capital has the places of the Armoury")
	t.check(MissionBook.hostable("crowns_bread", capital), "and hosts the Crowns' Bread (Task 10: its overrides file)")
	t.check(MissionBook.hostable("armoury", capital), "and hosts the Armoury (Task 16: its overrides file)")
