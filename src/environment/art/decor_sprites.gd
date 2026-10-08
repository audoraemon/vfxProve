class_name DecorSprites
extends RefCounted
## Decor sprites (decor batch 4, docs/superpowers/specs/2026-10-05-decor-batch4-design.md): which decor piece draws
## from which sprite set, read from assets/pixellab/decor/manifest.json. A set is one still, intact.png, anchored at
## the piece's ground point ("anchor", sprite px). A run kind's set ("segment", ground units) repeats along the run.
## Oaks and pines draw tree sets at the procedural tree's size (tree_set: forest_oak_<n> / forest_pine_<n>, and
## town_oak_<n> / town_pine_<n> for the town's smaller decor trees, each family one runtime atlas); without them they
## stay procedural. Shown while SpriteArt.on(): F7 switches decor too.

const DIR := "res://assets/pixellab/decor/"
const MANIFEST := DIR + "manifest.json"
## ArtKit.pick salts: a decor piece's variant, a decor tree's set.
const SALT_VARIANT := 97
const SALT_TREE := 98
## Kinds drawn as a run from `at` to `at + size`, one set per run direction ("<base>_x" / "<base>_y"). A GARDEN is
## not a run: its plots come in four fixed sizes, each a still (garden_<n>, picked by its manifest "footprint").
const RUNS := [Decor.Kind.FENCE, Decor.Kind.BUNTING, Decor.Kind.BENCH]
## Kinds drawn mirrored (facing the other way) for half the seeds: ArtKit.hash01(seed, SALT_VARIANT + 1) < 0.5. Their
## sets face right, lit from the left; a mirrored one is lit from the right (as the procedural animals, which do not
## shade by facing).
const MIRRORED := [Decor.Kind.SHEEP, Decor.Kind.COW]
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
## The tree families packed into one runtime atlas each (atlas name -> set bases): a forest band's oaks and pines then
## draw from one texture, one draw call, instead of one each time the set changes. Each family's stills stand side by
## side along x, bottom-aligned, so wind.gdshader's sway weight (1 - UV.y: the height in the texture) still grows from
## a tree's foot to its top.
const ATLASES := {"forest": ["forest_oak", "forest_pine"], "town": ["town_oak", "town_pine"]}
## The plant layer's sets (PlantLayer: the floor's meadow shrubs, the baked reeds, bushes and flowers) packed by
## height into runtime atlases, so a band of them is a few draw calls, not one per piece. Built and drawn by the layer
## only (paint_plant); decor_set() and live decor keep each set's own texture. wind.gdshader sways a quad by its height
## in the texture, so a still shorter than its atlas sways that much less at its top (a 7 px flowerbed in the 10 px
## low atlas: 0.7 of the plant material's sway): the families group the heights (7..10, 11..15, the 30 px reeds).
const PLANT_ATLASES := {"plant_low": ["shrub", "flowerbed", "flowers"], "plant_bush": ["bush"], "plant_reeds": ["reeds"]}
## Built atlases: name -> {"tex": ImageTexture, "rects": {set name -> Rect2}} (kept here: ArtKit holds only RIDs).
static var _atlases := {}


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
	_atlases.clear()


## The set named `n`: {name, tex, stump, size, anchor, segment, glow, end_post}, and for a tree set (ATLASES) "src", its
## still's rect in "tex", its family's atlas (else tex is its intact.png, drawn whole).
## - glow: the optional "glow" (sprite px from the anchor: where a lamp's light pool sits), else zero.
## - glass: the optional "glass" [x, y, w, h] (a lantern's glass, sprite px from its top left, as the lamp_post
##   building set's: Decor lights it, glass_rect()), else an empty Rect2.
## - end_post: the optional "end_post" [x, y, w, h] (a run's closing post: the sub-rect of the sprite drawn at the
##   run's far end), else an empty Rect2.
## - stump: the optional stump.png (Texture2D or null).
## - frames, fps: an animated set's intact.png is a horizontal strip of "frames" frames (default 1, a still), `size`
##   one frame (with no "size": the strip's width over its frames); paint() draws frame 0's rect and wind.gdshader
##   steps it at "fps" on the idle clock (Decor.material_for). Not for a tree set (an ATLASES family packs stills).
## {} when it is not in the manifest or its PNG is missing (warned once).
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
	var built := _build(n, m, load(path))
	var packed := _atlas_rect(n)
	if packed.has("tex"):
		built.tex = packed.tex
		built.src = packed.src
		# An atlas packs stills: a strip's frames would step into its neighbours.
		built.frames = 1
	_sets[n] = built
	return built


