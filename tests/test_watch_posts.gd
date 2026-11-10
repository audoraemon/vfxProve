extends RefCounted
## Soldier jobs, Task 7: the Heretic Hunt, the Informer and Heart of Faith judge a watch from where an on-watch guard stands, not
## from the post he was given: a guard away on a job (fire, pile), walking off or held does not watch; a stationed or on-duty one does.

const GJ := preload("res://tests/test_guard_jobs.gd")
const Piles := preload("res://tests/test_piles.gd")


static func run(t) -> void:
	_judge(t, "hunt")
	_judge(t, "informer")
	_judge(t, "heart")


## Whether director `kind` counts `at` as watched.
static func _watched(kind: String, crowd: Crowd, at: Vector2) -> bool:
	match kind:
		"hunt":
			var d := HereticHuntDirector.new()
			d.crowd = crowd
			var r := d._watched(at)
			return r
		"informer":
			var d := InformerDirector.new()
			d.crowd = crowd
			var r := d._watched(at)
			return r
		_:
			var d := HeartOfFaithDirector.new()
			d.crowd = crowd
			var r := not d._quiet(at)
			return r


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal() if p.has_goal() else p.ground_pos
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## An ordinary guard at his post with no other soldier within 2R (R = 2.5 at most) of him.
static func _lone(crowd: Crowd) -> Person:
	for p in crowd.soldiers:
		if p.corps != Person.Corps.NONE or not crowd.guard_jobs.at_post(p):
			continue
		var alone := true
		for q in crowd.soldiers:
			if q != p and q.ground_pos.distance_to(p.ground_pos) < 6.0:
				alone = false
				break
		if alone:
			return p
	return null


static func _judge(t, kind: String) -> void:
	City.use(&"aldermere")
	var made := Piles._crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var g := _lone(crowd)
	t.check(g != null, "%s: a lone guard stands at his post" % kind)
	if g == null:
		crowd.clear()
		Piles._free(made)
		return
	var at := g.ground_pos + Vector2(0.3, 0.0)
	t.check(_watched(kind, crowd, at), "%s: a guard at his post watches" % kind)

	# Away at a fire, even stood back on the point.
	var house := GJ._house(env)
	g.assist(house, true)
	g.ground_pos = at - Vector2(0.3, 0.0)
	t.check(not _watched(kind, crowd, at), "%s: a guard at a fire does not watch" % kind)
	g.stand_down()
	g.send_to_post(g.post)
	_arrive(g)
	g.ground_pos = at - Vector2(0.3, 0.0)
	t.check(_watched(kind, crowd, at), "%s: back at his post he watches again" % kind)

	# Walking off his post.
	g.send_to_post(g.post + Vector2(6.0, 0.0))
	g.tick(1.0)
	t.check(g.has_goal() and not _watched(kind, crowd, at), "%s: a guard walking off does not watch" % kind)
	g.send_to_post(g.post)
	_arrive(g)
	g.ground_pos = at - Vector2(0.3, 0.0)

	# Digging a pile: the anchor is his dig spot, he stands at the point.
	var cells := Piles._house_with_street(crowd, env)
	var pile: PileManager.Pile = null
	if cells != null:
		var pc := crowd.piles.cells_for(cells)
		if not pc.is_empty():
			pile = crowd.piles.place(pc, cells)
	t.check(pile != null, "%s: a pile stands to dig" % kind)
	if pile != null:
		crowd.guard_jobs.take(g, pile)
		pile.spots[g] = at
		g.send_to_post(at)
		_arrive(g)
		t.check(g.on_guard_job and not _watched(kind, crowd, at), "%s: a digger at his spot does not watch" % kind)
		crowd.guard_jobs.release(g)
		g.on_guard_job = false

	# Stationed by a director, and on duty.
	g.send_to_post(at)
	_arrive(g)
	t.check(g.on_watch() and _watched(kind, crowd, at), "%s: a soldier a director stationed there watches" % kind)
	g.go_duty(at)
	_arrive(g)
	t.check(_watched(kind, crowd, at), "%s: a soldier on duty there watches" % kind)

	if kind == "heart":
		g.corps = Person.Corps.KNIGHT
		t.check(not _watched(kind, crowd, at), "heart: a Knight at the point still leaves it quiet")
	crowd.clear()
	Piles._free(made)
