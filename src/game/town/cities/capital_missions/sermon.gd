extends RefCounted
## The Sermon in the Capital (plan "The Capital at every tier", Task 17; spec 6.3.4): the preacher holds the old town houses' well (the Capital's well 3, east of x = 8).
## The spec's god's house (13.0, -2.5) is not a house the night can use: the dwellings there stand within the preacher's voice, and the next one east is 14 away, beyond one
## Mind Whisper (it reaches 10), so no listener is ever brought in (measured: a house at (8.0, 14.0), 0 believers in 300 s). The house is the dwelling nearest (1.5, -5.0), 10.4 of walking
## from the pulpit. The sources are the spec's moved to Aldermere's walks to the pulpit (21 / 10 / 13 against 23 / 12 / 13: the spec's 12 / 10 / 8 were short); the waves come at 85, 160 and 230
## (Aldermere 95, 185, 260). The camera rests at (8.0, 4.0), not the spec's (11.0, -1.0), which put the western sources under the HUD stack. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	return {
		"def": {"camera_at": Vector2(8.0, 4.0), "intro_from": Vector2(8.0, 10.0)},
		"director": {
			"pulpit_well": 3,
			"house_spot": Vector2(1.5, -5.0),
			"sources": [Vector2(-6.0, -9.0), Vector2(14.0, -5.5), Vector2(-2.0, -3.0)],
			"wave_at": [0.0, 85.0, 160.0, 230.0],
		},
	}
