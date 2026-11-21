class_name GateCheck
extends Duty
## The gate check (soldier duties, slice e): the wall guards at a gate -- up to PER_GATE, corps NONE or MARSHAL, whose town post lies
## within POST_REACH of it -- look over everyone who comes through it. A person who is guised (Corpse Guise) or in the god's hand
## (whispered, confused, compelled, staring at a lure) and stands within a checker's sight (WATCH_SIGHT, NO SIGHT caps it, a veil
## hides him) is spotted: the guise or the hold ends, an incident and an alarm are written, the checker wears a "!" and a banner
## says so. A corps-NONE checker holds a GATE record (so no one takes him for a director's man), steps to a spot beside the mouth
## when anyone comes near it and steps back after STAND_DOWN s of nobody; a marshal checks where he stands. The check never touches a
## gate's own clock or queue, and nothing here draws a number from any rng.

## Checkers at a gate, how far from the gate's centre their town posts may lie, how near the mouth a walker must be to bring them out
## (and to be looked at), and the alarm a spot adds.
const PER_GATE := 2
const POST_REACH := 2.5
const GATE_LOOK := 2.5
const GATE_SPOT_ALARM := 2.0
## Seconds with nobody near the mouth before a NONE checker steps back to his post.
const STAND_DOWN := 5.0
## A person is spotted at most once per gate in this many seconds.
const REPEAT_SECONDS := 10.0
## Seconds an unfilled GATE job waits for its man before it lets go (it is posted again at the next tick).
const OPEN_SECONDS := 20.0
## The post group of the wall guards.
const WALL_GROUP := 1
## The tag and the banner, the colour of the tag and the eye badge, and how long each badge is set for.
const TAG := "GATE CHECK"
const BANNER := "THE GATE GUARD SEES THROUGH IT"
const COLOUR := Color(0.95, 0.8, 0.35)
const BADGE_SECONDS := 1.5
const ALERT_SECONDS := 2.0

## Gate instance id -> {person instance id -> the crowd clock when he was last spotted there} (ids are only ever keys).
var _spotted := {}
## Gate instance id -> the crowd clock when anyone was last near its mouth.
var _near_at := {}
## The men this duty set `watch_far` and the eye badge on (checkers on their spot, marshals at their gate).
var _marked := {}
## Gate instance id -> the crowd clock of its last incident and alarm (one charge per gate per REPEAT_SECONDS).
var _charged := {}
## The ones let out of a queue this frame, [person, gate], looked at after the queue loop.
var _pending: Array = []
## The gates' centres whose tag shows (refreshed on every board tick).
var _shown: Array[Vector2] = []


func kind() -> int:
	return GuardJobs.Kind.GATE


## The men who check `gate` -- up to PER_GATE living wall-group soldiers of no corps or the marshals' whose town post lies within
## POST_REACH of its centre, nearest first (ties by stagger); no director's man (a stationed or named one is no checker).
func checkers(gate: Structure) -> Array[Person]:
	var out: Array[Person] = []
	if not is_instance_valid(gate):
		return out
	var at := gate.center()
	for p in crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.post_group != WALL_GROUP or p.town_post == Vector2.INF:
			continue
		if (p.corps != Person.Corps.NONE and p.corps != Person.Corps.MARSHAL) or p.town_post.distance_to(at) > POST_REACH:
			continue
		if p.corps == Person.Corps.NONE and board.mission_man(p):
			continue
		out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.town_post.distance_to(at)
		var db := b.town_post.distance_to(at)
		if da != db:
			return da < db
		return a.stagger < b.stagger)
	if out.size() > PER_GATE:
		out.resize(PER_GATE)
	return out


## Whether at least one checker of `gate` is looking now: a NONE man on his spot, or a marshal within GATE_LOOK of the mouth, free and
## in no hand but the town's.
func checked(gate: Structure) -> bool:
	for c in checkers(gate):
		if _active(c, gate):
			return true
	return false


