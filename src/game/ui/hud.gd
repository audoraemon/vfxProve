class_name Hud
extends Control
## The in-mission HUD (spec §5): the clock above, the objectives to the left, the city's state to the right,
## banners across the middle, Cael's lines (v0.10 M5, spec §5.2: what a Night 2 director has him say) on a plate of their
## own under them, and the slots below (v0.08: no Divine Power bar -- none is spent in a mission). A mission
## without a score (v0.08: The Warning) lists its objectives top left. It reads Rules, Crowd and the Citadel and
## changes nothing; it redraws only when what it shows has changed. v0.10 M6 adds the objective's
## clarity: the director's tags (a labelled diamond over each person or place worth finding, or an arrow at the screen's
## edge, kept to a frame; drawn first, under the HUD's own panels), the how-to-win plate under the objectives, and the
## intro tour's caption above the slots.

## How long one banner stays up.
const BANNER_SECONDS := 2.2
## Cael's lines (v0.10 M5, spec §5.2): how long one stays up (longer than a banner: it is a sentence to read), the top of
## its plate (just under the banner's bar, 116 to 136), and the gap between his name and the line.
const SUBTITLE_SECONDS := 4.0
const SUBTITLE_TOP := 140.0
const SUBTITLE_GAP := 6.0
## A slot that refused a cast stays red for this long (spec §1; the buzz that goes with it is milestone 5's).
const FLASH_SECONDS := 0.35
## The clock turns red and pulses under this many seconds (spec §5).
const HURRY_AT := 30.0

const SLOT_SIZE := 42.0
const SLOT_GAP := 4.0
## A slot is a compact card (v0.08: six fit across the screen): the SLOT_SIZE icon on the left, and beside it the
## power's name on one line, cut to NAME_ROOM, over its cooldown. Six make a 620-px row inside 640.
const SLOT_W := 100.0
## How wide the name may run beside the icon, short of the card's right edge.
const NAME_ROOM := SLOT_W - SLOT_SIZE - 6.0
## The screen width to lay out against before the Control has been sized (headless tests).
const SCREEN_W := 640.0
## Where the slot row sits: low, where the Divine Power bar was before v0.08.
const SLOT_TOP := 316.0
const STABILITY_BAR := Vector2(96.0, 5.0)
## The objectives, top left: sized for four lines of SIZE_SMALL text.
const OBJECTIVE_PANEL := Rect2(2.0, 2.0, 236.0, 60.0)
## The stability bar's legend: a short name for each part and its colour's index, in the bar's own order.
const LEGEND := [["Pop", 0], ["Infra", 1], ["Lead", 2], ["Mil", 3], ["Res", 4]]
## The dark plate under a slot's hotkey.
const PLATE_H := 12.0
## The Banishing Rite's bar under the clock (v0.05).
const RITE_BAR := Vector2(120.0, 4.0)
const RITE_TOP := 30.0
## The act's next timed events (v0.09), centred under the clock and the rite's bar: one line each.
const EVENTS_TOP := 44.0
## Halcyon's Gaze under the clock (v0.10), where the Banishing Rite's bar would sit (an Unaware town has no rite).
const GAZE_BAR := Vector2(120.0, 4.0)
const GAZE_TOP := 30.0
## A tag's diamond (v0.10's marks; M6's tags, MapTag): its half size unless the tag sets its own, and its dark edge (M5
## doubled it and gave it an edge, so it reads on the cobbles). Tags are drawn first, under the rest of the HUD, and their
## edge arrows right after them, also under the HUD's panels.
const MARK_R := 4.0
const MARK_EDGE := Color(0.04, 0.04, 0.06, 0.9)
## A tag's label (v0.10 M6) stands this far above its diamond; an edge arrow's label starts this far in from its tip, past
## the arrow's disc.
const LABEL_GAP := 2.0
const ARROW_REACH := 17.0
## The screen height to lay out against before the Control has been sized (headless tests).
const SCREEN_H := 360.0
## A mission without a score (v0.08: The Warning) lists its objectives top left instead, one row this tall each.
const ROW_H := 13.0
## How far in from the screen's sides the tags' arrows keep.
const EDGE_MARGIN := 10.0
## The tags' arrows keep to a frame (v0.10 M6): EDGE_MARGIN in from the screen's sides, below the clock, the Gaze bar and the
## events plate (TAG_TOP, clear of a two-row plate, which ends at 71, and of an up arrow's disc, 5 px above its tip) and just
## above the slot row, so a tag under any of them is pointed at, and no arrow is covered.
const TAG_TOP := 78.0
## How to win (v0.10 M6, spec §3): a line under the objectives, wrapped to HINT_W, at most HINT_LINES lines, pale gold.
const HINT_W := 228.0
const HINT_LINES := 3
const HINT_COL := Color("e8d690")
## The tour's caption (v0.10 M6, spec §5): its plate's top, above the slot row (SLOT_TOP), and the word under it.
const CAPTION_TOP := 262.0
const SKIP_TEXT := "SPACE TO SKIP"
## The wishes (v0.11 M1, spec §5.2): a row each under the how-to-win plate, ROW_H tall, with an open box (WISH_BOX square), a
## tick once granted, or a cross and the words struck through once failed.
const WISH_BOX := 7.0
## The ASCEND plate (spec §6): centred above the slot row, clear of a focused power's modes; its word and its key.
const ASCEND_SIZE := Vector2(96.0, 20.0)
const ASCEND_TOP := 272.0
const ASCEND_TEXT := "ASCEND"
const ASCEND_KEY := "F"
## The town prays (spec §5.1): the plate over the wishes heard during the night's first intro, its top and its title.
const PRAYERS_TOP := 166.0
const PRAYERS_TITLE := "THE TOWN PRAYS..."
## The ascent (spec §6): a pale gold column rising over the god's last cast spot for RISE_SECONDS of real time.
const RISE_SECONDS := 2.0
const RISE_COL := Color(1.0, 0.93, 0.7)
## How near a click must come to a waiting wish's tag to engage it (spec §5.2).
const ENGAGE_PX := 8.0

