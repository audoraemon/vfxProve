class_name AbilityBar
extends RefCounted
## The god's ability bar for a Might night: one page per god type the god has learned an ability of, ten tiles to a page on keys
## 1..9 and 0, and the Might gauge. Hidden it is a strip at the bottom centre (the armed ability and the gauge); open it is the
## row of tiles with the armed ability's line, the type tabs and the gauge above it. It knows where everything is (rect(), tile_rect(),
## hit()) and how to draw it; the HUD owns the keys, the mouse and the canvas. Icons are taken once in setup(): a texture first loaded
## inside a draw paints a white block (see Hud._slot_icons).

## A tile's side, HUD units (640x360).
const TILE := 42.0
## The gap between tiles.
const TILE_GAP := 4.0
## The armed tile in the hidden strip, which is as tall as it is.
const STRIP_TILE := 28.0
## The gap under the row, as the slot cards have.
const BOTTOM := 2.0
## The height of the name line, the tabs line and the gauge line.
const LINE := 13.0
## One gauge segment.
const SEG := Vector2(8.0, 6.0)
## Seconds the hidden strip names a page after a turn.
const PAGE_FLASH := 1.5
## What the hidden strip says beside the gauge.
const HINT := "Ctrl: abilities"
## The space between gauge segments, and around them.
const SEG_GAP := 2.0
## Padding at the strip's ends and either side of the open bar.
const PAD := 4.0
## The width kept for the armed ability's name in the strip.
const NAME_ROOM := 84.0
## The space between the strip's parts.
const GAP := 8.0
## The room either side of a tab's words, and between tabs.
const TAB_PAD := 6.0
const TAB_GAP := 3.0
const COL_MIGHT := Color("9cc4de")
const COL_SEG := Color("6fa8c8")
const COL_SEG_EMPTY := Color("1d2a36")
const COL_EDGE := Color("2c2c33")
const COL_POOR := Color(0.45, 0.45, 0.5)
const COL_SEALED := Color(0.2, 0.2, 0.22)
const COL_LOCK := Color(0.78, 0.74, 0.62)
## The height of a key or price plate, as Hud.PLATE_H.
const PLATE_H := 12.0

## Whether the whole bar is shown.
var open := false
## The page shown: an index into pages().
var page := 0

var _rules: Rules
var _pages: Array = []
var _small: Array[Texture2D] = []
var _big: Array[Texture2D] = []
var _names: Array[String] = []
var _flash_left := 0.0


## The pages for a god of `own_type` holding `keys`: [{"type": String, "slots": PackedInt32Array}], the slots being indices into
## `keys` in tree order, only types with a key. The own type sits between its ring neighbours, the rest follow in ring order; with
## no own type, or none of its keys held, the whole order is the ring's.
static func pages_for(own_type: String, keys: PackedStringArray) -> Array:
	var by_type := {}
	for i in keys.size():
		var spot := GodTree.spot_of(keys[i])
		if spot.is_empty():
			continue
		var type: String = spot.type
		if not by_type.has(type):
			by_type[type] = []
		by_type[type].append([int(spot.tier) * GodTree.PER_TIER + int(spot.i), i])
	var order: Array = []
	var near := GodTree.neighbours(own_type)
	if by_type.has(own_type) and near.size() == 2:
		order = [near[0], own_type, near[1]]
	for type: String in GodTree.RING:
		if not order.has(type):
			order.append(type)
	var out: Array = []
	for type: String in order:
		if not by_type.has(type):
			continue
		var rows: Array = by_type[type]
		rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var slots := PackedInt32Array()
		for row: Array in rows:
			slots.append(row[1])
		out.append({"type": type, "slots": slots})
	return out


