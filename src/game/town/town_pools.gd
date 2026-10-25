class_name TownPools
extends Node
## The light map of the DAY and NIGHT looks (Town.Look): one warm pool of light round every wall torch (LightField's
## static lights, read only), every decor lamp (read from the town's decor) and in front of every standing building that
## has lit windows (its sprite set's glow_mask). The pools are not drawn on the screen: they are drawn into a small
## light buffer (a SubViewport at half the game's resolution that follows the camera), and the colour grade multiplies
## the world by it (TownGrade: lit = base * (ambient + light)), so a wall, a roof or a person near a lamp turns warm while
## its own dark side stays dark. Nothing is registered in LightField.
## Every pool is one rect in a single draw node in the buffer (one draw call): the shared pool texture, additive. The
## flicker is re-read ten times a second, a pool hides on the event that puts its light out (a structure destroyed, a lamp
## knocked down), and pools outside the view are skipped, so the node redraws only when something changed.

## The light buffer's resolution against the game's (half).
const BUFFER_SCALE := 0.5
## The pool texture's size: a 2:1 ellipse with a smooth falloff to its edge (TownGrade cuts it into dithered steps of
## world pixels, so it never shows rings).
const TEX := Vector2i(96, 48)
## A torch's pool, against its light's radius in screen pixels (the light's own falloff reaches further).
const TORCH_REACH := 1.0
## A torch pool's strength (its light's flicker scales it).
const TORCH_ALPHA := 0.8
const WINDOW_COLOUR := Color(1.0, 0.72, 0.34)
## A window pool's strength: a little gentler than a torch's (0.5).
const WINDOW_ALPHA := 0.7
## Window pool radius (screen px, x semi-axis): per lit pixel, clamped to this range.
const WINDOW_MIN := 22.0
const WINDOW_MAX := 64.0
## A decor lamp's pool (a house lantern, a lamp post, anything with a "glow" in the decor manifest): the radius (screen px,
## x semi-axis; its own light quad is 23) and strength.
const LAMP_RADIUS := 48.0
const LAMP_ALPHA := 0.5
## Decor sets that are lamps whether or not the manifest gives them a "glow".
const LAMP_SETS := ["lamp_post", "lamp_house"]

## A pool's scale snaps to this step so the four bands stay even (96 * k and 48 * k are whole pixels).
const SCALE_STEP := 1.0 / 48.0
## The light on what stands round a pool: a second, rounder pool WALL_W as wide and WALL_H as tall, raised WALL_RISE of
## the ground pool's height, at WALL_ALPHA of its strength.
const WALL_W := 0.7
const WALL_H := 1.5
const WALL_RISE := 1.0
const WALL_ALPHA := 0.6
## A window's light up its own front, out of 255 (it mostly lights the street).
const WINDOW_WALL := 255
## Flicker is re-read this often (seconds).
const FLICKER_STEP := 0.1

static var _texture: ImageTexture
static var _lit_cache := {}

## Static facts per pool: {flicker: float, light: Dictionary or null, structure, decor, alpha: float, i: int}.
var _pools: Array[Dictionary] = []
## Per pool, parallel to _pools: the rect's top-left and size (world px), its colour (alpha = the live strength), shown.
var _tl := PackedVector2Array()
var _sz := PackedVector2Array()
var _col := PackedColorArray()
var _on := PackedByteArray()
## Per pool: how much it lights what stands round it, 0..255 (a torch or a lamp fully; a window its own front a little).
var _wall := PackedByteArray()
var _canvas: PoolCanvas
## The light buffer every pool is drawn into; TownGrade reads its texture.
var buffer: SubViewport
var _env: EnvironmentField
var _time := 0.0
var _since := 0.0
var _seen_view := Rect2()
## How many times the pools were redrawn (for tests).
var redraws := 0


## The one node every pool draws on: additive, linear filtered (the buffer is smooth; the grade steps it).
class PoolCanvas extends Node2D:
	var owner_pools: TownPools

	func _draw() -> void:
		owner_pools._paint(self)


