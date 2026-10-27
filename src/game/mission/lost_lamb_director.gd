class_name LostLambDirector
extends EscortDirector
## The Lost Lamb (v0.11 M2, Tier 1, spec §3 and §8 row 4): a runaway acolyte -- the cleric nearest the north-east fountain --
## hides there; lead him out through the west gate (the Main Gate, on screen the lower-left wall). Two patrols walk the south
## street and the market's street, the watch holds the gate, and at 2:30 the Temple sends two searchers after him.
## God T1R (Tier 1 routes, spec 2.2 and 7): he bolts -- sets out for the gate himself, past fear, at BOLT_PACE -- when a startle lands within
## BOLT_REACH of him (a loud power's danger, a building afire, a death, his fountain blighted) or at BOLT_AT, unless the god has led him
## (whispered, or drawn by a Wisp) first. The watch has two posts, one of them just outside the gate, and a watchman who sees him at the way out
## seizes him before he is out.

## Where he hides: the north-east fountain's plaza.
const START := Vector2(11.4, -10.0)
const HIDEOUT_NAME := "the north-east fountain"
## The west gate's mouth inside the walls, and the way out past it on the south road.
const GATE_MOUTH := Vector2(2.7, 14.4)
const EXIT := Vector2(2.7, 17.6)
## The watch's posts: one at the gate's mouth, one just outside it on the road (god T1R, Problem 10 (a): a way out set down past the gate
## lands in the outer watchman's sight unless the watch is changed or drawn off). And the guardhouse 6 units east along the wall, where
## the watch goes for the change.
const POSTS := [Vector2(2.7, 14.6), Vector2(2.7, 16.8)]
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
## God T1R (spec 2.2): he bolts -- sets out for the way out on his own -- when a startle lands within BOLT_REACH of him (a loud power's
## danger, a building afire, a death, his fountain blighted) or at BOLT_AT mission seconds, unless the god has led him by then. BOLT_PACE
## is his pace while he runs (tunable up to 0.6).
const BOLT_AT := 60.0
const BOLT_REACH := 6.0
const BOLT_PACE := CHARGE_PACE


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
## God T1R (spec 2.2): when he bolts (mission seconds); the god has led him (whispered, or drawn by a Wisp's light) so he never bolts; he is
## running for the way out; and his hiding place's fountain (the structure nearest charge_start), whose Blight startles him.
var bolt_at := BOLT_AT
var bolt_pace := BOLT_PACE
var led := false
var bolting := false
var fountain: Structure = null
## Seconds for which a Wisp's own draw (within WillOWisp.CHARGE_LURE_R) of him still counts as the god leading him: it lures him in the
## cast, a look later.
var _wisp_watch := 0.0


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


## He answers a Wisp's lure (v0.11.1): see WISP_HAND. God T1R: and he bolts at `bolt_at`, or when a startle lands near him.
func _place_charge(c: Charge) -> void:
	super(c)
	(c.man as Person).answers_lure = bound_by == null  # a charge bound to his spot is deaf to a lure, as to a whisper
	if not rules.cast_made.is_connected(_on_light):
		rules.cast_made.connect(_on_light)
	fountain = _fountain_near(charge_start)
	# Mission seconds, not stretched: a wait past a minute is never the player's (the board's longer clocks stretch the others). A charge bound
	# to his spot (a subclass's) never bolts.
	if bound_by == null:
		timeline.add(bolt_at / maxf(stretch, 0.001), "bolt", _bolt_label(), func() -> void: _start_bolt(false),
			func() -> bool: return not led and not bolting and not escaped and not taken and _alive(charge))
	if not crowd.danger_landed.is_connected(_on_danger):
		crowd.danger_landed.connect(_on_danger)
	if not crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.connect(_on_killed)
	if not crowd._env.structure_blighted.is_connected(_on_blighted):
		crowd._env.structure_blighted.connect(_on_blighted)


