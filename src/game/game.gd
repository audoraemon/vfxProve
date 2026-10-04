class_name Game
extends Node
## The game: which screen is up, what the save file remembers, and the mission it runs. Screens are children
## it makes and frees one at a time; each tells it what the player pressed through a "<screen>:<action>"
## string, and FLOW says where that leads. Keeping the flow as data is what makes it provable without
## building a single screen.

enum Screen {TITLE, BOARD, PREPARE, MISSION, RESULTS}

## Where every button leads (spec §1; v0.08 puts the mission board between the Title and Prepare, and Results and
## Pause go back to it). Pause is not a screen of its own: it sits over the mission, which is why "pause:resume"
## leads back to MISSION -- on_action() resumes that mission rather than building a new one.
const FLOW := {
	"title:play": Screen.BOARD,
	"board:pick": Screen.PREPARE,
	"board:back": Screen.TITLE,
	"prepare:manifest": Screen.MISSION,
	"prepare:back": Screen.BOARD,
	"mission:over": Screen.RESULTS,
	"results:replay": Screen.MISSION,
	"results:change": Screen.PREPARE,
	"results:missions": Screen.BOARD,
	"pause:resume": Screen.MISSION,
	"pause:restart": Screen.MISSION,
	"pause:change": Screen.PREPARE,
	"pause:missions": Screen.BOARD,
}

const MISSION_SCENE := "res://scenes/mission.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox.tscn"
## The fade into a mission: out to black, the mission loads behind it, back in once its town is there.
const FADE_OUT := 0.25
const FADE_IN := 0.35
## Where --flow-test keeps its save, so a scripted run never touches the player's best score.
const FLOW_TEST_SAVE := "user://test_flow.cfg"
## Grass: what shows between screens, the same clear colour the mission uses.
const CLEAR := Color("6e8230")
## What --show=results displays: a winning run with every line of the table in use.
const SAMPLE_RESULT := {
	"mission": "last_judgement", "won": true, "reason": "citadel", "score": 15350, "rank": "S", "best": true,
	"lines": [
		{"label": "The city has fallen", "value": "", "points": 5000},
		{"label": "Time left", "value": "3:20", "points": 5000},
		{"label": "Buildings destroyed", "value": "60", "points": 2400},
		{"label": "Citizens killed", "value": "110", "points": 1100},
		{"label": "Soldiers killed", "value": "50", "points": 1250},
		{"label": "Citizens escaped", "value": "0", "points": 0},
		{"label": "Chains", "value": "2", "points": 600},
	],
}
## What --show=results-warning displays (v0.08): The Warning won unseen, its messenger killed by Silent Doom.
const SAMPLE_WARNING_RESULT := {
	"mission": "warning", "won": true, "reason": "warning", "time": 21.4, "best": true,
	"goal": {"label": "Stop the warning", "done": true}, "bonuses": [{"label": "Unseen", "earned": true}],
	"solved_by": ["VEIL"], "relays": 0,
}

var screen := Screen.TITLE
var save: SaveFile
## Where the save file lives: the real one, or FLOW_TEST_SAVE under --flow-test.
var save_path := SaveFile.PATH
## The four powers the player drafted, kept so Replay can run them again.
var loadout := PackedStringArray()
## The mission to play (v0.08): Last Judgement until the board picks one.
var mission_id := MissionBook.LAST_JUDGEMENT
## The last mission's numbers, for the Results screen: Rules.result() -- won, reason, score, rank, lines, ... --
## and best.
var result := {}

## The running mission. It outlives the MISSION screen by one step: the Results screen is drawn over its
## frozen ruins, which is the payoff for the whole run.
var _mission: Mission
## Title, the board, Prepare or Results: whichever full screen is up.
var _screen_node: Node
## The pause menu, while it is up. It sits over the mission instead of replacing it.
var _pause: PauseMenu
## Black over everything between screens, so a fresh mission's bare battlefield is never shown (note 6).
var _fader: Fader
## True while a MANIFEST/Replay/Restart fade is under way, so a second click cannot start a second one.
var _fading := false
## True once that fade has the new mission up, behind the black and then coming back in (v0.08.2): the player can
## already pause and Restart, or go to Prepare and MANIFEST again, and that request is kept for when the fade ends.
var _fading_in := false
## A MANIFEST/Replay/Restart pressed during a fade-in (v0.08.2), run when the fade ends. Any other screen change
## drops it: the player has gone somewhere else since.
var _mission_queued := false


