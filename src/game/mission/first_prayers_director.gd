class_name FirstPrayersDirector
extends MirasHouseDirector
## First Prayers (v0.11 M2, Tier 1, spec §4 and §8 row 5), Mira's House's Convert generalised: lead three of the poor to the
## old well shrine unseen. The shrine is a drawn stone post (Broken Lanterns' shrine) at the market's west edge, which a blow
## only shakes. A poor citizen whispered to its door (or lured to a light by it) goes down the well's steps to pray, hidden,
## PRAY_SECONDS, one at a time, and comes out a Believer; NEED out win. Few Faithful -- the clergy nearest the Temple and a few
## lay -- and no Inquisitor; but the shrine sits by the market: at MARKET_AT the market fills and Faithful stand at its door,
## and at PRIESTS_AT the priests come to the well. Mira's rules otherwise: a Faithful who sees runs to the Temple, a report
## delivered fills the Gaze, a seen death adds to it, the bell's toll adds 40 and turns the Lantern (v0.11.2). Its tags are Mira's own, the shrine named for the well.

## Where the shrine stands (v0.11 M2; moved to free ground), and its role (not a building in the tally: Rules.BUILDING_ROLES).
const SHRINE_AT := Vector2(-4.4, 2.8)
const ROLE := &"well_shrine"
## The poor (v0.11 M2): the POOR lay citizens nearest POOR_SPOT (the south-west quarter); NEED of them must pray.
const POOR_SPOT := Vector2(-11.0, 12.0)
const POOR := 8
const POOR_QUARTER := "south-west quarter"
const NEED := 3
## The night's numbers (v0.11 M2, spec §4). PRAY_SECONDS was tuned from the first guess of 25 so the scripted clear lands in 3-4 minutes;
## the rest are the first guesses, to be tuned in this order if it misses again.
const PRAY_SECONDS := 32.0
const MARKET_AT := 75.0
const MARKET_SECONDS := 40.0
const PRIESTS_AT := 150.0
const PRIESTS_SECONDS := 40.0
const FAITHFUL_CLERGY := 3
const FAITHFUL_LAY := 3
## Where the priests stand by the door (v0.11 M2; offsets from it).
const PRIEST_SPOTS := [Vector2(-1.0, 1.2), Vector2(1.0, 1.2)]
## How hard a blow shakes the shrine (v0.11 M2).
const SHRINE_SHAKE := 2.0
## v0.11.1 (spec 7.2 row 5, a second route): a Will-o'-the-Wisp cast at the shrine draws the poor from beyond its own reach too -- up to
## FETCH_R from the light -- each walking to it at his own pace and staring FETCH_STARE seconds when there, so a player can fetch the poor
## from the streets instead of waiting for them to pass the shrine. Only a light at the shrine; loadout A casts none.
const FETCH_R := 16.0
const FETCH_STARE := 6.0
## (god T1R, spec 8, rule 3) The poor come to pray: from the night's start they walk to the shrine on their own, one at a time. The k-th sets
## out at POOR_OUT_AT[k], or POOR_CHAIN seconds after the one before him went in or was turned away, whichever is sooner. The first is timed
## to reach the door inside the market window (80 s out, 2-14 s of walking: so doing nothing loses); the others are chained. Tuned (task 6): 80 not 60,
## because a walker in by 72 s halves route A's clear; POOR_CHAIN 50, so a 60 s Bell Lies cooldown fits between two walkers. *tunable*
const POOR_OUT_AT := [80.0, 170.0, 240.0]
const POOR_CHAIN := 50.0
## A building burning within this of the shrine's door pulls the Faithful there away to the fire (F2). 7 not 6: more houses to burn. *tunable*
const FIRE_PULL := 7.0
## How far off a burning building the pulled Faithful stand (F2).
const FIRE_STAND := 1.5
## Seconds a walker may stand still on his way before he gives the walk up.
const WALK_STALL := 20.0
## F3b (god T1R fix round, D32): brambles by the well hide its steps. While a Thornwall segment stands within THORN_HIDE of the door, no
## Faithful sees who goes down or comes up, from any side; and one who went down hidden comes up hidden, his prayer over (a wall stands 25 s,
## a prayer takes 32). F3's line test alone gave Passage no route: one 3-unit wall cannot stand between the door and a line round it (the
## market's four stand on both sides), and a wall cools 42 s, so one could never hide both a going-in and its coming-out.
const THORN_HIDE := 1.5
## D34 (god T1R fix round 3, the user's option c): once no Faithful is left alive the door stands empty -- the next walker sets out at once (the
## chain is skipped) and the poor may pray together, several at the shrine at once, each counted. Without it a player who has taken every Faithful
## (Death's whole kit) could only wait out three prayers one at a time, 100 s and more. Banner EMPTY_BANNER, once.
const EMPTY_BANNER := "THE DOOR STANDS EMPTY - THE POOR HURRY IN"


