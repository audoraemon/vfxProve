extends RefCounted
## The Skill Tree as a wheel (spec 2026-11-10): the own type between its ring neighbours, far types never shown, a click selects and only
## the gold button spends, an Authority centres from its chip, panel, small icon or Q/E, locked and empty spots, the first open's pick,
## the state a Remembrance returns to, and a layout whose hit areas stay on screen and apart.


static func run(t) -> void:
	GodTree.dev_fill = true
	_columns(t)
	_far_hidden(t)
	_click_selects_only(t)
	_buy(t)
	_centre(t)
	_mini(t)
	_empty_and_locked(t)
	_first_open(t)
	_state_round_trip(t)
	_learn_at_compat(t)
	_costs(t)
	_layout(t)
	_icons_loaded(t)
	_texts_fit(t)
	GodTree.dev_fill = false


static func _screen(type := "ruin", tier := 1, points := 0, p_state := {}) -> SkillTreeScreen:
	var slot := GodSlot.make(1, type, 7)
	slot.tier = tier
	slot.points = points
	return SkillTreeScreen.new().setup(slot, p_state)


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _columns(t) -> void:
	var s := _screen("ruin")
	t.check(Array(s.columns()) == ["dominion", "ruin", "passage"], "a ruin god shows dominion, ruin, passage (%s)" % [s.columns()])
	t.check(s.centred == 1, "and opens centred on its own type")
	s.free()
	var w := _screen("dominion")
	t.check(Array(w.columns()) == ["death", "dominion", "ruin"], "the ring wraps: dominion sits between death and ruin (%s)" % [w.columns()])
	w.free()


static func _far_hidden(t) -> void:
	var s := _screen("ruin")
	var shown := {}
	for c in s.columns():
		shown[c] = true
	var far := 0
	var seen := 0
	for x in range(0, 640, 2):
		for y in range(0, 360, 2):
			var h := s.hit(Vector2(x, y))
			var p := h.split(":")
			var col := -1
			if p[0] == "mini" or p[0] == "side":
				col = int(p[1])
			elif p[0] == "node":
				col = s.centred
			if col < 0:
				continue
			seen += 1
			if col >= s.columns().size() or not shown.has(s.columns()[col]) or ["veil", "death", "decree"].has(s.columns()[col]):
				far += 1
	t.check(seen > 0 and far == 0, "no point of the screen hits a spot or panel of veil, death or decree (%d hits, %d far)" % [seen, far])
	var keys := {}
	for col in 3:
		for tier in range(1, 6):
			for i in 2:
				var key := s.key_at(col, tier, i)
				if key != "":
					keys[GodTree.spot_of(key).type] = true
	t.check(keys.size() == 3 and not keys.has("veil") and not keys.has("death") and not keys.has("decree"),
		"the keys on the screen belong to three types only (%s)" % [keys.keys()])
	s.free()


static func _click_selects_only(t) -> void:
	var s := _screen("ruin", 1, 5)
	var emitted := []
	s.action.connect(func(what: String) -> void: emitted.append(what))
	s.click(TreeWheel.node_at(1, 0))
	t.check(s.selected == Vector3i(1, 1, 0), "a click on a node selects it (%s)" % [s.selected])
	t.check(s._slot.points == 5 and s._slot.level_of("smite") == 1 and emitted.is_empty(),
		"and spends nothing (%d points, smite %d, %s)" % [s._slot.points, s._slot.level_of("smite"), emitted])
	s._slot.learned.erase("smite")
	s.click(TreeWheel.node_at(1, 0))
	t.check(s._slot.level_of("smite") == 0 and s._slot.points == 5 and emitted.is_empty(), "even for an unlearned power")
	s.free()