## The pool texture, built once: white, its alpha a smooth falloff (1 - d)^2.5 out to the ellipse's edge.
static func texture() -> ImageTexture:
	if _texture != null:
		return _texture
	var img := Image.create(TEX.x, TEX.y, false, Image.FORMAT_RGBA8)
	for y in TEX.y:
		for x in TEX.x:
			var d := Vector2((x + 0.5) / TEX.x * 2.0 - 1.0, (y + 0.5) / TEX.y * 2.0 - 1.0).length()
			var a := pow(maxf(1.0 - d, 0.0), 2.5)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_texture = ImageTexture.create_from_image(img)
	return _texture


## A set without a glow mask lights the street only with at least this many lit pixels painted in.
const ART_MIN := 8


## A building's lit window pixels: its glow mask's (red above one half), or for a set without a mask the pixels of its
## intact still that the sprite shader already lets glow (lit_art_pixels(); at least ART_MIN, on a windowed kind or a
## gate), or 0.
static func window_pixels(s: Structure) -> int:
	if not (s.sprite is Dictionary) or (s.sprite as Dictionary).is_empty():
		return 0
	var mask: Texture2D = SpriteArt.window_mask(s.sprite)
	if mask != null:
		return lit_pixels(mask)
	# Only a building with windows (or a gatehouse): an orchard's fruit or a vineyard's grapes are bright and warm too.
	if not (s.kind in Structure.WINDOWED or s.kind == Structure.Kind.GATE):
		return 0
	var stills: Dictionary = s.sprite.get("stills", {})
	var n := lit_art_pixels(stills.get(&"intact"))
	return n if n >= ART_MIN else 0


## The pixels of a still the sprite shader's glows() rule lights (a lit window or a fire painted in: warm, very bright,
## strongly saturated), cached by texture instance. tools/dev/check_sprite_glow.py and structure_sprite.gdshader hold
## the same rule.
static func lit_art_pixels(still: Texture2D) -> int:
	if still == null:
		return 0
	var key := -still.get_instance_id()
	if _lit_cache.has(key):
		return _lit_cache[key]
	var n := 0
	var img := still.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var mx := maxf(c.r, maxf(c.g, c.b))
				var mn := minf(c.r, minf(c.g, c.b))
				if c.a > 0.5 and c.r >= mx and mx > 0.93 and (mx - mn) / mx > 0.55 and c.g > 0.45:
					n += 1
	_lit_cache[key] = n
	return n


## The lit pixels of a glow mask (red above one half), cached by texture instance.
static func lit_pixels(mask: Texture2D) -> int:
	if mask == null:
		return 0
	var key := mask.get_instance_id()
	if _lit_cache.has(key):
		return _lit_cache[key]
	var n := 0
	var img := mask.get_image()
	if img != null:
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).r > 0.5:
					n += 1
	_lit_cache[key] = n
	return n


## Whether a standing decor piece is a lamp, and where its light sits (screen px, world): its set's "glow" while it draws
## from a lamp set (LAMP_SETS) or one with a "glow" key, else {} (not a lamp). Read only.
static func lamp_pool(d: Decor) -> Dictionary:
	if not is_instance_valid(d) or d.down or d.sprite_only:
		return {}
	var n := DecorSprites.name_for(d.kind, d.seed_value, d.size, d.at, true)
	if n == "":
		return {}
	var ds := DecorSprites.decor_set(n)
	var has_glow: bool = (ds.get("glow", Vector2.ZERO) as Vector2) != Vector2.ZERO or DecorSprites.manifest().get(n, {}).has("glow")
	var base := n.rstrip("0123456789").rstrip("_")
	if not has_glow and not (n in LAMP_SETS or base in LAMP_SETS):
		return {}
	var off: Vector2 = ds.get("glow", Vector2.ZERO)
	return {"pos": Iso.ground_to_screen(d.at) + off * ArtTuning.scale(d.tuning_key()) * d.scale_mul}


