class_name RelicRunDirector
extends VigilFlameDirector
## The Relic Run (v0.11 M5, Tier 4, mission spec §4; Steal, reused): the Temple's relic rides to the Citadel. Its cart is its carter
## (a resident) and two escorts walking a VigilRoute at CART_PACE from the Temple's door at SET_OUT_AT, by ROUTE, to the Citadel's gate;
## a dead driver's reins pass to an escort, and with all three dead the cart stands until new hands come from the Temple RELIEF_AFTER
## later (plan decision 196). At each checkpoint (the east and west watch-houses, HALT_LEGS) it halts (VigilRoute.busy, plan decision
## 194) for the watch's count: COUNT seconds with one of the watch (the checkpoint's wardens or the escorts) at the cart and not held,
## HALT_MAX at most; its reliquary opens only then. The cart is watched while a Faithful not held stands within WATCH of it (the
## escorts and wardens are Faithful; the carter is not). Pip, a lay citizen east of the market from the start, holds where a whisper
## leaves him; within CART_REACH of a halted cart unwatched BOARD seconds in a row he slips aboard, hidden; aboard he picks the lock
## (LOCK seconds, rolling or unwatched at a halt); at the second halt, SWAP seconds unwatched in all, he swaps the relic and slips out
## (plan decision 192), unseen by rule -- no report. Then he carries it at PIP_PACE to your believers' house (the dwelling nearest
## DROP_SPOT) under The Vigil Flame's Searchlight. The relic at the Citadel's gate loses ("relic_kept"), so does Pip dead or gone
## ("pip") or the Gaze. Two wardens at each watch-house, Faithful watchmen: one off his post walks back RETURN_AFTER after he left (at
## once when the town begins to evacuate), a fallen one is replaced RELIEF_AFTER later (RELIEFS at most). Everyone the run holds is
## kept by MissionDirector._hold_all() each look. A seen death sends a Faithful to the Temple (plan decision 195); a report delivered
## fills the Gaze; the bell's toll adds LanternWatch.GAZE_TOLL to it and turns the Lantern (v0.11.2; it used to fill it), and the hint warns of
## it before it is called (plan decisions 191-199, the controller's rulings). v0.11.2: the night's schedule runs on mission time (D20) -- the
## set-out (the timeline), the halt's seconds (halt_time, counted) and _clock follow Rules.clock_rate; the walks, Pip's lock and swap, the
## wardens' returns and reliefs and every look stay real.
## Structure.destroy() ignores damage filters; nothing here filters damage.

## One warden's post (v0.11 M5): a plain record, so the director holds no cycle.
class Warden:
	extends RefCounted
	## The warden, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade (v0.11 M5).
	var man: Variant = null
	## Where he stands; his checkpoint (0 east, 1 west) and his place at the count (0 or 1) (v0.11 M5).
	var post := Vector2.INF
	var checkpoint := 0
	var slot := 0
	## Seconds since he was last at his place (alive), and since he fell; he is a relief walking in (v0.11 M5).
	var away := 0.0
	var fallen := 0.0
	var relief := false


## The cart's route from the Temple's door (v0.11 M5, Decision 151): east along the cathedral street, south, west, north, to the
## Citadel's lane and its gate; the legs at which it halts (the east and west watch-houses), and their names.
const ROUTE := [Vector2(9.5, -5.1), Vector2(9.5, 9.0), Vector2(-6.0, 9.0), Vector2(-6.0, -5.1), Vector2(-10.5, -5.1), Vector2(-10.5, -7.6)]
const HALT_LEGS := [0, 2]
const CHECK_WORDS := ["the east watch-house", "the west watch-house"]
## Your believers' house is the dwelling nearest DROP_SPOT; Pip is the lay citizen nearest PIP_SPOT (v0.11 M5).
const DROP_SPOT := Vector2(12.5, -12.0)
const PIP_SPOT := Vector2(6.0, 2.5)
## Mission spec §4's numbers (v0.11 M5), tuned by the gate in this order: the drop-off's point (25-30 units from the second halt),
## CART_PACE (0.35-0.5), COUNT (15-25), SET_OUT_AT (25-45); HALT_MAX stays under 60. The set-out; the cart's pace; the count and the
## halt's limit; boarding, the lock and the swap; how near the cart Pip must be and the watch sees; Pip's pace with the relic; the
## cart's people and the wardens; return and relief; the Faithful.
const SET_OUT_AT := 45.0
const CART_PACE := 0.42
const COUNT := 25.0
const HALT_MAX := 50.0
## The first halt a led Pip rides out when its watch is drawn off (v0.11.1).
const LED_HALT := 18.0
const BOARD := 2.0
const LOCK := 8.0
const SWAP := 4.0
const CART_REACH := 1.0
const WATCH := 2.0
const PIP_PACE := 0.5
const ESCORTS := 2
const WARDENS := 2
const WARDEN_GAP := 2.6
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const FAITHFUL_LAY := 12
## How far from the cart the wardens stand at the count; how near his place a warden is at it; how near the Citadel's gate the cart has
## it (v0.11 M5).
const COUNT_OFF := 1.0
const POST_REACH := 1.5
const CITADEL_REACH := 1.0
## How far from the cart Pip may stand and slip aboard while a Wisp's light draws him (v0.11.1): the ring the drawn stand in round a light by the cart.
const LURE_BOARD_R := WillOWisp.RING.y + Person.GOAL_REACH
## How long the bell's warning shows after a seen death raised the Gaze (v0.11 M5, the controller's ruling: before the bell is called).
const SEEN_SHOW := 8.0
## Where the camera rests (v0.11 M5, Decision 159, checked against the real HUD stack): the Temple's door above the centre, the east
## watch-house at the right, Pip below.
const CART_CAMERA := Vector2(4.0, -3.0)
## The tags' colours (v0.11 M5, mission spec §0): the cart gold, Pip steel blue, places orange.
const MARK_CART := Color("d8b23a")
const MARK_PIP := Color("8fb8e8")
const MARK_PLACE := Color("ff9a3a")