var _rules: Rules
var _crowd: Crowd
var _town: Town
var _aim: Targeting
## Banners waiting their turn: [text, seconds shown].
var _banners: Array = []
## Cael's lines waiting their turn (v0.10 M5): [text, seconds shown].
var _subtitles: Array = []
## Seconds of red left per slot, for the refused-cast flash.
var _flash := PackedFloat32Array()
## What the last frame drew, so an unchanged HUD costs nothing.
var _drawn := ""
## The slot icons, taken once. PowerBook.hud_icon() goes through load(), and a texture asked for during
## _draw() can reach the draw list before the GPU has it -- which paints a solid white block, and because the
## HUD only redraws when something changes, the block stays white for the rest of the mission.
var _slot_icons: Array[Texture2D] = []
## The powers' names, cut to one line of NAME_ROOM, taken once with their icons.
var _slot_names: Array[String] = []
## The tags' layout for the frame being drawn (v0.10 M6, tag_layout()): placed by _draw_tags() and shared with
## _draw_tag_arrows(), so the arrows' labels keep clear of the map's.
var _layout: Array = []
## The tour's caption on screen (v0.10 M6); "" for none.
var _caption := ""
## The tags' own layer (board tags): a child drawn behind the HUD, so the tags under its panels can follow the camera
## every frame while the rest of the HUD stays a still picture (a whole-HUD redraw a frame cost Last Judgement, which
## always tags its Citadel, ~0.7 ms). It redraws only when what it shows has changed (_tag_signature()).
var _tag_layer: Control
var _tags_drawn := ""
## What the drawing helpers draw on: the HUD, or the tag layer while it draws (_draw_tag_layer()).
var _canvas: CanvasItem = self
## The night's first intro is up (v0.11 M1): Mission sets it, and the prayers plate shows the wishes heard.
var praying := false
## The ascent's column (v0.11 M1): its ground point (Vector2.INF for none) and its real seconds so far.
var _rise_at := Vector2.INF
var _rise_age := 0.0


func setup(rules: Rules, crowd: Crowd, town: Town, aim: Targeting) -> Hud:
	_rules = rules
	_crowd = crowd
	_town = town
	_aim = aim
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # the player is aiming at the town, not clicking the HUD
	_flash.resize(_rules.loadout.size())
	_flash.fill(0.0)
	_slot_icons.clear()
	for i in _rules.loadout.size():
		_slot_icons.append(PowerBook.hud_icon(_rules.key(i)))
	_slot_names.clear()
	for i in _rules.loadout.size():
		_slot_names.append(UiTheme.fit(String(_rules.power(i).get("name", "")), NAME_ROOM))
	_rules.banner.connect(push_banner)
	_rules.subtitle.connect(push_subtitle)
	_rules.cast_refused.connect(_on_cast_refused)
	if _tag_layer == null:
		_tag_layer = Control.new()
		_tag_layer.name = "Tags"
		_tag_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tag_layer.show_behind_parent = true  # under every panel of the HUD, as the tags were drawn first
		_tag_layer.draw.connect(_draw_tag_layer)
		add_child(_tag_layer)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Age the banners and Cael's lines, and redraw when anything on screen has changed.
func advance(delta: float) -> void:
	_age(_banners, delta, BANNER_SECONDS)
	_age(_subtitles, delta, SUBTITLE_SECONDS)
	if _rise_at != Vector2.INF:
		_rise_age += delta / maxf(Engine.time_scale, 0.001)  # real seconds, through the ascent's slow motion
	var flashing := false
	for i in _flash.size():
		_flash[i] = maxf(0.0, _flash[i] - delta)
		flashing = flashing or _flash[i] > 0.0
	# The tags follow their people and the camera (v0.10 M6): their own layer redraws whenever a tag or the camera has
	# changed, and once more as the last goes (board tags).
	var tags_now := _tag_signature()
	if tags_now != _tags_drawn and _tag_layer != null:
		_tags_drawn = tags_now
		_tag_layer.queue_redraw()
	# Banners and Cael's lines fade, a refused slot burns red and the last half minute pulses: while any of those is on
	# screen the HUD is an animation and redraws every frame. The rest of the time it is a still picture.
	if flashing or not _banners.is_empty() or not _subtitles.is_empty() or _rules.time_left <= HURRY_AT or rising():
		_drawn = ""
		queue_redraw()
		return
	var now := _signature()
	if now != _drawn:
		_drawn = now
		queue_redraw()


## Ages the one on screen of a queue of [text, seconds shown] and lets go of those whose time is up. Only the one on screen
## (index 0, the only one drawn) ages: one waiting behind it must not lose part of its own showing to the time it spent
## queued.
static func _age(queue: Array, delta: float, seconds: float) -> void:
	if not queue.is_empty():
		queue[0][1] += delta
	while not queue.is_empty() and float(queue[0][1]) >= seconds:
		queue.pop_front()


## "Destroy the Royal Citadel - 60% left", the spec's objective line.
func objective_text() -> String:
	var left := 0.0
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		left = _town.citadel.fraction()
	return "Destroy the Royal Citadel - %d%% left" % roundi(left * 100.0)


## The objective panel of a mission without a score (v0.08), as [text, mark] rows: each primary objective with a line
## to show (mark ""), then each bonus -- "ok" while it holds, "x" once it has failed.
func objective_rows() -> Array:
	var rows := []
	for o in _rules.objectives:
		var s := o.hud_text(_rules)
		if s != "":
			rows.append([s, ""])
	for b in _rules.bonuses:
		rows.append([b.hud_text(_rules), "x" if b.check(_rules) == Objective.Status.FAILED else "ok"])
	return rows


## The act's next two timed events (v0.09) as [clock, label] rows, e.g. ["0:23", "The bonfire lights"]; empty for a
## mission whose director keeps no timeline.
func event_rows() -> Array:
	var rows := []
	if _rules.director == null or _rules.director.timeline == null:
		return rows
	for e: Dictionary in _rules.director.timeline.upcoming(2):
		rows.append([UiTheme.clock(float(e["in"])), String(e["label"])])
	return rows


## The how-to-win line for the mission or act being played, in its director's phase (v0.10 M6, MissionHints); once a board
## night's main objective is done (v0.11 M1, spec §6), the open wishes' or the ascent's; "" for none.
func hint_text() -> String:
	if _rules == null or _rules.mission == null:
		return ""
	if _rules.main_done:
		return MissionHints.WISHES_LINE if _open_wishes() else MissionHints.ASCEND_LINE
	return MissionHints.line(_rules.mission.id, _rules.director.hint_phase() if _rules.director != null else "")


## A wish of the night is still open (v0.11 M1).
func _open_wishes() -> bool:
	if _rules.descent == null:
		return false
	for w in _rules.descent.wishes:
		if w.status == Objective.Status.PENDING:
			return true
	return false


## The how-to-win line as drawn (v0.10 M6): wrapped to HINT_W, at most HINT_LINES lines; none for no line.
static func hint_lines(text: String) -> PackedStringArray:
	if text == "":
		return PackedStringArray()
	return UiTheme.wrap(text, HINT_W, UiTheme.SIZE_SMALL).slice(0, HINT_LINES)


