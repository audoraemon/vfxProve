class_name ExodusDirector
extends EscortDirector
## Exodus (v0.11 M6, Tier 5, mission spec §2; Escort with many charges, Decision 222): the god leads three households of believers out of
## Aldermere while the Inquisition shuts the gates one by one. Twelve believers (BELIEVERS), four to a household, wait inside their
## house -- the dwelling nearest its point whose door the street reaches, quiet (no beat or gate post within QUIET of its door), stone
## tonight -- until their time on the chain (OUT_AT, or CHAIN after the one before is done: each of its four out, taken or dead). Out,
## they hold at the door and move by the god's hand alone at BELIEVER_PACE; a household follows its lamp-bearer in file (plan decision
## 282), the lamp passing on (lamp()). Each is a charge on the Escort type's Charge record. The watchers -- two patrols, two watchmen at
## each gate's mouth (no guard change: watch_changes false), and HOUNDS searchers per household sent HUNT_AFTER after it comes out --
## are lay citizens made watchmen: a watcher within SIGHT seizes a believer and marches him to the Temple's door, where he is taken
## inside; a watcher held by the god, frightened or indoors sees nothing, and one marching a believer sees no other. The gates shut at
## SHUT_AT; a shut gate is no way out. Ten out wins (EscortObjective, need NEED); too few left, or the last gate shut with fewer than ten
## out, loses at once (lost_reason()). Every held person is kept from the town's flight by MissionDirector._hold_all(). Its own Gaze
## hears every death (the field's enemy_killed) and a seen one adds GazeMeter.SEEN_DEATH (the controller's ruling).

## One household (v0.11 M6): a plain record, so the director holds no cycle.
class Household:
	extends RefCounted
	## Its words ("the west household") and its name on the tags ("WEST").
	var words := ""
	var name := ""
	## Its house, and the door the street reaches.
	var house: Structure
	var door := Vector2.INF
	## The gate it is bound for (an index into gates).
	var gate := 0
	## Its four believers' Charge records, in order.
	var members: Array = []
	## Out, and when; done, and when (the night's real seconds, -1 until then).
	var out := false
	var out_at := -1.0
	var done := false
	var done_at := -1.0
	## Its lamp's footsteps, oldest first (plan decision 282).
	var trail: Array[Vector2] = []
	## The way out its lamp got out by, where the file walks on to; Vector2.INF until then.
	var out_to := Vector2.INF
	## Its searchers (Variants: any may be freed), and whether they were sent.
	var searchers: Array = []
	var sent := false


## One gate (v0.11 M6): a plain record.
class Gate:
	extends RefCounted
	## Its name on the tags ("POSTERN") and in words ("the postern").
	var label := ""
	var words := ""
	## Its mouth inside the wall, and its way out beyond it.
	var mouth := Vector2.INF
	var way_out := Vector2.INF
	## When it shuts (the timeline's seconds), and whether it has.
	var shut_at := 0.0
	var shut := false


