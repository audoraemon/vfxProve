class_name SermonDirector
extends MirasHouseDirector
## The Sermon (v0.11 M5, Tier 4, mission spec §3; Convert, reused): a preacher holds the poor quarter. He preaches at the south-west
## well (TownLayout.WELLS[2]), his two acolytes ACOLYTE_OFF either side. While he preaches -- alive, out of doors, on duty at the
## pulpit -- every listener within VOICE of him is rapt: held deaf to a whisper and past fear, on duty. Whispered off, confused or
## frightened he is silent while held and preaches again back on his feet; dead he is silent for good, and an acolyte not held who
## sees it runs to the Temple. His crowd is twelve listeners in four waves of WAVE, appointed at the start by their sources and held
## deaf at them until their wave walks in (plan decision 183): the first at once, each next at WAVE_AT or CHAIN after the wave before is
## spent (each believes, is reading inside, is dead or is gone: the controller's idle ruling), whichever is sooner; each walks in on
## duty to a place on a ring RING from the preacher. Mira's rules otherwise: a listener whispered to the god's house goes in unless a
## Faithful within SIGHT of its door sees (then he is turned away, the seer runs to the Temple, and he walks back), reads READ and comes
## out a Believer -- who stands on duty on a ring BELIEVER_RING from the door until the night is won. Two sentries, Faithful watchmen,
## watch the door SENTRY_OFF either side of it; one off his post walks back RETURN_AFTER after he left (at once when the town begins to
## evacuate), a fallen one is replaced RELIEF_AFTER later (RELIEFS at most). Everyone the sermon holds is kept by the one rule,
## MissionDirector._hold_all(). A report delivered fills the Gaze; a seen death adds to it; the bell fills it. NEED Believers win; too
## few left to turn loses at once ("flock", lost_reason()); the sermon ends at SERMON_ENDS (EventObjective). The god's house only shakes
## tonight (plan decisions 183-190). Structure.destroy() ignores the damage filter: no power of the god's calls it on a house.

## One listener (v0.11 M5): a plain record, so the director holds no cycle.
class Listener:
	extends RefCounted
	## The listener, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## His wave (0 first), where he waits for it, and his place on the ring once it walks in.
	var wave := 0
	var source := Vector2.INF
	var spot := Vector2.INF


## One sentry's post (v0.11 M5): a plain record.
class Sentry:
	extends RefCounted
	## The sentry, a Variant read only through MissionDirector._alive().
	var man: Variant = null
	## Where he stands; seconds since he last saw the door (alive), and since he fell; he is a relief walking in.
	var post := Vector2.INF
	var away := 0.0
	var fallen := 0.0
	var relief := false


## The god's house is the dwelling nearest this point (v0.11 M5, Decision 143); the later waves' sources (the first is round the pulpit).
const HOUSE_SPOT := Vector2(-14.0, 10.4)
const SOURCES := [Vector2(-11.0, 3.0), Vector2(-2.0, 12.0), Vector2(-12.0, 6.0)]
## Mission spec §3's numbers (v0.11 M5), first guesses, tuned by the gate in this order: CHAIN (30-45), WAVE (3-4, NEED staying 8),
## WAVE_AT[1] (75-110), READ (6-10), VOICE (4-6). The need; the waves; their times and chain; the preacher's voice; the ring; the
## acolytes; the reading; the sentries; return and relief; the Faithful; the Believers' ring; the sermon's end.
const NEED := 8
const WAVE := 3
const WAVES := 4
const WAVE_AT := [0.0, 95.0, 185.0, 260.0]
const CHAIN := 45.0
const VOICE := 5.0
const RING := Vector2(2.5, 3.5)
const ACOLYTE_OFF := 1.0
## The ways round the pulpit an acolyte's place is tried, beside him first (v0.11 M5).
const ACOLYTE_DIRS := [Vector2.LEFT, Vector2.RIGHT, Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2.UP, Vector2(-1.0, 1.0),
	Vector2(1.0, 1.0), Vector2.DOWN]
