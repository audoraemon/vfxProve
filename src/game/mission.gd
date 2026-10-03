class_name Mission
extends Node2D
## One mission of Kingdoms Amid Kataclysm: the battlefield, the town of Aldermere, its people, the rules, the
## aiming and the HUD. The player picks a power with 1-6, clicks or drags to cast it, pans with WASD or the
## middle button and zooms with the wheel. R starts a fresh mission. Milestone 4 puts the Title, Prepare,
## Pause and Results screens around this.

## The run is over, with everything the Results screen shows (Rules.result()).
signal finished(result: Dictionary)
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
## Pan limits (screen px): the map is 60 x 60 units since the town scale upgrade. The furthest zoom out: below 0.5
## the pixel art shrinks past legibility -- cobbles shimmer and people vanish (playtest, 2026-09-27).
const PAN_MIN := Vector2(-1700, -900)
const PAN_MAX := Vector2(1700, 1000)
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
## A slot's hotkey: 1-6, for up to six slots (v0.08).
const SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
## Grass, the same clear colour the debug scene uses.
const CLEAR := Color("6e8230")

## The mission opens with the camera sweeping in under its banner (Last Judgement: to the Citadel, MANIFEST), and
## the clock only starts when it arrives (spec §1). Where it sweeps from and to is the mission's (MissionDef).
const INTRO_SECONDS := 2.0
## The sweep starts as far out as the zoom goes.
const INTRO_FROM_ZOOM := ZOOM_MIN
## How close the camera rests for play.
const PLAY_ZOOM := 0.6

## The ending plays out in slow motion before the results: the last blow lands, the dust settles, then the
## numbers (playtest note 5: three seconds between the mission's end and the results). Real seconds, and the
## time scale the world runs at meanwhile.
const ENDING_SECONDS := 3.0
const ENDING_TIME_SCALE := 0.3

## The scripted run: [seconds, slot, ground, drag direction or Vector2.ZERO].
## Spaced so each power has finished before the next is cast (Rules.busy_left()): Heaven 8.5 s, Cinderfall 12,
## Tsunami 9.5.
const TEST_CASTS := [
	[1.0, 0, Vector2(-9.0, -11.0), Vector2(0.2, 1.0)],
	[10.0, 2, Vector2(0.8, 2.2), Vector2.ZERO],
	[22.5, 1, Vector2(-12.0, 1.0), Vector2(1.0, 0.1)],
	[32.5, 3, TownLayout.CITADEL_ORIGIN, Vector2.ZERO],
]
const TEST_SHOTS := [0.5, 2.0, 12.0, 24.0, 34.0, 44.0]
## How many banner frames the scripted run takes before it stops bothering.
const BANNER_SHOTS := 3
const TEST_END := 34.0
## The Warning's scripted run (v0.08, --mission=warning --mission-test) casts nothing and lets the bell ring: frames
## of the start, the falling star, the watchman's run under his marker, and -- the camera turned west, to
## WARNING_LOOK_AT, between WARNING_LOOK_AWAY's two times -- the edge arrow pointing back at the messenger.
const WARNING_SHOTS := [0.5, 2.5, 9.0, 15.0]
const WARNING_LOOK_AWAY := [14.0, 16.0]
const WARNING_LOOK_AT := Vector2(-12.0, 8.0)
const WARNING_TEST_END := 45.0

var _bf: Battlefield
var _town: Town
var _grid: WalkGrid
var _crowd: Crowd
var _rules: Rules
var _aim: Targeting
var _hud: Hud
## F4: the citizens' intents, the alarm stage and the gates (v0.04 debug).
var _overlay: BehaviourOverlay
## The difficulty (v0.05): Game sets it before start(); a standalone run reads --difficulty=<name>.
var difficulty := ResponseProfile.DEFAULT
## The mission to play (v0.08): Game sets it before start(); a standalone run reads --mission=<id>.
var mission_id := MissionBook.LAST_JUDGEMENT
## The mission being played, and its director (null for a mission without scripted actors).
var _def: MissionDef
var _director: MissionDirector
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
## True from the last blow to Results: the slow-motion ending is playing out (note 9).
var _ending := false
## Seconds until the battle's layers are next fed how far the city has fallen.
var _music_in := 0.0


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
	_bf.ctx.env.structure_blighted.connect(_on_structure_blighted)
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
		await _quit()