## The households, in the order they come out: each house is the dwelling nearest its point with a quiet door; its words, its name, its
## gate (v0.11 M6). The south household's point moved from (-2.5, 10.5) to the south-east quarter in Task 6 (the houses are a tuning
## knob, Decision 229): no dwelling near the old point has a door QUIET from the west street's beat and the gates' posts.
const HOUSE_POINTS := [Vector2(-10.5, 7.0), Vector2(7.5, 4.5), Vector2(7.7, 13.8)]
const HOUSE_WORDS := ["the west household", "the east household", "the south household"]
const HOUSE_NAMES := ["WEST", "EAST", "SOUTH"]
## The gates: the postern, the Side Gate, the Main Gate -- their mouths, ways out, names, words, and the way along the wall at each.
const GATE_MOUTHS := [Vector2(-5.75, 14.6), Vector2(14.4, 9.0), Vector2(2.7, 14.4)]
const GATE_EXITS := [Vector2(-5.75, 17.4), Vector2(17.6, 9.0), Vector2(2.7, 17.6)]
const GATE_LABELS := ["POSTERN", "SIDE GATE", "MAIN GATE"]
const GATE_WORDS := ["the postern", "the Side Gate", "the Main Gate"]
const GATE_ALONG := [Vector2.RIGHT, Vector2.DOWN, Vector2.RIGHT]
## The Temple's door, where a seized believer is taken and the searchers and reliefs come from (v0.11 M6).
const TEMPLE_DOOR := LostLambDirector.TEMPLE_DOOR
## The patrols' beats (v0.11 M6): the long west street, along the west household's road to the postern; the east-west street, between
## the east household's road and the south household's (about 2.2 and 2.8 units from them).
const BEATS := [[Vector2(-6.25, 0.0), Vector2(-6.25, 12.0)], [Vector2(1.0, 9.0), Vector2(12.0, 9.0)]]
## Mission spec §2's numbers (v0.11 M6), first guesses, tuned by Step 9's gate in this order: CHAIN (20-30), BELIEVER_PACE (0.4-0.55),
## the houses (12-16 units of street from their gates), OUT_AT[0] (10-30), HUNT_AFTER (20-45); HUNT_AFTER down if doing nothing does not
## lose. The households; how many must get out; their times and chain; their pace; the file.
const BELIEVERS := 12
const PER_HOUSE := 4
const NEED := 10
const OUT_AT := [15.0, 105.0, 195.0]
const CHAIN := 25.0
const BELIEVER_PACE := 0.45
const FOLLOW_GAP := 0.9
const FOLLOW_REACH := 4.0
const REJOIN := 2.0
const TRAIL_MAX := 40
## The watch (v0.11 M6): a patrol's size; each gate's two posts, POST_GAP apart; return, relief and the reliefs in a night; the searchers'
## delay and number; how quiet a household's door is.
const PATROL_SIZE := 2
const GATE_WATCH := 2
const POST_GAP := 2.4
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const HUNT_AFTER := 30.0
const HOUNDS := 2
const QUIET := 3.5
## The gates' shutting (v0.11 M6), and how long before it a gate's tag warns of it.
const SHUT_AT := [150.0, 225.0, 300.0]
const SHUT_WARN := 60.0
## How far round its door a household stands when it comes out; how many dwellings a house's choice weighs; how near a believer the
## searchers count as on his household (the "hounds" hint) (v0.11 M6).
const OUT_RING := 0.6
const HOUSE_TRIES := 12
const HOUNDS_NEAR := 6.0
## Where the camera rests (v0.11 M6, Decision 247): the west household's door and the postern left of the centre, the Main Gate at the
## bottom.
const CAMERA_AT := Vector2(-7.0, 9.0)
## The map tags' colours a believer's base does not name (v0.11 M6): not yet grey, a shutting gate orange.
const MARK_NOT_YET := Color("9a948a")
const MARK_PLACE := Color("ff9a3a")

## The households and the gates (v0.11 M6).
var households: Array = []
var gates: Array = []
## The Temple and its door (v0.11 M6).
var temple: Structure
var temple_door := Vector2.INF
## How many gate reliefs came this night (v0.11 M6).
var reliefs := 0
## Each house's own damage filter before tonight (v0.11 M6).
var _own_filters: Array[Callable] = []
## Charge -> its household's index; instance id -> household index while appointing; Charge -> in the file (v0.11 M6).
var _home := {}
var _home_of := {}
var _in_file := {}
## Instance id -> the second a watcher first stood back on his feet (plan decision 285); the second the recall at once ends.
var _calm_since := {}
var _recall_until := -1.0
## Each gate post's watchman's fall, the second (-1 while he stands) (v0.11 M6).
var _fallen_since: Array[float] = []
## Each household's road to its gate's way out, cached by gate (v0.11 M6, for the scripted player).
var _roads := {}
## Seconds to the next look (v0.11 M6).
var _keep_in := 0.0


## The plan (v0.11 M6): the Gaze, no guard change, the Temple, the gates and their posts, the beats, the households' houses.
func _plan() -> void:
	gaze = GazeMeter.new()
	watch_changes = false
	temple_door = _walkable(TEMPLE_DOOR)
	return_to = TEMPLE_DOOR
	guardhouse = TEMPLE_DOOR
	gate_at = GATE_MOUTHS[2]
	exit_at = GATE_EXITS[2]
	hunt_at = -1.0
	charge_label = "LAMP"
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	for g in GATE_MOUTHS.size():
		var gate := Gate.new()
		gate.label = String(GATE_LABELS[g])
		gate.words = String(GATE_WORDS[g])
		gate.mouth = _walkable(GATE_MOUTHS[g])
		gate.way_out = _walkable(GATE_EXITS[g])
		gate.shut_at = float(SHUT_AT[g])
		gates.append(gate)
		for k in GATE_WATCH:
			watch_posts.append(_walkable(gate.mouth + (GATE_ALONG[g] as Vector2) * POST_GAP * (float(k) - 0.5)))
	for b: Array in BEATS:
		var line := PackedVector2Array()
		for at: Vector2 in b:
			line.append(_walkable(at))
		beats.append(line)
	patrol_size = PATROL_SIZE
	var skip: Array = []
	for i in HOUSE_POINTS.size():
		var h := Household.new()
		h.words = String(HOUSE_WORDS[i])
		h.name = String(HOUSE_NAMES[i])
		h.gate = i
		h.house = _quiet_house(HOUSE_POINTS[i], gates[i].mouth, skip)
		if h.house == null:
			push_warning("ExodusDirector: no house for %s" % h.words)
			continue
		skip.append(h.house)
		h.door = _quiet_door(h.house, (gates[i] as Gate).mouth)
		if h.door == Vector2.INF:
			h.door = _open_door(h.house, (gates[i] as Gate).mouth)
		households.append(h)