## Builds the pages from the night's loadout, takes every icon once, and opens on the own type's page (0 when it has none).
func setup(rules: Rules, own_type: String) -> AbilityBar:
	_rules = rules
	_pages = pages_for(own_type, rules.loadout)
	_small.clear()
	_big.clear()
	_names.clear()
	for i in rules.loadout.size():
		_small.append(PowerBook.hud_icon(rules.key(i)))
		_big.append(PowerBook.icon(rules.key(i)))
		_names.append(String(rules.power(i).get("name", "")))
	page = 0
	for i in _pages.size():
		if _pages[i].type == own_type:
			page = i
	return self


## The pages, as pages_for() made them.
func pages() -> Array:
	return _pages


## Shows or hides the whole bar; a night with no page has nothing to show.
func toggle() -> void:
	if _pages.is_empty():
		open = false
		return
	open = not open


## Turns the page by `by`, wrapping, and starts the page flash; nothing with fewer than two pages.
func turn(by: int) -> void:
	if _pages.size() < 2:
		return
	page = posmod(page + by, _pages.size())
	_flash_left = PAGE_FLASH


## Seconds of the page flash left.
func page_flash() -> float:
	return _flash_left


## Runs the page flash down.
func advance(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)


## The slots of the page shown.
func _slots() -> PackedInt32Array:
	if _pages.is_empty():
		return PackedInt32Array()
	return _pages[page].slots


## The loadout slot a number key addresses on the current page (digit 0 is key 1, digit 9 key 0), -1 for none.
func slot_for_digit(digit: int) -> int:
	var slots := _slots()
	return slots[digit] if digit >= 0 and digit < slots.size() else -1


## The slot's place on its own page, -1 when it is on none.
func digit_of(slot: int) -> int:
	for p: Dictionary in _pages:
		var at: int = p.slots.find(slot)
		if at >= 0:
			return at
	return -1


## The page a slot is on, -1 when it is on none.
func page_of(slot: int) -> int:
	for i in _pages.size():
		if _pages[i].slots.has(slot):
			return i
	return -1


## The gauge's segments.
func _segments() -> int:
	return ceili(_rules.might.capacity) if _rules != null and _rules.might != null else 0


## The width of "MIGHT [segments] v / cap", 0 with no pool.
func _gauge_width() -> float:
	if _segments() == 0:
		return 0.0
	var cap := int(_rules.might.capacity)
	return UiTheme.width("MIGHT", UiTheme.TEXT_S) + 4.0 + float(_segments()) * (SEG.x + SEG_GAP) + SEG_GAP + 4.0 \
		+ UiTheme.width("%d / %d" % [cap, cap], UiTheme.TEXT_S)


## The hidden strip: tile, name, gauge and hint, centred, its bottom BOTTOM above the view's.
func _strip(view: Vector2) -> Rect2:
	var w := PAD + STRIP_TILE + 4.0 + NAME_ROOM + GAP + _gauge_width() + GAP + UiTheme.width(HINT, UiTheme.TEXT_S) + PAD
	return Rect2(floorf((view.x - w) * 0.5), view.y - BOTTOM - STRIP_TILE, w, STRIP_TILE)


## Where the armed ability's tile sits in the hidden strip.
func strip_tile_rect(view: Vector2) -> Rect2:
	var s := _strip(view)
	return Rect2(s.position + Vector2(PAD, 0.0), Vector2(STRIP_TILE, STRIP_TILE))


## Whether the type tabs (and the Z / X keys beside them) are shown: with two or more pages.
func _has_tabs() -> bool:
	return _pages.size() > 1


## The words of tab `i`: the type's title and its count.
func _tab_label(i: int) -> String:
	return "%s %d" % [PowerBook.authority_title(_pages[i].type), _pages[i].slots.size()]