## How wide the how-to-win plate is as drawn (v0.10 M6): its widest line plus the plate's padding; 0 for no lines.
static func hint_width(lines: PackedStringArray) -> float:
	if lines.is_empty():
		return 0.0
	var wide := 0.0
	for l in lines:
		wide = maxf(wide, UiTheme.width(l, UiTheme.SIZE_SMALL))
	return wide + 10.0


## The events plate's rectangle on a screen `w` wide (v0.10 M6; factored out of _draw_events() so the how-to-win plate can
## keep clear of it): centred under the clock, `Rect2()` when it has no rows.
func events_rect(w: float) -> Rect2:
	var rows := event_rows()
	if rows.is_empty():
		return Rect2()
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]) + "  " + String(row[1]), UiTheme.SIZE_SMALL))
	# The plate starts 4 px above EVENTS_TOP, just under the rite's plate (which ends at 39 while it chants).
	return Rect2(roundf((w - wide) * 0.5) - 4.0, EVENTS_TOP - 4.0, wide + 8.0, 5.0 + ROW_H * float(rows.size()))


## Where the how-to-win plate starts (v0.10 M6): under the objective panel of a scored mission, else under the objective
## rows (at the top with none) -- and, when that would run it into the events plate (the events plate's left edge short
## of this plate's right edge, the two sharing some height, a 4 px margin counted), 4 px below the events plate instead.
## Read only, from the same data _draw() uses.
func hint_top() -> float:
	var top := OBJECTIVE_PANEL.end.y + 4.0
	if not _rules.mission.scored:
		var rows := objective_rows().size()
		top = 2.0 + (5.0 + ROW_H * float(rows) + 4.0 if rows > 0 else 0.0)
	var lines := hint_lines(hint_text())
	var events := events_rect(_view().x)
	if lines.is_empty() or events.size == Vector2.ZERO:
		return top
	var high := top + 5.0 + UiTheme.LINE_SMALL * float(lines.size())
	if events.position.x < 2.0 + hint_width(lines) and top - 4.0 < events.end.y and high + 4.0 > events.position.y:
		return events.end.y + 4.0
	return top


## Where the how-to-win plate is drawn (v0.10 M6); `Rect2()` for no line.
func hint_rect() -> Rect2:
	var lines := hint_lines(hint_text())
	if lines.is_empty():
		return Rect2()
	return Rect2(2.0, hint_top(), hint_width(lines), 5.0 + UiTheme.LINE_SMALL * float(lines.size()))


## The wishes heard (v0.11 M1, spec §5.2) as [text, state] rows, state "open", "granted" or "failed"; none off the board.
func wish_rows() -> Array:
	var rows := []
	if _rules == null or _rules.descent == null:
		return rows
	for w in _rules.descent.wishes:
		rows.append([w.hud_text(_rules), Wish.state_name(w.status)])
	return rows


## Where the wishes' rows start (v0.11 M1): under the how-to-win plate, or where it would be with no line.
func wishes_top() -> float:
	var hint := hint_rect()
	return hint.end.y + 4.0 if hint.size != Vector2.ZERO else hint_top()


## The ASCEND plate is up (spec §6): a board night's main objective done, the night not over.
func ascend_shown() -> bool:
	return _rules != null and _rules.descent != null and _rules.main_done and not _rules.finished


func ascend_rect() -> Rect2:
	return Rect2(roundf((_view().x - ASCEND_SIZE.x) * 0.5), ASCEND_TOP, ASCEND_SIZE.x, ASCEND_SIZE.y)


## Everything on the map's tag layer (v0.11 M1): the director's tags, then the wishes' (spec §5.1), so a crowded view keeps
## the mission's own labels.
func all_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if _rules == null:
		return out
	if _rules.director != null:
		out.append_array(_rules.director.tags())
	if _rules.descent != null:
		out.append_array(_rules.descent.tags())
	return out


## The waiting timed wish whose tag is within ENGAGE_PX of the screen point `point` (spec §5.2: clicking its tag engages it),
## as its index among the night's wishes; -1 for none.
func wish_at(point: Vector2) -> int:
	if _rules == null or _rules.descent == null:
		return -1
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var wishes := _rules.descent.wishes
	for i in wishes.size():
		if not wishes[i].waiting():
			continue
		for tag in wishes[i].tags():
			if tag.valid() and tag_point(tag, xf).distance_to(point) <= ENGAGE_PX:
				return i
	return -1


## The ascent begins (v0.11 M1, spec §6): a column of light over the ground point `at`.
func rise(at: Vector2) -> void:
	_rise_at = at
	_rise_age = 0.0


func rising() -> bool:
	return _rise_at != Vector2.INF and _rise_age < RISE_SECONDS


## The Gaze bar shows (v0.11 M1): the director keeps a Gaze, and the Banishing Rite is not showing in its place (review
## focus 1: a Tier 5 town has the rite, and both sit under the clock).
func gaze_bar_shown() -> bool:
	return gaze_of(_rules) >= 0.0 and rite_text() == ""


## "Gaze 12%" for a scored mission's panel (v0.11 M1: Tier 5's Gaze in Last Judgement and Act III); "" with no Gaze.
func gaze_readout() -> String:
	var f := gaze_of(_rules)
	return "" if f < 0.0 else "Gaze %d%%" % roundi(f * 100.0)


## The escapes that lose this act (v0.09): its EscapeLimitObjective's limit (Act III's is the night's own, lower when
## the Prince escaped), else the single missions' 50.
func escape_limit() -> int:
	for o in _rules.objectives:
		if o is EscapeLimitObjective:
			return (o as EscapeLimitObjective).limit
	return Rules.ESCAPE_LIMIT


## Something is tagged (v0.10 M6; v0.11 M1 the wishes too): the tags follow people and the camera, so their layer redraws.
static func tags_shown(rules: Rules) -> bool:
	if rules == null:
		return false
	if rules.director != null and not rules.director.tags().is_empty():
		return true
	return rules.descent != null and not rules.descent.tags().is_empty()


## How full Halcyon's Gaze is (v0.10), or -1.0 when the mission's director keeps none.
static func gaze_of(rules: Rules) -> float:
	if rules == null or rules.director == null or rules.director.gaze == null:
		return -1.0
	return rules.director.gaze.fraction()


func _draw_gaze(w: float) -> void:
	var f := gaze_of(_rules)
	if not gaze_bar_shown():
		return
	var at := Vector2(roundf((w - GAZE_BAR.x) * 0.5), GAZE_TOP)
	draw_rect(Rect2(at, GAZE_BAR), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(at, Vector2(roundf(GAZE_BAR.x * f), GAZE_BAR.y)), UiTheme.COL_GOLD.lerp(UiTheme.COL_BAD, f))


