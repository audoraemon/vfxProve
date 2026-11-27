extends RefCounted
## The Pale Eye (Veil ability levels, VS 6, VL5-VL7): the ledger of who the dark has seen, its life (time, unmark, release, for good),
## the cue's gap, its quiet, its one node and place, the edge marker's point, a bare cast, headless drawing, and that no cast below level 5
## ever makes one.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const LV := preload("res://tests/test_veil_levels.gd")
const KEYS := ["doom", "blight", "slumber", "cloak", "unseen", "dreamless", "dread", "shadowplay", "swallow", "evernight"]


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_bare(t, made)
	_mark(t, made)
	_time_out(t, made)
	_open_ended(t, made)
	_gone_for_good(t, made)
	_lingers(t, made)
	_cue(t, made)
	_quiet(t, made)
	_badge(t, made)
	_one_node(t, made)
	_edge_point(t)
	_headless(t, made)
	_owner_form(t, made)
	_nothing_below_five(t, made)
	_cleared_with_the_town(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


## A fresh town with no eye.
static func _begin(made: Array) -> Vector2:
	var crowd: Crowd = made[0]
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	return EV._fresh(made)


## A cast (never run) to mark through.
static func _cast(made: Array, at: Vector2) -> FxTimeline:
	return FxTimeline.cast(SlumberFx, made[5], at, {})


static func _bare(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	var fx := FxTimeline.cast(SlumberFx, bare, at, {})
	t.check(not PaleEye.mark(fx, p, "slumber"), "bare: no crowd, no eye")
	t.check(PaleEye.of(null) == null and PaleEye.of(crowd) == null, "of(): null with no crowd and before any mark; it never makes one")
	var no_layer := FxContext.new()
	no_layer.crowd = crowd
	var fx2 := FxTimeline.cast(SlumberFx, bare, at, {})
	fx2.ctx = no_layer
	t.check(not PaleEye.mark(fx2, p, "slumber") and PaleEye.of(crowd) == null, "a context with a crowd but no layer: false, nothing made")
	t.check(not PaleEye.mark(null, p, "slumber"), "no cast: false")
	var fx3 := _cast(made, at)
	t.check(not PaleEye.mark(fx3, null, "slumber") and PaleEye.of(crowd) == null, "nobody to eye: false")
	var dead := EV._put(crowd, at)
	dead.die(&"doom")
	t.check(not PaleEye.mark(fx3, dead, "slumber") and PaleEye.of(crowd) == null, "a dead man: false")
	var inside := EV._put(crowd, at)
	inside.inside = true
	t.check(not PaleEye.mark(fx3, inside, "slumber") and PaleEye.of(crowd) == null, "an indoor man: false")
	fx.free()
	fx2.free()
	fx3.free()
	bare.overhead.free()


static func _mark(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var fx := _cast(made, at)
	crowd._clock = 12.5
	t.check(PaleEye.mark(fx, p, "slumber"), "mark: true")
	var eye := PaleEye.of(crowd)
	t.check(eye != null and eye == crowd.pale_eye and eye.is_eyed(p), "the crowd's ledger holds him")
	t.check(eye.record.size() == 1 and eye.record[0] == {"id": p.get_instance_id(), "key": "slumber", "fx": fx.get_instance_id(), "at": crowd.clock()},
		"one record entry {id, key, fx, at == the crowd clock} (%s)" % [eye.record])
	t.check(eye.held_by(fx.get_instance_id()) == 1 and eye.eyed() == [p], "held_by counts the cast's eyes; eyed() lists him")
	t.check(PaleEye.mark(fx, p, "slumber", 9.0) and eye.record.size() == 1, "a second mark by the same cast: true, no new entry")
	eye.step(8.9)
	t.check(eye.is_eyed(p), "its life ran to the longer (9 s): still eyed at 8.9")
	eye.step(0.2)
	t.check(not eye.is_eyed(p), "and closed after it")
	t.check(PaleEye.mark(fx, p, "slumber", 2.0) and PaleEye.mark(fx, p, "slumber", 1.0), "a shorter mark never shortens an open eye")
	eye.step(1.5)
	t.check(eye.is_eyed(p), "(2 s kept)")
	var fx2 := _cast(made, at)
	t.check(PaleEye.mark(fx2, p, "doom") and eye.record.size() == 3 and eye.held_by(fx2.get_instance_id()) == 1,
		"another cast's mark on the same man: its own entry")
	fx.free()
	fx2.free()


static func _time_out(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var fx := _cast(made, at)
	PaleEye.mark(fx, p, "slumber")
	var eye := PaleEye.of(crowd)
	eye.step(3.9)
	t.check(eye.is_eyed(p), "eyed at 3.9 s of step")
	eye.step(0.2)
	t.check(not eye.is_eyed(p) and eye.record.size() == 1 and eye.held_by(fx.get_instance_id()) == 0, "not at 4.1 s; the record is kept")
	fx.free()


static func _open_ended(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var q := EV._put(crowd, at + Vector2(0.5, 0.0))
	var r := EV._put(crowd, at + Vector2(1.0, 0.0))
	var a := _cast(made, at)
	var b := _cast(made, at)
	PaleEye.mark(a, p, "slumber", INF)
	PaleEye.mark(b, q, "slumber", INF)
	PaleEye.mark(a, r, "slumber")
	var eye := PaleEye.of(crowd)
	eye.step(100.0)
	t.check(eye.is_eyed(p) and eye.is_eyed(q) and not eye.is_eyed(r), "INF stays for 100 s; the timed one is gone")
	PaleEye.unmark(a, p)
	t.check(not eye.is_eyed(p) and eye.is_eyed(q), "unmark closes this cast's eye only")
	PaleEye.mark(a, p, "slumber", INF)
	PaleEye.mark(a, r, "slumber")
	PaleEye.release(a)
	t.check(not eye.is_eyed(p) and eye.is_eyed(q) and eye.is_eyed(r), "release(A) closes A's INF eyes only: not B's, not A's timed one")
	eye.step(4.1)
	t.check(not eye.is_eyed(r) and eye.is_eyed(q), "A's timed eye runs out; B's open-ended one stays")
	PaleEye.release(b)
	t.check(eye.eyed().is_empty() and eye.record.size() == 5, "release(B) closes it; the record keeps all five entries (%d)" % eye.record.size())
	a.free()
	b.free()


static func _gone_for_good(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var taken := EV._put(crowd, at)
	var killed := EV._put(crowd, at + Vector2(0.5, 0.0))
	var inside := EV._put(crowd, at + Vector2(1.0, 0.0))
	var a := _cast(made, at)
	var b := _cast(made, at)
	for p in [taken, killed, inside]:
		PaleEye.mark(a, p, "slumber", INF)
	var eye := PaleEye.of(crowd)
	var entries := eye.record.size()
	crowd.take(taken, &"night")
	(made[3] as EnemyField).kill(killed, &"doom", at)
	inside.inside = true
	eye.step(0.05)
	t.check(eye.eyed().is_empty(), "taken, killed and indoors: closed on the next step")
	inside.inside = false
	t.check(not PaleEye.mark(a, inside, "slumber") and eye.record.size() == entries, "back outside, the same cast's mark: false and no entry")
	t.check(PaleEye.mark(b, inside, "slumber") and eye.record.size() == entries + 1 and eye.is_eyed(inside), "another cast's mark: true, a new entry")
	a.free()
	b.free()


## An eye whose man died or was taken stays where he last stood for FADE, drawn fading, then closes for good; is_eyed()/eyed()/held_by()
## count it closed at once. Going indoors closes at once. A man eyed by two casts is drawn once, with the larger alpha.
static func _lingers(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var taken := EV._put(crowd, at)
	var killed := EV._put(crowd, at + Vector2(0.5, 0.0))
	var inside := EV._put(crowd, at + Vector2(1.0, 0.0))
	var two := EV._put(crowd, at + Vector2(1.5, 0.0))
	var a := _cast(made, at)
	var b := _cast(made, at)
	for p in [taken, killed, inside]:
		PaleEye.mark(a, p, "slumber", INF)
	PaleEye.mark(a, two, "slumber", 0.2)
	PaleEye.mark(b, two, "slumber", 3.0)
	var eye := PaleEye.of(crowd)
	var drawn := eye.drawn()
	t.check(drawn.size() == 4,
		"(four drawn, the man of two casts once: %d)" % drawn.size())
	var where := {taken.get_instance_id(): taken.ground_pos, killed.get_instance_id(): killed.ground_pos}
	crowd.take(taken, &"night")
	(made[3] as EnemyField).kill(killed, &"doom", at)
	inside.inside = true
	eye.step(0.1)
	t.check(not eye.is_eyed(taken) and not eye.is_eyed(killed) and not eye.is_eyed(inside) and eye.held_by(a.get_instance_id()) == 1,
		"closed at once for is_eyed() and held_by()")
	var ids := {}
	for d in eye.drawn():
		ids[d["id"]] = d
	t.check(ids.has(taken.get_instance_id()) and ids.has(killed.get_instance_id()) and not ids.has(inside.get_instance_id()),
		"drawn: the taken and the killed still, the one who went indoors not")
	t.check(ids[killed.get_instance_id()]["at"] == where[killed.get_instance_id()] and ids[taken.get_instance_id()]["at"] == where[taken.get_instance_id()],
		"... where each last stood")
	t.check(float(ids[killed.get_instance_id()]["a"]) < 1.0 and float(ids[killed.get_instance_id()]["a"]) > 0.0, "... fading")
	var seen := 0
	for d in eye.drawn():
		if d["id"] == two.get_instance_id():
			seen += 1
			t.check(float(d["a"]) == 1.0, "a man eyed by two casts: one entry, the larger alpha (the longer eye, full)")
	t.check(seen == 1, "... drawn once")
	eye.step(PaleEye.FADE + 0.1)
	ids.clear()
	for d in eye.drawn():
		ids[d["id"]] = d
	t.check(not ids.has(taken.get_instance_id()) and not ids.has(killed.get_instance_id()), "after FADE the dead are not drawn")
	inside.inside = false
	a.free()
	b.free()


static func _cue(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var people := LV._ring(crowd, at, 1.0, 6)
	var fx := _cast(made, at)
	PaleEye.mark(fx, people[0], "slumber")
	PaleEye.mark(fx, people[1], "slumber")
	PaleEye.mark(fx, people[2], "slumber")
	var eye := PaleEye.of(crowd)
	t.check(eye.cues == 1, "three eyes opened in one frame: one cue request (%d)" % eye.cues)
	eye.step(0.5)
	PaleEye.mark(fx, people[3], "slumber")
	t.check(eye.cues == 1, "another 0.5 s later: still one")
	eye.step(0.5)
	PaleEye.mark(fx, people[4], "slumber")
	t.check(eye.cues == 2, "at 1.0 s: two (%d)" % eye.cues)
	PaleEye.mark(fx, people[4], "slumber")
	t.check(eye.cues == 2, "an eye already open asks for no cue")
	t.check(String(PaleEye.CUE) == "v_pale_eye" and Sfx.CATALOG.has(PaleEye.CUE) and Sfx.CATALOG[PaleEye.CUE].get("voices", 0) == 1,
		"the cue is v_pale_eye, catalogued with one voice")
	fx.free()


static func _quiet(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var people := LV._ring(crowd, at, 1.0, 5)
	var minds := []
	for p in people:
		minds.append([p.mind, p.state, p.fearless_left, p.is_asleep(), p.statuses.duplicate()])
	var alarm := crowd.alarm
	var threats := crowd.threats.active_count()
	var fx := _cast(made, at)
	for p in people:
		PaleEye.mark(fx, p, "slumber")
	var now := []
	for p in people:
		now.append([p.mind, p.state, p.fearless_left, p.is_asleep(), p.statuses.duplicate()])
	t.check(crowd.alarm == alarm and crowd.threats.active_count() == threats and now == minds,
		"quiet: five eyed, no alarm, no threat, every mind unchanged")
	fx.free()


static func _badge(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	p.set_badge(Person.GLYPH_DIAMOND, Color.RED, 7.0)
	var fx := _cast(made, at)
	PaleEye.mark(fx, p, "slumber")
	t.check(p.badge_glyph == Person.GLYPH_DIAMOND and p.badge_color == Color.RED and is_equal_approx(p.badge_left, 7.0),
		"a badge set before the mark keeps glyph, colour and seconds")
	fx.free()


static func _one_node(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _begin(made)
	var people := LV._ring(crowd, at, 1.0, 5)
	var fx := _cast(made, at)
	var kids := []
	for p in people:
		kids.append(p.get_child_count())
	for p in people:
		PaleEye.mark(fx, p, "slumber")
	var nodes := 0
	for c in ctx.overhead.get_children():
		if c is PaleEye:
			nodes += 1
	var eye := PaleEye.of(crowd)
	var same := true
	for i in people.size():
		same = same and people[i].get_child_count() == kids[i]
	t.check(nodes == 1 and eye.get_child_count() == 0 and same, "five eyed: one PaleEye, no child of its own, none on a person")
	t.check(eye.z_index == 4 and not eye.z_as_relative and eye.z_index < 5, "absolute z_index 4, under Targeting's 5")
	var sibling := Node2D.new()
	sibling.z_index = 4
	ctx.overhead.add_child(sibling)
	t.check(ctx.overhead.get_child(ctx.overhead.get_child_count() - 1) == sibling, "(the sibling came last)")
	eye.step(0.1)
	t.check(ctx.overhead.get_child(ctx.overhead.get_child_count() - 1) == eye, "the eye is the layer's last child again after a step")
	var sibling2 := Node2D.new()
	ctx.overhead.add_child(sibling2)
	PaleEye.mark(fx, people[0], "slumber")
	t.check(ctx.overhead.get_child(ctx.overhead.get_child_count() - 1) == eye, "and after a mark")
	sibling.free()
	sibling2.free()
	fx.free()


static func _edge_point(t) -> void:
	var view := Rect2(0, 0, 800, 600)
	t.check(PaleEye.edge_point(view, Vector2(400, 300)) == Vector2(400, 300), "edge_point: the centre stays")
	t.check(PaleEye.edge_point(view, Vector2(1200, 300)).is_equal_approx(Vector2(788, 300)), "(1200,300) -> (788,300)")
	var corner := PaleEye.edge_point(view, Vector2(-100, -100))
	var ray := (corner - view.get_center()).normalized()
	var want := (Vector2(-100, -100) - view.get_center()).normalized()
	t.check(ray.is_equal_approx(want) and (is_equal_approx(corner.x, PaleEye.EDGE_MARGIN) or is_equal_approx(corner.y, PaleEye.EDGE_MARGIN))
		and Rect2(0, 0, 800, 600).grow(-PaleEye.EDGE_MARGIN + 0.01).has_point(corner),
		"(-100,-100) lands on the border on the ray from the centre (%s)" % [corner])


static func _headless(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var fx := _cast(made, at)
	PaleEye.mark(fx, p, "slumber", INF)
	var eye := PaleEye.of(crowd)
	eye.step(0.1)
	eye._draw()
	t.check(DisplayServer.get_name() != "headless" or eye.edge_marks() == 0, "headless: edge_marks() is 0, nothing drawn")
	t.check(eye.is_eyed(p), "(the ledger works)")
	fx.free()


static func _owner_form(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var layer := made[5].overhead as Node
	t.check(not PaleEye.mark_by(crowd, 77, p, "blight", INF, null) and PaleEye.of(crowd) == null, "mark_by with no layer and no ledger: false")
	t.check(PaleEye.mark_by(crowd, 77, p, "blight", INF, layer), "mark_by with a layer: true")
	var eye := PaleEye.of(crowd)
	t.check(eye.held_by(77) == 1 and eye.record[0]["fx"] == 77 and eye.record[0]["key"] == "blight", "its owner is the id given")
	t.check(PaleEye.mark_by(crowd, 78, p, "blight", 1.0), "a second owner, no layer needed now")
	PaleEye.unmark_by(crowd, 78, p)
	t.check(eye.held_by(78) == 0 and eye.held_by(77) == 1, "unmark_by closes one owner's eye")
	PaleEye.release_by(crowd, 77)
	t.check(eye.held_by(77) == 0 and eye.eyed().is_empty(), "release_by closes the owner's open-ended eyes")


static func _cleared_with_the_town(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var p := EV._put(crowd, at)
	var fx := _cast(made, at)
	PaleEye.mark(fx, p, "slumber")
	var eye := PaleEye.of(crowd)
	crowd.clear()
	t.check(crowd.pale_eye == null and PaleEye.of(crowd) == null and eye.is_queued_for_deletion(), "Crowd.clear() forgets the ledger and frees its node")
	fx.free()


## RF5: a night of level-4 casts of every Veil power, each run to its end, builds no Pale Eye.
static func _nothing_below_five(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var made_any := false
	for key: String in KEYS:
		for dark in [false, true]:
			var at := _begin(made)
			LV._ring(crowd, at, 1.0, 4)
			LV._ring(crowd, at + Vector2(3.0, 0.0), 1.0, 2)
			if dark:
				crowd.lay_dusk(at, 1.0, 300.0)
			var fx := FxTimeline.cast(load(String(PowerBook.get_power(key).path)), ctx, at, {"level": 4, "dark": dark})
			var guard := 0
			while is_instance_valid(fx) and not fx.finished and guard < 1400:
				fx._process(0.1)
				guard += 1
			made_any = made_any or PaleEye.of(crowd) != null
			if is_instance_valid(fx):
				if not fx.finished:
					fx.end_now()
				fx.free()
	t.check(not made_any, "every Veil power cast at level 4 (light and dark), run to its end: no Pale Eye is ever made")

