extends RefCounted
## The Heretic Hunt in the Capital (plan "The Capital at every tier", Task 12; spec 6.2.5): the Inquisition sweeps the cathedral quarter, the
## west market and the south gate quarter in turn, closing on the cellar (walks 36.8 / 27.6 / 17.9, Aldermere's 31.2 / 16.5 / 20.6), then its
## captain (the Temple's own door, the one the Lost Lamb returns to) searches the houses round the cellar. The sweeps' areas are the Capital's
## own rectangles (its quarters are not Aldermere's districts); the third one (x -8..10, y 5..19) overlaps the cellar's area (x -16..0, y 10..18) on x -8..0, y 10..18 and does not hold the cellar itself.
## The cellar stands at (-10, 15) in the area (-16, 10, 16, 8), not the plan's (-21, 1) in the west: the west ward holds one house, so the
## captain walked 17.5 to it against Aldermere's 32.0 (0.55x); here 38.9 (1.22x). His search is longer than Aldermere's (98.6 walked against
## 65.5), so the last step is 200 s, not 240 s: a night with nothing cast loses by the cellar found (326-355 s; Aldermere's 323-342).
## The camera rests at (-9, 9): it keeps the three sweeps' spots, the cellar's door and the Temple's door (or their arrows) clear of the HUD stack.
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-9.0, 9.0)
	return {
		"def": {"camera_at": camera, "intro_from": Vector2(-9.0, 15.0)},
		"director": {
			"sweep_spots": [Vector2(-6.0, -12.0), Vector2(-20.0, -6.0), Vector2(3.0, 10.0)],
			"sweep_words": ["the cathedral quarter", "the west market", "the south gate quarter"],
			"sweep_areas": [Rect2(-9.0, -21.0, 17.0, 12.0), Rect2(-24.0, -9.0, 22.0, 13.0), Rect2(-8.0, 5.0, 18.0, 14.0)],
			"cellar_at": Vector2(-10.0, 15.0),
			"cellar_area": Rect2(-16.0, 10.0, 16.0, 8.0),
			"temple_door_at": Vector2(-3.9, -14.0),
			"step_at": [60.0, 115.0, 185.0, 200.0],
		},
	}