## A fresh mission: clear the world, build the town, spawn the people, hand out 100 DP and six minutes.
## `powers` is the drafted loadout in slot order; an empty array falls back to the command line's or the
## default four, so a standalone run still works.
func start(powers: PackedStringArray, seed_value: int) -> void:
	if _director != null:
		_director.teardown()
		if is_instance_valid(_rules):
			_rules.director = null  # already let go: the old rules' teardown below must not do it twice
	_director = null
	_bf.reset(seed_value)
	for n: Node in [_town, _crowd, _rules, _aim, _hud, _overlay]:
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
	_bf.ctx.crowd = _crowd
	_crowd.sfx = _bf.ctx.sfx
	_town.sfx = _bf.ctx.sfx
	var args := OS.get_cmdline_user_args()
	_def = _mission_def(args)
	var tier := difficulty
	if autostart and Battlefield.arg_value(args, "--difficulty") != "":
		tier = ResponseProfile.tier_named(Battlefield.arg_value(args, "--difficulty"))
	_crowd.profile = _def.response_profile(tier)
	var wanted := Battlefield.arg_value(args, "--people")
	var people := int(wanted) if wanted != "" else PEOPLE
	var citizens := roundi(float(people) * float(Crowd.CITIZENS) / float(PEOPLE))
	_crowd.spawn(citizens, people - citizens)

	_rules = Rules.new()
	_rules.name = "Rules"
	add_child(_rules)
	var loadout := powers if not powers.is_empty() else _loadout(OS.get_cmdline_user_args())
	_rules.setup(loadout, _bf.ctx, _bf.ctx.env, _bf.ctx.field, _crowd, _town, _def)
	_rules.over.connect(_on_over)
	if _def.director != null:
		_director = (_def.director.new() as MissionDirector).setup(_rules, _crowd, _town, _bf.ctx)
		_rules.director = _director
	_crowd.rallied.connect(func(): _rules.banner.emit("SOLDIERS RALLY"))
	if _crowd.bell != null:
		_crowd.bell.climbing_started.connect(func():
			_rules.banner.emit(bell_hand(_crowd.bell) + " CLIMBS THE TOWER"))  # (after a takeover too)
		_crowd.bell.rung.connect(func(): _rules.banner.emit("THE BELL TOLLS - THE TOWN IS WARNED"))
		_crowd.bell.silenced.connect(func(_why: String): _rules.banner.emit("THE BELL IS SILENCED"))
		_crowd.bell.keeper_replaced.connect(func():
			_rules.banner.emit(bell_hand(_crowd.bell) + " TAKES THE BELL ROPE"))
	if _crowd.engineers != null and not _crowd.engineers.teams.is_empty():
		_crowd.engineers.turned_out.connect(func(): _rules.banner.emit("THE ENGINEERS TURN OUT"))
		_crowd.engineers.rebuilt.connect(func(s: Structure):
			var what := "THE DOCK" if s.role == &"dock" else ("THE BRIDGE" if s.kind == Structure.Kind.BRIDGE else
				("THE POSTERN" if s.art_tag == &"postern" else
				("THE MAIN GATE" if s.footprint == TownLayout.MAIN_GATE else "THE SIDE GATE")))
			_rules.banner.emit(what + " IS REBUILT"))
	if _crowd.ferry != null and _crowd.ferry.state != RiverFerry.State.ENDED:
		_crowd.ferry.opened.connect(func(): _rules.banner.emit("BOATS TAKE PEOPLE FROM THE DOCK"))
		_crowd.ferry.closed.connect(func(_why: String): _rules.banner.emit("THE BOATS ARE STOPPED"))
	if _crowd.marshals != null:
		_crowd.marshals.posted.connect(func(): _rules.banner.emit("THE SOLDIERS TAKE THE GATES"))
	if _crowd.rescue != null:
		_crowd.rescue.first_rescue.connect(func(): _rules.banner.emit("SURVIVORS DUG FROM THE RUBBLE"))
	if _crowd.rite != null and _crowd.rite.state != BanishingRite.State.ENDED:
		var rite := _crowd.rite
		rite.gathering.connect(func(): _rules.banner.emit("THE CLERGY GATHER AT THE CATHEDRAL"))
		rite.started.connect(func(): _rules.banner.emit("THE BANISHING RITE BEGINS"))
		rite.broken.connect(func(_why: String): _rules.banner.emit("THE RITE IS BROKEN"))
		rite.ended.connect(func(_why: String): _rules.banner.emit("THE RITE IS ENDED"))
		rite.completed.connect(func():
			_rules.lose_time(BanishingRite.PENALTY)
			_rules.banner.emit("THE CLERGY BANISH YOU - %d s LOST" % roundi(BanishingRite.PENALTY)))

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
	_overlay = BehaviourOverlay.new().setup(_crowd, _bf)
	_overlay.name = "BehaviourOverlay"
	if "--behaviour" in OS.get_cmdline_user_args():
		BehaviourOverlay.shown = true
	add_child(_overlay)

	if _scripted:
		# The scripted runs time their casts from the first frame and frame the town the way milestone 3 did,
		# so their captures and numbers stay comparable: no intro for them.
		_intro_left = 0.0
		_bf.camera.zoom = Vector2.ONE * PLAY_ZOOM
		var framed := Vector2(0, -2) if _def.id == MissionBook.LAST_JUDGEMENT else _def.camera_at
		_bf.camera.position = Iso.ground_to_screen(framed).round()
	else:
		_intro_left = INTRO_SECONDS
		_rules.set_process(false)  # the clock waits for the camera
		_bf.camera.zoom = Vector2.ONE * INTRO_FROM_ZOOM
		_bf.camera.position = Iso.ground_to_screen(_def.intro_from).round()
		if _def.intro_banner != "":
			_rules.banner.emit(_def.intro_banner)


