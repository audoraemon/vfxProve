extends RefCounted
## The Crown's Bread in the Capital (plan "The Capital at every tier", Task 10; spec 6.2.3, decision 1): the Great Market's market hall is the granary
## and the bakery behind it is the mill, both in the old town; the bridge is the west stone bridge, with the bridge shift in the west river gate's west
## tower (gate_towers()[0]). The Capital has no watermill, so the words the player reads are the town's own: names, words and the strip's labels are
## the director's town vars, and the def's brief and goal are said again here. Floats carry a decimal point and tags are &"..." (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-13.0, -2.0)
	return {
		"def": {
			"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0),
			"brief": PackedStringArray(["The Crown's bread is made tonight.", "Destroy the market hall, the bakery and the bridge."]),
			"goal": "Raze the market hall, the bakery and the bridge, each while it is in use, before the Crown's carts roll at %s" % UiTheme.clock(
				CrownsBreadDirector.CARTS_AT),
		},
		"director": {
			"granary_tag": &"gpt_markethall", "mill_tag": &"gpt_bakery", "bridge_at": Vector2(-14.0, 8.0),
			"names": ["MARKET HALL", "BAKERY", "BRIDGE"], "words": ["market hall", "bakery", "bridge"],
			"stage_labels": ["The grain carts fill the market hall", "The bakers bake the Crown's bread", "The bread carts gather at the bridge"],
		},
	}
