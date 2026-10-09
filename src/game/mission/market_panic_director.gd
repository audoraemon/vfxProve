class_name MarketPanicDirector
extends FestivalDirector
## Market Panic (v0.11 M3, Tier 2, mission spec §2; Break, generalised from the Festival): a night fair at the north-east fountain
## (TownLayout.FOUNTAINS[1]). Three crowds of WAVE lay citizens come to it -- the first, the WAVE nearest the fountain, at the
## start; the second from SOURCES[1] at WAVE_AT[1] and the third from SOURCES[2] at WAVE_AT[2], or CHAIN after the crowd before
## is scattered (WAVE_NEED of it broken), whichever is sooner -- each strolling to a spot within FAIR_R of the fountain. Once
## there a goer holds to the fair (on duty at his spot: the town's regroup and evacuation pass him by) until he breaks or the
## market closes. WARDENS wardens -- watchmen at posts evenly round the fountain -- keep it: on guard (alive, out of doors, at his
## post, calm) a warden is fearless and steadies every goer within WARD_R: they are held fearless too and _may_break() says no, so
## a fright breaks none of them; a death still counts. A warden off his post goes back RETURN_AFTER after he left, once calm; a
## fallen one is replaced RELIEF_AFTER after he fell (Spoiled Harvest's rule, copied with its numbers: Decision 16). Breaking
## FAIR_NEED of the goers by the Festival's rule wins (FestivalObjective); the guard closing the market at MARKET_CLOSE loses
## (EventObjective). No Mayor, no address; one bonfire by the fountain.

## One warden's post (v0.11 M3): a plain record, so the director holds no cycle.
class Ward:
	extends RefCounted
	## The warden, held as a Variant and read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## Where he stands, beside the fountain.
	var post := Vector2.INF
	## Seconds since he was last on guard (alive but frightened, held or away).
	var away := 0.0
	## Seconds since he fell (a relief is sent RELIEF_AFTER after).
	var fallen := 0.0


## The fair's heart, the north-east fountain (v0.11 M3, Decision 13).
const HEART := Vector2(11.4, -10.0)
## Where each crowd comes from, and the tour's words for it (v0.11 M3, Decision 14): the quarter round the fair, the cathedral's
## street by the market's north-east corner, the workshops and the smithy.
const SOURCES := [Vector2(11.4, -10.0), Vector2(4.5, -4.0), Vector2(12.0, 1.0)]
const SOURCE_NAMES := ["the north-east quarter", "the cathedral's street", "the workshops"]
## Mission spec §2's numbers, tuned by Task 3's gate in this order: CHAIN (30-45), WAVE_AT, WARDENS (2-3), WARD_R, FAIR_R, FAIR_NEED
## (v0.11 M3; the spec's first guesses were WARDENS 2, WARD_R 4, FAIR_R 4.5 and FAIR_NEED 30). A crowd's size and how many of it
## scatter it; how many must break in all; when each crowd sets out at the latest; how long after one is scattered the next sets
## out at the latest; how many wardens, and how far each steadies.
const WAVE := 14
const WAVE_NEED := 10
const FAIR_NEED := 36
const WAVE_AT := [0.0, 90.0, 165.0]
const CHAIN := 45.0
const WARDENS := 3
const WARD_R := 5.5
## How far round the fountain the goers spread (v0.11 M3, Decision 13): one Heaven Splitter cannot take a whole crowd.
const FAIR_R := 5.5
## The wardens' posts lie this far from the fountain's centre, evenly round it -- three: 2.6 apart, more than one Silent Doom
## takes (v0.11 M3).
const WARD_SIDE := 1.5
## When the guard closes the market (v0.11 M3, Decision 17), in the timeline's seconds.
const MARKET_CLOSE := 270.0
## Where the bonfire burns, from the fountain (v0.11 M3, Decision 18).
const BONFIRE_OFF := Vector2(-1.6, 1.2)
## Seconds between looks at the goers; how near his spot a goer counts as arrived (v0.11 M3).
const TICK := 0.5
const ARRIVE := 0.6
## Where the camera rests (v0.11 M3, Decision 30): the fountain at the centre, the cathedral's street at the left below the HUD
## stack, the workshops at the bottom.
const CAMERA_AT := Vector2(10.0, -8.0)
## The map tags' colours (v0.11 M3): a warden red, the next crowd's source orange (the fair and its goers keep the Festival's gold).
const MARK_WARDEN := Color("c8342a")
const MARK_NEXT := Color("ff9a3a")

