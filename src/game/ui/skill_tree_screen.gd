class_name SkillTreeScreen
extends Node
## The Skill Tree as a wheel (spec 2026-11-10): one Authority centred as five oval tier rings with two powers on each, the other two
## Authorities (the god's ring neighbours; far types never shown) as dim side panels, and a detail panel along the bottom with the
## selected power's looping preview clip, what it is, what its next level changes and two buttons. A click on a power only selects it;
## points are spent by the gold button. A neighbour's powers cost double. The screen edits the GodSlot it is given and emits
## "learned" so Game writes the slot, "remember" to try the selected power free in a city, and "back" (Esc or Back).

## "learned" (a point was spent: Game writes the slot), "remember" (try the selected power) or "back".
signal action(name: String)

const BACK_RECT := Rect2(6.0, 4.0, 52.0, 18.0)
const REMEMBER_RECT := Rect2(528.0, 256.0, 96.0, 26.0)
const BUY_RECT := Rect2(528.0, 286.0, 96.0, 26.0)
## The detail panel (the wheel's DETAIL strip): the clip box, the info column, the level column and the buttons sit inside it.
const DETAIL := TreeWheel.DETAIL
const CLIP_BOX := Rect2(15.0, 258.0, 152.0, 86.0)
const INFO_X := 172.0
const INFO_W := TreeDetail.DESCRIPTION_W
const LEVEL_X := 387.0
const LEVEL_W := 132.0
## A side panel's small icons: a 2x5 grid of MINI_PX squares.
const MINI_PX := 22.0
## The icon sizes asked of UiIcon.native_rect: a node's (21 u at k2, 14 u at k3: always 42 px or a multiple) and a side cell's.
const NODE_ICON_UNITS := 21.0
const MINI_ICON_UNITS := 18.0
## Where a node's name may sit, and how tall its strip is.
const LABEL_AREA := Rect2(124.0, 28.0, 392.0, 218.0)
const LABEL_STRIP_H := 13.0
const LABEL_STRIP_H2 := 25.0
## The affordable nodes' glow breathes once in this many seconds.
const PULSE_SECONDS := 1.6
## The refusal under RAISE wraps to this width (units) and at most 2 lines.
const REFUSAL_W := 96.0
## The keys hint's box (kept clear of the labels).
const HINT_RECT := Rect2(8.0, 236.0, 184.0, 14.0)
## The wheel's centre emblem, and a lock badge's place and size relative to its node.
const EMBLEM_R := 18.0
const BADGE_AT := Vector2(8.0, 8.0)
const BADGE_R := 5.0
const ORBIT_SEGMENTS := 72
## The level column's last text baseline.
const LEVEL_BOTTOM := 348.0
## The twist line count the info column has room for (baselines 333 and 345).
const TWIST_LINES := 2
## How long a refusal's reason stays up.
const REFUSE_SECONDS := 1.5
## What a refused click says, by GodSlot.refusal(); "tier" takes the spot's tier.
const REFUSALS := TreeDetail.REFUSALS

const COL_REMEMBER := Color("6fa8c8")
const COL_SELECT := Color("fff3c4")
const COL_NODE := Color("100c18")
const COL_GREEN := Color("9fe08a")
const COL_TWIST := Color("e9c96a")
const COL_LABEL := Color("f3e7c0")
const COL_LABEL_LOCKED := Color("8a8296")
const COL_STRIP := Color(0.03, 0.02, 0.06, 0.82)
const COL_RING_LOCKED := Color("4a4358", 0.8)
## Orbit segments under a label strip are drawn at this alpha.
const ORBIT_FADED := 0.12
const NODE_NAME_PX := 11
const SMALL_PX := 11
const SIZE_CHIP := 11

## Why the last buy learned nothing, shown for REFUSE_SECONDS; "" for none.
var refused_reason := ""
## Which of columns() is on the wheel (0-2), and the selected spot (column, tier 1-5, i) or (-1, -1, -1).
var centred := 1
var selected := Vector3i(-1, -1, -1)

var _refuse_left := 0.0
var _slot: GodSlot
var _ui: Control
var _hover := ""
## The spots' icons, loaded once each in setup(), not in the draw (a texture first loaded inside a draw showed white for a frame);
## null for a power with none yet. _big holds the large icons and _clips the preview sheets, loaded when a power is selected.
var _icons := {}
var _icons_big := {}
var _big := {}
var _clips := {}
var _clip_time := 0.0
var _clip_shown := -1
var _pulse_t := 0.0
var _label_cache := {}
var _wide_style: StyleBoxFlat


func setup(slot: GodSlot, p_state := {}) -> SkillTreeScreen:
	UiTheme.word_spacing = true  # this screen's text is laid out for the wider spaces; off again when it leaves (_exit_tree)
	_slot = slot
	for col in columns().size():
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				var key := key_at(col, tier, i)
				if key != "" and not _icons.has(key):
					_icons[key] = spot_icon(key)
					_icons_big[key] = PowerBook.icon(key)
	centred = maxi(columns().find(slot.type), 0)
	selected = _first_pick()
	if p_state.has("centred") and int(p_state.centred) >= 0 and int(p_state.centred) < columns().size():
		centred = int(p_state.centred)
	var want: Variant = p_state.get("selected")
	if want is Vector3i and (want as Vector3i).x >= 0 and (want as Vector3i).x < columns().size():
		selected = want
	_load_selected()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The three types shown, left to right: the god's left ring neighbour, its own type, its right neighbour. Far types never appear.
func columns() -> PackedStringArray:
	var near := GodTree.neighbours(_slot.type)
	if near.size() < 2:
		return PackedStringArray([_slot.type])
	return PackedStringArray([near[0], _slot.type, near[1]])


## The ability key in a spot ("" when empty).
func key_at(col: int, tier: int, i: int) -> String:
	var cols := columns()
	return GodTree.spot(cols[col], tier, i) if col >= 0 and col < cols.size() else ""


