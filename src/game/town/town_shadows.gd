class_name TownShadows
extends Node2D
## The cast shadows of the DAY and NIGHT looks (Town.Look). Round 5: every standing structure with a sprite casts a
## shadow mask baked from the still it shows (bake_mask(): each opaque texel h px above its footprint's front edge
## stamps the ground point that edge point + SUN * h, and the footprint's diamond is filled), so the shadow starts at
## the building's base edges and follows its towers, crenels, roofs and spire, falling down and to the right at a
## moderate length. Each mask is one textured quad placed by the sprite's anchor. A tree (a TREE structure or a forest
## tree) casts a short ellipse at its foot, a lamp or a tiny prop a small foot blob. A structure without a sprite casts
## the old hull: its footprint's diamond, its copy shifted by height * SHEAR, and the hull between. Everything is in
## screen pixels under the ground plane's transform, so it scales and pans with the art. All of it is drawn white in
## one CanvasGroup and given its darkness once by the group's self_modulate, so overlaps never stack.
## The layer sits over the floor, the plants and the forest, and under everything that stands. It is rebuilt only when a
## structure is destroyed, restored, added or removed (deferred, once per frame at most), never per frame.

## Screen pixels of shadow per unit of height for a hull (a structure without a sprite): down and to the right, away
## from the sun at the upper left.
const SHEAR := Vector2(1.0, 0.46)
## A baked mask's sun: a texel h px above its base lands h * SUN from the base point (down and right, moderate).
const SUN := Vector2(0.5, 0.24)
## Transparent margin round a baked mask, px.
const MASK_PAD := 2
## A tree's ellipse: half-width as a share of its crown's width, flattened to ELLIPSE_FLAT high, its centre moved this
## share of the half-axes down and right of the foot.
const TREE_RX := 0.5
const ELLIPSE_FLAT := 0.42
const TREE_SHIFT := 0.6
## A lamp's or tiny prop's foot blob: half-width px.
const BLOB_RX := 5.0
## A footprint smaller than this (ground units squared) is a tiny prop: a foot blob, no mask.
const TINY_AREA := 0.1
## A destroyed structure without a sprite casts the shadow of its ruin: this much of its height.
const RUIN_FACTOR := 0.15
## The contact band reaches this far out from a footprint (ground units: about 2 to 4 px on screen), a tree's blob this
## much of its height across.
const CONTACT_GROW := 0.2
const CONTACT_TREE := 0.16

var env: EnvironmentField
var look := 0
## The forest's baked trees (Town.build's), each a silhouette in the same group.
var trees: Array[Dictionary] = []
## The one group every shadow is drawn in.
var group: CanvasGroup
## Structure instance id -> its shadow polygon (screen px): its hull, its mask's quad, or its ellipse or blob.
var _polys := {}
## One Polygon2D holds the hull shadow of every structure without a sprite and the ellipse or blob of every tree, lamp
## and tiny prop, one convex polygon each, rebuilt on change.
var _struct_poly: Polygon2D
## The masks: one node drawing, per mask texture, one triangle array of quads, through one shared material. Texture
## RID -> {tex, pts, uvs}. The forest's trees cast ellipses on a Polygon2D in a group of their own (tree_group: their
## colour, TownLook.tree_shadow_colour()).
var silhouettes: SilhouetteCanvas
var tree_group: CanvasGroup
var tree_poly: Polygon2D
var _sil := {}
## How many mask quads are drawn, and how many forest trees cast an ellipse (for tests).
var silhouette_count := 0
var tree_count := 0
## Structure instance id -> the still its mask is baked from.
var _tex_of := {}
## Structure instance id -> its mask's texture.
var _mask_of := {}
## The contact shadows: a dithered band round every structure's base and a blob under every tree, in a group of their
## own (darker than the cast shadows; TownLook.contact_colour()).
var contact: CanvasGroup
var _contact_poly: Polygon2D
var _pending := false
## How many times rebuild() has run (for tests).
var rebuilds := 0

static var _sil_material: ShaderMaterial
## Baked masks, shared by every town: key (still, mirror, set) -> {tex: ImageTexture, size: Vector2i}.
static var _masks := {}


