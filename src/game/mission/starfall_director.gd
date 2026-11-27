class_name StarfallDirector
extends MissionDirector
## The Warning on the tier board (the Warning rework, spec 2): from 0:00 three watchmen stand at three posts, one star falls over the town (OMEN_AT), and
## each watchman sets off for the bellkeeper at his own time (STARS' first field), unless he has been stopped first. Each watchman is a WarningDirector
## of his own -- the post, the run, the relay, the unseen kill -- with the rework's flags on (holds_post, quiet_omen, dreams_stop, lead_key,
## bell_breaks, besides W1-W3): the stars' set-offs and the omen are in MISSION seconds (W-R13), so a toll brings the later ones sooner. The main
## objective (StarsObjective) is all three warnings stopped. v0.11.2: a Herald night -- the toll turns the Lantern, and the warning's carrier runs
## for the Temple (HeraldObjective loses the night only if one gets in); a blighted or fallen bell tower breaks the bell and buys time (W-R3).
## Each later runner starts nearer the bell (spec 8): the postern, the Main Gate, then the Side Gate.

## Each watchman: [seconds into the night he sets off (first guess), his post just inside his gate, the gate's name for the banner].
const STARS := [
	[20.0, Vector2(-5.75, 14.9), "THE POSTERN"],
	[40.0, Vector2(2.7, 14.5), "THE MAIN GATE"],
	[60.0, Vector2(14.5, 9.0), "THE SIDE GATE"],
]

## The quiet posts (spec 4, G3): no one but the watchman may stand within QUIET_R of a held post (first guess), so a kill there is unseen. The men moved
## out of a ring are put QUIET_R + QUIET_MARGIN from every post, along the line out from the post.
const QUIET_R := 3.0
const QUIET_MARGIN := 0.5
## Seconds between one turning-away of the same person.
const HUSH_EVERY := 0.5
## An idle citizen drifts about his anchor: one anchored within this of a post (QUIET_R plus his drift) is re-anchored at setup, past ANCHOR_R + QUIET_MARGIN.
const ANCHOR_R := 4.5
## The minds the hush leaves alone: a fright, a fight, the god's hold, a sleeper.
const HUSH_SKIP := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER, Person.Mind.FIGHT, Person.Mind.ASLEEP, Person.Mind.WHISPERED,
	Person.Mind.CONFUSED, Person.Mind.COMPELLED, Person.Mind.RALLY]
## How a man's nearness to a post is read: where he stands, where he stands or is posted, or where he is anchored.
enum Gap { HERE, HERE_OR_POSTED, ANCHORED }

## The mission second the one star falls over the town (first guess): each watchman looks up at it (STARE), then keeps his post.
const OMEN_AT := 1.0

## The town's posts and set-off times (v0.12, spec 1.5): seeded from the consts above, which are Aldermere's; a town's overrides replace them.
## (`stars` below is the list of warnings, so the schedule is `star_falls`.)
## The names a town's overrides may set (Overrides): the var above, which setup reads and never assigns.
const TOWN_VARS := ["star_falls"]
var star_falls: Array = STARS

## The three warnings, in the order they set off; each is set up on the first step (its `rules` is null until then).
var stars: Array[WarningDirector] = []
## Mission seconds into the night (v0.11.2: the schedule runs on the mission clock's rate; each warning's own run is real time).
var _clock := 0.0
## The one star has fallen (and each live watchman has looked up at it).
var _omen_done := false
## The warnings have been set up (the first step, after NightRules has made the town its own).
var _set_up := false
## The posts' ground (each post's walkable spot), set by _quiet_posts().
var _spots: Array[Vector2] = []
## The soldiers this director holds for the posts, each Person -> {"post": the post's index, "moved": whether he was moved out, "was": his own `post`}.
var _men := {}
## The idle citizens re-anchored out of a ring, each Person -> {"post": index, "was": his anchor}.
var _folk := {}
## Which posts have been held (by _quiet_posts()) and which have been let go.
var _held_once: Array[bool] = []
var _freed: Array[bool] = []
## Each person turned away -> the hush clock he was turned at.
var _turned := {}
var _hush_clock := 0.0


