extends Node2D
## VFX sandbox: iso floor, dummy enemies, effect picker, capture and bench modes.

## Set 0: sci-fi city. Set 1: fantasy castle (KWAI). Tab switches set and rebuilds the map.
const SETS := [
	{"name": "Set1 Sci-Fi", "theme": "scifi", "clear": Color("07080d")},
	{"name": "Set2 Fantasy", "theme": "fantasy", "clear": Color("0b0908")},
]
## `lane`: cast with a drag direction.
const EFFECTS := [
	{"set": 0, "key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd"},
	{"set": 0, "key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd"},
	{"set": 0, "key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd"},
	{"set": 0, "key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd", "lane": true},
	{"set": 1, "key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd"},
	{"set": 1, "key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd", "lane": true},
	{"set": 1, "key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd"},
	{"set": 1, "key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd", "lane": true},
	{"set": 1, "key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd", "lane": true},
	{"set": 1, "key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd"},
	{"set": 1, "key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd", "lane": true},
]

## Capture moments per effect (seconds from cast).
const CAPTURES := {
	"nova": {"target": Vector2(0, 0), "times": [2.6, 3.05, 3.3, 3.7, 4.1]},
	"orbital": {"target": Vector2(0, 0), "times": [2.6, 3.4]},
	"gravity": {"target": Vector2(0, 0), "times": [1.5, 2.6, 3.6, 4.02, 4.2, 4.5, 5.5]},
	"laser": {"target": Vector2(-4.5, 0), "dir": Vector2(1, 0), "times": [1.9, 2.8, 3.8, 4.8, 5.4, 6.2, 7.0]},
	"heaven": {"target": Vector2(0, 0), "dir": Vector2(1, 0), "times": [1.0, 1.45, 1.75, 2.5, 3.0, 3.5, 5.0, 7.5]},
	"glacial": {"target": Vector2(0, 0), "times": [1.9, 2.6, 3.6, 5.5, 7.35, 7.55, 7.8, 8.1, 9.2]},
}

const ENEMY_COUNT := 40
const PAN_SPEED := 240.0
const LASER_DRAG_MIN := 0.5

var ctx := FxContext.new()
var selected := 0
var set_index := 0
var _tiles: Node2D

var _field: EnemyField
var _camera: CameraShake
var _hud: Label
var _flash_rect: ColorRect
var _flash_tween: Tween
var _ground_plane: Node2D
var _drag_preview: Node2D
var _press_ground := Vector2.ZERO
var _pressing := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("07080d"))
	_build_world()
	var args := OS.get_cmdline_user_args()
	var seed_value := 7 if _has_any_flag(args) else Time.get_ticks_usec()
	if _arg_value(args, "--set") != "":
		set_index = int(_arg_value(args, "--set"))
	var only := _arg_value(args, "--only")
	if only != "":
		for e in EFFECTS:
			if e.key == only:
				set_index = e.set
	_reset_world(seed_value)
	_update_hud()
	await FxParts.prewarm(ctx.distort)
	if "--capture-idle" in args:
		_capture_idle()
	elif "--capture-all" in args:
		_capture_all(_arg_value(args, "--only"))
	elif "--bench" in args:
		_bench(_arg_value(args, "--only"))


func _has_any_flag(args: PackedStringArray) -> bool:
	for a in args:
		if a.begins_with("--capture") or a == "--bench":
			return true
	return false


func _arg_value(args: PackedStringArray, key: String) -> String:
	for a in args:
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


