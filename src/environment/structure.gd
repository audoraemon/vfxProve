class_name Structure
extends Node2D
## Destructible iso building/prop drawn as a lit pixel box. Faces pick up light from the LightField
## on the side facing each light. Damage scorches and cracks it; destruction collapses it into
## rubble with dust and debris, reacting to the damage type (blast, beam cut, gravity).

## Emitted once, when the building is destroyed by any cause.
signal broken(s: Structure)

enum Kind {
	TOWER, BLOCK, WALL, CRATES, KEEP, CASTLE_WALL, HOUSE, TORCH,
	TEMPLE, BARRACKS, MARKET_STALL, GATE, BRIDGE, FARM_FIELD, TREE, FOUNTAIN,
}

const RUBBLE_H := 5.0
const COLLAPSE_TIME := 0.8
const COL_CHAR := Color("141112")
const COL_WINDOW := [Color("ffcf7a"), Color("9fe8ff"), Color("ffb060")]
const COL_WINDOW_OFF := Color("1b1f28")
const COL_MOLTEN := Color("ffb040")
const COL_GOLD := Color("d8b23a")
const COL_BEAM := Color("3a2a1e")
const COL_FLAME := [Color("fff0b0"), Color("ffb040"), Color("ff6a1a")]
const COL_IRON_CUP := Color("3a3230")
## A street lamp's post height, px (the reference's lamps stand about twice a person's height).
const LAMP_H := 34.0
const TORCH_LIGHT := Color(1.0, 0.55, 0.22)
## Seconds a dropped banner takes to fall and fade.
const BANNER_FALL_TIME := 1.0
## The shake jitter is re-rolled this many times a second instead of every frame. A 1-2 px pixel-art shudder
## reads the same, and a shaking building stops rebuilding its whole drawing sixty times a second.
const SHAKE_HZ := 15.0
## How often a quiet building re-checks its light bucket, the way DummyEnemy.LIGHT_HZ throttles units. An
## animating building (shaking, collapsing, molten) always keeps its signature current every frame regardless
## (see _process), so this only trims the ~142-structure cost while nothing is happening to them.
const LIGHT_HZ := 20.0
## Kinds with lit windows; the fantasy ones get framed windows (houses) or arrow slits (keeps).
const WINDOWED := [Kind.TOWER, Kind.BLOCK, Kind.KEEP, Kind.HOUSE, Kind.TEMPLE, Kind.BARRACKS]
const FANTASY_WINDOWS := [Kind.KEEP, Kind.HOUSE, Kind.TEMPLE, Kind.BARRACKS]
## Drawn by the art classes (src/environment/art) while they stand; the rest keep the plain lit box.
const ART_KINDS := [Kind.HOUSE, Kind.KEEP, Kind.CASTLE_WALL, Kind.GATE, Kind.TEMPLE, Kind.BARRACKS,
	Kind.MARKET_STALL, Kind.BRIDGE, Kind.FARM_FIELD, Kind.TREE, Kind.FOUNTAIN]
## Lights the art's unlit geometry (see ArtKit); the rest of a structure's drawing passes through it untouched.
const ART_SHADER := preload("res://src/environment/art/structure_art.gdshader")
## Units walk over these while they stand.
const WALKABLE := [Kind.GATE, Kind.BRIDGE, Kind.FARM_FIELD]
## Flat things people walk on. They are drawn under every person whatever their sort key says: a bridge sorts
## by its far corner, and drew over everyone crossing it.
const FLAT := [Kind.BRIDGE, Kind.FARM_FIELD]
## Nothing to crack on these.
const NO_CRACKS := [Kind.FARM_FIELD, Kind.TREE]
## Light buckets the redraw signature quantizes to. Faces are always shaded from the exact sampled
## light; these only decide how far the light has to move before a building rebuilds its drawing.
const SIG_COLOR_STEPS := 48.0
const SIG_DIR_STEPS := 8.0
## Scratch buffers for _quad(); canvas drawing is single-threaded, so one shared pair is enough.
static var _no_uv := PackedVector2Array()
static var _quad_cols := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])

var kind := Kind.BLOCK
var footprint := Rect2()
var max_height := 60.0
var height := 60.0
var max_hp := 100.0
var hp := 100.0
var destroyed := false
var scorch := 0.0
var lights: LightField
## Overhead layer for debris/sparks, and the back layer for dust and smoke. Null in headless tests.
var fx_parent: Node
var fx_back: Node
var rng := RandomNumberGenerator.new()
## Game role for rules and scoring (&"house", &"citadel", ...); empty in the sandbox.
var role := &""
## Units walk over it while it stands (gates, the bridge, fields).
var walkable := false
## Art plan from setup(): pure data hashed from the seed (ArtKit.plan_for), empty for kinds without art.
var art := {}
## The last art drawing and what it was drawn for (_art_key_now()); replayed until its geometry changes.
var _art_cache: Array = []
var _art_key := 0
## Picks a variant of the kind's art: &"keep" (the Citadel keep's flag), &"gate" (the Citadel's gateway),
## &"tavern" and &"smithy" (houses), &"lamp" (a street lamp instead of a torch).
var art_tag := &""
## Optional owner of this building's health: func(s: Structure, amount: float, source: Vector2, kind: StringName).
## When set, damage() hands every hit to it instead of lowering hp (the Citadel's damage budget).
var damage_filter := Callable()