## The dwelling nearest `at` for a household bound for `mouth` (v0.11 M6): one of its doors the street reaches from the gate and quiet
## (_quiet_door()), none of `skip`, never a wish's (_house_near()); the first reachable one when none tried has a quiet door; null for
## none.
func _quiet_house(at: Vector2, mouth: Vector2, skip: Array) -> Structure:
	var tried := skip.duplicate()
	var first: Structure = null
	for k in HOUSE_TRIES:
		var h := _house_near(at, tried)
		if h == null:
			break
		tried.append(h)
		if _quiet_door(h, mouth) != Vector2.INF:
			return h
		if first == null and _open_door(h, mouth) != Vector2.INF:
			first = h
	return first


## The first door of `h` -- its front, its back, then a side, as _open_door() tries them -- that the street reaches from `mouth` and that
## is quiet (_quiet()); Vector2.INF for none (v0.11 M6). Only reads.
func _quiet_door(h: Structure, mouth: Vector2) -> Vector2:
	var half := h.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(h.center() + off)
		if _quiet(door) and (crowd._grid == null or not crowd._grid.path(mouth, door).is_empty()):
			return door
	return Vector2.INF


## No beat passes and no gate post stands within QUIET of `door` (v0.11 M6). Only reads.
func _quiet(door: Vector2) -> bool:
	for p: Vector2 in watch_posts:
		if p.distance_to(door) <= QUIET:
			return false
	for b: Array in BEATS:
		if Geometry2D.get_closest_point_to_segment(door, b[0], b[1]).distance_to(door) <= QUIET:
			return false
	return true


## The Escort type's setup, then the searchers inside the Temple, the houses stone, the households and the shuttings on the strip
## (v0.11 M6).
func _begin() -> void:
	super()
	for h: Household in households:
		for k in HOUNDS:
			var near := _lay_near(temple_door, 1, _in_use(charge))
			if near.is_empty():
				break
			var p := near[0]
			_watchman(p)
			_set_down(p, temple_door)
			p.go_duty(temple_door)
			_take_inside(p, temple)
			h.searchers.append(p)
		_own_filters.append(h.house.damage_filter)
		h.house.damage_filter = _stone
	for i in watch.size():
		_fallen_since.append(-1.0)
	crowd._field.enemy_killed.connect(_on_killed)
	for i in households.size():
		timeline.add(float(OUT_AT[i]), "out_%d" % i, "The %s comes out" % (households[i] as Household).words.trim_prefix("the "),
			_come_out.bind(i), func() -> bool: return not (households[i] as Household).out)
	for g in gates.size():
		timeline.add(float(SHUT_AT[g]), "shut_%d" % g, "The Inquisition shuts %s" % (gates[g] as Gate).words, _shut.bind(g))


## The twelve believers (v0.11 M6): the four lay citizens nearest each household's door.
func _appoint_charges() -> Array[Person]:
	var out: Array[Person] = []
	for i in households.size():
		for p in _lay_near((households[i] as Household).door, PER_HOUSE, out):
			out.append(p)
			_home_of[p.get_instance_id()] = i
	return out


## Believer `c` set down at his household's door at BELIEVER_PACE, on duty, and taken inside its house (v0.11 M6).
func _place_charge(c: Charge) -> void:
	var p := c.man as Person
	var i := int(_home_of.get(p.get_instance_id(), 0))
	var h: Household = households[i]
	_home[c] = i
	h.members.append(c)
	_set_down(p, h.door)
	p.pace *= BELIEVER_PACE
	c.hold_at = h.door
	p.go_duty(h.door)
	_take_inside(p, h.house)


