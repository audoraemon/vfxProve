extends RefCounted
## The natural light trial's nodes (DAY and NIGHT only): CURRENT creates none of them, and they sit in their layer order:
## the light map's buffer, the grade (1), the glow (2), then Battlefield's glow layer (3).


static func run(t) -> void:
	_current_creates_none(t)
	_bloom(t)
	_windows(t)
	_atmosphere(t)
	_contact(t)
	_smoke(t)


static func _build(look: Town.Look) -> Array:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.look = look
	town.build(env, ground)
	return [town, env, ground]


static func _free(parts: Array) -> void:
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var lights := env.lights
	town.teardown()
	town.free()
	env.clear()
	env.free()
	(parts[2] as Node).free()
	lights.free()


static func _find(town: Town, script: GDScript) -> Node:
	for n in town.look_nodes():
		if is_instance_of(n, script):
			return n
	return null


## Every node in the subtree of `n`, `n` included.
static func _count_all(n: Node, script: GDScript) -> int:
	var k := 1 if is_instance_of(n, script) else 0
	for c in n.get_children():
		k += _count_all(c, script)
	return k


static func _current_creates_none(t) -> void:
	var parts := _build(Town.Look.CURRENT)
	var town: Town = parts[0]
	var ground: Node2D = parts[2]
	t.check(town.look_nodes().is_empty(), "CURRENT adds no look nodes")
	var trial := 0
	for script: GDScript in [TownPools, TownGrade, TownBloom]:
		trial += _count_all(town, script) + _count_all(ground, script)
	t.check(trial == 0, "CURRENT builds no light map, grade or glow (%d)" % trial)
	_free(parts)


static func _bloom(t) -> void:
	for look: Town.Look in [Town.Look.DAY, Town.Look.NIGHT]:
		var parts := _build(look)
		var town: Town = parts[0]
		var grade := _find(town, TownGrade) as TownGrade
		var bloom := _find(town, TownBloom) as TownBloom
		t.check(bloom != null and grade != null, "%s has a glow" % Town.Look.keys()[look])
		if bloom != null and grade != null:
			t.check(grade.layer < bloom.layer and bloom.layer < Battlefield.GLOW_LAYER,
				"grade %d < glow %d < Battlefield glow %d" % [grade.layer, bloom.layer, Battlefield.GLOW_LAYER])
			t.check((bloom.mat.shader as Shader).code.contains("blend_add"), "the glow only adds light (the art under it stays sharp)")
		_free(parts)
	var day := TownLook.bloom(Town.Look.DAY)
	var night := TownLook.bloom(Town.Look.NIGHT)
	t.check(float(night.strength) > float(day.strength), "NIGHT glows more strongly than DAY")
	t.check(float(day.get("use_lum", 0.0)) == 1.0 and float(night.get("use_lum", 0.0)) == 0.0,
		"DAY blooms from bright luminance (highlights), NIGHT from a flame's brightest channel")


## Every house's windows: DAY and NIGHT push the glow-mask windows toward a hot lamp colour (NIGHT fully, DAY faintly),
## CURRENT leaves the sprite shader's path alone, and the town puts the static back on teardown. A building whose set has
## no mask still lights the street from the windows painted in its art.
static func _windows(t) -> void:
	t.check(TownLook.window_boost(Town.Look.NIGHT) > TownLook.window_boost(Town.Look.DAY) and TownLook.window_boost(Town.Look.DAY) > 0.0
		and TownLook.window_boost(Town.Look.CURRENT) == 0.0, "NIGHT lights every window, DAY faintly, CURRENT not at all")
	var cur := _build(Town.Look.CURRENT)
	t.check(SpriteView.window_boost == 0.0, "a CURRENT build leaves the window boost at 0")
	var plain := true
	for s in (cur[1] as EnvironmentField).structures():
		if s.sprite is Dictionary and SpriteArt.window_mask(s.sprite) != null:
			plain = _boost_of(s) == null
			break
	t.check(plain, "CURRENT sprites never get a window_boost parameter")
	_free(cur)
	var parts := _build(Town.Look.NIGHT)
	var env: EnvironmentField = parts[1]
	t.check(SpriteView.window_boost == TownLook.window_boost(Town.Look.NIGHT), "a NIGHT build sets the window boost")
	var boosted := 0
	var masked := 0
	var from_art := 0
	for s in env.structures():
		if s.sprite is Dictionary and SpriteArt.window_mask(s.sprite) != null:
			masked += 1
			if boosted == 0 and float(_boost_of(s)) > 0.0:
				boosted += 1
		elif TownPools.window_pixels(s) > 0:
			from_art += 1
	t.check(boosted > 0 and masked > 50, "NIGHT sprites carry the boost (%d), %d buildings have masked windows" % [boosted, masked])
	t.check(from_art > 0, "buildings without a mask light the street from their painted windows (%d)" % from_art)
	_free(parts)
	t.check(SpriteView.window_boost == 0.0, "teardown puts the window boost back")


## The window_boost a fresh view of the structure's sprite set gets (null: none set).
static func _boost_of(s: Structure) -> Variant:
	var v := SpriteView.new().setup(s.sprite, Vector2(-32, -16), Vector2(32, -16))
	var b = (v.material as ShaderMaterial).get_shader_parameter("window_boost")
	v.free()
	return b


