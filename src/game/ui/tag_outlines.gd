class_name TagOutlines
extends CanvasLayer
## Covered-outline (2026-11-17, "Option A"): a person the map tags (MapTag.who, as Hud.all_tags() shows them) who stands behind something
## drawn in front of them -- a stall's roof, a tree, a house, a wall: the y-sorted world sprites -- gets a thin outline of the hidden part of
## the body, one art px wide, in the tag's colour. Only the covered parts: a tagged person in the open looks as before, an untagged one never
## gets one, and the occluder stays as it is (the hidden body is not filled in).
##
## How: each outlined person takes a slot (up to SLOTS): a copy of its sprite frame on this layer. A mask is a SubViewport sharing the
## world's World2D that renders only the canvas items carrying its visibility-layer bit (canvas_cull_mask). Every frame (just before
## drawing) the things in front of each outlined person -- the Structures, Decor and look props sorted after the body (y-sort order, z)
## whose screen box meets it -- get its mask's bit, so the mask renders exactly them, aligned to the world viewport's device pixels round the
## body: the occluder mask. People share one mask unless a thing in front of one meets another it is not in front of (clash()): then they
## take separate masks. Each mask is one more pass over the world's canvas, so several tags cost about one. The copy's shader
## (tag_outline.gdshader) keeps only the frame's edge texels its mask covers. This layer sits over the world's grade and glow (LAYER), so
## the outline keeps its colour at night.
## Visual only: nothing here moves, sorts or seeds anything the simulation reads. Hosted worlds only (headless runs never draw).

## Over the grade (1), the bloom (2), the glow (3), and as a later sibling than Battlefield's post layer (4): the outline is not graded, not
## bloomed and not glowed into a halo. Under the flash (5).
const LAYER := 4
## People outlined at once (a few tagged people, so a dozen is plenty), and the masks' visibility-layer bits (FIRST_BIT .., one a mask:
## never more masks than people).
const SLOTS := 12
const FIRST_BIT := 8
const ALL_BITS := ((1 << SLOTS) - 1) << FIRST_BIT
## A mask's size steps (device px).
const MASK_STEP := 64
## The occluder index's cell (world px).
const CELL := 64.0
## A decor piece's screen box round its ground footprint (generous; times its ArtTuning scale): a tree's crown stands DECOR_UP over its foot
## and spreads DECOR_SIDE either side; the rest (a barrel, a bench, a cart) DECOR_UP_SMALL and DECOR_SIDE_SMALL unless listed.
const DECOR_UP := 128.0
const DECOR_SIDE := 48.0
const DECOR_UP_SMALL := 40.0
const DECOR_SIDE_SMALL := 24.0
const DECOR_TALL := [Decor.Kind.OAK, Decor.Kind.PINE, Decor.Kind.SHIP]
const DECOR_UP_BY_KIND := {Decor.Kind.OAK: DECOR_UP, Decor.Kind.PINE: DECOR_UP, Decor.Kind.SHIP: DECOR_UP, Decor.Kind.LAMP: 56.0,
	Decor.Kind.BUNTING: 64.0, Decor.Kind.SCARECROW: 48.0, Decor.Kind.SIGNPOST: 48.0, Decor.Kind.BOAT: 56.0}
## A footprint's screen box is cut into parts at most this long (ground units) each way (_ground_boxes()).
const PART := 2.0
const SHADER := preload("res://src/game/ui/tag_outline.gdshader")

## The HUD whose tags are traced.
var hud: Hud
## The y-sorted world layer (Battlefield's WorldLayer).
var world: Node2D
## The viewport the world is drawn in (the WorldView's).
var world_vp: Viewport
## Tests only: refresh even when the world is not hosted (headless model runs).
static var test_force := false

