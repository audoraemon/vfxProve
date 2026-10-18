class_name BishopDirector
extends AssassinateDirector
## The Bishop (v0.11 M5, Tier 4, mission spec §1; Assassinate, reused): the bishop hides behind his Lantern Knights. He waits in the
## Citadel, untouchable, and at ARRIVE_AT goes to ground in his house by the cellars. Between refuges he moves indoors, unseen; he
## never walks a street until the Temple drives him out. His refuges, in order: his house (the dwelling nearest REFUGE_SPOTS[0]), the
## chapter house (nearest REFUGE_SPOTS[1]) and the Temple. A refuge he is not yet in is stone tonight: a blow only shakes it and any
## fire on it is smothered. STANDING Knights hold each refuge's door from the start, POST_GAP apart along its open face; his escort of
## ESCORT comes with him and comes out at its own posts POST_GAP beyond them, every post more than two Doom radii from the
## next -- the last refuge's survivors, topped up from the Citadel through the
## cellars. A Knight on guard (alive, out of doors, within GUARD_REACH of the refuge) beats out a fire on it once it has burned
## SMOTHER_AFTER. The refuge he is in burning DRIVE_OUT seconds in all with none on guard (the Temple DRIVE_OUT_TEMPLE), or falling,
## drives him out: he reaches the next CHAIN later, unseen, his escort's survivors with him. A standing Knight who falls is replaced
## RELIEF_AFTER later by one walking from the Citadel's gate while the bishop has not passed his refuge (RELIEFS at most); a refuge
## he has left sends its Knights home. Driven from the Temple he comes out at its door ringed by its living Knights (two more if
## fewer than two live) at RING_R and walks on duty at BISHOP_PACE for the Citadel's gate; a loud power near him, a fallen Knight or
## a fright sends him running (the base's alarm, with no hideout). Reaching the gate, or leaving the town, loses; so does TAKEN_AT
## (EventObjective). His death wins, seen or not (a seen one calls the bellkeeper). The Knights are soldiers the director adds
## (Crowd.add_soldier(), corps KNIGHT): a whisper, Discord or a lure takes a Knight off his post and he walks back (v0.11.1), a town's fright does not move one, and the rally, the
## marshals and the investigations never take a Knight (plan decisions 171-176).

## One Knight's post (v0.11 M5): a plain record, so the director holds no cycle.
class Post:
	extends RefCounted
	## The Knight, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## The refuge he holds (an index into `refuges`) and his place at its door.
	var refuge := 0
	var spot := Vector2.INF
	## He is of the bishop's escort (inside with him between refuges), not a standing Knight.
	var escort := false
	## Seconds since he fell; he is a relief walking in until he first stands guard; his post is given up (his refuge passed, or
	## he rings the bishop in the square).
	var fallen := 0.0
	var relief := false
	var done := false