## `p` in the watch cloak and lantern (v0.11 M6).
func _watchman(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN


## Everyone at the night's work (v0.11 M6): the Escort type's (every believer, the watch, the patrols), and the searchers.
func _in_use(c: Person) -> Array:
	var out := super(c)
	for h: Household in households:
		out.append_array(h.searchers)
	return out


## Each gate's watch (v0.11 M6): the lay citizens nearest its posts, made watchmen and set down there.
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


## A patrol (v0.11 M6): the lay citizens nearest its beat's first point, made watchmen and set down there.
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


## A lay watchman goes on duty at his post (v0.11 M6, The Prisoner's way).
func _post_to(p: Person, at: Vector2, _hurry: bool) -> void:
	p.go_duty(at)


## A lay watchman takes his post or beat again (v0.11 M6, plan decision 285): on duty, always; back on his feet, RETURN_AFTER after he
## first stood so -- at once in the two looks after the evacuation began; never a seizer, a searcher or one indoors.
func _takes_post(p: Person) -> bool:
	if p.inside or _seizing(p) or _is_searcher(p):
		return false
	var id := p.get_instance_id()
	if p.mind == Person.Mind.DUTY:
		_calm_since.erase(id)
		return true
	if not p.mind in RECALL_MINDS:
		_calm_since.erase(id)
		return false
	if _clock <= _recall_until:
		return true
	if not _calm_since.has(id):
		_calm_since[id] = _clock
	return _clock - float(_calm_since[id]) >= RETURN_AFTER


## `v` marches a believer now (v0.11 M6).
func _seizing(v: Variant) -> bool:
	for c in charges:
		if c.held and c.seizer == v:
			return true
	return false


## `v` is one of the searchers (v0.11 M6).
func _is_searcher(v: Variant) -> bool:
	for h: Household in households:
		if h.searchers.has(v):
			return true
	return false


## Every watcher (v0.11 M6): the gates' watch, the patrols, and the searchers sent out by a household not yet done. Untyped: any may be
## freed.
func _watchers() -> Array:
	var out: Array = []
	out.append_array(watch)
	for squad: Array in patrols:
		out.append_array(squad)
	for h: Household in households:
		if h.sent and not h.done:
			out.append_array(h.searchers)
	return out


## A believer has reached a way out (v0.11 M6, Decision 228): any open gate's.
func _exit_reached(c: Charge) -> bool:
	var at := (c.man as Person).ground_pos
	for g: Gate in gates:
		if not g.shut and at.distance_to(g.way_out) <= ESCAPE_REACH:
			return true
	return false


## The nearest open gate's way out to `at`, or Vector2.INF with every gate shut (v0.11 M6).
func _open_exit_near(at: Vector2) -> Vector2:
	var best := Vector2.INF
	for g: Gate in gates:
		if not g.shut and (best == Vector2.INF or g.way_out.distance_to(at) < best.distance_to(at)):
			best = g.way_out
	return best


## Free (v0.11 M6): a follower in file holds at his place in it (_file_spot()); then the Escort type's rule.
func _step_free(c: Charge) -> void:
	if (c.man as Person).inside:
		return
	var spot := _file_spot(c)
	if spot != Vector2.INF:
		c.hold_at = spot
	super(c)


## Held (v0.11 M6): the Escort type's march; delivered, he goes inside the Temple (plan decision 283).
func _step_held(c: Charge) -> void:
	super(c)
	if c.taken and _alive(c.man) and not (c.man as Person).inside:
		_take_inside(c.man as Person, temple)


## Out (v0.11 M6): a household's lamp getting out sends its file on to his way out (plan decision 282); then the Escort type's.
func _escape(c: Charge) -> void:
	var i := int(_home.get(c, -1))
	if i >= 0 and lamp(i) == c:
		(households[i] as Household).out_to = _open_exit_near((c.man as Person).ground_pos)
	super(c)


## Household `i`'s lamp-bearer (v0.11 M6, plan decision 287): its first member in town, alive, out of doors, not out, not taken and not
## held by a seizer; null for none.
func lamp(i: int) -> Charge:
	for c: Charge in (households[i] as Household).members:
		if not _resolved(c) and not c.held and not (c.man as Person).inside:
			return c
	return null


## Household `i`'s followers in file now (v0.11 M6), in order. Only reads.
func followers(i: int) -> Array:
	var out := []
	var lead := lamp(i)
	for c: Charge in (households[i] as Household).members:
		if c != lead and bool(_in_file.get(c, false)) and not _resolved(c) and not c.held and not (c.man as Person).inside:
			out.append(c)
	return out


## Where believer `c` holds in his household's file (v0.11 M6, plan decision 282): its lamp's way out once he got out; else his place
## FOLLOW_GAP x (his place) back along the lamp's trail while within FOLLOW_REACH of it; Vector2.INF when he is not in file, is the lamp,
## or is too far.
func _file_spot(c: Charge) -> Vector2:
	if not bool(_in_file.get(c, false)):
		return Vector2.INF
	var i := int(_home.get(c, -1))
	if i < 0:
		return Vector2.INF
	var h: Household = households[i]
	if h.out_to != Vector2.INF:
		return h.out_to
	var lead := lamp(i)
	if lead == null or lead == c:
		return Vector2.INF
	var lp := (lead.man as Person).ground_pos
	if (c.man as Person).ground_pos.distance_to(lp) > FOLLOW_REACH:
		return Vector2.INF
	var place := followers(i).find(c)
	return _trail_point(h, lp, FOLLOW_GAP * float(maxi(place, 0) + 1))


## The point `back` along household `h`'s trail behind `from` (v0.11 M6), on walkable ground; the trail's oldest point if it is shorter.
func _trail_point(h: Household, from: Vector2, back: float) -> Vector2:
	var at := from
	var left := back
	for k in range(h.trail.size() - 1, -1, -1):
		var nxt: Vector2 = h.trail[k]
		var seg := at.distance_to(nxt)
		if seg >= left:
			return _walkable(at.move_toward(nxt, left))
		left -= seg
		at = nxt
	return _walkable(at)


## Household `i` comes out (v0.11 M6): its four on a ring round the door, on duty, in file; its searchers on the strip HUNT_AFTER on.
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
	timeline.add(timeline.elapsed() + HUNT_AFTER / timeline.stretch_factor(), "hunt_%d" % i, "The Temple sends searchers", _send.bind(i),
		func() -> bool: return not (households[i] as Household).done)


## Household `i`'s searchers leave the Temple's door for its lamp (v0.11 M6).
func _send(i: int) -> void:
	var h: Household = households[i]
	if h.sent or h.done:
		return
	h.sent = true
	for v: Variant in h.searchers:
		if _alive(v) and (v as Person).inside:
			_bring_out(v as Person, temple_door)
			_keep_from_flight(v as Person, true)
	_step_hunters()


## Gate `g` shuts (v0.11 M6): no way out from now on. A household's file walking on to its way out behind a lamp already out turns for
## the next open gate's (the controller's ruling: never a silent loss); with every gate shut it follows its lamp again.
func _shut(g: int) -> void:
	var gate: Gate = gates[g]
	gate.shut = true
	for h: Household in households:
		if h.out_to != Vector2.INF and h.out_to.distance_to(gate.way_out) <= ESCAPE_REACH:
			h.out_to = _open_exit_near(h.out_to)


## Someone died (v0.11 M6, the controller's ruling): the Gaze judges whether it was seen (GazeMeter.judge_deaths(), in step()).
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)


