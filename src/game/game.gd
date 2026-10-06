class_name Game
extends Node
## The game: which screen is up, what the save file remembers, and the mission it runs. Screens are children
## it makes and frees one at a time; each tells it what the player pressed through a "<screen>:<action>"
## string, and FLOW says where that leads. Keeping the flow as data is what makes it provable without
## building a single screen.

enum Screen {TITLE, BOARD, PREPARE, MISSION, RESULTS, INTERLUDE, CAMPAIGN, ENDING}

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
	# Between the acts of a night (v0.09): the interlude over the frozen town, the re-draft, and BEGIN, which carries
	# on in the same Mission node rather than building a new one.
	"mission:act_over": Screen.INTERLUDE,
	"interlude:draft": Screen.PREPARE,
	"interlude:missions": Screen.BOARD,
	"prepare:begin": Screen.MISSION,
	# The Lantern campaign (v0.10): its night screen, the draft for tonight, the night's results leading on to the next
	# night or the ending, and Pause's way back to the night screen.
	"title:campaign": Screen.CAMPAIGN,
	"campaign:draft": Screen.PREPARE,
	"campaign:title": Screen.TITLE,
	"prepare:campaign": Screen.CAMPAIGN,
	"results:next": Screen.CAMPAIGN,
	"results:ending": Screen.ENDING,
	"pause:campaign": Screen.CAMPAIGN,
	"ending:title": Screen.TITLE,
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
## What --show=results-night displays (v0.09): a night won by the Festival path, Act III lost on its clock.
const SAMPLE_NIGHT_RESULT := {
	"mission": "long_night", "won": false, "reason": "timeout", "score": 11650, "rank": "B", "best": true,
	"time": 421.0, "path": "festival",
	"acts": [
		{"act": "omen", "won": true, "reason": "warning", "bonuses": [{"label": "Unseen", "earned": true}], "time": 41.0},
		{"act": "festival", "won": true, "reason": "festival", "bonuses": [{"label": "Bell silent", "earned": false}],
			"time": 98.0},
		{"act": "judgement", "won": false, "reason": "timeout", "bonuses": [{"label": "Quiet succession", "earned": false}],
			"time": 180.0},
	],
	"lines": [
		{"label": "Buildings destroyed", "value": "38", "points": 1520},
		{"label": "Citizens killed", "value": "64", "points": 640},
		{"label": "Soldiers killed", "value": "21", "points": 525},
		{"label": "Citizens escaped", "value": "9", "points": 0},
		{"label": "Chains", "value": "1", "points": 300},
	],
	"bonuses": [], "goal": {"label": "The night is yours", "done": false},
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
## True from an act's end until the next act begins (v0.09): the interlude and the Prepare after it keep the mission.
var _between_acts := false
## The act the interlude's choice card picked ("" for the only one that follows).
var _next_path := ""
## The interlude, while it is up.
var _interlude: InterludeScreen
## True while the Lantern campaign is being played (v0.10), from its night screen until the title or the board: Prepare
## drafts within the campaign's slots and budget, a finished night is recorded on it, and Pause and Results lead back to
## its night screen.
var _in_campaign := false


## The screen an action leads to, or -1 when nothing offers it.
static func next_screen(action: String) -> int:
	return int(FLOW.get(action, -1))


## The loadout Prepare opens with for a mission: the last one drafted for it, and for the night (v0.09) -- never
## played, or an old save with no section for it -- the night's default loadout. The other missions open empty.
static func starting_loadout(from: SaveFile, id: String) -> PackedStringArray:
	var kept := from.loadout_for(id)
	var def := MissionBook.get_mission(id)
	return def.default_loadout if kept.is_empty() and not def.acts.is_empty() else kept


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	var args := OS.get_cmdline_user_args()
	if "--flow-test" in args:
		save_path = FLOW_TEST_SAVE
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	save = SaveFile.new().load_from(save_path)
	mission_id = save.last_mission
	loadout = starting_loadout(save, mission_id)
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
		"results-night":
			result = SAMPLE_NIGHT_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"results-warning":
			result = SAMPLE_WARNING_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"interlude":
			# The Warning's sample result as the night's first act, then the Long Night's two Act II cards (v0.09).
			result = SAMPLE_WARNING_RESULT.duplicate(true)
			result["mission"] = "omen"
			var ln := MissionBook.long_night()
			screen = Screen.INTERLUDE
			_show_interlude([ln.act("festival"), ln.act("procession")], NightState.new())
		"pause":
			go_to(Screen.MISSION)
			_open_pause()
		"campaign":
			if save.campaign == null:
				save.campaign = CampaignState.new()
			go_to(Screen.CAMPAIGN)
		"campaign-choice":
			# Night 2's three cards (v0.10), for the photograph; the save is not written.
			save.campaign = CampaignState.new()
			save.campaign.night = 1
			save.campaign.dp = 8
			go_to(Screen.CAMPAIGN)
		"ending":
			save.campaign = CampaignState.new()
			save.campaign.ending = CampaignDef.FALSE_LANTERN
			go_to(Screen.ENDING)
		"miras", "cael":
			# Mira's House as its intro lands (v0.10 M2), for the photograph of its HUD: the Gaze bar and the marks over the
			# grieving (unpaused: the pause menu would cover them). cael (v0.10 M5) is the same, with Venn's banner and
			# Cael's line under it.
			mission_id = MissionBook.MIRAS_HOUSE
			loadout = MissionBook.miras_house().default_loadout
			go_to(Screen.MISSION)
		"lanterns":
			# Broken Lanterns as its intro lands (v0.10 M3), for the photograph of the shrines, their marks, the Gaze bar and
			# the objectives (unpaused, as Mira's House's).
			mission_id = MissionBook.BROKEN_LANTERNS
			loadout = MissionBook.broken_lanterns().default_loadout
			go_to(Screen.MISSION)
		"flame", "flame-beams":
			# The Vigil Flame as its intro lands (v0.10 M4), for the photograph of the Vigil, its marks and the objectives;
			# flame-beams lights the Searchlight's two beams at once (VigilFlameDirector.bench_beams()) for the cones,
			# the pools of light and the dim (unpaused, as Mira's House's). Both wait two seconds, not one: the intro's
			# camera has landed and the director is ticking, so the marks sit on the Vigil.
			mission_id = MissionBook.VIGIL_FLAME
			loadout = MissionBook.vigil_flame().default_loadout
			go_to(Screen.MISSION)
		_:
			go_to(Screen.TITLE)
	if "--capture" in args:
		# A second for anything behind the screen to settle, then one frame to disk. This is how each screen
		# task shows its work: SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture
		# A mission underneath (the pause photograph) only builds its town once its shader prewarm is done,
		# which takes longer than that second -- the first pause capture showed the menu over bare grass.
		if is_instance_valid(_mission) and not _mission.started():
			await _mission.prewarmed
		if show == "flame-beams" and is_instance_valid(_mission) and _mission.rules() != null \
				and _mission.rules().director is VigilFlameDirector:
			(_mission.rules().director as VigilFlameDirector).bench_beams()
		if show == "cael" and is_instance_valid(_mission) and is_instance_valid(_mission._hud):
			# Cael's line under its event's banner (v0.10 M5), for the photograph of the subtitle.
			_mission._hud.push_banner("THE INQUISITOR SEARCHES")
			_mission._hud.push_subtitle(CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "venn"))
		await get_tree().create_timer(2.0 if show.begins_with("flame") else 1.0).timeout
		await _capture("screen_%s.png" % (show if show != "" else "start"))
		await _quit_cleanly()
	elif "--flow-test" in args:
		await _flow_test()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		await _quit_cleanly()


