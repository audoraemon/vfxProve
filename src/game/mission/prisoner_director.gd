class_name PrisonerDirector
extends EscortDirector
## The Prisoner (v0.11 M4, Tier 3, mission spec §2; Escort, reused): a woman who spoke the god's name stands in the stocks at the head
## of the long west street, LANE_DOWN or more from the Citadel's gate -- a drawn market stall, the director's own (role `stocks`, never a
## building in a tally), taken away with the town. She is bound (EscortDirector.bound_by): held there, deaf to a whisper, past fear,
## seen by no one. Her two gaolers stand GAOLER_OFF either side of her, held past fear while she is bound, so the stocks' fall does not
## scare them off before they see her free (decision 119). Any blow or fire that brings the stocks down frees her; still standing at
## FREE_BY, the gaolers take her inside: lost. Free, she moves by the god's hand alone at PACE of a citizen's, and the watchers -- the
## gaolers, two patrols, the postern's watch and, HUE_AFTER after the stocks break, two searchers out of the Citadel -- seize her on
## sight and march her back to the Citadel's gate (a march of some seconds, the controller's ruling, so a seizure can be answered).
## Every watcher is a lay citizen made a watchman, so Mind Whisper and Discord work on all of them; held, frightened or indoors, one
## sees nothing. She gets out at the dock bank past the postern (open in a Prepared town), or by any way out of the town. The
## postern's watch changes as The Lost Lamb's does (EscortDirector's WATCH_CHANGE, WATCH_GAP, WATCH_CYCLE). Every person the director
## holds is kept out of the town's flight at each look, here and not in EscortDirector, so The Lost Lamb plays as before.

## Where the stocks stand (v0.11 M4, decision 105; moved by the controller's ruling from beside the Citadel's gate to the yard at the
## head of the long west street): tried on rings STOCKS_STEP apart round STOCKS_AT, out to STOCKS_RINGS; their footprint, height and
## role (not one of Rules.BUILDING_ROLES).
const STOCKS_AT := Vector2(-6.25, -7.4)
const STOCKS_SIZE := Vector2(0.6, 0.4)
const STOCKS_H := 10.0
const STOCKS_ROLE := &"stocks"
const STOCKS_STEP := 0.25
const STOCKS_RINGS := 6
## How far from the Citadel's gate the stocks and she stand at the least (v0.11 M4, the controller's ruling): a seizer's march back
## takes some seconds, time to answer it, never a loss within a second.
const LANE_DOWN := 4.0
## The foot of the Citadel's lane, which the stocks must leave walkable; the Citadel's gate, where a seizer takes her (v0.11 M4).
const LANE_FOOT := Vector2(-10.5, -5.1)
const CITADEL_GATE := HarvestDirector.CITADEL_GATE
## How far south of the stocks she stands, and how far north of them the far-side aim (and the STOCKS tag) lies (v0.11 M4).
const HER_OFF := 1.0
const FAR_OFF := 0.25
## The postern's mouth inside the wall, and the way out on the dock bank past it; its watch's posts either side of the mouth, and the
## guardhouse six units west along the wall where the watch goes for its change (v0.11 M4, mission spec §2).
const GATE_MOUTH := Vector2(-5.75, 14.6)
const EXIT := Vector2(-5.75, 17.4)
const POSTS := [Vector2(-6.45, 14.6), Vector2(-5.05, 14.6)]
const GUARDHOUSE := Vector2(-11.75, 14.4)
## The patrols' beats (v0.11 M4): the street by the cathedral across the lane's foot to the head of the long west street; the south
## street across the long west street.
const BEATS := [[Vector2(-14.0, -5.1), Vector2(-7.0, -5.1)], [Vector2(-14.0, 9.0), Vector2(-2.0, 9.0)]]
## Her road (v0.11 M4, decision 106): from the stocks down the long west street to the postern and out. For the policy, the tests and
## the tour only.
const ROAD := [STOCKS_AT + Vector2(0.0, HER_OFF), Vector2(-6.25, 13.5), GATE_MOUTH, EXIT]
## Mission spec §2's numbers (v0.11 M4), first guesses, tuned by Task 3's gate in this order: PACE (0.33-0.45), the beats, HUE_AFTER
## (20-45); then stop and report (WATCH_GAP is The Lost Lamb's too, decision 107). Freed by; the gaolers and how far from her; her
## pace; a patrol's size; the hue and cry; the searchers.
const FREE_BY := 120.0
const GAOLERS := 2
const GAOLER_OFF := 1.7
const PACE := 0.33
const PATROL_SIZE := 2
const HUE_AFTER := 30.0
const HOUNDS := 2
## Where the camera rests (v0.11 M4, Decision 80): the stocks and the Citadel's gate above and right of the centre; the postern's
## arrow on the bottom edge, left, below the HUD stack.
const CAMERA_AT := Vector2(-9.0, -2.0)
## The stocks' tag (v0.11 M4): orange, a place.
const MARK_STOCKS := Color("ff9a3a")
## Screen pixels the stocks' plate stands above the usual place's, clear of the prisoner's plate over the same spot (v0.11 M4).
const STOCKS_LIFT := 14.0
## Screen pixels a gaoler's diamond rides above his feet: none, so his plate stands below the prisoner's, not hidden by it (v0.11 M4).
## 0.0 is chosen, not a placeholder (Task 7's photographs): his diamond sits at his feet and his plate just above it, below hers; at
## the usual MapTag.PERSON_LIFT his plate overlapped hers and the HUD dropped it (Hud.tag_layout keeps the earlier plate).
const GAOLER_LIFT := 0.0