## True while the sweep is still landing: the world does not yet respond to input or run its clock.
## The running mission's rules (its clock, DP, stability), for whoever drives it. Null until started().
func rules() -> Rules:
	return _rules


func in_intro() -> bool:
	return _intro_left > 0.0


## The mission to play: Game's choice, or for a standalone run the command line's --mission=<id> (v0.08).
func _mission_def(args: PackedStringArray) -> MissionDef:
	var wanted_mission := Battlefield.arg_value(args, "--mission") if autostart else ""
	return MissionBook.get_mission(wanted_mission if wanted_mission != "" else mission_id)


## The drafted loadout: the command line's, or the mission's default. _ready() asks before start() has chosen the
## mission, so it is looked up here when there is none yet.
func _loadout(args: PackedStringArray) -> PackedStringArray:
	var wanted := Battlefield.arg_value(args, "--loadout")
	var def := _def if _def != null else _mission_def(args)
	var keys := PackedStringArray(def.default_loadout)
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


## Blight landed (v0.05): what it ruined, for the player -- the town itself is not told.
func _on_structure_blighted(s: Structure) -> void:
	if is_instance_valid(_rules):
		_rules.banner.emit(blight_banner(s))


## Who is on the bell rope, for its banners: the bellkeeper, a soldier who took it over (v0.07), or the watchman -- or
## a citizen the warning passed to -- climbing in a dead keeper's place (v0.08, The Warning).
static func bell_hand(bell: BellNetwork) -> String:
	if not is_instance_valid(bell.keeper):
		return "THE BELLKEEPER"
	var p := bell.keeper
	if p.soldier:
		return "A SOLDIER"
	if p.profile == null or p.profile.role == CitizenProfile.Role.BELLKEEPER:
		return "THE BELLKEEPER"
	return "THE WATCHMAN" if p.profile.role == CitizenProfile.Role.WATCHMAN else "A CITIZEN"


static func blight_banner(s: Structure) -> String:
	if s.art_tag == &"bell_tower":
		return "BLIGHT - THE BELL IS CRACKED"
	if s.role == &"temple":
		return "BLIGHT - THE CATHEDRAL IS DEFILED"
	if s.role == &"dock":
		return "BLIGHT - THE DOCK ROTS"
	if s.kind == Structure.Kind.GATE:
		var which := "THE POSTERN" if s.art_tag == &"postern" else (
			"THE MAIN GATE" if s.footprint == TownLayout.MAIN_GATE else "THE SIDE GATE")
		return "BLIGHT - %s IS JAMMED" % which
	return "BLIGHT - THE %s IS POISONED" % ("WELL" if s.art_tag == &"well" else "FOUNTAIN")


func _on_over(won: bool, reason: String) -> void:
	_rules.banner.emit(ResultsScreen.title_for(won, reason))
	if _scripted:
		# The scripted runs have no Results screen to show, so they keep printing what they found.
		if _rules.mission.scored:
			print("MISSION result won=%s reason=%s score=%d rank=%s" % [won, reason, _rules.score(), _rules.rank()])
			for line: Dictionary in _rules.stat_lines():
				print("  %-22s %8s %6d" % [line.label, line.value, line.points])
		else:
			var res := _rules.result()
			print("MISSION result won=%s reason=%s time=%.1f relays=%s" % [won, reason, float(res.time),
				res.get("relays", 0)])
	_play_ending()


