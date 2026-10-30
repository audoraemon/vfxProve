class_name HideFaithfulDirector
extends ExodusDirector
## Hide the faithful (god P5, Hunt 1, MS §2; Tier 1, the Lantern Hunt of the Escort type; Exodus's director grown small): two households of
## three believers (HF_PER_HOUSE) wait in their quiet stone houses -- the north-west one for the Main Gate, the north one for the Side Gate --
## and walk themselves out of the walls (shared rule 2, "he bolts": at Tier 1 only a Dominion god can move a man, so the files walk on their
## own, past fear and deaf to the evacuation, at HF_BELIEVER_PACE). A believer anywhere out of the walls (Walls.outside(), shared rule 1) is
## out and sent off the map; five of the six win (HF_NEED); two taken or killed lose at once (HF_LOSE, lost_reason() "faithful_lost").
##
## The watch is soldiers, as the Lost Lamb's, so The Bell Lies' CALL THE GUARD answers it: two at each gate's mouth and just outside it
## (HF_POSTS), two patrols of two on the Lamb's beats (HF_BEATS), walking HF_PATROL_GAP apart (the Escort type rings them at 0.5, so one
## Silent Doom would take both). Seize on sight (SIGHT = HF_SIGHT), and the watch is not replaced. The Hunt's own rule is the search: two
## inquisitors -- lay citizens in the watch's cloak -- set out from the Temple's door and visit HF_SEARCH_LIST houses in a fixed order (four
## empty dwellings and the two households' houses, the first household's second, the second's last), standing HF_SEARCH_STOP seconds at
## each door. A household that is already out when they reach its house is trailed (they walk after its lamp, seizing on sight) until it
## is done; a household still inside is never found there: it slips out HF_SLIP seconds before the search would reach it (out_due()).
## A fallen inquisitor is replaced HF_SEARCH_RELIEF_AFTER seconds later, at most HF_SEARCH_RELIEFS a night. Nothing here gazes (Tier 1): the
## base keeps a Gaze meter the Hunt hides (step()).
##
## Overrides of ExodusDirector (the MS §2 checklist): _plan(), the tune_ vars (setup()), _appoint_watch() and _appoint_patrol() (soldiers),
## _post_to() and _takes_post() (the Escort type's send_to_post way), _step_patrols() and the patrols' first placement (HF_PATROL_GAP apart),
## _relieve_watch() (a no-op), _come_out() (no "The Temple sends searchers" row), _step_free() (the self-walk, the sight check before the
## out check), _exit_reached() (out of the walls), _escape() (sent off the map), _chain()/out_due() (SLIP), the searchers in place of the
## hounds (_step_hunters() and what it calls), lost_reason(), hud_line() (the base's), tags(), hint_phase(), strip_rows(), tour().
## `_watchman()` is kept as the base's, on purpose: it only puts a lay citizen in the watch's cloak, and here its one user is the inquisitors (the gate
## watch and the patrols are soldiers, who need no cloak, and the watch is not replaced).

## The households (MS §2), first guesses (fg): how many believers, how many to a household, how many must get out, where each house is sought,
## the words and tag names, and the gate each household is bound for (an index into HF_GATES). Ruling P5-11's twins live in HF_SEARCH_*.
const HF_BELIEVERS := 6
const HF_PER_HOUSE := 3
const HF_NEED := 5
## Taken plus dead that lose the night (6 believers, 5 needed).
const HF_LOSE := 2
const HF_HOUSE_POINTS := [Vector2(-11.0, -1.5), Vector2(5.5, -12.0)]
const HF_HOUSE_WORDS := ["the north-west household", "the north household"]
const HF_HOUSE_NAMES := ["NORTH-WEST", "NORTH"]
## The two gates the households use: the Main Gate, then the Side Gate (their mouths inside the wall, their ways out beyond it, tags, words
## and the way along the wall); the same places as the Lost Lamb's gate and Exodus's Side Gate.
const HF_GATES := [
	{"mouth": Vector2(2.7, 14.4), "exit": Vector2(2.7, 17.6), "label": "MAIN GATE", "words": "the Main Gate", "along": Vector2.RIGHT},
	{"mouth": Vector2(14.4, 9.0), "exit": Vector2(17.6, 9.0), "label": "SIDE GATE", "words": "the Side Gate", "along": Vector2.DOWN},
]
## When each household comes out at the latest (fg), the chain (a rule: no wait over 45 s), and how long before the search would reach a
## household's house it slips out (fg).
## Tuning round 1 (Task 9): the second household 110 -> 140 and the believers' pace 0.45 -> 0.40 (ruling P5-C10: the default play won at 150-168 s, under
## the 180-240 s bar; later and slower is the reverse of MS §7's easier moves). Result: wins at 166-205 s, the Hunt's pooled median 189 s. The pace did the
## work: the chain (45 s after the first household is done, about 95 s) brings the second household out at about 140 s whichever of the two numbers is
## used, so 140 rarely binds alone. The chain (45 s) still ends the wait.
const HF_OUT_AT := [15.0, 140.0]
const HF_CHAIN := 45.0
const HF_SLIP := 30.0
## The believers' pace as a fraction of a citizen's (fg 0.45; 0.40 in tuning round 1, see HF_OUT_AT).
const HF_BELIEVER_PACE := 0.40
## The watch: the gates' four posts (two inside the Main Gate and just outside it, two at the Side Gate's mouth and outside it), the patrols'
## beats (the Lost Lamb's), how far apart a patrol walks, and how near a door must be quiet (no post or beat within it).
const HF_POSTS := [Vector2(2.7, 14.6), Vector2(2.7, 16.8), Vector2(14.6, 9.0), Vector2(16.8, 9.0)]
const HF_BEATS := LostLambDirector.BEATS
## (2.0 from Task 9, first review Minor 4: patrol pairs measured 1.5-1.6 apart in motion at a nominal 1.8. Two causes were found and fixed: the
## follower's own pace (_match_pace(): the pair walks at its slowest man's, else the follower gained down to 0.4 apart) and the lead's arrival
## (_step_patrols() measures it from his place of the pair, not the beat's point); measured in motion over 90 s, nearest 2.0.)
const HF_PATROL_GAP := 2.0
const HF_SIGHT := 2.5
const HF_QUIET := 3.5
## The search (MS §2, fg): how many inquisitors, how many houses listed (the households' included), how long they stand at a door, how far
## apart they walk, how fast they walk the list and a trail (a fraction of a citizen's duty pace), how long a fallen one is missed and how
## many come in a night, how near a door counts as reached, how near a door a household still inside is brought out at once (the net under
## SLIP), and how far apart the listed houses stand.
const HF_SEARCHERS := 2
const HF_SEARCH_LIST := 6
const HF_SEARCH_STOP := 6.0
const HF_SEARCH_GAP := 1.8
## Added to HF_SEARCH_GAP when the pair is sent to its places (pair_spots()): a person stops a step short of or past his place, so places this much
## farther apart than HF_SEARCH_GAP keep the two more than two Silent Doom radii apart. 0.6 from Task 9 (ruling P5-T9-R1): at 0.5 a pair stopped at a door,
## or a relief arriving at his place, was sampled 1.4 apart while he was still a step short of it; places 2.4 apart keep the two more than 1.6 apart while
## one is within HF_PLACE_NEAR of his place and the other settled (0.8 left no room for the arrival guard at one door).
const HF_PAIR_SLACK := 0.6
## How near his place an inquisitor counts as standing at it (the report line's pair gap is sampled only then).
const HF_PLACE_NEAR := 0.5
## The pair walks in file (ruling P5-T9-R8): the rear man holds where he stands until he is this far behind his fellow along the path, and which of
## the two is the front changes only when the other is nearer the place by more than HF_FILE_STICKY.
const HF_PAIR_FILE := 2.3
const HF_FILE_STICKY := 0.6
## The pace every inquisitor walks at before HF_SEARCH_PACE (a citizen's mean): citizens' own paces differ by a tenth, and the faster of a pair
## (or a relief walking in) closed on his fellow along a leg to 1.4 apart -- inside one Silent Doom -- before he stopped at his place (ruling P5-T9-R1).
const HF_SEARCH_BASE_PACE := 1.0
const HF_SEARCH_PACE := 0.6
const HF_TRAIL_PACE := 1.0
const HF_SEARCH_RELIEF_AFTER := 30.0
const HF_SEARCH_RELIEFS := 2
const HF_ARRIVE := 1.6
const HF_SLIP_NEAR := 5.0
const HF_SEARCH_SPACING := 4.0
## How far from the Temple's door the search's first stop is at least.
const HF_SEARCH_FIRST := 8.0
## Where the camera rests: the north-west household's door and the Temple at the top of the picture, the Main Gate below (MS §2 leaves it to
## the frame).
const HF_CAMERA_AT := Vector2(-4.0, 4.0)

