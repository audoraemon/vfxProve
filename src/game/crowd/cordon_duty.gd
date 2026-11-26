class_name CordonDuty
extends Duty
## The cordon (soldier duties, slice c): when a fire is doused or a building falls, two soldiers stand at the two ends of the street
## stretch beside it for CORDON_SECONDS, facing out. Calm citizens bound for the rope (a goal inside it, or a path through it) are
## turned back (Person.hold_off(), renewed every tick, their goals kept for when the cordon ends); a lure through the rope fails;
## a death inside it is seen by no cordon man. Never turned back: anyone fleeing, panicking, on duty, assisting, sheltering,
## regrouping, and every soldier. Nothing here draws a number from any rng.

## Cordons at once (scaled by the board's cap()), the men of one, how far from the street a free man may stand to be taken.
const CORDONS := 2
const CREW := 2
const REACH := 10.0
## Half the length of the roped stretch, and how far the rect is grown about the ruin.
const CORDON_HALF := 3.0
const FOOT_GROW := 0.5
## Seconds a cordon stands after its (last) start; an unstaffed one waits as long for its men.
const CORDON_SECONDS := 40.0
## Seconds an unstaffed (open) job waits for its full crew before it lets go.
const OPEN_WAIT := 10.0
## How far from the stretch's middle the ruin's part of the rect reaches, on each axis (a deep lot ropes no junction).
const FOOT_CLIP := CORDON_HALF + 1.0
## How many waypoints ahead a citizen's path is read for a crossing of the rope.
const PATH_AHEAD := 24
## A goal this near his profile's home is "going home" (never turned back).
const HOME_NEAR := 1.0
## Seconds a citizen is turned back for; renewed every tick while the cordon is live.
const TURN_BACK := 1.5
## Seconds the nearer end man talks to a citizen he turns back.
const TALK := 1.0
## The tag and rope colour.
const COLOUR := Color(0.92, 0.55, 0.3)
## Posts and rope on the ground drawer: post height, rope height (screen px), rope width.
const POST_H := 8.0
const ROPE_H := 6.0
const ROPE_W := 1.5

## The cordon jobs that are not over (the lure test loops these; empty means nothing blocks).
var _live: Array[GuardJobs.Job] = []


func kind() -> int:
	return GuardJobs.Kind.CORDON


## The road rect nearest `near` (distance to the rect, ties the first in the list), its long axis, the centre-line point nearest
## `near` (kept `half` clear of the road's ends where it is long enough): [end_a, end_b, rect], the ends `half` either side of
## that point on the centre line (clamped to the road) and the rect the road's width between them.
static func stretch(roads: Array, near: Vector2, half: float) -> Array:
	var best := Rect2()
	var best_d := INF
	for r: Rect2 in roads:
		var d := Vector2(maxf(maxf(r.position.x - near.x, 0.0), near.x - r.end.x),
				maxf(maxf(r.position.y - near.y, 0.0), near.y - r.end.y)).length()
		if d < best_d:
			best = r
			best_d = d
	if best_d == INF:
		return [near, near, Rect2(near, Vector2.ZERO)]
	if best.size.x >= best.size.y:
		var y := best.position.y + best.size.y * 0.5
		var lo := best.position.x
		var hi := best.end.x
		var c := clampf(near.x, lo + half, hi - half) if hi - lo >= 2.0 * half else (lo + hi) * 0.5
		var a := Vector2(maxf(c - half, lo), y)
		var b := Vector2(minf(c + half, hi), y)
		return [a, b, Rect2(a.x, best.position.y, b.x - a.x, best.size.y)]
	var x := best.position.x + best.size.x * 0.5
	var top := best.position.y
	var bottom := best.end.y
	var m := clampf(near.y, top + half, bottom - half) if bottom - top >= 2.0 * half else (top + bottom) * 0.5
	var a2 := Vector2(x, maxf(m - half, top))
	var b2 := Vector2(x, minf(m + half, bottom))
	return [a2, b2, Rect2(best.position.x, a2.y, best.size.x, b2.y - a2.y)]