## Each crowd's goers, in the order they set out (v0.11 M3; Variants: any may be a body freed after its death fade).
var waves: Array = []
## The second each crowd set out, and was scattered; -1 until then (v0.11 M3).
var wave_out: Array[float] = []
var scattered_at: Array[float] = []
## The wardens' posts (v0.11 M3).
var wards: Array[Ward] = []
## A goer's instance id -> his spot at the fair; -> true once he has arrived there (v0.11 M3).
var _spots := {}
var _arrived := {}
## Seconds into the night, and to the next look (v0.11 M3).
var _clock := 0.0
var _tick_in := 0.0


## The night's setup (v0.11 M3): no Mayor, one bonfire, the need; the wardens set down at their posts; then the Festival's own
## setup, which sends the first crowd (_gather()) and adds the crowds' and the close's events (_add_events()).
func _begin() -> void:
	has_mayor = false
	need = FAIR_NEED
	fire_spots = [_walkable(HEART + BONFIRE_OFF)]
	for i in SOURCES.size():
		waves.append([])
		wave_out.append(-1.0)
		scattered_at.append(-1.0)
	for k in WARDENS:
		var w := Ward.new()
		w.post = _ring_spot(HEART, WARD_SIDE, k, WARDENS)
		var crew := _lay_near(w.post, 1, _busy())
		if not crew.is_empty():
			_make_warden(w, crew[0])
			_set_down(crew[0], w.post)
		wards.append(w)
	super()
	rules.banner.emit("THE NIGHT FAIR")


## The first crowd walks in at once (v0.11 M3): the Festival's own gathering, replaced.
func _gather() -> void:
	_send_wave(0)


## The crowds still to come and the market's close (v0.11 M3, Decisions 14, 17): the Festival's events, replaced.
func _add_events() -> void:
	for i in range(1, SOURCES.size()):
		timeline.add(float(WAVE_AT[i]), "crowd_%d" % i, "More come to the fair", _send_wave.bind(i),
			func() -> bool: return wave_out[i] < 0.0)
	timeline.add(MARKET_CLOSE, "close", "The guard closes the market")


## Crowd `i` sets out (v0.11 M3, Decision 14): the WAVE lay citizens nearest its source who are calm or regrouping, none at work
## for the fair, each strolling to his spot within FAIR_R of the fountain. Once only.
func _send_wave(i: int) -> void:
	if wave_out[i] >= 0.0:
		return
	wave_out[i] = _clock
	var picked := 0
	for p in _lay_near(SOURCES[i], crowd.citizens.size(), _busy()):
		if picked >= WAVE:
			break
		if not p.mind in WarningDirector.RESUMABLE:
			continue
		picked += 1
		goers.append(p)
		(waves[i] as Array).append(p)
		var spot := _fair_spot()
		_spots[p.get_instance_id()] = spot
		_send(p, spot)


## A spot within FAIR_R of the fountain on walkable ground (v0.11 M3: the plaza, the street and the gaps between houses).
func _fair_spot() -> Vector2:
	for attempt in 12:
		var spot := HEART + Vector2(crowd._rng.randf_range(-FAIR_R, FAIR_R), crowd._rng.randf_range(-FAIR_R, FAIR_R))
		if spot.distance_to(HEART) <= FAIR_R and (crowd._grid == null or crowd._grid.walkable(spot)):
			return spot
	return _walkable(HEART)


## Everyone at work for the fair (v0.11 M3): its goers and its wardens, for a new one to leave out.
func _busy() -> Array:
	var out: Array = []
	out.append_array(goers)
	for w in wards:
		if w.man != null:
			out.append(w.man)
	return out


## `p` keeps the fair at `w`'s post (v0.11 M3): a watchman, in the watch cloak and lantern.
func _make_warden(w: Ward, p: Person) -> void:
	w.man = p
	p.profile.role = CitizenProfile.Role.WATCHMAN
	p.profile.work = w.post


## One step (v0.11 M3): the Festival's (the timeline, and who has broken), the crowds' chain, the wardens every frame, and every
## TICK the steadied goers held and those at the fair kept there.
func step(delta: float) -> void:
	_clock += delta
	super(delta)
	_chain()
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	if looking:
		_tick_in = TICK
	_ward(delta, looking)
	if looking:
		_steady()
		_hold_fair()