## The tags on the map (v0.10 M6, spec §2.3): each one's footprint outline and, while on screen, its diamond, then the
## labels kept for them, after every diamond so that no tag's diamond or outline hides another's label. Lays the frame's
## tags out first (tag_layout()).
func _draw_tags() -> void:
	_layout = []
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	_layout = tag_layout(all_tags(), xf, _view())
	# Outlines and diamonds first, then the labels over them all, so no later tag's diamond hides a label kept for an
	# earlier one.
	for e: Dictionary in _layout:
		var t: MapTag = e.tag
		if t.outline.has_area():
			_draw_outline(t.outline, xf, t.color)
		if String(e.mode) == "map":
			var shape := mark_shape(e.c, t.size)
			_canvas.draw_colored_polygon(shape, t.color)
			shape.append(shape[0])
			_canvas.draw_polyline(shape, MARK_EDGE, 1.0)
	for e: Dictionary in _layout:
		if String(e.mode) == "map" and bool(e.show):
			var t: MapTag = e.tag
			_plate((e.label as Rect2).position, t.label, t.color)


## The tags outside the frame (v0.10 M6): an arrow at the frame's edge for each, its label beside it. Every arrow first, then
## every shown label, so no arrow's disc clips a label. Drawn straight after the tags, under the HUD's panels, so the
## objectives, the hint and the status stay readable (their plates are translucent: an arrow behind one shows through).
func _draw_tag_arrows() -> void:
	for e: Dictionary in _layout:
		if String(e.mode) == "arrow":
			var t: MapTag = e.tag
			_draw_arrow(e.arrow, e.dir, t.color, t.color.darkened(0.4))
	for e: Dictionary in _layout:
		if String(e.mode) == "arrow" and bool(e.show):
			var t: MapTag = e.tag
			_plate((e.label as Rect2).position, t.label, t.color)


## A ground footprint's outline (v0.10 M6): its diamond on the ground, through the camera `xf`, 1 px in `col`.
func _draw_outline(r: Rect2, xf: Transform2D, col: Color) -> void:
	var pts := PackedVector2Array()
	for g: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]:
		pts.append((xf * Iso.ground_to_screen(g)).round())
	_canvas.draw_polyline(pts, col, 1.0)


## The diamond a tag is drawn as, centred on `c` (screen pixels), `r` each way.
static func mark_shape(c: Vector2, r := MARK_R) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0.0, -r), c + Vector2(r, 0.0), c + Vector2(0.0, r), c + Vector2(-r, 0.0)])


## Where a tag's diamond sits on screen (v0.10 M6): its ground point raised `rise` world pixels, through the camera `xf`,
## then `lift` screen pixels up.
static func tag_point(t: MapTag, xf: Transform2D) -> Vector2:
	return (xf * (Iso.ground_to_screen(t.at) - Vector2(0.0, t.rise)) - Vector2(0.0, t.lift)).round()


## The frame the tags' arrows keep to on a screen `view` wide and tall (v0.10 M6).
static func tag_frame(view: Vector2) -> Rect2:
	var bottom := minf(SLOT_TOP, view.y) - 4.0
	return Rect2(EDGE_MARGIN, TAG_TOP, view.x - 2.0 * EDGE_MARGIN, maxf(bottom - TAG_TOP, 1.0))


## A label's plate (v0.10 M6): its words' width and a pixel each side, PLATE_H tall -- the one measure tag_layout() and
## _plate() share, so a plate is drawn exactly where the layout placed it.
static func plate_size(text: String) -> Vector2:
	return Vector2(UiTheme.width(text, UiTheme.SIZE_SMALL) + 2.0, PLATE_H)


## A label's plate (v0.10 M6): as wide as its words, PLATE_H tall, centred on `centre` and kept inside the screen.
static func label_rect(text: String, centre: Vector2, view: Vector2) -> Rect2:
	var box := plate_size(text)
	var at := (centre - box * 0.5).round()
	return Rect2(at.clamp(Vector2.ZERO, (view - box).max(Vector2.ZERO)), box)


## Where each tag goes this frame (v0.10 M6, spec §2.3), in the tags' order, as {tag, c, mode, arrow, dir, label, show}.
## - `c`: its diamond's centre on screen.
## - `mode`: "map" for its diamond where it is -- anywhere inside the screen for a tag without `edge`, and inside
##   tag_frame() for one with it; "arrow" for a tag with `edge` outside the frame (off screen, under the clock, or under
##   the slot row), an arrow on the frame's edge (`arrow` is its tip and `dir` its heading); "" for a tag without `edge`
##   off screen (only its outline may show).
## - `label`: its label's plate.
## - `show`: the label is drawn. Not when it has none, nor when its plate would overlap one placed before it: a director
##   lists its most important tags first, so a crowded view keeps their labels.
## A tag at no point is left out.
static func tag_layout(tags: Array[MapTag], xf: Transform2D, view: Vector2) -> Array:
	var out := []
	var placed: Array[Rect2] = []
	var frame := tag_frame(view)
	for t in tags:
		if not t.valid():
			continue
		var c := tag_point(t, xf)
		var e := {"tag": t, "c": c, "mode": "", "arrow": Vector2.INF, "dir": Vector2.ZERO, "label": Rect2(), "show": false}
		if frame.has_point(c) or (not t.edge and Rect2(Vector2.ZERO, view).has_point(c)):
			e.mode = "map"
			e.label = label_rect(t.label, c - Vector2(0.0, t.size + LABEL_GAP + PLATE_H * 0.5), view)
		elif t.edge:
			var tip := frame_point(c, frame)
			var d := (c - frame.get_center()).normalized()
			var reach := ARROW_REACH + absf(d.x) * plate_size(t.label).x * 0.5 \
				+ absf(d.y) * PLATE_H * 0.5
			e.mode = "arrow"
			e.arrow = tip
			e.dir = d
			e.label = label_rect(t.label, tip - d * reach, view)
		if String(e.mode) != "" and t.label != "":
			var r: Rect2 = e.label
			var clear := true
			for p in placed:
				clear = clear and not r.intersects(p)
			if clear:
				placed.append(r)
				e.show = true
		out.append(e)
	return out


## Where the arrow for a point outside `frame` sits (v0.10 M6): on the line from the frame's centre to it, on the frame's edge.
static func frame_point(point: Vector2, frame: Rect2) -> Vector2:
	var mid := frame.get_center()
	var d := point - mid
	var half := frame.size * 0.5
	var k := 1.0
	if absf(d.x) > half.x:
		k = half.x / absf(d.x)
	if absf(d.y) * k > half.y:
		k = half.y / absf(d.y)
	return mid + d * k


## The screen's size: the Control's once laid out, else 640 x 360.
func _view() -> Vector2:
	return Vector2(size.x if size.x > 1.0 else SCREEN_W, size.y if size.y > 1.0 else SCREEN_H)


