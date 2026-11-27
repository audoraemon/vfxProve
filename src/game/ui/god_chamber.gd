class_name GodChamber
extends Node
## The God's Chamber (spec docs/superpowers/specs/2026-11-19-kak-god-chamber-design.md): where a god stands between nights. It replaces the
## hub on Screen.HUB: four stations (World Table, Ability Tree, Faith Altar, Rite Door) in a room that shifts a little against the mouse, a
## slim top bar with the god's status, the Hunt and seal lines, and the bottom lines. The words and decisions come from HubStatus, the
## rects and keys from ChamberLayout, the pictures from ChamberArt (greybox until art is painted). Step 7: the room lives and shows the god's
## progress (ChamberLife: flames, candles per tier, cups, the hourglass, the Hunt's red sky), with its own sound (ChamberSound). Step 8: the
## move into a station is a camera move (a log-space zoom whose focus pans to the screen's centre, the layers dollying at their own rates,
## drawn through pixel_aa), led by the station's signature (ChamberSignature) and its sounds; the page then fades in from the colour the zoom
## ended in (Game's ChamberPageFade), and Back fades the page out to it before the room pulls back.

## "descend", "awaken", "tree", "faith", "title" or "awaken_dev".
signal action(name: String)

## The words the screen says, kept here under their old names (HubStatus holds them).
const BLOCKED := HubStatus.BLOCKED
const BLOCKED_DRAFT := HubStatus.BLOCKED_DRAFT
const HUNT_DUE := HubStatus.HUNT_DUE
const SEALED := HubStatus.SEALED
const AWAKEN_HUNT := HubStatus.AWAKEN_HUNT
const RITE_UNWRITTEN := HubStatus.RITE_UNWRITTEN
const GIFTS_LINE := HubStatus.GIFTS_LINE
## The widest the one-off line may be before it wraps.
const LINE_WIDTH := 600.0
## The Title button at the bar's right end (its width), and the Notice meter's size in the bar.
const TITLE_W := 34.0
const NOTICE_W := 36.0
const BAR_GAP := 8.0
## The keys hint's baseline; the lines above it stack upward by `STACK_GAP`.
const HINT_Y := 350.0
const STACK_GAP := 18.0

## Hovering lights the object itself (round 3): its own picture brightened (hover_<key>) and a soft warm rim round its silhouette
## (rim_<key>), both from the build pass; no gold box round the hit rect.
const HOVER_BOX := false
## How strongly the hovered object's brightened picture is laid over it.
const HOVER_ALPHA := 0.9
## The colour each station's zoom fades through before the page (round 3): the Ability Tree's purple, the altar's warm gold, the
## World Table's blue, the Rite Door's warm white-gold. Step 8: the fade ends in the station's END_COLORS (a deeper tone of the same
## light; the Rite Door's floods out white-gold), the page fades in from it, and Back fades the page out to it. FADE_DARK is the end of a
## zoom about no station.
const FADE_COLORS := {"descend": Color(0.24, 0.48, 0.88), "tree": Color(0.5, 0.24, 0.72), "faith": Color(0.9, 0.62, 0.22),
	"awaken": Color(0.8, 0.7, 0.48)}
const END_COLORS := {"descend": Color(0.1, 0.2, 0.42), "tree": Color(0.24, 0.1, 0.36), "faith": Color(0.46, 0.28, 0.08),
	"awaken": Color(0.8, 0.68, 0.44)}
## The brightest any channel of the Rite Door's covers may be (the user, step 8 review): it floods warm gold, never near-white.
const COVER_CAP := 0.8
## The soft inner edge of the veil over the dark sides (veil_edges()), in frame units at full depth; and the depth by which the dark sides
## a very wide window shows at rest are fully covered (veil_soft_edges()).
const VEIL_RAMP := 28.0
const VEIL_SOFT_D := 0.3
const FADE_DARK := Color(0.02, 0.016, 0.02)
## The keys hint's strip on the desk (round 3): dark parchment, translucent, edge to edge, with a worn edge above and the hint in ink.
const HINT_STRIP := Color(0.25, 0.17, 0.1, 0.8)
const HINT_EDGE := Color(0.46, 0.33, 0.16, 0.85)
const HINT_INK := Color(0.93, 0.85, 0.68)
const HINT_STRIP_H := 15.0
## The order the stations are drawn in, back to front (ChamberLayout.ORDER is the order they are listed and hit-tested in).
const DRAW_ORDER: Array[String] = ["awaken", "descend", "tree", "faith"]
## Zoom and fade between the Chamber and a station's page. Off (false) in --flow-test, --capture and headless runs, where a press emits in the same call.
static var transitions := true
## Step 8, the camera move. On a press the station's signature swells for CUE_TIME (the anticipation, the room still), then the room
## zooms in over OUT_TIME: scale = ZOOM_TO ^ depth (log space), depth a strong ease-out (out_depth), while the station's focus pans to
## the screen's centre; coming back it takes BACK_TIME with a soft settle (back_depth), no overshoot. The cover rises over the zoom's last
## (1 - FADE_FROM) of its time and lifts over the first (1 - FADE_FROM) of the way back. Each layer scales about the same focus at its own
## rate, ZOOM_TO ^ (depth x (1 + DOLLY x (its factor - the station's layer's factor))): the desk rushes past, the wall moves least.
const ZOOM_TO := 2.2
const CUE_TIME := 0.1
const OUT_TIME := 0.45
const BACK_TIME := 0.4
const FADE_FROM := 0.55
const DOLLY := 0.8
## The transition's sounds (UiSound, the UI bus; tools/audio/foley/chamber/): a soft whoosh with the zoom, each station's own sound with
## the press, and the reverse whoosh as a page's Back fades it out (ChamberPageFade). Only where transitions play.
const WHOOSH := &"chamber_whoosh"
const WHOOSH_BACK := &"chamber_whoosh_back"
const STATION_CUES := {"tree": &"chamber_riffle", "faith": &"chamber_coin", "descend": &"chamber_unroll", "awaken": &"chamber_groan"}
## The room's draw while it moves: pixel-art anti-aliasing (src/core/pixel_aa.gdshader, the town floor's), so a texel at 2.2 x k screen
## pixels never shows as 4 or 5 and never shimmers; at rest the room is drawn plain, as before.
const PIXEL_AA := preload("res://src/core/pixel_aa.gdshader")
## How long the room waits, black, for Game to replace it after a zoom in before it comes back to rest. Every hub action Game accepts frees the room
## inside the emit call, so this only times out after a refusal.
const HELD_TIME := 0.25
## Transition modes: at rest, zooming into a station (the action waits), coming back out of one, and held (input ignored) at the end of the zoom in.
enum Mode {REST, OUT, BACK, HELD}

