class_name SpriteArt
extends RefCounted
## Building sprites for the PixelLab structures proof (docs/superpowers/specs/2026-10-02-pixellab-structures-proof-
## design.md): which structures are drawn from a sprite instead of their procedural art, and the sprite sets, read from
## assets/pixellab/buildings/manifest.json. A set is three stills on one canvas -- intact, damaged, ruins -- with an
## optional idle strip and an optional generated collapse strip (damaged to ruins), all anchored at the footprint's
## front corner, where Structure.position sits.
##
## `-- --art=procedural` starts with the sprites off for old-vs-new captures; F7 (ArtToggle) flips them live.
##
## The manifest is read with FileAccess: an exported build must include *.json in its export filter.

const DIR := "res://assets/pixellab/buildings/"
const MANIFEST := DIR + "manifest.json"
const STILLS := [&"intact", &"damaged", &"ruins"]
## Pixels kept under the front corner, for steps, eaves and the rubble a collapse spills forward (it scatters up to a
## quarter cell past the footprint: 8 px down at the front corner).
const FOOT_ROOM := 10.0
## ArtKit.hash01 salt for a cottage's roof.
const SALT_ROOF := 90

static var _enabled := true
static var _args_read := false
static var _manifest := {}
static var _loaded := false
## Built sprite sets by name ({} for one whose stills are missing).
static var _sets := {}


static func on() -> bool:
	if not _args_read:
		_args_read = true
		if "--art=procedural" in OS.get_cmdline_user_args():
			_enabled = false
	return _enabled


static func set_enabled(value: bool) -> void:
	_args_read = true
	_enabled = value


## The manifest's entries by sprite name: size, footprint, height, seed, kind, role, tag; optionally anchor, frames, fps.
static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = {}
		if FileAccess.file_exists(MANIFEST):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if parsed is Dictionary:
				_manifest = parsed
	return _manifest


## Read the manifest and the stills again (the reference tool rewrites them).
static func reload() -> void:
	_loaded = false
	_sets.clear()


## The sprite that replaces `s`, or "" (only the proof's buildings have one).
static func name_for(s: Structure) -> String:
	match s.kind:
		Structure.Kind.HOUSE:
			if s.role != &"house":
				return ""
			match s.art_tag:
				&"":
					return "cottage_red" if ArtKit.hash01(s.rng.seed, SALT_ROOF) < 0.5 else "cottage_blue"
				&"tavern":
					return "tavern"
				&"smithy":
					return "smithy"
		Structure.Kind.TEMPLE:
			if s.art_tag == &"cathedral":
				return "cathedral"
		Structure.Kind.KEEP:
			# The Citadel's keep and towers share their kind and role; only their size tells them apart.
			if s.role == &"citadel":
				return "citadel_keep" if s.footprint.size.x >= 1.8 else "citadel_tower"
		Structure.Kind.CASTLE_WALL:
			if s.role == &"citadel":
				if s.art_tag == &"gate":
					return "citadel_gate"
				var long := maxf(s.footprint.size.x, s.footprint.size.y)
				return "citadel_wall" if long >= 2.4 else "citadel_wall_side"
	return ""


## The front corner's pixel in a sprite of `size` drawn for footprint `fp` (ground units): the footprint's diamond
## centred across the canvas, FOOT_ROOM pixels above its bottom.
static func default_anchor(size: Vector2, fp: Vector2) -> Vector2:
	return Vector2(roundf(size.x * 0.5 + 16.0 * (fp.x - fp.y)), size.y - FOOT_ROOM)


## The sprite set named `n` ({} when its stills are missing or it is not in the manifest). Shared: never edit it.
static func sprite(n: String) -> Dictionary:
	if _sets.has(n):
		return _sets[n]
	var m: Dictionary = manifest().get(n, {})
	if m.is_empty():
		return {}
	var stills := {}
	for st: StringName in STILLS:
		var path := DIR + n + "/" + String(st) + ".png"
		if not ResourceLoader.exists(path):
			push_warning("SpriteArt: missing " + path)
			_sets[n] = {}
			return {}
		stills[st] = load(path)
	var size := Vector2(m.size[0], m.size[1])
	var fp := Vector2(m.footprint[0], m.footprint[1])
	var idle_path := DIR + n + "/idle.png"
	var frames := int(m.get("frames", 1))
	var idle: Texture2D = load(idle_path) if frames > 1 and ResourceLoader.exists(idle_path) else null
	var collapse_path := DIR + n + "/collapse.png"
	var collapse_frames := int(m.get("collapse_frames", 0))
	var collapse: Texture2D = null
	if collapse_frames > 1 and ResourceLoader.exists(collapse_path):
		collapse = load(collapse_path)
	var built := {
		"name": n, "stills": stills, "size": size, "footprint": fp,
		"anchor": Vector2(m.anchor[0], m.anchor[1]) if m.has("anchor") else default_anchor(size, fp),
		"idle": idle, "frames": frames if idle != null else 1, "fps": float(m.get("fps", 8.0)), "mirror": false,
		"collapse": collapse, "collapse_frames": collapse_frames if collapse != null else 0,
	}
	_sets[n] = built
	return built


## Whether a fall plays a set's generated collapse (its collapse strip) or the engine's sink: `-- --collapse=engine`
## forces the engine's, to compare the two.
static func generated_collapse() -> bool:
	return not "--collapse=engine" in OS.get_cmdline_user_args()


## The sprite set drawn for `s`, or {} when sprites are off or it has none. A sprite drawn for a wide footprint stands
## mirrored on a deep one: mirroring an iso picture swaps its ground axes.
static func set_for(s: Structure) -> Dictionary:
	if not on():
		return {}
	var n := name_for(s)
	if n == "":
		return {}
	var base := sprite(n)
	if base.is_empty():
		return {}
	var out := base.duplicate()
	var fp: Vector2 = base.footprint
	out.mirror = not is_equal_approx(fp.x, fp.y) and (fp.x >= fp.y) != (s.footprint.size.x >= s.footprint.size.y)
	return out
