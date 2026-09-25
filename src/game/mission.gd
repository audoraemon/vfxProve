extends Node2D
## One mission of Kingdoms Amid Kataclysm: the battlefield, the town of Aldermere, its people, the rules, the
## aiming and the HUD. The player picks a power with 1-4, clicks or drags to cast it, pans with WASD or the
## middle button and zooms with the wheel. R starts a fresh mission. Milestone 4 puts the Title, Prepare,
## Pause and Results screens around this.

## The four powers a mission starts with until the Prepare screen exists (milestone 4). Override on the
## command line: -- --loadout=heaven,gravity,judgement,nova
const DEFAULT_LOADOUT := ["heaven", "tsunami", "cinder", "nova"]
const PEOPLE := Crowd.CITIZENS + Crowd.SOLDIERS
const PAN_SPEED := 320.0
const PAN_MIN := Vector2(-760, -380)
const PAN_MAX := Vector2(760, 520)
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
const SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4]
## Grass, the same clear colour the debug scene uses.
const CLEAR := Color("4a6a2a")

## The scripted run: [seconds, slot, ground, drag direction or Vector2.ZERO].
const TEST_CASTS := [
	[1.0, 0, Vector2(-1.0, -6.0), Vector2(0.2, 1.0)],
	[6.0, 2, Vector2(2.6, 2.2), Vector2.ZERO],
	[14.0, 1, Vector2(-7.0, 1.0), Vector2(1.0, 0.1)],
	[24.0, 3, TownLayout.CITADEL_ORIGIN, Vector2.ZERO],
]
const TEST_SHOTS := [0.5, 2.0, 8.0, 16.0, 26.0, 30.0]
const TEST_END := 34.0

var _bf: Battlefield
var _town: Town
var _grid: WalkGrid
var _crowd: Crowd
var _rules: Rules
var _aim: Targeting
var _hud: Hud
var _pressing := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	_bf.ctx.impact.dim_scale = 0.4
	_bf.ctx.field.bounds = TownLayout.MAP
	# Connected here and not in _start(): the field outlives a restart, so connecting per mission would stack
	# up a handler for every mission the player has played.
	_bf.ctx.env.structure_destroyed.connect(_on_structure_destroyed)
	var args := OS.get_cmdline_user_args()
	var scripted := "--mission-test" in args or "--bench" in args
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var seed_value := int(seed_arg) if seed_arg != "" else (7 if scripted else Time.get_ticks_usec())
	_start(seed_value)
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(Vector2(0, -2)).round()
	await FxParts.prewarm(_bf.ctx.distort)
	if "--mission-test" in args:
		_mission_test()
	elif "--bench" in args:
		# Both awaited: unawaited, quit()'s handful of frames beats bench()'s 9-second loop to
		# get_tree().quit() and the run ends before a bench[...] line is ever printed.
		await _bf.bench("mission")
		await _bf.quit()


## A fresh mission: clear the world, build the town, spawn the people, hand out 100 DP and four minutes.
func _start(seed_value: int) -> void:
	_bf.reset(seed_value)
	for n: Node in [_town, _crowd, _rules, _aim, _hud]:
		if is_instance_valid(n):
			if n is Town:
				(n as Town).teardown()
			elif n is Crowd:
				(n as Crowd).clear()
			elif n is Rules:
				# The old rules let the world go before the new ones take it: queue_free() is deferred, and a
				# frame with two Rules connected would count the next destroyed building twice.
				(n as Rules).teardown()
			# Parents may be mid-teardown here, so never free a tree-resident node immediately.
			if n.is_inside_tree():
				n.queue_free()
			else:
				n.free()
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_grid = WalkGrid.new().setup(_bf.ctx.env, _town)
	_crowd = Crowd.new()
	_crowd.name = "Crowd"
	add_child(_crowd)
	_crowd.setup(_bf.ctx.field, _bf.ctx.env, _town, _grid, _bf.ctx.world, seed_value)
	var args := OS.get_cmdline_user_args()
	var wanted := Battlefield.arg_value(args, "--people")
	var people := int(wanted) if wanted != "" else PEOPLE
	var citizens := roundi(float(people) * float(Crowd.CITIZENS) / float(PEOPLE))
	_crowd.spawn(citizens, people - citizens)

	_rules = Rules.new()
	_rules.name = "Rules"
	add_child(_rules)
	_rules.setup(_loadout(args), _bf.ctx, _bf.ctx.env, _bf.ctx.field, _crowd, _town)
	_rules.over.connect(_on_over)
	_crowd.rallied.connect(func(): _rules.banner.emit("SOLDIERS RALLY"))

	_aim = Targeting.new()
	_aim.name = "Targeting"
	_bf.ground_plane.add_child(_aim)
	_aim.setup(_rules, _crowd)

	_hud = Hud.new()
	_hud.name = "Hud"
	_bf.hud_layer.add_child(_hud)
	_hud.setup(_rules, _crowd, _town, _aim)


