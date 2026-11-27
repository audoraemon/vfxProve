extends RefCounted
## Exodus in the Capital (plan "The Capital at every tier", Task 22; spec 6.4.4): three households hide in three dwellings of the old town and are led out by its west gate,
## its harbour gate and the bridge gate (the east river gate at the middle stone bridge) before the Inquisition shuts them. Snapped to the real town (task-22-report.md): the spec's house points had no dwelling near them, so each point is the front door of a real townhouse
## (west (-16.2, -5.4): the only dwelling in the west; east (12.3, -14.2); south (8.1, -2.6)); the second patrol's beat is moved from y -6 to y -7 so the south door is quiet;
## the harbour gate's posts stand along the approach (RIGHT, not the spec's DOWN: the road comes down the post's own line); the camera rests at (-9, 0) because the west
## door and gate would sit in the HUD stack from the spec's (-4, -8).
## Floats carry a decimal point and tags are &"..." (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-9.0, 0.0)
	return {
		"def": {
			"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0),
			"goal": "Lead ten of your twelve believers out of the Capital before the Inquisition shuts the last gate at %s" % UiTheme.clock(float(ExodusDirector.SHUT_AT[2])),
		},
		"director": {
			"house_points": [Vector2(-16.19398, -5.4), Vector2(12.29509, -14.17), Vector2(8.076139, -2.575)],
			"gate_mouths": [Vector2(-22.4, -13.0), Vector2(16.4, -9.0), Vector2(4.0, 2.4)],
			"gate_exits": [Vector2(-25.6, -13.0), Vector2(19.6, -9.0), Vector2(4.0, 5.6)],
			"gate_labels": ["WEST GATE", "HARBOUR GATE", "BRIDGE GATE"],
			"gate_words": ["the west gate", "the harbour gate", "the bridge gate"],
			"gate_along": [Vector2(0.0, 1.0), Vector2(1.0, 0.0), Vector2(1.0, 0.0)],
			"beat_spots": [[Vector2(-12.0, -20.0), Vector2(-12.0, -10.0)], [Vector2(2.0, -7.0), Vector2(12.0, -7.0)]],
			"temple_door_at": Vector2(-3.9, -14.0),
			"gate_at": Vector2(4.0, 2.4),
			"exit_at": Vector2(4.0, 5.6),
		},
	}
