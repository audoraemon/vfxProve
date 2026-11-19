extends RefCounted
## Mission and the Might gauge: each act's Rules gets the pool and the seal from the def (or the bots' tier), never in a Remembrance,
## the night's cast keys are the union over its acts, and a board mission has no pool.
## A real Mission cannot be started in the headless suite, so the hooks are driven on a bare Mission with bare Rules.


static func run(t) -> void:
	_board(t)
	_gauge_def(t)
	_tier(t)
	_remembrance(t)
	_acts(t)
	_hud_bar(t)
	_keys(t)
	_covered(t)
	_mouse(t)


## A def that is a gauge night of `size` and `seconds`, sealed on `sealed`.
static func _def(size: int, seconds: float, sealed := "") -> MissionDef:
	var d := MissionDef.new()
	d.might_capacity = size
	d.might_refill = seconds
	d.sealed = sealed
	return d


## A Mission with bare Rules armed from `d`; the caller frees both.
static func _armed(d: MissionDef, tier := 0, memory := "") -> Mission:
	var m := Mission.new()
	m.might_tier = tier
	m.remembrance = memory
	m._rules = Rules.new()
	m._arm_might(d)
	return m


static func _drop(m: Mission) -> void:
	m._rules.free()
	m._rules = null
	m.free()


static func _board(t) -> void:
	var m := _armed(TierBook.board("warning", null))
	t.check(m._rules.might == null and m._rules.sealed == "", "a board mission has no pool and no seal")
	t.check(m.cast_keys().is_empty(), "and has cast nothing yet")
	_drop(m)


static func _gauge_def(t) -> void:
	var m := _armed(_def(8, 55.0, "heaven"))
	var p: MightPool = m._rules.might
	t.check(p != null and p.capacity == 8.0 and is_equal_approx(p.refill_seconds, 55.0) and is_equal_approx(p.value, 8.0),
		"a gauge def gives a full pool of 8, refill 55 s")
	t.check(m._rules.sealed == "heaven", "and the seal (%s)" % m._rules.sealed)
	_drop(m)


static func _tier(t) -> void:
	var m := _armed(TierBook.board("warning", null), 1)
	var p: MightPool = m._rules.might
	t.check(p != null and p.capacity == 6.0 and is_equal_approx(p.refill_seconds, 60.0), "might_tier 1 on a board def: a pool of 6 / 60")
	_drop(m)
	m = _armed(_def(8, 55.0), 1)
	t.check(m._rules.might.capacity == 6.0, "the bots' tier wins over the def's own gauge")
	_drop(m)


static func _remembrance(t) -> void:
	var m := _armed(_def(8, 55.0, "heaven"), 0, "wisp")
	t.check(m._rules.might == null and m._rules.sealed == "", "a Remembrance has no pool and no seal, whatever the def says")
	_drop(m)
	m = _armed(_def(8, 55.0), 1, "wisp")
	t.check(m._rules.might == null, "nor with the bots' tier")
	_drop(m)


static func _acts(t) -> void:
	var one := _def(8, 55.0, "heaven")
	var m := _armed(one)
	m._rules.might.pay(5.0)
	m._rules.cast_keys.append("tsunami")
	t.check(m.cast_keys() == PackedStringArray(["tsunami"]), "the act's own cast keys show at once")
	m._carry_cast()
	m._rules.free()
	m._rules = Rules.new()
	m._arm_might(_def(8, 55.0, "heaven"))
	t.check(is_equal_approx(m._rules.might.value, 8.0), "the next act's pool starts full")
	m._rules.cast_keys.append("cinder")
	m._rules.cast_keys.append("tsunami")
	t.check(m.cast_keys() == PackedStringArray(["tsunami", "cinder"]), "the night's cast keys hold both acts', once each (%s)" % [m.cast_keys()])
	_drop(m)


## The ruin page's ten keys between a dominion key and three passage keys: pages are dominion (1), ruin (10, the bar's own), passage (3).
const KEYS := ["whisper", "smite", "ember", "tornado", "scatter", "solaris", "dragon", "tsunami", "cinder", "tempest", "shatter",
	"skylift", "windfall", "houndgate"]
const VIEW := Vector2(640, 360)


## A bare night: a Mission holding Rules, Targeting and a Hud (the bar made when `pooled`), none of them in a tree.
static func _night(keys: PackedStringArray, pooled := true) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), Node2D.new(), 5)
	var rules := Rules.new().setup(keys, null, env, field, crowd, town, TierBook.board("warning", null))
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	if pooled:
		rules.might = MightPool.make(16)
	var aim := Targeting.new().setup(rules, crowd)
	var hud := Hud.new()
	hud.bar_type = "ruin"
	hud.setup(rules, crowd, town, aim)
	var m := Mission.new()
	m._rules = rules
	m._aim = aim
	m._hud = hud
	return {"m": m, "rules": rules, "aim": aim, "hud": hud}


