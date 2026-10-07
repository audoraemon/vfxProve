class_name BrokenLanternsDirector
extends MissionDirector
## Broken Lanterns (v0.10 M3, the Ruin path's Night 2): Halcyon's six wayside shrines anchor his protection over the
## town. Break them before the Vigil relights them, and drink what was in them. A broken shrine is drained once it has
## stayed broken DRAIN_SECONDS. The flame-bearer walks the Vigil round the six, turns aside for a broken shrine, and
## relights it if he reaches it first (it stands again). A drained shrine is gone for good. All six drained win the
## night. A death someone sees adds to Halcyon's Gaze, and the bell fills it. Faithful pray at the standing shrines, and
## the prayer feeds the Gaze; at 1:30 four Lantern Knights come and guard the shrines; when five are drained, up to
## fifteen Faithful kneel round the last one, more coming as they are free (the bonus, if the blow falls through ten).
## The shrines are this mission's own: placed here, never in the shared town layout, and taken away with the town
## (Town._built).

## Where the six shrines stand, in the Vigil's order (ground units; each is moved to the nearest open ground). Each
## stands well beyond GUARD_REACH of the Temple's door, where the Knights come out, so no Knight guards one by
## standing there.
const SHRINE_SPOTS := [Vector2(5.5, -4.8), Vector2(10.2, -8.8), Vector2(12.0, 9.2), Vector2(0.5, 13.0),
	Vector2(-7.0, 10.0), Vector2(-7.5, -4.0)]
## A shrine's footprint and height (a stone post, Structure.Kind.SHRINE), and its role. The role is not one of
## Rules.BUILDING_ROLES, so a shrine is never a building in the tally, the chain or the score.
const SHRINE_SIZE := Vector2(0.4, 0.4)
const SHRINE_H := 22.0
const ROLE := &"shrine"
## Where the bearer stands to relight a shrine (from its centre), and how near its footprint he must be.
const RELIGHT_OFF := Vector2(0.0, 0.7)
const RELIGHT_REACH := 1.2
## A broken shrine is drained once it has stayed broken this long.
const DRAIN_SECONDS := 20.0
## How many Faithful there are besides the clergy (spec §4.1: about 20 devout citizens).
const FAITHFUL := 20
## Where the camera opens: the market, between the shrines.
const CAMERA_AT := Vector2(1.0, 2.0)
## The marks over the shrines: standing (Halcyon's gold), and broken but not yet drained (ember).
const MARK_LIT := Color(0.95, 0.82, 0.42, 0.9)
const MARK_DRAINING := Color("ff9a3a")
## The Knights' steel blue (v0.10 M6, spec §4.2): a Knight's tag, and a shrine one guards.
const MARK_KNIGHT := Color("8fb8e8")

## Each shrine broken (spec §4.1): every standing shrine is topped up to PRAYERS Faithful sent to pray there, on a ring
## PRAY_RING round it. On their duty and within PRAY_REACH of their place, they pray. Prayer feeds Halcyon's Gaze
## (GazeMeter.pray()), scaled by PRAYER_SCALE: 1.0 is the spec's rate, and the scale is this mission's own lever for
## balance, so M4's Gaze is untouched. Task 8 measured it: three praying at each of two standing shrines already reach
## PRAYER_CAP, so at 1.0 prayer alone fills the Gaze about 17 s after the first break, and at 0.2 or 0.1 prayer and the
## seen deaths together still filled it before the sixth shrine could drain.
const PRAYERS := 3
const PRAY_RING := 1.0
const PRAY_REACH := 0.6
const PRAYER_SCALE := 0.05
## A death someone sees adds this share of GazeMeter.SEEN_DEATH in this mission (LanternGaze): Ruin is loud, and one
## Heaven Splitter kills ten to twenty people, nearly all seen (Task 8 measured it). GazeMeter's own number stays for
## Mira's House and M4.
const SEEN_DEATH_SCALE := 0.05
## When five are drained, KNEELERS Faithful kneel round the last standing shrine on these rings ([radius, places]), all
## within BONUS_REACH of it (ThroughFaithfulObjective).
const KNEELERS := 15
const KNEEL_RINGS := [[1.0, 6], [1.7, 9]]
const BONUS_REACH := 2.0
## 1:30 -- KNIGHTS Lantern Knights come from the Temple and guard the standing shrines, each at one of a shrine's
## GUARD_OFFSETS places. A shrine with a living Knight within GUARD_REACH takes no damage.
const KNIGHTS_AT := 90.0
const KNIGHTS := 4
const GUARD_REACH := 1.5
const GUARD_OFFSETS := [Vector2(0.8, -0.6), Vector2(-0.8, -0.6)]
## Seconds between the director's looks at its prayers and Knights.
const TICK := 0.5
## Minds a prayer is sent back from (back on their feet). A Faithful in one of these, or on a duty, can be called.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var shrines: Array[Structure] = []
var vigil: VigilRoute
var temple_door := Vector2.INF
## Broken shrines not yet drained -> seconds left before they are.
var drain_left := {}
## Drained shrines (-> true): gone for good.
var drained := {}
## How many times the flame has relit a shrine.
var relit := 0
## Shrine -> where the bearer stands to relight it.
var _relight_at := {}

