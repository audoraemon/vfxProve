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
## A set with "banner_drop" also has these: its intact and damaged stills once the banners fell, and the banners.
const BANNER_STILLS := [&"intact_fallen", &"damaged_fallen", &"banners_intact", &"banners_damaged"]
## Pixels kept under the front corner, for steps, eaves and the rubble a collapse spills forward (it scatters up to a
## quarter cell past the footprint: 8 px down at the front corner).
const FOOT_ROOM := 10.0
## ArtKit.hash01 salt for a cottage's roof.
const SALT_ROOF := 90
## ArtKit.hash01 salt for a townhouse's look.
const SALT_TOWNHOUSE := 91
## A market stall's sprite by its awning (PropArt.CLOTH's index, the stall's art.cloth).
const STALLS := ["stall_red", "stall_blue", "stall_cream"]
## The longest piece a wall run is cut into (TownLayout.WALL_PIECE): a strip spans its period plus this.
const STRIP_PIECE := 1.2

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


## The sprite that replaces `s`, or "" (only buildings with a set in the manifest are drawn from one).
static func name_for(s: Structure) -> String:
	match s.kind:
		Structure.Kind.HOUSE:
			if s.role == &"farm":
				# A barn; the windmill and watermill keep their turning procedural art.
				return "barn" if s.art_tag == &"" else ""
			if s.role != &"house":
				return ""
			match s.art_tag:
				&"":
					return "cottage_red" if ArtKit.hash01(s.rng.seed, SALT_ROOF) < 0.5 else "cottage_blue"
				&"townhouse":
					return "townhouse_a" if ArtKit.hash01(s.rng.seed, SALT_TOWNHOUSE) < 0.5 else "townhouse_b"
				&"tavern":
					return "tavern"
				&"smithy":
					return "smithy"
				&"workshop":
					return "workshop"
				&"carpenter":
					return "carpenter"
		Structure.Kind.TEMPLE:
			if s.art_tag == &"cathedral":
				return "cathedral"
		Structure.Kind.KEEP:
			# The Citadel's keep and towers share their kind and role; only their size tells them apart. So do the town's
			# corner towers (2.0) and wall and gate towers (1.6).
			if s.role == &"citadel":
				return "citadel_keep" if s.footprint.size.x >= 1.8 else "citadel_tower"
			if s.role == &"tower":
				if s.art_tag == &"bell_tower":
					return "bell_tower"
				return "town_tower_corner" if s.footprint.size.x >= 1.8 else "town_tower"
		Structure.Kind.CASTLE_WALL:
			if s.role == &"citadel":
				if s.art_tag == &"gate":
					return "citadel_gate"
				var long := maxf(s.footprint.size.x, s.footprint.size.y)
				return "citadel_wall" if long >= 2.4 else "citadel_wall_side"
			if s.role == &"wall":
				return "town_wall"
		Structure.Kind.GATE:
			# The side gate is the main gate turned, so it draws the same sprite mirrored.
			if s.role == &"gate":
				return "town_postern" if s.art_tag == &"postern" else "town_gate"
		Structure.Kind.BARRACKS:
			return "barracks"
		Structure.Kind.MARKET_STALL:
			return STALLS[int(s.art.get("cloth", 0)) % STALLS.size()]
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
	# The Citadel keep's banner drop (Citadel.BANNER_AT): its stills without the banners, and the banners on their own
	# to slide down and fade (tools/dev/banner_mask.py). Missing files: the keep's banners never fall.
	if m.get("banner_drop", false):
		for extra: StringName in BANNER_STILLS:
			var p := DIR + n + "/" + String(extra) + ".png"
			if ResourceLoader.exists(p):
				stills[extra] = load(p)
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
		# Its chimney's top (sprite px) for ChimneySmoke; INF when it has none. own_smoke: its smoke is drawn in.
		"chimney": Vector2(m.chimney[0], m.chimney[1]) if m.has("chimney") else Vector2.INF,
		"own_smoke": bool(m.get("own_smoke", false)),
		# The building's own footprint (ground units) when the sprite covers less than its plot: its shadow's size.
		"shadow": Vector2(m.shadow[0], m.shadow[1]) if m.has("shadow") else Vector2.ZERO,
		# A strip set (the town wall): one long run of wall repeating every `period` ground units; each piece draws its
		# own stretch of it (strip_piece()), so `region` is set per structure in set_for(). Rect2() = the whole frame.
		"strip": bool(m.get("strip", false)), "period": float(m.get("period", 0.0)), "region": Rect2(),
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
	if out.strip:
		var piece := strip_piece(base, s.footprint, out.mirror)
		out.anchor = piece.anchor
		out.region = piece.region
	return out


## A wall piece's stretch of its strip set `base`. The strip is a run along ground x drawn on its canvas with its
## footprint's front corner at `anchor` (as every set); its front edge at run distance u sits at pixel
## anchor - (32, 16) * (footprint.x - u), and it repeats every `period` units. A piece covering [start, start + length)
## of its run reads u0 = start mod period onward: the strip's columns for its stretch, anchored at its own front corner.
## Pieces read their stretch from where they stand, so neighbours join, and a run wraps at the period without a jog
## (the strip spans a period plus the longest piece, STRIP_PIECE). A run along y is the strip mirrored (`mirrored`),
## measured along y. Nothing is rounded: rounding would shift a piece a pixel against its neighbour.
static func strip_piece(base: Dictionary, fp: Rect2, mirrored: bool) -> Dictionary:
	var start := fp.position.y if mirrored else fp.position.x
	var length := fp.size.y if mirrored else fp.size.x
	var u0 := fposmod(start, float(base.period))
	var span: float = (base.footprint as Vector2).x
	var run0: Vector2 = (base.anchor as Vector2) - Vector2(32.0, 16.0) * span
	var size: Vector2 = base.size
	var x0 := run0.x + 32.0 * u0
	return {"anchor": run0 + Vector2(32.0, 16.0) * (u0 + length), "region": Rect2(x0, 0.0, 32.0 * length, size.y)}