## Every pool of a town: {pos: Vector2 (world screen px), radius: float (x semi-axis, px), color: Color, flicker: float,
## light: the LightField entry for a torch, absent for a window}.
static func pools_for(town: Town) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var env: EnvironmentField = town._env
	if env == null:
		return out
	if env.lights != null:
		for l: Dictionary in env.lights._lights:
			if l.get("static", false):
				out.append({"pos": Iso.ground_to_screen(l.pos), "radius": Iso.radius_to_screen(l.radius).x * TORCH_REACH,
					"color": l.color, "flicker": float(l.flicker), "light": l})
	# The decor lamps (the capital's street lamps, the houses' lanterns): LightField knows none of them.
	for d: Decor in town._decor:
		var lp := lamp_pool(d)
		if lp.is_empty():
			continue
		out.append({"pos": lp.pos, "radius": LAMP_RADIUS * d.scale_mul, "color": Structure.TORCH_LIGHT, "flicker": 1.0,
			"alpha": LAMP_ALPHA, "decor": d})
	for s in env.structures():
		if not is_instance_valid(s) or s.destroyed:
			continue
		var lit := window_pixels(s)
		if lit <= 0:
			continue
		var front := Iso.ground_to_screen(s.footprint.end)
		out.append({"pos": front + Vector2(0, 3), "radius": clampf(sqrt(float(lit)) * 2.8, WINDOW_MIN, WINDOW_MAX),
			"color": WINDOW_COLOUR, "flicker": 0.5, "alpha": WINDOW_ALPHA, "structure": s})
	return out


func setup(town: Town) -> TownPools:
	name = "Pools"
	_env = town._env
	buffer = SubViewport.new()
	buffer.name = "LightBuffer"
	buffer.disable_3d = true
	buffer.transparent_bg = true
	buffer.size = Vector2i(320, 180)
	buffer.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(buffer)
	_canvas = PoolCanvas.new()
	_canvas.name = "PoolCanvas"
	_canvas.owner_pools = self
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_canvas.material = mat
	buffer.add_child(_canvas)
	for p in pools_for(town):
		# Whole-pixel size: the scale k snaps to 1/48 steps, the top-left to a pixel.
		var k := maxf(snappedf(float(p.radius) / (TEX.x * 0.5), SCALE_STEP), SCALE_STEP)
		var sz := Vector2(TEX) * k
		var c: Color = p.color
		_tl.append(((p.pos as Vector2) - sz * 0.5).round())
		_sz.append(sz)
		_col.append(Color(c.r, c.g, c.b, float(p.get("alpha", TORCH_ALPHA))))
		_on.append(1)
		# A window lights its own front a little (WINDOW_WALL), a torch or a lamp what stands round it fully.
		_wall.append(WINDOW_WALL if p.get("structure") != null else 255)
		_pools.append({"flicker": p.flicker, "light": p.get("light"), "structure": p.get("structure"), "decor": p.get("decor"),
			"alpha": float(p.get("alpha", TORCH_ALPHA)), "i": _pools.size()})
		var dc = p.get("decor")
		if dc != null:
			(dc as Decor).fell.connect(_on_lamp_fell.bind(_pools.size() - 1))
	if _env != null:
		_env.structure_destroyed.connect(_on_structure_destroyed)
		_env.structure_restored.connect(_on_structure_restored)
		_env.structure_removed.connect(_on_structure_removed)
	_refresh()
	return self


func _enter_tree() -> void:
	if not RenderingServer.frame_pre_draw.is_connected(follow_view):
		RenderingServer.frame_pre_draw.connect(follow_view)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(follow_view):
		RenderingServer.frame_pre_draw.disconnect(follow_view)
	if is_instance_valid(_env):
		for pair: Array in [[_env.structure_destroyed, _on_structure_destroyed], [_env.structure_restored, _on_structure_restored],
				[_env.structure_removed, _on_structure_removed]]:
			if (pair[0] as Signal).is_connected(pair[1]):
				(pair[0] as Signal).disconnect(pair[1])


func pool_count() -> int:
	return _pools.size()


