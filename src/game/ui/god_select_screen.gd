class_name GodSelectScreen
extends Node
## The god select (god P1, spec §4 and §12; restyled as "God's Paths"): the ring of six types on an ellipse with RING[0] at the top and the
## rest clockwise, each a grey stone statue (lit when picked, dimmed otherwise) standing on its nameplate, in a ruined temple with a slowly
## turning swirl in the middle, braziers and drifting leaves; a statue's dark box stands in when its art is missing. The selected type shows
## in the middle its name, one line of flavour, its two Tier 1 spots ("Not yet chosen" while
## the tree is empty) and its two neighbours. Choose, or Enter, picks it -- once, for the slot being made (spec §4) -- and Esc or Back
## goes back. The screen only reports; Game makes the god.

## "chosen" (`chosen_type` is the type) or "back".
signal action(name: String)

## The ring's centre, its half-width and half-height, and one type's box (the statue in its upper part, the nameplate in its lower ~22 px).
const CENTRE := Vector2(320.0, 178.0)
const RADIUS := Vector2(230.0, 100.0)
const BOX := Vector2(152.0, 84.0)
## The middle panel the selected type's lines are drawn in: it sits inside the ring, clear of the six boxes.
const INFO_RECT := Rect2(204.0, 124.0, 232.0, 108.0)
const CHOOSE_RECT := Rect2(260.0, 330.0, 120.0, 22.0)
const BACK_RECT := Rect2(8.0, 332.0, 90.0, 20.0)
## The nameplate's height, at the bottom of a type's box.
const PLATE_H := 22.0
## What each type does, in three words, under its title on the nameplate.
const VERBS := {
	"ruin": "Destroy · Collapse · Erase",
	"passage": "Open · Move · Close",
	"veil": "Conceal · Obscure · Displace",
	"decree": "Law · Bind · Enforce",
	"death": "Wither · Harvest · Release",
	"dominion": "Control · Command · Bend",
}

## How long the light rays take to slide to a newly picked statue, in seconds.
const RAY_TIME := 0.25
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
## The ring position (0-5) in the middle panel; clicks and Left/Right move it.
var selected := 0
## The light rays' current position (centre x, and top y of the shaft); it eases to the selected statue over RAY_TIME. `ray_x` is its x.
var ray_x := statue_anchor(0).x
var ray_y := _statue_top(0)
var _ui: Control
var _hover := ""
var _clock := 0.0
var _ray_from := Vector2(ray_x, ray_y)
var _ray_to := Vector2(ray_x, ray_y)
var _draws := 0
var _ray_t := RAY_TIME
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


## The top y of type `i`'s statue (its plinth stands on its nameplate).
static func _statue_top(i: int) -> float:
	return ring_rect(i).end.y - PLATE_H - 80.0


## Steps the clock and eases the rays (`ray_x`, `ray_y`) towards the selected statue.
func advance(delta: float) -> void:
	_clock += delta
	var target := Vector2(statue_anchor(selected).x, _statue_top(selected))
	if target != _ray_to:
		_ray_from = Vector2(ray_x, ray_y)
		_ray_to = target
		_ray_t = 0.0
	_ray_t = minf(_ray_t + delta, RAY_TIME)
	var at := _ray_from.lerp(_ray_to, smoothstep(0.0, 1.0, _ray_t / RAY_TIME))
	ray_x = at.x
	ray_y = at.y


## A statue's brightness: 1.0 selected, 0.75 under the mouse, 0.45 otherwise.
func lit(i: int) -> float:
	if i == selected:
		return 1.0
	return 0.75 if _hover == "ring:%d" % i else 0.45


## Type `i`'s ring point (0-5): on an ellipse around CENTRE, RING[0] at the top, then clockwise in 60 degree steps. The statue's feet stand here.
static func statue_anchor(i: int) -> Vector2:
	var angle := deg_to_rad(-90.0 + 60.0 * float(i))
	return CENTRE + Vector2(cos(angle) * RADIUS.x, sin(angle) * RADIUS.y)


## Type `i`'s box (0-5): BOX centred on its ring point.
static func ring_rect(i: int) -> Rect2:
	return Rect2((statue_anchor(i) - BOX * 0.5).round(), BOX)


## A type's three verbs for its nameplate, or "" for a type that is not on the ring.
static func verbs(type: String) -> String:
	return String(VERBS.get(type, ""))


## What the middle panel says of a type: its title, its flavour line, its Tier 1 spots' power names (or "Not yet chosen"), and its
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