func _build_world() -> void:
	_ground_plane = Node2D.new()
	_ground_plane.name = "GroundPlane"
	_ground_plane.transform = Iso.BASIS
	_ground_plane.z_index = -10
	add_child(_ground_plane)
	_tiles = Node2D.new()
	_tiles.name = "Tiles"
	_tiles.set_script(preload("res://src/sandbox/ground_tiles.gd"))
	_ground_plane.add_child(_tiles)

	_drag_preview = Node2D.new()
	_drag_preview.name = "DragPreview"
	_drag_preview.z_index = 5
	_drag_preview.draw.connect(_draw_drag_preview)
	_ground_plane.add_child(_drag_preview)

	var world := Node2D.new()
	world.name = "WorldLayer"
	world.y_sort_enabled = true
	add_child(world)

	# Dim only darkens the ground; buildings and enemies darken themselves via LightField.ambient
	# so effect light on them still reads in the dark.
	var dim_layer := Node2D.new()
	dim_layer.name = "DimLayer"
	dim_layer.z_index = -6
	add_child(dim_layer)

	var overhead_back := Node2D.new()
	overhead_back.name = "OverheadBackLayer"
	overhead_back.z_index = 8
	add_child(overhead_back)

	var overhead := Node2D.new()
	overhead.name = "OverheadLayer"
	overhead.z_index = 10
	add_child(overhead)

	var distort := Node2D.new()
	distort.name = "DistortLayer"
	distort.z_index = 20
	add_child(distort)

	_camera = CameraShake.new()
	_camera.name = "Camera"
	add_child(_camera)
	_camera.make_current()
	var listener := AudioListener2D.new()
	_camera.add_child(listener)
	listener.make_current()

	var sfx := Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)

	var lights := LightField.new()
	lights.name = "Lights"
	add_child(lights)
	var env := EnvironmentField.new()
	env.name = "Environment"
	add_child(env)
	env.lights = lights
	env.world_parent = world
	env.fx_parent = overhead
	env.fx_back = overhead_back

	_field = EnemyField.new()
	_field.env = env
	_field.lights = lights
	_field.name = "EnemyField"
	add_child(_field)

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	_hud = Label.new()
	_hud.position = Vector2(6, 4)
	_hud.add_theme_font_size_override("font_size", 8)
	_hud.add_theme_color_override("font_color", Color("cfd8e8"))
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 2)
	hud_layer.add_child(_hud)

	var post_layer := CanvasLayer.new()
	post_layer.layer = 3
	add_child(post_layer)
	var impact := Impact.new()
	impact.name = "Impact"
	add_child(impact)
	impact.setup(post_layer, dim_layer, _camera)

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 4
	add_child(flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_layer.add_child(_flash_rect)

	ctx.field = _field
	ctx.env = env
	ctx.lights = lights
	ctx.shake = _camera
	ctx.sfx = sfx
	ctx.ground = _ground_plane
	ctx.world = world
	ctx.overhead_back = overhead_back
	ctx.overhead = overhead
	ctx.impact = impact
	ctx.distort = distort
	ctx.rng = _rng
	ctx.flash = _screen_flash


func _screen_flash(color: Color, seconds: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _visible_effects() -> Array:
	return EFFECTS.filter(func(e): return e.set == set_index)


func _reset_world(seed_value: int) -> void:
	_rng.seed = seed_value
	var theme: String = SETS[set_index].theme
	RenderingServer.set_default_clear_color(SETS[set_index].clear)
	_tiles.theme = theme
	_field.look = DummyEnemy.Look.ORC if theme == "fantasy" else DummyEnemy.Look.TROOPER
	ctx.impact.dim(0.0, 100.0)
	for layer in [ctx.overhead_back, ctx.overhead, ctx.distort]:
		for c in layer.get_children():
			c.queue_free()
	_field.clear()
	ctx.lights.clear()
	ctx.env.clear()
	ctx.env.rng.seed = seed_value
	if theme == "fantasy":
		ctx.env.build_castle()
	else:
		ctx.env.build_city()
	_field.spawn(ENEMY_COUNT, ctx.world, _rng)


func cast(index: int, ground: Vector2, extra := {}) -> FxTimeline:
	return _cast_entry(_visible_effects()[index], ground, extra)


func _cast_entry(entry: Dictionary, ground: Vector2, extra := {}) -> FxTimeline:
	if not ResourceLoader.exists(entry.path):
		push_warning("Effect not built yet: %s" % entry.name)
		return null
	return FxTimeline.cast(load(entry.path), ctx, ground, extra)


func _mouse_ground() -> Vector2:
	return Iso.screen_to_ground(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
				var i: int = event.physical_keycode - KEY_1
				if i < _visible_effects().size():
					selected = i
					_update_hud()
			KEY_TAB:
				set_index = (set_index + 1) % SETS.size()
				selected = 0
				_reset_world(Time.get_ticks_usec())
				_update_hud()
			KEY_R:
				_reset_world(Time.get_ticks_usec())
			KEY_SPACE:
				ctx.impact.set_base_time_scale(0.25 if ctx.impact.base_time_scale > 0.5 else 1.0)
				_update_hud()
			KEY_ESCAPE:
				_quit()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_ground = _mouse_ground()
		elif _pressing:
			_pressing = false
			_drag_preview.queue_redraw()
			var extra := {}
			if _visible_effects()[selected].get("lane", false):
				var drag := _mouse_ground() - _press_ground
				extra["dir"] = drag.normalized() if drag.length() >= LASER_DRAG_MIN else Vector2(1, 0)
			cast(selected, _press_ground, extra)


func _process(delta: float) -> void:
	var pan := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		pan.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		pan.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		pan.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		pan.y += 1
	if pan != Vector2.ZERO:
		# Pan in real time regardless of slow-mo.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_camera.position = (_camera.position + pan.normalized() * PAN_SPEED * real_delta).clamp(
			Vector2(-300, -160), Vector2(300, 160))
	if _pressing:
		_drag_preview.queue_redraw()
	ctx.lights.ambient = 1.0 - ctx.impact.dim_level() * 0.85


func _draw_drag_preview() -> void:
	if not _pressing or not _visible_effects()[selected].get("lane", false):
		return
	var to := _mouse_ground()
	var col := Color(1, 0.35, 0.2, 0.9)
	_drag_preview.draw_line(_press_ground, to, col, -1.0)
	_drag_preview.draw_rect(Rect2(_press_ground - Vector2(0.08, 0.08), Vector2(0.16, 0.16)), col)


func _update_hud() -> void:
	var names := []
	var list := _visible_effects()
	for i in list.size():
		var label := "%d %s" % [i + 1, list[i].name]
		if not ResourceLoader.exists(list[i].path):
			label += "*"
		names.append("[%s]" % label if i == selected else " %s " % label)
		if i == 3 and list.size() > 4:
			names.append("\n   ")
	var slow := "  SLOW-MO x0.25" if ctx.impact.base_time_scale < 0.5 else ""
	_hud.text = "%s:  %s\nLMB cast (lane skills: drag = direction)   TAB switch set   R respawn   SPACE slow-mo   WASD pan%s" % [
		SETS[set_index].name, "  ".join(names), slow]


## Stop voices before quitting so the audio server does not leak playbacks.
func _quit() -> void:
	ctx.sfx.stop_all("")
	for c in ctx.overhead_back.get_children() + ctx.overhead.get_children() + ctx.distort.get_children():
		c.queue_free()
	await _wait_frames(3)
	# Stopped playbacks are released by the audio thread; give it real time (fixed-fps frames can be ~1 ms).
	OS.delay_msec(150)
	await _wait_frames(1)
	Sfx.clear_cache()
	get_tree().quit()


# --- Capture / bench -------------------------------------------------------

func _capture_dir() -> String:
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


func _save_capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var path := _capture_dir().path_join(file_name)
	img.save_png(path)
	print("captured ", path)


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _capture_idle() -> void:
	await _wait_frames(30)
	await _save_capture("idle.png")
	await _quit()


func _capture_all(only: String) -> void:
	for entry in EFFECTS:
		var key: String = entry.key
		if only != "" and only != key:
			continue
		if not ResourceLoader.exists(entry.path) or not CAPTURES.has(key):
			print("skip (not built): ", key)
			continue
		var plan: Dictionary = CAPTURES[key]
		set_index = entry.set
		_reset_world(7)
		_hud.text = entry.name
		await _wait_frames(10)
		var extra := {}
		if plan.has("dir"):
			extra["dir"] = plan.dir
		var fx := _cast_entry(entry, plan.target, extra)
		for time in plan.times:
			while is_instance_valid(fx) and fx.t < time:
				await get_tree().process_frame
			await _save_capture("%s_%04d.png" % [key, int(time * 1000)])
		while is_instance_valid(fx):
			await get_tree().process_frame
	await _quit()


func _bench(only: String) -> void:
	await _wait_frames(10)
	var spots := [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(-5, 3)]
	var list := _visible_effects()
	for i in list.size():
		if only != "" and only != list[i].key:
			continue
		if ResourceLoader.exists(list[i].path):
			_cast_entry(list[i], spots[i % spots.size()], {"dir": Vector2(1, 0)})
	var worst := 0.0
	var total := 0.0
	var frames := 0
	var last := Time.get_ticks_usec()
	var start := last
	while Time.get_ticks_usec() - start < 9_000_000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		if frames > 2:
			worst = maxf(worst, ms)
		total += ms
		frames += 1
	print("bench[%s] frames=%d avg_ms=%.2f avg_fps=%.1f worst_ms=%.2f min_fps=%.1f" % [
		only if only != "" else "all", frames, total / frames, 1000.0 * frames / total, worst, 1000.0 / worst])
	await _quit()