## The route on walkable ground, and its checkpoints (v0.11 M5).
var route := PackedVector2Array()
var checkpoints: Array[Vector2] = []
## Your believers' house (v0.11 M5); its door is `shrine`.
var drop_house: Structure
## The cart's carter and escorts now (Variants: any may be freed), and the wardens (v0.11 M5).
var carter: Variant = null
var escorts: Array = []
var wardens: Array = []
## It has set out; the checkpoint it halts at (-1 rolling); each halt done; the halt's seconds and the count's (v0.11 M5).
var set_out := false
var halt := -1
var halts_done: Array[bool] = [false, false]
var halt_time := 0.0
var counted := 0.0
## Pip is aboard; the lock's seconds left; the swap's seconds so far; the cart unwatched this long at a halt (v0.11 M5).
var aboard := false
var lock_left := LOCK
var swap_spent := 0.0
## Pip has been taken by the god's light or oath (v0.11.1, R6): from then the cart's watch -- its escorts and wardens -- answers a Will-o'-Wisp
## as a curious crowd does, and stares at the light away from the cart. Never set where he is led by a whisper, so no loadout A meets it.
var pip_led := false
var unwatched_for := 0.0
## The cart stands, its people dead; seconds to new hands; the new hands walking to it (the carter first); reliefs come (v0.11 M5).
var stalled := false
var stall_left := 0.0
var hands: Array = []
var reliefs := 0
## The route's leg the cart's VigilRoute starts from (a new one, after a stall, walks the rest) (v0.11 M5).
var _leg_base := 0
## Where deaths fell, to be judged once the cast's victims have fallen (v0.11 M5).
var _falls: Array[Vector2] = []
## Mission seconds into the night (v0.11.2: the clock's rate speeds it), and real seconds to the next look (v0.11 M5).
var _clock := 0.0
var _look_in := 0.0
## Seconds left of the bell's warning since a seen death last raised the Gaze (v0.11 M5).
var _seen_left := 0.0


## The night's setup (v0.11 M5, in place of The Vigil Flame's): the Gaze, the Temple's door, the Searchlight (asleep), the route and its
## checkpoints, your believers' house, the people, the signals, the strip (the set-out, the light's search).
func _begin() -> void:
	gaze = VigilFlameDirector.FlameGaze.new()
	temple_door = _walkable(Vector2(Places.rect(&"temple").get_center().x, Places.rect(&"temple").end.y + 0.6))
	searchlight = Searchlight.new().setup(Places.at(&"temple"))
	for p: Vector2 in ROUTE:
		route.append(_walkable(p))
	for k: int in HALT_LEGS:
		checkpoints.append(route[k])
	drop_house = _house_near(DROP_SPOT)
	var door := _open_door(drop_house, checkpoints[checkpoints.size() - 1]) if drop_house != null else Vector2.INF
	shrine = door if door != Vector2.INF else (_front_of(drop_house) if drop_house != null else _walkable(DROP_SPOT))
	_choose_people()
	_lantern = (carter as Person).ground_pos if _alive(carter) else temple_door
	crowd._field.enemy_killed.connect(_on_killed)
	_listen()
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	timeline.add(SET_OUT_AT, "set_out", "The relic sets out", _set_out_cart)
	_add_events()
	rules.banner.emit("THE RELIC RUN")