static func _end(n: Dictionary) -> void:
	(n.m as Mission).free()
	(n.hud as Hud).free()
	(n.aim as Targeting).free()
	(n.rules as Rules).free()


static func _key(code: Key, shift := false, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	e.echo = echo
	e.shift_pressed = shift
	return e


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _hud_bar(t) -> void:
	var n := _night(PackedStringArray(KEYS))
	var hud: Hud = n.hud
	var rules: Rules = n.rules
	t.check(hud.bar != null and hud.bar.pages().size() == 3, "a gauge night has the bar in its HUD, three pages")
	t.check(hud.slots_rect() == hud.bar.rect(VIEW), "slots_rect() is the bar's rect")
	var shut_top := hud.slot_top()
	hud.bar.toggle()
	t.check(shut_top > hud.slot_top(), "slot_top() is lower with the bar hidden than open (%.0f > %.0f)" % [shut_top, hud.slot_top()])
	t.check(hud.slots_rect() == hud.bar.rect(VIEW), "and slots_rect() follows it open")
	t.check(hud.slot_at(hud.bar.tile_rect(0, VIEW).get_center()) == hud.bar.slot_for_digit(0), "slot_at() gives a tile's loadout slot")
	t.check(hud.slot_at(Vector2(1.0, 1.0)) == -1 and hud.bar_hit(Vector2(1.0, 1.0)) == "", "and -1 off the bar")
	rules.cast_refused.emit(1, "might")
	t.check("NOT ENOUGH MIGHT" in hud.banners(), "a cast refused for Might raises NOT ENOUGH MIGHT (%s)" % [hud.banners()])
	rules.cast_refused.emit(1, "sealed")
	t.check("SEALED BY THE LANTERN" in hud.banners(), "a sealed one raises SEALED BY THE LANTERN")
	var before := hud._signature()
	t.check(hud._signature() == before, "with nothing changed the signature does not")
	hud.bar.turn(1)
	t.check(hud._signature() != before, "turning the page changes the HUD's signature")
	before = hud._signature()
	rules.might.pay(3.0)
	t.check(hud._signature() != before, "paying Might changes it")
	before = hud._signature()
	rules.might.advance(1.0)
	t.check(hud._signature() != before, "and a second of refill (the part-filled segment) does")
	var steps := 0
	var last := hud._signature()
	for i in 60:
		rules.might.advance(1.0 / 60.0)
		var now := hud._signature()
		steps += 1 if now != last else 0
		last = now
	t.check(steps > 0 and steps < 30, "over one second the signature changes %d times in 60 frames: not every frame, not never" % steps)
	_end(n)
	var board := _night(PackedStringArray(KEYS.slice(0, 4)), false)
	var bh: Hud = board.hud
	var card := bh.slot_w()
	var total := 4.0 * card + 3.0 * Hud.SLOT_GAP
	var want := Rect2(Vector2(roundf((VIEW.x - total) * 0.5), Hud.slot_top_in(VIEW)), Vector2(card, Hud.SLOT_SIZE))
	t.check(bh.bar == null and bh.bar_hit(Vector2(320, 340)) == "" and bh.slot_rect(0) == want, "a board night: no bar, the slot row as before")
	t.check(is_equal_approx(bh.slot_top(), Hud.slot_top_in(VIEW)), "and slot_top() is the row's")
	_end(board)


static func _keys(t) -> void:
	var n := _night(PackedStringArray(KEYS))
	var m: Mission = n.m
	var bar: AbilityBar = n.hud.bar
	var aim: Targeting = n.aim
	m._unhandled_input(_key(KEY_CTRL))
	t.check(bar.open, "Ctrl opens the bar")
	m._unhandled_input(_key(KEY_CTRL, false, true))
	t.check(bar.open, "a Ctrl echo does not toggle")
	m._unhandled_input(_key(KEY_CTRL, true))
	t.check(bar.open, "Shift+Ctrl does not toggle")
	m._unhandled_input(_key(KEY_CTRL))
	t.check(not bar.open, "Ctrl again hides it")
	t.check(Mission.toggles_bar(_key(KEY_CTRL)) and not Mission.toggles_bar(_key(KEY_Z)), "toggles_bar() reads a bare Ctrl press")
	m._unhandled_input(_key(KEY_0))
	t.check(aim.slot == 10, "KEY_0 arms the tenth tile of the ruin page, slot 10 (armed %d)" % aim.slot)
	m._unhandled_input(_key(KEY_1))
	t.check(aim.slot == 1, "KEY_1 arms the page's first (slot %d), not loadout slot 0" % aim.slot)
	m._unhandled_input(_key(KEY_X))
	t.check(bar.page == 2 and aim.slot == 1, "X turns to the next page and keeps the armed slot (page %d, armed %d)" % [bar.page, aim.slot])
	m._unhandled_input(_key(KEY_2))
	t.check(aim.slot == 12, "a number key then arms from the new page (slot %d)" % aim.slot)
	aim.unfocus()
	m._unhandled_input(_key(KEY_7))
	t.check(aim.slot == -1, "KEY_7 on a page of three arms nothing")
	m._unhandled_input(_key(KEY_Z))
	t.check(bar.page == 1, "Z turns back")
	_end(n)


static func _covered(t) -> void:
	var n := _night(PackedStringArray(KEYS))
	var m: Mission = n.m
	var bar: AbilityBar = n.hud.bar
	var aim: Targeting = n.aim
	m._legend = LegendPanel.new().setup([] as Array[MapTag])
	m._legend.page = 1
	for code in [KEY_CTRL, KEY_Z, KEY_X, KEY_7]:
		m._unhandled_input(_key(code))
	t.check(not bar.open and bar.page == 1 and aim.slot == -1, "the legend open: Ctrl, Z, X and 7 change nothing")
	m._legend.free()
	m._legend = null
	m._intro_left = 5.0
	for code in [KEY_CTRL, KEY_Z, KEY_X, KEY_7]:
		m._unhandled_input(_key(code))
	t.check(not bar.open and bar.page == 1 and aim.slot == -1, "the intro: the same")
	m._intro_left = 0.0
	m.ui_hidden = true
	m._unhandled_input(_key(KEY_CTRL))
	t.check(not m.ui_hidden, "with the interface hidden a Ctrl press brings it back")
	m.ui_hidden = true
	m._unhandled_input(_key(KEY_X))
	t.check(not m.ui_hidden and bar.page == 2, "and so does X, which then turns")
	m.ui_hidden = true
	m._unhandled_input(_key(KEY_9))
	t.check(not m.ui_hidden, "and 9")
	_end(n)
	var none := _night(PackedStringArray())
	var nm: Mission = none.m
	var nh: Hud = none.hud
	for code in [KEY_CTRL, KEY_Z, KEY_X, KEY_1, KEY_7, KEY_0, KEY_CTRL]:
		nm._unhandled_input(_key(code))
	nm._unhandled_input(_click(nh.bar.rect(VIEW).get_center()))
	t.check(nh.bar.pages().is_empty() and not nh.bar.open and (none.aim as Targeting).slot == -1, "an empty night takes every key and a click, the bar stays shut")
	t.check(nh.slots_rect().has_area() and nh._signature() != "", "and its HUD has a strip and a signature")
	_end(none)


static func _mouse(t) -> void:
	var n := _night(PackedStringArray(KEYS))
	var m: Mission = n.m
	var hud: Hud = n.hud
	var bar: AbilityBar = hud.bar
	var aim: Targeting = n.aim
	m._unhandled_input(_click(bar.rect(VIEW).get_center()))
	t.check(bar.open and aim.slot == -1, "a click on the hidden strip opens the bar and arms nothing")
	m._unhandled_input(_click(bar.tile_rect(2, VIEW).get_center()))
	t.check(aim.slot == bar.slot_for_digit(2), "a click on a tile arms it (slot %d)" % aim.slot)
	var armed := aim.slot
	m._unhandled_input(_click(bar.tab_rect(2, VIEW).get_center()))
	t.check(bar.page == 2 and aim.slot == armed, "a click on a tab turns to it, the armed slot kept")
	m._unhandled_input(_click(bar.tab_rect(0, VIEW).get_center()))
	t.check(bar.page == 0, "and on another")
	# R5: a click inside the open bar that is no tile and no tab (the gauge, the tabs line, the name line) is the bar's and casts nothing.
	var gap := Vector2.INF
	var rect := bar.rect(VIEW)
	for y in range(int(rect.position.y) + 1, int(rect.end.y), 2):
		for x in range(int(rect.position.x) + 1, int(rect.end.x), 2):
			var at := Vector2(x, y)
			if gap == Vector2.INF and bar.hit(at, VIEW) == "":
				gap = at
	t.check(gap != Vector2.INF and bar.open, "the open bar has a point that is neither a tile nor a tab")
	aim.pick(bar.slot_for_digit(0))
	var held := aim.slot
	t.check(held >= 0 and m.bar_input(_click(gap)) and aim.slot == held, "a click on the open bar's empty part is swallowed and keeps the armed ability (slot %d)" % aim.slot)
	t.check(not m.bar_input(_click(bar.tile_rect(0, VIEW).get_center())), "a tile click is still left to the slot branch")
	t.check(not m.bar_input(_click(Vector2(rect.position.x - 3.0, rect.position.y - 3.0))), "and a click outside the bar is not the bar's")
	WorldView.test_mouse = bar.tile_rect(0, VIEW).get_center()
	var first := hud._signature()
	WorldView.test_mouse = Vector2(5.0, 5.0)
	var off := hud._signature()
	WorldView.test_mouse = Vector2.INF
	t.check(first != off, "hovering a tile changes the signature")
	_end(n)
