class_name BreakHuntDirector
extends HuntDirector
## Break the hunt (god P5, MS §5, plan Task 7, Rulings C4, C9; Hunt 4 of the Lantern Hunts, Tier 4, the Hunt type): four standards march on three
## of the god's believers' houses. Each is carried by a standard-bearer with two escorts walking at his sides, raised at its muster at its time
## (or BH_CHAIN seconds after the standard before is broken, whichever is sooner) and marched to the nearest house the others are not going
## to. A bearer who comes within BH_TAKE_REACH of an untaken house's door plants the standard there and the house is taken; two taken houses
## lose the night. All four standards broken wins.
##
## The Hunt's own rule is that the standard is carried, not planted: there is no Structure (Ruling C4). A bearer killed or frightened (by the god
## or by the town's own panic) while no escort guards him breaks the standard; while one does, that escort takes it up and marches on as the
## bearer. An escort guards when he is alive, out of doors, within `guard_reach` of the bearer, not held by the god, not fighting, not frail and
## not afraid. A fallen escort is not replaced, so each standard grows easier. A bearer out of the walls (shared rule 1) breaks his standard
## and is walked off the map. A planted standard is still breakable and still counts for the win.
##
## It is the Hunt type with no head and no Structure, so the paths that assume one are replaced (pre-flight B4): _plan() (the musters, the
## houses), _raise(i) (appoints and marks the bearer, starts the march, never breaks the step), _raise_standard() (null, never called),
## _guarding(), _guarded(), _keep_party() (the escorts' posts move with the bearer; also the march, the take-up, the break, the plant),
## _relieve() (a no-op), _in_use(), _keep_held() (the bearers too), standard(), tags(), _found() (two taken), hint_phase(), strip_rows(),
## tour(). _shield(), _unguarded_blow(), _on_broken() and _step_of() stay as the base has them and are never reached with no Structure.
## Timers run in mission seconds (_clock advances by mission_delta()), so a Lantern night keeps the chain and the tags counting down like the
## strip. Opposition stands more than 1.6 apart (MS §0): the two escorts 1.8 apart at the bearer's sides. The director's own people are held
## through an evacuation every look (MS §0, _hold_all). Every wait is at most 45 s (the chain); no one's death loses.