var _slots: Array[Slot] = []
var _masks: Array[Mask] = []
## Each occluder: {node: CanvasItem, items: Array[CanvasItem] (it and its sprite children), box: Rect2 (world px, all its parts), y: float,
## z: int}.
var _items: Array[Dictionary] = []
## The occluder index: each occluder's screen box in parts (a long wall or a row of trees is a diagonal on screen: one box round it would
## meet everything near), the item of each part, and Vector2i cell -> PackedInt32Array of the parts meeting that cell.
var _part_box: Array[Rect2] = []
var _part_item := PackedInt32Array()
var _cells := {}
## Per item: its sort key and z (packed, for the per-frame query), and the query that last saw it.
var _ys := PackedFloat32Array()
var _zs := PackedInt32Array()
var _stamp := PackedInt32Array()
var _query := 0
## The index needs building again: a world sprite came or went under a y-sorted layer it watches (_containers).
var _dirty := true
var _containers: Array[Node] = []
## Ancestors of an occluder given every mask bit (a canvas item renders in a viewport only if it and all its parents share a bit).
var _marked: Array[CanvasItem] = []


## One outlined person: its traced copy and the mask it reads.
class Slot:
	var copy: Copy
	var mat: ShaderMaterial
	var who: Person = null
	var color := Color.WHITE
	var mask: Mask = null


## One occluder mask: its bit, its viewport, the canvas items carrying the bit (instance id -> Array[CanvasItem]) and its top-left in the
## world viewport's device px.
class Mask:
	var bit := 0
	var vp: SubViewport
	var occ := {}
	var origin := Vector2.ZERO


## The person's frame drawn again, through the outline shader.
class Copy extends Node2D:
	var src := Rect2()
	var dst := Rect2()

	func _draw() -> void:
		var tex := PeopleArt.atlas()
		if tex != null and src.has_area():
			draw_texture_rect_region(tex, dst, src)


func setup(p_hud: Hud, bf: Node) -> TagOutlines:
	name = "TagOutlines"
	layer = LAYER
	follow_viewport_enabled = true
	hud = p_hud
	world = bf.get_node_or_null("WorldLayer") as Node2D
	return self


func _enter_tree() -> void:
	world_vp = get_viewport()
	if not RenderingServer.frame_pre_draw.is_connected(refresh):
		RenderingServer.frame_pre_draw.connect(refresh)


## Leaving: every bit given back (the occluders' and their ancestors') and the index let go.
func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(refresh):
		RenderingServer.frame_pre_draw.disconnect(refresh)
	for s in _slots:
		_release(s)
	for m in _masks:
		_free_mask(m)
	for n: Variant in _marked:
		if is_instance_valid(n):
			n.visibility_layer &= ~ALL_BITS
	_marked.clear()
	_unwatch()
	_dirty = true


# --- Who ---------------------------------------------------------------------------------------------------------------------------

## The people `tags` (what the map shows: Hud.all_tags()) would outline when covered, each once with its first tag's colour (the mission's
## own tags come first): a tag on a Person who is drawn (MapTag.drawn(): not hidden, faded or indoors), alive, and last drawn standing
## from the people sprites (Person.drawn_upright). Pairs [Person, Color]. Spots, places and untagged people are never in it.
static func wanted(tags: Array[MapTag]) -> Array:
	var out: Array = []
	var seen := {}
	for t in tags:
		if not t.valid() or t.who == null or not is_instance_valid(t.who) or not (t.who is Person):
			continue
		var p := t.who as Person
		if seen.has(p.get_instance_id()) or not t.drawn() or not p.is_alive() or p.inside or not p.drawn_upright:
			continue
		seen[p.get_instance_id()] = true
		out.append([p, t.color])
	return out


## The person's drawn sprite frame on the world layer (world px): its last drawing's destination from its draw origin.
func body_box(p: Person) -> Rect2:
	return _to_world() * p.get_global_transform() * Transform2D(0.0, p._draw_origin) * p.drawn_dst


