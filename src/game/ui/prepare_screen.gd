class_name PrepareScreen
extends Node
## Prepare (spec §1, §5): the briefing and the card under the mouse on the left; on the right the powers by Authority
## (v0.08: a tab per Authority -- v0.06's were kinds -- over a grid of the open tab's cards), and under them the
## loadout bar -- the picks in slot order, whichever tab they came from -- with MANIFEST once there is one.
##
## One deviation from the spec's layout, forced by 640x360: the cards carry the 42-pixel HUD icons, and the
## 84-pixel card art is shown large in the left panel for the card under the mouse, with the power's shape.

## "manifest" (a power is picked and the player pressed MANIFEST or Enter) or "back" (Esc).
signal action(name: String)

const CARD := Vector2(140.0, 50.0)
const GAP := 6.0
const GRID_AT := Vector2(196.0, 60.0)
const COLUMNS := 3
## The tabs above the grid, one per PowerBook.AUTHORITIES: six share the grid's 432 px (v0.08).
const TAB_AT := Vector2(196.0, 40.0)
const TAB := Vector2(68.0, 16.0)
const TAB_GAP := 4.0
## The loadout bar under the grid: the mission's slots, then MANIFEST. SLOT is a slot's size when there are four.
const LOADOUT_BAR := Rect2(196.0, 280.0, 432.0, 32.0)
const SLOT := Vector2(84.0, 28.0)
## A loadout slot narrower than this shows its icon and number without the name.
const SLOT_NAME_MIN := 70.0
const MANIFEST_RECT := Rect2(552.0, 282.0, 76.0, 28.0)
## The left panel: briefing above, the card under the mouse below.
const PANEL := Rect2(8.0, 40.0, 180.0, 274.0)
## The 1-4 badge on a picked card: large enough for the body size, where 2 and 3 do not read as 8.
const BADGE := 15.0
## The gap between the briefing's widest label and its values.
const LABEL_GAP := 6.0

## The mission being prepared (v0.08): its briefing, its slots and the powers it allows. Last Judgement until setup().
var mission: MissionDef = MissionBook.last_judgement()
var draft := Draft.new()
## The open tab: an index into PowerBook.AUTHORITIES.
var tab := 0
## The difficulty chosen here (v0.05), and the town responses it brings (the Defense Profile strip at the bottom).
var difficulty := ResponseProfile.DEFAULT
## The bottom strip: the difficulty selector on the left, the Defense Profile beside it.
const STRIP := Rect2(8.0, 318.0, 624.0, 38.0)
const ARROW := Vector2(14.0, 14.0)
## The Defense Profile's columns run from the right of the selector to the strip's edge less the padding the selector has on
## the left, with at least COLUMN_GAP between them.
const PROFILE_LEFT := 168.0
const PROFILE_RIGHT := 626.0
const COLUMN_GAP := 8.0

var _ui: Control
## Both icon sizes, loaded once here and never inside _draw() (a texture loaded while drawing can reach the
## draw list before the GPU has it and paint a white block that stays).
var _icons := {}
var _art := {}
## The power key under the mouse, "manifest", or "".
var _hover := ""
## Each power's preview sheet, loaded once in setup() like the icons.
var _clips := {}
var _clip_t := 0.0
var _clip_frame := 0


func setup(def: MissionDef, preselect: PackedStringArray, tier := ResponseProfile.DEFAULT) -> PrepareScreen:
	mission = def
	draft = Draft.new().for_mission(mission)
	draft.preselect(preselect)
	# Open on the tab of the first pick, so a returning player sees where their loadout starts.
	tab = maxi(PowerBook.AUTHORITIES.find(PowerBook.authority_of(draft.picks[0])), 0) if not draft.picks.is_empty() else 0
	difficulty = tier
	for p: Dictionary in PowerBook.POWERS:
		var key := String(p.key)
		_icons[key] = PowerBook.hud_icon(key)
		_art[key] = PowerBook.icon(key)
		_clips[key] = PowerBook.clip(key)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## Where the open tab's card `i` sits.
static func cell_rect(i: int) -> Rect2:
	var col := i % COLUMNS
	var row := i / COLUMNS
	return Rect2(GRID_AT + Vector2(float(col) * (CARD.x + GAP), float(row) * (CARD.y + GAP)), CARD)


static func tab_rect(i: int) -> Rect2:
	return Rect2(TAB_AT + Vector2(float(i) * (TAB.x + TAB_GAP), 0.0), TAB)