## The city's state, top right, as [text, colour] pieces: each figure wears the colour of the stability part it
## drives, so the player can tell which number moves which part of the bar.
## The alarm stage's colour on the status line (v0.04), calm to red.
const STAGE_COLS := [Color("9a9484"), Color("e8e2d0"), Color("d8b23a"), Color("ff8a3a"), Color("c8342a"), Color("ff4a4a")]


func status_segments() -> Array:
	return [
		["Citizens %d" % _crowd.alive_citizens(), UiTheme.STABILITY_COLS[0]],
		["Soldiers %d" % _crowd.alive_soldiers(), UiTheme.STABILITY_COLS[3]],
		["Destroyed %d" % _rules.buildings_down, UiTheme.STABILITY_COLS[1]],
		[_crowd.alarms.stage_name(), STAGE_COLS[_crowd.alarms.stage]],
	]


func status_text() -> String:
	var parts := PackedStringArray()
	for seg: Array in status_segments():
		parts.append(String(seg[0]))
	return "   ".join(parts)


## What a slot is: ready to cast, waiting out a cooldown, or waiting for the power now playing. Being the picked one is a separate
## question -- a picked slot still has to show its own cooldown, which it did not when this answered "picked".
func slot_state(slot: int) -> String:
	var reason := _rules.refusal(slot)
	return "ready" if reason == "" else reason


## Is this the slot the player has picked?
func is_picked(slot: int) -> bool:
	return _aim != null and _aim.slot == slot


## Where slot `i` is drawn -- the one geometry both the drawing and the mouse use.
func slot_rect(i: int) -> Rect2:
	var w := size.x if size.x > 1.0 else SCREEN_W
	var count := _rules.loadout.size()
	var total := float(count) * SLOT_W + float(maxi(count - 1, 0)) * SLOT_GAP
	var left := roundf((w - total) * 0.5)
	return Rect2(Vector2(left + float(i) * (SLOT_W + SLOT_GAP), SLOT_TOP), Vector2(SLOT_W, SLOT_SIZE))


## The power's name in slot `i` as its card shows it, cut to one line (taken once in setup()).
func slot_name(i: int) -> String:
	return _slot_names[i] if i >= 0 and i < _slot_names.size() else ""


## The slot under a screen point, or -1.
func slot_at(point: Vector2) -> int:
	for i in _rules.loadout.size():
		if slot_rect(i).has_point(point):
			return i
	return -1


func push_banner(text: String) -> void:
	_banners.append([text, 0.0])


func banners() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _banners:
		out.append(String(b[0]))
	return out


## Cael's line (v0.10 M5): queued behind any still showing, as banners are.
func push_subtitle(text: String) -> void:
	_subtitles.append([text, 0.0])


func subtitles() -> PackedStringArray:
	var out := PackedStringArray()
	for s in _subtitles:
		out.append(String(s[0]))
	return out


## Who speaks, as the HUD names him.
static func speaker() -> String:
	return CampaignText.SPEAKER.to_upper()


## How wide a line is on screen: his name, the gap, then the line.
static func subtitle_width(text: String) -> float:
	return UiTheme.width(speaker(), UiTheme.SIZE_SMALL) + SUBTITLE_GAP + UiTheme.width(text, UiTheme.SIZE_BODY)


## The tour's caption (v0.10 M6): Mission sets it every frame of the tour, and clears it when the camera lands.
func set_caption(text: String) -> void:
	_caption = text


## The tour's caption on screen now (v0.10 M6); "" for none.
func caption() -> String:
	return _caption


## The tour's caption (v0.10 M6) on a dark plate centred above the slot row, with SKIP_TEXT dim under it.
func _draw_caption(w: float) -> void:
	if _caption == "":
		return
	var tw := UiTheme.width(_caption, UiTheme.SIZE_BODY)
	var sw := UiTheme.width(SKIP_TEXT, UiTheme.SIZE_SMALL)
	var plate_w := maxf(tw, sw) + 16.0
	draw_rect(Rect2(roundf((w - plate_w) * 0.5), CAPTION_TOP, plate_w, 32.0), Color(0.03, 0.03, 0.05, 0.78))
	UiTheme.text(self, Vector2(roundf((w - tw) * 0.5), CAPTION_TOP + 14.0), _caption, UiTheme.SIZE_BODY)
	UiTheme.text(self, Vector2(roundf((w - sw) * 0.5), CAPTION_TOP + 27.0), SKIP_TEXT, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## Is this slot still red from a cast it could not take?
func flashing(slot: int) -> bool:
	return slot >= 0 and slot < _flash.size() and _flash[slot] > 0.0


func _on_cast_refused(slot: int, reason: String) -> void:
	if slot >= 0 and slot < _flash.size():
		_flash[slot] = FLASH_SECONDS
	if reason == "nobody":
		push_banner("NO ONE TO WHISPER TO")
	elif reason == "shaken":
		push_banner("THEY SHAKE OFF THE WHISPER")
	UiSound.play(&"ui_buzz")


## Everything the HUD shows, as one string. Cheap to build, and it means a still frame is not redrawn sixty
## times a second while a four-minute mission's effects are already busy.
func _signature() -> String:
	var out := "%s|%s|%s|%d|%s" % [UiTheme.clock(_rules.time_left),
		objective_text() if _rules.mission.scored else str(objective_rows()), status_text(),
		roundi(_rules.stability.total() * 200.0), rite_text()]
	var events := event_rows()
	if not events.is_empty():
		out += "|" + str(events)
	out += "|" + hint_text()
	out += "|" + _caption
	out += "|%s|%s|%s|%d" % [str(wish_rows()), ascend_shown(), praying, roundi(gaze_of(_rules) * 100.0)]
	for i in _rules.loadout.size():
		out += "%s%d%s," % [slot_state(i), roundi(_rules.cooldown_left(i) * 4.0), ("p%d" % _aim.mode_index()) if is_picked(i) else ""]
	return out


## What the tag layer shows, in short (board tags): the camera, the screen and every tag's fields -- everything
## tag_layout() lays the tags out from. "" with nothing tagged.
func _tag_signature() -> String:
	var tags := all_tags()
	if tags.is_empty():
		return ""
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var out := "%s|%s" % [xf, _view()]
	for t in tags:
		out += "|%s%s%s%s%s%s%s%s%s" % [t.at, t.color.to_html(), t.label, t.rise, t.lift, t.size, t.edge, t.outline, t.valid()]
	return out


## The tag layer's drawing (board tags): the tags on the map (v0.10; M6) and their edge arrows. The layer sits behind the
## HUD, so they sit under every other HUD element -- the clock, the bars, the events, the objectives, the status, the
## banners, Cael's plate and the slots -- and never hide one.
func _draw_tag_layer() -> void:
	_canvas = _tag_layer
	_draw_tags()
	_draw_tag_arrows()
	_canvas = self


func _draw() -> void:
	# Before the first layout pass a Control can still be 0 wide, and this one is centred on the screen.
	var w := size.x if size.x > 1.0 else get_viewport_rect().size.x
	_draw_rise()
	_draw_clock(w)
	_draw_rite(w)
	_draw_gaze(w)
	_draw_events(w)
	if _rules.mission.scored:
		_draw_objectives()
	else:
		_draw_rows()
	_draw_hint()
	_draw_wishes()
	_draw_status(w)
	_draw_banners(w)
	_draw_subtitle(w)
	_draw_prayers(w)
	_draw_caption(w)
	_draw_ascend()
	_draw_slots(w)


func _draw_clock(w: float) -> void:
	var s := UiTheme.clock(_rules.time_left)
	var col := UiTheme.COL_TEXT
	if _rules.time_left <= HURRY_AT:
		# One pulse a second, so the last half minute is felt without a tween.
		col = UiTheme.COL_BAD if fmod(_rules.time_left, 1.0) > 0.5 else Color("ff8a72")
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(s, UiTheme.SIZE_BIG)) * 0.5), 18.0), s, UiTheme.SIZE_BIG, col)


