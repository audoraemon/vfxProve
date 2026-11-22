extends RefCounted
## Mira's House in the Capital (plan "The Capital at every tier", Task 2; spec 6.1.1, ruled in fix round 1): Mira's house is the east tenement
## outside the old town's east gate, a poor and quiet door; its walk to the Temple door (29.3) is in Aldermere's band (37.1 x 0.75-1.35). The
## Temple door, the shout, the line and the Vigil's way are door- or landmark-relative and move by themselves. The intro rests at her door. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	# Her door (just off the tenement's front): the dwelling nearest it is the tenement at (23.26, -12.37), whose own centre is not ground.
	var spot := Vector2(23.26, -11.25)
	# Not the spot: the Temple's door lies 27 west, so with the camera on her door its arrow sits in the HUD stack. Here (south of the tenement) the door's
	# arrow is at the top and the Temple's at the left edge, both clear of the padded stack, at the resting place and at the intro's start.
	var camera := Vector2(23.26, 4.75)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {"mira_spot": spot},
	}