## A power's cooldown as the cards print it: whole seconds stay whole ("20 s"), a fraction shows one decimal ("2.5 s").
static func cooldown_text(p: Dictionary) -> String:
	var seconds := float(p.cooldown)
	return "%d s" % roundi(seconds) if is_equal_approx(seconds, roundf(seconds)) else "%.1f s" % seconds


## The loadout bar's slot `i`, from 0, of `count`: the slots share the bar left of MANIFEST (v0.08: up to six).
static func slot_rect(i: int, count := 4) -> Rect2:
	var room := MANIFEST_RECT.position.x - 4.0 - LOADOUT_BAR.position.x
	var w := floorf((room - 4.0 * float(count)) / float(count))
	return Rect2(Vector2(LOADOUT_BAR.position.x + 4.0 + float(i) * (w + 4.0), LOADOUT_BAR.position.y + 2.0), Vector2(w, SLOT.y))


## The open tab's power keys, in PowerBook order: those the mission allows.
func shown() -> PackedStringArray:
	return authority_keys(tab)


## Tab `i`'s power keys that the mission allows, in PowerBook order.
func authority_keys(i: int) -> PackedStringArray:
	var out := PackedStringArray()
	for key in PowerBook.of_authority(PowerBook.AUTHORITIES[i]):
		if mission.allows(key):
			out.append(key)
	return out


func set_tab(i: int) -> void:
	tab = posmod(i, PowerBook.AUTHORITIES.size())
	if _ui != null:
		_ui.queue_redraw()


## What is under a point: a power key, "tab:<i>", "slot:<i>", "manifest", the difficulty arrows, or "".
func hit(point: Vector2) -> String:
	for i in PowerBook.AUTHORITIES.size():
		if tab_rect(i).has_point(point):
			return "tab:%d" % i
	var keys := shown()
	for i in keys.size():
		if cell_rect(i).has_point(point):
			return String(keys[i])
	for i in draft.slots:
		if slot_rect(i, draft.slots).has_point(point):
			return "slot:%d" % i
	if MANIFEST_RECT.has_point(point):
		return "manifest"
	if arrow_rect(-1).has_point(point):
		return "diff_prev"
	if arrow_rect(1).has_point(point):
		return "diff_next"
	return ""


## The difficulty selector's arrows: -1 the left one, 1 the right one.
static func arrow_rect(side: int) -> Rect2:
	var y := STRIP.position.y + 12.0
	var x := STRIP.position.x + 6.0 if side < 0 else STRIP.position.x + 130.0
	return Rect2(Vector2(x, y), ARROW)


## Step the difficulty by `by`, wrapping.
func step_difficulty(by: int) -> void:
	difficulty = posmod(int(difficulty) + by, ResponseProfile.NAMES.size()) as ResponseProfile.Tier
	UiSound.play(&"ui_click")
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			action.emit("back")
		elif event.physical_keycode == KEY_LEFT:
			step_difficulty(-1)
		elif event.physical_keycode == KEY_RIGHT:
			step_difficulty(1)
		elif event.physical_keycode == KEY_TAB:
			UiSound.play(&"ui_click")
			set_tab(tab + (-1 if event.shift_pressed else 1))
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and draft.can_manifest():
			UiSound.play(&"ui_manifest")
			action.emit("manifest")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			_clip_t = 0.0
			_clip_frame = 0
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := hit(event.position)
		if h == "diff_prev" or h == "diff_next":
			step_difficulty(-1 if h == "diff_prev" else 1)
		elif h.begins_with("tab:"):
			UiSound.play(&"ui_click")
			set_tab(int(h.substr(4)))
		elif h.begins_with("slot:"):
			# A filled slot gives its pick back.
			var i := int(h.substr(5))
			if i < draft.picks.size():
				UiSound.play(&"ui_click")
				draft.toggle(draft.picks[i])
				_ui.queue_redraw()
		elif h == "manifest":
			if draft.can_manifest():
				UiSound.play(&"ui_manifest")
				action.emit("manifest")
			else:
				UiSound.play(&"ui_buzz")
		elif h != "":
			UiSound.play(&"ui_click")
			draft.toggle(h)
			_ui.queue_redraw()


## The power the mouse is over: a card's, or the pick in a loadout slot's.
func _hover_key() -> String:
	if _hover.begins_with("slot:"):
		var i := int(_hover.substr(5))
		return draft.picks[i] if i < draft.picks.size() else ""
	return _hover


func _process(delta: float) -> void:
	if _clips.get(_hover_key()) == null:
		return
	_clip_t += delta
	var f := int(_clip_t * PowerBook.CLIP_FPS) % PowerBook.CLIP_FRAMES
	if f != _clip_frame:
		_clip_frame = f
		_ui.queue_redraw()


