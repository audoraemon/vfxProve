extends RefCounted
## Last Judgement in the Capital (plan "The Capital at every tier", Task 20; spec 6.4.1): the director tags the active city's Citadel, exits, rite and boats, so it
## needs no town var; only the words of the brief and the intro's start (the harbour gate) are the Capital's. The camera stays unset: the Capital's Citadel.
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	return {
		"def": {
			"brief": PackedStringArray(["The Capital and its Royal Keep.", "Bring the whole kingdom down."]),
			"intro_from": Vector2(16.4, -9.0),
		},
		"director": {},
	}
