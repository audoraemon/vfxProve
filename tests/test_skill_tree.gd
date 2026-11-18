extends RefCounted
const UiScaleTest := preload("res://tests/test_ui_scale.gd")
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
	_labels_clear(t)
	_refusal_fits(t)
	_value_columns(t)
	_crisp_only(t)
	_pulse(t)
	_mini_cells(t)
	_states_draw(t)
	_click_through_input(t)
	_twists_whole(t)
	_word_spacing(t)
	_death_decree_twists(t)
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


## Nothing the page writes is cut: every description fits two lines of the info column with no "...", and every node name shows whole
## (or visibly ellipsised) within its label width. (Where the labels sit is _labels_clear.)
static func _texts_fit(t) -> void:
	var cut := PackedStringArray()
	var chopped := PackedStringArray()
	for type in ["ruin", "dominion", "death", "passage", "veil", "decree"]:
		var s := _screen(type)
		for col in 3:
			for tier in range(1, 6):
				for i in 2:
					var key := s.key_at(col, tier, i)
					if key == "":
						continue
					var d := TreeDetail.description(key, SkillTreeScreen.INFO_W)
					if d.size() > TreeDetail.DESCRIPTION_LINES or (d.size() > 0 and d[d.size() - 1].ends_with("...")):
						cut.append(key)
					var full := String(PowerBook.get_power(key).name)
					if SkillTreeScreen.node_label(full) != full:
						chopped.append(key)
		s.free()
	t.check(cut.is_empty(), "every description fits two lines at the info column's width, none ends in ... (%s)" % [cut])
	t.check(chopped.is_empty(), "every node name shows whole, never cut (%s)" % [chopped])


## Every name's strip, in every column of every type, sits inside LABEL_AREA, clear of every node disc grown 3 u and of the ring numeral
## plates, and no two strips of a wheel meet; and the layout is cached per column.
static func _labels_clear(t) -> void:
	var bad := PackedStringArray()
	var count := 0
	for type in ["ruin", "dominion", "death", "passage", "veil", "decree"]:
		var s := _screen(type, 5, 3)
		for col in 3:
			var layout := s.label_layout(col)
			var keys := 0
			for tier in range(1, 6):
				for i in 2:
					if s.key_at(col, tier, i) != "":
						keys += 1
			if layout.size() != keys:
				bad.append("%s col %d: %d strips for %d powers" % [type, col, layout.size(), keys])
			var strips: Array = layout.keys()
			for at: Vector2i in strips:
				var r: Rect2 = layout[at]
				var tag := "%s col %d %d:%d" % [type, col, at.x, at.y]
				count += 1
				var full := String(PowerBook.get_power(s.key_at(col, at.x, at.y)).name)
				var lines := SkillTreeScreen.label_lines(full, r.size.y > SkillTreeScreen.LABEL_STRIP_H + 1.0)
				if " ".join(lines) != full:
					bad.append(tag + " shows a cut name")
				for l in lines:
					if UiTheme.width(l, SkillTreeScreen.NODE_NAME_PX) + 6.0 > r.size.x:
						bad.append(tag + " strip narrower than its text")
				if not SkillTreeScreen.LABEL_AREA.encloses(r):
					bad.append(tag + " leaves LABEL_AREA")
				for tt in range(1, 6):
					for ii in 2:
						var p := TreeWheel.node_at(tt, ii)
						if p.clamp(r.position, r.end).distance_to(p) < TreeWheel.NODE_R + 3.0 - 0.001:
							bad.append("%s touches the disc %d:%d" % [tag, tt, ii])
				for plate in SkillTreeScreen.numeral_plates():
					if r.intersects(plate):
						bad.append(tag + " covers a numeral plate")
				var own := TreeWheel.node_at(at.x, at.y).clamp(r.position, r.end).distance_to(TreeWheel.node_at(at.x, at.y)) - TreeWheel.NODE_R
				var nearest := INF
				for tt in range(1, 6):
					for ii in 2:
						if Vector2i(tt, ii) != at:
							var q := TreeWheel.node_at(tt, ii)
							nearest = minf(nearest, q.clamp(r.position, r.end).distance_to(q) - TreeWheel.NODE_R)
				if own > 6.0 + 0.001 or own > 0.7 * nearest + 0.001:
					bad.append("%s is %.1f from its node and %.1f from the nearest other" % [tag, own, nearest])
				for other: Vector2i in strips:
					if other != at and r.intersects(layout[other]):
						bad.append("%s meets strip %d:%d" % [tag, other.x, other.y])
			t.check(s.label_layout(col) == layout, "%s col %d: the layout is cached" % [type, col])
		s.free()
	t.check(count > 100 and bad.is_empty(), "every label strip (%d) is inside LABEL_AREA, off every disc and plate and apart: %s" % [count, bad.slice(0, 12)])