const READ := 8.0
const SENTRIES := 2
const SENTRY_OFF := 1.5
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const FAITHFUL_LAY := 8
const BELIEVER_RING := 2.0
const SERMON_ENDS := 300.0
## How near the pulpit the preacher preaches; how long past each look a held listener stays deaf and fearless; how far round its
## source a waiting wave stands; how many dwellings _find_house() weighs; how hard a blow shakes the god's house (v0.11 M5).
const PREACH_REACH := 1.0
const HOLD := 1.0
const WAIT_R := 1.0
## How far (radians) and how many times a place on a ring is nudged to land on walkable, reachable ground (v0.11 M5).
const RING_NUDGE := 0.12
const RING_TRIES := 8
const HOUSE_TRIES := 12
const HOUSE_SHAKE := 2.0
## How long the bell's warning shows after the Gaze rises (v0.11 M5, the controller's ruling: before the bell is called).
const SEEN_SHOW := 8.0
## Where the camera rests (v0.11 M5, the controller's ruling, checked against the real HUD stack): the pulpit below the centre, the
## god's house and its western sentry at the left just under the stack, the waves' sources above and to the right, the Temple's arrow
## on the right edge. (The ruling's ~(-11, 10.5) left the god's door at (214, 161), under the stack's 240 x 165.)
const CAMERA_AT := Vector2(-13.0, 9.5)
## Seconds between looks, and the float slack a look is taken within (v0.11 M5: ten 0.05 s frames sum a hair short of 0.5).
const TICK := 0.5
const LOOK_SLACK := 0.0001
## The tags' gold for the crowd, grey for the silent preacher, orange for the next wave (v0.11 M5).
const MARK_GOLD := Color("d8b23a")
const MARK_GREY := Color("9a948a")
const MARK_NEXT := Color("ff9a3a")

## Where the preacher preaches (v0.11 M5).
var pulpit := Vector2.INF
## The preacher and his acolytes (Variants: any may be freed), and the acolytes' places (v0.11 M5).
var preacher: Variant = null
var acolytes: Array = []
var acolyte_spots: Array[Vector2] = []
## The twelve listeners and the sentries (v0.11 M5).
var listeners: Array = []
var sentries: Array = []
## Each wave has walked in; the second it was spent (-1 until then); how many sentries' reliefs came (v0.11 M5).
var called: Array[bool] = []
var spent_at: Array[float] = []
var reliefs := 0
## He preached at the last frame; where he fell, and it was judged (v0.11 M5).
var _was_preaching := true
var _preacher_fell := Vector2.INF
var _fall_judged := false
## The acolytes held by the god when he fell (v0.11 M5): they saw nothing. Untyped: either may be freed.
var _held_at_fall: Array = []
## Seconds into the night, and to the next look (v0.11 M5).
var _clock := 0.0
var _tick_in := 0.0
## The second of the last look (v0.11 M5): the sentries' timers count the real seconds between looks.
var _looked_at := 0.0
## The Gaze at the last frame, and seconds left of the bell's warning since it last rose (v0.11 M5).
var _gaze_was := 0.0
var _seen_left := 0.0


## The night's setup (v0.11 M5): its numbers (as First Prayers'), Mira's (the house, the people, the strip), the first wave walking in,
## and the refused whispers heard.
func _begin() -> void:
	need = NEED
	read_seconds = READ
	for w in WAVES:
		called.append(w == 0)
		spent_at.append(-1.0)
	super()
	rules.cast_refused.connect(_on_refused)
	for l: Listener in listeners:
		if l.wave == 0 and _alive(l.man):
			(l.man as Person).go_duty(l.spot)


## The night's opening banner (v0.11 M5).
func _opening_banner() -> String:
	return "THE SERMON"


## What the god's house's tag says (v0.11 M5).
func _house_label() -> String:
	return "GOD'S HOUSE"


## Dawn (v0.11 M5, as First Prayers): on the tier board a won night is held to dawn, so nobody is burned in; nobody goes in after it.
func _roof() -> void:
	roof_fallen = true


