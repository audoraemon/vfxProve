extends RefCounted
## v0.11.1 Task 3 the legend of marks (spec §4): the rows of "This night", the two pages, and the keys around the panel (review
## focus 1 and 2): Esc closes it and does not open the pause menu, H turns its pages, nothing but the legend answers while it is
## open, the ending refuses it, and a new mission or act starts with it shut.

const RED := Color("c8342a")
const GOLD := Color("d8b23a")


static func run(t) -> void:
	_rows(t)
	_pages(t)
	_arrow(t)
	_keys_while_open(t)
	_closes_on_start(t)


static func _tags(list: Array) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for x in list:
		out.append(x)
	return out


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _rows(t) -> void:
	var tags := _tags([MapTag.person(Vector2.ZERO, RED, "WATCHMAN"), MapTag.person(Vector2.ONE, RED, "PATROL"),
		MapTag.person(Vector2.ONE, RED, "WATCHMAN"), MapTag.pip(Vector2.ONE, GOLD)])
	var rows := LegendPanel.night_rows(tags)
	t.check(rows.size() == 2 and rows[0][0] == RED and rows[0][1] == "WATCHMAN, PATROL" and rows[1][0] == GOLD
		and rows[1][1] == "(unnamed)", "one row a colour in order of first appearance, labels deduped (%s)" % [rows])
	t.check(LegendPanel.night_rows(_tags([])).is_empty(), "no tags, no rows (the panel says nothing is marked yet)")
	var many := _tags([])
	for w in ["A", "B", "C", "D"]:
		many.append(MapTag.person(Vector2.ZERO, GOLD, w))
	t.check(LegendPanel.night_rows(many)[0][1] == "A, B, C", "up to three labels a row")
	t.check(LegendPanel.MARKS.size() == 12 and LegendPanel.OVERHEAD.size() == 17, "every mark of the spec's two tables")


static func _pages(t) -> void:
	var p := LegendPanel.new().setup(_tags([]))
	var shut := [0]
	p.closed.connect(func() -> void: shut[0] += 1)
	t.check(p.page == 0, "a new panel is closed")
	p.open_next()
	t.check(p.page == 1, "H once: page 1")
	p.open_next()
	t.check(p.page == 2, "H again: page 2")
	t.check(shut[0] == 0, "not closed yet")
	p.open_next()
	t.check(p.page == 0 and shut[0] == 1, "H a third time closes it, once")
	p.close()
	t.check(shut[0] == 1, "closing a closed panel says nothing")
	p.free()


static func _arrow(t) -> void:
	var tip := Vector2(10, 20)
	var shape := Hud.arrow_shape(tip, Vector2.RIGHT)
	t.check(shape.size() == 3 and shape[0] == tip and shape[1].x < tip.x and shape[2].x < tip.x
		and is_equal_approx(shape[1].y + shape[2].y, 2.0 * tip.y), "the arrow the HUD and the legend share points along its direction")


## A mission with just what the legend touches (the suite runs outside a scene tree, where a real Mission's _ready() never
## comes): a battlefield's HUD layer, rules, aim and HUD. The real keys and a real start() are FLOW's.
static func _mission() -> Mission:
	var m := Mission.new()
	m._bf = Battlefield.new()
	m._bf.hud_layer = CanvasLayer.new()
	m._rules = Rules.new()
	m._aim = Targeting.new()
	m._hud = Hud.new()
	return m


static func _drop(m: Mission) -> void:
	if m.legend_open():
		m._legend.close()
	m._bf.hud_layer.free()
	m._bf.free()
	m._rules.free()
	m._aim.free()
	m._hud.free()
	m.free()


static func _keys_while_open(t) -> void:
	var m := _mission()
	var pauses := [0]
	m.pause_pressed.connect(func() -> void: pauses[0] += 1)
	t.check(Mission.toggles_legend(_key(KEY_H)) and not Mission.toggles_legend(_key(KEY_R)), "H is the legend's key, only H")
	var echo := _key(KEY_H)
	echo.echo = true
	t.check(not Mission.toggles_legend(echo), "a held H does not toggle")
	t.check(not m.legend_open() and m.process_mode == Node.PROCESS_MODE_INHERIT, "closed: the night runs")
	m._intro_left = 2.0
	m._unhandled_input(_key(KEY_H))
	t.check(m.legend_open() and m.in_intro() and m.process_mode == Node.PROCESS_MODE_DISABLED and m._legend.page == 1,
		"H opens page 1 over the intro and the night waits")
	var rules := m.rules()
	m._unhandled_input(_key(KEY_R))
	m._unhandled_input(_key(KEY_ESCAPE))
	t.check(m.rules() == rules and m.legend_open() and pauses[0] == 0, "R and Esc fed to the mission do nothing while it is open")
	m._unhandled_input(_key(KEY_H))
	t.check(m._legend.page == 2, "H (to the mission) turns the page, never stacks a second panel")
	m._legend._unhandled_input(_key(KEY_ESCAPE))
	t.check(not m.legend_open() and m.process_mode == Node.PROCESS_MODE_INHERIT and pauses[0] == 0,
		"Esc to the panel closes it, lets the night go and opens no pause menu")
	m._unhandled_input(_key(KEY_H))
	m._legend._unhandled_input(_key(KEY_H))
	m._legend._unhandled_input(_key(KEY_H))
	t.check(not m.legend_open() and m.process_mode == Node.PROCESS_MODE_INHERIT, "page 1, page 2, then H closes it")
	m._ending = true
	m._unhandled_input(_key(KEY_H))
	t.check(not m.legend_open(), "during the ending H does nothing")
	m._ending = false
	_drop(m)


static func _closes_on_start(t) -> void:
	var m := _mission()
	m.open_legend()
	t.check(m.legend_open() and m.process_mode == Node.PROCESS_MODE_DISABLED, "open")
	m._close_legend()  # what start() and next_act() do first
	t.check(not m.legend_open() and m.process_mode == Node.PROCESS_MODE_INHERIT, "closing for a new mission lets the night go")
	_drop(m)
