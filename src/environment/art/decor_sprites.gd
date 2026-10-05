class_name DecorSprites
extends RefCounted
## Decor sprites (decor batch 4, docs/superpowers/specs/2026-10-05-decor-batch4-design.md): which decor piece draws
## from which sprite set, read from assets/pixellab/decor/manifest.json. A set is one still, intact.png, anchored at
## the piece's ground point ("anchor", sprite px). A run kind's set ("segment", ground units) repeats along the run.
## Oaks and pines draw forest-scale decor sets (forest_oak_<n>, forest_pine_<n>); until those exist they stay
## procedural. Shown while SpriteArt.on(): F7 switches decor too.

const DIR := "res://assets/pixellab/decor/"
const MANIFEST := DIR + "manifest.json"
## ArtKit.pick salts: a decor piece's variant, a decor tree's set.
const SALT_VARIANT := 97
const SALT_TREE := 98
## Kinds drawn as a run from `at` to `at + size`, one set per run direction ("<base>_x" / "<base>_y"). A GARDEN is
## not a run: its plots come in four fixed sizes, each a still (garden_<n>, picked by its manifest "footprint").
const RUNS := [Decor.Kind.FENCE, Decor.Kind.BUNTING, Decor.Kind.BENCH]
## Each kind's set base name; DOCK has none (the dock is a Structure since batch 3).
const BASE := {
	Decor.Kind.BARREL: "barrel", Decor.Kind.CRATES: "crates", Decor.Kind.BENCH: "bench", Decor.Kind.FENCE: "fence",
	Decor.Kind.GARDEN: "garden", Decor.Kind.BUSH: "bush", Decor.Kind.ROCK: "rock", Decor.Kind.LAMP: "lamp_house",
	Decor.Kind.BUNTING: "bunting", Decor.Kind.SCARECROW: "scarecrow", Decor.Kind.SIGNPOST: "signpost",
	Decor.Kind.REEDS: "reeds", Decor.Kind.FLOWERS: "flowers", Decor.Kind.TABLE: "table", Decor.Kind.SHIP: "ship",
	Decor.Kind.BOAT: "boat", Decor.Kind.SHEEP: "sheep", Decor.Kind.COW: "cow", Decor.Kind.CART: "cart",
	Decor.Kind.LOGS: "logs",
}
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