## Where the bishop's house and the chapter house are (v0.11 M5, Decision 127): the dwellings nearest these points; and the Citadel's
## gate, where he waits and where he runs once drawn into the square. The chapter house is the spec's next nearest dwelling to
## (6.5, -13.0) (the quiet-places rule): the nearest's only door opens on a one-cell gap in a lane walled both sides, where its two
## Knights stood 1.0 apart, inside one Doom.
const REFUGE_SPOTS := [Vector2(12.0, -6.8), Vector2(7.9, -12.3)]
const CITADEL_GATE := Vector2(-10.5, -7.6)
## The refuges in words, for the banners and the strip (v0.11 M5).
const REFUGE_WORDS := ["his house", "the chapter house", "the Temple"]
## Mission spec §1's numbers (v0.11 M5), tuned by Step 7's gate in this order: CHAIN (30-45; at 45 already), ARRIVE_AT (30-60) 45 -> 60,
## ESCORT (1-3) 2 -> 3, DRIVE_OUT (6-12) 8 -> 12 with the Temple's 10 -> 14; then (the controller's fix round 1 ruling: the escort
## comes out spread, and a longer first wait is waiting) ARRIVE_AT back to 45 (the scripted clear 212 s median); RELIEF_AFTER
## (20-30) untouched. His first refuge; his flight; the Knights; their spacing and reach; the fire's rules; the reliefs;
## the square; the Knights' deadline.
const ARRIVE_AT := 45.0
const CHAIN := 45.0
const STANDING := 2
const ESCORT := 3
const POST_GAP := 1.8
const GUARD_REACH := 2.5
const SMOTHER_AFTER := 3.0
const DRIVE_OUT := 12.0
const DRIVE_OUT_TEMPLE := 14.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const RING_R := 1.4
const BISHOP_PACE := 0.5
const TAKEN_AT := 300.0
## Where the camera rests (v0.11 M5, Decision 159 moved by the controller's ruling to keep the real HUD stack clear): his house at the
## right, the chapter house at the top, the Temple's door and the first half of his walk across the square clear of the stack; the
## Citadel's gate's arrow at the top-left corner is left to M6's tag keep-out.
const CAMERA_AT := Vector2(2.0, -3.0)
## How hard a blow shakes a refuge he is not yet in; how far a Knight's place must move before he is sent again (v0.11 M5).
const STONE_SHAKE := 2.0
const MOVE := 0.3
## The tags' grey for what is not yet (v0.11 M5).
const MARK_GREY := Color("9a948a")

## The refuges in order and each one's door (v0.11 M5; the quarry's stops and their doors).
var refuges: Array[Structure] = []
var doors: Array[Vector2] = []
## Every Knight's Post, standing and escort (v0.11 M5).
var posts: Array = []
## The refuge he is in, or making for in a flight (-1 while he waits in the Citadel); he is on his way; the second he arrives; how
## many refuges he has been driven from; he is in the square; how many reliefs came (v0.11 M5).
var at_refuge := -1
var in_flight := false
var arrive_at := -1.0
var driven := 0
var in_square := false
var reliefs := 0
## Each refuge's seconds alight with none on guard, in all, and its fire's seconds with one on guard (v0.11 M5).
var _burned: Array[float] = []
var _alight: Array[float] = []
## Structure -> the damage filter it had before, while it is stone (v0.11 M5; restored when it is a building again).
var _stoned := {}
## His own pace, before BISHOP_PACE; the Knights walking home (v0.11 M5).
var _own_pace := 1.0
var _homeward: Array = []
## The refuge whose Knights hold it against blows now (v0.11.1).
var _guard_sealed: Structure
## The refuge's own damage filter before the Knights' seal went on, put back when it comes off (final review M9).
var _guard_before := Callable()


## The places and numbers (v0.11 M5): no hideout (no smoke-out, the Citadel's gate as the safe place), the guards' ring RING_R, and
## the bishop's three refuges as his stops; ESCORT guards (his escort, _appoint_guards()).
func _plan() -> void:
	hideout = null
	safe_at = CITADEL_GATE
	smoke_out = false
	guard_r = RING_R
	safe_label = "CITADEL"
	var from := _walkable(CITADEL_GATE)
	var stops: Array[Structure] = []
	for spot: Vector2 in REFUGE_SPOTS:
		var h := _house_reached(spot, from, stops)
		if h != null:
			stops.append(h)
	var temple := _temple()
	if temple != null:
		stops.append(temple)
	_add_quarry("BISHOP", ARRIVE_AT, stops, ESCORT)


## The town's Temple, by its role (v0.11 M5); null for none.
func _temple() -> Structure:
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple" and not s.destroyed:
			return s
	return null