## The tabs line: every tab's rect, then Z's and X's centres' x; the room either side of the words shrinks to fit a narrow view.
func _tab_layout(view: Vector2, top: float) -> Dictionary:
	var pad := TAB_PAD
	var widths: Array[float] = []
	var total := 0.0
	var key_w := UiTheme.width("Z", UiTheme.TEXT_S) + 6.0
	for attempt in 2:
		widths.clear()
		total = 2.0 * (key_w + TAB_GAP)
		for i in _pages.size():
			widths.append(UiTheme.width(_tab_label(i), UiTheme.TEXT_S) + 2.0 * pad)
			total += widths[i] + (TAB_GAP if i < _pages.size() - 1 else 0.0)
		if total <= view.x - 2.0 * PAD:
			break
		pad = 1.0
	var x := floorf((view.x - total) * 0.5)
	var out := {"z": Rect2(x, top, key_w, LINE - 1.0), "tabs": [] as Array[Rect2], "width": total}
	x += key_w + TAB_GAP
	for i in _pages.size():
		out.tabs.append(Rect2(x, top, widths[i], LINE - 1.0))
		x += widths[i] + TAB_GAP
	out["x"] = Rect2(x, top, key_w, LINE - 1.0)
	return out


## The open bar's measures: the row's left and width, and the tops of the tiles, the name line, the tabs and the gauge.
func _open_layout(view: Vector2) -> Dictionary:
	var n := _slots().size()
	var row_w := float(n) * TILE + float(maxi(n - 1, 0)) * TILE_GAP
	var tiles_top := view.y - BOTTOM - TILE
	var name_top := tiles_top - LINE
	var tabs_top := name_top - LINE
	var gauge_top := tabs_top - LINE if _has_tabs() else name_top - LINE
	var wide := maxf(row_w, _gauge_width())
	if _has_tabs():
		wide = maxf(wide, float(_tab_layout(view, tabs_top).width))
	wide += 2.0 * PAD
	return {"row_x": (view.x - row_w) * 0.5, "tiles_top": tiles_top, "name_top": name_top, "tabs_top": tabs_top,
		"gauge_top": gauge_top, "rect": Rect2((view.x - wide) * 0.5, gauge_top, wide, view.y - BOTTOM - gauge_top)}


## Everything drawn now: the strip when hidden, the whole bar when open.
func rect(view: Vector2) -> Rect2:
	if open and not _pages.is_empty():
		return _open_layout(view).rect
	return _strip(view)


## Tile `i` of the current page (open only).
func tile_rect(i: int, view: Vector2) -> Rect2:
	if i < 0 or i >= _slots().size():
		return Rect2()
	var lay := _open_layout(view)
	return Rect2(lay.row_x + float(i) * (TILE + TILE_GAP), lay.tiles_top, TILE, TILE)


## Tab `i`, Rect2() when there are no tabs.
func tab_rect(i: int, view: Vector2) -> Rect2:
	if not _has_tabs() or i < 0 or i >= _pages.size():
		return Rect2()
	return _tab_layout(view, _open_layout(view).tabs_top).tabs[i]


## Where the armed ability's tile is: the bar's tile when open and on this page, else the strip's.
func armed_rect(armed: int, view: Vector2) -> Rect2:
	if armed < 0:
		return Rect2()
	if open and page_of(armed) == page:
		return tile_rect(digit_of(armed), view)
	return strip_tile_rect(view)


## What is under `point`: "tile:<slot>", "tab:<i>", "strip" (hidden only), or "".
func hit(point: Vector2, view: Vector2) -> String:
	if not open or _pages.is_empty():
		return "strip" if _strip(view).has_point(point) else ""
	var slots := _slots()
	for i in slots.size():
		if tile_rect(i, view).has_point(point):
			return "tile:%d" % slots[i]
	for i in _pages.size():
		if tab_rect(i, view).has_point(point):
			return "tab:%d" % i
	return ""


## "ready", or what Rules.refusal() says ("sealed", "cooldown", "might", "busy", "empty", "over").
func tile_state(slot: int) -> String:
	if _rules == null:
		return "empty"
	var why := _rules.refusal(slot)
	return "ready" if why == "" else why