## The screen an action leads to, or -1 when nothing offers it.
static func next_screen(action: String) -> int:
	return int(FLOW.get(action, -1))


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	var args := OS.get_cmdline_user_args()
	if "--flow-test" in args:
		save_path = FLOW_TEST_SAVE
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	save = SaveFile.new().load_from(save_path)
	mission_id = save.last_mission
	loadout = save.loadout_for(mission_id)
	# For the photographs (v0.08): --mission=<id> puts that mission on the board, Prepare or a paused run, with its
	# default loadout when nothing was drafted for it.
	var wanted := Battlefield.arg_value(args, "--mission")
	if wanted != "":
		mission_id = MissionBook.get_mission(wanted).id
		loadout = save.loadout_for(mission_id)
		if loadout.is_empty():
			loadout = MissionBook.get_mission(mission_id).default_loadout
	_fader = Fader.new()
	_fader.name = "Fader"
	add_child(_fader)
	var show := Battlefield.arg_value(args, "--show")
	match show:
		"board":
			go_to(Screen.BOARD)
		"prepare":
			go_to(Screen.PREPARE)
			var hover := Battlefield.arg_value(args, "--hover")
			if hover != "" and _screen_node is PrepareScreen:
				(_screen_node as PrepareScreen).preview(hover)
		"results":
			result = SAMPLE_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"results-warning":
			result = SAMPLE_WARNING_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"pause":
			go_to(Screen.MISSION)
			_open_pause()
		_:
			go_to(Screen.TITLE)
	if "--capture" in args:
		# A second for anything behind the screen to settle, then one frame to disk. This is how each screen
		# task shows its work: SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture
		# A mission underneath (the pause photograph) only builds its town once its shader prewarm is done,
		# which takes longer than that second -- the first pause capture showed the menu over bare grass.
		if is_instance_valid(_mission) and not _mission.started():
			await _mission.prewarmed
		await get_tree().create_timer(1.0).timeout
		await _capture("screen_%s.png" % (show if show != "" else "start"))
		await _quit_cleanly()
	elif "--flow-test" in args:
		await _flow_test()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		await _quit_cleanly()


## Put up a screen, taking down whatever was there.
func go_to(to: int) -> void:
	_close_pause()
	screen = to
	# A hit dips Engine.time_scale and the battlefield's Impact restores it from its own _process. A mission
	# freed mid-dip never restores it, and the whole game would stay in slow motion from then on.
	Engine.time_scale = 1.0
	if is_instance_valid(_screen_node):
		_screen_node.queue_free()
		_screen_node = null
	if to != Screen.RESULTS and is_instance_valid(_mission):
		_mission.queue_free()
		_mission = null
	match to:
		Screen.TITLE:
			var title := TitleScreen.new()
			title.name = "Title"
			add_child(title)
			title.setup(save.best_score, save.best_rank)
			title.action.connect(_on_title_action)
			_screen_node = title
		Screen.BOARD:
			var board := MissionBoard.new()
			board.name = "Board"
			add_child(board)
			board.setup(save, mission_id)
			board.action.connect(_on_board_action.bind(board))
			_screen_node = board
		Screen.PREPARE:
			var prep := PrepareScreen.new()
			prep.name = "Prepare"
			add_child(prep)
			prep.setup(MissionBook.get_mission(mission_id), loadout, save.difficulty)
			prep.action.connect(_on_prepare_action.bind(prep))
			_screen_node = prep
		Screen.MISSION:
			_mission = _build_mission()
		Screen.RESULTS:
			if is_instance_valid(_mission):
				_mission.set_frozen(true)
			var res := ResultsScreen.new()
			res.name = "Results"
			add_child(res)
			res.setup(result)
			UiSound.play(&"ui_win" if bool(result.get("won", false)) else &"ui_lose")
			res.action.connect(func(what: String) -> void: on_action("results:" + what))
			_screen_node = res
		_:
			push_warning("KAK screen %d has nothing to show yet" % to)  # Tasks 3 and 4
	match to:
		Screen.TITLE, Screen.BOARD, Screen.PREPARE:
			Music.play(&"theme")
		Screen.RESULTS:
			Music.play(&"")  # the win or lose sting stands alone


