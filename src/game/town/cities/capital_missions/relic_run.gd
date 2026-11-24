extends RefCounted
## The Relic Run in the Capital (plan "The Capital at every tier", Task 18; spec 6.3.5): the cart's route, the words of its two halts, the drop-off and Pip's spot, and
## the camera, placed to Aldermere's shape by a search on the real walk grid (Task 18 report, "Opus placement search"). The first halt (-13.0, -14.0) stands in the noble
## quarter's patrician street, 9.3 of walking west of the Temple's door (Aldermere 9.3), among few of the Faithful; the cart rolls back east past the door and through the
## pilgrim plaza (route point (3.0, -10.0)) to the second halt (10.0, -9.0) before the bathhouse, 25.8 on (Aldermere 30.7: a shorter leg, so the policy waits less between the
## halts) and 16.4 of walking from the Temple's door (Aldermere 20.5), then by (9.0, -13.0) and the fountain (5.5, -17.5) to the Citadel's gate: 46.2 in all (Aldermere 53.1).
## Pip stands at (-7.0, -7.0) on the Great Market's north side, 11.3 from the first halt (Aldermere 11.8); the drop-off is the dwelling by (-16.0, -5.0), its door 28.3 of
## carrying from the second halt (Aldermere 33.0) and 17.4 from the spire. The camera (-12.0, -9.5) keeps the Temple's door, both halts, Pip, the drop-off's door and the
## Citadel's gate on screen or as edge arrows outside the HUD stack.
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-12.0, -9.5)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"cart_route": [Vector2(-13.0, -14.0), Vector2(3.0, -10.0), Vector2(10.0, -9.0), Vector2(9.0, -13.0), Vector2(5.5, -17.5), Vector2(0.0, -22.6)],
			"check_words": ["the noble quarter watch-house", "the bathhouse watch-house"],
			"drop_spot": Vector2(-16.0, -5.0),
			"pip_spot": Vector2(-7.0, -7.0),
		},
	}