static func _refusal_fits(t) -> void:
	var reasons := PackedStringArray(["Not enough ability points"])
	for v in SkillTreeScreen.REFUSALS.values():
		reasons.append(String(v) % 5 if String(v).contains("%d") else String(v))
	var bad := PackedStringArray()
	for r in reasons:
		var lines := SkillTreeScreen.refusal_lines(r)
		if lines.size() > 2 or lines.is_empty():
			bad.append("%s: %d lines" % [r, lines.size()])
		for l in lines:
			if UiTheme.width(l, UiTheme.TEXT_S) > 96.0:
				bad.append("%s: line '%s' is %.0f u" % [r, l, UiTheme.width(l, UiTheme.TEXT_S)])
	t.check(bad.is_empty(), "every refusal wraps to at most 2 lines of 96 u at 11 u: %s" % [bad])
	t.check(Array(SkillTreeScreen.refusal_lines("Not enough ability points")) == ["Not enough", "ability points"],
		"'Not enough ability points' breaks as 'Not enough' / 'ability points'")
	t.check(SkillTreeScreen.refusal_lines("one two three four five six seven eight nine ten eleven twelve").size() == 2, "a long text is cut to 2 lines")


static func _value_columns(t) -> void:
	var rows := [{"label": "Damage", "old": "10", "new": "14"}, {"label": "Radius", "old": "4.0", "new": "4.5"},
		{"label": "Cooldown", "old": "8.0", "new": "10.25"}, {"label": "Fire", "old": "yes", "new": "yes"}, {"label": "Might", "old": "9", "new": "12"}]
	var cols := SkillTreeScreen.value_columns(rows)
	var right := SkillTreeScreen.LEVEL_X + SkillTreeScreen.LEVEL_W - 6.0
	t.check(is_equal_approx(float(cols.right), right) and is_equal_approx(right, 513.0), "the column's right edge is 513")
	t.check(float(cols.arrow_x) > float(cols.old_right) and float(cols.arrow_x) < right, "the arrow sits between the old values and the new ones")
	var olds := {}
	var news := {}
	var wide := 0.0
	for row: Dictionary in rows:
		var lay := SkillTreeScreen.row_layout(row, cols)
		news[snappedf(float(lay.new_x) + UiTheme.width(String(lay["new"]), SkillTreeScreen.SMALL_PX), 0.001)] = true
		if lay.changed:
			olds[snappedf(float(lay.old_x) + UiTheme.width(String(lay.old), SkillTreeScreen.SMALL_PX), 0.001)] = true
			wide = maxf(wide, UiTheme.width(String(lay["new"]), SkillTreeScreen.SMALL_PX))
	t.check(news.size() == 1 and is_equal_approx(float(news.keys()[0]), right), "every new value ends at the right edge (%s)" % [news.keys()])
	t.check(olds.size() == 1 and is_equal_approx(float(olds.keys()[0]), float(cols.old_right)), "every old value ends at old_right (%s)" % [olds.keys()])
	t.check(is_equal_approx(float(cols.new_w), wide), "the new column is as wide as the widest changed new value")
	t.check(not SkillTreeScreen.row_layout(rows[3], cols).changed, "an unchanged row shows its value alone")
	t.check(SkillTreeScreen.num("4.0") == "4" and SkillTreeScreen.num("10.25") == "10.25" and SkillTreeScreen.num("1.05") == "1.05", "num drops a needless .0 only")
	var m := SkillTreeScreen.might_row("30 -> 34")
	t.check(m.old == "30" and m["new"] == "34" and SkillTreeScreen.might_row("30").old == "30", "the Might line splits into old and new")