## Put up a screen, taking down whatever was there.
func go_to(to: int) -> void:
	_close_pause()
	var from := screen
	screen = to
	if to == Screen.TITLE or to == Screen.BOARD:
		_in_campaign = false
	elif to == Screen.CAMPAIGN:
		_in_campaign = true
	# A hit dips Engine.time_scale and the battlefield's Impact restores it from its own _process. A mission
	# freed mid-dip never restores it, and the whole game would stay in slow motion from then on.
	Engine.time_scale = 1.0
	if is_instance_valid(_screen_node):
		_screen_node.queue_free()
		_screen_node = null
	# Between the acts of a night (v0.09) the interlude and its Prepare keep the mission too: BEGIN carries it on.
	var keep := to == Screen.RESULTS or to == Screen.INTERLUDE or (to == Screen.PREPARE and _between_acts)
	if to != Screen.INTERLUDE and to != Screen.PREPARE:
		_between_acts = false
	if not keep and is_instance_valid(_mission):
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
			if _between_acts and is_instance_valid(_mission):
				# The re-draft for the next act (v0.09): the one the choice card picked, or the only one that follows.
				var next: Array = _mission.next_choices()
				var act: ActDef = next[0]
				for a: ActDef in next:
					if a.id == _next_path:
						act = a
				prep.setup(act, loadout, save.difficulty)
				prep.confirm_label = "BEGIN"
			elif _in_campaign and save.campaign != null:
				prep.setup(save.campaign.mission(mission_id), loadout, save.difficulty)
			else:
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
			res.action.connect(func(what: String) -> void: on_action(_results_action(what)))
			_screen_node = res
		Screen.INTERLUDE:
			# Like the results, over the frozen town (v0.09); the act's sting only when it has just ended, not on the
			# way back from Prepare.
			if is_instance_valid(_mission):
				_mission.set_frozen(true)
				_show_interlude(_mission.next_choices(), _mission.night())
			if from == Screen.MISSION:
				UiSound.play(&"ui_win" if bool(result.get("won", false)) else &"ui_lose")
		Screen.CAMPAIGN:
			var night := CampaignScreen.new()
			night.name = "Campaign"
			add_child(night)
			night.setup(save.campaign)
			night.action.connect(_on_campaign_action.bind(night))
			_screen_node = night
		Screen.ENDING:
			var end := EndingScreen.new()
			end.name = "Ending"
			add_child(end)
			end.setup(save.campaign.ending, save.campaign.ending_fragment())
			end.action.connect(func(what: String) -> void: on_action("ending:" + what))
			_screen_node = end
		_:
			push_warning("KAK screen %d has nothing to show yet" % to)
	match to:
		Screen.TITLE, Screen.BOARD, Screen.PREPARE, Screen.CAMPAIGN, Screen.ENDING:
			Music.play(&"theme")
		Screen.RESULTS, Screen.INTERLUDE:
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
		if action == "prepare:begin":
			_continue_night()
		else:
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


