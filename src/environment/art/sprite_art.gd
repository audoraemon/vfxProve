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
## ArtKit.hash01 salts for a market stall's design, a tree's and an oak's variant (batch 3 sets).
const SALT_STALL := 92
const SALT_TREE := 93
const SALT_OAK := 94
## ArtKit.hash01 salt for the design of a field off the town's plots (SpriteView.SALT_PHASE is 95).
const SALT_FIELD := 96
## A town market stall's design walk over the city's stalls() (_stall_design): the first of these steps prime to the
## number of designs, and where the walk starts.
const STALL_STEPS := [5, 7, 11, 13]
const STALL_OFFSET := 3
## The longest piece a wall run is cut into (TownLayout.WALL_PIECE): a strip spans its period plus this.
const STRIP_PIECE := 1.2

static var _enabled := true
static var _args_read := false
static var _manifest := {}
static var _loaded := false
## Built sprite sets by name ({} for one whose stills are missing).
static var _sets := {}
## Variant numbers found in the manifest per prefix ("stall" -> [1, 2, ...], ascending), built on first use.
static var _variants_cache := {}


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
	_variants_cache.clear()


## The design numbers n of manifest entries "<prefix>_<n>" (digits only, so "stall_1_red" is not a design), ascending.
## Cached per manifest load.
static func variants(prefix: String) -> Array:
	if _variants_cache.has(prefix):
		return _variants_cache[prefix]
	var out := []
	var lead := prefix + "_"
	for key: String in manifest():
		if key.begins_with(lead):
			var rest := key.trim_prefix(lead)
			if rest.is_valid_int() and int(rest) > 0:
				out.append(int(rest))
	out.sort()
	_variants_cache[prefix] = out
	return out


## "<prefix>_<n>" with n picked from the seed over the designs in the manifest, or "" when there are none.
static func _pick_variant(prefix: String, seed_value: int, salt: int) -> String:
	var v := variants(prefix)
	if v.is_empty():
		return ""
	return "%s_%d" % [prefix, v[ArtKit.pick(seed_value, salt, v.size())]]


## `n` when the manifest has it, else "" (the structure stays procedural).
static func _have(n: String) -> String:
	return n if manifest().has(n) else ""


## A stall's sprite: its design, in the awning tint of its cloth when that tint exists.
static func _stall_name(s: Structure) -> String:
	var design := _stall_design(s)
	if design == "":
		return ""
	var tinted: String = design + "_" + ["red", "blue", "cream"][int(s.art.get("cloth", 0)) % 3]
	return tinted if manifest().has(tinted) else design


## A stall's design. A town market stall (its plot one of the city's stalls(), index i) takes design
## STALL_STEP * i + STALL_OFFSET (mod the number of designs present): plots next to each other in the market are 1, 2
## or 3 apart in that list (along a row, or down a column where a row is short), so with four or more designs and a
## step prime to their count no two neighbours share one. It reads the layout only, so gameplay is untouched. Any
## other stall picks its design from its seed.
static func _stall_design(s: Structure) -> String:
	var v := variants("stall")
	if v.is_empty():
		return ""
	var i: int = City.current().stalls().find(s.footprint)
	if i < 0:
		return _pick_variant("stall", s.rng.seed, SALT_STALL)
	var step := 1
	for c in STALL_STEPS:
		if v.size() % c != 0:
			step = c
			break
	return "stall_%d" % v[(i * step + STALL_OFFSET) % v.size()]


## A field's sprite: its crop's set "field_<crop>" (none: procedural) or one of that crop's other designs
## "field_<crop>_<n>" (rows the other way). A town field (its plot one of the city's fields(), index i) takes design
## i mod (designs): side-by-side plots are next to each other in that list, so two neighbouring fields of one crop never
## look stamped. It reads the layout only, so gameplay is untouched. Any other field picks its design from its seed.
static func _field_name(s: Structure) -> String:
	var base := "field_%d" % int(s.art.get("crop", 0))
	if not manifest().has(base):
		return ""
	var v := variants(base)
	var n := v.size() + 1
	var i: int = City.current().fields().find(s.footprint)
	var k := i % n if i >= 0 else ArtKit.pick(s.rng.seed, SALT_FIELD, n)
	return base if k == 0 else "%s_%d" % [base, v[k - 1]]