## DAY's atmosphere: haze, beams, sun and a vignette in the grade; NIGHT only a stronger vignette. The beams inside the town
## stay in the ground plane (TownMist's, cut to the town's diamond); the grade's beams keep off the town rect.
static func _atmosphere(t) -> void:
	var day := TownLook.atmosphere(Town.Look.DAY)
	var night := TownLook.atmosphere(Town.Look.NIGHT)
	t.check(TownLook.atmosphere(Town.Look.CURRENT).is_empty(), "CURRENT has no atmosphere")
	t.check(float(day.haze) > 0.0 and float(day.beam) > 0.0 and float(day.sun) > 0.0, "DAY has haze, sunbeams and a sun glow")
	t.check(not night.has("haze") and not night.has("beam") and not night.has("sun"), "NIGHT has none of DAY's atmosphere")
	t.check(float(night.vignette) > float(day.vignette) and float(day.vignette) > 0.0, "both have a vignette, NIGHT's stronger")
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		var town_rect := City.current().town()
		var keep: Vector4 = TownLook.atmosphere(Town.Look.DAY).beam_keep
		var k := Rect2(keep.x, keep.y, keep.z, keep.w)
		t.check(k.encloses(town_rect), "%s: the grade's beams keep off the whole town rect" % id)
		var parts := _build(Town.Look.DAY)
		var town: Town = parts[0]
		var mist := _find(town, TownMist) as TownMist
		var inside := true
		var ground_plane := true
		for b in mist.beams():
			ground_plane = ground_plane and b.get_parent().get_parent() == mist and b.z_index == 0 and b.get_parent().z_index == TownMist.BEAM_Z
			for p in b.polygon:
				var g := Iso.screen_to_ground(p)
				inside = inside and town_rect.grow(0.1).has_point(g)
		t.check(mist.beam_count() > 0 and inside, "%s: the town's %d beam pieces lie inside the town" % [id, mist.beam_count()])
		t.check(ground_plane and mist.get_parent() == parts[2], "%s: the town's beams are in the ground plane, under everything that stands" % id)
		var ok := true
		for n in range(-3, 4):
			var st := TownLook.beam_stripe(n)
			ok = ok and st.y > 0.0 and absf(st.x - n * TownLook.BEAM_PERIOD) <= TownLook.BEAM_PERIOD * 0.15 + 0.001
		t.check(ok, "beam stripes repeat every period, jittered at most 15%")
		_free(parts)
	City.use(&"aldermere")
	var src := FileAccess.get_file_as_string("res://src/game/town/town_mist.gdshader")
	t.check(src.contains("bayer4(floor(wpos))"), "DAY mist is soft-edged with a dithered alpha")


## Contact shadows: in the shadow layer (TownShadows), a group of their own drawn after the cast shadows, four dithered
## quads round every casting structure's base and a blob under every forest tree; a destroyed building keeps its band.
static func _contact(t) -> void:
	for look: Town.Look in [Town.Look.DAY, Town.Look.NIGHT]:
		var parts := _build(look)
		var town: Town = parts[0]
		var env: EnvironmentField = parts[1]
		var sh := _find(town, TownShadows) as TownShadows
		var casting := 0
		for s in env.structures():
			if TownShadows.casts(s):
				casting += 1
		t.check(sh.contact != null and sh.contact.get_parent() == sh and sh.contact.get_index() > sh.group.get_index(),
			"%s: the contact group is in the shadow layer, after the cast shadows" % Town.Look.keys()[look])
		t.check(sh.contact_count() == casting * 4 + sh.trees.size() * 8,
			"%s: a band per casting structure (%d) and a blob per tree (%d): %d shapes" % [Town.Look.keys()[look], casting, sh.trees.size(), sh.contact_count()])
		t.check(sh.contact.self_modulate.a > TownLook.shadow_colour(look).a, "the contact band is darker than the cast shadow")
		var mat := sh.contact.get_child(0).material as ShaderMaterial
		t.check(mat != null and mat.shader.code.contains("bayer4"), "the band is dithered")
		_free(parts)


## More chimney smoke in the looks only: CURRENT's plume is the old one (ChimneySmoke.tall off), DAY and NIGHT draw the
## taller one with wisps, from at least every chimney CURRENT smokes from.
static func _smoke(t) -> void:
	var cur := _build(Town.Look.CURRENT)
	var cs: ChimneySmoke = (cur[0] as Town).smoke
	t.check(not cs.tall, "CURRENT smoke is the old plume")
	var n_cur := cs.wisp_count()
	_free(cur)
	for look: Town.Look in [Town.Look.DAY, Town.Look.NIGHT]:
		var parts := _build(look)
		var sm: ChimneySmoke = (parts[0] as Town).smoke
		t.check(sm.tall and sm.wisp_count() >= n_cur and n_cur > 0,
			"%s smokes taller, from %d chimneys (CURRENT %d)" % [Town.Look.keys()[look], sm.wisp_count(), n_cur])
		_free(parts)
	t.check(ChimneySmoke.TALL_RISE > ChimneySmoke.RISE and ChimneySmoke.TALL_PUFFS > ChimneySmoke.PUFFS, "the looks' plume rises higher, with more puffs")