static func _buy(t) -> void:
	var s := _screen("ruin", 1, 5)
	s._slot.learned.erase("smite")
	var emitted := []
	s.action.connect(func(what: String) -> void: emitted.append(what))
	s.click(TreeWheel.node_at(1, 0))
	t.check(s.hit(SkillTreeScreen.BUY_RECT.get_center()) == "buy", "the gold button is hit")
	s._on_gui_input(_click(SkillTreeScreen.BUY_RECT.get_center()))
	t.check(s._slot.level_of("smite") == 1 and s._slot.points == 4 and emitted == ["learned"],
		"the buy button learns it: level 1, 4 points, 'learned' once (%d, %d, %s)" % [s._slot.level_of("smite"), s._slot.points, emitted])
	s.click(SkillTreeScreen.BUY_RECT.get_center())
	t.check(s._slot.level_of("smite") == 2 and s._slot.points == 3 and emitted == ["learned", "learned"], "and again raises it")
	s._slot.learned["smite"] = 5
	s.click(SkillTreeScreen.BUY_RECT.get_center())
	t.check(s.refused_reason == "Already at level 5" and emitted.size() == 2, "level 5 is the top (%s)" % s.refused_reason)
	s._slot.learned["smite"] = 2
	s._slot.points = 0
	s.click(SkillTreeScreen.BUY_RECT.get_center())
	t.check(s.refused_reason == "Not enough ability points" and s._slot.level_of("smite") == 2 and emitted.size() == 2,
		"with no points it is refused and says why (%s)" % s.refused_reason)
	s._process(SkillTreeScreen.REFUSE_SECONDS + 0.1)
	t.check(s.refused_reason == "", "the reason goes after REFUSE_SECONDS")
	var back := []
	s.action.connect(func(what: String) -> void: back.append(what))
	s._on_gui_input(_click(SkillTreeScreen.BACK_RECT.get_center()))
	s._unhandled_input(_key(KEY_ESCAPE))
	t.check(back == ["back", "back"], "Back and Esc leave (%s)" % [back])
	s.free()


static func _centre(t) -> void:
	var s := _screen("ruin", 1, 5)
	s.click(s.chip_rect(0).get_center())
	t.check(s.centred == 0, "a click on chip 0 centres the left neighbour (%d)" % s.centred)
	s.click(TreeWheel.node_at(1, 0))
	t.check(s.selected == Vector3i(0, 1, 0) and s.selected_key() == s.key_at(0, 1, 0) and s.selected_key() != "",
		"and the wheel now selects that column's powers (%s, %s)" % [s.selected, s.selected_key()])
	s._unhandled_input(_key(KEY_Q))
	t.check(s.centred == 2, "Q wraps from the first to the last (%d)" % s.centred)
	s._unhandled_input(_key(KEY_E))
	t.check(s.centred == 0, "E wraps back (%d)" % s.centred)
	s._unhandled_input(_key(KEY_E))
	t.check(s.centred == 1, "E moves right (%d)" % s.centred)
	var side := s.side_col(0)
	s.click(SkillTreeScreen.side_rect(0).position + Vector2(56, 30))
	t.check(s.centred == side, "a click on a side panel centres it (%d, wanted %d)" % [s.centred, side])
	t.check(s.side_col(0) != s.side_col(1) and s.side_col(0) != s.centred and s.side_col(1) != s.centred,
		"and the panels show the other two")
	s.free()


static func _mini(t) -> void:
	var s := _screen("ruin", 1, 5)
	var col := s.side_col(0)
	var at := SkillTreeScreen.mini_rect(SkillTreeScreen.side_rect(0), 1, 0).get_center()
	t.check(s.hit(at) == "mini:%d:1:0" % col, "a side panel's first small icon is hit (%s)" % s.hit(at))
	s.click(at)
	t.check(s.selected == Vector3i(col, 1, 0) and s.centred == 1, "clicking it selects that spot without centring (%s, %d)" % [s.selected, s.centred])
	t.check(s._slot.points == 5, "and spends nothing")
	s.free()


static func _empty_and_locked(t) -> void:
	var s := _screen("dominion", 1, 6)
	var emitted := []
	s.action.connect(func(what: String) -> void: emitted.append(what))
	var key := s.key_at(1, 3, 0)
	s.select(1, 3, 0)
	t.check(s.selected_key() == key and key != "", "a tier 3 power can be selected at tier 1 (%s)" % key)
	s.click(SkillTreeScreen.BUY_RECT.get_center())
	t.check(s.refused_reason == "Awaken to Tier 3" and s._slot.level_of(key) == 0 and emitted.is_empty(),
		"buying it is refused: Awaken to Tier 3 (%s)" % s.refused_reason)
	s.click(SkillTreeScreen.REMEMBER_RECT.get_center())
	t.check(emitted == ["remember"], "but Remembrance still opens (%s)" % [emitted])
	s.free()
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var d := _screen("death", 1, 6)
	var got := []
	d.action.connect(func(what: String) -> void: got.append(what))
	d.select(1, 2, 0)
	t.check(d.selected_key() == "", "an empty spot selects as no key")
	t.check(d.hit(SkillTreeScreen.REMEMBER_RECT.get_center()) == "" and d.hit(SkillTreeScreen.BUY_RECT.get_center()) == "",
		"and the buttons are not there")
	d.click(SkillTreeScreen.REMEMBER_RECT.get_center())
	d.click(SkillTreeScreen.BUY_RECT.get_center())
	t.check(got.is_empty() and d._slot.points == 6, "so they emit and spend nothing (%s)" % [got])
	t.check(d.learn_at(1, 2, 0) == "unknown", "learn_at on an empty spot is 'unknown'")
	d.free()
	GodTree.use_table({})
	GodTree.dev_fill = true