var _collapse := -1.0
var _collapse_from := 0.0
## What damage kind brought it down (empty while it stands).
var destroy_kind := &""
var _shake := 0.0
var _time := 0.0
var _windows: Array = []
var _cracks: Array[PackedVector2Array] = []
var _rubble: Array = []
var _top_piece := {}
var _molten := 0.0
var _burning := false
var _s: Array[Vector2] = []
var _emitters: Array[PixelParticles] = []
## LightField id for torches (0 = none).
var light_id := 0
## Ice coating 0..1 from frost effects.
var frost := 0.0
var _glow: QuadFx
var _banner: Node2D
## A wall torch's flame, on its own node so the wall piece under it stays cached.
var _flame: Node2D
var _flame_step := -1
## Last drawn light state; redraw only when it changes or something animates.
var _drawn_sig := -1
## One-shot "redraw once" flag: set it when something changed the drawing (a hit, a crack, a collapse start).
## A state that animates every frame belongs in `_process`'s `animating` expression instead — this is cleared
## after the next redraw.
var _dirty := true
## Seconds since drop_banner() (-1 = the banner still hangs).
var _banner_fall := -1.0
## Which SHAKE_HZ step the current jitter belongs to (-1 = not shaking).
var _shake_step := -1
## Last drawn banner state, the same idea as _drawn_sig for the keep's banner.
var _banner_sig := -1
## Seconds until the next quiet-frame light check (staggered per-instance so all ~142 do not land on one frame).
var _light_in := 0.0


func setup(rect: Rect2, h: float, k: Kind, seed_value: int, role_value := &"", tag_value := &"") -> Structure:
	role = role_value
	art_tag = tag_value
	footprint = rect
	max_height = h
	height = h
	kind = k
	rng.seed = seed_value
	max_hp = {Kind.TOWER: 160.0, Kind.BLOCK: 110.0, Kind.WALL: 60.0, Kind.CRATES: 30.0,
		Kind.KEEP: 180.0, Kind.CASTLE_WALL: 90.0, Kind.HOUSE: 50.0, Kind.TORCH: 10.0,
		Kind.TEMPLE: 200.0, Kind.BARRACKS: 150.0, Kind.MARKET_STALL: 25.0, Kind.GATE: 120.0,
		Kind.BRIDGE: 140.0, Kind.FARM_FIELD: 20.0, Kind.TREE: 30.0, Kind.FOUNTAIN: 80.0}[k]
	hp = max_hp
	walkable = k in WALKABLE
	z_index = -1 if k in FLAT else 0
	var g0 := rect.position
	var g2 := rect.end
	var front := Iso.ground_to_screen(g2)
	position = front
	_s = [Iso.ground_to_screen(g0) - front, Iso.ground_to_screen(Vector2(g2.x, g0.y)) - front,
		Vector2.ZERO, Iso.ground_to_screen(Vector2(g0.x, g2.y)) - front]
	if k in WINDOWED:
		_build_windows()
	# After the windows: the plan hashes the seed and must never draw from the rng stream they just used.
	art = ArtKit.plan_for(self)
	return self


func _ready() -> void:
	_light_in = float(get_instance_id() % 16) / (LIGHT_HZ * 16.0)
	if kind == Kind.KEEP:
		# The waving banners redraw on their own small node so the keep itself can stay cached.
		_banner = Node2D.new()
		_banner.draw.connect(_draw_banner)
		add_child(_banner)
	if not _flame_tips().is_empty():
		_flame = Node2D.new()
		_flame.draw.connect(_draw_flame)
		add_child(_flame)
		# A warm halo round each flame, lighting the stone and timber near it as the reference's torches do.
		for tip in _flame_tips():
			var halo := QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(44, 30))
			halo.set_param("color", TORCH_LIGHT)
			halo.set_param("falloff", 1.8)
			halo.set_param("intensity", 0.35)
			halo.set_param("flicker", 1.0)
			halo.position = tip + Vector2(0, -4)
			_flame.add_child(halo)
	if kind == Kind.TORCH:
		# Warm pool of light on the ground around the torch; sits above the dim layer so it glows at night.
		_glow = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(90, 45))
		_glow.set_param("color", TORCH_LIGHT)
		_glow.set_param("falloff", 1.6)
		_glow.set_param("intensity", 0.55)
		_glow.set_param("flicker", 1.0)
		_glow.z_as_relative = false
		_glow.z_index = -4
		add_child(_glow)


func contains(g: Vector2, margin := 0.0) -> bool:
	return footprint.grow(margin).has_point(g)


func center() -> Vector2:
	return footprint.get_center()


func distance_to(g: Vector2) -> float:
	var c := g.clamp(footprint.position, footprint.end)
	return c.distance_to(g)


func damage(amount: float, source: Vector2, damage_kind: StringName) -> void:
	if destroyed:
		return
	if damage_filter.is_valid():
		# Someone else (the Citadel) owns this building's health and decides when it falls.
		damage_filter.call(self, amount, source, damage_kind)
		return
	hp -= amount
	mark_hit(amount / max_hp, damage_kind)
	if hp <= 0.0:
		destroy(source, damage_kind)
		return
	if hp < max_hp * 0.65:
		crack()
	for w in _windows:
		if rng.randf() < 0.3:
			w[3] = false
	if (damage_kind == &"nova" or damage_kind == &"orbital") and hp < max_hp * 0.7 and not _burning:
		_burning = true
		_spawn_fire(Vector2(0, -height), 3.5)