## The night's setup (v0.11 M5): the Assassinate type's (the bishop appointed and set down at the Citadel's gate, his escort added and
## inside), then the refuges stone and kept from the town's engineers, two Knights at each door, the bishop inside on duty, and the
## Knights' deadline on the strip.
func _begin() -> void:
	super()
	var q := quarries[0]
	refuges = q.stops
	doors = q.stop_doors
	for i in refuges.size():
		_burned.append(0.0)
		_alight.append(0.0)
		_stone(refuges[i])
		var mates: Array[Vector2] = []
		for k in STANDING:
			var p := Post.new()
			p.refuge = i
			p.spot = _post(i, k, false, mates)
			mates.append(p.spot)
			p.man = _knight(p.spot)
			posts.append(p)
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(refuges)
	if _alive(q.target):
		_own_pace = q.target.pace
		q.target.go_duty(q.target.ground_pos)
		_take_inside(q.target, null)
	timeline.add(TAKEN_AT, "taken", "The Knights take him away", Callable(), func() -> bool: return not all_fallen() and not any_safe())


## The bishop is the cleric nearest the Citadel's gate (v0.11 M5).
func _appoint_target(_q: Quarry) -> Person:
	return _citizen_near(hide_door, CitizenProfile.Role.CLERGY, _appointed())


## His escort (v0.11 M5, Task 1's hook): q.guard_count Knights added at the Citadel's gate and taken inside with him.
func _appoint_guards(q: Quarry, _taken: Array) -> Array[Person]:
	var out: Array[Person] = []
	for k in q.guard_count:
		var p := Post.new()
		p.escort = true
		p.man = _knight(hide_door)
		_take_inside(p.man as Person, null)
		posts.append(p)
		out.append(p.man as Person)
	return out


## The base sends and sends home only his Knights at their posts (v0.11 M5, Task 1's hook).
func _tends(p: Person) -> bool:
	return p.corps == Person.Corps.KNIGHT and p.mind == Person.Mind.POST