## Show a power's preview as if the mouse were on its card -- for photographs of this screen.
func preview(key: String) -> void:
	_hover = key
	if PowerBook.AUTHORITIES.has(PowerBook.authority_of(key)):
		tab = PowerBook.AUTHORITIES.find(PowerBook.authority_of(key))
	_clip_t = 0.0
	_clip_frame = 0
	_ui.queue_redraw()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "PREPARE THE MANIFESTATION", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	_draw_panel()
	_draw_tabs()
	var keys := shown()
	for i in keys.size():
		_draw_card(i, String(keys[i]))
	_draw_loadout()
	_draw_profile()


## The Authorities' tabs: the open one gold-framed; a gold mark on any tab holding a pick.
func _draw_tabs() -> void:
	for i in PowerBook.AUTHORITIES.size():
		var r := tab_rect(i)
		var open := i == tab
		_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if open else (Color(0.1, 0.09, 0.07, 0.9) if _hover == "tab:%d" % i
			else UiTheme.COL_PANEL))
		UiTheme.frame(_ui, r, open)
		var keys := authority_keys(i)
		# The count goes when it would not fit beside the title ("LIFE/DEATH" fills a sixth of the row).
		var title: String = PowerBook.AUTHORITY_TITLES[i]
		var label := "%s %d" % [title, keys.size()]
		if UiTheme.width(label, UiTheme.SIZE_SMALL) > r.size.x - 10.0:
			label = title
		UiTheme.text(_ui, Vector2(r.position.x + 5.0, r.end.y - 4.0), label, UiTheme.SIZE_SMALL,
			UiTheme.COL_GOLD if open else UiTheme.COL_TEXT)
		var picked := false
		for key in keys:
			picked = picked or draft.slot_of(key) > 0
		if picked:
			_ui.draw_rect(Rect2(r.end - Vector2(8.0, 10.0), Vector2(3.0, 3.0)), UiTheme.COL_GOLD)


## Where the Defense Profile's three columns start, left to right between `left` and `right`: each as wide as its widest
## line (line i is in column i % 3), the space left over shared between the two gaps (at least COLUMN_GAP each).
static func profile_columns(lines: PackedStringArray, left: float, right: float) -> PackedFloat32Array:
	var widths := [0.0, 0.0, 0.0]
	for i in lines.size():
		widths[i % 3] = maxf(widths[i % 3], UiTheme.width(lines[i], UiTheme.SIZE_SMALL))
	var gap := maxf(COLUMN_GAP, (right - left - widths[0] - widths[1] - widths[2]) * 0.5)
	var out := PackedFloat32Array([left, 0.0, 0.0])
	out[1] = left + widths[0] + gap
	out[2] = out[1] + widths[1] + gap
	return out