## Only the crisp sizes: 11, 22, 33 and 66 through TEXT_*, NODE_NAME_PX, SMALL_PX and SIZE_CHIP; no old SIZE_* and no text call that leaves
## its size out (the defaults are the 13 u body size).
static func _crisp_only(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/ui/skill_tree_screen.gd")
	for old in ["SIZE_SMALL", "SIZE_BODY", "SIZE_BIG", "SIZE_TITLE", "SIZE_HUGE"]:
		t.check(not src.contains(old), "skill_tree_screen.gd does not use " + old)
	var okay := RegEx.create_from_string("^(UiTheme\\.TEXT_[A-Z]+|NODE_NAME_PX|SMALL_PX|SIZE_CHIP|size|int\\(shown\\.size\\))$")
	var sizes := {"UiTheme.text": 3, "UiTheme.width": 1, "UiTheme.wrap": 2, "UiTheme.fit": 2, "_text_centred": 3}
	var bad := PackedStringArray()
	var seen := 0
	for call in sizes:
		var rx := RegEx.create_from_string("(?<![A-Za-z0-9_.])(?<!func )" + String(call).replace(".", "\\.") + "\\(")
		for m in rx.search_all(src):
			var args: Array = UiScaleTest._call_args(src, m.get_end() - 1)
			var n: int = args.size() - 1
			var line := src.substr(0, m.get_start()).count("\n") + 1
			var idx: int = sizes[call]
			seen += 1
			if n <= idx or okay.search(String(args[idx])) == null:
				bad.append("%s line %d" % [call, line])
	t.check(seen > 40 and bad.is_empty(), "every text call names a crisp size (%d calls); offenders: %s" % [seen, bad])
	t.check(SkillTreeScreen.NODE_NAME_PX == 11 and SkillTreeScreen.SMALL_PX == 11 and SkillTreeScreen.SIZE_CHIP == 11, "the three size constants are 11")


static func _pulse(t) -> void:
	var s := _screen("ruin", 1, 3)
	s._slot.learned.clear()
	var lo := 1.0
	var hi := 0.0
	var same := true
	for k in 160:
		var tt := float(k) * 0.01
		var a := s.pulse_alpha(tt)
		lo = minf(lo, a)
		hi = maxf(hi, a)
		same = same and absf(a - s.pulse_alpha(tt + SkillTreeScreen.PULSE_SECONDS)) < 1e-4
	t.check(lo >= 0.14 - 1e-6 and hi <= 0.32 + 1e-6 and hi > 0.31 and lo < 0.15, "pulse_alpha stays in [0.14, 0.32] and reaches both ends (%f, %f)" % [lo, hi])
	t.check(same and SkillTreeScreen.PULSE_SECONDS == 1.6, "and repeats every 1.6 s")
	var cold := _screen("ruin", 1, 0)
	t.check(s._any_can() and not cold._any_can(), "only a wheel with an affordable power redraws for the pulse")
	cold.free()
	s.free()


static func _mini_cells(t) -> void:
	for side in 2:
		var panel := SkillTreeScreen.side_rect(side)
		var cells: Array[Rect2] = []
		for tier in range(1, 6):
			for i in 2:
				cells.append(SkillTreeScreen.mini_rect(panel, tier, i))
		t.check(cells.size() == 10, "10 mini cells per panel")
		var ok := true
		var apart := true
		for a in cells.size():
			ok = ok and panel.encloses(cells[a]) and cells[a].size == Vector2(22, 22) and cells[a].end.y <= panel.end.y - 8.0 - 9.0
			for b in range(a + 1, cells.size()):
				apart = apart and not cells[a].intersects(cells[b])
		t.check(ok and apart, "the cells are 22 u, inside the panel, above the bottom line and apart (side %d)" % side)
		t.check(is_equal_approx(cells[0].get_center().x, panel.get_center().x - 13.0) and is_equal_approx(cells[1].get_center().x, panel.get_center().x + 13.0)
			and is_equal_approx(cells[0].position.y, panel.position.y + 60.0) and is_equal_approx(cells[8].position.y, panel.position.y + 60.0 + 96.0),
			"two columns at the middle +- 13, rows 24 apart from +60")


## UiIcon.grey: a texture with an image gets a real grey copy (luma x 0.85, alpha kept, drawn white); one without (headless) gets itself back and the tint stand-in.
static func _grey_copy(t) -> void:
	var img := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(1.0, 0.0, 0.0, 1.0))
	img.set_pixel(1, 0, Color(0.0, 0.0, 1.0, 0.5))
	var tex := ImageTexture.create_from_image(img)
	var g := UiIcon.grey(tex)
	t.check(g != tex and g.has_meta("ui_grey"), "an icon with an image gets a new grey copy, marked ui_grey")
	t.check(UiIcon.locked_tint(g) == Color.WHITE, "a real grey copy is drawn white")
	var out := g.get_image()
	t.check(out != null, "the grey copy gives its image back")
	if out != null:
		var red := out.get_pixel(0, 0)
		t.near(red.r, 0.299 * UiIcon.GREY_LUMA, 0.01, "red goes to its luma x 0.85")
		t.check(is_equal_approx(red.r, red.g) and is_equal_approx(red.g, red.b), "and is grey (r = g = b)")
		t.near(out.get_pixel(1, 0).a, 0.5, 0.01, "alpha is kept")
	var plain := PlaceholderTexture2D.new()
	var same := UiIcon.grey(plain)
	t.check(same == plain and UiIcon.locked_tint(same) == UiIcon.LOCKED_TINT, "a texture with no image stays itself and gets the tint stand-in")
	t.check(UiIcon.grey(null) == null, "no texture, no grey")