func _begin() -> void:
	for i in star_falls.size():
		var s: Array = star_falls[i]
		var w := WarningDirector.new()
		w.post = s[1]
		w.post_name = String(s[2])
		w.rework_reach = true  # (the Warning rework, W-R1) the new why_not reach, on the board only
		w.walls_stop = true  # (god T1R, spec 4.1) a carrier out of the walls, or one who reaches a keeper who heard ALL IS WELL, stops the warning
		w.lie_stops = true
		w.gate_keeps = true  # (god T1R fix round, D26) W3: a death just outside his gate draws the staring watchman out; the postern's has its key
		w.holds_post = true  # (the Warning rework, spec 3) he keeps his post until his set-off
		w.quiet_omen = true  # this director plays the one star
		w.dreams_stop = true  # a Discord on him at his post: he dreamt it
		w.lead_key = true  # K2: a whisper led through the postern's key
		w.bell_breaks = true  # W-R3: a blighted tower breaks the bell
		w.broken_said = i > 0  # (W-R16) THE BELL IS BROKEN shows once: only the first warning says it
		stars.append(w)


## Sets the warnings up on the first step, in STARS order, each leaving the others' people alone; then the one omen at OMEN_AT and each set-off at its time
## (mission seconds), for each watchman still at his post.
func step(delta: float) -> void:
	_clock += mission_delta(delta)
	if not _set_up:
		_set_up = true
		for w in stars:
			if not w.warning_dead:
				w.reserved = _reserved_for(w)
				w.setup(rules, crowd, town, ctx, night)
		_quiet_posts()
	for w in stars:
		if w.rules != null:
			w.step(delta)
	if not _omen_done and _clock >= OMEN_AT:
		_omen()
	for i in stars.size():
		if stars[i].at_post() and _clock >= float(star_falls[i][0]):
			stars[i].set_off()
	_say_broken()
	_release_posts()
	_hush_step(delta)


## The places the wishes may not pick a person from (spec 4, I9): each post's ring, with its margin. Read before setup(), so the posts are the raw spots.
func wish_keepout() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for st: Array in star_falls:
		var at: Vector2 = st[1]
		out.append(Vector3(at.x, at.y, QUIET_R + QUIET_MARGIN))
	return out


## `p` is one of the men this director holds for a post (the moved soldiers and the gate checkers): no town duty takes him (_holds_soldier).
func busy(p: Person) -> bool:
	return _men.has(p)


## The posts held now, by index: the watchman is at his post (not set off, not stopped). Only reads.
func posts_held() -> Array[int]:
	var out: Array[int] = []
	for i in stars.size():
		if stars[i].rules != null and stars[i].at_post():
			out.append(i)
	return out