## `p`, within sight of a checker of `gate` (and not veiled), is looked at: when he is guised or the god holds him he is spotted
## (unmask(), an incident, GATE_SPOT_ALARM, the "!" badge, the banner) and the call is true. Soldiers are never checked, nobody is
## checked twice at a gate within REPEAT_SECONDS, and a hushed town hears and writes nothing (the banner still shows).
func check(p: Person, gate: Structure) -> bool:
	if not board.is_open() or not is_instance_valid(p) or not is_instance_valid(gate) or p.soldier or not p.is_alive() or p.inside:
		return false
	if p.answers_lure:
		return false  # a director's charge (the Lamb, the prisoner, First Prayers' people) passes untouched
	if not (p.guised() or p.held_by_god()) or crowd.is_veiled(p.ground_pos):
		return false
	var gid := gate.get_instance_id()
	var seen: Dictionary = _spotted.get(gid, {})
	if crowd._clock - float(seen.get(p.get_instance_id(), -INF)) < REPEAT_SECONDS:
		return false
	var by := _watcher(gate, p)
	if by == null:
		return false
	seen[p.get_instance_id()] = crowd._clock
	_spotted[gid] = seen
	p.unmask()
	var at := gate.center()
	by.set_badge(GuardJobs.GLYPH_ALERT, COLOUR, ALERT_SECONDS)
	# One gate, one charge: the incident, the alarm and the banner come once per REPEAT_SECONDS however many are spotted.
	if crowd._clock - float(_charged.get(gid, -INF)) < REPEAT_SECONDS:
		return true
	_charged[gid] = crowd._clock
	if not crowd.is_hushed() and not crowd.is_hushed_at(at):
		if crowd.alarms.incident(at):
			crowd._investigate(at)
		crowd._hear_alarm(GATE_SPOT_ALARM)
	crowd.duty_event.emit(GuardJobs.Kind.GATE, BANNER, at)
	return true


## The one let out of the queue at `gate` (Crowd._gates()): looked at once the queue's loop is over, so the queue, the release
## clock and the counts are as without checkers.
func note_release(p: Person, gate: Structure) -> void:
	if p.guised() or p.held_by_god():
		_pending.append([p, gate])


## Looks at everyone noted since the last call (Crowd._gates(), after its loop).
func apply_pending() -> void:
	var list := _pending
	_pending = []
	for e in list:
		if is_instance_valid(e[0]) and is_instance_valid(e[1]):
			check(e[0], e[1])


func may_take(job: GuardJobs.Job, p: Person) -> bool:
	return p == job.data.who


func still_on(job: GuardJobs.Job, p: Person) -> bool:
	if p.mind != Person.Mind.POST:
		return false
	# Somebody else's order (a director's send_to_post) moved him off both his post and his spot: he is theirs, not ours.
	return p.anchor.is_equal_approx(p.post) or (bool(job.data.out) and p.anchor.is_equal_approx(job.data.spot))


func on_dropped(job: GuardJobs.Job, p: Person) -> void:
	_unflag(p)
	_marked.erase(p)
	# Dropped for good (his record is still this job's, not a higher job's): a checker out on his spot goes back to his post.
	if board.job_of(p) == job and p.is_alive() and (p.mind == Person.Mind.POST or p.held_by_god()) and bool(job.data.out) \
			and not board.mission_man(p) and p.anchor.is_equal_approx(job.data.spot) and not p.anchor.is_equal_approx(p.post):
		p.back_to_post()


## Counts an unfilled job's wait; a freed man leaves the crew.
func tick(job: GuardJobs.Job, delta: float) -> void:
	for i in range(job.crew.size() - 1, -1, -1):
		var m: Variant = job.crew[i]
		if not is_instance_valid(m):
			job.crew.remove_at(i)
		elif board.job_of(m) != job:
			# A director took him (GuardJobs.release() skips on_dropped): the record is dead; the flags go, he is not ours.
			job.crew.remove_at(i)
			_unflag(m)
			_marked.erase(m)
	if not job.started and not bool(job.data.over):
		job.data.wait = float(job.data.wait) - delta
		if float(job.data.wait) <= 0.0:
			job.data.over = true


func done(job: GuardJobs.Job) -> bool:
	var who: Variant = job.data.who
	if bool(job.data.over) or not is_instance_valid(who) or not (who as Person).is_alive() or (who as Person).corps != Person.Corps.NONE:
		return true
	var gate: Variant = job.data.gate
	return not is_instance_valid(gate) or (gate as Structure).destroyed or not (gate as Structure).walkable


