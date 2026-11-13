class_name UiIcon
extends RefCounted
## Painted ability icons at native multiples (UI resolution spec §3): the 42 px HUD icon is drawn at 42*m device px, never
## fractionally scaled and never under 42; the 84 px icon serves even m. Locked icons are grey copies made once.
## `k` arguments default to 0, meaning the current UiScale.k(); tests pass them.

const SOURCE := 42
## The old locked look, for when a grey copy cannot be made (the headless dummy renderer returns no image).
const LOCKED_TINT := Color(0.5, 0.5, 0.55, 0.55)
const GREY_LUMA := 0.85
const ROUND_SEGMENTS := 32

static var _grey_cache := {}


static func _k(k: int) -> int:
	return k if k > 0 else UiScale.k()


## m = max(1, floor(want_units * k / 42)): how many device px per source px.
static func multiple(want_units: float, k := 0) -> int:
	return maxi(1, floori(want_units * _k(k) / float(SOURCE) + 1e-6))


## The square the icon occupies: 42*m/k units on a side, centred on `centre` and snapped to the device pixel grid.
static func native_rect(centre: Vector2, want_units: float, k := 0) -> Rect2:
	var kk := float(_k(k))
	var side := float(SOURCE * multiple(want_units, int(kk))) / kk
	var top_left := ((centre - Vector2(side, side) / 2.0) * kk).round() / kk
	return Rect2(top_left, Vector2(side, side))


## The source for `m`: the 84 px painted icon when m is even (drawn at m/2 device px per source px), else the 42 px HUD icon.
## Null when the power has no icon yet; the other size stands in when only one is painted.
static func texture_for(key: String, m: int) -> Texture2D:
	var big := PowerBook.icon(key)
	var small := PowerBook.hud_icon(key)
	if m % 2 == 0 and big != null:
		return big
	return small if small != null else big


## A desaturated copy of `img`: luma (Rec. 601) x 0.85 in r, g and b, alpha kept. Pure.
static func grey_image(img: Image) -> Image:
	var out := Image.new()
	out.copy_from(img)
	out.convert(Image.FORMAT_RGBA8)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			var l := (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * GREY_LUMA
			out.set_pixel(x, y, Color(l, l, l, c.a))
	return out


## The grey copy of `tex`, built once and cached by resource path. When the texture gives no image (headless) the texture itself
## comes back: ask `locked_tint()` for the colour to draw it with.
static func grey(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key := tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id())
	if _grey_cache.has(key):
		return _grey_cache[key]
	var img := tex.get_image()
	var out: Texture2D = tex
	if img != null and not img.is_empty():
		var made := ImageTexture.create_from_image(grey_image(img))
		made.set_meta("ui_grey", true)
		out = made
	_grey_cache[key] = out
	return out


## White for a real grey copy, the old translucent tint for a stand-in.
static func locked_tint(grey_tex: Texture2D) -> Color:
	return Color.WHITE if grey_tex != null and grey_tex.has_meta("ui_grey") else LOCKED_TINT


## The disc's outline: ROUND_SEGMENTS points on the circle inscribed in `rect`.
static func round_points(rect: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := rect.get_center()
	var r := rect.size / 2.0
	for i in ROUND_SEGMENTS:
		var a := TAU * i / ROUND_SEGMENTS
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


## The matching 0..1 texture coordinates.
static func round_uvs() -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for i in ROUND_SEGMENTS:
		var a := TAU * i / ROUND_SEGMENTS
		uvs.append(Vector2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5))
	return uvs


## `tex` clipped to a circle filling `rect`. Call from _draw; the item's texture_filter should be nearest.
static func draw_round(on: CanvasItem, tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	on.draw_colored_polygon(round_points(rect), tint, round_uvs(), tex)
