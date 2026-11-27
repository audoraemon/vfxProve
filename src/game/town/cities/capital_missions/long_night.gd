extends RefCounted
## The Long Night in the Capital (plan "The Capital at every tier", Task 24; spec 6.4.2): three acts that are other missions' directors, so the overrides carry an `acts`
## section (MissionBook.apply_acts()). The Festival and the Procession are those missions' own: their acts take their files' values (one source: festival.gd, procession.gd),
## the night adds only what differs (nothing, for them). The Judgement's intro starts at the harbour gate as last_judgement.gd's does, and its camera is the Capital's Citadel
## (an act's camera is Aldermere's Citadel until set; the mission's own stays unset). The Omen is a WarningDirector: its watchman keeps the west gate (the `post` and `post_name`
## town vars) and the camera rests a tenth of the way from it to the bell tower (the spec's third, (-17.4, -15.5), put the watchman's tag under the HUD stack: the gate is 15 from the
## tower, so the tower shows as an edge arrow either way); the intro starts 6 south of it. Floats carry a decimal point
## (Overrides is strict).

const FESTIVAL := preload("res://src/game/town/cities/capital_missions/festival.gd")
const PROCESSION := preload("res://src/game/town/cities/capital_missions/procession.gd")
const JUDGEMENT := preload("res://src/game/town/cities/capital_missions/last_judgement.gd")


static func overrides() -> Dictionary:
	var camera := Vector2(-21.0, -13.7)
	var intro := Vector2(-21.0, -7.7)
	var judgement: Dictionary = JUDGEMENT.overrides().def
	return {
		"def": {"camera_at": camera, "intro_from": intro},
		"acts": {
			"omen": {
				"def": {
					"camera_at": camera, "intro_from": intro,
					"brief": PackedStringArray(["A star falls over the west gate.", "A watchman runs to wake the bell."]),
				},
				"director": {"post": Vector2(-22.4, -13.0), "post_name": "THE WEST GATE"},
			},
			"festival": {"def": FESTIVAL.overrides().def},
			"procession": PROCESSION.overrides(),
			"judgement": {"def": {"intro_from": judgement.intro_from, "camera_at": CapitalCity.CITADEL_ORIGIN}},
		},
	}