## The Banishing Rite under the clock: the clergy gathering, then the rite's progress in RITE_BAR's steps; "" when
## there is nothing to show.
func rite_text() -> String:
	var rite := _crowd.rite if _crowd != null else null
	if rite == null:
		return ""
	match rite.state:
		BanishingRite.State.GATHERING:
			return "CLERGY GATHER %d/%d" % [mini(rite.in_ring(), BanishingRite.NEED), BanishingRite.NEED]
		BanishingRite.State.CHANTING:
			return "BANISHING RITE %d" % floori(rite.fraction() * RITE_BAR.x)
	return ""


func _draw_rite(w: float) -> void:
	var rite := _crowd.rite if _crowd != null else null
	if rite_text() == "":
		return
	var chanting := rite.state == BanishingRite.State.CHANTING
	var label := "BANISHING RITE" if chanting else rite_text()
	var plate_w := maxf(RITE_BAR.x, UiTheme.width(label, UiTheme.SIZE_SMALL)) + 8.0
	draw_rect(Rect2(roundf((w - plate_w) * 0.5), RITE_TOP - 8.0, plate_w, 17.0 if chanting else 11.0), UiTheme.COL_PANEL)
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(label, UiTheme.SIZE_SMALL)) * 0.5), RITE_TOP),
		label, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if chanting else UiTheme.COL_DIM)
	if chanting:
		var at := Vector2(roundf((w - RITE_BAR.x) * 0.5), RITE_TOP + 3.0)
		draw_rect(Rect2(at - Vector2.ONE, RITE_BAR + Vector2(2.0, 2.0)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(at, Vector2(roundf(RITE_BAR.x * rite.fraction()), RITE_BAR.y)), UiTheme.COL_GOLD)


## The next timed events (v0.09), centred on a plate under the clock: the time dim, the label light.
func _draw_events(w: float) -> void:
	var rows := event_rows()
	if rows.is_empty():
		return
	var plate := events_rect(w)
	draw_rect(plate, UiTheme.COL_PANEL)
	var wide := plate.size.x - 8.0
	var y := plate.position.y + 12.0
	for row: Array in rows:
		var clock := String(row[0])
		var x := roundf((w - wide) * 0.5)
		UiTheme.text(self, Vector2(x, y), clock, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		UiTheme.text(self, Vector2(x + UiTheme.width(clock + "  ", UiTheme.SIZE_SMALL), y), String(row[1]), UiTheme.SIZE_SMALL)
		y += ROW_H


func _draw_objectives() -> void:
	draw_rect(OBJECTIVE_PANEL, UiTheme.COL_PANEL)
	UiTheme.text(self, Vector2(6.0, 14.0), objective_text(), UiTheme.SIZE_SMALL)
	# The five-colour stability bar: one segment per part, each as wide as its weight.
	var at := Vector2(6.0, 21.0)
	var parts := [[_rules.stability.population, Stability.W_POPULATION],
		[_rules.stability.infrastructure, Stability.W_INFRASTRUCTURE],
		[_rules.stability.leadership, Stability.W_LEADERSHIP],
		[_rules.stability.military, Stability.W_MILITARY],
		[_rules.stability.resources, Stability.W_RESOURCES]]
	draw_rect(Rect2(at, STABILITY_BAR), Color(0, 0, 0, 0.6))
	var x := at.x
	for i in parts.size():
		var part: Array = parts[i]
		var full := STABILITY_BAR.x * float(part[1])
		draw_rect(Rect2(Vector2(x, at.y), Vector2(full * float(part[0]), STABILITY_BAR.y)), UiTheme.STABILITY_COLS[i])
		x += full
	UiTheme.text(self, Vector2(at.x + STABILITY_BAR.x + 5.0, at.y + 6.0),
		"Stability %d%%" % roundi(_rules.stability.total() * 100.0), UiTheme.SIZE_SMALL)
	# The legend: a swatch and a short name for each part, in the bar's order.
	var lx := 6.0
	for entry: Array in LEGEND:
		draw_rect(Rect2(lx, 31.0, 5.0, 5.0), UiTheme.STABILITY_COLS[int(entry[1])])
		UiTheme.text(self, Vector2(lx + 7.0, 38.0), String(entry[0]), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		lx += 7.0 + UiTheme.width(String(entry[0]), UiTheme.SIZE_SMALL) + 8.0
	var count := _rules.escaped_this_act()
	var limit := escape_limit()
	var escaped := "Escaped %d / %d" % [count, limit]
	var col := UiTheme.COL_BAD if count >= limit - 8 else UiTheme.COL_DIM
	UiTheme.text(self, Vector2(6.0, 54.0), escaped, UiTheme.SIZE_SMALL, col)
	var gaze := gaze_readout()
	if gaze != "":
		# Tier 5's Gaze (v0.11 M1) beside the escapes, readable while the rite's plate takes the bar's place.
		UiTheme.text(self, Vector2(OBJECTIVE_PANEL.end.x - 6.0 - UiTheme.width(gaze, UiTheme.SIZE_SMALL), 54.0), gaze,
			UiTheme.SIZE_SMALL, UiTheme.COL_GOLD.lerp(UiTheme.COL_BAD, gaze_of(_rules)))


## The objective panel of a mission without a score (v0.08): objective_rows(), each with its tick or cross after it.
func _draw_rows() -> void:
	var rows := objective_rows()
	if rows.is_empty():
		return
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL) + (12.0 if String(row[1]) != "" else 0.0))
	draw_rect(Rect2(2.0, 2.0, wide + 10.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)
	var y := 14.0
	for row: Array in rows:
		var text := String(row[0])
		UiTheme.text(self, Vector2(6.0, y), text, UiTheme.SIZE_SMALL)
		if String(row[1]) != "":
			UiTheme.mark(self, Vector2(6.0 + UiTheme.width(text, UiTheme.SIZE_SMALL) + 5.0, y - 7.0), String(row[1]) == "ok")
		y += ROW_H


## The how-to-win line (v0.10 M6) on its own dark plate under the objectives, in HINT_COL.
func _draw_hint() -> void:
	var lines := hint_lines(hint_text())
	if lines.is_empty():
		return
	var plate := hint_rect()
	draw_rect(plate, UiTheme.COL_PANEL)
	var y := plate.position.y + 12.0
	for l in lines:
		UiTheme.text(self, Vector2(6.0, y), l, UiTheme.SIZE_SMALL, HINT_COL)
		y += UiTheme.LINE_SMALL


## The wishes' rows (v0.11 M1, spec §5.2) on a plate under the how-to-win line: an open box, a tick once granted, a cross and
## the words struck through once failed.
func _draw_wishes() -> void:
	var rows := wish_rows()
	if rows.is_empty():
		return
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL))
	var top := wishes_top()
	draw_rect(Rect2(2.0, top, wide + 22.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)
	var y := top + 12.0
	for row: Array in rows:
		var text := String(row[0])
		var state := String(row[1])
		var box := Vector2(6.0, y - 8.0)
		if state == "granted":
			UiTheme.mark(self, box, true)
		elif state == "failed":
			UiTheme.mark(self, box, false)
		else:
			draw_rect(Rect2(box, Vector2(WISH_BOX - 1.0, WISH_BOX - 1.0)), Wish.COLOR, false, -1.0)
		var col := Wish.COLOR if state == "open" else (UiTheme.COL_GOLD if state == "granted" else UiTheme.COL_DIM)
		UiTheme.text(self, Vector2(18.0, y), text, UiTheme.SIZE_SMALL, col)
		if state == "failed":
			draw_line(Vector2(18.0, y - 4.0), Vector2(18.0 + UiTheme.width(text, UiTheme.SIZE_SMALL), y - 4.0), UiTheme.COL_DIM, -1.0)
		y += ROW_H


## The town prays (v0.11 M1, spec §5.1): during the night's first intro, a plate in the middle of the screen with
## PRAYERS_TITLE over the wishes heard; none when no wish was.
func _draw_prayers(w: float) -> void:
	if not praying:
		return
	var rows := wish_rows()
	if rows.is_empty():
		return
	var wide := UiTheme.width(PRAYERS_TITLE, UiTheme.SIZE_BODY)
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL))
	draw_rect(Rect2(roundf((w - wide) * 0.5) - 8.0, PRAYERS_TOP, wide + 16.0, 22.0 + UiTheme.LINE_SMALL * float(rows.size())),
		Color(0.03, 0.03, 0.05, 0.78))
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(PRAYERS_TITLE, UiTheme.SIZE_BODY)) * 0.5), PRAYERS_TOP + 14.0),
		PRAYERS_TITLE, UiTheme.SIZE_BODY, Wish.COLOR)
	var y := PRAYERS_TOP + 16.0 + UiTheme.LINE_SMALL
	for row: Array in rows:
		var text := String(row[0])
		UiTheme.text(self, Vector2(roundf((w - UiTheme.width(text, UiTheme.SIZE_SMALL)) * 0.5), y), text, UiTheme.SIZE_SMALL)
		y += UiTheme.LINE_SMALL


