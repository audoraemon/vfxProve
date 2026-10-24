class_name TownPools
extends CanvasLayer
## The warm light pools of the NIGHT look (Town.Look): one additive stepped ellipse of light on the ground under every
## wall torch (LightField's static lights, read only) and in front of every standing building that has lit windows (its
## sprite set's glow_mask). They sit above the colour grade, so lamplight is what the grade did not darken, and under
## Battlefield's glow layer. The layer follows the viewport, so the pools are world-space: they pan and scale with the
## art, and their bands are world pixels. Torch pools flicker with their light; nothing is registered in LightField.

## One above the grade (TownGrade.LAYER), under Battlefield's glow layer.
const LAYER := 2
## The band texture's size: a 2:1 ellipse, four hard bands.
const TEX := Vector2i(96, 48)
const BAND_EDGES := [0.34, 0.58, 0.80, 1.0]
const BAND_ALPHA := [1.0, 0.62, 0.34, 0.14]
## A torch's pool, against its light's radius in screen pixels (the light's own falloff reaches further).
const TORCH_REACH := 0.72
const WINDOW_COLOUR := Color(1.0, 0.72, 0.34)
## Window pool radius (screen px, x semi-axis): per lit pixel, clamped.
## A window pool's strength: gentler than a torch's (0.5).
const WINDOW_ALPHA := 0.3
const WINDOW_MIN := 14.0
const WINDOW_MAX := 40.0

static var _texture: ImageTexture
static var _lit_cache := {}

## [{sprite: Sprite2D, base: float, flicker: float, light: Dictionary or null}]
var _pools: Array[Dictionary] = []
var _time := 0.0


## The band texture, built once: alpha steps in four bands out to the ellipse's edge, white.
static func texture() -> ImageTexture:
	if _texture != null:
		return _texture
	var img := Image.create(TEX.x, TEX.y, false, Image.FORMAT_RGBA8)
	for y in TEX.y:
		for x in TEX.x:
			var d := Vector2((x + 0.5) / TEX.x * 2.0 - 1.0, (y + 0.5) / TEX.y * 2.0 - 1.0).length()
			var a := 0.0
			for i in BAND_EDGES.size():
				if d < BAND_EDGES[i]:
					a = BAND_ALPHA[i]
					break
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_texture = ImageTexture.create_from_image(img)
	return _texture


## The lit pixels of a glow mask (red above one half), cached by texture.
static func lit_pixels(mask: Texture2D) -> int:
	if mask == null:
		return 0
	var key := mask.get_rid()
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
	for s in env.structures():
		if not is_instance_valid(s) or s.destroyed:
			continue
		var mask: Texture2D = s.sprite.get("glow_mask") if s.sprite is Dictionary else null
		if mask == null:
			continue
		var lit := lit_pixels(mask)
		if lit <= 0:
			continue
		var front := Iso.ground_to_screen(s.footprint.end)
		out.append({"pos": front + Vector2(0, 3), "radius": clampf(sqrt(float(lit)) * 2.2, WINDOW_MIN, WINDOW_MAX),
			"color": WINDOW_COLOUR, "flicker": 0.5, "alpha": WINDOW_ALPHA, "structure": s})
	return out


func setup(town: Town) -> TownPools:
	name = "Pools"
	layer = LAYER
	follow_viewport_enabled = true
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for p in pools_for(town):
		var sp := Sprite2D.new()
		sp.texture = texture()
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.material = mat
		sp.position = (p.pos as Vector2).round()
		var k: float = float(p.radius) / (TEX.x * 0.5)
		sp.scale = Vector2(k, k)
		var c: Color = p.color
		sp.modulate = Color(c.r, c.g, c.b, float(p.get("alpha", 0.5)))
		add_child(sp)
		_pools.append({"sprite": sp, "flicker": p.flicker, "light": p.get("light"), "structure": p.get("structure"), "alpha": float(p.get("alpha", 0.5)),
			"i": _pools.size()})
	return self


func pool_count() -> int:
	return _pools.size()


func pool_sprite(i: int) -> Sprite2D:
	return _pools[i].sprite


func _process(delta: float) -> void:
	_time += delta
	for p in _pools:
		var base: float = p.alpha
		var a := base
		var l = p.light
		if l != null:
			a = base * clampf(float(l.intensity) / maxf(float(l.base), 0.001), 0.0, 1.2)
		else:
			var f: float = p.flicker
			var i: int = p.i
			a = base * (1.0 - f * 0.25 + f * 0.25 * sin(_time * 5.0 + i * 2.3) * sin(_time * 3.1 + i))
		var sp: Sprite2D = p.sprite
		# A window's pool goes out with its building.
		var st = p.structure
		if st != null:
			sp.visible = is_instance_valid(st) and not st.destroyed
		if absf(sp.modulate.a - a) > 0.01:
			sp.modulate.a = a
