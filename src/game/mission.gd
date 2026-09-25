class_name Mission
extends Node2D
## One mission of Kingdoms Amid Kataclysm: the battlefield, the town of Aldermere, its people, the rules, the
## aiming and the HUD. The player picks a power with 1-4, clicks or drags to cast it, pans with WASD or the
## middle button and zooms with the wheel. R starts a fresh mission. Milestone 4 puts the Title, Prepare,
## Pause and Results screens around this.

## The run is over, with everything the Results screen shows.
signal finished(won: bool, reason: String, score: int, rank: String, lines: Array[Dictionary])
## Esc with nothing to cancel: whoever owns this mission decides what that means.
signal pause_pressed
## The effect shaders are compiled and the mission can start. start() before this would clear the effect
## layers under the prewarm while it is still using them.
signal prewarmed

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

## The mission opens with the camera sweeping in to the Citadel under a MANIFEST banner, and the clock only
## starts when it arrives (spec §1).
const INTRO_SECONDS := 2.0
## Where the sweep starts: the whole town, from further out.
const INTRO_FROM := Vector2(0.0, 3.0)
const INTRO_FROM_ZOOM := 0.5
## Where the camera rests for play, and how close.
const PLAY_ZOOM := 0.75

## The scripted run: [seconds, slot, ground, drag direction or Vector2.ZERO].
const TEST_CASTS := [
	[1.0, 0, Vector2(-1.0, -6.0), Vector2(0.2, 1.0)],
	[6.0, 2, Vector2(2.6, 2.2), Vector2.ZERO],
	[14.0, 1, Vector2(-7.0, 1.0), Vector2(1.0, 0.1)],
	[24.0, 3, TownLayout.CITADEL_ORIGIN, Vector2.ZERO],
]
const TEST_SHOTS := [0.5, 2.0, 8.0, 16.0, 26.0, 30.0]
## How many banner frames the scripted run takes before it stops bothering.
const BANNER_SHOTS := 3
const TEST_END := 34.0

var _bf: Battlefield
var _town: Town
var _grid: WalkGrid
var _crowd: Crowd
var _rules: Rules
var _aim: Targeting
var _hud: Hud
var _pressing := false
## A scripted run (--mission-test, --bench) has no mouse: the cursor sits whereever the desktop left it, which
## is off the map, so the aim preview follows the script instead of it.
var _scripted := false
## True when the mission runs on its own (play.bat before milestone 4, the scripted runs, the bench) and
## starts itself. Game sets it false before adding the node, then calls start() with the drafted loadout.
var autostart := true
## True once _ready() has finished compiling the effect shaders.
var is_prewarmed := false
## Seconds of intro left; 0 once the mission is under way.
var _intro_left := 0.0


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
	_scripted = scripted
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var seed_value := int(seed_arg) if seed_arg != "" else (7 if scripted else Time.get_ticks_usec())
	if autostart:
		start(_loadout(args), seed_value)
	await FxParts.prewarm(_bf.ctx.distort)
	is_prewarmed = true
	prewarmed.emit()
	if "--mission-test" in args:
		_mission_test()
	elif "--bench" in args:
		# Both awaited: unawaited, quit()'s handful of frames beats bench()'s 9-second loop to
		# get_tree().quit() and the run ends before a bench[...] line is ever printed.
		await _bf.bench("mission")
		await _bf.quit()


## A fresh mission: clear the world, build the town, spawn the people, hand out 100 DP and four minutes.
## `powers` is the drafted loadout in slot order; an empty array falls back to the command line's or the
## default four, so a standalone run still works.
func start(powers: PackedStringArray, seed_value: int) -> void:
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
	_crowd.sfx = _bf.ctx.sfx
	var args := OS.get_cmdline_user_args()
	var wanted := Battlefield.arg_value(args, "--people")
	var people := int(wanted) if wanted != "" else PEOPLE
	var citizens := roundi(float(people) * float(Crowd.CITIZENS) / float(PEOPLE))
	_crowd.spawn(citizens, people - citizens)

	_rules = Rules.new()
	_rules.name = "Rules"
	add_child(_rules)
	var loadout := powers if not powers.is_empty() else _loadout(OS.get_cmdline_user_args())
	_rules.setup(loadout, _bf.ctx, _bf.ctx.env, _bf.ctx.field, _crowd, _town)
	_rules.over.connect(_on_over)
	_crowd.rallied.connect(func(): _rules.banner.emit("SOLDIERS RALLY"))

	_aim = Targeting.new()
	_aim.name = "Targeting"
	_bf.ground_plane.add_child(_aim)
	_aim.setup(_rules, _crowd)
	_aim.picked.connect(func(s: int) -> void:
		if s >= 0:
			UiSound.play(&"ui_focus"))

	_hud = Hud.new()
	_hud.name = "Hud"
	_bf.hud_layer.add_child(_hud)
	_hud.setup(_rules, _crowd, _town, _aim)

	if _scripted:
		# The scripted runs time their casts from the first frame and frame the town the way milestone 3 did,
		# so their captures and numbers stay comparable: no intro for them.
		_intro_left = 0.0
		_bf.camera.zoom = Vector2.ONE * PLAY_ZOOM
		_bf.camera.position = Iso.ground_to_screen(Vector2(0, -2)).round()
	else:
		_intro_left = INTRO_SECONDS
		_rules.set_process(false)  # the clock waits for the camera
		_bf.camera.zoom = Vector2.ONE * INTRO_FROM_ZOOM
		_bf.camera.position = Iso.ground_to_screen(INTRO_FROM).round()
		_rules.banner.emit("MANIFEST")