## The stocks; the aim on their far side, where their tag sits (v0.11 M4).
var stocks: Structure
var stocks_far := Vector2.INF
## The gaolers and their posts; the searchers waiting inside the Citadel until the hue and cry (untyped: any may be freed) (v0.11 M4).
var gaolers: Array = []
var gaoler_posts: Array[Vector2] = []
var searchers: Array = []
## The Citadel's gate on walkable ground (v0.11 M4).
var citadel_door := Vector2.INF
## Seconds to the next look at the gaolers and at everyone held (v0.11 M4).
var _keep_in := 0.0


## The mission's places and numbers (v0.11 M4): the stocks placed and binding her; the postern, the beats, the hue and cry.
func _plan() -> void:
	citadel_door = _walkable(CITADEL_GATE)
	stocks = _place_stocks()
	if stocks == null:
		push_warning("PrisonerDirector: no room for the stocks; she starts free")
	var c := stocks.center() if stocks != null else STOCKS_AT
	bound_by = stocks
	free_by = FREE_BY
	charge_start = c + Vector2(0.0, HER_OFF)
	stocks_far = c - Vector2(0.0, FAR_OFF)
	gate_at = GATE_MOUTH
	exit_at = EXIT
	return_to = CITADEL_GATE
	guardhouse = GUARDHOUSE
	for p: Vector2 in POSTS:
		watch_posts.append(p)
	for b: Array in BEATS:
		var line := PackedVector2Array()
		for at: Vector2 in b:
			line.append(_walkable(at))
		beats.append(line)
	patrol_size = PATROL_SIZE
	hunt_at = -1.0
	hunt_after_free = HUE_AFTER
	hunt_size = HOUNDS
	charge_pace = PACE
	charge_label = "PRISONER"
	exit_label = "POSTERN"
	return_label = "CITADEL"


## The stocks (v0.11 M4, decision 105 and the controller's ruling): the first walkable spot on the rings round STOCKS_AT, LANE_DOWN or
## more from the Citadel's gate, whose stall leaves a walk path from the Citadel's gate to the lane's foot and walkable ground where she
## stands, with a way from the gate to her; each one tried is added, tested and, failing, taken away. Null for none.
func _place_stocks() -> Structure:
	var lane := _walkable(LANE_FOOT)
	for ring in STOCKS_RINGS + 1:
		var n := maxi(1, ring * 6)
		for k in n:
			var at := STOCKS_AT + Vector2.from_angle(TAU * float(k) / float(n)) * STOCKS_STEP * float(ring)
			var her := at + Vector2(0.0, HER_OFF)
			if at.distance_to(citadel_door) < LANE_DOWN or her.distance_to(citadel_door) < LANE_DOWN:
				continue
			if crowd._grid != null and not crowd._grid.walkable(at):
				continue
			var s := crowd._env.add_structure(Rect2(at - STOCKS_SIZE * 0.5, STOCKS_SIZE), STOCKS_H, Structure.Kind.MARKET_STALL, STOCKS_ROLE)
			if crowd._grid == null or (not crowd._grid.path(citadel_door, lane).is_empty() and crowd._grid.walkable(her)
					and not crowd._grid.path(citadel_door, her).is_empty()):
				town._built.append(s)  # the town takes it away with its own buildings (Town.teardown())
				return s
			crowd._env.remove(s)
	return null


