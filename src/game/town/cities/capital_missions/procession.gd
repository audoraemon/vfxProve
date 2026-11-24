extends RefCounted
## The Procession in the Capital (plan "The Capital at every tier", Task 14; spec 6.3.1): the Prince leaves the Keep's court by its south, stops at the
## cathedral's door for the blessing, walks the avenue to the harbour gate and out onto the quay, waits on the quay's waiting ground and boards at the pier
## (the Capital's ship lies at its end, CapitalCity.ship_at()). The landmark route would lead him through the Great Market, so the Capital names its five points
## The first point is (0, -20.5), not the spec's (0, -22.4): from the court's edge the Prince was alone within five act-seconds on two seeds of three and the scripted play won at 50 s; with it 3 of 3 win, two of them slow (fix round 1).
## (the blessing leg is index 1 and the dock leg index 3, as at Aldermere). Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	return {
		"def": {"camera_at": Vector2(-1.0, -12.0), "intro_from": Vector2(0.0, -25.5)},
		"director": {
			"route_spots": [Vector2(0.0, -20.5), Vector2(-3.9, -14.1), Vector2(16.4, -9.0), Vector2(31.0, -4.1), Vector2(31.0, -2.8)],
		},
	}