## The three believers' houses as points: the dwelling nearest each whose door the street reaches from every muster is stone tonight (MS §5 *fg*).
const BH_HOUSE_POINTS := [Vector2(-4.0, 4.0), Vector2(7.0, 6.0), Vector2(-2.0, 12.5)]
## The four musters, one per side, inside the walls (MS §5 *fg*): north, west, east, south-west; their words for the banners and the strip.
const BH_MUSTERS := [Vector2(6.0, -13.5), Vector2(-14.0, 0.0), Vector2(14.0, -2.0), Vector2(-11.0, 14.0)]
const BH_MUSTER_WORDS := ["the north", "the west", "the east", "the south-west"]
## Each standard's escorts, and how far to either side of the bearer they walk (MS §5: 0.9 each, 1.8 apart).
const BH_ESCORTS := 2
const BH_ESCORT_OFF := 0.9
## When each standard is raised at the latest, in the strip's seconds: 0:20, 1:10, 2:00, 2:50 (MS §5 *fg*).
const BH_BEARER_AT := [20.0, 70.0, 120.0, 170.0]
## How long after one standard is broken the next is raised at the latest (MS §0: no wait over 60 s; the chain is 45).
const BH_CHAIN := 45.0
## The pace the bearer and his escorts all walk at, in ground units a second (MS §5 *fg*: 0.5 makes the 25-35 units of street from a muster to
## a house 50-70 s; MS §7 tunes it to 0.45): the same for all three, so the escorts keep up (Ruling P5-T7-R1: Person.pace is a share of
## Person.PANIC_SPEED, so each is set to BH_BEARER_PACE / PANIC_SPEED).
const BH_BEARER_PACE := 0.5
## How near the bearer an escort must stand to guard him (MS §5: 1.5; MS §7 tunes it to 1.2).
const BH_GUARD_REACH := 1.5
## How near a house's door a bearer plants his standard (MS §5), and how many taken houses lose the night.
const BH_TAKE_REACH := 1.0
const BH_LOSE_TAKEN := 2
## Mission seconds before a standard reaches a house at which the banner warns (MS §5: 15 s).
const BH_NEAR_WARN := 15.0
## The shortest a march may last, in mission seconds (MS §0: every instant loss warned with room to act): a standard whose street to its house
## is shorter than BH_MARCH_MIN x BH_BEARER_PACE walks slower, so its countdown first shows 50 s out (Ruling P5-T7-R3).
const BH_MARCH_MIN := 50.0
## How many dwellings are weighed for each house, and how hard a stone house shakes when struck.
const BH_HOUSE_TRIES := 12
const BH_STONE_SHAKE := 2.0
## How far, in steps, a muster is moved to reach ground the street reaches (_street_spot()).
const BH_SNAP_STEP := 0.5
const BH_SNAP_MAX := 6.0
## How many places round the bearer a flank is chosen from, and how near a spot must be to the street for a flank to stand there.
const BH_FLANK_TURNS := 12
const BH_FLANK_SNAP := 0.3
## The least two escorts stand apart (more than two Silent Doom radii, 1.6) and the furthest from the bearer one may stand and still guard.
const BH_FLANK_GAP := 1.7
const BH_FLANK_NEAR := 1.3
## The minds that are afraid (the Assassinate type's FRIGHT): a bearer in one while no escort guards him breaks his standard.
const BH_FRIGHT := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]
## The bearer's drawn pole and pennant (a badge over his head, no art): a pennant on a pole.
const BH_FLAG: Array[int] = [0b11110, 0b11100, 0b10000, 0b10000, 0b10000]
## The seconds each refresh of the pennant lasts, and how little may be left before it is refreshed.
const BH_FLAG_SECONDS := 3.0
const BH_FLAG_MIN := 1.5
## The map tags' colours: the houses blue (the Hunt type's steel blue), a taken house red.
const BH_MARK_HOUSE := Color("8fb8e8")
const BH_MARK_TAKEN := Color("c8342a")
## Banners (MS §5).
const BH_OPENING := "BREAK THE HUNT"
const BH_TAKEN_UP := "THE STANDARD IS TAKEN UP"
const BH_HOUSE_TAKEN := "A HOUSE IS TAKEN - ONE MORE AND THE HUNT IS LOST"
const BH_NEARS := "A STANDARD NEARS A HOUSE"
const BH_FOUND := "THE HUNT TAKES THEIR HOUSES"
const BH_ROW := "A standard reaches a house"
## Where the camera stands (MS §5, clear of the HUD stack): the north muster's side, its first house in view.
const BH_CAMERA_AT := Vector2(3.0, -6.0)

## The believers' houses (stone tonight), their doors, and which are taken (by house).
var houses: Array[Structure] = []
var house_doors: Array[Vector2] = []
var _taken: Array[bool] = []
## The houses' own damage filters before they were made stone, by instance id (put back at teardown()).
var _house_filters := {}
## The bearers, one per step (Variants: any may be freed; null before one is appointed or after he is gone), and every escort the night
## appointed (a Hunt's people, for the wish check and the freed-body tests).
var bearers: Array = []
var crew: Array = []
## By step: the house it marches on (-1 for none), planted at its door, taken up by an escort, where the bearer last stood, the way he heads,
## the seconds to the house at the last look and the clock it was taken at, and whether the banner told it nears.
var _dest: Array[int] = []
var _planted: Array[bool] = []
var _took_up: Array[bool] = []
var _last_at: Array[Vector2] = []
var _dir: Array[Vector2] = []
var _eta: Array[float] = []
var _eta_clock: Array[float] = []
var _told: Array[bool] = []
## How many standards an escort took up, and how many the walls stopped, for the report.
var took_up_count := 0
var walled_count := 0


