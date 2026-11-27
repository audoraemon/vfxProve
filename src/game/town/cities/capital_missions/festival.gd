extends RefCounted
## The Festival in the Capital (plan "The Capital at every tier", Task 9; spec 6.2.2): the Capital's market square (Places.rect(&"market_square")) and the
## fountain in it are where the old town's feast is held; the director reads Places only, so only the intro camera is the town's. Floats carry a decimal
## point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-7.5, -2.5)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 8.0)},
	}