## The second household `i` comes out at the latest (v0.11 M6): its own time, or CHAIN after the one before is done if that is sooner.
func out_due(i: int) -> float:
	var at := float(OUT_AT[i]) * timeline.stretch_factor()
	if i > 0 and (households[i - 1] as Household).done:
		at = minf(at, (households[i - 1] as Household).done_at + CHAIN)
	return at


## Seconds until household `i` comes out at the latest (v0.11 M6); 0 once it has.
func due_in(i: int) -> float:
	return 0.0 if (households[i] as Household).out else maxf(out_due(i) - _clock, 0.0)


## The current household: the first out and not done, or -1 (v0.11 M6).
func current() -> int:
	for i in households.size():
		var h: Household = households[i]
		if h.out and not h.done:
			return i
	return -1


## The next household still inside, or -1 (v0.11 M6).
func upcoming() -> int:
	for i in households.size():
		if not (households[i] as Household).out:
			return i
	return -1


## Gate `g` is watched (v0.11 M6): one of its watchmen would see a believer at its mouth. Only reads.
func gate_watched(g: int) -> bool:
	for k in watch.size():
		if k / GATE_WATCH == g and _watching(watch[k]) and (watch[k] as Person).ground_pos.distance_to((gates[g] as Gate).mouth) <= SIGHT + 1.0:
			return true
	return false


## Household `i`'s searchers out of doors and watching (v0.11 M6). Only reads.
func searchers_out(i: int) -> Array[Person]:
	var out: Array[Person] = []
	var h: Household = households[i]
	if not h.sent or h.done:
		return out
	for v: Variant in h.searchers:
		if _watching(v):
			out.append(v as Person)
	return out


## Household `i`'s road from its door to the nearest open gate's way out (v0.11 M6, for the scripted player): the walk grid's path,
## cached per gate; door, mouth and way out with no grid.
func road(i: int) -> Array:
	var h: Household = households[i]
	var exit := _open_exit_near(h.door)
	if exit == Vector2.INF:
		return [h.door]
	var key := "%d:%s" % [i, exit]
	if not _roads.has(key):
		var line: Array = [h.door]
		var path := crowd._grid.path(h.door, exit) if crowd._grid != null else PackedVector2Array()
		if path.is_empty():
			for g: Gate in gates:
				if g.way_out == exit:
					line.append(g.mouth)
		else:
			line.append_array(Array(path))
		line.append(exit)
		_roads[key] = line
	return _roads[key]


