extends RefCounted
## The Sermon in the Capital (plan "The Capital at every tier", Task 17; spec 6.3.4), placed by a search of every Capital well and dwelling for Aldermere's shape (real grid
## walks): the preacher holds the Capital's well 1, in the south-west houses; the god's house is the dwelling at (-20.5, 18.7), its door 8.9 from the pulpit as the crow
## flies but 12.0 of walking (Aldermere 6.1 and 15.1), about 7 from the first wave's nearest ring place (one Mind Whisper; Aldermere 3.0), with 8 soldiers within 8 of it at
## the start (Aldermere 7). Its report run to the Temple's door is 44.3 (Aldermere 30.7, 1.44x): the two dwellings a first-wave listener reaches with a report run in the
## band (1.33x, 1.38x) have 11 soldiers by the door (the first gate there won 1 of 3), and the spec's well 3 and house (13.0, -2.5) sit in the watched centre, 14.5 from the Temple. The sources walk 23.6 / 11.5 / 12.7 to the pulpit
## (Aldermere 23.3 / 11.5 / 12.6) and stand 9.4 / 11.0 / 5.9 from the god's door (Aldermere 10.0 / 13.0 / 5.9); the waves come at Aldermere's times. Floats carry a
## decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	return {
		"def": {"camera_at": Vector2(-23.0, 20.0), "intro_from": Vector2(-23.0, 26.0)},
		"director": {
			"pulpit_well": 1,
			"house_spot": Vector2(-20.5, 18.7),
			"sources": [Vector2(-27.75, 13.45), Vector2(-10.25, 22.95), Vector2(-25.75, 22.95)],
			"wave_at": [0.0, 95.0, 185.0, 260.0],
		},
	}