## True while the sweep is still landing: the world does not yet respond to input or run its clock.
## The running mission's rules (its clock, DP, stability), for whoever drives it. Null until started().
func rules() -> Rules:
	return _rules


func in_intro() -> bool:
	return _intro_left > 0.0


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
	if _scripted:
		# The scripted runs have no Results screen to show, so they keep printing what they found.
		print("MISSION result won=%s reason=%s score=%d rank=%s" % [won, reason, _rules.score(), _rules.rank()])
		for line: Dictionary in _rules.stat_lines():
			print("  %-22s %8s %6d" % [line.label, line.value, line.points])
	finished.emit(won, reason, _rules.score(), _rules.rank(), _rules.stat_lines())


func _unhandled_input(event: InputEvent) -> void:
	if not started():
		return
	if in_intro() and not (event is InputEventKey and event.physical_keycode == KEY_ESCAPE):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var i := SLOT_KEYS.find(event.physical_keycode)
		if i >= 0 and i < _rules.loadout.size():
			_aim.pick(i)
		elif event.physical_keycode == KEY_R:
			start(PackedStringArray(), Time.get_ticks_usec())
		elif event.physical_keycode == KEY_ESCAPE:
			# Esc first calls off a held press, then unfocuses the power. With nothing focused it is the
			# pause menu's -- or, for a mission running on its own with no Game around it, still the way out.
			if _aim.cancel():
				pass  # a held press was called off
			elif _aim.slot >= 0:
				_aim.unfocus()
			elif autostart:
				_bf.quit()
			else:
				# Handled here, so the same Esc cannot reach the pause menu it is about to open and close it again.
				get_viewport().set_input_as_handled()
				pause_pressed.emit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right-click first calls off a held press (note 10), and otherwise lets go of the focused power (note 7).
		if not _aim.cancel():
			_aim.unfocus()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# A click on a HUD slot focuses that power instead of casting into the town under it.
			var on_slot := _hud.slot_at(event.position)
			if on_slot >= 0 and on_slot < _rules.loadout.size():
				_aim.pick(on_slot)
				return
			_pressing = true
			_aim.press(_bf.mouse_ground())
		elif _pressing:
			_pressing = false
			_aim.release(_bf.mouse_ground())


func _process(delta: float) -> void:
	if not started():
		return
	if _intro_left > 0.0:
		_intro_left = maxf(0.0, _intro_left - delta)
		var k := 1.0 - _intro_left / INTRO_SECONDS
		var smooth := k * k * (3.0 - 2.0 * k)  # not "ease": that is a global function, and shadowing it warns
		_bf.camera.position = Iso.ground_to_screen(INTRO_FROM.lerp(TownLayout.CITADEL_ORIGIN, smooth)).round()
		_bf.camera.zoom = Vector2.ONE * lerpf(INTRO_FROM_ZOOM, PLAY_ZOOM, smooth)
		if _intro_left <= 0.0:
			_rules.set_process(true)
		return  # the camera is the intro's until it lands: no panning, no aiming
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	if not _scripted:
		_aim.hover(_bf.mouse_ground())


func _pan(by: Vector2) -> void:
	_bf.camera.position = (_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX)


## A fixed mission: four casts on a timetable, screenshots at the interesting moments, and one result line.
func _mission_test() -> void:
	# Aim the Nova at the Citadel and cast nothing: the first screenshot is the aim preview on a whole town.
	_aim.pick(3)
	_aim.hover(TownLayout.CITADEL_ORIGIN)
	var casts := TEST_CASTS.duplicate()
	var shots := TEST_SHOTS.duplicate()
	# Banners are the one thing a fixed timetable cannot catch: they fire when the town happens to break. The
	# run takes its own shot a moment after each of the first few, so the layout is actually seen.
	var banner_shots: Array[String] = []
	_rules.banner.connect(func(text: String) -> void:
		if banner_shots.size() < BANNER_SHOTS:
			banner_shots.append(text)
	)
	var banners_taken := 0
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
			# Aim first, so the captured frames show the preview and the picked slot the way a player would see
			# them. Nothing moves the mouse in a scripted run, and the cursor's own ground position is off-map.
			_aim.pick(slot)
			_aim.hover(c[2])
			_rules.cast(slot, c[2], extra)
		while not shots.is_empty() and t >= float(shots[0]):
			var at: float = shots.pop_front()
			await _bf.save_capture("mission_%04d.png" % roundi(at * 100.0))
		while banners_taken < banner_shots.size():
			banners_taken += 1
			await _bf.save_capture("mission_banner_%d.png" % banners_taken)
			print("banner ", banners_taken, ": ", banner_shots[banners_taken - 1])
	print("MISSION test dp=%.1f buildings=%d citizens=%d escaped=%d alarm=%d stability=%d%% citadel=%d%%" % [
		_rules.dp, _rules.buildings_down, _crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm),
		roundi(_rules.stability.total() * 100.0), roundi(_town.citadel.fraction() * 100.0)])
	_bf.quit()


## Whether start() has run. Between add_child() and the end of the shader prewarm there is a battlefield but
## no town, rules or aim yet, and nothing in the mission may touch them.
func started() -> bool:
	return is_instance_valid(_rules)


## Stop the world without stopping the menu over it. The whole mission lives under this node, so pausing the
## subtree freezes the town, the crowd, the effects and the clock together.
func set_frozen(frozen: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
