class_name HuntDirector
extends MissionDirector
## The Hunt type (v0.11 M4, mission spec §3.1): a hunt closes on a place the god protects, step by step. Each step is a HuntStep --
## its words, its spot, its district, its time, its party -- whose party stands guard round its spot from the start. At its time, or
## `chain` seconds after the step before is broken, whichever is sooner, its standard is raised there (_raise_standard()). A standard
## its party guards (_guarded(): a member within `guard_reach`, out of doors, not held by the god) only shakes when struck; unguarded,
## it breaks for good and its party goes home. A guard off his post and calm again walks back `return_after` after he left; a fallen
## one is replaced `relief_after` after he fell; a broken step's party gets no relief. With `has_head`, the head (_appoint_head())
## waits indoors with his escorts until his time (`head_at`, or `head_chain` -- by default `chain` -- after the last step is broken;
## never before every standard is raised), then walks his search route (_head_route()) on duty, stopping `head_stop` at each door,
## to the quarry (_quarry_point()); a fright, a whisper or Discord drops his search, and back on his feet he takes it up at the door
## he had reached. The hunt finds its quarry (_found()): the night is lost. Every standard broken and the head down wins
## (HuntObjective). Every one of the hunt's people is kept out of the town's flight (_keep_held()). The Heretic Hunt is its first
## subclass; M6's The Lantern's Eye returns tower mirrors from _raise_standard(), has no head, and overrides _found() and
## _quarry_point() for its Searchlight (decision 111).

## One step of the hunt (v0.11 M4): a plain record, so the director holds no cycle.
class HuntStep:
	extends RefCounted
	## Its words on the banners and the strip ("the north quarter").
	var words := ""
	## Where its standard is raised (walkable ground once the director has begun).
	var spot := Vector2.INF
	## The district it sweeps, outlined while its standard stands; an empty Rect2 for none.
	var district := Rect2()
	## When its standard is raised at the latest, in the timeline's seconds.
	var at := 0.0
	## How many stand guard round its spot.
	var party_size := 3
	## Its standard once raised (a Variant: the town's teardown frees it; read through is_instance_valid()).
	var standard: Variant = null
	## Raised, and when; broken, and when (-1 until then; the night's real seconds).
	var raised := false
	var raised_at := -1.0
	var broken := false
	var broken_at := -1.0
	## Its party: Guard records.
	var party: Array = []


## One guard's post (v0.11 M4), as Spoiled Harvest's Watch.
class Guard:
	extends RefCounted
	## The guard, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## Where he stands, on his step's ring.
	var post := Vector2.INF
	## Seconds since he was last on guard (alive but away), and since he fell.
	var away := 0.0
	var fallen := 0.0
	## He is a relief, walking in, until he first stands guard.
	var relief := false


## Seconds between looks at the guards' orders and the escorts; how near a point the head has reached it; how far a place must move
## before someone is sent again; how far to the side of the head's track each escort walks (v0.11 M4).
const TICK := 0.5
const ARRIVE := 0.8
const MOVE := 0.3
const ESCORT_SIDE := 0.5
## The default standard (v0.11 M4): Broken Lanterns' drawn shrine post, its own role (never a building in a tally), and how hard a
## guarded one shakes when struck.
const STANDARD_SIZE := Vector2(0.4, 0.4)
const STANDARD_H := 22.0
const STANDARD_ROLE := &"standard"
const SHAKE := 2.5
## The map tags' colours (v0.11 M4, mission spec §0): a standard and the head gold, what is not yet grey, guards and danger red, the
## quarry steel blue.
const MARK_TARGET := Color("d8b23a")
const MARK_NOT_YET := Color("9a948a")
const MARK_WATCHED := Color("c8342a")
const MARK_QUARRY := Color("8fb8e8")

