class_name TownShadows
extends Node2D
## The cast shadows of the DAY and NIGHT looks (Town.Look). Round 4: every standing structure with a sprite, and every
## forest tree, throws its own silhouette along the sun (down and to the right on screen): its sprite drawn a second
## time, skewed about its base row (a texel h px above the base lands h * SHEAR from it: x shifted by h, y squashed
## toward the base), so towers, roofs, the cathedral's spire and the tree crowns cast their real shapes. A structure
## without a sprite casts the old hull: its footprint's diamond, its copy shifted by height * SHEAR, and the hull
## between. Everything is in screen pixels under the ground plane's transform, so it scales and pans with the art. All of
## it is drawn white in one CanvasGroup and given its darkness once by the group's self_modulate, so overlaps never
## stack.
## The layer sits over the floor, the plants and the forest, and under everything that stands. It is rebuilt only when a
## structure is destroyed, restored, added or removed (deferred, once per frame at most), never per frame.

## Screen pixels of shadow per pixel of height: down and to the right, away from the sun at the upper left.
const SHEAR := Vector2(1.0, 0.46)
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
## Structure instance id -> its shadow polygon (screen px): its hull, or its silhouette's skewed quad.
var _polys := {}
## One Polygon2D holds the hull shadow of every structure without a sprite, one convex polygon each, rebuilt on change.
var _struct_poly: Polygon2D
## The silhouettes: one node drawing, per sprite texture, one triangle array of skewed quads, through one shared
## material. Texture RID -> {tex, pts, uvs}. The forest's trees draw on a node of their own in a group of their own
## (tree_group: their colour, TownLook.tree_shadow_colour()).
var silhouettes: SilhouetteCanvas
var tree_group: CanvasGroup
var tree_silhouettes: SilhouetteCanvas
var _sil := {}
var _tree_sil := {}
## How many silhouette quads are drawn, and how many of them are trees' (for tests).
var silhouette_count := 0
var tree_count := 0
## Structure instance id -> the still its silhouette is drawn from.
var _tex_of := {}
## The contact shadows: a dithered band round every structure's base and a blob under every tree, in a group of their
## own (darker than the cast shadows; TownLook.contact_colour()).
var contact: CanvasGroup
var _contact_poly: Polygon2D
var _pending := false
## How many times rebuild() has run (for tests).
var rebuilds := 0

static var _sil_material: ShaderMaterial


## A silhouettes' draw node: one triangle array per texture of its quads (TownShadows.paint_silhouettes()).
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


## The one material every silhouette draws through: white where the texel is opaque.
static func silhouette_material() -> ShaderMaterial:
	if _sil_material == null:
		_sil_material = ShaderMaterial.new()
		_sil_material.shader = preload("res://src/game/town/town_silhouette.gdshader")
	return _sil_material


## A sprite's shadow quad: the texture rect `src` drawn with its anchor texel `anchor` on the screen point `base`,
## mirrored when `mirror`, then skewed about the base row: a corner h px above the base lands at x + h * shear.x,
## base.y + h * shear.y. Returns the four corners (the texture's top left, top right, bottom right, bottom left).
static func silhouette_quad(src: Rect2, anchor: Vector2, base: Vector2, mirror: bool, shear: Vector2) -> PackedVector2Array:
	var m := -1.0 if mirror else 1.0
	var out := PackedVector2Array()
	for c: Vector2 in _corners(src):
		var local := c - anchor
		var h := -local.y
		out.append(Vector2(base.x + m * local.x + h * shear.x, base.y + h * shear.y))
	return out


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
	tree_silhouettes = _new_canvas("TreeSilhouettes", _tree_sil)
	tree_group.add_child(tree_silhouettes)
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


