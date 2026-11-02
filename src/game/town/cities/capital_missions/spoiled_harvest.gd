extends RefCounted
## Spoiled Harvest in the Capital (v0.12 M2, Task 11, spec 2.3): three granaries among the old town's dwellings (inside the wall
## ring, no route over the river), each given as a spot on the ground at its dwelling's door so the director picks that house and
## no neighbour. Their walks from the Keep's gate and the watchmen's posts are checked by tests/test_capital_harvest.gd.
## Floats carry a decimal point and the names are Strings, as the seeded vars are (Overrides is strict).

## The three granaries' doors, in the order their grain arrives: west, south and east.
const STORE_SPOTS := [Vector2(-16.19, -5.4), Vector2(-0.27, 2.1), Vector2(11.88, -2.58)]
const STORE_NAMES := ["west", "south", "east"]


static func overrides() -> Dictionary:
	var camera: Vector2 = STORE_SPOTS[0] + Vector2(0.25, 0.25)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {"store_spots": STORE_SPOTS.duplicate(), "store_names": STORE_NAMES.duplicate()},
	}
