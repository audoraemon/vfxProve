extends RefCounted
## First Prayers in the Capital (v0.12 M2, Task 13; spec 2.5): the old well shrine on the Great Market's free south promenade, the poor
## of the west market (merchants, a tight cluster 9-13 from the shrine's door, as Aldermere's south-west quarter is 10-12), and an intro
## that rests between the two (the poor, west of the shrine, would sit under the HUD stack at a camera on the shrine). Every other number
## is Aldermere's (the director's consts). The values are written for Overrides: floats with a decimal point; the director snaps the spots.


static func overrides() -> Dictionary:
	var shrine := Vector2(-9.25, 0.75)
	var poor := Vector2(-19.75, -2.25)
	var camera := shrine.lerp(poor, 0.8)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {"shrine_at": shrine, "poor_spot": poor, "poor_quarter": "west market"},
	}
