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

## The ten digits as drawn here, in two bitmap sizes. Pixelify Sans's own digits read wrong at UI sizes: its 5 is an S ("15,380" read "1S,3S0"),
## its 8 an S too, its 7 a "?" and its 2 and 3 are squashed. These are drawn in front of the font (digit_font), so every number in the game uses them.
## SMALL is 5 x 7, advance 6: drawn at 11 and whole multiples of it (22, 33, 66). MEDIUM is 6 x 9, advance 7: drawn at 13-21 (the old body and big sizes).
const DIGITS_SMALL := {
	"0": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
}
## The capitals Pixelify Sans draws so alike at 11 u that they read as each other: its B has the same round ink as an 8 or a G ("Barrage" read "Garrage",
## "Breaker" "Greaker"), its G as a B, its E as a C with an open tail, its H as a W or N, and its Z as a 2. Drawn here with square shoulders, 5 x 7 like the digits
## and with the same advance (6) as the font's own, so no line changes width. They are in the small set only (11 u and its whole multiples); the legacy 13-21 sizes keep the font's.
const LETTERS_SMALL := {
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
}
const DIGITS_MEDIUM := {
	"0": [".####.", "#....#", "#....#", "#....#", "#....#", "#....#", "#....#", "#....#", ".####."],
	"1": ["..#...", ".##...", "..#...", "..#...", "..#...", "..#...", "..#...", "..#...", ".###.."],
	"2": [".####.", "#....#", ".....#", ".....#", "....#.", "...#..", "..#...", ".#....", "######"],
	"3": [".####.", "#....#", ".....#", ".....#", "..###.", ".....#", ".....#", "#....#", ".####."],
	"4": ["....#.", "...##.", "..#.#.", ".#..#.", "#...#.", "######", "....#.", "....#.", "....#."],
	"5": ["######", "#.....", "#.....", "#####.", ".....#", ".....#", ".....#", "#....#", ".####."],
	"6": ["..###.", ".#....", "#.....", "#.....", "#####.", "#....#", "#....#", "#....#", ".####."],
	"7": ["######", ".....#", ".....#", "....#.", "...#..", "..#...", "..#...", "..#...", "..#..."],
	"8": [".####.", "#....#", "#....#", "#....#", ".####.", "#....#", "#....#", "#....#", ".####."],
	"9": [".####.", "#....#", "#....#", "#....#", ".#####", ".....#", ".....#", "....#.", ".###.."],
}
## The sizes the digit bitmaps are native at: the small ones also serve every whole multiple (integer scaling only, so they stay on the pixel grid).
const DIGIT_SMALL_NATIVE := 11
const DIGIT_MEDIUM_NATIVE := 13
## The first size that takes the medium digits, and the first that goes back to the small ones (doubled: 22 u).
const DIGIT_MEDIUM_FROM := 13
const DIGIT_MEDIUM_UNTIL := 22

static var _font: FontFile
static var _digits := {}
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


## Whether `size` takes the medium digit set (13-21) rather than the small one (11 and whole multiples).
static func digits_medium(size: int) -> bool:
	return size >= DIGIT_MEDIUM_FROM and size < DIGIT_MEDIUM_UNTIL


## The extra width a space gets at `size` when the words are kept apart: +1 u per whole 11 u of size (+1 at 11, +2 at 22, +3 at 33, +6 at 66).
static func space_extra(size: int) -> int:
	return maxi(1, int(round(float(size) / 11.0)))