## The hunt's plan (MS §5): no head, the chain, the guard reach, the loss word; the four musters as steps; the houses, and the house each
## standard marches on first.
func _plan() -> void:
	has_head = false
	chain = BH_CHAIN
	guard_reach = BH_GUARD_REACH
	lost_word = "houses"
	standard_label = "STANDARD"
	count_word = "standards"
	var hub := _walkable(lantern_door())
	var from: Array[Vector2] = []
	for m: Vector2 in BH_MUSTERS:
		from.append(_street_spot(m, hub))
	_pick_houses(from)
	for i in BH_MUSTERS.size():
		steps.append(_step(String(BH_MUSTER_WORDS[i]), from[i], Rect2(), float(BH_BEARER_AT[i]), BH_ESCORTS))
		bearers.append(null)
		_dest.append(-1)
		_planted.append(false)
		_took_up.append(false)
		_last_at.append(from[i])
		_dir.append(Vector2.DOWN)
		_eta.append(INF)
		_eta_clock.append(0.0)
		_told.append(false)
	if houses.is_empty():
		push_warning("BreakHuntDirector: no house; the standards have nowhere to march")
	for i in steps.size():
		_dest[i] = _first_dest(i, from[i])


## The ground nearest `m` that the street reaches from `hub` and that has room for a bearer between two escorts (the spec's south-west muster
## lies in a walled yard no street reaches, so it is moved to the nearest ground that is open): rings of BH_SNAP_STEP out to BH_SNAP_MAX; `m` snapped to walkable ground if none is.
func _street_spot(m: Vector2, hub: Vector2) -> Vector2:
	var r := 0.0
	while r <= BH_SNAP_MAX:
		var turns := 1 if r == 0.0 else 12
		for k in turns:
			var p := _walkable(m + Vector2.from_angle(TAU * float(k) / float(turns)) * r)
			if (crowd._grid == null or not crowd._grid.path(p, hub).is_empty()) and not _flank_pair(p, 0.0, false).is_empty():
				return p
		r += BH_SNAP_STEP
	return _walkable(m)


## The three houses: for each point the dwelling nearest it that is not reserved, not already picked and has a door the street reaches from
## every muster (`from`); each made stone for the night.
func _pick_houses(from: Array[Vector2]) -> void:
	var skip: Array = []
	for p: Vector2 in BH_HOUSE_POINTS:
		for k in BH_HOUSE_TRIES:
			var h := _house_near(p, skip)
			if h == null:
				break
			skip.append(h)
			var door := _door_from_all(h, from)
			if door == Vector2.INF:
				continue
			houses.append(h)
			house_doors.append(door)
			_taken.append(false)
			_house_filters[h.get_instance_id()] = h.damage_filter
			h.damage_filter = _stone
			break


## A door of `h` the street reaches from every one of `from` (front, back, then the sides), or Vector2.INF.
func _door_from_all(h: Structure, from: Array[Vector2]) -> Vector2:
	var half := h.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(h.center() + off)
		var ok := true
		for f: Vector2 in from:
			ok = ok and (crowd._grid == null or not crowd._grid.path(f, door).is_empty())
		if ok:
			return door
	return Vector2.INF