## On into the next act of the night, behind the same fade as a fresh mission: the same Mission node continues.
## Prepare and the interlude ignore the player during the fade (v0.09 final review); should the night still be gone by
## its end, the fade only lifts over whatever is up -- before, the act was begun on a freed mission and the black stayed.
func _continue_night() -> void:
	if _fading or not is_instance_valid(_mission):
		return
	_fading = true
	await _fader.fade_out(FADE_OUT)
	if not _between_acts or not is_instance_valid(_mission):
		await _fade_back_in()
		return
	if is_instance_valid(_screen_node):
		_screen_node.queue_free()
		_screen_node = null
	_between_acts = false
	screen = Screen.MISSION
	_mission.next_act(loadout, _next_path)
	_mission.set_frozen(false)
	Music.play(&"battle")
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_back_in()


## The end of _continue_night()'s fade: like _faded_into_mission()'s, a Restart or MANIFEST pressed while it comes back
## in is kept and run once it has.
func _fade_back_in() -> void:
	_fading_in = true
	await _fader.fade_in(FADE_IN)
	_fading_in = false
	_fading = false
	if _mission_queued:
		_mission_queued = false
		_faded_into_mission()


## The interlude over whatever is behind it, with the acts that may follow and the night so far.
func _show_interlude(choices: Array, night: NightState) -> void:
	_interlude = InterludeScreen.new()
	_interlude.name = "Interlude"
	add_child(_interlude)
	_interlude.setup(result, choices, night)
	if _next_path != "" and choices.size() > 1:
		_interlude.choose(_next_path)  # back from Prepare: the act chosen before stays chosen
	_interlude.action.connect(_on_interlude_action)
	_screen_node = _interlude


func _on_interlude_action(what: String) -> void:
	if _fading:
		return  # BEGIN is carrying the night on: the interlude is on its way out
	match what:
		"draft":
			_next_path = _interlude.chosen
			on_action("interlude:draft")
		"missions":
			on_action("interlude:missions")


func _build_mission() -> Mission:
	var mission: Mission = load(MISSION_SCENE).instantiate()
	mission.autostart = false  # set before add_child(), so its _ready() does not start a mission of its own
	mission.difficulty = save.difficulty
	mission.mission_id = mission_id
	mission.bell_rang = _in_campaign and save.campaign != null and save.campaign.bell_rang
	add_child(mission)
	mission.finished.connect(_on_mission_finished)
	mission.act_over.connect(_on_act_over)
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
	_between_acts = false
	result = outcome
	if _in_campaign and save.campaign != null:
		# A campaign night is the campaign's (v0.10): The Warning and Last Judgement share their ids with the board, whose
		# best results and drafted loadouts it must not touch.
		result["campaign"] = save.campaign.record(mission_id, result)
		result["best"] = false
	else:
		result["best"] = save.record(mission_id, result)
		save.remember_loadout(mission_id, loadout)
	save.save_to(save_path)
	on_action("mission:over")


