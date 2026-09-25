class_name Game
extends Node
## The game: which screen is up, what the save file remembers, and the mission it runs. Screens are children
## it makes and frees one at a time; each tells it what the player pressed through a "<screen>:<action>"
## string, and FLOW says where that leads. Keeping the flow as data is what makes it provable without
## building a single screen.

enum Screen {TITLE, PREPARE, MISSION, RESULTS}

## Where every button leads (spec §1). Pause is not a screen of its own: it sits over the mission, which is
## why "pause:resume" leads back to MISSION -- on_action() resumes that mission rather than building a new one.
const FLOW := {
	"title:play": Screen.PREPARE,
	"prepare:manifest": Screen.MISSION,
	"prepare:back": Screen.TITLE,
	"mission:over": Screen.RESULTS,
	"results:replay": Screen.MISSION,
	"results:change": Screen.PREPARE,
	"results:title": Screen.TITLE,
	"pause:resume": Screen.MISSION,
	"pause:restart": Screen.MISSION,
	"pause:change": Screen.PREPARE,
	"pause:title": Screen.TITLE,
}

const MISSION_SCENE := "res://scenes/mission.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox.tscn"
## Grass: what shows between screens, the same clear colour the mission uses.
const CLEAR := Color("4a6a2a")

var screen := Screen.TITLE
var save: SaveFile
## The four powers the player drafted, kept so Replay can run them again.
var loadout := PackedStringArray()
## The last mission's numbers, for the Results screen: won, reason, score, rank, lines, best.
var result := {}

## The running mission. It outlives the MISSION screen by one step: the Results screen is drawn over its
## frozen ruins, which is the payoff for the whole run.
var _mission: Mission
## Title, Prepare or Results: whichever full screen is up.
var _screen_node: Node


## The screen an action leads to, or -1 when nothing offers it.
static func next_screen(action: String) -> int:
	return int(FLOW.get(action, -1))


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	save = SaveFile.new().load_from()
	loadout = save.last_loadout
	var args := OS.get_cmdline_user_args()
	var show := Battlefield.arg_value(args, "--show")
	match show:
		"prepare":
			go_to(Screen.PREPARE)
		_:
			go_to(Screen.TITLE)
	if "--capture" in args:
		# A second for anything behind the screen to settle, then one frame to disk. This is how each screen
		# task shows its work: SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture
		await get_tree().create_timer(1.0).timeout
		await _capture("screen_%s.png" % (show if show != "" else "start"))
		get_tree().quit()


## Put up a screen, taking down whatever was there.
func go_to(to: int) -> void:
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
		Screen.PREPARE:
			var prep := PrepareScreen.new()
			prep.name = "Prepare"
			add_child(prep)
			prep.setup(loadout, save.best_score, save.best_rank)
			prep.action.connect(_on_prepare_action.bind(prep))
			_screen_node = prep
		Screen.MISSION:
			_mission = _build_mission()
		Screen.RESULTS:
			if is_instance_valid(_mission):
				_mission.set_frozen(true)
			push_warning("KAK has no Results screen yet")  # Task 5
		_:
			push_warning("KAK screen %d has nothing to show yet" % to)  # Tasks 3 and 4


## What a screen reports the player pressed.
func on_action(action: String) -> void:
	var to := next_screen(action)
	if to < 0:
		push_warning("KAK ignored an unknown action: " + action)
		return
	go_to(to)


func _build_mission() -> Mission:
	var mission: Mission = load(MISSION_SCENE).instantiate()
	mission.autostart = false  # set before add_child(), so its _ready() does not start a mission of its own
	add_child(mission)
	mission.finished.connect(_on_mission_finished)
	# Its _ready() is still compiling the effect shaders into the effect layers a frame or two after
	# add_child(), and start() clears those layers -- starting now freed the prewarm's nodes under it.
	var seed_value := Time.get_ticks_usec()
	if mission.is_prewarmed:
		mission.start(loadout, seed_value)
	else:
		mission.prewarmed.connect(func() -> void: mission.start(loadout, seed_value), CONNECT_ONE_SHOT)
	return mission


func _on_mission_finished(won: bool, reason: String, score: int, rank: String, lines: Array[Dictionary]) -> void:
	result = {"won": won, "reason": reason, "score": score, "rank": rank, "lines": lines,
		"best": save.record(score, rank)}
	save.remember_loadout(loadout)
	save.save_to()
	on_action("mission:over")


func _on_prepare_action(what: String, prep: PrepareScreen) -> void:
	if what == "manifest":
		loadout = prep.draft.picks
		save.remember_loadout(loadout)
		save.save_to()
	on_action("prepare:" + what)


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