## Spec 4 (G3), once, in the first step right after the three appointments (NightRules has run): every soldier whose post anchor or position lies within
## QUIET_R of a post is moved out and held, so is each checker of the three gates, and each idle citizen anchored in a ring is re-anchored. Deterministic:
## nearest first, then instance order; no RNG.
func _quiet_posts() -> void:
	_spots.clear()
	for st: Array in star_falls:
		_spots.append(_walkable(st[1]))
	_held_once.resize(stars.size())
	_freed.resize(stars.size())
	_held_once.fill(false)
	_freed.fill(false)
	var held := posts_held()
	for i in held:
		_held_once[i] = true
	var used: Array[Vector2] = []
	# The gate checkers first (GateCheck.checkers() skips a man this director holds), each held where he stands unless he is in a ring.
	if crowd.gate_check != null and town != null:
		for i in held:
			var gate := _gate_of(_spots[i])
			if gate == null:
				continue
			for c in crowd.gate_check.checkers(gate):
				_hold(c, i, false, c.post)
	var movers: Array = []
	for v: Variant in crowd.soldiers:
		if not _alive(v) or (v as Person).inside:
			continue
		var p := v as Person
		var i := _ring_of(p, held, QUIET_R, Gap.HERE_OR_POSTED)
		if i >= 0:
			movers.append([p, i, _gap(p, i, Gap.HERE_OR_POSTED)])
	for m: Array in _nearest_first(movers):
		_move_soldier(m[0] as Person, int(m[1]), used)
	var folk: Array = []
	for v: Variant in crowd.citizens:
		if not _alive(v):
			continue
		var p := v as Person
		if p.inside or p.mind != Person.Mind.CALM or p.has_goal() or reserved.has(p) or _is_watchman(p):
			continue
		var i := _ring_of(p, held, ANCHOR_R, Gap.ANCHORED)
		if i >= 0:
			folk.append([p, i, _gap(p, i, Gap.ANCHORED)])
	for m: Array in _nearest_first(folk):
		var p := m[0] as Person
		var at := _out_spot(p.anchor, int(m[1]), used, ANCHOR_R + QUIET_MARGIN)
		if at == Vector2.INF:
			continue
		used.append(at)
		_folk[p] = {"post": int(m[1]), "was": p.anchor}
		if p.ground_pos.distance_to(_spots[int(m[1])]) <= ANCHOR_R:  # (before the first frame: nobody sees him set down)
			p.ground_pos = at
			p._path = PackedVector2Array()
			p._target = at
		p.anchor = at


## [person, post, gap] rows, the nearest first, then in instance order (the same order on every run: no RNG).
func _nearest_first(rows: Array) -> Array:
	rows.sort_custom(func(a: Array, b: Array) -> bool:
		if not is_equal_approx(float(a[2]), float(b[2])):
			return float(a[2]) < float(b[2])
		return (a[0] as Person).get_instance_id() < (b[0] as Person).get_instance_id())
	return rows


## Whether `p` is one of the three watchmen, a messenger of a warning or a leaver (never moved or turned away).
func _is_watchman(p: Person) -> bool:
	for w in stars:
		if p == w.watchman or p == w.messenger or w.leaving.has(p):
			return true
	return false


## The gate nearest to `at`, or null.
func _gate_of(at: Vector2) -> Structure:
	var best: Structure = null
	for g in town.gates:
		if is_instance_valid(g) and (best == null or g.center().distance_to(at) < best.center().distance_to(at)):
			best = g
	return best


## The index of the held post whose ring (`r`) holds `p`, the nearest first; -1 for none.
func _ring_of(p: Person, held: Array[int], r: float, how: Gap) -> int:
	var best := -1
	var best_d := INF
	for i in held:
		var d := _gap(p, i, how)
		if d <= r and d < best_d:
			best = i
			best_d = d
	return best


## How near `p` is to post `i`, read as `how`.
func _gap(p: Person, i: int, how: Gap) -> float:
	match how:
		Gap.HERE:
			return p.ground_pos.distance_to(_spots[i])
		Gap.ANCHORED:
			return p.anchor.distance_to(_spots[i])
	return minf(p.ground_pos.distance_to(_spots[i]), p.anchor.distance_to(_spots[i]))


## A soldier out of a ring (B2): his `post` saved and set to the new spot, sent there and placed, `watch_far` off; held until the post is let go.
func _move_soldier(p: Person, i: int, used: Array[Vector2], place := true) -> void:
	var from := p.anchor if p.anchor.distance_to(_spots[i]) < p.ground_pos.distance_to(_spots[i]) else p.ground_pos
	var at := _out_spot(from, i, used, QUIET_R + QUIET_MARGIN, true, Vector2.INF if place else p.ground_pos)  # in play he walks out: a way that never leads in
	if at == Vector2.INF:
		at = _clear_spot(p.ground_pos, used, place)  # no straight way out: the nearest ground that is clear, set there (setup) or walked to (in play)
	if at == Vector2.INF and not place:
		at = p.ground_pos  # nothing at all in reach: he stands where he is, held
	if at == Vector2.INF:
		_hold(p, i, false, p.post)
		return
	used.append(at)
	if _men.has(p):
		# Already held (a gate checker held where he stood): now moved too, so his own `post` is given back with the rest.
		(_men[p] as Dictionary).moved = true
	else:
		_hold(p, i, true, p.post)
	p.post = at
	p.send_to_post(at)
	if place:  # only before the first frame; in play he is walked there
		p.ground_pos = at
		p._path = PackedVector2Array()
		p._target = at