## The picture of an ability's spot: the HUD copy of its icon, else the full one; null when the power has none yet.
static func spot_icon(key: String) -> Texture2D:
	var hud := PowerBook.hud_icon(key)
	return hud if hud != null else PowerBook.icon(key)


# ------------------------------------------------------------------------------------------------ state

## Puts column `col` on the wheel (the selection stays where it was).
func centre(col: int) -> void:
	if col < 0 or col >= columns().size():
		return
	centred = col
	_label_cache.clear()
	_redraw()


## Selects a spot (nothing is spent); an empty spot may be selected, it shows "Not yet chosen".
func select(col: int, tier: int, i: int) -> void:
	selected = Vector3i(col, tier, i)
	_load_selected()
	_redraw()


## The key of the selected spot, "" for none or an empty spot.
func selected_key() -> String:
	return key_at(selected.x, selected.y, selected.z) if selected.x >= 0 else ""


## What the next open of the screen restores: the centred Authority and the selected spot.
func state() -> Dictionary:
	return {"centred": centred, "selected": selected}


## The level Remembrance starts at: the selected power's learned level, else 1.
func remember_level() -> int:
	return maxi(_slot.level_of(selected_key()), 1)


## The first open's selection: the first power learned below level 5 in the god's own column (tier order), else the first one it
## can learn now, else its Tier I first spot.
func _first_pick() -> Vector3i:
	var own := maxi(columns().find(_slot.type), 0)
	for want_open in [false, true]:
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				var key := key_at(own, tier, i)
				if key == "":
					continue
				var have := _slot.level_of(key)
				if (not want_open and have > 0 and have < PowerBook.MAX_LEVEL) or (want_open and _slot.refusal(key) == ""):
					return Vector3i(own, tier, i)
	return Vector3i(own, 1, 0)


## Loads the selected power's clip and large icon (never inside a draw) and restarts its loop.
func _load_selected() -> void:
	_clip_time = 0.0
	_clip_shown = -1
	var key := selected_key()
	if key == "":
		return
	if not _clips.has(key):
		_clips[key] = PowerBook.clip(key)
	if not _big.has(key):
		var big := PowerBook.icon(key)
		_big[key] = big if big != null else spot_icon(key)


## The state of a spot on the wheel: "empty", "learned", "can" (buyable now), "poor" (open but not buyable now), "lock" (tier above
## the god's).
func node_state(col: int, tier: int, i: int) -> String:
	var key := key_at(col, tier, i)
	if key == "":
		return "empty"
	if _slot.level_of(key) > 0:
		return "learned"
	var why := _slot.refusal(key)
	if why == "":
		return "can"
	return "lock" if why == "tier" else "poor"


# ------------------------------------------------------------------------------------------------ layout

## The chip of column `col` in the top bar: the three chips are centred together, the centred one wider.
func chip_rect(col: int) -> Rect2:
	var cols := columns()
	var widths: Array[float] = []
	var total := 3.0 * (cols.size() - 1)
	for c in cols.size():
		var w := UiTheme.width(_chip_title(c), SIZE_CHIP) + (28.0 if c == centred else 18.0)
		if c != centred and cols[c] != _slot.type:
			w += UiTheme.width(" x2", SIZE_CHIP)
		widths.append(w)
		total += w
	var x := 320.0 - total * 0.5
	for c in cols.size():
		if c == col:
			return Rect2(x, 4.0, widths[c], 18.0)
		x += widths[c] + 3.0
	return Rect2()


func _chip_title(col: int) -> String:
	return PowerBook.authority_title(columns()[col])


## The panel of the `side`-th (0-1) column that is not centred, in chip order.
func side_col(side: int) -> int:
	var seen := 0
	for c in columns().size():
		if c == centred:
			continue
		if seen == side:
			return c
		seen += 1
	return -1


## A node's name as its label shows it: always the whole name.
static func node_label(full: String) -> String:
	return full


## The lines of a name's strip: one, or (two == true) split at the space nearest the middle.
static func label_lines(full: String, two: bool) -> PackedStringArray:
	if not two or not full.contains(" "):
		return PackedStringArray([full])
	var best := -1
	for k in full.length():
		if full[k] == " " and (best < 0 or absi(k - full.length() / 2) < absi(best - full.length() / 2)):
			best = k
	return PackedStringArray([full.substr(0, best), full.substr(best + 1)])


## The size of a name's strip: its widest line + 6 u by one or two lines tall.
static func strip_size(full: String, two: bool) -> Vector2:
	var w := 0.0
	var lines := label_lines(full, two)
	for l in lines:
		w = maxf(w, UiTheme.width(l, NODE_NAME_PX))
	return Vector2(ceilf(w) + 6.0, LABEL_STRIP_H if lines.size() == 1 else LABEL_STRIP_H2)


## The ring numeral plates, one on the top of each tier's oval (16x12 u, the numeral inside at 11 u).
static func numeral_plates() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for tier in range(1, GodTree.TIERS + 1):
		var top := Vector2(TreeWheel.CENTER.x, TreeWheel.CENTER.y - TreeWheel.ring(tier).y)
		out.append(Rect2(top.x - 8.0, top.y - 4.0, 16.0, 12.0))
	return out


## How far a point is from a rect (0 inside it).
static func _gap(r: Rect2, p: Vector2) -> float:
	return (p.clamp(r.position, r.end) - p).length()


## Whether a label strip may sit at `r`: inside LABEL_AREA, off the top bar, the side panels, the detail panel and the keys hint, off
## the ring numeral plates and the wheel's centre, 3 u clear of every node disc (and of its lock badge) and 2 u clear of every strip
## already `placed`.
static func strip_clear(r: Rect2, placed: Array) -> bool:
	if not LABEL_AREA.encloses(r):
		return false
	for fixed: Rect2 in [TreeWheel.TOP_BAR, TreeWheel.DETAIL, TreeWheel.SIDE_L, TreeWheel.SIDE_R, HINT_RECT]:
		if r.intersects(fixed):
			return false
	for plate in numeral_plates():
		if r.intersects(plate):
			return false
	if _gap(r, TreeWheel.CENTER) < EMBLEM_R + 1.0:
		return false
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			var p := TreeWheel.node_at(tier, i)
			if _gap(r, p) < TreeWheel.NODE_R + 3.0 or _gap(r, p + BADGE_AT) < BADGE_R + 1.0:
				return false
	for q: Rect2 in placed:
		if r.intersects(q.grow(2.0)):
			return false
	return true


