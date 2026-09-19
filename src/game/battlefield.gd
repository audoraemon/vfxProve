class_name Battlefield
extends Node2D
## The shared world effects play in: iso ground plane, y-sorted world layer, overhead and distortion layers,
## camera with shake, positional sound, lights, destructible buildings, units, screen glow, impact post and
## screen flash, all wired into one FxContext. The VFX sandbox and the KAK game each add one as a child.

var ctx := FxContext.new()
## Seeds unit spawns and effect randomness; reseeded by reset().
var rng := RandomNumberGenerator.new()
var camera: CameraShake
## Transform Iso.BASIS: floors and ground previews added here are authored in ground units.
var ground_plane: Node2D
## CanvasLayer 5 for HUD controls (empty until the owner adds some).
var hud_layer: CanvasLayer

var _flash_rect: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	ground_plane = Node2D.new()
	ground_plane.name = "GroundPlane"
	ground_plane.transform = Iso.BASIS
	ground_plane.z_index = -10
	add_child(ground_plane)

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

	camera = CameraShake.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	var listener := AudioListener2D.new()
	camera.add_child(listener)
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

	var field := EnemyField.new()
	field.env = env
	field.lights = lights
	field.name = "EnemyField"
	add_child(field)

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HudLayer"
	hud_layer.layer = 5
	add_child(hud_layer)

	# Glow sits above the world and effects, below the impact post and flash.
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = 2
	add_child(glow_layer)
	var glow := ColorRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	var glow_mat := ShaderMaterial.new()
	glow_mat.shader = preload("res://shaders/glow_post.gdshader")
	glow.material = glow_mat
	glow_layer.add_child(glow)

	var post_layer := CanvasLayer.new()
	post_layer.layer = 3
	add_child(post_layer)
	var impact := Impact.new()
	impact.name = "Impact"
	add_child(impact)
	impact.setup(post_layer, dim_layer, camera)

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 4
	add_child(flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_layer.add_child(_flash_rect)

	ctx.field = field
	ctx.env = env
	ctx.lights = lights
	ctx.shake = camera
	ctx.sfx = sfx
	ctx.ground = ground_plane
	ctx.world = world
	ctx.overhead_back = overhead_back
	ctx.overhead = overhead
	ctx.impact = impact
	ctx.distort = distort
	ctx.rng = rng
	ctx.flash = flash


func _process(_delta: float) -> void:
	ctx.lights.ambient = 1.0 - ctx.impact.dim_level() * 0.85


## Full-screen flash of `color` that fades out over `seconds`.
func flash(color: Color, seconds: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Reseed, lift the dim and clear effects, units, lights and buildings. The owner then builds its map and spawns
## its units (in that order, so spawns avoid the new buildings).
func reset(seed_value: int) -> void:
	rng.seed = seed_value
	ctx.impact.dim(0.0, 100.0)
	clear_effects()
	ctx.field.clear()
	ctx.lights.clear()
	ctx.env.clear()
	ctx.env.rng.seed = seed_value


## Free every effect node in the overhead and distortion layers.
func clear_effects() -> void:
	for layer in [ctx.overhead_back, ctx.overhead, ctx.distort]:
		for c in layer.get_children():
			c.queue_free()


## Ground point under the mouse.
func mouse_ground() -> Vector2:
	return Iso.screen_to_ground(get_global_mouse_position())


## Small outlined debug text at the top left of the HUD layer.
func add_debug_label() -> Label:
	var label := Label.new()
	label.position = Vector2(6, 4)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("cfd8e8"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	hud_layer.add_child(label)
	return label


## Save the next drawn frame, scaled 2x with nearest filtering, to res://captures/<file_name>.
func save_capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(file_name)
	img.save_png(path)
	print("captured ", path)


func wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Time frames for `seconds` of real time and print one bench line.
func bench(label: String, seconds := 9.0) -> void:
	var worst := 0.0
	var total := 0.0
	var frames := 0
	var last := Time.get_ticks_usec()
	var start := last
	while Time.get_ticks_usec() - start < int(seconds * 1_000_000.0):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		if frames > 2:
			worst = maxf(worst, ms)
		total += ms
		frames += 1
	print("bench[%s] frames=%d avg_ms=%.2f avg_fps=%.1f worst_ms=%.2f min_fps=%.1f" % [
		label, frames, total / frames, 1000.0 * frames / total, worst, 1000.0 / worst])


## Stop voices and effects before quitting so the audio server does not leak playbacks.
func quit() -> void:
	ctx.sfx.stop_all("")
	clear_effects()
	await wait_frames(3)
	# Stopped playbacks are released by the audio thread; give it real time (fixed-fps frames can be ~1 ms).
	OS.delay_msec(150)
	await wait_frames(1)
	Sfx.clear_cache()
	get_tree().quit()


## Value of a `key=value` command-line argument, or "".
static func arg_value(args: PackedStringArray, key: String) -> String:
	for a in args:
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


## Held WASD / arrow keys as a pan direction (not normalized; zero when none are held).
static func key_pan_dir() -> Vector2:
	var pan := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		pan.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		pan.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		pan.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		pan.y += 1
	return pan
