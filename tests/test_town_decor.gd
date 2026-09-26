extends RefCounted
## The town's floor trails and decor: placement rules, damage, the fountain and chimney smoke.


static func run(t) -> void:
	var trails_ok := not TownFloor.TRAILS.is_empty()
	for tr: Array in TownFloor.TRAILS:
		for p: Vector2 in tr:
			trails_ok = trails_ok and not TownLayout.TOWN.grow(0.8).has_point(p) \
				and not TownLayout.RIVER.grow(0.3).has_point(p)
	t.check(trails_ok, "dirt trails stay outside the walls and out of the river")
