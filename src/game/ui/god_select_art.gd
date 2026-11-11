class_name GodSelectArt
extends RefCounted
## Loads the God's Paths art (assets/pixellab/god_select/). Loading only: GodSelectScreen draws and animates it.

const DIR := "res://assets/pixellab/god_select/"
## True makes every lookup fail (a test of the screen without its art).
static var art_off := false
static var _cache := {}
static var _frames := {}


## One piece by name (no extension), cached; null when the file is missing or fails to load.
static func texture(piece: String) -> Texture2D:
	if art_off:
		return null
	if _cache.has(piece):
		return _cache[piece]
	var path := DIR + piece + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[piece] = tex
	return tex


## The numbered frames `prefix1`, `prefix2`, ... up to the first one missing.
static func frames(prefix: String) -> Array[Texture2D]:
	if art_off:
		return []
	if not _frames.has(prefix):
		var list: Array[Texture2D] = []
		var n := 1
		while true:
			var tex := texture("%s%d" % [prefix, n])
			if tex == null:
				break
			list.append(tex)
			n += 1
		_frames[prefix] = list
	return _frames[prefix]