## The hunt's steps, in order, and its knobs, set by _plan() (v0.11 M4, decision 111): the chain; the head's time at the latest (-1
## for none: then only his chain brings him, and with no "head" event on the strip _break()'s expect() has nothing to bring forward,
## so his chained time never shows there -- the final review's note; M6's The Lantern's Eye has no head); whether there is a head;
## the ring the parties stand on and how near a standard a guard must stand; a guard's return and relief; the head's stop at each
## door, his pace (and his escorts'), and how far behind him his escorts walk; where he comes out.
var steps: Array[HuntStep] = []
var chain := 45.0
var head_at := -1.0
var has_head := true
var party_r := 1.2
var guard_reach := 1.5
var return_after := 20.0
var relief_after := 30.0
var head_stop := 4.0
var head_pace := 1.0
var escort_gap := 1.4
var head_door := Vector2.INF
## The head's own chain (v0.11 M4, the controller's ruling for The Heretic Hunt): how long after the last step breaks he comes out at
## the latest; -1 (the default) takes the steps' `chain`.
var head_chain := -1.0
## The tags' and the HUD's words, set by _plan() (v0.11 M4): The Heretic Hunt's by default; lost_word is the loss's reason.
var standard_label := "STANDARD"
var guard_label := "GUARD"
var next_label := "NEXT SWEEP"
var head_label := "CAPTAIN"
var head_waiting_label := "CAPTAIN - IN THE TEMPLE"
var escort_label := "ESCORT"
var quarry_label := "CELLAR"
var count_word := "standards"
var head_word := "kill the captain"
var lost_word := "found"

## The standards raised so far, in order (v0.11 M4; untyped: the town frees them at its teardown).
var standards: Array = []
## The damage filter each standard had when raised, by instance id (v0.11 M4): a borrowed tower's own is put back at teardown().
var _filters := {}
## The head and his escorts (Variants: any may be freed); his route; he is out, and when; he fell; he is searching; the hunt found
## its quarry (v0.11 M4).
var head: Variant = null
var escorts: Array = []
var head_route: Array[Vector2] = []
var head_out := false
var head_out_at := -1.0
var head_fell := false
var searching := false
var found := false
## His time has come while a standard was still to raise (v0.11 M4): he comes out once the last is raised.
var _head_called := false
## The point of his route he is making for, and the seconds of his stop left there (v0.11 M4).
var _route_at := 0
var _stop_left := 0.0
## Seconds into the night, and to the next look (v0.11 M4).
var _clock := 0.0
var _tick_in := 0.0


## The night's setup (v0.11 M4): the plan; each step's party set down on its ring and kept there on duty; the head and his escorts
## indoors, his route; each step and the head's time on the strip.
func _begin() -> void:
	_plan()
	for st in steps:
		st.spot = _walkable(st.spot)
	for i in steps.size():
		var picked := _appoint_party(i)
		for k in picked.size():
			var g := Guard.new()
			g.post = _party_post(i, k)
			g.man = picked[k]
			_set_down(picked[k], g.post)
			picked[k].go_duty(g.post)
			steps[i].party.append(g)
	if has_head:
		head = _appoint_head()
		escorts = _appoint_escorts()
		for v: Variant in [head] + escorts:
			if _alive(v):
				(v as Person).pace *= head_pace
		head_route = _head_route()
		_stop_left = head_stop
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in steps.size():
		timeline.add(steps[i].at, "step_%d" % i, _step_label(i), _raise.bind(i), func() -> bool: return not steps[i].raised)
	if has_head and head_at >= 0.0:
		timeline.add(head_at, "head", _head_label(), _call_head, func() -> bool: return not head_out and not head_down())
	rules.banner.emit(_opening_banner())


## A step for _plan() (v0.11 M4).
func _step(words: String, spot: Vector2, district: Rect2, at: float, party: int) -> HuntStep:
	var st := HuntStep.new()
	st.words = words
	st.spot = spot
	st.district = district
	st.at = at
	st.party_size = party
	return st


## Virtual (v0.11 M4): the steps, the knobs and the words.
func _plan() -> void:
	pass


## Virtual (v0.11 M4): the opening banner.
func _opening_banner() -> String:
	return "THE HUNT"


## Virtual (v0.11 M4): the strip's and the banner's words when step `i`'s standard is raised.
func _step_label(i: int) -> String:
	return "The hunt sweeps %s" % steps[i].words


## Virtual (v0.11 M4): the strip's and the banner's words when the head comes out.
func _head_label() -> String:
	return "The captain leads the last sweep"


## Virtual (v0.11 M4): the banner when step `i`'s standard breaks.
func _broken_banner(_i: int) -> String:
	return "A STANDARD FALLS"


## Virtual (v0.11 M4): the banner when the hunt finds its quarry.
func _found_banner() -> String:
	return "THE HUNT FINDS ITS QUARRY"