static func _first_open(t) -> void:
	var slot := GodSlot.make(1, "dominion", 7)
	slot.learned["whisper"] = 5
	slot.learned["discord"] = 2
	var s := SkillTreeScreen.new().setup(slot)
	t.check(s.selected_key() == "discord" and s.selected.x == 1, "a god with whisper 5 and discord 2 opens on discord (%s)" % s.selected_key())
	s.free()
	var f := _screen("ruin")
	t.check(f.selected == Vector3i(1, 1, 0), "a fresh god opens on its first spot (%s)" % [f.selected])
	f.free()
	var g := GodSlot.make(1, "ruin", 7)
	g.learned.clear()
	g.points = 3
	var h := SkillTreeScreen.new().setup(g)
	t.check(h.selected == Vector3i(1, 1, 0) and h.remember_level() == 1, "nothing learned: the first learnable, Remembrance starts at 1")
	h.free()
	var k := _screen("ruin")
	k._slot.learned["smite"] = 3
	k.select(1, 1, 0)
	t.check(k.remember_level() == 3, "Remembrance starts at the learned level (%d)" % k.remember_level())
	k.free()


static func _state_round_trip(t) -> void:
	var a := _screen("ruin", 2, 1)
	a.centre(2)
	a.select(2, 1, 1)
	var b := _screen("ruin", 2, 1, a.state())
	t.check(b.centred == 2 and b.selected == Vector3i(2, 1, 1), "setup restores the state (%d, %s)" % [b.centred, b.selected])
	a.free()
	b.free()


static func _learn_at_compat(t) -> void:
	var s := _screen("ruin", 1, 0)
	var emitted := []
	s.action.connect(func(what: String) -> void: emitted.append(what))
	s._slot.learned.erase("smite")
	t.check(s.learn_at(1, 1, 0) == "points" and s.refused_reason == "Not enough ability points" and emitted.is_empty(),
		"learn_at with no points returns 'points' and says why")
	s._slot.points = 1
	t.check(s.learn_at(1, 1, 0) == "" and s._slot.level_of("smite") == 1 and emitted == ["learned"],
		"with a point it learns and emits 'learned'")
	t.check(s.learn_at(1, 2, 0) == "tier" and s.refused_reason == "Awaken to Tier 2", "a locked tier is refused (%s)" % s.refused_reason)
	s.free()


static func _costs(t) -> void:
	var s := _screen("ruin", 1, 1)
	t.check(s.learn_at(2, 1, 0) == "points" and s._slot.level_of("skylift") == 0, "a neighbour's power needs 2 points, not 1")
	s._slot.points = 2
	t.check(s.learn_at(2, 1, 0) == "" and s._slot.level_of("skylift") == 1 and s._slot.points == 0, "and spends 2")
	s.free()