## The people (v0.11 M5): Pip, set down on duty; the carter (the resident nearest the Temple's door) and two escorts at it; two wardens
## at each checkpoint; then every cleric and FAITHFUL_LAY of the rest are Faithful (never Pip or the carter).
func _choose_people() -> void:
	var taken: Array = []
	var pip := _lay_near(_walkable(PIP_SPOT), 1, taken)
	if pip.is_empty():
		no_wren = true
	else:
		wren = pip[0]
		taken.append(wren)
		_set_down(wren, _walkable(PIP_SPOT))
		wren.go_duty(wren.ground_pos)
		appeared = true
	var c := _citizen_near(temple_door, CitizenProfile.Role.RESIDENT, taken)
	if c == null:
		var any := _lay_near(temple_door, 1, taken)
		c = any[0] if not any.is_empty() else null
	if c != null:
		carter = c
		taken.append(c)
		_set_down(c, temple_door)
		c.go_duty(temple_door)
	for k in ESCORTS:
		var near := _lay_near(temple_door, 1, taken)
		if near.is_empty():
			break
		var e := near[0]
		_make_watch(e)
		taken.append(e)
		escorts.append(e)
		var spot := _walkable(temple_door + (VigilRoute.ACOLYTE_OFFSETS[k % 2] as Vector2))
		_set_down(e, spot)
		e.go_duty(spot)
	for k in checkpoints.size():
		for j in WARDENS:
			var w := Warden.new()
			w.checkpoint = k
			w.slot = j
			w.post = _walkable(checkpoints[k] + Vector2(WARDEN_GAP * (float(j) - 0.5), 0.0))
			var near := _lay_near(w.post, 1, taken)
			if not near.is_empty():
				var p := near[0]
				_make_watch(p)
				taken.append(p)
				w.man = p
				_set_down(p, w.post)
				p.go_duty(w.post)
			wardens.append(w)
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in clergy:
		if not faithful.has(p):
			_make_faithful(p)
	var rest: Array[Person] = []
	for p in lay:
		if p.profile.faith == CitizenProfile.Faith.NONE and not p.profile.role in Wish.NOT_LAY and not taken.has(p):
			rest.append(p)
	_spread_faithful(rest, FAITHFUL_LAY)


