extends RefCounted


static func _field_with(points: Array) -> EnemyField:
	var f := EnemyField.new()
	f.bounds = Rect2(-50, -50, 100, 100)
	for p in points:
		var e := DummyEnemy.new()
		e.ground_pos = p
		f.add(e)
	return f


static func run(t) -> void:
	var f := _field_with([Vector2(0, 0), Vector2(2, 0), Vector2(5, 5)])
	t.check(f.in_radius(Vector2.ZERO, 2.5).size() == 2, "in_radius finds 2")
	var lane := f.in_lane(Vector2(-1, 0), Vector2(1, 0), 0.5, 0.0, 2.5)
	t.check(lane.size() == 1, "lane length excludes far enemy")
	lane = f.in_lane(Vector2(-1, 0), Vector2(1, 0), 0.5, 0.0, 3.5)
	t.check(lane.size() == 2, "lane covers two on axis")

	var e: DummyEnemy = f.alive()[0]
	t.check(f.kill(e, &"test"), "kill returns true first time")
	t.check(not f.kill(e, &"test"), "kill returns false when already dead")
	t.check(f.alive().size() == 2, "dead removed from alive")

	var g := _field_with([Vector2(4, 0), Vector2(0, -3)])
	var before := [g.alive()[0].ground_pos.length(), g.alive()[1].ground_pos.length()]
	for i in 180:
		g.pull(Vector2.ZERO, 4.5, 3.0, 1.0, 1.0 / 60.0)
	for i in 2:
		var d: float = g.alive()[i].ground_pos.length()
		t.check(d < before[i] * 0.3, "pull converges enemy %d (d=%f)" % [i, d])
		t.check(g.alive()[i].state == DummyEnemy.State.PULLED, "pulled state")
	g.release_all()
	t.check(g.alive()[0].state == DummyEnemy.State.WANDER, "release returns to wander")

	var k := _field_with([Vector2(3, 0)])
	k.knock_from(Vector2.ZERO, 0.0, 5.0, 6.0)
	for i in 30:
		k.alive()[0].tick(1.0 / 60.0)
	t.check(k.alive()[0].ground_pos.x > 3.2, "knockback pushes outward")
	for x in [f, g, k]:
		x.clear()
		x.free()
