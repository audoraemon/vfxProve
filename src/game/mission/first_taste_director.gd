class_name FirstTasteDirector
extends RiteDirector
## The First Taste (god P3, mission spec MS §3, plan Task 4; the rite at level 10): five of Halcyon's lamplighters walk their rounds of four street
## lamps, four soldiers of the Watch stand on the way out, and after each of the first two shards Halcyon answers with a clergy march on Mira's
## shrine -- two clergy, then three -- that muster ten seconds at the Temple door, walk the long way round to the shrine and kneel there; two kneeling
## twelve seconds cleanse its flame and lose the night. The god drags three lamplighters to the shrine with Chain of the Forgotten (RiteDirector).
## The Watch and the marchers are the chain's breakers; nobody else ever grips (MS §0). A march is stopped for good by killing or frightening all but
## one of its people; a held marcher only loses time. A lamplighter that is gone (dead, or safe at the Temple) is replaced by a new one at once when
## too few are left (MS §3.6), so the night is never a dead end. Every timer here runs in real seconds (R5: a toll never shortens a warning).
## Numbers marked *fg* are first guesses, tuned only in Task 7 (MS §3.9).

## The five lamplighters' rounds (MS §3.2): four lamps each, snapped to walkable ground. All five lie in the south and west half, so every drag path
## stays under about 45 units.
const ROUNDS := [
	[Vector2(-6.0, 13.5), Vector2(-6.0, 10.0), Vector2(-10.0, 9.0), Vector2(-10.0, 13.0)],
	[Vector2(-14.5, 9.0), Vector2(-6.5, 4.0), Vector2(-6.5, 0.0), Vector2(-12.0, 2.5)],
	[Vector2(0.0, 7.5), Vector2(2.7, 10.5), Vector2(5.0, 7.5), Vector2(2.7, 4.0)],
	[Vector2(5.5, 12.5), Vector2(9.5, 12.0), Vector2(9.5, 8.8), Vector2(6.0, 9.0)],
	[Vector2(-6.5, -4.0), Vector2(-2.0, -5.0), Vector2(-3.0, 0.5), Vector2(-6.5, 2.0)],
]
## Seconds a lamplighter stands at each lamp to light it, and how near a lamp counts as reached.
const LAMP_SECONDS := 4.0
const LAMP_REACH := 0.5
## The Watch's four posts (MS §3.3, *fg*; Task 7 may cut it to three): the two inside the Main Gate, the shrine road, the shrine approach.
const POSTS := [Vector2(1.6, 13.6), Vector2(3.8, 13.6), Vector2(-8.0, 17.6), Vector2(-17.2, 10.0)]
## Seconds a march musters at the Temple door after its shard (*fg*; Task 7 may raise 10 -> 15), how many clergy each march has (*fg*; the second's 3
## may fall to 2), the gap a file keeps between its people, and their pace: MARCH_PACE units a second times each marcher's own 0.85-1.2 (MS §3.4: the
## walk is about 90 s).
const MARCH_AFTER := 10.0
const MARCHERS := [2, 3]
const MARCH_GAP := 1.8
const MARCH_PACE := 0.6
## The fastest a file may walk the whole way: no marcher covers his path in under this many seconds, however quick his own pace (MS §3.5: the flame is
## never out sooner than ~110 s after the shard = MARCH_AFTER 10 + 88 + CLEANSE_SECONDS 12; controller ruling, review-t4 I5). A marcher of the usual pace
## (1.0) walks the 55-unit way in about 92 s; only the quick ones are held to 88.
const MARCH_WALK_MIN := 88.0
## How many angles round its ring a kneeling spot is tried at, and how far from the others (over 2 Silent Doom radii, 1.6, with a margin) and from the
## shrine it may lie after the walk grid's snap.
const KNEEL_TRIES := 24
const KNEEL_APART := 1.7
const KNEEL_MAX := 3.6
## A follower waits when he is under MARCH_GAP + FILE_WAIT behind the one ahead and sets on again at MARCH_GAP + FILE_GO (a margin: the checks are TICK
## apart, and behind a held leader he must still stay over 1.6).
const FILE_WAIT := 0.2
const FILE_GO := 0.4
## How much further out than KNEEL_RING a later march kneels, so two marches never share a ring (the spread rule between marches).
const KNEEL_OUTER := 0.9
## Seconds two kneeling marchers cleanse the shrine in, how many must kneel, the ring their kneeling spots lie on round the shrine (MS §3.4; *my call*:
## 1.1, so three kneelers stand 1.9 apart, over the 1.6 of two Silent Doom radii -- the plan's 0.8 would have put them 1.4 apart) and how near a spot
## counts as kneeling on it.
const CLEANSE_SECONDS := 12.0
const CLEANSE_NEED := 2
const KNEEL_RING := 1.1
const KNEEL_REACH := 0.5
## The camera's resting place for the night: the gate plaza, where lamplighters #3 and #4 are (*my call*). The intro looks down from 6 units south.
const CAMERA_AT := Vector2(3.0, 10.0)
## The muster ring round the Temple door the marchers gather on.
const MUSTER_RING := 1.0

