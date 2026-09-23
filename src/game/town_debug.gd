extends Node2D
## Milestone 1 debug scene for Kingdoms Amid Kataclysm: the town of Aldermere and its fortified Royal Citadel on the
## shared Battlefield, 40 placeholder units inside the walls, and every power castable from the keyboard. No rules,
## HUD or people yet (milestones 2 and 3).
## Flags after `--`: --capture-town (screenshots), --citadel-test (scripted strikes on the Citadel, logged),
## --bench [--only=<power key>] (frame times while that power plays beside the Citadel).

const UNIT_COUNT := 40
## Placeholder units stay inside the town walls until the people milestone gives them real brains.
const UNIT_BOUNDS := Rect2(-8.3, -8.3, 16.6, 16.6)
const PAN_SPEED := 320.0
const PAN_MIN := Vector2(-760, -380)
const PAN_MAX := Vector2(760, 520)
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
const DRAG_MIN := 0.5
## Keys 1-9, 0 and - pick PowerBook.POWERS[0..10].
const POWER_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS]
const KEY_LABELS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"]
const CLEAR := Color("2a2e24")
## [file, ground point to look at, zoom] for --capture-town.
const TOWN_SHOTS := [
	["town_overview.png", Vector2(2, 2), 0.5],
	["town_citadel.png", Vector2(0, -5.9), 1.1],
	["town_market.png", Vector2(0, 0), 1.2],
	["town_main_gate.png", Vector2(0, 8.7), 1.1],
	["town_side_gate.png", Vector2(8.7, 0), 1.1],
	["town_river_farms.png", Vector2(1, 13), 0.8],
]
## [time, power key, ground point] for --citadel-test.
const CITADEL_CASTS := [
	[0.5, "judgement", Vector2(0, -5.9)],
	[12.0, "cinder", Vector2(-4.5, -5.0)],
	[22.0, "nova", Vector2(0, -5.9)],
	[30.0, "judgement", Vector2(0, -5.9)],
	[40.0, "nova", Vector2(0, -5.9)],
	[48.0, "orbital", Vector2(0, -5.9)],
]
const CITADEL_SHOTS := [0.3, 4.0, 9.5, 14.0, 18.0, 25.5, 33.0, 43.5, 52.0]
const CITADEL_TEST_END := 60.0

var _bf: Battlefield
var _town: Town
var _selected := 0
var _pressing := false
var _press_ground := Vector2.ZERO
var _hud: Label
var _drag_line: Node2D
var _destroyed := 0
## Game-time seconds since the scene started (follows Engine.time_scale like the effects' clocks).
var _t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	_bf.ctx.impact.dim_scale = 0.4
	_bf.ctx.field.look = DummyEnemy.Look.ORC
	_bf.ctx.field.bounds = UNIT_BOUNDS
	_bf.ctx.env.structure_destroyed.connect(_on_structure_destroyed)
	_drag_line = Node2D.new()
	_drag_line.name = "DragLine"
	_drag_line.z_index = 5
	_drag_line.draw.connect(_draw_drag_line)
	_bf.ground_plane.add_child(_drag_line)
	_hud = _bf.add_debug_label()
	var args := OS.get_cmdline_user_args()
	var scripted := "--capture-town" in args or "--citadel-test" in args or "--bench" in args
	_rebuild(7 if scripted else Time.get_ticks_usec())
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(Vector2(0, -2)).round()
	await FxParts.prewarm(_bf.ctx.distort)
	if "--capture-town" in args:
		_capture_town()
	elif "--citadel-test" in args:
		_citadel_test()
	elif "--bench" in args:
		_run_bench(Battlefield.arg_value(args, "--only"))


## Fresh town: clear the battlefield, build Aldermere and its Citadel, spawn the placeholder units.
func _rebuild(seed_value: int) -> void:
	_bf.reset(seed_value)
	_destroyed = 0
	if is_instance_valid(_town):
		_town.free()
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_bf.ctx.field.spawn(UNIT_COUNT, _bf.ctx.world, _bf.rng)


func _cast(power: Dictionary, ground: Vector2, extra := {}) -> FxTimeline:
	if power.is_empty():
		push_warning("Unknown power")
		return null
	return FxTimeline.cast(load(power.path), _bf.ctx, ground, extra)