## An act of the night is over (v0.09): its result for the interlude, and the loadout kept for the re-draft.
func _on_act_over(res: Dictionary) -> void:
	_between_acts = true
	_next_path = ""
	result = res
	save.remember_loadout(mission_id, loadout)
	save.save_to(save_path)
	on_action("mission:act_over")


## The board's pick becomes the mission to prepare, with the loadout last drafted for it; the save remembers it.
func _on_board_action(what: String, board: MissionBoard) -> void:
	if what == "pick":
		mission_id = board.chosen
		save.last_mission = mission_id
		loadout = starting_loadout(save, mission_id)
		save.save_to(save_path)
	on_action("board:" + what)


## The night screen's buttons (v0.10): on to Prepare for tonight's mission, with the loadout last drafted for it; a
## fresh campaign; or back to the title, where the board's mission is the one last picked there.
func _on_campaign_action(what: String, night: CampaignScreen) -> void:
	match what:
		"draft":
			mission_id = night.chosen
			loadout = save.loadout_for(mission_id)
			if loadout.is_empty():
				loadout = MissionBook.get_mission(mission_id).default_loadout
			on_action("campaign:draft")
		"restart":
			save.campaign = CampaignState.new()
			save.save_to(save_path)
			go_to(Screen.CAMPAIGN)
		"title":
			mission_id = save.last_mission
			loadout = starting_loadout(save, mission_id)
			on_action("campaign:title")


## A Results button's action (v0.10): a campaign night's Continue leads to the ending once the campaign has one.
func _results_action(what: String) -> String:
	if what == "next" and _in_campaign and save.campaign != null and save.campaign.ending != "":
		return "results:ending"
	return "results:" + what


func _on_prepare_action(what: String, prep: PrepareScreen) -> void:
	if _between_acts:
		# The re-draft between acts (v0.09): BEGIN carries the night on, Back returns to the interlude -- but not once
		# BEGIN's fade is under way: Back, then Missions from the interlude, would free the night it is carrying on.
		if _fading:
			return
		if what == "manifest":
			loadout = prep.draft.picks
			save.remember_loadout(mission_id, loadout)
			save.save_to(save_path)
			on_action("prepare:begin")
		elif what == "back":
			go_to(Screen.INTERLUDE)
		return
	if what == "back" and _in_campaign:
		on_action("prepare:campaign")
		return
	if what == "manifest":
		loadout = prep.draft.picks
		if not _in_campaign:
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
	_pause.setup(_in_campaign)
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
		"campaign":
			# A campaign that has reached its ending is over: Campaign begins a fresh one (review focus 3).
			if save.campaign == null or save.campaign.ending != "":
				save.campaign = CampaignState.new()
				save.save_to(save_path)
			on_action("title:campaign")
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

	# A restart during the ending's slow motion (v0.09): the old ending lets go without reporting, so the mission now
	# running is not cut short by the one before it, and time runs at normal speed again.
	(_screen_node as MissionBoard).choose(MissionBook.WARNING)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_mission.rules().time_left = 0.01
	var ending := await _until(func() -> bool: return _mission._ending, 3.0)
	var ended := _mission.rules()
	_mission.start(loadout, Time.get_ticks_usec())  # what the R key does
	var cut := await _until(func() -> bool: return screen != Screen.MISSION, Mission.ENDING_SECONDS + 3.0)
	step.call(ending and not cut and screen == Screen.MISSION and _mission.rules() != ended and not _mission._ending
		and Engine.time_scale == 1.0,
		"a restart during the ending is not ended by it (%s, time scale %.2f)" % [Screen.keys()[screen], Engine.time_scale])
	_open_pause()
	on_action("pause:missions")
	await get_tree().process_frame
	await _flow_night(step)
	(_screen_node as MissionBoard).action.emit("back")
	step.call(screen == Screen.TITLE and _screen_node is TitleScreen, "Back from the board returns to the title")
	step.call(Engine.time_scale == 1.0, "and time runs at normal speed")

	await _flow_campaign(step)

	print("FLOW result checks=%d failures=%d %s" % [count[0], fails.size(), ", ".join(fails)])


## A mission is up and started, no fade running, and it is not `other`: a Restart has built the fresh one.
func _mission_up(other: Mission) -> bool:
	var up := screen == Screen.MISSION and is_instance_valid(_mission) and _mission != other
	return up and _mission.started() and not _fading