## The nearest walkable ground to `from` (inside the walls, not taken, in a clear line from `from`) that is quiet: at setup at least QUIET_R + QUIET_MARGIN from
## every post; in play more than Crowd.DOOM_WITNESS (plus a hand's breadth) from every waiting watchman, so whoever stands there is no witness. Vector2.INF for none.
func _clear_spot(from: Vector2, used: Array[Vector2], setup: bool) -> Vector2:
	var grid := crowd._grid
	var watchers: Array[Vector2] = []
	for k in posts_held():
		watchers.append(stars[k].watchman.ground_pos)
	for step in range(1, 17):
		var d := 0.5 * float(step)
		for a in 16:
			var v := from + Vector2.RIGHT.rotated(TAU * float(a) / 16.0) * d
			if grid != null and (not grid.walkable(v) or not grid.clear_line(from, v)):
				continue
			if Walls.outside(v):
				continue
			var fits := true
			if setup:
				for sp in _spots:
					fits = fits and sp.distance_to(v) >= QUIET_R + QUIET_MARGIN - 0.01
			else:
				for w in watchers:
					fits = fits and w.distance_to(v) > Crowd.DOOM_WITNESS + 0.25
			for u in used:
				fits = fits and u.distance_to(v) >= 0.8
			if fits:
				return v
	return Vector2.INF


## Holds `p` for post `i` (busy): `moved` says his `post` was changed and must be given back, `was` what it was.
func _hold(p: Person, i: int, moved: bool, was: Vector2) -> void:
	if _men.has(p):
		return
	_men[p] = {"post": i, "moved": moved, "was": was, "far": p.watch_far}
	p.watch_far = false


## The nearest ground to post `i` along the line out from it through `from`, at least `r` from every post and not already taken, inside the walls and
## walkable (unless `within_walls` is off, for a walker turned back through the gate): tries each distance (nearest first) at the line's angle, then turning away from it. Vector2.INF for none. No RNG.
func _out_spot(from: Vector2, i: int, used: Array[Vector2], r: float, within_walls := true, walk_from := Vector2.INF) -> Vector2:
	var away := from - _spots[i]
	var dir := away.normalized() if away.length() > 0.05 else (-_spots[i]).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var grid := crowd._grid
	for step in 10:
		var d := r + 0.5 * float(step)
		for a: float in [0.0, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5, 2.0, -2.0, 2.5, -2.5, PI]:
			var v := _spots[i] + dir.rotated(a) * d
			if grid != null and not grid.walkable(v):
				continue
			if within_walls and Walls.outside(v):
				continue
			if walk_from != Vector2.INF and grid != null and not grid.clear_line(walk_from, v):
				continue  # a walker is sent where he can walk, in a straight line
			if walk_from != Vector2.INF and not _walks_out(walk_from, v, i):
				continue  # and his walk never goes in towards the post (nor into another's ring)
			var fits := true
			for sp in _spots:
				fits = fits and sp.distance_to(v) >= r - 0.01
			for u in used:
				fits = fits and u.distance_to(v) >= 0.8
			if fits:
				return v
	return Vector2.INF


## Whether the straight walk `a` -> `b` only ever goes away from post `i` (no nearer than where it starts) and keeps clear of the other posts' rings.
func _walks_out(a: Vector2, b: Vector2, i: int) -> bool:
	var d0 := a.distance_to(_spots[i])
	for k in range(1, 9):
		var q := a.lerp(b, float(k) / 8.0)
		if q.distance_to(_spots[i]) < d0 - 0.05:
			return false
		for j in _spots.size():
			if j != i and q.distance_to(_spots[j]) < QUIET_R and q.distance_to(_spots[j]) < a.distance_to(_spots[j]):
				return false
	return true