## The things drawn in front of `p` that meet its body on screen: Structures, Decor and look props (the y-sorted world sprites; never
## people or animals) sorted after it -- a higher z, or the same z and further down the screen (tree order on a tie) -- whose screen box
## meets its drawn frame. Each as its index entry (_items). Empty: the person is in the open, and nothing is outlined.
func occluders_of(p: Person) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if world == null or not p.drawn_dst.has_area():
		return out
	_ensure_index()
	var to_world := _to_world()
	var box := to_world * p.get_global_transform() * Transform2D(0.0, p._draw_origin) * p.drawn_dst
	var py := (to_world * p.get_global_transform()).origin.y
	var pz := _z(p)
	_query += 1
	for c in _cells_of(box):
		var parts: Variant = _cells.get(c)
		if parts == null:
			continue
		for k: int in parts as PackedInt32Array:
			if not _part_box[k].intersects(box):
				continue
			var i := _part_item[k]
			if _stamp[i] == _query:
				continue
			_stamp[i] = _query
			var z := _zs[i]
			if z < pz or (z == pz and _ys[i] < py):
				continue
			var it := _items[i]
			var n: Variant = it.node  # untyped: it may have been freed since the index was built
			if not is_instance_valid(n) or not n.is_visible_in_tree():
				continue
			if z == pz and _ys[i] == py and not n.is_greater_than(p):
				continue
			out.append(it)
	return out


## The people outlined now: [Person, Color] per slot in use (a covered tagged person).
func outlined() -> Array:
	var out: Array = []
	for s in _slots:
		if s.who != null and is_instance_valid(s.who) and s.copy.visible:
			out.append([s.who, s.color])
	return out


## Two covered people may not share a mask when a thing in front of one meets the other's body without being in front of it too: the
## shared mask would cover that body where it shows. Each is {ids (occluder instance id -> index entry), body (world px)}.
static func clash(a: Dictionary, b: Dictionary) -> bool:
	for pair: Array in [[a, b], [b, a]]:
		var x: Dictionary = pair[0]
		var y: Dictionary = pair[1]
		for id: int in x.ids:
			if not y.ids.has(id) and ((x.ids[id] as Dictionary).box as Rect2).intersects(y.body):
				return true
	return false


# --- Each frame ------------------------------------------------------------------------------------------------------------------

## Just before the frame is drawn (the camera and the bodies are where they will be drawn): the HUD's tags, while it shows them in a hosted
## world with the people sprites on.
func refresh() -> void:
	if not is_inside_tree() or world == null or not is_instance_valid(world):
		return
	var on := (WorldView.of(self) != null or test_force) and hud != null and is_instance_valid(hud) and hud.tag_layer_on()
	var none: Array[MapTag] = []
	update(hud.all_tags() if on and SpriteArt.on() and PeopleArt.ready() else none)


## Who of `tags`' people is covered (wanted(), then occluders_of()), up to SLOTS in tag order; their masks (shared where nothing clashes),
## the occluders' bits, and their copies. The rest let go of their slots, and masks no one reads of their bits.
func update(tags: Array[MapTag]) -> void:
	var covered: Array[Dictionary] = []
	for w: Array in wanted(tags):
		if covered.size() >= SLOTS:
			break
		var occ := occluders_of(w[0])
		if occ.is_empty():
			continue
		var ids := {}
		for it in occ:
			ids[(it.node as Object).get_instance_id()] = it
		covered.append({"who": w[0], "color": w[1], "ids": ids, "body": body_box(w[0])})
	# Each person joins the first mask it clashes with no one in.
	var groups: Array = []
	for c in covered:
		var placed := false
		for g: Array in groups:
			if not g.any(func(o: Dictionary) -> bool: return clash(c, o)):
				g.append(c)
				placed = true
				break
		if not placed:
			groups.append([c])
	var keep := {}
	for c in covered:
		keep[(c.who as Person).get_instance_id()] = true
	for s in _slots:
		if s.who != null and (not is_instance_valid(s.who) or not keep.has(s.who.get_instance_id())):
			_release(s)
	var dev := device_xf()
	for gi in groups.size():
		if gi >= _masks.size():
			_masks.append(_new_mask(gi))
		var mask := _masks[gi]
		var items := {}
		var rect := Rect2()
		for c: Dictionary in groups[gi]:
			items.merge(c.ids)
			var p: Person = c.who
			var r := dev * (p.get_global_transform() * Transform2D(0.0, p._draw_origin)) * p.drawn_dst
			rect = r if not rect.has_area() else rect.merge(r)
		_bind(mask, items)
		_size_mask(mask, rect.grow(2.0), dev)
		for c: Dictionary in groups[gi]:
			var s := _slot_for(c.who)
			s.color = c.color
			s.mask = mask
			_place(s)
	for mi in range(groups.size(), _masks.size()):
		_free_mask(_masks[mi])


