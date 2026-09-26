class_name ArtTuning
extends RefCounted
## Per-component size and colour adjustments, found by tools/dev/tune_components.py and kept in art_tuning.json:
## {"<key>": {"scale": 1.0, "tint": [r, g, b]}}. Keys are decor kinds in lower case ("barrel") and structures as
## Structure.tuning_key() names them ("house", "house_tavern", "keep_keep"). A missing key or field means no change,
## so an empty file draws everything as authored.
##
## The file is read with FileAccess: an exported build must include *.json in its export filter.

const PATH := "res://src/environment/art/art_tuning.json"

static var _data := {}
static var _loaded := false


## Read the file again (the tuning tool rewrites it between renders; a new process reads it fresh anyway).
static func reload() -> void:
	_loaded = true
	_data = {}
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		_data = parsed


static func _entry(key: String) -> Dictionary:
	if not _loaded:
		reload()
	var e: Variant = _data.get(key, {})
	return e if e is Dictionary else {}


## Size multiplier for a decor kind (structures take their size from their footprint).
static func scale(key: String) -> float:
	return float(_entry(key).get("scale", 1.0))


## Colour multiplier for the component's materials (glow and flames are left alone).
static func tint(key: String) -> Color:
	var t: Variant = _entry(key).get("tint", [1.0, 1.0, 1.0])
	if t is Array and t.size() >= 3:
		return Color(float(t[0]), float(t[1]), float(t[2]))
	return Color.WHITE


## For tests: use this data instead of the file.
static func set_data(data: Dictionary) -> void:
	_loaded = true
	_data = data