## Set `n` from its manifest entry `m` and its intact texture (decor_set() without the cache, the stump aside).
static func _build(n: String, m: Dictionary, tex: Texture2D) -> Dictionary:
	var frames := maxi(int(m.get("frames", 1)), 1)
	var size := Vector2(m.size[0], m.size[1]) if m.has("size") \
		else Vector2(floorf(float(tex.get_width()) / float(frames)), tex.get_height())
	var stump_path := DIR + n + "/stump.png"
	return {
		"name": n, "tex": tex, "stump": load(stump_path) if ResourceLoader.exists(stump_path) else null, "size": size,
		"frames": frames, "fps": float(m.get("fps", 0.0)),
		"anchor": Vector2(m.anchor[0], m.anchor[1]) if m.has("anchor") else Vector2(roundf(size.x * 0.5), size.y - 2.0),
		"segment": float(m.get("segment", 0.0)),
		"glow": Vector2(m.glow[0], m.glow[1]) if m.has("glow") else Vector2.ZERO,
		"glass": Rect2(m.glass[0], m.glass[1], m.glass[2], m.glass[3]) if m.has("glass") else Rect2(),
		"end_post": Rect2(m.end_post[0], m.end_post[1], m.end_post[2], m.end_post[3]) if m.has("end_post") else Rect2(),
	}


## The atlas a tree set is packed in, {"tex", "src"} (its still's rect there), built on first use; {} for a set in no
## ATLASES family.
static func _atlas_rect(n: String) -> Dictionary:
	for a: String in ATLASES:
		for base: String in ATLASES[a]:
			if n.begins_with(base + "_"):
				var at: Dictionary = _atlas(a)
				return {"tex": at.tex, "src": at.rects[n]} if at.rects.has(n) else {}
	return {}


## Build atlas `a`: every variant of its families' stills, left to right with a 1 px gap, bottom-aligned.
static func _atlas(a: String) -> Dictionary:
	if _atlases.has(a):
		return _atlases[a]
	var images := []
	for base: String in ATLASES.get(a, PLANT_ATLASES.get(a, [])):
		for v: int in variants(base):
			var n := "%s_%d" % [base, v]
			var path := DIR + n + "/intact.png"
			if ResourceLoader.exists(path):
				var im: Image = (load(path) as Texture2D).get_image()
				if im != null:
					im.convert(Image.FORMAT_RGBA8)
					images.append([n, im])
	var w := 0
	var h := 0
	for e: Array in images:
		w += (e[1] as Image).get_width() + 1
		h = maxi(h, (e[1] as Image).get_height())
	var out := {"tex": null, "rects": {}}
	if images.is_empty():
		_atlases[a] = out
		return out
	var atlas := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var x := 0
	for e: Array in images:
		var im: Image = e[1]
		var r := Rect2i(x, h - im.get_height(), im.get_width(), im.get_height())
		atlas.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), r.position)
		out.rects[e[0]] = Rect2(r)
		x += im.get_width() + 1
	out.tex = ImageTexture.create_from_image(atlas)
	_atlases[a] = out
	return out


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
## boat standing at `at` lies along the river holding it (boat_2 along y on the city's river_west, else boat_1 along
## x); a garden takes the garden_<n> whose "footprint" is nearest its plot; a kind with one set takes its bare name,
## else a variant picked from the seed (a boat too, when `at` is INF; a town sheep or cow by its decor order).
## `force` looks past F7 (the set the piece draws while sprites are on), for layout that must not hang on the art.
static func name_for(kind: int, seed_value: int, size: Vector2, at := Vector2.INF, force := false) -> String:
	if (not force and not SpriteArt.on()) or not BASE.has(kind):
		return ""
	var base: String = BASE[kind]
	if kind == Decor.Kind.BOAT and at != Vector2.INF:
		var b := "boat_2" if City.current().landmark(&"river_west").has_point(at) else "boat_1"
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
	# A town's animals take turns down the decor order (with flipped(): variant i % n, facing (i / n) % 2), so a
	# pasture's few cows, every third piece of its herd, never all come out alike; seed chance did that.
	var i := _order(seed_value) if kind in MIRRORED else -1
	if i >= 0:
		return "%s_%d" % [base, v[i % v.size()]]
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


