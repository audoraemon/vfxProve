extends RefCounted
## God P1 Task 8 (spec §5.2-§5.4, §12): the Skill Tree screen -- the own type between its ring neighbours, far types never shown, the
## 30 spots laid out clear of the detail panel and Back, each spot's lines, a locked tier refused, learning spends points and emits.


static func run(t) -> void:
	GodTree.dev_fill = true
	_columns(t)
	_layout(t)
	_lines(t)
	_locked_tier(t)
	_learn(t)
	_far_hidden(t)
	_header_and_detail(t)
	_spot_icons(t)
	GodTree.dev_fill = false


static func _screen(type := "ruin", tier := 1, points := 0) -> SkillTreeScreen:
	var slot := GodSlot.make(1, type, 7)
	slot.tier = tier
	slot.points = points
	return SkillTreeScreen.new().setup(slot)


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _columns(t) -> void:
	var s := _screen("ruin")
	t.check(Array(s.columns()) == ["dominion", "ruin", "death"], "a ruin god shows dominion, ruin, death (%s)" % [s.columns()])
	t.check(s.column_title(1) == "RUIN" and s.column_title(0) == "DOMINION x2" and s.column_title(2) == "DEATH x2",
		"the own column is titled, each neighbour's says x2 (%s, %s, %s)" % [s.column_title(0), s.column_title(1), s.column_title(2)])
	s.free()
	var w := _screen("dominion")
	t.check(Array(w.columns()) == ["decree", "dominion", "ruin"], "the ring wraps: dominion sits between decree and ruin (%s)" % [w.columns()])
	w.free()


static func _layout(t) -> void:
	var screen := Rect2(0, 0, 640, 360)
	var rects: Array[Rect2] = []
	for col in 3:
		for tier in range(1, 6):
			for i in 2:
				rects.append(SkillTreeScreen.spot_rect(col, tier, i))
	t.check(rects.size() == 30, "30 spots (%d)" % rects.size())
	var inside := true
	var clear := true
	var apart := true
	for a in rects.size():
		inside = inside and screen.encloses(rects[a])
		clear = clear and not rects[a].intersects(SkillTreeScreen.DETAIL) and not rects[a].intersects(SkillTreeScreen.BACK_RECT)
		for b in range(a + 1, rects.size()):
			apart = apart and not rects[a].intersects(rects[b])
	t.check(inside, "every spot lies inside the 640x360 screen")
	t.check(apart, "no two spots overlap")
	t.check(clear, "no spot touches the detail panel or Back")
	t.check(screen.encloses(SkillTreeScreen.DETAIL) and screen.encloses(SkillTreeScreen.BACK_RECT)
		and not SkillTreeScreen.DETAIL.intersects(SkillTreeScreen.BACK_RECT), "the detail panel and Back fit and stay apart")


static func _lines(t) -> void:
	var s := _screen("ruin", 1, 0)
	s._slot.learned["smite"] = 2
	var want := PackedStringArray(["Smite", "2 / 5", "1 Might", "Level 3: 1 point", PowerBook.NO_LEVELS])
	t.check(s.spot_lines(1, 1, 0) == want, "smite learned at 2: name, pips, Might, next level, its change (%s)" % [s.spot_lines(1, 1, 0)])
	var death := s.spot_lines(2, 1, 0)
	t.check(death[0] == "Death Mark" and death[1] == "0 / 5" and death[3] == "Learn: 2 points",
		"a neighbour's unlearned spot costs 2 points to learn (%s)" % [death])
	var ember := s.spot_lines(1, 1, 1)
	t.check(ember[3] == "Level 2: 1 point", "a learned-at-1 own spot: next is level 2 for 1 point (%s)" % [ember])
	s._slot.learned["smite"] = 5
	t.check(s.spot_lines(1, 1, 0)[3] == "Level 5" and s.spot_lines(1, 1, 0)[1] == "5 / 5", "level 5 reads Level 5 (%s)" % [s.spot_lines(1, 1, 0)])
	s.free()
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var bare := _screen("ruin")
	var all_empty := true
	for col in 3:
		for tier in range(1, 6):
			for i in 2:
				all_empty = all_empty and bare.spot_lines(col, tier, i) == PackedStringArray([GodTree.NOT_CHOSEN])
	t.check(all_empty, "with the dev fill off every spot reads Not yet chosen")
	t.check(bare.learn_at(1, 1, 0) == "unknown", "and an empty spot cannot be learned (unknown)")
	bare.free()
	GodTree.use_table({})
	GodTree.dev_fill = true


static func _locked_tier(t) -> void:
	var s := _screen("ruin", 1, 5)
	var why := s.learn_at(1, 2, 0)
	t.check(why == "tier" and s._slot.level_of("heaven") == 0, "a Tier 1 god cannot learn a Tier 2 spot (%s)" % why)
	t.check(s.refused_reason == "Awaken to Tier 2", "and the panel says what unlocks it (%s)" % s.refused_reason)
	t.check(s._slot.points == 5, "a refusal spends nothing (%d)" % s._slot.points)
	s._slot.tier = 2
	t.check(s.learn_at(1, 2, 0) == "" and s._slot.level_of("heaven") == 1, "after Awaken to Tier 2 it can")
	s.free()