## `p` made one of the watch (v0.11 M5): a watchman (the cloak and lantern) and one of Halcyon's Faithful.
func _make_watch(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN
	_make_faithful(p)


## Everyone at the run's work (v0.11 M5), for a new one to leave out and for the one hold rule. Untyped: any may be freed.
func _busy() -> Array:
	var out: Array = [wren, carter]
	out.append_array(escorts)
	out.append_array(hands)
	for w: Warden in wardens:
		out.append(w.man)
	return out


## Everyone at the run's work is busy (v0.11.2): the Lantern-Bearer and his escorts are never picked from Pip, the cart's people, the new
## hands or the wardens.
func busy(p: Person) -> bool:
	return _busy().has(p)


## The relic sets out (v0.11 M5, the timeline's event): the cart walks the route.
func _set_out_cart() -> void:
	if set_out:
		return
	set_out = true
	_start_route(route, carter, escorts)


## A VigilRoute for the cart along `points` (v0.11 M5): `bearer` the carter, `helpers` his escorts; the reins pass on a death; the
## halts ride on its busy callable (_cart_busy()); its walkers at CART_PACE, the carter keeping beside his escorts (_pace_bearer()).
func _start_route(points: PackedVector2Array, bearer: Variant, helpers: Array) -> void:
	if not _alive(bearer):
		return
	var by: Array[Person] = []
	for v: Variant in helpers:
		if _alive(v):
			by.append(v as Person)
	vigil = VigilRoute.new().setup(points, bearer as Person, by)
	vigil.pass_flame = true
	vigil.busy = _cart_busy
	vigil.flame_passed.connect(_on_reins)
	for p in vigil.walkers():
		_walk_pace[p] = p.pace
		p.pace *= CART_PACE
	_pace_bearer()
	vigil.start()


## The reins passed to an escort (v0.11 M5): the new carter keeps beside the one left.
func _on_reins(_to: Person) -> void:
	_pace_bearer()
	if not swapped:
		rules.banner.emit("AN ESCORT TAKES THE REINS")


## VigilRoute.busy for the cart (v0.11 M5, plan decision 194): a walker carrying a report; the carter while the cart halts or stands at
## the next checkpoint's point -- the walk waits for him.
func _cart_busy(p: Person) -> bool:
	if _carrying(p) or (p.mind == Person.Mind.OBSERVE and p.held_by_god()):
		return true  # (v0.11.1) one drawn to a Wisp's light is left to it: the walk does not call him back
	return vigil != null and p == vigil.bearer and (halt >= 0 or _at_checkpoint())


## The cart stands at the next checkpoint's point (v0.11 M5): its leg is that checkpoint's, its carter within VigilRoute.ARRIVE of it.
func _at_checkpoint() -> bool:
	var k := next_halt()
	if k < 0 or vigil == null or not vigil.active or not _alive(vigil.bearer):
		return false
	var leg := _leg_base + vigil.leg
	return leg == int(HALT_LEGS[k]) and vigil.bearer.ground_pos.distance_to(route[leg]) <= VigilRoute.ARRIVE


## The next checkpoint not yet passed, or -1 (v0.11 M5).
func next_halt() -> int:
	for k in halts_done.size():
		if not halts_done[k]:
			return k
	return -1


## Where the cart (and the relic) is (v0.11 M5). Only reads.
func cart_at() -> Vector2:
	return _lantern


## One step (v0.11 M5, plan decision 191, in place of The Vigil Flame's): the strip and the Gaze (a seen death's rise shows the bell's
## warning); every TICK the one hold rule; the cart and its halts; the seen deaths; the reports; the swap; Pip; the wardens; phase 2;
## the bell.
func step(delta: float) -> void:
	var mission_dt := mission_delta(delta)
	_clock += mission_dt
	timeline.step(delta)
	var was := gaze.value
	gaze.judge_deaths(crowd)
	_seen_left = SEEN_SHOW if gaze.value > was else maxf(_seen_left - delta, 0.0)
	_look_in -= delta
	var looking := _look_in <= 0.0
	var evacuating := false
	if looking:
		_look_in = TICK
		evacuating = _evacuation_began()
		_watch_answers()
		_hold_all(_busy(), evacuating)  # the one rule (the controller's ruling): Pip, the cart's people, the new hands, the wardens
	_cart_step(delta, mission_dt)
	if not _falls.is_empty() and crowd._doomed.is_empty():
		_judge_falls()
	_step_reports(delta)
	if not swapped:
		_home_check()
		_swap_step(delta)
	_wren_step(delta)
	_wardens_step(delta, looking, evacuating)
	_phase2_step(delta)


## The cart (v0.11 M5): its walk, the relic with its carter -- halted, the cart stands where it stopped, whatever its carter does (a
## carter held by the god wanders; the cart does not); all three dead, it stands (and waits for new hands); at the next checkpoint it
## halts; a halt ends once the count is done or after HALT_MAX (both counted in mission seconds, `mission_dt`: dawn hastens the watch's count too).
func _cart_step(delta: float, mission_dt: float) -> void:
	if vigil != null:
		vigil.step(delta)
		if vigil.active and _alive(vigil.bearer) and halt < 0:
			_lantern = vigil.bearer.ground_pos
		elif not vigil.active and vigil.walkers().is_empty() and not stalled and not kept:
			stalled = true
			stall_left = RELIEF_AFTER
			_leg_base += vigil.leg
			vigil = null
			rules.banner.emit("THE CART STANDS")
	if stalled:
		_stall_step(delta)
	if halt < 0:
		var k := next_halt()
		if k >= 0 and _at_checkpoint():
			_begin_halt(k)
		return
	halt_time += mission_dt
	if _count_ok():
		counted += mission_dt
	if counted >= COUNT or halt_time >= HALT_MAX or (_led_roll() and halt_time >= LED_HALT):
		_end_halt()


## The first halt is not stood out to HALT_MAX (v0.11.1, R6, R8): with Pip aboard and led by the god's light or oath (pip_led), and the cart
## left unwatched (the watch drawn off or bound), the carter rolls on LED_HALT seconds in -- the cart's tag counts that down (_halt_left()).
## Never where Pip was only whispered: no loadout A is led.
func _led_roll() -> bool:
	return pip_led and aboard and halt == 0 and not watched()


## Seconds the halt has left to run at most (v0.11.1, R8): the tag's count -- HALT_MAX, or LED_HALT when the led-Pip roll-on rule holds.
func _halt_left() -> float:
	return maxf((LED_HALT if _led_roll() else HALT_MAX) - halt_time, 0.0)


## A stalled cart (v0.11 M5, plan decision 196): RELIEF_AFTER after it stood, new hands; at the cart, they take it on.
func _stall_step(delta: float) -> void:
	if hands.is_empty():
		stall_left -= delta
		if stall_left <= 0.0:
			_new_hands()
		return
	if not _alive(hands[0]):
		hands = hands.filter(func(v: Variant) -> bool: return _alive(v))
		if hands.is_empty():
			stall_left = RELIEF_AFTER
		return
	var lead := hands[0] as Person
	if lead.ground_pos.distance_to(_lantern) <= VigilRoute.ARRIVE + 0.3:
		stalled = false
		var rest: Array = hands.slice(1)
		hands = []
		_start_route(route.slice(_leg_base), lead, rest)
	elif lead.mind in RESUMABLE:
		lead.go_duty(_lantern)


## New hands for the cart (v0.11 M5, the controller's ruling: The Crown's Bread's _relieve): the resident nearest the Temple's door
## (else a lay citizen) and two lay escorts, made Faithful watchmen, walking on duty to the cart. Each chosen once the town is running is
## stopped from the flight first; with no one to send, the search backs off and is tried again RELIEF_AFTER later.
func _new_hands() -> void:
	var busy := _busy()
	var lead := _citizen_near(temple_door, CitizenProfile.Role.RESIDENT, busy)
	if lead == null:
		var any := _lay_near(temple_door, 1, busy)
		lead = any[0] if not any.is_empty() else null
	if lead == null:
		stall_left = RELIEF_AFTER
		return
	hands = [lead]
	_to_duty(lead, _lantern)
	for k in ESCORTS:
		var near := _lay_near(temple_door, 1, busy + hands)
		if near.is_empty():
			break
		_make_watch(near[0])
		hands.append(near[0])
		_to_duty(near[0], _walkable(_lantern + (VigilRoute.ACOLYTE_OFFSETS[k % 2] as Vector2)))
	carter = lead
	escorts = hands.slice(1)
	rules.banner.emit("NEW HANDS COME FROM THE TEMPLE")


## `p`, newly put to the run's work, on duty to `at` (v0.11 M5, The Crown's Bread's _relieve): one chosen once the town is running is
## stopped from the flight first -- Person.go_duty() refuses a fleeing man, and he would run on to the gates.
func _to_duty(p: Person, at: Vector2) -> void:
	if crowd._fled_all:
		_keep_from_flight(p, true)
	p.go_duty(at)


## The cart's watch answers a Will-o'-Wisp once Pip has been led by the god's light or oath (v0.11.1, R6), from its whole reach.
func _watch_answers() -> void:
	var watch: Array = escorts.duplicate()
	for w: Warden in wardens:
		watch.append(w.man)
	for v: Variant in watch:
		if _alive(v):
			(v as Person).answers_lure = pip_led
			(v as Person).lure_reach = WillOWisp.LURE_REACH


## The cart halts at checkpoint `k` (v0.11 M5): the reliquary opens for the count; that checkpoint's wardens step up to the cart.
func _begin_halt(k: int) -> void:
	halt = k
	halt_time = 0.0
	counted = 0.0
	unwatched_for = 0.0
	rules.banner.emit("THE CART HALTS AT %s" % String(CHECK_WORDS[k]).to_upper())
	for w: Warden in wardens:
		if w.checkpoint == k and _alive(w.man) and not (w.man as Person).inside:
			(w.man as Person).go_duty(_count_spot(w))


## Warden `w`'s place at the count (v0.11 M5): COUNT_OFF from the cart, his slot's side.
func _count_spot(w: Warden) -> Vector2:
	return _ring_spot(_lantern, COUNT_OFF, w.slot, WARDENS, 0.5)


## The halt ends (v0.11 M5): the reliquary closes, the wardens go back to their posts, and the cart rolls on; a swap not finished
## is no longer under way (the final review: the HUD would show it on).
func _end_halt() -> void:
	var k := halt
	halts_done[k] = true
	halt = -1
	swapping = false
	for w: Warden in wardens:
		if w.checkpoint == k:
			_recall_to(w.man, w.post)
	rules.banner.emit("THE CART ROLLS ON")


## The count runs (v0.11 M5): one of the watch -- the halt's wardens or the escorts -- alive, out of doors, not held, within WATCH of the
## cart.
func _count_ok() -> bool:
	var watch: Array = escorts.duplicate()
	for w: Warden in wardens:
		if w.checkpoint == halt:
			watch.append(w.man)
	for v: Variant in watch:
		if _alive(v):
			var p := v as Person
			if not p.inside and not p.mind in BLIND and p.ground_pos.distance_to(_lantern) <= WATCH:
				return true
	return false


## A Faithful bound by an oath keeps his mind on it (v0.11.1, R6): Oathbound's hold-a-place binds him by WILL (Person.Mind.COMPELLED), and
## he neither watches the cart nor sees a fall. Only this night asks it; no loadout A casts Oathbound.
func _sees(f: Variant, at: Vector2, reach: float, exclude: Variant) -> bool:
	return super(f, at, reach, exclude) and (f as Person).mind != Person.Mind.COMPELLED


## The cart is watched now (v0.11 M5, plan decision 193): a Faithful not held within WATCH of it. Only reads.
func watched() -> bool:
	return faithful_seeing(_lantern, WATCH) != null


## Every Faithful watching the cart now (v0.11 M5, for the policy and the tags). Only reads.
func watchers_now() -> Array[Person]:
	return watchers(_lantern, WATCH)


## Checkpoint `k`'s living wardens out of doors (v0.11 M5). Only reads.
func wardens_at(k: int) -> Array[Person]:
	var out: Array[Person] = []
	for w: Warden in wardens:
		if w.checkpoint == k and _alive(w.man) and not (w.man as Person).inside:
			out.append(w.man as Person)
	return out


## The heist at a halt, in place of the base's swap (v0.11 M5, plan decision 192): rolling, Pip aboard picks the lock; halted, Pip
## within CART_REACH boards after BOARD seconds unwatched in a row; aboard, the lock goes on while unwatched; at the last halt, the lock
## open, SWAP seconds unwatched in all swap the relic.
func _swap_step(delta: float) -> void:
	if not _alive(wren):
		return
	if halt < 0:
		unwatched_for = 0.0
		if aboard and vigil != null and vigil.active:
			lock_left = maxf(lock_left - delta, 0.0)
		return
	var seen := watched()
	unwatched_for = 0.0 if seen else unwatched_for + delta
	if not aboard:
		if not wren.inside and _by_the_cart() and unwatched_for >= BOARD:
			_board()
		return
	if seen:
		return
	if lock_left > 0.0:
		lock_left = maxf(lock_left - delta, 0.0)
		return
	if halt != HALT_LEGS.size() - 1:
		return
	swapping = true
	swap_spent += delta
	swap_left = maxf(SWAP - swap_spent, 0.0)
	if swap_spent >= SWAP:
		_take_relic()


## Pip is near enough the halted cart to slip aboard (v0.11.1, spec §7.3): within CART_REACH of it; or staring at a Will-o'-Wisp's light by it
## -- a lure is the god's hand as a whisper is -- anywhere on the ring the drawn stand in round the light (LURE_BOARD_R, as Mira's LURE_REACH).
func _by_the_cart() -> bool:
	if wren.ground_pos.distance_to(_lantern) <= CART_REACH:
		return true
	return wren.mind == Person.Mind.OBSERVE and wren.held_by_god() and wren._threat.distance_to(_lantern) <= LURE_BOARD_R \
			and wren.ground_pos.distance_to(_lantern) <= LURE_BOARD_R


## Pip slips aboard (v0.11 M5): on duty where he stands, then hidden in the cart's straw, carried with it (MissionDirector._ride_in()).
func _board() -> void:
	aboard = true
	_ride_in(wren)
	rules.banner.emit("PIP SLIPS ABOARD")


## The relic swapped (v0.11 M5, plan decision 191): Pip slips out at the cart's side with it, unseen by rule (no report), and makes for
## your believers' house at PIP_PACE; the spire flares and the Searchlight wakes.
func _take_relic() -> void:
	swapping = false
	swapped = true
	aboard = false
	_ride_out(wren, _walkable(_lantern + Vector2(0.0, 0.8)))
	rules.banner.emit("THE RELIC IS TAKEN")
	wren.pace *= PIP_PACE
	wren.go_duty(shrine)
	_phase2_begin()


## The relic reaches the Citadel's gate with its cart (v0.11 M5, in place of the Temple): kept, and the night is lost.
func _home_check() -> void:
	if vigil == null or not _alive(vigil.bearer) or route.is_empty():
		return
	if vigil.bearer.ground_pos.distance_to(route[route.size() - 1]) <= CITADEL_REACH:
		kept = true


## Pip's errand, every frame (v0.11 M5, in place of Wren's): aboard he rides with the cart; with the relic at your believers' door it is
## home; back on his feet he holds where he stands, or, with the relic, walks on to the house. A whisper is the god's: he is left to it.
func _wren_step(_delta: float) -> void:
	if not appeared or not _alive(wren) or home:
		return
	wren.answers_lure = _pip_answers()
	if not pip_led and (wren.mind == Person.Mind.COMPELLED or (wren.mind == Person.Mind.OBSERVE and wren.held_by_god())):
		pip_led = true
		rules.banner.emit("PIP FOLLOWS THE GOD - THE WATCH WILL FOLLOW A WISP")  # (R8) the rule is told when it begins; the hint says it too
	if aboard:
		_ride_step(wren, _lantern)
		return
	if swapped and not wren.inside and wren.ground_pos.distance_to(shrine) <= SHRINE_REACH:
		_relic_home()
		return
	if wren.inside or not (wren.mind == Person.Mind.DUTY or wren.mind in RESUMABLE):
		return
	if wren.mind == Person.Mind.OBSERVE and wren.held_by_god():
		if not swapped:
			wren.anchor = wren.ground_pos  # (v0.11.1) drawn by a Wisp: the god's hand, left be; he holds where the lure leaves him
		return
	var goal := _wren_goal()
	if wren.mind != Person.Mind.DUTY or wren.anchor.distance_to(goal) > 0.3:
		wren.go_duty(goal)


## Pip answers a Will-o'-Wisp's lure now (v0.11.1, spec §7.3, Decision 28; ruling R1/I10): not aboard (inside, nothing draws him), and not by the
## halted cart (within WillOWisp.CHARGE_LURE_R of it) -- a Wisp cast beyond it for the passers-by never pulls him off the cart; one drawn from
## afar to a light by the cart is already his lure. With the relic he answers again.
func _pip_answers() -> bool:
	if aboard:
		return false
	return swapped or not (halt >= 0 and wren.ground_pos.distance_to(_lantern) <= WillOWisp.CHARGE_LURE_R)


## Where Pip makes for (v0.11 M5): your believers' house with the relic; else where he stands (he holds where a whisper left him).
func _wren_goal() -> Vector2:
	if swapped:
		return shrine
	return wren.anchor if wren.mind == Person.Mind.DUTY else wren.ground_pos


## The relic home (v0.11 M5): the win (its banner its own, the results title being "THE RELIC IS OURS"), and the light dies.
func _relic_home() -> void:
	home = true
	rules.banner.emit("YOUR BELIEVERS HAVE THE RELIC")
	if wren.mind == Person.Mind.DUTY:
		wren.leave_shelter(false)
	_phase2_end()


## The wardens at their work (v0.11 M5): at his place -- his post, or by the cart while it halts at his checkpoint -- kept on duty; away,
## sent back RETURN_AFTER after he left, or at once at the first look after the town began to evacuate (`evacuating`, the controller's
## ruling; a relief walks on at once); fallen, replaced RELIEF_AFTER later (RELIEFS at most).
func _wardens_step(delta: float, looking: bool, evacuating := false) -> void:
	for w: Warden in wardens:
		var at := _count_spot(w) if halt == w.checkpoint else w.post
		if not _alive(w.man):
			w.fallen += delta
			if looking and w.fallen >= RELIEF_AFTER and reliefs < RELIEFS:
				_relieve(w, at)
			continue
		w.fallen = 0.0
		var p := w.man as Person
		if p.inside:
			continue
		if not p.mind in BLIND and p.ground_pos.distance_to(at) <= POST_REACH:
			w.away = 0.0
			w.relief = false
			if looking and p.mind != Person.Mind.DUTY and not (p.mind == Person.Mind.OBSERVE and p.held_by_god()):
				_recall_to(p, at, evacuating)
		else:
			w.away += delta
			if looking and (w.relief or w.away >= RETURN_AFTER or evacuating):
				_recall_to(p, at, evacuating)


## A relief for fallen warden `w` (v0.11 M5, the controller's ruling: The Crown's Bread's _relieve): the nearest lay citizen with a way
## to his post (M4's _lay_reaching()), made one of the watch, walking on duty to `at` -- stopped from the flight first when the town is
## running. With none who can reach the post, the search backs off and is tried again RELIEF_AFTER later.
func _relieve(w: Warden, at: Vector2) -> void:
	var p := _lay_reaching(w.post, _busy())
	if p == null:
		w.fallen = 0.0
		return
	_make_watch(p)
	w.man = p
	w.fallen = 0.0
	w.away = 0.0
	w.relief = true
	reliefs += 1
	_to_duty(p, at)
	rules.banner.emit("A NEW WARDEN TAKES THE WATCH-HOUSE")


## A death (v0.11 M5): The Vigil Flame's (the Gaze's note, the reports' relay, the light's noise), and its fall kept to be judged.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	super(e, kind)
	_falls.append(e.ground_pos)


## The deaths judged (v0.11 M5, plan decision 195): at each fall a Faithful not held within Crowd.DOOM_WITNESS runs to the Temple.
func _judge_falls() -> void:
	for at in _falls:
		var seer := faithful_seeing(at, Crowd.DOOM_WITNESS)
		if seer != null:
			_report(seer, temple_door)
	_falls.clear()


## A report (v0.11 M5, plan decision 190): MissionDirector's, its relay passing over the fleeing and the reserved (TempleReport.skip).
func _report(seer: Person, at: Vector2) -> void:
	var before := reports.size()
	super(seer, at)
	for i in range(before, reports.size()):
		reports[i].skip = _passed_over


## A relay never picks `p` (v0.11 M5): one fleeing the town or reserved; nor, v0.11.2 (C15), one on the Lantern's errand.
func _passed_over(p: Person) -> bool:
	return p.mind == Person.Mind.FLEE or reserved.has(p) or on_lantern_errand(p)


## Seconds until the cart halts at the next checkpoint, about (v0.11 M5, plan decision 198, for the scripted player): the route still to
## walk at its carter's duty pace, and before the set-out its time too; 0 while it halts; INF with none to come or no cart walking.
func halt_in() -> float:
	if halt >= 0:
		return 0.0
	var k := next_halt()
	if k < 0:
		return INF
	var to := int(HALT_LEGS[k])
	var speed := Person.PANIC_SPEED * CART_PACE
	if not set_out:
		var d := _lantern.distance_to(route[0])
		for i in to:
			d += route[i].distance_to(route[i + 1])
		return maxf(SET_OUT_AT - _clock, 0.0) / maxf(rules.clock_rate, 0.01) + d / speed
	if vigil == null or not vigil.active:
		return INF
	var at := _leg_base + vigil.leg
	if at > to:
		return INF
	var left := _lantern.distance_to(route[at])
	for i in range(at, to):
		left += route[i].distance_to(route[i + 1])
	return left / maxf(vigil.bearer.walk_speed if _alive(vigil.bearer) else speed, 0.05)


## The bell's keeper while he is called or climbing, else null (v0.11 M5, the controller's ruling). Only reads.
func bellkeeper() -> Person:
	var bell := crowd.bell
	if bell == null or not bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return null
	var k: Variant = bell.keeper
	return k as Person if _alive(k) and not (k as Person).inside else null


## The HUD's line (v0.11 M5, Task 1's hook): where the relic is.
func hud_line() -> String:
	if home:
		return "The relic: ours"
	if swapped:
		return "The relic to your believers: %d" % roundi(wren.ground_pos.distance_to(shrine)) if _alive(wren) else "The relic: lost"
	if swapping and swap_spent > 0.0:
		return "Swapping %d / %d s" % [floori(swap_spent), roundi(SWAP)]
	if aboard:
		return "The relic: Pip at the lock" if lock_left > 0.0 else "The relic: Pip aboard"
	return "The relic: in its cart"


## The cart's tag's words (v0.11 M5): Pip at the lock or aboard; halted, its window's seconds; else its name.
func _cart_label() -> String:
	if aboard:
		if lock_left > 0.0:
			return "RELIC CART - PIP AT THE LOCK"
		if _led_roll():
			return "RELIC CART - PIP ABOARD, ROLLS ON %d" % ceili(_halt_left())  # v0.11.1: the led roll-on counts down
		return "RELIC CART - PIP ABOARD"
	if halt >= 0:
		return "RELIC CART - HALTED %d" % ceili(_halt_left())
	return "RELIC CART"


## Pip's tag's words (v0.11 M5): "DO NOT KILL" in every state, his death loses in each (the controller's ruling) -- waiting by a watched
## halted cart, carrying the relic, else his name alone.
func _pip_label() -> String:
	if swapped:
		return "PIP - THE RELIC, DO NOT KILL"
	if halt >= 0 and wren.ground_pos.distance_to(_lantern) <= CART_REACH and watched():
		return "PIP - WAITING, DO NOT KILL"
	return "PIP - DO NOT KILL"


## The map tags, most important first (v0.11 M5, mission spec §4): the cart (until the swap) and Pip, pointed at; the next checkpoint;
## your believers' house; the Citadel from the second halt on; each report's runner and the Temple; the called bellkeeper, red and
## pointed at (the controller's ruling); ESCORT and WARDEN; a red diamond on any other Faithful watching the cart.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if not swapped and not kept and _lantern != Vector2.INF:
		out.append(MapTag.person(_lantern, MARK_CART, _cart_label(), true))
	if appeared and _alive(wren) and not wren.inside and not home:
		out.append(MapTag.person(wren.ground_pos, MARK_PIP, _pip_label(), true))
	if not swapped and next_halt() >= 0:
		out.append(MapTag.place(checkpoints[next_halt()], MARK_PLACE, "CHECKPOINT", 0.0, true))
	if not home:
		out.append(MapTag.place(shrine, MARK_PLACE, "BELIEVERS' HOUSE", 0.0, true))
	var last := HALT_LEGS.size() - 1
	if not swapped and (halt == last or halts_done[last]):
		out.append(MapTag.place(route[route.size() - 1], MARK_WATCHED, "CITADEL", 0.0, true))
	var running := false
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			out.append(MapTag.person(r.carrier.ground_pos, MARK_WATCHED, "TO THE TEMPLE", true))
			running = true
	if running:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE"))
	var keeper := bellkeeper()
	if keeper != null:
		out.append(MapTag.person(keeper.ground_pos, MARK_WATCHED, "BELLKEEPER", true))
	var named: Array = []
	for v: Variant in escorts:
		if _alive(v) and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "CART ESCORT"))  # (the Lantern-Bearer's are "ESCORT")
			named.append(v)
	for w: Warden in wardens:
		if _alive(w.man) and not (w.man as Person).inside:
			out.append(MapTag.person((w.man as Person).ground_pos, MARK_WATCHED, "WARDEN"))
			named.append(w.man)
	if not swapped:
		for f in watchers_now():
			if not named.has(f):
				out.append(MapTag.person(f.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5): "bell" while the bell is called or climbing (plan decision 197); "report" while one runs; "seen" for
## SEEN_SHOW after a seen death raised the Gaze (the bell's warning before it is called, the controller's ruling); "carry" once swapped;
## halted, "watched" while watched, else "aboard" with Pip aboard, else ""; rolling, "aboard" with Pip aboard, "citadel" once the last
## halt is passed (as the CITADEL tag shows: the final review), "last_halt" once the first is, "moving" once set out; "" before.
func hint_phase() -> String:
	if crowd.bell != null and crowd.bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return "bell"
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			return "report"
	if _seen_left > 0.0:
		return "seen"
	if swapped:
		return "carry"
	if halt >= 0:
		if watched():
			return "watched"
		return "aboard" if aboard else ""
	if aboard:
		return "aboard"
	if halts_done[HALT_LEGS.size() - 1]:
		return "citadel"
	if halts_done[0]:
		return "last_halt"
	return "moving" if set_out else ""


## The tour (v0.11 M5, mission spec §4): the cart at the Temple, Pip, your believers' house.
func tour() -> Array:
	var out := [[temple_door, "The relic cart at the Temple. It halts at two checkpoints, where its reliquary opens."]]
	if _alive(wren):
		out.append([wren.ground_pos, "Pip. Bring him to the first halt: he slips aboard there and swaps the relic at the second."])
	out.append([shrine, "Your believers' house. Pip must bring the relic here. Four seen deaths in a district call the bell."])
	return out


## What the results show (v0.11 M5): the swap, the halts passed, the Searchlight's touches, the reports, the relic home.
func report() -> Dictionary:
	var halts := 0
	for done in halts_done:
		halts += 1 if done else 0
	return {"swapped": swapped, "halts": halts, "touches": touches, "reports": reports_started, "home": home}
