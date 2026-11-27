extends RefCounted
## The Armoury in the Capital (plan "The Capital at every tier", Task 16; spec 6.3.3): the first target is the west market tavern (taverns()[0]), the
## second the west river gate's east tower (gate_towers()[1]) and the third the Keep's barracks, all found by the director from the town's own lists.
## The words the player reads say west barracks, gate barracks, armoury; the third horn's label is Aldermere's. The reserve waits at the place citadel_gate.
## The camera rests at (-16.0, -4.0), not the spec's (-16.0, -6.0), which put the west tavern under the HUD stack (the targets span 31 north to south): now the tavern and the
## tower are on screen clear of the stack, and the Keep's barracks is an edge arrow on the right. Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-16.0, -4.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"words": ["west barracks", "gate barracks", "armoury"],
			# The third horn at 150 s at the latest: the previous horn (110) plus CHAIN (40). Measured (task-16-report.md): route A stage 3 is 1.05x Aldermere's
			# horn-to-raze time, route B 0.50x (its policy clears the night watch before the horn and the Keep's gate stands beside its barracks, so the
			# reinforcements arrive in 8 of walking, not 36); a lower value would pull route A's median under 180 s.
			"stage_at": [40.0, 110.0, 150.0],
			"horn_labels": ["The muster horn: the west barracks turns out", "The muster horn: the gate barracks turns out", "The muster horn: the garrison arms"],
		},
	}
