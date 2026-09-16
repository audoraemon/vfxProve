extends RefCounted


static func run(t) -> void:
	var f := EnemyField.new()
	f.bounds = Rect2(-50, -50, 100, 100)
	for p in [Vector2(0, 0), Vector2(1, 0), Vector2(6, 0)]:
		var e := DummyEnemy.new()
		e.ground_pos = p
		f.add(e)
	var frozen := f.freeze_radius(Vector2.ZERO, 2.0, 1.0)
	t.check(frozen == 2, "freeze_radius freezes two (got %d)" % frozen)
	var a: DummyEnemy = f.alive()[0]
	var far: DummyEnemy = f.alive()[2]
	t.check(a.is_frozen() and not far.is_frozen(), "only enemies in radius frozen")
	var before := a.ground_pos
	for i in 30:
		f.pull(Vector2(3, 3), 10.0, 5.0, 1.0, 1.0 / 60.0)
		a.tick(1.0 / 60.0)
	t.check(a.ground_pos == before, "frozen enemy ignores pull")
	a.knock(Vector2(20, 0))
	for i in 10:
		a.tick(1.0 / 60.0)
	t.check(a.ground_pos == before, "frozen enemy ignores knockback")
	t.check(f.frozen_in_radius(Vector2.ZERO, 2.0).size() == 2, "frozen_in_radius lists frozen")
	for i in 70:
		a.tick(1.0 / 60.0)
	t.check(not a.is_frozen(), "enemy thaws after duration")
	t.check(f.kill(f.alive()[1], &"ice", Vector2.ZERO), "ice kill works")
	t.check(f.alive().size() == 2, "shattered enemy removed from alive")

	# LightField static lights (torches) persist until removed.
	var lights := LightField.new()
	var id := lights.add_static(Vector2(0, 0), 2.0, Color(1, 0.6, 0.2), 1.0)
	lights._process(5.0)
	t.check(lights.sample(Vector2(0.5, 0)).r > 0.0, "static light persists")
	lights.remove(id)
	lights._process(0.1)
	t.check(lights.sample(Vector2(0.5, 0)).r == 0.0, "removed static light gone")
	lights.free()
	f.clear()
	f.free()