func _play_ending() -> void:
	_ending = true
	_aim.unfocus()
	if not _scripted:
		# The scripted runs keep milestone 3's timing: no slow motion for them.
		_bf.ctx.impact.set_base_time_scale(ENDING_TIME_SCALE)
		await get_tree().create_timer(ENDING_SECONDS, true, false, true).timeout
		_bf.ctx.impact.set_base_time_scale(1.0)
	finished.emit(_rules.result())


func _unhandled_input(event: InputEvent) -> void:
	if not started():
		return
	if _ending:
		return  # the mission is over; nothing to aim or pause
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
				_quit()
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
	if not _ending:
		_music_in -= delta
		if _music_in <= 0.0:
			_music_in = 0.5
			Music.set_intensity(1.0 - _rules.stability.total())
	if _intro_left > 0.0:
		_intro_left = maxf(0.0, _intro_left - delta)
		var k := 1.0 - _intro_left / INTRO_SECONDS
		var smooth := k * k * (3.0 - 2.0 * k)  # not "ease": that is a global function, and shadowing it warns
		_bf.camera.position = Iso.ground_to_screen(_def.intro_from.lerp(_def.camera_at, smooth)).round()
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


## A fixed mission: four casts on a timetable, screenshots at the interesting moments, and one result line. The
## Warning's (v0.08) casts nothing: see WARNING_SHOTS.
func _mission_test() -> void:
	var judgement := _def.id == MissionBook.LAST_JUDGEMENT
	var prefix := "mission" if judgement else _def.id
	if judgement:
		# Aim the Nova at the Citadel and cast nothing: the first screenshot is the aim preview on a whole town.
		_aim.pick(3)
		_aim.hover(TownLayout.CITADEL_ORIGIN)
	var casts := TEST_CASTS.duplicate() if judgement else []
	var shots := TEST_SHOTS.duplicate() if judgement else WARNING_SHOTS.duplicate()
	var looks := [] if judgement else WARNING_LOOK_AWAY.duplicate()
	var framed := _bf.camera.position
	var end := TEST_END if judgement else WARNING_TEST_END
	# Banners are the one thing a fixed timetable cannot catch: they fire when the town happens to break. The
	# run takes its own shot a moment after each of the first few, so the layout is actually seen.
	var banner_shots: Array[String] = []
	_rules.banner.connect(func(text: String) -> void:
		if banner_shots.size() < BANNER_SHOTS:
			banner_shots.append(text)
	)
	var banners_taken := 0
	var t := 0.0
	while t < end:
		await get_tree().process_frame
		t += get_process_delta_time()
		if not looks.is_empty() and t >= float(looks[0]):
			looks.pop_front()
			_bf.camera.position = framed if looks.is_empty() else Iso.ground_to_screen(WARNING_LOOK_AT).round()
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
			await _bf.save_capture("%s_%04d.png" % [prefix, roundi(at * 100.0)])
		while banners_taken < banner_shots.size():
			banners_taken += 1
			await _bf.save_capture("%s_banner_%d.png" % [prefix, banners_taken])
			print("banner ", banners_taken, ": ", banner_shots[banners_taken - 1])
	print("MISSION test buildings=%d citizens=%d escaped=%d alarm=%d stability=%d%% citadel=%d%%" % [
		_rules.buildings_down, _crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm),
		roundi(_rules.stability.total() * 100.0), roundi(_town.citadel.fraction() * 100.0)])
	await _quit()


## Whether start() has run. Between add_child() and the end of the shader prewarm there is a battlefield but
## no town, rules or aim yet, and nothing in the mission may touch them.
func started() -> bool:
	return is_instance_valid(_rules)


## Battlefield.quit() stops its own Sfx pool and waits out the audio thread before it exits; the crowd's panic
## bed is not in that pool, so it is silenced first, or a bed still playing at that moment leaks its playback.
func _quit() -> void:
	if is_instance_valid(_crowd):
		_crowd.stop_bed()
	await _bf.quit()


## Stop the world without stopping the menu over it. The whole mission lives under this node, so pausing the
## subtree freezes the town, the crowd, the effects and the clock together.
func set_frozen(frozen: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	if is_instance_valid(_crowd):
		_crowd.pause_bed(frozen)
