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
## The Lantern's rings on the clock (v0.11.2, spec 5.1): gold while it stirs, red while it burns.
const LANTERN_GOLD := Color("d8b23a")
const LANTERN_RED := Color("c8342a")
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
## The keepout's margin round the left HUD stack (v0.11 M6, mission spec §6.4): screen pixels beyond its right and bottom edges -- an
## arrow's disc (radius 10, centred 5 px behind its tip) on the border never reaches back behind a plate.
const STACK_PAD := 10.0
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
## v0.11.1 §1: the HUD collapses to one objective line, and TAB opens the rest (`details`). The how-to-win line flashes for HINT_FLASH
## seconds when play begins and whenever its (unfilled) words change; the cue on the objective row says what TAB does.
const HINT_FLASH := 8.0
const MORE_TEXT := "TAB more"
const LESS_TEXT := "TAB less"
## A scored mission's objective panel collapsed: no colour legend row, the Escaped line moved up to ESCAPED_Y_SHORT.
const OBJECTIVE_PANEL_SHORT := Rect2(2.0, 2.0, 236.0, 46.0)
const ESCAPED_Y := 54.0
const ESCAPED_Y_SHORT := 40.0
## v0.11.1 §3: an off-screen tag shows its label while the mouse is this close to its arrow's disc (or while `details` is on).
const ARROW_HOVER_PX := 12.0
## The ascent (spec §6): a pale gold column rising over the god's last cast spot for RISE_SECONDS of real time.
const RISE_SECONDS := 2.0
const RISE_COL := Color(1.0, 0.93, 0.7)
## How near a click must come to a waiting wish's tag to engage it (spec §5.2).
const ENGAGE_PX := 8.0
## The chain plate (god P3, MS §2 "Key, plate", R7): C's own plate above the slot row's right end, 100 x 20, CHAIN_GAP above SLOT_TOP. At six
## slots the row is 620 of 640 px, so there is no room beside it.
const CHAIN_SIZE := Vector2(100.0, 20.0)
const CHAIN_GAP := 4.0
const CHAIN_LABEL := "C CHAIN"
## The plate's icon: an existing one (Leaving Is Prohibited's, plan P3-17, C4: no new art).
const CHAIN_ICON := "noleave"
const CHAIN_ICON_SIZE := 16.0
## The rite's win plate (god P3, MS §5, plan P3-18): centred, y 120 to 200, in place of the stack, the strip and the slots while it shows.
const RITE_PLATE_TOP := 120.0
const RITE_PLATE_H := 80.0
const RITE_PLATE_WRAP := 560.0

var _rules: Rules
var _crowd: Crowd
var _town: Town
var _aim: Targeting
## Banners waiting their turn: [text, seconds shown, heard]. A banner rings ui_notice as it comes on screen, unless it
## came with a sound of its own.
var _banners: Array = []
## The frame a slot last rang ui_ready on, so slots coming back on the same frame ring once.
var _ready_rang := -1
## The Divine Surge rings ui_surge, and Rules sends its banner straight after: that next banner stays quiet.
var _quiet_next_banner := false
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
## The intro is up (v0.11.1, spec §2): Mission sets it. The HUD then draws the clock, the slots and one message (a banner, a
## tour caption or the prayers plate): the objective stack, the strip, the status line and the Gaze bar wait for play.
var intro := false
## The ascent's column (v0.11 M1): its ground point (Vector2.INF for none) and its real seconds so far.
var _rise_at := Vector2.INF
var _rise_age := 0.0
## How wide the column is drawn, 1.0 for the ascent's (god P3, MS §5: a won rite's rises larger, Mission.RITE_RISE).
var _rise_scale := 1.0
## The chain plate (god P3, MS §2): Mission sets `chain_aiming` while C's aim is up (the plate's frame turns gold); a refused chain flashes it
## red for FLASH_SECONDS.
var chain_aiming := false
var _chain_flash := 0.0
var _chain_icon: Texture2D
## The rite's win plate lines (MS §5) while it shows; empty otherwise.
var _rite_lines := PackedStringArray()
## The objective rows, the how-to-win line and its wrapped lines, taken once at the start of advance() and dropped at its end (v0.11
## M6's final review): the redraw signature and the tags' keepout (stack_rect(), each frame) read them several times a frame, and the
## line's wrapping was done twice for each. null outside advance(), where every reader takes them live.
var _frame_rows: Variant = null
var _frame_hint: Variant = null
var _frame_lines: Variant = null
## The wish rows taken once per advance() as well (v0.11.1 fix round): the signature and the keepout read them several times a frame.
var _frame_wishes: Variant = null
## The cue's plate width by its text (two texts): measured once.
var _cue_widths := {}
## v0.11.1: expanded (TAB) or collapsed. Static, so it holds for the session across missions, restarts and acts (spec §1.3); nothing but
## the HUD reads it.
static var details := false
## The how-to-win flash: the unfilled line last seen, the seconds of flash left, and whether play has begun (play_began()).
var _hint_key := ""
var _hint_left := 0.0
var _played := false


## Back to a fresh session (v0.11.1): collapsed. The suite calls it before each test file, so no file depends on what ran before it in
## the same process.
static func reset_session() -> void:
	details = false


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
	_rules.recharged.connect(_on_recharged)
	_rules.surged.connect(_on_surged)
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


## Age the banners and Cael's lines, and redraw when anything on screen has changed. v0.11 M6's final review: the objective rows and
## the how-to-win line are taken once for the whole advance (_frame_rows, _frame_hint, _frame_lines).
func advance(delta: float) -> void:
	if _rules != null and _rules.mission != null:
		_frame_rows = objective_rows()
		_frame_wishes = _build_wish_rows()
		_frame_hint = hint_text()
		_step_hint_flash(delta)
		_frame_lines = hint_lines(String(_frame_hint)) if hint_shown() else PackedStringArray()
	_advance(delta)
	_frame_rows = null
	_frame_wishes = null
	_frame_hint = null
	_frame_lines = null


## advance()'s work, with the frame's rows and line taken (v0.11 M6's final review).
func _advance(delta: float) -> void:
	_age(_banners, delta, BANNER_SECONDS)
	_age(_subtitles, delta, SUBTITLE_SECONDS)
	if _rise_at != Vector2.INF:
		_rise_age += delta / maxf(Engine.time_scale, 0.001)  # real seconds, through the ascent's slow motion
	if not _banners.is_empty() and not bool(_banners[0][2]):
		_banners[0][2] = true
		UiSound.play(&"ui_notice")
	var flashing := false
	for i in _flash.size():
		_flash[i] = maxf(0.0, _flash[i] - delta)
		flashing = flashing or _flash[i] > 0.0
	_chain_flash = maxf(0.0, _chain_flash - delta)
	flashing = flashing or _chain_flash > 0.0
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


