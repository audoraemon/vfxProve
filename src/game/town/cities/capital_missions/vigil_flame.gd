extends RefCounted
## The Vigil Flame in the Capital (plan "The Capital at every tier", Task 8; spec 6.2.1): the Vigil walks Task 3's six shrine spots (the same literals as
## Broken Lanterns' here; the Relic Run shares them), Wren carries the flame to Mira's shrine by Mira's house, and the intro rests north-west of the
## Temple. The Temple's door, the Searchlight and the bearer's pace are door- and spire-relative and move by themselves. Floats carry a decimal point
## (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-3.0, -12.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {"route_spots": [Vector2(2.0, -11.5), Vector2(7.0, -14.5), Vector2(9.5, -11.5), Vector2(5.5, 0.0), Vector2(-3.0, -0.5),
			Vector2(-16.5, -14.5)], "mira_shrine": Vector2(32.0, -16.0)},
	}