## A one-off message shown near the bottom (e.g. GodNight.ABANDONED); "" for none.
var line := ""
## True in the DEV build: A is the Awaken hook.
var dev := false
var status: HubStatus
## The station whose page the god is coming back from (Task 4 plays the zoom back from it); "" for none.
var from := ""
var _slot: GodSlot
var _ui: Control
var _hover := ""
## The mouse from the area's centre, -1..1 on each axis: what the parallax follows.
var _mouse01 := Vector2.ZERO
var _mode := Mode.REST
## Seconds into the current zoom, the station it is about, and the action that waits for its end.
var _t := 0.0
var _focus_key := ""
var _pending := ""
## The room's life (step 7): what it shows of the god, and its own running time (seconds since the room opened; it only runs while
## ChamberLife.moving). `life_hold` stops the clock where it is (the photographs of the idle life set `life_t` frame by frame).
var _life := ChamberLife.new()
var life_t := 0.0
var life_hold := false
var _sound: ChamberSound
## The room's own canvas item (step 8): drawn behind the bar and the lines, through pixel_aa while it moves.
var _room: Control
var _aa: ShaderMaterial
## The render warm-up (_prewarm()): once a session, two clear canvas items (one through the room's pixel_aa) drawn for WARM_FRAMES frames.
const WARM_FRAMES := 3
static var _aa_warm := false
var _warm: Array[Control] = []
var _warm_frames := 0
## Photographs only (Game's capture flags): a station shown hovered whatever the window's mouse does, and a transition held at a pose.
var _hover_held := false
var _pose_held := false


func setup(slot: GodSlot, p_line := "", p_dev := false, p_from := "") -> GodChamber:
	_slot = slot
	line = p_line
	dev = p_dev
	from = p_from
	status = HubStatus.new(slot)
	_life.st = ChamberLife.state(slot, status)
	WorldMap.prewarm()  # the World Map's art starts loading now, so the table's zoom into it does not stall on the first open
	if ChamberSound.enabled and (DisplayServer.get_name() != "headless" or ChamberSound.force):
		_sound = ChamberSound.new()
		_sound.name = "RoomSound"
		_sound.setup(_life.st, -1, "%d:%d" % [slot.index, slot.seed], slot.night)
		add_child(_sound)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)  # 640x360 coordinates, centred in the area
	_ui.draw.connect(_draw_ui)
	_room = Control.new()
	_room.name = "Room"
	_room.size = ChamberLayout.FRAME.size
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.show_behind_parent = true
	_room.draw.connect(_draw_room_canvas)
	_ui.add_child(_room)
	# The Design child is only 640x360: a click outside it (the bands of a wide or tall window, where the bar and the Title button reach) would go
	# to the blocker, which swallows it. So the blocker takes the mouse and hands it on in frame units; the child ignores it.
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_ui.get_parent() as Control).gui_input.connect(_on_blocker_input)
	if transitions and ChamberLayout.STATIONS.has(p_from):
		_mode = Mode.BACK
		_focus_key = p_from
		_t = 0.0
	_sync_canvas()
	if transitions:
		_prewarm()
	return self


func _exit_tree() -> void:
	_pending = ""  # a room torn down mid-zoom sends nothing


## Called once from setup() where transitions play. The stations' pages and the transition's sounds start loading on other threads
## (ChamberPrewarm; the Rite Door's Prepare only while the door is lit; nothing headless), and the first room of the session draws two
## clear canvas items for WARM_FRAMES frames, so the first zoom and the first page do not stop to build their render pipelines.
func _prewarm() -> void:
	var paths := PackedStringArray()
	for cue: StringName in [WHOOSH, WHOOSH_BACK] + STATION_CUES.values():
		paths.append_array(Sfx.paths_for(cue))
	var tree := SkillTreeScreen.prewarm_paths(_slot)
	paths.append_array(tree.paths)
	if status.awaken_shown() and not status.awaken_dim():
		paths.append_array(PrepareScreen.prewarm_paths())  # the door can open a Prepare
	ChamberPrewarm.start(paths, tree.grey)
	if _aa_warm or DisplayServer.get_name() == "headless":
		return
	_aa = ShaderMaterial.new()
	_aa.shader = PIXEL_AA
	# Two clear canvas items: one through the room's pixel_aa (its zoom), one plain with the shapes the pages draw and the room never
	# does at rest (lines, strips, discs, textured polygons, a rounded panel: the Ability Tree's wheel).
	for aa: bool in [true, false]:
		var item := Control.new()
		item.name = "AaWarm" if aa else "PlainWarm"
		item.size = Vector2(4.0, 4.0)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if aa:
			item.material = _aa
			item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		item.draw.connect(_draw_warm.bind(item, aa))
		_ui.add_child(item)
		_warm.append(item)


