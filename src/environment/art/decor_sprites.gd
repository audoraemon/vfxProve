class_name DecorSprites
extends RefCounted
## Decor sprites (decor batch 4, docs/superpowers/specs/2026-10-05-decor-batch4-design.md): which decor piece draws
## from which sprite set, read from assets/pixellab/decor/manifest.json. A set is one still, intact.png, anchored at
## the piece's ground point ("anchor", sprite px). A run kind's set ("segment", ground units) repeats along the run.
## Oaks and pines draw the batch 3 tree sets (SpriteArt). Shown while SpriteArt.on(): F7 switches decor too.

const DIR := "res://assets/pixellab/decor/"
const MANIFEST := DIR + "manifest.json"
## ArtKit.pick salts: a decor piece's variant, a decor tree's set.
const SALT_VARIANT := 97
const SALT_TREE := 98
## Kinds drawn as a run from `at` to `at + size`, one set per run direction ("<base>_x" / "<base>_y").
const RUNS := [Decor.Kind.FENCE, Decor.Kind.BUNTING, Decor.Kind.BENCH, Decor.Kind.GARDEN]
## Each kind's set base name; DOCK has none (the dock is a Structure since batch 3).
const BASE := {
	Decor.Kind.BARREL: "barrel", Decor.Kind.CRATES: "crates", Decor.Kind.BENCH: "bench", Decor.Kind.FENCE: "fence",
	Decor.Kind.GARDEN: "garden", Decor.Kind.BUSH: "bush", Decor.Kind.ROCK: "rock", Decor.Kind.LAMP: "lamp_house",
	Decor.Kind.BUNTING: "bunting", Decor.Kind.SCARECROW: "scarecrow", Decor.Kind.SIGNPOST: "signpost",
	Decor.Kind.REEDS: "reeds", Decor.Kind.FLOWERS: "flowers", Decor.Kind.TABLE: "table", Decor.Kind.SHIP: "ship",
	Decor.Kind.BOAT: "boat", Decor.Kind.SHEEP: "sheep", Decor.Kind.COW: "cow", Decor.Kind.CART: "cart",
	Decor.Kind.LOGS: "logs",
}
## The batch 3 tree sets a decor oak or pine picks from (SpriteArt names): leafy ones for oaks, pines for pines.
const OAK_SETS := ["oak_1", "oak_2", "oak_3", "tree_1", "tree_3", "tree_4"]
const PINE_SETS := ["tree_2", "tree_5"]

static var _manifest := {}
static var _loaded := false
static var _sets := {}
static var _variants_cache := {}


static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = {}
		if FileAccess.file_exists(MANIFEST):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if parsed is Dictionary:
				_manifest = parsed
	return _manifest


static func reload() -> void:
	_loaded = false
	_sets.clear()
	_variants_cache.clear()


## The set named `n`: {name, tex, size, anchor, segment}; {} when it is not in the manifest or its PNG is missing
## (warned once).
static func decor_set(n: String) -> Dictionary:
	if _sets.has(n):
		return _sets[n]
	var m: Dictionary = manifest().get(n, {})
	var path := DIR + n + "/intact.png"
	if m.is_empty() or not ResourceLoader.exists(path):
		if not m.is_empty():
			push_warning("DecorSprites: missing " + path)
		_sets[n] = {}
		return {}
	var tex: Texture2D = load(path)
	var size := Vector2(m.size[0], m.size[1]) if m.has("size") else Vector2(tex.get_size())
	var built := {
		"name": n, "tex": tex, "size": size,
		"anchor": Vector2(m.anchor[0], m.anchor[1]) if m.has("anchor") else Vector2(roundf(size.x * 0.5), size.y - 2.0),
		"segment": float(m.get("segment", 0.0)),
	}
	_sets[n] = built
	return built


## "<base>_<n>" variant numbers in the manifest, ascending (cached per load).
static func variants(base: String) -> Array:
	if _variants_cache.has(base):
		return _variants_cache[base]
	var out := []
	for key: String in manifest():
		if key.begins_with(base + "_"):
			var rest := key.trim_prefix(base + "_")
			if rest.is_valid_int() and int(rest) > 0:
				out.append(int(rest))
	out.sort()
	_variants_cache[base] = out
	return out


## The set a decor piece draws, or "" (procedural): off while SpriteArt is off; a run takes its direction's set; a
## kind with one set takes its bare name, else a variant picked from the seed.
static func name_for(kind: int, seed_value: int, size: Vector2) -> String:
	if not SpriteArt.on() or not BASE.has(kind):
		return ""
	var base: String = BASE[kind]
	if kind in RUNS:
		var n := base + ("_x" if absf(size.x) >= absf(size.y) else "_y")
		return n if manifest().has(n) else ""
	if manifest().has(base):
		return base
	var v := variants(base)
	if v.is_empty():
		return ""
	return "%s_%d" % [base, v[ArtKit.pick(seed_value, SALT_VARIANT, v.size())]]


## A decor oak's or pine's batch 3 tree set (SpriteArt.sprite()), picked from the seed over the sets that exist;
## {} while SpriteArt is off or none exist.
static func tree_set(kind: int, seed_value: int) -> Dictionary:
	if not SpriteArt.on():
		return {}
	var pool: Array = []
	for n: String in (PINE_SETS if kind == Decor.Kind.PINE else OAK_SETS):
		if not SpriteArt.sprite(n).is_empty():
			pool.append(n)
	if pool.is_empty():
		return {}
	return SpriteArt.sprite(pool[ArtKit.pick(seed_value, SALT_TREE, pool.size())])
