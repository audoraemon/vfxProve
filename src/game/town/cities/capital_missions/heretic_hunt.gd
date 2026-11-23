extends RefCounted
## The Heretic Hunt in the Capital (plan "The Capital at every tier", Task 12; spec 6.2.5): the Inquisition sweeps the cathedral quarter, the
## noble quarter and the west market in turn, then its captain (the Temple's own door, the one the Lost Lamb returns to) searches the houses
## round the cellar in the old town's south-west corner, where the old town's houses stand together (the west holds a single house). The sweeps' areas are the Capital's own rectangles (its quarters are not Aldermere's districts);
## the times (60/115/185/240) are Aldermere's.
## The cellar stands at (-10, 15) in the area (-16, 10, 16, 8), not the plan's (-21, 1) in the west: the west ward holds one house, so the captain
## walked 17.5 to it against Aldermere's 32.0 (0.55x) and searched houses scattered across the town; here the walk is 1.22x.
## The camera rests at (-18, -8), west of the plan's (-14, -8): there the west market's spot fell under the HUD stack.
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-18.0, -8.0)
	return {
		"def": {"camera_at": camera, "intro_from": Vector2(-18.0, -2.0)},
		"director": {
			"sweep_spots": [Vector2(-6.0, -12.0), Vector2(-18.0, -15.0), Vector2(-20.0, -6.0)],
			"sweep_words": ["the cathedral quarter", "the noble quarter", "the west market"],
			"sweep_areas": [Rect2(-9.0, -21.0, 17.0, 12.0), Rect2(-24.0, -21.0, 15.0, 12.0), Rect2(-24.0, -9.0, 22.0, 13.0)],
			"cellar_at": Vector2(-10.0, 15.0),
			"cellar_area": Rect2(-16.0, 10.0, 16.0, 8.0),
			"temple_door_at": Vector2(-3.9, -14.0),
		},
	}
