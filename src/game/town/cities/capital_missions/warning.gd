extends RefCounted
## The Capital's changes to the board's Warning (Starfall; v0.12 M2 Task 9, spec 2.1). Played inside the old town's wall ring
## (INNER): the three stars fall far to near over the harbour gate, the west river gate and the west gate, each watchman
## posted just inside his gate, each run ending at the bellkeeper's foot below the cathedral's bell tower. The spots are
## literals, snapped to walkable ground by the director at setup. Floats carry a decimal point (Overrides is strict).
## The river gate's post stands 3.4 inside the gate (y 0.6, not the gate's 2.4): at 2.4 its run to the bell is 1.65x Aldermere's
## Main Gate run, over the 1.6x band (tests/test_capital_starfall.gd prints both walks).

## The first star's gate (inside the harbour gate) and the bell tower's centre: the camera rests a third of the way from the
## first post to the tower, as Aldermere's rests between the Main Gate and its tower.
const HARBOUR_POST := Vector2(16.4, -9.0)
const BELL_CENTRE := Vector2(-8.05, -20.05)


static func overrides() -> Dictionary:
	var camera := HARBOUR_POST.lerp(BELL_CENTRE, 0.35)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"star_falls": [
				[10.0, HARBOUR_POST, "THE HARBOUR GATE"],
				[90.0, Vector2(-14.0, 0.6), "THE RIVER GATE"],
				[180.0, Vector2(-22.4, -13.0), "THE WEST GATE"],
			],
		},
	}