## The town's places and numbers (v0.12, spec 1.5): seeded from the consts above, which are Aldermere's; a town's overrides replace them.
## (`read_seconds`, MirasHouseDirector's, is the prayer's length: seeded from PRAY_SECONDS in _init().) NEED (the copy says three),
## POOR and FAITHFUL_CLERGY stay consts.
## The names a town's overrides may set (Overrides): the vars below and `read_seconds`; setup reads them and never assigns them.
const TOWN_VARS := ["shrine_at", "poor_spot", "poor_quarter", "market_at", "market_seconds", "priests_at", "priests_seconds", "poor_out_at",
	"faithful_lay", "fetch_r", "read_seconds"]
var shrine_at: Vector2 = SHRINE_AT
var poor_spot: Vector2 = POOR_SPOT
## What the tour calls the place the poor live (a name on a tag: a town may set it; the copy must never name another town's quarter).
var poor_quarter: String = POOR_QUARTER
var market_at: float = MARKET_AT
var market_seconds: float = MARKET_SECONDS
var priests_at: float = PRIESTS_AT
var priests_seconds: float = PRIESTS_SECONDS
var faithful_lay: int = FAITHFUL_LAY
var fetch_r: float = FETCH_R
## When the poor walk (god T1R): a town may put its first walker later where the poor live nearer the door.
var poor_out_at: Array = POOR_OUT_AT.duplicate()
## The one of the poor walking to the shrine now (null between walks) (god T1R).
var walker: Person
## Walkers sent so far, and how many of POOR_OUT_AT's times are left (past them a walker goes by the chain alone).
var _walk_n := 0
var _walks_left := POOR_OUT_AT.size()
## The timeline second the last walker went in or was turned away (-1 while one walks, or before the first): the chain counts from it.
var _chain_from := -1.0
## How many times each of the poor has walked: a turned-away walker goes to the back of the line.
var _walked := {}
## The walker on his way: where he last moved from, and for how long he has stood (a walk is given up after WALK_STALL seconds).
var _walker_at := Vector2.INF
var _walker_still := 0.0
## The night's own seconds, on the clock the liners' window counts (real seconds, not the timeline's).
var _t := 0.0
## F2: the Faithful pulled to a fire, and the fire that pulled them.
var _pulled: Array[Person] = []
var _blaze: Structure
## Where each liner of the open window stands (Person -> offset from the door), for the one who goes back to it.
var _line_spots := {}
## F5: a window that came due during the lie ({pool: Callable, spots: Array, ends: float on _t}); it forms when the lie ends.
var _late: Array[Dictionary] = []
var _lie_told := false
## F3b: the night second each bramble segment by the door was first seen (by instance id), and whether the door was hidden at the last step;
## the poor who went down hidden (Person -> true), and the one coming up hidden now (nobody sees the door while he does).
var _brambles := {}
var _hid := false
var _hidden_prayers := {}
var _hush := false
## D33: where each bramble segment near the shrine stood (by instance id), so a look at one is known after it has withered.
var _thorn_spots := {}
## D34: the door has stood empty (and EMPTY_BANNER been shown); the poor hurrying to the shrine together besides the walker.
var _emptied := false
var _hurrying: Array[Person] = []


## MirasHouseDirector's prayer length starts at PRAY_SECONDS (v0.12, R31): set at .new(), so a town's override survives setup.
func _init() -> void:
	read_seconds = PRAY_SECONDS


func _begin() -> void:
	need = NEED
	_walks_left = poor_out_at.size()
	one_at_a_time = true
	super()
	rules.cast_made.connect(_on_light)