## The Long Night through the screens (v0.09), from the board: Act I won on its clock, the choice card, the re-draft,
## Act II (one building counted once), Act III ended on its clock for the night's results; then a restart in Act I and
## the way out through Pause. Ends on the board.
func _flow_night(step: Callable) -> void:
	var kit := MissionBook.long_night().default_loadout
	(_screen_node as MissionBoard).choose(MissionBook.LONG_NIGHT)
	var prep: PrepareScreen = _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and prep.mission.id == MissionBook.LONG_NIGHT
		and prep.draft.slots == 4 and mission_id == MissionBook.LONG_NIGHT,
		"picking The Long Night opens its draft, with 4 slots")
	step.call(prep.draft.picks == kit, "its first Prepare opens on the night's default loadout (%s)" % ",".join(prep.draft.picks))
	prep.draft.preselect(kit)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	step.call(screen == Screen.MISSION and is_instance_valid(_mission) and loadout == kit
		and _mission.act() != null and _mission.act().id == "omen" and _mission.night() != null,
		"MANIFEST starts the night in Act I, The Omen (%s)" % ",".join(loadout))

	# Act I wins on its clock, and the interlude after it is for that act.
	_mission.rules().time_left = 0.01
	var inter := await _until(func() -> bool: return screen == Screen.INTERLUDE, 6.0)
	var card: InterludeScreen = _screen_node as InterludeScreen
	step.call(inter and card != null and card.choices.size() == 2 and bool(result.get("won", false))
		and is_instance_valid(_mission) and _mission.process_mode == Node.PROCESS_MODE_DISABLED,
		"Act I ending opens the interlude with two choices, over the frozen town")
	step.call(InterludeScreen.act_name(String(result.get("mission", ""))) == "Act I: The Omen"
		and card != null and card.act_name(String(result.get("mission", ""))) == "Act I: The Omen",
		"the interlude is for the act just played (%s)" % InterludeScreen.act_name(String(result.get("mission", ""))))
	var night: NightState = _mission.night()
	var same_night := true
	for a: ActDef in _mission.next_choices():
		same_night = same_night and a.night == night
	step.call(same_night and night.results.size() == 1, "each act that may follow reads the night being played")

	# The choice card: the Festival, then the re-draft with BEGIN, the same mission kept.
	var first := _mission
	card.choose("festival")
	card.action.emit("draft")
	await get_tree().process_frame
	prep = _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and prep.confirm_label == "BEGIN" and is_instance_valid(first)
		and _mission == first and prep.mission.id == "festival",
		"Choose powers shows the Festival's draft with BEGIN, the mission still alive")
	prep.draft.preselect(kit)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and not _fading and _mission.act().id == "festival", 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	step.call(screen == Screen.MISSION and _mission == first and _mission.act().id == "festival"
		and _mission.night().path == "festival", "BEGIN plays Act II, the Festival (path %s)" % _mission.night().path)

	# One destroyed building counts once: only the act's own Rules is listening.
	var houses: Array[Structure] = []
	for s: Structure in _mission._town._built:
		if s.kind == Structure.Kind.HOUSE and s.role == &"house":
			houses.append(s)
	var listening := 0
	for c: Dictionary in _mission._bf.ctx.env.structure_destroyed.get_connections():
		if (c.callable as Callable).get_object() is Rules:
			listening += 1
	var down0: int = _mission.rules().buildings_down
	if not houses.is_empty():
		_mission.rules()._on_structure_destroyed(houses[0], &"stone")
	step.call(not houses.is_empty() and listening == 1 and _mission.rules().buildings_down == down0 + 1 and down0 == 0,
		"one building down counts once: %d Rules listening, buildings_down %d" % [listening, _mission.rules().buildings_down])

	# Act II ends on its clock: the last choice is a single line, and Prepare for Act III.
	_mission.rules().time_left = 0.01
	inter = await _until(func() -> bool: return screen == Screen.INTERLUDE, 6.0)
	card = _screen_node as InterludeScreen
	step.call(inter and card != null and card.choices.size() == 1 and _mission.night().results.size() == 2
		and InterludeScreen.act_name(String(result.get("mission", ""))) == "Act II: The Festival",
		"Act II ending opens the interlude with one choice (%s)" % InterludeScreen.act_name(String(result.get("mission", ""))))
	card.action.emit("draft")
	await get_tree().process_frame
	prep = _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and prep.confirm_label == "BEGIN" and _mission == first,
		"Choose powers shows Act III's draft with BEGIN")
	prep.draft.preselect(kit)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and not _fading and _mission.act().id == "judgement", 5.0)
	# The festival held: Act III's director posts the marshals while the act is built, before its HUD exists -- the
	# banner is held and shown after the intro's (v0.09 final review; before, it was lost).
	var shown: PackedStringArray = _mission._hud.banners() if is_instance_valid(_mission._hud) else PackedStringArray()
	step.call(shown.has("THE SOLDIERS TAKE THE GATES"), "the held festival's carry-over banner shows (%s)" % ", ".join(shown))
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	step.call(screen == Screen.MISSION and _mission.act().id == "judgement", "BEGIN plays Act III, Judgement")

	# Act III ends on its clock: the night's results.
	_mission.rules().time_left = 0.01
	var over := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var acts: Array = result.get("acts", [])
	step.call(over and _screen_node is ResultsScreen and acts.size() == 3 and String(result.get("path", "")) == "festival"
		and result.has("rank") and String(result.get("reason", "")) == "timeout" and not bool(result.get("won", true)),
		"Act III ending reports the night: %d acts, path %s, rank %s, %s" % [acts.size(), result.get("path", "?"),
		result.get("rank", "?"), result.get("reason", "?")])
	on_action("results:missions")
	await get_tree().process_frame
	step.call(screen == Screen.BOARD and not is_instance_valid(_mission), "Missions from the night's results returns to the board")

	# A restart in Act I is a fresh night, and so is one in Act II; Pause then Missions leaves it.
	(_screen_node as MissionBoard).choose(MissionBook.LONG_NIGHT)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return _mission_up(null), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	step.call(_mission != old and _mission.act() != null and _mission.act().id == "omen" and _mission.night().results.is_empty(),
		"Restart in Act I is a fresh night, Act I again (%s)" % _mission.act().id)
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.INTERLUDE, 6.0)
	card = _screen_node as InterludeScreen
	card.choose("procession")
	card.action.emit("draft")
	await get_tree().process_frame
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return screen == Screen.MISSION and not _fading and _mission.act().id == "procession", 5.0)
	step.call(_mission.act().id == "procession" and _mission.night().path == "procession" and _mission.night().results.size() == 1,
		"a night through the Procession (path %s)" % _mission.night().path)
	old = _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	var live := 0
	for c: Dictionary in _mission._bf.ctx.env.structure_destroyed.get_connections():
		if (c.callable as Callable).get_object() is Rules:
			live += 1
	step.call(_mission != old and _mission.act().id == "omen" and _mission.night().results.is_empty()
		and _mission.night().path == "" and live == 1 and _mission.rules().buildings_down == 0,
		"Restart in Act II is a fresh night from Act I, one Rules listening (%s)" % _mission.act().id)

	# Review focus 2: Esc on the interlude leaves the night for the board.
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.INTERLUDE, 6.0)
	(_screen_node as InterludeScreen).action.emit("missions")
	await get_tree().process_frame
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not is_instance_valid(_mission) and not _between_acts,
		"Esc on the interlude returns to the board, the night gone")

	# BEGIN, then Esc on Prepare and Esc on the interlude before its fade is out (v0.09 final review): both are ignored,
	# and the night carries on into Act II. Before, they freed the mission under the fade, which stayed black for good.
	(_screen_node as MissionBoard).choose(MissionBook.LONG_NIGHT)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return _mission_up(null), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	await _night_to_redraft("festival")
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	_on_prepare_action("back", _screen_node as PrepareScreen)
	if _screen_node is InterludeScreen:
		(_screen_node as InterludeScreen).action.emit("missions")
	var in_act2 := func() -> bool:
		return screen == Screen.MISSION and not _fading and is_instance_valid(_mission) and _mission.act().id == "festival"
	var carried: bool = await _until(in_act2, 5.0)
	step.call(carried and _fader.is_clear() and is_instance_valid(_mission) and _mission.act().id == "festival",
		"Esc during BEGIN's fade is ignored: Act II begins and the fade clears (%s)" % Screen.keys()[screen])

	# Review focus 2: Pause, then Change powers mid-night, in Act II: the night's own draft, nothing left of it.
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_open_pause()
	on_action("pause:change")
	await get_tree().process_frame
	var draft := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and draft != null and draft.mission.id == MissionBook.LONG_NIGHT
		and draft.confirm_label != "BEGIN" and not is_instance_valid(_mission) and not _between_acts,
		"Change powers in Act II opens the night's draft, the mission gone")

	# The night gone some other way while BEGIN's fade is out: the fade lifts over what is up, and MANIFEST works again.
	_on_prepare_action("manifest", draft)
	await _until(func() -> bool: return _mission_up(null), 5.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	await _night_to_redraft("procession")
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	go_to(Screen.BOARD)
	var lifted := await _until(func() -> bool: return not _fading, 3.0)
	step.call(lifted and screen == Screen.BOARD and _fader.is_clear() and not is_instance_valid(_mission),
		"a night gone during BEGIN's fade leaves the fade clear over the board")
	(_screen_node as MissionBoard).choose(MissionBook.LONG_NIGHT)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	# A fresh mission's shader prewarm took over 5 s on some runs this late in the test: the new waits allow 10.
	var again := await _until(func() -> bool: return _mission_up(null), 10.0)
	step.call(again and _mission.act().id == "omen", "and MANIFEST starts the night again (up: %s, %s, fading %s, act %s)" % [again,
		Screen.keys()[screen], _fading, _mission.act().id if is_instance_valid(_mission) and _mission.act() != null else "-"])
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)

	# Pause, then Restart while BEGIN's fade comes back in (v0.09 final review): kept, and run once the fade is over -- a
	# fresh night from Act I, as from _faded_into_mission()'s fade-in.
	await _night_to_redraft("festival")
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	var fading_in := await _until(func() -> bool: return _fading_in, 3.0)
	var carrying := _mission
	_open_pause()
	on_action("pause:restart")
	step.call(fading_in and _mission_queued and _mission == carrying,
		"a Restart during BEGIN's fade-in is kept for when it ends (fading in: %s)" % fading_in)
	var carried_id := carrying.get_instance_id()  # the lambda keeps the id: the night it carried is freed by the Restart
	var restarted := await _until(func() -> bool: return _mission_up(null) and _mission.get_instance_id() != carried_id, 10.0)
	step.call(restarted and _mission.act().id == "omen" and _mission.night().results.is_empty(),
		"and then restarts the night from Act I (up: %s, %s, fading %s, act %s)" % [restarted, Screen.keys()[screen], _fading,
		_mission.act().id if is_instance_valid(_mission) and _mission.act() != null else "-"])
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_open_pause()
	on_action("pause:missions")
	await get_tree().process_frame
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not is_instance_valid(_mission)
		and not is_instance_valid(_pause), "Missions from the pause menu leaves the night for the board")