## What a screen reports the player pressed.
func on_action(action: String) -> void:
	if action == "pause:resume":
		_close_pause()
		if is_instance_valid(_mission):
			_mission.set_frozen(false)
		return
	var to := next_screen(action)
	if to < 0:
		push_warning("KAK ignored an unknown action: " + action)
		return
	if to == Screen.MISSION:
		_faded_into_mission()
		return
	_mission_queued = false
	go_to(to)


## Into a mission behind the fade. Not awaited by the caller: the button that asked for it has done its part.
func _faded_into_mission() -> void:
	if _fading:
		# During the fade out it is a second click on the same button: dropped. Once the mission is up it is a new
		# request from the mission now up (Restart) or from a Prepare reached through its pause menu (MANIFEST):
		# kept, and run once this fade has ended (v0.08.2; before, it was lost).
		if _fading_in:
			_mission_queued = true
		return
	_fading = true
	await _fader.fade_out(FADE_OUT)
	Music.play(&"battle")  # rises behind the fade
	go_to(Screen.MISSION)
	_fading_in = true
	if is_instance_valid(_mission) and not _mission.started():
		await _mission.prewarmed
	# Two frames for the town to be drawn once before it is shown.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fader.fade_in(FADE_IN)
	_fading_in = false
	_fading = false
	if _mission_queued:
		_mission_queued = false
		_faded_into_mission()


func _build_mission() -> Mission:
	var mission: Mission = load(MISSION_SCENE).instantiate()
	mission.autostart = false  # set before add_child(), so its _ready() does not start a mission of its own
	mission.difficulty = save.difficulty
	mission.mission_id = mission_id
	add_child(mission)
	mission.finished.connect(_on_mission_finished)
	mission.pause_pressed.connect(_open_pause)
	# Its _ready() is still compiling the effect shaders into the effect layers a frame or two after
	# add_child(), and start() clears those layers -- starting now freed the prewarm's nodes under it.
	var seed_value := Time.get_ticks_usec()
	if mission.is_prewarmed:
		mission.start(loadout, seed_value)
	else:
		mission.prewarmed.connect(func() -> void: mission.start(loadout, seed_value), CONNECT_ONE_SHOT)
	return mission


func _on_mission_finished(outcome: Dictionary) -> void:
	result = outcome
	result["best"] = save.record(mission_id, result)
	save.remember_loadout(mission_id, loadout)
	save.save_to(save_path)
	on_action("mission:over")


## The board's pick becomes the mission to prepare, with the loadout last drafted for it; the save remembers it.
func _on_board_action(what: String, board: MissionBoard) -> void:
	if what == "pick":
		mission_id = board.chosen
		save.last_mission = mission_id
		loadout = save.loadout_for(mission_id)
		save.save_to(save_path)
	on_action("board:" + what)


func _on_prepare_action(what: String, prep: PrepareScreen) -> void:
	if what == "manifest":
		loadout = prep.draft.picks
		save.remember_loadout(mission_id, loadout)
		save.difficulty = prep.difficulty
		save.save_to(save_path)
	on_action("prepare:" + what)


func _open_pause() -> void:
	if is_instance_valid(_pause) or not is_instance_valid(_mission):
		return
	_mission.set_frozen(true)
	_pause = PauseMenu.new()
	_pause.name = "Pause"
	add_child(_pause)
	_pause.setup()
	UiSound.play(&"ui_pause")
	Music.set_ducked(true)
	_pause.action.connect(func(what: String) -> void: on_action("pause:" + what))


func _close_pause() -> void:
	if is_instance_valid(_pause):
		_pause.queue_free()
	_pause = null
	Music.set_ducked(false)


func _on_title_action(what: String) -> void:
	match what:
		"sandbox":
			get_tree().change_scene_to_file(SANDBOX_SCENE)
		"quit":
			get_tree().quit()
		_:
			on_action("title:" + what)