## Whether a decor piece draws mirrored (a MIRRORED kind only). A town piece goes by its place in the decor order
## (_order, as name_for picks a variant), any other seed by hash01(seed, SALT_VARIANT + 1) < 0.5.
static func flipped(kind: int, seed_value: int) -> bool:
	if not kind in MIRRORED:
		return false
	var i := _order(seed_value)
	if i >= 0:
		return (i / maxi(variants(BASE[kind]).size(), 1)) % 2 == 1
	return ArtKit.hash01(seed_value, SALT_VARIANT + 1) < 0.5


## A town decor piece's place in TownDecor.spots() order, read back from its seed (TownDecor._add seeds piece i with
## SEED + i * 7919); -1 for a seed not made that way.
static func _order(seed_value: int) -> int:
	var d := seed_value - TownDecor.SEED
	return d / 7919 if d >= 0 and d % 7919 == 0 else -1


## Whether a decor piece draws an animated set (its set's "frames" > 1): while sprites are on (or `force`), such a piece
## is drawn live (a Decor node on the wind shader's frame stepping), never baked into the floor nor merged into a pile.
static func animated(kind: int, seed_value: int, size := Vector2.ZERO, at := Vector2.INF, force := false) -> bool:
	if kind == Decor.Kind.OAK or kind == Decor.Kind.PINE or kind == Decor.Kind.PILE:
		return false
	var n := name_for(kind, seed_value, size, at, force)
	return n != "" and int(decor_set(n).get("frames", 1)) > 1


## Where a decor piece's light pool sits (Decor._glow; relative to its ground point, unscaled screen px): its set's
## "glow" while it draws from a set, else its ground point (as the procedural lamp's).
static func glow_offset(kind: int, seed_value: int, size: Vector2) -> Vector2:
	var n := name_for(kind, seed_value, size)
	if n == "":
		return Vector2.ZERO
	return decor_set(n).get("glow", Vector2.ZERO)


## Set `d`'s lantern glass (its "glass") where a piece drawing it shows it: relative to the piece's ground point,
## unscaled px, as paint() places the sprite (its top left at -anchor), mirrored with a mirrored piece (`flip`). An
## empty Rect2 for a set with no glass.
static func glass_rect(d: Dictionary, flip: bool) -> Rect2:
	var g: Rect2 = d.get("glass", Rect2())
	if not g.has_area():
		return Rect2()
	var anchor: Vector2 = d.anchor
	if flip:
		return Rect2(Vector2(anchor.x - g.end.x, g.position.y - anchor.y), g.size)
	return Rect2(g.position - anchor, g.size)


## A decor oak's or pine's set, a variant picked from the seed: a forest_oak / forest_pine (the forest's trees, and any
## with no height: PropArt.tree tall 46..64), or with a height `tall` (a town decor tree's size.x, 24..32: half the
## forest's) a town_oak / town_pine. {} while SpriteArt is off or the manifest has none of that family (the tree stays
## procedural, never drawn from the other family at twice or half its size).
static func tree_set(kind: int, seed_value: int, tall := 0.0, force := false) -> Dictionary:
	if not force and not SpriteArt.on():
		return {}
	var base := ("town_" if tall > 0.0 else "forest_") + ("pine" if kind == Decor.Kind.PINE else "oak")
	var v := variants(base)
	if v.is_empty():
		return {}
	return decor_set("%s_%d" % [base, v[ArtKit.pick(seed_value, SALT_TREE, v.size())]])


## Draw a "<base>_<n>" set that belongs to no decor kind (the floor's baked meadow shrubs: "shrub", "flowerbed"), its
## variant picked from the seed, anchored at `at` on whole pixels, and return true; false (draw nothing) while SpriteArt
## is off or the manifest has no such set, so the caller keeps its procedural art.
static func paint_named(base: String, at: Vector2, seed_value: int, origin: Vector2) -> bool:
	var d := named_set(base, seed_value)
	if d.is_empty():
		return false
	ArtKit.tex(d.tex, Rect2(Vector2.ZERO, d.size), (Iso.ground_to_screen(at) - origin - d.anchor).round())
	return true