## The words (MS §3.4, §3.6, §3.5). The opening banner is the def's own (`intro_banner`, R9), so none is pushed here.
const ANSWER := "HALCYON ANSWERS - CLERGY MARCH ON THE SHRINE"
const CLEANSE := "THE CLERGY CLEANSE THE SHRINE"
const BREAKS := "THE MARCH BREAKS"
const NEW_LAMPLIGHTER := "A NEW LAMPLIGHTER SETS OUT"
const NO_CLERGY := "HALCYON'S CLERGY ARE GONE"
const TAG_LAMPLIGHTER := "LAMPLIGHTER"
const TAG_WATCH := "WATCH"
const TAG_MUSTER := "CLERGY MARCH IN %s"
const TAG_LEADER := "CLERGY - SHRINE IN %s"
const TAG_CLERGY := "CLERGY"
const TAG_CLEANSE := "CLEANSING %s"
const STRIP_ROW := "The clergy reach the shrine"

## One clergy march: its people in file order (the leader first), its muster, and who has fled it.
class March extends RefCounted:
	## The marchers still on it (alive, not fled), the ones who left it frightened, the seconds of muster left and whether the file is walking.
	## Untyped so a body freed after its death fade never trips a typed read (review-t4 I1); every use goes through _alive().
	var people: Array = []
	var fled: Array = []
	var muster_left := 0.0
	var walking := false
	## It is over: broken (too few left) or it has done its work.
	var done := false
	## Person -> his kneeling spot, his own pace before the march, and whether he is waiting for the one ahead to get 1.8 on.
	var spots := {}
	var pace0 := {}
	var paused := {}
	## Person -> his walking speed in units a second, fixed at the set-out (MARCH_PACE times his pace, capped by MARCH_WALK_MIN).
	var speeds := {}
	## The kneeling spots planned for the march, one per marcher, in file order (_plan_spots()).
	var plan: Array[Vector2] = []
	## Seconds the leader still needs to walk to the shrine (the walk only; set at the muster from the door, refreshed at each look once walking,
	## counted down each frame). march_eta() adds the muster.
	var eta := 0.0

## The people on rounds, one per round (null once that round's lamplighter is gone and none replaced him), and each round's lamp and the time he
## reached it (-1: not there).
var lamps: Array = []
var _stage := PackedInt32Array()
var _reached := PackedFloat32Array()
## The Watch, each at his post, and the clergy marches (a finished one stays listed).
var watch: Array = []
var _posts := {}
var marches: Array[March] = []
## Seconds the shrine has been cleansed so far, and whether this run of it has been announced.
var cleanse := 0.0
var _cleansing := false
## Real seconds since the director began; the lamp timers read it.
var _now := 0.0


func rite_id() -> String:
	return RiteBook.FIRST_TASTE


func victim_word() -> String:
	return TAG_LAMPLIGHTER


# --- Set up ------------------------------------------------------------------------------------

