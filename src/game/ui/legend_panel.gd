class_name LegendPanel
extends Control
## The legend of marks (v0.11.1, spec §4): H opens it over a mission, page 1 "WHAT THE MARKS MEAN" (the HUD's colours, with this
## night's own tags listed beside them), H again page 2 "OVER HEADS AND ON THE HUD", H once more closes it; Esc closes it at once.
## The night waits while it is open (Mission freezes itself), so this node runs whatever the mission's state and takes H and
## Esc itself. It is drawn with the HUD's own primitives and redrawn only when the page changes. It reads, and changes nothing.

## Closed (page 0, or after Esc/H on page 2). The mission frees the panel and lets the night go on.
signal closed

const VIEW := Vector2(640.0, 360.0)
const PANEL := Rect2(20.0, 12.0, 600.0, 336.0)
const FOOTER := "H next   Esc close   the night waits"
const TITLES := ["WHAT THE MARKS MEAN", "OVER HEADS AND ON THE HUD"]
const NIGHT_TITLE := "This night"
const NOTHING := "Nothing is marked yet."
const UNNAMED := "(unnamed)"
## How many distinct labels one colour's row lists.
const ROW_LABELS := 3

## The swatch zone beside every row: its width, and the least a row takes (px).
const SWATCH_W := 26.0
const ROW_MIN := 15.0
const COL_GAP := 16.0
const LEFT_W := 300.0

## The HUD's colours (spec 0, the plan's global constraints).
const TARGET := Color("d8b23a")
const PLACE := Color("ff9a3a")
const DANGER := Color("c8342a")
const CHARGE := Color("8fb8e8")
const NOT_YET := Color("9a948a")
const CLEAR := Color("7fc46a")
const WISH := Color("8fb8ff")

## Page 1, left: [swatch kind, colour, words] (spec §4.1).
const MARKS := [
	["diamond", TARGET, "Gold: your target"],
	["diamond", PLACE, "Orange: a place, or what comes next"],
	["diamond", DANGER, "Red: those who would see, seize or stop you"],
	["diamond", CHARGE, "Steel blue: one you lead, or the guard the hint names"],
	["diamond", NOT_YET, "Grey: not yet; it comes later"],
	["faded", NOT_YET, "Faded: not this one yet"],
	["diamond", CLEAR, "Green: the way is clear"],
	["diamond", WISH, "Soft blue: a wish of the town; click a waiting one to begin it"],
	["pip", TARGET, "Small diamond: one of a crowd"],
	["outline", PLACE, "Outline on the ground: the building or yard that matters"],
	["arrow", TARGET, "Arrow at the edge: a mark off screen; hover it for its name"],
	["plate", DANGER, "DO NOT KILL: that death loses the night"],
]

## Page 2: the same shape (spec §4.2). v0.11.2 (spec 5.5, R33): 21 rows, laid in two columns -- the first OVERHEAD_SPLIT rows on the left, the rest
## on the right -- with the Lantern's four after Halcyon's light (its clock ring leads the HUD's column).
const OVERHEAD := [
	["eye", Color("ffe9a8"), "Gold eye: whispered, walking where you sent them"],
	["swirl", Color("b070ff"), "Violet swirl: confused by Discord"],
	["glyph_ring", Color("ffcf5a"), "Glyph and ring: compelled; the glyph names the order"],
	["badge", Color("ffcf5a"), "Badge: held, believing, judged, turned or marked to die"],
	["madness", Color("ff9a3a"), "Ring underfoot: madness; it reddens as it grows"],
	["tint", CLEAR, "Green to red: the plague, from caught to dying"],
	["beam", Color("ffe9a8"), "Halcyon's light: anyone in it is seen; a cast in it adds to the Gaze"],
	["beam", SearchlightFx.PALE_POOL, "Pale beam: the Lantern's eye. A loud power or a seen death in it makes it burn"],
	["diamond", TARGET, "LANTERN-BEARER: kill him and dawn slows again; his escorts take the flame if they see"],
	["diamond", TARGET, "HERALD: runs to the Temple; if he gets in, the night is lost"],
	["clock_ring", Color("d8b23a"), "Gold ring on the clock: the Lantern hastens dawn, x1.5; red, burning, x2.0"],
	["gaze_bar", TARGET, "The Gaze: when it fills, the night is lost"],
	["rite_bar", TARGET, "The Banishing Rite: finished, it takes time off your clock"],
	["strip", NOT_YET, "The strip: what happens next, and when"],
	["stability", TARGET, "City stability: Pop, Infra, Lead, Mil, Res"],
	["wishes", WISH, "Wishes: open, granted, failed"],
	["cooldown", TARGET, "A power cooling down; a gold number: another power still plays"],
	["refused", DANGER, "That cast was refused"],
	["aim_ring", UiTheme.COL_TEXT, "Where the power will land"],
	["district", PLACE, "The district the power will reach"],
	["topline", NOT_YET, "Citizens, soldiers, buildings down, and the town's alarm"],
]