## Hit reaction without health: scorch (or frost, for ice) by `share` of the building, and a shake.
func mark_hit(share: float, damage_kind: StringName) -> void:
	if destroyed:
		return
	_dirty = true
	if damage_kind == &"ice":
		frost = minf(frost + share * 3.0, 1.0)
	else:
		scorch = minf(scorch + share * 0.9, 1.0)
	_shake = maxf(_shake, 2.5)


## Cracks up the visible walls (once).
func crack() -> void:
	if destroyed or not _cracks.is_empty() or kind in NO_CRACKS:
		return
	_build_cracks()
	_dirty = true


func shake(amount: float) -> void:
	if not destroyed:
		_shake = maxf(_shake, amount)


## Fire and smoke on the building for `seconds`; `offset` is in px from its front corner (its position).
func ignite(offset: Vector2, seconds: float) -> void:
	_spawn_fire(offset, seconds)


func dust_burst(amount: float) -> void:
	_spawn_dust(amount)


## The banner comes loose and slides down the wall, fading (the Citadel at 20%).
func drop_banner() -> void:
	if is_instance_valid(_banner) and _banner_fall < 0.0:
		_banner_fall = 0.0


func destroy(source: Vector2, damage_kind: StringName) -> void:
	if destroyed:
		return
	destroyed = true
	_dirty = true
	hp = 0.0
	destroy_kind = damage_kind
	if damage_kind != &"ice":
		scorch = maxf(scorch, 0.6)
	for w in _windows:
		w[3] = false
	if light_id != 0 and lights != null:
		lights.remove(light_id)
		light_id = 0
	if is_instance_valid(_glow):
		_glow.queue_free()
	_fall_apart(source, damage_kind)
	broken.emit(self)


## How the building comes down: a laser slices the top off; anything else collapses into rubble with debris,
## dust and, for hot damage, fire.
func _fall_apart(source: Vector2, damage_kind: StringName) -> void:
	if kind == Kind.FARM_FIELD:
		# Crops burn flat (or freeze, or drown): no rubble, just a ruined field.
		if damage_kind == &"ice":
			frost = 1.0
		elif damage_kind != &"water":
			scorch = 1.0
			_spawn_fire(Vector2.ZERO, 2.5)
		_spawn_dust(0.4)
		return
	_build_rubble()
	if kind == Kind.TREE:
		# Felled: a stump among its leaves (the rubble), never sliced or slumped like a building.
		_spawn_dust(0.4)
		if not damage_kind in [&"gravity", &"ice", &"water", &"wind", &"stone"]:
			_spawn_fire(Vector2.ZERO, 2.0)
	elif damage_kind == &"laser" and max_height > 20.0:
		# Cut clean through: the top slides off and falls, a molten stump remains.
		var cut := clampf(max_height * 0.35, 10.0, 28.0)
		var away := (Iso.ground_to_screen(center()) - Iso.ground_to_screen(source)).normalized()
		_top_piece = {"h0": cut, "h1": max_height, "off": Vector2.ZERO, "vel": away * 55.0, "fall": 0.0, "t": 0.0}
		height = cut
		_molten = 1.0
		_spawn_sparks(Vector2(0, -cut), 26)
	else:
		_collapse = 0.0
		_collapse_from = height
		var toward := damage_kind == &"gravity"
		_spawn_debris(source, toward)
		_spawn_dust(1.0)
		if not damage_kind in [&"gravity", &"ice", &"water", &"wind", &"stone"]:
			_spawn_fire(Vector2.ZERO, 3.0)