## Everything the drawing depends on, for the HUD's redraw check.
func signature(armed: int) -> String:
	var parts := PackedStringArray([str(open), str(page), str(_flash_left > 0.0), str(armed)])
	if _rules != null and _rules.might != null:
		var pool := _rules.might
		parts.append("%d/%d/%d" % [pool.whole(), int(pool.capacity), floori((pool.value - float(pool.whole())) * 8.0)])
	var shown: Array = []
	if open:
		shown.append_array(_slots())
	if armed >= 0:
		shown.append(armed)
	for slot: int in shown:
		parts.append("%d:%s:%d" % [slot, tile_state(slot), ceili(_rules.cooldown_left(slot)) if _rules != null else 0])
	return "|".join(parts)


## The square an icon occupies in `box`: UiIcon's native multiple centred in it, or the whole box when no native size fits (the 28 u
## strip tile at 640x360).
static func _icon_rect(box: Rect2) -> Rect2:
	var native := UiIcon.native_rect(box.get_center(), box.size.x)
	return native if native.size.x <= box.size.x + 0.001 else box


## The tile's icon for `rect` at the current UI scale: the 84 px painted icon for even multiples, else the 42 px one.
func _icon(slot: int, rect: Rect2) -> Texture2D:
	var small: Texture2D = _small[slot] if slot >= 0 and slot < _small.size() else null
	var big: Texture2D = _big[slot] if slot >= 0 and slot < _big.size() else null
	var m := maxi(roundi(rect.size.x * float(UiScale.k()) / float(UiIcon.SOURCE)), 1)
	if m % 2 == 0 and big != null:
		return big
	return small if small != null else big


## A short label on a dark plate, `at` being its top-left corner; the plate's width.
static func _plate(on: CanvasItem, at: Vector2, label: String, col: Color) -> float:
	var w := UiTheme.width(label, UiTheme.TEXT_S) + 2.0
	on.draw_rect(Rect2(at, Vector2(w, PLATE_H)), Color(0, 0, 0, 0.62))
	UiTheme.text(on, at + Vector2(1.0, PLATE_H - 3.0), label, UiTheme.TEXT_S, col)
	return w


## A small padlock centred on `c`, from rects.
static func _padlock(on: CanvasItem, c: Vector2) -> void:
	on.draw_rect(Rect2(c + Vector2(-3.0, -7.0), Vector2(6.0, 6.0)), COL_LOCK, false, 1.0)
	on.draw_rect(Rect2(c + Vector2(-5.0, -2.0), Vector2(10.0, 8.0)), COL_LOCK)
	on.draw_rect(Rect2(c + Vector2(-1.0, 0.0), Vector2(2.0, 4.0)), COL_SEALED)


## One tile in `box`: panel, red flash, icon (grey when it cannot be cast, dark when sealed), cooldown shade, key plate, price plate.
## `key_label` is "" for no key plate; `price` draws the Might price bottom-right.
func _draw_tile(on: CanvasItem, box: Rect2, slot: int, key_label: String, armed: bool, flash_alpha: float, price: bool) -> void:
	var state := tile_state(slot)
	on.draw_rect(box, UiTheme.COL_PANEL)
	if flash_alpha > 0.0:
		var red := UiTheme.COL_BAD
		red.a = flash_alpha
		on.draw_rect(box, red)
	var icon_box := _icon_rect(box)
	var icon := _icon(slot, icon_box)
	if icon != null:
		var tint := Color.WHITE
		if state == "sealed":
			tint = COL_SEALED
		elif state != "ready":
			tint = COL_POOR
		on.draw_texture_rect(icon, icon_box, false, tint)
	if armed:
		UiTheme.frame(on, box, true)
	else:
		on.draw_rect(box, COL_EDGE, false, 1.0)
	if state == "sealed":
		_padlock(on, box.get_center())
	if state == "busy":
		on.draw_rect(box, Color(0, 0, 0, 0.35))
	if state == "cooldown":
		var left := _rules.cooldown_left(slot)
		var frac := clampf(left / maxf(_rules.cooldown_of(slot), 0.001), 0.0, 1.0)
		on.draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * frac)), Color(0, 0, 0, 0.6))
		var secs := "%d" % ceili(left)
		UiTheme.text(on, box.get_center() + Vector2(-UiTheme.width(secs, UiTheme.TEXT_L) * 0.5, 8.0), secs, UiTheme.TEXT_L, UiTheme.COL_TEXT)
	if key_label != "":
		_plate(on, box.position + Vector2(1.0, 1.0), key_label, UiTheme.COL_TEXT)
	if price:
		var cost := "%d" % _rules.might_cost(slot)
		var size := Vector2(UiTheme.width(cost, UiTheme.TEXT_S) + 2.0, PLATE_H)
		_plate(on, box.end - size - Vector2(1.0, 1.0), cost, UiTheme.COL_BAD if state == "might" else COL_MIGHT)