## How many masks are drawing now (tests, the fps check).
func masks_on() -> int:
	return _masks.filter(func(m: Mask) -> bool: return m.vp.render_target_update_mode != SubViewport.UPDATE_DISABLED).size()


func _slot_for(p: Person) -> Slot:
	var free: Slot = null
	for s in _slots:
		if s.who == p:
			return s
		if s.who == null and free == null:
			free = s
	if free == null:
		free = _new_slot(_slots.size())
		_slots.append(free)
	free.who = p
	return free


func _new_slot(i: int) -> Slot:
	var s := Slot.new()
	s.mat = ShaderMaterial.new()
	s.mat.shader = SHADER
	s.copy = Copy.new()
	s.copy.name = "Outline%d" % i
	s.copy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.copy.material = s.mat
	s.copy.visible = false
	add_child(s.copy)
	return s


func _new_mask(i: int) -> Mask:
	var m := Mask.new()
	m.bit = 1 << (FIRST_BIT + i)
	m.vp = SubViewport.new()
	m.vp.name = "OutlineMask%d" % i
	m.vp.disable_3d = true
	m.vp.transparent_bg = true
	m.vp.world_2d = world_vp.world_2d
	m.vp.canvas_cull_mask = m.bit
	m.vp.snap_2d_vertices_to_pixel = world_vp.snap_2d_vertices_to_pixel
	m.vp.canvas_item_default_texture_filter = world_vp.canvas_item_default_texture_filter
	m.vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	m.vp.size = Vector2i(2, 2)
	add_child(m.vp)
	return m


## The mask's bit on exactly `items`' canvas items (instance id -> index entry), and on every ancestor of theirs once.
func _bind(m: Mask, items: Dictionary) -> void:
	for id: int in m.occ:
		if not items.has(id):
			for ci: Variant in m.occ[id]:  # untyped: freed ones are skipped
				if is_instance_valid(ci):
					ci.visibility_layer &= ~m.bit
	var now := {}
	for id: int in items:
		var cis: Array[CanvasItem] = (items[id] as Dictionary).items
		now[id] = cis
		if not m.occ.has(id):
			for ci in cis:
				if is_instance_valid(ci):
					ci.visibility_layer |= m.bit
			_mark_ancestors(cis[0])
	m.occ = now


func _mark_ancestors(ci: CanvasItem) -> void:
	var n := ci.get_parent()
	while n is CanvasItem:
		if ((n as CanvasItem).visibility_layer & ALL_BITS) != ALL_BITS:
			(n as CanvasItem).visibility_layer |= ALL_BITS
			_marked.append(n)
		n = n.get_parent()


## The mask over `r` (the world viewport's device px), on whole pixels so it lines up with the world's.
func _size_mask(m: Mask, r: Rect2, dev: Transform2D) -> void:
	var origin := Vector2(floorf(r.position.x), floorf(r.position.y))
	var need := Vector2i(maxi(int(ceilf(r.end.x - origin.x)), 1), maxi(int(ceilf(r.end.y - origin.y)), 1))
	# Resizing reallocates the render target: the size moves in steps of MASK_STEP and only when the bodies no longer fit or would fit in
	# a quarter of it, never every frame a body walks or animates. The spare edge renders nothing the shader reads.
	var have := m.vp.size
	if have.x < need.x or have.y < need.y or have.x * have.y > 4 * MASK_STEP * MASK_STEP + 4 * need.x * need.y:
		m.vp.size = Vector2i(ceili(need.x / float(MASK_STEP)) * MASK_STEP, ceili(need.y / float(MASK_STEP)) * MASK_STEP)
	var ct := Transform2D(0.0, -origin) * dev
	if m.vp.canvas_transform != ct:
		m.vp.canvas_transform = ct
	if m.vp.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		m.vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	m.origin = origin