func _process(delta: float) -> void:
	_time += delta
	_shake = move_toward(_shake, 0.0, 10.0 * delta)
	if _collapse >= 0.0 and _collapse < 1.0:
		_collapse = minf(_collapse + delta / COLLAPSE_TIME, 1.0)
		var k := _collapse * _collapse
		height = lerpf(_collapse_from, RUBBLE_H, k)
		_shake = maxf(_shake, 2.0 * (1.0 - _collapse))
		if _collapse >= 1.0:
			_spawn_dust(0.5)
	if not _top_piece.is_empty():
		_top_piece.t += delta
		_top_piece.off += _top_piece.vel * delta
		if _top_piece.t > 0.35:
			_top_piece.fall += (_top_piece.t - 0.35) * 420.0 * delta
		if _top_piece.fall > _top_piece.h0 + 4.0:
			_spawn_debris(center() - (_top_piece.vel as Vector2).normalized(), false, _top_piece.off)
			_spawn_dust(0.7, _top_piece.off)
			_top_piece = {}
	_molten = maxf(_molten - delta * 0.5, 0.0)
	if is_instance_valid(_banner):
		_banner.visible = not destroyed
		if _banner_fall >= 0.0:
			_banner_fall += delta
			_banner.position = Vector2(0, roundf(90.0 * _banner_fall * _banner_fall))
			_banner.modulate.a = clampf(1.0 - _banner_fall / BANNER_FALL_TIME, 0.0, 1.0)
			if _banner_fall >= BANNER_FALL_TIME:
				_banner.queue_free()
		else:
			_banner.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).round() * _shake if _shake > 0.2 else Vector2.ZERO
		# Sliding or jittering the banner moves the node; only its stepped wave and the light on it
		# change what it draws, so that is all it redraws for.
		var banner_sig := roundi(sin(_time * 3.0)) * 4096 + int((lights.ambient if lights else 1.0) * 48.0) * 64 \
			+ int(scorch * 48.0)
		if banner_sig != _banner_sig:
			_banner_sig = banner_sig
			_banner.queue_redraw()
	if is_instance_valid(_flame):
		_flame.visible = not destroyed
		var flame_step := int(_time * 8.0)
		if flame_step != _flame_step and not destroyed:
			_flame_step = flame_step
			_flame.queue_redraw()
	var shake_step := int(_time * SHAKE_HZ) if _shake > 0.0 else -1
	var animating := shake_step != _shake_step or (_collapse >= 0.0 and _collapse <= 1.0) \
		or not _top_piece.is_empty() or _molten > 0.0 or kind == Kind.TORCH
	_shake_step = shake_step
	# A hit sets _dirty and used to force a same-frame repaint regardless of the shake step; under Cinderfall's
	# stone rain a building can be hit again before its step advances, repainting off-cadence. While it is
	# already shaking, the pending repaint just rides the next step (still <= 1/SHAKE_HZ away); only a hit
	# with no shake in progress (the first hit, or a building that never shakes) still repaints at once.
	if animating or (_dirty and _shake <= 0.0):
		_dirty = false
		# Keep the light bucket current while animating, or the first quiet frame compares against a
		# stale one and can skip the redraw it needs.
		_drawn_sig = _light_signature()
		queue_redraw()
		return
	_light_in -= delta
	if _light_in > 0.0:
		return
	_light_in = 1.0 / LIGHT_HZ
	var sig := _light_signature()
	if sig != _drawn_sig:
		_drawn_sig = sig
		queue_redraw()


## Quantized light + ambient + blink bucket; equal signatures draw identically.
func _light_signature() -> int:
	var sig := int((lights.ambient if lights else 1.0) * 48.0)
	if lights != null:
		sig = sig * 1021 + lights.sample_signature(center(), SIG_COLOR_STEPS, SIG_DIR_STEPS)
	if kind == Kind.TOWER or kind == Kind.BLOCK:
		sig = sig * 1021 + int(_time * 8.0)
	return sig


# --- Drawing -----------------------------------------------------------------

func _palette() -> Array:
	match kind:
		Kind.WALL:
			return [Color("4d525c"), Color("3d424b"), Color("31353d")]
		Kind.CRATES:
			return [Color("6a5638"), Color("56452d"), Color("433523")]
		Kind.KEEP, Kind.CASTLE_WALL, Kind.GATE:
			return [Color("b4aca8"), Color("9f9796"), Color("7f797d")]
		Kind.HOUSE:
			return [Color("7a6a58"), Color("c8b28c"), Color("a8916c")]
		Kind.TORCH:
			return [Color("4a3a2a"), Color("3a2c20"), Color("2c2118")]
		Kind.TEMPLE:
			return [Color("a8926a"), Color("d6c08c"), Color("b49c6a")]
		Kind.BARRACKS:
			return [Color("9a9486"), Color("7e796d"), Color("656157")]
		Kind.MARKET_STALL, Kind.BRIDGE:
			return [Color("9a7a4c"), Color("7c6038"), Color("604a2c")]
		Kind.FOUNTAIN:
			return [Color("b4aca8"), Color("9f9796"), Color("7f797d")]
		Kind.FARM_FIELD:
			return [Color("c9a94f"), Color("7a5c3a"), Color("634a2f")]
		Kind.TREE:
			return [Color("6a9a3a"), Color("54803a"), Color("3e6230")]
		_:
			return [Color("3d4453"), Color("2f3542"), Color("252a34")]


func _face_color(base: Color, normal: Vector2, light: Color, dir: Vector2) -> Color:
	var facing := 0.35
	if normal != Vector2.ZERO and dir.length() > 0.001:
		facing += 0.9 * clampf(dir.normalized().dot(normal), 0.0, 1.0)
	elif normal == Vector2.ZERO:
		facing = 0.9
	var lit := Color(light.r * facing, light.g * facing, light.b * facing)
	# Soft-clip the pooled light per channel so two overlapping torch radii saturate gracefully instead of
	# summing without limit; a channel can get arbitrarily bright but never exceeds 1.0 on its own.
	lit = Color(lit.r / (1.0 + lit.r), lit.g / (1.0 + lit.g), lit.b / (1.0 + lit.b))
	var amb := lights.ambient if lights else 1.0
	# Dark materials take a strong multiplicative boost so unlit night buildings stay readable. Bright stone
	# starts with less boost, and whatever boost it gets is further scaled by its own headroom above white
	# (1.0 - luminance), so a fully lit pale-stone face keeps its masonry and crenellation detail instead of
	# clamping to a flat white slab, while torch pools still read as warm pools of light.
	var headroom := 1.0 - base.get_luminance()
	var gain := lerpf(4.0, 1.2, clampf((base.get_luminance() - 0.25) / 0.4, 0.0, 1.0)) * headroom
	var add := lerpf(0.35, 0.12, clampf((base.get_luminance() - 0.25) / 0.4, 0.0, 1.0)) * headroom
	var c := Color(
		minf(base.r * amb * (1.0 + lit.r * gain) + lit.r * add, 1.0),
		minf(base.g * amb * (1.0 + lit.g * gain) + lit.g * add, 1.0),
		minf(base.b * amb * (1.0 + lit.b * gain) + lit.b * add, 1.0))
	c = c.lerp(COL_CHAR, scorch * 0.65)
	c = c.lerp(Color(0.62, 0.78, 0.92), frost * 0.35)
	var t := lights.tint if lights else Color.WHITE
	return Color(c.r * t.r, c.g * t.g, c.b * t.b)