## The places a strip of `size` may take for a node at `p`, best first: radially outward, below, above, the outer side (the four of the
## spec), then the same shifted along the node (aligned to its left or right edge, or nudged up or down) and radially further out, so a
## crowded quarter of the wheel can still fan its names out.
static func strip_candidates(p: Vector2, size: Vector2) -> Array[Rect2]:
	var dir := (p - TreeWheel.CENTER).normalized()
	var ext := absf(dir.x) * size.x * 0.5 + absf(dir.y) * size.y * 0.5
	var gap := TreeWheel.NODE_R + 4.0
	var side := 1.0 if p.x >= TreeWheel.CENTER.x else -1.0
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	var centres: Array[Vector2] = [p + dir * (gap + ext), p + Vector2(0.0, gap + hh), p - Vector2(0.0, gap + hh),
		p + Vector2(side * (gap + hw), 0.0)]
	for lean in [-1.0, 1.0]:
		centres.append(p + Vector2(lean * (hw - 6.0), gap + hh))
		centres.append(p + Vector2(lean * (hw - 6.0), -(gap + hh)))
	for dy in [-9.0, 9.0, -18.0, 18.0]:
		centres.append(p + Vector2(side * (gap + hw), dy))
		centres.append(p + Vector2(-side * (gap + hw), dy))
	for more in [6.0, 12.0, 20.0]:
		centres.append(p + dir * (gap + ext + more))
	var out: Array[Rect2] = []
	for c in centres:
		out.append(Rect2((c - size * 0.5).round(), size))
	return out


## Where every name of column `col` is written: Vector2i(tier, i) -> its strip (text width + 6 u by LABEL_STRIP_H), outermost tier first,
## each in the first candidate place that is clear (strip_clear); when none is, the radial place, and a test fails. Cached per column.
func label_layout(col: int) -> Dictionary:
	if _label_cache.has(col):
		return _label_cache[col]
	var out := {}
	var placed: Array[Rect2] = []
	for tier in range(GodTree.TIERS, 0, -1):
		for i in GodTree.PER_TIER:
			var key := key_at(col, tier, i)
			if key == "":
				continue
			var full := String(PowerBook.get_power(key).name)
			var p := TreeWheel.node_at(tier, i)
			var pick := Rect2()
			var found := false
			for two in [false, true]:
				for c in strip_candidates(p, strip_size(full, two)):
					if strip_clear(c, placed):
						pick = c
						found = true
						break
				if found:
					break
			if not found:
				pick = strip_candidates(p, strip_size(full, false))[0]
			out[Vector2i(tier, i)] = pick
			placed.append(pick)
	_label_cache[col] = out
	return out


## The affordable nodes' glow alpha at time t: 0.14 .. 0.32, once round every PULSE_SECONDS.
func pulse_alpha(t: float) -> float:
	return 0.14 + 0.18 * (0.5 + 0.5 * sin(TAU * t / PULSE_SECONDS))


## Whether the wheel shows a node that can be bought now (so it must redraw every frame for its glow).
func _any_can() -> bool:
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			if node_state(centred, tier, i) == "can":
				return true
	return false


## The refusal under RAISE: `reason` wrapped to REFUSAL_W at 11 u, at most 2 lines (the second ends "..." if the text went on).
static func refusal_lines(reason: String) -> PackedStringArray:
	var lines := UiTheme.wrap(reason, REFUSAL_W, UiTheme.TEXT_S)
	if lines.size() <= 2:
		return lines
	var last := " ".join(lines.slice(1))
	while last.length() > 1 and UiTheme.width(last + "...", UiTheme.TEXT_S) > REFUSAL_W:
		last = last.substr(0, last.length() - 1).strip_edges(false, true)
	return PackedStringArray([lines[0], last + "..."])


static var _dot_zero: RegEx


## A level value without a needless ".0".
static func num(s: String) -> String:
	if _dot_zero == null:
		_dot_zero = RegEx.create_from_string("(?<=\\d)\\.0(?!\\d)")
	return _dot_zero.sub(s, "", true)


## The level column's one value column for `rows` ({label, old, new}): every new value ends at `right`, every old value at `old_right`,
## and the arrow sits at `arrow_x` between them, so the numbers line up whatever their width. Only changed rows size the new column.
static func value_columns(rows: Array) -> Dictionary:
	var right := LEVEL_X + LEVEL_W - 6.0
	var new_w := 0.0
	for row: Dictionary in rows:
		var o := num(String(row.old))
		var n := num(String(row["new"]))
		if o != n:
			new_w = maxf(new_w, UiTheme.width(n, SMALL_PX))
	return {"new_w": new_w, "arrow_x": right - new_w - 8.0, "old_right": right - new_w - 10.0, "right": right}


## Where one row's values go in `cols` (value_columns): {changed, old, old_x, new, new_x} (x is the left edge of the text).
static func row_layout(row: Dictionary, cols: Dictionary) -> Dictionary:
	var o := num(String(row.old))
	var n := num(String(row["new"]))
	var out := {"changed": o != n, "new": n, "new_x": float(cols.right) - UiTheme.width(n, SMALL_PX)}
	if o != n:
		out["old"] = o
		out["old_x"] = float(cols.old_right) - UiTheme.width(o, SMALL_PX)
	return out


## The Might line as a row ("a -> b" when the next level changes it).
static func might_row(might: String) -> Dictionary:
	var parts := might.split(" -> ")
	return {"label": "Might", "old": parts[0], "new": parts[parts.size() - 1]}


static func side_rect(side: int) -> Rect2:
	return TreeWheel.SIDE_L if side == 0 else TreeWheel.SIDE_R


