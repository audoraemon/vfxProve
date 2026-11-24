## The Lantern's Eye in the Capital (plan "The Capital at every tier", Task 21; spec 6.4.3): the Searchlight burns from the cathedral's spire (the Temple's centre,
## (-3.9, -17.7); the director's `spire` var, since Places.at(&"temple") is one ulp off Aldermere's const there) and the three mirrors hang on three wall towers of the
## old town's ring, each the standing wall tower nearest its point: a tower on the north wall, the east tower on the east wall and a tower on the south wall, 20.7, 21.8
## and 21.4 from the spire, all within the light's reach. Two of the spec's points were moved (measured, task-21-report.md):
## - the south point (-11.0, 4.0) is the west river gate's east tower (a gate tower); (-3.0, 4.0) is the plain wall tower beside it;
## - the north point (-11.0, -30.0) is the tower under the Keep's garrison (22 soldiers within 8, against 4 in Aldermere): with it first, the scripted player's route A
##   never shattered a mirror (0 of 3: a guard of that tower stayed within reach of it from 0:40 to the end and was never taken unseen). (13.0, -30.0) has 3 soldiers within 8
##   and wins both routes; the other towers tried first (-19.0, -30.0 and the west tower) won route A but lost every route B run. Its third guard's post falls 0.5 beyond
##   the wall, beside the tower (the north-east corner tower leaves no room inside): the test pins that one post.
## The words say north, east and south: true by place. The camera rests at the spec's (-4.0, -14.0). Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-4.0, -14.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"spire": Vector2(-3.9, -17.7),
			"tower_points": [Vector2(13.0, -30.0), Vector2(18.0, -21.0), Vector2(-3.0, 4.0)],
			"tower_words": ["the north tower", "the east tower", "the south tower"],
		},
	}
