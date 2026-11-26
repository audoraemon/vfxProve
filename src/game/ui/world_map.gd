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
## The key hint is shown on a god slot's first few maps of a session only.
const HINT_VISITS := 3
const TITLE := "THE KNOWN WORLD"
## The parchment card on the map's calm vellum, the brass Back tab on the frame, and where the hint and a refusal's line are written.
const PLATE := Rect2(238.0, 268.0, 196.0, 64.0)
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
static var _hole: Texture2D
static var _bold: FontVariation
static var _visits := {}

var selected := ""
## A one-off message shown above the info plate ("" for none).
var line := ""
var status: HubStatus
var _slot: GodSlot
var _ui: Control
var _fx: Control
var _faith: ColorRect
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
	_visits[slot.index] = int(_visits.get(slot.index, 0)) + 1
	UiSound.play(&"chamber_page")  # the map is unrolled
	if not _reveal.is_empty():
		UiSound.play(&"chamber_chime")
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ui.draw.connect(_draw_ui)
	# As the Chamber: the blocker takes the mouse and hands it on in frame units; the 640x360 child ignores it.
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_ui.get_parent() as Control).gui_input.connect(_on_blocker_input)
	# Over the painting: the god's faith on the land, the weather of the map (clipped to the vellum), the lights (added), the writing.
	_faith = ColorRect.new()
	_faith.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faith.size = Vector2(640.0, 360.0)
	_faith.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/game/ui/world_faith.gdshader")
	_faith.material = mat
	_ui.add_child(_faith)
	_set_faith()
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
	if _faith != null:
		(_faith.material as ShaderMaterial).set_shader_parameter("time", _t)
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
	return Rect2(PLATE.end.x - 56.0, PLATE.position.y + 7.0, 46.0, 52.0)


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


## The colours of the god's hold on the land: the wash and its inked border. Ruin's is an ember with a scorched edge (its orange is the
## vellum's own colour).
func faith_colors() -> Array:
	if _slot.type == "ruin":
		return [Color(0.78, 0.13, 0.05), Color(0.07, 0.03, 0.02)]
	var god := god_color()
	return [god, god.darkened(0.62)]


## How far a town's faith reaches over the land, in page units, for the part (0..1) of its people that believe.
static func faith_reach(part: float) -> float:
	return 0.0 if part <= 0.0 else 34.0 + 130.0 * part


## Tells the faith shader each open town's place and reach.
func _set_faith() -> void:
	var mat := _faith.material as ShaderMaterial
	var towns := PackedVector3Array()
	for id in WorldLayout.ids():
		if WorldLayout.is_town(id) and Conquest.is_open(_slot, id):
			var p: Vector2 = WorldLayout.spot(id).place
			towns.append(Vector3(p.x, p.y, faith_reach(float(Conquest.percent_of(_slot, id)) / 100.0)))
	while towns.size() < 4:
		towns.append(Vector3.ZERO)
	var cols := faith_colors()
	mat.set_shader_parameter("towns", towns)
	mat.set_shader_parameter("fill", cols[0])
	mat.set_shader_parameter("edge", cols[1])
	mat.set_shader_parameter("land", piece("land"))
	mat.set_shader_parameter("time", 0.0)


## How much of a spot's fog is left: 1 for a sealed spot, less for a locked town, 0 for an open one; a newly opened town's burns away.
func fog_of(id: String) -> float:
	match spot_state(id):
		"sealed": return 1.0
		"locked": return 0.7
	if _reveal.has(id):
		return 0.7 * (1.0 - smoothstep(0.0, 1.0, float(_reveal[id]) / REVEAL_SECONDS))
	return 0.0


## A cut-out of the map's art (assets/chamber/map/), or null when it is not painted yet.
static func piece(name: String) -> Texture2D:
	return ChamberArt.texture("map/" + name)


## A round stain texture: `flat` keeps its strength to past half its radius (fog); the other falls away from the middle (light);
## `inside_out` is clear in the middle and full at the rim (the dusk around the chosen town).
static func _disc(flat: bool, inside_out := false) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0 if inside_out else 1.0))
	g.set_color(1, Color(1, 1, 1, 1.0 if inside_out else 0.0))
	if inside_out:
		g.add_point(0.45, Color(1, 1, 1, 0.0))
	else:
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