## The `k`th Knight's post at refuge `i` (v0.11 M5): along its door's face, the standing pair POST_GAP apart about the door, the escort
## POST_GAP beyond them, a third of the escort POST_GAP straight out from the door; each kept more than two Silent Doom radii from
## the posts already set (`mates`) by _spread() (the controller's fix round 1 ruling, The Crown's Bread's: one strike never clears a
## refuge).
func _post(i: int, k: int, escort: bool, mates: Array[Vector2]) -> Vector2:
	var face := doors[i]
	var out := face - refuges[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	var want := face + along * side * POST_GAP * (1.5 if escort else 0.5)
	if escort and k >= 2:
		want = face + out * POST_GAP
	return _spread(i, want, mates)


## A post at or near `want` for refuge `i` (v0.11 M5, The Crown's Bread's _spread()): walkable, within GUARD_REACH of the refuge,
## reached on foot from its door (a Knight sent back or a relief must get there), and farther than two Silent Doom radii from every
## post in `mates`. The nearest such point on rings of POST_GAP / 2 steps round `want`; `want` made walkable when there is none.
func _spread(i: int, want: Vector2, mates: Array[Vector2]) -> Vector2:
	var first := _walkable(want)
	for ring in 5:
		var r := POST_GAP * 0.5 * float(ring)
		var n := 1 if ring == 0 else 12
		for k in n:
			var at := first if ring == 0 else _walkable(want + Vector2.from_angle(TAU * float(k) / float(n)) * r)
			if refuges[i].distance_to(at) > GUARD_REACH or (crowd._grid != null and (not crowd._grid.walkable(at)
					or (at.distance_to(doors[i]) > 0.1 and crowd._grid.path(doors[i], at).is_empty()))):
				continue
			var clear := true
			for m in mates:
				clear = clear and m.distance_to(at) > 2.0 * SilentDoom.RADIUS
			if clear:
				return at
	return first


## `s` is stone tonight (v0.11 M5, Decision 128): a blow only shakes it, and its fire is smothered (_smother_stone()).
func _stone(s: Structure) -> void:
	_stoned[s] = s.damage_filter
	s.damage_filter = _stone_hit


## `s` is a building again (v0.11 M5): the bishop is in it; any filter it had before is restored.
func _unstone(s: Structure) -> void:
	var before: Callable = _stoned.get(s, Callable())
	_stoned.erase(s)
	if is_instance_valid(s):
		s.damage_filter = before


## Structure.damage_filter for a stone refuge (v0.11 M5): the blow only shakes it.
func _stone_hit(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(STONE_SHAKE)


## The refuge he is in is held by its Knights (v0.11.1, R6; mission spec §7.2 row 17: "Heaven fells the refuge; whisper, Discord and the
## Wisp clear the Knights"): while one stands guard at it, a blow only shakes it, as it does a refuge he is not yet in; fire is not a blow
## (the Knights beat that out themselves). With none on guard it takes blows as any building does. Checked every step.
func _seal_guarded() -> void:
	var cur := current_refuge()
	var s: Structure = refuges[cur] if cur >= 0 else null
	var want := s != null and is_instance_valid(s) and not s.destroyed and not guards_at(cur).is_empty()
	if _guard_sealed != null and (not want or _guard_sealed != s):
		if is_instance_valid(_guard_sealed):
			_guard_sealed.damage_filter = _guard_before
		_guard_sealed = null
		_guard_before = Callable()
	if want and _guard_sealed == null:
		_guard_before = s.damage_filter
		s.damage_filter = _guard_hit
		_guard_sealed = s


## Structure.damage_filter for a refuge its Knights hold (v0.11.1): a blow only shakes it; fire burns it as ever.
func _guard_hit(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	if kind == &"fire":
		s.damage_filter = _guard_before
		s.damage(amount, source, kind)
		if is_instance_valid(s) and not s.destroyed:
			s.damage_filter = _guard_hit
		return
	s.shake(STONE_SHAKE)


## Every stone refuge's fire is put out (v0.11 M5).
func _smother_stone() -> void:
	for s: Variant in _stoned.keys():
		if is_instance_valid(s) and _burning(s as Structure):
			crowd.fires._put_out(s as Structure, true)


## The night's opening banner (v0.11 M5).
func _opening_banner() -> String:
	return "THE BISHOP"


## The strip's words for his first refuge (v0.11 M5).
func _set_out_label(_q: Quarry) -> String:
	return "The bishop goes to ground"


## The banner when he runs (v0.11 M5).
func _hide_banner(_q: Quarry) -> String:
	return "THE BISHOP RUNS FOR THE CITADEL"


## The banner when he reaches the gate, or leaves the town (v0.11 M5).
func _safe_banner() -> String:
	return "THE BISHOP REACHES THE CITADEL"


## The banner when his death is seen (v0.11 M5).
func _seen_banner() -> String:
	return "THE KNIGHTS CRY MURDER"


## His time (v0.11 M5, the timeline's "out_0"): he goes to ground in his house, unseen.
func _set_out(q: Quarry) -> void:
	if q.state != State.WAITING or not _alive(q.target) or at_refuge >= 0 or refuges.is_empty():
		return
	_reach_refuge(0)


## He reaches refuge `i` (v0.11 M5): indoors in it, unseen; it is a building again; his escort's survivors, topped up to ESCORT from
## the Citadel through the cellars, come out each at his own post, spread round it (the controller's fix round 1 ruling).
func _reach_refuge(i: int) -> void:
	var q := quarries[0]
	if q.dead or in_square or not _alive(q.target):
		return
	at_refuge = i
	in_flight = false
	arrive_at = -1.0
	q.inside_of = refuges[i]
	q.target.ground_pos = refuges[i].center()
	_unstone(refuges[i])
	var living: Array[Person] = []
	for p: Post in posts:
		if p.escort and not p.done:
			if _alive(p.man):
				living.append(p.man as Person)
			else:
				p.done = true
	while living.size() < ESCORT:
		var np := Post.new()
		np.escort = true
		np.man = _knight(refuges[i].center())
		_take_inside(np.man as Person, null)
		posts.append(np)
		living.append(np.man as Person)
	var mates: Array[Vector2] = []
	for p: Post in posts:
		if not p.escort and not p.done and p.refuge == i:
			mates.append(p.spot)
	var k := 0
	for p: Post in posts:
		if not p.escort or p.done:
			continue
		p.refuge = i
		p.spot = _post(i, k, true, mates)
		mates.append(p.spot)
		k += 1
		var man := p.man as Person
		if man.inside:
			_bring_out(man, p.spot)  # at his own post, never bunched at the door (the controller's fix round 1 ruling)
		man.send_to_post(p.spot, false, true)
	q.guards = living
	_guard_total = living.size()


## How long refuge `i` must burn with none on guard to drive him out (v0.11 M5).
func drive_out_after(i: int) -> float:
	return DRIVE_OUT_TEMPLE if refuges[i].role == &"temple" else DRIVE_OUT


## He is driven from refuge `i` (v0.11 M5): from the Temple into the square; else its Knights go home, his escort's survivors go in
## with him, unseen, and he reaches the next CHAIN later (the timeline's event, so the strip counts down to it).
func _drive_out(i: int) -> void:
	var q := quarries[0]
	driven += 1
	if i + 1 >= refuges.size():
		_into_square()
		return
	_send_home(i)
	rules.banner.emit("THE BISHOP FLEES %s" % String(REFUGE_WORDS[i]).to_upper())
	in_flight = true
	at_refuge = i + 1
	arrive_at = _clock + CHAIN
	q.inside_of = null
	q.target.ground_pos = refuges[i + 1].center()
	for p: Post in posts:
		if p.escort and not p.done and _alive(p.man) and not (p.man as Person).inside:
			_take_inside(p.man as Person, null)
	var next := i + 1
	timeline.add(timeline.elapsed() + CHAIN / timeline.stretch_factor(), "arrive_%d" % next,
		"The bishop reaches %s" % REFUGE_WORDS[next], _reach_refuge.bind(next),
		func() -> bool: return in_flight and at_refuge == next)


## Refuge `i`'s standing Knights go home to the Citadel (v0.11 M5): their posts are given up.
func _send_home(i: int) -> void:
	for p: Post in posts:
		if p.escort or p.done or p.refuge != i:
			continue
		p.done = true
		if _alive(p.man):
			(p.man as Person).send_to_post(hide_door)
			_homeward.append(p.man)


## Driven from the Temple (v0.11 M5): he comes out at its door with its living Knights -- two more if fewer than two live -- who ring
## him (the base's guards' ring), and walks on duty for the Citadel's gate at BISHOP_PACE (the base walks him from here).
func _into_square() -> void:
	var q := quarries[0]
	var last := refuges.size() - 1
	var door := doors[last]
	in_square = true
	in_flight = false
	q.inside_of = null
	var ring: Array[Person] = []
	for p: Post in posts:
		if p.done or p.refuge != last:
			continue
		p.done = true
		if not _alive(p.man):
			continue
		var man := p.man as Person
		if man.inside:
			_bring_out(man, door)
		ring.append(man)
	if ring.size() < 2:
		for k in 2:
			ring.append(_knight(door))
	_bring_out(q.target, door)
	_keep_from_flight(q.target, true)
	q.guard_fell = false  # a Knight felled before he came out does not alarm him: only one felled in the square
	q.target.pace = _own_pace * BISHOP_PACE
	q.leg = q.stops.size()
	q.state = State.WALKING
	q.guards = ring
	_guard_total = ring.size()
	q.target.go_duty(safe_at)
	rules.banner.emit("THE BISHOP IS DRAWN INTO THE SQUARE")
	_send_guards()


## Alarmed in the square (v0.11 M5): the base's flight for the gate, at his own pace.
func _alarm(q: Quarry) -> void:
	var was := q.state
	super(q)
	if was == State.WALKING and q.state == State.FLEEING and _alive(q.target):
		q.target.pace = _own_pace
		q.target.go_duty(_hide_goal())


## The base's guards' ring, only in the square (v0.11 M5): before it the Knights keep their own posts (_tend()).
func _send_guards() -> void:
	if in_square:
		super()


## One step (v0.11 M5): at each look first the one rule for his held people (_hold_all()), so the base never takes a flight the
## evacuation gave him for a fright; then the Assassinate type's (the strip, the judge, his walk in the square, which puts one stopped
## on his feet straight back on duty for the gate), the refuge he is in, the Knights, and the stone refuges' fires.
func step(delta: float) -> void:
	var looking := _tick_in - delta <= 0.0  # the base's own look this step (super() counts _tick_in down and resets it)
	if looking:
		_hold_all(_held(), _evacuation_began())
	super(delta)
	var q := quarries[0]
	if not q.dead and q.state == State.WAITING and at_refuge >= 0 and not in_flight and _alive(q.target):
		_refuge_step(at_refuge, delta)
	_tend(delta, looking)
	_smother_stone()
	_seal_guarded()


## The bishop's people for the one hold rule (v0.11 M5, the controller's ruling): the bishop and every Knight at a post or ringing him.
## The Knights are soldiers, whom the town's flight never takes, but they are held by the same rule all the same. Untyped: any may be
## a body freed after its death fade.
func _held() -> Array:
	var out: Array = [quarries[0].target]
	for p: Post in posts:
		if not p.done:
			out.append(p.man)
	out.append_array(quarries[0].guards)
	return out


## The refuge he is in (v0.11 M5): fallen, he is driven out; alight with a Knight on guard, it is beaten out after SMOTHER_AFTER;
## alight with none, its seconds count, and drive_out_after(i) of them drive him out.
func _refuge_step(i: int, delta: float) -> void:
	var s := refuges[i]
	if not is_instance_valid(s) or s.destroyed:
		_drive_out(i)
		return
	if not _burning(s):
		_alight[i] = 0.0
		return
	if not guards_at(i).is_empty():
		_alight[i] += delta
		if _alight[i] >= SMOTHER_AFTER:
			_alight[i] = 0.0
			crowd.fires._put_out(s, true)
		return
	_alight[i] = 0.0
	_burned[i] += delta
	if _burned[i] >= drive_out_after(i):
		_drive_out(i)


## The Knights at their work (v0.11 M5): each out of doors kept at his post (Broken Lanterns' _tend_knights()); a standing one of a
## refuge not yet passed who fell is replaced RELIEF_AFTER later (_relieve()); those going home are taken in at the Citadel's gate.
func _tend(delta: float, looking: bool) -> void:
	for p: Post in posts:
		if p.done or (p.escort and in_flight):
			continue
		if not _alive(p.man):
			if p.escort:
				continue
			p.fallen += delta
			if looking and p.fallen >= RELIEF_AFTER and reliefs < RELIEFS:
				_relieve(p)
			continue
		p.fallen = 0.0
		var man := p.man as Person
		if man.inside:
			continue
		if _on_guard(p):
			p.relief = false
		if looking and man.mind == Person.Mind.POST and man.anchor.distance_to(p.spot) > MOVE:
			man.send_to_post(p.spot, false, true)
	if not looking:
		return
	for v: Variant in _homeward.duplicate():
		if not _alive(v) or (v as Person).inside:
			_homeward.erase(v)
		elif (v as Person).ground_pos.distance_to(hide_door) <= ARRIVE:
			_take_inside(v as Person, null)
			_homeward.erase(v)


## A new Knight for post `p` (v0.11 M5, The Crown's Bread's _relieve() shape): added at the Citadel's gate, walking to the post. One
## added once the town is running is kept from its flight first. With no road from the gate to the post, the relief backs off and is
## tried again RELIEF_AFTER later (the controller's ruling: not at every look).
func _relieve(p: Post) -> void:
	if not _reaches(p.spot):
		p.fallen = 0.0
		return
	var k := _knight(hide_door)
	if crowd._fled_all:
		_keep_from_flight(k, true)  # added once the town is running: never one of the flight
	k.send_to_post(p.spot, false, true)
	p.man = k
	p.fallen = 0.0
	p.relief = true
	reliefs += 1
	rules.banner.emit("A NEW KNIGHT COMES FROM THE CITADEL")


## A Knight walking from the Citadel's gate can reach `at` (v0.11 M5): the town's walk grid has a road there (always, with none).
func _reaches(at: Vector2) -> bool:
	return crowd._grid == null or not crowd._grid.path(hide_door, at).is_empty()


## Post `p`'s Knight is on guard now (v0.11 M5, plan decision 172): alive, out of doors, within GUARD_REACH of his refuge.
func _on_guard(p: Post) -> bool:
	if p.done or not _alive(p.man):
		return false
	var man := p.man as Person
	var s := refuges[p.refuge]
	return not man.inside and not man.held_by_god() and is_instance_valid(s) and s.distance_to(man.ground_pos) <= GUARD_REACH


## The Knights on guard at refuge `i` now (v0.11 M5). Only reads.
func guards_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if p.refuge == i and _on_guard(p):
			out.append(p.man as Person)
	return out


## Refuge `i`'s living Knights out of doors, on guard or not (v0.11 M5, for the policy and the tags). Only reads.
func standing_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if not p.done and p.refuge == i and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## A relief walking in, or null (v0.11 M5, for the scripted player). Only reads.
func relief_walking() -> Person:
	for p: Post in posts:
		if p.relief and not p.done and _alive(p.man) and not (p.man as Person).inside and not _on_guard(p):
			return p.man as Person
	return null


## The refuge he is in now, or -1 (in the Citadel, in a flight, in the square) (v0.11 M5). Only reads.
func current_refuge() -> int:
	return at_refuge if at_refuge >= 0 and not in_flight and not in_square else -1


## The refuge he makes for next, or -1 (v0.11 M5): his house before 0:45, the one he flies to, or the one after his. Only reads.
func next_refuge() -> int:
	if in_square:
		return -1
	if at_refuge < 0:
		return 0
	if in_flight:
		return at_refuge
	return at_refuge + 1 if at_refuge + 1 < refuges.size() else -1


## Seconds until he reaches his next refuge (v0.11 M5): to 0:45 in the Citadel, the flight's end in one; 0 in a refuge or the square.
func arrive_in() -> float:
	if at_refuge < 0 and not in_square:
		return maxf(out_at(0) - _clock, 0.0)
	if in_flight:
		return maxf(arrive_at - _clock, 0.0)
	return 0.0


## The HUD's line (v0.11 M5): "Kill the bishop: refuges 1 / 3"; in the square, "Kill the bishop, he makes for the Citadel".
func hud_line() -> String:
	if in_square:
		return "Kill the bishop, he makes for the Citadel"
	return "Kill the bishop: refuges %d / %d" % [driven, refuges.size()]


## The map tags, most important first (v0.11 M5, mission spec §1): before 0:45 BISHOP - IN THE CITADEL (grey, an edge tag: the Citadel
## lies under the HUD's corner, and M6's keepout keeps an edge tag's words -- the final review); the refuge he is in, gold, guarded,
## open or burning; the next refuge, grey, with his arrival's time while he is on his way; KNIGHT on each Knight on guard at those two,
## a red diamond on a relief, a small red mark on one away. In the square: BISHOP (RUNNING once alarmed), CITADEL, and a red diamond on
## each who would see a Doom on him. None once he is dead or gone.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	var q := quarries[0]
	if q.dead or q.state == State.SAFE or not _alive(q.target):
		return out
	if in_square:
		var running := q.state == State.FLEEING
		out.append(MapTag.person(q.target.ground_pos, MARK_TARGET, "BISHOP - RUNNING" if running else "BISHOP", true))
		out.append(MapTag.place(safe_at, MARK_WATCHED, safe_label, 0.0, true))
		for p in witnesses(q):
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
		return out
	if at_refuge < 0:
		out.append(MapTag.place(hide_door, MARK_GREY, "BISHOP - IN THE CITADEL", 0.0, true))
	var cur := current_refuge()
	if cur >= 0:
		var s := refuges[cur]
		var label := "REFUGE - SET IT ALIGHT"
		if not guards_at(cur).is_empty():
			label = "REFUGE - GUARDED"
		elif _burning(s):
			label = "REFUGE - BURNING %d" % ceili(maxf(drive_out_after(cur) - _burned[cur], 0.0))
		out.append(MapTag.place(s.center(), MARK_TARGET, label, s.height, true))
	var nxt := next_refuge()
	if nxt >= 0 and nxt != cur:
		var n := refuges[nxt]
		var words := "NEXT REFUGE - HE COMES IN %s" % UiTheme.clock(arrive_in()) if cur < 0 else "NEXT REFUGE"
		out.append(MapTag.place(n.center(), MARK_GREY, words, n.height, true))
	for i: int in [cur, nxt]:
		if i < 0:
			continue
		for p: Post in posts:
			if p.done or p.refuge != i or not _alive(p.man) or (p.man as Person).inside:
				continue
			var man := p.man as Person
			if _on_guard(p):
				out.append(MapTag.person(man.ground_pos, MARK_WATCHED, "KNIGHT"))
			elif p.relief:
				out.append(MapTag.person(man.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(man.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5, plan decision 205): "square" / "running" in the square; "waiting" in the Citadel or a flight;
## "guarded", "burning" or "open" in a refuge; "" once he is dead or gone.
func hint_phase() -> String:
	var q := quarries[0]
	if q.dead or q.state == State.SAFE or not _alive(q.target):
		return ""
	if in_square:
		return "running" if q.state == State.FLEEING else "square"
	var cur := current_refuge()
	if cur < 0:
		return "waiting"
	if not guards_at(cur).is_empty():
		return "guarded"
	return "burning" if _burning(refuges[cur]) else "open"


## The seconds the hint counts down (v0.11 M5, MissionHints.SECONDS): to his next refuge while he waits or is on his way; else 0.
func hint_seconds() -> float:
	return arrive_in() if hint_phase() == "waiting" else 0.0


## The tour (v0.11 M5, mission spec §1): his house, the chapter house, the Temple.
func tour() -> Array:
	var words := ["His house. The bishop goes to ground here at %s, his Knights at the door." % UiTheme.clock(ARRIVE_AT),
		"The chapter house, his next refuge. Burn each one to drive him on.",
		"The Temple, his last refuge. Set it alight to draw him into the square."]
	var out := []
	for i in refuges.size():
		out.append([doors[i], String(words[2 if refuges[i].role == &"temple" else mini(i, 1)])])
	return out


## What the results show (v0.11 M5): the Assassinate type's, the refuges he was driven from and the reliefs.
func report() -> Dictionary:
	var r := super()
	r["refuges"] = driven
	r["reliefs"] = reliefs
	return r


## Lets go of the stone and the engineers' list, then the Assassinate type's (v0.11 M5).
func teardown() -> void:
	if is_instance_valid(_guard_sealed):
		_guard_sealed.damage_filter = _guard_before
	_guard_sealed = null
	_guard_before = Callable()
	for s: Variant in _stoned.keys():
		if is_instance_valid(s):
			(s as Structure).damage_filter = _stoned[s]
	_stoned.clear()
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s: Variant in refuges:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
	super()