func _draw() -> void:
	var light := lights.sample(center()) if lights else Color.BLACK
	var dir := lights.sample_dir(center()) if lights else Vector2.ZERO
	var pal := _palette()
	var top_c := _face_color(pal[0], Vector2.ZERO, light, dir)
	var right_c := _face_color(pal[1], Vector2(1, 0), light, dir)
	var left_c := _face_color(pal[2], Vector2(0, 1), light, dir)
	var jitter := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake if _shake > 0.2 else Vector2.ZERO
	draw_set_transform(jitter.round())

	# Ground shadow toward the back (fields lie flat and cast none).
	if kind != Kind.FARM_FIELD:
		_quad(PackedVector2Array([_s[0], _s[1] + Vector2(6, -3), _s[2] + Vector2(6, -3), _s[3]]),
			Color(0, 0, 0, 0.25))

	var rubble_top := _collapse >= 0.0
	var art_drawn := not destroyed and not rubble_top and kind in ART_KINDS
	if art_drawn:
		var key := _art_key_now()
		_light_art(light, dir)
		if key != _art_key or _art_cache.is_empty():
			ArtKit.record()
			match kind:
				Kind.HOUSE:
					HouseArt.draw(self)
				Kind.TEMPLE, Kind.BARRACKS:
					CivicArt.draw(self)
				Kind.MARKET_STALL, Kind.BRIDGE, Kind.FARM_FIELD, Kind.TREE, Kind.FOUNTAIN:
					PropArt.draw(self)
				_:
					StoneArt.draw(self)
			_art_cache = ArtKit.take()
			_art_key = key
		else:
			ArtKit.replay(self, _art_cache)
	elif kind == Kind.TORCH and not destroyed:
		_draw_torch(right_c, left_c)
	elif kind == Kind.TREE:
		_draw_stump()
	else:
		_draw_box(0.0, height, top_c, right_c, left_c, rubble_top)
	if not rubble_top and kind in WINDOWED and not art_drawn:
		_draw_windows(light)
	_draw_kind_details(top_c, right_c, left_c)
	for crack in _cracks:
		var pts := PackedVector2Array()
		for p in crack:
			pts.append(Vector2(p.x, p.y * height))
		draw_polyline(pts, Color(0.05, 0.04, 0.05, 0.9), -1.0)

	if _molten > 0.0:
		var m := COL_MOLTEN
		m.a = _molten
		draw_polyline(PackedVector2Array([_s[3] + Vector2(0, -height), _s[2] + Vector2(0, -height),
			_s[1] + Vector2(0, -height)]), m, -1.0)

	if not _top_piece.is_empty():
		draw_set_transform((jitter + _top_piece.off + Vector2(0, _top_piece.fall)).round())
		_draw_box(_top_piece.h0, _top_piece.h1, top_c, right_c, left_c, false)
		draw_set_transform(Vector2.ZERO)

	if _collapse >= 1.0 or (destroyed and _top_piece.is_empty() and _collapse < 0.0):
		for r in _rubble:
			draw_colored_polygon(r[0], r[1].lerp(COL_CHAR, scorch * 0.5))
	draw_set_transform(Vector2.ZERO)


## This structure's key in ArtTuning: its kind, then its art tag ("house_tavern"), or "_barn" for a farm's house.
func tuning_key() -> String:
	var key := String(Kind.keys()[kind]).to_lower()
	if art_tag != &"":
		return key + "_" + String(art_tag)
	if kind == Kind.HOUSE and role == &"farm":
		return key + "_barn"
	return key


## Everything the art's geometry reads besides the seed: height and which windows are lit. Light, scorch and
## frost only change the shader's uniforms (_light_art), so a building rebuilds its art only when a window goes dark.
func _art_key_now() -> int:
	var lit := 0
	for i in _windows.size():
		if _windows[i][3]:
			lit |= 1 << (i % 60)
	return int(height) * 1000003 + lit


## Hand the light, ambient, scorch and frost to the art shader (created on first use).
func _light_art(light: Color, dir: Vector2) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = ART_SHADER
		material = mat
	mat.set_shader_parameter("light_col", Vector3(light.r, light.g, light.b))
	mat.set_shader_parameter("light_dir", dir)
	mat.set_shader_parameter("ambient", lights.ambient if lights else 1.0)
	mat.set_shader_parameter("scorch", scorch)
	mat.set_shader_parameter("frost", frost)
	var t := lights.tint if lights else Color.WHITE
	mat.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	var at := ArtTuning.tint(tuning_key())
	mat.set_shader_parameter("art_tint", Vector3(at.r, at.g, at.b))


