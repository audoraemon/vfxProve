extends RefCounted
## The Prisoner in the Capital (plan "The Capital at every tier", Task 11; spec 6.2.4): she stands in the stocks at the south road's head below
## the Keep's gate and is led along the south road and the cross avenue to the harbour gate and out to the quays. Its watch stands either side
## of the gate's mouth; the guardhouse is in the quarter beyond; the patrols walk the Keep's square and the avenue. The Keep's gate is the place
## citadel_gate (the director reads it). Floats carry a decimal point and tags are &"..." (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(8.0, -15.0)
	var stocks := Vector2(4.0, -19.0)
	var mouth := Vector2(16.4, -9.0)
	var out := Vector2(19.6, -9.0)
	return {
		"def": {
			"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0),
			"goal": "Break the prisoner out of the stocks by %s and lead her out by the harbour gate" % UiTheme.clock(PrisonerDirector.FREE_BY),
		},
		"director": {
			"stocks_at": stocks,
			"lane_foot": Vector2(4.0, -21.0),
			"charge_start": stocks + Vector2(0.0, 1.0),
			"gate_at": mouth,
			"exit_at": out,
			"watch_posts": [Vector2(16.4, -9.9), Vector2(16.4, -8.1)],
			"guardhouse": Vector2(16.0, -4.0),
			"beat_spots": [[Vector2(0.0, -16.5), Vector2(8.0, -16.5)], [Vector2(10.0, -13.0), Vector2(10.0, -4.0)]],
			"road": [stocks + Vector2(0.0, 1.0), Vector2(4.0, -9.0), mouth, out],
			"gate_words": "The harbour gate, out to the quays. Its guard changes soon after she draws near.",
			"exit_name": "HARBOUR GATE",
		},
	}