## Whether the segment `a`-`b` touches `r` (Liang-Barsky).
static func _hits(r: Rect2, a: Vector2, b: Vector2) -> bool:
	var d := b - a
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x - r.position.x, r.end.x - a.x, a.y - r.position.y, r.end.y - a.y]
	var t0 := 0.0
	var t1 := 1.0
	for i in 4:
		if is_zero_approx(p[i]):
			if q[i] < 0.0:
				return false
			continue
		var t: float = q[i] / p[i]
		if p[i] < 0.0:
			if t > t1:
				return false
			t0 = maxf(t0, t)
		else:
			if t < t0:
				return false
			t1 = minf(t1, t)
	return true


## A cordon for a doused fire or a fall at `site`, on the street nearest `street_at`: none when the site is veiled, the town is
## at EVACUATION or the board is closed; a site inside a live rope only starts that cordon's clock again; none past the cap.
func request(site: Structure, street_at: Vector2) -> void:
	if board == null or not board.is_open() or not is_instance_valid(site):
		return
	var centre := site.center()
	if crowd.is_veiled(centre) or crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
		return
	for job in _live:
		if (job.data.rect as Rect2).has_point(centre):
			if bool(job.data.begun):
				job.data.left = CORDON_SECONDS  # an unroped job's wait is not restarted
			return
	if _live.size() >= board.cap(CORDONS):
		return
	var roads: Array = City.current().roads()
	if roads.is_empty():
		return
	var s := stretch(roads, street_at, CORDON_HALF)
	var ends: Array[Vector2] = [s[0], s[1]]
	var road: Rect2 = s[2]
	var mid := (ends[0] + ends[1]) * 0.5
	var box := Rect2(mid - Vector2(FOOT_CLIP, FOOT_CLIP), Vector2(FOOT_CLIP, FOOT_CLIP) * 2.0)
	var foot := site.footprint.grow(FOOT_GROW)
	var rect := road.merge(foot.intersection(box)) if foot.intersects(box) else road
	var job := board.post(GuardJobs.Kind.CORDON, mid, CREW, REACH, {"site": site, "ends": ends,
			"rect": rect, "width": minf(road.size.x, road.size.y), "at_end": {}, "home": {},
			"left": CORDON_SECONDS, "wait": OPEN_WAIT, "begun": false, "over": false, "stood": false, "held": []})
	if job != null:
		_live.append(job)


## The rect a cordon job ropes off.
func rect_of(job: GuardJobs.Job) -> Rect2:
	return job.data.rect


## Whether the segment `a`-`b` crosses a staffed cordon's rect (false at once when none is live). One that starts inside a rect
## and ends outside it is not blocked by that rect (he is leaving).
func blocks(a: Vector2, b: Vector2) -> bool:
	for job in _live:
		if not _roped(job):
			continue
		var r: Rect2 = job.data.rect
		if r.has_point(a) and not r.has_point(b):
			continue
		if _hits(r, a, b):
			return true
	return false


## Whether `at` lies in a staffed cordon's rect.
func inside(at: Vector2) -> bool:
	for job in _live:
		if _roped(job) and (job.data.rect as Rect2).has_point(at):
			return true
	return false


## Whether `p` is a cordon man who does not witness `at` (it lies inside his own rope).
func crew_blind(p: Person, at: Vector2) -> bool:
	if _live.is_empty():
		return false
	var job: Variant = board.job_of(p)
	return job is GuardJobs.Job and (job as GuardJobs.Job).kind == GuardJobs.Kind.CORDON and _roped(job) \
			and (job.data.rect as Rect2).has_point(at)


## No man is sent to a site while a danger is live there: the open job waits out its window, and forms if the danger ends in it (R19).
func may_take(job: GuardJobs.Job, p: Person) -> bool:
	var site: Variant = job.data.site
	return p.corps == Person.Corps.NONE and danger_near(job.at).is_empty() 			and not (is_instance_valid(site) and not danger_near((site as Structure).center()).is_empty())


func on_taken(job: GuardJobs.Job, _p: Person) -> void:
	if job.crew.size() >= job.need:
		_begin(job)


func still_on(_job: GuardJobs.Job, p: Person) -> bool:
	return p.mind == Person.Mind.POST


func on_taken_away(job: GuardJobs.Job, p: Person) -> void:
	super(job, p)
	if job.crew.is_empty():
		_stop(job)