## The masks' draw node: one triangle array per texture of its quads (TownShadows.paint_silhouettes()).
class SilhouetteCanvas extends Node2D:
	var quads := {}

	func _draw() -> void:
		TownShadows.paint_silhouettes(self, quads)


func _new_canvas(n: String, quads: Dictionary) -> SilhouetteCanvas:
	var c := SilhouetteCanvas.new()
	c.name = n
	c.quads = quads
	c.material = silhouette_material()
	c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return c


## The one material every mask draws through: white where the texel is opaque.
static func silhouette_material() -> ShaderMaterial:
	if _sil_material == null:
		_sil_material = ShaderMaterial.new()
		_sil_material.shader = preload("res://src/game/town/town_silhouette.gdshader")
	return _sil_material


## The shadow mask of a sprite still (cached for every town): `art` its sprite set (anchor: its footprint's front
## corner; footprint; shadow: the building's own smaller footprint centred on the plot, or zero; strip: a strip set,
## whose run's front edge extends across the whole canvas). A mirrored sprite is baked from its flipped image with its
## sides swapped, so its shadow still falls down and to the right. Returns {tex, size, anchor}: the mask's texel
## (MASK_PAD, MASK_PAD) is the (flipped) still's texel (0, 0); `anchor` the set's anchor in that (flipped) frame.
static func mask_for(still: Texture2D, art: Dictionary) -> Dictionary:
	var mirror := bool(art.get("mirror", false))
	var strip := bool(art.get("strip", false))
	var key := "%d|%s|%s" % [still.get_instance_id(), mirror, art.get("name", "")]
	if _masks.has(key):
		return _masks[key]
	var img := still.get_image()
	if img == null:
		return {}
	if img.is_compressed():
		img.decompress()
	img = img.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var fp: Vector2 = art.footprint
	var own: Vector2 = art.get("shadow", Vector2.ZERO)
	var anchor: Vector2 = art.anchor
	if strip and art.has("name"):
		# strip_piece() moves each piece's anchor along the run; bake from the set's own (the run's end).
		anchor = SpriteArt.sprite(String(art.name)).get("anchor", anchor)
	if mirror:
		img.flip_x()
		anchor.x = img.get_width() - anchor.x
		fp = Vector2(fp.y, fp.x)
		own = Vector2(own.y, own.x)
	var m := bake_mask(img, anchor, fp, own, strip, SUN)
	var out := {"tex": ImageTexture.create_from_image(m), "size": Vector2(m.get_size())}
	_masks[key] = out
	return out


## The footprint's diamond in a sprite's pixels (front corner `anchor`, footprint `fp` in ground units; `own` a smaller
## footprint centred on it, or zero): front, left, back, right.
static func sprite_diamond(anchor: Vector2, fp: Vector2, own := Vector2.ZERO) -> PackedVector2Array:
	var g0 := -fp
	var g2 := Vector2.ZERO
	if own != Vector2.ZERO:
		var c := -fp * 0.5
		g0 = c - own * 0.5
		g2 = c + own * 0.5
	return PackedVector2Array([anchor + Iso.ground_to_screen(g2), anchor + Iso.ground_to_screen(Vector2(g0.x, g2.y)),
		anchor + Iso.ground_to_screen(g0), anchor + Iso.ground_to_screen(Vector2(g2.x, g0.y))])


## The y of a diamond's (front, left, back, right) lower or upper edge at column x, or NAN outside it. A strip's lower
## edge is its run's front edge (the longer front edge) extended across every column.
static func diamond_y(d: PackedVector2Array, x: float, lower: bool, strip := false) -> float:
	var f := d[0]
	var l := d[1]
	var b := d[2]
	var r := d[3]
	if strip and lower:
		var run_end := l if f.distance_to(l) >= f.distance_to(r) else r
		return f.y + (x - f.x) * (run_end.y - f.y) / (run_end.x - f.x)
	if x < l.x or x > r.x:
		return NAN
	if lower:
		if x <= f.x:
			return f.y if is_equal_approx(f.x, l.x) else lerpf(l.y, f.y, (x - l.x) / (f.x - l.x))
		return f.y if is_equal_approx(r.x, f.x) else lerpf(f.y, r.y, (x - f.x) / (r.x - f.x))
	if x <= b.x:
		return b.y if is_equal_approx(b.x, l.x) else lerpf(l.y, b.y, (x - l.x) / (b.x - l.x))
	return b.y if is_equal_approx(r.x, b.x) else lerpf(b.y, r.y, (x - b.x) / (r.x - b.x))