## The `k`th guard's post of step `i` (v0.11 M4): on a ring of `party_r` round its spot, `party_size` evenly spaced.
func _party_post(i: int, k: int) -> Vector2:
	return _ring_spot(steps[i].spot, party_r, k, steps[i].party_size)


## Virtual (v0.11 M4): step `i`'s party, one for each post in order (fewer when the town is short): the lay citizens nearest each
## post, dressed as guards (_dress_guard()). The base sets them down and keeps them on duty.
func _appoint_party(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for k in steps[i].party_size:
		var crew := _lay_near(_party_post(i, k), 1, _in_use() + out)
		if crew.is_empty():
			break
		_dress_guard(crew[0])
		out.append(crew[0])
	return out


## Virtual (v0.11 M4): `p` dressed as a guard -- the watch cloak and lantern by default.
func _dress_guard(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN


## Virtual (v0.11 M4): step `i`'s standard, raised now -- a drawn lantern post at its spot by default, taken away with the town's own
## buildings (Town._built, Broken Lanterns' way). The Lantern's Eye returns an existing tower. Null, or one already destroyed: the
## step counts as broken.
func _raise_standard(i: int) -> Structure:
	var at := steps[i].spot
	var s := crowd._env.add_structure(Rect2(at - STANDARD_SIZE * 0.5, STANDARD_SIZE), STANDARD_H, Structure.Kind.SHRINE, STANDARD_ROLE)
	town._built.append(s)
	return s


## Virtual (v0.11 M4): step `i`'s standard is guarded now -- a member of its party guarding (_guarding()) by default.
func _guarded(i: int) -> bool:
	for g: Guard in steps[i].party:
		if _guarding(i, g):
			return true
	return false


## Virtual (v0.11 M4): the head, indoors until his time; null for none (then he is down).
func _appoint_head() -> Person:
	return null


## Virtual (v0.11 M4): the head's escorts, indoors with him (untyped); none by default.
func _appoint_escorts() -> Array:
	return []


## Virtual (v0.11 M4): the head's route, its last point the quarry -- straight there by default.
func _head_route() -> Array[Vector2]:
	var out: Array[Vector2] = [_quarry_point()]
	return out


## Virtual (v0.11 M4): the place the hunt seeks -- none by default (The Heretic Hunt's cellar door; The Lantern's Eye's last cast).
func _quarry_point() -> Vector2:
	return Vector2.INF


## Virtual (v0.11 M4): the hunt has found its quarry now -- the head at the last point of his route, at the quarry, by default.
func _found() -> bool:
	if not head_out or not _alive(head) or head_route.is_empty() or _route_at < head_route.size() - 1:
		return false
	var p := head as Person
	return not p.inside and p.ground_pos.distance_to(_quarry_point()) <= ARRIVE


## Everyone at the hunt's work (v0.11 M4): every guard, the head and his escorts (untyped), for a new one to leave out.
func _in_use() -> Array:
	var out: Array = []
	for st in steps:
		for g: Guard in st.party:
			out.append(g.man)
	if head != null:
		out.append(head)
	out.append_array(escorts)
	return out


## One step (v0.11 M4): the timeline and the chain; every frame each unbroken step's party and the head's search; every TICK the
## hunt's people kept out of the town's flight and the escorts' places; then whether the hunt has found its quarry.
func step(delta: float) -> void:
	_clock += delta
	timeline.step(delta)
	if found:
		return
	_chain()
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	var evacuating := false
	if looking:
		_tick_in = TICK
		evacuating = _evacuation_began()
		_keep_held(evacuating)
	for i in steps.size():
		if not steps[i].broken:
			_keep_party(i, delta, looking, evacuating)
	_step_head(delta)
	if looking:
		_keep_escorts()
	if not found and _found():
		found = true
		rules.banner.emit(_found_banner())


## The second of the night step `i`'s standard is raised at the latest (v0.11 M4): its own time, or `chain` after the step before is
## broken if that is sooner. The step before still standing never brings it forward.
func step_due(i: int) -> float:
	var due := steps[i].at * timeline.stretch_factor()
	if i > 0 and steps[i - 1].broken:
		due = minf(due, steps[i - 1].broken_at + chain)
	return due


## The second of the night the head comes out at the latest (v0.11 M4): his time, or his chain (`head_chain`, else `chain`) after the
## last step is broken. With no time of his own (head_at < 0) only the chain brings him; INF while the last step stands.
func head_due() -> float:
	var due := INF if head_at < 0.0 else head_at * timeline.stretch_factor()
	if not steps.is_empty() and steps.back().broken:
		due = minf(due, (steps.back() as HuntStep).broken_at + (head_chain if head_chain >= 0.0 else chain))
	return due


## Seconds until step `i`'s standard is raised at the latest (v0.11 M4); 0 once it is.
func due_in(i: int) -> float:
	return 0.0 if steps[i].raised else maxf(step_due(i) - _clock, 0.0)


## Each step whose chained time has come is raised; the head comes out once called and every standard is raised (v0.11 M4).
func _chain() -> void:
	for i in range(1, steps.size()):
		if not steps[i].raised and steps[i - 1].broken and _clock >= step_due(i):
			rules.banner.emit(_step_label(i).to_upper())
			_raise(i)
	if has_head and not head_out and not head_down() and _all_raised():
		var last: HuntStep = steps.back() if not steps.is_empty() else null
		if _head_called or (last != null and last.broken and _clock >= head_due()):
			_head_go(true)


## Every step's standard is raised (v0.11 M4).
func _all_raised() -> bool:
	for st in steps:
		if not st.raised:
			return false
	return true


## Step `i`'s standard is raised (v0.11 M4): shielded while guarded (_shield()) and watched for its fall. One that cannot be made
## counts the step broken, so the night never locks.
func _raise(i: int) -> void:
	var st := steps[i]
	if st.raised:
		return
	st.raised = true
	st.raised_at = _clock
	var made: Variant = _raise_standard(i)
	if not is_instance_valid(made) or (made as Structure).destroyed:
		_break(i)  # none to raise, or a borrowed one already down: the step counts broken, so the night never locks
		return
	var s := made as Structure
	st.standard = s
	_filters[s.get_instance_id()] = s.damage_filter
	s.damage_filter = _shield
	if not s.broken.is_connected(_on_broken):
		s.broken.connect(_on_broken)
	standards.append(s)


## The step whose standard `s` is, or -1 (v0.11 M4).
func _step_of(s: Structure) -> int:
	for i in steps.size():
		if is_instance_valid(steps[i].standard) and steps[i].standard == s:
			return i
	return -1


## Structure.damage_filter for a standard (v0.11 M4, Broken Lanterns' guarded shrine): guarded, the blow only shakes it; else it
## takes the blow as any building does.
func _shield(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	var i := _step_of(s)
	if i >= 0 and _guarded(i):
		s.shake(SHAKE)
		return
	s.hp -= amount
	s.mark_hit(amount / s.max_hp, kind)
	if s.hp <= 0.0:
		s.destroy(source, kind)
	elif s.hp < s.max_hp * Structure.CRACK_AT:
		s.crack()


## A standard fell (v0.11 M4).
func _on_broken(s: Structure) -> void:
	var i := _step_of(s)
	if i >= 0 and not steps[i].broken:
		_break(i)


## Step `i` is broken for good (v0.11 M4): its party goes home, and the strip shows the next item's chained time.
func _break(i: int) -> void:
	var st := steps[i]
	st.broken = true
	st.broken_at = _clock
	rules.banner.emit(_broken_banner(i))
	for g: Guard in st.party:
		_release(g)
	if i + 1 < steps.size():
		timeline.expect("step_%d" % (i + 1), step_due(i + 1))
	elif has_head:
		timeline.expect("head", head_due())


## A guard of a broken step goes home (v0.11 M4, Spoiled Harvest's _release()): one on duty stood down, one calm sent home.
func _release(g: Guard) -> void:
	if not _alive(g.man):
		return
	var p := g.man as Person
	if p.mind == Person.Mind.DUTY:
		crowd.off_duty(p)
	elif p.mind in RECALL_MINDS and p.profile != null:
		p.regroup(p.profile.home)


## Guard `g` of step `i` stands guard now (v0.11 M4): alive, out of doors, not held by the god (BLIND), and within `guard_reach` of
## the standard -- of the spot before it is raised, or once it is down.
func _guarding(i: int, g: Guard) -> bool:
	if not _alive(g.man):
		return false
	var p := g.man as Person
	if p.inside or p.mind in BLIND:
		return false
	var st := steps[i]
	var s: Variant = st.standard
	var gap := (s as Structure).distance_to(p.ground_pos) if is_instance_valid(s) and not (s as Structure).destroyed \
		else st.spot.distance_to(p.ground_pos)
	return gap <= guard_reach


## Every one of the hunt's people is kept out of the town's flight by the one rule (v0.11 M4, the final review's ruling,
## MissionDirector._hold_all(): `evacuating`, at the first look after the evacuation began, calls back one it sent running; a whisper
## it found him under ends with him on his feet; a false calm's owed flight is let go): the guards of every unbroken step, the head and
## his escorts while the head stands -- a captain run off for the gates would win the hunt by his absence (head_down()). The ones the
## base recalls (_keep_party(), _step_head(), _keep_escorts()) are then put on duty again by their own rules.
func _keep_held(evacuating: bool) -> void:
	var people: Array = []
	for st in steps:
		if st.broken:
			continue
		for g: Guard in st.party:
			people.append(g.man)
	if not head_fell:
		people.append(head)
		people.append_array(escorts)
	_hold_all(people, evacuating)


## Step `i`'s party at their work (v0.11 M4): a guard standing guard is kept on duty at his post (back on his feet within reach, he is
## put on duty again, so the town's regroup and evacuation pass him by); one off his post but alive is sent back `return_after` after
## he left (once back on his feet), or at once at the first look after the town began to evacuate (`evacuating`, the final review's one
## policy, as The Crown's Bread's _work(): one _keep_held() just stopped from running is put straight back on duty); a fallen one is
## replaced `relief_after` after he fell.
func _keep_party(i: int, delta: float, looking: bool, evacuating := false) -> void:
	for g: Guard in steps[i].party:
		if _guarding(i, g):
			g.away = 0.0
			g.fallen = 0.0
			g.relief = false
			if looking and (g.man as Person).mind != Person.Mind.DUTY:
				_recall_to(g.man, g.post, evacuating)
		elif _alive(g.man):
			g.fallen = 0.0
			if (g.man as Person).inside:
				continue
			g.away += delta
			if looking and (g.away >= return_after or evacuating):
				_recall_to(g.man, g.post, evacuating)
		else:
			g.fallen += delta
			if looking and g.fallen >= relief_after:
				_relieve(i, g)


## A relief for a fallen guard of a step (v0.11 M4): the nearest lay citizen with a way to the post, dressed as a guard. With none who
## can reach it, the search backs off and is tried again `relief_after` later (the final review: not at every look). The step's index
## is passed for a subclass that relieves by step.
func _relieve(_i: int, g: Guard) -> void:
	var p := _lay_reaching(g.post, _in_use())
	if p == null:
		g.fallen = 0.0
		return
	_dress_guard(p)
	g.man = p
	g.fallen = 0.0
	g.away = 0.0
	g.relief = true
	if crowd._fled_all:
		_keep_from_flight(p, true)  # chosen once the town is running: never one of the flight
	p.go_duty(g.post)
	rules.banner.emit(_relief_banner())


## Virtual (v0.11 M4): the banner when a relief takes a fallen guard's post.
func _relief_banner() -> String:
	return "A NEW GUARD TAKES THE POST"


## The head's time has come (v0.11 M4, the timeline): out now if every standard is raised, else as soon as the last is.
func _call_head() -> void:
	_head_called = true
	if _all_raised():
		_head_go(false)


## The head comes out at `head_door` with his escorts and walks his route (v0.11 M4); `announce` gives the banner (the timeline
## gives its own). One the evacuation sent running while he waited indoors (it flees the calm indoors too) is stopped as he comes
## out, for go_duty() refuses a fleeing man.
func _head_go(announce: bool) -> void:
	if head_out:
		return
	head_out = true
	head_out_at = _clock
	if announce:
		rules.banner.emit(_head_label().to_upper())
	if not _alive(head):
		return
	var p := head as Person
	var door := _walkable(head_door) if head_door != Vector2.INF else p.ground_pos
	if p.inside:
		_bring_out(p, door)
		_keep_from_flight(p, true)
	if not head_route.is_empty():
		p.go_duty(head_route[0])
	for k in escorts.size():
		var v: Variant = escorts[k]
		if _alive(v) and (v as Person).inside:
			_bring_out(v as Person, _escort_out(k, door))
			_keep_from_flight(v as Person, true)


## Virtual (v0.11 M4): where the `k`th escort comes out with the head at `door` -- `escort_gap` behind it, ESCORT_SIDE to either side,
## by default. The Heretic Hunt sets them along the Temple's street, as the Temple stands behind its door.
func _escort_out(k: int, door: Vector2) -> Vector2:
	return _walkable(door + Vector2(ESCORT_SIDE * (-1.0 if k % 2 == 0 else 1.0), -escort_gap))


## The head's search, every frame (v0.11 M4): on duty, at his point he stops `head_stop` (searching from the first door), then walks
## on to the next; knocked off his errand, he takes it up again back on his feet, at the door he had reached, his stop begun anew.
func _step_head(delta: float) -> void:
	if not head_out or found or head_down() or head_route.is_empty():
		return
	var p := head as Person
	if p.inside:
		return
	var goal := head_route[_route_at]
	if p.mind == Person.Mind.DUTY:
		if p.ground_pos.distance_to(goal) <= ARRIVE:
			searching = true
			if _route_at >= head_route.size() - 1:
				return
			_stop_left -= delta
			if _stop_left <= 0.0:
				_route_at += 1
				_stop_left = head_stop
				p.go_duty(head_route[_route_at])
		elif p.anchor.distance_to(goal) > MOVE:
			p.go_duty(goal)
	elif p.mind in RECALL_MINDS:
		_stop_left = head_stop
		p.go_duty(goal)


## The escorts keep `escort_gap` behind the head, ESCORT_SIDE to either side of his track (v0.11 M4): beyond one Silent Doom of him.
## One frightened, held or fighting is left be, and walks back once on his feet.
func _keep_escorts() -> void:
	if not head_out or not _alive(head) or (head as Person).inside:
		return
	var p := head as Person
	var goal := head_route[mini(_route_at, head_route.size() - 1)] if not head_route.is_empty() else p.ground_pos
	var dir := goal - p.ground_pos
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.DOWN
	var side := Vector2(-dir.y, dir.x)
	for k in escorts.size():
		var v: Variant = escorts[k]
		if not _alive(v) or (v as Person).inside:
			continue
		var e := v as Person
		var spot := _walkable(p.ground_pos - dir * escort_gap + side * ESCORT_SIDE * (-1.0 if k % 2 == 0 else 1.0))
		if e.mind in RECALL_MINDS or (e.mind == Person.Mind.DUTY and e.anchor.distance_to(spot) > 0.5):
			e.go_duty(spot)


## A death (v0.11 M4): the head's, any death, ends him for the objective; his escorts go home. Nobody takes up the search.
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if head == null or not is_instance_valid(head) or e != head or head_fell:
		return
	head_fell = true
	for v: Variant in escorts:
		if _alive(v):
			crowd.off_duty(v as Person)


## The head is down (v0.11 M4, decision 113): there is none, he was killed, or his body is gone.
func head_down() -> bool:
	return not has_head or head_fell or not _alive(head)


## Step `i`'s standard, standing or fallen, or null (v0.11 M4).
func standard(i: int) -> Structure:
	var s: Variant = steps[i].standard
	return s as Structure if is_instance_valid(s) else null


## Step `i`'s standard stands raised and guarded now (v0.11 M4). Only reads.
func guarded(i: int) -> bool:
	return steps[i].raised and not steps[i].broken and standard(i) != null and _guarded(i)


## Step `i`'s guards standing guard now (v0.11 M4). Only reads.
func party_on(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for g: Guard in steps[i].party:
		if _guarding(i, g):
			out.append(g.man as Person)
	return out


## A relief of step `i` walking in, or null (v0.11 M4, for the scripted player). Only reads.
func relief_walking(i: int) -> Person:
	for g: Guard in steps[i].party:
		if g.relief and _alive(g.man) and not _guarding(i, g) and not (g.man as Person).inside:
			return g.man as Person
	return null


## Whether step `i` is broken (v0.11 M4).
func broken(i: int) -> bool:
	return steps[i].broken


## How many steps are broken (v0.11 M4).
func broken_count() -> int:
	var n := 0
	for st in steps:
		n += 1 if st.broken else 0
	return n


## Every step is broken (v0.11 M4); false with none.
func broken_all() -> bool:
	return not steps.is_empty() and broken_count() == steps.size()


## The current step (v0.11 M4): the first raised and unbroken, or -1.
func current() -> int:
	for i in steps.size():
		if steps[i].raised and not steps[i].broken:
			return i
	return -1


## The next step still to be raised, or -1 (v0.11 M4).
func next_step() -> int:
	for i in steps.size():
		if not steps[i].raised:
			return i
	return -1


## Why the night is lost now, "" while it is not (v0.11 M4): the hunt found its quarry.
func lost_reason() -> String:
	return lost_word if found else ""


## The map tags, most important first (v0.11 M4, mission spec §3):
## - each standing standard, gold; the current one pointed at, "- GUARDED" while guarded;
## - the next step's spot with its chained time, grey, pointed at;
## - the head waiting (grey, at his door), or out (gold, pointed at, "- SEARCHING" once he searches), and his escorts, red;
## - the quarry, steel blue, pointed at;
## - each unbroken step's guards: labelled on guard, a red diamond on a relief walking in, a small red mark on one away;
## - each standing standard's district outlined in red, on a red pip at its foot (decision 114).
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	var cur := current()
	for i in steps.size():
		var s := standard(i)
		if s == null or steps[i].broken or s.destroyed:
			continue
		var label := standard_label + (" - GUARDED" if i == cur and guarded(i) else "")
		out.append(MapTag.place(s.center(), MARK_TARGET, label, s.height, i == cur))
	var n := next_step()
	if n >= 0:
		out.append(MapTag.place(steps[n].spot, MARK_NOT_YET, "%s %s" % [next_label, UiTheme.clock(due_in(n))], 0.0, true))
	if has_head and _alive(head):
		var h := head as Person
		if not head_out and head_door != Vector2.INF:
			out.append(MapTag.place(_walkable(head_door), MARK_NOT_YET, head_waiting_label, 0.0, false))
		elif head_out and not h.inside:
			out.append(MapTag.person(h.ground_pos, MARK_TARGET, head_label + (" - SEARCHING" if searching else ""), true))
			for v: Variant in escorts:
				if _alive(v) and not (v as Person).inside:
					out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, escort_label))
	var q := _quarry_point()
	if q != Vector2.INF:
		out.append(MapTag.place(q, MARK_QUARRY, quarry_label, 0.0, true))
	for i in steps.size():
		if steps[i].broken:
			continue
		for g: Guard in steps[i].party:
			if not _alive(g.man) or (g.man as Person).inside:
				continue
			var p := g.man as Person
			if _guarding(i, g):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, guard_label))
			elif g.relief:
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	for i in steps.size():
		var s := standard(i)
		if s == null or steps[i].broken or s.destroyed or not steps[i].district.has_area():
			continue
		var o := MapTag.pip(s.center(), MARK_WATCHED)
		o.outline = steps[i].district
		out.append(o)
	return out