## The warm-up's frame, all fully clear so nothing on screen changes: through pixel_aa what the room draws while it moves (a rect, a
## texture, a polygon); plain, the pages' shapes.
func _draw_warm(item: Control, aa: bool) -> void:
	var clear := Color(1.0, 1.0, 1.0, 0.0)
	var tri := PackedVector2Array([Vector2.ZERO, Vector2(2.0, 0.0), Vector2(0.0, 2.0)])
	item.draw_rect(Rect2(0.0, 0.0, 1.0, 1.0), clear)
	item.draw_texture_rect(ChamberSignature.bloom_texture(), Rect2(0.0, 0.0, 2.0, 2.0), false, clear)
	item.draw_polygon(tri, PackedColorArray([clear, clear, clear]))
	if aa:
		return
	item.draw_line(Vector2.ZERO, Vector2(2.0, 2.0), clear, 1.0)
	item.draw_line(Vector2.ZERO, Vector2(2.0, 2.0), clear, 2.0)
	item.draw_polyline(tri, clear, 1.0)
	item.draw_polyline(tri, clear, 3.0)
	item.draw_arc(Vector2(2.0, 2.0), 1.5, 0.0, TAU, 8, clear, 2.0)
	item.draw_arc(Vector2(2.0, 2.0), 1.5, 0.0, TAU, 8, clear, 1.0)
	item.draw_circle(Vector2(2.0, 2.0), 1.5, clear)
	item.draw_colored_polygon(tri, clear, PackedVector2Array([Vector2.ZERO, Vector2(1.0, 0.0), Vector2(0.0, 1.0)]), ChamberSignature.bloom_texture())
	item.draw_rect(Rect2(0.0, 0.0, 2.0, 2.0), clear, false, 1.0)
	var box := StyleBoxFlat.new()
	box.bg_color = clear
	box.border_color = clear
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	item.draw_style_box(box, Rect2(0.0, 0.0, 4.0, 4.0))


## The warm-up runs for WARM_FRAMES frames, then goes; the room keeps loading while it is at rest (never during a zoom).
func _prewarm_step() -> void:
	if not _warm.is_empty():
		_warm_frames += 1
		if _warm_frames >= WARM_FRAMES:
			for item in _warm:
				item.queue_free()
			_warm.clear()
			_aa_warm = true
	if _mode == Mode.REST:
		ChamberPrewarm.step()


func _process(delta: float) -> void:
	if transitions:
		_prewarm_step()
	advance(delta)
	if ChamberLife.moving and not life_hold and not is_queued_for_deletion():
		life_t += delta
		_redraw()


## The room's sound (null when it is off: FLOW, --capture, headless).
func room_sound() -> ChamberSound:
	return _sound if is_instance_valid(_sound) else null


## What the room shows of the god (ChamberLife.state()).
func life_state() -> Dictionary:
	return _life.st


## The mouse from the area's centre, -1..1 on each axis ((0, 0) before any motion).
func mouse01() -> Vector2:
	return _mouse01


func in_transition() -> bool:
	return _mode != Mode.REST


