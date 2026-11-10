extends RefCounted
## Skill Tree wheel Task 1: TreeWheel's rings, node places and Authority colours (a pure static helper).


static func run(t) -> void:
	_inside(t)
	_apart(t)
	_hit(t)
	_rings(t)
	_colors(t)


static func _spots() -> Array:
	var out := []
	for tier in range(1, 6):
		for i in 2:
			out.append([tier, i, TreeWheel.node_at(tier, i)])
	return out


static func _inside(t) -> void:
	for s in _spots():
		var p: Vector2 = s[2]
		var r := Rect2(p - Vector2(TreeWheel.NODE_R, TreeWheel.NODE_R), Vector2(TreeWheel.NODE_R * 2.0, TreeWheel.NODE_R * 2.0 + 10.0))
		t.check(TreeWheel.WHEEL_AREA.encloses(r), "tier %d spot %d (with its name) lies inside WHEEL_AREA" % [s[0], s[1]])
	var others := {"SIDE_L": TreeWheel.SIDE_L, "SIDE_R": TreeWheel.SIDE_R, "TOP_BAR": TreeWheel.TOP_BAR, "DETAIL": TreeWheel.DETAIL}
	for name in others:
		t.check(not TreeWheel.WHEEL_AREA.intersects(others[name]), "WHEEL_AREA does not meet " + name)


static func _apart(t) -> void:
	var sp := _spots()
	for a in sp.size():
		for b in range(a + 1, sp.size()):
			var d: float = (sp[a][2] as Vector2).distance_to(sp[b][2])
			t.check(d >= 2.0 * TreeWheel.NODE_R + 4.0, "nodes %d.%d and %d.%d are %.1f apart" % [sp[a][0], sp[a][1], sp[b][0], sp[b][1], d])


static func _hit(t) -> void:
	for s in _spots():
		t.check(TreeWheel.node_hit(s[2]) == Vector2i(s[0], s[1]), "node_hit finds %d.%d" % [s[0], s[1]])
	t.check(TreeWheel.node_hit(TreeWheel.CENTER) == Vector2i(-1, -1), "the centre hits no node")


static func _rings(t) -> void:
	var r1 := TreeWheel.ring(1)
	t.check(absf(r1.x - 31.9) < 0.01 and absf(r1.y - 22.0) < 0.01, "ring(1) is (31.9, 22), got %s" % [r1])
	t.check(is_equal_approx(TreeWheel.ring(5).y, 102.0), "ring(5).y is 102")


static func _colors(t) -> void:
	t.check(TreeWheel.color("dominion") == Color("9b7fd0"), "dominion colour")
	t.check(TreeWheel.color("nope") == UiTheme.COL_TEXT, "unknown type falls back to COL_TEXT")
	for k in ["dominion", "ruin", "death", "passage", "veil", "decree"]:
		t.check(TreeWheel.COLORS.has(k), "COLORS has " + k)