func _begin() -> void:
	super._begin()
	for i in POSTS.size():
		var taken: Array = watch.duplicate()
		var soldiers := _free_soldiers(POSTS[i], 1, taken)
		if soldiers.is_empty():
			continue
		var s: Person = soldiers[0]
		var at := _walkable(POSTS[i])
		s.ground_pos = at
		s.send_to_post(at)
		watch.append(s)
		_posts[s] = at


## The five lamplighters (MS §3.2, R13): for each round the eligible resident or labourer nearest its first lamp, set down at it, Faithful for the night,
## on duty there.
func _appoint_victims() -> Array[Person]:
	var out: Array[Person] = []
	lamps.clear()
	_stage = PackedInt32Array()
	_reached = PackedFloat32Array()
	for i in ROUNDS.size():
		var first := _lamp_spot(i, 0)
		var v := _nearest_lay(first, out)
		lamps.append(v)
		_stage.append(0)
		_reached.append(-1.0)
		if v == null:
			continue
		_make_lamplighter(v, first)
		out.append(v)
	return out


## A lamplighter's walk-through: round `i`'s `k`th lamp on walkable ground.
func _lamp_spot(i: int, k: int) -> Vector2:
	return _walkable((ROUNDS[i] as Array)[k % (ROUNDS[i] as Array).size()])


## The eligible resident or labourer nearest `at`, none of `exclude`, not already on the rite's errand; null for none.
func _nearest_lay(at: Vector2, exclude: Array = []) -> Person:
	var best: Person = null
	for p in crowd.citizens:
		if not _eligible(p) or p.profile == null or exclude.has(p) or marked.has(p) or safe.has(p) or lamps.has(p) or _marching(p):
			continue
		if p.profile.role != CitizenProfile.Role.RESIDENT and p.profile.role != CitizenProfile.Role.LABORER:
			continue
		if best == null or p.ground_pos.distance_squared_to(at) < best.ground_pos.distance_squared_to(at):
			best = p
	return best


## `v` is a lamplighter for the night: Faithful, standing at `at` on duty.
func _make_lamplighter(v: Person, at: Vector2) -> void:
	v.profile.faith = CitizenProfile.Faith.FAITHFUL
	_set_down(v, at)
	v.go_duty(v.ground_pos)


# --- The breakers --------------------------------------------------------------------------------

## The Watch still standing and the marchers on their way (walking or kneeling); a muster is not yet a breaker.
func _breakers() -> Array[Person]:
	var out: Array[Person] = []
	for s: Variant in watch:
		if _alive(s):
			out.append(s as Person)
	for m in marches:
		if m.done or not m.walking:
			continue
		for p: Variant in m.people:
			if _alive(p):
				out.append(p as Person)
	return out


func _post_of(b: Person) -> Vector2:
	return _posts.get(b, b.ground_pos)


## A marcher keeps to his march; only the Watch walks to a captive.
func _go_grip(b: Person, at: Vector2) -> void:
	if _marching(b):
		return
	super._go_grip(b, at)


func _go_back(b: Person) -> void:
	if _marching(b):
		return
	super._go_back(b)


## `p` is on a march (mustering, walking or kneeling).
func _marching(p: Variant) -> bool:
	for m in marches:
		if not m.done and m.people.has(p):
			return true
	return false


## Everyone the director keeps at his errand through an evacuation (MS §0): the base's, the whole Watch and every marcher.
func _held_people() -> Array:
	var all: Array = []
	all.append_array(super._held_people())
	all.append_array(watch)
	all.append_array(lamps)
	for m in marches:
		if not m.done:
			all.append_array(m.people)
	var out: Array = []
	for v: Variant in all:
		if v != null and not out.has(v):
			out.append(v)
	return out


## The base's busy people, and the ones mustering (G3).
func busy(p: Person) -> bool:
	return super.busy(p) or watch.has(p) or _marching(p)


# --- Each frame ----------------------------------------------------------------------------------

func step(delta: float) -> void:
	_now += delta
	super.step(delta)
	for m in marches:
		if m.done:
			continue
		if not m.walking:
			m.muster_left -= delta
			if m.muster_left <= 0.0:
				_set_out(m)
		else:
			m.eta = maxf(m.eta - delta, 0.0)
	_step_cleanse(delta)