static func _layout(t) -> void:
	var screen := Rect2(0, 0, 640, 360)
	var s := _screen("ruin", 3, 4)
	var rects := {"back": SkillTreeScreen.BACK_RECT, "remember": SkillTreeScreen.REMEMBER_RECT, "buy": SkillTreeScreen.BUY_RECT,
		"side0": TreeWheel.SIDE_L, "side1": TreeWheel.SIDE_R, "points": s.points_rect()}
	for c in 3:
		rects["chip%d" % c] = s.chip_rect(c)
	var names := rects.keys()
	var inside := true
	var apart := true
	var clear := true
	for a in names.size():
		var ra: Rect2 = rects[names[a]]
		inside = inside and screen.encloses(ra)
		clear = clear and not ra.intersects(TreeWheel.WHEEL_AREA)
		for b in range(a + 1, names.size()):
			if ra.intersects(rects[names[b]]):
				apart = false
				t.check(false, "%s overlaps %s" % [names[a], names[b]])
	t.check(inside, "every hit rect lies inside the 640x360 screen")
	t.check(apart, "no two overlap")
	t.check(clear, "and none touches the wheel's area")
	t.check(TreeWheel.DETAIL.encloses(SkillTreeScreen.REMEMBER_RECT) and TreeWheel.DETAIL.encloses(SkillTreeScreen.BUY_RECT)
		and TreeWheel.DETAIL.encloses(SkillTreeScreen.CLIP_BOX), "the buttons and the clip box sit in the detail panel")
	var minis_ok := true
	for side in 2:
		for tier in range(1, 6):
			for i in 2:
				minis_ok = minis_ok and SkillTreeScreen.side_rect(side).encloses(
					SkillTreeScreen.mini_rect(SkillTreeScreen.side_rect(side), tier, i))
	t.check(minis_ok, "the small icons sit inside their side panels")
	s.free()


static func _icons_loaded(t) -> void:
	var s := _screen("ruin")
	var missing := PackedStringArray()
	var with_key := 0
	for col in 3:
		for tier in range(1, 6):
			for i in 2:
				var key := s.key_at(col, tier, i)
				if key == "":
					continue
				with_key += 1
				if not s._icons.has(key) or s._icons[key] == null:
					missing.append(key)
	t.check(with_key > 0 and SkillTreeScreen.spot_icon("smite") != null, "smite has an icon (%d spots with a power)" % with_key)
	t.check(missing.is_empty(), "every power in the tree has its icon loaded in setup (missing: %s)" % ", ".join(missing))
	s.free()


## Nothing the page writes is cut: every description fits two lines of the info column with no "...", and every node name fits its
## label, no two labels of a wheel overlap and none leaves the screen.
static func _texts_fit(t) -> void:
	var cut := PackedStringArray()
	var chopped := PackedStringArray()
	var overlaps := PackedStringArray()
	for type in ["ruin", "dominion", "death", "passage", "veil", "decree"]:
		var s := _screen(type)
		for col in 3:
			for tier in range(1, 6):
				for i in 2:
					var key := s.key_at(col, tier, i)
					if key == "":
						continue
					var d := TreeDetail.description(key, SkillTreeScreen.INFO_W)
					if d.size() > 2 or (d.size() > 0 and d[d.size() - 1].ends_with("...")):
						cut.append(key)
		for col in 3:
			var labels: Array[Rect2] = []
			var owners: Array[Vector2i] = []
			for tier in range(1, 6):
				for i in 2:
					var key := s.key_at(col, tier, i)
					if key == "":
						continue
					var shown := SkillTreeScreen.node_label(String(PowerBook.get_power(key).name))
					var full := String(PowerBook.get_power(key).name)
					if shown != full and not (shown.ends_with("...") and full.begins_with(shown.trim_suffix("..."))):
						chopped.append(key)
					if UiTheme.width(shown, SkillTreeScreen.NODE_NAME_PX) > SkillTreeScreen.NODE_NAME_W:
						chopped.append(key + " (too wide)")
					labels.append(SkillTreeScreen.node_label_rect(tier, i, shown))
					owners.append(Vector2i(tier, i))
			for a in labels.size():
				for tt in range(1, 6):
					for ii in 2:
						var circle := Rect2(TreeWheel.node_at(tt, ii) - Vector2.ONE * TreeWheel.NODE_R, Vector2.ONE * TreeWheel.NODE_R * 2.0)
						if labels[a].intersects(circle) and Vector2i(tt, ii) != owners[a]:
							overlaps.append("%s col %d label %d on node %d:%d" % [type, col, a, tt, ii])
				if not Rect2(0, 0, 640, 360).encloses(labels[a]):
					overlaps.append("%s col %d label %d off screen" % [type, col, a])
				for b in range(a + 1, labels.size()):
					if labels[a].intersects(labels[b]):
						overlaps.append("%s col %d labels %d/%d" % [type, col, a, b])
		s.free()
	t.check(cut.is_empty(), "every description fits two lines at the info column's width, none ends in ... (%s)" % [cut])
	t.check(chopped.is_empty(), "every node name shows whole, or visibly ellipsised within its label (%s)" % [chopped])
	t.check(overlaps.is_empty(), "no two node labels overlap and none leaves the screen (%s)" % [overlaps])
