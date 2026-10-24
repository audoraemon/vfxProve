class_name TownShadows
extends Node2D
## The cast shadows of the DAY and NIGHT looks (Town.Look). Every standing structure throws its footprint along the sun
## (down and to the right on screen), as long as it is tall: the footprint's diamond, plus its copy shifted by
## height * SHEAR, plus the hull between them. The shadows are polygons in screen pixels under the ground plane's
## transform, so they scale and pan with the art. They are all children of one CanvasGroup, drawn in an opaque colour
## and given their darkness once by the group's self_modulate, so where shadows overlap they do not stack.
## The layer sits over the floor, the plants and the forest, and under everything that stands. It is rebuilt only when a
## structure is destroyed, restored, added or removed (deferred, once per frame at most), never per frame.

## Screen pixels of shadow per pixel of height: down and to the right, away from the sun at the upper left.
const SHEAR := Vector2(1.0, 0.46)
## A destroyed structure casts the shadow of its ruin: this much of its height.
const RUIN_FACTOR := 0.15

var env: EnvironmentField
var look := 0
## The forest's baked trees (Town.build's), each a blob in the same layer.
var trees: Array[Dictionary] = []
## The one group every shadow polygon is a child of.
var group: CanvasGroup
## Structure instance id -> its polygon node.
var _polys := {}
var _tree_poly: Polygon2D
var _pending := false
## How many times rebuild() has run (for tests).
var rebuilds := 0


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
	_tree_poly = Polygon2D.new()
	_tree_poly.name = "Trees"
	_tree_poly.color = Color.WHITE
	group.add_child(_tree_poly)
	_build_trees()
	env.structure_destroyed.connect(_on_change)
	env.structure_restored.connect(_on_change)
	env.structure_added.connect(_on_change)
	env.structure_removed.connect(_on_change)
	rebuild()
	return self


func _on_change(_s = null, _k = null) -> void:
	if _pending:
		return
	_pending = true
	rebuild.call_deferred()


## Redraws every standing structure's shadow (a destroyed one's as its ruin's).
func rebuild() -> void:
	_pending = false
	rebuilds += 1
	if not is_instance_valid(env):
		return
	var alive := {}
	for s in env.structures():
		if not is_instance_valid(s) or not casts(s):
			continue
		var id := s.get_instance_id()
		alive[id] = true
		var h := s.max_height * RUIN_FACTOR if s.destroyed else s.max_height
		var poly := cast_polygon(diamond_of(s.footprint), h, SHEAR)
		var node: Polygon2D = _polys.get(id)
		if node == null:
			node = Polygon2D.new()
			node.color = Color.WHITE
			group.add_child(node)
			_polys[id] = node
		if node.polygon != poly:
			node.polygon = poly
	for id in _polys.keys():
		if not alive.has(id):
			(_polys[id] as Node).queue_free()
			_polys.erase(id)


## One capsule per baked forest tree, all in a single multi-polygon node.
func _build_trees() -> void:
	var pts := PackedVector2Array()
	var polys: Array = []
	for d in trees:
		var tall: float = (d.size as Vector2).x if (d.size as Vector2).x > 0.0 else 52.0
		var base := Iso.ground_to_screen(d.at as Vector2)
		var rx := tall * 0.2
		var ring := PackedVector2Array()
		for i in 8:
			var a := TAU * float(i) / 8.0
			var e := Vector2(cos(a) * rx, sin(a) * rx * 0.5)
			ring.append(base + e)
			ring.append(base + e + SHEAR * tall * 0.9)
		var hull := Geometry2D.convex_hull(ring)
		if hull.size() > 1:
			hull.remove_at(hull.size() - 1)
		var idx := PackedInt32Array()
		for p in hull:
			idx.append(pts.size())
			pts.append(p)
		polys.append(idx)
	if pts.is_empty():
		return
	_tree_poly.polygon = pts
	_tree_poly.polygons = polys


## The polygon node of a structure, or null (for tests).
func polygon_of(s: Structure) -> Polygon2D:
	return _polys.get(s.get_instance_id())


func polygon_count() -> int:
	return _polys.size()