## Person -> [Structure, Vector2]: the Faithful sent to pray, at which shrine, and where.
var praying := {}
var kneelers: Array[Person] = []
## The shrine the kneelers ring, once five are drained.
var kneel_shrine: Structure
var knights: Array[Person] = []
## Knight -> the shrine he guards.
var guarding := {}
## Kneelers within BONUS_REACH of the last shrine when it last broke, counted the step before the blow.
var last_kneelers := 0
var _kneeling_near := 0
var _tick := 0.0


func _begin() -> void:
	gaze = LanternGaze.new()
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	_place_shrines()
	_choose_faithful(FAITHFUL)
	_start_vigil()
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	_add_events()
	rules.banner.emit("BREAK THE SIX LANTERNS")


func _place_shrines() -> void:
	for spot: Vector2 in SHRINE_SPOTS:
		var at := _walkable(spot)
		var s := crowd._env.add_structure(Rect2(at - SHRINE_SIZE * 0.5, SHRINE_SIZE), SHRINE_H, Structure.Kind.SHRINE, ROLE)
		s.damage_filter = _shield
		s.broken.connect(_on_broken)
		town._built.append(s)  # the town takes it away with its own buildings (Town.teardown())
		shrines.append(s)
		_relight_at[s] = _walkable(at + RELIGHT_OFF)


## The flame-bearer and his two acolytes are the clergy nearest the Temple's door (else any Faithful). They walk the six
## shrines round and round from the first, turning aside for broken ones, the flame passing on if the bearer falls.
func _start_vigil() -> void:
	var walkers := _vigil_walkers(faithful.duplicate(), temple_door)
	if walkers.is_empty():
		return
	var route := PackedVector2Array()
	for s in shrines:
		route.append(relight_point(s))
	var acolytes: Array[Person] = []
	acolytes.assign(walkers.slice(1))
	vigil = VigilRoute.new().setup(route, walkers[0], acolytes)
	vigil.loop = true
	vigil.pass_flame = true
	vigil.flame_passed.connect(func(_to: Person) -> void:
		rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME")
		_sync_detour())
	vigil.start()