## A Wisp is cast at the shrine (v0.11.1): each of the poor beyond the Wisp's own reach but within FETCH_R is drawn to the near side of its
## ring, the lure lasting his walk there and FETCH_STARE more. Those within the Wisp's reach it draws itself.
func _on_light(_slot: int, key: String, at: Vector2) -> void:
	if key != "wisp" or roof_fallen or burning or not _near_house(at, MirasHouseDirector.LURE_REACH):
		return
	for g in grieving:
		if not _alive(g) or g.inside or believers.has(g):
			continue
		var gap := g.ground_pos.distance_to(at)
		if gap <= WillOWisp.LURE_REACH or gap > fetch_r:
			continue
		var near := _walkable(at + (g.ground_pos - at).normalized() * WillOWisp.RING.x)
		if not g.lure(near, WillOWisp.WISP_TIME - 0.5, g.ground_pos):
			continue
		var way := 0.0
		var from := g.ground_pos
		for step in crowd._grid.path(g.ground_pos, near):
			way += from.distance_to(step)
			from = step
		g._observe_left = way / maxf(g.walk_speed, 0.05) + FETCH_STARE


func teardown() -> void:
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_light):
		rules.cast_made.disconnect(_on_light)
	super()


## The night's opening banner (v0.11 M2).
func _opening_banner() -> String:
	return "THE POOR COME TO THE OLD WELL"


## What the shrine's tag says (v0.11 M2): its name, or while someone prays the seconds left, as Broken Lanterns' DRAINING counts
## them (whole seconds, rounded up); HIDDEN as well while the one praying went down hidden (god T1R, F3b: he comes up unseen).
func _house_label() -> String:
	var left := reading_left()
	if left == INF:
		return "OLD WELL SHRINE"
	for p: Variant in _hidden_prayers.keys():
		if is_instance_valid(p) and _reading.has(p) and is_equal_approx(float(_reading[p]), left):
			return "PRAYING %d - HIDDEN" % ceili(left)
	return "PRAYING %d" % ceili(left)


## Dawn (v0.11 M2): on the tier board a won night is held to dawn, so the roof of Mira's House does not fall here. Nobody goes in
## after it, but a prayer in progress goes on and the shrine post stands (a blow only shakes it).
func _roof() -> void:
	roof_fallen = true


## The old well shrine, raised at the market's edge (v0.11 M2): a shrine post a blow only shakes. The town takes it away with
## its own buildings (Town.teardown()).
func _find_house() -> Structure:
	var at := _walkable(shrine_at)
	var size := BrokenLanternsDirector.SHRINE_SIZE
	var s := crowd._env.add_structure(Rect2(at - size * 0.5, size), BrokenLanternsDirector.SHRINE_H, Structure.Kind.SHRINE, ROLE)
	s.damage_filter = func(st: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void: st.shake(SHRINE_SHAKE)
	town._built.append(s)
	return s


## The POOR lay citizens nearest POOR_SPOT are the poor; the FAITHFUL_CLERGY clergy nearest the Temple's door and FAITHFUL_LAY
## lay citizens spread through the rest are Halcyon's Faithful (v0.11 M2). No Inquisitor.
func _choose_people() -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	lay.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_to(poor_spot) < b.ground_pos.distance_to(poor_spot))
	for i in mini(POOR, lay.size()):
		lay[i].profile.faith = CitizenProfile.Faith.GRIEVING
		grieving.append(lay[i])
	clergy.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	for p in clergy.slice(0, FAITHFUL_CLERGY):
		_make_faithful(p)
	var rest: Array[Person] = []
	rest.assign(lay.slice(POOR))
	_spread_faithful(rest, faithful_lay)
	venn = null


## The night's two windows (v0.11 M2): the market fills; the priests come to the well.
func _add_events() -> void:
	# (god T1R) one event for each walker; it is dropped if the chain sent him sooner, or one is still walking when it falls due
	# (the walker goes as soon as the one before him is done: _walker_step()).
	for k in poor_out_at.size():
		timeline.add(float(poor_out_at[k]), "poor_%d" % k, "One of the poor sets out", Callable(),
			func() -> bool: return _walk_n <= k and walker == null)
	timeline.add(market_at, "market", "The market fills", _market_fills, func() -> bool: return not _free_faithful().is_empty())
	timeline.add(priests_at, "priests", "The priests come to the well", _priests_come,
		func() -> bool: return not _free_clergy().is_empty())


