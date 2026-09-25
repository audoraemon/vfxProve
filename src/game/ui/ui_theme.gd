class_name UiTheme
extends RefCounted
## The game's pixel UI look, in one place: the font, the palette, the shared gold icon frame and the clock's
## format. Milestone 4's Title, Prepare and Results screens use the same ones.

const FONT_PATH := "res://assets/fonts/PixelifySans-Variable.ttf"

const COL_TEXT := Color("e8e2d0")
const COL_DIM := Color("9a9484")
const COL_GOLD := Color("d8b23a")
const COL_GOLD_DARK := Color("7a5f18")
const COL_PANEL := Color(0.04, 0.04, 0.06, 0.66)
const COL_BAD := Color("c8342a")
const COL_DP := Color("6fd0ff")
const COL_DP_LOW := Color("ffb040")
const COL_SHADOW := Color(0, 0, 0, 0.75)
## The five stability colours in the spec's order: population, infrastructure, leadership, military, resources.
const STABILITY_COLS := [Color("7fc46a"), Color("c8a05a"), Color("d8b23a"), Color("c05a4a"), Color("6fa8c8")]

const SIZE_SMALL := 8
const SIZE_BODY := 10
const SIZE_BIG := 16

static var _font: FontFile


## The pixel font with every smoothing trick off: on a 640x360 screen a blurred glyph is a broken glyph.
static func font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH)
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font


## m:ss, the way the mission clock reads. Rounded up, so it shows 0:01 until the last moment and 0:00 only
## when the manifestation is actually over.
static func clock(seconds: float) -> String:
	var whole := int(ceilf(maxf(0.0, seconds)))
	return "%d:%02d" % [whole / 60, whole % 60]


## Text with a hard black shadow one pixel down-right, which is how every label in this game is drawn.
static func text(on: CanvasItem, at: Vector2, s: String, size := SIZE_BODY, col := COL_TEXT) -> void:
	on.draw_string(font(), at + Vector2.ONE, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, COL_SHADOW)
	on.draw_string(font(), at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## How wide that text will be, for right-aligned and centred lines.
static func width(s: String, size := SIZE_BODY) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## The one gold frame every icon in the game wears: a bevel, four corner studs and a small diamond on top.
static func frame(on: CanvasItem, rect: Rect2, bright := true) -> void:
	var gold := COL_GOLD if bright else COL_GOLD_DARK
	var dark := COL_GOLD_DARK if bright else Color(0.2, 0.16, 0.08, 1.0)
	on.draw_rect(rect.grow(1.0), dark, false, -1.0)
	on.draw_rect(rect, gold, false, -1.0)
	for corner in [rect.position, Vector2(rect.end.x - 1.0, rect.position.y),
			Vector2(rect.position.x, rect.end.y - 1.0), rect.end - Vector2.ONE]:
		on.draw_rect(Rect2(corner, Vector2.ONE), gold)
	var top := Vector2(rect.get_center().x, rect.position.y - 2.0)
	on.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -2), top + Vector2(2, 0), top + Vector2(0, 2),
		top + Vector2(-2, 0)]), gold)