## Two or more marchers kneeling on their spots, none held, run the ring; fewer reset it. A full ring puts the flame out.
func _step_cleanse(delta: float) -> void:
	if flame_out:
		return
	if _kneeling() >= CLEANSE_NEED:
		if not _cleansing:
			_cleansing = true
			rules.banner.emit(CLEANSE)
		cleanse += delta
		if cleanse >= CLEANSE_SECONDS:
			cleanse = CLEANSE_SECONDS
			flame_out = true
	else:
		cleanse = 0.0
		_cleansing = false


## How many marchers kneel on their spots now: alive, within KNEEL_REACH of the spot, not held.
func _kneeling() -> int:
	var n := 0
	for m in marches:
		if m.done or not m.walking:
			continue
		for p: Variant in m.people:
			if _kneels(m, p):
				n += 1
	return n


func _kneels(m: March, p: Variant) -> bool:
	return _alive(p) and not held(p) and (p as Person).ground_pos.distance_to(m.spots.get(p, Vector2.INF)) <= KNEEL_REACH


# --- Each look (every TICK) ----------------------------------------------------------------------

func _look() -> void:
	_prune_watch()
	super._look()
	_step_rounds()
	_look_marches()


## Each lamplighter walks his round: stands LAMP_SECONDS at a lamp, then walks on to the next, round and round. One the chain has (the captive, a
## freed runner), or one the god holds, is left alone; when his hold ends he is called back to his lamp.
func _step_rounds() -> void:
	for i in lamps.size():
		var v: Variant = lamps[i]
		if not _alive(v):
			continue
		var p := v as Person
		if safe.has(p) or claimed(p) or held(p):
			continue
		var at := _lamp_spot(i, _stage[i])
		if p.ground_pos.distance_to(at) <= LAMP_REACH:
			if _reached[i] < 0.0:
				_reached[i] = _now
			if _now - _reached[i] >= LAMP_SECONDS:
				_stage[i] = (_stage[i] + 1) % (ROUNDS[i] as Array).size()
				_reached[i] = -1.0
				p.go_duty(_lamp_spot(i, _stage[i]))
		else:
			_reached[i] = -1.0
			_recall_to(p, at)


## The Watch without the dead and freed (a body is freed after its death fade): the posts follow (review-t4 I1).
func _prune_watch() -> void:
	var keep: Array = []
	for s: Variant in watch:
		if _alive(s):
			keep.append(s)
	if keep.size() == watch.size():
		return
	watch = keep
	for k in _posts.keys():
		if not _alive(k):
			_posts.erase(k)


## The lamp round `i`'s lamplighter walks to or stands at now.
func lamp_of(i: int) -> Vector2:
	return _lamp_spot(i, _stage[i])


## Round `i` has no lamplighter on it: his man is dead or safe at the Temple, and no new one has set out.
func _gone(i: int) -> bool:
	var p: Variant = lamps[i]
	return not _alive(p) or safe.has(p)


## MS §3.6, P3-16: the eligible resident or labourer nearest the Temple door sets out on the lowest round whose lamplighter is gone, from where he
## stands, Faithful for the night.
func _replace() -> void:
	var free_round := -1
	for i in lamps.size():
		if _gone(i):
			free_round = i
			break
	if free_round < 0:
		return
	var v := _nearest_lay(lantern_door())
	if v == null:
		return
	lamps[free_round] = v
	_stage[free_round] = 0
	_reached[free_round] = -1.0
	v.profile.faith = CitizenProfile.Faith.FAITHFUL
	_mark(v)
	v.go_duty(_lamp_spot(free_round, 0))
	rules.banner.emit(NEW_LAMPLIGHTER)


# --- Halcyon's answer: the clergy march --------------------------------------------------------