func _draw_box(h0: float, h1: float, top_c: Color, right_c: Color, left_c: Color, jagged: bool) -> void:
	var b := Vector2(0, -h0)
	var t := Vector2(0, -h1)
	_quad(PackedVector2Array([_s[3] + b, _s[2] + b, _s[2] + t, _s[3] + t]), left_c)
	_quad(PackedVector2Array([_s[1] + b, _s[2] + b, _s[2] + t, _s[1] + t]), right_c)
	if jagged:
		# Broken, uneven top while collapsing / as rubble: twelve points, so not a quad.
		var top := PackedVector2Array()
		for i in 4:
			var a := _s[i] + t
			var c := _s[(i + 1) % 4] + t
			for k in 3:
				var p := a.lerp(c, k / 3.0)
				top.append(p + Vector2(0, -fposmod(sin(float(i * 7 + k) * 12.9898) * 43758.5, 5.0)))
		draw_colored_polygon(top, top_c)
	else:
		_quad(PackedVector2Array([_s[0] + t, _s[1] + t, _s[2] + t, _s[3] + t]), top_c)
	var edge := top_c.lightened(0.18)
	# Two segments rather than a polyline: thin lines batch together, a polyline is its own draw call.
	draw_line(_s[3] + t, _s[2] + t, edge, -1.0)
	draw_line(_s[2] + t, _s[1] + t, edge, -1.0)
	draw_line(_s[2] + b, _s[2] + t, right_c.lightened(0.1), -1.0)


func _build_windows() -> void:
	if kind in FANTASY_WINDOWS:
		_build_fantasy_windows()
		return
	var rows := int((max_height - 8.0) / 9.0)
	for face in [[3, 2], [1, 2]]:
		var a: Vector2 = _s[face[0]]
		var b: Vector2 = _s[face[1]]
		var cols := int(absf(b.x - a.x) / 8.0)
		for c in cols:
			for r in rows:
				var u := (c + 0.6) / float(cols)
				var v := (r * 9.0 + 7.0) / max_height
				_windows.append([face[0], u, v, rng.randf() < 0.35, rng.randi() % 3])


func _draw_windows(light: Color) -> void:
	if kind in FANTASY_WINDOWS:
		_draw_fantasy_windows(light)
		return
	for w in _windows:
		if w[2] * max_height > height - 4.0:
			continue
		var a: Vector2 = _s[w[0]]
		var p: Vector2 = a.lerp(_s[2], w[1]) + Vector2(0, -w[2] * max_height)
		var col: Color = COL_WINDOW[w[4]] if w[3] else COL_WINDOW_OFF.lerp(Color(light.r, light.g, light.b), 0.25)
		if w[3] and fmod(_time * 0.7 + w[1] * 13.0, 9.0) < 0.12:
			col = COL_WINDOW_OFF
		draw_rect(Rect2(p.round() + Vector2(-1, -2), Vector2(2, 3)), col)


func _draw_kind_details(top_c: Color, right_c: Color, left_c: Color) -> void:
	if destroyed:
		return
	var roof := _s[0].lerp(_s[2], 0.5) + Vector2(0, -height)
	match kind:
		Kind.TOWER:
			draw_rect(Rect2(roof + Vector2(-4, -4), Vector2(7, 4)), right_c.lightened(0.05))
			draw_rect(Rect2(roof + Vector2(-4, -4), Vector2(7, 1)), top_c.lightened(0.15))
			draw_line(roof + Vector2(5, 0), roof + Vector2(5, -14), left_c.lightened(0.25), -1.0)
			if fmod(_time, 1.2) < 0.5:
				draw_rect(Rect2(roof + Vector2(5, -15), Vector2.ONE), Color("ff3a2a"))
		Kind.WALL:
			# Hazard stripes along the front face.
			for i in 6:
				var u := (i + 0.5) / 6.0
				var p := _s[3].lerp(_s[2], u) + Vector2(0, -height * 0.55)
				draw_rect(Rect2(p.round(), Vector2(2, 2)), Color("c89a2a").lerp(COL_CHAR, scorch))
		Kind.CRATES:
			draw_line(_s[3].lerp(_s[2], 0.5), _s[3].lerp(_s[2], 0.5) + Vector2(0, -height), left_c.darkened(0.3), -1.0)
			draw_line(_s[1].lerp(_s[2], 0.5), _s[1].lerp(_s[2], 0.5) + Vector2(0, -height), right_c.darkened(0.3), -1.0)


## One flat-coloured convex quad. Consecutive quads drawn this way share a single draw call, while a
## polygon per face costs one each -- the town's crenellations alone were 1285 draw calls a frame.
func _quad(p: PackedVector2Array, c: Color) -> void:
	_quad_cols[0] = c
	_quad_cols[1] = c
	_quad_cols[2] = c
	_quad_cols[3] = c
	draw_primitive(p, _quad_cols, _no_uv)


## Screen position (local) of a ground point at height h.
func _gp(g: Vector2, h: float) -> Vector2:
	return Iso.ground_to_screen(g) - position + Vector2(0, -h)


func _draw_torch(right_c: Color, left_c: Color) -> void:
	if art_tag == &"lamp":
		_draw_lamp(right_c, left_c)
		return
	# A stout post with an iron cup and a fat flame, the reference's torch.
	draw_rect(Rect2(-2, -height, 4, height), left_c)
	draw_rect(Rect2(0, -height, 2, height), right_c)
	draw_rect(Rect2(-3, -2, 6, 2), left_c.darkened(0.2))
	draw_rect(Rect2(-3, -height - 2, 6, 3), COL_IRON_CUP)
	var f := int(_time * 12.0 + float(rng.seed % 5)) % 3
	draw_rect(Rect2(-3, -height - 6, 6, 4), COL_FLAME[2])
	draw_rect(Rect2(-2, -height - 9 - f % 2, 4, 5), COL_FLAME[1])
	draw_rect(Rect2(-1 + (f % 2), -height - 12 - f, 2, 4), COL_FLAME[0])