## Bakes a shadow mask from an RGBA8 image: every texel of a column from its topmost opaque one (alpha above one half)
## down to the column's base (the diamond's front edges; beyond the diamond the nearer side corner's y; a strip's whole
## run), `up` px above that base, stamps a 2x2 block at the base point + up * sun, and the diamond (a strip's band) is
## filled, so the shadow is attached and has no holes. Returns an LA8 image (white; alpha 0 or 1) with MASK_PAD px more
## on the top left and room for the shadow below and right.
static func bake_mask(img: Image, anchor: Vector2, fp: Vector2, own: Vector2, strip: bool, sun: Vector2) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var d := sprite_diamond(anchor, fp, own)
	var mw := w + MASK_PAD * 2 + int(ceil(sun.x * h)) + 2
	var mh := h + MASK_PAD * 2 + int(ceil(sun.y * h)) + 2
	var src := img.get_data()
	var out := PackedByteArray()
	out.resize(mw * mh * 2)
	for i in mw * mh:
		out[i * 2] = 255
	# A strip's band reaches back from its run by the shorter front edge's rise, twice (the diamond's depth).
	var depth := minf(absf(d[1].y - d[0].y), absf(d[3].y - d[0].y)) * 2.0
	for x in w:
		var cx := float(x) + 0.5
		var base := diamond_y(d, cx, true, strip)
		var top := base - depth if strip else diamond_y(d, cx, false)
		if is_nan(base):
			base = d[1].y if cx < d[1].x else d[3].y
		base = minf(base, float(h))
		if not is_nan(top):
			for y in range(maxi(int(floor(top)), -MASK_PAD), mini(int(ceil(base)), h + MASK_PAD)):
				out[((y + MASK_PAD) * mw + x + MASK_PAD) * 2 + 1] = 255
		# The column is solid from its topmost opaque texel down to its base: no holes under eaves, signs or porches.
		var top_y := -1
		for y in mini(h, int(ceil(base))):
			if src[(y * w + x) * 4 + 3] >= 128:
				top_y = y
				break
		if top_y < 0:
			continue
		for y in range(top_y, mini(h, int(ceil(base)))):
			var up := base - (float(y) + 0.5)
			if up <= 0.0:
				continue
			var tx := int(floor(cx + sun.x * up)) + MASK_PAD
			var ty := int(floor(base + sun.y * up)) + MASK_PAD
			for yy in [ty - 1, ty]:
				if yy < 0 or yy >= mh:
					continue
				for xx in [tx, tx + 1]:
					if xx >= 0 and xx < mw:
						out[(yy * mw + xx) * 2 + 1] = 255
	return Image.create_from_data(mw, mh, false, Image.FORMAT_LA8, out)