## The market fills (v0.11 M2): the free Faithful nearest the door stand by it (Mira's LINE_SPOTS) for MARKET_SECONDS.
func _market_fills() -> void:
	_form_line(_free_faithful, MirasHouseDirector.LINE_SPOTS, market_seconds)


## The priests come (v0.11 M2): the free clergy among the Faithful stand by the door (PRIEST_SPOTS) for PRIESTS_SECONDS.
func _priests_come() -> void:
	_form_line(_free_clergy, PRIEST_SPOTS, priests_seconds)


## A window's line forms (god T1R, F5): at once, or, while the bell lies ALL IS WELL, when the lie ends -- for the seconds the window
## has left by then (none: it never forms). `pool` is asked at the moment the line forms.
func _form_line(pool: Callable, spots: Array, seconds: float) -> void:
	if crowd.is_bell_lying():
		_late.append({"pool": pool, "spots": spots, "ends": _t + seconds})
		_tell_lie()
		return
	_line_door(pool.call(), spots, seconds)


## The free Faithful who are clergy (v0.11 M2).
func _free_clergy() -> Array[Person]:
	var out: Array[Person] = []
	for f in _free_faithful():
		if CitizenProfile.is_clergy(f.profile.role):
			out.append(f)
	return out


## The nearest of `pool` stand at the door's `spots` for `seconds` (v0.11 M2; Mira's liners: _liners_step() lets them go); any
## line still standing is let go first.
func _line_door(pool: Array[Person], spots: Array, seconds: float) -> void:
	for f: Variant in liners:
		if _alive(f) and f.mind == Person.Mind.DUTY:
			f.leave_shelter(false)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	liners = []
	_line_spots = {}
	for i in mini(spots.size(), pool.size()):
		pool[i].go_duty(_walkable(door + (spots[i] as Vector2)))
		liners.append(pool[i])
		_line_spots[pool[i]] = spots[i]
	_liners_left = seconds


## One step (god T1R): the lie first (the line is stood down and the reports dropped before one can be delivered), then Mira's step,
## then the fire's pull and the walker (who is turned away or goes in in Mira's _doors()).
func step(delta: float) -> void:
	_t += delta
	_lie_step()
	_bramble_step()
	_empty_step()
	super(delta)
	_fire_step()
	_walker_step(delta)
	_hurry()


## F5 ALL IS WELL (the bell lies): every liner is stood down at once, every running report dropped (the carrier goes back to his day, nothing is
## delivered), and a window that falls due now forms when the lie ends, for the seconds it has left.
func _lie_step() -> void:
	if not crowd.is_bell_lying():
		_lie_told = false
		_form_late()
		return
	var stood := false
	for f: Variant in liners:
		if _alive(f) and (f as Person).mind == Person.Mind.DUTY and not _carrying(f):
			(f as Person).leave_shelter(false)
			stood = true
	liners = []
	_liners_left = 0.0
	for r in reports:
		if r.is_open():
			r.drop()
			stood = true
	if stood:
		_tell_lie()


func _tell_lie() -> void:
	if not _lie_told:
		_lie_told = true
		rules.banner.emit("ALL IS WELL - THE FAITHFUL GO HOME")


## The lie is over: each window that fell due during it forms for the seconds it has left (a window the lie outlasted never forms).
func _form_late() -> void:
	if _late.is_empty():
		return
	var due := _late
	_late = []
	for w in due:
		var left := float(w.ends) - _t
		if left > 1.0:
			_line_door((w.pool as Callable).call(), w.spots, left)


## F2 Fire pulls the Faithful: while a building burns within FIRE_PULL of the door, every Faithful lining it and every free Faithful within
## FIRE_PULL of the door stands off the fire (on duty to a spot FIRE_STAND from it, on the side away from the door). When it is out, a liner whose
## window is still open goes back to his spot, the others to their day.
func _fire_step() -> void:
	if burning or roof_fallen or crowd.fires == null:
		return
	var blaze := _burning_near_door()
	if blaze == null:
		if not _pulled.is_empty():
			_fire_out()
		_blaze = null
		return
	_blaze = blaze
	var pulled_now := false
	var crowd_n := _pulled.size()
	var who: Array[Person] = []
	for f: Variant in liners:
		if _alive(f) and not _carrying(f) and not _pulled.has(f):
			who.append(f)
	for f in _free_faithful():
		if f.ground_pos.distance_to(door) <= FIRE_PULL and not _pulled.has(f) and not who.has(f):
			who.append(f)
	for f in who:
		_pull_to(blaze, f, crowd_n)
		_pulled.append(f)
		crowd_n += 1
		pulled_now = true
	# One a fright broke off (or whose spot he could not reach) is sent again.
	for f: Variant in _pulled:
		if _alive(f) and not (f as Person).held_by_god() and (f as Person).mind in Person.LURABLE and not _carrying(f):
			_pull_to(blaze, f, _pulled.find(f))
	if pulled_now:
		rules.banner.emit("THE FAITHFUL RUN TO THE FIRE")