## The digit (and, at 11 u and multiples, the confusable-capital) bitmaps as a font for text at `size`: only those and the space, with the pixel font behind it for every other character. One per size (the space
## differs), built once from DIGITS_*. The space is this font's own because a FontVariation's extra spacing only reaches the space of the font it wraps: it is the
## pixel font's space at `size` plus space_extra when `spaced`, so a line is as wide as it was with the spacing on the pixel font itself.
static func digit_font(size := TEXT_S, spaced := true) -> FontFile:
	var cache_key := size * 2 + (1 if spaced else 0)
	if not _digits.has(cache_key):
		var medium := digits_medium(size)
		var rows_of: Dictionary = DIGITS_MEDIUM if medium else DIGITS_SMALL
		var native := DIGIT_MEDIUM_NATIVE if medium else DIGIT_SMALL_NATIVE
		var w: int = String(rows_of["0"][0]).length()
		var h: int = rows_of["0"].size()
		var f := FontFile.new()
		f.fixed_size = native
		f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		f.generate_mipmaps = false
		var tex_size := Vector2i(native, 0)
		# The glyphs this face draws itself: the ten digits, and in the small set the confusable capitals (LETTERS_SMALL).
		var glyphs := {}
		for d in 10:
			glyphs[48 + d] = rows_of[str(d)]
		if not medium:
			for letter in LETTERS_SMALL:
				glyphs[String(letter).unicode_at(0)] = LETTERS_SMALL[letter]
		var sheet := Image.create((w + 1) * glyphs.size(), h, false, Image.FORMAT_RGBA8)
		var slot := 0
		for ch in glyphs:
			var rows: Array = glyphs[ch]
			for y in h:
				for x in w:
					if String(rows[y])[x] == "#":
						sheet.set_pixel(slot * (w + 1) + x, y, Color.WHITE)
			slot += 1
		f.set_texture_image(0, tex_size, 0, sheet)
		# The pixel font's own metrics at that size: the digits stand on its baseline and the line is as tall as its line.
		var base := base_font()
		f.set_cache_ascent(0, native, base.get_ascent(native))
		f.set_cache_descent(0, native, base.get_descent(native))
		slot = 0
		for ch in glyphs:
			# Whole advance (6 at 11 u, 12 at 22, 18 at 33): a fractional one lands the glyph between device pixels and greys it. The pixel font's own capitals are 13 and 19 u
			# at 22 and 33 u, so a capital here is 1 u narrower per letter there (none at 11 u).
			f.set_glyph_advance(0, native, ch, Vector2(w + 1, 0))
			f.set_glyph_size(0, tex_size, ch, Vector2(w, h))
			f.set_glyph_offset(0, tex_size, ch, Vector2(0, -h))
			f.set_glyph_uv_rect(0, tex_size, ch, Rect2(slot * (w + 1), 0, w, h))
			f.set_glyph_texture_idx(0, tex_size, ch, 0)
			slot += 1
		var scale := maxi(1, int(round(float(size) / float(native))))
		var target := base.get_char_size(32, size).x
		if spaced:
			target += space_extra(size)
		f.set_glyph_size(0, tex_size, 32, Vector2.ZERO)
		f.set_glyph_uv_rect(0, tex_size, 32, Rect2())
		f.set_glyph_texture_idx(0, tex_size, 32, -1)
		f.set_glyph_advance(0, native, 32, Vector2(target / scale, 0))
		f.fallbacks = [base]
		# The text server rounds a scaled space on its own: measure four as drawn and take the difference off.
		var drawn := f.get_string_size("    ", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.25
		f.set_glyph_advance(0, native, 32, Vector2((target - (drawn - target)) / scale, 0))
		_digits[cache_key] = f
	return _digits[cache_key]


## Whether UI text gets its extra word spacing: on by default, everywhere. Callers read it; a test that needs the narrow spaces sets it false and restores it.
static var word_spacing := true


## The pixel font as the UI draws it at `size`: the digit bitmaps and a wider space (digit_font) in front of the file.
static func font_for(size := TEXT_S) -> FontVariation:
	var key := size * 2 + (1 if word_spacing else 0)
	if not _variations.has(key):
		var v := FontVariation.new()
		v.base_font = digit_font(size, word_spacing)
		_variations[key] = v
	return _variations[key]


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
