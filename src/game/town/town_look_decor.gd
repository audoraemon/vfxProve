class_name TownLookDecor
extends Node2D
## The DAY and NIGHT looks' extra lights (round 2), visual only: a torch every TORCH_STEP along every wall walk, a lantern
## by every house on its face toward the street, and street lamps along the roads and round the squares every LAMP_STEP
## where the ground is free. Drawn in code at the house art's scale (round 4: small posts, the engine's small flame and
## lantern glass), packed into one atlas with one material, so neighbouring props batch; the flames step on the idle clock in the shader (town_look_decor.gdshader), with no per-frame work.
## Nothing here is gameplay: no structure, no decor in EnvironmentField, no walk grid, no LightField entry, no random draw
## (placement is a pure function of the city and its seeds-free hashes). Each prop's light goes to the light map
## (TownPools reads lights()), so NIGHT gets a warm pool round every one. A prop on a building (a wall torch, a house's
## lantern) sorts just after it and hides while it is down.
## The node itself is the props' y-sorted layer in the world (its children sort with everything else), lit as the decor
## layer is (Town.DecorLayer: the ambient and the tint).

enum Prop { TORCH, LAMP, LANTERN }

## Wall-walk torches: one every TORCH_STEP ground units along a wall's run (a grid laid along the axis, so the spacing
## carries over from one wall piece to the next). Round 4: none on the towers' and gatehouses' tops: their art's own
## painted braziers glow there (the extra crown of four torches and a brazier read as person-sized fires).
const TORCH_STEP := 2.5
## Street lamps: along each side of a road every LAMP_STEP (the sides staggered by half), LAMP_OUT off its edge; round each
## square every LAMP_STEP, LAMP_IN inside its edge. A lamp keeps CLEAR from any other piece and FOOT_CLEAR off a footprint.
## Round 4: every 5.5 cells, so the lamps are points in a dark town.
const LAMP_STEP := 5.5
const LAMP_OUT := 0.3
const LAMP_IN := 0.3
const CLEAR := 0.5
const FOOT_CLEAR := 0.2
## DAY (round 3) shows far fewer props: no wall-walk torches, street lamps
## only along the main avenues (roads at least MAIN_ROAD wide) every DAY_LAMP_STEP and round the squares, and a lantern
## only by a house within DAY_NEAR of a square or a main avenue (and by the church and barracks); none on the stalls.
const MAIN_ROAD := 1.3
const DAY_LAMP_STEP := 6.0
const DAY_NEAR := 1.2
## Lamps stand inside the town (and the capital's paved ring), and this far beyond it along the approaches.
const TOWN_PAD := 1.5
## The buildings that get a lantern by their door.
const LANTERN_KINDS := [Structure.Kind.HOUSE, Structure.Kind.MARKET_STALL, Structure.Kind.TEMPLE, Structure.Kind.BARRACKS]
## A house's lantern stands LANTERN_OUT off its face, and none where the town's own lantern (a decor lamp) stands within
## LANTERN_GAP (round 4: two lanterns at one door doubled its pool).
const LANTERN_OUT := 0.14
const LANTERN_GAP := 1.5
## A prop on a building sorts this far (screen px) below its building's sort point: just after it.
const SORT_AFTER := 0.01

## The light each prop sends to the light map (TownPools): its pool's radius (screen px, x semi-axis), strength and flicker.
## Round 4: small pools, so the lights are points in a dark town: a lantern about 1.2 cells (Iso.radius_to_screen), a
## street lamp or torch about 2 cells, each full only near its middle.
const LIGHT := {
	Prop.TORCH: {"radius": 56.0, "alpha": 0.8, "flicker": 1.0},
	Prop.LAMP: {"radius": 80.0, "alpha": 1.0, "flicker": 0.5},
	Prop.LANTERN: {"radius": 46.0, "alpha": 0.8, "flicker": 0.5},
}
## A market stall's bare lantern's pool: a point on its counter.
const BARE_RADIUS := 24.0
const BARE_ALPHA := 0.5