## The small icon of tier 1-5, spot i (0-1) inside a side panel.
static func mini_rect(panel: Rect2, tier: int, i: int) -> Rect2:
	return Rect2(Vector2(panel.get_center().x - 24.0 + float(i) * 26.0, panel.position.y + 60.0 + float(tier - 1) * 24.0),
		Vector2(MINI_PX, MINI_PX))


## The points box in the top bar.
func points_rect() -> Rect2:
	var w := 28.0 + UiTheme.width("Ability points", SMALL_PX) + UiTheme.width(str(_slot.points), SMALL_PX)
	return Rect2(632.0 - w, 4.0, w, 18.0)


## What is under a point: "back", "chip:<col>", "remember", "buy", "node:<tier>:<i>", "mini:<col>:<tier>:<i>", "side:<col>" or "".
func hit(point: Vector2) -> String:
	if BACK_RECT.has_point(point):
		return "back"
	for c in columns().size():
		if chip_rect(c).has_point(point):
			return "chip:%d" % c
	if selected_key() != "":
		if REMEMBER_RECT.has_point(point):
			return "remember"
		if BUY_RECT.has_point(point):
			return "buy"
	var n := TreeWheel.node_hit(point)
	if n.x > 0:
		return "node:%d:%d" % [n.x, n.y]
	for side in 2:
		var col := side_col(side)
		if col < 0:
			continue
		var panel := side_rect(side)
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				if mini_rect(panel, tier, i).has_point(point):
					return "mini:%d:%d:%d" % [col, tier, i]
		if panel.has_point(point):
			return "side:%d" % col
	return ""


# ------------------------------------------------------------------------------------------------ input

## A left click at a screen point: Back leaves, a chip or side panel centres, a node or small icon selects, the buttons act.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	var p := h.split(":")
	match p[0]:
		"back":
			UiSound.play(&"ui_click")
			action.emit("back")
		"chip", "side":
			UiSound.play(&"ui_click")
			centre(int(p[1]))
		"node":
			UiSound.play(&"ui_click")
			select(centred, int(p[1]), int(p[2]))
		"mini":
			UiSound.play(&"ui_click")
			select(int(p[1]), int(p[2]), int(p[3]))
		"remember":
			UiSound.play(&"ui_click")
			action.emit("remember")
		"buy":
			_buy()


## Selects a spot and buys it (learns the power or raises it a level); returns GodSlot.refusal()'s code ("unknown", "far", "max",
## "tier", "points") when it cannot, or "" and emits "learned" when it did.
func learn_at(col: int, tier: int, i: int) -> String:
	select(col, tier, i)
	return _buy()


## Buys the selected spot. A refusal buzzes and says why for REFUSE_SECONDS.
func _buy() -> String:
	if selected.x < 0:
		return "unknown"
	var key := selected_key()
	var why := _slot.refusal(key)
	if why != "":
		UiSound.play(&"ui_buzz")
		refused_reason = String(REFUSALS.get(why, why))
		if why == "tier":
			refused_reason = refused_reason % selected.y
		_refuse_left = REFUSE_SECONDS
		_redraw()
		return why
	_slot.learn(key)
	UiSound.play(&"ui_manifest")
	refused_reason = ""
	_redraw()
	action.emit("learned")
	return ""


func _exit_tree() -> void:
	UiTheme.word_spacing = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var n := columns().size()
		match event.physical_keycode:
			KEY_ESCAPE:
				UiSound.play(&"ui_click")
				action.emit("back")
			KEY_Q:
				UiSound.play(&"ui_click")
				centre((centred + n - 1) % n)
			KEY_E:
				UiSound.play(&"ui_click")
				centre((centred + 1) % n)


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


## Photographs only (`--tree-hover=<hit>`): shows the screen as if the mouse were over `what` (a hit() string).
func hover_for_photo(what: String) -> void:
	_hover = what
	_redraw()


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _process(delta: float) -> void:
	if _refuse_left > 0.0:
		_refuse_left -= delta
		if _refuse_left <= 0.0:
			refused_reason = ""
			_redraw()
	_clip_time += delta
	_pulse_t = fmod(_pulse_t + delta, PULSE_SECONDS)
	if _any_can():
		_redraw()
	var frame := int(_clip_time * PowerBook.CLIP_FPS) % PowerBook.CLIP_FRAMES
	if frame != _clip_shown and _clips.get(selected_key()) != null:
		_clip_shown = frame
		_redraw()


# ------------------------------------------------------------------------------------------------ drawing

func _draw_ui() -> void:
	_draw_backdrop()
	_draw_top_bar()
	_draw_wheel()
	for side in 2:
		if side_col(side) >= 0:
			_draw_side(side)
	UiTheme.text(_ui, Vector2(10.0, 246.0), "Esc back    Q / E switch Authority", SMALL_PX, Color(UiTheme.COL_DIM, 0.7))
	_draw_detail()


func _draw_backdrop() -> void:
	var stops := [[0.0, Color("2a1d45")], [0.26, Color("160f26")], [0.55, Color("0b0912")], [1.0, Color("050408")]]
	_ui.draw_rect(Rect2(0, 0, 640, 360), stops[3][1])
	for k in range(45, 0, -1):
		var t := float(k) / 45.0
		var col: Color = stops[3][1]
		for s in 3:
			if t <= float(stops[s + 1][0]):
				col = (stops[s][1] as Color).lerp(stops[s + 1][1], (t - float(stops[s][0])) / (float(stops[s + 1][0]) - float(stops[s][0])))
				break
		_ui.draw_circle(Vector2(320.0, 133.0), 450.0 * t, col)
	for d: Array in [[77, 79, 0.35], [524, 50, 0.3], [435, 220, 0.3], [173, 209, 0.25], [288, 32, 0.2], [589, 187, 0.25], [38, 169, 0.3]]:
		_ui.draw_rect(Rect2(float(d[0]), float(d[1]), 1, 1), Color(0.8, 0.75, 1.0, float(d[2])))