## The drafted loadout: the command line's, or the default four.
func _loadout(args: PackedStringArray) -> PackedStringArray:
	var wanted := Battlefield.arg_value(args, "--loadout")
	var keys := PackedStringArray(DEFAULT_LOADOUT)
	if wanted != "":
		keys = PackedStringArray()
		for key in wanted.split(","):
			if PowerBook.get_power(key).is_empty():
				push_warning("Unknown power in --loadout: " + key)
			else:
				keys.append(key)
	return keys


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if is_instance_valid(_town) and is_instance_valid(_rules) and s == _town.bridge:
		_rules.banner.emit("THE BRIDGE HAS FALLEN")


func _on_over(won: bool, reason: String) -> void:
	var title := "THE CITY HAS FALLEN"
	if not won:
		title = "THE PEOPLE ESCAPED" if reason == "escapes" else "MANIFESTATION ENDED"
	_rules.banner.emit(title)
	# Milestone 4 turns this into the Results screen; until then the numbers go to the console.
	print("MISSION result won=%s reason=%s score=%d rank=%s" % [won, reason, _rules.score(), _rules.rank()])
	for line: Dictionary in _rules.stat_lines():
		print("  %-22s %8s %6d" % [line.label, line.value, line.points])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var i := SLOT_KEYS.find(event.physical_keycode)
		if i >= 0 and i < _rules.loadout.size():
			_aim.pick(i)
		elif event.physical_keycode == KEY_R:
			_start(Time.get_ticks_usec())
		elif event.physical_keycode == KEY_ESCAPE:
			# Aiming first: Esc cancels a drag, and only quits when there is nothing to cancel (Pause is
			# milestone 4's).
			if _aim.aiming:
				_aim.cancel()
			else:
				_bf.quit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_aim.cancel()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_aim.press(_bf.mouse_ground())
		elif _pressing:
			_pressing = false
			_aim.release(_bf.mouse_ground())


func _process(delta: float) -> void:
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	_aim.hover(_bf.mouse_ground())


func _pan(by: Vector2) -> void:
	_bf.camera.position = (_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX)


## A fixed mission: four casts on a timetable, screenshots at the interesting moments, and one result line.
func _mission_test() -> void:
	var casts := TEST_CASTS.duplicate()
	var shots := TEST_SHOTS.duplicate()
	var t := 0.0
	while t < TEST_END:
		await get_tree().process_frame
		t += get_process_delta_time()
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			var slot := int(c[1])
			var extra := {}
			if (c[3] as Vector2) != Vector2.ZERO:
				extra["dir"] = (c[3] as Vector2).normalized()
			_rules.cast(slot, c[2], extra)
		while not shots.is_empty() and t >= float(shots[0]):
			var at: float = shots.pop_front()
			await _bf.save_capture("mission_%04d.png" % roundi(at * 100.0))
	print("MISSION test dp=%.1f buildings=%d citizens=%d escaped=%d alarm=%d stability=%d%% citadel=%d%%" % [
		_rules.dp, _rules.buildings_down, _crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm),
		roundi(_rules.stability.total() * 100.0), roundi(_town.citadel.fraction() * 100.0)])
	_bf.quit()