## The listed houses, in the order the search visits them: dictionaries of `house` (Structure), `door` (Vector2) and `household` (an index
## into households, -1 for an empty dwelling).
var _search: Array = []
## The index of the listed house the search is bound for; the clock second its stop ends (-1 while walking); the household whose trail it
## follows (-1 for none); how many listed houses it has stood at.
var _search_at := 0
var _search_stop := -1.0
var _trail := -1
var searched := 0
## The inquisitors (Variants: any may be freed) and each one's base pace by instance id; the second each one fell (-1 while he stands); how
## many reliefs came.
var inquisitors: Array = []
var _inq_base := {}
var _inq_fallen: Array[float] = []
var inq_reliefs := 0
## The seconds from `_eta_at` until the search reaches each listed house (INF for none), refreshed every look.
var _eta: Array[float] = []
var _eta_at := 0.0
## Each marched believer's seconds to the Temple, by Charge: {"eta", "at"}.
var _march := {}
## The nearest the two inquisitors have stood to each other while stopped at a door, both at their places (INF until then): what a Silent Doom
## would take together; the scripted run prints it (god P5, review of Task 4).
var stopped_gap_min := INF
var stopped_gaps := 0
## The same, kept per listed house (by its index in the list; INF until sampled there): a run's line prints every door's, not the first's
## alone (review of Task 4, re-review item 2).
var stopped_door_gap: Array[float] = []
## The first loss has been announced.
var _lost_said := false
## The Gaze meter the base steps and this Hunt never shows (step()).
var _no_gaze: GazeMeter
## Leg lengths between listed doors, by "a>b".
var _legs := {}
## The pair's places at the listed door the search is bound for, by "door/count" (_door_spots()); cleared at each arrival and each move on, so a
## house fallen or rebuilt since is seen (review of Task 4, re-review item 5).
var _pairs := {}
## The instance id of the inquisitor in front along the path (_order_search()), kept so the two do not swap places look to look.
var _file_front := 0


## The Hunt's numbers into the base's tune_ vars and existing vars before the base sets up (god P5, MS H11, H12, Ruling C2): no gate shuts,
## no hounds, three to a household, five needed.
func setup(r: Rules, c: Crowd, t: Town, x: FxContext, n: NightState = null) -> MissionDirector:
	_tune()
	return super(r, c, t, x, n)


## Copies the HF_ consts into the base's vars (god P5, MS H11). Public so a test can read what setup() set.
func _tune() -> void:
	tune_out_at = HF_OUT_AT.duplicate()
	tune_shut_at = []
	tune_hounds = 0
	tune_per_house = HF_PER_HOUSE
	tune_believer_pace = HF_BELIEVER_PACE
	tune_need = HF_NEED
	tune_chain = HF_CHAIN
	tune_gate_watch = 2
	tune_quiet = HF_QUIET
	tune_beats = HF_BEATS.duplicate(true)
	patrol_size = 2


## The plan (MS §2): no Gaze, no guard change, the Temple, two gates and their four posts, the Lamb's beats, the two households' houses.
func _plan() -> void:
	watch_changes = false
	temple_door = _walkable(TEMPLE_DOOR)
	return_to = TEMPLE_DOOR
	guardhouse = TEMPLE_DOOR
	gate_at = HF_GATES[0].mouth
	exit_at = HF_GATES[0].exit
	hunt_at = -1.0
	charge_label = "BELIEVER"
	exit_label = "MAIN GATE"
	return_label = "TEMPLE"
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	for g in HF_GATES.size():
		var gate := Gate.new()
		gate.label = String(HF_GATES[g].label)
		gate.words = String(HF_GATES[g].words)
		gate.mouth = _walkable(HF_GATES[g].mouth)
		gate.way_out = _walkable(HF_GATES[g].exit)
		gates.append(gate)
	for post: Vector2 in HF_POSTS:
		watch_posts.append(_walkable(post))
	for b: Array in HF_BEATS:
		var line := PackedVector2Array()
		for at: Vector2 in b:
			line.append(_walkable(at))
		beats.append(line)
	patrol_size = 2
	var skip: Array = []
	for i in HF_HOUSE_POINTS.size():
		var h := Household.new()
		h.words = String(HF_HOUSE_WORDS[i])
		h.name = String(HF_HOUSE_NAMES[i])
		h.gate = i
		h.house = _quiet_house(HF_HOUSE_POINTS[i], (gates[i] as Gate).mouth, skip)
		if h.house == null:
			push_warning("HideFaithfulDirector: no house for %s" % h.words)
			continue
		skip.append(h.house)
		h.door = _quiet_door(h.house, (gates[i] as Gate).mouth)
		if h.door == Vector2.INF:
			h.door = _open_door(h.house, (gates[i] as Gate).mouth)
		households.append(h)


## The base's setup, then the patrols exactly HF_PATROL_GAP apart, the inquisitors at the Temple's door, the search list, the banners on
## this Hunt's own words, and the first look's numbers (MS §2).
func _begin() -> void:
	super()
	for k in patrols.size():
		var squad: Array = patrols[k]
		var beat: PackedVector2Array = beats[k]
		_match_pace(squad)
		for i in squad.size():
			var spot := _gap_spot(beat, beat[0], i, squad.size())
			_set_down(squad[i] as Person, spot)
			_post_to(squad[i] as Person, spot, false)
	for c: Dictionary in timeline.fired.get_connections():
		timeline.fired.disconnect(c.callable)
	timeline.fired.connect(_on_fired)
	_appoint_inquisitors()
	_plan_search()
	_refresh_eta()