## Spec 4: while a post is held, anyone else within its ring is turned away -- not a carrier, a reserved man, one the god holds or one in flight: a goal
## inside the ring is moved out past it, one idle inside is walked out. A far-seeing man (`watch_far`) is turned from WATCH_SIGHT. A soldier at a post of
## the town (POST or HOLD, not on a job) who stands inside is taken as the first step took the rest. Each is turned at most every HUSH_EVERY seconds.
func _hush_step(delta: float) -> void:
	_hush_clock += delta
	var held := posts_held()
	if held.is_empty():
		return
	# Only the people near a held post can be turned: ask the field for each ring's patch (its widest turn radius is the far-seer's), never every soldier and citizen.
	var reach := maxf(QUIET_R + QUIET_MARGIN, Crowd.WATCH_SIGHT + 0.5)
	var patches: Array[Rect2] = []
	for i in held:
		patches.append(Rect2(_spots[i] - Vector2(reach, reach), Vector2(reach, reach) * 2.0))
	var near := {}
	for e in crowd._field.in_rects(patches):
		if e is Person:
			near[e] = true
	# A held man who is not near still loses his far sight (as it was when everyone was scanned).
	for v: Variant in _men.keys():
		if _alive(v):
			(v as Person).watch_far = false
	var rows: Array = []
	for v: Variant in near.keys():
		rows.append(v)
	rows.sort_custom(func(x: Person, y: Person) -> bool:
		if x.soldier != y.soldier:
			return x.soldier
		return x.get_instance_id() < y.get_instance_id())
	for v: Variant in rows:
		if not _alive(v):
			continue
		var p := v as Person
		# A wisher or wish target who is out walking his day is turned away too (I9): the wish is his, not the ring.
		if p.inside or p.mind in HUSH_SKIP or (reserved.has(p) and (p.soldier or p.mind != Person.Mind.CALM)) or _is_watchman(p):
			continue
		if _men.has(p):
			continue
		var r := maxf(QUIET_R + QUIET_MARGIN, Crowd.WATCH_SIGHT + 0.5) if p.watch_far else QUIET_R + QUIET_MARGIN  # turned on the ring's margin, so he is out before he can see
		var i := _ring_of(p, held, r, Gap.HERE)
		if i < 0 or _hush_clock - float(_turned.get(p, -INF)) < HUSH_EVERY:
			continue
		_turned[p] = _hush_clock
		var used: Array[Vector2] = []
		if p.soldier and (p.mind == Person.Mind.POST or p.mind == Person.Mind.HOLD) and p.corps == Person.Corps.NONE:
			_move_soldier(p, i, used, false)
			continue
		var at := _out_spot(p.ground_pos, i, used, r + QUIET_MARGIN, false, p.ground_pos)  # a walker is turned back the way he came, even out through the gate
		if at != Vector2.INF:
			p.set_goal(at)


## A post that stops being held (its warning stopped or its watchman set off) gives its men back: each moved soldier's `post` is restored and he goes
## back to it (B2: Crowd.off_duty() would do nothing for a man on a post), each re-anchored citizen's anchor too.
func _release_posts() -> void:
	for i in _freed.size():
		if _freed[i] or not _held_once[i] or (stars[i].rules != null and stars[i].at_post()):
			continue
		_freed[i] = true
		var held := posts_held()
		for p: Variant in _men.keys():
			if int((_men[p] as Dictionary).post) == i:
				var rec := _men[p] as Dictionary
				var home := _home_ring(p, held)
				if home >= 0:
					rec.post = home  # his own post lies in a ring still held: he is let go with that one, never walked into it
					continue
				_give_back(p, rec)
				_men.erase(p)
		for p: Variant in _folk.keys():
			if int((_folk[p] as Dictionary).post) == i:
				if _alive(p):
					(p as Person).anchor = (_folk[p] as Dictionary).was
				_folk.erase(p)