## The fountain nearest `at`, or null (god T1R): the one his hiding place is.
func _fountain_near(at: Vector2) -> Structure:
	var best: Structure = null
	for s in crowd._env.structures():
		if is_instance_valid(s) and s.kind == Structure.Kind.FOUNTAIN and not s.destroyed \
				and (best == null or s.distance_to(at) < best.distance_to(at)):
			best = s
	return best


## A Will-o'-the-Wisp is cast (v0.11.1): the acolyte beyond the Wisp's own CHARGE_LURE_R but within WISP_HAND of its light walks to the near
## side of its ring and stares. Within CHARGE_LURE_R the Wisp draws him itself. God T1R: either way the god has led him.
func _on_light(_slot: int, key: String, at: Vector2) -> void:
	if key != "wisp" or not _alive(charge) or charge.inside or bound:
		return
	var gap := charge.ground_pos.distance_to(at)
	if gap <= WillOWisp.CHARGE_LURE_R:
		_wisp_watch = 1.0  # the Wisp's own draw: it lures him in the cast, and the next look sees it
	if gap <= WillOWisp.CHARGE_LURE_R or gap > WISP_HAND:
		return
	var near := _walkable(at + (charge.ground_pos - at).normalized() * WillOWisp.RING.x)
	if not charge.lure(near, WillOWisp.WISP_TIME - 0.5, charge.ground_pos):
		return
	_lead()
	var way := 0.0
	var from := charge.ground_pos
	for step in crowd._grid.path(charge.ground_pos, near):
		way += from.distance_to(step)
		from = step
	charge._observe_left = way / maxf(charge.walk_speed, 0.05) + WISP_STARE


## The god leads him (god T1R, spec 2.2): a whisper, or a Wisp's light. He never bolts after it, and a run he was on is over: he holds where
## the god leaves him, as before.
func _lead() -> void:
	led = true
	bolting = false


## Whether the god has his hand on him (god T1R): whispered, or drawn by a Wisp's own light (not a Death Mark's body, which draws him too).
func _note_led(delta: float) -> void:
	_wisp_watch = maxf(_wisp_watch - delta, 0.0)
	if led or not _alive(charge):
		return
	if charge.mind == Person.Mind.WHISPERED or (_wisp_watch > 0.0 and charge.lured()):
		_lead()


## One step (god T1R): who the god has led is known before the timeline's bolt asks.
func step(delta: float) -> void:
	_note_led(delta)
	super(delta)


## Mission seconds until he bolts: 0 once he is bolting, led or gone (god T1R).
func bolt_left() -> float:
	if bolting or led or escaped or taken or not _alive(charge) or timeline == null:
		return 0.0
	return timeline.seconds_to("bolt")


## The strip's words for the bolt: "He bolts for the west gate".
func _bolt_label() -> String:
	return "He bolts for the %s" % exit_label.to_lower()


## He sets out for the way out on his own (god T1R, spec 2.2). `say`: the banner (the timeline's event says it itself).
func _start_bolt(say: bool) -> void:
	if bolting or led or not _alive(charge):
		return
	bolting = true
	if not is_equal_approx(bolt_pace, charge_pace):
		charge.pace *= bolt_pace / charge_pace
	if say:
		rules.banner.emit("HE BOLTS FOR THE %s" % exit_label)
	_run_for_it(_first())


## While he bolts (god T1R): past fear, on duty for the way out -- a fright does not send him indoors or off his run. A god's hand on him, a
## seizer's, or a roof over him is let be; the look that finds him free sends him on.
func _run_for_it(c: Charge) -> void:
	var p := c.man as Person
	p.fearless_left = maxf(p.fearless_left, BOUND_HOLD)
	if p.inside or p.held_by_god() or c.held:
		return
	c.hold_at = exit_at
	if p.mind != Person.Mind.DUTY or p.anchor.distance_to(exit_at) > MOVE:
		p.go_duty(exit_at)


## A startle `gap` from him (god T1R): if he is free, out of doors and not led, and it is within BOLT_REACH of him, he bolts.
func _startle(gap: float) -> void:
	if led or bolting or escaped or taken or held or bound_by != null or not _alive(charge) or charge.inside:
		return
	if gap <= BOLT_REACH:
		_start_bolt(true)