## `f` goes on duty to a spot FIRE_STAND off `blaze`, on the side away from the door, fanned by `k`: the first of the fan he has a way to, and
## that lies beyond the door's sight, is his; else the plain one.
func _pull_to(blaze: Structure, f: Person, k: int) -> void:
	var from := blaze.center()
	var away := (from - door).normalized() if from.distance_to(door) > 0.1 else Vector2.DOWN
	var reach := maxf(blaze.footprint.size.x, blaze.footprint.size.y) * 0.5 + FIRE_STAND
	var best := Vector2.INF
	var best_len := INF
	for i in 8:
		var turn := float((k + i) % 8) * TAU / 8.0
		var spot := _walkable(from + away.rotated(turn) * reach)
		if spot.distance_to(door) <= SIGHT + 0.8:
			continue
		var way := crowd._grid.path(f.ground_pos, spot)
		if way.is_empty() or _past_door(f.ground_pos, way):
			continue
		var len := _way_length(f.ground_pos, way)
		if len < best_len:
			best = spot
			best_len = len
	if best != Vector2.INF:
		f.go_duty(best)
	elif f.ground_pos.distance_to(door) > SIGHT + 1.0:
		f.go_duty(f.ground_pos)  # no way round the door's sight: he stands where he is, out of it
	else:
		f.go_duty(_walkable(from + away * reach))


## The way `way` from `at` passes within the door's sight (or, from within it, nearer the door than he stands).
func _past_door(at: Vector2, way: PackedVector2Array) -> bool:
	var prev := at
	var limit := minf(SIGHT + 0.3, at.distance_to(door) - 0.2)
	for p in way:
		if Geometry2D.get_closest_point_to_segment(door, prev, p).distance_to(door) <= limit:
			return true
		prev = p
	return false


func _way_length(at: Vector2, way: PackedVector2Array) -> float:
	var n := 0.0
	var prev := at
	for p in way:
		n += prev.distance_to(p)
		prev = p
	return n


## The nearest burning building (not the shrine) within FIRE_PULL of the door; null for none.
func _burning_near_door() -> Structure:
	var best: Structure = null
	for s: Variant in crowd.fires.fires.keys():
		if not is_instance_valid(s) or (s as Structure).destroyed or s == house or (s as Structure).center().distance_to(door) > FIRE_PULL:
			continue
		if best == null or (s as Structure).center().distance_to(door) < best.center().distance_to(door):
			best = s as Structure
	return best


## The fire is out: back to the line for a liner whose window is still open, else to his day.
func _fire_out() -> void:
	for f: Variant in _pulled:
		if not _alive(f) or (f as Person).mind != Person.Mind.DUTY or _carrying(f):
			continue
		if liners.has(f) and _line_spots.has(f) and _liners_left > 0.0:
			(f as Person).go_duty(_walkable(door + (_line_spots[f] as Vector2)))
		else:
			(f as Person).leave_shelter(false)
	_pulled = []


## Rule 3, They come to pray: when the next walker is due and none walks, the nearest unbelieving poor who is free sets out for the door; the
## walker on his way is kept to his walk (taken up again when a fright or a hold wears off), and when he is turned away (home, to the back of the line),
## has gone in or has fallen the chain starts for the next. Quiet once the shrine is closed.
func _walker_step(delta: float) -> void:
	if burning or roof_fallen:
		return
	if walker != null:
		if not _alive(walker) or walker.inside or _reading.has(walker) or believers.has(walker):
			_walker_done()
		elif _turned.has(walker):
			walker.leave_shelter(false)
			_walker_done()
		else:
			_walker_keep(delta)
		return
	if timeline.elapsed() >= walk_due() and not (door_empty() and still_needed() <= 0):
		_walker_out()