static func _learn(t) -> void:
	var s := _screen("ruin", 1, 1)
	var emitted := []
	s.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(s.learn_at(1, 1, 0) == "" and s._slot.level_of("smite") == 2 and s._slot.points == 0,
		"one point raises smite to level 2 (%d, %d points)" % [s._slot.level_of("smite"), s._slot.points])
	t.check(emitted == ["learned"], "and 'learned' is emitted (%s)" % [emitted])
	t.check(s.learn_at(1, 1, 0) == "points" and s._slot.level_of("smite") == 2 and emitted == ["learned"],
		"with no points left it is refused (points) and nothing is emitted")
	t.check(s.refused_reason == "Not enough ability points", "the panel says why (%s)" % s.refused_reason)
	# A real click on a spot does the same as learn_at.
	s._slot.points = 2
	s._on_gui_input(_click(SkillTreeScreen.spot_rect(1, 1, 1).get_center()))
	t.check(s._slot.level_of("ember") == 2 and emitted.size() == 2, "a click on a spot learns it (%d)" % s._slot.level_of("ember"))
	# A neighbour's spot costs double.
	s._slot.points = 1
	t.check(s.learn_at(2, 1, 0) == "points" and s._slot.level_of("deathmark") == 0, "a neighbour's spot needs 2 points, not 1")
	s._slot.points = 2
	t.check(s.learn_at(2, 1, 0) == "" and s._slot.level_of("deathmark") == 1 and s._slot.points == 0, "and spends 2")
	s._slot.learned["smite"] = 5
	s._slot.points = 3
	t.check(s.learn_at(1, 1, 0) == "max", "level 5 is the top (max)")
	# Back.
	var back := []
	s.action.connect(func(what: String) -> void: back.append(what))
	s._on_gui_input(_click(SkillTreeScreen.BACK_RECT.get_center()))
	t.check(back.has("back"), "Back leaves the screen (%s)" % [back])
	s.free()


static func _far_hidden(t) -> void:
	var s := _screen("ruin")
	var shown := {}
	for c in s.columns():
		shown[c] = true
	var hits := 0
	var far := 0
	for x in range(0, 640, 2):
		for y in range(0, 360, 2):
			var h := s.hit(Vector2(x, y))
			if not h.begins_with("spot:"):
				continue
			hits += 1
			var at := h.split(":")
			var type: String = s.columns()[int(at[1])]
			if not shown.has(type) or ["veil", "passage", "decree"].has(type):
				far += 1
	t.check(hits > 0 and far == 0, "no point of the screen hits a spot of veil, passage or decree (%d hits, %d far)" % [hits, far])
	var keys := {}
	for col in 3:
		for tier in range(1, 6):
			for i in 2:
				var key := s.key_at(col, tier, i)
				if key != "":
					keys[GodTree.spot_of(key).type] = true
	t.check(keys.size() == 3 and not keys.has("veil") and not keys.has("passage") and not keys.has("decree"),
		"the keys on the screen belong to three types only (%s)" % [keys.keys()])
	t.check(s.hit(Vector2(630, 5)) == "" and s.hit(SkillTreeScreen.spot_rect(2, 5, 1).get_center()) == "spot:2:5:1",
		"hit names a spot or nothing")
	s.free()


static func _header_and_detail(t) -> void:
	var s := _screen("ruin", 1, 3)
	t.check(s.header_text() == "SKILL TREE   RUIN   Ability points 3", "the header (%s)" % s.header_text())
	t.check(s.detail_lines().size() == 1, "no spot shown: one hint line")
	s._hover = "spot:1:1:0"
	var lines := s.detail_lines()
	t.check(lines.size() >= 2 and lines[0].begins_with("Smite") and lines[1].begins_with("Level 2: 1 point"),
		"hovering a spot: its title line, then its next level (%s)" % [lines])
	s._hover = "spot:1:3:0"
	t.check(s.detail_lines()[0].begins_with("Dragon"), "another spot (%s)" % [s.detail_lines()])
	s.free()


## M6 (final review, spec §12): every spot with an ability draws that power's icon, small, left of the name -- inside the spot, clear of
## the level pips under it.
static func _spot_icons(t) -> void:
	var s := _screen("ruin")
	var with_key := 0
	var missing := PackedStringArray()
	for col in 3:
		for tier in range(1, 6):
			for i in 2:
				var key := s.key_at(col, tier, i)
				if key == "":
					continue
				with_key += 1
				var spot := SkillTreeScreen.spot_rect(col, tier, i)
				var box := SkillTreeScreen.icon_rect(col, tier, i)
				t.check(spot.encloses(box) and box.size == Vector2(SkillTreeScreen.ICON_PX, SkillTreeScreen.ICON_PX),
					"the icon of %s sits inside its spot (%s in %s)" % [key, box, spot])
				t.check(box.end.x <= spot.position.x + SkillTreeScreen.NAME_X and box.end.y <= spot.position.y + 15.0,
					"and clear of the name and the pips (%s)" % [box])
				if SkillTreeScreen.spot_icon(key) == null:
					missing.append(key)
	t.check(with_key > 0 and SkillTreeScreen.spot_icon("smite") != null, "smite has an icon to draw (%d spots with a power)" % with_key)
	t.check(missing.is_empty(), "every power in the tree has an icon (missing: %s)" % ", ".join(missing))
	s.free()