## After shard 1 and shard 2 a march forms (MS §3.4): the clergy nearest the Temple door, then Faithful residents if short (P3-15); fewer than two able
## is no march, said on a banner. There is none after the last shard (the night is won).
func _answer(shard: int) -> void:
	if shard < 1 or shard > MARCHERS.size():
		return
	var people := _marchers(int(MARCHERS[shard - 1]))
	if people.size() < CLEANSE_NEED:
		rules.banner.emit(NO_CLERGY)
		return
	var m := March.new()
	m.people = people
	m.muster_left = MARCH_AFTER
	marches.append(m)
	m.plan = _plan_spots(m)
	var door := lantern_door()
	for k in people.size():
		var p: Person = people[k]
		m.pace0[p] = p.pace
		m.paused[p] = k > 0
		p.go_duty(_ring_spot(door, MUSTER_RING, k, people.size()))
	# The walk only: march_eta() adds the muster (review-t4 I4).
	m.eta = _walk_seconds(door, _kneel_spot(m, 0), float(m.pace0[people[0]]))
	rules.banner.emit(ANSWER)


## The `n` marchers: clergy nearest the door first (R8: through is_clergy), then Faithful residents who are not on the rite's other errands.
func _marchers(n: int) -> Array[Person]:
	var door := lantern_door()
	var clergy: Array[Person] = []
	var faithful: Array[Person] = []
	for p in crowd.citizens:
		if not _eligible(p) or p.profile == null or marked.has(p) or safe.has(p) or lamps.has(p) or _marching(p) or claimed(p):
			continue
		if CitizenProfile.is_clergy(p.profile.role):
			clergy.append(p)
		elif p.profile.faith == CitizenProfile.Faith.FAITHFUL and p.profile.role == CitizenProfile.Role.RESIDENT:
			faithful.append(p)
	var by_door := func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(door) < b.ground_pos.distance_squared_to(door)
	clergy.sort_custom(by_door)
	faithful.sort_custom(by_door)
	var out: Array[Person] = []
	for p in clergy + faithful:
		if out.size() >= n:
			break
		out.append(p)
	return out


## The muster is over: the file sets out for the shrine -- each marcher at MARCH_PACE times his own pace, to his kneeling spot, the leader at once and
## each follower once the one ahead has got MARCH_GAP on.
func _set_out(m: March) -> void:
	m.walking = true
	for k in m.people.size():
		var p: Person = m.people[k]
		m.spots[p] = _kneel_spot(m, k)
		m.speeds[p] = _march_speed(p.ground_pos, m.spots[p], float(m.pace0[p]))
		p.pace = float(m.speeds[p]) / Person.PANIC_SPEED
		if k == 0:
			m.paused[p] = false
			p.go_duty(m.spots[p])
		else:
			m.paused[p] = true
	m.eta = _march_seconds(m.people[0], m)


## Marcher `k`'s kneeling spot (planned when the march forms).
func _kneel_spot(m: March, k: int) -> Vector2:
	return m.plan[k] if k < m.plan.size() else _shrine


## The march's kneeling spots, one per marcher: on a ring round the shrine (a later march on a ring KNEEL_OUTER further out), each the first of
## KNEEL_TRIES angles whose point -- after the walk grid's snap -- lies more than KNEEL_APART from every spot already planned (this march's and the
## earlier marches'), not on the stone and not far from it, and has a way from the Temple door. The spread rule must hold on the real shrine, not on
## a perfect ring (review-t4 I3).
func _plan_spots(m: March) -> Array[Vector2]:
	var index := maxi(marches.find(m), 0)
	var taken: Array[Vector2] = []
	for other in marches:
		if other != m:
			taken.append_array(other.plan)
	var n := maxi(m.people.size(), CLEANSE_NEED)
	var out: Array[Vector2] = []
	for k in n:
		var chosen := Vector2.INF
		for r_extra in [0.0, 0.5, 1.0]:
			for j in KNEEL_TRIES:
				var angle := float(index) * 0.9 + 0.3 + TAU * float(k) / float(n) + TAU * float(j) / float(KNEEL_TRIES)
				var at := _walkable(_shrine + Vector2.from_angle(angle) * (KNEEL_RING + KNEEL_OUTER * float(index) + r_extra))
				var d_shrine := at.distance_to(_shrine)
				if d_shrine < SHRINE_REACH or d_shrine > KNEEL_MAX or _walk_way(lantern_door(), at) < 0.0:
					continue
				var apart := true
				for o in taken:
					if at.distance_to(o) <= KNEEL_APART:
						apart = false
				for o in out:
					if at.distance_to(o) <= KNEEL_APART:
						apart = false
				if apart:
					chosen = at
					break
			if chosen != Vector2.INF:
				break
		out.append(chosen if chosen != Vector2.INF else _ring_spot(_shrine, KNEEL_RING, k, n))
	return out