## The timeline second the next walker sets out: his own time, or POOR_CHAIN after the one before him was done if that is sooner; INF while one walks
## and there is no chain yet. With the door empty (D34), now.
func walk_due() -> float:
	var at := float(poor_out_at[_walk_n]) if _walks_left > 0 else INF  # past the list a walker goes by the chain alone
	if _chain_from >= 0.0:
		at = minf(at, _chain_from + POOR_CHAIN)
	if door_empty():
		at = minf(at, timeline.elapsed())
	return at


## D34: no Faithful is left alive -- nobody can watch the door again.
func door_empty() -> bool:
	for f in faithful:
		if _alive(f):
			return false
	return true


## D34: how many more of the poor must set out for the night to be won: NEED less the Believers out, those praying, the walker and those hurrying.
func still_needed() -> int:
	var on_way := 1 if _alive(walker) and not walker.inside else 0
	return need - believers_outside() - inside().size() - on_way - _hurrying.size()


## D34: with the door empty, as many of the poor as the night still needs set out at once besides the walker, together (the chain skipped for
## each); each keeps to his walk as the walker does. Quiet while a Faithful lives.
func _hurry() -> void:
	var still: Array[Person] = []
	for p in _hurrying:
		if _alive(p) and not p.inside and not _reading.has(p) and not believers.has(p):
			still.append(p)
	_hurrying = still
	if burning or roof_fallen or not door_empty():
		return
	for p in _hurrying:
		if p.mind == Person.Mind.DUTY:
			if not p.has_goal() and p.ground_pos.distance_to(door) > DOOR_REACH:
				p.go_duty(door)
		elif p.mind in Person.LURABLE and not p.held_by_god():
			p.go_duty(door)
	var more := still_needed()
	while more > 0:
		var pick := next_walker()
		if pick == null:
			break
		_walked[pick] = int(_walked.get(pick, 0)) + 1
		pick.go_duty(door)
		_hurrying.append(pick)
		more -= 1


## D34: with the door empty the shrine takes the poor together (Mira's one_at_a_time off), and the moment is announced once.
func _empty_step() -> void:
	if burning or roof_fallen or not door_empty():
		return
	one_at_a_time = false
	if not _emptied:
		_emptied = true
		rules.banner.emit(EMPTY_BANNER)


## The one of the poor who would set out next: the unbelieving poor nearest the door who is alive, out of doors and free (not held by the god,
## not reporting, not praying), the ones who have walked least first; null for none.
func next_walker() -> Person:
	var pick: Person = null
	var best := INF
	var most := 99
	for g in grieving:
		if not _alive(g) or g.inside or believers.has(g) or _reading.has(g) or _carrying(g) or g.held_by_god() \
				or not g.mind in Person.LURABLE:
			continue
		var n := int(_walked.get(g, 0))
		var d := g.ground_pos.distance_to(door)
		if n < most or (n == most and d < best):
			pick = g
			most = n
			best = d
	return pick


## The next walker sets out for the door on duty, if one of the poor is free (else the next look tries again).
func _walker_out() -> void:
	var pick := next_walker()
	if pick == null:
		return
	walker = pick
	_walked[pick] = int(_walked.get(pick, 0)) + 1
	_walk_n += 1
	_walks_left -= 1
	_chain_from = -1.0
	pick.go_duty(door)
	rules.banner.emit("ONE OF THE POOR SETS OUT FOR THE SHRINE")


## The walk is over (in, turned away or fallen): the chain for the next starts now, and the strip shows its time.
func _walker_done() -> void:
	walker = null
	_walker_at = Vector2.INF
	_walker_still = 0.0
	_chain_from = timeline.elapsed()
	if _walks_left > 0:
		timeline.expect("poor_%d" % _walk_n, walk_due() * timeline.stretch_factor())


