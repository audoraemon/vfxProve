extends RefCounted
## The Tax Collector in the Capital (v0.12 M2, Task 10, spec 2.2): the counting-house is the Great Market's weigh-house; the three rounds
## are walked inside the old town's wall ring (no bridge); the collectors end at the Keep's gate (the place citadel_gate). Floats are
## written with a decimal point and tags as &"..." (Overrides is strict about types).
## The old town has only 18 dwellings (townhouses of the guild row, the north-east corner, one in the west), so every spot is a dwelling's
## own centre: the three rounds use eight distinct ones. Set-out times, chain, visits and flush gap are Aldermere's (the gate passed
## with the spots alone). The camera rests on the weigh-house + (-2, 3), as Aldermere's rests on its counting-house.


static func overrides() -> Dictionary:
	return {
		"def": {
			"camera_at": Vector2(-7.35, -3.95),
			"intro_from": Vector2(-7.35, 2.05),
		},
		"director": {
			"counting_tag": &"gpt_weighhouse",
			"counting_spot": Vector2(-6.2, -7.7),
			"rounds": [
				[Vector2(10.0, -3.6), Vector2(-0.3, 1.1), Vector2(-16.2, -6.4)],
				[Vector2(11.9, -3.6), Vector2(10.2, -15.1)],
				[Vector2(6.3, -5.1), Vector2(14.6, -13.4), Vector2(8.4, -0.5)],
			],
		},
	}