## Every banner a timeline event raises is its label in capitals, but a household coming out says it SLIPS OUT (MS §2).
func _on_fired(id: String, label: String) -> void:
	if id.begins_with("out_"):
		rules.banner.emit(_slips_banner(int(id.trim_prefix("out_"))))
	else:
		rules.banner.emit(label.to_upper())


## "THE NORTH-WEST HOUSEHOLD SLIPS OUT" for household `i`.
func _slips_banner(i: int) -> String:
	return "THE %s HOUSEHOLD SLIPS OUT" % (households[i] as Household).name


# --- The watch: soldiers -----------------------------------------------------------------------------------------------------------

## The `i`th of `n` places HF_PATROL_GAP apart round `at` for a patrol on `beat`: in file along the street it walks, so a narrow street never
## squeezes the pair together (a ring across it would snap to walkable ground and could land 1.5 apart, inside two Silent Doom radii).
func _gap_spot(beat: PackedVector2Array, at: Vector2, i: int, n: int) -> Vector2:
	var turn := (beat[beat.size() - 1] - beat[0]).angle() if beat.size() > 1 else 0.0
	return _ring_spot(at, HF_PATROL_GAP * 0.5, i, n, turn)


## The squad walks at one pace, its slowest man's (Task 9, first review Minor 4): citizens' paces differ by a tenth, and a follower a tenth faster
## than his lead closes the gap along a beat -- measured, 2.0 apart at a turn and 0.4 at the far end -- so the pair would stand within one Silent Doom.
func _match_pace(squad: Array) -> void:
	var slowest := INF
	for v: Variant in squad:
		if is_instance_valid(v):
			slowest = minf(slowest, (v as Person).pace)
	for v: Variant in squad:
		if is_instance_valid(v) and slowest < INF:
			(v as Person).pace = slowest