func _free_mask(m: Mask) -> void:
	for id: int in m.occ:
		for ci: Variant in m.occ[id]:  # untyped: freed ones are skipped
			if is_instance_valid(ci):
				ci.visibility_layer &= ~m.bit
	m.occ = {}
	if is_instance_valid(m.vp):
		m.vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


## The copy over the body, reading its mask.
func _place(s: Slot) -> void:
	var p := s.who
	var tex := s.mask.vp.get_texture()
	if s.mat.get_shader_parameter("mask") != tex:
		s.mat.set_shader_parameter("mask", tex)
	_param(s.mat, "mask_origin", s.mask.origin)
	_param(s.mat, "region", Vector4(p.drawn_src.position.x, p.drawn_src.position.y, p.drawn_src.size.x, p.drawn_src.size.y))
	_param(s.mat, "tag_color", s.color)
	var xf := p.get_global_transform() * Transform2D(0.0, p._draw_origin)
	if s.copy.transform != xf:
		s.copy.transform = xf
	if s.copy.src != p.drawn_src or s.copy.dst != p.drawn_dst:
		s.copy.src = p.drawn_src
		s.copy.dst = p.drawn_dst
		s.copy.queue_redraw()
	s.copy.visible = true


## A shader parameter set only when it changes (each set queues a material update).
static func _param(m: ShaderMaterial, key: StringName, v: Variant) -> void:
	if m.get_shader_parameter(key) != v:
		m.set_shader_parameter(key, v)


func _release(s: Slot) -> void:
	s.who = null
	s.mask = null
	if is_instance_valid(s.copy):
		s.copy.visible = false


## The world canvas to the world viewport's device px: its size_2d_override stretch over its global canvas and camera transforms.
func device_xf() -> Transform2D:
	var k := Vector2.ONE
	if world_vp is SubViewport:
		var sv := world_vp as SubViewport
		if sv.size_2d_override.x > 0 and sv.size_2d_override.y > 0 and sv.size_2d_override_stretch:
			k = Vector2(sv.size) / Vector2(sv.size_2d_override)
	return Transform2D(0.0, k, 0.0, Vector2.ZERO) * world_vp.global_canvas_transform * world_vp.canvas_transform


# --- The occluder index ----------------------------------------------------------------------------------------------------------

func _to_world() -> Transform2D:
	return world.get_global_transform().affine_inverse()


## A canvas item's z as drawn (its own z on its parents' while relative).
static func _z(ci: CanvasItem) -> int:
	var z := 0
	var n: Node = ci
	while n is CanvasItem:
		z += (n as CanvasItem).z_index
		if not (n as CanvasItem).z_as_relative:
			break
		n = n.get_parent()
	return z