func _draw_top_bar() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 26), Color(0, 0, 0, 0.45))
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back")
	_text_centred(BACK_RECT.get_center().x, BACK_RECT.position.y + 13.0, "< BACK", SMALL_PX,
		UiTheme.COL_GOLD if _hover == "back" else UiTheme.COL_TEXT)
	UiTheme.text(_ui, Vector2(64.0, 17.0), "SKILL TREE", SMALL_PX, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(64.0 + UiTheme.width("SKILL TREE", SMALL_PX) + 8.0, 17.0), "Tier %d . level %d" % [_slot.tier, _slot.level],
		SMALL_PX, UiTheme.COL_DIM)
	var cols := columns()
	for c in cols.size():
		var r := chip_rect(c)
		var on := c == centred
		var hue := TreeWheel.color(cols[c])
		var hot := _hover == "chip:%d" % c
		_ui.draw_rect(r, hue.darkened(0.55) if on else Color(0.05, 0.04, 0.08, 0.8))
		_ui.draw_rect(r, hue if on else (hue.lightened(0.2) if hot else Color("2e2838")), false, 1.0)
		if on:
			_ui.draw_rect(r.grow(2.0), Color(hue, 0.18), false, 2.0)
		var title := _chip_title(c)
		var title_col := Color("efe3ff") if on else (UiTheme.COL_TEXT if hot else Color("7d7668"))
		var tw := UiTheme.width(title, SIZE_CHIP)
		var x2 := 0.0 if (on or cols[c] == _slot.type) else UiTheme.width(" x2", SIZE_CHIP)
		var x := r.position.x + (r.size.x - tw - x2) * 0.5
		UiTheme.text(_ui, Vector2(roundf(x), r.position.y + 13.0), title, SIZE_CHIP, title_col)
		if x2 > 0.0:
			UiTheme.text(_ui, Vector2(roundf(x + tw), r.position.y + 13.0), " x2", SIZE_CHIP, Color("c07a4a"))
	var pr := points_rect()
	_ui.draw_rect(pr, Color(0.07, 0.055, 0.02, 0.8))
	_ui.draw_rect(pr, Color("4a3c1c"), false, 1.0)
	var d := Vector2(pr.position.x + 9.0, pr.get_center().y)
	_ui.draw_colored_polygon(PackedVector2Array([d + Vector2(0, -4), d + Vector2(4, 0), d + Vector2(0, 4), d + Vector2(-4, 0)]), UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(pr.position.x + 17.0, pr.position.y + 13.0), "Ability points", SMALL_PX, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(pr.end.x - 5.0 - UiTheme.width(str(_slot.points), SMALL_PX), pr.position.y + 13.0), str(_slot.points),
		SMALL_PX, Color("f3d36a"))


func _ellipse(rx: float, ry: float, from_deg := 0.0, steps := ORBIT_SEGMENTS) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in steps + 1:
		var a := deg_to_rad(from_deg + 360.0 * float(k) / float(steps))
		out.append(TreeWheel.CENTER + Vector2(sin(a) * rx, -cos(a) * ry))
	return out


## Whether an orbit segment's midpoint lies under a label strip (grown 3 u): those segments are drawn faint.
static func _under_strip(a: Vector2, b: Vector2, strips: Array) -> bool:
	var mid := (a + b) * 0.5
	for s: Rect2 in strips:
		if s.grow(3.0).has_point(mid):
			return true
	return false


## One ring as its 72 segments cut into runs: [points, faded] pairs, faded where a label strip lies over the ring.
func _orbit_runs(pts: PackedVector2Array, strips: Array) -> Array:
	var runs := []
	var run := PackedVector2Array()
	var faded := false
	for k in pts.size() - 1:
		var f := _under_strip(pts[k], pts[k + 1], strips)
		if run.size() > 0 and f != faded:
			runs.append([run, faded])
			run = PackedVector2Array()
		if run.size() == 0:
			run.append(pts[k])
		run.append(pts[k + 1])
		faded = f
	if run.size() > 1:
		runs.append([run, faded])
	return runs


## The colour of an orbit run: `col`, or ORBIT_FADED alpha under a strip.
static func _orbit_colour(col: Color, faded: bool) -> Color:
	return Color(col, minf(col.a, ORBIT_FADED)) if faded else col