## Locked powers have their own ring colour; the buttons and bars are drawn where hit() looks for them (source-text drift guards).
static func _states_draw(t) -> void:
	var s := _screen("ruin", 1, 1)
	t.check(s.node_state(1, 3, 0) == "lock", "a power of a tier above is locked")
	t.check(SkillTreeScreen.state_edge("lock", Color.RED) == SkillTreeScreen.COL_RING_LOCKED and SkillTreeScreen.state_edge("learned", Color.RED) == UiTheme.COL_GOLD,
		"locked and owned rings have their own colours")
	s.free()
	_grey_copy(t)
	var src := FileAccess.get_file_as_string("res://src/game/ui/skill_tree_screen.gd")
	var fn := func(name: String) -> String:
		var a := src.find("func " + name + "(")
		return src.substr(a, src.find("
func ", a + 5) - a)
	t.check(String(fn.call("_draw_buttons")).contains("REMEMBER_RECT") and String(fn.call("_draw_buttons")).contains("BUY_RECT")
		and not String(fn.call("_draw_buttons")).contains("Rect2("), "drift guard (source text): the buttons are drawn at the rects hit() uses")
	t.check(String(fn.call("_draw_top_bar")).contains("BACK_RECT") and String(fn.call("_draw_top_bar")).contains("chip_rect(c)")
		and String(fn.call("_draw_top_bar")).contains("points_rect()"), "drift guard (source text): the back button, chips and points box are drawn at their hit rects")
	t.check(String(fn.call("_draw_mini")).contains("mini_rect(side_rect(side), tier, i)") and String(fn.call("_draw_node")).contains("TreeWheel.node_at(tier, i)"),
		"drift guard (source text): nodes and minis are drawn at the places hit() tests")
	t.check(not String(fn.call("_draw_node")).contains("0.85"), "drift guard (source text): a poor node's icon is full colour")


## A click on RAISE through the Control's gui_input buys, whatever the scale (the screen works in design units; no code depends on k).
static func _click_through_input(t) -> void:
	for k in [2, 3]:
		UiScale.set_test_area(Vector2i(640 * k, 360 * k))
		var s := _screen("ruin", 1, 5)
		s.select(1, 1, 0)
		var before := s._slot.level_of("smite")
		s._ui.gui_input.emit(_click(SkillTreeScreen.BUY_RECT.get_center()))
		t.check(s._slot.level_of("smite") == before + 1, "a click on RAISE through gui_input buys at k%d" % k)
		s.free()
		UiScale.clear_test_area()


## Every power's level-5 twist is shown in full: at most TWIST_LINES lines of the info column, no "...", every word there.
static func _twists_whole(t) -> void:
	var bad := PackedStringArray()
	var seen := 0
	for sp in GodTree.spots():
		var key := String(sp.key)
		if key == "" or PowerBook.twist(key) == "" or not PowerBook.has_levels(key):
			continue
		seen += 1
		var lines := SkillTreeScreen.twist_lines(key)
		var want := "Level %d . %s" % [PowerBook.MAX_LEVEL, PowerBook.twist(key)]
		if lines.size() > SkillTreeScreen.TWIST_LINES or " ".join(lines) != want or " ".join(lines).contains("..."):
			bad.append("%s: %d lines" % [key, lines.size()])
		for l in lines:
			if UiTheme.width(l, SkillTreeScreen.SMALL_PX) > SkillTreeScreen.INFO_W:
				bad.append(key + " line too wide")
	t.check(seen > 20 and bad.is_empty(), "every twist (%d powers) fits %d lines of the info column, in full: %s" % [seen, SkillTreeScreen.TWIST_LINES, bad])
	t.check(SkillTreeScreen.twist_lines("smite").size() >= 1, "smite has a twist")


## Words are separated (always, on every screen): a space is the font's own plus 1 u per 11 u (3 u at 11 u, 6 u at 22 u), and the refusal still wraps to two lines.
static func _word_spacing(t) -> void:
	t.check(UiTheme.width(" ", 11) >= 3.0, "a space is at least 3 u wide at 11 u (%s)" % UiTheme.width(" ", 11))
	t.check(UiTheme.width(" ", 22) >= 6.0, "and at least 6 u at 22 u (%s)" % UiTheme.width(" ", 22))
	t.check(UiTheme.width("a b", 11) > UiTheme.width("ab", 11) + 2.0, "words are apart at 11 u")
	t.check(UiTheme.wrap("Not enough ability points", 96.0, 11).size() == 2, "the refusal still wraps to two lines")


## Every spot of the Death and Decree wheels has its table, and its level-5 line (the twist) wraps to the three lines of the
## level column with nothing cut.
static func _death_decree_twists(t) -> void:
	var cut := PackedStringArray()
	var no_table := PackedStringArray()
	var found := {}
	var mine := ["deathmark", "raise", "pestilence", "gravecall", "guise", "walker", "gatebelow", "pale", "serpent", "gravetide",
		"noleave", "breath", "redefine", "bound", "erase", "disorder", "eminent", "fenced", "cage", "sealed"]
	for type in ["death", "decree"]:
		var s := _screen(type, 5, 0)
		for col in 3:
			for tier in range(1, 6):
				for i in 2:
					var key := s.key_at(col, tier, i)
					if key == "" or not mine.has(key):
						continue
					found[key] = true
					if not PowerBook.has_levels(key):
						no_table.append(key)
						continue
					var line := "Level 5 . " + PowerBook.twist(key)
					var lines := UiTheme.wrap(line, SkillTreeScreen.LEVEL_W - 14.0, SkillTreeScreen.SMALL_PX - 1)
					if lines.size() > 3:
						cut.append(key)
		s.free()
	t.check(found.size() == 20 and no_table.is_empty(), "all twenty spots on the Death and Decree wheels have a levels table (%d found; none: %s)" % [found.size(), no_table])
	t.check(cut.is_empty(), "each level-5 twist line fits the level column's three lines (cut: %s)" % [cut])
