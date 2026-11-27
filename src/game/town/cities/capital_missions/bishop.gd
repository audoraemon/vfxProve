extends RefCounted
## The Bishop in the Capital (plan "The Capital at every tier", Task 15; spec 6.3.2): he waits in the Keep and goes to ground in his house on the
## south road's east side, then the chapter house beside the civic square, then the Cathedral (the Temple). The spec's spots (12.4,-12.5) and (6.5,-18.0)
## have no second dwelling near them (the north-east quarter holds four houses in a row: his house to the next is 5.5 of walking, 0.67x Aldermere's), so the
## two refuges are the square's houses (10.1,-5.1) and (1.6,-5.1): the three key walks measure 1.06x, 1.00x and 1.00x Aldermere's. The camera moved
## from (4.0,-14.0), which put the Cathedral's door under the HUD stack, to (2.0,-9.0). The Keep's gate is the place citadel_gate (the director's `safe_at`
## starts there; the override says it too). Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(2.0, -9.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"refuge_spots": [Vector2(10.1, -5.5), Vector2(1.6, -5.4)],
			"safe_at": Vector2(0.0, -22.6),
		},
	}