## Once a second: every standing gate's NONE checkers get their jobs and their orders (out when anyone is near the mouth, back after
## STAND_DOWN s), flags and badges are renewed on the men who are looking, the people near each checked gate are looked at, and the
## tags are refreshed.
func post_jobs() -> void:
	var now := crowd._clock
	var have := {}
	for job in board.live(GuardJobs.Kind.GATE):
		if is_instance_valid(job.data.who):
			have[(job.data.who as Person).get_instance_id()] = true
	var suspects: Array[Person] = []
	for p in crowd.citizens:
		if is_instance_valid(p) and (p.guised() or p.held_by_god()):
			suspects.append(p)
	var kept := {}
	var shown: Array[Vector2] = []
	for gate in crowd._town.gates:
		if not _standing(gate):
			continue
		var gid := gate.get_instance_id()
		var mouth := _mouth(gate)
		var near := _near(gate, mouth)
		if near:
			_near_at[gid] = now
		var quiet := now - float(_near_at.get(gid, -INF))
		var list := checkers(gate)
		var tagged := false
		for i in list.size():
			var c := list[i]
			if c.corps == Person.Corps.NONE:
				var job: Variant = board.job_of(c)
				if job is GuardJobs.Job and job.kind == GuardJobs.Kind.GATE:
					if job.data.gate == gate:
						_order(job, c, gate, i, near, quiet)
				elif not have.has(c.get_instance_id()) and board.is_free(c):
					have[c.get_instance_id()] = true
					board.post(GuardJobs.Kind.GATE, gate.center(), 1, INF, {"gate": gate, "who": c, "out": false,
							"spot": Vector2.INF, "wait": OPEN_SECONDS, "over": false})
			if _active(c, gate):
				kept[c] = true
				_flag(c)
				tagged = true
				if c.corps == Person.Corps.NONE and near:
					_face(c)
			elif c.corps == Person.Corps.NONE and board.gate_checker(c):
				tagged = true
		if tagged:
			shown.append(gate.center())
		if checked(gate):
			for p in suspects:
				if p.ground_pos.distance_to(mouth) <= GATE_LOOK:
					check(p, gate)
	for p in _marked.keys():
		if not is_instance_valid(p):
			_marked.erase(p)
		elif not kept.has(p):
			_unflag(p)
			_marked.erase(p)
	_shown = shown
	_forget(now)


func standing_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for at in _shown:
		out.append(MapTag.place(at, COLOUR, TAG))
	return out


## The board closed: every flag this duty set comes off.
func on_close() -> void:
	_release_all(false)
	_shown.clear()
	_pending.clear()


## A new crowd or act: every flag comes off and a checker out on his spot goes back to his post.
func clear() -> void:
	_release_all(true)
	_spotted.clear()
	_charged.clear()
	_pending.clear()
	_near_at.clear()
	_shown.clear()


## Takes the flags off every marked man; with `home`, a living NONE man out away from his post goes back to it.
func _release_all(home: bool) -> void:
	for p in _marked.keys():
		if is_instance_valid(p):
			var s: Person = p
			_unflag(s)
			if home and s.is_alive() and s.corps == Person.Corps.NONE and not s.held_by_god() and not s.anchor.is_equal_approx(s.post):
				s.back_to_post()
	_marked.clear()


## The mouth of `gate`: where the crowd queues (the marshals' exit point).
func _mouth(gate: Structure) -> Vector2:
	var out := Crowd.outward_of(gate)
	return gate.center() - out * (absf(gate.footprint.size.dot(out)) * 0.5 + Crowd.GATE_DOOR)


## A gate that stands and lets people through (rubble is no gate; a barred postern is shut).
func _standing(gate: Variant) -> bool:
	return is_instance_valid(gate) and not (gate as Structure).destroyed and (gate as Structure).walkable


## Whether anyone waits at the gate or a living citizen is out of doors within GATE_LOOK of its mouth.
func _near(gate: Structure, mouth: Vector2) -> bool:
	if crowd.waiting_at(gate) > 0:
		return true
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(mouth) <= GATE_LOOK:
			return true
	return false