## The atlas: the three sprites on its top rows, then the animated band from BAND_Y: rows of four CELL x CELL frames.
const ATLAS := Vector2i(112, 128)
const BAND_Y := 48
const CELL := 16
const ROW_FLAME := 0
const ROW_FLAME_SMALL := 1
const ROW_GLASS_LAMP := 2
const ROW_GLASS_LANTERN := 3
## A wall torch's iron bracket (round 3: no post, so at overview zoom a wall carries flames, not sticks): its cup's top
## sits at BRACKET_CUP in its cell, its stem runs to the cell's bottom.
const ROW_BRACKET := 4
const BRACKET_CUP := Vector2i(8, 11)
const BRACKET_STEM := 3
## Where a glass sits in its cell (top left), and a flame's base (the engine's flame tip) in its cell.
const GLASS_AT := Vector2i(5, 5)
const FLAME_BASE := Vector2i(8, 15)
## Per prop: its sprite (top left in the atlas, size, anchor = its ground point in the sprite), and its light point: a
## lamp's glass rect. Round 4: drawn here in code at the house art's scale (the lamp_post and lamp_house art stood two
## and a half people tall beside the houses): a street lamp a little over a person's height, a house lantern a short
## post, each a 2 px post with an arm and an unlit iron-framed glass; the lit glass is the animated band's, over it. A
## torch draws only its bracket and flame (the band).
const SPRITES := {
	Prop.LAMP: {"at": Vector2i(0, 0), "size": Vector2i(9, 22), "anchor": Vector2(1, 21), "glass": Rect2(5, 5, 3, 4)},
	Prop.LANTERN: {"at": Vector2i(12, 0), "size": Vector2i(7, 15), "anchor": Vector2(1, 14), "glass": Rect2(4, 4, 3, 3)},
}
## The props' post colours: wood and its dark outline.
const COL_POST := Color("6a3c1f")
const COL_POST_DARK := Color("2a1a10")
const FLICKER_HZ := 10.0

static var _atlas: ImageTexture
static var _material: ShaderMaterial

var look := 0
## Every prop: {prop: Prop, at: Vector2 (ground), lift: float (px up: a wall's or tower's height), host: Structure or
## null, phase: int (0..3, its flame's first frame), bare: true for a lantern hung without its post (a market stall's)}.
var props: Array[Dictionary] = []
var _lights: LightField
var _env: EnvironmentField
## Host structure instance id -> its PropNode.
var _host_nodes := {}


## A building's props, or one street lamp: one canvas item drawing every piece from the atlas.
class PropNode extends Node2D:
	## Pairs of [destination, source] rects (local px, atlas px).
	var rects: Array[Rect2] = []

	func _draw() -> void:
		var tex := TownLookDecor.atlas()
		for i in range(0, rects.size(), 2):
			draw_texture_rect_region(tex, rects[i], rects[i + 1])