## A loud power's danger has landed (Crowd.danger_landed): any point of it within reach.
func _on_danger(_key: String, points: Array[Vector2]) -> void:
	if not _alive(charge):
		return
	for at in points:
		_startle(charge.ground_pos.distance_to(at))


## A death in the field, of anyone but him: within reach of him.
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if _alive(charge) and is_instance_valid(e) and e != charge:
		_startle(charge.ground_pos.distance_to(e.ground_pos))


## A structure is blighted: his hiding place's fountain, wherever he stands.
func _on_blighted(s: Structure) -> void:
	if fountain != null and s == fountain:
		_startle(0.0)


## A building has caught fire within reach of him (god T1R): checked every look, over the few that burn.
func _burning_near() -> void:
	if led or bolting or not _alive(charge) or crowd.fires == null or crowd.fires.fires.is_empty():
		return
	for s: Structure in crowd.fires.fires.keys():
		if is_instance_valid(s) and not s.destroyed:
			_startle(s.distance_to(charge.ground_pos))


## Free (v0.11.1): drawn by a light, his hold goes with him -- where it leaves him is where he holds, not where he stood before.
## God T1R: a watchman who sees him at the way out seizes him before he is out (spec 7.3, preflight 2: the outer post); bolting, he is sent
## on for the way out every look.
func _step_free(c: Charge) -> void:
	var p := c.man as Person
	if not p.inside and _exit_reached(c):
		var by := _seen_by(c)
		if by != null:
			_seize(c, by)
			return
	if p.answers_lure and p.mind == Person.Mind.OBSERVE and not p.inside:
		p.anchor = p.ground_pos
		c.hold_at = p.ground_pos
	_burning_near()
	if bolting:
		_run_for_it(c)
	super(c)


## Freed of his seizer (god T1R): bolting, he runs on at once.
func _release(c: Charge) -> void:
	super(c)
	if bolting and _alive(c.man):
		_run_for_it(c)


func teardown() -> void:
	for c in charges:
		if is_instance_valid(c.man):
			(c.man as Person).answers_lure = false  # a body is not his for ever: the next night's may be recycled
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_light):
		rules.cast_made.disconnect(_on_light)
	if is_instance_valid(crowd):
		if crowd.danger_landed.is_connected(_on_danger):
			crowd.danger_landed.disconnect(_on_danger)
		if crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
			crowd._field.enemy_killed.disconnect(_on_killed)
		if crowd._env != null and crowd._env.structure_blighted.is_connected(_on_blighted):
			crowd._env.structure_blighted.disconnect(_on_blighted)
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


## The map tags (god T1R, spec 7.1): his own reads the seconds to his bolt until the god has led him or he runs, and RUNNING while he does;
## the rest are the Escort type's.
func tags() -> Array[MapTag]:
	var out := super()
	if held or out.is_empty() or out[0].label != charge_label:
		return out
	if bolting:
		out[0] = MapTag.person(charge.ground_pos, MARK_CHARGE, charge_label + " - RUNNING", true)
	elif not led:
		out[0] = MapTag.person(charge.ground_pos, MARK_CHARGE, "%s - BOLTS IN %s" % [charge_label, UiTheme.clock(bolt_left())], true)
	return out


## The hint's phase (god T1R, spec 7.4): the Escort type's (caught, at the gate), else "running" while he bolts, else "led" once the god has
## led him (he never runs then: the base line would be untrue).
func hint_phase() -> String:
	var phase := super()
	if phase == "" and not held and _alive(charge) and not escaped and not taken:
		if bolting:
			return "running"
		if led:
			return "led"
	return phase


## The tour (v0.11 M2, spec §3): him, the west gate, the Temple.
func tour() -> Array:
	var out := []
	if _alive(charge):
		out.append([charge.ground_pos, "The runaway acolyte hides by %s." % hideout_name])
	out.append([gate_at, "The west gate. Its watch changes soon after he draws near."])
	out.append([return_to, "The Temple. At %s it sends searchers after him." % UiTheme.clock(hunt_at)])
	return out