## Each crowd with WAVE_NEED of it broken is scattered, and the strip shows the next one's chained time; each crowd still to come
## whose chain time has come sets out (v0.11 M3).
func _chain() -> void:
	for i in SOURCES.size():
		if scattered_at[i] < 0.0 and wave_out[i] >= 0.0 and wave_count(i) >= WAVE_NEED:
			scattered_at[i] = _clock
			if i + 1 < SOURCES.size():
				timeline.expect("crowd_%d" % (i + 1), wave_due(i + 1))
	for i in range(1, SOURCES.size()):
		if wave_out[i] < 0.0 and scattered_at[i - 1] >= 0.0 and _clock >= wave_due(i):
			rules.banner.emit("MORE COME TO THE FAIR")
			_send_wave(i)


## The second into the night crowd `i` sets out at the latest (v0.11 M3): its own time, or CHAIN after the crowd before was
## scattered if that is sooner. One not yet scattered never brings it forward.
func wave_due(i: int) -> float:
	var at := float(WAVE_AT[i]) * timeline.stretch_factor()
	if i > 0 and scattered_at[i - 1] >= 0.0:
		at = minf(at, scattered_at[i - 1] + CHAIN)
	return at


## Crowd `i`'s losses by the Festival's rule (v0.11 M3): dead, freed or broken; one who left the town unbroken is none of them.
func wave_count(i: int) -> int:
	var n := 0
	for p: Variant in waves[i]:
		if _left.has(p):
			continue
		if not is_instance_valid(p) or not (p as Person).is_alive() or _broke.has(p):
			n += 1
	return n


## Whether warden `w` is on guard now (v0.11 M3, Spoiled Harvest's GUARD_MINDS and GUARD_REACH): alive, out of doors, calm and at
## his post.
func _on_guard(w: Ward) -> bool:
	if not _alive(w.man):
		return false
	var p := w.man as Person
	return not p.inside and p.mind in HarvestDirector.GUARD_MINDS and p.ground_pos.distance_to(w.post) <= HarvestDirector.GUARD_REACH


## The wardens on guard now, the one nearest the fountain first (v0.11 M3).
func on_guard() -> Array[Person]:
	var out: Array[Person] = []
	for w in wards:
		if _on_guard(w):
			out.append(w.man as Person)
	out.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(HEART) < b.ground_pos.distance_to(HEART))
	return out


## The wardens' rule (v0.11 M3, copied from Spoiled Harvest's watchmen with their numbers): one on guard is held fearless
## (HOLD_POST past now); one alive but off his post is sent back RETURN_AFTER after he left, once calm; a fallen one is replaced
## RELIEF_AFTER after he fell.
func _ward(delta: float, looking: bool) -> void:
	for w in wards:
		if _on_guard(w):
			w.away = 0.0
			w.fallen = 0.0
			var man := w.man as Person
			man.fearless_left = maxf(man.fearless_left, HarvestDirector.HOLD_POST)
		elif _alive(w.man):
			w.fallen = 0.0
			w.away += delta
			if looking and w.away >= HarvestDirector.RETURN_AFTER:
				_recall(w)
		else:
			w.fallen += delta
			if looking and w.fallen >= HarvestDirector.RELIEF_AFTER:
				_relieve(w)


## The warden off his post, calm again, goes back to it (v0.11 M3).
func _recall(w: Ward) -> void:
	var p := w.man as Person
	if p.inside:
		return
	if p.mind in WarningDirector.RESUMABLE or (p.mind == Person.Mind.DUTY and p.anchor.distance_to(w.post) > 0.3):
		p.go_duty(w.post)


## A relief for a fallen warden (v0.11 M3): the lay citizen nearest his post not already at work for the fair walks to it.
func _relieve(w: Ward) -> void:
	var crew := _lay_near(w.post, 1, _busy())
	if crew.is_empty():
		return
	_make_warden(w, crew[0])
	w.fallen = 0.0
	w.away = 0.0
	crew[0].go_duty(w.post)
	rules.banner.emit("A NEW WARDEN TAKES THE POST")


## Goer `p` stands within WARD_R of a warden on guard (v0.11 M3, Decision 16). Only reads.
func steadied(p: Person) -> bool:
	for w in wards:
		if _on_guard(w) and (w.man as Person).ground_pos.distance_to(p.ground_pos) <= WARD_R:
			return true
	return false


## A steadied goer is not broken by a fright or a loud cast's danger (v0.11 M3); a death still counts.
func _may_break(p: Person) -> bool:
	return not steadied(p)


## Every goer still to break within WARD_R of a warden on guard is held fearless past the next look (v0.11 M3, Spoiled Harvest's
## HOLD_POST): a fright does not take him. One no warden steadies any more is let go of the hold at once, Spoiled Harvest's
## _release() way, so a fright takes him the moment the wardens are gone.
func _steady() -> void:
	for v: Variant in goers:
		if not _alive(v) or (v as Person).inside or _broke.has(v):
			continue
		var p := v as Person
		if steadied(p):
			p.fearless_left = maxf(p.fearless_left, HarvestDirector.HOLD_POST)
		elif p.fearless_left <= HarvestDirector.HOLD_POST:
			p.fearless_left = 0.0