func _on_structure_destroyed(_s: Structure) -> void:
	_destroyed += 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var i := POWER_KEYS.find(event.physical_keycode)
		if i >= 0:
			_selected = i
		elif event.physical_keycode == KEY_R:
			_rebuild(Time.get_ticks_usec())
		elif event.physical_keycode == KEY_ESCAPE:
			_bf.quit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_ground = _bf.mouse_ground()
		elif _pressing:
			_pressing = false
			_drag_line.queue_redraw()
			var power: Dictionary = PowerBook.POWERS[_selected]
			var extra := {}
			if power.aim == "drag":
				var drag := _bf.mouse_ground() - _press_ground
				extra["dir"] = drag.normalized() if drag.length() >= DRAG_MIN else Vector2(1, 0)
			_cast(power, _press_ground, extra)


func _process(delta: float) -> void:
	_t += delta
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	if _pressing:
		_drag_line.queue_redraw()
	_update_hud()


func _pan(by: Vector2) -> void:
	_bf.camera.position = (_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX)


func _draw_drag_line() -> void:
	if not _pressing or PowerBook.POWERS[_selected].aim != "drag":
		return
	var col := Color(1, 0.35, 0.2, 0.9)
	_drag_line.draw_line(_press_ground, _bf.mouse_ground(), col, -1.0)
	_drag_line.draw_rect(Rect2(_press_ground - Vector2(0.08, 0.08), Vector2(0.16, 0.16)), col)


func _update_hud() -> void:
	if _town == null or not is_instance_valid(_town.citadel):
		return
	var power: Dictionary = PowerBook.POWERS[_selected]
	var cit := _town.citadel
	var text := "KAK town debug   [%s] %s  (%s, %d DP)\nCitadel %d%%   parts %d/9   buildings down %d\n1-9 0 - pick   LMB cast (drag: line powers)   WASD / middle-drag pan   wheel zoom   R rebuild   Esc quit" % [
		KEY_LABELS[_selected], power.name, power.aim, power.dp, roundi(cit.fraction() * 100.0), cit.standing_parts(),
		_destroyed]
	if _hud.text != text:
		_hud.text = text


# --- Scripted runs ---------------------------------------------------------

func _capture_town() -> void:
	_hud.visible = false
	for shot in TOWN_SHOTS:
		_bf.camera.zoom = Vector2.ONE * float(shot[2])
		_bf.camera.position = (Iso.ground_to_screen(shot[1]) + Vector2(0, -30)).round()
		await _bf.wait_frames(20)
		await _bf.save_capture(shot[0])
	await _bf.quit()


## Scripted strikes on the Citadel: the titan's punches, a volcano beside it, then novas, the titan again and an
## orbital strike until it falls. Logs its health every second and at each collapse, and captures key moments.
func _citadel_test() -> void:
	var cit := _town.citadel
	cit.part_collapsed.connect(_log_part)
	_bf.camera.zoom = Vector2.ONE * 0.8
	_bf.camera.position = (Iso.ground_to_screen(TownLayout.CITADEL_ORIGIN) + Vector2(0, -60)).round()
	await _bf.wait_frames(10)
	_t = 0.0
	var casts := CITADEL_CASTS.duplicate()
	var shots := CITADEL_SHOTS.duplicate()
	var next_log := 0.0
	var fall_time := -1.0
	while _t < CITADEL_TEST_END:
		while not casts.is_empty() and _t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			print("CAST %s t=%.2f" % [c[1], _t])
			_cast(PowerBook.get_power(c[1]), c[2])
		if not shots.is_empty() and _t >= float(shots[0]):
			await _bf.save_capture("citadel_%05d.png" % int(float(shots.pop_front()) * 1000.0))
		if _t >= next_log:
			next_log += 1.0
			print("CITADEL t=%.1f frac=%.2f standing=%d" % [_t, cit.fraction(), cit.standing_parts()])
		if cit.is_fallen() and fall_time < 0.0:
			fall_time = _t
			print("CITADEL FALLEN t=%.2f" % _t)
		if fall_time >= 0.0 and _t >= fall_time + 3.0:
			await _bf.save_capture("citadel_fallen.png")
			break
		await get_tree().process_frame
	print("CITADEL result fallen=%s frac=%.2f standing=%d t=%.1f" % [cit.is_fallen(), cit.fraction(), cit.standing_parts(), _t])
	await _bf.quit()


func _log_part(_p: Structure) -> void:
	var cit := _town.citadel
	print("CITADEL part down t=%.2f frac=%.2f standing=%d" % [_t, cit.fraction(), cit.standing_parts()])


func _run_bench(only: String) -> void:
	_hud.visible = false
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(TownLayout.CITADEL_ORIGIN).round()
	await _bf.wait_frames(10)
	if only != "":
		_cast(PowerBook.get_power(only), TownLayout.CITADEL_ORIGIN + Vector2(-3.0, 2.0), {"dir": Vector2(1, 0)})
	await _bf.bench("town-" + (only if only != "" else "idle"))
	await _bf.quit()
