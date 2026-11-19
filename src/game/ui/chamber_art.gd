class_name ChamberArt
extends RefCounted
## God's Chamber art hook. A piece draws from res://assets/chamber/<name>.png when that file exists, otherwise as a flat greybox
## silhouette, so the room is playable before any art is painted and real art drops in by file name alone.

const DIR := "res://assets/chamber/"
const _DIM := 0.45

static var _cache := {}


static func greybox_color(name: String) -> Color:
	match name:
		"descend", "table": return Color(0.30, 0.37, 0.48)
		"tree": return Color(0.40, 0.25, 0.55)
		"faith": return Color(0.75, 0.52, 0.16)
		"awaken", "awaken_closed": return Color(0.42, 0.40, 0.38)
		"wall": return Color(0.06, 0.06, 0.08)
		"desk": return Color(0.20, 0.12, 0.07)
	return Color(0.25, 0.25, 0.25)


## The piece's texture, loaded once; null when the file is missing (remembered, so no per-frame load or log).
static func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var tex: Texture2D = null
	var path := DIR + name + ".png"
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[name] = tex
	return tex


## state: "", "hover", "dim" or "closed". The hover outline belongs to GodChamber, not here.
static func draw(canvas: CanvasItem, name: String, rect: Rect2, state := "") -> void:
	var piece := "awaken_closed" if state == "closed" and name == "awaken" else name
	var tex := texture(piece)
	var tint := Color.WHITE
	if state == "dim":
		tint = Color(_DIM, _DIM, _DIM, 1.0)
	if tex != null:
		canvas.draw_texture_rect(tex, rect, false, tint)
		return
	var col := greybox_color(name)
	if state == "closed":
		col = col.darkened(0.7)
	canvas.draw_rect(rect, col * tint)
	if name != "wall":
		var base_h := minf(rect.size.y * 0.15, 12.0)
		canvas.draw_rect(Rect2(rect.position.x, rect.end.y - base_h, rect.size.x, base_h), (col * tint).darkened(0.4))
