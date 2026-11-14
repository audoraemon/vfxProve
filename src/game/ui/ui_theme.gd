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
## Red text on a flat dark screen: COL_BAD is only 3.7:1 there (5.8:1 for this), and a refusal or a warning must read at 11 u.
const COL_BAD_TEXT := Color("e8604f")
## Gold for a card or name that is not the selected one: COL_GOLD_DARK on black is 2.9:1 (6.4:1 for this); the selected one stays COL_GOLD.
const COL_GOLD_MID := Color("b09030")
const COL_SHADOW := Color(0, 0, 0, 0.75)
## The five stability colours in the spec's order: population, infrastructure, leadership, military, resources.
const STABILITY_COLS := [Color("7fc46a"), Color("c8a05a"), Color("d8b23a"), Color("c05a4a"), Color("6fa8c8")]

## The smallest text that reads. Pixelify Sans is drawn on a pixel grid and, with smoothing off, anything under
## 11 px drops strokes: at 8 px "Citadel" read "Otodel", the colon in 4:00 vanished and 50 read 20.
const SIZE_SMALL := 11
const SIZE_BODY := 13
## Line spacing for stacked text at those sizes.
const LINE_SMALL := 12.0
const LINE_BODY := 15.0
const SIZE_BIG := 16
## The game's name on the title screen and the ending on the results screen.
const SIZE_TITLE := 32
## The rank letter on the results screen.
const SIZE_HUGE := 64

## The crisp text sizes (UI resolution): multiples of 11, so every glyph lands on the device pixel grid at every integer scale.
## The skill tree and the HUD use only these; the old SIZE_* stay until nothing uses them.
const TEXT_S := 11
const TEXT_L := 22
const TEXT_XL := 33
const TEXT_XXL := 66
## Line spacing for stacked text at TEXT_S and TEXT_L.
const LINE_S := 12.0
const LINE_L := 24.0

static var _font: FontFile
static var _variations := {}


## The pixel font file with every smoothing trick off: on a 640x360 screen a blurred glyph is a broken glyph.
static func base_font() -> FontFile:
	if _font == null:
		_font = load(FONT_PATH)
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		# The font's "fi" ligature is a single glyph that reads as a capital A at every size ("fire" -> "Are",
		# "Dragonfire" -> "DragonAre"). Letters are drawn one by one instead.
		var ts := TextServerManager.get_primary_interface()
		_font.opentype_feature_overrides = {ts.name_to_tag("liga"): 0, ts.name_to_tag("clig"): 0}
	return _font


## Whether UI text gets its extra word spacing: true while any owner holds it (spacing_acquire). The skill tree and the HUD hold it while they live: the wider
## spaces change how every wrapped text fits, and each other screen re-fits its own text when it migrates (Tasks 6-8), then this becomes the default.
## Callers read it; tests that need a state save and set it directly and restore it, and tests/run_part.gd resets it per suite (spacing_reset).
static var word_spacing := false
## The owners (instance ids) that hold the wider spaces.
static var _spacing_owners := {}


## `owner` wants the wider spaces. Idempotent per owner (a second acquire changes nothing); one owner leaving never clears another's.
static func spacing_acquire(owner: Object) -> void:
	_spacing_owners[owner.get_instance_id()] = true
	word_spacing = true


## `owner` is done with them: they go off when the last owner has released. Releasing without having acquired does nothing.
static func spacing_release(owner: Object) -> void:
	_spacing_owners.erase(owner.get_instance_id())
	word_spacing = not _spacing_owners.is_empty()


## Nobody holds them (tests, between suites).
static func spacing_reset() -> void:
	_spacing_owners.clear()
	word_spacing = false


## The pixel font as the UI draws it at `size`: the file plus, when `word_spacing` is on, extra word spacing, because its space is only
## 2 u wide at 11 u and words ran together ("Notenoughability"). +1 px of space per 11 u of size (+1 at 11, +2 at 22, +3 at 33, +6 at 66).
static func font_for(size := TEXT_S) -> FontVariation:
	var extra := maxi(1, int(round(float(size) / 11.0))) if word_spacing else 0
	if not _variations.has(extra):
		var v := FontVariation.new()
		v.base_font = base_font()
		v.spacing_space = extra
		_variations[extra] = v
	return _variations[extra]