## The held post whose ring (with its margin) holds the town post of soldier `p`, or the straight way home to it, else -1.
func _home_ring(p: Variant, held: Array[int]) -> int:
	if not _alive(p) or (p as Person).town_post == Vector2.INF:
		return -1
	var from := (p as Person).ground_pos
	var home := (p as Person).town_post
	for j in held:
		for k in range(0, 13):  # his own post, or any step of the straight way home, in the ring
			if from.lerp(home, float(k) / 12.0).distance_to(_spots[j]) < QUIET_R + QUIET_MARGIN + 0.5:
				return j
	return -1


## One soldier given back: his own `post` again (so `post == town_post`: GateCheck and GuardJobs take him as before), and back to it.
func _give_back(p: Variant, rec: Dictionary) -> void:
	if not _alive(p) or not bool(rec.moved):
		return
	var s := p as Person
	s.post = rec.was
	if s.mind == Person.Mind.POST or s.mind == Person.Mind.HOLD:
		s.back_to_post()


## The one star over the Main Gate's post (the middle post), the banners, and each live watchman's look-up (his own `_omen()`, quiet).
func _omen() -> void:
	_omen_done = true
	var at := _walkable(star_falls[mini(1, star_falls.size() - 1)][1])
	if ctx != null:
		FxTimeline.cast(FallingStarFx, ctx, at + Vector2(0.0, 0.8))
	rules.banner.emit("A STAR FALLS OVER THE TOWN")
	rules.banner.emit("STOP THE WARNINGS")
	for w in stars:
		if w.rules != null and not w.warning_dead and not w.omen_fallen:
			w._omen()


## THE BELL IS BROKEN, once (W-R16): the first warning says it in its own step; if it has been stopped by then (it never steps again), the director does.
func _say_broken() -> void:
	var w := stars[0]
	if w.rules != null and w.warning_dead and not w.broken_said and w.herald_night() and w.bell_broken():
		w.broken_said = true
		rules.banner.emit(WarningDirector.BROKEN_BANNER)


## Mission seconds until star `i`'s watchman sets off (never below 0): INF once he has set off or been stopped. Before the warnings are set up it is the
## schedule's. Only reads.
func sets_off_in(i: int) -> float:
	var w := stars[i]
	if w.warning_dead:
		return INF
	if w.rules != null and not w.at_post():
		return INF
	return maxf(0.0, float(star_falls[i][0]) - _clock)


## The seconds the task line counts: the soonest set-off still to come, else 0.
func step_seconds() -> float:
	var best := INF
	for i in stars.size():
		best = minf(best, sets_off_in(i))
	return best if best < INF else 0.0


## Who a star about to be set up must leave alone (v0.11 M1): this director's reserved people -- the wishers and wish
## targets -- and the watchman and messenger of every star already set up and still alive, so one kill never ends two.
func _reserved_for(next: WarningDirector) -> Array[Person]:
	var out: Array[Person] = reserved.duplicate()
	for w in stars:
		if w.rules != null:
			for p: Variant in w.leaving:  # (god T1R) a stopped carrier walking off the map is nobody's watchman
				if is_instance_valid(p) and not out.has(p):
					out.append(p as Person)
		if w == next or w.rules == null or w.warning_dead:
			continue
		# Variants: a runner killed on an earlier star may be freed by now (_alive() rules the same way).
		for p: Variant in [w.watchman, w.messenger]:
			if is_instance_valid(p) and not out.has(p):
				out.append(p as Person)
	return out


## How many warnings have been stopped (killed unseen with their messenger).
func stopped() -> int:
	var n := 0
	for w in stars:
		n += 1 if w.warning_dead else 0
	return n


## StarsObjective's count (v0.11 M3 final review): the warnings stopped, of the night's stars.
func stars_stopped() -> int:
	return stopped()