## The set named `n`: {name, tex, stump, size, anchor, segment, glow, end_post, footprint}; glow is the optional "glow"
## (sprite px from the anchor: where a lamp's light pool sits), else zero; end_post the optional "end_post" [x, y, w, h]
## (a run's closing post: the sub-rect of the sprite drawn at the run's far end), else an empty Rect2; footprint the
## optional "footprint" [w, d] (ground units: a garden still's plot), else zero; stump is the optional stump.png (Texture2D or null); {} when it is not in the manifest or its PNG is missing
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
	var stump_path := DIR + n + "/stump.png"
	var built := {
		"name": n, "tex": tex, "stump": load(stump_path) if ResourceLoader.exists(stump_path) else null, "size": size,
		"anchor": Vector2(m.anchor[0], m.anchor[1]) if m.has("anchor") else Vector2(roundf(size.x * 0.5), size.y - 2.0),
		"segment": float(m.get("segment", 0.0)),
		"glow": Vector2(m.glow[0], m.glow[1]) if m.has("glow") else Vector2.ZERO,
		"end_post": Rect2(m.end_post[0], m.end_post[1], m.end_post[2], m.end_post[3]) if m.has("end_post") else Rect2(),
		"footprint": Vector2(m.footprint[0], m.footprint[1]) if m.has("footprint") else Vector2.ZERO,
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
## boat standing at `at` lies along the river holding it (boat_2 along y on TownLayout.RIVER_WEST, else boat_1 along
## x); a garden takes the garden_<n> whose "footprint" is nearest its plot; a kind with one set takes its bare name,
## else a variant picked from the seed (a boat too, when `at` is INF).
static func name_for(kind: int, seed_value: int, size: Vector2, at := Vector2.INF) -> String:
	if not SpriteArt.on() or not BASE.has(kind):
		return ""
	var base: String = BASE[kind]
	if kind == Decor.Kind.BOAT and at != Vector2.INF:
		var b := "boat_2" if TownLayout.RIVER_WEST.has_point(at) else "boat_1"
		return b if manifest().has(b) else ""
	if kind in RUNS:
		var n := base + ("_x" if absf(size.x) >= absf(size.y) else "_y")
		return n if manifest().has(n) else ""
	if kind == Decor.Kind.GARDEN:
		return _nearest_plot(base, size)
	if manifest().has(base):
		return base
	var v := variants(base)
	if v.is_empty():
		return ""
	return "%s_%d" % [base, v[ArtKit.pick(seed_value, SALT_VARIANT, v.size())]]


## The "<base>_<n>" set whose manifest "footprint" is nearest `size` (summed side differences; ties to the lower n),
## or "" when none has one.
static func _nearest_plot(base: String, size: Vector2) -> String:
	var best := ""
	var best_d := INF
	for v: int in variants(base):
		var n := "%s_%d" % [base, v]
		var f: Variant = manifest()[n].get("footprint", null)
		if f == null:
			continue
		var d := absf(float(f[0]) - size.x) + absf(float(f[1]) - size.y)
		if d < best_d:
			best_d = d
			best = n
	return best


## Where a decor piece's light pool sits (Decor._glow; relative to its ground point, unscaled screen px): its set's
## "glow" while it draws from a set, else its ground point (as the procedural lamp's).
static func glow_offset(kind: int, seed_value: int, size: Vector2) -> Vector2:
	var n := name_for(kind, seed_value, size)
	if n == "":
		return Vector2.ZERO
	return decor_set(n).get("glow", Vector2.ZERO)


## A decor oak's or pine's forest set: a variant of forest_oak / forest_pine picked from the seed; {} while
## SpriteArt is off or the manifest has none (the tree stays procedural).
static func tree_set(kind: int, seed_value: int) -> Dictionary:
	if not SpriteArt.on():
		return {}
	var base := "forest_pine" if kind == Decor.Kind.PINE else "forest_oak"
	var v := variants(base)
	if v.is_empty():
		return {}
	return decor_set("%s_%d" % [base, v[ArtKit.pick(seed_value, SALT_TREE, v.size())]])


## Draw a decor piece from its sprite (ArtKit.tex) and return true; false leaves it to DecorArt's polygons. A down
## tree shows its set's stump texture, or is left to the procedural stump; any other down piece with a set draws nothing. A run repeats its set's
## segment from its back end (the low end along its main axis), the last tile cut to the run's length (on its near
## side: the left of an x set, the right of a y set); a set with an "end_post" closes the run with that post at its
## far end.
static func paint(kind: int, at: Vector2, size: Vector2, seed_value: int, origin: Vector2, down := false) -> bool:
	if kind == Decor.Kind.OAK or kind == Decor.Kind.PINE:
		var tr := tree_set(kind, seed_value)
		if tr.is_empty():
			return false
		var still: Texture2D = tr.stump if down else tr.tex
		if still == null:
			return false
		ArtKit.tex(still, Rect2(Vector2.ZERO, still.get_size() if down else tr.size), Iso.ground_to_screen(at) - origin - tr.anchor)
		return true
	var n := name_for(kind, seed_value, size, at)
	if n == "":
		return false
	var d := decor_set(n)
	if d.is_empty():
		return false
	if down:
		return true
	if kind in RUNS and d.segment > 0.0:
		var length := size.length()
		if length <= 0.0:
			return true
		var dir := size / length
		var start := at
		# The back end is the low end along the run's main axis (the axis that picked its set), so a slanted run's
		# tiles step the way its sprite runs.
		if (dir.x < 0.0) if absf(dir.x) >= absf(dir.y) else (dir.y < 0.0):
			start = at + size
			dir = -dir
		var count := ceili(length / d.segment - 0.001)
		# A set anchored on its right half runs leftward on screen (a "_y" set): its last tile keeps its right
		# (near) columns, drawn where they sit in a whole tile; else it keeps its left ones.
		var leftward: bool = d.anchor.x > d.size.x * 0.5
		for i in count:
			var w: float = d.size.x
			if i == count - 1:
				w = maxf(1.0, roundf(d.size.x * (length - d.segment * float(count - 1)) / d.segment))
			var cut: float = d.size.x - w if leftward else 0.0
			var g: Vector2 = start + dir * d.segment * float(i)
			ArtKit.tex(d.tex, Rect2(cut, 0, w, d.size.y), Iso.ground_to_screen(g) - origin - d.anchor + Vector2(cut, 0))
		var post: Rect2 = d.get("end_post", Rect2())
		if post.has_area():
			ArtKit.tex(d.tex, post, Iso.ground_to_screen(start + dir * length) - origin - d.anchor + post.position)
		return true
	ArtKit.tex(d.tex, Rect2(Vector2.ZERO, d.size), Iso.ground_to_screen(at) - origin - d.anchor)
	return true