## Structure.damage_filter for a believers' house: stone tonight, a blow only shakes it, until teardown().
func _stone(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(BH_STONE_SHAKE)


## The house standard `i` marches on first, from `from`: the nearest by the street that no earlier standard is going to; the nearest if every
## house is spoken for; -1 with no house.
func _first_dest(i: int, from: Vector2) -> int:
	var best := -1
	var best_score := INF
	for h in houses.size():
		var score := _way(from, house_doors[h])
		for j in i:
			if _dest[j] == h:
				score += 1000.0
		if score < best_score:
			best_score = score
			best = h
	return best


## The setup: the base's (the parties appointed at their musters and kept there, the timeline), then the town's flight kept off them.
func _begin() -> void:
	super()
	_keep_held(false)


## Step `i`'s people at its muster: its bearer (the lay citizen nearest the muster, set down and kept there on duty) and then its escorts
## (the lay citizens nearest their posts beside him, dressed as guards), all at the Hunt's pace. Returns the escorts, as the base expects.
func _appoint_party(i: int) -> Array[Person]:
	var out: Array[Person] = []
	var spot := steps[i].spot
	var b := _lay_near(spot, 1, _in_use())
	if not b.is_empty():
		bearers[i] = b[0]
		crew.append(b[0])
		_set_down(b[0], spot)
		b[0].go_duty(spot)
		b[0].pace = BH_BEARER_PACE / Person.PANIC_SPEED
	for k in steps[i].party_size:
		var picked := _lay_near(_party_post(i, k), 1, _in_use() + out)
		if picked.is_empty():
			break
		_dress_guard(picked[0])
		picked[0].pace = BH_BEARER_PACE / Person.PANIC_SPEED
		crew.append(picked[0])
		out.append(picked[0])
	return out


## The `k`th escort's post: beside the bearer (_flanks()); at the muster before the march.
func _party_post(i: int, k: int) -> Vector2:
	return _flanks(i)[k % 2]


## The two places beside step `i`'s bearer (_flank_pair()).
func _flanks(i: int) -> Array[Vector2]:
	var at := _bearer_pos(i)
	var pair := _flank_pair(at, _heading(i).rotated(PI * 0.5).angle(), true)
	return pair


## The two places beside a bearer at `at`: BH_ESCORT_OFF from him and on opposite sides of him (1.8 apart, more than two Silent Doom radii) --
## of the BH_FLANK_TURNS / 2 opposite pairs round him the one whose two places are both on the street, at least BH_FLANK_GAP apart, and whose
## line is nearest the angle `square`. With none (a lane too narrow or bent), the two places on the street within BH_FLANK_NEAR of him that are
## furthest apart when `fallback`, else an empty array.
func _flank_pair(at: Vector2, square: float, fallback: bool) -> Array[Vector2]:
	var best: Array[Vector2] = []
	var best_score := INF
	var spots: Array[Vector2] = []
	for k in BH_FLANK_TURNS:
		spots.append(_walkable(at + Vector2.from_angle(TAU * float(k) / float(BH_FLANK_TURNS)) * BH_ESCORT_OFF))
	for k in BH_FLANK_TURNS / 2:
		var ang := TAU * float(k) / float(BH_FLANK_TURNS)
		var a := spots[k]
		var b := spots[k + BH_FLANK_TURNS / 2]
		if a.distance_to(at + Vector2.from_angle(ang) * BH_ESCORT_OFF) > BH_FLANK_SNAP 				or b.distance_to(at - Vector2.from_angle(ang) * BH_ESCORT_OFF) > BH_FLANK_SNAP or a.distance_to(b) < BH_FLANK_GAP:
			continue
		var off := absf(angle_difference(ang, square))
		off = minf(off, PI - off)
		if off < best_score:
			best_score = off
			best = [a, b]
	if not best.is_empty() or not fallback:
		return best
	var near: Array[Vector2] = []
	for radius in [0.9, 1.1, 1.3]:
		for k in BH_FLANK_TURNS * 2:
			var p := _walkable(at + Vector2.from_angle(TAU * float(k) / float(BH_FLANK_TURNS * 2)) * radius)
			if p.distance_to(at) <= BH_FLANK_NEAR:
				near.append(p)
	var widest := -1.0
	best = [at, at]
	for m in near.size():
		for n in range(m + 1, near.size()):
			var gap := near[m].distance_to(near[n])
			if gap > widest:
				widest = gap
				best = [near[m], near[n]]
	return best


## The way step `i`'s bearer heads: toward the next bend of the street to his house's door; the way he last headed when he stands at it.
func _heading(i: int) -> Vector2:
	var from := _bearer_pos(i)
	if _dest[i] >= 0:
		var to := house_doors[_dest[i]]
		var way := crowd._grid.path(from, to) if crowd._grid != null else PackedVector2Array()
		var next := to
		for pt in way:
			if from.distance_to(pt) > 0.5:
				next = pt
				break
		var d := next - from
		if d.length() > 0.3:
			_dir[i] = d.normalized()
	return _dir[i]


## Where step `i`'s bearer stands: his own position while his body is there (even dead, until it is freed), else where he last stood, else
## the muster.
func _bearer_pos(i: int) -> Vector2:
	var v: Variant = bearers[i]
	if is_instance_valid(v):
		return (v as Person).ground_pos
	return _last_at[i]


## Step `i`'s bearer while he lives, or null.
func bearer(i: int) -> Person:
	var v: Variant = bearers[i]
	return v as Person if _alive(v) else null


## Everyone at the hunt's work (the base's, and the bearers).
func _in_use() -> Array:
	var out := super()
	out.append_array(bearers)
	return out


## Virtual in the base, replaced (Ruling C4): there is no Structure to raise, so none is made and this is never called.
func _raise_standard(_i: int) -> Structure:
	return null


## Step `i`'s standard is raised now (Ruling C4: the base's would break a step whose standard is null). Its bearer is marked and marches; one
## fallen at the muster before his time is replaced by an escort, silently; with none to carry it the step counts broken, so the night never
## locks. No damage filter is set and nothing is connected.
func _raise(i: int) -> void:
	var st := steps[i]
	if st.raised:
		return
	st.raised = true
	st.raised_at = _clock
	if bearer(i) == null:
		var up := _taker(i)
		if up == null:
			_break(i)
			return
		_make_bearer(i, up)
	_dest[i] = _pick_dest(i)
	var b := bearer(i)
	_mark(b)
	_set_pace(i)
	if _dest[i] >= 0:
		b.go_duty(house_doors[_dest[i]])
	_refresh_eta(i)


## Step `i`'s bearer and escorts walk at the march's pace (BH_BEARER_PACE, or slower where the street to the house is short: BH_MARCH_MIN).
func _set_pace(i: int) -> void:
	var speed := BH_BEARER_PACE
	if _dest[i] >= 0:
		var rate: float = rules.clock_rate if is_instance_valid(rules) else 1.0
		speed = minf(speed, _way(_bearer_pos(i), house_doors[_dest[i]]) * rate / BH_MARCH_MIN)
	var share := speed / Person.PANIC_SPEED
	var people: Array = [bearers[i]]
	for g: Guard in steps[i].party:
		people.append(g.man)
	for v: Variant in people:
		if _alive(v):
			(v as Person).pace = share


## `p` carries a standard: the pennant over his head, unless a power's badge is on him.
func _mark(p: Person) -> void:
	if p.badge_left <= 0.0 or (p.badge_glyph == BH_FLAG and p.badge_left < BH_FLAG_MIN):
		p.set_badge(BH_FLAG, MARK_TARGET, BH_FLAG_SECONDS)


## Escort `p` becomes step `i`'s bearer: no longer among its escorts.
func _make_bearer(i: int, p: Person) -> void:
	var st := steps[i]
	for g: Guard in st.party.duplicate():
		if g.man == p:
			st.party.erase(g)
	bearers[i] = p
	_last_at[i] = p.ground_pos


## Step `i`'s escort who takes the standard up now, the nearest guarding the bearer's place; null for none.
func _taker(i: int) -> Person:
	var best: Person = null
	var best_gap := INF
	var at := _bearer_pos(i)
	for g: Guard in steps[i].party:
		if not _guarding(i, g):
			continue
		var gap := (g.man as Person).ground_pos.distance_to(at)
		if gap < best_gap:
			best_gap = gap
			best = g.man as Person
	return best


## Escort `g` of step `i` guards the bearer now (MS §5): alive, out of doors, within `guard_reach` of the bearer's place, not held by the god
## (whispered, confused, compelled, lured), not fighting, not frail, not afraid.
func _guarding(i: int, g: Guard) -> bool:
	if not _alive(g.man):
		return false
	var p := g.man as Person
	if p.inside or p.held_by_god() or p.mind == Person.Mind.FIGHT or p.mind in BH_FRIGHT or p.statuses.has(&"frail"):
		return false
	return p.ground_pos.distance_to(_bearer_pos(i)) <= guard_reach


## Step `i`'s standard has an escort guarding it now (the base's, restated: any escort of the step).
func _guarded(i: int) -> bool:
	for g: Guard in steps[i].party:
		if _guarding(i, g):
			return true
	return false


## Step `i`'s standard is raised, unbroken and guarded now (only reads). It has no Structure, so the base's test of one is replaced.
func guarded(i: int) -> bool:
	return steps[i].raised and not steps[i].broken and bearer(i) != null and _guarded(i)


## No Structure (Ruling C4): null.
func standard(_i: int) -> Structure:
	return null


## A fallen escort is not replaced (MS §5): each standard grows easier.
func _relieve(_i: int, _g: Guard) -> void:
	pass


## Every one of the hunt's people kept out of the town's flight (MS §0, _hold_all): the bearers and the escorts of every unbroken step.
func _keep_held(evacuating: bool) -> void:
	var people: Array = []
	for i in steps.size():
		if steps[i].broken:
			continue
		people.append(bearers[i])
		for g: Guard in steps[i].party:
			people.append(g.man)
	_hold_all(people, evacuating)


## One step: the base's (the timeline, the chain, every look), the clock moved on to mission seconds, those the walls stopped taken off the
## map, and the warning for a standard nearing a house.
func step(delta: float) -> void:
	_step_leaving()
	super(delta)
	_clock += mission_delta(delta) - delta
	_warn_near()


## A step's looks, every TICK for each unbroken step (the base calls this where it keeps a party on its posts): the escorts to their places beside
## the bearer, then the bearer himself -- fallen (an escort takes it up, or it breaks), out of the walls (it breaks), afraid with no escort by
## (it breaks), at a door (it plants), held and back on his feet (he takes up the march again). On the look the evacuation began the fright
## test is skipped: the town's flight is not a fright (_hold_all has just called the people back).
func _keep_party(i: int, _delta: float, looking: bool, evacuating := false) -> void:
	if not looking:
		return
	var st := steps[i]
	_post_escorts(i, evacuating)
	if not st.raised:
		var waiting := bearer(i)
		if waiting != null:
			_last_at[i] = waiting.ground_pos
			_recall_to(waiting, st.spot, evacuating)
		return
	_look(i, evacuating)


## Step `i`'s escorts to their places beside the bearer where he stands now.
func _post_escorts(i: int, evacuating: bool) -> void:
	var st := steps[i]
	var posts := _flanks(i)
	for k in st.party.size():
		var g: Guard = st.party[k]
		g.post = posts[k % 2]
		if _alive(g.man) and not (g.man as Person).inside:
			_recall_to(g.man, g.post, evacuating)


## Step `i`'s bearer at a look (see _keep_party()).
func _look(i: int, evacuating: bool) -> void:
	var b := bearer(i)
	if b == null:
		var up := _taker(i)
		if up == null:
			_break(i)
			return
		_make_bearer(i, up)
		_post_escorts(i, evacuating)  # the one left closes up on the new bearer at once
		_took_up[i] = true
		took_up_count += 1
		rules.banner.emit(BH_TAKEN_UP)
		b = up
	_last_at[i] = b.ground_pos
	if Walls.outside(b.ground_pos):
		walled_count += 1
		send_off(b)
		_break(i)
		return
	if not evacuating and b.mind in BH_FRIGHT and not _guarded(i):
		_break(i)
		return
	_mark(b)
	if not _planted[i]:
		if b.mind == Person.Mind.DUTY:
			for h in houses.size():
				if not _taken[h] and b.ground_pos.distance_to(house_doors[h]) <= BH_TAKE_REACH:
					_plant(i, h)
					break
	if not _planted[i]:
		if _dest[i] < 0 or _taken[_dest[i]]:
			_dest[i] = _pick_dest(i)
		if _dest[i] >= 0:
			_recall_to(b, house_doors[_dest[i]], evacuating)
		_refresh_eta(i)


## Step `i`'s bearer plants the standard at house `h`: it is taken, a setback, and he stands there still breakable.
func _plant(i: int, h: int) -> void:
	_planted[i] = true
	_taken[h] = true
	_dest[i] = h
	_eta[i] = INF
	var n := taken()
	if n < BH_LOSE_TAKEN:
		rules.banner.emit(BH_HOUSE_TAKEN)


## The house step `i`'s bearer should march on: the nearest untaken by the street that no other standard marching is going to; the nearest
## untaken if each is spoken for; -1 with every house taken.
func _pick_dest(i: int) -> int:
	var at := _bearer_pos(i)
	var best := -1
	var best_score := INF
	for h in houses.size():
		if _taken[h]:
			continue
		var score := _way(at, house_doors[h])
		for j in steps.size():
			if j != i and not steps[j].broken and not _planted[j] and _dest[j] == h and (steps[j].raised or j < i):
				score += 1000.0
				break
		if score < best_score:
			best_score = score
			best = h
	return best


## The length of the street walk from `a` to `b` (straight when no path is found).
func _way(a: Vector2, b: Vector2) -> float:
	var route := crowd._grid.path(a, b) if crowd._grid != null else PackedVector2Array()
	var total := 0.0
	var at := a
	for pt in route:
		total += at.distance_to(pt)
		at = pt
	return total + at.distance_to(b)


## Step `i`'s seconds to its house at the last look, mission seconds (INF for a standard planted, broken, not yet raised or with no house).
func _refresh_eta(i: int) -> void:
	var b := bearer(i)
	if b == null or _planted[i] or _dest[i] < 0 or steps[i].broken or not steps[i].raised:
		_eta[i] = INF
		return
	var rate: float = rules.clock_rate if is_instance_valid(rules) else 1.0
	var speed := maxf(Person.PANIC_SPEED * b.pace * float(b.statuses.get(&"slow", 1.0)), 0.05)
	_eta[i] = _way(b.ground_pos, house_doors[_dest[i]]) / speed * rate
	_eta_clock[i] = _clock


## Mission seconds until step `i`'s standard reaches its house: INF when it does not march (planted, broken, not raised).
func eta(i: int) -> float:
	if _eta[i] == INF or steps[i].broken or _planted[i]:
		return INF
	return maxf(_eta[i] - (_clock - _eta_clock[i]), 0.0)


## Mission seconds until the nearest standard marching on house `h` reaches it; INF for none.
func house_eta(h: int) -> float:
	var best := INF
	for i in steps.size():
		if steps[i].raised and not steps[i].broken and not _planted[i] and _dest[i] == h:
			best = minf(best, eta(i))
	return best


## The soonest any standard reaches a house, mission seconds; INF with none marching.
func soonest_eta() -> float:
	var best := INF
	for i in steps.size():
		if steps[i].raised and not steps[i].broken and not _planted[i]:
			best = minf(best, eta(i))
	return best


## The banner when a standard is within BH_NEAR_WARN of a house, once for each standard.
func _warn_near() -> void:
	for i in steps.size():
		if _told[i] or not steps[i].raised or steps[i].broken or _planted[i]:
			continue
		if eta(i) <= BH_NEAR_WARN:
			_told[i] = true
			rules.banner.emit(BH_NEARS)


## Step `i` is broken for good: the banner and the party's release are the base's; the bearer, if he stands, is stood down too and his
## pennant taken off.
func _break(i: int) -> void:
	var b := bearer(i)
	if b != null:
		if b.badge_glyph == BH_FLAG:
			b.clear_badge()
		var gone := Guard.new()
		gone.man = b
		_release(gone)
	super(i)


## The banner when a standard is broken: with the count.
func _broken_banner(_i: int) -> String:
	return "THE STANDARD IS BROKEN  %d/%d" % [broken_count(), steps.size()]


## The step's strip label and banner when its standard is raised.
func _step_label(i: int) -> String:
	return "A standard marches from %s" % steps[i].words


func _opening_banner() -> String:
	return BH_OPENING


func _found_banner() -> String:
	return BH_FOUND


## The hunt has taken its second house -- unless every standard is broken, which wins first (MS §0: the winning strike never also loses).
func _found() -> bool:
	return taken() >= BH_LOSE_TAKEN and not broken_all()


## How many believers' houses are taken.
func taken() -> int:
	var n := 0
	for t: bool in _taken:
		n += 1 if t else 0
	return n


## No place the hunt seeks (it has no head): none.
func _quarry_point() -> Vector2:
	return Vector2.INF


## The strip's row (MS §5): when the soonest standard reaches a house.
func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var soon := soonest_eta()
	if soon != INF and not found:
		out.append({"in": soon, "label": BH_ROW})
	return out


## "taken" once a house is taken (one more loses), "carried" while a standard an escort took up stands, else the mission's own line.
func hint_phase() -> String:
	if found or broken_all():
		return ""
	if taken() >= 1:
		return "taken"
	for i in steps.size():
		if _took_up[i] and steps[i].raised and not steps[i].broken and bearer(i) != null:
			return "carried"
	return ""


## The map tags (MS §5), most important first: each standard's bearer (gold, pointed at) with his seconds to the house; the believers' houses
## (blue, a taken one red) with the nearest standard's seconds; the musters not yet raised (grey) with their countdown; the escorts (red,
## pointed at once the march begins).
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if found or broken_all():
		return out
	for i in steps.size():
		var b := bearer(i)
		if not steps[i].raised or steps[i].broken or b == null or b.inside:
			continue
		var label := standard_label + (" - PLANTED" if _planted[i] else " - HOUSE IN %s" % UiTheme.clock(ceilf(eta(i))))
		out.append(MapTag.person(b.ground_pos, MARK_TARGET, label, true))
	for h in houses.size():
		if _taken[h]:
			out.append(MapTag.place(house_doors[h], BH_MARK_TAKEN, "BELIEVERS - TAKEN", houses[h].height, true))
			continue
		var soon := house_eta(h)
		var words := "BELIEVERS" if soon == INF else "BELIEVERS - STANDARD IN %s" % UiTheme.clock(ceilf(soon))
		out.append(MapTag.place(house_doors[h], BH_MARK_HOUSE, words, houses[h].height, soon != INF))
	var next := next_step()
	for i in steps.size():
		if not steps[i].raised:
			out.append(MapTag.place(steps[i].spot, MARK_NOT_YET, "RAISED IN %s" % UiTheme.clock(ceilf(due_in(i))), 0.0, i == next))
	for i in steps.size():
		if steps[i].broken:
			continue
		for g: Guard in steps[i].party:
			if not _alive(g.man) or (g.man as Person).inside:
				continue
			if steps[i].raised:
				out.append(MapTag.person((g.man as Person).ground_pos, MARK_WATCHED, escort_label, true))
			else:
				out.append(MapTag.pip((g.man as Person).ground_pos, MARK_WATCHED))
	return out


## The tour (MS §5): a believers' house, the north muster, the east muster.
func tour() -> Array:
	var out := []
	if not houses.is_empty():
		out.append([house_doors[0], "Your believers hide in this house. Two houses taken and the night is lost."])
	if not steps.is_empty():
		out.append([steps[0].spot, "A standard is raised at the north muster at %s and marches on a house." % UiTheme.clock(float(BH_BEARER_AT[0]))])
	if steps.size() > 1:
		out.append([steps[1].spot, "Three more follow. Break a standard when no escort stands by its bearer."])
	return out


## What the results show: the base's keys, and the Hunt's.
func report() -> Dictionary:
	var out := super()
	out["taken"] = taken()
	out["took_up"] = took_up_count
	out["walled"] = walled_count
	return out


## Lets go of the houses' stone and the bearers' pennants, then the base's.
func teardown() -> void:
	for i in houses.size():
		var h: Variant = houses[i]
		if is_instance_valid(h) and (h as Structure).damage_filter == _stone:
			(h as Structure).damage_filter = _house_filters.get((h as Structure).get_instance_id(), Callable())
	for v: Variant in bearers:
		if _alive(v) and (v as Person).badge_glyph == BH_FLAG:
			(v as Person).clear_badge()
	super()
