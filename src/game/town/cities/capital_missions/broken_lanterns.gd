extends RefCounted
## Broken Lanterns in the Capital (plan "The Capital at every tier", Task 3; spec 6.1.2): the six wayside shrines in the Vigil's order round the
## Temple, spread over the old town; the Temple's door, the Knights' coming and the flame-bearer's round are door- and shrine-relative and move by
## themselves. The intro rests north of the Temple. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	# The spec's first guesses (camera (-1, -9); shrines (1.5, -12.6), (7, -16), (14, -11), (12, -1), (-2.5, -1), (-14.5, -11.5)) put shrines on the west
	# road and the lane, one off the ground, and tags under the HUD stack. These are the nearest spots with clear ground (footprint off every road and
	# building, both Knights' posts and the relight point walkable), and the nearest camera that keeps the Temple door and all six arrows clear.
	var camera := Vector2(-4.0, -6.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {"shrine_spots": [Vector2(2.0, -11.5), Vector2(7.0, -14.5), Vector2(9.5, -11.5), Vector2(5.5, 0.0),
			Vector2(-3.0, -0.5), Vector2(-16.5, -14.5)]},
	}