## Each post's watchman (MS §2): the free soldier nearest the post, set down there. Soldiers, as the Lost Lamb's, so CALL THE GUARD answers.
func _appoint_watch(c: Person, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var post := _walkable(watch_posts[i])
		var crew := _free_soldiers(post, 1, _in_use(c) + out)
		if crew.is_empty():
			break
		_set_down(crew[0], post)
		out.append(crew[0])
	return out


## A patrol (MS §2): the free soldiers nearest its beat's first point, HF_PATROL_GAP apart there.
func _appoint_patrol(c: Person, beat: PackedVector2Array, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var spot := _gap_spot(beat, beat[0], i, n)
		var crew := _free_soldiers(spot, 1, _in_use(c) + out)
		if crew.is_empty():
			break
		_set_down(crew[0], spot)
		out.append(crew[0])
	return out


## A soldier goes to his post (the Escort type's way; Exodus's lay watchmen go on duty instead).
func _post_to(p: Person, at: Vector2, hurry: bool) -> void:
	p.send_to_post(at, false, hurry)


## A soldier takes his post or beat again (the Escort type's rule: of no corps, in a mind of POST_MINDS, not held by the god; a seizer, on
## duty, is not).
func _takes_post(p: Person) -> bool:
	return p.corps == Person.Corps.NONE and p.mind in POST_MINDS and not p.held_by_god()


## Each patrol along its beat (the Escort type's rule), its soldiers HF_PATROL_GAP apart.
func _step_patrols() -> void:
	for k in patrols.size():
		var squad: Array = patrols[k]
		var beat: PackedVector2Array = beats[k]
		var lead: Variant = null
		var lead_i := 0
		for i in squad.size():
			if _on_post(squad[i]):
				lead = squad[i]
				lead_i = i
				break
		if lead == null:
			continue
		# He has arrived when he stands at his own place of the pair round the beat's point (HF_PATROL_GAP * 0.5 off it, which is more than
		# ARRIVE: measured from the point itself, a pair this wide never arrived and stood at the beat's start for good).
		if (lead as Person).ground_pos.distance_to(_gap_spot(beat, beat[_beat_at[k]], lead_i, squad.size())) <= ARRIVE:
			_beat_at[k] = (_beat_at[k] + 1) % beat.size()
		var to := beat[_beat_at[k]]
		for i in squad.size():
			var v: Variant = squad[i]
			if not _on_post(v):
				continue
			var spot := _gap_spot(beat, to, i, squad.size())
			if (v as Person).anchor.distance_to(spot) > MOVE:
				_post_to(v as Person, spot, false)


## The watch is not replaced (MS §2): the base's lay gate reliefs are off.
func _relieve_watch() -> void:
	pass


# --- The inquisitors and the search -----------------------------------------------------------------------------------------------

## The two inquisitors (MS §2): the lay citizens nearest the Temple's door, in the watch's cloak, set down HF_SEARCH_GAP apart there.
func _appoint_inquisitors() -> void:
	var made := _lay_near(temple_door, HF_SEARCHERS, _in_use(charge))
	for i in made.size():
		_make_inquisitor(made[i])
		var spot := pair_spots(temple_door, made.size())[i]
		_set_down(made[i], spot)
		made[i].go_duty(spot)
		inquisitors.append(made[i])
		_inq_fallen.append(-1.0)


## `p` in the inquisitors' cloak, his own pace remembered.
func _make_inquisitor(p: Person) -> void:
	_watchman(p)
	if not reserved.has(p):
		reserved.append(p)  # set aside: the Lantern's Bearer picks his escort from the watchmen free to walk, and took the inquisitors off the search for good
	p.pace = HF_SEARCH_BASE_PACE  # one pace for the pair, as for a patrol (_match_pace): a faster man closes on his fellow along a leg
	_inq_base[p.get_instance_id()] = p.pace
	if crowd._fled_all:
		_keep_from_flight(p, true)  # chosen once the town is running: never one of the flight


## The listed houses (MS §2, Ruling P5-11): four empty dwellings and the two households' houses in the walk order from the Temple's door --
## one empty house, the first household's, the rest of the empties, the second household's. Each empty one is the dwelling on the way (the
## least detour from the last door towards the next household's), a door the street reaches, none reserved by a wish, none within
## HF_SEARCH_SPACING of one already listed.
func _plan_search() -> void:
	_search.clear()
	if households.is_empty():
		return
	var pool: Array = []
	var used: Array = []
	for h: Household in households:
		used.append(h.house)
	for s: Structure in town._built:
		if not is_instance_valid(s) or s.destroyed or not RuinWish.fits(s, "house") or reserved_places.has(s) or used.has(s):
			continue
		var door := _open_door(s, temple_door)
		if door != Vector2.INF:
			pool.append({"house": s, "door": door, "household": -1})
	var empties := maxi(HF_SEARCH_LIST - households.size(), 0)
	var before := mini(1, empties)
	var from := temple_door
	for i in households.size():
		var h: Household = households[i]
		var take := before if i == 0 else (empties - before if i == households.size() - 1 else 0)
		for k in take:
			var pick := _pick_empty(pool, from, h.door, i == 0 and k == 0)
			if pick.is_empty():
				break
			pool.erase(pick)
			_search.append(pick)
			from = pick.door
		_search.append({"house": h.house, "door": h.door, "household": i})
		from = h.door


## The empty dwelling of `pool` for the walk from `from` to `goal`: on the way, the least detour; the first stop of all (`first`), the nearest
## to `from` that is at least HF_SEARCH_FIRST from it, so the search does not stand at the Temple's own door. None within HF_SEARCH_SPACING of
## a listed door or a household's; {} for none.
func _pick_empty(pool: Array, from: Vector2, goal: Vector2, first := false) -> Dictionary:
	var best := {}
	var best_cost := INF
	for e: Dictionary in pool:
		var door: Vector2 = e.door
		var crowded := door.distance_to(from) < (HF_SEARCH_FIRST if first else HF_SEARCH_SPACING)
		for l: Dictionary in _search:
			crowded = crowded or (l.door as Vector2).distance_to(door) < HF_SEARCH_SPACING
		for h: Household in households:
			crowded = crowded or h.door.distance_to(door) < HF_SEARCH_SPACING
		if crowded:
			continue
		var cost := from.distance_to(door) if first else from.distance_to(door) + door.distance_to(goal) - from.distance_to(goal)
		if cost < best_cost:
			best = e
			best_cost = cost
	return best


## The houses in the order the search visits them (MS §2).
func search_list() -> Array:
	var out: Array = []
	for e: Dictionary in _search:
		out.append(e.house)
	return out


## Seconds until the search reaches listed house `i` (its door), 0 once it has, INF when no inquisitor can (all fallen, no relief left).
func search_eta(i: int) -> float:
	if i < 0 or i >= _eta.size():
		return INF
	if _reached(i):
		return 0.0
	return maxf(_eta[i] - (_clock - _eta_at), 0.0)


## The household whose trail the search follows now, -1 for none (MS §2).
func trail_of() -> int:
	return _trail


## Listed house `i` has been reached (the search stands or stood there, or is past it).
func _reached(i: int) -> bool:
	return i < _search_at or (i == _search_at and (_search_stop >= 0.0 or _trail >= 0))


## The listed house of household `i`, -1 for none.
func _entry_of(i: int) -> int:
	for k in _search.size():
		if int(_search[k].household) == i:
			return k
	return -1


## Household `i` comes out at the latest (MS §2): its own time, CHAIN after the one before is done, or HF_SLIP before the search would
## reach its house -- the soonest of the three.
func out_due(i: int) -> float:
	var at := super(i)
	var k := _entry_of(i)
	if k >= 0 and k < _eta.size() and _eta[k] < INF and not _reached(k):
		at = minf(at, _eta_at + _eta[k] - HF_SLIP)
	return at


## The households come out when their time comes (MS §2): every one, the first included, not only the chained.
func _chain() -> void:
	for i in households.size():
		var h: Household = households[i]
		if not h.out and _clock >= out_due(i):
			rules.banner.emit(_slips_banner(i))
			_come_out(i)


## Household `i` comes out (MS §2): its believers on a ring round the door, on duty, in file; no searchers sent (the search is the
## Hunt's own, from the Temple's door at 0:00).
func _come_out(i: int) -> void:
	var h: Household = households[i]
	if h.out:
		return
	h.out = true
	h.out_at = _clock
	h.trail.clear()
	for k in h.members.size():
		var c: Charge = h.members[k]
		if not _alive(c.man) or not (c.man as Person).inside or c.taken:
			continue
		var p := c.man as Person
		var spot := _ring_spot(h.door, OUT_RING, k, h.members.size())
		_bring_out(p, spot)
		_keep_from_flight(p, true)
		p.go_duty(spot)
		c.hold_at = spot
		_in_file[c] = true


## One step: the base's, with the Gaze meter it steps put on for the call and taken off again (MS §2: no Gaze at Tier 1), then those sent off
## the map walk on.
func step(delta: float) -> void:
	if _no_gaze == null:
		_no_gaze = GazeMeter.new()
	gaze = _no_gaze
	super(delta)
	gaze = null
	_step_leaving()


## A death is no Gaze's business here (the base notes it on a Gaze); an inquisitor's is seen to in _relieve_search().
func _on_killed(_e: DummyEnemy, _kind: StringName) -> void:
	pass


## Everyone held through an evacuation (the base's list and the inquisitors).
func _keep_held(evacuating: bool) -> void:
	_hold_all(inquisitors, evacuating)
	super(evacuating)


## Everyone at the night's work, the inquisitors too.
func _in_use(c: Person) -> Array:
	var out := super(c)
	out.append_array(inquisitors)
	return out


## Every watcher: the gates' watch, the patrols and the inquisitors (untyped: any may be freed).
func _watchers() -> Array:
	var out: Array = []
	out.append_array(watch)
	for squad: Array in patrols:
		out.append_array(squad)
	out.append_array(inquisitors)
	return out


## `v` is one of the inquisitors.
func _is_searcher(v: Variant) -> bool:
	return inquisitors.has(v)


## An inquisitor who seizes marches at his full pace (the list is walked slowly, the Temple is not).
func _seize(c: Charge, by: Person) -> void:
	_set_pace(by, 1.0)
	super(c, by)


## `p`'s pace as `factor` of his own (an inquisitor); true when it changed.
func _set_pace(p: Person, factor: float) -> bool:
	var want := float(_inq_base.get(p.get_instance_id(), p.pace)) * factor
	if is_equal_approx(p.pace, want):
		return false
	p.pace = want
	return true


## The searchers' look, in the hounds' place (MS §2): the fallen replaced, the stops and arrivals, the orders, the numbers, a household
## still inside caught up with, the loss announced.
func _step_hunters() -> void:
	_relieve_search()
	_advance_search()
	_order_search()
	_note_pair()
	_refresh_eta()
	_refresh_march()
	for i in households.size():
		var h: Household = households[i]
		if not h.out and _search_near(h.door, HF_SLIP_NEAR):
			rules.banner.emit(_slips_banner(i))  # the net under SLIP: never found inside
			_come_out(i)
		elif not h.out:
			var left := maxf(out_due(i) - _clock, 0.0)
			_retime("out_%d" % i, timeline.elapsed() + left / timeline.stretch_factor())
	if lost() >= 1 and not _lost_said:
		_lost_said = true
		rules.banner.emit("ONE BELIEVER LOST - ONE MORE AND THE HUNT FAILS")


## The strip shows event `id` at `at` (the timeline's own seconds), whether that is sooner or later than before: a household's time moves
## with the search, and EventTimeline.expect() only ever brings a time forward.
func _retime(id: String, at: float) -> void:
	for e in timeline._events:
		if String(e.id) == id and not bool(e.done):
			e.at = at
			e.shown = at
			return


## The relief for a fallen inquisitor: the lay citizen nearest the Temple's door with a way on foot to it, not one walking the Lantern's errand (its Bearer's
## escort: the Bearer kept driving him, and the search stood still for the night) -- the base's, with that left out.
func _relief_from_temple(post: Vector2) -> Person:
	var busy := _in_use(charge)
	for p: Person in crowd.citizens:
		if on_lantern_errand(p):
			busy.append(p)
	for p in _lay_near(temple_door, REACH_PICKS, busy):
		if crowd._grid == null or not crowd._grid.path(p.ground_pos, post).is_empty():
			return p
	return null


## A fallen inquisitor is replaced HF_SEARCH_RELIEF_AFTER after he fell by the lay citizen nearest the Temple's door with a way on foot to
## it, at most HF_SEARCH_RELIEFS a night (MS §2).
func _relieve_search() -> void:
	for k in inquisitors.size():
		if _alive(inquisitors[k]):
			_inq_fallen[k] = -1.0
			continue
		if _inq_fallen[k] < 0.0:
			_inq_fallen[k] = _clock
			continue
		if _clock - _inq_fallen[k] < HF_SEARCH_RELIEF_AFTER or inq_reliefs >= HF_SEARCH_RELIEFS:
			continue
		var p := _relief_from_temple(temple_door)
		if p == null:
			_inq_fallen[k] = _clock
			continue
		_make_inquisitor(p)
		inquisitors[k] = p
		_inq_fallen[k] = -1.0
		inq_reliefs += 1
		p.go_duty(temple_door)
		rules.banner.emit("A NEW INQUISITOR COMES FROM THE TEMPLE")


## The search's stops and arrivals (MS §2): reaching a house whose household is out and not done, it takes up the trail; any other door, it
## stands HF_SEARCH_STOP there and goes on; a trailed household done, it goes on down the list.
func _advance_search() -> void:
	if _trail >= 0:
		if not (households[_trail] as Household).done:
			return
		_trail = -1
		_search_at += 1
		_search_stop = -1.0
		_pairs.clear()
	if _search_at >= _search.size():
		return
	var e: Dictionary = _search[_search_at]
	if _search_stop >= 0.0:
		if _clock >= _search_stop:
			_search_at += 1
			_search_stop = -1.0
			_pairs.clear()
		return
	if not _search_near(e.door, HF_ARRIVE):
		return
	_pairs.clear()  # an arrival: the pair's places are worked out afresh, on the ground as it stands now
	var hi := int(e.household)
	if hi >= 0 and (households[hi] as Household).out and not (households[hi] as Household).done:
		_trail = hi
		searched += 1
		rules.banner.emit("THE INQUISITION FINDS THE TRAIL")
		return
	_search_stop = _clock + HF_SEARCH_STOP
	searched += 1


## An inquisitor, alive, out of doors and not marching, stands within `reach` of `at`.
func _search_near(at: Vector2, reach: float) -> bool:
	for v: Variant in inquisitors:
		if _alive(v) and not (v as Person).inside and not _seizing(v) and (v as Person).ground_pos.distance_to(at) <= reach:
			return true
	return false


## Where the search stands or walks to now: the trailed household's lamp (else its first believer out of doors), else the listed door;
## Vector2.INF with nowhere to go.
func _search_point() -> Vector2:
	if _trail >= 0:
		var lead := lamp(_trail)
		if lead != null:
			return (lead.man as Person).ground_pos
		for c: Charge in (households[_trail] as Household).members:
			if not _resolved(c) and not (c.man as Person).inside:
				return (c.man as Person).ground_pos
		return Vector2.INF
	if _search_at < _search.size():
		return _search[_search_at].door
	return Vector2.INF


## Each inquisitor on his feet and free is sent to the search's place, HF_SEARCH_GAP apart: walking the list at HF_SEARCH_PACE, on a trail
## at HF_TRAIL_PACE. A seizer, one held by the god or frightened or indoors is left be; one back on his feet goes on.
func _order_search() -> void:
	var live: Array[Person] = []
	for v: Variant in inquisitors:
		if _alive(v) and not (v as Person).inside and not _seizing(v):
			live.append(v as Person)
	var target := _search_point()
	if target == Vector2.INF:
		return
	var trailing := _trail >= 0
	var on_trail: Household = households[_trail] if trailing else null
	var spots := _door_spots(target, live.size()) if not trailing else pair_spots(target, live.size(), Vector2.INF, on_trail)
	var holding: Person = null
	if live.size() == 2 and spots.size() == 2:
		# The pair walks in file (ruling P5-T9-R8): the man nearer the place along the path goes to the place beyond (the far one from his fellow), the
		# other to the near one, so neither overtakes through the other; and the rear man holds where he stands until the gap along the path opens to
		# HF_PAIR_FILE, so that leaving a stop they do not walk side by side in a one-wide street.
		var a := live[0]
		var b := live[1]
		var la := _path_len(a.ground_pos, target)
		var lb := _path_len(b.ground_pos, target)
		var front := a
		var rear := b
		if absf(la - lb) < HF_FILE_STICKY and (b.get_instance_id() == _file_front):
			front = b
			rear = a
		elif lb < la - HF_FILE_STICKY:
			front = b
			rear = a
		_file_front = front.get_instance_id()
		var near_spot := spots[0] if rear.ground_pos.distance_to(spots[0]) <= rear.ground_pos.distance_to(spots[1]) else spots[1]
		var far_spot := spots[1] if near_spot == spots[0] else spots[0]
		live = [front, rear]
		spots = [far_spot, near_spot]
		var l_front := la if front == a else lb
		var l_rear := lb if front == a else la
		if rear.mind == Person.Mind.DUTY and l_rear - l_front < HF_PAIR_FILE and l_front > HF_ARRIVE + HF_PAIR_FILE:
			holding = rear
	# A place the man cannot walk to from where he stands (the street to it is shut from here) is not sent to: he goes to the door itself, and the places
	# are worked out afresh when the search arrives. (Else he stood still for good, anchored to it.)
	var dest: Array[Vector2] = []
	for k in live.size():
		dest.append(spots[k] if _reaches(live[k].ground_pos, spots[k]) else _walkable(target))
	# When one of the pair needs a new order they are both sent, so their anchors always stand together as the places do (on a trail the lamp
	# moves, and each re-ordered alone on his own distance left anchors 1.7 apart: ruling P5-T9-R1).
	var resend := false
	for k in live.size():
		var p := live[k]
		if p == holding or (p.mind != Person.Mind.DUTY and not p.mind in RECALL_MINDS):
			continue
		resend = resend or p.mind != Person.Mind.DUTY or p.anchor.distance_to(dest[k]) > (1.0 if trailing else MOVE)
	for k in live.size():
		var p := live[k]
		if p.mind != Person.Mind.DUTY and not p.mind in RECALL_MINDS:
			continue
		var paced := _set_pace(p, HF_TRAIL_PACE if trailing else HF_SEARCH_PACE)
		if p != holding and (paced or resend):
			p.go_duty(dest[k])


## The pair's places at the listed door `target` (the search is bound for it), worked out once: the line of walk is from the listed door before
## it (the Temple's door for the first), so the places never flip between looks. (Cleared at each arrival.)
func _door_spots(target: Vector2, n: int) -> Array[Vector2]:
	var key := "%s/%d" % [target, n]
	if not _pairs.has(key):
		var from := temple_door
		for k in range(1, _search.size()):
			if (_search[k].door as Vector2) == target:
				from = _search[k - 1].door
		_pairs[key] = pair_spots(target, n, from)
	return _pairs[key]


## The places the `n` inquisitors are sent to round `target` (god P5, MS §0 and §2: more than two Silent Doom radii apart, walking
## HF_SEARCH_GAP apart, at every stop and on a trail, so one Doom never takes the pair). On a trail (`trail`: the household's record) the
## first stands at the lamp's place and the second behind him: on the lamp's trail when that reaches far enough back, else, while the lamp is
## still near its house door, on the road's own points before the lamp (_road_behind(), the road drawn on past the door); the ring below
## only when neither leaves the pair apart (review of Task 4, re-review item 1; Task 9). Otherwise the pair stands in file along their line of
## walk (from `toward`, the listed door before the target, or the Temple's door for the first), else along the street axes, else the diagonals:
## a ring turned to each in turn, each spot snapped to walkable ground (_walkable() can pull two spots together), every place within HF_ARRIVE
## of the door (the stop starts when one of them is, so a place beyond it could stall the search) and reachable on foot, and the first turn
## that leaves them HF_SEARCH_GAP + HF_PAIR_SLACK - 0.1 apart is kept; none does, the widest. Only reads.
func pair_spots(target: Vector2, n: int, toward := Vector2.INF, trail: Household = null) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if n <= 1:
		for k in n:
			out.append(_walkable(target))
		return out
	var want := HF_SEARCH_GAP + HF_PAIR_SLACK - 0.1
	if trail != null:
		var lead := _walkable(target)
		if not trail.trail.is_empty():
			for step in 10:
				var behind := _trail_point(trail, target, HF_SEARCH_GAP + HF_PAIR_SLACK + 0.4 * float(step))
				if lead.distance_to(behind) >= want:
					out = [lead, behind]
					for k in range(2, n):
						out.append(_ring_spot(target, HF_SEARCH_GAP, k, n))
					return out
		var i := households.find(trail)
		if i >= 0:
			for step in 10:
				var behind := _road_behind(i, target, HF_SEARCH_GAP + HF_PAIR_SLACK + 0.4 * float(step))
				if behind != Vector2.INF and lead.distance_to(behind) >= want and _reaches(lead, behind):
					out = [lead, behind]
					for k in range(2, n):
						out.append(_ring_spot(target, HF_SEARCH_GAP, k, n))
					return out
	var turns: Array[float] = []
	if toward != Vector2.INF and toward.distance_to(target) > 1.0:
		turns.append((target - toward).angle())
	for k in 8:
		turns.append(PI * float(k) / 8.0)
	var best_gap := -2.0
	for radius in [(HF_SEARCH_GAP + HF_PAIR_SLACK) * 0.5, (HF_SEARCH_GAP + HF_PAIR_SLACK) * 0.65, (HF_SEARCH_GAP + HF_PAIR_SLACK) * 0.85,
			(HF_SEARCH_GAP + HF_PAIR_SLACK) * 1.1]:
		for turn in turns:
			var tried: Array[Vector2] = []
			for k in n:
				tried.append(_ring_spot(target, float(radius), k, n, turn))
			var gap := INF
			for a in n:
				for b in range(a + 1, n):
					gap = minf(gap, tried[a].distance_to(tried[b]))
				if not _reaches(target, tried[a]) or not _reaches(tried[a], target) or (toward != Vector2.INF and not _reaches(toward, tried[a])):
					gap = -1.0  # a place in a closed yard: nobody can walk to it (from the door, or from the door the search comes from)
				if trail == null and tried[a].distance_to(target) > HF_ARRIVE:
					gap = -1.0  # a place out of reach of the door: the stop might never start
			if gap > best_gap:
				best_gap = gap
				out = tried
			if gap >= want:
				return out
	if best_gap < 0.0 and n == 2:
		# No ring leaves both places walkable to and from the door (a door in an alley whose far side is shut): the pair is made of the places that are,
		# the two farthest apart of the door itself and every ring place that can be walked to and from it.
		var open: Array[Vector2] = [_walkable(target)]
		for radius in [(HF_SEARCH_GAP + HF_PAIR_SLACK) * 0.5, (HF_SEARCH_GAP + HF_PAIR_SLACK) * 0.65, HF_ARRIVE, HF_ARRIVE + 0.8, HF_ARRIVE + 1.6]:
			for k in 16:
				var q := _walkable(target + Vector2.from_angle(TAU * float(k) / 16.0) * float(radius))
				if _reaches(target, q) and _reaches(q, target) and (toward == Vector2.INF or _reaches(toward, q)):
					open.append(q)
		var widest := -1.0
		for a in open.size():
			for b in range(a + 1, open.size()):
				# (the stop begins when one of them is within HF_ARRIVE of the door, the other may stand a little farther)
				if minf(open[a].distance_to(target), open[b].distance_to(target)) <= HF_ARRIVE - 0.2 and open[a].distance_to(open[b]) > widest:
					widest = open[a].distance_to(open[b])
					out = [open[a], open[b]]
	return out


## The point `back` units behind `at` on household `i`'s own road (the walk from its door to its gate's way out): `at`'s nearest place on the
## road, then back along it; past the door, the road drawn on backwards along its first leg. On walkable ground; Vector2.INF with no road.
## Only reads. (Task 9: where the lamp's trail is still short, the second inquisitor stands on the road behind the lamp.)
func _road_behind(i: int, at: Vector2, back: float) -> Vector2:
	var line: Array = []
	for q: Vector2 in road(i):
		if line.is_empty() or (line.back() as Vector2).distance_to(q) > 0.01:
			line.append(q)  # (a road can repeat its first point: the door and the grid's first step)
	if line.size() < 2:
		return Vector2.INF
	var seg := 0
	var best := INF
	for k in range(line.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(at, line[k], line[k + 1])
		if q.distance_to(at) < best:
			best = q.distance_to(at)
			seg = k
	var here: Vector2 = Geometry2D.get_closest_point_to_segment(at, line[seg], line[seg + 1])
	var left := back
	var k := seg
	while k >= 0:
		var a: Vector2 = line[k]
		var run := here.distance_to(a)
		if run >= left:
			return _walkable(here.move_toward(a, left))
		left -= run
		here = a
		k -= 1
	var out_dir := ((line[0] as Vector2) - (line[1] as Vector2)).normalized()
	return _walkable(here + out_dir * left)


## A person at `a` can walk to `b` on the town's streets (always without a grid).
func _reaches(a: Vector2, b: Vector2) -> bool:
	return crowd._grid == null or a.distance_to(b) < 0.5 or not crowd._grid.path(a, b).is_empty()


## While the search stands at a door (or follows a trail), the gap between the two inquisitors when both stand within a step of their places is
## noted (stopped_gap_min, and per listed house in stopped_door_gap).
func _note_pair() -> void:
	if (_search_stop < 0.0 and _trail < 0) or inquisitors.size() < 2 or _search_at >= _search.size():
		return
	var a: Variant = inquisitors[0]
	var b: Variant = inquisitors[1]
	if not _alive(a) or not _alive(b) or (a as Person).inside or (b as Person).inside:
		return
	var pa := a as Person
	var pb := b as Person
	if pa.ground_pos.distance_to(pa.anchor) < HF_PLACE_NEAR and pb.ground_pos.distance_to(pb.anchor) < HF_PLACE_NEAR and pa.anchor.distance_to(pb.anchor) < 6.0:  # (6: an alley door's two places stand 4.5 apart)
		var gap := pa.ground_pos.distance_to(pb.ground_pos)
		stopped_gaps += 1
		stopped_gap_min = minf(stopped_gap_min, gap)
		while stopped_door_gap.size() < _search.size():
			stopped_door_gap.append(INF)
		stopped_door_gap[_search_at] = minf(stopped_door_gap[_search_at], gap)


## The seconds from now until the search reaches each listed house (MS §2, Ruling P5-11): the lead inquisitor's walk to the door it is
## bound for, each stop, each leg between doors, and the time a household out and not done at that point will take (its road left at the
## believers' pace). INF everywhere when no inquisitor stands and no relief is left to come.
func _refresh_eta() -> void:
	_eta_at = _clock
	_eta.clear()
	for k in _search.size():
		_eta.append(INF)
	if _search_at >= _search.size():
		return
	var speed := Person.PANIC_SPEED * HF_SEARCH_PACE
	var t := 0.0
	var from := temple_door
	var lead: Person = null
	for v: Variant in inquisitors:
		if _alive(v) and not (v as Person).inside:
			lead = v as Person
			break
	if lead != null:
		from = lead.ground_pos
	else:
		var wait := _relief_wait()
		if wait == INF:
			return
		t = wait
	var k := _search_at
	if _trail >= 0:
		t += _trail_left(_trail)
		from = _way_out_of(_trail)
		k += 1
	elif _search_stop >= 0.0:
		t += maxf(_search_stop - _clock, 0.0)
		from = _search[_search_at].door
		k += 1
	for j in range(k, _search.size()):
		var e: Dictionary = _search[j]
		t += _leg(from, e.door, j > k or lead == null or k != _search_at or _trail >= 0 or _search_stop >= 0.0) / speed
		_eta[j] = t
		t += HF_SEARCH_STOP
		from = e.door
		var hi := int(e.household)
		if hi >= 0 and j < _search.size() - 1:
			t += _trail_left(hi)
			from = _way_out_of(hi)


## The way out of the gate household `i` is bound for: where a search that has trailed it ends.
func _way_out_of(i: int) -> Vector2:
	return (gates[(households[i] as Household).gate] as Gate).way_out


## Seconds until a relief takes a fallen inquisitor's place: the soonest of those missing, INF with none left to come.
func _relief_wait() -> float:
	if inq_reliefs >= HF_SEARCH_RELIEFS:
		return INF
	var best := INF
	for k in inquisitors.size():
		var since: float = _inq_fallen[k]
		best = minf(best, maxf(HF_SEARCH_RELIEF_AFTER - (_clock - since), 0.0) if since >= 0.0 else HF_SEARCH_RELIEF_AFTER)
	return best


## The walk between two points through the town's streets: the grid path's length (the straight line with no grid or no path), cached.
## `cache` is false for the lead inquisitor's own place, which is never the same twice.
func _leg(a: Vector2, b: Vector2, cache := true) -> float:
	if not cache:
		return _path_len(a, b)
	var key := "%s>%s" % [a, b]
	if not _legs.has(key):
		_legs[key] = _path_len(a, b)
	return float(_legs[key])


## The grid path's length from `a` to `b`.
func _path_len(a: Vector2, b: Vector2) -> float:
	if crowd._grid == null:
		return a.distance_to(b)
	var path := crowd._grid.path(a, b)
	if path.is_empty():
		return a.distance_to(b)
	var len := 0.0
	var at := a
	for q: Vector2 in path:
		len += at.distance_to(q)
		at = q
	return len


## Seconds a household takes to be done once the search is on its trail: its road left from its lamp (from its door while inside) at the
## believers' pace; 0 once done.
func _trail_left(i: int) -> float:
	var h: Household = households[i]
	if h.done:
		return 0.0
	var at := h.door
	var lead := lamp(i) if h.out else null
	if lead != null:
		at = (lead.man as Person).ground_pos
	return _road_left(i, at) / (Person.PANIC_SPEED * HF_BELIEVER_PACE)


## The length of household `i`'s road (the base's cached walk to its gate's way out) still ahead of a believer at `at`: from the nearest
## point of the road on.
func _road_left(i: int, at: Vector2) -> float:
	var line: Array = road(i)
	var best := INF
	var left := 0.0
	var rest := 0.0
	for k in range(line.size() - 1, 0, -1):
		var a: Vector2 = line[k - 1]
		var b: Vector2 = line[k]
		var near := Geometry2D.get_closest_point_to_segment(at, a, b)
		var gap := near.distance_to(at)
		if gap <= best:
			best = gap
			left = near.distance_to(b) + rest
		rest += a.distance_to(b)
	return left + (best if best < INF else 0.0)


## Every marched believer's seconds to the Temple, from the seizer's walk (once a look, so tags() reads and never paths).
func _refresh_march() -> void:
	var now: Dictionary = {}
	for c in charges:
		if c.held and not _resolved(c) and _alive(c.seizer):
			var s := c.seizer as Person
			now[c] = {"eta": _path_len(s.ground_pos, return_to) / maxf(s.walk_speed, 0.1), "at": _clock}
	_march = now


## Seconds until marched believer `c` is delivered.
func _temple_in(c: Charge) -> float:
	if not _march.has(c):
		return 0.0
	return maxf(float(_march[c].eta) - (_clock - float(_march[c].at)), 0.0)


# --- The self-walk (shared rule 2) and out of the walls (shared rule 1) --------------------------------------------------------------

## Free (MS §2): a watcher who sees a believer outside the walls seizes him before he is out (T1R PF2's order: the outer post's sight comes
## first); then the self-walk; then the base's rule (the file's places, the way out, the sight, the hold).
func _step_free(c: Charge) -> void:
	var p := c.man as Person
	if p.inside:
		return
	if Walls.outside(p.ground_pos):
		var by := _seen_by(c)
		if by != null:
			_seize(c, by)
			return
	_walk_on(c)
	super(c)


## The household walks itself (MS §2): past fear, its lamp -- and any believer out of the file -- sent on to the nearest way out, wherever
## the god's hand left him once it lets go. A believer under the god's hand, or in a seizer's, is let be.
func _walk_on(c: Charge) -> void:
	var p := c.man as Person
	p.fearless_left = maxf(p.fearless_left, BOUND_HOLD)
	if p.held_by_god() or c.held or p.mind == Person.Mind.WHISPERED:
		return
	var i := int(_home.get(c, -1))
	if i < 0:
		return
	var in_file := bool(_in_file.get(c, false)) and lamp(i) != c and _file_spot(c) != Vector2.INF
	if in_file:
		return
	var to := _open_exit_near(p.ground_pos)
	if to == Vector2.INF:
		return
	c.hold_at = to
	if p.mind != Person.Mind.DUTY or p.anchor.distance_to(to) > MOVE:
		p.go_duty(to)


## A believer has reached a way out (MS §2, shared rule 1): anywhere out of the walls.
func _exit_reached(c: Charge) -> bool:
	return Walls.outside((c.man as Person).ground_pos)


## Out (MS §2): the believer is counted, the lamp's file walks on to the way out, and he is sent off the map.
func _escape(c: Charge) -> void:
	var i := int(_home.get(c, -1))
	if i >= 0 and lamp(i) == c:
		(households[i] as Household).out_to = _open_exit_near((c.man as Person).ground_pos)
	c.escaped = true
	rules.banner.emit(_escape_banner())
	send_off(c.man)


# --- The loss, the banners, the tags -------------------------------------------------------------------------------------------------

## Believers taken to the Temple or dead (MS §2).
func lost() -> int:
	var n := 0
	for c in charges:
		if c.taken or (not c.escaped and not _alive(c.man)):
			n += 1
	return n


## Why the night is lost now (MS §2): "faithful_lost" once two are taken or dead.
func lost_reason() -> String:
	return "faithful_lost" if lost() >= HF_LOSE else ""


func _opening_banner() -> String:
	return "HIDE THE FAITHFUL"


func _caught_banner() -> String:
	return "A BELIEVER IS SEIZED - FREE HIM BEFORE THE TEMPLE"


func _escape_banner() -> String:
	return "A BELIEVER IS OUT  %d/%d" % [out_count(), tune_need]


## The strip (MS §2): "The search reaches <household>" counting down to the listed house of each household the search has not reached yet.
func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in _search.size():
		var hi := int(_search[k].household)
		if hi < 0 or _reached(k) or k >= _eta.size() or _eta[k] == INF:
			continue
		out.append({"in": search_eta(k), "label": "The search reaches %s" % (households[hi] as Household).words})
	return out


## A waiting household's tag (MS §2): its door, "OUT IN" its countdown to the time it comes out at the latest.
func _waiting_tag(i: int) -> MapTag:
	var h: Household = households[i]
	return MapTag.place(h.door, MARK_NOT_YET, "OUT IN %s" % UiTheme.clock(due_in(i)), h.house.height, true)


## The map tags, most important first (MS §2): each marched believer "SEIZED - TEMPLE IN" its seconds, his seizer, the Temple's door; each
## lamp "BELIEVER - <GATE> IN" its seconds, blue, pointed at; each follower "BELIEVER"; a waiting house "OUT IN"; each listed house the search
## has not reached "SEARCH IN" its seconds (blue for a household's, grey for the others); each inquisitor "INQUISITOR", pointed at; the
## patrols (pointed at) and the gates' watch "WATCH". After the first loss each believer's tag ends "- DO NOT KILL".
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if lost_reason() != "" or out_count() >= tune_need:
		return out
	var warn := " - DO NOT KILL" if lost() >= 1 else ""
	var marched := false
	for c in charges:
		if not c.held or _resolved(c):
			continue
		out.append(MapTag.person((c.man as Person).ground_pos, MARK_WATCHED, "SEIZED - TEMPLE IN %s%s" % [UiTheme.clock(_temple_in(c)), warn], true))
		if _alive(c.seizer):
			out.append(MapTag.person((c.seizer as Person).ground_pos, MARK_WATCHED, "TAKING HIM IN", true))
		marched = true
	if marched:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE", 0.0, true))
	for i in households.size():
		var h: Household = households[i]
		if not h.out:
			out.append(_waiting_tag(i))
			continue
		var lead := lamp(i)
		for c: Charge in h.members:
			if _resolved(c) or c.held or (c.man as Person).inside:
				continue
			var p := c.man as Person
			if c == lead:
				var g := heading(i)
				var gate := String((gates[g] as Gate).label) if g >= 0 else "GATE"
				var eta := _road_left(i, p.ground_pos) / maxf(Person.PANIC_SPEED * HF_BELIEVER_PACE, 0.1)
				out.append(MapTag.person(p.ground_pos, MARK_CHARGE, "BELIEVER - %s IN %s%s" % [gate, UiTheme.clock(eta), warn], true))
			else:
				out.append(MapTag.person(p.ground_pos, MARK_CHARGE, "BELIEVER" + warn, true))
	for k in _search.size():
		if _reached(k) or k >= _eta.size() or _eta[k] == INF:
			continue
		var color := MARK_CHARGE if int(_search[k].household) >= 0 else MARK_NOT_YET
		out.append(MapTag.place(_search[k].door, color, "SEARCH IN %s" % UiTheme.clock(search_eta(k)), 0.0, true))
	for v: Variant in inquisitors:
		if _alive(v) and not (v as Person).inside and not _seizing(v):
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "INQUISITOR", true))
	for squad: Array in patrols:
		var named := false
		for v: Variant in squad:
			if _alive(v) and not (v as Person).inside and not _seizing(v):
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "" if named else "WATCH", not named))
				named = true
	var posted := 0
	for v: Variant in watch:
		if _alive(v) and not (v as Person).inside and not _seizing(v):
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "WATCH" if posted % 2 == 0 else ""))
		posted += 1
	return out