## Puts the middle panel on ring position `i` (0-5); it does not choose.
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
	var swirl := GodSelectArt.texture("swirl")
	if swirl != null:
		_ui.draw_set_transform(CENTRE, _clock * TAU / 20.0)
		_ui.draw_texture(swirl, -swirl.get_size() * 0.5, Color(1, 1, 1, 0.85))
		_ui.draw_set_transform(Vector2.ZERO)
	for i in GodTree.RING.size():
		_draw_statue(i)
	_draw_rays()
	_draw_braziers()
	_draw_leaves()
	var keys := "Left and Right look round the ring. Enter chooses. Esc goes back."
	var kw := UiTheme.width(keys, UiTheme.SIZE_SMALL)
	var rule := "A god's type is chosen once, for this slot."
	var lw := maxf(UiTheme.width("GOD'S PATHS", UiTheme.SIZE_BIG), UiTheme.width(rule, UiTheme.SIZE_SMALL))
	_ui.draw_rect(Rect2(14, 8, lw + 12, 54), Color(0, 0, 0, 0.55))
	_ui.draw_rect(Rect2(614.0 - kw, 14, kw + 12, 18), Color(0, 0, 0, 0.55))
	UiTheme.text(_ui, Vector2(20, 26), "GOD'S PATHS", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(20, 42), "CHOOSE YOUR AUTHORITY", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(20, 56), rule, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(620.0 - kw, 26.0), keys, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	for i in GodTree.RING.size():
		_draw_plate(i)
	_draw_info()
	var choose_on := _hover == "choose:0"
	_ui.draw_rect(CHOOSE_RECT, Color(0.1, 0.09, 0.07, 0.9) if choose_on else Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, CHOOSE_RECT, choose_on)
	var go := "Enter Path ›"
	UiTheme.text(_ui, Vector2(roundf(CHOOSE_RECT.get_center().x - UiTheme.width(go) * 0.5), CHOOSE_RECT.position.y + 16.0), go,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back:0")
	var back := "‹ Back"
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width(back) * 0.5), BACK_RECT.position.y + 14.0), back,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back:0" else UiTheme.COL_TEXT)
	_draws += 1


## Type `i`'s nameplate at the bottom of its box: its title and its verbs, framed bright when selected or hovered.
func _draw_plate(i: int) -> void:
	var box := ring_rect(i)
	var plate := Rect2(box.position.x, box.end.y - PLATE_H, box.size.x, PLATE_H)
	var on := i == selected
	var hot := _hover == "ring:%d" % i
	_ui.draw_rect(plate, Color(0.1, 0.09, 0.07, 0.9) if on or hot else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, plate, on or hot)
	var title := PowerBook.authority_title(GodTree.RING[i])
	UiTheme.text(_ui, Vector2(roundf(plate.get_center().x - UiTheme.width(title, UiTheme.SIZE_SMALL) * 0.5), plate.position.y + 10.0), title,
		UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if on else UiTheme.COL_TEXT)
	var v := UiTheme.fit(verbs(GodTree.RING[i]), plate.size.x - 6.0, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(roundf(plate.get_center().x - UiTheme.width(v, UiTheme.SIZE_SMALL) * 0.5), plate.position.y + 19.0), v,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## The height of the centre text block for `flavour_rows` rows of flavour and `tail_rows` small rows.
static func info_height(flavour_rows: int, tail_rows: int) -> float:
	return 16.0 + 22.0 + flavour_rows * UiTheme.LINE_BODY + 12.0 + tail_rows * (UiTheme.LINE_SMALL + 2.0)


## A light shaft on the picked statue (native 64 px wide, the bright top of rays.png, plinth to head), sliding with `ray_x`, `ray_y`.
func _draw_rays() -> void:
	var rays := GodSelectArt.texture("rays")
	if rays == null:
		return
	_ui.draw_texture_rect_region(rays, Rect2(roundf(ray_x) - 32.0, roundf(ray_y), 64.0, 80.0), Rect2(0, 0, 64, 80), Color(1.0, 0.95, 0.8, 1.7))


## Type `i`'s statue, its plinth on its nameplate, dimmed unless picked, with a soft aura in the god's colour; today's box if no art.
func _draw_statue(i: int) -> void:
	var tex := GodSelectArt.texture("statue_" + String(GodTree.RING[i]))
	var box := ring_rect(i)
	if tex == null:
		_ui.draw_rect(box, Color(0.04, 0.04, 0.06, 0.4))
		return
	var v := lit(i)
	var top_left := Vector2(statue_anchor(i).x - 32.0, box.end.y - PLATE_H - 80.0)
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


## The selected type's four lines, centred in the middle panel and wrapped to it, on a translucent backing sized to the lines.
func _draw_info() -> void:
	var lines := type_lines(GodTree.RING[selected])
	var w := INFO_RECT.size.x - 16.0
	var flavour := UiTheme.wrap(lines[1], w, UiTheme.SIZE_BODY)
	var tail := PackedStringArray()
	for k in [2, 3]:
		tail.append_array(UiTheme.wrap(lines[k], w, UiTheme.SIZE_SMALL))
	var widest := UiTheme.width(lines[0], UiTheme.SIZE_BIG)
	for row in flavour:
		widest = maxf(widest, UiTheme.width(row))
	for row in tail:
		widest = maxf(widest, UiTheme.width(row, UiTheme.SIZE_SMALL))
	var h := info_height(flavour.size(), tail.size())
	var back_w := minf(widest + 16.0, INFO_RECT.size.x)
	_ui.draw_rect(Rect2(INFO_RECT.get_center().x - back_w * 0.5, INFO_RECT.position.y, back_w, minf(h, INFO_RECT.size.y)), Color(0, 0, 0, 0.55))
	var x := INFO_RECT.get_center().x
	var y := INFO_RECT.position.y + 20.0
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(lines[0], UiTheme.SIZE_BIG) * 0.5), y), lines[0], UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	y += 22.0
	for row in flavour:
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row) * 0.5), y), row, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY
	y += 12.0
	for row in tail:
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row, UiTheme.SIZE_SMALL) * 0.5), y), row, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		y += UiTheme.LINE_SMALL + 2.0