func _draw_wheel() -> void:
	var hue := TreeWheel.color(columns()[centred])
	var c := TreeWheel.CENTER
	var strips: Array = label_layout(centred).values()
	for r in range(40, 18, -2):
		_ui.draw_circle(c, float(r), Color(hue, 0.045))
	_ui.draw_circle(c, 18.0, hue.darkened(0.7))
	_ui.draw_circle(c, 13.0, hue.darkened(0.3))
	_ui.draw_circle(c, 8.0, hue.lightened(0.15))
	_ui.draw_circle(c, 4.0, hue.lightened(0.6))
	var plates := numeral_plates()
	for tier in range(1, GodTree.TIERS + 1):
		var ring := TreeWheel.ring(tier)
		var locked := tier > _slot.tier
		var pts := _ellipse(ring.x, ring.y)
		if locked:
			for k in range(0, pts.size() - 1, 2):
				var dash := Color("3a3348", minf(0.7, ORBIT_FADED) if _under_strip(pts[k], pts[k + 1], strips) else 0.7)
				_ui.draw_line(pts[k], pts[k + 1], dash, 1.0)
		elif tier == _slot.tier:
			for run: Array in _orbit_runs(_ellipse(ring.x + 1.0, ring.y + 1.0), strips):
				_ui.draw_polyline(run[0], _orbit_colour(Color(hue, 0.18), run[1]), 3.0)
			for run: Array in _orbit_runs(pts, strips):
				_ui.draw_polyline(run[0], _orbit_colour(Color(hue.lightened(0.3), 0.75), run[1]), 1.0)
		else:
			for run: Array in _orbit_runs(pts, strips):
				_ui.draw_polyline(run[0], _orbit_colour(Color(hue, 0.35), run[1]), 1.0)
		var plate: Rect2 = plates[tier - 1]
		_ui.draw_rect(plate, Color(0.07, 0.05, 0.12, 0.95))
		_text_centred(plate.get_center().x, plate.position.y + 10.0, String(TreeDetail.ROMAN[tier - 1]), SMALL_PX,
			Color("6a6178") if locked else Color("a794c8"))
	var glow := pulse_alpha(_pulse_t)
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			if node_state(centred, tier, i) == "can":
				var np := TreeWheel.node_at(tier, i)
				_ui.draw_circle(np, 19.0, Color(hue, glow))
				_ui.draw_circle(np, 17.0, Color(hue, glow))
				_ui.draw_arc(np, 16.0, 0.0, TAU, 64, Color(hue.lightened(0.3), minf(1.0, glow * 2.0)), 2.0)
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			_draw_node(tier, i, hue)
	var layout := label_layout(centred)
	for tier in range(1, GodTree.TIERS + 1):
		for i in GodTree.PER_TIER:
			var at := Vector2i(tier, i)
			if not layout.has(at):
				continue
			var strip: Rect2 = layout[at]
			var key := key_at(centred, tier, i)
			var sel := selected == Vector3i(centred, tier, i)
			var name_col := COL_SELECT if sel else (COL_LABEL_LOCKED if node_state(centred, tier, i) == "lock" else COL_LABEL)
			_ui.draw_rect(strip, COL_STRIP)
			var lines := label_lines(node_label(String(PowerBook.get_power(key).name)), strip.size.y > LABEL_STRIP_H + 1.0)
			for n in lines.size():
				UiTheme.text(_ui, Vector2(strip.position.x + 3.0, strip.position.y + 10.0 + 11.0 * float(n)), lines[n], NODE_NAME_PX, name_col)


## The ring colour of a state (the same on the wheel and in the side panels).
static func state_edge(state: String, hue: Color) -> Color:
	match state:
		"learned":
			return UiTheme.COL_GOLD
		"can":
			return hue.lightened(0.2)
		"lock":
			return COL_RING_LOCKED
	return hue.darkened(0.35)


## An icon of `want` units centred on `c` at a native multiple, clipped round; grey when `locked`. The picture comes from setup's caches.
func _draw_icon(c: Vector2, key: String, want: float, locked: bool, alpha := 1.0) -> void:
	var rect := UiIcon.native_rect(c, want)
	if rect.size.x > want * 1.6:
		rect = Rect2(c - Vector2(want, want) * 0.5, Vector2(want, want))  # below the design window (k1): the 42 px icon would swamp the disc
	var m := UiIcon.multiple(want)
	var tex: Texture2D = _icons.get(key)
	var big: Texture2D = _icons_big.get(key)
	if m % 2 == 0 and big != null:
		tex = big
	elif tex == null:
		tex = big
	if tex == null:
		return
	var tint := Color(1, 1, 1, alpha)
	if locked:
		tex = UiIcon.grey(tex)
		var lt := UiIcon.locked_tint(tex)
		tint = Color(lt, lt.a * alpha)
	UiIcon.draw_round(_ui, tex, rect, tint)


## The padlock badge of a locked power at `at`; `s` scales it (1 on the wheel, 0.8 in a side panel).
func _draw_lock(at: Vector2, s: float) -> void:
	var b := at.round()
	_ui.draw_circle(b, 5.0 * s, Color("120e1a"))
	_ui.draw_arc(b, 4.5 * s, 0.0, TAU, 24, Color("8a8090"), 1.0)
	_ui.draw_rect(Rect2(b.x - 2.5 * s, b.y - 0.5 * s, 5.0 * s, 4.0 * s), Color("b8b0c4"))
	_ui.draw_arc(b + Vector2(0.0, -0.5 * s), 1.5 * s, PI, TAU, 8, Color("b8b0c4"), 1.0)


func _draw_node(tier: int, i: int, hue: Color) -> void:
	var p := TreeWheel.node_at(tier, i)
	var r := TreeWheel.NODE_R
	var key := key_at(centred, tier, i)
	var state := node_state(centred, tier, i)
	var sel := selected == Vector3i(centred, tier, i)
	var hot := _hover == "node:%d:%d" % [tier, i]
	if sel:
		_ui.draw_arc(p, r + 4.0, 0.0, TAU, 64, Color(COL_SELECT, 0.25), 2.0)
		_ui.draw_arc(p, r + 2.0, 0.0, TAU, 64, COL_SELECT, 2.0)
	if state == "empty":
		_dashed_circle(p, r - 1.0, Color(hue, 0.45 if hot else 0.3))
		return
	var have := _slot.level_of(key)
	var edge := state_edge(state, hue)
	if hot:
		edge = edge.lightened(0.3)
	if state == "learned":
		_ui.draw_arc(p, r + 0.5, 0.0, TAU, 64, Color(UiTheme.COL_GOLD, 0.25), 3.0)
	_ui.draw_circle(p, r, Color(COL_NODE, 0.95))
	_draw_icon(p, key, NODE_ICON_UNITS, state == "lock", 1.0)
	_ui.draw_arc(p, r - 1.0, 0.0, TAU, 64, edge, 2.0)
	if state == "lock":
		_draw_lock(p + BADGE_AT, 1.0)
	if have > 0:
		for k in PowerBook.MAX_LEVEL:
			_ui.draw_rect(Rect2(p.x - 9.5 + float(k) * 4.0, p.y + r + 1.0, 3.0, 2.0), Color("f3d36a") if k < have else Color("3a3326"))


func _dashed_circle(p: Vector2, r: float, col: Color) -> void:
	for k in range(0, 16, 2):
		_ui.draw_arc(p, r, TAU * float(k) / 16.0, TAU * float(k + 1) / 16.0, 4, col, 1.0)