func on_dropped(job: GuardJobs.Job, p: Person) -> void:
	on_taken_away(job, p)
	if p.is_alive() and (p.mind == Person.Mind.POST or p.held_by_god()) and not board.mission_man(p):
		p.back_to_post()


## Counts the clocks: the cordon's 40 s (an open one waits as long for its men), the stage, who stands his end.
func tick(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	if bool(d.over):
		return
	for i in range(job.crew.size() - 1, -1, -1):
		var m: Variant = job.crew[i]
		if not is_instance_valid(m):
			job.crew.remove_at(i)
		elif board.job_of(m) != job:
			job.crew.remove_at(i)
			on_taken_away(job, m as Person)
	if not is_instance_valid(d.site) or crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
		_finish(job)
		return
	if not bool(d.begun):
		d.wait = float(d.wait) - delta
		if float(d.wait) <= 0.0:
			_finish(job)
		return
	d.left = float(d.left) - delta
	if float(d.left) <= 0.0:
		_finish(job)
		return
	_keep_off_danger(job)
	var standing := 0
	for p in job.crew:
		if _stands(d, p):
			standing += 1
	if standing > 0:
		d.stood = true
	elif bool(d.stood) or job.crew.is_empty():
		_finish(job)


## Once a second: every staffed cordon turns back the calm citizens bound for its rope.
func post_jobs() -> void:
	for job in _live.duplicate():
		if _roped(job):
			_turn_back(job)


func done(job: GuardJobs.Job) -> bool:
	return bool(job.data.over)


func tags(job: GuardJobs.Job) -> Array[MapTag]:
	var out: Array[MapTag] = []
	if _roped(job):
		out.append(MapTag.place((job.data.rect as Rect2).get_center(), COLOUR, "CORDON %d" % ceili(float(job.data.left))))
	return out


## At each end two short posts and a rope between them across the road.
func draw_ground(canvas: Node2D) -> void:
	for job in _live:
		if not _roped(job):
			continue
		var ends: Array[Vector2] = job.data.ends
		var along := (ends[1] - ends[0]).normalized()
		var across := along.orthogonal() * float(job.data.width) * 0.5
		for e in ends:
			var s1 := Iso.ground_to_screen(e + across)
			var s2 := Iso.ground_to_screen(e - across)
			canvas.draw_line(s1, s1 + Vector2(0.0, -POST_H), COLOUR.darkened(0.4), 2.0)
			canvas.draw_line(s2, s2 + Vector2(0.0, -POST_H), COLOUR.darkened(0.4), 2.0)
			canvas.draw_line(s1 + Vector2(0.0, -ROPE_H), s2 + Vector2(0.0, -ROPE_H), COLOUR, ROPE_W)


func showing() -> bool:
	for job in _live:
		if _roped(job):
			return true
	return false


func clear() -> void:
	for job in _live.duplicate():
		_stop(job)
		for m: Variant in job.crew:
			if is_instance_valid(m):
				var p: Person = m
				p.stand_face = Vector2.INF
				p.talk_left = 0.0
				if p.is_alive() and not p.held_by_god() and not p.anchor.is_equal_approx(p.post):
					p.back_to_post()
	_live.clear()


## A man whose end lies in a live danger stands off outside it (he is sent there once), and goes back to his end when the danger is
## over: no man stands inside a lingering power he is cordoning (R19).
func _keep_off_danger(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	for m: Variant in job.crew:
		if not is_instance_valid(m) or not d.home.has(m):
			continue
		var p: Person = m
		var home: Vector2 = d.home[p]
		var want := home
		var danger := danger_near(home)
		if not danger.is_empty():
			want = off_spot(danger, p.ground_pos if p.ground_pos.distance_to(home) > 0.01 else home)
		if not (d.at_end[p] as Vector2).is_equal_approx(want) and p.is_alive() and not p.held_by_god():
			d.at_end[p] = want
			d.stood = false  # on his way to the new spot: nobody "has left" the cordon
			p.send_to_post(want)
			var out := want - (d.rect as Rect2).get_center()
			p.stand_face = out.normalized() if out.length() > 0.05 else Vector2.DOWN


## Whether the job's men are sent and its rope is up.
func _roped(job: GuardJobs.Job) -> bool:
	return bool(job.data.begun) and not bool(job.data.over) and not job.ended


## Whether `p` is on his end now: alive, in no one's hand but the town's, within two goal reaches of the spot he was sent to.
func _stands(d: Dictionary, p: Variant) -> bool:
	if not is_instance_valid(p):
		return false
	var s := p as Person
	var at: Variant = d.at_end.get(s)
	return at is Vector2 and s.is_alive() and not s.held_by_god() and s.ground_pos.distance_to(at) <= Person.GOAL_REACH * 2.0


## The two men are on: each takes the end nearer him (the pair that walks least; ties by crew order), stands facing out.
func _begin(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	var a: Person = job.crew[0]
	var b: Person = job.crew[1]
	var e0 := _snap(d.ends[0])
	var e1 := _snap(d.ends[1])
	var straight := a.ground_pos.distance_to(e0) + b.ground_pos.distance_to(e1)
	var swapped := a.ground_pos.distance_to(e1) + b.ground_pos.distance_to(e0)
	if swapped < straight:
		var keep := e0
		e0 = e1
		e1 = keep
	var centre := (d.rect as Rect2).get_center()
	for i in 2:
		var p: Person = a if i == 0 else b
		var spot := e0 if i == 0 else e1
		p.send_to_post(spot)
		var out := spot - centre
		p.stand_face = out.normalized() if out.length() > 0.05 else Vector2.DOWN
		d.at_end[p] = spot
		d.home[p] = spot
	d.begun = true
	d.left = CORDON_SECONDS


## Turns back every calm citizen whose goal lies in the rect or whose path crosses it (and renews those already turned back);
## the nearer end man stands talking to the first.
func _turn_back(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	var rect: Rect2 = d.rect
	var centre := rect.get_center()
	var talked := false
	for p in crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or crowd.held_by_mission(p):
			continue
		if p.mind != Person.Mind.CALM and p.mind != Person.Mind.RECOVER:
			continue
		if not (p.held_off() and p.held_rect() == rect):
			# Not yet held: only one whose goal is in the rect or whose path crosses it, who is not on his way out of it or home.
			if not p.has_goal():
				continue
			var goal := p.goal()
			if rect.has_point(p.ground_pos) and not rect.has_point(goal):
				continue
			if p.profile != null and p.profile.home.distance_to(goal) <= HOME_NEAR:
				continue
			if not (rect.has_point(goal) or p.path_crosses(rect, PATH_AHEAD)):
				continue
		if p.hold_off(rect, TURN_BACK, p.ground_pos - centre, 1.0, true):
			if not d.held.has(p):
				d.held.append(p)
			if not talked:
				talked = true
				_talk_to(job, p)


## The end man nearer `p` stands talking to him (ties: the first crew man).
func _talk_to(job: GuardJobs.Job, p: Person) -> void:
	var best: Person = null
	for m: Variant in job.crew:
		if is_instance_valid(m) and (best == null or (m as Person).ground_pos.distance_to(p.ground_pos) < best.ground_pos.distance_to(p.ground_pos)):
			best = m
	if best != null and best.is_alive():
		best.talk_left = TALK


## The cordon is over: the rope comes down and every man goes back to his post.
func _finish(job: GuardJobs.Job) -> void:
	_stop(job)
	for i in range(job.crew.size() - 1, -1, -1):
		var m: Variant = job.crew[i]
		if is_instance_valid(m):
			board.drop(job, m as Person)
		else:
			job.crew.remove_at(i)


## The rope is down at once: the job is over, and every citizen turned back by it is let in (he takes up his goal).
func _stop(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	if bool(d.over):
		return
	d.over = true
	_live.erase(job)
	var rect: Rect2 = d.rect
	for p: Variant in d.held:
		if is_instance_valid(p) and (p as Person).held_off() and (p as Person).held_rect() == rect:
			(p as Person).end_hold_off()
	d.held.clear()


## `at` on open ground (the shared rng is never drawn from).
func _snap(at: Vector2) -> Vector2:
	var s := crowd._grid.nearest_walkable(at)
	return at if s == Vector2.INF else s
