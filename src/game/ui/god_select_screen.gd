class_name GodSelectScreen
extends Node
## The god select (god P1, spec §4 and §12; restyled as "God's Paths", round 2): six grey stone statues, one on each of the ruined temple
## background's own platforms (RING[0] at the back, the rest clockwise), lit when picked and dimmed otherwise, each with its name carved on
## the platform's front, in a courtyard with braziers and drifting leaves; a statue's dark box stands in when its art is missing. A panel
## at the top centre shows the selected type's name, its three verbs, one line of flavour, its two Tier 1 spots ("Not yet chosen" while
## the tree is empty) and its two neighbours. Choose, or Enter, picks it -- once, for the slot being made (spec §4) -- and Esc or Back
## goes back. The screen only reports; Game makes the god.

## "chosen" (`chosen_type` is the type) or "back".
signal action(name: String)

## Where each type's statue stands (its plinth's bottom centre, on the background's platform) and where its name is carved on the
## platform's front, both in `GodTree.RING` order: Ruin at the back, then clockwise.
const FEET := [Vector2(324, 151), Vector2(476, 170), Vector2(521, 253), Vector2(317, 300), Vector2(118, 253), Vector2(161, 170)]
const NAME_AT := [Vector2(324, 158), Vector2(476, 177), Vector2(521, 273), Vector2(317, 321), Vector2(118, 274), Vector2(161, 177)]
## The centre pool, where the selected god's emblem goes.
const EMBLEM_AT := Vector2(320, 206)
## The top panel the selected type's lines are drawn in, and the two buttons.
const INFO_RECT := Rect2(186.0, 2.0, 268.0, 66.0)
const CHOOSE_RECT := Rect2(520.0, 334.0, 112.0, 18.0)
const BACK_RECT := Rect2(8.0, 334.0, 90.0, 18.0)
## A statue's sprite size; its plinth's bottom centre is at (32, 79).
const STATUE_SIZE := Vector2(64.0, 80.0)
## How wide a statue's clickable body column is (64, the sprite's width, would overlap Death's and Dominion's).
const BODY_W := 40.0
## What each type does, in three words, in the top panel.
const VERBS := {
	"ruin": "Destroy · Collapse · Erase",
	"passage": "Open · Move · Close",
	"veil": "Conceal · Obscure · Displace",
	"decree": "Law · Bind · Enforce",
	"death": "Wither · Harvest · Release",
	"dominion": "Control · Command · Bend",
}

## Each god's colour, for its statue's aura.
const GOD_COL := {
	"ruin": Color("e8602a"), "passage": Color("4a90e8"), "veil": Color("3ab8a8"),
	"decree": Color("f0d890"), "death": Color("98d880"), "dominion": Color("a060e0"),
}
## Where the four braziers stand (bottom centre of each).
const BRAZIERS := [Vector2(22, 248), Vector2(618, 248), Vector2(222, 318), Vector2(418, 318)]
const LEAF_COUNT := 8

## The type chosen by confirm(), or "".
var chosen_type := ""
## The ring position (0-5) in the top panel; clicks and Left/Right move it.
var selected := 0
var _ui: Control
var _hover := ""
var _clock := 0.0
var _draws := 0
## One drifting leaf each: x start, y start, fall speed, sway phase, spin speed.
var _leaves: Array[PackedFloat32Array] = []


func setup() -> GodSelectScreen:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for k in LEAF_COUNT:
		_leaves.append(PackedFloat32Array([rng.randf_range(0.0, 640.0), rng.randf_range(0.0, 380.0), rng.randf_range(10.0, 22.0),
			rng.randf_range(0.0, TAU), rng.randf_range(-1.5, 1.5)]))
	return self


func _process(delta: float) -> void:
	advance(delta)
	_redraw()


## Steps the clock that drives the animated bits (braziers, leaves, and the later power effects).
func advance(delta: float) -> void:
	_clock += delta


## A statue's brightness: 1.0 selected, 0.86 under the mouse, 0.72 otherwise.
func lit(i: int) -> float:
	if i == selected:
		return 1.0
	return 0.86 if _hover == "ring:%d" % i else 0.72


## Where type `i`'s statue's feet stand (0-5): its plinth's bottom centre.
static func feet(i: int) -> Vector2:
	return FEET[i]


## Where type `i`'s sprite is drawn: its top left is `feet(i)` - (32, 79), so the plinth's bottom centre lands on `feet(i)`.
static func statue_rect(i: int) -> Rect2:
	return Rect2(feet(i) - Vector2(32.0, 79.0), STATUE_SIZE)