func _draw_side(side: int) -> void:
	var col := side_col(side)
	var panel := side_rect(side)
	var type := columns()[col]
	var hue := TreeWheel.color(type)
	var hot := _hover == "side:%d" % col or _hover.begins_with("mini:%d:" % col)
	var fade := 1.0 if hot else 0.78
	if _wide_style == null:
		_wide_style = StyleBoxFlat.new()
		_wide_style.set_corner_radius_all(4)
		_wide_style.corner_radius_top_left = 56
		_wide_style.corner_radius_top_right = 56
		_wide_style.set_border_width_all(1)
	_wide_style.bg_color = Color(1, 1, 1, 0.03 if not hot else 0.06)
	_wide_style.border_color = Color("2a2433") if not hot else Color("4a4058")
	_ui.draw_style_box(_wide_style, panel)
	var mid := panel.get_center().x
	_text_centred(mid, panel.position.y + 24.0, PowerBook.authority_title(type), SMALL_PX, Color(hue, fade))
	_text_centred(mid, panel.position.y + 37.0, "your nature" if type == _slot.type else "neighbour", SMALL_PX, Color("7d7668", fade))
	if type != _slot.type:
		var pill := Rect2(mid - 26.0, panel.position.y + 42.0, 52.0, 13.0)
		_ui.draw_rect(pill, Color("5a3a22", 0.8), false, 1.0)
		_text_centred(mid, pill.position.y + 10.0, "x2 cost", SMALL_PX, Color("c07a4a", fade))
	for tier in range(1, GodTree.TIERS + 1):
		var row := mini_rect(panel, tier, 0)
		_text_centred(mid - 40.0, row.get_center().y + 4.0, String(TreeDetail.ROMAN[tier - 1]), SMALL_PX, Color(UiTheme.COL_DIM, fade))
		for i in GodTree.PER_TIER:
			_draw_mini(side, col, tier, i, hue, fade)
	var line := "click to centre"
	var line_col := Color("9a9484", fade)
	if _hover.begins_with("mini:%d:" % col):
		var p := _hover.split(":")
		var key := key_at(col, int(p[2]), int(p[3]))
		if key != "":
			line = UiTheme.fit(String(PowerBook.get_power(key).name), 104.0, SMALL_PX)
			line_col = COL_LABEL
	_text_centred(mid, panel.end.y - 8.0, line, SMALL_PX, line_col)


func _draw_mini(side: int, col: int, tier: int, i: int, hue: Color, fade: float) -> void:
	var r := mini_rect(side_rect(side), tier, i)
	var key := key_at(col, tier, i)
	var c := r.get_center()
	var sel := selected == Vector3i(col, tier, i)
	if sel:
		_ui.draw_arc(c, 12.0, 0.0, TAU, 48, COL_SELECT, 2.0)
	if key == "":
		_dashed_circle(c, 9.5, Color(hue, 0.4 * fade))
		return
	var state := node_state(col, tier, i)
	var edge := state_edge(state, hue)
	if _hover == "mini:%d:%d:%d" % [col, tier, i]:
		edge = edge.lightened(0.35)
	_ui.draw_circle(c, 11.0, Color(COL_NODE, 0.9))
	_draw_icon(c, key, MINI_ICON_UNITS, state == "lock", fade)
	_ui.draw_arc(c, 10.5, 0.0, TAU, 48, Color(edge, edge.a * fade), 1.0)
	if state == "lock":
		_draw_lock(c + Vector2(7.0, 7.0), 0.8)


## The detail panel: clip, name and tags and description, the level column and the two buttons.
func _draw_detail() -> void:
	_ui.draw_rect(DETAIL, Color(0.07, 0.055, 0.1, 0.94))
	_ui.draw_rect(DETAIL, Color("5a4a2a"), false, 1.0)
	_ui.draw_line(DETAIL.position + Vector2(40, 0), Vector2(DETAIL.end.x - 40.0, DETAIL.position.y), Color(UiTheme.COL_GOLD, 0.8), 1.0)
	var key := selected_key()
	_ui.draw_rect(CLIP_BOX, Color("0a0810"))
	_ui.draw_rect(CLIP_BOX, Color("3a3326"), false, 1.0)
	if key == "":
		_text_centred(CLIP_BOX.get_center().x, CLIP_BOX.get_center().y + 4.0, GodTree.NOT_CHOSEN, SMALL_PX, UiTheme.COL_DIM)
		UiTheme.text(_ui, Vector2(INFO_X, 278.0), GodTree.NOT_CHOSEN, UiTheme.TEXT_L, UiTheme.COL_DIM)
		UiTheme.text(_ui, Vector2(INFO_X, 309.0), "Nothing here yet.", SMALL_PX, UiTheme.COL_DIM)
		return
	_draw_clip(key)
	var entry := PowerBook.get_power(key)
	var shown := detail_name(String(entry.name))
	UiTheme.text(_ui, Vector2(INFO_X, 278.0), String(shown.text), int(shown.size), COL_LABEL)
	var tx := INFO_X
	var tags := TreeDetail.tags(key)
	var hue := TreeWheel.color(PowerBook.authority_of(key))
	for n in tags.size():
		var tag_col := hue if n == 0 else (Color("9fd1b8") if tags[n] == "QUIET" else (Color("d8906a") if tags[n] == "LOUD" else Color("c9b8ea")))
		var w := UiTheme.width(tags[n], SMALL_PX) + 10.0
		_ui.draw_rect(Rect2(tx, 283.0, w, 13.0), Color(tag_col, 0.55), false, 1.0)
		UiTheme.text(_ui, Vector2(tx + 5.0, 293.0), tags[n], SMALL_PX, tag_col)
		tx += w + 3.0
	var desc := TreeDetail.description(key, INFO_W)
	for n in desc.size():
		UiTheme.text(_ui, Vector2(INFO_X, 309.0 + UiTheme.LINE_S * float(n)), desc[n], SMALL_PX, Color("c8c0ac"))
	var twist := twist_lines(key)
	for n in twist.size():
		UiTheme.text(_ui, Vector2(INFO_X, 333.0 + UiTheme.LINE_S * float(n)), twist[n], SMALL_PX, COL_TWIST)
	var button := TreeDetail.buy_button(_slot, key, selected.y)
	_draw_levels(key)
	_draw_buttons(button)
	var reason := refused_reason if refused_reason != "" else String(button.reason)
	if reason != "":
		var lines := refusal_lines(reason)
		for n in lines.size():
			_text_centred(BUY_RECT.get_center().x, 325.0 + UiTheme.LINE_S * float(n), lines[n], SMALL_PX,
				UiTheme.COL_BAD if refused_reason != "" else Color(UiTheme.COL_BAD, 0.75))


