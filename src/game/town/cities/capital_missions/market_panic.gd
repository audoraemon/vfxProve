extends RefCounted
## Market Panic in the Capital (plan "The Capital at every tier", Task 5; spec 6.1.4): the night fair is held where the old town's houses stand close,
## west of its centre, so that a fire there frightens a crowd (the spec's north-end guess had five burnable buildings within six of it, Aldermere's
## heart 23); the later crowds come in from the north, the east and the west. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	return {
		"def": {"camera_at": Vector2(-5.0, -3.5), "intro_from": Vector2(-5.0, 2.5),
			"brief": PackedStringArray(["A night fair fills the old town's streets.", "Scatter it before the market closes."])},
		"director": {"heart": Vector2(-3.5, -5.0),
			"sources": [Vector2(-3.5, -5.0), Vector2(-4.0, -14.0), Vector2(9.0, -3.0), Vector2(-13.0, -9.0)],
			"source_names": ["the old town", "the northern lanes", "the eastern lanes", "the western lanes"]},
	}