## One step (v0.11 M6): the Escort type's (each believer, the watch's posts, the patrols, the searchers), the Gaze's deaths, the
## households' chain, then every TICK a look of its own: everyone held kept from the flight, the households and their files, the gate
## reliefs, the houses' fires.
func step(delta: float) -> void:
	super(delta)
	gaze.judge_deaths(crowd)
	_chain()
	_keep_in -= delta
	if _keep_in > 0.0:
		return
	_keep_in = TICK
	var evacuating := _evacuation_began()
	if evacuating:
		_recall_until = _clock + 2.0 * TICK
	_keep_held(evacuating)
	_households()
	_relieve_watch()
	_quench()


## Each household still inside whose chained time has come comes out (v0.11 M6); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, households.size()):
		var h: Household = households[i]
		if not h.out and (households[i - 1] as Household).done and _clock >= out_due(i):
			rules.banner.emit(("The %s comes out" % h.words.trim_prefix("the ")).to_upper())
			_come_out(i)


## Everyone held is kept from the town's flight by the one rule (v0.11 M6, plan decision 288): every watcher and searcher, and every
## believer still in the town; the base and _takes_post() then put each on duty again.
func _keep_held(evacuating: bool) -> void:
	var people: Array = _watchers()
	for h: Household in households:
		for v: Variant in h.searchers:
			if not people.has(v):
				people.append(v)
	for c in charges:
		if not _resolved(c):
			people.append(c.man)
	_hold_all(people, evacuating)


## Each household out (v0.11 M6): done once each of its four is out, taken or dead -- its searchers home, the next one's chained time on
## the strip; else its lamp's trail grows, a follower whispered on his own leaves the file and one within REJOIN of the lamp rejoins it.
func _households() -> void:
	for i in households.size():
		var h: Household = households[i]
		if not h.out or h.done:
			continue
		var all := true
		for c: Charge in h.members:
			all = all and _resolved(c)
		if all:
			h.done = true
			h.done_at = _clock
			for v: Variant in h.searchers:
				if _alive(v) and not (v as Person).inside and (v as Person).mind == Person.Mind.DUTY and not _seizing(v):
					crowd.off_duty(v as Person)
			if i + 1 < households.size():
				timeline.expect("out_%d" % (i + 1), out_due(i + 1))
			continue
		var lead := lamp(i)
		if lead != null:
			var at := (lead.man as Person).ground_pos
			if h.trail.is_empty() or h.trail.back().distance_to(at) >= FOLLOW_GAP * 0.5:
				h.trail.append(at)
				if h.trail.size() > TRAIL_MAX:
					h.trail.remove_at(0)
		for c: Charge in h.members:
			if _resolved(c) or c.held or c == lead or (c.man as Person).inside:
				continue
			var p := c.man as Person
			if p.mind == Person.Mind.WHISPERED:
				_in_file[c] = false
			elif not bool(_in_file.get(c, false)) and lead != null and p.ground_pos.distance_to((lead.man as Person).ground_pos) <= REJOIN:
				_in_file[c] = true


## Each household's searchers sent and not done keep walking to its lamp, a step apart (v0.11 M6, in place of the Escort type's single
## charge's): one back on his feet goes after it again; a seizer, one held by the god or frightened is left be.
func _step_hunters() -> void:
	for i in households.size():
		var h: Household = households[i]
		if not h.sent or h.done:
			continue
		var lead := lamp(i)
		if lead == null:
			continue
		var to := (lead.man as Person).ground_pos
		for k in h.searchers.size():
			var v: Variant = h.searchers[k]
			if not _alive(v) or _seizing(v) or (v as Person).inside:
				continue
			var p := v as Person
			var spot := to + Vector2(0.5 * (-1.0 if k % 2 == 0 else 1.0), 0.0)
			if p.mind == Person.Mind.DUTY or p.mind in RECALL_MINDS:
				if p.mind != Person.Mind.DUTY or p.anchor.distance_to(spot) > 1.0:
					p.go_duty(spot)


## A fallen gate watchman is replaced RELIEF_AFTER after he fell by one from the Temple's door, at most RELIEFS in a night; with none who
## can reach the post the search backs off RELIEF_AFTER (v0.11 M6, plan decision 286).
func _relieve_watch() -> void:
	for i in watch.size():
		var v: Variant = watch[i]
		if _alive(v):
			_fallen_since[i] = -1.0
			continue
		if _fallen_since[i] < 0.0:
			_fallen_since[i] = _clock
			continue
		if _clock - _fallen_since[i] < RELIEF_AFTER or reliefs >= RELIEFS:
			continue
		var post := _walkable(watch_posts[i])
		var p := _relief_from_temple(post)
		if p == null:
			_fallen_since[i] = _clock
			continue
		_watchman(p)
		if crowd._fled_all:
			_keep_from_flight(p, true)  # chosen once the town is running: never one of the flight
		watch[i] = p
		p.go_duty(post)
		reliefs += 1
		_fallen_since[i] = -1.0
		rules.banner.emit("A NEW WATCHMAN COMES FROM THE TEMPLE")