## The "<base>_<n>" set paint_named() draws for `seed_value`; {} while SpriteArt is off (unless `force`) or the
## manifest has none.
static func named_set(base: String, seed_value: int, force := false) -> Dictionary:
	if not force and not SpriteArt.on():
		return {}
	var v := variants(base)
	if v.is_empty():
		return {}
	return decor_set("%s_%d" % [base, v[ArtKit.pick(seed_value, SALT_VARIANT, v.size())]])


## The set a plant-layer piece draws (TownFloor.plant_in_layer): a floor shrub spot {base, at, seed} its named set, a
## REEDS / BUSH / FLOWERS piece {kind, at, size, seed} its decor set; {} for any other piece, while SpriteArt is off,
## or with no set (the floor bake keeps it). `force`: the set it draws while sprites are on, whatever F7 says.
static func plant_set(d: Dictionary, force := false) -> Dictionary:
	if d.has("base"):
		return named_set(d.base, d.seed, force)
	if not d.get("kind", -1) in Decor.PLANTS:
		return {}
	var n := name_for(d.kind, d.seed, d.size, d.at, force)
	return {} if n == "" else decor_set(n)


## The PLANT_ATLASES atlas set `n` packs into, or "" for none.
static func plant_atlas(n: String) -> String:
	for a: String in PLANT_ATLASES:
		for base: String in PLANT_ATLASES[a]:
			if n.begins_with(base + "_"):
				return a
	return ""


## Draw plant-layer piece `d` (screen px, origin zero) from its set `s` (plant_set), taking the set's rect in its
## PLANT_ATLASES atlas: anchored at its ground point on whole pixels, as paint() and paint_named() place it.
static func paint_plant(d: Dictionary, s: Dictionary) -> void:
	var tex: Texture2D = s.tex
	var src := Rect2(Vector2.ZERO, s.size)
	var a := plant_atlas(s.name)
	if a != "":
		var at: Dictionary = _atlas(a)
		if at.rects.has(s.name):
			tex = at.tex
			src = at.rects[s.name]
	ArtKit.tex(tex, src, (Iso.ground_to_screen(d.at) - s.anchor).round())


## Draw a decor piece from its sprite (ArtKit.tex) and return true; false leaves it to DecorArt's polygons. A down
## tree shows its set's stump texture, or is left to the procedural stump; any other down piece with a set draws
## nothing. A run repeats its set's segment from its back end (the low end along its main axis), the last tile cut
## to the run's length (on its near side: the left of an x set, the right of a y set); a set with an "end_post"
## closes the run with that post at its far end. A MIRRORED kind faces either way by seed (its anchor mirrored with it).
static func paint(kind: int, at: Vector2, size: Vector2, seed_value: int, origin: Vector2, down := false) -> bool:
	if kind == Decor.Kind.OAK or kind == Decor.Kind.PINE:
		var tr := tree_set(kind, seed_value, size.x)
		if tr.is_empty():
			return false
		var still: Texture2D = tr.stump if down else tr.tex
		if still == null:
			return false
		# On whole pixels: the forest's trees are baked pieces (origin zero) at fractional ground points.
		var src: Rect2 = Rect2(Vector2.ZERO, still.get_size()) if down else tr.get("src", Rect2(Vector2.ZERO, tr.size))
		ArtKit.tex(still, src,
			(Iso.ground_to_screen(at) - origin - tr.anchor).round())
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
	var flip := flipped(kind, seed_value)
	var anchor: Vector2 = Vector2(d.size.x - d.anchor.x, d.anchor.y) if flip else d.anchor
	# On whole pixels, as the procedural shrubs (TownFloor._shrubs rounds its point): a baked piece (origin zero) has a
	# fractional ground point; a live one (origin its own ground point) is already whole.
	ArtKit.tex(d.tex, Rect2(Vector2.ZERO, d.size), (Iso.ground_to_screen(at) - origin - anchor).round(), Color.WHITE, flip)
	return true