## The pulpit, and the god's house (v0.11 M5, Decision 143): the dwelling nearest HOUSE_SPOT, never set aside, whose door the street
## from the pulpit reaches beyond VOICE of it; it only shakes tonight (plan decision 184).
func _find_house() -> Structure:
	pulpit = _walkable(TownLayout.WELLS[2].get_center() + Vector2(0.0, -0.8))
	var skip: Array = []
	for i in HOUSE_TRIES:
		var h := _house_near(HOUSE_SPOT, skip)
		if h == null:
			return null
		var d := _open_door(h, pulpit)
		if d != Vector2.INF and d.distance_to(pulpit) > VOICE:
			h.damage_filter = _house_hit
			return h
		skip.append(h)
	return null


## Structure.damage_filter for the god's house (v0.11 M5): the blow only shakes it.
func _house_hit(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(HOUSE_SHAKE)


## The god's house's door (v0.11 M5): the one the street from the pulpit reaches, else Mira's front.
func _door_of(s: Structure) -> Vector2:
	var d := _open_door(s, pulpit) if pulpit != Vector2.INF else Vector2.INF
	return d if d != Vector2.INF else super(s)


## The people (v0.11 M5): the WAVE lay citizens nearest each wave's source, set down at it (the first where they stand) and on duty;
## the preacher and his acolytes, the clergy nearest the pulpit; the sentries, made Faithful watchmen; then every cleric and
## FAITHFUL_LAY of the rest are Faithful. No Inquisitor.
func _choose_people() -> void:
	var taken: Array = []
	for w in WAVES:
		var src: Vector2 = pulpit if w == 0 else _wave_source(w)
		var crowd_of := _lay_near(src, WAVE, taken)
		for k in crowd_of.size():
			var p := crowd_of[k]
			var l := Listener.new()
			l.man = p
			l.wave = w
			l.source = p.ground_pos if w == 0 else _wait_spot(src, k)
			l.spot = _ring_place(listeners.size())
			p.profile.faith = CitizenProfile.Faith.GRIEVING
			grieving.append(p)
			listeners.append(l)
			taken.append(p)
			_set_down(p, l.source)
			p.go_duty(l.source)
	var pr := _citizen_near(pulpit, CitizenProfile.Role.CLERGY, taken)
	if pr != null:
		preacher = pr
		taken.append(pr)
		_set_down(pr, pulpit)
		pr.go_duty(pulpit)
	for k in 2:
		var a := _citizen_near(pulpit, CitizenProfile.Role.CLERGY, taken)
		if a == null:
			break
		var spot := _acolyte_spot()
		taken.append(a)
		acolytes.append(a)
		acolyte_spots.append(spot)
		_set_down(a, spot)
		a.go_duty(spot)
	for k in SENTRIES:
		var st := Sentry.new()
		st.post = _sentry_post(k)
		var near := _lay_near(st.post, 1, taken)
		if not near.is_empty():
			var p := near[0]
			_make_sentry(p)
			st.man = p
			taken.append(p)
			_set_down(p, st.post)
			p.go_duty(st.post)
		sentries.append(st)
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
	venn = null


## The next acolyte's place (v0.11 M5): ACOLYTE_OFF from the pulpit on walkable ground, beside him first (west, then east), then
## round him, the first that lands within one Discord of him and beyond one Doom (the walk grid's cells can pull a spot nearer) and
## is not the other acolyte's; the pulpit's west side if none does.
func _acolyte_spot() -> Vector2:
	for dir: Vector2 in ACOLYTE_DIRS:
		var at := _walkable(pulpit + dir.normalized() * ACOLYTE_OFF)
		var gap := at.distance_to(pulpit)
		if gap > SilentDoom.RADIUS and gap <= DiscordFx.DISCORD_R and not acolyte_spots.has(at):
			return at
	return _walkable(pulpit + Vector2.LEFT * ACOLYTE_OFF)


## Wave `w`'s source (v0.11 M5): round the pulpit for the first, SOURCES[w - 1] for the rest.
func _wave_source(w: int) -> Vector2:
	return pulpit if w == 0 else _walkable(SOURCES[w - 1])


## The `k`th place on the preacher's ring (v0.11 M5): on its northern arc, RING.x and RING.y from him by turns (outside his witnesses'
## reach), the town's side of the well. The walk grid's cells can pull a point off the ring or into a closed yard, so the angle is
## nudged either way (RING_NUDGE, RING_TRIES times) until it lands on the ring's band, walked to from the pulpit, clear of the places
## taken before it; the first point if none does.
func _ring_place(k: int) -> Vector2:
	var n := WAVES * WAVE
	var angle := PI + 0.25 + (PI - 0.5) * float(k) / float(maxi(n - 1, 1))
	var radius: float = RING.x if k % 2 == 0 else RING.y
	var first := _walkable(pulpit + Vector2.from_angle(angle) * radius)
	for j in RING_TRIES:
		var turn := RING_NUDGE * floorf(float(j + 1) * 0.5) * (1.0 if j % 2 == 0 else -1.0)
		var at := _walkable(pulpit + Vector2.from_angle(angle + turn) * radius)
		var gap := at.distance_to(pulpit)
		if gap >= Crowd.DOOM_WITNESS + 0.2 and gap <= RING.y + 0.5 and _reaches(pulpit, at) and not _spot_taken(at):
			return at
	return first


## The `k`th waiting place round wave source `src` (v0.11 M5): on a ring WAIT_R round it, the first of RING_TRIES places from the `k`th
## with a way on foot to the pulpit (a point in a closed yard would hold its listener there for good); the source itself if none has.
func _wait_spot(src: Vector2, k: int) -> Vector2:
	for j in RING_TRIES:
		var at := _ring_spot(src, WAIT_R, k + j, WAVE)
		if _reaches(at, pulpit) and not _spot_taken(at, true):
			return at
	return _walkable(src)


## Someone at `from` can walk to `to` (v0.11 M5): the town has no walk grid, or it has a route.
func _reaches(from: Vector2, to: Vector2) -> bool:
	return crowd._grid == null or from.distance_to(to) < 0.3 or not crowd._grid.path(from, to).is_empty()


## A listener already has his place at (or, with `waiting`, waits at) about `at` (v0.11 M5).
func _spot_taken(at: Vector2, waiting := false) -> bool:
	for l: Listener in listeners:
		if (l.source if waiting else l.spot).distance_to(at) < 0.4:
			return true
	return false


## The `k`th sentry's post (v0.11 M5): SENTRY_OFF along the door's face, either side.
func _sentry_post(k: int) -> Vector2:
	var out := door - house.center() if house != null else Vector2.DOWN
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	return _walkable(door + along * SENTRY_OFF * (-1.0 if k == 0 else 1.0))


## `p` made a sentry (v0.11 M5): a watchman (the cloak and lantern) and one of Halcyon's Faithful.
func _make_sentry(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN
	_make_faithful(p)


## Everyone at the sermon's work (v0.11 M5): the preacher, his acolytes, every listener (the Believers among them) and the sentries --
## the people MissionDirector._hold_all() keeps, a relief leaves out and the tags' other watchers skip. Untyped, as any may be freed.
func _busy() -> Array:
	var out: Array = [preacher]
	out.append_array(acolytes)
	for l: Listener in listeners:
		out.append(l.man)
	for st: Sentry in sentries:
		out.append(st.man)
	return out


## The strip (v0.11 M5): each later wave at its time, and the sermon's end.
func _add_events() -> void:
	for w in range(1, WAVES):
		timeline.add(float(WAVE_AT[w]), "wave_%d" % w, "More come to hear him", _call_wave.bind(w), func() -> bool: return not called[w])
	timeline.add(SERMON_ENDS, "ends", "The sermon ends", Callable(), func() -> bool: return believers_outside() < need)


## Wave `w` walks in (v0.11 M5): each listener out of doors kept from the town's flight and on duty to his place on the ring.
func _call_wave(w: int) -> void:
	if called[w]:
		return
	called[w] = true
	for l: Listener in listeners:
		if l.wave == w and _alive(l.man) and not (l.man as Person).inside:
			_keep_from_flight(l.man as Person, true)
			(l.man as Person).go_duty(l.spot)


## Listener `l` is done with, for the chain (v0.11 M5, the controller's idle ruling): he believes, is inside reading, is dead or is
## gone -- the last of a wave whispered in starts the next wave's CHAIN, not his walk out READ later.
func _counted(l: Listener) -> bool:
	return not _alive(l.man) or believers.has(l.man) or (l.man as Person).inside


## Wave `w` is spent (v0.11 M5): each of its listeners is done with (_counted()).
func spent(w: int) -> bool:
	for l: Listener in listeners:
		if l.wave == w and not _counted(l):
			return false
	return true


## The second of the night wave `w` walks in at the latest (v0.11 M5): its own time, or CHAIN after the wave before is spent if sooner.
func wave_due(w: int) -> float:
	var at := float(WAVE_AT[w]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if w > 0 and spent_at[w - 1] >= 0.0:
		at = minf(at, spent_at[w - 1] + CHAIN)
	return at


## Seconds until wave `w` walks in at the latest (v0.11 M5); 0 once it has.
func due_in(w: int) -> float:
	return 0.0 if called[w] else maxf(wave_due(w) - _clock, 0.0)


## The first wave not yet walked in, or -1 (v0.11 M5).
func next_wave() -> int:
	for w in WAVES:
		if not called[w]:
			return w
	return -1


## Each wave newly spent is marked and the next one's chained time shown on the strip; each wave whose chained time has come walks in
## (v0.11 M5).
func _chain() -> void:
	for w in WAVES:
		if spent_at[w] < 0.0 and called[w] and spent(w):
			spent_at[w] = _clock
			if timeline != null and w + 1 < WAVES:
				timeline.expect("wave_%d" % (w + 1), wave_due(w + 1))
	for w in range(1, WAVES):
		if not called[w] and spent_at[w - 1] >= 0.0 and _clock >= wave_due(w):
			rules.banner.emit("MORE COME TO HEAR HIM")
			_call_wave(w)


## The preacher preaches now (v0.11 M5, plan decision 185): alive, out of doors, on duty within PREACH_REACH of the pulpit.
func preaching() -> bool:
	if not _alive(preacher):
		return false
	var p := preacher as Person
	return not p.inside and p.mind == Person.Mind.DUTY and p.ground_pos.distance_to(pulpit) <= PREACH_REACH


## The listener `v` is rapt now (v0.11 M5): his wave walked in, unturned and out of doors, within VOICE of the preaching preacher.
func rapt(v: Variant) -> bool:
	if not preaching() or not _alive(v) or believers.has(v):
		return false
	var p := v as Person
	var l := _listener_of(p)
	return l != null and called[l.wave] and not p.inside and p.ground_pos.distance_to((preacher as Person).ground_pos) <= VOICE


## `v` is held by the god (v0.11 M5): confused or whispered. Only reads.
func held(v: Variant) -> bool:
	return _alive(v) and (v as Person).mind in BLIND


## `p`'s Listener record, or null (v0.11 M5).
func _listener_of(p: Person) -> Listener:
	for l: Listener in listeners:
		if l.man == p:
			return l
	return null


## Every listener whose wave has walked in, alive, out of doors, not yet a Believer (v0.11 M5, for the policy and the tags).
func unturned() -> Array[Person]:
	var out: Array[Person] = []
	for l: Listener in listeners:
		if called[l.wave] and _alive(l.man) and not (l.man as Person).inside and not believers.has(l.man):
			out.append(l.man as Person)
	return out


## `p`'s place as a Believer (v0.11 M5): on a ring BELIEVER_RING round the god's door, by the order they came out.
func _believer_spot(p: Person) -> Vector2:
	return _ring_spot(door, BELIEVER_RING, maxi(believers.find(p), 0), NEED)


## Mira's step's events (v0.11 M5): the chain, the preacher's word, the acolytes' sight of his death, the god's house kept from fire,
## the bell's warning, and every TICK everyone the sermon holds kept by the one rule and each at his place.
func _step_events(delta: float) -> void:
	_clock += delta
	_chain()
	var now := preaching()
	if now and not _was_preaching:
		rules.banner.emit("THE PREACHER TAKES UP HIS SERMON")
	_was_preaching = now
	if _preacher_fell != Vector2.INF and not _fall_judged and crowd._doomed.is_empty():
		_acolytes_see()
	if house != null and crowd.fires != null and crowd.fires.is_burning(house):
		crowd.fires._put_out(house, true)
	_seen_left = maxf(_seen_left - delta, 0.0)
	if gaze.value > _gaze_was:
		_seen_left = SEEN_SHOW
	_gaze_was = gaze.value
	_tick_in -= delta
	if _tick_in > LOOK_SLACK:
		return
	_tick_in = TICK
	var since := _clock - _looked_at
	_looked_at = _clock
	var evacuating := _evacuation_began()
	_hold_all(_busy(), evacuating)  # the one rule (the controller's ruling): everyone the sermon holds, Believers among the listeners
	_keep_clergy(evacuating)
	for l: Listener in listeners:
		_keep_listener(l, now, evacuating)
	for v: Variant in believers:
		_keep_believer(v, evacuating)
	for st: Sentry in sentries:
		_keep_sentry(st, since, evacuating)


## The preacher and his acolytes kept at their places (v0.11 M5): back on his feet, each goes on duty there again.
func _keep_clergy(evacuating: bool) -> void:
	_recall_to(preacher, pulpit, evacuating)
	for k in acolytes.size():
		_recall_to(acolytes[k], acolyte_spots[k], evacuating)


## Listener `l` at his place (v0.11 M5): waiting, held deaf and fearless on duty at his source; walked in, on duty to his place on the
## ring (back on his feet after a whisper or a fright), and held while rapt.
func _keep_listener(l: Listener, preaching_now: bool, evacuating: bool) -> void:
	if not _alive(l.man) or believers.has(l.man):
		return
	var p := l.man as Person
	if p.inside:
		return
	if not called[l.wave]:
		_hold(p)
		_recall_to(p, l.source, evacuating)
		return
	if preaching_now and p.ground_pos.distance_to((preacher as Person).ground_pos) <= VOICE:
		_hold(p)
	_recall_to(p, l.spot, evacuating)


## `p` held deaf to a whisper and past fear past the next look (v0.11 M5, plan decision 94's hold).
static func _hold(p: Person) -> void:
	p._shaken_left = maxf(p._shaken_left, HOLD)
	p.fearless_left = maxf(p.fearless_left, HOLD)


## A Believer kept at his place by the door (v0.11 M5, Decision 147): out of the town's flight, on duty there.
func _keep_believer(v: Variant, evacuating: bool) -> void:
	if not _alive(v) or (v as Person).inside:
		return
	_recall_to(v, _believer_spot(v as Person), evacuating)


## Sentry `st` is on guard (v0.11 M5, plan decision 188): he sees the door.
func _on_guard(st: Sentry) -> bool:
	return _alive(st.man) and _sees(st.man, door, SIGHT, null)


## Sentry `st` at his work, every TICK, `since` seconds after the last look (v0.11 M5): on guard, kept on duty; off his post, sent back
## RETURN_AFTER after he left, or at once at the first look after the town began to evacuate (a relief walks on at once); fallen,
## replaced RELIEF_AFTER later (RELIEFS at most).
func _keep_sentry(st: Sentry, since: float, evacuating: bool) -> void:
	if _on_guard(st):
		st.away = 0.0
		st.fallen = 0.0
		st.relief = false
		if (st.man as Person).mind != Person.Mind.DUTY:
			_recall_to(st.man, st.post, evacuating)
		return
	if _alive(st.man):
		st.fallen = 0.0
		if (st.man as Person).inside:
			return
		st.away += since
		if st.relief or evacuating or st.away >= RETURN_AFTER:
			_recall_to(st.man, st.post, evacuating)
		return
	st.fallen += since
	if st.fallen >= RELIEF_AFTER and reliefs < RELIEFS:
		_relieve(st)


## A relief for fallen sentry `st` (v0.11 M5, The Crown's Bread's _relieve(), the controller's ruling): the nearest lay citizen with a
## way to the post (M4's _lay_reaching()), made a sentry; one chosen once the town is running is stopped from the flight first
## (go_duty() refuses a fleeing man). With none who can reach the post, the search backs off and is tried again RELIEF_AFTER later.
func _relieve(st: Sentry) -> void:
	var p := _lay_reaching(st.post, _busy())
	if p == null:
		st.fallen = 0.0
		return
	_make_sentry(p)
	st.man = p
	st.fallen = 0.0
	st.away = 0.0
	st.relief = true
	reliefs += 1
	if crowd._fled_all:
		_keep_from_flight(p, true)  # chosen once the town is running: never one of the flight
	p.go_duty(st.post)
	rules.banner.emit("A NEW SENTRY WATCHES THE GOD'S HOUSE")


## The sentries on guard now (v0.11 M5). Only reads.
func sentries_on_guard() -> Array[Person]:
	var out: Array[Person] = []
	for st: Sentry in sentries:
		if _on_guard(st):
			out.append(st.man as Person)
	return out


## The sentries alive and out of doors but off guard (v0.11 M5, for the scripted player: one whispered off, a relief walking in). Only
## reads.
func sentries_off() -> Array[Person]:
	var out: Array[Person] = []
	for st: Sentry in sentries:
		if _alive(st.man) and not (st.man as Person).inside and not _on_guard(st):
			out.append(st.man as Person)
	return out


## A sentry's relief walking in, or null (v0.11 M5, for the scripted player). Only reads.
func relief_walking() -> Person:
	for st: Sentry in sentries:
		if st.relief and _alive(st.man) and not (st.man as Person).inside and not _on_guard(st):
			return st.man as Person
	return null


## Out at the door (v0.11 M5): Mira's (a Faithful who sees runs to the Temple), then a Believer is kept from the flight and goes on duty
## to his place by the door (plan decision 187).
func _exit(p: Person) -> void:
	super(p)
	if _alive(p) and believers.has(p):
		_keep_from_flight(p, true)
		p.go_duty(_believer_spot(p))


## A death (v0.11 M5): Mira's (the Gaze's note, the reports' relay), and the preacher's fall, for his acolytes to see.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	super(e, kind)
	var v: Variant = preacher
	if v == e and _preacher_fell == Vector2.INF:
		_preacher_fell = e.ground_pos
		for a: Variant in acolytes:
			if held(a):
				_held_at_fall.append(a)
		rules.banner.emit("THE PREACHER IS SILENT")


## The preacher's death judged (v0.11 M5, plan decision 189): each acolyte not held who sees the fall within SIGHT runs to the Temple.
## One held when he fell saw nothing, though the seen death's fright may have shaken him out of it by the time it is judged (spec §3:
## "Discord holds all three; a Doom on him then ... sends no report").
func _acolytes_see() -> void:
	_fall_judged = true
	for a: Variant in acolytes:
		if not _held_at_fall.has(a) and _sees(a, _preacher_fell, SIGHT, null):
			_report(a as Person, temple_door)


## A report (v0.11 M5, plan decision 190): Mira's, its relay passing over the fleeing and the reserved (TempleReport.skip).
func _report(seer: Person, at: Vector2) -> void:
	var before := reports.size()
	super(seer, at)
	for i in range(before, reports.size()):
		reports[i].skip = _passed_over


## A relay never picks `p` (v0.11 M5, the M3 final review's rule): one fleeing the town or reserved.
func _passed_over(p: Person) -> bool:
	return p.mind == Person.Mind.FLEE or reserved.has(p)


## Too few left to turn (v0.11 M5, Decision 148): the living listeners, Believers among them, below NEED -- "flock"; else "".
func lost_reason() -> String:
	var n := 0
	for l: Listener in listeners:
		n += 1 if _alive(l.man) else 0
	return "flock" if n < need else ""


## A refused cast (Rules.cast_refused, v0.11 M5, plan decision 186): a whisper refused while his crowd is rapt says why.
func _on_refused(slot: int, why: String) -> void:
	if why != "shaken" or rules.key(slot) != "whisper":
		return
	for l: Listener in listeners:
		if rapt(l.man):
			rules.banner.emit("THEY HEAR ONLY HIM")
			return


## The bell's keeper while he is called or climbing, else null (v0.11 M5, the controller's ruling). Only reads.
func bellkeeper() -> Person:
	var bell := crowd.bell
	if bell == null or not bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return null
	var k: Variant = bell.keeper
	return k as Person if _alive(k) and not (k as Person).inside else null


## The map tags, most important first (v0.11 M5, mission spec §3): the god's house, outlined and pointed at; its door, clear or
## watched; each report's runner and the Temple while one runs; the called bellkeeper, red and pointed at (the controller's ruling);
## the preacher (grey while silent), pointed at; the next wave's source and time; each sentry on guard, a red diamond on a relief; a
## red diamond on any other Faithful who would see the door (Mira's watchers); the acolytes; a gold diamond on each listener not yet
## turned (a small red mark while rapt), green on each Believer.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if house != null:
		var h := MapTag.place(house.center(), MARK_HOUSE, _house_label(), house.height, true)
		h.outline = house.footprint
		out.append(h)
	var watched := faithful_seeing(door, SIGHT) != null
	out.append(MapTag.place(door, MARK_WATCHED if watched else MARK_CLEAR, "DOOR - WATCHED" if watched else "DOOR - CLEAR", 0.0, false))
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
	if _alive(preacher) and not (preacher as Person).inside:
		var on := preaching()
		out.append(MapTag.person((preacher as Person).ground_pos, MARK_WATCHED if on else MARK_GREY, "PREACHER" if on else "PREACHER - SILENT",
			true))
	var w := next_wave()
	if w > 0:
		out.append(MapTag.place(_wave_source(w), MARK_NEXT, "NEXT WAVE %s" % UiTheme.clock(due_in(w)), 0.0, true))
	for st: Sentry in sentries:
		if not _alive(st.man) or (st.man as Person).inside:
			continue
		if _on_guard(st):
			out.append(MapTag.person((st.man as Person).ground_pos, MARK_WATCHED, "SENTRY"))
		elif st.relief:
			out.append(MapTag.person((st.man as Person).ground_pos, MARK_WATCHED))
	var posted := _busy()
	for f in watchers(door, SIGHT):
		if not posted.has(f):
			out.append(MapTag.person(f.ground_pos, MARK_WATCHED))
	for a: Variant in acolytes:
		if _alive(a) and not (a as Person).inside:
			out.append(MapTag.person((a as Person).ground_pos, MARK_WATCHED))
	for l: Listener in listeners:
		if not _alive(l.man) or (l.man as Person).inside:
			continue
		var p := l.man as Person
		if believers.has(p):
			out.append(MapTag.person(p.ground_pos, MARK_CLEAR))
			continue
		out.append(MapTag.person(p.ground_pos, MARK_GOLD))
		if rapt(p):
			out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5): "bell" while the bell is called or climbing (plan decision 197); "report" while one runs; "seen" for
## SEEN_SHOW after the Gaze rose (the bell's warning before it is called, the controller's ruling); while he preaches, "coming" with a
## walked-in listener still on his way, else "rapt"; "watched" while a Faithful watches the door; else "".
func hint_phase() -> String:
	if crowd.bell != null and crowd.bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return "bell"
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			return "report"
	if _seen_left > 0.0:
		return "seen"
	if preaching():
		for p in unturned():
			if p.mind == Person.Mind.DUTY and not rapt(p):
				return "coming"
		return "rapt"
	return "watched" if faithful_seeing(door, SIGHT) != null else ""


## The tour (v0.11 M5, mission spec §3): the preacher, the god's house, the Temple.
func tour() -> Array:
	return [[pulpit, "The preacher at the south-west well. While he preaches, his crowd hears only him."],
		[door, "The god's house. Lead eight of his crowd here, unseen by the Faithful."],
		[temple_door, "The Temple. A Faithful who sees you runs here. Four deaths in a district call the bell."]]


## What the results show (v0.11 M5): the Believers, the reports, whether the preacher lives, the reliefs.
func report() -> Dictionary:
	return {"believers": believers_outside(), "reports": reports_started, "preacher": "alive" if _alive(preacher) else "silent",
		"reliefs": reliefs}


## Lets go of the god's house and the refused casts, then Mira's (v0.11 M5).
func teardown() -> void:
	if house != null and is_instance_valid(house):
		house.damage_filter = Callable()
	if is_instance_valid(rules) and rules.cast_refused.is_connected(_on_refused):
		rules.cast_refused.disconnect(_on_refused)
	super()
