extends RefCounted
## Soldier duties, slice a2: street beats. The street pairs walk generated beats (a centre line there and back, a point every
## 3, a pause at each) in both towns; a beat man is off watch but free for jobs, and keeps walking after the call-up.

const Corps := preload("res://tests/test_corps.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")
const STEP := 1.0 / 30.0


static func run(t) -> void:
	_beat_shape(t)
	_beats_aldermere(t)
	_beats_capital(t)
	_pairs_walk(t)
	_pause_talks(t)
	_after_call_up(t)
	_off_watch(t)
	_director_station_watches(t)
	_walker_free(t)
	_escort_stands(t)
	_mission_man_never(t)


## Every soldier thinks and moves one step, then the crowd's own tick.
static func _step(crowd: Crowd) -> void:
	for p in crowd.soldiers:
		if is_instance_valid(p) and not p.inside:
			p.tick(STEP)
	crowd.advance(STEP)


static func _run_for(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		_step(crowd)


## Runs `seconds`, returning the set of `men` who had a post other than their first at any step (a beat comes back to where it
## began, so the end of the run says nothing).
static func _moved_on(crowd: Crowd, men: Array[Person], seconds: float) -> Dictionary:
	var first := {}
	for p in men:
		first[p] = p.post
	var moved := {}
	for i in roundi(seconds / STEP):
		_step(crowd)
		for p in men:
			if p.post.distance_to(first[p]) > 0.5:
				moved[p] = true
	return moved


## The ordinary beat men of `crowd`: corps NONE, with an entry.
static func _beat_men(crowd: Crowd) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.soldiers:
		if crowd.beat_of(p) >= 0 and p.corps == Person.Corps.NONE:
			out.append(p)
	return out


static func _done(made: Array) -> void:
	Corps._done(made)
	City.use(&"aldermere")


## The centre line of a street from one end to the other, a point every BEAT_STEP, then back without repeating the ends.
static func _beat_shape(t) -> void:
	var b := CityDef.beat_of_road(Rect2(0, 0, 1, 12), Vector2(0.5, 0.0))
	var pts: Array = b.points
	t.check(pts.size() == 8, "a 12 long street gives 5 points forward and 3 back (%d)" % pts.size())
	t.check(pts[0].is_equal_approx(Vector2(0.5, 0.0)) and pts[4].is_equal_approx(Vector2(0.5, 12.0)), "from one end to the other")
	t.check(pts[5].is_equal_approx(Vector2(0.5, 9.0)) and pts[7].is_equal_approx(Vector2(0.5, 3.0)), "and back without the ends again")
	t.check(int(b.start) == 0, "starts at the point nearest the post (0)")
	var wide := CityDef.beat_of_road(Rect2(0, 0, 12, 1), Vector2(6.2, 0.5))
	t.check(wide.points.size() == 8 and wide.points[0].is_equal_approx(Vector2(0.0, 0.5)), "a street that runs east to west too")
	t.check(int(wide.start) == 2, "its start is the nearest point (%d)" % int(wide.start))
	var mid := CityDef.beat_of_road(Rect2(0, 0, 1, 12), Vector2(0.5, 4.5))
	t.check(int(mid.start) == 1, "a tie goes to the lowest index (%d)" % int(mid.start))
	t.check(CityDef.BEAT_STEP == 3.0, "a point every 3")


## Aldermere: one beat per street pair, each post the point the old formula gives.
static func _beats_aldermere(t) -> void:
	City.use(&"aldermere")
	var beats: Array = City.current().street_beats()
	t.check(beats.size() == Crowd.POST_PATROL / 2, "ten beats for ten pairs (%d)" % beats.size())
	var streets: Array[Rect2] = []
	for road: Rect2 in City.current().roads():
		if City.current().town().encloses(road):
			streets.append(road)
	var good := true
	for k in beats.size():
		var road := streets[k % streets.size()]
		var along := (float(k / streets.size()) + 0.5) / ceilf(float(Crowd.POST_PATROL / 2) / streets.size())
		var at := Vector2(road.get_center().x, lerpf(road.position.y, road.end.y, along)) if road.size.y > road.size.x \
			else Vector2(lerpf(road.position.x, road.end.x, along), road.get_center().y)
		good = good and (beats[k].post as Vector2).distance_to(at) < 0.01 and beats[k].points.size() >= 2
	t.check(good, "each beat's post is the formula's point")


## The Capital: STREET_PAIRS beats, every point on a road.
static func _beats_capital(t) -> void:
	City.use(&"capital")
	var city := City.current()
	var beats: Array = city.street_beats()
	t.check(beats.size() == CapitalCity.STREET_PAIRS, "the Capital has a beat for each street pair (%d)" % beats.size())
	var off := 0
	for b: Dictionary in beats:
		for pt: Vector2 in b.points:
			var on := false
			for road: Rect2 in city.roads():
				if road.grow(0.5).has_point(pt):
					on = true
					break
			off += 0 if on else 1
	t.check(off == 0, "every beat point lies on a road (%d off)" % off)
	var posts: Array = city.soldier_posts().patrol
	var same := true
	for k in beats.size():
		same = same and (beats[k].post as Vector2).distance_to(posts[posts.size() - 2 * (beats.size() - k)]) < 0.01
	t.check(same, "each beat's post is the street pair's post")
	City.use(&"aldermere")


## In a calm spell the pairs walk on: most move off their first post.
static func _pairs_walk(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var men := _beat_men(crowd)
	t.check(men.size() >= 10 and crowd.loop_of(men[0]) < 0 and men[0].beat_index >= 0, "beat men have no wall loop (%d)" % men.size())
	var moved := _moved_on(crowd, men, 120.0).size()
	t.check(moved >= men.size() * 0.8, "the beat men walk on (%d of %d)" % [moved, men.size()])
	_done(made)


## A beat man at his point stands LOOP_PAUSE with no goal, then moves on.
static func _pause_talks(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	_run_for(crowd, 3.0 * STEP)
	var p: Person = null
	for q in _beat_men(crowd):
		if not q.has_goal() and q.mind == Person.Mind.POST:
			p = q
			break
	t.check(p != null, "a beat man stands at a point")
	if p != null:
		var at := p.post
		_run_for(crowd, 1.7)
		t.check(p.post == at and not p.has_goal() and p.mind == Person.Mind.POST, "he stands, no goal, mind POST, under LOOP_PAUSE")
		_run_for(crowd, 0.6)
		t.check(p.post != at and p.has_goal(), "then he walks to the next point")
	_done(made)


## After the call-up the beat men go on walking; the wall patrols (Capital) stand.
static func _after_call_up(t) -> void:
	var b: Dictionary = CapPeople._build()
	var crowd: Crowd = b.crowd
	crowd.rally()
	_run_for(crowd, 5.0)
	var beat: Array[Person] = []
	for p in _beat_men(crowd):
		if not crowd.guard.job.crew.has(p) and not crowd.guard_jobs.on_job(p):
			beat.append(p)
	var loops: Array[Person] = []
	for p in crowd.soldiers:
		if crowd.loop_of(p) >= 0 and p.corps == Person.Corps.NONE:
			loops.append(p)
	var walked := _moved_on(crowd, beat + loops, 30.0)
	var moved := 0
	for p in beat:
		moved += 1 if walked.has(p) else 0
	var wall_moved := 0
	for p in loops:
		wall_moved += 1 if walked.has(p) else 0
	t.check(beat.size() >= 10 and moved >= beat.size() * 0.8, "after the call-up the beat men keep moving on (%d of %d)" % [moved, beat.size()])
	t.check(not loops.is_empty() and wall_moved == 0, "the wall loop men stop (%d of %d moved)" % [wall_moved, loops.size()])
	crowd.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## A beat man paused at his point is not on watch; a guard at his post is.
static func _off_watch(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var p: Person = _beat_men(crowd)[0]
	t.check(p.on_beat() and p.at_own_post() and not p.on_watch(), "a beat man at his point is on his beat and off watch")
	var g: Person = null
	for q in crowd.soldiers:
		if q.beat_index < 0 and q.corps == Person.Corps.NONE and q.at_own_post():
			g = q
			break
	t.check(g != null and g.on_watch(), "a guard at his post watches")
	t.check(p.beat_index >= 0 and crowd.beat_of(p) == p.beat_index, "beat_of() is his beat's index")
	_done(made)


## A director's man stationed on a beat man is not on his beat: he watches the spot.
static func _director_station_watches(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var p: Person = _beat_men(crowd)[0]
	var spot := p.ground_pos + Vector2(4.0, 0.0)
	var post := p.post
	p.send_to_post(spot)
	p.ground_pos = spot
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	t.check(not p.on_beat() and p.on_watch(), "stationed by a director: off his beat, on watch at the spot")
	_run_for(crowd, 6.0)
	t.check(p.anchor == spot and p.post == post and p.on_watch() and not p.on_beat(), "and his beat never re-posts him")
	_done(made)


## A beat man mid-leg is free for a job; a wall loop man mid-leg is not.
static func _walker_free(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var p: Person = _beat_men(crowd)[0]
	var to := p.post + Vector2(0.0, 2.0)
	p.post = to
	p.town_post = to
	p.send_to_post(to)
	t.check(p.has_goal() and p.on_beat() and crowd.guard_jobs.beat_walker(p), "a beat man mid-leg is a beat walker")
	t.check(crowd.guard_jobs.is_free(p), "and free for a job")
	_done(made)
	var b: Dictionary = CapPeople._build()
	var cap: Crowd = b.crowd
	var w: Person = null
	for q in cap.soldiers:
		if cap.loop_of(q) >= 0 and q.corps == Person.Corps.NONE:
			w = q
			break
	t.check(w != null, "the Capital has a wall loop man")
	if w != null:
		var next := w.post + Vector2(0.0, 2.0)
		w.post = next
		w.town_post = next
		w.send_to_post(next)
		t.check(w.has_goal() and not cap.guard_jobs.is_free(w), "a wall loop man mid-leg is not free")
	cap.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## An escort-corps patrol man keeps his post.
static func _escort_stands(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var p: Person = _beat_men(crowd)[0]
	p.corps = Person.Corps.ESCORT
	var at := p.post
	var from := p.ground_pos
	_run_for(crowd, 60.0)
	t.check(crowd.beat_of(p) >= 0 and p.post == at and p.ground_pos.distance_to(from) < 1.5, "an escort never leaves his post in 60 s")
	_done(made)


## A beat man a mission names is not free and his entry never re-posts him.
static func _mission_man_never(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var p: Person = _beat_men(crowd)[0]
	crowd.mission_holds.append(func(q: Person) -> bool: return q == p)
	var at := p.post
	t.check(not crowd.guard_jobs.is_free(p), "a held beat man is not free")
	_run_for(crowd, 8.0)
	t.check(p.post == at and not p.has_goal(), "his entry never re-posts him")
	_done(made)