## A street lamp as in the reference: a stout post on a foot with an arm at the top, and a lantern hanging from the
## arm whose glow flickers a little.
func _draw_lamp(right_c: Color, left_c: Color) -> void:
	var post := COL_BEAM.lerp(COL_CHAR, scorch)
	var tall := LAMP_H
	draw_rect(Rect2(-2, -tall, 3, tall), post)
	draw_rect(Rect2(0, -tall, 1, tall), post.lightened(0.18))
	draw_rect(Rect2(-4, -2, 7, 2), post)
	draw_rect(Rect2(-2, -tall - 2, 12, 2), post)
	draw_rect(Rect2(1, -tall + 1, 2, 3), post)
	var f := int(_time * 6.0 + float(rng.seed % 5)) % 4
	var l := Vector2(5, -tall + 1)
	draw_rect(Rect2(l + Vector2(2, -1), Vector2(1, 2)), post)
	draw_rect(Rect2(l, Vector2(6, 8)), right_c.darkened(0.45))
	draw_rect(Rect2(l + Vector2(1, 1), Vector2(4, 6)), COL_FLAME[1] if f != 0 else COL_FLAME[2])
	draw_rect(Rect2(l + Vector2(2, 2), Vector2(2, 4)), COL_FLAME[0])
	draw_rect(Rect2(l + Vector2(-1, -1), Vector2(8, 1)), left_c.darkened(0.3))


## A felled tree's stump (its leaves are the rubble).
func _draw_stump() -> void:
	var base := _gp(center(), 0.0).round()
	draw_rect(Rect2(base + Vector2(-1, -4), Vector2(3, 4)), COL_BEAM.lerp(COL_CHAR, scorch))


func _build_fantasy_windows() -> void:
	var slits := kind == Kind.KEEP
	var rows := int((max_height - 10.0) / (16.0 if slits else 12.0))
	for face in [3, 1]:
		var a: Vector2 = _s[face]
		var cols := int(absf(_s[2].x - a.x) / (12.0 if slits else 14.0))
		for c in cols:
			for r in rows:
				var u := (c + 0.5) / float(cols)
				var v := (r * (16.0 if slits else 12.0) + 10.0) / max_height
				_windows.append([face, u, v, rng.randf() < (0.4 if slits else 0.6), 0])


func _draw_fantasy_windows(light: Color) -> void:
	var slits := kind == Kind.KEEP
	for w in _windows:
		if w[2] * max_height > height - 5.0:
			continue
		var p: Vector2 = (_s[w[0]] as Vector2).lerp(_s[2], w[1]) + Vector2(0, -w[2] * max_height)
		var lit := Color("ffb45a")
		var col: Color = lit if w[3] else Color("1a1614").lerp(Color(light.r, light.g, light.b), 0.25)
		if slits:
			draw_rect(Rect2(p.round() + Vector2(0, -4), Vector2(1, 5)), col)
		else:
			draw_rect(Rect2(p.round() + Vector2(-1, -3), Vector2(3, 3)), col)
			draw_rect(Rect2(p.round() + Vector2(-1, -3), Vector2(3, 3)), COL_BEAM, false, -1.0)


## The keep's banners (and the Citadel keep's flag), drawn by StoneArt onto the banner node.
func _draw_banner() -> void:
	var amb := maxf(lights.ambient, 0.35) if lights else 1.0
	var t := lights.tint if lights else Color.WHITE
	StoneArt.draw_banners(self, _banner, _time, Color(amb * t.r, amb * t.g, amb * t.b))


## Where this structure's art has flames: a wall torch, the bridge's corner torches, the forge's furnace.
func _flame_tips() -> Array[Vector2]:
	if art.get("torch", false):
		return [StoneArt.torch_tip(self)]
	if kind == Kind.BRIDGE:
		return PropArt.flame_tips(self)
	if kind == Kind.BARRACKS:
		return CivicArt.flame_tips(self)
	if art_tag == &"smithy":
		return [HouseArt.forge_tip(self)]
	return []


## The art's flames, flickering in 8 Hz steps, each a little out of step with the others.
func _draw_flame() -> void:
	var tips := _flame_tips()
	for i in tips.size():
		var tip: Vector2 = tips[i]
		var f := int(_time * 8.0 + float((rng.seed + i * 3) % 5)) % 3
		_flame.draw_rect(Rect2(tip + Vector2(-2, -3), Vector2(4, 3)), COL_FLAME[2])
		_flame.draw_rect(Rect2(tip + Vector2(-1, -5 - f % 2), Vector2(3, 4)), COL_FLAME[1])
		_flame.draw_rect(Rect2(tip + Vector2(-1 + (f % 2), -7 - f), Vector2(1, 3)), COL_FLAME[0])


func _build_cracks() -> void:
	for n in 3:
		var face := 3 if n % 2 == 0 else 1
		var u := rng.randf_range(0.15, 0.85)
		var p: Vector2 = _s[face].lerp(_s[2], u)
		var pts := PackedVector2Array()
		var v := rng.randf_range(0.5, 0.9)
		for i in 5:
			pts.append(Vector2(p.x + rng.randf_range(-3, 3), -v))
			v -= rng.randf_range(0.08, 0.16)
		_cracks.append(pts)


