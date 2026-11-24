extends RefCounted
## The Relic Run in the Capital (plan "The Capital at every tier", Task 18; spec 6.3.5): the cart's route (the spec's six points), the words of its two halts, the drop-off and
## Pip's spot, and the camera. The first halt (14.0, 1.5) stands 2.5 inside the old town's south-east gate (14.0, 4.0), not at the harbour gate (18.0, -9.0), so its
## words are the south-east gate's; the second (-2.0, -9.0) is 1.1 south of the pilgrim plaza. Pip stands at (8.0, -6.0): his walk to the first halt is 12.4 (Aldermere 11.8; the
## spec's (10.0, 0.0) was 5.0), with 6 soldiers within 8 (Aldermere 10). The camera (5.0, -3.5) keeps the Temple's door, both halts, Pip, the drop-off's door and the Citadel's
## gate on screen or as edge arrows outside the HUD stack (the spec's (8.0, -6.0) put the door's and the second halt's arrows under it).
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(5.0, -3.5)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"cart_route": [Vector2(14.0, 1.5), Vector2(14.0, -9.0), Vector2(-2.0, -9.0), Vector2(-2.0, -13.0), Vector2(4.0, -13.0), Vector2(0.0, -22.6)],
			"check_words": ["the south-east gate watch-house", "the plaza watch-house"],
			"drop_spot": Vector2(16.0, -14.0),
			"pip_spot": Vector2(8.0, -6.0),
		},
	}