## The night's people (v0.11 M4, decision 104): she -- the lay citizen nearest her spot -- then her gaolers either side of her, set
## down and kept on duty at their posts, and the searchers waiting inside the Citadel's gate. All but her made watchmen. Appointed
## here, before the base appoints the watch and the patrols, which leave them out (_in_use()).
func _appoint_charge() -> Person:
	var near := _lay_near(charge_start, 1)
	if near.is_empty():
		return null
	var her := near[0]
	var at := _walkable(charge_start)
	for k in GAOLERS:
		var post := _walkable(at + Vector2(GAOLER_OFF * (-1.0 if k % 2 == 0 else 1.0), 0.0))
		var crew := _lay_near(post, 1, [her] + gaolers)
		if crew.is_empty():
			continue
		_watchman(crew[0])
		_set_down(crew[0], post)
		crew[0].go_duty(post)
		gaolers.append(crew[0])
		gaoler_posts.append(post)
	for k in HOUNDS:
		var crew := _lay_near(citadel_door, 1, [her] + gaolers + searchers)
		if crew.is_empty():
			break
		_watchman(crew[0])
		_set_down(crew[0], citadel_door)
		crew[0].go_duty(citadel_door)
		_take_inside(crew[0], null)
		searchers.append(crew[0])
	return her