## The ASCEND plate (v0.11 M1, spec §6): a gold-framed button above the slots, its key on a plate beside the word.
func _draw_ascend() -> void:
	if not ascend_shown():
		return
	var r := ascend_rect()
	draw_rect(r, Color(0.12, 0.1, 0.04, 0.92))
	UiTheme.frame(self, r, true)
	var word_w := UiTheme.width(ASCEND_TEXT, UiTheme.SIZE_BODY)
	var x := roundf(r.get_center().x - (word_w + 6.0 + plate_size(ASCEND_KEY).x) * 0.5)
	UiTheme.text(self, Vector2(x, r.position.y + 14.0), ASCEND_TEXT, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_plate(Vector2(x + word_w + 6.0, r.position.y + 4.0), ASCEND_KEY, UiTheme.COL_TEXT)


## The ascent's light (v0.11 M1, spec §6): a pale gold column over its ground point, growing to the top of the screen over
## the first half of RISE_SECONDS and fading over all of it, three widths brightening to its core.
func _draw_rise() -> void:
	if not rising():
		return
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	var foot := (xf * Iso.ground_to_screen(_rise_at)).round()
	var k := clampf(_rise_age / RISE_SECONDS, 0.0, 1.0)
	var top := lerpf(foot.y, 0.0, minf(k * 2.0, 1.0))
	for i in 3:
		var half := (9.0 - float(i) * 3.0) * (1.0 - k * 0.5)
		var col := RISE_COL
		col.a = (0.16 + 0.18 * float(i)) * (1.0 - k)
		draw_rect(Rect2(foot.x - half, top, half * 2.0, maxf(foot.y - top, 1.0)), col)


## An arrow at the screen's edge (v0.10 M6's tags): `col` on a dark disc ringed in `ring`, its tip at
## `at`, pointing along `dir`. On a dark disc, so it stands out from the town's warm roofs and stalls.
func _draw_arrow(at: Vector2, dir: Vector2, col: Color, ring: Color) -> void:
	var side := Vector2(-dir.y, dir.x)
	_canvas.draw_circle(at - dir * 5.0, 10.0, MARK_EDGE)
	_canvas.draw_arc(at - dir * 5.0, 10.0, 0.0, TAU, 24, ring, -1.0)
	var arrow := PackedVector2Array([at, at - dir * 10.0 + side * 6.0, at - dir * 10.0 - side * 6.0])
	_canvas.draw_colored_polygon(arrow, col)
	arrow.append(arrow[0])
	_canvas.draw_polyline(arrow, MARK_EDGE, -1.0)


func _draw_status(w: float) -> void:
	var gap := UiTheme.width("   ", UiTheme.SIZE_SMALL)
	var segs := status_segments()
	var total := gap * float(segs.size() - 1)
	for seg: Array in segs:
		total += UiTheme.width(String(seg[0]), UiTheme.SIZE_SMALL)
	var x := w - total - 6.0
	for seg: Array in segs:
		UiTheme.text(self, Vector2(x, 14.0), String(seg[0]), UiTheme.SIZE_SMALL, seg[1])
		x += UiTheme.width(String(seg[0]), UiTheme.SIZE_SMALL) + gap


func _draw_banners(w: float) -> void:
	if _banners.is_empty():
		return
	var text := String(_banners[0][0])
	var age := float(_banners[0][1])
	var fade := clampf((BANNER_SECONDS - age) / 0.4, 0.0, 1.0)
	var col := UiTheme.COL_GOLD
	col.a = fade
	var text_w := UiTheme.width(text, UiTheme.SIZE_BIG)
	var x := roundf((w - text_w) * 0.5)
	# A banner announces something that is happening right now, which means it lands on top of the effect that
	# caused it. On its own bar with a gold edge it stays readable over lightning or a wave.
	var bar := Rect2(x - 8.0, 116.0, text_w + 16.0, 20.0)
	draw_rect(bar, Color(0.03, 0.03, 0.05, 0.78 * fade))
	var edge := UiTheme.COL_GOLD_DARK
	edge.a = fade
	draw_rect(bar, edge, false, -1.0)
	UiTheme.text(self, Vector2(x, 131.0), text, UiTheme.SIZE_BIG, col)


## Cael's line under the banner's bar (v0.10 M5): on a dark plate, his name small in gold, then the line in the body's
## light text; it comes up over 0.2 s and fades over its last 0.4 s, the words' shadows with them (UiTheme.text()'s
## `shadow_a`).
func _draw_subtitle(w: float) -> void:
	if _subtitles.is_empty():
		return
	var text := String(_subtitles[0][0])
	var age := float(_subtitles[0][1])
	var fade := clampf((SUBTITLE_SECONDS - age) / 0.4, 0.0, 1.0) * clampf(age / 0.2, 0.0, 1.0)
	var who := speaker()
	var who_w := UiTheme.width(who, UiTheme.SIZE_SMALL)
	var x := roundf((w - subtitle_width(text)) * 0.5)
	draw_rect(Rect2(x - 6.0, SUBTITLE_TOP, subtitle_width(text) + 12.0, 17.0), Color(0.03, 0.03, 0.05, 0.72 * fade))
	var gold := UiTheme.COL_GOLD
	gold.a = fade
	var body := UiTheme.COL_TEXT
	body.a = fade
	UiTheme.text(self, Vector2(x, SUBTITLE_TOP + 12.0), who, UiTheme.SIZE_SMALL, gold, fade)
	UiTheme.text(self, Vector2(x + who_w + SUBTITLE_GAP, SUBTITLE_TOP + 13.0), text, UiTheme.SIZE_BODY, body, fade)


func _draw_slots(_w: float) -> void:
	for i in _rules.loadout.size():
		var box := slot_rect(i)
		var icon_box := Rect2(box.position, Vector2(SLOT_SIZE, SLOT_SIZE))
		var state := slot_state(i)
		var usable := state == "ready"
		draw_rect(box, UiTheme.COL_PANEL)
		if flashing(i):
			var red := UiTheme.COL_BAD
			red.a = _flash[i] / FLASH_SECONDS
			draw_rect(box, red)
		var icon: Texture2D = _slot_icons[i] if i < _slot_icons.size() else null
		if icon != null:
			draw_texture_rect(icon, icon_box, false, Color.WHITE if usable else Color(0.45, 0.45, 0.5))
		UiTheme.frame(self, box, is_picked(i))
		if is_picked(i):
			_draw_modes(box)
		_plate(icon_box.position + Vector2(1.0, 1.0), "%d" % (i + 1), UiTheme.COL_TEXT)
		# The name beside the icon on one line, gold when focused, dim when it cannot be cast; its cooldown under it.
		var tx := box.position.x + SLOT_SIZE + 4.0
		var name_col := UiTheme.COL_GOLD if is_picked(i) else (UiTheme.COL_TEXT if usable else UiTheme.COL_DIM)
		UiTheme.text(self, Vector2(tx, box.position.y + 14.0), slot_name(i), UiTheme.SIZE_SMALL, name_col)
		UiTheme.text(self, Vector2(tx, box.position.y + 14.0 + UiTheme.LINE_SMALL),
			PrepareScreen.cooldown_text(_rules.power(i)), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		if state == "busy":
			# Another power is still playing: a light shade and its seconds left, in gold.
			draw_rect(Rect2(box.position, Vector2(SLOT_W, SLOT_SIZE)), Color(0, 0, 0, 0.35))
			var wait := "%d" % ceili(_rules.busy_left())
			UiTheme.text(self, icon_box.get_center() + Vector2(-UiTheme.width(wait) * 0.5, 4.0), wait, UiTheme.SIZE_BODY,
				UiTheme.COL_GOLD)
		if state == "cooldown":
			# The cooldown as a shade falling away from the top of the card, its seconds over the icon.
			var left := _rules.cooldown_left(i)
			var frac := clampf(left / maxf(float(_rules.power(i).cooldown), 0.001), 0.0, 1.0)
			draw_rect(Rect2(box.position, Vector2(SLOT_W, SLOT_SIZE * frac)), Color(0, 0, 0, 0.6))
			var secs := "%d" % ceili(left)
			UiTheme.text(self, icon_box.get_center() + Vector2(-UiTheme.width(secs) * 0.5, 4.0), secs, UiTheme.SIZE_BODY)


## The focused power's modes (Voice of God's commands, Divine Schism's ways to divide) in a row above its slot: the
## picked one gold, with the keys that step through them.
func _draw_modes(box: Rect2) -> void:
	var modes := _aim.modes()
	if modes.is_empty():
		return
	var labels: Array[String] = ["Q/E"]
	for m: Dictionary in modes:
		labels.append(String(m.name))
	var total := 0.0
	for l in labels:
		total += UiTheme.width(l, UiTheme.SIZE_SMALL) + 6.0
	var view_w := get_viewport_rect().size.x
	var x := clampf(box.position.x, 2.0, maxf(view_w - total - 2.0, 2.0))
	var y := box.position.y - PLATE_H - 3.0
	for k in labels.size():
		var col := UiTheme.COL_DIM if k == 0 else (UiTheme.COL_GOLD if k - 1 == _aim.mode_index() else UiTheme.COL_TEXT)
		_plate(Vector2(x, y), labels[k], col)
		x += UiTheme.width(labels[k], UiTheme.SIZE_SMALL) + 6.0


## A short label on a dark plate, `at` being the plate's top-left corner.
func _plate(at: Vector2, label: String, col: Color) -> void:
	_canvas.draw_rect(Rect2(at, plate_size(label)), Color(0, 0, 0, 0.62))
	UiTheme.text(_canvas, at + Vector2(1.0, PLATE_H - 3.0), label, UiTheme.SIZE_SMALL, col)