## The objective rows this advance took (v0.11 M6's final review), else live.
func _rows_now() -> Array:
	return _frame_rows if _frame_rows != null else objective_rows()


## The how-to-win line this advance took (v0.11 M6's final review), else live.
func _hint_now() -> String:
	return String(_frame_hint) if _frame_hint != null else hint_text()


## The how-to-win line's wrapped lines this advance took (v0.11 M6's final review), else wrapped live.
func _lines_now() -> PackedStringArray:
	if _frame_lines != null:
		return _frame_lines
	return hint_lines(hint_text()) if hint_shown() else PackedStringArray()


## TAB (v0.11.1 §1.2): everything, or the short screen again.
func toggle_details() -> void:
	details = not details


## The cue's plate width: measured once per text.
func _cue_width() -> float:
	var text := cue_text()
	if not _cue_widths.has(text):
		_cue_widths[text] = plate_size(text).x
	return _cue_widths[text]


## The cue on the objective row: what TAB does now.
func cue_text() -> String:
	return LESS_TEXT if details else MORE_TEXT


## Play begins (v0.11.1 §1.1): the intro has landed (or a scripted run starts), so the how-to-win line flashes once, and from now on a
## change of its words flashes it again.
func play_began() -> void:
	_played = true
	_hint_key = hint_key()
	_hint_left = HINT_FLASH if _hint_key != "" else 0.0


## Ages the flash and restarts it when the unfilled words have changed (after play_began() only). A ticking `{n}` does not change them.
func _step_hint_flash(delta: float) -> void:
	_hint_left = maxf(0.0, _hint_left - delta)
	if not _played:
		return
	var key := hint_key()
	if key != _hint_key:
		_hint_key = key
		_hint_left = HINT_FLASH if key != "" else 0.0


## The how-to-win plate is up: expanded, or flashing; and there is a line.
func hint_shown() -> bool:
	return (details or _hint_left > 0.0) and _hint_now() != ""


## The objective rows as drawn: collapsed, the main one only.
func rows_shown() -> Array:
	var rows := _rows_now()
	return rows if details or rows.size() <= 1 else rows.slice(0, 1)


## The objective panel of a scored mission as drawn.
func objective_panel() -> Rect2:
	return OBJECTIVE_PANEL if details else OBJECTIVE_PANEL_SHORT


## The act's next two timed events (v0.09) as [clock, label] rows, e.g. ["0:23", "The bonfire lights"]; empty for a
## mission whose director keeps no timeline.
func event_rows() -> Array:
	var rows := []
	var want := 2 if details else 1
	# v0.11.2 (spec 5.2): the Lantern's rows (the Bearer sets out, reaches the tower; a Herald reaches the Temple) merge with the timeline's by the
	# seconds still to come, soonest first; collapsed, the soonest of all.
	var soon: Array[Dictionary] = []
	if _rules.director != null and _rules.director.timeline != null:
		soon.append_array(_rules.director.timeline.upcoming(want))
	if _rules.lantern != null:
		soon.append_array(_rules.lantern.strip_rows())
	if _rules.director != null:
		soon.append_array(_rules.director.strip_rows())  # god P3 (MS §3.4): a rite's clergy march counts down here; empty for every other director
	soon.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["in"]) < float(b["in"]))
	for e: Dictionary in soon.slice(0, want):
		rows.append([String(e["clock"]) if e.has("clock") else UiTheme.clock(float(e["in"])), String(e["label"])])  # (a row may carry no countdown)
	return rows


## The how-to-win line for the mission or act being played, in its director's phase (v0.10 M6, MissionHints); once a board
## night's main objective is done (v0.11 M1, spec §6), the open wishes' or the ascent's; "" for none. v0.11 M4: a line that counts
## down shows the director's seconds (MissionHints.filled()).
func hint_text() -> String:
	if _rules == null or _rules.mission == null:
		return ""
	if _rules.main_done or _rules.director == null:
		return hint_key()
	return MissionHints.filled(hint_key(), _rules.director.hint_seconds())


## The how-to-win line with its seconds unfilled (v0.11.1): what the flash keys on, so a ticking `{n}` never re-flashes it.
func hint_key() -> String:
	if _rules == null or _rules.mission == null:
		return ""
	# v0.11.2 (spec 5.3, final-review ruling C17): a Herald running first (the instant loss the Lantern owns); then the director's own phase line
	# when it has one (a collector running for the Citadel, a report running to the Temple: they are instant losses too); then the Lantern's
	# counterplay lines; "" gives the rest back. The clock ring shows the Lantern's state whatever the plate says.
	if _rules.lantern != null:
		var phase := _rules.lantern.hint_phase()
		var lantern_line := MissionHints.lantern_line(phase)
		if lantern_line != "" and not (phase == "herald" or phase == "herald_silent") and _director_line_up():
			lantern_line = ""
		if lantern_line != "":
			return lantern_line
	if _rules.main_done:
		return MissionHints.WISHES_LINE if _open_wishes() else MissionHints.ASCEND_LINE
	if _rules.director == null:
		return MissionHints.line(_rules.mission.id)
	return MissionHints.line(_rules.mission.id, _rules.director.hint_phase())


## The mission's director is in a phase with a line of its own (not its default one), and the night's main objective is not done (C17).
func _director_line_up() -> bool:
	if _rules.main_done or _rules.director == null:
		return false
	var phase := _rules.director.hint_phase()
	return phase != "" and MissionHints.LINES.has(_rules.mission.id + "." + phase)


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
	if rows.is_empty() or rite_plate_up():
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
	var top := objective_panel().end.y + 4.0
	if not _rules.mission.scored:
		var rows := rows_shown().size()
		top = 2.0 + (5.0 + ROW_H * float(rows) + 4.0 if rows > 0 else 0.0)
	var lines := _lines_now()
	var events := events_rect(_view().x)
	if lines.is_empty() or events.size == Vector2.ZERO:
		return top
	var high := top + 5.0 + UiTheme.LINE_SMALL * float(lines.size())
	if events.position.x < 2.0 + hint_width(lines) and top - 4.0 < events.end.y and high + 4.0 > events.position.y:
		return events.end.y + 4.0
	return top