## The font for 11 u text (what callers without a size draw with).
static func font() -> FontVariation:
	return font_for(TEXT_S)


## m:ss, the way the mission clock reads. Rounded up, so it shows 0:01 until the last moment and 0:00 only
## when the manifestation is actually over.
static func clock(seconds: float) -> String:
	var whole := int(ceilf(maxf(0.0, seconds)))
	return "%d:%02d" % [whole / 60, whole % 60]


## The text shadow's colour: COL_SHADOW, its opacity scaled by `fade` (v0.10 M5), for text that is fading in or out.
static func shadow_color(fade := 1.0) -> Color:
	return Color(COL_SHADOW.r, COL_SHADOW.g, COL_SHADOW.b, COL_SHADOW.a * fade)


## Text with a hard black shadow one pixel down-right, which is how every label in this game is drawn. Text whose colour
## fades passes the same fade as `shadow_a` (v0.10 M5: Cael's lines), or its shadow shows bare before the words come up and
## stays behind as they go.
static func text(on: CanvasItem, at: Vector2, s: String, size := SIZE_BODY, col := COL_TEXT, shadow_a := 1.0) -> void:
	on.draw_string(font_for(size), at + Vector2.ONE, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, shadow_color(shadow_a))
	on.draw_string(font_for(size), at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## How wide that text will be, for right-aligned and centred lines.
static func width(s: String, size := SIZE_BODY) -> float:
	return font_for(size).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## A string broken into lines no wider than `width`, at word boundaries. A single word wider than the line is
## left whole on its own line rather than cut: the pixel font has no hyphenation worth reading.
static func wrap(s: String, line_width: float, size := SIZE_BODY) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in s.split(" ", false):
		var tried := word if line == "" else line + " " + word
		if line != "" and width(tried, size) > line_width:
			lines.append(line)
			line = word
		else:
			line = tried
	if line != "":
		lines.append(line)
	return lines


## A name cut to one line of `room` px (v0.08: Prepare's loadout bar and the HUD's compact slots): whole if it fits,
## else its first word, trimmed letter by letter until that fits.
static func fit(s: String, room: float, size := SIZE_SMALL) -> String:
	var out := s
	if width(out, size) > room:
		out = out.split(" ")[0]
	while out.length() > 1 and width(out, size) > room:
		out = out.substr(0, out.length() - 1)
	return out


## A tick (gold) or a cross (red) seven pixels square, its top-left at `at`: the font has no check-mark glyph (v0.08).
static func mark(on: CanvasItem, at: Vector2, ok: bool) -> void:
	if ok:
		on.draw_polyline(PackedVector2Array([at + Vector2(0, 4), at + Vector2(2, 6), at + Vector2(7, 0)]), COL_GOLD, 1.0)
	else:
		on.draw_line(at, at + Vector2(6, 6), COL_BAD, 1.0)
		on.draw_line(at + Vector2(6, 0), at + Vector2(0, 6), COL_BAD, 1.0)


## The one gold frame every icon in the game wears: a bevel, four corner studs and a small diamond on top.
static func frame(on: CanvasItem, rect: Rect2, bright := true) -> void:
	var gold := COL_GOLD if bright else COL_GOLD_DARK
	var dark := COL_GOLD_DARK if bright else Color(0.2, 0.16, 0.08, 1.0)
	on.draw_rect(rect.grow(1.0), dark, false, 1.0)
	on.draw_rect(rect, gold, false, 1.0)
	for corner in [rect.position, Vector2(rect.end.x - 1.0, rect.position.y),
			Vector2(rect.position.x, rect.end.y - 1.0), rect.end - Vector2.ONE]:
		on.draw_rect(Rect2(corner, Vector2.ONE), gold)
	var top := Vector2(rect.get_center().x, rect.position.y - 2.0)
	on.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -2), top + Vector2(2, 0), top + Vector2(0, 2),
		top + Vector2(-2, 0)]), gold)