## StarsObjective's count (v0.11 M3 final review): one warning for each star.
func stars_total() -> int:
	return stars.size()


## The warning that has set off and lives, the latest of them first (a watchman still at his post is not running); null for none.
func running() -> WarningDirector:
	for i in range(stars.size() - 1, -1, -1):
		var w := stars[i]
		if w.rules != null and not w.warning_dead and w.phase != WarningDirector.Phase.OVER and not w.at_post():
			return w
	return null


## The tags (spec 6.1), most important first: each live watchman's own -- "WATCHMAN - SETS OFF IN m:ss" until he sets off, then his carrier tag -- the
## bellkeeper and the bell tower once (not per warning), the Temple's door unless the Lantern draws its own, then the witnesses.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	var live: Array[WarningDirector] = []
	var herald := false
	var broken := false
	var running_to_keeper := false
	var keeper_carries := false
	for i in range(stars.size() - 1, -1, -1):
		var w := stars[i]
		if w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER or not WarningDirector._alive(w.messenger):
			continue
		live.append(w)
		herald = herald or w.herald_open()
		broken = broken or w.bell_broken()
		running_to_keeper = running_to_keeper or w.phase == WarningDirector.Phase.RUN
		if w.crowd.bell != null and w.messenger == w.crowd.bell.keeper:
			keeper_carries = true
		if w.at_post():
			out.append(MapTag.person(w.messenger, WarningDirector.MARK_MESSENGER, "WATCHMAN - SETS OFF IN %s" % UiTheme.clock(sets_off_in(stars.find(w))), true))
		else:
			out.append_array(w.carrier_tags())
	var bell := crowd.bell
	if bell != null and not herald and not broken:
		var keeper: Person = bell.keeper if WarningDirector._alive(bell.keeper) else null
		if keeper != null and not keeper_carries and not keeper.inside and not live.is_empty():
			out.append(MapTag.person(keeper, WarningDirector.MARK_KEEPER, live[0]._keeper_label(), running_to_keeper))
		if is_instance_valid(bell.tower) and not bell.tower.destroyed and not live.is_empty():
			out.append(MapTag.place(bell.tower.center(), WarningDirector.MARK_WATCHED, "BELL TOWER", bell.tower.height, false))
	if rules.lantern == null or not rules.lantern.herald_running():
		out.append(MapTag.place(lantern_door(), LanternWatch.MARK_TEMPLE, "TEMPLE", 0.0, false))
	for w in live:
		out.append_array(w.witness_tags())
	return out


## The hint's phase (spec 6.2), the most urgent live warning first; never "": herald (a Herald runs), bell (the keeper carries it), relay (a witness does),
## running (a watchman has set off), broken (the bell is broken and only watchmen at their posts remain), else posts.
func hint_phase() -> String:
	var order := ["herald", "bell", "relay"]
	for ph: String in order:
		for w in stars:
			if w.rules != null and not w.warning_dead and w.hint_phase() == ph:
				return ph
	var posts := true
	var broken := false
	for w in stars:
		if w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER:
			continue
		broken = broken or w.bell_broken()
		if not w.at_post():
			return "running"
	return "broken" if broken else "posts"


## Every phase hint_phase() can return (spec 6.2).
func hint_phases() -> PackedStringArray:
	return PackedStringArray(["herald", "bell", "relay", "running", "broken", "posts"])


## Mission clarity (spec 5.1, review focus 3): the banner of the first warning a cast reaches and will not stop -- unless the cast could stop
## any warning it reaches (the watchmen stand close: a kill that stops one is "" though it lands near another's carrier). A warning
## a kill has just stopped counts too: its carrier's body is where the kill fell. Then (W-R3, I6) Blight on the bell tower says what it does:
## TOLLED first, SOONER if any live warning would be sooner by the broken bell, else TIME. Only reads.
func why_not(key: String, at: Vector2) -> String:
	var text := ""
	for w in stars:
		if w.rules == null:
			continue
		var reach := w._carrier_reach(key, at)
		if reach == WarningDirector.Reach.MAYBE:
			return ""
		if reach == WarningDirector.Reach.NOT and text == "":
			text = WarningDirector.STOPS_BANNER
	var bell := _bell_why(key, at)
	if bell != "":
		return bell
	for w in stars:  # a spark that only lights a watchman: he runs burning (no cast that could stop a warning got here)
		if w.rules != null and w.burn_why(key, at) != "":
			return WarningDirector.BURN_BANNER
	return text


