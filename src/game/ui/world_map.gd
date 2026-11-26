class_name WorldMap
extends Node
## The World Map (World Map + Conquer Progress, Task 5): the page between the Chamber's table and Prepare. Six spots (WorldLayout): the two towns
## the god can go to, and four sealed ones. A town shows its people's percent; a town not yet opened says what opens it. Arrows or the mouse
## choose, Enter or the Descend button goes down, Esc or Back returns. Whether the god can descend is HubStatus's word.

## "descend" (the chosen town is `selected`) or "back".
signal action(name: String)

const SEALED_LINE := "Beyond your reach"
const LOCK_LINE := "Conquer %d%% of %s"
const NO_NIGHT := "No night waits there yet"
const HINT := "Arrows: choose   Enter: Descend   Esc: Back"
const TITLE := "THE KNOWN WORLD"
## The parchment card on the map's calm vellum, the brass Back tab on the frame, and where the hint and a refusal's line are written.
const PLATE := Rect2(240.0, 270.0, 192.0, 62.0)
const BACK := Rect2(18.0, 339.0, 46.0, 15.0)
const HINT_Y := 357.0
const LINE_Y := 262.0
## How long a newly opened town's fog takes to burn away.
const REVEAL_SECONDS := 2.6
## Ink on parchment, the parchment card, the wax of the Descend seal, the wood outside the painting.
const INK := Color(0.20, 0.11, 0.05)
const CARD := Color(0.86, 0.70, 0.44)
const WAX := Color(0.56, 0.11, 0.08)
const WOOD := Color(0.145, 0.07, 0.094)
const GOD_COL := {
	"ruin": Color("e8602a"), "passage": Color("4a90e8"), "veil": Color("3ab8a8"),
	"decree": Color("f0d890"), "death": Color("98d880"), "dominion": Color("a060e0"),
}

## Off in FLOW, --capture and headless runs: the map is drawn at rest (no drift, no flicker, no reveal).
static var moving := true
## The towns each god slot's map has already shown open, this session: a town that opens later burns its fog away once.
static var _known := {}
static var _blob: Texture2D
static var _flat: Texture2D

var selected := ""
## A one-off message shown above the info plate ("" for none).
var line := ""
var status: HubStatus
var _slot: GodSlot
var _ui: Control
var _fx: Control
var _glow: Control
var _top: Control
var _dev := false
var _t := 0.0
## Town id -> seconds since its fog began to burn away.
var _reveal := {}
var _map_tex: Texture2D
var _map_px := Vector2i.ZERO
var _sparks := PackedVector2Array()


func setup(slot: GodSlot, p_dev := false) -> WorldMap:
	_slot = slot
	_dev = p_dev
	status = HubStatus.new(slot)
	# The town last played, when it is open and a night is drawn there (a Hunt due, or a tier it hosts nothing of, would only buzz).
	selected = Conquest.HOME
	if WorldLayout.is_town(slot.last_town) and Conquest.is_open(slot, slot.last_town) and GodNight.draw(slot, slot.last_town) != "":
		selected = slot.last_town
	var args := OS.get_cmdline_user_args()
	if "--flow-test" in args or "--capture" in args or DisplayServer.get_name() == "headless":
		moving = false
	_note_opened()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ui.draw.connect(_draw_ui)
	# As the Chamber: the blocker takes the mouse and hands it on in frame units; the 640x360 child ignores it.
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_ui.get_parent() as Control).gui_input.connect(_on_blocker_input)
	# Over the painting: the weather of the map (clipped to the vellum), the lights (added), then the writing.
	_fx = _layer(_draw_fx)
	_fx.position = WorldLayout.LAND.position
	_fx.size = WorldLayout.LAND.size
	_fx.clip_contents = true
	_glow = _layer(_draw_glow)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	_top = _layer(_draw_top)
	_top.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(moving)
	return self


