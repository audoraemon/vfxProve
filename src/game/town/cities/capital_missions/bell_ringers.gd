extends RefCounted
## The Bell-Ringers in the Capital (plan "The Capital at every tier", Task 4; spec 6.1.3): three watch posts on the old town's west and north walls
## (the wall tower nearest each spot), each with a town-side door; the bell's foot, the ringers' run and the mates are door- and foot-relative and move
## by themselves. The intro rests inside the west wall. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-14.0, -22.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {"post_spots": [Vector2(-3.0, 3.65), Vector2(5.0, -30.0), Vector2(-24.0, -5.0)],
			"post_names": ["south", "north", "west"]},
	}