## The bottom strip: "< ORGANIZED >" and the Defense Profile -- what the town will do this time.
func _draw_profile() -> void:
	_ui.draw_rect(STRIP, UiTheme.COL_PANEL)
	UiTheme.frame(_ui, STRIP, false)
	var profile := ResponseProfile.for_tier(difficulty)
	for side in [-1, 1]:
		var r := arrow_rect(side)
		_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == ("diff_prev" if side < 0 else "diff_next") else Color(0, 0, 0, 0.5))
		UiTheme.text(_ui, r.position + Vector2(4.0, 11.0), "<" if side < 0 else ">", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(STRIP.position.x + 6.0, STRIP.position.y + 9.0), "DIFFICULTY", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	var name := profile.tier_name().to_upper()
	var mid := (arrow_rect(-1).end.x + arrow_rect(1).position.x) * 0.5
	UiTheme.text(_ui, Vector2(roundf(mid - UiTheme.width(name, UiTheme.SIZE_SMALL) * 0.5), STRIP.position.y + 23.0), name,
		UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	# The Defense Profile right of the selector: its label and the tier's blurb, then the responses in three columns.
	var x0 := PROFILE_LEFT
	var label := "DEFENSE PROFILE"
	UiTheme.text(_ui, Vector2(x0, STRIP.position.y + 9.0), label, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(x0 + UiTheme.width(label, UiTheme.SIZE_SMALL) + 8.0, STRIP.position.y + 9.0),
		ResponseProfile.BLURBS[difficulty], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	var lines := profile.lines()
	var cols := profile_columns(lines, PROFILE_LEFT, PROFILE_RIGHT)
	for i in lines.size():
		UiTheme.text(_ui, Vector2(cols[i % 3], STRIP.position.y + 9.0 + UiTheme.LINE_SMALL * float(1 + i / 3)),
			lines[i], UiTheme.SIZE_SMALL)


## The left panel: the briefing, or -- while the mouse is on a power -- that power's card: its name, its preview clip,
## its price and how it is aimed, what it does and its Authority. (v0.06: the briefing had grown under the clip.)
func _draw_panel() -> void:
	_ui.draw_rect(PANEL, UiTheme.COL_PANEL)
	var hover := _hover_key()
	var p := PowerBook.get_power(hover)
	if not p.is_empty():
		_draw_power_card(hover, p)
		return
	var brief := [
		["TARGET", mission.brief[0] if not mission.brief.is_empty() else mission.name],
		["WIN", mission.goal],
		["LOSE", "%d citizens escape, or the time runs out" % Rules.ESCAPE_LIMIT],
		["CITY", "%d citizens, %d soldiers, a nine-part fortress" % [Crowd.CITIZENS, Crowd.SOLDIERS]],
		["POWER", "%d DP for the loadout; none is spent in the mission" % mission.dp_capacity],
		["TEMPLE", "Its fall resets every cooldown, once"],
	]
	# Values start just right of the widest label, measured rather than guessed -- a guessed column ran
	# TARGET into "Aldermere".
	var value_x := 0.0
	for pair: Array in brief:
		value_x = maxf(value_x, UiTheme.width(String(pair[0]), UiTheme.SIZE_SMALL))
	value_x = roundf(value_x + 4.0 + LABEL_GAP)
	var y := PANEL.position.y + 10.0
	for pair: Array in brief:
		UiTheme.text(_ui, Vector2(PANEL.position.x + 4.0, y), String(pair[0]), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		for line in UiTheme.wrap(String(pair[1]), PANEL.size.x - value_x - 4.0, UiTheme.SIZE_SMALL):
			UiTheme.text(_ui, Vector2(PANEL.position.x + value_x, y), line, UiTheme.SIZE_SMALL)
			y += UiTheme.LINE_SMALL
		y += 3.0
	var hint := UiTheme.wrap("Pick four powers, in the order you want them", PANEL.size.x - 8.0, UiTheme.SIZE_SMALL)
	for i in hint.size():
		UiTheme.text(_ui, Vector2(PANEL.position.x + 4.0, PANEL.end.y - 8.0 - UiTheme.LINE_SMALL * float(hint.size() - 1 - i)),
			hint[i], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


func _draw_power_card(key: String, p: Dictionary) -> void:
	var tx := PANEL.position.x + 6.0
	var y := PANEL.position.y + 14.0
	UiTheme.text(_ui, Vector2(tx, y), String(p.name), UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	y += 6.0
	var clip_rect := Rect2(Vector2(PANEL.position.x + (PANEL.size.x - PowerBook.CLIP_SIZE.x) * 0.5, y),
		Vector2(PowerBook.CLIP_SIZE))
	var sheet: Texture2D = _clips.get(key)
	if sheet != null:
		_ui.draw_texture_rect_region(sheet, clip_rect, PowerBook.clip_frame(_clip_frame))
	else:
		# No recording for this power: its card art, centred where the clip would be.
		var art: Texture2D = _art.get(key)
		if art != null:
			_ui.draw_texture_rect(art, Rect2(clip_rect.get_center() - Vector2(42, 42), Vector2(84, 84)), false)
	UiTheme.frame(_ui, clip_rect, true)
	y = clip_rect.end.y + 16.0
	var title := PowerBook.authority_title(PowerBook.authority_of(key))
	UiTheme.text(_ui, Vector2(tx, y), "%d DP   %s   %s" % [int(p.dp), cooldown_text(p), String(p.aim)], UiTheme.SIZE_SMALL)
	y += UiTheme.LINE_SMALL
	UiTheme.text(_ui, Vector2(tx, y), title + ("   quiet" if bool(p.get("quiet", false)) else ""), UiTheme.SIZE_SMALL,
		Color("9ab48a") if bool(p.get("quiet", false)) else UiTheme.COL_DIM)
	y += UiTheme.LINE_SMALL + 4.0
	for line in UiTheme.wrap(String(p.shape), PANEL.size.x - 12.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, y), line, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
		y += UiTheme.LINE_SMALL


func _draw_card(i: int, key: String) -> void:
	var p := PowerBook.get_power(key)
	var r := cell_rect(i)
	var slot := draft.slot_of(key)
	_ui.draw_rect(r, UiTheme.COL_PANEL if key != _hover else Color(0.1, 0.09, 0.07, 0.9))
	var icon: Texture2D = _icons.get(key)
	if icon != null:
		_ui.draw_texture_rect(icon, Rect2(r.position + Vector2(4, 4), Vector2(42, 42)), false)
	# Gold for a picked card (spec §5), so the four read at a glance across the grid.
	UiTheme.frame(_ui, r, slot > 0)
	var tx := r.position.x + 52.0
	var ty := r.position.y + 13.0
	var lines := UiTheme.wrap(String(p.name), CARD.x - 56.0, UiTheme.SIZE_SMALL)
	for k in mini(lines.size(), 2):
		UiTheme.text(_ui, Vector2(tx, ty), lines[k], UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if slot > 0 else UiTheme.COL_TEXT)
		ty += UiTheme.LINE_SMALL
	var cost := "%d DP  %s" % [int(p.dp), cooldown_text(p)]
	UiTheme.text(_ui, Vector2(tx, r.end.y - 5.0), cost, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	if bool(p.get("quiet", false)):
		# The quiet powers' mark: the town does not see them cast.
		UiTheme.text(_ui, Vector2(r.end.x - UiTheme.width("quiet", UiTheme.SIZE_SMALL) - 4.0, r.end.y - 5.0), "quiet",
			UiTheme.SIZE_SMALL, Color("9ab48a"))
	if slot > 0:
		# On the icon's corner, gold on dark like the HUD's hotkeys. Dark digits on a gold square picked up every
		# label's one-pixel shadow and read as 8, and a badge in the card's top-right corner covered long names.
		var badge := Rect2(r.position + Vector2(2.0, 2.0), Vector2(BADGE, BADGE))
		_ui.draw_rect(badge, Color(0.04, 0.04, 0.06, 0.92))
		_ui.draw_rect(badge, UiTheme.COL_GOLD, false, -1.0)
		var digit := "%d" % slot
		UiTheme.text(_ui, badge.position + Vector2(roundf((BADGE - UiTheme.width(digit, UiTheme.SIZE_BODY)) * 0.5), 12.0),
			digit, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)


## The loadout bar: the picks in slot order, whichever tab they came from (a click gives one back), then MANIFEST,
## lit once there is one (v0.08: empty slots are allowed).
func _draw_loadout() -> void:
	_ui.draw_rect(LOADOUT_BAR, UiTheme.COL_PANEL)
	for i in draft.slots:
		var r := slot_rect(i, draft.slots)
		var key := draft.picks[i] if i < draft.picks.size() else ""
		_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == "slot:%d" % i else Color(0, 0, 0, 0.35))
		UiTheme.frame(_ui, r, key != "")
		var digit := "%d" % (i + 1)
		if key == "":
			UiTheme.text(_ui, r.position + Vector2(5.0, 18.0), digit, UiTheme.SIZE_BODY, UiTheme.COL_DIM)
			continue
		var icon: Texture2D = _icons.get(key)
		if icon != null:
			_ui.draw_texture_rect(icon, Rect2(r.position + Vector2(2, 2), Vector2(24, 24)), false)
		UiTheme.text(_ui, r.position + Vector2(3.0, 12.0), digit, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		# The name, or its first word, cut to the slot's room -- none in a slot too narrow for one.
		if r.size.x < SLOT_NAME_MIN:
			continue
		var name := String(PowerBook.get_power(key).name)
		var room := r.size.x - 32.0
		if UiTheme.width(name, UiTheme.SIZE_SMALL) > room:
			name = name.split(" ")[0]
		while name.length() > 1 and UiTheme.width(name, UiTheme.SIZE_SMALL) > room:
			name = name.substr(0, name.length() - 1)
		UiTheme.text(_ui, r.position + Vector2(29.0, 17.0), name, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	var full := draft.can_manifest()  # not "ready": that is Node's own signal, and shadowing it warns
	_ui.draw_rect(MANIFEST_RECT, Color(0.12, 0.1, 0.04, 0.95) if full else Color(0, 0, 0, 0.35))
	UiTheme.frame(_ui, MANIFEST_RECT, full and _hover == "manifest")
	var label := "MANIFEST"
	var size := UiTheme.SIZE_BIG if UiTheme.width(label, UiTheme.SIZE_BIG) <= MANIFEST_RECT.size.x - 6.0 else UiTheme.SIZE_BODY
	UiTheme.text(_ui, Vector2(roundf(MANIFEST_RECT.get_center().x - UiTheme.width(label, size) * 0.5),
		MANIFEST_RECT.position.y + 19.0), label, size, UiTheme.COL_GOLD if full else UiTheme.COL_DIM)