## Where the how-to-win plate is drawn (v0.10 M6); `Rect2()` for no line.
func hint_rect() -> Rect2:
	var lines := _lines_now()
	if lines.is_empty():
		return Rect2()
	return Rect2(2.0, hint_top(), hint_width(lines), 5.0 + UiTheme.LINE_SMALL * float(lines.size()))


## The objective plate as drawn (v0.11 M6, factored out of _draw_rows() so the keepout reads the same rectangle): a scored mission's
## OBJECTIVE_PANEL, else the rows' plate, Rect2() with no rows.
func objective_rect() -> Rect2:
	if _rules.mission.scored:
		return objective_panel()
	var rows := rows_shown()
	if rows.is_empty():
		return Rect2()
	var wide := 0.0
	var first_w := -1.0
	for row: Array in rows:
		var row_w := UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL) + (12.0 if String(row[1]) != "" else 0.0)
		if first_w < 0.0:
			first_w = row_w
		wide = maxf(wide, row_w)
	# The cue sits at the right end of the first row (v0.11.1): the plate is at least as wide as that row and the cue side by side.
	wide = maxf(wide, first_w + _cue_width() + 4.0)
	return Rect2(2.0, 2.0, wide + 10.0, 5.0 + ROW_H * float(rows.size()))


## The cue's plate as drawn (v0.11.1 §1.1): at the right end of the objective row; a scored panel's, at the right end of its Escaped line.
## Rect2() with nothing to put it on.
func cue_rect() -> Rect2:
	if _rules == null or _rules.mission == null:
		return Rect2()
	var box := Vector2(_cue_width(), PLATE_H)
	if _rules.mission.scored:
		var panel := objective_panel()
		return Rect2(panel.end.x - 3.0 - box.x, (ESCAPED_Y if details else ESCAPED_Y_SHORT) - (PLATE_H - 3.0), box.x, box.y)
	var plate := objective_rect()
	if not plate.has_area():
		return Rect2()
	return Rect2(plate.end.x - 3.0 - box.x, 14.0 - (PLATE_H - 3.0), box.x, box.y)


## The wishes' plate as drawn (v0.11 M6, factored out of _draw_wishes()): Rect2() with no rows.
func wishes_rect() -> Rect2:
	return _wishes_plate(hint_rect())


## The wishes' plate under a how-to-win plate `hint` already measured (v0.11 M6): stack_rect() measures the hint once and shares it.
func _wishes_plate(hint: Rect2) -> Rect2:
	var rows := wish_rows_shown()
	if rows.is_empty():
		return Rect2()
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL))
	return Rect2(2.0, _wishes_top_under(hint), wide + 22.0, 5.0 + ROW_H * float(rows.size()))


## The left HUD stack as drawn this frame (v0.11 M6, mission spec §6.4): from the screen's corner to the right edge of the widest of the
## objective plate, the hint plate and the wishes' plate, and down to the bottom of the lowest, STACK_PAD beyond both. The plates are
## drawn whenever the HUD is -- the tour's caption and the night's end leave them -- so it is empty only while none has anything to show.
## The tags' keepout (_draw_tags()).
func stack_rect() -> Rect2:
	if _rules == null or _rules.mission == null or intro or rite_plate_up():
		return Rect2()  # v0.11.1: the stack is not drawn during the intro, so it keeps nothing clear (nor under a rite's win plate, god P3)
	var right := 0.0
	var bottom := 0.0
	var hint := hint_rect()  # measured once: the how-to-win plate wraps its words, and the wishes' plate sits under it
	for r: Rect2 in [objective_rect(), hint, _wishes_plate(hint)]:
		if r.has_area():
			right = maxf(right, r.end.x)
			bottom = maxf(bottom, r.end.y)
	if right <= 0.0:
		return Rect2()
	return Rect2(0.0, 0.0, right + STACK_PAD, bottom + STACK_PAD)


## The wishes heard (v0.11 M1, spec §5.2) as [text, state] rows, state "open", "granted" or "failed"; none off the board.
func wish_rows() -> Array:
	return _frame_wishes if _frame_wishes != null else _build_wish_rows()


func _build_wish_rows() -> Array:
	var rows := []
	if _rules == null or _rules.descent == null:
		return rows
	for w in _rules.descent.wishes:
		rows.append([w.hud_text(_rules), Wish.state_name(w.status)])
	return rows


## "Wishes: K of N granted" (v0.11.1 §1.1): K granted of the N heard; "" off the board or with none heard.
func wish_summary() -> String:
	var rows := wish_rows()
	if rows.is_empty():
		return ""
	return "Wishes: %d of %d granted" % [_granted(rows), rows.size()]


## How many of the wish rows are granted.
func _granted(rows: Array) -> int:
	var granted := 0
	for row: Array in rows:
		if String(row[1]) == "granted":
			granted += 1
	return granted


## The wishes' rows as drawn: collapsed, the one summary row (never nothing: a failed wish still shows in the count).
func wish_rows_shown() -> Array:
	var rows := wish_rows()
	if details or rows.is_empty():
		return rows
	return [[wish_summary(), "granted" if _granted(rows) == rows.size() else "open"]]


## Where the wishes' rows start (v0.11 M1): under the how-to-win plate, or where it would be with no line.
func wishes_top() -> float:
	return _wishes_top_under(hint_rect())


## Where the wishes' rows start under a how-to-win plate `hint` already measured (v0.11 M6's final review): the one rule wishes_top()
## and _wishes_plate() share.
func _wishes_top_under(hint: Rect2) -> float:
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
	if _rules.lantern != null:
		out.append_array(_rules.lantern.tags())  # v0.11.2: the Herald and the Bearer, after the mission's own, before the wishes'
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
## god P3 (MS §5, plan P3-18): `scale` widens the column -- a won rite's is Mission.RITE_RISE, twice the ascent's. 1.0 draws exactly as before.
func rise(at: Vector2, scale := 1.0) -> void:
	_rise_at = at
	_rise_age = 0.0
	_rise_scale = scale


