extends Node2D
## VFX sandbox: iso floor, dummy enemies, effect picker, capture and bench modes. The world itself (layers, camera,
## sound, lights, buildings, units, glow, impact, flash) is the shared Battlefield.

## Set 0: sci-fi city. Set 1: fantasy castle (KWAI). Tab switches set and rebuilds the map.
## dim_scale: how strongly effects darken the world. zoom: camera push-in while a skill plays.
const SETS := [
	{"name": "Set1 Sci-Fi", "theme": "scifi", "clear": Color("07080d"), "dim_scale": 0.75, "zoom": 1.35},
	{"name": "Set2 Fantasy", "theme": "fantasy", "clear": Color("2a2e24"), "dim_scale": 0.4, "zoom": 1.55},
]
const FOCUS_IN := 0.45
const FOCUS_OUT := 0.7
## `lane`: cast with a drag direction.
const EFFECTS := [
	{"set": 0, "key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd", "zoom": 1.2, "focus_up": -60.0},
	{"set": 0, "key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd"},
	{"set": 0, "key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd"},
	{"set": 0, "key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd", "lane": true, "focus_along": 5.0},
	{"set": 1, "key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd", "zoom": 1.3, "focus_up": -50.0},
	{"set": 1, "key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd", "lane": true, "focus_along": 0.0, "focus_up": -60.0, "zoom": 1.1},
	{"set": 1, "key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd", "zoom": 0.95, "focus_up": -70.0},
	{"set": 1, "key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd", "lane": true, "focus_along": 3.0, "focus_up": -70.0, "zoom": 0.8},
	{"set": 1, "key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd", "follow": true, "focus_up": -120.0, "zoom": 0.9},
	{"set": 1, "key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd", "focus_up": -130.0, "zoom": 0.7},
	{"set": 1, "key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd", "focus_up": -10.0, "focus_px": Vector2(150, -20), "zoom": 0.8},
]

## Capture moments per effect (seconds from cast).
const CAPTURES := {
	"nova": {"target": Vector2(0, 0), "times": [2.6, 3.05, 3.3, 3.7, 4.1]},
	"orbital": {"target": Vector2(0, 0), "times": [2.6, 3.4]},
	"gravity": {"target": Vector2(0, 0), "times": [1.5, 2.6, 3.6, 4.02, 4.2, 4.5, 5.5]},
	"laser": {"target": Vector2(-4.5, 0), "dir": Vector2(1, 0), "times": [1.9, 2.8, 3.8, 4.8, 5.4, 6.2, 7.0]},
	"heaven": {"target": Vector2(0, 0), "dir": Vector2(1, 0), "times": [1.0, 1.3, 1.5, 1.75, 2.3, 2.8, 3.0, 3.2, 3.45, 3.75, 5.0, 7.0]},
	"cinder": {"target": Vector2(0, 0), "times": [1.0, 1.8, 2.7, 3.2, 4.2, 5.4, 6.6, 8.6, 10.0, 11.2]},
	"tsunami": {"target": Vector2(-3.0, 0.5), "dir": Vector2(1, 0), "times": [0.8, 1.6, 2.6, 3.4, 4.1, 4.5, 6.5, 8.5]},
	"tornado": {"target": Vector2(0, 0), "times": [0.8, 1.6, 2.6, 4.5, 6.5, 8.5, 10.5, 11.6, 13.0]},
	"judgement": {"target": Vector2(0, 0), "times": [2.6, 3.64, 4.14, 4.64, 5.14, 5.64, 6.14, 6.64, 7.14, 7.94, 8.4, 11.0]},
	"dragon": {"target": Vector2(-2, -1), "times": [0.9, 1.5, 2.8, 4.2, 5.0, 5.8, 6.5, 7.4, 10.0]},
	"glacial": {"target": Vector2(0, 0), "times": [1.9, 2.6, 3.6, 5.5, 7.35, 7.55, 7.8, 8.1, 9.2]},
}

const ENEMY_COUNT := 40
const PAN_SPEED := 240.0
const LASER_DRAG_MIN := 0.5
## How far (px) a followed effect may drift from the screen centre before the camera moves after it.
const FOLLOW_SLACK := Vector2(120, 24)

var ctx: FxContext
var selected := 0
var set_index := 0
var _bf: Battlefield
var _tiles: Node2D

var _field: EnemyField
var _camera: CameraShake
var _hud: Label
var _drag_preview: Node2D
var _press_ground := Vector2.ZERO
var _pressing := false
var _rng: RandomNumberGenerator
var _active_fx: Array[FxTimeline] = []
var _home_position := Vector2.ZERO
var _camera_tween: Tween
## Effect the camera keeps following (entries with "follow"), and how far above its ground point to look.
var _follow_fx: FxTimeline
var _follow_up := 0.0
## 0..1: ramps up once the follow camera has centred on the cast, letting the effect roam inside FOLLOW_SLACK.
var _follow_slack := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("07080d"))
	_build_world()
	var args := OS.get_cmdline_user_args()
	var seed_value := 7 if _has_any_flag(args) else Time.get_ticks_usec()
	if Battlefield.arg_value(args, "--set") != "":
		set_index = int(Battlefield.arg_value(args, "--set"))
	var only := Battlefield.arg_value(args, "--only")
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
		_capture_all(Battlefield.arg_value(args, "--only"))
	elif "--bench" in args:
		_bench(Battlefield.arg_value(args, "--only"))


