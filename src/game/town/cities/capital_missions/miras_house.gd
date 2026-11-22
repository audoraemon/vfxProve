extends RefCounted
## Mira's House in the Capital (plan "The Capital at every tier", Task 2; spec 6.1.1): Mira's house is a patrician house in the noble quarter,
## a quieter door than the Great Market's; the Temple door, the shout, the line and the Vigil's way are door- or landmark-relative and move by
## themselves. The intro rests at her door. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var spot := Vector2(-18.0, -15.5)
	return {
		"def": {"camera_at": spot, "intro_from": spot + Vector2(0.0, 6.0)},
		"director": {"mira_spot": spot},
	}