## Whether pool i is lit (its building stands, its lamp is up).
func pool_visible(i: int) -> bool:
	return _on[i] == 1


## The centre of pool i, world px.
func pool_position(i: int) -> Vector2:
	return _tl[i] + _sz[i] * 0.5


## The live strength of pool i (what the flicker last set).
func pool_alpha(i: int) -> float:
	return _col[i].a


## The light buffer's texture (what TownGrade multiplies the world by).
func light_texture() -> Texture2D:
	return buffer.get_texture()


## The buffer follows the game's view: its size is the view's times BUFFER_SCALE, and its canvas transform is the view's
## scaled down, so a pool sits under the same world pixels it lights. Run just before each frame is drawn, after the
## camera has moved.
func follow_view() -> void:
	if not is_inside_tree() or buffer == null:
		return
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var want := Vector2i(maxi(int(size.x * BUFFER_SCALE), 1), maxi(int(size.y * BUFFER_SCALE), 1))
	if buffer.size != want:
		buffer.size = want
	var k := Vector2(want) / size
	buffer.canvas_transform = Transform2D().scaled(k) * vp.canvas_transform


## The draw node (for tests).
func canvas() -> Node2D:
	return _canvas


func _on_lamp_fell(i: int) -> void:
	if _on[i] == 1:
		_on[i] = 0
		_canvas.queue_redraw()


func _on_structure_destroyed(s: Structure, _kind = null) -> void:
	_set_structure(s, 0)


func _on_structure_restored(s: Structure) -> void:
	_set_structure(s, 1)


func _on_structure_removed(s: Structure) -> void:
	_set_structure(s, 0)


func _set_structure(s: Structure, shown: int) -> void:
	var changed := false
	for p in _pools:
		if p.structure == s and _on[p.i] != shown:
			_on[p.i] = shown
			changed = true
	if changed:
		_canvas.queue_redraw()


## The live strength of pool p now.
func _strength(p: Dictionary) -> float:
	var base: float = p.alpha
	var l = p.light
	if l != null:
		return base * clampf(float(l.intensity) / maxf(float(l.base), 0.001), 0.0, 1.2)
	var f: float = p.flicker
	var i: int = p.i
	return base * (1.0 - f * 0.25 + f * 0.25 * sin(_time * 5.0 + i * 2.3) * sin(_time * 3.1 + i))


## Re-read every pool's flicker; true when one changed enough to show.
func _refresh() -> bool:
	var changed := false
	for p in _pools:
		var a := _strength(p)
		var i: int = p.i
		if absf(_col[i].a - a) > 0.01:
			_col[i].a = a
			changed = true
	return changed


func _process(delta: float) -> void:
	_time += delta
	_since += delta
	var redraw := false
	if _since >= FLICKER_STEP:
		_since = 0.0
		redraw = _refresh()
	if Structure.view != _seen_view:
		_seen_view = Structure.view
		redraw = true
	if redraw:
		_canvas.queue_redraw()


## The pools a paint draws: lit and inside the view (all lit ones while no view is known).
func drawn_indices() -> PackedInt32Array:
	var out := PackedInt32Array()
	var culled := _seen_view.has_area()
	for i in _tl.size():
		if _on[i] != 0 and (not culled or _seen_view.intersects(Rect2(_tl[i], _sz[i]))):
			out.append(i)
	return out


func _paint(c: CanvasItem) -> void:
	redraws += 1
	var tex := texture()
	for i in drawn_indices():
		var r := Rect2(_tl[i], _sz[i])
		c.draw_texture_rect(tex, r, false, _col[i])
		# The light up the walls: a rounder, fainter pool rising from the ground one, so the faces, roofs and people
		# standing over the lit ground take the light too, not the paving alone.
		var col := _col[i]
		col.a *= WALL_ALPHA * _wall[i] / 255.0
		c.draw_texture_rect(tex, Rect2(r.position + Vector2(r.size.x * (1.0 - WALL_W) * 0.5, -r.size.y * WALL_RISE),
			Vector2(r.size.x * WALL_W, r.size.y * WALL_H)), false, col)