## The depth of the zoom going in, 0..1, at u (0..1) of OUT_TIME: a strong (quartic) ease-out.
static func out_depth(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return 1.0 - pow(1.0 - u, 4.0)


## The depth coming back, 1..0, at u of BACK_TIME: a soft (cubic) settle into rest, no overshoot.
static func back_depth(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return pow(1.0 - u, 3.0)


## How far through its timed part the transition is, 0..1 (out: the zoom after the anticipation; back: the way back).
func _u() -> float:
	match _mode:
		Mode.OUT: return clampf((_t - CUE_TIME) / OUT_TIME, 0.0, 1.0)
		Mode.BACK: return clampf(_t / BACK_TIME, 0.0, 1.0)
		Mode.HELD: return 1.0
	return 0.0


## Progress of the zoom in, 0 (at rest) to 1 (fully in): the zoom, the pan and the draw all read it.
func _depth() -> float:
	match _mode:
		Mode.OUT: return out_depth(_u())
		Mode.BACK: return back_depth(_u())
		Mode.HELD: return 1.0
	return 0.0


## The room's scale (the station's own layer): 1 at rest, ZOOM_TO fully in, in log space.
func zoom() -> float:
	return pow(ZOOM_TO, _depth())


## The layer of the station the zoom is about (the wall when none).
func _focus_layer() -> String:
	return ChamberLayout.STATIONS[_focus_key].layer if ChamberLayout.STATIONS.has(_focus_key) else "wall"


## A layer's scale now (the depth dolly): its rate is ordered by its parallax factor, the station's own layer's is the zoom.
func layer_scale(layer: String) -> float:
	var rate := 1.0 + DOLLY * (float(ChamberLayout.LAYERS[layer]) - float(ChamberLayout.LAYERS[_focus_layer()]))
	return pow(ZOOM_TO, _depth() * rate)


## Where the station's focus is on screen now: where it is drawn at rest, panning with the depth to the frame's centre.
func focus_screen() -> Vector2:
	return _focus_point().lerp(ChamberLayout.FRAME.get_center(), _depth())


## How a layer is drawn now: scaled by layer_scale() about the station's focus, which sits at focus_screen(). Identity at rest.
func layer_transform(layer: String) -> Transform2D:
	if _depth() <= 0.0:
		return Transform2D.IDENTITY
	var s := layer_scale(layer)
	var f := _focus_point()
	return Transform2D(Vector2(s, 0.0), Vector2(0.0, s), focus_screen() - f * s)


## The cover over the room and bar: 0 until FADE_FROM of the zoom's time, then up to 1 at its end (a smoothstep); the way back lifts it
## over its first (1 - FADE_FROM).
func fade() -> float:
	var k := 0.0
	match _mode:
		Mode.OUT: k = clampf((_u() - FADE_FROM) / (1.0 - FADE_FROM), 0.0, 1.0)
		Mode.BACK: k = 1.0 - clampf(_u() / (1.0 - FADE_FROM), 0.0, 1.0)
		Mode.HELD: k = 1.0
	return k * k * (3.0 - 2.0 * k)


## The colour of that cover: the station's own colour as it comes in, deepening to its end colour (round 3, step 8), so the room passes
## through the station's light into the page; it depends on fade() alone, so the way back passes through the same colours.
func fade_color() -> Color:
	var k := fade()
	var c: Color = FADE_COLORS.get(_focus_key, FADE_DARK)
	var rgb := c.lerp(end_color(_focus_key), k * k)
	return Color(rgb.r, rgb.g, rgb.b, k)


## The colour a station's zoom ends in, opaque: the page fades in from it and out to it (ChamberPageFade).
static func end_color(key: String) -> Color:
	return END_COLORS.get(key, FADE_DARK)


## The last frame of a station's zoom, for a page that would match its own opening to it (the World Table's match cut, later): the end
## colour, the station's focus (room units, at rest) and the zoom it ends at, and the frame point the focus ends on.
static func end_frame(key: String) -> Dictionary:
	var focus: Vector2 = ChamberLayout.STATIONS[key].focus if ChamberLayout.STATIONS.has(key) else ChamberLayout.FRAME.get_center()
	return {"key": key, "color": end_color(key), "focus": focus, "zoom": ZOOM_TO, "centre": ChamberLayout.FRAME.get_center()}


## Where the veil over the dark sides ends now, in frame units: x = the left veil's inner edge (it covers the backdrop from its left side
## to there), y = the right veil's. The safe part of the room is the painting's lit part (ChamberLayout.LIT) plus whatever the window
## showed at rest; the zoom would carry anything else into the frame -- the dark sides beyond the Ability Tree and the Faith Altar, or
## past the room's edge -- so from the moment it would enter, it is covered, opaque, in the station's end colour (the colour the cover
## then rises to). Nothing at rest: (back.left, back.right).
func veil_edges() -> Vector2:
	var back := UiScale.backdrop(_ui) if _ui != null else ChamberLayout.FRAME
	var out := Vector2(back.position.x, back.end.x)
	if _depth() <= 0.0:
		return out
	var sh := ChamberLayout.shift("wall", _mouse01).x
	var tr := layer_transform("wall")
	var l := (tr * Vector2(minf(ChamberLayout.LIT.position.x, back.position.x - sh) + sh, 0.0)).x
	var r := (tr * Vector2(maxf(ChamberLayout.LIT.end.x, back.end.x - sh) + sh, 0.0)).x
	return Vector2(maxf(out.x, l), minf(out.y, r))


## The veil's alpha: opaque whenever the room has moved at all (its width is what grows from nothing).
func veil_alpha() -> float:
	return 1.0 if _depth() > 0.0 else 0.0


func veil_color() -> Color:
	return end_color(_focus_key)


## The dark sides a very wide window already shows at rest (beyond ChamberLayout.LIT, inside what veil_edges() leaves): covered too, in
## the same colour, at veil_soft_alpha(), which rises with the depth (so nothing pops at either end). x, y as veil_edges(); at 16:9 they
## lie inside the opaque veil and add nothing.
func veil_soft_edges() -> Vector2:
	var back := UiScale.backdrop(_ui) if _ui != null else ChamberLayout.FRAME
	var out := Vector2(back.position.x, back.end.x)
	if _depth() <= 0.0:
		return out
	var sh := ChamberLayout.shift("wall", _mouse01).x
	var tr := layer_transform("wall")
	var l := (tr * Vector2(ChamberLayout.LIT.position.x + sh, 0.0)).x
	var r := (tr * Vector2(ChamberLayout.LIT.end.x + sh, 0.0)).x
	return Vector2(clampf(l, out.x, out.y), clampf(r, out.x, out.y))


func veil_soft_alpha() -> float:
	var d := _depth()
	return 0.0 if d <= 0.0 else smoothstep(0.0, VEIL_SOFT_D, d)


func _draw_veil(back: Rect2) -> void:
	if veil_alpha() <= 0.0:
		return
	var v := veil_edges()
	var s := veil_soft_edges()
	var c := veil_color()
	var soft := Color(c.r, c.g, c.b, veil_soft_alpha())
	var clear := Color(c.r, c.g, c.b, 0.0)
	var ramp := VEIL_RAMP * _depth()
	var top := back.position.y
	var bottom := back.end.y
	# Left: opaque where nothing showed at rest, the soft part over the dark side a wide window showed, then a ramp into the room.
	if v.x > back.position.x:
		_room.draw_rect(Rect2(back.position.x, top, v.x - back.position.x, back.size.y), c)
	var inner := v.x
	var edge := c
	if s.x > v.x:
		_room.draw_rect(Rect2(v.x, top, s.x - v.x, back.size.y), soft)
		inner = s.x
		edge = soft
	if inner > back.position.x:
		_room.draw_polygon(PackedVector2Array([Vector2(inner, top), Vector2(inner + ramp, top), Vector2(inner + ramp, bottom), Vector2(inner, bottom)]),
			PackedColorArray([edge, clear, clear, edge]))
	if v.y < back.end.x:
		_room.draw_rect(Rect2(v.y, top, back.end.x - v.y, back.size.y), c)
	inner = v.y
	edge = c
	if s.y < v.y:
		_room.draw_rect(Rect2(s.y, top, v.y - s.y, back.size.y), soft)
		inner = s.y
		edge = soft
	if inner < back.end.x:
		_room.draw_polygon(PackedVector2Array([Vector2(inner - ramp, top), Vector2(inner, top), Vector2(inner, bottom), Vector2(inner - ramp, bottom)]),
			PackedColorArray([clear, edge, edge, clear]))


## The station's signature (step 8): 0 at rest; on a press one swell up to 1 at the end of the zoom (it starts with the anticipation);
## coming back it only fades, to 0 at rest.
func signature() -> float:
	match _mode:
		Mode.OUT:
			var s := clampf(_t / (CUE_TIME + OUT_TIME), 0.0, 1.0)
			return 1.0 - (1.0 - s) * (1.0 - s)
		Mode.BACK:
			var b := 1.0 - _u()
			return b * b
		Mode.HELD:
			return 1.0
	return 0.0


## What the signature draws now (ChamberSignature.pieces(): masks, blooms, embers), on the wall's layer.
func signature_pieces() -> Array:
	var f := signature()
	if f <= 0.0 or not ChamberLayout.STATIONS.has(_focus_key):
		return []
	return ChamberSignature.pieces(_focus_key, f, _t if _mode == Mode.OUT else -1.0)


## One step of a transition (public so tests drive it without the clock). The end of a zoom in sends the waiting action.
func advance(delta: float) -> void:
	if is_queued_for_deletion() or not in_transition() or _pose_held:
		return
	_t += delta
	if _mode == Mode.HELD:
		if _t >= HELD_TIME:
			_mode = Mode.REST  # Game did not replace the room (the action was refused): show the stations again
	elif _t >= (CUE_TIME + OUT_TIME if _mode == Mode.OUT else BACK_TIME):
		_finish()
	_redraw()


## Photographs only: show `key` hovered, the mouse ignored from now on.
func hold_hover(key: String) -> void:
	_hover = key
	_hover_held = true
	_redraw()


## Photographs only: hold the zoom into `key` (or back out of it) `t` seconds in (going in, the anticipation is the first CUE_TIME); nothing
## is sent.
func pose_transition(key: String, back: bool, t: float) -> void:
	_mode = Mode.BACK if back else Mode.OUT
	_focus_key = key
	_t = t
	_pending = ""
	_pose_held = true
	_redraw()


## Finishes a transition at once: a zoom in sends its action, a return is at rest.
func skip() -> void:
	if is_queued_for_deletion():
		return
	if _mode == Mode.OUT or _mode == Mode.BACK:
		_finish()
		_redraw()


func _finish() -> void:
	if _mode == Mode.BACK:
		_mode = Mode.REST
		return
	_mode = Mode.HELD
	_t = 0.0
	var what := _pending
	_pending = ""
	if what != "":
		action.emit(what)


## Where the zoom is centred: the station's focus point after its layer's parallax shift.
func _focus_point() -> Vector2:
	if not ChamberLayout.STATIONS.has(_focus_key):
		return ChamberLayout.FRAME.get_center()
	var s: Dictionary = ChamberLayout.STATIONS[_focus_key]
	return (s.focus as Vector2) + ChamberLayout.shift(s.layer, _mouse01)


## The Divine Power bar's words (see HubStatus.bar_text).
static func bar_text(slot: GodSlot) -> String:
	return HubStatus.bar_text(slot)


## The status lines (see HubStatus.lines).
func lines() -> PackedStringArray:
	return status.lines()


func can_descend() -> bool:
	return status.can_descend()


## The top bar's rect in frame coordinates: the screen's top edge (above the frame in a tall window), edge to edge, 22 units high.
func bar_rect() -> Rect2:
	var back := UiScale.backdrop(_ui)
	return Rect2(back.position.x, back.position.y, back.size.x, ChamberLayout.BAR_H)


## The Title button's rect, at the bar's right end.
func title_rect() -> Rect2:
	var bar := bar_rect()
	return Rect2(bar.end.x - TITLE_W - 4.0, bar.position.y + 3.0, TITLE_W, ChamberLayout.BAR_H - 6.0)


## The station's current rect ("descend", "tree", "faith", "awaken") with the parallax; the Title button's for "title"; empty for none.
func menu_rect(what: String) -> Rect2:
	if what == "title":
		return title_rect()
	if ChamberLayout.STATIONS.has(what):
		return ChamberLayout.rect_of(what, _mouse01)
	return Rect2()


## "", "hover", "dim" or "closed" for a station: the Rite Door is closed while the god is not capped; A Door that is not ready is dim (the table never is: the World Map it opens says why a night cannot be had); the hovered station is "hover".
func station_state(key: String) -> String:
	if key == "awaken" and not status.awaken_shown():
		return "closed"
	if key == "awaken" and status.awaken_dim():
		return "dim"
	return "hover" if key == _hover else ""


## The red "!" on a station: unspent points on the tree, Faith to spend at the altar, a rite ready (or the Hunt leading) at the door.
func badge(key: String) -> bool:
	match key:
		"tree": return _slot.points > 0
		"faith": return status.faith_affordable()
		"awaken": return status.awaken_shown() and not status.awaken_dim()
	return false


## The keys row: the Awaken key joins it while the door is open, else the dev hook is named under --dev.
func hint_text() -> String:
	var hint := "Enter: Descend   T: Tree   F: Faith   Esc: Title"
	if status.awaken_shown():
		hint += "   A: Awaken"
	elif dev:
		hint += "   DEV  A: awaken"
	return hint


## The station under a frame point; a closed door is skipped (no hover, no click).
func _station_at(point: Vector2) -> String:
	var key := ChamberLayout.at(point, _mouse01, bar_rect().position.y)
	if key == "awaken" and not status.awaken_shown():
		return ""
	return key


## A left click at a frame point: the Title button, or the station there.
func click(point: Vector2) -> void:
	if title_rect().has_point(point):
		_press("title")
		return
	var key := _station_at(point)
	if key != "":
		_press(key)


## Plays and sends what HubStatus decided for a press: a buzz, a click and the action, or the one-off line.
func _press(what: String, from_key := false) -> void:
	var result := status.press(what, from_key, dev)
	if result.buzz:
		UiSound.play(&"ui_buzz")
	elif result.emit != "":
		UiSound.play(&"ui_click")
	if result.line != "":
		line = result.line
		_redraw()
	if result.emit == "":
		return
	if is_instance_valid(_sound):
		_sound.leave()  # a page is opening: the room's bed fades with the zoom
	if transitions and ChamberLayout.STATIONS.has(result.emit):
		_mode = Mode.OUT
		_t = 0.0
		_focus_key = result.emit
		_pending = result.emit
		UiSound.play(WHOOSH)
		UiSound.play(STATION_CUES[result.emit])
		_redraw()
		return
	action.emit(result.emit)


func _redraw() -> void:
	_sync_canvas()
	if _ui != null:
		_ui.queue_redraw()
	if _room != null:
		_room.queue_redraw()


## The room's canvas: through pixel_aa with linear sampling while it moves, plain (no material, the project's nearest) at rest.
func _sync_canvas() -> void:
	if _room == null:
		return
	if in_transition():
		if _aa == null:
			_aa = ShaderMaterial.new()
			_aa.shader = PIXEL_AA
		_room.material = _aa
		_room.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		_room.material = null
		_room.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE


## The room's canvas item (tests and photographs).
func room_canvas() -> Control:
	return _room


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if in_transition():
		skip()
		return
	if event.physical_keycode == KEY_ESCAPE:
		_press("title")
		return
	var key := ChamberLayout.key_for(event.physical_keycode)
	if key == "":
		return
	if key == "awaken":
		# The A key is the dev hook and the "rite not written" line; the 4 key is the door and nothing else.
		if event.physical_keycode == KEY_A:
			_press("awaken", true)
		elif status.awaken_shown():
			_press("awaken")
		return
	_press(key)


## The blocker's mouse, in the blocker's units: converted to frame units (the same point the Design child would have reported).
func _on_blocker_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var e := event.duplicate() as InputEventMouse
	e.position = (event.position - _ui.position) / maxf(_ui.scale.x, 0.0001)
	_on_gui_input(e)


func _on_gui_input(event: InputEvent) -> void:
	if in_transition():
		if event is InputEventMouseButton and event.pressed:
			skip()
		return
	if _hover_held:
		return  # a photograph of a hover: the window's own mouse moves nothing
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_follow_mouse(event.position)
	if event is InputEventMouseMotion:
		var h := _station_at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


## Moves the parallax to follow the mouse (a frame point), and redraws when the room moved.
func _follow_mouse(point: Vector2) -> void:
	var back := UiScale.backdrop(_ui)
	var m := ((point - back.get_center()) / (back.size * 0.5)).clamp(Vector2(-1, -1), Vector2(1, 1))
	if m != _mouse01:
		_mouse01 = m
		_redraw()


# --- drawing -------------------------------------------------------------------------------------------------------------------------------

func _layer_rect(rect: Rect2, layer: String) -> Rect2:
	return Rect2(rect.position + ChamberLayout.shift(layer, _mouse01), rect.size)


func _draw_station(key: String) -> void:
	var state := station_state(key)
	if state == "hover":
		state = ""  # hovering lights the outline, not the picture
	var st: Dictionary = ChamberLayout.STATIONS[key]
	var at := menu_rect(key)
	if st.has("art"):  # the picture is larger than the rect that is clicked
		at = _layer_rect(st["art"], st["layer"])
	ChamberArt.draw(_room, key, at, state)


## The bar, the lines and the cover, over the room (which is drawn by its own canvas item, behind this one).
func _draw_ui() -> void:
	var back := UiScale.backdrop(_ui)
	_draw_bar()
	_draw_under_bar()
	_draw_bottom()
	if fade() > 0.0:
		_ui.draw_rect(back, fade_color())


func _draw_room_canvas() -> void:
	_draw_room(UiScale.backdrop(_ui))
	_room.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_room(back: Rect2) -> void:
	var c := _room
	c.draw_rect(back, ChamberArt.greybox_color("wall"))
	# Back to front: wall, the stations on the wall, the stations layer, the table with its station, the desk. Each layer is drawn with
	# its own camera transform (identity at rest; the depth dolly during a zoom).
	c.draw_set_transform_matrix(layer_transform("wall"))
	for piece: Dictionary in ChamberLayout.SCENERY:
		if piece.name == "wall":
			ChamberArt.draw(c, "wall", _layer_rect(piece.rect, piece.layer))
			# The value hierarchy (round 3): corners and ceiling a little darker, the stations left alone.
			_draw_piece("vignette", 1.0)
	for layer in ["wall", "stations", "table"]:
		c.draw_set_transform_matrix(layer_transform(layer))
		if layer == "table":
			for piece: Dictionary in ChamberLayout.SCENERY:
				if piece.name == "table":
					ChamberArt.draw(c, "table", _layer_rect(piece.rect, piece.layer))
		# The Rite Door first: the World Table stands in front of it, so the table's map is drawn over the door's dimmed or
		# put-out light, never darkened by it.
		for key: String in DRAW_ORDER:
			if ChamberLayout.STATIONS[key].layer == layer:
				_draw_station(key)
	c.draw_set_transform_matrix(layer_transform("wall"))
	var hover := hover_drawn()
	if not hover.is_empty():
		_draw_piece(hover.glow, HOVER_ALPHA, float(hover.tint))
	var life := _life.frame(life_t)
	_draw_life(life, "wall")
	if not hover.is_empty():
		_draw_piece(hover.rim, 1.0)
	for piece: Dictionary in ChamberLayout.SCENERY:
		if piece.name == "desk":
			c.draw_set_transform_matrix(layer_transform("desk"))
			# The desk is wider than the frame so a wide window still meets it; extend it to the backdrop's edges.
			var r := _layer_rect(piece.rect, piece.layer)
			var left := minf(r.position.x, back.position.x)
			var right := maxf(r.end.x, back.end.x)
			var at := Rect2(left, r.position.y, right - left, r.size.y)
			ChamberArt.draw(c, "desk", at)
			_draw_life(life, "desk", r, at)
	# The station's signature (step 8) rides the wall and lights over the desk too.
	c.draw_set_transform_matrix(layer_transform("wall"))
	_draw_life(signature_pieces(), "wall")
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_veil(back)
	if in_transition():
		return  # the name plate and the badges belong to the room at rest: they do not ride the zoom
	for key: String in ChamberLayout.ORDER:
		if _hover == key and station_state(key) != "closed":
			_draw_plate(key)
	for key: String in ChamberLayout.ORDER:
		if badge(key):
			_draw_badge(menu_rect(key))


## The room's life on one layer (ChamberLife.frame()), each piece moved by its layer's parallax. On the desk, a piece follows the desk
## from where it sits (`desk`, its layer rect) to where it is drawn (`at`): the same, except in a window so wide the desk is stretched.
func _draw_life(pieces: Array, layer: String, desk := Rect2(), at := Rect2()) -> void:
	var k := at.size.x / desk.size.x if desk.size.x > 0.0 else 1.0
	for p: Dictionary in pieces:
		if p.layer != layer:
			continue
		var r := ChamberLife.placed(p, _mouse01)
		if k != 1.0:
			r = Rect2(at.position.x + (r.position.x - desk.position.x) * k, r.position.y, r.size.x * k, r.size.y)
		var tex_name: String = p.tex
		if tex_name == "":
			var c: Color = p.color
			if p.get("kind", "") == "bloom":
				_room.draw_texture_rect(ChamberSignature.bloom_texture(), r, false, Color(c.r, c.g, c.b, c.a * float(p.alpha)))
			else:
				_room.draw_rect(r, Color(c.r, c.g, c.b, c.a * float(p.alpha)))
			continue
		var tex := ChamberArt.texture(ChamberLife.DIR + tex_name)
		if tex == null:
			continue  # a missing mask or patch: that source is skipped
		var mod := Color(1.0, 1.0, 1.0, float(p.alpha))
		if p.has("src"):
			_room.draw_texture_rect_region(tex, r, p.src, mod)
		else:
			_room.draw_texture_rect(tex, r, false, mod)


## A file of the life pass drawn whole at its room rect on its layer, `tint` darkening its colour (a dim station's hover).
func _draw_piece(name: String, alpha: float, tint := 1.0) -> void:
	var tex := ChamberArt.texture(ChamberLife.DIR + name)
	if tex == null or not ChamberLife.FILES.has(name):
		return
	var r := ChamberLife.placed(ChamberLife.FILES[name], _mouse01)
	_room.draw_texture_rect(tex, r, false, Color(tint, tint, tint, alpha))


## What hovering `key` draws (round 3): {"glow": its brightened picture, "rim": its warm rim, "tint": 1, or ChamberArt.DIM for a dim
## door}; {} for a closed door.
func hover_art(key: String) -> Dictionary:
	if not ChamberLayout.STATIONS.has(key):
		return {}
	var state := "dim" if key == "awaken" and status.awaken_dim() else ""
	if key == "awaken" and not status.awaken_shown():
		return {}
	return {"glow": "hover_" + key, "rim": "rim_" + key, "tint": ChamberArt.DIM if state == "dim" else 1.0}


## What the hover draws now: hover_art() of the hovered station, or {}.
func hover_drawn() -> Dictionary:
	return hover_art(_hover) if _hover != "" else {}


## The name plate under a hovered station.
func plate_rect(key: String) -> Rect2:
	var r := menu_rect(key)
	var label: String = ChamberLayout.STATIONS[key].name
	var w := UiTheme.width(label, UiTheme.SIZE_SMALL) + 10.0
	return Rect2(roundf(r.get_center().x - w * 0.5), r.end.y + 3.0, w, 15.0)


func _draw_plate(key: String) -> void:
	var plate := plate_rect(key)
	_room.draw_rect(plate, Color(0.02, 0.02, 0.03, 0.85))
	UiTheme.text(_room, Vector2(plate.position.x + 5.0, plate.position.y + 12.0), ChamberLayout.STATIONS[key].name, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)


func _draw_badge(r: Rect2) -> void:
	var c := Vector2(r.end.x, r.position.y)
	_room.draw_circle(c, 6.0, UiTheme.COL_BAD)
	UiTheme.text(_room, c + Vector2(-2.0, 4.0), "!", UiTheme.SIZE_SMALL, Color.WHITE)


## Where the bar's parts sit, in the bar's own coordinates: text rects for the town, the Night, the Faith and the points, the Notice's
## meter with its percent, the Divine Power bar, and the baseline `y`. Built from the Title button leftwards: Night, the town (World Map +
## Conquer Progress), the Notice meter and percent, Faith, ability points; the Divine Power bar sits in what is left.
func _bar_layout() -> Dictionary:
	var bar := bar_rect()
	var text := lines()
	var y := bar.position.y + 15.0
	var left_x := bar.position.x + 6.0
	var title_w := UiTheme.width(text[0], UiTheme.SIZE_SMALL)
	var x := left_x + title_w + 8.0
	var left_end := x + UiTheme.width(text[1], UiTheme.SIZE_SMALL)
	var tr := title_rect()
	var rx := tr.position.x - BAR_GAP
	var out := {"y": y, "left_x": left_x, "level_x": x, "left_end": left_end}
	var night: String = text[6]
	rx -= UiTheme.width(night, UiTheme.SIZE_SMALL)
	out.night_text = night
	out.night_x = rx
	out.night = _text_rect(rx, UiTheme.width(night, UiTheme.SIZE_SMALL), bar)
	rx -= BAR_GAP
	var town := status.town_line()
	rx -= UiTheme.width(town, UiTheme.SIZE_SMALL)
	out.town_text = town
	out.town_x = rx
	out.town = _text_rect(rx, UiTheme.width(town, UiTheme.SIZE_SMALL), bar)
	rx -= BAR_GAP
	var pct := "%d%%" % _slot.notice
	rx -= UiTheme.width(pct, UiTheme.SIZE_SMALL)
	out.pct_text = pct
	out.pct_x = rx
	var meter := Rect2(rx - 3.0 - NOTICE_W, bar.position.y + 8.0, NOTICE_W, 6.0)
	out.meter = meter
	out.notice = Rect2(meter.position.x, bar.position.y + 4.0, rx + UiTheme.width(pct, UiTheme.SIZE_SMALL) - meter.position.x, 14.0)
	rx = meter.position.x - BAR_GAP
	var faith := "Faith %d" % _slot.faith
	rx -= UiTheme.width(faith, UiTheme.SIZE_SMALL)
	out.faith_text = faith
	out.faith_x = rx
	out.faith = _text_rect(rx, UiTheme.width(faith, UiTheme.SIZE_SMALL), bar)
	rx -= BAR_GAP
	var pts := "Points %d" % _slot.points
	rx -= UiTheme.width(pts, UiTheme.SIZE_SMALL)
	out.pts_text = pts
	out.pts_x = rx
	out.points = _text_rect(rx, UiTheme.width(pts, UiTheme.SIZE_SMALL), bar)
	# Centre: the Divine Power bar, centred on the area and kept clear of the left and right groups.
	var lo := left_end + BAR_GAP
	var hi := rx - BAR_GAP
	var w := maxf(0.0, minf(150.0, hi - lo))
	var cx := clampf(bar.get_center().x, lo + w * 0.5, hi - w * 0.5)
	out.power = Rect2(roundf(cx - w * 0.5), bar.position.y + 6.0, roundf(w), 10.0)
	return out


func _text_rect(x: float, w: float, bar: Rect2) -> Rect2:
	return Rect2(x, bar.position.y + 4.0, w, 14.0)


## The rects the bar's parts take ("town", "night", "notice", "faith", "points", "power"), so a test can see they stay inside the bar and
## clear of each other.
func bar_parts() -> Dictionary:
	var l := _bar_layout()
	return {"town": l.town, "night": l.night, "notice": l.notice, "faith": l.faith, "points": l.points, "power": l.power}


func _draw_bar() -> void:
	var bar := bar_rect()
	_ui.draw_rect(bar, Color(0.03, 0.03, 0.05, 0.92))
	_ui.draw_rect(Rect2(bar.position.x, bar.end.y, bar.size.x, 1.0), UiTheme.COL_GOLD_DARK)
	var text := lines()
	var l := _bar_layout()
	var y: float = l.y
	# Left: the type's title, then the level and the tier's name.
	UiTheme.text(_ui, Vector2(l.left_x, y), text[0], UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(l.level_x, y), text[1], UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	var tr := title_rect()
	_ui.draw_rect(tr, Color(0.10, 0.09, 0.07, 0.95))
	UiTheme.frame(_ui, tr, false)
	UiTheme.text(_ui, Vector2(roundf(tr.get_center().x - UiTheme.width("Title", UiTheme.SIZE_SMALL) * 0.5), y - 1.0), "Title", UiTheme.SIZE_SMALL,
		UiTheme.COL_TEXT)
	UiTheme.text(_ui, Vector2(l.night_x, y), l.night_text, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	UiTheme.text(_ui, Vector2(l.town_x, y), l.town_text, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(l.pct_x, y), l.pct_text, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	var meter: Rect2 = l.meter
	_ui.draw_rect(meter, Color(0.10, 0.04, 0.04, 0.9))
	_ui.draw_rect(Rect2(meter.position, Vector2(roundf(meter.size.x * status.notice_fill()), meter.size.y)), UiTheme.COL_BAD)
	UiTheme.frame(_ui, meter, false)
	UiTheme.text(_ui, Vector2(l.faith_x, y), l.faith_text, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	UiTheme.text(_ui, Vector2(l.pts_x, y), l.pts_text, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if _slot.points > 0 else UiTheme.COL_TEXT)
	var pr: Rect2 = l.power
	_ui.draw_rect(pr, Color(0.04, 0.04, 0.06, 0.85))
	_ui.draw_rect(Rect2(pr.position, Vector2(roundf(pr.size.x * status.bar_fill()), pr.size.y)), UiTheme.COL_GOLD_DARK)
	UiTheme.frame(_ui, pr, false)
	var bt := UiTheme.fit(text[2], pr.size.x - 4.0, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(roundf(pr.get_center().x - UiTheme.width(bt, UiTheme.SIZE_SMALL) * 0.5), pr.position.y + 9.0), bt, UiTheme.SIZE_SMALL,
		UiTheme.COL_TEXT)


## The baseline of the i-th line under the bar (the Hunt line, then the seal line).
func under_bar_baseline(i: int) -> float:
	return bar_rect().end.y + 14.0 + UiTheme.LINE_BODY * float(i)


## One centred line on a dark plate, so it reads over the painted room (the desk's papers sit under the bottom lines).
func _centred(text: String, baseline: float, size: int, col: Color) -> void:
	var w := UiTheme.width(text, size)
	var x := roundf(320.0 - w * 0.5)
	_ui.draw_rect(Rect2(x - 5.0, baseline - 10.0, w + 10.0, 14.0), Color(0.03, 0.03, 0.05, 0.78))
	UiTheme.text(_ui, Vector2(x, baseline), text, size, col)


## The Hunt and the seal, in red, centred under the bar.
func _draw_under_bar() -> void:
	var i := 0
	for s: String in [status.hunt_line(), status.seal_line()]:
		if s != "":
			_centred(s, under_bar_baseline(i), UiTheme.SIZE_BODY, UiTheme.COL_BAD_TEXT)
			i += 1


## Baselines of the stack above the keys hint, bottom up: the blocked line, the stolen gifts, the one-off line's last row.
func _stack() -> Dictionary:
	var y := HINT_Y - STACK_GAP
	var out := {}
	out.blocked = y
	if status.blocked_line() != "":
		y -= 14.0
	out.gifts = y
	if status.gifts_line() != "":
		y -= UiTheme.LINE_BODY
	out.line = y
	return out


## The bottom block, stacked upward from the keys hint: the blocked line, the stolen gifts, the one-off line (wrapped to 600).
func _draw_bottom() -> void:
	var hint := hint_text()
	var strip := hint_strip_rect()
	_ui.draw_rect(strip, HINT_STRIP)
	_ui.draw_rect(Rect2(strip.position.x, strip.position.y, strip.size.x, 1.0), HINT_EDGE)
	_ui.draw_rect(Rect2(strip.position.x, strip.end.y - 1.0, strip.size.x, 1.0), Color(0.0, 0.0, 0.0, 0.35))
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), HINT_Y), hint, UiTheme.SIZE_SMALL, HINT_INK)
	var at := _stack()
	var blocked := status.blocked_line()
	if blocked != "":
		_centred(blocked, at.blocked, UiTheme.SIZE_SMALL, UiTheme.COL_BAD_TEXT)
	var gifts := status.gifts_line()
	if gifts != "":
		_centred(gifts, at.gifts, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	if line != "":
		var wrapped := UiTheme.wrap(line, LINE_WIDTH, UiTheme.SIZE_BODY)
		var y: float = at.line
		for i in range(wrapped.size() - 1, -1, -1):
			_centred(wrapped[i], y, UiTheme.SIZE_BODY, UiTheme.COL_BAD_TEXT)
			y -= UiTheme.LINE_BODY


## The keys hint's strip (round 3): a band of dark parchment across the desk, the backdrop's width, round the hint's row.
func hint_strip_rect() -> Rect2:
	var back := UiScale.backdrop(_ui)
	return Rect2(back.position.x, HINT_Y - 11.0, back.size.x, HINT_STRIP_H)


## The baseline of the one-off line's last row (a test checks it against the hint).
func one_off_baseline() -> float:
	return _stack().line