## The props for `town` (its built structures and City.current()), in a stable order.
static func plan(town: Town) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var city := City.current()
	var areas := city.floor_areas()
	var inside: Array[Rect2] = [city.town().grow(TOWN_PAD)]
	for r: Rect2 in areas.get(&"paved", []):
		inside.append(r.grow(TOWN_PAD))
	var keep: Structure = town.citadel.keep if is_instance_valid(town.citadel) else null
	var feet: Array[Rect2] = []
	var taken := PackedVector2Array()
	for s in town._built:
		if not is_instance_valid(s):
			continue
		if s.kind != Structure.Kind.FARM_FIELD:
			feet.append(s.footprint)
		if s.kind == Structure.Kind.TORCH:
			taken.append(s.footprint.get_center())
	var own_lamps := PackedVector2Array()
	for d in town._decor:
		if is_instance_valid(d):
			taken.append(d.at)
			if not TownPools.lamp_pool(d).is_empty():
				own_lamps.append(d.at)
	var roads: Array = city.roads()
	var day: bool = town.look == Town.Look.DAY
	var mains: Array[Rect2] = []
	for r: Rect2 in roads:
		if minf(r.size.x, r.size.y) >= MAIN_ROAD:
			mains.append(r)
	# DAY's lit ground: the squares and the main avenues.
	var squares: Array[Rect2] = []
	squares.assign(areas.get(&"plazas", []))
	squares.append_array(mains)
	# Wall walks (NIGHT only).
	for s in town._built:
		if not is_instance_valid(s) or s == keep:
			continue
		if s.kind == Structure.Kind.CASTLE_WALL and not day:
			_wall_torches(out, s)
	# A lantern by every house (a farmhouse too), and by every market stall, church and barracks inside the town, on its
	# face toward the nearest street.
	for s in town._built:
		if not is_instance_valid(s) or not s.kind in LANTERN_KINDS 				or (s.kind != Structure.Kind.HOUSE and not _in(inside, s.footprint.get_center())):
			continue
		if day and (s.kind == Structure.Kind.MARKET_STALL or s.kind == Structure.Kind.HOUSE 				and not _hits(squares, s.footprint.get_center(), DAY_NEAR + s.footprint.size.length() * 0.5)):
			continue
		if s.kind == Structure.Kind.MARKET_STALL:
			# A stall's lantern hangs from its awning's front corner: its glass alone, no post (the market is busy enough).
			_put(out, Prop.LANTERN, s.footprint.end, s.height, s)
			out[out.size() - 1].bare = true
			continue
		var g := _lantern_spot(s.footprint, roads, out.size())
		if _near(own_lamps, g, LANTERN_GAP):
			continue
		_put(out, Prop.LANTERN, g, 0.0, s)
		taken.append(g)
	# Street lamps along both sides of every road, then round every square.
	var spots: Array[Vector2] = []
	var step := DAY_LAMP_STEP if day else LAMP_STEP
	for r: Rect2 in (mains if day else roads):
		var along_x := r.size.x >= r.size.y
		var a0 := r.position.x if along_x else r.position.y
		var a1 := r.end.x if along_x else r.end.y
		for side in 2:
			var across := (r.position.y - LAMP_OUT if side == 0 else r.end.y + LAMP_OUT) if along_x \
				else (r.position.x - LAMP_OUT if side == 0 else r.end.x + LAMP_OUT)
			var k := ceili(a0 / step - (0.25 + 0.5 * side))
			while (k + 0.25 + 0.5 * side) * step < a1:
				var u := (k + 0.25 + 0.5 * side) * step
				spots.append(Vector2(u, across) if along_x else Vector2(across, u))
				k += 1
	for p: Rect2 in areas.get(&"plazas", []):
		var r := p.grow(-LAMP_IN)
		var corners: Array[Vector2] = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for e in 4:
			var a: Vector2 = corners[e]
			var b: Vector2 = corners[(e + 1) % 4]
			var n := maxi(int(a.distance_to(b) / step), 1)
			for i in n:
				spots.append(a.lerp(b, (i + 0.5) / n))
	var water: Array[Rect2] = city.rivers()
	for g in spots:
		if not _in(inside, g) or _hits(feet, g, FOOT_CLEAR) or _hits(water, g, 0.3) or _hits_roads(roads, g) \
				or _near(taken, g, CLEAR) or _hits(town.keep_clear, g, 0.0):
			continue
		_put(out, Prop.LAMP, g, 0.0, null)
		taken.append(g)
	return out


static func _wall_torches(out: Array[Dictionary], s: Structure) -> void:
	var r := s.footprint
	var along_x := r.size.x >= r.size.y
	var a0 := r.position.x if along_x else r.position.y
	var a1 := r.end.x if along_x else r.end.y
	var mid := r.get_center()
	var k := ceili(a0 / TORCH_STEP - 0.5)
	while (k + 0.5) * TORCH_STEP < a1:
		var u := (k + 0.5) * TORCH_STEP
		_put(out, Prop.TORCH, Vector2(u, mid.y) if along_x else Vector2(mid.x, u), s.height, s)
		k += 1


## A house's lantern: LANTERN_OUT off whichever of its two front faces (+x or +y, the ones the view sees) looks more
## toward the nearest road, somewhere along the middle of that face.
static func _lantern_spot(f: Rect2, roads: Array, salt: int) -> Vector2:
	var c := f.get_center()
	var best := Vector2.INF
	for r: Rect2 in roads:
		var q := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
		if best == Vector2.INF or c.distance_squared_to(q) < c.distance_squared_to(best):
			best = q
	var d := best - c if best != Vector2.INF else Vector2(0, 1)
	var t := 0.35 + 0.3 * ArtKit.hash01(int(f.position.x * 97.0) * 31 + int(f.position.y * 89.0), salt % 7)
	if d.x > d.y:
		return Vector2(f.end.x + LANTERN_OUT, lerpf(f.position.y, f.end.y, t))
	return Vector2(lerpf(f.position.x, f.end.x, t), f.end.y + LANTERN_OUT)


