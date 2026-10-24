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
## The one group every shadow is drawn in.
var group: CanvasGroup
## Structure instance id -> its shadow polygon (screen px).
var _polys := {}
## One Polygon2D holds every structure's shadow, one convex polygon each (its `polygons`), rebuilt on change.
var _struct_poly: Polygon2D
## NIGHT's tree capsules, or DAY's first soft band (null when there are no trees).
var _tree_poly: Polygon2D
## DAY's soft tree shadows: a wider band and a smaller core, each in a group of its own (so the two add up inside the core).
var tree_bands: Array[CanvasGroup] = []
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
	_struct_poly = Polygon2D.new()
	_struct_poly.name = "Structures"
	_struct_poly.color = Color.WHITE
	group.add_child(_struct_poly)
	if look == Town.Look.DAY:
		_build_soft_trees()
	else:
		_build_trees()
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


## Redraws every standing structure's shadow (a destroyed one's as its ruin's), all into the one polygon node.
func rebuild() -> void:
	_pending = false
	rebuilds += 1
	if not is_instance_valid(env):
		return
	_polys.clear()
	var pts := PackedVector2Array()
	var polys: Array = []
	for s in env.structures():
		if not is_instance_valid(s) or not casts(s):
			continue
		var h := s.max_height * RUIN_FACTOR if s.destroyed else s.max_height
		var poly := cast_polygon(diamond_of(s.footprint), h, SHEAR)
		_polys[s.get_instance_id()] = poly
		var idx := PackedInt32Array()
		for p in poly:
			idx.append(pts.size())
			pts.append(p)
		polys.append(idx)
	# Clear before the points shrink: a stale index list must never outlive its points.
	_struct_poly.polygons = []
	_struct_poly.polygon = pts
	_struct_poly.polygons = polys


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
	_tree_poly = Polygon2D.new()
	_tree_poly.name = "Trees"
	_tree_poly.color = Color.WHITE
	group.add_child(_tree_poly)
	_tree_poly.polygon = pts
	_tree_poly.polygons = polys


## The shadow polygon of a structure (empty if it casts none).
func polygon_of(s: Structure) -> PackedVector2Array:
	return _polys.get(s.get_instance_id(), PackedVector2Array())


func has_shadow(s: Structure) -> bool:
	return _polys.has(s.get_instance_id())


func polygon_count() -> int:
	return _polys.size()


## DAY's tree shadows: per tree a short low ellipse a little down and to the right, in two stepped bands (a wide faint one
## and a smaller core), a dark green-slate tuned to the grass. They never stripe: nothing is sheared.
func _build_soft_trees() -> void:
	var bands := TownLook.tree_shadow_bands(look)
	for k in bands.size():
		var scale: float = bands[k].scale
		var pts := PackedVector2Array()
		var polys: Array = []
		for d in trees:
			var tall: float = (d.size as Vector2).x if (d.size as Vector2).x > 0.0 else 52.0
			var c := Iso.ground_to_screen(d.at as Vector2) + SHEAR * tall * 0.14
			var rx := tall * 0.26 * scale
			var idx := PackedInt32Array()
			for i in 10:
				var a := TAU * float(i) / 10.0
				idx.append(pts.size())
				pts.append((c + Vector2(cos(a) * rx, sin(a) * rx * 0.5)).round())
			polys.append(idx)
		var grp := CanvasGroup.new()
		grp.name = "TreeBand%d" % k
		grp.self_modulate = bands[k].colour
		var poly := Polygon2D.new()
		poly.name = "Trees"
		poly.color = Color.WHITE
		if not pts.is_empty():
			poly.polygon = pts
			poly.polygons = polys
		grp.add_child(poly)
		add_child(grp)
		tree_bands.append(grp)
		if k == 0:
			_tree_poly = poly
