class_name LostLambDirector
extends EscortDirector
## The Lost Lamb (v0.11 M2, Tier 1, spec §3 and §8 row 4): a runaway acolyte -- the cleric nearest the north-east fountain --
## hides there; lead him out through the west gate (the Main Gate, on screen the lower-left wall). Two patrols walk the south
## street and the market's street, the watch holds the gate, and at 2:30 the Temple sends two searchers after him.

## Where he hides: the north-east fountain's plaza.
const START := Vector2(11.4, -10.0)
const HIDEOUT_NAME := "the north-east fountain"
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
## a citizen's became 0.385 (his march in a seizer's tow slows with it: time to answer the seizer), the searchers' 1:30 became 2:30.
const CHARGE_PACE := 0.385
const PATROL_SIZE := 2
const HUNT_AT := 150.0
const HUNTERS := 2
## v0.11.1 (spec 7.2 row 4, a second route): a Will-o'-the-Wisp draws the acolyte from as far as it draws anyone (WillOWisp.LURE_REACH),
## not only from CHARGE_LURE_R -- he is the whole of the lead, and the light is cast once in thirty seconds. He answers it from his duty
## (Person.answers_lure) and walks to it at his own slow pace -- so slow that the Wisp's twelve seconds would leave him two steps on -- and
## stares there WISP_STARE seconds; the hold he keeps where the lure leaves him is his own.
const WISP_HAND := WillOWisp.LURE_REACH
const WISP_STARE := 5.0


## The town's patrol beats (v0.12, spec 1.5): seeded from BEATS, which is Aldermere's; _plan() builds `beats` from it. The other places and
## numbers are EscortDirector's own vars, set in _init().
## The names a town's overrides may set (Overrides): `beat_spots` and EscortDirector's vars seeded in _init(); setup reads them (the
## gate, exit, return and guardhouse it snaps to walkable ground) and never replaces them (the labels it assigns are not here).
const TOWN_VARS := ["charge_start", "gate_at", "exit_at", "return_to", "guardhouse", "watch_posts", "patrol_size", "beat_spots",
	"hunt_at", "hunt_size", "charge_pace", "hideout_name"]
var beat_spots: Array = BEATS
## How the tour names his hiding place ("hides by <this>."): Aldermere's words, which a town whose hiding place is another fountain
## replaces (the game's words must stay true there).
var hideout_name: String = HIDEOUT_NAME


## EscortDirector's places and numbers start at the consts above (v0.12, R31): set at .new(), so a town's override survives setup.
func _init() -> void:
	charge_start = START
	gate_at = GATE_MOUTH
	exit_at = EXIT
	return_to = TEMPLE_DOOR
	guardhouse = GUARDHOUSE
	watch_posts.assign(POSTS)
	patrol_size = PATROL_SIZE
	hunt_at = HUNT_AT
	hunt_size = HUNTERS
	charge_pace = CHARGE_PACE


## The mission's beats and labels (v0.11 M2), from the town vars.
func _plan() -> void:
	for b: Array in beat_spots:
		var line := PackedVector2Array()
		for at: Vector2 in b:
			line.append(_walkable(at))
		beats.append(line)
	charge_label = "ACOLYTE"
	exit_label = "WEST GATE"
	return_label = "TEMPLE"


## The cleric nearest the north-east fountain (v0.11 M2).
func _appoint_charge() -> Person:
	return _citizen_near(charge_start, CitizenProfile.Role.CLERGY)


## He answers a Wisp's lure (v0.11.1): see WISP_HAND.
func _place_charge(c: Charge) -> void:
	super(c)
	(c.man as Person).answers_lure = bound_by == null  # a charge bound to his spot is deaf to a lure, as to a whisper
	if not rules.cast_made.is_connected(_on_light):
		rules.cast_made.connect(_on_light)


## A Will-o'-the-Wisp is cast (v0.11.1): the acolyte beyond the Wisp's own CHARGE_LURE_R but within WISP_HAND of its light walks to the near
## side of its ring and stares. Within CHARGE_LURE_R the Wisp draws him itself.
func _on_light(_slot: int, key: String, at: Vector2) -> void:
	if key != "wisp" or not _alive(charge) or charge.inside or bound:
		return
	var gap := charge.ground_pos.distance_to(at)
	if gap <= WillOWisp.CHARGE_LURE_R or gap > WISP_HAND:
		return
	var near := _walkable(at + (charge.ground_pos - at).normalized() * WillOWisp.RING.x)
	if not charge.lure(near, WillOWisp.WISP_TIME - 0.5, charge.ground_pos):
		return
	var way := 0.0
	var from := charge.ground_pos
	for step in crowd._grid.path(charge.ground_pos, near):
		way += from.distance_to(step)
		from = step
	charge._observe_left = way / maxf(charge.walk_speed, 0.05) + WISP_STARE


## Free (v0.11.1): drawn by a light, his hold goes with him -- where it leaves him is where he holds, not where he stood before.
func _step_free(c: Charge) -> void:
	var p := c.man as Person
	if p.answers_lure and p.mind == Person.Mind.OBSERVE and not p.inside:
		p.anchor = p.ground_pos
		c.hold_at = p.ground_pos
	super(c)


func teardown() -> void:
	for c in charges:
		if is_instance_valid(c.man):
			(c.man as Person).answers_lure = false  # a body is not his for ever: the next night's may be recycled
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_light):
		rules.cast_made.disconnect(_on_light)
	super()


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


## The tour (v0.11 M2, spec §3): him, the west gate, the Temple.
func tour() -> Array:
	var out := []
	if _alive(charge):
		out.append([charge.ground_pos, "The runaway acolyte hides by %s." % hideout_name])
	out.append([gate_at, "The west gate. Its watch changes soon after he draws near."])
	out.append([return_to, "The Temple. At %s it sends searchers after him." % UiTheme.clock(hunt_at)])
	return out