## How wide the column is drawn relative to the ascent's (god P3).
func rise_scale() -> float:
	return _rise_scale


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
	if rules.lantern != null and not rules.lantern.tags().is_empty():
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
## tags out first (tag_layout()). v0.11 M6: the live stack is the layout's keepout (stack_rect()), so no tag, label or arrow hides under it;
## the timeline strip and the slot bar count as placed for labels (the final review), so no plate is drawn over them.
func _draw_tags() -> void:
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	# v0.11.1 §3: the hover comes from the previous frame's arrows (cheap, one frame late), read before the layout is replaced.
	var hover := _hover_point()
	_layout = tag_layout(all_tags(), xf, _view(), stack_rect(), [events_rect(_view().x), slots_rect(), chain_rect() if chain_shown() else Rect2()],
		hover, details)
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
			if t.ring >= 0.0:
				_draw_ring(e.c, t)
	for e: Dictionary in _layout:
		if String(e.mode) == "map" and bool(e.show):
			var t: MapTag = e.tag
			_plate((e.label as Rect2).position, t.label, t.color)


## A tag's ring (god P3, MS §2, §3.4): a dark circle round the diamond and, over it, a red arc filling clockwise from the top as `t.ring` goes 0 to 1 --
## a breaker's grip on a chained captive, the clergy's cleanse of the shrine. A tag with no ring (-1, the default) draws exactly as before.
func _draw_ring(c: Vector2, t: MapTag) -> void:
	var r := t.size + 3.0
	_canvas.draw_arc(c, r, 0.0, TAU, 32, Color(0.0, 0.0, 0.0, 0.6), 3.0)
	if t.ring > 0.0:
		_canvas.draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * clampf(t.ring, 0.0, 1.0), 32, UiTheme.COL_BAD, 2.0)


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


## Where the mouse is, for the arrows' hover (v0.11.1 §3): Vector2.INF unless the last layout held an arrow and the labels are not all
## showing anyway (`details`).
func _hover_point() -> Vector2:
	if details or not is_inside_tree():
		return Vector2.INF
	for e: Dictionary in _layout:
		if String(e.mode) == "arrow":
			return get_viewport().get_mouse_position()
	return Vector2.INF


## The index in `layout` of the arrow whose disc (tip - dir * 5) the point `hover` is within ARROW_HOVER_PX of -- the nearest, one only --
## and which has a label to show; -1 for none (v0.11.1 §3).
static func hovered_arrow(layout: Array, hover: Vector2) -> int:
	var best := -1
	var near := ARROW_HOVER_PX + 0.001
	if hover == Vector2.INF:
		return best
	for i in layout.size():
		var e: Dictionary = layout[i]
		if String(e.mode) != "arrow" or (e.tag as MapTag).label == "":
			continue
		var d := hover.distance_to((e.arrow as Vector2) - (e.dir as Vector2) * 5.0)
		if d < near:
			near = d
			best = i
	return best


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
## v0.11 M6's final review: `taken`, the other HUD plates no label may cover (the timeline strip, the slot bar): each counts as a label
## already placed, and a map tag's plate that would lie over one first tries beside its diamond (_label_aside()); the arrows, the
## diamonds and the keepout's rules are as they were. Empty, the layout of old.
## v0.11 M6 (mission spec §6.4) `keepout`, the left HUD stack: empty, the layout of old exactly. Else (1) a tag with `edge` whose diamond
## lies inside it becomes an arrow on its border, where the line from the frame's centre to the diamond crosses it, its label beside the
## arrow toward the centre, clear of it (_label_beside()); (2) an arrow frame_point() would put on the frame's edge inside it slides to
## its border the same way; (3) it counts as a label already placed, so no plate is drawn over it; (4) a tag without `edge` inside it
## keeps its diamond, not its label; (5) a tag whose diamond is clear of it but whose plate over the diamond would lie under it takes
## its plate beside the diamond (_label_aside()).
## v0.11.1 §3: with `arrow_labels` false an off-screen tag's arrow shows no label plate unless `hover` (screen pixels) is within
## ARROW_HOVER_PX of its disc -- the nearest one only; a bare arrow's plate is never placed, so it blocks no label. The defaults
## (labels on, no hover) are v0.11's layout exactly.
static func tag_layout(tags: Array[MapTag], xf: Transform2D, view: Vector2, keepout := Rect2(), taken: Array[Rect2] = [],
		hover := Vector2.INF, arrow_labels := true) -> Array:
	var out := []
	var frame := tag_frame(view)
	var keep := keepout.has_area()
	var blocked: Array[Rect2] = []
	for r in taken:
		if r.has_area():
			blocked.append(r)
	for t in tags:
		if not t.valid():
			continue
		var c := tag_point(t, xf)
		var e := {"tag": t, "c": c, "mode": "", "arrow": Vector2.INF, "dir": Vector2.ZERO, "label": Rect2(), "show": false}
		var hidden := keep and t.edge and keepout.has_point(c)
		if (frame.has_point(c) and not hidden) or (not t.edge and Rect2(Vector2.ZERO, view).has_point(c)):
			e.mode = "map"
			e.label = label_rect(t.label, c - Vector2(0.0, t.size + LABEL_GAP + PLATE_H * 0.5), view)
			if keep and not keepout.has_point(c) and (e.label as Rect2).intersects(keepout):
				e.label = _label_aside(t.label, c, t.size, keepout, view)
			for b in blocked:
				if (e.label as Rect2).intersects(b):
					e.label = _label_aside(t.label, c, t.size, b, view)
		elif t.edge:
			var tip := frame_point(c, frame, keepout)
			var d := (c - frame.get_center()).normalized()
			var reach := ARROW_REACH + absf(d.x) * plate_size(t.label).x * 0.5 \
				+ absf(d.y) * PLATE_H * 0.5
			e.mode = "arrow"
			e.arrow = tip
			e.dir = d
			e.label = label_rect(t.label, tip - d * reach, view)
			if keep and (e.label as Rect2).intersects(keepout):
				e.label = _label_beside(t.label, tip, d, keepout, view)
		out.append(e)
	# Which labels show, in the tags' order: a label that would overlap one placed before it (or the keepout or a taken plate) stays off.
	var placed: Array[Rect2] = []
	if keep:
		placed.append(keepout)
	for r in blocked:
		placed.append(r)
	var hovered := -1 if arrow_labels else hovered_arrow(out, hover)
	for i in out.size():
		var e: Dictionary = out[i]
		if String(e.mode) == "" or (e.tag as MapTag).label == "":
			continue
		if String(e.mode) == "arrow" and not arrow_labels:
			e.show = i == hovered
			continue
		var r: Rect2 = e.label
		var clear := true
		for p in placed:
			clear = clear and not r.intersects(p)
		if clear:
			placed.append(r)
			e.show = true
	return out