## The length in units of the grid's path from `from` to `to` (-1 when there is none).
func _walk_way(from: Vector2, to: Vector2) -> float:
	if from.distance_to(to) <= 0.01:
		return 0.0
	var way := crowd._grid.path(from, to)
	if way.is_empty():
		return -1.0
	var total := 0.0
	var at := from
	for pt in way:
		total += at.distance_to(pt)
		at = pt
	return total + at.distance_to(to)


## A marcher's speed in units a second: MARCH_PACE times his own pace, but never fast enough to cover his way in under MARCH_WALK_MIN seconds.
func _march_speed(from: Vector2, to: Vector2, pace0: float) -> float:
	var speed := MARCH_PACE * pace0
	var way := _walk_way(from, to)
	if way > 0.0:
		speed = minf(speed, way / MARCH_WALK_MIN)
	return maxf(speed, 0.05)


## Seconds to walk from `from` to `to` at a marcher's speed.
func _walk_seconds(from: Vector2, to: Vector2, pace0: float) -> float:
	return maxf(_walk_way(from, to), 0.0) / _march_speed(from, to, pace0)


## Seconds `p` still needs to walk from where he stands to his kneeling spot at his march speed (the last estimate when he is gone).
func _march_seconds(p: Variant, m: March) -> float:
	if not _alive(p) or not m.spots.has(p):
		return m.eta
	var way := _walk_way((p as Person).ground_pos, m.spots[p])
	return maxf(way, 0.0) / maxf(float(m.speeds.get(p, MARCH_PACE)), 0.05)


## One look at each march: the dead and the frightened leave it for good; under CLEANSE_NEED left it breaks; a walking file keeps MARCH_GAP between
## its people and calls back the ones whose hold has ended.
func _look_marches() -> void:
	for m in marches:
		if m.done:
			continue
		var keep: Array = []
		for v: Variant in m.people:
			if not _alive(v):
				continue
			var p := v as Person
			if p.mind == Person.Mind.PANIC or p.mind == Person.Mind.FLEE or p.mind == Person.Mind.SHELTER:
				m.fled.append(p)
				_unmarch(m, p, false)
			else:
				keep.append(p)
		m.people = keep
		if m.people.size() < CLEANSE_NEED:
			_break_march(m)
			continue
		if m.walking:
			_keep_file(m)
			m.eta = _march_seconds(m.people[0], m)


## The march is broken (MS §3.4): banner, and the survivors go home.
func _break_march(m: March) -> void:
	m.done = true
	rules.banner.emit(BREAKS)
	for p: Variant in m.people:
		_unmarch(m, p, true)
	m.people.clear()


## `p` leaves the march: his own pace back, and sent home when he is still on duty for it.
func _unmarch(m: March, p: Variant, home: bool) -> void:
	if not is_instance_valid(p):
		return
	if m.pace0.has(p):
		(p as Person).pace = float(m.pace0[p])
	if home:
		crowd.off_duty(p as Person)


## The file's order and spacing (MS §3.4: kept 1.8 apart by the director, more than 1.6): a marcher too close behind the one ahead waits where he
## stands, and sets on again once the gap is MARCH_GAP; one who was held and is free again is sent on to his spot. A held marcher is left to his hold.
func _keep_file(m: March) -> void:
	var ahead: Variant = null
	for v: Variant in m.people:
		if not _alive(v):
			continue
		var p := v as Person
		var spot: Vector2 = m.spots[p]
		if held(p):
			ahead = p
			continue
		var gap := p.ground_pos.distance_to((ahead as Person).ground_pos) if ahead != null and _alive(ahead) else INF
		var behind := ahead != null and _alive(ahead) and not _kneels(m, ahead)
		if bool(m.paused[p]):
			# Waiting: set on again once the one ahead is MARCH_GAP + FILE_GO on (or has gone to his knees).
			if not behind or gap >= MARCH_GAP + FILE_GO:
				m.paused[p] = false
				p.go_duty(spot)
		elif behind and gap < MARCH_GAP + FILE_WAIT:
			m.paused[p] = true
			_stand(p)
		else:
			_recall_to(p, spot)
		ahead = p