## The hint's phase (v0.11 M4, decision 110; the final review put a standing standard first): "guarded" or "open" for the current
## standard while one stands; else "searching" or "captain" while the head is out; "coming" once every step is broken and the head is
## still to come out (the controller's ruling: the seconds to him, hint_seconds(), on the line); "waiting" while none stands and a step
## is still to come; "" before the first is raised.
func hint_phase() -> String:
	if found:
		return ""
	var cur := current()
	if cur >= 0:
		return "guarded" if guarded(cur) else "open"
	if has_head and not head_down():
		if head_out:
			return "searching" if searching else "captain"
		if broken_all():
			return "coming"
	if broken_count() > 0 and next_step() >= 0:
		return "waiting"
	return ""


## The seconds the hint's line counts down (v0.11 M4, MissionHints.SECONDS): in the "coming" phase, until the head comes out at the
## latest (head_due()); else 0.
func hint_seconds() -> float:
	if hint_phase() != "coming":
		return 0.0
	var due := head_due()
	return maxf(due - _clock, 0.0) if due != INF else 0.0


## What the results show (v0.11 M4): the steps broken, the head down, and whether the hunt found its quarry.
func report() -> Dictionary:
	return {"broken": broken_count(), "head_down": head_down(), "found": found}


## Lets go of every standard's filter and signal (a standard may be a town tower that outlives the night, decision 111), the kills,
## and the timeline (v0.11 M4). Safe to call twice.
func teardown() -> void:
	for v: Variant in standards:
		if is_instance_valid(v):
			var s := v as Structure
			s.damage_filter = _filters.get(s.get_instance_id(), Callable())
			if s.broken.is_connected(_on_broken):
				s.broken.disconnect(_on_broken)
	_unhook_kills(_on_killed)
	timeline = null  # its banner and guard lambdas hold this director: let both go
