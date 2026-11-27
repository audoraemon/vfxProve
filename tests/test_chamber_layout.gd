extends RefCounted
## God's Chamber Task 2: the room's layout table and the greybox art hook -- every station sits inside the frame and below the
## top bar without touching another, keys map back to one station, parallax shifts snap and clamp, hit tests follow the
## shifted rects front layer first, and the art hook has no file for an unknown name while the four stations look different.


static func run(t) -> void:
	_rects(t)
	_keys(t)
	_shift(t)
	_hit(t)
	_art(t)


static func _rects(t) -> void:
	for k in ChamberLayout.ORDER:
		var r: Rect2 = ChamberLayout.STATIONS[k]["rect"]
		t.check(ChamberLayout.FRAME.encloses(r), "%s sits inside the frame" % k)
		t.check(r.position.y >= ChamberLayout.BAR_H, "%s sits below the top bar" % k)
		for k2 in ChamberLayout.ORDER:
			if k2 != k:
				t.check(not r.intersects(ChamberLayout.STATIONS[k2]["rect"]), "%s and %s do not overlap" % [k, k2])


static func _keys(t) -> void:
	t.check(ChamberLayout.ORDER.size() == 4 and ChamberLayout.STATIONS.size() == 4, "four stations in the order and the table")
	var seen := {}
	for k in ChamberLayout.ORDER:
		t.check(ChamberLayout.STATIONS.has(k), "%s has a station row" % k)
		var s: Dictionary = ChamberLayout.STATIONS[k]
		t.check((s["rect"] as Rect2).has_point(s["focus"]), "%s focus is inside its rect" % k)
		t.check(s["action"] == k, "%s action is its key" % k)
		for code in s["keys"]:
			t.check(ChamberLayout.key_for(code) == k, "key %d maps back to %s" % [code, k])
			t.check(not seen.has(code), "key %d belongs to one station" % code)
			seen[code] = true
	t.check(ChamberLayout.key_for(KEY_Z) == "", "an unbound key maps to no station")


static func _shift(t) -> void:
	t.check(ChamberLayout.shift("desk", Vector2(1, 0)) == Vector2(-6, 0), "the desk shifts the full 6 units")
	t.check(ChamberLayout.shift("wall", Vector2(1, 0)) == Vector2(-2, 0), "the wall's 1.5 snaps to 2")
	t.check(ChamberLayout.shift("desk", Vector2(5, -5)) == ChamberLayout.shift("desk", Vector2(1, -1)), "the mouse is clamped to -1..1")


static func _hit(t) -> void:
	for k in ChamberLayout.ORDER:
		var c: Vector2 = (ChamberLayout.STATIONS[k]["rect"] as Rect2).get_center()
		t.check(ChamberLayout.at(c) == k, "%s is found at rest" % k)
		for m in [Vector2(1, 1), Vector2(-1, -1)]:
			t.check(ChamberLayout.at(ChamberLayout.rect_of(k, m).get_center(), m) == k, "%s is found at mouse %s" % [k, m])
	t.check(ChamberLayout.at(Vector2(300, 10)) == "", "a point in the top bar hits nothing")
	t.check(ChamberLayout.at(Vector2(5, 340)) == "", "empty floor hits nothing")


static func _art(t) -> void:
	t.check(ChamberArt.texture("no_such") == null, "a missing art file gives no texture")
	var cols := []
	for k in ChamberLayout.ORDER:
		cols.append(ChamberArt.greybox_color(k))
	for i in cols.size():
		for j in range(i + 1, cols.size()):
			t.check(cols[i] != cols[j], "greybox colours %d and %d differ" % [i, j])