## Type `i`'s hit box (0-5): the statue's body column, BODY_W wide, down to the carved name.
static func ring_rect(i: int) -> Rect2:
	var top := feet(i).y - 79.0
	return Rect2(feet(i).x - BODY_W * 0.5, top, BODY_W, NAME_AT[i].y + 6.0 - top)


## A type's three verbs for the top panel, or "" for a type that is not on the ring.
static func verbs(type: String) -> String:
	return String(VERBS.get(type, ""))


## What the top panel says of a type: its title, its flavour line, its Tier 1 spots' power names (or "Not yet chosen"), and its
## neighbours. Empty for a type that is not on the ring.
func type_lines(type: String) -> PackedStringArray:
	if not GodTree.RING.has(type):
		return PackedStringArray()
	var names := PackedStringArray()
	for i in GodTree.PER_TIER:
		var key := GodTree.spot(type, 1, i)
		names.append(String(PowerBook.get_power(key).name) if key != "" else GodTree.NOT_CHOSEN)
	var beside := PackedStringArray()
	for n in GodTree.neighbours(type):
		beside.append(PowerBook.authority_title(n))
	return PackedStringArray([PowerBook.authority_title(type), String(GodTree.FLAVOUR.get(type, "")),
		"Tier 1: %s" % ", ".join(names), "Neighbours: %s" % ", ".join(beside)])


## Puts the top panel on ring position `i` (0-5); it does not choose.
func select(i: int) -> void:
	selected = clampi(i, 0, GodTree.RING.size() - 1)
	_redraw()


## Chooses the selected type: `chosen_type` is set and "chosen" is emitted.
func confirm() -> void:
	chosen_type = GodTree.RING[selected]
	UiSound.play(&"ui_manifest")
	action.emit("chosen")


## What is under a point: "ring:<i>", "choose:0", "back:0" or "".
func hit(point: Vector2) -> String:
	for i in GodTree.RING.size():
		if ring_rect(i).has_point(point):
			return "ring:%d" % i
	if CHOOSE_RECT.has_point(point):
		return "choose:0"
	if BACK_RECT.has_point(point):
		return "back:0"
	return ""


## A left click at a screen point.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	var parts := h.split(":")
	match parts[0]:
		"ring":
			UiSound.play(&"ui_click")
			select(int(parts[1]))
		"choose":
			confirm()
		"back":
			UiSound.play(&"ui_click")
			action.emit("back")


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("back")
		KEY_LEFT:
			UiSound.play(&"ui_hover")
			select((selected + GodTree.RING.size() - 1) % GodTree.RING.size())
		KEY_RIGHT:
			UiSound.play(&"ui_hover")
			select((selected + 1) % GodTree.RING.size())
		KEY_ENTER, KEY_KP_ENTER:
			confirm()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	var bg := GodSelectArt.texture("background")
	if bg != null:
		_ui.draw_texture_rect(bg, Rect2(0, 0, 640, 360), false)
	else:
		_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	_draw_braziers()
	var order := [0, 1, 2, 3, 4, 5]
	order.sort_custom(func(a: int, b: int) -> bool: return FEET[a].y < FEET[b].y)
	for i in order:
		_draw_statue(i)
		_draw_name(i)
	_draw_leaves()
	var back_col := Color(0, 0, 0, 0.55)
	_ui.draw_rect(Rect2(0, 0, 182, 59), back_col)
	UiTheme.text(_ui, Vector2(10, 20), "GOD'S PATHS", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(10, 32), "CHOOSE YOUR AUTHORITY", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(10, 45), "A god's type is chosen once,", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(10, 56), "for this slot.", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_ui.draw_rect(Rect2(452, 0, 188, 32), back_col)
	var keys := ["Left / Right look round the ring", "Enter chooses · Esc goes back"]
	var kx := minf(466.0, 634.0 - maxf(UiTheme.width(keys[0], UiTheme.SIZE_SMALL), UiTheme.width(keys[1], UiTheme.SIZE_SMALL)))
	UiTheme.text(_ui, Vector2(kx, 14), keys[0], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(kx, 26), keys[1], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_draw_info()
	var choose_on := _hover == "choose:0"
	_ui.draw_rect(CHOOSE_RECT, Color(0.1, 0.09, 0.07, 0.9) if choose_on else Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, CHOOSE_RECT, choose_on)
	var go := "Enter Path ›"
	UiTheme.text(_ui, Vector2(roundf(CHOOSE_RECT.get_center().x - UiTheme.width(go) * 0.5), CHOOSE_RECT.position.y + 14.0), go,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back:0")
	var back := "‹ Back"
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width(back) * 0.5), BACK_RECT.position.y + 14.0), back,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back:0" else UiTheme.COL_TEXT)
	_draws += 1


## Type `i`'s name carved on its platform's front: light stone letters with a 1 px dark outline, gold when selected or hovered.
func _draw_name(i: int) -> void:
	var title := PowerBook.authority_title(GodTree.RING[i])
	var size := UiTheme.SIZE_SMALL
	if UiTheme.width(title, size) > 60.0:
		size -= 1
	var on := i == selected
	var at := Vector2(roundf(NAME_AT[i].x - UiTheme.width(title, size) * 0.5), NAME_AT[i].y + 4.0)
	var col := UiTheme.COL_GOLD if on or _hover == "ring:%d" % i else Color("b2b8c8")
	var dark := Color(0.03, 0.03, 0.06, 0.95)
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_ui.draw_string(UiTheme.font(), at + d, title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, dark)
	_ui.draw_string(UiTheme.font(), at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## The height of the top panel's text for `flavour_rows` rows of flavour and `tail_rows` small rows (name, verbs, flavour, then the tail).
static func info_height(flavour_rows: int, tail_rows: int) -> float:
	return 16.0 + 11.0 + 16.0 + (flavour_rows - 1) * UiTheme.LINE_BODY + tail_rows * 10.0 + 3.0


## Type `i`'s statue, its plinth on `feet(i)`, over a small contact shadow, dimmed unless picked, with a soft aura in the god's colour;
## today's box if no art.
func _draw_statue(i: int) -> void:
	var tex := GodSelectArt.texture("statue_" + String(GodTree.RING[i]))
	if tex == null:
		_ui.draw_rect(ring_rect(i), Color(0.04, 0.04, 0.06, 0.4))
		return
	var v := lit(i)
	var top_left := statue_rect(i).position
	_ui.draw_set_transform(feet(i) + Vector2(0.0, -1.0), 0.0, Vector2(1.0, 0.22))
	_ui.draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.35))
	var col: Color = GOD_COL.get(GodTree.RING[i], Color.WHITE)
	_ui.draw_set_transform(top_left + Vector2(32.0, 36.0), 0.0, Vector2(1.0, 1.3))
	for r in [30.0, 22.0, 15.0]:
		_ui.draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.07 * v * v))
	_ui.draw_set_transform(Vector2.ZERO)
	_ui.draw_texture(tex, top_left, Color(v, v, v, 1.0))