## The key a page place carries: 1..9, then 0.
static func _key_label(digit: int) -> String:
	return "%d" % ((digit + 1) % 10)


## "MIGHT", the segments and "v / cap", the words' baseline at `base_y`, the segments' top at `seg_y`; `x` is the left edge.
func _draw_gauge(on: CanvasItem, x: float, base_y: float, seg_y: float) -> void:
	var pool := _rules.might
	var count := _segments()
	if pool == null or count == 0:
		return
	UiTheme.text(on, Vector2(x, base_y), "MIGHT", UiTheme.TEXT_S, COL_MIGHT)
	x += UiTheme.width("MIGHT", UiTheme.TEXT_S) + 4.0
	var strip_w := float(count) * (SEG.x + SEG_GAP) + SEG_GAP
	on.draw_rect(Rect2(x, seg_y - SEG_GAP, strip_w, SEG.y + 2.0 * SEG_GAP), Color(0, 0, 0, 0.65))
	for i in count:
		var seg := Rect2(x + SEG_GAP + float(i) * (SEG.x + SEG_GAP), seg_y, SEG.x, SEG.y)
		on.draw_rect(seg, COL_SEG_EMPTY)
		var fill := clampf(pool.value - float(i), 0.0, 1.0)
		if fill >= 1.0 - MightPool.EPSILON:
			on.draw_rect(seg, COL_SEG)
		elif fill > 0.0:
			on.draw_rect(Rect2(seg.position, Vector2(seg.size.x * fill, seg.size.y)), COL_SEG)
	x += strip_w + 4.0
	UiTheme.text(on, Vector2(x, base_y), "%d / %d" % [pool.whole(), int(pool.capacity)], UiTheme.TEXT_S, UiTheme.COL_TEXT)


## The ability's one line: name, price, ready or what stops it.
func _line_parts(slot: int, gold: bool) -> Array:
	var state := tile_state(slot)
	var status := "ready"
	match state:
		"cooldown":
			status = "%ds" % ceili(_rules.cooldown_left(slot))
		"might":
			status = "not enough Might"
		"sealed":
			status = "sealed"
		"busy":
			status = "%ds" % ceili(_rules.busy_left())
		"over", "empty":
			status = ""
	return [[_names[slot] if slot < _names.size() else "", UiTheme.COL_GOLD if gold else UiTheme.COL_TEXT],
		["%d Might" % _rules.might_cost(slot), COL_MIGHT], [status, UiTheme.COL_DIM]]


## Draws what rect() reports onto `on`. `armed` is the armed slot (-1 none), `hover` the slot under the mouse (-1 none), `flash` the
## HUD's seconds of red per slot.
func draw(on: CanvasItem, view: Vector2, armed: int, hover: int, flash: PackedFloat32Array) -> void:
	if _rules == null:
		return
	if open and not _pages.is_empty():
		_draw_open(on, view, armed, hover, flash)
	else:
		_draw_strip(on, view, armed)