## A flat-topped stain (the night on a sealed land).
static func _wash(on: CanvasItem, c: Vector2, size: Vector2, col: Color) -> void:
	if _flat == null:
		_flat = _disc(true)
	on.draw_texture_rect(_flat, Rect2(c - size * 0.5, size), false, col)


## A soft round stain of `col`, `size` across, about `c`.
static func _stain(on: CanvasItem, c: Vector2, size: Vector2, col: Color) -> void:
	on.draw_texture_rect(_soft(), Rect2(c - size * 0.5, size), false, col)


## The bold face of the pixel font, for the names on the ribbons.
static func bold() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = UiTheme.base_font()
		_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	return _bold


static func bold_width(s: String, size: int) -> float:
	return bold().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


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


## How much of the road to `id` is inked: all of an open town's, the near part of a locked one's, growing while its fog burns.
func road_part(id: String) -> float:
	if _reveal.has(id):
		return lerpf(0.4, 1.0, smoothstep(0.0, 1.0, float(_reveal[id]) / REVEAL_SECONDS))
	return 1.0 if Conquest.is_open(_slot, id) else 0.4


## Dashes of ink along a road's way, as far as `part` of its length.
func _draw_road(points: Array, part: float) -> void:
	var total := 0.0
	for i in range(1, points.size()):
		total += (points[i] as Vector2).distance_to(points[i - 1])
	var reach := total * part
	var walked := 0.0
	for i in range(1, points.size()):
		var a: Vector2 = points[i - 1]
		var b: Vector2 = points[i]
		var seg := a.distance_to(b)
		var at := fposmod(-walked, 6.5)  # dashes 4 long, 2.5 apart, unbroken across the bends
		while at < seg:
			var from := maxf(at, 0.0)
			var to := minf(at + 4.0, seg)
			if walked + from >= reach:
				return
			to = minf(to, reach - walked)
			if to > from:
				var fade := 1.0 if part >= 1.0 else clampf((reach - walked - from) / 30.0, 0.0, 1.0)
				_fx.draw_line(a.lerp(b, from / seg), a.lerp(b, to / seg), Color(0.30, 0.17, 0.07, 0.9 * fade), 1.6, true)
			at += 6.5
		walked += seg


## The cloud banks over a spot, back row first: [texture index, middle, width] each. A sealed spot is covered; `ring` leaves the
## middle open (a locked town shows through its cloud).
static func cloud_bank(id: String, ring := false) -> Array:
	var p: Vector2 = WorldLayout.spot(id).place
	var span: Vector2 = WorldLayout.span(id)
	var w := clampf(span.x * 1.7, 58.0, 84.0)
	var step := Vector2(w * 0.62, w * 0.27)
	var cols := maxi(2, int(round(span.x * (2.3 if ring else 3.0) / step.x)))
	var rows := maxi(2, int(round(span.y * (2.0 if ring else 2.7) / step.y)))
	var out := []
	var n := id.hash() % 6
	for row in rows:
		for col in cols:
			var off := Vector2((float(col) - float(cols - 1) * 0.5 + (0.5 if row % 2 == 1 else 0.0)) * step.x,
				(float(row) - float(rows - 1) * 0.5) * step.y)
			if ring and (off / span).length() < 0.62:
				continue
			var cw := w * (0.85 + 0.3 * float((row * 3 + col * 5) % 3) / 2.0)
			if Rect2(p + off - Vector2(cw, cw * 0.4) * 0.5, Vector2(cw, cw * 0.4)).grow(-6.0).intersects(WorldLayout.ribbon(id)):
				continue  # the ribbon stays in sight: blank over a sealed spot, named over a locked town
			out.append([(n + row * 2 + col * 3) % 6, p + off, cw])
	return out


