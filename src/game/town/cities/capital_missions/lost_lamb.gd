extends RefCounted
## The Lost Lamb in the Capital (v0.12 M2, spec 2.4): the acolyte hides by the civic square's fountain and is led out of the old town by its
## west gate (the mission's own words), past two posts either side of the mouth and two patrols; the cathedral's door is where a seizer
## takes him back. Every spot is the town's (the director snaps the gate, exit, return and guardhouse to walkable ground at setup).
## Floats carry a decimal point and tags are StringNames (Overrides is strict).


static func overrides() -> Dictionary:
	var start := Vector2(6.1, -15.2)
	var gate := Vector2(-22.4, -13.0)
	# Not start.lerp(gate, 0.3): the gate lies far up-left of the acolyte on the screen, so with the acolyte in view its arrow
	# sits in the HUD stack. Here (the Great Market's west edge) the acolyte's arrow is at the right edge and the gate's at the top.
	var camera := Vector2(-12.0, -2.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"charge_start": start,
			"gate_at": gate,
			"exit_at": Vector2(-25.6, -13.0),
			"watch_posts": [Vector2(-22.2, -13.9), Vector2(-22.2, -12.1)],
			"guardhouse": Vector2(-22.6, -6.0),
			"return_to": Vector2(-3.9, -14.0),
			"hideout_name": "the civic square's fountain",
			"beat_spots": [[Vector2(-14.0, -19.0), Vector2(-14.0, -7.0)], [Vector2(-18.5, -10.25), Vector2(-10.0, -10.25)]],
		},
	}