## The lay citizen nearest the Temple's door with a way on foot to `post`, of the REACH_PICKS nearest, none at the night's work; null for
## none (v0.11 M6).
func _relief_from_temple(post: Vector2) -> Person:
	for p in _lay_near(temple_door, REACH_PICKS, _in_use(charge)):
		if crowd._grid == null or not crowd._grid.path(p.ground_pos, post).is_empty():
			return p
	return null


## Structure.damage_filter for a household's house tonight (v0.11 M6): stone, a blow only shakes it.
func _stone(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(HuntDirector.SHAKE)


## Any fire on a household's house is put out (v0.11 M6): no stray power empties a household.
func _quench() -> void:
	if crowd.fires == null:
		return
	for h: Household in households:
		if is_instance_valid(h.house) and crowd.fires.is_burning(h.house):
			crowd.fires._put_out(h.house, true)


## Why the night is lost now (v0.11 M6, Decisions 223 and 228): "exodus_few" once the believers out and those left fall below NEED;
## "gates_shut" once every gate is shut with fewer than NEED out; else "".
func lost_reason() -> String:
	if out_count() + left_count() < NEED:
		return "exodus_few"
	var all_shut := not gates.is_empty()
	for g: Gate in gates:
		all_shut = all_shut and g.shut
	if all_shut and out_count() < NEED:
		return "gates_shut"
	return ""


## "Lead them out 3 / 10, 2 to spare" (v0.11 M6).
func hud_line() -> String:
	return "Lead them out %d / %d, %d to spare" % [out_count(), NEED, maxi(out_count() + left_count() - NEED, 0)]


## The banners (v0.11 M6).
func _opening_banner() -> String:
	return "EXODUS"


func _caught_banner() -> String:
	return "A BELIEVER IS TAKEN"


func _freed_banner() -> String:
	return "THE BELIEVER IS FREE"


func _taken_banner() -> String:
	return "THE INQUISITION TAKES A BELIEVER"


func _escape_banner() -> String:
	return "A BELIEVER GETS OUT"


## The map tags, most important first (v0.11 M6, mission spec §2): each believer seized, TAKEN TO THE TEMPLE, his seizer TAKING HIM IN and
## the Temple's door, red, pointed at; each lamp, LAMP - DO NOT KILL, steel blue, pointed at, and a steel-blue diamond on each other
## believer out; each household still inside, HOUSEHOLD - OUT BY its sooner time, grey, pointed at; each gate, watched, clear, shutting or
## shut, pointed at; SEARCHER on each searcher out, pointed at; PATROL on each patrol's first watchman and a red diamond on the rest and
## on each gate's watch.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if lost_reason() != "" or out_count() >= NEED:
		return out
	var marched := false
	for c in charges:
		if not c.held or _resolved(c):
			continue
		out.append(MapTag.person((c.man as Person).ground_pos, MARK_WATCHED, "TAKEN TO THE TEMPLE", true))
		if _alive(c.seizer):
			out.append(MapTag.person((c.seizer as Person).ground_pos, MARK_WATCHED, "TAKING HIM IN", true))
		marched = true
	for i in households.size():
		var h: Household = households[i]
		if not h.out:
			out.append(MapTag.place(h.door, MARK_NOT_YET, "HOUSEHOLD - OUT BY %s" % UiTheme.clock(out_due(i)), h.house.height, true))
			continue
		var lead := lamp(i)
		for c: Charge in h.members:
			if _resolved(c) or c.held or (c.man as Person).inside:
				continue
			var p := c.man as Person
			out.append(MapTag.person(p.ground_pos, MARK_CHARGE, "LAMP - DO NOT KILL" if c == lead else "", c == lead))
	if marched:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE", 0.0, true))
	for g in gates.size():
		var gate: Gate = gates[g]
		var shut_at := gate.shut_at * timeline.stretch_factor()
		if gate.shut:
			out.append(MapTag.place(gate.mouth, MARK_NOT_YET, "%s - SHUT" % gate.label, 0.0, true))
		elif shut_at - _clock <= SHUT_WARN:
			out.append(MapTag.place(gate.mouth, MARK_PLACE, "%s - SHUT AT %s" % [gate.label, UiTheme.clock(shut_at)], 0.0, true))
		elif gate_watched(g):
			out.append(MapTag.place(gate.mouth, MARK_WATCHED, "%s - WATCHED" % gate.label, 0.0, true))
		else:
			out.append(MapTag.place(gate.mouth, MARK_CLEAR, "%s - CLEAR" % gate.label, 0.0, true))
	for h: Household in households:
		if not h.sent or h.done:
			continue
		for v: Variant in h.searchers:
			if _alive(v) and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "SEARCHER", true))
	for squad: Array in patrols:
		var named := false
		for v: Variant in squad:
			if _alive(v) and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "" if named else "PATROL"))
				named = true
	for v: Variant in watch:
		if _alive(v) and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M6, plan decision 303): "caught" while a believer is marched; for the current household, "hounds" while its