## The red a refused cast leaves on `slot`.
func _flash_alpha(flash: PackedFloat32Array, slot: int) -> float:
	return clampf(flash[slot] / Hud.FLASH_SECONDS, 0.0, 1.0) if slot >= 0 and slot < flash.size() else 0.0


func _draw_strip(on: CanvasItem, view: Vector2, armed: int) -> void:
	var box := _strip(view)
	on.draw_rect(box, UiTheme.COL_PANEL)
	var tile := strip_tile_rect(view)
	var x := tile.end.x + 4.0
	if armed >= 0:
		_draw_tile(on, tile, armed, _key_label(maxi(digit_of(armed), 0)), true, 0.0, false)
		var parts := _line_parts(armed, true)
		UiTheme.text(on, Vector2(x, box.position.y + 11.0), UiTheme.fit(parts[0][0], NAME_ROOM), UiTheme.TEXT_S, UiTheme.COL_GOLD)
		UiTheme.text(on, Vector2(x, box.position.y + 23.0), parts[1][0], UiTheme.TEXT_S, COL_MIGHT)
	else:
		on.draw_rect(tile, COL_EDGE, false, 1.0)
	x += NAME_ROOM + GAP
	_draw_gauge(on, x, box.position.y + 18.0, box.position.y + (STRIP_TILE - SEG.y) * 0.5)
	x += _gauge_width() + GAP
	if _flash_left > 0.0 and not _pages.is_empty():
		UiTheme.text(on, Vector2(x, box.position.y + 18.0), _tab_label(page), UiTheme.TEXT_S, UiTheme.COL_GOLD)
	else:
		UiTheme.text(on, Vector2(x, box.position.y + 18.0), HINT, UiTheme.TEXT_S, UiTheme.COL_DIM)


func _draw_open(on: CanvasItem, view: Vector2, armed: int, hover: int, flash: PackedFloat32Array) -> void:
	var lay := _open_layout(view)
	var slots := _slots()
	for i in slots.size():
		_draw_tile(on, tile_rect(i, view), slots[i], _key_label(i), slots[i] == armed, _flash_alpha(flash, slots[i]), true)
	var shown := hover if hover >= 0 and _slots().has(hover) else armed
	if shown >= 0:
		var parts := _line_parts(shown, shown == armed)
		var total := 0.0
		for p: Array in parts:
			total += UiTheme.width(p[0], UiTheme.TEXT_S) + (GAP if p[0] != "" else 0.0)
		var x := (view.x - total + GAP) * 0.5
		for p: Array in parts:
			if p[0] == "":
				continue
			UiTheme.text(on, Vector2(x, lay.name_top + LINE - 3.0), p[0], UiTheme.TEXT_S, p[1])
			x += UiTheme.width(p[0], UiTheme.TEXT_S) + GAP
	if _has_tabs():
		var tabs := _tab_layout(view, lay.tabs_top)
		for key: String in ["z", "x"]:
			var kr: Rect2 = tabs[key]
			UiTheme.text(on, kr.position + Vector2(3.0, LINE - 4.0), key.to_upper(), UiTheme.TEXT_S, UiTheme.COL_DIM)
		for i in _pages.size():
			var tr: Rect2 = tabs.tabs[i]
			var current := i == page
			on.draw_rect(tr, UiTheme.COL_GOLD if current else UiTheme.COL_PANEL)
			var label := _tab_label(i)
			UiTheme.text(on, tr.position + Vector2(floorf((tr.size.x - UiTheme.width(label, UiTheme.TEXT_S)) * 0.5), LINE - 4.0), label,
				UiTheme.TEXT_S, Color("10161b") if current else UiTheme.COL_DIM)
	var gauge_x := (view.x - _gauge_width()) * 0.5
	_draw_gauge(on, gauge_x, lay.gauge_top + LINE - 3.0, lay.gauge_top + (LINE - SEG.y) * 0.5)