func _has_any_flag(args: PackedStringArray) -> bool:
	for a in args:
		if a.begins_with("--capture") or a == "--bench":
			return true
	return false


func _build_world() -> void:
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	ctx = _bf.ctx
	_field = ctx.field
	_camera = _bf.camera
	_rng = _bf.rng

	_tiles = Node2D.new()
	_tiles.name = "Tiles"
	_tiles.set_script(preload("res://src/sandbox/ground_tiles.gd"))
	_bf.ground_plane.add_child(_tiles)

	_drag_preview = Node2D.new()
	_drag_preview.name = "DragPreview"
	_drag_preview.z_index = 5
	_drag_preview.draw.connect(_draw_drag_preview)
	_bf.ground_plane.add_child(_drag_preview)

	_hud = _bf.add_debug_label()


func _visible_effects() -> Array:
	return EFFECTS.filter(func(e): return e.set == set_index)


func _reset_world(seed_value: int) -> void:
	var theme: String = SETS[set_index].theme
	RenderingServer.set_default_clear_color(SETS[set_index].clear)
	_tiles.theme = theme
	_field.look = DummyEnemy.Look.ORC if theme == "fantasy" else DummyEnemy.Look.TROOPER
	ctx.impact.dim_scale = SETS[set_index].dim_scale
	_active_fx.clear()
	_follow_fx = null
	if _camera_tween:
		_camera_tween.kill()
	_camera.zoom = Vector2.ONE
	_bf.reset(seed_value)
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
	var fx := FxTimeline.cast(load(entry.path), ctx, ground, extra)
	_focus_camera(entry, fx, ground, extra)
	return fx


## Push the camera in toward the skill while it plays, like the concept panels; ease back when the last one ends.
func _focus_camera(entry: Dictionary, fx: FxTimeline, ground: Vector2, extra: Dictionary) -> void:
	if _active_fx.is_empty():
		_home_position = _camera.position
	_active_fx.append(fx)
	fx.tree_exited.connect(_on_fx_done.bind(fx))
	var focus := ground
	if entry.get("lane", false):
		focus += (extra.get("dir", Vector2(1, 0)) as Vector2).normalized() * float(entry.get("focus_along", 4.0))
	var target := Iso.ground_to_screen(focus) + Vector2(0, float(entry.get("focus_up", -40.0)))
	target += entry.get("focus_px", Vector2.ZERO)
	var zoom: float = entry.get("zoom", SETS[set_index].zoom)
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel()
	if entry.get("follow", false) and fx.has_method("camera_focus"):
		# Moving skills: _process eases the camera after the effect instead of tweening to a fixed spot.
		_follow_fx = fx
		_follow_up = float(entry.get("focus_up", -40.0))
		_follow_slack = 0.0
	else:
		_camera_tween.tween_property(_camera, "position", target.round(), FOCUS_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "zoom", Vector2.ONE * zoom, FOCUS_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_fx_done(fx: FxTimeline) -> void:
	_active_fx.erase(fx)
	if fx == _follow_fx:
		_follow_fx = null
	if not _active_fx.is_empty() or not is_inside_tree():
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel()
	_camera_tween.tween_property(_camera, "position", _home_position, FOCUS_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_camera, "zoom", Vector2.ONE, FOCUS_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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
				_bf.quit()
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
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of slow-mo.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_camera.position = (_camera.position + pan.normalized() * PAN_SPEED * real_delta).clamp(
			Vector2(-300, -160), Vector2(300, 160))
	if is_instance_valid(_follow_fx) and _follow_fx.is_inside_tree():
		var real := delta / maxf(Engine.time_scale, 0.001)
		var goal := Iso.ground_to_screen(_follow_fx.camera_focus()) + Vector2(0, _follow_up)
		# Centre on the cast first, then only chase the effect once it drifts out of a dead zone, so its travel
		# shows on screen instead of the ground sliding under a pinned effect.
		var off := goal - _camera.position
		if _follow_slack > 0.0 or off.length() < 6.0:
			_follow_slack = move_toward(_follow_slack, 1.0, real / 1.5)
		var slack := FOLLOW_SLACK * _follow_slack
		var chase := Vector2(signf(off.x) * maxf(absf(off.x) - slack.x, 0.0), signf(off.y) * maxf(absf(off.y) - slack.y, 0.0))
		_camera.position = _camera.position.lerp(_camera.position + chase, minf(4.0 * real, 1.0))
	if _pressing:
		_drag_preview.queue_redraw()


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


# --- Capture / bench -------------------------------------------------------

func _capture_idle() -> void:
	await _bf.wait_frames(30)
	await _bf.save_capture("idle.png")
	await _bf.quit()


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
		await _bf.wait_frames(10)
		var extra := {}
		if plan.has("dir"):
			extra["dir"] = plan.dir
		var fx := _cast_entry(entry, plan.target, extra)
		for time in plan.times:
			while is_instance_valid(fx) and fx.t < time:
				await get_tree().process_frame
			await _bf.save_capture("%s_%04d.png" % [key, int(time * 1000)])
		while is_instance_valid(fx):
			await get_tree().process_frame
	await _bf.quit()


func _bench(only: String) -> void:
	await _bf.wait_frames(10)
	var spots := [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(-5, 3)]
	var list := _visible_effects()
	for i in list.size():
		if only != "" and only != list[i].key:
			continue
		if ResourceLoader.exists(list[i].path):
			_cast_entry(list[i], spots[i % spots.size()], {"dir": Vector2(1, 0)})
	await _bf.bench(only if only != "" else "all")
	await _bf.quit()