## From Act I up and running: end it on its clock, choose `path` on the card and open the re-draft with BEGIN.
func _night_to_redraft(path: String) -> void:
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.INTERLUDE, 6.0)
	var card := _screen_node as InterludeScreen
	card.choose(path)
	card.action.emit("draft")
	await get_tree().process_frame


## The Lantern campaign through the screens (v0.10), from the title: Night 1 won on its clock, Night 2's three cards
## and the Vigil Flame won with its flame home, Night 3's Festival lost on its clock (a bite, and the Theft ending),
## then the ending's two pages; a fresh campaign after it; nights left unfinished (review focus 2); the board after the
## campaign (review focus 5). Starts and ends on the title.
func _flow_campaign(step: Callable) -> void:
	var quiet := PackedStringArray(["whisper", "doom", "discord"])
	var board_kit := save.loadout_for(MissionBook.WARNING)
	(_screen_node as TitleScreen).action.emit("campaign")
	var night := _screen_node as CampaignScreen
	step.call(screen == Screen.CAMPAIGN and night != null and save.campaign != null and save.campaign.night == 0
		and night.chosen == MissionBook.WARNING, "Campaign opens Night 1 of a fresh campaign, The Warning chosen")
	night.click(night.button_rect("draft").get_center())
	var prep := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and prep.mission.id == MissionBook.WARNING
		and prep.draft.slots == 3 and prep.draft.capacity == 6, "its draft has the campaign's 3 slots and 6 DP")

	# Review focus 2: Back from the draft records nothing.
	_on_prepare_action("back", prep)
	step.call(screen == Screen.CAMPAIGN and save.campaign.night == 0 and save.campaign.dp == 6,
		"Back from a campaign draft returns to the night, nothing recorded")
	(_screen_node as CampaignScreen).click((_screen_node as CampaignScreen).button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	prep.draft.preselect(PackedStringArray(["whisper", "wisp"]))
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)

	# Review focus 2: Restart and Pause, Campaign record nothing either.
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	step.call(save.campaign.night == 0 and save.campaign.bites == 0, "Restart in a campaign night records nothing")
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_open_pause()
	on_action("pause:campaign")
	await get_tree().process_frame
	step.call(screen == Screen.CAMPAIGN and not is_instance_valid(_mission) and save.campaign.night == 0
		and save.campaign.bites == 0, "Pause, Campaign leaves the night unplayed: no bite, the same night")

	# Night 1 won on its clock.
	night = _screen_node as CampaignScreen
	night.click(night.button_rect("draft").get_center())
	(_screen_node as PrepareScreen).draft.preselect(PackedStringArray(["whisper", "wisp"]))
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var res := _screen_node as ResultsScreen
	# A quiet omen earns The Warning's Unseen bonus: +1 DP on top of the win's 2.
	var unseen := CampaignState._bonus_earned(result)
	var dp1 := CampaignDef.START_DP + CampaignDef.WIN_DP + (CampaignDef.BONUS_DP if unseen else 0)
	step.call(res != null and res.campaign and save.campaign.night == 1 and save.campaign.dp == dp1,
		"Night 1 won: the results offer Continue, and the god has %d DP (%d, Unseen %s)" % [dp1, save.campaign.dp, unseen])
	var reread := SaveFile.new().load_from(save_path)
	step.call(reread.campaign != null and reread.campaign.night == 1 and reread.campaign.dp == dp1, "and the save holds it")
	step.call(save.loadout_for(MissionBook.WARNING) == board_kit and not bool(result.get("best", false)),
		"a campaign night leaves the board's Warning alone: its loadout %s, no NEW BEST" % [save.loadout_for(MissionBook.WARNING)])

	# Night 2: three cards, the Vigil Flame won by bringing its flame home.
	res.action.emit("next")
	night = _screen_node as CampaignScreen
	step.call(screen == Screen.CAMPAIGN and night != null and night.options.size() == 3 and night.chosen == "",
		"Continue opens Night 2's three cards, none chosen")
	night.choose(MissionBook.VIGIL_FLAME)
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.mission.id == MissionBook.VIGIL_FLAME and prep.draft.capacity == dp1
		and not prep.draft.pool.has("heaven"), "the Vigil Flame's draft: the god's %d DP, the quiet pool" % dp1)
	prep.draft.preselect(quiet)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	(_mission.rules().director as VigilFlameDirector).home = true
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	# The flame home with no beam ever on Wren (the light never wakes here) earns Unseen hands: +1 DP on top of the win's 2,
	# expected outright, so a bonus that went missing would fail this step rather than be read back from the result.
	var dp2 := dp1 + CampaignDef.WIN_DP + CampaignDef.BONUS_DP
	step.call(save.campaign.night == 2 and save.campaign.path() == CampaignDef.THEFT and save.campaign.dp == dp2
		and String(result.get("reason", "")) == "flame", "the flame home: Night 3 next, on the Theft path, %d DP" % dp2)

	# Night 3: the Festival alone, in an unwarned town, lost on its clock.
	(_screen_node as ResultsScreen).action.emit("next")
	night = _screen_node as CampaignScreen
	step.call(night != null and night.options.size() == 2, "Night 3 offers the Festival and the Procession")
	night.choose(MissionBook.FEAST_FESTIVAL)
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 4 and prep.draft.capacity == dp2, "with 4 slots and %d DP" % dp2)
	prep.draft.preselect(quiet)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
	step.call(_mission.act() != null and _mission.act().id == "festival" and _mission.act().is_last()
		and not _mission.night().bell_rang, "the Festival plays as a night of one act, its town unwarned")
	_mission.rules().time_left = 0.01
	await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(save.campaign.bites == 1 and save.campaign.dp == dp2 - CampaignDef.BITE_DP and save.campaign.ending == CampaignDef.FALSE_LANTERN,
		"the square closed: a bite, and the Theft path's ending (%s)" % save.campaign.ending)

	# The ending's two pages, then the title.
	(_screen_node as ResultsScreen).action.emit("next")
	var end := _screen_node as EndingScreen
	step.call(screen == Screen.ENDING and end != null and end.pages.size() == 2,
		"Continue opens the ending: The Vision, then The False Lantern")
	end.turn()
	end.turn()
	step.call(screen == Screen.TITLE and _screen_node is TitleScreen and not _in_campaign,
		"turning its last page returns to the title, the campaign left")

	# Review focus 3: after an ending, Campaign begins a fresh one.
	(_screen_node as TitleScreen).action.emit("campaign")
	step.call(screen == Screen.CAMPAIGN and save.campaign.night == 0 and save.campaign.ending == ""
		and save.campaign.dp == CampaignDef.START_DP, "after an ending, Campaign begins a fresh one")

	# Review focus 5: the board after the campaign drafts within its own mission's numbers.
	(_screen_node as CampaignScreen).action.emit("title")
	(_screen_node as TitleScreen).action.emit("play")
	(_screen_node as MissionBoard).choose(MissionBook.LAST_JUDGEMENT)
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 6 and prep.draft.capacity == 14 and not _in_campaign,
		"the board after the campaign: Last Judgement's own 6 slots and 14 DP")
	on_action("prepare:back")
	(_screen_node as MissionBoard).action.emit("back")
	step.call(screen == Screen.TITLE, "and back to the title")