## Whether `c` is looking at `gate` now: alive, out of doors, in no hand but the town's, and either a marshal standing within
## GATE_LOOK of the mouth, or a NONE man on his GATE job's spot beside it.
func _active(c: Person, gate: Structure) -> bool:
	if not c.is_alive() or c.inside or c.held_by_god() or crowd.held_by_mission(c):
		return false
	if c.corps == Person.Corps.MARSHAL:
		return (c.mind == Person.Mind.POST or c.mind == Person.Mind.HOLD) and c.ground_pos.distance_to(_mouth(gate)) <= GATE_LOOK
	var job: Variant = board.job_of(c)
	if not (job is GuardJobs.Job) or job.kind != GuardJobs.Kind.GATE or job.data.gate != gate or not bool(job.data.out):
		return false
	return c.mind == Person.Mind.POST and c.ground_pos.distance_to(job.data.spot) <= Person.GOAL_REACH * 2.0


## The first checker of `gate` (nearest first) who is looking and sees `p`: not veiled himself, and `p` within his sight.
func _watcher(gate: Structure, p: Person) -> Person:
	for c in checkers(gate):
		if _active(c, gate) and not crowd.is_veiled(c.ground_pos) \
				and c.ground_pos.distance_to(p.ground_pos) <= crowd.sight(c, p.ground_pos, Crowd.WATCH_SIGHT * crowd.sight_scale):
			return c
	return null


## One order for a NONE checker's job: out to his spot when anyone is near the mouth (or was within STAND_DOWN s), back to his post
## after it. One send_to_post per change, never per tick; his post and town post never change.
func _order(job: GuardJobs.Job, c: Person, gate: Structure, k: int, near: bool, quiet: float) -> void:
	var d: Dictionary = job.data
	if c.mind != Person.Mind.POST or c.held_by_god():
		return
	if near or (bool(d.out) and quiet < STAND_DOWN):
		if not bool(d.out):
			d.out = true
			d.spot = _spot(gate, k)
			c.send_to_post(d.spot)
	elif bool(d.out):
		d.out = false
		c.send_to_post(c.post)


## Where the k-th checker of a gate stands: the spots after the marshals' (marshals_per_exit + k).
func _spot(gate: Structure, k: int) -> Vector2:
	var mouth := _mouth(gate)
	if crowd.marshals == null:
		return mouth
	return crowd.marshals.spot(mouth, Crowd.outward_of(gate), crowd.profile.marshals_per_exit + k)


## A checker on his spot: far sight and the eye badge (renewed; never over another badge a mission put on him, nor the "!").
func _flag(c: Person) -> void:
	c.watch_far = true
	_marked[c] = true
	if c.badge_left <= 0.0 or c.badge_glyph == GuardJobs.GLYPH_EYE:
		c.set_badge(GuardJobs.GLYPH_EYE, COLOUR, BADGE_SECONDS)


## Takes this duty's flags off `c`.
func _unflag(c: Person) -> void:
	c.watch_far = false
	if c.badge_glyph == GuardJobs.GLYPH_EYE:
		c.clear_badge()
	c.talk_left = 0.0
	c.stand_face = Vector2.INF


## The checker on his spot turns to the nearest living citizen within GATE_LOOK (ties by stagger) and talks to him.
func _face(c: Person) -> void:
	var best: Person = null
	var best_d := GATE_LOOK
	for p in crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		var d := p.ground_pos.distance_to(c.ground_pos)
		if d < best_d or (d == best_d and best != null and p.stagger < best.stagger):
			best = p
			best_d = d
	if best == null:
		return
	var dir := best.ground_pos - c.ground_pos
	c.stand_face = dir.normalized() if dir.length() > 0.05 else Vector2.DOWN
	c.talk_left = 1.0


## Forgets spots older than REPEAT_SECONDS (and gates with none left).
func _forget(now: float) -> void:
	for gid in _spotted.keys():
		var seen: Dictionary = _spotted[gid]
		for pid in seen.keys():
			if now - float(seen[pid]) >= REPEAT_SECONDS:
				seen.erase(pid)
		if seen.is_empty():
			_spotted.erase(gid)