# --- Reports for the HUD -----------------------------------------------------------------------

## A march's seconds to the shrine: the muster still to run and the leader's walk (review-t4 I4: counted once, smooth through the set-out).
func march_eta(m: March) -> float:
	return (maxf(m.muster_left, 0.0) if not m.walking else 0.0) + m.eta


func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in marches:
		if m.done or (m.walking and _kneeling_all(m)):
			continue
		out.append({"in": march_eta(m), "label": STRIP_ROW})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["in"]) < float(b["in"]))
	return out


## Every marcher of `m` kneels on his spot.
func _kneeling_all(m: March) -> bool:
	for p: Variant in m.people:
		if not _kneels(m, p):
			return false
	return not m.people.is_empty()


## The cleanse is running (a ring on the shrine).
func cleansing() -> bool:
	return _cleansing and not flame_out


## "drag" first while a breaker has his grip on the captive (the time-critical case: the Yank line); "cleanse" while the shrine is being cleansed; "march" while a file walks; "drag" with a captive; "chain" otherwise (the mission's own line).
func hint_phase() -> String:
	if grip_by != null and _alive(grip_by) and chain_state == Chain.DRAG:
		return "drag"
	if cleansing():
		return "cleanse"
	for m in marches:
		if not m.done and m.walking:
			return "march"
	if chain_state == Chain.BITE or chain_state == Chain.DRAG:
		return "drag"
	return "chain"


## The shrine and the two ways in: the gate pair and the camera's resting place.
func tour() -> Array:
	var out := []
	out.append([_shrine, "Mira's shrine, past the west wall. Drag three of Halcyon's lamplighters here."])
	if watch.size() >= 2 and _alive(watch[0]) and _alive(watch[1]):
		out.append([((watch[0] as Person).ground_pos + (watch[1] as Person).ground_pos) * 0.5, "The Watch holds the Main Gate. Anyone who sees a captive grips his chain."])
	out.append([CAMERA_AT, "Halcyon's lamplighters walk their rounds. Press C, then click one."])
	return out


## Base tags, then the marchers and the shrine's cleanse, then the Watch.
func tags() -> Array[MapTag]:
	var out := super.tags()
	var shrine_at := 0
	for i in out.size():
		if out[i].color == MARK_SHRINE:
			shrine_at = i
			if cleanse > 0.0 and not flame_out:
				out[i].label = TAG_CLEANSE % UiTheme.clock(CLEANSE_SECONDS - cleanse)
				out[i].ring = clampf(cleanse / CLEANSE_SECONDS, 0.0, 1.0)
	var idx := shrine_at + 1
	for m in marches:
		if m.done:
			continue
		for k in m.people.size():
			var v: Variant = m.people[k]
			if not _alive(v) or (v as Person).inside:
				continue
			var p := v as Person
			var label := TAG_CLERGY
			if k == 0 and not (m.walking and _kneeling_all(m)):
				label = (TAG_MUSTER % UiTheme.clock(m.muster_left)) if not m.walking else (TAG_LEADER % UiTheme.clock(m.eta))
			out.insert(idx, MapTag.person(p.ground_pos, EscortDirector.MARK_WATCHED, label, true))
			idx += 1
	for w: Variant in watch:
		if _alive(w) and not (w as Person).inside:
			out.append(MapTag.person((w as Person).ground_pos, EscortDirector.MARK_WATCHED, TAG_WATCH))
	return out


func report() -> Dictionary:
	var out := super.report()
	var rite: Dictionary = out["rite"]
	rite["marches"] = marches.size()
	return out


func teardown() -> void:
	for m in marches:
		for p: Variant in m.people:
			if is_instance_valid(p) and m.pace0.has(p):
				(p as Person).pace = float(m.pace0[p])
	super.teardown()
