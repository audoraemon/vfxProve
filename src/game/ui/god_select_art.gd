class_name GodSelectArt
extends RefCounted
## Loads the God's Paths art (assets/pixellab/god_select/). Loading only: GodSelectScreen draws and animates it.

const DIR := "res://assets/pixellab/god_select/"
## True makes every lookup fail (a test of the screen without its art).
static var art_off := false
## Piece-name prefixes that fail to load (a test of partial art; empty normally).
static var blocked: Array[String] = []
static var _cache := {}
static var _sets := {}


## One piece by name (no extension), cached; null when the file is missing or fails to load.
static func texture(piece: String) -> Texture2D:
	if art_off or _is_blocked(piece):
		return null
	if _cache.has(piece):
		return _cache[piece]
	var path := DIR + piece + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[piece] = tex
	return tex


## The numbered frames `prefix_1`, `prefix_2`, ... up to the first one missing (cached; empty when the first is missing).
static func frame_set(prefix: String) -> Array[Texture2D]:
	if art_off or _is_blocked(prefix + "_"):
		return []
	if not _sets.has(prefix):
		var list: Array[Texture2D] = []
		var n := 1
		while true:
			var tex := texture("%s_%d" % [prefix, n])
			if tex == null:
				break
			list.append(tex)
			n += 1
		_sets[prefix] = list
	return _sets[prefix]


## True when the frame set `prefix` has been loaded (read-only; a test helper).
static func cached(prefix: String) -> bool:
	return _sets.has(prefix)


## Forgets the loaded frame sets (a test of the loading order).
static func clear_sets() -> void:
	_sets.clear()


static func _is_blocked(name: String) -> bool:
	for b in blocked:
		if name.begins_with(b):
			return true
	return false