## A mask's quad: the mask rect `src` (mask texels) drawn so that the still's anchor texel `anchor` (in the mask's
## still frame, flipped for a mirrored sprite) lands on the screen point `base`. Returns the four corners (top left,
## top right, bottom right, bottom left).
static func mask_quad(src: Rect2, anchor: Vector2, base: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c: Vector2 in _corners(src):
		out.append(base + c - Vector2(MASK_PAD, MASK_PAD) - anchor)
	return out


## A convex ellipse polygon (screen px) round `c`.
static func ellipse(c: Vector2, rx: float, ry: float, n := 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


## A tree's shadow: a short ellipse by its foot `foot`, sized by its crown's width, moved down and to the right.
static func tree_ellipse(foot: Vector2, crown: float) -> PackedVector2Array:
	var rx := crown * TREE_RX
	var ry := rx * ELLIPSE_FLAT
	return ellipse(foot + Vector2(rx, ry) * TREE_SHIFT, rx, ry)


static func _corners(r: Rect2) -> Array[Vector2]:
	return [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]


## The shadow of a footprint `diamond` (its four corners, screen px) of `height`: the hull of the corners and the
## corners shifted by shear * height. Open (the closing point repeated by Geometry2D is dropped).
static func cast_polygon(diamond: PackedVector2Array, height: float, shear: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array(diamond)
	var off := shear * height
	for p in diamond:
		pts.append(p + off)
	var hull := Geometry2D.convex_hull(pts)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	return hull


## Whether a structure casts anything when standing: not the flat or walkable kinds.
static func casts(s: Structure) -> bool:
	return not s.walkable and s.kind != Structure.Kind.FARM_FIELD and s.kind != Structure.Kind.BRIDGE


## The footprint's diamond on screen.
static func diamond_of(r: Rect2) -> PackedVector2Array:
	var g0 := r.position
	var g2 := r.end
	return PackedVector2Array([Iso.ground_to_screen(g0), Iso.ground_to_screen(Vector2(g2.x, g0.y)),
		Iso.ground_to_screen(g2), Iso.ground_to_screen(Vector2(g0.x, g2.y))])


## The darkness of the group for a look (TownLook.shadow_colour).
static func colour_for(look_value) -> Color:
	return TownLook.shadow_colour(look_value)


func setup(field: EnvironmentField, look_value, forest_trees: Array[Dictionary] = []) -> TownShadows:
	name = "Shadows"
	env = field
	look = look_value
	trees = forest_trees
	# Drawn in screen pixels on the ground plane, as the forest and the floor are.
	transform = Iso.BASIS.affine_inverse()
	group = CanvasGroup.new()
	group.name = "ShadowGroup"
	group.self_modulate = colour_for(look)
	add_child(group)
	_struct_poly = Polygon2D.new()
	_struct_poly.name = "Structures"
	_struct_poly.color = Color.WHITE
	group.add_child(_struct_poly)
	silhouettes = _new_canvas("Silhouettes", _sil)
	group.add_child(silhouettes)
	tree_group = CanvasGroup.new()
	tree_group.name = "TreeGroup"
	tree_group.self_modulate = TownLook.tree_shadow_colour(look)
	add_child(tree_group)
	tree_poly = Polygon2D.new()
	tree_poly.name = "Trees"
	tree_poly.color = Color.WHITE
	tree_group.add_child(tree_poly)
	contact = CanvasGroup.new()
	contact.name = "ContactGroup"
	contact.self_modulate = TownLook.contact_colour(look)
	add_child(contact)
	_contact_poly = Polygon2D.new()
	_contact_poly.name = "Contact"
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://src/game/town/town_contact.gdshader")
	_contact_poly.material = cm
	contact.add_child(_contact_poly)
	env.structure_destroyed.connect(_on_change)
	env.structure_restored.connect(_on_change)
	env.structure_added.connect(_on_change)
	env.structure_removed.connect(_on_change)
	rebuild()
	return self


## The field outlives the town's nodes: let go of its signals.
func _exit_tree() -> void:
	if is_instance_valid(env):
		for sig: Signal in [env.structure_destroyed, env.structure_restored, env.structure_added, env.structure_removed]:
			if sig.is_connected(_on_change):
				sig.disconnect(_on_change)


func _on_change(_s = null, _k = null) -> void:
	if _pending:
		return
	_pending = true
	rebuild.call_deferred()


## Redraws every standing structure's shadow (a destroyed one's from its ruins) and every forest tree's: baked masks for
## the sprites, ellipses for trees, blobs for lamps and tiny props, hulls for the rest.
func rebuild() -> void:
	_pending = false
	rebuilds += 1
	if not is_instance_valid(env):
		return
	_polys.clear()
	_sil.clear()
	_tex_of.clear()
	_mask_of.clear()
	silhouette_count = 0
	tree_count = 0
	var pts := PackedVector2Array()
	var polys: Array = []
	for s in env.structures():
		if not is_instance_valid(s) or not casts(s):
			continue
		var poly := _foot_shape(s)
		if poly.is_empty():
			if _add_structure_mask(s):
				continue
			var h := s.max_height * RUIN_FACTOR if s.destroyed else s.max_height
			poly = cast_polygon(diamond_of(s.footprint), h, SHEAR)
		_polys[s.get_instance_id()] = poly
		_append_poly(pts, polys, poly)
	# Clear before the points shrink: a stale index list must never outlive its points.
	_struct_poly.polygons = []
	_struct_poly.polygon = pts
	_struct_poly.polygons = polys
	var tpts := PackedVector2Array()
	var tpolys: Array = []
	for d in trees:
		var crown := _tree_crown(d)
		if crown <= 0.0:
			continue
		_append_poly(tpts, tpolys, tree_ellipse(Iso.ground_to_screen(d.at as Vector2), crown))
		tree_count += 1
	tree_poly.polygons = []
	tree_poly.polygon = tpts
	tree_poly.polygons = tpolys
	silhouettes.queue_redraw()
	_rebuild_contact()


static func _append_poly(pts: PackedVector2Array, polys: Array, poly: PackedVector2Array) -> void:
	var idx := PackedInt32Array()
	for p in poly:
		idx.append(pts.size())
		pts.append(p)
	polys.append(idx)


## A tree's ellipse, a lamp's or a tiny prop's foot blob (screen px), or empty for a structure that casts a mask or a
## hull. A felled tree casts a small one.
func _foot_shape(s: Structure) -> PackedVector2Array:
	var foot := Iso.ground_to_screen(s.footprint.get_center())
	if s.kind == Structure.Kind.TREE:
		var w := 40.0
		if s.sprite is Dictionary and not (s.sprite as Dictionary).is_empty():
			w = (s.sprite.size as Vector2).x * 0.8
		if s.destroyed:
			w *= 0.3
		return tree_ellipse(foot, w)
	if s.kind == Structure.Kind.TORCH or s.footprint.get_area() < TINY_AREA:
		return ellipse(foot + Vector2(BLOB_RX * 0.4, BLOB_RX * 0.2), BLOB_RX, BLOB_RX * ELLIPSE_FLAT, 8)
	return PackedVector2Array()


## A forest tree's crown width (px): its sprite's (DecorSprites.tree_set), 0 without one.
static func _tree_crown(d: Dictionary) -> float:
	var tr := DecorSprites.tree_set(d.kind, d.seed, (d.size as Vector2).x)
	if tr.is_empty() or tr.get("tex") == null:
		return 0.0
	var src: Rect2 = tr.get("src", Rect2(Vector2.ZERO, tr.size))
	return src.size.x * 0.8


## A structure's mask, baked from the still it shows (its ruins once destroyed), placed by its sprite's anchor on its
## footprint's front corner; false for one without a sprite.
func _add_structure_mask(s: Structure) -> bool:
	if not (s.sprite is Dictionary) or (s.sprite as Dictionary).is_empty():
		return false
	var art: Dictionary = s.sprite
	var stills: Dictionary = art.get("stills", {})
	var st := &"intact"
	if s.destroyed:
		st = &"ruins"
	elif s.sprite_state() == &"damaged":
		st = &"damaged"
	var tex: Texture2D = stills.get(st, stills.get(&"intact"))
	if tex == null:
		return false
	var mask := mask_for(tex, art)
	if mask.is_empty():
		return false
	var mirror := bool(art.get("mirror", false))
	var size: Vector2 = art.size
	var anchor: Vector2 = art.anchor
	var msize: Vector2 = mask.size
	var src := Rect2(Vector2.ZERO, msize)
	var region: Rect2 = art.get("region", Rect2())
	if mirror:
		anchor.x = size.x - anchor.x
		if region.has_area():
			region.position.x = size.x - region.end.x
	if region.has_area():
		# A strip piece: its stretch of the run's mask, whole height. The next piece's stretch holds the shadow its
		# columns throw to the right.
		src = Rect2(region.position.x + MASK_PAD, 0.0, region.size.x, msize.y)
	var quad := mask_quad(src, anchor, Iso.ground_to_screen(s.footprint.end))
	_add_quad(mask.tex, src, quad)
	_polys[s.get_instance_id()] = quad
	_tex_of[s.get_instance_id()] = tex
	_mask_of[s.get_instance_id()] = mask.tex
	return true


func _add_quad(tex: Texture2D, src: Rect2, quad: PackedVector2Array) -> void:
	var key := tex.get_rid()
	if not _sil.has(key):
		_sil[key] = {"tex": tex, "pts": PackedVector2Array(), "uvs": PackedVector2Array()}
	var g: Dictionary = _sil[key]
	var size := Vector2(tex.get_size())
	var pts: PackedVector2Array = g.pts
	var uvs: PackedVector2Array = g.uvs
	pts.append_array(quad)
	for c: Vector2 in _corners(src):
		uvs.append(c / size)
	g.pts = pts
	g.uvs = uvs
	silhouette_count += 1


## Every mask quad of `quads`, one triangle array per texture (one draw each).
static func paint_silhouettes(c: CanvasItem, quads: Dictionary) -> void:
	for key in quads:
		var g: Dictionary = quads[key]
		var pts: PackedVector2Array = g.pts
		var idx := PackedInt32Array()
		for q in pts.size() / 4:
			var o := q * 4
			idx.append_array([o, o + 1, o + 2, o, o + 2, o + 3])
		var cols := PackedColorArray()
		cols.resize(pts.size())
		cols.fill(Color.WHITE)
		RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(), idx, pts, cols, g.uvs, PackedInt32Array(),
			PackedFloat32Array(), (g.tex as Texture2D).get_rid())


## How many mask textures are drawn (one draw call each).
func silhouette_textures() -> int:
	return _sil.size()


## The contact band of every structure that casts (a ruin's too: it still sits on the ground), as quads from its
## footprint's edge (alpha 1) out to the footprint grown by CONTACT_GROW (alpha 0), and a blob under every forest tree.
func _rebuild_contact() -> void:
	if _contact_poly == null:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var polys: Array = []
	for s in env.structures():
		if not is_instance_valid(s) or not casts(s):
			continue
		var inner := diamond_of(s.footprint)
		var outer := diamond_of(s.footprint.grow(CONTACT_GROW))
		var base := pts.size()
		for p in inner:
			pts.append(p)
			cols.append(Color(1, 1, 1, 1))
		for p in outer:
			pts.append(p)
			cols.append(Color(1, 1, 1, 0))
		for i in 4:
			var j := (i + 1) % 4
			polys.append(PackedInt32Array([base + i, base + j, base + 4 + j, base + 4 + i]))
	for d in trees:
		var tall: float = (d.size as Vector2).x if (d.size as Vector2).x > 0.0 else 52.0
		var c := Iso.ground_to_screen(d.at as Vector2)
		var rx := tall * CONTACT_TREE
		var base := pts.size()
		pts.append(c)
		cols.append(Color(1, 1, 1, 0.9))
		for i in 8:
			var a := TAU * float(i) / 8.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * rx * 0.5))
			cols.append(Color(1, 1, 1, 0))
		for i in 8:
			polys.append(PackedInt32Array([base, base + 1 + i, base + 1 + (i + 1) % 8]))
	_contact_poly.polygons = []
	_contact_poly.polygon = pts
	_contact_poly.vertex_colors = cols
	_contact_poly.polygons = polys


## How many contact shapes the band holds (for tests).
func contact_count() -> int:
	return _contact_poly.polygons.size() if _contact_poly != null else 0


## The shadow polygon of a structure (empty if it casts none): its hull, its mask's quad, or its ellipse or blob.
func polygon_of(s: Structure) -> PackedVector2Array:
	return _polys.get(s.get_instance_id(), PackedVector2Array())


func has_shadow(s: Structure) -> bool:
	return _polys.has(s.get_instance_id())


func polygon_count() -> int:
	return _polys.size()


## The still a structure's mask is baked from, or null (no mask: a hull, a blob, or none).
func shadow_texture(s: Structure) -> Texture2D:
	return _tex_of.get(s.get_instance_id())


## A structure's baked mask texture, or null.
func mask_texture(s: Structure) -> Texture2D:
	return _mask_of.get(s.get_instance_id())