## The map's weather, in the vellum's own coordinates: roads and ways, the ships, sea glints, chimney smoke, a passing cloud, the dusk
## around the chosen town, and the cloud banks on what the god cannot reach.
func _draw_fx() -> void:
	_fx.draw_set_transform(-WorldLayout.LAND.position)
	var god := god_color()
	# Roads: inked as far as the god's reach goes.
	for id: String in WorldLayout.ROAD_PATHS:
		_draw_road(WorldLayout.ROAD_PATHS[id], road_part(id))
	# Ways not yet known: dots of ink from an open town toward a sealed one.
	for r: Dictionary in WorldLayout.ROUTES:
		if not Conquest.is_open(_slot, r.from):
			continue
		for n in range(6, 29):
			var u := float(n) / 32.0
			_fx.draw_circle(_route_point(r, u), 1.0, Color(INK.r, INK.g, INK.b, 0.75 * (1.0 - u * 0.4)))
	# The Capital's ships ride at anchor.
	for i in WorldLayout.SHIPS.size():
		var tex := piece("ship_%d" % i)
		if tex == null:
			continue
		var bob := sin(_t * 1.3 + float(i) * 1.9) if moving else 0.0
		var at: Vector2 = WorldLayout.SHIPS[i] + Vector2(0.0, bob * 0.7)
		var size := Vector2(22.0, 22.0 * float(tex.get_height()) / float(tex.get_width()))
		_fx.draw_set_transform(at - WorldLayout.LAND.position, deg_to_rad(bob * 2.2))
		_fx.draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y + 2.0), size), false)
		_fx.draw_set_transform(-WorldLayout.LAND.position)
	# The sea glints.
	for i in _sparks.size():
		var a := pow(maxf(0.0, sin(_t * 1.1 + float(i) * 2.399)), 10.0) if moving else 0.0
		if a > 0.02:
			_fx.draw_rect(Rect2(_sparks[i], Vector2(1.5, 0.5)), Color(0.80, 0.90, 1.0, 0.75 * a))
	# Chimney smoke over a town that is not under cloud.
	for id in WorldLayout.ids():
		var s := WorldLayout.spot(id)
		if not s.has("smoke") or fog_of(id) > 0.05:
			continue
		for i in 5:
			var age := fposmod(_t * 0.10 + float(i) * 0.2, 1.0)
			var at: Vector2 = (s.smoke as Vector2) + Vector2(age * 7.0 + sin(age * 5.0 + float(i)) * 1.5, -age * 14.0)
			_fx.draw_circle(at, 1.1 + age * 2.8, Color(0.80, 0.78, 0.74, 0.34 * (1.0 - age)))
	# A cloud's shadow crossing the land.
	if moving:
		var cx := fposmod(_t * 7.0, 1100.0) - 220.0
		_stain(_fx, Vector2(cx, 150.0 + 40.0 * sin(_t * 0.05)), Vector2(300.0, 150.0), Color(0.02, 0.03, 0.08, 0.16))
	# Dusk on the map around the chosen town: the eye goes where the light is.
	if _hole == null:
		_hole = _disc(false, true)
	var sel: Vector2 = WorldLayout.spot(selected).get("place", Vector2(320.0, 180.0))
	var hole := Rect2(sel - WorldLayout.span(selected) * 4.2, WorldLayout.span(selected) * 8.4)
	var dusk := Color(0.02, 0.02, 0.06, 0.26)
	_fx.draw_texture_rect(_hole, hole, false, dusk)
	var land := WorldLayout.LAND
	_fx.draw_rect(Rect2(land.position.x, land.position.y, land.size.x, maxf(0.0, hole.position.y - land.position.y)), dusk)
	_fx.draw_rect(Rect2(land.position.x, hole.end.y, land.size.x, maxf(0.0, land.end.y - hole.end.y)), dusk)
	_fx.draw_rect(Rect2(land.position.x, hole.position.y, maxf(0.0, hole.position.x - land.position.x), hole.size.y), dusk)
	_fx.draw_rect(Rect2(hole.end.x, hole.position.y, maxf(0.0, land.end.x - hole.end.x), hole.size.y), dusk)
	# Cloud on what is locked or beyond reach: night under it, then the banks, drifting; a town that opens sheds them.
	for id in WorldLayout.ids():
		var f := fog_of(id)
		if f <= 0.0:
			continue
		var p: Vector2 = WorldLayout.spot(id).place
		var span: Vector2 = WorldLayout.span(id)
		var sealed := spot_state(id) == "sealed"
		_wash(_fx, p + Vector2(0.0, -2.0), span * 3.3, Color(0.035, 0.045, 0.10, (0.72 if sealed else 0.5) * f))
		var u := float(_reveal[id]) / REVEAL_SECONDS if _reveal.has(id) else 0.0
		var bank := cloud_bank(id, not sealed)
		for i in bank.size():
			var tex := piece("cloud_%d" % int(bank[i][0]))
			if tex == null:
				continue
			var ph := float(i) * 1.7 + float(id.hash() % 7)
			var drift := Vector2(sin(_t * 0.10 + ph) * 5.0, cos(_t * 0.07 + ph) * 1.5) if moving else Vector2.ZERO
			var at: Vector2 = (bank[i][1] as Vector2) + drift + ((bank[i][1] as Vector2) - p).normalized() * 46.0 * u
			var w: float = bank[i][2]
			var size := Vector2(w, w * float(tex.get_height()) / float(tex.get_width()))
			_fx.draw_texture_rect(tex, Rect2(at - size * 0.5, size), false, Color(0.88, 0.88, 0.94, (0.97 if sealed else 0.90) * (1.0 - u)))
		if _reveal.has(id):  # a ring of the god's light runs outward
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
			_stain(_glow, p, WorldLayout.span(id) * 3.0, Color(god.r, god.g, god.b, 0.22))
		if id == selected:
			var pulse := 0.5 + 0.5 * sin(_t * 2.0) if moving else 0.5
			_stain(_glow, p, WorldLayout.span(id) * 3.4, Color(1.0, 0.80, 0.42, 0.20 + 0.07 * pulse))