## The selected power's name as the detail panel writes it: 22 u when it fits INFO_W, else the whole name at 11 u (a name is never cut).
## {text, size}.
static func detail_name(full: String) -> Dictionary:
	if UiTheme.width(full, UiTheme.TEXT_L) <= INFO_W:
		return {"text": full, "size": UiTheme.TEXT_L}
	return {"text": UiTheme.fit(full, INFO_W, SMALL_PX), "size": SMALL_PX}


func _draw_clip(key: String) -> void:
	var sheet: Texture2D = _clips.get(key)
	if sheet != null:
		var frame := int(_clip_time * PowerBook.CLIP_FPS) % PowerBook.CLIP_FRAMES
		_ui.draw_texture_rect_region(sheet, CLIP_BOX, PowerBook.clip_frame(frame))
		return
	var big: Texture2D = _big.get(key)
	if big != null:
		_ui.draw_texture_rect(big, Rect2(CLIP_BOX.get_center() - Vector2(40.0, 40.0), Vector2(80.0, 80.0)), false)


func _draw_levels(key: String) -> void:
	var col := TreeDetail.level_column(_slot, key)
	_ui.draw_line(Vector2(LEVEL_X, 258.0), Vector2(LEVEL_X, 346.0), Color("2a2433"), 1.0)
	var x := LEVEL_X + 8.0
	var room := LEVEL_W - 14.0
	var y := 268.0
	var line := UiTheme.LINE_S
	UiTheme.text(_ui, Vector2(x, y), String(col.head), SMALL_PX, UiTheme.COL_DIM)
	y += line
	# Rows that do not fit above the Might row are dropped.
	var budget := int((LEVEL_BOTTOM - y) / line)
	var all_rows: Array = (col.rows as Array).slice(0, maxi(budget, 0))
	all_rows.append(might_row(String(col.might)))
	var cols := value_columns(all_rows)
	for row: Dictionary in all_rows:
		var lay := row_layout(row, cols)
		var left := float(lay.new_x)
		if lay.changed:
			left = float(lay.old_x)
			UiTheme.text(_ui, Vector2(float(lay.old_x), y), String(lay.old), SMALL_PX, Color("c8c0ac"))
			_draw_arrow(float(cols.arrow_x), y - 4.0)
			UiTheme.text(_ui, Vector2(float(lay.new_x), y), String(lay["new"]), SMALL_PX, COL_GREEN)
		else:
			UiTheme.text(_ui, Vector2(float(lay.new_x), y), String(lay["new"]), SMALL_PX, Color("c8c0ac"))
		UiTheme.text(_ui, Vector2(x, y), UiTheme.fit(String(row.label), left - x - 4.0, SMALL_PX), SMALL_PX, Color("bfb49a"))
		y += line


## The level-5 twist as the detail panel writes it, in full: wrapped to the info column, at most TWIST_LINES lines (a test over every power).
static func twist_lines(key: String) -> PackedStringArray:
	var text := PowerBook.twist(key)
	if text == "" or not PowerBook.has_levels(key):
		return PackedStringArray()
	return UiTheme.wrap("Level %d . %s" % [PowerBook.MAX_LEVEL, text.split(". ")[0]], INFO_W, SMALL_PX)


## The 6x5 u chevron arrow between an old value and a new one, its vertical middle at `cy`.
func _draw_arrow(ax: float, cy: float) -> void:
	_ui.draw_line(Vector2(ax, cy), Vector2(ax + 5.0, cy), COL_GREEN, 1.0)
	_ui.draw_polyline(PackedVector2Array([Vector2(ax + 3.0, cy - 2.0), Vector2(ax + 5.0, cy), Vector2(ax + 3.0, cy + 2.0)]), COL_GREEN, 1.0)


func _draw_buttons(button: Dictionary) -> void:
	var rem_hot := _hover == "remember"
	_ui.draw_rect(REMEMBER_RECT, Color("1f3a4a") if rem_hot else Color("152a37"))
	_ui.draw_rect(REMEMBER_RECT, COL_REMEMBER, false, 1.0)
	_text_centred(REMEMBER_RECT.get_center().x, REMEMBER_RECT.position.y + 11.0, "REMEMBRANCE", SMALL_PX, Color("dff2fa"))
	_text_centred(REMEMBER_RECT.get_center().x, REMEMBER_RECT.position.y + 22.0, "try it, free", SMALL_PX, Color(COL_REMEMBER, 0.9))
	var on: bool = button.enabled
	var hot := _hover == "buy" and on
	var fill := Color("f0cf62") if hot else Color("d8b23a")
	_ui.draw_rect(BUY_RECT, fill if on else Color("2a2630"))
	_ui.draw_rect(BUY_RECT, Color("f3d36a") if on else Color("463f50"), false, 1.0)
	var ink := Color("2a1d04") if on else Color("7d7668")
	_text_centred(BUY_RECT.get_center().x, BUY_RECT.position.y + 11.0, String(button.label), SMALL_PX, ink)
	var cost: int = button.cost
	var sub := "Level %d" % PowerBook.MAX_LEVEL if button.label == "MAX" else "%d point%s" % [cost, "" if cost == 1 else "s"]
	_text_centred(BUY_RECT.get_center().x, BUY_RECT.position.y + 22.0, sub, SMALL_PX, Color(ink, 0.85))


func _text_centred(x: float, baseline: float, s: String, size: int, col: Color) -> void:
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(s, size) * 0.5), baseline), s, size, col)