## One frame to res://captures/<file_name>, scaled 2x with nearest filtering -- the same shape as the
## battlefield's captures, so they sit next to each other.
func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join(file_name))
	print("captured ", dir.path_join(file_name))


## Stop any interface sound still ringing (the win/lose stings run past 2 seconds) and let the audio thread
## actually release its playback before the process ends -- the same wait Battlefield.quit() gives the
## mission's own Sfx pool, so a scripted --capture or --flow-test run does not leak a live playback.
func _quit_cleanly() -> void:
	UiSound.stop_all()
	Music.stop_all()  # the battle stems loop forever and are not in either pool; stop them before the wait below
	for i in 3:
		await get_tree().process_frame
	OS.delay_msec(150)
	await get_tree().process_frame
	Sfx.clear_cache()
	get_tree().quit()


## Wait until `cond` holds or `seconds` of real time pass; true when it held.
func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > end:
			return false
		await get_tree().process_frame
	return true


## The whole screen flow, driven without a mouse -- the part nobody could click through while it was being
## built. One FLOW line per step, then one FLOW result line:
##   /f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn -- --flow-test
func _flow_test() -> void:
	var fails: Array[String] = []
	var count := [0]
	var step := func(ok: bool, what: String) -> void:
		count[0] += 1
		print("FLOW %s %s" % ["ok  " if ok else "FAIL", what])
		if not ok:
			fails.append(what)
	var four := PackedStringArray(["heaven", "tsunami", "cinder", "nova"])

	step.call(screen == Screen.TITLE and _screen_node is TitleScreen, "the game opens on the title")
	step.call(Music.current() == &"theme", "the title plays the theme")
	# The title's first frames compile its shaders, which can take seconds; let them pass before anything is timed.
	await get_tree().process_frame
	await get_tree().process_frame
	on_action("title:play")
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard, "Play opens the mission board")
	step.call(Music.current() == &"theme", "the board plays the theme")
	(_screen_node as MissionBoard).choose(MissionBook.LAST_JUDGEMENT)
	step.call(screen == Screen.PREPARE and _screen_node is PrepareScreen
		and (_screen_node as PrepareScreen).mission.id == MissionBook.LAST_JUDGEMENT
		and mission_id == MissionBook.LAST_JUDGEMENT and save.last_mission == MissionBook.LAST_JUDGEMENT,
		"picking Last Judgement opens its draft, and the save remembers the pick")
	var prep: PrepareScreen = _screen_node
	prep.draft.preselect(four)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	step.call(screen == Screen.MISSION and is_instance_valid(_mission), "MANIFEST starts a mission")
	step.call(loadout == four and save.loadout_for(mission_id) == four, "the drafted four are the loadout, and are saved")

	# The intro holds the clock, then lets it run.
	if not _mission.started():
		await _mission.prewarmed
	await get_tree().process_frame
	step.call(_mission.in_intro(), "the mission opens with its intro")
	var clock0 := _mission.rules().time_left
	await get_tree().create_timer(Mission.INTRO_SECONDS * 0.5).timeout
	step.call(_mission.rules().time_left == clock0, "the clock waits during the intro (%.2f)" % _mission.rules().time_left)
	await get_tree().create_timer(Mission.INTRO_SECONDS * 0.5 + 1.0).timeout
	var running := _mission.rules().time_left
	step.call(not _mission.in_intro() and running < clock0, "after the intro the clock runs (%.2f)" % running)
	step.call(_fader.is_clear(), "the fade has cleared once the mission is up")
	step.call(Music.current() == &"battle", "the mission plays the battle")

	# Pause freezes the mission; Resume gives the same one back.
	var first := _mission
	_open_pause()
	var paused_at := _mission.rules().time_left
	await get_tree().create_timer(1.0).timeout
	step.call(is_instance_valid(_pause) and _mission.rules().time_left == paused_at,
		"pause stops the clock (%.2f -> %.2f)" % [paused_at, _mission.rules().time_left])
	on_action("pause:resume")
	step.call(_mission == first and not is_instance_valid(_pause), "Resume gives back the same mission")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < paused_at, "and its clock runs on (%.2f)" % _mission.rules().time_left)

	# The clock running out ends it on the Results screen, over the frozen mission.
	_mission.rules().time_left = 0.01
	var reached := await _until(func() -> bool: return screen == Screen.RESULTS, 5.0)
	step.call(reached, "the ending plays out before the results (slow motion, %.1f s)" % Mission.ENDING_SECONDS)
	step.call(screen == Screen.RESULTS and _screen_node is ResultsScreen, "the mission ends on the results")
	step.call(is_instance_valid(_mission) and _mission.process_mode == Node.PROCESS_MODE_DISABLED,
		"drawn over the frozen mission")
	step.call(String(result.get("reason", "")) == "timeout" and not bool(result.get("won", true)),
		"reported as a loss on the clock (%s)" % result.get("reason", "?"))

	# Replay is a fresh mission with the same four.
	on_action("results:replay")
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	step.call(screen == Screen.MISSION and is_instance_valid(_mission) and _mission != first, "Replay starts a fresh mission")
	step.call(loadout == four, "with the same four powers")

	# Pause, then Change powers: the draft, with the four preselected, and nothing left of the mission.
	if not _mission.started():
		await _mission.prewarmed
	_open_pause()
	on_action("pause:change")
	await get_tree().process_frame
	step.call(screen == Screen.PREPARE and _screen_node is PrepareScreen, "Change powers opens the draft")
	step.call(_screen_node is PrepareScreen and (_screen_node as PrepareScreen).draft.picks == four,
		"with the four preselected")
	step.call(not is_instance_valid(_pause) and not is_instance_valid(_mission), "and the pause menu and mission are gone")
	on_action("prepare:back")
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard, "Back from the draft returns to the board")

	# Pause, then Missions: the board, with nothing left of the mission. The Replay's fade-in is still running this
	# soon after it (no player is this quick): the MANIFEST below is kept until it ends, then runs (v0.08.2; before,
	# it was dropped, and this test waited the fade out first).
	(_screen_node as MissionBoard).choose(MissionBook.LAST_JUDGEMENT)
	var during_fade := _fading_in
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	step.call(during_fade and _mission_queued and screen == Screen.PREPARE,
		"a MANIFEST during the Replay's fade-in is kept for when it ends (fading in: %s)" % during_fade)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	step.call(screen == Screen.MISSION and is_instance_valid(_mission) and loadout == four, "the board, the draft and MANIFEST again")
	_open_pause()
	on_action("pause:missions")
	await get_tree().process_frame
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard, "Missions from the pause menu opens the board")
	step.call(not is_instance_valid(_pause) and not is_instance_valid(_mission), "and the pause menu and mission are gone")

	# The Warning (v0.08): picked by its id, its default loadout manifested, won when the omen fades -- an unscored
	# result -- and Missions goes back to the board.
	var kit := MissionBook.warning().default_loadout
	(_screen_node as MissionBoard).choose(MissionBook.WARNING)
	step.call(screen == Screen.PREPARE and _screen_node is PrepareScreen
		and (_screen_node as PrepareScreen).mission.id == MissionBook.WARNING and mission_id == MissionBook.WARNING,
		"picking The Warning opens its draft")
	(_screen_node as PrepareScreen).draft.preselect(kit)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	step.call(screen == Screen.MISSION and is_instance_valid(_mission) and loadout == kit
		and _mission.rules().mission.id == MissionBook.WARNING,
		"MANIFEST starts The Warning with its default loadout (%s)" % ",".join(loadout))
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_mission.rules().time_left = 0.01
	var faded := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(faded and _screen_node is ResultsScreen and String(result.get("reason", "")) == "omen"
		and bool(result.get("won", false)) and not result.has("score"),
		"the omen fading wins it, on unscored results (%s)" % result.get("reason", "?"))
	on_action("results:missions")
	await get_tree().process_frame
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not is_instance_valid(_mission),
		"Missions from the results returns to the board")
	(_screen_node as MissionBoard).action.emit("back")
	step.call(screen == Screen.TITLE and _screen_node is TitleScreen, "Back from the board returns to the title")
	step.call(Engine.time_scale == 1.0, "and time runs at normal speed")

	print("FLOW result checks=%d failures=%d %s" % [count[0], fails.size(), ", ".join(fails)])