## The walker keeps to his walk: on duty, he walks on; back on his feet from a fright or a hold (not the god's own, a whisper to the door
## is Mira's _brought()), he takes it up again.
func _walker_keep(delta: float) -> void:
	# One who has not moved for WALK_STALL seconds on the way (a way shut, a place he cannot leave, a whisper to ground he cannot reach) gives the
	# walk up: home, and the chain goes on.
	if walker.ground_pos.distance_to(door) > DOOR_REACH + 0.6 and walker.ground_pos.distance_to(_walker_at) < 0.4:
		_walker_still += delta
		if _walker_still >= WALK_STALL:
			walker.leave_shelter(false)
			rules.banner.emit("ONE OF THE POOR GIVES UP THE WALK")  # (D31) not a loss -- the chain sends the next -- but never a silent one
			_walker_done()
			return
	else:
		_walker_at = walker.ground_pos
		_walker_still = 0.0
	if walker.mind == Person.Mind.DUTY:
		if not walker.has_goal() and walker.ground_pos.distance_to(door) > DOOR_REACH:
			walker.go_duty(door)
	elif walker.mind in Person.LURABLE and not walker.held_by_god():
		walker.go_duty(door)


## The walker on duty at the door is brought (Mira's rules: turned away if a Faithful sees, else in, one at a time) as well as a whispered or lured one;
## with brambles grown over the door itself (a Thornwall clicked on it), he is at the door from DOOR_REACH of the brambles. One who has prayed does not go
## down again (god T1R fix round): Mira's base let a Believer stopping to look at something by the shrine pray twice, out of the count for 32 s and
## keeping the walker waiting. And a poor who stops to look at brambles grown by the shrine (Crowd.THORN_LOOK) is not brought by the look (D33): it
## is no lure of the god's, and it would make an unannounced Believer.
func _brought(p: Person) -> bool:
	if believers.has(p):
		return false
	if (p == walker or _hurrying.has(p)) and p.mind == Person.Mind.DUTY:
		var reach := DOOR_REACH + ThornwallFx.SEG if _door_overgrown() else DOOR_REACH
		if _near_house(p.ground_pos, DOOR_REACH) or p.ground_pos.distance_to(door) <= reach:
			return true
	if p.mind == Person.Mind.OBSERVE and _looks_at_brambles(p):
		return false
	return super(p)


## D33: `p` is looking at a bramble segment (Crowd.THORN_LOOK makes calm people by a new wall stop and look at its segments' centres).
func _looks_at_brambles(p: Person) -> bool:
	if p._threat == Vector2.INF or crowd == null or crowd._env == null:
		return false
	for s in crowd._env.near(p._threat, 0.5):
		if s.role == &"thorns" and s.center().distance_to(p._threat) < 0.05:
			return true
	for at: Variant in _thorn_spots.values():
		if (at as Vector2).distance_to(p._threat) < 0.05:
			return true
	return false


## D33: a bramble segment stands on the door itself (a Thornwall clicked on it): its rect, grown by a person's reach, holds the door.
func _door_overgrown() -> bool:
	for s in _hiding():
		if s.footprint.grow(Person.GOAL_REACH).has_point(door):
			return true
	return false


## F3 Thornwall blocks sight: a Faithful whose straight line to `at` crosses a bramble segment does not see it; F3b: brambles by the well
## (door_hidden()) hide its door from every side. F5: while the bell lies ALL IS WELL (Crowd.is_bell_lying()) no Faithful sees anything to
## report -- they have gone home, or are going.
func _sees(f: Variant, at: Vector2, reach: float, exclude: Variant) -> bool:
	if crowd.is_bell_lying() or not super(f, at, reach, exclude):
		return false
	if at.distance_to(door) < 0.05 and (_hush or door_hidden()):
		return false
	return not _thorned((f as Person).ground_pos, at)


## F3b: one who goes down while brambles hide the door is hidden for his whole prayer.
func _entered(p: Person) -> void:
	if door_hidden():
		_hidden_prayers[p] = true
	super(p)


## F3b: one who went down hidden comes up hidden -- nobody sees the door as he does.
func _exit(p: Person) -> void:
	_hush = _hidden_prayers.has(p)
	_hidden_prayers.erase(p)
	super(p)
	_hush = false


## F3b: the bramble segments (role `thorns`) standing within THORN_HIDE of the shrine's door.
func _hiding() -> Array[Structure]:
	var out: Array[Structure] = []
	if crowd == null or crowd._env == null or door == Vector2.INF:
		return out
	for s in crowd._env.near(door, THORN_HIDE + 1.0):
		if s.role == &"thorns" and not s.destroyed and s.footprint.grow(THORN_HIDE).has_point(door):
			out.append(s)
	return out