## searchers are within HOUNDS_NEAR of one of its own, "shut" once the gate it is heading for (heading()) is shut, "gate" while its lamp
## nears that gate, watched; "waiting" between households (not before the first); else "".
func hint_phase() -> String:
	if lost_reason() != "" or out_count() >= NEED:
		return ""
	for c in charges:
		if c.held and not _resolved(c):
			return "caught"
	var cur := current()
	if cur < 0:
		return "waiting" if upcoming() > 0 else ""
	var h: Household = households[cur]
	for p in searchers_out(cur):
		for c: Charge in h.members:
			if not _resolved(c) and not (c.man as Person).inside and (c.man as Person).ground_pos.distance_to(p.ground_pos) <= HOUNDS_NEAR:
				return "hounds"
	var g := heading(cur)
	if g < 0:
		return ""
	if (gates[g] as Gate).shut:
		return "shut"
	var lead := lamp(cur)
	if lead != null and (lead.man as Person).ground_pos.distance_to((gates[g] as Gate).mouth) <= NEAR_GATE and gate_watched(g):
		return "gate"
	return ""


## The gate household `i` is heading for (v0.11 M6, fix round 1): the one its file walks on to behind a lamp already out (out_to);
## else the gate whose mouth is nearest where its lamp is whispered to, or, standing, where he stands -- shut or open, so the hint can
## say a household makes for a shut gate; -1 with no lamp. Only reads.
func heading(i: int) -> int:
	var h: Household = households[i]
	if h.out_to != Vector2.INF:
		for g in gates.size():
			if (gates[g] as Gate).way_out.distance_to(h.out_to) <= ESCAPE_REACH:
				return g
	var lead := lamp(i)
	if lead == null:
		return -1
	var p := lead.man as Person
	var to := p.goal() if p.mind == Person.Mind.WHISPERED and p.goal() != Vector2.INF else p.ground_pos
	var best := -1
	for g in gates.size():
		if best < 0 or (gates[g] as Gate).mouth.distance_to(to) < (gates[best] as Gate).mouth.distance_to(to):
			best = g
	return best


## The seconds the hint counts down (v0.11 M6): in "waiting", until the next household comes out at the latest; else 0.
func hint_seconds() -> float:
	return due_in(upcoming()) if hint_phase() == "waiting" else 0.0


## The tour (v0.11 M6, mission spec §2): the west household's door, the postern, the Temple's door; fix round 1: each line fits the
## caption's one-line plate, and the gates' line says plainly that the last shutting loses the night unless ten are out.
func tour() -> Array:
	var out := []
	if not households.is_empty():
		out.append([(households[0] as Household).door, "The west household hides here. At %s, whisper its lamp to the postern; the rest follow." % UiTheme.clock(float(OUT_AT[0]))])
	if not gates.is_empty():
		out.append([(gates[0] as Gate).mouth, "Gates shut: postern %s, Side Gate %s, Main Gate %s (lost unless ten are out)." % [
			UiTheme.clock(float(SHUT_AT[0])), UiTheme.clock(float(SHUT_AT[1])), UiTheme.clock(float(SHUT_AT[2]))]])
	out.append([temple_door, "The Temple. Inquisitors take any believer they catch here. Ten must get out."])
	return out


## What the results show (v0.11 M6): the believers out and taken, the seizures, the reliefs, the Gaze.
func report() -> Dictionary:
	var taken_n := 0
	for c in charges:
		taken_n += 1 if c.taken else 0
	return {"out": out_count(), "taken": taken_n, "seizures": seizures, "reliefs": reliefs, "gaze": gaze.value}


## The field's deaths let go, each house's own filter back, then the Escort type's (v0.11 M6).
func teardown() -> void:
	_unhook_kills(_on_killed)
	for i in mini(households.size(), _own_filters.size()):
		var h: Household = households[i]
		if is_instance_valid(h.house):
			h.house.damage_filter = _own_filters[i]
	super()