func _build_rubble() -> void:
	var pal := _palette()
	var count := int(clampf(footprint.get_area() * 10.0, 6.0, 26.0))
	for i in count:
		var g := Vector2(rng.randf_range(footprint.position.x - 0.25, footprint.end.x + 0.25),
			rng.randf_range(footprint.position.y - 0.25, footprint.end.y + 0.25))
		var c := Iso.ground_to_screen(g) - position
		var size := rng.randf_range(2.0, 5.5)
		var poly := PackedVector2Array()
		for k in 5:
			var ang := TAU * k / 5.0 + rng.randf() * 0.6
			poly.append(c + Vector2(cos(ang), sin(ang) * 0.7) * size * rng.randf_range(0.6, 1.0) + Vector2(0, -size * 0.4))
		_rubble.append([poly, pal[rng.randi() % 3]])


# --- Effects -----------------------------------------------------------------

func _particles(parent: Node, shape: PixelParticles.Shape, ramp: Array, offset := Vector2.ZERO) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = rng.randi()
	p.shape = shape
	p.ramp = PackedColorArray(ramp)
	p.position = position + offset
	parent.add_child(p)
	return p


func _footprint_radius_px() -> float:
	return maxf(footprint.size.x, footprint.size.y) * FxParts.PX_PER_UNIT_MAJOR * 0.6


func _spawn_debris(source: Vector2, toward: bool, offset := Vector2.ZERO) -> void:
	if fx_parent == null:
		return
	var away := (Iso.ground_to_screen(center()) - Iso.ground_to_screen(source)).normalized()
	if toward:
		away = -away
	var p := _particles(fx_parent, PixelParticles.Shape.CHUNK, FxParts.ROCK, offset + Vector2(0, -height * 0.5))
	p.gravity = 420.0
	p.bounce = true
	p.drag = 0.8
	p.shadows = true
	var count := int(clampf(max_height * 0.5, 10.0, 40.0))
	for i in count:
		var v := (away * rng.randf_range(40.0, 170.0) + Vector2(rng.randf_range(-60, 60), rng.randf_range(-30, 30)))
		p.burst(1, {"radius": _footprint_radius_px(), "velocity": v, "alt": Vector2(0, height * 0.6),
			"alt_speed": Vector2(30, 180), "life": Vector2(1.0, 2.0), "size": Vector2(1.5, 4.5)})


func _spawn_dust(amount: float, offset := Vector2.ZERO) -> void:
	if fx_back == null:
		return
	var ramp: Array = FxParts.MIST_LIFE if destroy_kind == &"ice" else FxParts.DUST_LIFE
	var p := _particles(fx_back, PixelParticles.Shape.PUFF, ramp, offset)
	p.drag = 1.4
	p.burst(int(12.0 * amount * clampf(max_height / 50.0, 0.5, 1.6)), {
		"radius": _footprint_radius_px() * 1.1, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(20, 70),
		"alt": Vector2(0, maxf(height * 0.4, 4.0)), "alt_speed": Vector2(4, 22), "life": Vector2(0.9, 1.8),
		"size": Vector2(4, 8), "size_end_mul": 1.5,
	})


func _spawn_sparks(offset: Vector2, count: int) -> void:
	if fx_parent == null:
		return
	var p := _particles(fx_parent, PixelParticles.Shape.STREAK, FxParts.LASER_LIFE, offset)
	p.gravity = 260.0
	p.drag = 1.5
	p.burst(count, {"radius": _footprint_radius_px() * 0.6, "speed": Vector2(60, 200), "alt_speed": Vector2(20, 120),
		"life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})


func _spawn_fire(offset: Vector2, seconds: float) -> void:
	if fx_parent == null or fx_back == null:
		return
	var f := _particles(fx_parent, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, offset)
	f.rate = 18.0
	f.emitting = true
	f.spec = {"radius": _footprint_radius_px() * 0.5, "alt_speed": Vector2(20, 50), "speed": Vector2(0, 6),
		"life": Vector2(0.3, 0.6), "size": Vector2(1.5, 3.5), "size_end_mul": 0.3}
	var smoke := _particles(fx_back, PixelParticles.Shape.PUFF, FxParts.SMOKE_LIFE, offset)
	smoke.rate = 6.0
	smoke.emitting = true
	smoke.drag = 0.4
	smoke.spec = {"radius": _footprint_radius_px() * 0.4, "alt": Vector2(4, 10), "alt_speed": Vector2(18, 40),
		"speed": Vector2(2, 10), "life": Vector2(1.2, 2.2), "size": Vector2(3, 5), "size_end_mul": 1.7}
	_emitters.append(f)
	_emitters.append(smoke)
	var tw := create_tween() if is_inside_tree() else null
	if tw:
		tw.tween_interval(seconds)
		tw.tween_callback(_stop_emitters.bind([f, smoke]))


func _stop_emitters(list: Array) -> void:
	for e in list:
		if is_instance_valid(e):
			e.emitting = false


func _exit_tree() -> void:
	# Emitters live in the fx layers; make sure they wind down if this structure goes away first.
	_stop_emitters(_emitters)