## How many of OVERHEAD's rows the first column holds (the marks over the town and the Lantern's beam and people; the HUD's own are the second's).
const OVERHEAD_SPLIT := 10

## 0 closed, 1 or 2 the page showing.
var page := 0
## This night's rows, built when the panel is set up: [[Color, String]].
var _night: Array = []


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP  # a click on the legend casts nothing into the town under it
	set_anchors_preset(Control.PRESET_FULL_RECT)


## The panel for a night whose live tags are `tags` (Hud.all_tags()).
func setup(tags: Array[MapTag]) -> LegendPanel:
	_night = night_rows(tags)
	return self


## 0 -> 1 -> 2 -> 0: closing on the third press emits `closed`.
func open_next() -> void:
	if page >= 2:
		close()
		return
	page += 1
	UiSound.play(&"ui_click")
	queue_redraw()


func close() -> void:
	if page == 0:
		return
	page = 0
	UiSound.play(&"ui_back")
	queue_redraw()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if page == 0 or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_H:
		_handled()
		open_next()
	elif event.physical_keycode == KEY_ESCAPE:
		# Handled here, so the same Esc cannot reach the pause menu it would open.
		_handled()
		close()


func _handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


## The right column of page 1: one row per colour, in order of first appearance among `tags`, with up to ROW_LABELS of its
## distinct labels joined by ", " ("(unnamed)" for a bare tag). Empty for no tags: the caller says "Nothing is marked yet.".
static func night_rows(tags: Array[MapTag]) -> Array:
	var colours: Array[Color] = []
	var labels: Array = []
	for t in tags:
		var at := colours.find(t.color)
		if at < 0:
			colours.append(t.color)
			labels.append([])
			at = colours.size() - 1
		var words: String = t.label if t.label != "" else UNNAMED
		if not (labels[at] as Array).has(words):
			(labels[at] as Array).append(words)
	var out := []
	for i in colours.size():
		out.append([colours[i], ", ".join((labels[i] as Array).slice(0, ROW_LABELS))])
	return out


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	if page == 0:
		return
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.0, 0.0, 0.0, 0.5))
	draw_rect(PANEL, Color(0.04, 0.04, 0.06, 0.92))
	UiTheme.frame(self, PANEL.grow(-3.0), true)
	var title: String = TITLES[page - 1]
	UiTheme.text(self, Vector2(roundf(PANEL.get_center().x - UiTheme.width(title, UiTheme.SIZE_BIG) * 0.5), PANEL.position.y + 26.0),
		title, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var count := "%d / 2" % page
	UiTheme.text(self, Vector2(PANEL.end.x - 14.0 - UiTheme.width(count, UiTheme.SIZE_SMALL), PANEL.position.y + 26.0), count,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	var left := PANEL.position.x + 16.0
	var top := PANEL.position.y + 44.0
	if page == 1:
		_draw_rows(MARKS, left, top, LEFT_W - SWATCH_W - 8.0)
		var right := left + LEFT_W + COL_GAP
		UiTheme.text(self, Vector2(right, top + 2.0), NIGHT_TITLE, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
		var rows: Array = []
		for r in _night:
			rows.append(["diamond", r[0], String(r[1])])
		if rows.is_empty():
			UiTheme.text(self, Vector2(right, top + 22.0), NOTHING, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		else:
			var room := PANEL.end.x - 16.0 - right - SWATCH_W - 8.0
			_draw_rows(fit_rows(rows, room, top + 10.0, PANEL.end.y - 24.0), right, top + 10.0, room)
	else:
		var cols := overhead_columns()
		var room := column_room()
		_draw_rows(cols[0], left, top, room)
		_draw_rows(cols[1], left + room + SWATCH_W + 8.0 + COL_GAP, top, room)
	_draw_footer()


## Page 2's two columns, as [left rows, right rows].
static func overhead_columns() -> Array:
	return [OVERHEAD.slice(0, OVERHEAD_SPLIT), OVERHEAD.slice(OVERHEAD_SPLIT)]


## The words' room in one of page 2's columns (px): half the panel's inner width less the gap, then the swatch zone.
static func column_room() -> float:
	return (PANEL.size.x - 32.0 - COL_GAP) * 0.5 - SWATCH_W - 8.0


## The height `rows` take wrapped to `room` (what _draw_rows() advances by).
static func rows_height(rows: Array, room: float) -> float:
	var total := 0.0
	for r: Array in rows:
		total += maxf(ROW_MIN, UiTheme.LINE_SMALL * float(UiTheme.wrap(String(r[2]), room, UiTheme.SIZE_SMALL).size()) + 3.0)
	return total


## The rows that fit between `top` and `bottom` (v0.11.1 fix round): the column has no room to run into the footer, so the rows
## beyond what fits become one last row, "+K more". All of them when they fit.
static func fit_rows(rows: Array, room: float, top: float, bottom: float) -> Array:
	var heights: Array[float] = []
	var total := 0.0
	for r: Array in rows:
		var h := maxf(ROW_MIN, UiTheme.LINE_SMALL * float(UiTheme.wrap(String(r[2]), room, UiTheme.SIZE_SMALL).size()) + 3.0)
		heights.append(h)
		total += h
	if top + total <= bottom:
		return rows
	var out: Array = []
	var y := top + ROW_MIN  # the "+K more" row is kept room for
	for i in rows.size():
		if y + heights[i] > bottom:
			break
		y += heights[i]
		out.append(rows[i])
	out.append(["none", UiTheme.COL_DIM, "+%d more" % (rows.size() - out.size())])
	return out


## The footer's three phrases with a visible gap between them (the pixel font's spaces are narrow).
func _draw_footer() -> void:
	var parts := FOOTER.split("   ")
	var gap := 14.0
	var total := gap * float(parts.size() - 1)
	for part in parts:
		total += UiTheme.width(part, UiTheme.SIZE_SMALL)
	var x := roundf(PANEL.get_center().x - total * 0.5)
	for part in parts:
		UiTheme.text(self, Vector2(x, PANEL.end.y - 12.0), part, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		x += UiTheme.width(part, UiTheme.SIZE_SMALL) + gap


## Rows down from `top`: a swatch, then the words wrapped to `room`. Returns the y below the last.
func _draw_rows(rows: Array, x: float, top: float, room: float) -> float:
	var y := top
	for r: Array in rows:
		var lines := UiTheme.wrap(String(r[2]), room, UiTheme.SIZE_SMALL)
		var h := maxf(ROW_MIN, UiTheme.LINE_SMALL * float(lines.size()) + 3.0)
		_swatch(String(r[0]), r[1], x, y + 7.0)
		for i in lines.size():
			UiTheme.text(self, Vector2(x + SWATCH_W + 8.0, y + 10.0 + UiTheme.LINE_SMALL * float(i)), lines[i], UiTheme.SIZE_SMALL)
		y += h
	return y


func _glyph(rows: Array[int], at: Vector2, col: Color, px := 2.0) -> void:
	for gy in 5:
		for gx in 5:
			if (rows[gy] >> (4 - gx)) & 1 == 1:
				draw_rect(Rect2(at + Vector2(gx, gy) * px, Vector2(px, px)), col)


func _ellipse(c: Vector2, rx: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, rx, 0.0, TAU, 24, col, -1.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## One row's picture, in the SWATCH_W box starting at `x`, centred on `cy`.
func _swatch(kind: String, col: Color, x: float, cy: float) -> void:
	var c := Vector2(x + SWATCH_W * 0.5, cy)
	match kind:
		"diamond", "faded", "pip":
			var tint := col
			if kind == "faded":
				tint.a = 0.55
			var shape := Hud.mark_shape(c, 3.0 if kind == "pip" else Hud.MARK_R)
			draw_colored_polygon(shape, tint)
			shape.append(shape[0])
			draw_polyline(shape, Hud.MARK_EDGE, -1.0)
		"outline":
			draw_polyline(PackedVector2Array([c + Vector2(-10, 0), c + Vector2(0, -5), c + Vector2(10, 0), c + Vector2(0, 5),
				c + Vector2(-10, 0)]), col, 1.0)
		"arrow":
			Hud.paint_arrow(self, Vector2(x + 16.0, cy), Vector2.RIGHT, col, col.darkened(0.4))
		"plate":
			draw_rect(Rect2(x, cy - 5.0, SWATCH_W, 10.0), Color(0.04, 0.04, 0.06, 0.9))
			draw_rect(Rect2(x, cy - 5.0, SWATCH_W, 10.0), col, false, 1.0)
			for i in 3:
				draw_rect(Rect2(x + 3.0 + 7.0 * float(i), cy - 1.0, 5.0, 2.0), UiTheme.COL_TEXT)
		"eye":
			_glyph(DominionParts.EYE, c - Vector2(5, 5), col)
		"swirl":
			draw_arc(c, 3.0, 0.0, TAU * 0.8, 12, col, 1.0)
			draw_arc(c, 6.0, 1.0, 1.0 + TAU * 0.8, 16, col, 1.0)
		"glyph_ring":
			_glyph(DominionParts.CROSS, c - Vector2(5, 9), col)
			_ellipse(c + Vector2(0, 5), 10.0, col)
		"badge":
			_glyph(DecreeParts.BARS, c - Vector2(11, 5), col)
			_glyph(DominionParts.BLADE, c + Vector2(1, -5), col)
		"madness":
			_ellipse(c + Vector2(0, 2), 10.0, col)
			_ellipse(c + Vector2(0, 2), 7.0, DANGER)
		"tint":
			for i in 8:
				draw_rect(Rect2(x + 1.0 + 3.0 * float(i), cy - 4.0, 3.0, 8.0), CLEAR.lerp(DANGER, float(i) / 7.0))
		"clock_ring":
			draw_rect(Rect2(x + 1.0, cy - 7.0, 24.0, 14.0), col, false, 1.0)
			UiTheme.text(self, Vector2(x + 3.0, cy + 4.0), "1.5", UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
		"beam":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -6), c + Vector2(2, -6), c + Vector2(10, 5), c + Vector2(-10, 5)]),
				Color(col, 0.4))
			_ellipse(c + Vector2(0, 5), 10.0, col)
		"gaze_bar":
			draw_rect(Rect2(x + 1.0, cy - 2.0, 24.0, 4.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(x + 1.0, cy - 2.0, 16.0, 4.0), UiTheme.COL_GOLD.lerp(UiTheme.COL_BAD, 0.65))
		"rite_bar":
			draw_rect(Rect2(x + 1.0, cy - 2.0, 24.0, 4.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(x + 1.0, cy - 2.0, 15.0, 4.0), col)
		"strip":
			UiTheme.text(self, Vector2(x, cy + 4.0), "0:23", UiTheme.SIZE_SMALL, col)
		"stability":
			for i in 5:
				draw_rect(Rect2(x + 1.0 + 5.0 * float(i), cy - 2.0, 4.0, 5.0), UiTheme.STABILITY_COLS[i])
		"wishes":
			draw_rect(Rect2(x, cy - 3.0, 7.0, 7.0), col, false, 1.0)
			UiTheme.mark(self, Vector2(x + 9.0, cy - 3.0), true)
			UiTheme.mark(self, Vector2(x + 18.0, cy - 3.0), false)
		"cooldown":
			draw_rect(Rect2(x + 2.0, cy - 6.0, 12.0, 12.0), Color(0.04, 0.04, 0.06, 0.9))
			draw_rect(Rect2(x + 2.0, cy - 6.0, 12.0, 7.0), Color(0, 0, 0, 0.55))
			draw_rect(Rect2(x + 2.0, cy - 6.0, 12.0, 12.0), UiTheme.COL_GOLD_DARK, false, 1.0)
			UiTheme.text(self, Vector2(x + 17.0, cy + 4.0), "2", UiTheme.SIZE_SMALL, col)
		"refused":
			draw_rect(Rect2(x + 7.0, cy - 6.0, 12.0, 12.0), Color(col, 0.45))
			draw_rect(Rect2(x + 7.0, cy - 6.0, 12.0, 12.0), col, false, 1.0)
		"aim_ring":
			_ellipse(c, 10.0, col)
			draw_circle(c, 1.0, col)
		"district":
			draw_polyline(PackedVector2Array([c + Vector2(-12, 0), c + Vector2(-2, -6), c + Vector2(12, -2), c + Vector2(4, 6),
				c + Vector2(-12, 0)]), col, 1.0)
		"topline":
			for i in 3:
				draw_rect(Rect2(x + 1.0 + 8.0 * float(i), cy - 1.0, 6.0, 2.0), col)