func step(delta: float) -> void:
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	if vigil != null:
		vigil.step(delta)
	_drain(delta)
	_relight()
	_prayers_step(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()


## A shrine broke: it drains from the start (a relit shrine broken again starts over).
func _on_broken(s: Structure) -> void:
	if drained.has(s):
		return
	drain_left[s] = DRAIN_SECONDS
	rules.banner.emit("A LANTERN BREAKS")
	_broke(s)
	_sync_detour()


func _drain(delta: float) -> void:
	for s: Structure in drain_left.keys():
		drain_left[s] = float(drain_left[s]) - delta
		if float(drain_left[s]) > 0.0:
			continue
		drain_left.erase(s)
		drained[s] = true
		rules.banner.emit("A LANTERN IS DRAINED (%d / %d)" % [drained.size(), shrines.size()])
		if drained.size() == 1:
			_say("drained")  # Cael, at the first only (spec §5.2)
		_drained_one(s)
		_sync_detour()


## The flame-bearer at a broken shrine not yet drained relights it: it stands again, whole.
func _relight() -> void:
	if vigil == null or not vigil.active or not _alive(vigil.bearer):
		return
	for s: Structure in drain_left.keys():
		if s.distance_to(vigil.bearer.ground_pos) > RELIGHT_REACH:
			continue
		drain_left.erase(s)
		s.restore()
		relit += 1
		rules.banner.emit("THE FLAME RELIGHTS A LANTERN")
		_relit(s)
		_sync_detour()


## The bearer turns aside for the nearest broken shrine not yet drained, or goes back to his round when there is none.
func _sync_detour() -> void:
	if vigil == null or not vigil.active:
		return
	var from := vigil.bearer.ground_pos if _alive(vigil.bearer) else temple_door
	var best := Vector2.INF
	for s: Structure in drain_left.keys():
		var p := relight_point(s)
		if best == Vector2.INF or from.distance_to(p) < from.distance_to(best):
			best = p
	if best != vigil.detour:
		vigil.divert(best)


## Structure.damage_filter for every shrine: a guarded shrine (Task 6: a Lantern Knight beside it) only shakes; any
## other takes the blow as a structure does, cracking and then breaking.
func _shield(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	if guarded(s):
		s.shake(2.5)
		return
	s.hp -= amount
	s.mark_hit(amount / s.max_hp, kind)
	if s.hp <= 0.0:
		s.destroy(source, kind)
	elif s.hp < s.max_hp * Structure.CRACK_AT:
		s.crack()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)


func relight_point(s: Structure) -> Vector2:
	var p: Vector2 = _relight_at.get(s, s.center())
	return p


func draining(s: Structure) -> bool:
	return drain_left.has(s)


func is_drained(s: Structure) -> bool:
	return drained.has(s)


func drained_count() -> int:
	return drained.size()


func standing_shrines() -> Array[Structure]:
	var out: Array[Structure] = []
	for s in shrines:
		if not s.destroyed:
			out.append(s)
	return out


## The tags (v0.10 M6, spec §4.2), the most important first:
## - each standing shrine: GUARDED while a Knight guards it, else LANTERN;
## - each broken one draining, with its whole seconds left;
## - all of those pointed at from the edge;
## - the flame-bearer, pointed at while he is on his way to relight one;
## - each living Knight.
## A drained shrine has none.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for s in shrines:
		if not s.destroyed:
			var g := guarded(s)
			out.append(MapTag.place(s.center(), MARK_KNIGHT if g else MARK_LIT, "GUARDED" if g else "LANTERN", SHRINE_H))
		elif drain_left.has(s):
			out.append(MapTag.place(s.center(), MARK_DRAINING, "DRAINING %d" % ceili(float(drain_left[s])), SHRINE_H))
	if vigil != null and vigil.active and _alive(vigil.bearer):
		out.append(MapTag.person(vigil.bearer.ground_pos, MARK_LIT, "FLAME-BEARER", vigil.detour != Vector2.INF))
	for k in knights:
		if _alive(k):
			out.append(MapTag.person(k.ground_pos, MARK_KNIGHT, "KNIGHT"))
	return out


## The hint's phase (v0.10 M6, spec §4.2): "knights" while a Lantern Knight lives, else "".
func hint_phase() -> String:
	return "knights" if living_knights() > 0 else ""


## The tour (v0.10 M6, spec §5): a lantern, the flame-bearer, the Temple the Knights come out of.
func tour() -> Array:
	var out := []
	var standing := standing_shrines()
	if not standing.is_empty():
		out.append([standing[0].center(), "A lantern. Break it, then let it drain."])
	if vigil != null and _alive(vigil.bearer):
		out.append([vigil.bearer.ground_pos, "The flame-bearer relights broken lanterns."])
	if temple_door != Vector2.INF:
		out.append([temple_door, "The Temple. Lantern Knights come out of it later."])
	return out


func report() -> Dictionary:
	return {"drained": drained.size(), "relit": relit, "knights": living_knights()}


func teardown() -> void:
	_unhook_kills(_on_killed)
	for s in shrines:
		if is_instance_valid(s) and s.broken.is_connected(_on_broken):
			s.broken.disconnect(_on_broken)
	vigil = null
	timeline = null


func _add_events() -> void:
	timeline.add(KNIGHTS_AT, "knights", "The Lantern Knights", _knights_come)


func _prayers_step(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		_tend_prayers()
		_call_kneelers()
		_tend_knights()
	gaze.pray(praying_count(), delta * PRAYER_SCALE)
	_kneeling_near = kneeling_near()


## The shrine's prayers are let go (its kneelers stay by it), and every standing shrine is topped up.
func _broke(s: Structure) -> void:
	last_kneelers = _kneeling_near if s == kneel_shrine else 0
	for k: Variant in praying.keys():
		if praying[k][0] != s or kneelers.has(k):
			continue
		praying.erase(k)
		if _alive(k) and (k as Person).mind == Person.Mind.DUTY:
			(k as Person).leave_shelter(false)
	_call_prayers()


func _relit(_s: Structure) -> void:
	_maybe_kneel()


func _drained_one(_s: Structure) -> void:
	_maybe_kneel()


## A living Lantern Knight stands within GUARD_REACH of the shrine.
func guarded(s: Structure) -> bool:
	return guard_of(s) != null


func guard_of(s: Structure) -> Person:
	for k in knights:
		if _alive(k) and s.distance_to(k.ground_pos) <= GUARD_REACH:
			return k
	return null


func living_knights() -> int:
	var n := 0
	for k in knights:
		n += 1 if _alive(k) else 0
	return n


func faithful_near(at: Vector2, reach: float) -> int:
	var n := 0
	for f in faithful:
		n += 1 if _alive(f) and not f.inside and f.ground_pos.distance_to(at) <= reach else 0
	return n


## Each standing shrine is topped up to PRAYERS living Faithful sent to pray there, the nearest free ones first.
func _call_prayers() -> void:
	for s in standing_shrines():
		var have := 0
		for k: Variant in praying.keys():
			if praying[k][0] == s and _alive(k):
				have += 1
		for i in range(have, PRAYERS):
			var p := _free_faithful(s.center())
			if p == null:
				return
			_send(p, s, _ring(s, PRAY_RING, i, PRAYERS))


## The living Faithful nearest `at` who is free to be sent: out in the open, not walking the Vigil, not already sent,
## and on their day or back on their feet (or on a duty: a prayer whose shrine fell). Null when there is nobody.
func _free_faithful(at: Vector2) -> Person:
	var walking: Array[Person] = vigil.walkers() if vigil != null else ([] as Array[Person])
	var best: Person = null
	for f in faithful:
		if not _alive(f) or f.inside or praying.has(f) or walking.has(f):
			continue
		if not (f.mind in RESUMABLE or f.mind == Person.Mind.DUTY):
			continue
		if best == null or f.ground_pos.distance_to(at) < best.ground_pos.distance_to(at):
			best = f
	return best


func _send(p: Person, s: Structure, spot: Vector2) -> void:
	praying[p] = [s, spot]
	p.go_duty(spot)


## The i-th of n places on a ring of radius r round the shrine, on open ground.
func _ring(s: Structure, r: float, i: int, n: int) -> Vector2:
	return _walkable(s.center() + Vector2.from_angle(TAU * float(i) / float(n) + 0.4) * r)


## The dead are let go; those back on their feet are sent to their places again.
func _tend_prayers() -> void:
	for k: Variant in praying.keys():
		if not _alive(k):
			praying.erase(k)
			continue
		var p := k as Person
		if p.mind in RESUMABLE:
			var e: Array = praying[k]
			p.go_duty(e[1])


## The Faithful praying now: alive and out, on their duty within PRAY_REACH of their place, at a standing shrine.
func praying_count() -> int:
	var n := 0
	for k: Variant in praying.keys():
		if not _alive(k):
			continue
		var p := k as Person
		var e: Array = praying[k]
		var spot: Vector2 = e[1]
		if not p.inside and p.mind == Person.Mind.DUTY and not (e[0] as Structure).destroyed \
				and p.ground_pos.distance_to(spot) <= PRAY_REACH:
			n += 1
	return n


## Kneelers alive and out within BONUS_REACH of the last shrine.
func kneeling_near() -> int:
	if kneel_shrine == null:
		return 0
	var n := 0
	for p in kneelers:
		if _alive(p) and not p.inside and p.ground_pos.distance_to(kneel_shrine.center()) <= BONUS_REACH:
			n += 1
	return n


## Five drained and the last shrine standing: it becomes the kneelers' shrine, once a night. Whoever was praying
## anywhere is let go, free to kneel there with the others.
func _maybe_kneel() -> void:
	if kneel_shrine != null or drained.size() != shrines.size() - 1:
		return
	var last: Structure = null
	for s in shrines:
		if not drained.has(s):
			last = s
	if last == null or last.destroyed:
		return
	kneel_shrine = last
	praying.clear()
	_call_kneelers()
	rules.banner.emit("THE FAITHFUL KNEEL AT THE LAST LANTERN")


## While the kneelers' shrine stands, each empty place round it (up to KNEELERS) takes the nearest free Faithful: at
## five drained, then every TICK. So the dead are replaced, and those panicked, sheltering or held come to kneel once
## back on their feet; the Vigil's walkers and anyone frightened or held are never taken (_free_faithful()).
func _call_kneelers() -> void:
	if kneel_shrine == null or kneel_shrine.destroyed:
		return
	var taken := {}  # place -> how many living kneelers hold it (open ground may join two places into one)
	var living: Array[Person] = []
	for p in kneelers:
		if _alive(p) and praying.has(p):
			living.append(p)
			taken[praying[p][1]] = int(taken.get(praying[p][1], 0)) + 1
	kneelers = living
	for place in _kneel_places(kneel_shrine):
		if kneelers.size() >= KNEELERS:
			return
		if int(taken.get(place, 0)) > 0:
			taken[place] = int(taken[place]) - 1
			continue
		var p := _free_faithful(kneel_shrine.center())
		if p == null:
			return
		_send(p, kneel_shrine, place)
		kneelers.append(p)


func _kneel_places(s: Structure) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for ring: Array in KNEEL_RINGS:
		for i in int(ring[1]):
			out.append(_ring(s, float(ring[0]), i, int(ring[1])))
	return out


## 1:30 -- the Lantern Knights come from the Temple's door: soldiers with three times a soldier's health, who guard the
## standing shrines.
func _knights_come() -> void:
	for i in KNIGHTS:
		var k := crowd.add_soldier(_walkable(temple_door + Vector2(float(i) - float(KNIGHTS - 1) * 0.5, 0.6)))
		k.corps = Person.Corps.KNIGHT
		k.health = Person.HEALTH_KNIGHT
		knights.append(k)
	_tend_knights()
	_say("knights")


## Each living Knight to a standing shrine. One whose shrine fell goes to the standing shrine with the fewest Knights
## (the nearest of those). One taken off his place (an investigation) is sent back to it.
func _tend_knights() -> void:
	var standing := standing_shrines()
	for k in knights:
		if not _alive(k):
			continue
		var s: Structure = guarding.get(k)
		if s == null or s.destroyed:
			guarding.erase(k)
			s = _least_guarded(standing, k)
			if s == null:
				continue
			guarding[k] = s
		var place := _guard_place(s, k)
		if k.mind == Person.Mind.POST and k.anchor.distance_to(place) > 0.3:
			k.send_to_post(place, false, true)


func _least_guarded(standing: Array[Structure], k: Person) -> Structure:
	var best: Structure = null
	var best_n := 0
	for s in standing:
		var n := _guards(s).size()
		if best == null or n < best_n \
				or (n == best_n and s.center().distance_to(k.ground_pos) < best.center().distance_to(k.ground_pos)):
			best = s
			best_n = n
	return best


## The living Knights guarding `s`, in the order they came.
func _guards(s: Structure) -> Array[Person]:
	var out: Array[Person] = []
	for k in knights:
		if _alive(k) and guarding.get(k) == s:
			out.append(k)
	return out


func _guard_place(s: Structure, k: Person) -> Vector2:
	var i := maxi(_guards(s).find(k), 0)
	return _walkable(s.center() + (GUARD_OFFSETS[i % GUARD_OFFSETS.size()] as Vector2))


## Broken Lanterns' Gaze: a seen death adds SEEN_DEATH_SCALE of GazeMeter.SEEN_DEATH; all else is GazeMeter's.
class LanternGaze extends GazeMeter:
	func seen_death() -> void:
		add(GazeMeter.SEEN_DEATH * SEEN_DEATH_SCALE)