## The honest banner for Blight on the tower, over every warning (each answers for its own carrier): TOLLED, else SOONER if any says so, else TIME; "" for none.
func _bell_why(key: String, at: Vector2) -> String:
	var text := ""
	for w in stars:
		if w.rules == null:
			continue
		var said := w.bell_why(key, at)
		if said == WarningDirector.BELL_TOLLED:
			return said
		if said == WarningDirector.BELL_SOONER or text == "":
			text = said
	return text


## The tour (spec 6.3): each post, the bellkeeper, then the Temple's door.
func tour() -> Array:
	var out := []
	for s: Array in star_falls:
		out.append([_walkable(s[1]), "%s's watchman. He sets off for the bellkeeper at %s." % [String(s[2]).capitalize(), UiTheme.clock(float(s[0]))]])
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		out.append([bell.keeper.ground_pos, "The bellkeeper. Warned, he rings the bell: the Lantern turns, and he runs for the Temple."])
	out.append([lantern_door(), "The Temple. A warning that reaches it loses the night."])
	return out


## The toll fell (v0.11.2, spec 4.6): every warning that is up hears of it (a Herald's errand is the Temple); a star yet to fall finds the
## Lantern already tolled when its watchman runs.
func on_toll() -> void:
	for w in stars:
		if w.rules != null:
			w.on_toll()


## `p` is the Herald of one of the warnings that are up (v0.11.2).
func claims_herald(p: Person) -> bool:
	for w in stars:
		if w.rules != null and w.claims_herald(p):
			return true
	return false


## One of the warnings runs for the Temple as a Herald (v0.11.2).
func herald_open() -> bool:
	for w in stars:
		if w.rules != null and w.herald_open():
			return true
	return false


## Loss warning: each of the stars' own threats (a Herald, a witness's word), its id numbered by the star it is, so a second one running is a
## new warning; then the base's.
func threats() -> Array[Dictionary]:
	var out := super()
	for i in stars.size():
		if stars[i].rules != null:
			out.append_array(NightThreat.suffixed(stars[i].threats(), str(i)))
	return out


## The soonest of the Heralds' arrivals, in mission seconds (v0.11.2).
func herald_eta() -> float:
	var best := INF
	for w in stars:
		if w.rules != null:
			best = minf(best, w.herald_eta())
	return best


## The results' report (v0.11 M1): the warnings stopped, the relays all three made, and how they were stopped (out, lie, dreamt).
func report() -> Dictionary:
	var relays := 0
	var out := 0
	var lies := 0
	var dreamt := 0
	for w in stars:
		relays += w.relays
		out += 1 if w.stopped_how == "out" else 0
		lies += 1 if w.stopped_how == "lie" else 0
		dreamt += 1 if w.stopped_how == "dreamt" else 0
	return {"stopped": stopped(), "relays": relays, "out": out, "lies": lies, "dreamt": dreamt}


func teardown() -> void:
	for p: Variant in _men.keys():
		var rec := _men[p] as Dictionary
		_give_back(p, rec)
		if _alive(p):
			(p as Person).watch_far = bool(rec.get("far", false))  # his sight back, as a checker had it
	_men.clear()
	for p: Variant in _folk.keys():
		if _alive(p):
			(p as Person).anchor = (_folk[p] as Dictionary).was
	_folk.clear()
	_turned.clear()
	if crowd != null:
		crowd.wish_keepout = [] as Array[Vector3]
	for w in stars:
		if w.rules != null:
			w.teardown()