func _cells_of(r: Rect2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cx in range(floori(r.position.x / CELL), floori(r.end.x / CELL) + 1):
		for cy in range(floori(r.position.y / CELL), floori(r.end.y / CELL) + 1):
			out.append(Vector2i(cx, cy))
	return out


## Rebuilt when a world sprite comes or goes under the y-sorted layers (a building put up or freed, decor added): people, animals and
## effects coming and going leave it as it is.
func _ensure_index() -> void:
	if not _dirty:
		return
	_dirty = false
	_unwatch()
	_items.clear()
	_part_box.clear()
	_part_item.clear()
	_cells.clear()
	_collect(world, _to_world())
	_ys.resize(_items.size())
	_zs.resize(_items.size())
	_stamp.resize(_items.size())
	_stamp.fill(0)
	for i in _items.size():
		_ys[i] = _items[i].y
		_zs[i] = _items[i].z
	var lists := {}  # built as Arrays: a PackedInt32Array taken out of a Dictionary is a copy
	for k in _part_box.size():
		for c in _cells_of(_part_box[k]):
			if not lists.has(c):
				lists[c] = []
			(lists[c] as Array).append(k)
	for c: Vector2i in lists:
		_cells[c] = PackedInt32Array(lists[c])


func _unwatch() -> void:
	for n: Variant in _containers:
		if is_instance_valid(n) and n.child_entered_tree.is_connected(_on_child):
			n.child_entered_tree.disconnect(_on_child)
			n.child_exiting_tree.disconnect(_on_child)
	_containers.clear()


func _on_child(n: Node) -> void:
	if n is Structure or n is Decor or n is TownLookDecor.PropNode or (n is Node2D and (n as Node2D).y_sort_enabled):
		_dirty = true


## The y-sort's members under `n` (nested y-sorted layers flattened), the occluding kinds only; `n` watched for new ones.
func _collect(n: Node, inv: Transform2D) -> void:
	_containers.append(n)
	n.child_entered_tree.connect(_on_child)
	n.child_exiting_tree.connect(_on_child)
	for c in n.get_children():
		if c is DummyEnemy or c is Animal or not (c is CanvasItem):
			continue
		if c is Node2D and (c as Node2D).y_sort_enabled:
			_collect(c, inv)
			continue
		var parts := _boxes(c as CanvasItem, inv)
		if parts.is_empty():
			continue
		var items: Array[CanvasItem] = [c as CanvasItem]
		for k in c.get_children():
			if k is SpriteView:
				items.append(k)
		var box := parts[0]
		for r in parts:
			box = box.merge(r)
			_part_box.append(r)
			_part_item.append(_items.size())
		_items.append({"node": c, "items": items, "box": box, "y": (inv * (c as CanvasItem).get_global_transform()).origin.y, "z": _z(c)})


## An occluder's screen box on the world layer, in parts (generous: a box too big only renders an empty corner of a mask), or none for
## anything that is not a world sprite.
func _boxes(c: CanvasItem, inv: Transform2D) -> Array[Rect2]:
	if c is Structure:
		var s := c as Structure
		return _ground_boxes(s.footprint, maxf(s.max_height, s.height), 0.0)
	var at := (inv * c.get_global_transform()).origin
	if c is Decor:
		var d := c as Decor
		var k := ArtTuning.scale(d.tuning_key()) * d.scale_mul
		var up: float = DECOR_UP_BY_KIND.get(d.kind, DECOR_UP_SMALL) * k
		var side: float = (DECOR_SIDE if d.kind in DECOR_TALL else DECOR_SIDE_SMALL) * k
		var out := _ground_boxes(Rect2(d.at, d.size).abs(), up, side)
		out[0] = out[0].merge(Rect2(at, Vector2.ZERO).grow_individual(side, up, side, 8.0))
		return out
	if c is TownLookDecor.PropNode:
		var rects: Array[Rect2] = (c as TownLookDecor.PropNode).rects
		var out: Array[Rect2] = []
		for i in range(0, rects.size(), 2):
			out.append(Rect2(rects[i].position + at, rects[i].size))
		return out
	var none: Array[Rect2] = []
	return none


## A ground footprint's screen boxes, raised `up` (and a roof, Person._screen_box()) and widened `side` either way: one per piece of at most
## PART ground units each way, so a long wall or a row of trees is a chain of boxes along its diagonal on screen, not one box round it.
static func _ground_boxes(fp: Rect2, up: float, side: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var nx := maxi(ceili(fp.size.x / PART), 1)
	var ny := maxi(ceili(fp.size.y / PART), 1)
	var step := Vector2(fp.size.x / nx, fp.size.y / ny)
	for ix in nx:
		for iy in ny:
			var r := Rect2(fp.position + Vector2(ix * step.x, iy * step.y), step)
			out.append(Person._screen_box(r, up).grow_individual(side, 0.0, side, 0.0))
	return out