## `p` in the watch cloak and lantern (v0.11 M4).
func _watchman(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN


## Everyone at work for her (v0.11 M4): the base's, and the gaolers and searchers.
func _in_use(c: Person) -> Array:
	var out := super(c)
	out.append_array(gaolers)
	out.append_array(searchers)
	return out


## The postern's watch (v0.11 M4, Decision 69): the lay citizens nearest its posts, made watchmen and set down there.
func _appoint_watch(c: Person, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var post := _walkable(watch_posts[i])
		var crew := _lay_near(post, 1, _in_use(c) + out)
		if crew.is_empty():
			break
		_watchman(crew[0])
		_set_down(crew[0], post)
		out.append(crew[0])
	return out


## A patrol (v0.11 M4): the lay citizens nearest its beat's first point, made watchmen and set down there.
func _appoint_patrol(c: Person, beat: PackedVector2Array, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var spot := _ring_spot(beat[0], 0.5, i, n)
		var crew := _lay_near(spot, 1, _in_use(c) + out)
		if crew.is_empty():
			break
		_watchman(crew[0])
		_set_down(crew[0], spot)
		out.append(crew[0])
	return out


## The hue and cry (v0.11 M4, Decision 71): the searchers still waiting come out of the Citadel's gate, any the evacuation sent running
## where they waited stopped first (Task 1's note: Crowd._evacuate() runs the indoors too, and Person.go_duty() refuses a fleeing man);
## the base sends them after her.
func _appoint_hunters(_c: Person, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in searchers:
		if out.size() >= n:
			break
		if _alive(v) and (v as Person).inside:
			_bring_out(v as Person, citadel_door)
			_keep_from_flight(v as Person, true)
			out.append(v as Person)
	return out


## A lay watchman goes on duty at his post (v0.11 M4, decision 107); on duty he runs, so `hurry` changes nothing.
func _post_to(p: Person, at: Vector2, _hurry: bool) -> void:
	p.go_duty(at)


## A lay watchman takes his post or beat again (v0.11 M4, decision 107): out of doors, on duty or back on his feet, and neither her
## seizer nor a searcher (each on his own errand).
func _takes_post(p: Person) -> bool:
	return not p.inside and p != seizer and not hunters.has(p) and (p.mind == Person.Mind.DUTY or p.mind in RECALL_MINDS)


## Every watcher (v0.11 M4): the base's three groups -- the watch, the patrols, the searchers sent out -- and the gaolers. Gathered
## into an untyped Array here, not through the base's copy of the typed watch, which refuses a freed body (review focus 5).
func _watchers() -> Array:
	var out: Array = []
	out.append_array(watch)
	for squad: Array in patrols:
		out.append_array(squad)
	out.append_array(hunters)
	out.append_array(gaolers)
	return out


## One step (v0.11 M4): the Escort type's, then every TICK a look of its own -- everyone it holds kept out of the town's flight
## (_keep_held(), the controller's ruling: here, never in EscortDirector, so The Lost Lamb stays exact), and the gaolers, held past fear
## while she is bound (decision 119), each not her seizer kept on duty at his post.
func step(delta: float) -> void:
	super(delta)
	if escaped or taken or bound_lost or not _alive(charge):
		return
	_keep_in -= delta
	if _keep_in > 0.0:
		return
	_keep_in = TICK
	var evacuating := _evacuation_began()
	_keep_held(evacuating)
	for i in gaolers.size():
		var g: Variant = gaolers[i]
		if not _alive(g) or g == seizer:
			continue
		if bound:
			(g as Person).fearless_left = maxf((g as Person).fearless_left, BOUND_HOLD)
		_recall_to(g, gaoler_posts[i], evacuating)


## Everyone the director holds is kept out of the town's flight by the one rule (v0.11 M4, the final review's ruling,
## MissionDirector._hold_all()): every watcher, the searchers indoors or out (each once: a searcher sent out is a watcher too), and she
## while she is bound. Free, she is left to the Lost Lamb's rule: the crowd carrying her out is her escape. A watchman it stops is put
## back on his post or beat at the base's next look (_takes_post()). The flight a false calm owes is let go too: this director's own
## hold past fear (BOUND_HOLD) puts off an evacuation's flee() until it wears off (Person._reassured_fled), when a gaoler back on his
## feet would run for the gates after the evacuation's one look had passed.
func _keep_held(evacuating: bool) -> void:
	var people: Array = _watchers()
	for v: Variant in searchers:
		if not people.has(v):
			people.append(v)
	if bound:
		people.append(charge)
	_hold_all(people, evacuating)


## The night is lost while she is still bound at FREE_BY (v0.11 M4).
func lost_reason() -> String:
	return "prisoner_inside" if bound_lost else ""


## While she is bound (v0.11 M4, decision 96): "Free the prisoner: taken inside 1:23".
func hud_line() -> String:
	if not bound or timeline == null:
		return ""
	return "Free the prisoner: taken inside %s" % UiTheme.clock(timeline.seconds_to("inside"))


## The opening banner (v0.11 M4).
func _opening_banner() -> String:
	return "BREAK HER FREE"


## The timeline's words when the searchers set out (v0.11 M4).
func _hunt_label() -> String:
	return "The Citadel sends its hounds"


## The banner when a watcher seizes her (v0.11 M4).
func _caught_banner() -> String:
	return "THE PRISONER IS CAUGHT"


## The banner when she is freed of her seizer (v0.11 M4).
func _freed_banner() -> String:
	return "SHE IS FREE"


## The banner when she is freed of the stocks (v0.11 M4).
func _unbound_banner() -> String:
	return "SHE IS FREE"


## The banner when she is taken back (v0.11 M4).
func _taken_banner() -> String:
	return "THE PRISONER IS TAKEN BACK"


## The banner when she gets out (v0.11 M4).
func _escape_banner() -> String:
	return "SHE IS OUT"


## The banner when the postern's watch goes for its change (v0.11 M4).
func _change_banner() -> String:
	return "THE GUARD CHANGES"


## The timeline's words when the gaolers take her inside (v0.11 M4).
func _inside_label() -> String:
	return "The gaolers take her inside"


## The map tags, most important first (v0.11 M4, mission spec §2): her (PRISONER - DO NOT KILL while bound, PRISONER once free, red and
## CAUGHT while held), pointed at; the stocks' deadline on their far side while they stand (its seconds counting down as the strip
## does, v0.11 M6's final review); the postern, watched or clear, pointed at; her seizer and the Citadel's gate while she is held;
## GAOLER - SEIZES HER on each gaoler (the controller's ruling: the warning said plainly), pointed at (the final review); each
## searcher, pointed at; PATROL on each patrol's first watchman and a red diamond on the rest; a red diamond on the postern's watch
## while at it.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if escaped or taken or bound_lost or not _alive(charge):
		return out
	if bound:
		out.append(MapTag.person(charge.ground_pos, MARK_CHARGE, "PRISONER - DO NOT KILL", true))
		if is_instance_valid(stocks) and not stocks.destroyed:
			var left := timeline.seconds_to("inside") if timeline != null else FREE_BY
			var spot := MapTag.place(stocks_far, MARK_STOCKS, "STOCKS - TAKEN INSIDE IN %s" % UiTheme.clock(left), stocks.height, false)
			spot.lift += STOCKS_LIFT  # above the prisoner's own plate, which stands over the same spot (the photograph, v0.11 M4)
			out.append(spot)
	elif held:
		out.append(MapTag.person(charge.ground_pos, MARK_WATCHED, "PRISONER - CAUGHT", true))
	else:
		out.append(MapTag.person(charge.ground_pos, MARK_CHARGE, "PRISONER", true))
	var clear := watch_away or not _gate_watched()
	out.append(MapTag.place(exit_at, MARK_CLEAR if clear else MARK_WATCHED, "POSTERN - CLEAR" if clear else "POSTERN - WATCHED", 0.0, true))
	if held and _alive(seizer):
		out.append(MapTag.person((seizer as Person).ground_pos, MARK_WATCHED, "TAKING HER BACK", true))
		out.append(MapTag.place(return_to, MARK_WATCHED, "CITADEL"))
	for v: Variant in gaolers:
		if _alive(v) and v != seizer and not (v as Person).inside:
			var warn := MapTag.person((v as Person).ground_pos, MARK_WATCHED, "GAOLER - SEIZES HER", true)
			warn.lift = GAOLER_LIFT  # at the feet: the gaolers stand by the prisoner, and her plate would hide a plate over their heads
			out.append(warn)
	for v: Variant in hunters:
		if _alive(v) and v != seizer and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "SEARCHER", true))
	for squad: Array in patrols:
		var named := false
		for v: Variant in squad:
			if _alive(v) and v != seizer and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "" if named else "PATROL"))
				named = true
	if not watch_away:
		for v: Variant in watch:
			if _alive(v) and v != seizer and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M4, mission spec §2): "bound"; "caught" while held; near the postern "gate" or "clear"; "hounds" while a
## searcher is out; else "".
func hint_phase() -> String:
	if escaped or taken or bound_lost or not _alive(charge):
		return ""
	if bound:
		return "bound"
	if held:
		return "caught"
	if charge.ground_pos.distance_to(gate_at) <= NEAR_GATE:
		return "clear" if watch_away or not _gate_watched() else "gate"
	for v: Variant in hunters:
		if _alive(v) and v != seizer and not (v as Person).inside:
			return "hounds"
	return ""


## The tour (v0.11 M4, mission spec §2): her in the stocks, the postern, the Citadel.
func tour() -> Array:
	var out := []
	if _alive(charge):
		out.append([charge.ground_pos, "The prisoner in the stocks by the Citadel. Break her free by %s: do not kill her." % UiTheme.clock(FREE_BY)])
	out.append([gate_at, "The postern, down to the dock. Its guard changes soon after she draws near."])
	out.append([citadel_door, "The Citadel. Once she is free it sends its hounds after her."])
	return out


## What the results show (v0.11 M4): the Escort type's, when she was freed, and whether she was taken inside.
func report() -> Dictionary:
	var out := super()
	out["freed_at"] = freed_at
	out["inside"] = bound_lost
	return out