static func _put(out: Array[Dictionary], prop: Prop, at: Vector2, lift: float, host: Structure) -> void:
	out.append({"prop": prop, "at": at, "lift": lift, "host": host, "phase": posmod(out.size() * 7 + 3, 4)})


static func _in(rects: Array[Rect2], g: Vector2) -> bool:
	for r in rects:
		if r.has_point(g):
			return true
	return false


static func _hits(rects: Array[Rect2], g: Vector2, margin: float) -> bool:
	for r in rects:
		if r.grow(margin).has_point(g):
			return true
	return false


static func _hits_roads(roads: Array, g: Vector2) -> bool:
	for r: Rect2 in roads:
		if r.has_point(g):
			return true
	return false


static func _near(pts: PackedVector2Array, g: Vector2, d: float) -> bool:
	for p in pts:
		if p.distance_squared_to(g) < d * d:
			return true
	return false


## The shared atlas: the three prop sprites, then the flames' and glasses' four frames each (Structure's flame and lamp
## glass drawing: its colours and shapes), built once.
static func atlas() -> ImageTexture:
	if _atlas != null:
		return _atlas
	var img := Image.create(ATLAS.x, ATLAS.y, false, Image.FORMAT_RGBA8)
	for k: int in SPRITES:
		var sp: Dictionary = SPRITES[k]
		_post(img, sp)
	var fl: Array = Structure.COL_FLAME
	for f in 4:
		var step: int = [0, 1, 2, 1][f]
		var o := Vector2i(f * CELL, BAND_Y + ROW_FLAME * CELL) + FLAME_BASE
		# Structure._draw_post_flame()'s torch flame (unused since round 4: every prop burns the small one).
		_fill(img, o, Rect2i(-4, -5, 8, 5), fl[2])
		_fill(img, o, Rect2i(-3, -9 - step % 2, 6, 7), fl[1])
		_fill(img, o, Rect2i(-2 + (step % 2), -12 - step, 3, 6), fl[0])
		_fill(img, o, Rect2i(-1, -7, 2, 3), Color.WHITE)
		# Structure._draw_flame()'s small flame (a wall torch's, the art's own torch flames' size).
		o = Vector2i(f * CELL, BAND_Y + ROW_FLAME_SMALL * CELL) + FLAME_BASE
		_fill(img, o, Rect2i(-2, -3, 4, 3), fl[2])
		_fill(img, o, Rect2i(-1, -5 - step % 2, 3, 4), fl[1])
		_fill(img, o, Rect2i(-1 + (step % 2), -7 - step, 1, 3), fl[0])
		# The glasses: Structure.draw_lamp_glass() (a lamp post's, with its bar) and lamp_glass.gdshader (a lantern's).
		for row in [ROW_GLASS_LAMP, ROW_GLASS_LANTERN]:
			var g: Rect2 = SPRITES[Prop.LAMP if row == ROW_GLASS_LAMP else Prop.LANTERN].glass
			var gs := Vector2i(g.size)
			o = Vector2i(f * CELL, BAND_Y + row * CELL) + GLASS_AT
			_fill(img, o, Rect2i(Vector2i.ZERO, gs), fl[2] if f == 0 else fl[1])
			_fill(img, o, Rect2i(Vector2i.ONE, gs - Vector2i(2, 2)), fl[0])
		# A wall torch's bracket: a small iron cup on a short stem, the same each frame.
		o = Vector2i(f * CELL, BAND_Y + ROW_BRACKET * CELL) + BRACKET_CUP
		_fill(img, o, Rect2i(-2, 0, 4, 1), Structure.COL_IRON_CUP)
		_fill(img, o, Rect2i(0, 1, 1, BRACKET_STEM), Structure.COL_IRON_CUP.darkened(0.25))
	_atlas = ImageTexture.create_from_image(img)
	return _atlas