## Redraws every standing structure's shadow (a destroyed one's from its ruins) and every forest tree's: silhouettes for
## the sprites, hulls for the rest.
func rebuild() -> void:
	_pending = false
	rebuilds += 1
	if not is_instance_valid(env):
		return
	_polys.clear()
	_sil.clear()
	_tree_sil.clear()
	_tex_of.clear()
	silhouette_count = 0
	tree_count = 0
	var pts := PackedVector2Array()
	var polys: Array = []
	for s in env.structures():
		if not is_instance_valid(s) or not casts(s):
			continue
		if _add_structure_silhouette(s):
			continue
		var h := s.max_height * RUIN_FACTOR if s.destroyed else s.max_height
		var poly := cast_polygon(diamond_of(s.footprint), h, SHEAR)
		_polys[s.get_instance_id()] = poly
		var idx := PackedInt32Array()
		for p in poly:
			idx.append(pts.size())
			pts.append(p)
		polys.append(idx)
	for d in trees:
		_add_tree_silhouette(d)
	# Clear before the points shrink: a stale index list must never outlive its points.
	_struct_poly.polygons = []
	_struct_poly.polygon = pts
	_struct_poly.polygons = polys
	silhouettes.queue_redraw()
	tree_silhouettes.queue_redraw()
	_rebuild_contact()


## A structure's silhouette from the still it shows (its ruins once destroyed), at its footprint's front corner where
## its sprite's anchor sits; false for one without a sprite.
func _add_structure_silhouette(s: Structure) -> bool:
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
	var src := Rect2(Vector2.ZERO, art.size)
	var region: Rect2 = art.get("region", Rect2())
	if region.has_area():
		src = region
	_polys[s.get_instance_id()] = _add_quad(tex, src, art.anchor, Iso.ground_to_screen(s.footprint.end),
		bool(art.get("mirror", false)))
	_tex_of[s.get_instance_id()] = tex
	return true


## A forest tree's silhouette from its sprite set (DecorSprites.tree_set, placed as DecorSprites.paint() draws it).
func _add_tree_silhouette(d: Dictionary) -> void:
	var tr := DecorSprites.tree_set(d.kind, d.seed, (d.size as Vector2).x)
	if tr.is_empty() or tr.get("tex") == null:
		return
	var src: Rect2 = tr.get("src", Rect2(Vector2.ZERO, tr.size))
	_add_quad(tr.tex, src, tr.anchor, Iso.ground_to_screen(d.at as Vector2).round(), false, true)
	tree_count += 1


func _add_quad(tex: Texture2D, src: Rect2, anchor: Vector2, base: Vector2, mirror: bool, tree := false) -> PackedVector2Array:
	var quad := silhouette_quad(src, anchor, base, mirror, SHEAR)
	var key := tex.get_rid()
	var bucket := _tree_sil if tree else _sil
	if not bucket.has(key):
		bucket[key] = {"tex": tex, "pts": PackedVector2Array(), "uvs": PackedVector2Array()}
	var g: Dictionary = bucket[key]
	var size := Vector2(tex.get_size())
	var pts: PackedVector2Array = g.pts
	var uvs: PackedVector2Array = g.uvs
	pts.append_array(quad)
	for c: Vector2 in _corners(src):
		uvs.append(c / size)
	g.pts = pts
	g.uvs = uvs
	silhouette_count += 1
	return quad


## Every silhouette of `quads`, one triangle array per texture (one draw each).
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


## How many textures the silhouettes draw from (one draw call each), buildings' and trees'.
func silhouette_textures() -> int:
	return _sil.size() + _tree_sil.size()


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


## The shadow polygon of a structure (empty if it casts none): its hull, or its silhouette's skewed quad.
func polygon_of(s: Structure) -> PackedVector2Array:
	return _polys.get(s.get_instance_id(), PackedVector2Array())


func has_shadow(s: Structure) -> bool:
	return _polys.has(s.get_instance_id())


func polygon_count() -> int:
	return _polys.size()


## The still a structure's silhouette is drawn from, or null (no silhouette: a hull, or none).
func shadow_texture(s: Structure) -> Texture2D:
	return _tex_of.get(s.get_instance_id())