func _layer(draw_fn: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = Vector2(640.0, 360.0)
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	c.draw.connect(draw_fn)
	_ui.add_child(c)
	return c


## Which towns this slot's map has shown open: the first map of a session takes today's as known; a town opened since burns its fog away.
func _note_opened() -> void:
	var now := PackedStringArray()
	for id in WorldLayout.ids():
		if WorldLayout.is_town(id) and Conquest.is_open(_slot, id):
			now.append(id)
	if _known.has(_slot.index) and moving:
		for id in now:
			if not (_known[_slot.index] as PackedStringArray).has(id):
				_reveal[id] = 0.0
	_known[_slot.index] = now


func _process(delta: float) -> void:
	_t += delta
	for id: String in _reveal.keys():
		_reveal[id] += delta
		if _reveal[id] >= REVEAL_SECONDS:
			_reveal.erase(id)
	_redraw()


## "sealed", "locked", "dim" (open, but no night is drawn there; a conquered town too), "conquered" or "open".
func spot_state(id: String) -> String:
	if not WorldLayout.is_town(id):
		return "sealed"
	if not Conquest.is_open(_slot, id):
		return "locked"
	if GodNight.draw(_slot, id) == "":
		return "dim"  # before "conquered" (spec 4.6): a conquered town with no night to go to is dim too
	if Conquest.conquered(_slot, id):
		return "conquered"
	return "open"


func selectable(id: String) -> bool:
	return spot_state(id) in ["open", "dim", "conquered"]


func select(id: String) -> bool:
	if not selectable(id):
		return false
	selected = id
	line = ""  # a refusal's words belong to the spot it was said of
	_redraw()
	return true


## Moves the selection to the selectable spot lying most nearly in `dir` (a positive dot with it; a tie goes to the nearer); nothing when none.
func move(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var from: Vector2 = WorldLayout.spot(selected).get("place", Vector2.ZERO)
	var best := ""
	var best_dot := 0.0
	var best_dist := 0.0
	for id in WorldLayout.ids():
		if id == selected or not selectable(id):
			continue
		var v: Vector2 = (WorldLayout.spot(id).place as Vector2) - from
		var dot := v.normalized().dot(dir.normalized())
		if dot <= 0.0:
			continue
		var dist := v.length()
		if dot > best_dot + 0.0001 or (absf(dot - best_dot) <= 0.0001 and dist < best_dist):
			best = id
			best_dot = dot
			best_dist = dist
	if best != "":
		UiSound.play(&"ui_hover")
		select(best)


## Enter or the Descend button: refused when the god has nothing to draft or no night waits in the town; else emits "descend".
func press_descend() -> void:
	if not status.can_descend():
		UiSound.play(&"ui_buzz")
		line = HubStatus.BLOCKED
		_redraw()
		return
	if GodNight.draw(_slot, selected) == "":
		UiSound.play(&"ui_buzz")
		line = NO_NIGHT
		_redraw()
		return
	UiSound.play(&"ui_click")
	action.emit("descend")


## The Back tab, on the frame's bottom left.
func back_rect() -> Rect2:
	return BACK


## The Descend seal, on the info card.
func descend_rect() -> Rect2:
	return Rect2(PLATE.end.x - 68.0, PLATE.position.y + 22.0, 60.0, 20.0)


## What the plate says of a spot: an open town its name, percent and believers (and "Conquered"); a locked one its name and what opens it; a
## sealed one its name and that it is beyond reach.
func info_lines(id: String) -> PackedStringArray:
	var out := PackedStringArray([WorldLayout.name_of(id)])
	match spot_state(id):
		"sealed":
			out.append(SEALED_LINE)
		"locked":
			out.append(LOCK_LINE % [Conquest.UNLOCK_PERCENT, Conquest.town_name(Conquest.opener_of(id))])
		_:
			out.append("%d%%" % Conquest.percent_of(_slot, id))
			out.append("%d / %d believers" % [Conquest.count_of(_slot, id), Conquest.population(id)])
			if Conquest.conquered(_slot, id):
				out.append("Conquered")
	return out


## A left click at a frame point.
func click(point: Vector2) -> void:
	if back_rect().has_point(point):
		UiSound.play(&"ui_click")
		action.emit("back")
		return
	if descend_rect().has_point(point):
		press_descend()
		return
	var id := WorldLayout.at(point)
	if id == "":
		return
	if id == selected:
		press_descend()
	elif selectable(id):
		UiSound.play(&"ui_hover")
		select(id)
	else:
		UiSound.play(&"ui_buzz")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_LEFT: move(Vector2.LEFT)
		KEY_RIGHT: move(Vector2.RIGHT)
		KEY_UP: move(Vector2.UP)
		KEY_DOWN: move(Vector2.DOWN)
		KEY_ENTER, KEY_KP_ENTER: press_descend()
		KEY_ESCAPE: action.emit("back")


func _on_blocker_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var e := event.duplicate() as InputEventMouse
	e.position = (event.position - _ui.position) / maxf(_ui.scale.x, 0.0001)
	_on_gui_input(e)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _redraw() -> void:
	for c: Control in [_ui, _fx, _glow, _top]:
		if c != null:
			c.queue_redraw()


# --- drawing -------------------------------------------------------------------------------------------------------------------------------

## The god's colour (gold for a type without one).
func god_color() -> Color:
	return GOD_COL.get(_slot.type, UiTheme.COL_GOLD)


## How much of a spot's fog is left: 1 for a sealed spot, less for a locked town, 0 for an open one; a newly opened town's burns away.
func fog_of(id: String) -> float:
	match spot_state(id):
		"sealed": return 1.0
		"locked": return 0.7
	if _reveal.has(id):
		return 0.7 * (1.0 - smoothstep(0.0, 1.0, float(_reveal[id]) / REVEAL_SECONDS))
	return 0.0


## A round stain texture: `flat` keeps its strength to past half its radius (fog); the other falls away from the middle (light).
static func _disc(flat: bool) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.55 if flat else 0.5, Color(1, 1, 1, 0.82 if flat else 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


static func _soft() -> Texture2D:
	if _blob == null:
		_blob = _disc(false)
	return _blob


## A flat-topped stain (fog, the night on a sealed land).
static func _wash(on: CanvasItem, c: Vector2, size: Vector2, col: Color) -> void:
	if _flat == null:
		_flat = _disc(true)
	on.draw_texture_rect(_flat, Rect2(c - size * 0.5, size), false, col)


## A soft round stain of `col`, `size` across, about `c`.
static func _stain(on: CanvasItem, c: Vector2, size: Vector2, col: Color) -> void:
	on.draw_texture_rect(_soft(), Rect2(c - size * 0.5, size), false, col)


## The painting at the page's real size on this screen (resampled once per size, so it is sharp at any window).
func _painting() -> Texture2D:
	var src := ChamberArt.texture("map")
	if src == null:
		return null
	var f := _ui.scale.x if _ui.scale.x > 0.0 else 1.0
	var want := Vector2i((Vector2(640.0, 360.0) * f * float(UiScale.k())).round())
	if _map_tex == null or want != _map_px:
		var img := src.get_image()
		if img == null:
			return src
		if img.is_compressed():
			img.decompress()
		if _sparks.is_empty():
			_find_sea(img)
		if want != img.get_size():
			img.resize(want.x, want.y, Image.INTERPOLATE_LANCZOS)
		_map_tex = ImageTexture.create_from_image(img)
		_map_px = want
	return _map_tex


## Where the sea glints: a fixed scatter of points whose painted pixel is sea blue.
func _find_sea(img: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tries := 0
	while _sparks.size() < 46 and tries < 4000:
		tries += 1
		var p := Vector2(rng.randf_range(WorldLayout.LAND.position.x, WorldLayout.LAND.end.x), rng.randf_range(WorldLayout.LAND.position.y, WorldLayout.LAND.end.y))
		var c := img.get_pixel(int(p.x / 640.0 * img.get_width()), int(p.y / 360.0 * img.get_height()))
		if c.b > c.r + 0.08 and c.b > 0.25:
			_sparks.append(p)


func _draw_ui() -> void:
	_ui.draw_rect(UiScale.backdrop(_ui), WOOD)
	var page := Rect2(0.0, 0.0, 640.0, 360.0)
	var tex := _painting()
	if tex != null:
		_ui.draw_texture_rect(tex, page, false)
	else:
		_ui.draw_rect(WorldLayout.LAND, ChamberArt.greybox_color("table").lerp(Color(0.22, 0.30, 0.22), 0.7))
		_ui.draw_rect(WorldLayout.LAND, UiTheme.COL_GOLD_DARK, false, 1.0)


## A point on the bent way `r` at u (0..1).
static func _route_point(r: Dictionary, u: float) -> Vector2:
	var a: Vector2 = WorldLayout.spot(r.from).place
	var b: Vector2 = WorldLayout.spot(r.to).place
	var v: Vector2 = r.via
	return a.lerp(v, u).lerp(v.lerp(b, u), u)


## The map's weather, in the vellum's own coordinates: the god's faith on the land, the ways not yet known, sea glints, chimney smoke, a
## passing cloud, and the fog on what the god cannot reach.
func _draw_fx() -> void:
	_fx.draw_set_transform(-WorldLayout.LAND.position)
	var god := god_color()
	# Faith: a wash of the god's colour about a town, wider and deeper as its people turn.
	for id in WorldLayout.ids():
		if not WorldLayout.is_town(id) or not Conquest.is_open(_slot, id):
			continue
		var part := float(Conquest.percent_of(_slot, id)) / 100.0
		if part <= 0.0:
			continue
		var p: Vector2 = WorldLayout.spot(id).place
		var breathe := 1.0 + 0.03 * sin(_t * 0.7)
		var size := Vector2(110.0 + 230.0 * part, 76.0 + 150.0 * part) * breathe
		_stain(_fx, p, size, Color(god.r, god.g, god.b, 0.30 + 0.30 * part))
		_stain(_fx, p, size * 0.6, Color(god.r, god.g, god.b, 0.22 + 0.26 * part))
	# Ways not yet known: dots of ink from an open town toward a sealed one.
	for r: Dictionary in WorldLayout.ROUTES:
		if not Conquest.is_open(_slot, r.from):
			continue
		for n in range(6, 29):
			var u := float(n) / 32.0
			_fx.draw_circle(_route_point(r, u), 1.0, Color(INK.r, INK.g, INK.b, 0.75 * (1.0 - u * 0.4)))
	# The sea glints.
	for i in _sparks.size():
		var a := pow(maxf(0.0, sin(_t * 1.1 + float(i) * 2.399)), 10.0) if moving else 0.0
		if a > 0.02:
			_fx.draw_rect(Rect2(_sparks[i], Vector2(1.5, 0.5)), Color(0.80, 0.90, 1.0, 0.75 * a))
	# Chimney smoke over a town that is not under fog.
	for id in WorldLayout.ids():
		var s := WorldLayout.spot(id)
		if not s.has("smoke") or fog_of(id) > 0.05:
			continue
		for i in 4:
			var age := fposmod(_t * 0.11 + float(i) * 0.25, 1.0)
			var at: Vector2 = (s.smoke as Vector2) + Vector2(age * 6.0 + sin(age * 5.0 + float(i)) * 1.5, -age * 13.0)
			_fx.draw_circle(at, 1.2 + age * 2.6, Color(0.78, 0.76, 0.72, 0.30 * (1.0 - age)))
	# A cloud's shadow crossing the land.
	if moving:
		var cx := fposmod(_t * 7.0, 1100.0) - 220.0
		_stain(_fx, Vector2(cx, 150.0 + 40.0 * sin(_t * 0.05)), Vector2(300.0, 150.0), Color(0.02, 0.03, 0.08, 0.16))
	# Fog on what is locked or beyond reach: a dark wash, then pale drifts.
	for id in WorldLayout.ids():
		var f := fog_of(id)
		if f <= 0.0:
			continue
		var p: Vector2 = WorldLayout.spot(id).place
		var span: Vector2 = WorldLayout.span(id)
		_wash(_fx, p + Vector2(0.0, -4.0), span * 3.4, Color(0.035, 0.045, 0.10, 0.90 * f))
		for i in 5:
			var ph := float(i) * 1.7 + float(id.hash() % 7)
			var drift := Vector2(sin(_t * 0.11 + ph) * 14.0, cos(_t * 0.08 + ph) * 4.0) if moving else Vector2.ZERO
			var at := p + Vector2((float(i) - 2.0) * span.x * 0.55, (float(i % 2) - 0.5) * span.y * 1.1 - 4.0) + drift
			_stain(_fx, at, Vector2(span.x * 2.6, span.y * 1.5), Color(0.62, 0.68, 0.80, 0.26 * f))
		if _reveal.has(id):  # the fog burns: a ring of the god's light runs outward
			var u := float(_reveal[id]) / REVEAL_SECONDS
			_fx.draw_arc(p, 8.0 + 70.0 * u, 0.0, TAU, 48, Color(god.r, god.g, god.b, 0.8 * (1.0 - u)), 2.0)


## Light, added to the painting: the candles in the frame's corner, the chosen town's pool, a conquered town's glow.
func _draw_glow() -> void:
	var flick := 0.0
	if moving:
		flick = 0.5 * sin(_t * 2.3) + 0.3 * sin(_t * 5.1 + 1.0) + 0.2 * sin(_t * 8.7)
	_stain(_glow, WorldLayout.CANDLES_AT, Vector2(150.0, 150.0), Color(1.0, 0.62, 0.22, 0.13 + 0.035 * flick))
	_stain(_glow, WorldLayout.CANDLES_AT + Vector2(0.0, -12.0), Vector2(44.0, 44.0), Color(1.0, 0.75, 0.35, 0.16 + 0.05 * flick))
	var god := god_color()
	for id in WorldLayout.ids():
		var p: Vector2 = WorldLayout.spot(id).place
		if Conquest.is_town(id) and Conquest.conquered(_slot, id):
			_stain(_glow, p, WorldLayout.span(id) * 3.4, Color(god.r, god.g, god.b, 0.30))
		if id == selected:
			var pulse := 0.5 + 0.5 * sin(_t * 2.0) if moving else 0.5
			_stain(_glow, p, WorldLayout.span(id) * 3.2, Color(1.0, 0.78, 0.36, 0.24 + 0.10 * pulse))


func _ellipse(on: CanvasItem, c: Vector2, radii: Vector2, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * float(i) / 40.0
		pts.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	on.draw_polyline(pts, col, width, true)


## The largest of the small sizes at which `s` fits in `room`.
static func _fit_size(s: String, room: float) -> int:
	for size: int in [10, 9, 8, 7]:
		if UiTheme.width(s, size) <= room:
			return size
	return 6


func _ink(at: Vector2, s: String, size: int, col := INK) -> void:
	_top.draw_string(UiTheme.font_for(size), at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _draw_top() -> void:
	for id in WorldLayout.ids():
		_draw_spot(id)
	_ink(Vector2(roundf(WorldLayout.TITLE_AT.x - UiTheme.width(TITLE, UiTheme.SIZE_SMALL) * 0.5), WorldLayout.TITLE_AT.y), TITLE, UiTheme.SIZE_SMALL)
	_draw_plate()
	_draw_back()
	var hint_x := roundf(320.0 - UiTheme.width(HINT, UiTheme.SIZE_SMALL) * 0.5)
	UiTheme.text(_top, Vector2(hint_x, HINT_Y), HINT, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	if line != "":
		var w := UiTheme.width(line, UiTheme.SIZE_SMALL) + 12.0
		var pill := Rect2(roundf(PLATE.get_center().x - w * 0.5), LINE_Y - 12.0, w, 16.0)
		_top.draw_rect(pill, Color(0.10, 0.04, 0.03, 0.90))
		UiTheme.text(_top, Vector2(pill.position.x + 6.0, LINE_Y), line, UiTheme.SIZE_SMALL, UiTheme.COL_BAD_TEXT)


## A spot's writing: its name on its ribbon (a sealed spot's ribbon stays blank), the people's bar under it, the chosen town's ring, a
## conquered town's seal, and under a locked town what opens it.
func _draw_spot(id: String) -> void:
	var p: Vector2 = WorldLayout.spot(id).place
	var rib := WorldLayout.ribbon(id)
	var state := spot_state(id)
	var god := god_color()
	if id == selected:
		var pulse := 0.5 + 0.5 * sin(_t * 2.0) if moving else 1.0
		var radii: Vector2 = WorldLayout.span(id)
		_ellipse(_top, p, radii + Vector2.ONE, Color(0.0, 0.0, 0.0, 0.45), 2.5)
		_ellipse(_top, p, radii, Color(UiTheme.COL_GOLD.r, UiTheme.COL_GOLD.g, UiTheme.COL_GOLD.b, 0.65 + 0.35 * pulse), 1.5)
	if state == "sealed":
		return
	var label := WorldLayout.name_of(id)
	var size := _fit_size(label, rib.size.x - 4.0)
	var dim := state == "locked" and not _reveal.has(id)
	var col := Color(INK.r, INK.g, INK.b, 0.55) if dim else INK
	_ink(Vector2(roundf(rib.get_center().x - UiTheme.width(label, size) * 0.5), rib.get_center().y + float(size) * 0.36), label, size, col)
	if state == "locked":
		var lock := LOCK_LINE % [Conquest.UNLOCK_PERCENT, Conquest.town_name(Conquest.opener_of(id))]
		UiTheme.text(_top, Vector2(roundf(p.x - UiTheme.width(lock, UiTheme.SIZE_SMALL) * 0.5), p.y + 6.0), lock, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
		return
	# The people's bar, under the ribbon.
	var bar := Rect2(roundf(rib.get_center().x - 15.0), rib.end.y + 4.0, 30.0, 3.0)
	_top.draw_rect(bar.grow(1.0), Color(0.12, 0.07, 0.04))
	_top.draw_rect(bar, Color(0.30, 0.20, 0.11))
	var part := float(Conquest.percent_of(_slot, id)) / 100.0
	_top.draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * part), bar.size.y)), god)
	if Conquest.conquered(_slot, id):  # the god's wax seal on the ribbon's end
		var at := Vector2(rib.end.x + 3.0, rib.get_center().y)
		_top.draw_circle(at, 5.5, god.darkened(0.55))
		_top.draw_circle(at, 4.5, god.darkened(0.15))
		_top.draw_arc(at, 2.6, 0.0, TAU, 16, god.lightened(0.35), 1.0)


## The info card, on the calm vellum: the chosen town in ink, and the Descend seal.
func _draw_plate() -> void:
	_top.draw_rect(Rect2(PLATE.position + Vector2(2.0, 2.0), PLATE.size), Color(0.0, 0.0, 0.0, 0.35))
	_top.draw_rect(PLATE, CARD)
	_top.draw_rect(PLATE, Color(0.36, 0.22, 0.10), false, 1.0)
	_top.draw_rect(PLATE.grow(-2.0), Color(0.60, 0.44, 0.24), false, 1.0)
	var lines := info_lines(selected)
	for i in lines.size():
		var size := UiTheme.SIZE_BODY if i == 0 else UiTheme.SIZE_SMALL
		_ink(Vector2(PLATE.position.x + 9.0, PLATE.position.y + 16.0 + 12.0 * float(i)), lines[i], size, INK if i == 0 else Color(0.30, 0.18, 0.09))
	var lit := status.can_descend() and GodNight.draw(_slot, selected) != ""
	var r := descend_rect()
	_top.draw_rect(Rect2(r.position + Vector2(1.0, 2.0), r.size), Color(0.0, 0.0, 0.0, 0.4))
	_top.draw_rect(r, WAX if lit else Color(0.42, 0.33, 0.24))
	_top.draw_rect(r, (WAX if lit else Color(0.42, 0.33, 0.24)).darkened(0.45), false, 1.0)
	_top.draw_rect(Rect2(r.position + Vector2(2.0, 2.0), Vector2(r.size.x - 4.0, 1.0)), Color(1.0, 1.0, 1.0, 0.18 if lit else 0.08))
	var label := "Descend"
	UiTheme.text(_top, Vector2(roundf(r.get_center().x - UiTheme.width(label, UiTheme.SIZE_SMALL) * 0.5), r.position.y + 14.0), label, UiTheme.SIZE_SMALL,
		UiTheme.COL_TEXT if lit else UiTheme.COL_DIM)


## The Back tab: brass, on the frame.
func _draw_back() -> void:
	var r := back_rect()
	_top.draw_rect(r, Color(0.36, 0.25, 0.09))
	_top.draw_rect(r, UiTheme.COL_GOLD_MID, false, 1.0)
	_top.draw_rect(Rect2(r.position + Vector2(2.0, 2.0), Vector2(r.size.x - 4.0, 1.0)), Color(1.0, 0.9, 0.6, 0.25))
	var label := "Back"
	UiTheme.text(_top, Vector2(roundf(r.get_center().x - UiTheme.width(label, UiTheme.SIZE_SMALL) * 0.5), r.position.y + 11.0), label, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