## The largest of the small sizes at which `s` fits in `room`, in the bold face.
static func _fit_size(s: String, room: float) -> int:
	for size: int in [10, 9, 8, 7]:
		if bold_width(s, size) <= room:
			return size
	return 6


func _ink(at: Vector2, s: String, size: int, col := INK, face: Font = null) -> void:
	_top.draw_string(face if face != null else UiTheme.font_for(size), at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func _roman(n: int) -> String:
	return ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"][clampi(n, 0, 10)]


func _draw_top() -> void:
	for id in WorldLayout.ids():
		_draw_spot(id)
	_ink(Vector2(roundf(WorldLayout.TITLE_AT.x - bold_width(TITLE, UiTheme.SIZE_SMALL) * 0.5), WorldLayout.TITLE_AT.y), TITLE, UiTheme.SIZE_SMALL, INK, bold())
	# Whose map this is: the god's tier and Faith on the frame, its emblem on the compass.
	var god := god_color()
	var tier := "TIER %s" % _roman(_slot.tier)
	var faith := "FAITH %d" % _slot.faith
	UiTheme.text(_top, Vector2(roundf(196.0 - UiTheme.width(tier, UiTheme.SIZE_SMALL)), 21.0), tier, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_top, Vector2(444.0, 21.0), faith, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	# The god's jewel on the compass's boss.
	var c := WorldLayout.COMPASS_AT
	_top.draw_circle(c, 6.5, Color(0.07, 0.05, 0.08, 0.92))
	_top.draw_circle(c, 5.0, god.darkened(0.35))
	_top.draw_colored_polygon(PackedVector2Array([c + Vector2(0.0, -4.5), c + Vector2(4.5, 0.0), c + Vector2(0.0, 4.5), c + Vector2(-4.5, 0.0)]), god)
	_top.draw_colored_polygon(PackedVector2Array([c + Vector2(0.0, -4.5), c + Vector2(4.5, 0.0), c]), god.lightened(0.45))
	_top.draw_arc(c, 6.5, 0.0, TAU, 28, UiTheme.COL_GOLD_MID, 1.0)
	_draw_plate()
	_draw_back()
	if int(_visits.get(_slot.index, 0)) <= HINT_VISITS:
		var hint_x := roundf(320.0 - UiTheme.width(HINT, UiTheme.SIZE_SMALL) * 0.5)
		UiTheme.text(_top, Vector2(hint_x, HINT_Y), HINT, UiTheme.SIZE_SMALL, Color(UiTheme.COL_DIM.r, UiTheme.COL_DIM.g, UiTheme.COL_DIM.b, 0.8))
	if line != "":
		var w := UiTheme.width(line, UiTheme.SIZE_SMALL) + 12.0
		var pill := Rect2(roundf(PLATE.get_center().x - w * 0.5), LINE_Y - 12.0, w, 16.0)
		_top.draw_rect(pill, Color(0.10, 0.04, 0.03, 0.90))
		UiTheme.text(_top, Vector2(pill.position.x + 6.0, LINE_Y), line, UiTheme.SIZE_SMALL, UiTheme.COL_BAD_TEXT)


## A spot's writing: its name on its ribbon (a sealed spot's ribbon stays blank), the people's bar under it, the pointer over the chosen
## town, a conquered town's seal, and under a locked town a tag that says what opens it.
func _draw_spot(id: String) -> void:
	var rib := WorldLayout.ribbon(id)
	var state := spot_state(id)
	var god := god_color()
	if id == selected:
		var bob := sin(_t * 2.4) * 1.2 if moving else 0.0
		var ptr := piece("pointer")
		if ptr != null:
			var size := Vector2(10.0, 10.0 * float(ptr.get_height()) / float(ptr.get_width()))
			_top.draw_texture_rect(ptr, Rect2(Vector2(rib.get_center().x - size.x * 0.5, rib.position.y - size.y - 1.5 + bob), size), false)
	if state == "sealed":
		return
	var label := WorldLayout.name_of(id).to_upper()
	var size := _fit_size(label, rib.size.x - 4.0)
	var dim := state == "locked" and not _reveal.has(id)
	var col := Color(INK.r, INK.g, INK.b, 0.6) if dim else INK
	_ink(Vector2(roundf(rib.get_center().x - bold_width(label, size) * 0.5), rib.get_center().y + float(size) * 0.36), label, size, col, bold())
	if state == "locked":
		var lock := LOCK_LINE % [Conquest.UNLOCK_PERCENT, Conquest.town_name(Conquest.opener_of(id))]
		var tag := piece("tag")
		var tag_rect := Rect2(roundf(rib.get_center().x - 70.0), rib.end.y - 3.0, 140.0, 0.0)
		if tag != null:
			tag_rect.size.y = tag_rect.size.x * float(tag.get_height()) / float(tag.get_width())
			_top.draw_texture_rect(tag, tag_rect, false)
		var lock_size := 8
		_ink(Vector2(roundf(tag_rect.get_center().x - UiTheme.width(lock, lock_size) * 0.5), tag_rect.position.y + tag_rect.size.y * 0.80), lock, lock_size)
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


## The info card, pinned on the calm vellum: the chosen town in ink, and the Descend seal.
func _draw_plate() -> void:
	var note := piece("note")
	if note != null:
		_top.draw_texture_rect(note, Rect2(PLATE.position + Vector2(1.5, 2.0), PLATE.size), false, Color(0.0, 0.0, 0.0, 0.35))
		_top.draw_texture_rect(note, PLATE, false)
	else:
		_top.draw_rect(PLATE, CARD)
		_top.draw_rect(PLATE, Color(0.36, 0.22, 0.10), false, 1.0)
	var lines := info_lines(selected)
	for i in lines.size():
		var at := Vector2(PLATE.position.x + 18.0, PLATE.position.y + 19.0 + 11.5 * float(i))
		if i == 0:
			_ink(at, lines[i], UiTheme.SIZE_BODY, INK, bold())
		else:
			_ink(at, lines[i], UiTheme.SIZE_SMALL, Color(0.30, 0.18, 0.09))
	var lit := status.can_descend() and GodNight.draw(_slot, selected) != ""
	var r := descend_rect()
	var seal := piece("seal" if lit else "seal_off")
	var seal_rect := Rect2(r.get_center().x - 16.0, r.position.y, 32.0, 33.0)
	if seal != null:
		_top.draw_texture_rect(seal, Rect2(seal_rect.position + Vector2(1.0, 1.5), seal_rect.size), false, Color(0.0, 0.0, 0.0, 0.35))
		_top.draw_texture_rect(seal, seal_rect, false)
	else:
		_top.draw_rect(seal_rect, WAX if lit else Color(0.42, 0.33, 0.24))
	var label := "DESCEND"
	_ink(Vector2(roundf(r.get_center().x - bold_width(label, 8) * 0.5), seal_rect.end.y + 10.0), label, 8, INK if lit else Color(INK.r, INK.g, INK.b, 0.45), bold())


## The Back tab: brass, on the frame.
func _draw_back() -> void:
	var r := back_rect()
	_top.draw_rect(r, Color(0.36, 0.25, 0.09))
	_top.draw_rect(r, UiTheme.COL_GOLD_MID, false, 1.0)
	_top.draw_rect(Rect2(r.position + Vector2(2.0, 2.0), Vector2(r.size.x - 4.0, 1.0)), Color(1.0, 0.9, 0.6, 0.25))
	var label := "Back"
	UiTheme.text(_top, Vector2(roundf(r.get_center().x - UiTheme.width(label, UiTheme.SIZE_SMALL) * 0.5), r.position.y + 11.0), label, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