## A lamp's or lantern's post into the atlas at its SPRITES entry: a 2 px post from its anchor up to an arm running right
## to over its glass, a foot, and the glass's iron frame round a dark pane (unlit; NIGHT's lit glass is drawn over it).
static func _post(img: Image, sp: Dictionary) -> void:
	var o: Vector2i = sp.at
	var size: Vector2i = sp.size
	var g := Rect2i(sp.glass)
	var top := 1
	# The post and its foot.
	_fill(img, o, Rect2i(0, top, 2, size.y - top), COL_POST)
	_fill(img, o, Rect2i(1, top, 1, size.y - top), COL_POST_DARK)
	_fill(img, o, Rect2i(0, size.y - 1, 3, 1), COL_POST_DARK)
	# The arm over the glass, and the hook down to it.
	_fill(img, o, Rect2i(0, top - 1, g.end.x, 1), COL_POST_DARK)
	_fill(img, o, Rect2i(0, top, g.end.x - 1, 1), COL_POST)
	_fill(img, o, Rect2i(g.position.x + g.size.x / 2, top + 1, 1, g.position.y - top - 1), Structure.COL_IRON_CUP)
	# The glass: an iron frame round a dark pane.
	_fill(img, o, g, Structure.COL_IRON_CUP)
	_fill(img, o, g.grow(-1), Color("4a3a2a"))


static func _fill(img: Image, o: Vector2i, r: Rect2i, c: Color) -> void:
	img.fill_rect(Rect2i(o + r.position, r.size), c)


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://src/game/town/town_look_decor.gdshader")
		_material.set_shader_parameter("band_v", float(BAND_Y) / ATLAS.y)
		_material.set_shader_parameter("cell_u", float(CELL) / ATLAS.x)
		_material.set_shader_parameter("hz", FLICKER_HZ)
	return _material


## The look's settings on the shared material (round 3): at NIGHT the posts take their own lamp's warm light
## (SELF_LIT) instead of reading as black sticks; in both looks the posts fade out below POST_ZOOM (the camera's zoom),
## so at overview zoom only the flames and glasses show.
const SELF_LIT := Color(1.0, 0.66, 0.40, 0.75)
const POST_ZOOM := Vector2(0.45, 0.7)


static func _set_look(look_value) -> void:
	var m := material()
	m.set_shader_parameter("self_lit", SELF_LIT if look_value == Town.Look.NIGHT else Color(0, 0, 0, 0))
	m.set_shader_parameter("post_zoom", POST_ZOOM)


func setup(town: Town, look_value) -> TownLookDecor:
	name = "LookDecor"
	look = look_value
	y_sort_enabled = true
	_env = town._env
	_lights = _env.lights if _env != null else null
	_set_look(look_value)
	props = plan(town)
	for p in props:
		var host: Structure = p.host
		var node: PropNode
		if host != null and _host_nodes.has(host.get_instance_id()):
			node = _host_nodes[host.get_instance_id()]
		else:
			node = PropNode.new()
			node.material = material()
			node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.position = host.position + Vector2(0, SORT_AFTER) if host != null else Iso.ground_to_screen(p.at)
			add_child(node)
			if host != null:
				_host_nodes[host.get_instance_id()] = node
		node.rects.append_array(_rects(p, node.position))
	if _env != null:
		_env.structure_destroyed.connect(_on_destroyed)
		_env.structure_restored.connect(_on_restored)
		_env.structure_removed.connect(_on_removed)
	return self