## Where the arrow for a point outside `frame` sits (v0.10 M6): on the line from the frame's centre to it, on the frame's edge. v0.11
## M6: one that would land inside `keepout` -- or a point inside it -- sits where that line first meets the keepout's border instead.
static func frame_point(point: Vector2, frame: Rect2, keepout := Rect2()) -> Vector2:
	var mid := frame.get_center()
	var d := point - mid
	var half := frame.size * 0.5
	var k := 1.0
	if absf(d.x) > half.x:
		k = half.x / absf(d.x)
	if absf(d.y) * k > half.y:
		k = half.y / absf(d.y)
	var tip := mid + d * k
	if keepout.has_area() and (keepout.grow(0.5).has_point(tip) or keepout.has_point(point)):
		return _keepout_point(mid, d, keepout, tip)
	return tip


## A map tag's label moved out of `keepout` (v0.11 M6): its plate over the diamond would lie under the stack, so it goes to the diamond's
## right, else below it; the plate over it again (and so no label, the keepout counting as placed) when neither is clear.
static func _label_aside(text: String, c: Vector2, mark: float, keepout: Rect2, view: Vector2) -> Rect2:
	var wide := plate_size(text).x
	var centres: Array[Vector2] = [c + Vector2(mark + LABEL_GAP + wide * 0.5, 0.0), c + Vector2(0.0, mark + LABEL_GAP + PLATE_H * 0.5)]
	for centre in centres:
		var r := label_rect(text, centre, view)
		if not r.intersects(keepout):
			return r
	return label_rect(text, c - Vector2(0.0, mark + LABEL_GAP + PLATE_H * 0.5), view)


## An arrow's label moved out of `keepout` (v0.11 M6): a plate beside the arrow's disc, to its right and level with it, and no higher
## than the keepout's bottom while it still lies within the keepout's width -- where label_rect()'s plate, centred away from the tip
## along its heading, would straddle the stack's border (an arrow bound mostly up or left).
static func _label_beside(text: String, tip: Vector2, d: Vector2, keepout: Rect2, view: Vector2) -> Rect2:
	var box := plate_size(text)
	var disc := tip - d * 5.0
	var at := Vector2(disc.x + 11.0, disc.y - box.y * 0.5)
	if at.x < keepout.end.x:
		at.y = maxf(at.y, keepout.end.y + 1.0)
	return Rect2(at.round().clamp(Vector2.ZERO, (view - box).max(Vector2.ZERO)), box)


## Where the line from `mid` along `d` first meets `keepout`'s border (v0.11 M6): its right edge or its bottom, whichever comes first --
## the stack sits in the screen's top-left corner, the frame's centre below and right of it. The final review's guard: a line that
## never meets either (a keepout reaching past the frame's centre, or a zero heading -- neither happens with the HUD's stack, which
## stops well short of the centre) gets `fallback`, the frame's own edge point, never the centre of the screen.
static func _keepout_point(mid: Vector2, d: Vector2, keepout: Rect2, fallback: Vector2) -> Vector2:
	var best := INF
	if d.x < 0.0:
		var k := (keepout.end.x - mid.x) / d.x
		var y := mid.y + d.y * k
		if k > 0.0 and y >= keepout.position.y - 0.01 and y <= keepout.end.y + 0.01:
			best = minf(best, k)
	if d.y < 0.0:
		var k := (keepout.end.y - mid.y) / d.y
		var x := mid.x + d.x * k
		if k > 0.0 and x >= keepout.position.x - 0.01 and x <= keepout.end.x + 0.01:
			best = minf(best, k)
	return mid + d * best if best != INF else fallback


## The screen's size: the Control's once laid out, else 640 x 360.
func _view() -> Vector2:
	return Vector2(size.x if size.x > 1.0 else SCREEN_W, size.y if size.y > 1.0 else SCREEN_H)


## The city's state, top right, as [text, colour] pieces: each figure wears the colour of the stability part it
## drives, so the player can tell which number moves which part of the bar.
## The alarm stage's colour on the status line (v0.04), calm to red.
const STAGE_COLS := [Color("9a9484"), Color("e8e2d0"), Color("d8b23a"), Color("ff8a3a"), Color("c8342a"), Color("ff4a4a")]