## The hint's phase (MS §2): "seized" while a believer is marched, "trail" while the search follows a household, else the mission's own.
func hint_phase() -> String:
	if lost_reason() != "" or out_count() >= tune_need:
		return ""
	for c in charges:
		if c.held and not _resolved(c):
			return "seized"
	return "trail" if _trail >= 0 else ""


## The tour (MS §2, *my call*): the north-west household's door, the Main Gate, the Temple's door; each line fits the caption's plate.
func tour() -> Array:
	var out := []
	if not households.is_empty():
		out.append([(households[0] as Household).door, "The north-west household hides here. At %s it walks itself to the Main Gate." % UiTheme.clock(
			float(HF_OUT_AT[0]))])
	if not gates.is_empty():
		out.append([(gates[0] as Gate).mouth, "Soldiers watch both gates and walk two streets. Clear them from the road."])
	out.append([temple_door, "The Temple. Two inquisitors set out from here, house by house."])
	return out


## What the results show (MS §2): the base's keys (the Gaze meter is shown for the call), and the Hunt's.
func report() -> Dictionary:
	if _no_gaze == null:
		_no_gaze = GazeMeter.new()
	gaze = _no_gaze
	var out := super()
	gaze = null
	out["lost"] = lost()
	out["searched"] = searched
	out["search_reliefs"] = inq_reliefs
	return out
