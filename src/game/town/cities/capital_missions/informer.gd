extends RefCounted
## The Informer in the Capital (plan "The Capital at every tier", Task 6; spec 6.1.5): the old town's ring holds only 18 dwellings the mission
## calls a house (the townhouses; the noble quarter's are role gpt), so every spot is a townhouse's own centre: the chandler's by the middle
## of the guild row, the weaver's east of it, the potter's in the south of the ring, the carpenter's (the hiding place) in the north-east
## corner, where the informer's lodging also stands (the next townhouse west). The Temple is the Capital's cathedral: its door is the one
## the Lost Lamb returns to. Visit times and the chain are Aldermere's. The intro rests over the old town's middle (the chandler's door,
## the Temple's and the carpenter's clear of the HUD stack). Mira's house (the east tenement) is neither a contact nor the lodging.
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var door := Vector2(-3.9, -14.0)
	return {
		"def": {"camera_at": Vector2(2.0, -10.0), "intro_from": Vector2(2.0, -4.0)},
		"director": {
			"contact_spots": [Vector2(6.3, -5.1), Vector2(11.9, -3.55), Vector2(-0.27, 1.1), Vector2(14.4, -15.1)],
			"lodging_at": Vector2(10.2, -15.1),
			"temple_door_at": door,
			"safe_at": door,
		},
	}
