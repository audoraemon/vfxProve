class_name LostLambDirector
extends EscortDirector
## The Lost Lamb (v0.11 M2, Tier 1, spec §3 and §8 row 4): a runaway acolyte -- the cleric nearest the north-east fountain --
## hides there; lead him out through the west gate (the Main Gate, on screen the lower-left wall). Two patrols walk the south
## street and the market's street, the watch holds the gate, and at 2:30 the Temple sends two searchers after him.

## Where he hides: the north-east fountain's plaza.
const START := Vector2(11.4, -10.0)
## The west gate's mouth inside the walls, and the way out past it on the south road.
const GATE_MOUTH := Vector2(2.7, 14.4)
const EXIT := Vector2(2.7, 17.6)
## The watch's posts either side of the mouth, and the guardhouse 6 units east along the wall where it goes for the change.
const POSTS := [Vector2(2.0, 14.6), Vector2(3.4, 14.6)]
const GUARDHOUSE := Vector2(8.7, 13.4)
## The Temple's door, where a seizer takes him.
const TEMPLE_DOOR := Vector2(0.8, -5.0)
## The patrols' beats: the south street east and west, the market's street north and south (tuned: its north end moved from
## (2.7, -4.0), beside the Temple's door, where a seizure was lost in seconds, to (2.7, 0.0)).
const BEATS := [[Vector2(-6.0, 9.0), Vector2(10.0, 9.0)], [Vector2(2.7, 0.0), Vector2(2.7, 8.0)]]
## The numbers (spec §3), tuned against the scripted player (Task 4's behaviour gate) from the first guesses: his pace 0.6 of
## a citizen's became 0.4 (his march in a seizer's tow slows with it: time to answer the seizer), the searchers' 1:30 became 2:30.
const CHARGE_PACE := 0.4
const PATROL_SIZE := 2
const HUNT_AT := 150.0
const HUNTERS := 2


## The mission's places and numbers (v0.11 M2), from the consts above.
func _plan() -> void:
	charge_start = START
	gate_at = GATE_MOUTH
	exit_at = EXIT
	return_to = TEMPLE_DOOR
	guardhouse = GUARDHOUSE
	for p: Vector2 in POSTS:
		watch_posts.append(p)
	for b: Array in BEATS:
		var line := PackedVector2Array()
		for at: Vector2 in b:
			line.append(_walkable(at))
		beats.append(line)
	patrol_size = PATROL_SIZE
	hunt_at = HUNT_AT
	hunt_size = HUNTERS
	charge_pace = CHARGE_PACE
	charge_label = "ACOLYTE"
	exit_label = "WEST GATE"
	return_label = "TEMPLE"


## The cleric nearest the north-east fountain.
func _appoint_charge() -> Person:
	return _citizen_near(START, CitizenProfile.Role.CLERGY)


## The opening banner (v0.11 M2).
func _opening_banner() -> String:
	return "LEAD THE LOST LAMB OUT"


## The timeline's words when the searchers set out (v0.11 M2).
func _hunt_label() -> String:
	return "The Temple sends searchers"


## The banner when a soldier seizes him (v0.11 M2).
func _caught_banner() -> String:
	return "THE LAMB IS CAUGHT"


## The banner when he is freed of his seizer (v0.11 M2).
func _freed_banner() -> String:
	return "THE LAMB IS FREE"


## The banner when he is taken back to the Temple (v0.11 M2).
func _taken_banner() -> String:
	return "THE LAMB IS TAKEN BACK"


## The banner when he gets out (v0.11 M2).
func _escape_banner() -> String:
	return "THE LAMB IS OUT"


## The tour (spec §3): him, the west gate, the Temple.
func tour() -> Array:
	var out := []
	if _alive(charge):
		out.append([charge.ground_pos, "The runaway acolyte hides by the north-east fountain."])
	out.append([gate_at, "The west gate. Its watch changes soon after he draws near."])
	out.append([return_to, "The Temple. At %s it sends searchers after him." % UiTheme.clock(HUNT_AT)])
	return out