## A prop's sprite and its flame or glass, as [destination, source] rect pairs local to a node at `origin`.
func _rects(p: Dictionary, origin: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var cell := Vector2(CELL, CELL)
	var col := float(int(p.phase) * CELL)
	if p.prop == Prop.TORCH:
		# Round 3: a bracket, no post (a post read as a black stick at overview zoom). NIGHT burns a flame on its cup;
		# DAY's torches are unlit. Round 4: the small flame, the art's own torch flames' size.
		var foot := (Iso.ground_to_screen(p.at) - Vector2(0, p.lift) - origin).round()
		var cup := foot - Vector2(0, CELL - BRACKET_CUP.y)
		out.append_array([Rect2(cup - Vector2(BRACKET_CUP), cell), Rect2(Vector2(col, BAND_Y + ROW_BRACKET * CELL), cell)])
		if look == Town.Look.NIGHT:
			out.append_array([Rect2(cup + Vector2(0, 1) - Vector2(FLAME_BASE), cell),
				Rect2(Vector2(col, BAND_Y + ROW_FLAME_SMALL * CELL), cell)])
		return out
	var sp: Dictionary = SPRITES[p.prop]
	var g: Rect2 = sp.glass
	var top := (Iso.ground_to_screen(p.at) - Vector2(0, p.lift) - (sp.anchor as Vector2) - origin).round()
	if p.get("bare", false):
		# Its glass alone, hanging just under the point it is given.
		top = (Iso.ground_to_screen(p.at) - Vector2(0, p.lift) - g.position - origin).round()
	else:
		out.append_array([Rect2(top, Vector2(sp.size)), Rect2(Vector2(sp.at), Vector2(sp.size))])
	var row := ROW_GLASS_LAMP if p.prop == Prop.LAMP else ROW_GLASS_LANTERN
	out.append_array([Rect2(top + g.position - Vector2(GLASS_AT), cell), Rect2(Vector2(col, BAND_Y + row * CELL), cell)])
	return out


## Every prop's light for the light map (TownPools.pools_for()): {pos (world screen px), radius, color, flicker, alpha,
## structure (its host, so its pool hides while the host is down; null for a street lamp)}.
func lights() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in props:
		if not lit(p):
			continue
		var l: Dictionary = LIGHT[p.prop]
		var host: Structure = p.host
		# A house's (church's, barracks') lantern lights its front too (round 3, TownPools.face_of()).
		var bare: bool = p.get("bare", false)
		var face := TownPools.face_of(host) if p.prop == Prop.LANTERN and not bare and host != null \
			and host.kind in TownPools.FACE_KINDS else PackedVector2Array()
		# A stall's bare lantern is a point: a small pool on its counter (round 4: the market read as one lit sheet).
		out.append({"pos": Iso.ground_to_screen(p.at) - Vector2(0, p.lift), "radius": BARE_RADIUS if bare else l.radius,
			"color": Structure.TORCH_LIGHT, "flicker": l.flicker, "alpha": BARE_ALPHA if bare else l.alpha, "structure": host,
			"look_decor": true, "face": face})
	return out


## Whether prop `p` burns: DAY's wall torches are unlit (round 3).
func lit(p: Dictionary) -> bool:
	return not (look == Town.Look.DAY and p.prop == Prop.TORCH)


## How many props of kind `prop`.
func count(prop: Prop) -> int:
	var n := 0
	for p in props:
		if p.prop == prop:
			n += 1
	return n


## The props' canvas items (one per building that carries some, one per street lamp).
func prop_nodes() -> Array[Node]:
	return get_children()


func _process(_delta: float) -> void:
	# Lit as the decor layer is (Town.DecorLayer): the ambient light and its tint.
	var a := _lights.ambient if _lights else 1.0
	var t := _lights.tint if _lights else Color.WHITE
	var m := Color(a * t.r, a * t.g, a * t.b)
	if not modulate.is_equal_approx(m):
		modulate = m


func _exit_tree() -> void:
	if is_instance_valid(_env):
		for pair: Array in [[_env.structure_destroyed, _on_destroyed], [_env.structure_restored, _on_restored],
				[_env.structure_removed, _on_removed]]:
			if (pair[0] as Signal).is_connected(pair[1]):
				(pair[0] as Signal).disconnect(pair[1])


func _show_host(s: Structure, shown: bool) -> void:
	var n: PropNode = _host_nodes.get(s.get_instance_id())
	if is_instance_valid(n):
		n.visible = shown


func _on_destroyed(s: Structure, _kind = null) -> void:
	_show_host(s, false)


func _on_restored(s: Structure) -> void:
	_show_host(s, true)


func _on_removed(s: Structure) -> void:
	_show_host(s, false)