func status_segments() -> Array:
	var stage := [_crowd.alarms.stage_name(), STAGE_COLS[_crowd.alarms.stage]]
	if not details:
		return [stage]  # v0.11.1: collapsed, only the alarm stage, the one figure that warns
	return [
		["Citizens %d" % _crowd.alive_citizens(), UiTheme.STABILITY_COLS[0]],
		["Soldiers %d" % _crowd.alive_soldiers(), UiTheme.STABILITY_COLS[3]],
		["Destroyed %d" % _rules.buildings_down, UiTheme.STABILITY_COLS[1]],
		stage,
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


## The slot bar (v0.11 M6's final review): every slot's rectangle in one, Rect2() with none -- tag_layout() keeps the labels off it.
func slots_rect() -> Rect2:
	var out := Rect2()
	for i in _rules.loadout.size():
		out = slot_rect(i) if i == 0 else out.merge(slot_rect(i))
	return out


## The power's name in slot `i` as its card shows it, cut to one line (taken once in setup()).
func slot_name(i: int) -> String:
	return _slot_names[i] if i >= 0 and i < _slot_names.size() else ""


## The slot under a screen point, or -1.
func slot_at(point: Vector2) -> int:
	for i in _rules.loadout.size():
		if slot_rect(i).has_point(point):
			return i
	return -1


## `quiet`: the banner comes with its own sound (a refused cast's buzz), so it does not ring ui_notice as well.
func push_banner(text: String, quiet := false) -> void:
	_banners.append([text, 0.0, quiet or _quiet_next_banner])
	_quiet_next_banner = false


func banner_up() -> bool:
	return not _banners.is_empty()


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
		push_banner("NO ONE TO WHISPER TO", true)
	elif reason == "shaken":
		# v0.11 M5 (the final review): a director that knows why says so in place of the plain words, in one banner.
		var words := _rules.director.refused_words(slot, reason) if _rules.director != null else ""
		push_banner(words if words != "" else "THEY SHAKE OFF THE WHISPER", true)
	UiSound.play(&"ui_buzz")


func _on_recharged(_slot: int) -> void:
	var frame := Engine.get_process_frames()
	if frame != _ready_rang:
		_ready_rang = frame
		UiSound.play(&"ui_ready")


func _on_surged() -> void:
	UiSound.play(&"ui_surge")
	_quiet_next_banner = true


## Everything the HUD shows, as one string. Cheap to build, and it means a still frame is not redrawn sixty
## times a second while a four-minute mission's effects are already busy.
func _signature() -> String:
	var out := "%s|%s|%s|%d|%s" % [UiTheme.clock(_rules.time_left),
		objective_text() if _rules.mission.scored else str(_rows_now()), status_text(),
		roundi(_rules.stability.total() * 200.0), rite_text()]
	var events := event_rows()
	if not events.is_empty():
		out += "|" + str(events)
	out += "|" + clock_badge()  # v0.11.2: the Lantern's stage (the badge says which, the ring follows it)
	out += "|" + (_hint_now() if hint_shown() else "")
	out += "|" + _caption
	out += "|%s" % intro
	out += "|%s|%s|%s|%d" % [str(wish_rows()), ascend_shown(), praying, roundi(gaze_of(_rules) * 100.0)]
	out += "|%s|%s" % [details, wish_summary()]
	if chain_shown():
		out += "|%s|%s|%s" % [chain_state(), chain_aiming, chain_rect().position.y]  # god P3: the chain plate's words, aim and lift
	out += "|" + "/".join(_rite_lines)
	for i in _rules.loadout.size():
		out += "%s%d%s," % [slot_state(i), roundi(_rules.cooldown_left(i) * 4.0), ("p%d" % _aim.mode_index()) if is_picked(i) else ""]
	return out


## What the tag layer shows, in short (board tags): the camera, the screen and every tag's fields -- everything
## tag_layout() lays the tags out from. "" with nothing tagged.
func _tag_signature(with_stack := true) -> String:
	var tags := all_tags()
	if tags.is_empty():
		return ""
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	# v0.11 M6: the stack is the layout's keepout, so the layer redraws when its size changes (a wish row comes or goes); the final
	# review: the strip and the slot bar are placed for the labels, so the same for them (`with_stack` false leaves all three out).
	var out := "%s|%s|%s" % [xf, _view(), stack_rect() if with_stack else Rect2()]
	if with_stack:
		out += "|%s|%s|%s" % [events_rect(_view().x), slots_rect(), chain_rect() if chain_shown() else Rect2()]
	# v0.11.1 §3: which bare arrow the mouse is over (from the last layout: one frame late, no layout needed here) and whether all show.
	out += "|%s|%d" % [details, hovered_arrow(_layout, _hover_point())]
	for t in tags:
		out += "|%s%s%s%s%s%s%s%s%s%d" % [t.at, t.color.to_html(), t.label, t.rise, t.lift, t.size, t.edge, t.outline, t.valid(),
			roundi(t.ring * 48.0)]  # god P3: a ring filling (a grip on a standing captive) redraws the layer
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
	_frame_wishes = _build_wish_rows()  # v0.11.1: the wish rows are built once a draw, not once a plate
	_draw_rise()
	_draw_clock(w)
	_draw_rite(w)
	if not intro and not rite_plate_up():
		_draw_play_plates(w)
	_draw_banners(w)
	_draw_subtitle(w)
	_draw_prayers(w)
	_draw_caption(w)
	_draw_rite_plate(w)  # god P3: a won rite's plate stands in place of the stack, the strip and the slots
	if not rite_plate_up():
		_draw_ascend()
		_draw_chain()
		_draw_slots(w)
	_frame_wishes = null


func _draw_clock(w: float) -> void:
	var s := UiTheme.clock(_rules.time_left)
	var col := UiTheme.COL_TEXT
	if _rules.time_left <= HURRY_AT:
		# One pulse a second, so the last half minute is felt without a tween.
		col = UiTheme.COL_BAD if fmod(_rules.time_left, 1.0) > 0.5 else Color("ff8a72")
	var x := roundf((w - UiTheme.width(s, UiTheme.SIZE_BIG)) * 0.5)
	UiTheme.text(self, Vector2(x, 18.0), s, UiTheme.SIZE_BIG, col)
	_draw_clock_lantern(x, UiTheme.width(s, UiTheme.SIZE_BIG))


## The badge beside the clock while the Lantern hastens dawn (v0.11.2, spec 5.1): "x1.5" Stirring, "x2.0" Burning, with the multiplication sign
## when the pixel font has it (Decision 29); "" for Asleep, Blind and a night with no Lantern.
func clock_badge() -> String:
	if _rules == null or _rules.lantern == null:
		return ""
	var badge := _rules.lantern.badge()
	return badge.replace("x", String.chr(0xD7)) if badge != "" and UiTheme.font().has_char(0xD7) else badge


## The ring round the clock: the Lantern's gold at Stirring, red at Burning, transparent otherwise.
func clock_ring() -> Color:
	if _rules == null or _rules.lantern == null:
		return Color(0.0, 0.0, 0.0, 0.0)
	match _rules.lantern.stage:
		LanternWatch.Stage.STIRRING:
			return LANTERN_GOLD
		LanternWatch.Stage.BURNING:
			return LANTERN_RED
	return Color(0.0, 0.0, 0.0, 0.0)


## The ring, the drawn lantern mark left of it and the badge right of it, collapsed or not (TAB never hides them).
func _draw_clock_lantern(x: float, clock_w: float) -> void:
	var ring := clock_ring()
	if ring.a <= 0.0:
		return
	var plate := Rect2(x - 7.0, 2.0, clock_w + 14.0, 20.0)
	draw_rect(plate, ring, false, 1.0)
	var mark := Vector2(plate.position.x - 12.0, 5.0)  # a small lantern: the cap, the glass, the flame, the foot
	draw_rect(Rect2(mark + Vector2(2.0, 0.0), Vector2(4.0, 1.0)), ring)
	draw_rect(Rect2(mark + Vector2(1.0, 1.0), Vector2(6.0, 8.0)), Color(0.04, 0.04, 0.06, 0.8))
	draw_rect(Rect2(mark + Vector2(1.0, 1.0), Vector2(6.0, 8.0)), ring, false, 1.0)
	draw_rect(Rect2(mark + Vector2(3.0, 4.0), Vector2(2.0, 3.0)), ring)
	draw_rect(Rect2(mark + Vector2(1.0, 9.0), Vector2(6.0, 1.0)), ring)
	UiTheme.text(self, Vector2(plate.end.x + 5.0, 17.0), clock_badge(), UiTheme.SIZE_BODY, ring)


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
	draw_rect(objective_panel(), UiTheme.COL_PANEL)
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
	# The legend: a swatch and a short name for each part, in the bar's order (v0.11.1: expanded only; the H legend has it).
	var lx := 6.0
	for entry: Array in (LEGEND if details else []):
		draw_rect(Rect2(lx, 31.0, 5.0, 5.0), UiTheme.STABILITY_COLS[int(entry[1])])
		UiTheme.text(self, Vector2(lx + 7.0, 38.0), String(entry[0]), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		lx += 7.0 + UiTheme.width(String(entry[0]), UiTheme.SIZE_SMALL) + 8.0
	var count := _rules.escaped_this_act()
	var limit := escape_limit()
	var escaped := "Escaped %d / %d" % [count, limit]
	var col := UiTheme.COL_BAD if count >= limit - 8 else UiTheme.COL_DIM
	var escaped_y := ESCAPED_Y if details else ESCAPED_Y_SHORT
	UiTheme.text(self, Vector2(6.0, escaped_y), escaped, UiTheme.SIZE_SMALL, col)
	var gaze := gaze_readout()
	if gaze != "":
		# Tier 5's Gaze (v0.11 M1) beside the escapes, readable while the rite's plate takes the bar's place; v0.11.1: left of the cue.
		UiTheme.text(self, Vector2(cue_rect().position.x - 6.0 - UiTheme.width(gaze, UiTheme.SIZE_SMALL), escaped_y), gaze,
			UiTheme.SIZE_SMALL, UiTheme.COL_GOLD.lerp(UiTheme.COL_BAD, gaze_of(_rules)))


## The objective panel of a mission without a score (v0.08): objective_rows(), each with its tick or cross after it.
func _draw_rows() -> void:
	var rows := rows_shown()
	if rows.is_empty():
		return
	draw_rect(objective_rect(), UiTheme.COL_PANEL)
	var y := 14.0
	for row: Array in rows:
		var text := String(row[0])
		UiTheme.text(self, Vector2(6.0, y), text, UiTheme.SIZE_SMALL)
		if String(row[1]) != "":
			UiTheme.mark(self, Vector2(6.0 + UiTheme.width(text, UiTheme.SIZE_SMALL) + 5.0, y - 7.0), String(row[1]) == "ok")
		y += ROW_H


## The cue (v0.11.1 §1.1): "TAB more" / "TAB less" dim on a plate at the right end of the objective row.
func _draw_cue() -> void:
	var cue := cue_rect()
	if cue.has_area():
		_plate(cue.position, cue_text(), UiTheme.COL_DIM)


## The how-to-win line (v0.10 M6) on its own dark plate under the objectives, in HINT_COL.
func _draw_hint() -> void:
	var lines := _lines_now()
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
	var rows := wish_rows_shown()
	if rows.is_empty():
		return
	var top := wishes_top()
	draw_rect(wishes_rect(), UiTheme.COL_PANEL)
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


## The plates that wait for play (v0.11.1: not drawn during the intro): the Gaze bar, the strip, the objectives, the how-to-win
## line, the wishes and the status line.
func _draw_play_plates(w: float) -> void:
	_draw_gaze(w)
	_draw_events(w)
	if _rules.mission.scored:
		_draw_objectives()
	else:
		_draw_rows()
	_draw_cue()
	_draw_hint()
	_draw_wishes()
	_draw_status(w)


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
		var half := (9.0 - float(i) * 3.0) * (1.0 - k * 0.5) * _rise_scale
		var col := RISE_COL
		col.a = (0.16 + 0.18 * float(i)) * (1.0 - k)
		draw_rect(Rect2(foot.x - half, top, half * 2.0, maxf(foot.y - top, 1.0)), col)


## An arrow at the screen's edge (v0.10 M6's tags): `col` on a dark disc ringed in `ring`, its tip at
## `at`, pointing along `dir`. On a dark disc, so it stands out from the town's warm roofs and stalls.
func _draw_arrow(at: Vector2, dir: Vector2, col: Color, ring: Color) -> void:
	paint_arrow(_canvas, at, dir, col, ring)


## The arrow's triangle, its tip at `at`, pointing along `dir`: the one shape the HUD and the legend (LegendPanel) share.
static func arrow_shape(at: Vector2, dir: Vector2) -> PackedVector2Array:
	var side := Vector2(-dir.y, dir.x)
	return PackedVector2Array([at, at - dir * 10.0 + side * 6.0, at - dir * 10.0 - side * 6.0])


## _draw_arrow()'s drawing on any canvas (the legend draws the same arrow).
static func paint_arrow(on: CanvasItem, at: Vector2, dir: Vector2, col: Color, ring: Color) -> void:
	on.draw_circle(at - dir * 5.0, 10.0, MARK_EDGE)
	on.draw_arc(at - dir * 5.0, 10.0, 0.0, TAU, 24, ring, -1.0)
	var arrow := arrow_shape(at, dir)
	on.draw_colored_polygon(arrow, col)
	arrow.append(arrow[0])
	on.draw_polyline(arrow, MARK_EDGE, -1.0)


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
	var labels := _modes_labels(modes)
	var x := modes_rect(box).position.x
	var y := box.position.y - PLATE_H - 3.0
	for k in labels.size():
		var col := UiTheme.COL_DIM if k == 0 else (UiTheme.COL_GOLD if k - 1 == _aim.mode_index() else UiTheme.COL_TEXT)
		_plate(Vector2(x, y), labels[k], col)
		x += UiTheme.width(labels[k], UiTheme.SIZE_SMALL) + 6.0


## The labels of a focused power's modes plate: the keys, then each mode's name.
func _modes_labels(modes: Array) -> Array[String]:
	var labels: Array[String] = ["Q/E"]
	for m: Dictionary in modes:
		labels.append(String(m.name))
	return labels


## Where the focused power's modes plate is drawn over its slot `box` (god P3 pre-flight R2: the chain plate steps clear of it); Rect2() when the
## focused power has no modes. `box` defaults to the focused slot's.
func modes_rect(box := Rect2()) -> Rect2:
	if _aim == null or _rules == null or _aim.slot < 0 or _aim.slot >= _rules.loadout.size():
		return Rect2()
	var modes := _aim.modes()
	if modes.is_empty():
		return Rect2()
	if not box.has_area():
		box = slot_rect(_aim.slot)
	var total := 0.0
	for l in _modes_labels(modes):
		total += UiTheme.width(l, UiTheme.SIZE_SMALL) + 6.0
	var x := clampf(box.position.x, 2.0, maxf(_view().x - total - 2.0, 2.0))
	return Rect2(x, box.position.y - PLATE_H - 3.0, total, PLATE_H)


# --- The chain plate and the rite's win plate (god P3) -------------------------------------------

## The rite's director, or null off a rite.
func _rite_director() -> RiteDirector:
	return _rules.director as RiteDirector if _rules != null else null


## The chain plate shows (god P3, MS §2): in a rite, in play (the tour's caption would lie over it), until the night is over.
func chain_shown() -> bool:
	return _rules != null and _rules.director is RiteDirector and not intro and not _rules.finished and not rite_plate_up()


## The chain plate's rectangle (MS §2, R7): 100 x 20 above the slot row's right end, CHAIN_GAP above SLOT_TOP; centred with no slots. Pre-flight R2:
## when the focused power's modes plate (Decree's The Bell Lies in the last slot) would lie under it, it steps up one PLATE_H + CHAIN_GAP.
func chain_rect() -> Rect2:
	if _rules == null:
		return Rect2()
	var left := roundf((_view().x - CHAIN_SIZE.x) * 0.5) if _rules.loadout.is_empty() else slots_rect().end.x - CHAIN_SIZE.x
	var r := Rect2(left, SLOT_TOP - CHAIN_GAP - CHAIN_SIZE.y, CHAIN_SIZE.x, CHAIN_SIZE.y)
	if modes_rect().intersects(r):
		r.position.y -= PLATE_H + CHAIN_GAP
	return r


## The plate's label.
func chain_label() -> String:
	return CHAIN_LABEL


## The plate's state words: READY, DRAG 0:41 or the cooldown's clock (the director's chain_plate()); "" off a rite.
func chain_state() -> String:
	var d := _rite_director()
	return d.chain_plate() if d != null else ""


## A chain was refused (god P3, MS §2): the plate flashes red, a buzz sounds and the words show as a quiet banner (the buzz is its sound).
func chain_refused(text: String) -> void:
	_chain_flash = FLASH_SECONDS
	push_banner(text, true)
	UiSound.play(&"ui_buzz")


## The chain plate is still red from a refusal.
func chain_flashing() -> bool:
	return _chain_flash > 0.0


## The plate: the icon, the label over the state, in a frame that turns gold while C's aim is up. Two lines of capitals in 20 px.
func _draw_chain() -> void:
	if not chain_shown():
		return
	var r := chain_rect()
	var d := _rite_director()
	var ready := d != null and d.chain_state == RiteDirector.Chain.READY
	draw_rect(r, UiTheme.COL_PANEL)
	if chain_flashing():
		var red := UiTheme.COL_BAD
		red.a = _chain_flash / FLASH_SECONDS
		draw_rect(r, red)
	if _chain_icon == null:
		_chain_icon = PowerBook.hud_icon(CHAIN_ICON)
	if _chain_icon != null:
		draw_texture_rect(_chain_icon, Rect2(r.position + Vector2(2.0, 2.0), Vector2.ONE * CHAIN_ICON_SIZE), false,
			Color.WHITE if ready else Color(0.45, 0.45, 0.5))
	UiTheme.frame(self, r, chain_aiming)
	var x := r.position.x + CHAIN_ICON_SIZE + 6.0
	UiTheme.text(self, Vector2(x, r.position.y + 9.0), chain_label(), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if chain_aiming else UiTheme.COL_TEXT)
	UiTheme.text(self, Vector2(x, r.position.y + 18.0), chain_state(), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if ready else UiTheme.COL_DIM)


## A won rite's plate (MS §5, plan P3-18): the lines (RiteBook.plate_lines()) replace the stack, the strip, the chain plate and the slots until the
## results come.
func show_rite_plate(lines: PackedStringArray) -> void:
	_rite_lines = lines
	queue_redraw()


## The win plate is up.
func rite_plate_up() -> bool:
	return not _rite_lines.is_empty()


## The win plate's rectangle: centred, RITE_PLATE_TOP to RITE_PLATE_TOP + RITE_PLATE_H, as wide as its widest line (the third wraps at RITE_PLATE_WRAP);
## Rect2() while it is not up.
func rite_plate_rect() -> Rect2:
	if not rite_plate_up():
		return Rect2()
	var wide := UiTheme.width(_rite_lines[0], UiTheme.SIZE_BIG)
	if _rite_lines.size() > 1:
		wide = maxf(wide, UiTheme.width(_rite_lines[1], UiTheme.SIZE_BODY))
	for l in _rite_rest():
		wide = maxf(wide, UiTheme.width(l, UiTheme.SIZE_SMALL))
	wide = minf(wide + 32.0, _view().x - 8.0)
	return Rect2(roundf((_view().x - wide) * 0.5), RITE_PLATE_TOP, wide, RITE_PLATE_H)


## The plate's third and later lines as drawn: wrapped to RITE_PLATE_WRAP.
func _rite_rest() -> PackedStringArray:
	var out := PackedStringArray()
	for i in range(2, _rite_lines.size()):
		out.append_array(UiTheme.wrap(_rite_lines[i], RITE_PLATE_WRAP, UiTheme.SIZE_SMALL))
	return out


## The win plate drawn: the title in gold, the points, then the stolen gift wrapped, on a gold-framed dark plate (MS §5).
func _draw_rite_plate(w: float) -> void:
	if not rite_plate_up():
		return
	var r := rite_plate_rect()
	draw_rect(r, Color(0.07, 0.055, 0.02, 0.94))
	UiTheme.frame(self, r, true)
	var title := _rite_lines[0]
	UiTheme.text(self, Vector2(roundf((w - UiTheme.width(title, UiTheme.SIZE_BIG)) * 0.5), r.position.y + 26.0), title, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var y := r.position.y + 46.0
	if _rite_lines.size() > 1:
		var points := _rite_lines[1]
		UiTheme.text(self, Vector2(roundf((w - UiTheme.width(points, UiTheme.SIZE_BODY)) * 0.5), y), points, UiTheme.SIZE_BODY)
		y += 16.0
	for l in _rite_rest():
		UiTheme.text(self, Vector2(roundf((w - UiTheme.width(l, UiTheme.SIZE_SMALL)) * 0.5), y), l, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		y += UiTheme.LINE_SMALL


## A short label on a dark plate, `at` being the plate's top-left corner.
func _plate(at: Vector2, label: String, col: Color) -> void:
	_canvas.draw_rect(Rect2(at, plate_size(label)), Color(0, 0, 0, 0.62))
	UiTheme.text(_canvas, at + Vector2(1.0, PLATE_H - 3.0), label, UiTheme.SIZE_SMALL, col)