## The goers at the fair hold to it (v0.11 M3, Decision 19): one who has reached his spot is put on duty there -- the town's
## regroup takes only the calm, and its evacuation passes those on duty by -- and, moved off it (a whisper, a fright) but unbroken
## and back on his feet, walks back. A walker the town sent home (regrouping) is sent on to the fair again.
func _hold_fair() -> void:
	for v: Variant in goers:
		if not _alive(v) or _broke.has(v) or _left.has(v) or (v as Person).inside:
			continue
		var p := v as Person
		var id := p.get_instance_id()
		var spot: Vector2 = _spots.get(id, HEART)
		if not _arrived.has(id):
			if p.ground_pos.distance_to(spot) <= ARRIVE or (not p.has_goal() and p.ground_pos.distance_to(HEART) <= FAIR_R + 1.0):
				_arrived[id] = true
			else:
				if p.mind == Person.Mind.REGROUP:
					_send(p, spot)
				continue
		if p.mind in WarningDirector.RESUMABLE or (p.mind == Person.Mind.DUTY and p.anchor.distance_to(spot) > 0.3):
			p.go_duty(spot)


## The goers still to break, out of doors (v0.11 M3).
func unbroken() -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in goers:
		if _alive(v) and not (v as Person).inside and not _broke.has(v) and not _left.has(v):
			out.append(v as Person)
	return out


## The goers still to break on their way to the fair, not yet arrived (v0.11 M3).
func walkers() -> Array[Person]:
	var out: Array[Person] = []
	for p in unbroken():
		if not _arrived.has(p.get_instance_id()):
			out.append(p)
	return out


## The next crowd still to set out, by index; -1 once all have (v0.11 M3).
func next_wave() -> int:
	for i in SOURCES.size():
		if wave_out[i] < 0.0:
			return i
	return -1


## The map tags (v0.11 M3, mission spec §2), most important first: THE FAIR with its count, pointed at from the edge; WARDEN on each
## warden on guard (a small red mark on one away from his post); NEXT CROWD at the next crowd's source, pointed at, until it sets
## out; a gold diamond on each goer still to break, walkers too. None once the fair is scattered.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if broken():
		return out
	out.append(MapTag.place(HEART, MARK_FEAST, "THE FAIR - %d / %d" % [count(), need], 0.0, true))
	for w in wards:
		if not _alive(w.man) or (w.man as Person).inside:
			continue
		var p := w.man as Person
		if _on_guard(w):
			out.append(MapTag.person(p.ground_pos, MARK_WARDEN, "WARDEN"))
		else:
			out.append(MapTag.pip(p.ground_pos, MARK_WARDEN))
	var next := next_wave()
	if next >= 0:
		out.append(MapTag.place(_walkable(SOURCES[next]), MARK_NEXT, "NEXT CROWD", 0.0, true))
	for p in unbroken():
		out.append(MapTag.pip(p.ground_pos, MARK_GOER))
	return out


## The hint's phase (v0.11 M3): "coming" while a later crowd walks in; else "open" with no warden on guard, "steadied" while some
## but not all of them stand, else "" (the mission's own line). "" once scattered.
func hint_phase() -> String:
	if broken():
		return ""
	for i in range(1, SOURCES.size()):
		if wave_out[i] < 0.0:
			continue
		for v: Variant in waves[i]:
			if _alive(v) and not _broke.has(v) and not _arrived.has((v as Person).get_instance_id()):
				return "coming"
	var standing := on_guard().size()
	if standing == 0:
		return "open"
	return "steadied" if standing < wards.size() else ""


## The tour (mission spec §2, v0.11 M3): the fair and its wardens, then the two later crowds' sources with their times ("by": the
## chain can bring them sooner), the last with the close.
func tour() -> Array:
	var out := []
	out.append([HEART, "The night fair at the north-east fountain. Its wardens (red) keep the crowd calm."])
	out.append([_walkable(SOURCES[1]), "More come from %s by %s." % [SOURCE_NAMES[1], UiTheme.clock(float(WAVE_AT[1]))]])
	out.append([_walkable(SOURCES[2]), "More come from %s by %s. The guard closes the market at %s." % [SOURCE_NAMES[2],
		UiTheme.clock(float(WAVE_AT[2])), UiTheme.clock(MARKET_CLOSE)]])
	return out