func _draw_braziers() -> void:
	var fr := GodSelectArt.frames("brazier_")
	if fr.is_empty():
		return
	for k in BRAZIERS.size():
		var tex: Texture2D = fr[int(_clock * 8.0 + k * 3) % fr.size()]
		_ui.draw_texture(tex, BRAZIERS[k] - Vector2(tex.get_width() * 0.5, tex.get_height() - 1.0))


## Red leaves drifting down and wrapping; each position is a function of the clock.
func _draw_leaves() -> void:
	var leaf := GodSelectArt.texture("leaf")
	if leaf == null:
		return
	for l in _leaves:
		var y := fposmod(l[1] + _clock * l[2], 380.0) - 10.0
		var x: float = l[0] + sin(_clock * 0.8 + l[3]) * 14.0
		_ui.draw_set_transform(Vector2(x, y), _clock * l[4] + l[3])
		_ui.draw_texture(leaf, -leaf.get_size() * 0.5)
	_ui.draw_set_transform(Vector2.ZERO)


## The selected type's lines in the top panel: name, verbs in the god's colour, flavour, then Tier 1 and Neighbours each on its own line.
func _draw_info() -> void:
	var type: String = GodTree.RING[selected]
	var lines := type_lines(type)
	var w := INFO_RECT.size.x - 16.0
	_ui.draw_rect(INFO_RECT, Color(0.03, 0.03, 0.06, 0.88))
	UiTheme.frame(_ui, INFO_RECT, true)
	var x := INFO_RECT.get_center().x
	var y := INFO_RECT.position.y + 16.0
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(lines[0], UiTheme.SIZE_BIG) * 0.5), y), lines[0], UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	y += 11.0
	var vcol: Color = Color(GOD_COL.get(type, Color.WHITE)).lightened(0.25)
	var verb := verbs(type)
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(verb, UiTheme.SIZE_SMALL) * 0.5), y), verb, UiTheme.SIZE_SMALL, vcol)
	y += 16.0
	for row in UiTheme.wrap(lines[1], w, UiTheme.SIZE_BODY):
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row) * 0.5), y), row, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY
	y -= UiTheme.LINE_BODY - 10.0
	for k in [2, 3]:
		var row := UiTheme.fit(lines[k], w, UiTheme.SIZE_SMALL)
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row, UiTheme.SIZE_SMALL) * 0.5), y), row, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		y += 10.0