## F3b: brambles stand by the well, and nobody sees its door.
func door_hidden() -> bool:
	return not _hiding().is_empty()


## F3b: the seconds the brambles by the door still hide it (a Thornwall withers ThornwallFx.THORN_TIME after it grows; the youngest segment
## counts); 0 when none stands there.
func hidden_left() -> float:
	var most := 0.0
	for s in _hiding():
		most = maxf(most, ThornwallFx.THORN_TIME - (_t - float(_brambles.get(s.get_instance_id(), _t))))
	return maxf(most, 0.0)


## F3b: notes when each bramble by the door grew (for its countdown), and says so when the door is first hidden; D33: notes where every bramble
## near the shrine stands.
func _bramble_step() -> void:
	if crowd != null and crowd._env != null and door != Vector2.INF:
		for s in crowd._env.near(door, THORN_HIDE + Crowd.THORN_LOOK + LURE_REACH):
			if s.role == &"thorns" and not _thorn_spots.has(s.get_instance_id()):
				_thorn_spots[s.get_instance_id()] = s.center()
	var now_hidden := false
	for s in _hiding():
		now_hidden = true
		if not _brambles.has(s.get_instance_id()):
			_brambles[s.get_instance_id()] = _t
	if now_hidden and not _hid and not burning and not roof_fallen:
		rules.banner.emit("BRAMBLES HIDE THE WELL")
	_hid = now_hidden


## A Thornwall segment (role `thorns`) stands on the straight line from `a` to `b`.
func _thorned(a: Vector2, b: Vector2) -> bool:
	if crowd == null or crowd._env == null:
		return false
	for s in crowd._env.near((a + b) * 0.5, a.distance_to(b) * 0.5 + 1.0):
		if s.role == &"thorns" and not s.destroyed and _segment_hits(a, b, s.footprint):
			return true
	return false


## The segment a-b crosses the rect (slab test).
static func _segment_hits(a: Vector2, b: Vector2, r: Rect2) -> bool:
	var lo := 0.0
	var hi := 1.0
	var d := b - a
	for axis in 2:
		var o := a[axis]
		var dd := d[axis]
		var mn := r.position[axis]
		var mx := r.end[axis]
		if absf(dd) < 0.00001:
			if o < mn or o > mx:
				return false
			continue
		var t0 := (mn - o) / dd
		var t1 := (mx - o) / dd
		lo = maxf(lo, minf(t0, t1))
		hi = minf(hi, maxf(t0, t1))
		if lo > hi:
			return false
	return true


## The tags (god T1R): Mira's, with the walking poor (the walker, and those hurrying with him, D34) named and pointed at from the edge, and the door hidden by brambles counting down (F3b).
func tags() -> Array[MapTag]:
	var out := super()
	if door_hidden() and not burning and not roof_fallen:
		for i in out.size():
			if out[i].at == door and out[i].label == "DOOR - CLEAR":
				out[i] = MapTag.place(door, MARK_CLEAR, "DOOR - HIDDEN %d" % ceili(hidden_left()), 0.0, false)
				break
	var going: Array[Person] = _hurrying.duplicate()
	if _alive(walker):
		going.append(walker)
	for w in going:
		if not _alive(w) or w.inside:
			continue
		for i in out.size():
			if out[i].at == w.ground_pos and out[i].label == "":
				out[i] = MapTag.person(w.ground_pos, MARK_GRIEVING, "POOR - TO THE SHRINE", true)
				break
	return out


## The hint's phase (v0.11 M2): "watched" while a Faithful watches the shrine's door, else "".
func hint_phase() -> String:
	return "watched" if faithful_seeing(door, SIGHT) != null else ""


## The tour (v0.11 M2, spec §4): the shrine, the first of the poor still standing, the Temple.
func tour() -> Array:
	var out := []
	if door != Vector2.INF:
		out.append([door, "The old well shrine, by the market. The poor come here to pray."])
	for p: Variant in grieving:
		if _alive(p):
			out.append([(p as Person).ground_pos, "The poor of the %s. Three must pray at the well." % poor_quarter])
			break
	if temple_door != Vector2.INF:
		out.append([temple_door, "The Temple. A Faithful who sees you runs here."])
	return out