## The sprite that replaces `s`, or "" (only buildings with a set in the manifest are drawn from one).
static func name_for(s: Structure) -> String:
	# The GPT buildings proof (GptProof): a showcase structure (GptShowcase, dev only) or a proof plot draws its
	# ChatGPT building's set instead, while sprites are on.
	if on():
		var proof := GptProof.set_for(s)
		if proof != "" and manifest().has(proof):
			return proof
	# A ChatGPT building on one of a city's plots (the capital's, CapitalPlots: role "gpt") draws the set it is tagged
	# with. Aldermere has none.
	if s.role == CapitalPlots.ROLE:
		return _have(String(s.art_tag)) if String(s.art_tag).begins_with("gpt_") else ""
	match s.kind:
		Structure.Kind.HOUSE:
			if s.role == &"farm":
				match s.art_tag:
					&"":
						return _have("barn")
					&"windmill":
						return _have("windmill")
					&"watermill":
						return _have("watermill")
				return ""
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
					return _have("carpenter")
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
				var tower := "town_tower_corner" if s.footprint.size.x >= 1.8 else "town_tower"
				# A walkway door (TownLayout.door_tag): "door_e_s" -> town_tower_e_s; a variant missing from the
				# manifest falls back to the plain tower, so a tower is never left blank.
				var tag := String(s.art_tag)
				if tag.begins_with("door_"):
					var doored := tower + "_" + tag.trim_prefix("door_")
					if manifest().has(doored):
						return doored
				return tower
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
			return _stall_name(s)
		Structure.Kind.FOUNTAIN:
			return _have("well" if s.art_tag == &"well" else "fountain")
		Structure.Kind.TORCH:
			return _have("lamp_post" if s.art_tag == &"lamp" else "torch_post")
		Structure.Kind.TREE:
			if s.art_tag == &"oak":
				return _pick_variant("oak", s.rng.seed, SALT_OAK)
			if s.art_tag == &"":
				return _pick_variant("tree", s.rng.seed, SALT_TREE)
		Structure.Kind.BRIDGE:
			# A bridge tagged with a ChatGPT set draws that set (none is since polish 1: the capital's third crossing
			# is the stone bridge, not gpt_footbridge spans).
			if String(s.art_tag).begins_with("gpt_"):
				return _have(String(s.art_tag))
			if s.art_tag == &"stone":
				return _have("bridge_stone")
			if s.art_tag == &"dock":
				return _have("dock")
		Structure.Kind.FARM_FIELD:
			return _field_name(s)
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
	# Its lit windows (art animation round, Group B): one frame's size, red > 0.5 on the pixels that flicker. None: no
	# flicker.
	var mask_path := DIR + n + "/glow_mask.png"
	var glow_mask: Texture2D = load(mask_path) if ResourceLoader.exists(mask_path) else null
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
	# A strip without a positive period would read its stretch at fposmod(start, 0) = NaN and vanish: draw it whole.
	var strip := bool(m.get("strip", false))
	var period := float(m.get("period", 0.0))
	if strip and period <= 0.0:
		push_warning("SpriteArt: strip set %s has no positive period; drawn whole" % n)
		strip = false
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
		"strip": strip, "period": period, "region": Rect2(),
		# Its procedural flames (a wall torch, the barracks' forge) stay lit over it: the sprite paints none of its own.
		"keep_flames": bool(m.get("keep_flames", false)),
		# Its window mask (structure_sprite.gdshader's glow_mask), or null.
		"glow_mask": glow_mask,
		# A street torch's bowl rim (the procedural flame's base) or a street lamp's lantern glass (the procedural glow),
		# in sprite px; damaged_shift: where they move to on the damaged still (its post leans). INF / Rect2(): none.
		"flame": Vector2(m.flame[0], m.flame[1]) if m.has("flame") else Vector2.INF,
		"glass": Rect2(m.glass[0], m.glass[1], m.glass[2], m.glass[3]) if m.has("glass") else Rect2(),
		"damaged_shift": Vector2(m.damaged_shift[0], m.damaged_shift[1]) if m.has("damaged_shift") else Vector2.ZERO,
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
