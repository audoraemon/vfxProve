class_name Game
extends Node
## The game: which screen is up, what the save file remembers, and the mission it runs. Screens are children
## it makes and frees one at a time; each tells it what the player pressed through a "<screen>:<action>"
## string, and FLOW says where that leads. Keeping the flow as data is what makes it provable without
## building a single screen.

## The last five are Endless Night's (god P1, spec §14): the slot select, the god select, the hub, the skill tree and the Faith screen.
enum Screen {TITLE, BOARD, PREPARE, MISSION, RESULTS, INTERLUDE, CAMPAIGN, ENDING, UPGRADES, SLOTS, GOD_SELECT, HUB, TREE, FAITH}

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
	# An ending not yet seen (v0.10 M5: the game quit on the last night's Results) opens from the title's Campaign.
	"title:ending": Screen.ENDING,
	# The Upgrades screen's way back. Nothing leads to it since the board became a test mode (god P1, ruling C3: no Upgrades button),
	# but the screen and its Back stay for a later change of mind.
	"upgrades:back": Screen.BOARD,
	# Endless Night (god P1, spec §14 P1, rulings C2, P14): from the board's DEV ENDLESS button to the slot select, the god select for a
	# new god, the hub, and from the hub to a night's Prepare, the Skill Tree, the Faith screen or the title. A night's Results go back
	# to the hub, to the tree or to Faith; Prepare's back, Pause's Abandon and the interlude's Missions go back to the hub too.
	"board:endless": Screen.SLOTS,
	"slots:continue": Screen.HUB,
	"slots:new": Screen.GOD_SELECT,
	"slots:back": Screen.BOARD,
	"god:chosen": Screen.HUB,
	"god:back": Screen.SLOTS,
	"hub:descend": Screen.PREPARE,
	"hub:awaken": Screen.PREPARE,
	"hub:tree": Screen.TREE,
	"hub:faith": Screen.FAITH,
	"hub:title": Screen.TITLE,
	"tree:back": Screen.HUB,
	"faith:back": Screen.HUB,
	"prepare:hub": Screen.HUB,
	"results:continue": Screen.HUB,
	"results:tree": Screen.TREE,
	"results:faith": Screen.FAITH,
	"pause:abandon": Screen.HUB,
	"interlude:hub": Screen.HUB,
}

const MISSION_SCENE := "res://scenes/mission.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox.tscn"
## The fade into a mission: out to black, the mission loads behind it, back in once its town is there.
const FADE_OUT := 0.25
const FADE_IN := 0.35
## Where --flow-test keeps its save, so a scripted run never touches the player's best score.
const FLOW_TEST_SAVE := "user://test_flow.cfg"
## Where --flow-test keeps its volumes (v0.11.2): the player's own settings file is neither read nor written by a scripted run.
const FLOW_TEST_SETTINGS := "user://test_flow_settings.cfg"
## Where a --show photograph keeps its volumes: a photo run never rewrites the player's user://kak_settings.cfg.
const SHOW_SETTINGS := "user://test_show_settings.cfg"
## Where --show=<screen> writes its save (v0.10 M5 final review). A sample builds a state of its own -- --show=ending a
## campaign that has ended, --show=campaign-choice one on Night 2 -- and the first key pressed on it (Enter on the ending,
## MANIFEST after a card) writes the save, which would have replaced the player's real campaign with the sample. Under
## --show the screens still open on the player's own save, but write to this file instead; nothing ever reads it back.
const SHOW_SAVE := "user://test_show.cfg"
## Where --flow-test keeps its three god slots (god P1, Endless Night): `PATH_BASE`'s twin, so a scripted run never touches the player's gods.
## Its files are removed at the start and the end of the run.
const FLOW_TEST_GOD := "user://test_flow_god_"
## Where a --show photograph keeps its god slots: the player's `user://kak_god_<n>.cfg` is neither read nor written by a photograph.
const SHOW_GOD := "user://test_show_god_"
## The new Tier 1 missions' photographs (v0.11 M2): each its board night as the tour lands, its tags and HUD in view.
const TIER1_SHOWS := ["tax_collector", "spoiled_harvest", "lost_lamb", "first_prayers"]
## The new Tier 2 missions' photographs (v0.11 M3): each its board night as the tour lands, its tags and HUD in view.
const TIER2_SHOWS := ["bell_ringers", "market_panic", "informer"]
## The new Tier 3 missions' photographs (v0.11 M4): each its board night as the tour lands, its tags and HUD in view;
## heretic_hunt-sweep has its first standard raised at once, for the district outline's photograph (Decision 79).
const TIER3_SHOWS := ["crowns_bread", "prisoner", "heretic_hunt", "heretic_hunt-sweep"]
## The new Tier 4 missions' photographs (v0.11 M5): each its board night as the tour lands, its tags and HUD in view.
const TIER4_SHOWS := ["bishop", "armoury", "sermon", "relic_run"]
## The new Tier 5 missions' photographs (v0.11 M6): each its board night as the tour lands, its tags and HUD in view; lantern_eye-hunt has
## its first mirror up at once and a beam drawn to a cast; heart_of_faith-odran has the flame out and the litter on its road.
const TIER5_SHOWS := ["lantern_eye", "exodus", "heart_of_faith", "lantern_eye-hunt", "heart_of_faith-odran"]
## The Awaken rite's photographs (god P3, Task 8, MS §6 GAP): the First Taste in the god's own night. `start` is the intro's end (tags, the Watch, the
## chain plate READY, 3 slots), `six` the same with 6 slots, `modes` Decree's Bell Lies focused last of 6 (pre-flight R2), `drag` a captive in the
## Watch's grip (the ring), `march` the muster after the first shard (leader tag, strip row), `walk` the file on its road, `cleanse` two clergy
## kneeling (the shrine's ring) and `win` the third shard (the win plate). Staged by `_stage_rite()`.
const RITE_SHOWS := ["first_taste-start", "first_taste-six", "first_taste-modes", "first_taste-drag", "first_taste-march", "first_taste-walk",
	"first_taste-cleanse", "first_taste-win"]
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
## What --show=results-feast displays (v0.10 M5): the campaign's Feast won by breaking the festival, its bonus earned.
const SAMPLE_FEAST_RESULT := {
	"mission": "feast_festival", "won": true, "reason": "festival", "time": 96.0, "path": "",
	"acts": [{"act": "festival", "won": true, "reason": "festival", "bonuses": [{"label": "Before the bell", "earned": true}],
		"time": 96.0}],
	"goal": {"label": "The festival is broken", "done": true}, "bonuses": [{"label": "Before the bell", "earned": true}],
	"campaign": {"won": true, "dp_gain": 3, "dp": 13, "bites": 0, "ending": ""},
}

## What --show=results-descend displays (v0.11 M1): the board's Warning caught by dawn after its main objective -- a granted wish
## lost, one failed -- as a test-mode night (god P1): nothing banked, its fastest clear shown.
const SAMPLE_DESCEND_RESULT := {
	"mission": "warning", "won": true, "reason": "warning", "time": 214.0, "goal": {"label": "The warnings die", "done": true},
	"bonuses": [],
	"descend": {"tier": 1, "main": true, "main_time": 201.0, "main_reward": 10, "ascended": false, "caught": "dawn",
		"lost_text": "lost: dawn came", "earned": 10, "kept": 0,
		"wishes": [{"text": "Burn the moneylender's house", "reward": 10, "state": "granted", "lost": true},
			{"text": "Show me a sign", "reward": 5, "state": "failed", "lost": false}],
		"bank": {"test": true, "night": 1, "cleared": true, "first_clear": true, "bests": ["Fastest clear 3:21"]}},
}
## What --show=results-endless displays (god P1, spec §9.2): the Warning won with two wishes granted, 120 Divine Power and two levels
## gained (7 and 8), the bar left a fifth of the way to the next.
const SAMPLE_ENDLESS_RESULT := {
	"mission": "warning", "won": true, "reason": "warning", "time": 201.0, "goal": {"label": "The warnings die", "done": true},
	"bonuses": [], "best": false,
	"descend": {"tier": 1, "main": true, "main_time": 201.0, "main_reward": 10, "ascended": false, "caught": "", "lost_text": "",
		"earned": 30, "kept": 2,
		"wishes": [{"text": "Burn the moneylender's house", "reward": 10, "state": "granted", "lost": false},
			{"text": "Show me a sign", "reward": 10, "state": "granted", "lost": false}]},
	"god": {"divine_power": 120, "levels": [7, 8], "points": 2, "lost": 0, "capped": false, "level": 8, "bar": [20, 50], "believers": 30,
		"faith": 30, "faith_total": 210, "notice": 0, "notice_change": 0, "night": 7, "bests": ["Fastest clear 3:21"]},
}
## What --show=results-hunt-won displays (god P2, spec §10.3): The Lost Lamb as the Tier 1 Hunt, won -- the main objective done, the Notice
## back to 0 (from 100) and the Hunt's Faith bonus paid. Shaped like GodNight.bank()'s result.
const SAMPLE_HUNT_WON := {
	"mission": "lost_lamb", "won": true, "reason": "lamb_out", "time": 188.0, "goal": {"label": "The lamb is free", "done": true},
	"bonuses": [], "best": false,
	"descend": {"tier": 1, "main": true, "main_time": 188.0, "main_reward": 10, "ascended": false, "caught": "", "lost_text": "",
		"earned": 10, "kept": 0, "wishes": []},
	"god": {"divine_power": 80, "levels": [8], "points": 1, "lost": 0, "capped": false, "level": 8, "bar": [15, 50], "believers": 10,
		"faith": 10, "faith_total": 240, "notice": 0, "notice_change": -100, "night": 7, "bests": [],
		"hunt": {"tier": 1, "id": "lost_lamb", "title": "Hide the faithful", "won": true, "faith": 50, "sealed": "", "seal_nights": 0},
		"unsealed": "", "hunt_next": false},
}
## What --show=results-hunt-lost displays (god P2, spec §10.3): the same Hunt lost -- the acolyte taken back -- the Notice set to 50 and the
## most-carried ability sealed for three nights.
const SAMPLE_HUNT_LOST := {
	"mission": "lost_lamb", "won": false, "reason": "lamb_taken", "time": 140.0, "goal": {"label": "The lamb is free", "done": false},
	"bonuses": [], "best": false,
	"descend": {"tier": 1, "main": false, "main_time": 0.0, "main_reward": 10, "ascended": false, "caught": "", "lost_text": "lost: the lamb was taken back",
		"earned": 0, "kept": 0, "wishes": []},
	"god": {"divine_power": 0, "levels": [], "points": 0, "lost": 0, "capped": false, "level": 7, "bar": [20, 50], "believers": 0,
		"faith": 0, "faith_total": 180, "notice": 50, "notice_change": -50, "night": 7, "bests": [],
		"hunt": {"tier": 1, "id": "lost_lamb", "title": "Hide the faithful", "won": false, "faith": 0, "sealed": "smite", "seal_nights": 3},
		"unsealed": "", "hunt_next": false},
}

var screen := Screen.TITLE
var save: SaveFile
## Where the save file lives: the real one, FLOW_TEST_SAVE under --flow-test, or SHOW_SAVE under --show.
var save_path := SaveFile.PATH
## The volumes (v0.11.2): loaded and put on the buses at boot, edited by the Options panel (pause and title), saved apart from the progress.
var settings := Settings.new()
var settings_path := Settings.PATH
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
## The ability levels the board's Prepare picker chose (god P1, spec §3, ruling P13): power key -> level 1-5, absent = 1. Set from
## Prepare's draft at MANIFEST and BEGIN, handed to the mission, and shown again by Prepare after Change powers; kept for Again
## and Restart, reset by a new board pick, and never saved.
var levels := {}
## --dev (capital plan, Task 15): the board shows its DEV tab, the dev-only missions (MissionBook.dev_missions()).
var dev := false
## Endless Night's god (god P1, spec §4): the slot being played, read or made from the slot select. null outside Endless Night.
var god: GodSlot = null
## Which of the three slots (1-3) `god` is, and where the slots' files live: GodSlot.PATH_BASE, FLOW_TEST_GOD under --flow-test, SHOW_GOD under --show.
var god_slot := 0
var god_base := GodSlot.PATH_BASE
## True from the slot select to the hub and its nights (god P1); false at the title and the board, as `_in_campaign` is. Prepare, the
## pause menu, the interlude and Results read it: a night is the god's, banked to its file and never to the board's save (C7).
var _in_endless := false
## A line the next hub shows once (god P1, Ruling P9, P21): "Night 3 was abandoned: a lost night." after an Abandon or a slot found mid-night.
var _hub_line := ""


## The screen an action leads to, or -1 when nothing offers it.
static func next_screen(action: String) -> int:
	return int(FLOW.get(action, -1))


## The file a run writes its save to: `current`, unless a --show sample is up (v0.10 M5 final review), which writes to
## SHOW_SAVE: a key pressed on a photographed screen must never reach the player's own save. Any --show value counts, so
## a sample added later is covered without anyone remembering to list it.
static func save_path_for(show: String, current: String) -> String:
	return SHOW_SAVE if show != "" else current


## The loadout Prepare opens with for a mission: the last one drafted for it, and for the night (v0.09) -- never
## played, or an old save with no section for it -- the night's default loadout. The other missions open empty.
static func starting_loadout(from: SaveFile, id: String) -> PackedStringArray:
	var kept := from.loadout_for(id)
	var def := MissionBook.get_mission(id)
	return def.default_loadout if kept.is_empty() and not def.acts.is_empty() else kept


## The powers the draft greys and refuses (v0.11 M1, spec §3.4): none, now that the board is a test mode with every power open
## (god P1, spec §3, ruling C3). The signature stays, and so does the unlock economy in DescendState, for a later change of mind.
static func locked_for(_from: SaveFile, _in_campaign: bool) -> PackedStringArray:
	return PackedStringArray()


## The powers a mission picked outside the campaign greys: none (god P1, ruling C3; it was none for a dev mission and the locks
## for any other).
static func board_locked_for(_from: SaveFile, _id: String) -> PackedStringArray:
	return PackedStringArray()


## The board's version of a mission for Prepare and the night (god P1, ruling C3): TierBook's slots and Might and no upgrades
## (`Mission.def_for(id, true, null)`). It takes no state, so a save's bought Might or slot changes nothing.
static func board_def(id: String) -> MissionDef:
	return Mission.def_for(id, true, null)


## Opens the god in `file` (god P1, spec §9.1, Ruling P9), as [the slot or null, the line the hub shows once]. A slot found with `in_night`
## set was left after its clock started -- the game was closed or crashed mid-night -- so it is forfeited at once (a lost night: counted,
## nothing earned), written, and the line is GodNight.forfeit()'s. A missing or damaged file gives [null, ""]. A static so a suite can prove it.
static func load_god(file: String) -> Array:
	var slot := GodSlot.read(file)
	if slot == null:
		return [null, ""]
	var line := ""
	if slot.in_night != "":
		line = String(GodNight.forfeit(slot).line)
		line = join_lines(line, write_god(slot, file))  # a forfeit now costs Notice: a disk error must not hide it (god P2, pre-flight G1)
	return [slot, line]


## What the hub says once when the god's file could not be written (god P2, Ruling P2-13): `%d` is the error code.
const WRITE_FAILED := "The god could not be saved (error %d): progress since the last save may be lost."
## The night's banner when the clock's start could not be written (review M4): a quit from here would escape the Notice unseen otherwise.
const CLOCK_SAVE_FAILED := "THE GOD COULD NOT BE SAVED"


## Writes `slot` to `file` (god P2, Ruling P2-13): "" when saved, else WRITE_FAILED's line. A forfeit costs Notice now, so a quit that
## escapes it through a disk error has to be seen. A static so a suite can prove it.
static func write_god(slot: GodSlot, file: String) -> String:
	var err := slot.write(file)
	return "" if err == OK else WRITE_FAILED % err


## `line` with `extra` added after it (god P2, Ruling P2-13, review I1): nothing when `extra` is empty, and nothing when `line` already says
## it, so a disk that fails every write shows its one sentence once on the hub, not once per write. A static so a suite can prove it.
static func join_lines(line: String, extra: String) -> String:
	if extra == "" or line.contains(extra):
		return line
	return extra if line == "" else line + " " + extra


## The levels a between-acts Prepare shows (god P1, final review M1): the board night's, chosen so far; none in the campaign, whose picker is
## off and whose `levels` may be a board night's left behind. A static so a suite can prove it.
static func between_acts_levels(campaign: bool, chosen: Dictionary) -> Dictionary:
	return {} if campaign else chosen


## What a finished Endless Night night does (god P1, Rulings P9, P10, C7): it is banked to the god (GodNight.bank(): Divine Power, Faith, bests,
## the carried abilities) and the result carries it for the results screen. The caller writes the god's file. Nothing of the board's save is
## touched -- no SaveFile is even passed in -- and no NEW BEST shows. A static so a suite can prove it.
static func bank_god_night(slot: GodSlot, id: String, kept: PackedStringArray, outcome: Dictionary) -> void:
	outcome["god"] = GodNight.bank(slot, id, kept, outcome)
	outcome["best"] = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	var args := OS.get_cmdline_user_args()
	dev = "--dev" in args
	if "--flow-test" in args:
		save_path = FLOW_TEST_SAVE
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		settings_path = FLOW_TEST_SETTINGS
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
		god_base = FLOW_TEST_GOD
		_remove_gods()
	elif Battlefield.arg_value(args, "--show") != "":
		settings_path = SHOW_SETTINGS
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
		god_base = SHOW_GOD
		_remove_gods()
	settings = Settings.new().load_from(settings_path)
	settings.apply()
	save = SaveFile.new().load_from(save_path)
	mission_id = save.last_mission
	loadout = starting_loadout(save, mission_id)
	# For the photographs (v0.08): --mission=<id> puts that mission on the board, Prepare or a paused run, with its
	# default loadout when nothing was drafted for it.
	var wanted := Battlefield.arg_value(args, "--mission")
	if wanted != "":
		# A composite id (v0.12, `tax_collector@capital`) is kept as given; get_mission() only validates it.
		mission_id = wanted if MissionBook.split_city(wanted)[1] != &"" else MissionBook.get_mission(wanted).id
		loadout = save.loadout_for(mission_id)
		if loadout.is_empty():
			loadout = MissionBook.get_mission(mission_id).default_loadout
	_fader = Fader.new()
	_fader.name = "Fader"
	add_child(_fader)
	var show := Battlefield.arg_value(args, "--show")
	# The screen opens on the player's own save, read above; what it writes goes elsewhere (v0.10 M5 final review).
	save_path = save_path_for(show, save_path)
	match show:
		"board":
			# A fresh god's board (v0.11 M1): Whisper open, the rest locked, nothing cleared -- not the player's carried-over
			# save, which may have opened Omen. The player's own save is not written (SHOW_SAVE).
			save.descend = DescendState.new()
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
		"results-feast":
			result = SAMPLE_FEAST_RESULT.duplicate(true)
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
		"options":  # v0.11.2: the title with the Options panel open
			go_to(Screen.TITLE)
			(_screen_node as TitleScreen)._open_options()
		"pause-options":
			go_to(Screen.MISSION)
			_open_pause()
			_pause._open_options()
		"campaign":
			if save.campaign == null:
				save.campaign = CampaignState.new()
			go_to(Screen.CAMPAIGN)
		"campaign-choice":
			# Night 2's three cards (v0.10), for the photograph; the player's save is not written (SHOW_SAVE).
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
		"tour":
			# Mira's House on its tour (v0.10 M6), for the photograph of a stop's caption among its tags.
			mission_id = MissionBook.MIRAS_HOUSE
			loadout = MissionBook.miras_house().default_loadout
			go_to(Screen.MISSION)
		"tiers":
			# The tier board near its top (v0.11 M1-M6): three of every tier cleared, for the photograph (SHOW_SAVE).
			# It opens on Whisper's tab, its five cards with the ticks and the best lines; --mission=vigil_flame opens Wrath's instead, --mission=procession Reckoning's, --mission=last_judgement Ascendance's.
			save.descend = DescendState.new()
			save.descend.cleared = PackedStringArray(["warning", "tax_collector", "first_prayers", "miras_house", "broken_lanterns", "bell_ringers",
				"vigil_flame", "festival", "crowns_bread", "procession", "bishop", "armoury", "last_judgement", "lantern_eye", "exodus"])
			save.descend.fastest = {"warning": 192.0}
			save.descend.most_wishes = {"warning": 2}
			save.descend.believers = 64
			save.descend.night = 5
			save.descend.refresh_open()
			if wanted == "":
				mission_id = MissionBook.WARNING
			go_to(Screen.BOARD)
		"upgrades":
			# The Upgrades with a purse (v0.11 M1), one +1 DP and one power bought, for the photograph (SHOW_SAVE).
			save.descend = DescendState.new()
			save.descend.believers = 165
			save.descend.dp_bought = 1
			go_to(Screen.UPGRADES)
			# One power bought on the screen itself (45 believers), so its cell reads "Unlocked" in the photograph.
			(_screen_node as UpgradesScreen).buy("pestilence")
		"results-descend":
			result = SAMPLE_DESCEND_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"ascend":
			# The board's Warning with its main objective done (v0.11 M1), for the photograph of THE NIGHT IS YOURS, the ASCEND
			# plate, the wishes' rows and their tags.
			mission_id = MissionBook.WARNING
			loadout = MissionBook.warning().default_loadout
			go_to(Screen.MISSION)
		"tax_collector", "spoiled_harvest", "lost_lamb", "first_prayers", "bell_ringers", "market_panic", "informer", "crowns_bread", "prisoner", "heretic_hunt", "bishop", "armoury", "sermon", "relic_run", "lantern_eye", "exodus", "heart_of_faith":
			# A new Tier 1-5 mission's board night (v0.11 M2-M6), for the photograph of its tags, its how-to-win line and its wishes.
			mission_id = show
			loadout = MissionBook.get_mission(show).default_loadout
			go_to(Screen.MISSION)
		"heretic_hunt-sweep":
			# The Heretic Hunt with its first standard up (v0.11 M4, Decision 79): the swept district's outline among the tags.
			mission_id = MissionBook.HERETIC_HUNT
			loadout = MissionBook.heretic_hunt().default_loadout
			go_to(Screen.MISSION)
		"lantern_eye-hunt", "heart_of_faith-odran":
			# The Lantern's Eye with its first mirror up and a beam drawn, The Heart of Faith with its litter walking (v0.11 M6).
			mission_id = show.get_slice("-", 0)
			loadout = MissionBook.get_mission(mission_id).default_loadout
			go_to(Screen.MISSION)
		"slots", "god-select", "hub", "hub-capped", "tree", "faith", "results-endless", "prepare-endless", "pause-endless":
			# Endless Night's screens (god P1), for the photographs: a fixture god on the dev fill, in the show's own slot files.
			_show_endless(show)
		"hub-hunt", "hub-sealed", "prepare-hunt", "prepare-sealed", "results-hunt-won", "results-hunt-lost", "pause-hunt":
			# The Lantern's states (god P2, Ruling P2-15, pre-flight G2): the same fixture god, the Hunt and the seal on show.
			_show_endless(show)
		"hub-awaken", "hub-unwritten", "hub-gifts", "prepare-rite", "prepare-gifts", "results-rite-won", "results-rite-lost", "pause-rite":
			# The Awaken rite's screens (god P3, Task 8): the hub's fifth button, the dim one, the gifts line, the rite's Prepare and results.
			_show_endless(show)
		"first_taste-start", "first_taste-six", "first_taste-modes", "first_taste-drag", "first_taste-march", "first_taste-walk", "first_taste-cleanse", "first_taste-win":
			_show_endless(show)
		"tiers-all":
			# The board complete (v0.11 M6): every board mission cleared, the header's "All 25 cleared", for the photograph (SHOW_SAVE).
			save.descend = DescendState.new()
			save.descend.cleared = TierBook.all()
			save.descend.believers = 990
			save.descend.night = 41
			save.descend.refresh_open()
			mission_id = MissionBook.LAST_JUDGEMENT
			go_to(Screen.BOARD)
		_:
			go_to(Screen.TITLE)
	if "--capture" in args:
		# A second for anything behind the screen to settle, then one frame to disk. This is how each screen
		# task shows its work: SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture
		# A mission underneath (the pause photograph) only builds its town once its shader prewarm is done,
		# which takes longer than that second -- the first pause capture showed the menu over bare grass.
		if is_instance_valid(_mission) and not _mission.started():
			await _mission.prewarmed
		if (show in ["miras", "cael", "lanterns", "flame", "flame-beams"] or show in RITE_SHOWS or show in TIER1_SHOWS or show in TIER2_SHOWS or show in TIER3_SHOWS or show in TIER4_SHOWS or show in TIER5_SHOWS) and is_instance_valid(_mission):
			# Their photographs are of play (v0.10 M6): the tour is skipped, as a player would.
			await _until(func() -> bool: return _mission.started(), 10.0)
			_mission.skip_intro()
			if show == "heretic_hunt-sweep" and _mission.rules().director is HuntDirector:
				(_mission.rules().director as HuntDirector)._raise(0)
			if show == "lantern_eye-hunt" and _mission.rules().director is LanternEyeDirector:
				var eye := _mission.rules().director as LanternEyeDirector
				eye._raise(0)
				eye._on_cast(0, "smite", eye.outer_face(0))
			if show == "heart_of_faith-odran" and _mission.rules().director is HeartOfFaithDirector:
				var heart := _mission.rules().director as HeartOfFaithDirector
				heart._open(0)
				heart._raze(heart.targets[0])
				heart._open(1)
				heart._raze(heart.targets[1])
				heart._odran_comes()
		if (show in ["miras", "lanterns", "flame", "flame-beams"] or show in RITE_SHOWS or show in TIER1_SHOWS or show in TIER2_SHOWS or show in TIER3_SHOWS or show in TIER4_SHOWS or show in TIER5_SHOWS) and is_instance_valid(_mission) \
				and is_instance_valid(_mission._hud):
			# The opening banners cover the middle of the screen for their first seconds (v0.10 M6): wait them out, so the
			# tags are photographed clear. (Bounded in frames, so a HUD that never empties still gets its photograph.)
			for _frame in 1200:
				if _mission._hud.banners().is_empty():
					break
				await get_tree().process_frame
		if show in RITE_SHOWS and is_instance_valid(_mission):
			await _stage_rite(show)
		if show == "ascend" and is_instance_valid(_mission):
			await _until(func() -> bool: return _mission.started(), 10.0)
			_mission.skip_intro()
			for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
				w.warning_dead = true
			await _until(func() -> bool: return _mission.rules().main_done, 3.0)
		if show == "flame-beams" and is_instance_valid(_mission) and _mission.rules() != null \
				and _mission.rules().director is VigilFlameDirector:
			(_mission.rules().director as VigilFlameDirector).bench_beams()
		if show == "cael" and is_instance_valid(_mission) and is_instance_valid(_mission._hud):
			# Cael's line under its event's banner (v0.10 M5), for the photograph of the subtitle. The HUD shows one
			# banner at a time and the mission's own come first (its name, then its goal): wait them out, or the
			# event's would queue behind them and the line would be photographed under the wrong banner. (Bounded in
			# frames, so a HUD that never empties still gets its photograph.)
			for _frame in 1200:
				if _mission._hud.banners().is_empty():
					break
				await get_tree().process_frame
			_mission._hud.push_banner("THE INQUISITOR SEARCHES")
			_mission._hud.push_subtitle(CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "venn"))
		var wait := 1.0
		if show == "first_taste-win":
			wait = 0.6  # at the ending's 0.3 time scale: about 2 s real, inside the win plate's 4
		elif show.begins_with("flame"):
			wait = 2.0
		elif show == "tour":
			# v0.11.1: the tour waits for the opening banners; then held at the second stop.
			for _frame in 1200:
				if not is_instance_valid(_mission) or _mission._hud.banners().is_empty():
					break
				await get_tree().process_frame
			wait = IntroTour.MOVE_SECONDS * 2.0 + IntroTour.HOLD_SECONDS + 0.4
		await get_tree().create_timer(wait).timeout
		await _capture("screen_%s.png" % (show if show != "" else "start"))
		if god_base == SHOW_GOD:
			_remove_gods()
		await _quit_cleanly()
	elif "--flow-test" in args:
		await _flow_test()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		_remove_gods()
		await _quit_cleanly()


## Put up a screen, taking down whatever was there.
func go_to(to: int) -> void:
	_close_pause()
	var from := screen
	screen = to
	# Leaving the campaign (v0.10 M5), whichever way -- its Title, or its ending: the board's own mission and loadout come
	# back, so Missions opens on the last board pick rather than the campaign's last night.
	# The same for Endless Night (god P1): its nights drew their own missions, and the god is put down.
	if (to == Screen.TITLE or to == Screen.BOARD) and (_in_campaign or _in_endless):
		mission_id = save.last_mission
		loadout = starting_loadout(save, mission_id)
	if to == Screen.TITLE or to == Screen.BOARD:
		_in_campaign = false
		_in_endless = false
		god = null
	elif to == Screen.CAMPAIGN:
		_in_campaign = true
	elif to in [Screen.SLOTS, Screen.GOD_SELECT, Screen.HUB, Screen.TREE, Screen.FAITH]:
		_in_endless = true
		if to == Screen.SLOTS:
			god = null  # the slot select puts the god down; Continue or the god select picks one up
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
			title.setup(save.best_score, save.best_rank, settings, settings_path)
			title.action.connect(_on_title_action)
			_screen_node = title
		Screen.BOARD:
			var board := MissionBoard.new()
			board.name = "Board"
			board.dev = dev
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
				# The levels chosen so far show again, and can be changed, in a board night (god P1, pre-flight G1). An Endless Night
				# draft is the god's: its abilities at its levels, no picker.
				prep.level_picker = not _in_campaign and not _in_endless
				prep.levels = between_acts_levels(_in_campaign, levels)
				if _in_endless:
					prep.god = god
				prep.setup(act, loadout, save.difficulty, locked_for(save, _in_campaign))
				prep.confirm_label = "BEGIN"
			elif _in_endless and god != null:
				# Endless Night's night (god P1, spec §9.1): the drawn mission as this god plays it, drafting from what it has learned.
				prep.god = god
				prep.setup(GodNight.def_for(god, mission_id), loadout, save.difficulty)
			elif _in_campaign and save.campaign != null:
				prep.setup(save.campaign.mission(mission_id), loadout, save.difficulty)
			else:
				# The board is a test mode (god P1): TierBook's slots and Might with no upgrades, every power open, and the level
				# picker, which starts from the levels chosen before (Change powers, Again).
				prep.level_picker = true
				prep.levels = levels
				prep.setup(board_def(mission_id), loadout, save.difficulty, board_locked_for(save, mission_id))
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
			night.setup(save.campaign, mission_id)
			night.action.connect(_on_campaign_action.bind(night))
			_screen_node = night
		Screen.ENDING:
			var end := EndingScreen.new()
			end.name = "Ending"
			add_child(end)
			end.setup(save.campaign.ending, save.campaign.ending_fragment(), EndingScreen.summary_text(save.campaign))
			end.action.connect(_on_ending_action)
			_screen_node = end
		Screen.UPGRADES:
			var up := UpgradesScreen.new()
			up.name = "Upgrades"
			add_child(up)
			up.setup(save.descend)
			up.action.connect(_on_upgrades_action)
			_screen_node = up
		Screen.SLOTS:
			var slots := SlotScreen.new()
			slots.name = "Slots"
			add_child(slots)
			slots.setup(god_base)
			slots.action.connect(_on_slots_action.bind(slots))
			_screen_node = slots
		Screen.GOD_SELECT:
			var pick := GodSelectScreen.new()
			pick.name = "GodSelect"
			add_child(pick)
			pick.setup()
			pick.action.connect(_on_god_select_action.bind(pick))
			_screen_node = pick
		Screen.HUB:
			var hub := GodHub.new()
			hub.name = "Hub"
			add_child(hub)
			hub.setup(god, _hub_line, dev)
			_hub_line = ""  # shown once
			hub.action.connect(_on_hub_action)
			_screen_node = hub
		Screen.TREE:
			var tree := SkillTreeScreen.new()
			tree.name = "Tree"
			add_child(tree)
			tree.setup(god)
			tree.action.connect(_on_tree_action)
			_screen_node = tree
		Screen.FAITH:
			var faith := FaithScreen.new()
			faith.name = "Faith"
			add_child(faith)
			faith.setup(god)
			faith.action.connect(_on_faith_action)
			_screen_node = faith
		_:
			push_warning("KAK screen %d has nothing to show yet" % to)
	match to:
		Screen.TITLE, Screen.BOARD, Screen.PREPARE, Screen.CAMPAIGN, Screen.ENDING, Screen.UPGRADES, Screen.SLOTS, Screen.GOD_SELECT, \
				Screen.HUB, Screen.TREE, Screen.FAITH:
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
	_interlude.endless = _in_endless  # leaving between acts costs the night: the screen asks first (final review I2)
	if _in_endless and god != null:
		_interlude.notice = god.notice  # and says the Notice rise it will really cause (god P2 fix wave, M2)
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
			if _in_endless:
				# Leaving a night between its acts is leaving it after its clock started: a lost night (god P1, Ruling P9).
				_abandon_night()
				on_action("interlude:hub")
			else:
				on_action("interlude:missions")


func _build_mission() -> Mission:
	var mission: Mission = load(MISSION_SCENE).instantiate()
	mission.autostart = false  # set before add_child(), so its _ready() does not start a mission of its own
	mission.difficulty = save.difficulty
	mission.mission_id = mission_id
	# Outside the campaign every mission is a board night (v0.11 M1): its tier's version, the god's upgrades, and wishes
	# drawn from the nights played -- the same again on a Restart, redrawn once a night is counted.
	mission.board = not _in_campaign
	mission.descend = null  # no upgrades on the board (god P1, ruling C3); the wishes' seed below still counts the nights
	mission.levels = {} if _in_campaign else levels.duplicate()
	mission.wish_seed = Descent.seed_for(save.descend.night, mission_id)
	mission.bell_rang = _in_campaign and save.campaign != null and save.campaign.bell_rang
	if _in_endless and god != null:
		# Endless Night's night (god P1, spec §9.1): the god's version of the drawn mission, its learned levels, wishes seeded by the
		# god and its night (the same after a quit and a return), no restart, and the clock's start is written to the god's file (P9).
		mission.night_def = func() -> MissionDef: return GodNight.def_for(god, mission_id)
		mission.levels = god.learned.duplicate()
		mission.wish_seed = GodNight.wish_seed(god, mission_id)
		mission.restart_locked = true
		mission.report_on_decision = true  # the night banks when it is decided, not after its ending (review M1)
		mission.clock_started.connect(_on_clock_started.bind(mission))
		mission.decided.connect(_on_night_decided)
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
	if _in_endless and god != null:
		# Endless Night (god P1, Rulings P9, P10, C7): the night is banked to the god and only the god's file is written -- already
		# done when the night was decided (review M1), which put "god" in this same result.
		if not outcome.has("god"):
			bank_god_night(god, mission_id, loadout, result)
			_write_god()
	else:
		bank_night(save, mission_id, loadout, result, _in_campaign)
		save.save_to(save_path)
	on_action("mission:over")


## An Endless night is decided (god P2 fix wave, review M1): it is banked and written now, so a window closed during the 2-3 s ending
## keeps the night as played instead of forfeiting it. `finished` brings the same result afterwards and does not bank it again.
func _on_night_decided(outcome: Dictionary) -> void:
	if not _in_endless or god == null:
		return
	bank_god_night(god, mission_id, loadout, outcome)
	_write_god()


## What a finished night does to the save (not written to disk: the caller does that), a static so a suite can prove it (v0.12): a
## campaign night is the campaign's; a board night is banked; a dev night, a town's `<mission>@<city>` included, only records its own best
## under its own id and leaves the tier board's state (night, believers, cleared) alone.
static func bank_night(into: SaveFile, id: String, kept: PackedStringArray, outcome: Dictionary, in_campaign: bool) -> void:
	if in_campaign and into.campaign != null:
		# A campaign night is the campaign's (v0.10): The Warning and Last Judgement share their ids with the board, whose
		# best results and drafted loadouts it must not touch.
		outcome["campaign"] = into.campaign.record(id, outcome)
		outcome["best"] = false
	elif outcome.has("descend") and not MissionBook.is_dev(id):
		# A board night (v0.11 M1, spec §3.3, §6), a test mode since god P1 (spec §3, rulings C3, P11): the night counted (only to
		# seed the wishes), its mission cleared and its bests kept -- no believers banked, no tier opened (DescendState.bank_test()).
		# record() still runs so the title's best score and rank keep updating, but its NEW BEST is not shown: the board's results
		# have their own bests (controller ruling, Task 11).
		(outcome.descend as Dictionary)["bank"] = into.descend.bank_test(id, outcome.descend)
		into.record(id, outcome)
		outcome["best"] = false
		into.remember_loadout(id, kept)
	else:
		outcome["best"] = into.record(id, outcome)
		into.remember_loadout(id, kept)


## An act of the night is over (v0.09): its result for the interlude, and the loadout kept for the re-draft.
func _on_act_over(res: Dictionary) -> void:
	_between_acts = true
	_next_path = ""
	result = res
	if not _in_endless:  # Endless Night writes only the god's file (god P1, C7)
		save.remember_loadout(mission_id, loadout)
		save.save_to(save_path)
	on_action("mission:act_over")


## The board's pick becomes the mission to prepare, with the loadout last drafted for it; the save remembers it.
func _on_board_action(what: String, board: MissionBoard) -> void:
	if what == "endless":
		# The DEV door into Endless Night (god P1, Rulings P2, P14): the dev fill of the tree is on for the session.
		GodTree.dev_fill = true
	if what == "pick":
		mission_id = board.chosen
		levels = {}  # a new pick starts every power at level 1 (god P1, ruling P13)
		save.last_mission = mission_id
		loadout = starting_loadout(save, mission_id)
		save.save_to(save_path)
	on_action("board:" + what)


## The night screen's buttons (v0.10): on to Prepare for tonight's mission, with the loadout last drafted for it; a
## fresh campaign; or back to the title (go_to() puts the board's mission back).
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
			on_action("campaign:title")


## A Results button's action (v0.10): a campaign night's Continue leads to the ending once the campaign has one.
func _results_action(what: String) -> String:
	if what == "next" and _in_campaign and save.campaign != null and save.campaign.ending != "":
		return "results:ending"
	return "results:" + what


## The ending's last page turned, or Esc (v0.10 M5): the ending has been seen, so Campaign next begins afresh.
func _on_ending_action(what: String) -> void:
	if save.campaign != null and not save.campaign.ending_seen:
		save.campaign.ending_seen = true
		save.save_to(save_path)
	on_action("ending:" + what)


## The Upgrades screen (v0.11 M1): each purchase is saved at once; Back is the tier board.
func _on_upgrades_action(what: String) -> void:
	if what == "bought":
		save.save_to(save_path)
	elif what == "back":
		on_action("upgrades:back")


## The slot select (god P1, spec §4): Continue opens the slot's god (a night left mid-way is forfeited at once: Ruling P9), New goes to the
## god select, which makes the god and writes its file -- over an old one, only once it is chosen -- and Back is the board.
func _on_slots_action(what: String, slots: SlotScreen) -> void:
	match what:
		"continue":
			god_slot = slots.chosen
			var opened := load_god(GodSlot.path(god_slot, god_base))
			if opened[0] == null:
				return
			god = opened[0]
			_hub_line = String(opened[1])
			on_action("slots:continue")
		"new":
			god_slot = slots.chosen
			on_action("slots:new")
		"back":
			on_action("slots:back")


## The god select (god P1, spec §4): the type chosen makes the god (the seed from the clock) and writes it; Back is the slot select.
func _on_god_select_action(what: String, pick: GodSelectScreen) -> void:
	match what:
		"chosen":
			god = GodSlot.make(god_slot, pick.chosen_type, GodSlot.fresh_seed())
			_hub_line = ""
			_write_god()
			on_action("god:chosen")
		"back":
			on_action("god:back")


## The mission id Awaken opens for `slot` (god P3, MS §1, Ruling P3-21): "" when it opens nothing -- the god is below its tier's cap, is at
## the highest level, has no rite written for its level, or has nothing to draft (as Descend) -- else the Hunt while the Notice is full
## (exactly Descend's draw: the Hunt cannot be skipped, P2-4; the rite waits for the next night), else the rite for its level. A static so
## a suite can prove it.
static func awaken_target(slot: GodSlot) -> String:
	if slot == null or slot.draftable().is_empty():
		return ""
	var state := GodNight.awaken_state(slot)
	if state == "":
		return ""
	if slot.hunt_due():
		return GodNight.draw(slot)
	return String(GodNight.rite_for(slot).get("id", ""))


## The hub (god P1, spec §9): Descend draws the night (the same until one counts) and opens its Prepare, blocked while the god has nothing
## to draft; Awaken (god P3) opens the rite's Prepare -- the Hunt's while it is due (`awaken_target()`); `awaken_dev` (dev, a level with no rite
## written) raises the tier and writes; the rest are FLOW's.
func _on_hub_action(what: String) -> void:
	match what:
		"descend":
			if god.draftable().is_empty():
				return
			mission_id = GodNight.draw(god)
			loadout = god.loadout.duplicate()
			on_action("hub:descend")
		"awaken":
			var target := awaken_target(god)
			if target == "":
				return
			mission_id = target
			loadout = god.loadout.duplicate()
			on_action("hub:awaken")
		"awaken_dev":
			god.awaken()
			_write_god()
			go_to(Screen.HUB)
		_:
			on_action("hub:" + what)


## The Skill Tree: a point spent is written at once; Back is the hub.
func _on_tree_action(what: String) -> void:
	if what == "learned":
		_write_god()
	elif what == "back":
		on_action("tree:back")


## The Faith screen: a purchase is written at once; Back is the hub.
func _on_faith_action(what: String) -> void:
	if what == "bought":
		_write_god()
	elif what == "back":
		on_action("faith:back")


## The pause menu over an Endless Night night (god P1, Ruling P9): Abandon forfeits a night whose clock has started, then goes to the hub.
func _on_pause_action(what: String) -> void:
	if what == "abandon":
		_abandon_night()
	on_action("pause:" + what)


## Leaves the night in progress (god P1, Ruling P9, P21): one whose clock has started is a lost night -- counted, nothing earned, no results
## screen, the hub shows its line once; one that has not started costs nothing.
func _abandon_night() -> void:
	_hub_line = ""
	if god == null or god.in_night == "":
		return
	_hub_line = String(GodNight.forfeit(god).line)
	_write_god()


## The night's clock has started (god P1, Ruling P9): from here leaving is a lost night, so the god's file says so now, once.
## A failed write shows on the night's banner at once too (review M4): the hub's line alone is never seen if the player then quits.
func _on_clock_started(mission: Mission) -> void:
	if god == null or not _in_endless or god.in_night == mission_id:
		return
	god.in_night = mission_id
	if _write_god() != "" and is_instance_valid(mission):
		mission.announce(CLOCK_SAVE_FAILED)


## Writes the god in play to its slot's file: "" when saved, else the failure's line (also kept for the next hub).
func _write_god() -> String:
	if god == null or god_slot < 1:
		return ""
	var failed := write_god(god, GodSlot.path(god_slot, god_base))
	if failed != "":
		push_warning("KAK could not write the god in slot %d: %s" % [god_slot, failed])
		_hub_line = join_lines(_hub_line, failed)  # the next hub shows it once (god P2, Ruling P2-13)
	return failed


## Removes the three slot files under `god_base`: a --flow-test or --show run starts and ends without a god.
func _remove_gods() -> void:
	for n in range(1, GodSlot.COUNT + 1):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GodSlot.path(n, god_base)))


## The photographed god (god P1): a ruin god, level 7 (or `level`), tier 1 (or `tier`, god P3), three points, Smite at 3, Ember and Deathmark at 1,
## 180 Faith, on its sixth night.
func _show_god(level: int, tier := 1) -> GodSlot:
	var g := GodSlot.make(1, "ruin", 77)
	g.level = level
	g.tier = tier
	g.points = 3
	g.learned = {"smite": 3, "ember": 1, "deathmark": 1}
	g.faith = 180
	g.night = 6
	g.last_mission = MissionBook.WARNING
	g.loadout = PackedStringArray(["smite", "ember"])
	g.divine_power = g.need() if g.capped() else 20
	return g


## --show=<name> for Endless Night's screens (god P1): the fixture god on the dev fill, written to the show's own slot files. `hub-capped` is
## the same god at level 10 (the tier's cap); `pause-endless` has the night's clock started, so Abandon's confirm says the night is lost.
func _show_endless(show: String) -> void:
	GodTree.dev_fill = true
	dev = true
	_in_endless = true
	god_slot = 1
	var rite_night := show in RITE_SHOWS
	match show:
		"hub-unwritten":
			god = _show_god(20, 2)  # capped at the next cap, no rite written there yet: the dim Awaken
		"hub-gifts", "prepare-gifts":
			god = _show_god(12, 2)  # past the First Taste, holding its gift
			god.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL])
		_:
			var capped := show in ["hub-capped", "hub-awaken", "prepare-rite", "results-rite-won", "results-rite-lost", "pause-rite"] or rite_night
			god = _show_god(10 if capped else 7)
	if rite_night:
		_show_rite_loadout(show)
	_write_god()
	match show:
		"slots":
			var other := GodSlot.make(2, "veil", 5)
			other.level = 3
			other.night = 1
			other.write(GodSlot.path(2, god_base))
			go_to(Screen.SLOTS)
		"god-select":
			go_to(Screen.GOD_SELECT)
		"hub", "hub-capped":
			_hub_line = GodNight.ABANDONED % god.night if show == "hub" else ""
			go_to(Screen.HUB)
		"tree":
			go_to(Screen.TREE)
		"faith":
			go_to(Screen.FAITH)
		"results-endless":
			result = SAMPLE_ENDLESS_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
		"prepare-endless":
			mission_id = MissionBook.WARNING
			loadout = god.loadout.duplicate()
			go_to(Screen.PREPARE)
		"pause-endless":
			mission_id = MissionBook.WARNING
			loadout = god.loadout.duplicate()
			god.in_night = mission_id
			go_to(Screen.MISSION)
			_open_pause()
			if is_instance_valid(_pause):
				_pause._set_confirm(true)
		"hub-hunt":
			god.notice = GodSlot.NOTICE_MAX  # the Hunt is due: the meter full, the Hunt's line
			_write_god()
			go_to(Screen.HUB)
		"hub-sealed":
			# A lost Hunt's aftermath (god P2): the seal target sealed with two nights left, the Notice at 50, and the forfeit's own line.
			god.notice = GodSlot.NOTICE_MAX
			god.in_night = GodNight.HUNTS[0].id
			_write_god()
			god = GodSlot.read(GodSlot.path(god_slot, god_base))  # a copy, forfeited as a game closed mid-Hunt would be
			_hub_line = String(GodNight.forfeit(god).line)
			god.seal_nights = 2
			_write_god()
			go_to(Screen.HUB)
		"prepare-hunt":
			god.notice = GodSlot.NOTICE_MAX
			_write_god()
			mission_id = GodNight.draw(god)
			loadout = god.loadout.duplicate()
			go_to(Screen.PREPARE)
		"prepare-sealed":
			god.seal(god.seal_target())
			god.seal_nights = 2
			god.notice = 50
			_write_god()
			mission_id = GodNight.draw(god)
			loadout = god.loadout.duplicate()
			go_to(Screen.PREPARE)
		"results-hunt-won", "results-hunt-lost":
			result = (SAMPLE_HUNT_WON if show == "results-hunt-won" else SAMPLE_HUNT_LOST).duplicate(true)
			go_to(Screen.RESULTS)
		"pause-hunt":
			# The Hunt's pause menu with Abandon's confirm up: it names what the Lantern would seal (god P2, pre-flight G2).
			god.notice = GodSlot.NOTICE_MAX
			mission_id = GodNight.draw(god)
			loadout = god.loadout.duplicate()
			god.in_night = mission_id
			go_to(Screen.MISSION)
			_open_pause()
			if is_instance_valid(_pause):
				_pause._set_confirm(true)
		"hub-awaken", "hub-unwritten", "hub-gifts":
			_hub_line = ""
			go_to(Screen.HUB)
		"prepare-rite":
			mission_id = RiteBook.FIRST_TASTE
			loadout = god.loadout.duplicate()
			go_to(Screen.PREPARE)
		"prepare-gifts":
			mission_id = GodNight.draw(god)
			loadout = god.loadout.duplicate()
			go_to(Screen.PREPARE)
		"results-rite-won", "results-rite-lost":
			# The rite's results as banking makes them (god P3, P2's Task 4 M5): GodNight.bank() on the fixture god, from a result shaped
			# like the director's -- never a hand-written "god" entry.
			var won := show == "results-rite-won"
			result = {"mission": RiteBook.FIRST_TASTE, "won": won, "reason": "shards" if won else "cleansed", "time": 197.0 if won else 143.0,
				"goal": {"label": "Three Lantern shards", "done": won}, "bonuses": [], "best": false,
				"rite": {"id": RiteBook.FIRST_TASTE, "shards": 3 if won else 2, "need": 3, "flame_out": not won, "marches": 2}}
			loadout = god.loadout.duplicate()
			god.in_night = RiteBook.FIRST_TASTE
			bank_god_night(god, RiteBook.FIRST_TASTE, loadout, result)
			go_to(Screen.RESULTS)
		"pause-rite":
			# The rite's pause menu with Abandon's confirm up: it says the rite is lost and what that costs (god P3, MS §1).
			mission_id = RiteBook.FIRST_TASTE
			loadout = god.loadout.duplicate()
			god.in_night = mission_id
			go_to(Screen.MISSION)
			_open_pause()
			if is_instance_valid(_pause):
				_pause._set_confirm(true)
		_:
			if rite_night:
				mission_id = RiteBook.FIRST_TASTE
				go_to(Screen.MISSION)


## The god of a First Taste photograph (god P3): `six` and `modes` have six slots and six learned abilities (`modes`: Decree's, The Bell Lies last), the
## others the fixture's three. Sets `loadout` as the draft would.
func _show_rite_loadout(show: String) -> void:
	loadout = god.loadout.duplicate()
	if show not in ["first_taste-six", "first_taste-modes"]:
		return
	god.bought["slot"] = 3
	var keys := PackedStringArray()
	for type: String in GodTree.RING:  # any six abilities will do for a photograph of the row: every type's, learned at 1
		for key in GodTree.keys_for(type, 5):
			if key != "belllies" and not keys.has(key):
				keys.append(key)
				god.learned[key] = maxi(int(god.learned.get(key, 0)), 1)
	god.learned["belllies"] = 1
	loadout = PackedStringArray()
	for key in keys:
		if loadout.size() < (5 if show == "first_taste-modes" else 6):
			loadout.append(key)
	if show == "first_taste-modes":
		loadout.append("belllies")


## Stages a First Taste photograph past its intro (god P3, Task 8): the director's own paths, as the Tier 5 shots are staged. The mission is up
## and started; the opening banners are waited out by the caller for `start`/`six`/`modes`, and here for the rest.
func _stage_rite(show: String) -> void:
	await _until(func() -> bool: return _mission.started(), 10.0)
	_mission.skip_intro()
	var d := _mission.rules().director as FirstTasteDirector
	if d == null or not is_instance_valid(_mission._hud):
		return
	for _frame in 1200:  # the opening banners cover the middle of the screen for their first seconds
		if _mission._hud.banners().is_empty():
			break
		await get_tree().process_frame
	match show:
		"first_taste-modes":
			_mission._aim.pick(5)  # The Bell Lies, last of six: its modes plate lies where the chain plate would sit
		"first_taste-drag":
			var victim: Person = d.marked[0]
			d.chain(victim)
			await get_tree().create_timer(RiteDirector.BITE + 1.5).timeout
			var watchman: Variant = d.watch[0] if not d.watch.is_empty() else null
			if watchman is Person and is_instance_valid(victim):
				(watchman as Person).ground_pos = victim.ground_pos + Vector2(0.6, 0.0)  # the grip: the ring fills on his tag
				await get_tree().create_timer(1.6).timeout
		"first_taste-march", "first_taste-walk", "first_taste-cleanse":
			d.offer(d.marked[0])
			if show == "first_taste-march":
				await get_tree().create_timer(3.0).timeout
			elif show == "first_taste-walk":
				await get_tree().create_timer(FirstTasteDirector.MARCH_AFTER + 6.0).timeout
			else:
				var m: FirstTasteDirector.March = d.marches[0]
				m.walking = true
				m.muster_left = 0.0
				for k in m.people.size():
					var p := m.people[k] as Person
					m.spots[p] = d._kneel_spot(m, k)
					m.paused[p] = false
					p.ground_pos = m.spots[p]
					p.go_duty(p.ground_pos)
				await get_tree().create_timer(4.0).timeout
		"first_taste-win":
			for _shard in d.need():
				d.offer(d.marked[0])  # the ending runs at 0.3 time scale: the generic wait below is short, so the plate (4 s real) is still up


func _on_prepare_action(what: String, prep: PrepareScreen) -> void:
	if _between_acts:
		# The re-draft between acts (v0.09): BEGIN carries the night on, Back returns to the interlude -- but not once
		# BEGIN's fade is under way: Back, then Missions from the interlude, would free the night it is carrying on.
		if _fading:
			return
		if what == "manifest":
			if _in_endless and prep.draft.picks.is_empty():
				prep.refuse(PrepareScreen.REFUSE_EMPTY)  # as the button does (pre-flight R2)
				return
			loadout = prep.draft.picks
			if not _in_campaign and not _in_endless:
				levels = prep.draft.levels.duplicate()
				if is_instance_valid(_mission):
					_mission.levels = levels.duplicate()  # the next act's Rules read them (god P1, pre-flight G1)
			if not _in_endless:  # the god's draft is not the board's: only the god's file is written (pre-flight R1)
				save.remember_loadout(mission_id, loadout)
				save.save_to(save_path)
			on_action("prepare:begin")
		elif what == "back":
			go_to(Screen.INTERLUDE)
		return
	if what == "back" and _in_campaign:
		on_action("prepare:campaign")
		return
	if _in_endless:
		# Endless Night's Prepare (god P1): back to the hub is free (nothing started); MANIFEST needs a pick (pre-flight R2) and writes no
		# save of the board's (R1): the loadout is the god's, kept when the night is banked.
		if what == "back":
			on_action("prepare:hub")
		elif what == "manifest":
			if prep.draft.picks.is_empty():
				prep.refuse(PrepareScreen.REFUSE_EMPTY)
				return
			loadout = prep.draft.picks
			on_action("prepare:manifest")
		return
	if what == "manifest":
		loadout = prep.draft.picks
		levels = {} if _in_campaign else prep.draft.levels.duplicate()  # kept for Again and Restart, never saved (ruling P13)
		if not _in_campaign:
			save.remember_loadout(mission_id, loadout)
		save.difficulty = prep.difficulty
		save.save_to(save_path)
	on_action("prepare:" + what)


## A key press as the player would make it, for FLOW's real-input checks (v0.11.1).
func _flow_key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	return e


func _open_pause() -> void:
	if is_instance_valid(_pause) or not is_instance_valid(_mission):
		return
	_mission.set_frozen(true)
	_pause = PauseMenu.new()
	_pause.name = "Pause"
	add_child(_pause)
	if _in_endless and god != null and god.in_night != "" and String(GodNight.hunt_for(god).get("id", "")) == mission_id:
		_pause.hunt_stake = GodNight.hunt_stake(god)  # the Hunt: Abandon says what the Lantern would seal (god P2, Ruling P2-11)
	if _in_endless and god != null:
		_pause.notice = god.notice  # the lost-night confirm states the rise it will really cause (god P2 fix wave, M2)
	# Endless Night's menu (god P1, Ruling P9): no Restart, no Change powers, and Abandon night, which says whether it costs the night.
	_pause.rite = _in_endless and god != null and GodNight.is_rite(mission_id)  # the lost-rite confirm (god P3, MS §1)
	_pause.setup(_in_campaign, settings, settings_path, _in_endless, _in_endless and god != null and god.in_night != "")
	UiSound.play(&"ui_pause")
	Music.set_ducked(true)
	_pause.action.connect(_on_pause_action)


func _close_pause() -> void:
	if is_instance_valid(_pause):
		_pause.queue_free()
	_pause = null
	get_viewport().gui_release_focus()  # v0.11.1: a clicked menu button must not keep TAB
	Music.set_ducked(false)


func _on_title_action(what: String) -> void:
	match what:
		"sandbox":
			get_tree().change_scene_to_file(SANDBOX_SCENE)
		"quit":
			get_tree().quit()
		"campaign":
			# An ending not yet seen (v0.10 M5: the game quit on the last night's Results) is shown first.
			if save.campaign != null and save.campaign.ending != "" and not save.campaign.ending_seen:
				on_action("title:ending")
				return
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


## Waits out the mission's intro (FLOW). Any intro -- a tour (v0.10 M6) or a sweep with the prayers' hold (v0.11.1) -- is skipped
## at once, as a player would.
func _past_intro() -> void:
	if is_instance_valid(_mission) and _mission.in_intro():
		_mission.skip_intro()
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)


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
	step.call((_screen_node as TitleScreen)._menu.items.size() == 5 and String((_screen_node as TitleScreen)._menu.items[2].action) == "options",
		"the title's third row is Options")
	step.call(Music.current() == &"theme", "the title plays the theme")
	# The title's first frames compile its shaders, which can take seconds; let them pass before anything is timed.
	await get_tree().process_frame
	await get_tree().process_frame
	on_action("title:play")
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard, "Play opens the mission board")
	step.call(Music.current() == &"theme", "the board plays the theme")
	await _flow_board(step)
	await _flow_ascend(step)
	await _flow_results(step)
	await _flow_tier1(step)
	await _flow_tier2(step)
	await _flow_tier3(step)
	await _flow_tier4(step)
	await _flow_tier5(step)
	await _flow_dev_town(step)
	await _flow_endless(step)
	await _flow_lantern(step)
	await _flow_rite(step)
	_veteran()
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
	# v0.11.1: a night that heard wishes ends its sweep on the prayers' hold (Mission.PRAYERS_SECONDS), which waits for the opening
	# banners to go: so wait for the hold and then for the intro to land, not for a fixed time.
	var prayed := _mission.descent() != null and not _mission.descent().wishes.is_empty()
	if prayed:
		var prays := await _until(func() -> bool: return _mission._hud.praying, Mission.INTRO_SECONDS + 15.0)
		step.call(prays and _mission.rules().time_left == clock0 and _mission._hud.banners().is_empty(),
			"the sweep ends on the town's prayers, the clock still waiting")
	await _until(func() -> bool: return not _mission.in_intro(), Mission.PRAYERS_SECONDS + 5.0)
	await get_tree().create_timer(1.0).timeout
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
	# v0.11.2: Options is the pause menu's second row; its panel opens over the menu, lifts the duck, and Esc closes the panel only.
	step.call(_pause._menu.items.size() == 5 and String(_pause._menu.items[1].action) == "options", "the pause menu's second row is Options")
	_pause._open_options()
	step.call(_pause.options_open() and (not Music.is_ducked() or DisplayServer.get_name() == "headless"),
		"Options opens over the pause menu and lifts the music's duck")
	Input.parse_input_event(_flow_key(KEY_ESCAPE))
	await get_tree().process_frame
	await get_tree().process_frame
	step.call(is_instance_valid(_pause) and not _pause.options_open() and _mission.rules().time_left == paused_at,
		"Esc closes the panel and does not resume")
	step.call(Music.is_ducked() or DisplayServer.get_name() == "headless", "and the pause duck is back")
	on_action("pause:resume")
	step.call(_mission == first and not is_instance_valid(_pause), "Resume gives back the same mission")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < paused_at, "and its clock runs on (%.2f)" % _mission.rules().time_left)

	# The legend of marks (v0.11.1, spec §4): H opens it and the night waits; R does nothing under it; Esc closes it and does not
	# open the pause menu. Real key events, so the panel's own handling (and the mission's) is the path under test.
	var legend_rules := _mission.rules()
	Input.parse_input_event(_flow_key(KEY_H))
	await get_tree().process_frame
	await get_tree().process_frame
	var legend_at := _mission.rules().time_left
	step.call(_mission.legend_open() and _mission.process_mode == Node.PROCESS_MODE_DISABLED, "H opens the legend and the night waits")
	Input.parse_input_event(_flow_key(KEY_R))
	await get_tree().create_timer(1.0).timeout
	step.call(_mission.rules() == legend_rules and _mission.rules().time_left == legend_at,
		"R does nothing under the legend, and its clock waits (%.2f -> %.2f)" % [legend_at, _mission.rules().time_left])
	Input.parse_input_event(_flow_key(KEY_ESCAPE))
	await get_tree().process_frame
	await get_tree().process_frame
	step.call(not _mission.legend_open() and not is_instance_valid(_pause) and _mission.process_mode == Node.PROCESS_MODE_INHERIT,
		"Esc closes the legend and opens no pause menu")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < legend_at, "and the night runs on (%.2f)" % _mission.rules().time_left)

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

	# The board's Warning (v0.11 M1): three stars; all three stopped holds the night, and ascending ends it, won. Its default
	# loadout is manifested; the result is unscored (spec §7.3: the omen fading no longer wins), and Missions goes back to the board.
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
	await _past_intro()
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	_mission.ascend()
	var faded := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	step.call(faded and _screen_node is ResultsScreen and String(result.get("reason", "")) == "warning"
		and bool(result.get("won", false)) and not result.has("score") and result.has("descend"),
		"stopping the three warnings and ascending wins the board's Warning (%s)" % result.get("reason", "?"))
	on_action("results:missions")
	await get_tree().process_frame
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not is_instance_valid(_mission),
		"Missions from the results returns to the board")

	# A restart during the ending's slow motion (v0.09): the old ending lets go without reporting, so the mission now
	# running is not cut short by the one before it, and time runs at normal speed again.
	(_screen_node as MissionBoard).choose(MissionBook.WARNING)
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	await _past_intro()
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
	await _flow_tour(step)

	print("FLOW result checks=%d failures=%d %s" % [count[0], fails.size(), ", ".join(fails)])


## A mission is up and started, no fade running, and it is not `other`: a Restart has built the fresh one.
func _mission_up(other: Mission) -> bool:
	var up := screen == Screen.MISSION and is_instance_valid(_mission) and _mission != other
	return up and _mission.started() and not _fading


## v0.11 M1 (spec §3.1-§3.2), a test mode since god P1 (spec §3, ruling C3): on a fresh save the tier board opens on Whisper, its five
## cards (a fresh save opens on its last mission's tier, Ascendance), and every tier is open -- Omen, Wrath, Reckoning and Ascendance each show their five cards with no rule line, no padlock and
## no Upgrades button, under the test header. Ends on the board, Whisper open.
func _flow_board(step: Callable) -> void:
	var board := _screen_node as MissionBoard
	# A fresh save's last mission is Last Judgement (Ascendance): with every tier open the board opens on its tab, not on Whisper's.
	step.call(board != null and board.tier == TierBook.tier_of(mission_id) and board.lock_line() == ""
		and board.header_text() == MissionBoard.TEST_HEADER and save.descend.open_tier == 1,
		"a fresh board opens on the last mission's tier (%s, tab %d) under the test header, no rule line" % [mission_id, board.tier if board != null else 0])
	board.open_tab(1)
	step.call(board.tier == 1 and Array(board.missions()) == Array(TierBook.missions(1)) and board.missions().size() == 5,
		"Whisper holds The Warning and the four new missions")
	var open_ok := true
	for tier in range(2, TierBook.NAMES.size() + 1):
		board.open_tab(tier)
		open_ok = open_ok and board.tier == tier and Array(board.missions()) == Array(TierBook.missions(tier)) \
			and board.missions().size() == 5 and board.lock_line() == ""
	step.call(open_ok and board.hit(MissionBoard.UPGRADES_RECT.get_center()) != "upgrades",
		"every tab is open on a fresh save: Omen, Wrath, Reckoning and Ascendance show five cards and no rule; no Upgrades button")
	board._unhandled_input(_flow_key(KEY_U))
	step.call(screen == Screen.BOARD and _screen_node == board and board.chosen == "", "U does nothing on the board")
	board.open_tab(1)


## v0.11 M1 (spec §4, §5.1, §6): The Warning from the board's card.
## - Prepare has no difficulty picker, Tier 1's 3 slots and 6 Might, no locked power (god P1: every power is open) and the level
##   picker: a click on the first slot's badge makes it L2, and MANIFEST hands the level to the night.
## - The town prays during the intro.
## - F before the main objective does nothing (review focus 4).
## - Its three warnings stopped: THE NIGHT IS YOURS, the ASCEND plate up, the clock running on.
## - F ascends to the results. Ends on the results.
func _flow_ascend(step: Callable) -> void:
	(_screen_node as MissionBoard).choose(MissionBook.WARNING)
	var prep := _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 3 and prep.draft.capacity == 6 and not prep.mission.chooses_difficulty()
		and prep.draft.locked.is_empty() and prep.level_picker,
		"its Prepare: Tier 1's 3 slots and 6 Might, no difficulty, no power locked, the level picker up")
	prep.draft.preselect(MissionBook.warning().default_loadout)
	# The level picker (god P1, ruling P13): a click on the first badge makes that power L2, and the budget counts it.
	var first := prep.draft.picks[0]
	var spent := prep.draft.spent()
	prep.click(PrepareScreen.level_rect(0, prep.draft.slots).get_center())
	step.call(prep.hit(PrepareScreen.level_rect(0, prep.draft.slots).get_center()) == "level:0" and prep.draft.level_of(first) == 2
		and prep.draft.levels == {first: 2} and prep.draft.spent() == spent + PowerBook.might(first, 2) - PowerBook.might(first, 1)
		and prep.budget_text() == "%d / 3 slots   %d / 6 Might" % [prep.draft.picks.size(), prep.draft.spent()],
		"a click on the first badge makes %s L2 and the budget counts it (%s)" % [first, prep.budget_text()])
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await get_tree().process_frame
	step.call(levels == {first: 2} and _mission.levels == {first: 2} and _mission.rules().level_of(0) == 2 and _mission.rules().level_of(1) == 1,
		"MANIFEST hands the level to the night: Game's levels, the mission's, slot 1's rules (L%d)" % _mission.rules().level_of(0))
	var heard := _mission.descent().wishes.size() if _mission.descent() != null else 0
	# v0.11.1: the prayers plate is the intro's last hold (one message at a time), not its first frame: the tour, then the town prays.
	step.call(heard > 0 and heard <= TierBook.wishes(1) and not _mission._hud.praying and _mission._hud.intro,
		"the intro opens on its tour, not the prayers: %d wishes heard" % heard)
	var prays := await _until(func() -> bool: return _mission._hud.praying, 40.0)
	step.call(prays and _mission.in_intro() and _mission._hud.caption() == "" and _mission._hud.stack_rect() == Rect2(),
		"the town prays last in the intro, alone: no caption, no stack")
	await _past_intro()
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	await get_tree().process_frame
	await get_tree().process_frame
	step.call(not _mission.rules().finished and not _mission.rules().main_done and not _mission._hud.praying,
		"F before the main objective does nothing")
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var clock0 := _mission.rules().time_left
	step.call(_mission._hud.banners().has(Rules.MAIN_BANNER) and _mission._hud.ascend_shown() and not _mission.rules().finished,
		"the warnings stopped: THE NIGHT IS YOURS, the ASCEND plate up")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < clock0 and not _mission.rules().finished,
		"and the clock runs on (%.2f)" % _mission.rules().time_left)
	Input.parse_input_event(f)
	var up := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var d: Dictionary = result.get("descend", {})
	step.call(up and bool(d.get("ascended", false)) and bool(d.get("main", false)) and bool(result.get("won", false)),
		"F ascends: the results, won")


## v0.11 M1 (spec §3.3-§3.4, §6; review focus 3), a test mode since god P1 (spec §3, rulings P11, P13, pre-flight G1).
## - The ascended Warning's results are a test bank: Night 1, no believers, The Warning cleared, no tier opened, no Upgrades button; the
##   save holds the tick and the night.
## - Change powers shows Prepare on the levels chosen (the badge still reads L2); Back is the board, and a new pick starts at level 1
##   with The Warning's Prepare at TierBook.dp(1).
## - A restart banks nothing, hears the same wishes and keeps the levels.
## - A night caught by dawn after its main objective keeps the main win, its granted wish lost, and banks no believers.
## Ends on the board.
func _flow_results(step: Callable) -> void:
	var res := _screen_node as ResultsScreen
	var d: Dictionary = result.get("descend", {})
	var bank: Dictionary = d.get("bank", {})
	var earned := int(d.get("earned", 0))
	var menu: Array = []
	if res != null:
		for item: Dictionary in res._menu.items:
			menu.append(String(item.action))
	step.call(res != null and res.descend and bool(bank.get("test", false)) and save.descend.night == 1 and earned >= 10
		and save.descend.believers == 0 and save.descend.cleared.has(MissionBook.WARNING) and save.descend.open_tier == 1
		and int(bank.get("night", 0)) == 1 and not bank.has("believers") and menu == ["missions", "replay", "change"]
		and ResultsScreen.summary_lines(result)[0] == "Test mode: nothing banked",
		"the results are a test bank: Night 1, no believers (the %d earned are not banked), The Warning cleared, no tier opened, Board/Again/Change powers" % earned)
	var reread := SaveFile.new().load_from(save_path)
	step.call(reread.descend.night == 1 and reread.descend.believers == 0 and reread.descend.open_tier == 1
		and reread.descend.cleared.has(MissionBook.WARNING), "and the save holds the tick and the night, no believers")
	# Change powers (pre-flight G1): Prepare comes back on the levels chosen -- the badge still reads L2.
	var first := loadout[0]
	res.action.emit("change")
	var again := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and again != null and again.level_picker and again.draft.level_of(first) == 2
		and again.hit(PrepareScreen.level_rect(0, again.draft.slots).get_center()) == "level:0",
		"Change powers shows Prepare on the levels chosen: %s still L%d" % [first, again.draft.level_of(first) if again != null else 0])
	again.action.emit("back")
	var board := _screen_node as MissionBoard
	step.call(screen == Screen.BOARD and board != null and board.tier == 1, "Back is the tier board")
	board.choose(MissionBook.WARNING)
	var prep := _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.capacity == TierBook.dp(1) and prep.draft.levels.is_empty() and levels.is_empty(),
		"a new pick: The Warning's Prepare has %d Might (no upgrades) and every power at level 1" % (prep.draft.capacity if prep != null else 0))
	# (drafted in a different order from the default, so the R restart below can tell the draft from it)
	var reversed := PackedStringArray()
	for key in MissionBook.warning().default_loadout:
		reversed.insert(0, key)
	prep.draft.preselect(reversed)
	prep.click(PrepareScreen.level_rect(0, prep.draft.slots).get_center())  # slot 1 to L2, kept by the restarts below
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var heard := _wish_ids()
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	await _past_intro()
	step.call(save.descend.night == 1 and _wish_ids() == heard and _mission.rules().level_of(0) == 2,
		"a restart banks nothing, hears the same wishes (%s) and keeps the level" % ", ".join(heard))
	var r := InputEventKey.new()
	r.physical_keycode = KEY_R
	r.pressed = true
	var drafted := _mission.rules().loadout.duplicate()
	_mission._unhandled_input(r)
	await _past_intro()
	step.call(loadout != MissionBook.warning().default_loadout and Array(drafted) == Array(loadout)
		and Array(_mission.rules().loadout) == Array(loadout) and _wish_ids() == heard and save.descend.night == 1
		and _mission.rules().level_of(0) == 2,
		"R restarts the night with the drafted loadout (%s), its level and the same wishes, not the default" % ", ".join(_mission.rules().loadout))
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	var wishes := _mission.descent().wishes
	if not wishes.is_empty():
		wishes[0].status = Objective.Status.DONE
	var total := save.descend.believers
	_mission.rules().time_left = 0.01
	var over := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var caught: Dictionary = result.get("descend", {})
	var rows: Array = caught.get("wishes", [])
	step.call(String(caught.get("caught", "")) == "dawn" and bool(result.get("won", false)) and int(caught.get("earned", 0)) == 10
		and save.descend.believers == total and save.descend.night == 2 and bool((caught.get("bank", {}) as Dictionary).get("test", false))
		and (rows.is_empty() or bool((rows[0] as Dictionary).get("lost", false))),
		"caught by dawn after the main objective: Night 2, the 10 believers not banked, the granted wish lost")
	if over and _screen_node is ResultsScreen:  # (v0.11 M3 final review: no results, no cast on a freed or other screen)
		(_screen_node as ResultsScreen).action.emit("missions")
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard, "Board from the results returns to the tier board")


## v0.11 M2: a new Tier 1 mission from the board -- The Tax Collector. Its Prepare has Tier 1's Might; its
## night is the board's version with its director up (three collectors, each with his guards), and no wish's person is a
## collector or a guard (the wishes are reserved first); Pause > Missions abandons it without counting the night. Ends on the
## board.
func _flow_tier1(step: Callable) -> void:
	var nights := save.descend.night
	(_screen_node as MissionBoard).choose(MissionBook.TAX_COLLECTOR)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.tax_collector().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as TaxCollectorDirector
	var clash := false
	var targets := 0
	var guards := 0
	if d != null and _mission.descent() != null:
		for q in d.quarries:
			targets += int(q.target != null)
			guards += q.guards.size()
		for w in _mission.descent().wishes:
			for p in w.people():
				for q in d.quarries:
					clash = clash or p == q.target or q.guards.has(p)
	var up := d != null and targets == TaxCollectorDirector.ROUNDS.size() and guards > 0 and not clash \
		and dp == TierBook.dp(1) and _mission.rules().mission.tier == 1
	_open_pause()
	on_action("pause:missions")
	await _until(func() -> bool: return screen == Screen.BOARD, 5.0)
	step.call(up and screen == Screen.BOARD and save.descend.night == nights,
		"The Tax Collector from the board: its three collectors up with guards, no wish's person a collector or a guard; abandoned, uncounted")


## v0.11 M3: a Tier 2 mission from the board -- The Bell-Ringers (Omen is open: the board is a test mode). Its Prepare has Tier 2's
## Might; its night is the board's version, three posts each with its ringer; its three warnings stopped, F ascends to the results: won,
## The Bell-Ringers cleared, a test bank (its fastest clear shown, nothing banked, Omen still the only tier open). Ends on the board.
func _flow_tier2(step: Callable) -> void:
	(_screen_node as MissionBoard).choose(MissionBook.BELL_RINGERS)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.bell_ringers().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as BellRingersDirector
	var up := d != null and d.ringers.size() == 3 and dp == TierBook.dp(2) and _mission.rules().mission.tier == 2
	if d != null:
		for r in d.ringers:
			r.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	var shown := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var desc: Dictionary = result.get("descend", {})
	var bank: Dictionary = desc.get("bank", {})
	step.call(up and shown and bool(result.get("won", false)) and bool(desc.get("ascended", false))
		and save.descend.cleared.has(MissionBook.BELL_RINGERS) and _test_bank(bank),
		"The Bell-Ringers from the board: Tier 2's budget, three posts; stopped and ascended, a test bank: %s" % _bests_text(bank))
	if shown and _screen_node is ResultsScreen:  # (v0.11 M3 final review: no results, no cast on a freed or other screen)
		(_screen_node as ResultsScreen).action.emit("missions")
		await _until(func() -> bool: return screen == Screen.BOARD, 5.0)


## v0.11 M4: a Tier 3 mission from the board -- The Heretic Hunt (Wrath is open: the board is a test mode). Its Prepare has Tier 3's
## Might; its night is the board's version, three sweeps, a captain and a cellar; broken by its public state (every standard broken,
## the captain fallen), F ascends to the results: won, The Heretic Hunt cleared, a test bank. Ends on the board.
func _flow_tier3(step: Callable) -> void:
	(_screen_node as MissionBoard).choose(MissionBook.HERETIC_HUNT)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.heretic_hunt().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as HereticHuntDirector
	var up := d != null and d.steps.size() == 3 and d.cellar != null and dp == TierBook.dp(3) and _mission.rules().mission.tier == 3
	if d != null:
		for st in d.steps:
			st.raised = true
			st.broken = true
		d.head_fell = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	var shown := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var desc: Dictionary = result.get("descend", {})
	var bank: Dictionary = desc.get("bank", {})
	step.call(up and shown and bool(result.get("won", false)) and bool(desc.get("ascended", false))
		and save.descend.cleared.has(MissionBook.HERETIC_HUNT) and _test_bank(bank),
		"The Heretic Hunt from the board: Tier 3's budget, three sweeps and a cellar; broken and ascended, a test bank: %s" % _bests_text(bank))
	if shown and _screen_node is ResultsScreen:
		(_screen_node as ResultsScreen).action.emit("missions")
		await _until(func() -> bool: return screen == Screen.BOARD, 5.0)


## v0.11 M5: a Tier 4 mission from the board -- The Armoury (Reckoning is open: the board is a test mode). Its Prepare has Tier 4's
## Might; its night is the board's version, three targets; razed by its public state (each target razed, ArmouryDirector._raze()), F
## ascends to the results: won, The Armoury cleared, a test bank. Ends on the board.
func _flow_tier4(step: Callable) -> void:
	(_screen_node as MissionBoard).choose(MissionBook.ARMOURY)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.armoury().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as ArmouryDirector
	var up := d != null and d.targets.size() == 3 and dp == TierBook.dp(4) and _mission.rules().mission.tier == 4
	if d != null:
		for s in d.targets:
			d._raze(s)
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	var shown := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var desc: Dictionary = result.get("descend", {})
	var bank: Dictionary = desc.get("bank", {})
	step.call(up and shown and bool(result.get("won", false)) and bool(desc.get("ascended", false))
		and save.descend.cleared.has(MissionBook.ARMOURY) and _test_bank(bank),
		"The Armoury from the board: Tier 4's budget, three targets; razed and ascended, a test bank: %s" % _bests_text(bank))
	if shown and _screen_node is ResultsScreen:
		(_screen_node as ResultsScreen).action.emit("missions")
		await _until(func() -> bool: return screen == Screen.BOARD, 5.0)


## v0.11 M6: a Tier 5 mission from the board -- The Lantern's Eye (Ascendance is open: the board is a test mode). Its Prepare has Tier
## 5's Might; its night is the board's version, three mirror towers; each mirror given up by its public state (LanternEyeDirector._raise(),
## then _gone()), F ascends to the results: won, The Lantern's Eye cleared, a test bank. Ends on the board.
func _flow_tier5(step: Callable) -> void:
	(_screen_node as MissionBoard).choose(MissionBook.LANTERN_EYE)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.lantern_eye().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as LanternEyeDirector
	var up := d != null and d.towers.size() == 3 and dp == TierBook.dp(5) and _mission.rules().mission.tier == 5
	if d != null:
		for i in d.steps.size():
			d._raise(i)
			d._gone(i)
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	var shown := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var desc: Dictionary = result.get("descend", {})
	var bank: Dictionary = desc.get("bank", {})
	step.call(up and shown and bool(result.get("won", false)) and bool(desc.get("ascended", false))
		and save.descend.cleared.has(MissionBook.LANTERN_EYE) and _test_bank(bank),
		"The Lantern's Eye from the board: Tier 5's budget, three towers; its mirrors gone and ascended, a test bank: %s" % _bests_text(bank))
	if shown and _screen_node is ResultsScreen:
		(_screen_node as ResultsScreen).action.emit("missions")
		await _until(func() -> bool: return screen == Screen.BOARD, 5.0)


## v0.12 (spec 1.7, D22): with `dev` set, the board's DEV tab picks the Capital Sandbox and the night starts in the Capital; Missions
## goes back to the board and a Tier 1 board pick starts in Aldermere, exactly as it was built (no Capital left behind in the active
## city). A town night banks nothing. `dev` is restored and the board rebuilt without the tab. Ends on the board.
func _flow_dev_town(step: Callable) -> void:
	var was := dev
	var nights := save.descend.night
	var believers := save.descend.believers
	var cleared := save.descend.cleared.size()
	dev = true
	go_to(Screen.BOARD)
	var board := _screen_node as MissionBoard
	board.open_tab(MissionBoard.DEV_TIER)
	board.choose(MissionBook.CAPITAL_SANDBOX)
	var prep := _screen_node as PrepareScreen
	var picked := prep != null and mission_id == MissionBook.CAPITAL_SANDBOX
	if prep != null:
		prep.draft.preselect(MissionBook.capital_sandbox().default_loadout)
		_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	step.call(picked and screen == Screen.MISSION and City.current().id() == &"capital",
		"--dev: the board's DEV tab picks the Capital Sandbox and the night starts in the Capital (%s)" % City.current().id())
	_open_pause()
	on_action("pause:missions")
	await _until(func() -> bool: return screen == Screen.BOARD, 5.0)
	# v0.12 M2: the DEV tab lists the sandbox and the five Capital Tier 1 nights; a Tax Collector night there starts in the Capital
	# with the weigh-house as the counting-house, and Missions goes back to the DEV tab.
	var dev_board := _screen_node as MissionBoard
	var capital_ids := [MissionBook.CAPITAL_SANDBOX, "warning@capital", "tax_collector@capital", "spoiled_harvest@capital",
		"lost_lamb@capital", "first_prayers@capital"]
	step.call(dev_board != null and dev_board.tier == MissionBoard.DEV_TIER
		and Array(dev_board.missions()).slice(0, capital_ids.size()) == capital_ids,
		"the DEV tab lists the sandbox and the five Capital Tier 1 nights in tier order (%s)" % [dev_board.missions() if dev_board != null else []])
	dev_board.choose("tax_collector@capital")
	prep = _screen_node as PrepareScreen
	if prep != null:
		prep.draft.preselect(MissionBook.tax_collector().default_loadout)
		_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	var counting_tag := &""
	if is_instance_valid(_mission) and _mission.rules() != null and _mission.rules().director is TaxCollectorDirector:
		counting_tag = (_mission.rules().director as TaxCollectorDirector).counting_tag
	step.call(screen == Screen.MISSION and mission_id == "tax_collector@capital" and City.current().id() == &"capital"
		and counting_tag == &"gpt_weighhouse",
		"picking tax_collector@capital starts it in the Capital with the weigh-house as the counting-house (%s, %s)" % [City.current().id(), counting_tag])
	_open_pause()
	on_action("pause:missions")
	await _until(func() -> bool: return screen == Screen.BOARD, 5.0)
	step.call(_screen_node is MissionBoard and (_screen_node as MissionBoard).tier == MissionBoard.DEV_TIER,
		"Missions after it returns to the DEV tab")
	(_screen_node as MissionBoard).choose(MissionBook.TAX_COLLECTOR)
	prep = _screen_node as PrepareScreen
	if prep != null:
		prep.draft.preselect(MissionBook.tax_collector().default_loadout)
		_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	step.call(screen == Screen.MISSION and City.current().id() == &"aldermere"
		and City.current().structures() == AldermereCity.new().structures() and _mission.rules().mission.city == &"aldermere",
		"and a Tier 1 board pick after it starts in Aldermere, built as ever (%s)" % City.current().id())
	_open_pause()
	on_action("pause:missions")
	await _until(func() -> bool: return screen == Screen.BOARD, 5.0)
	step.call(save.descend.night == nights and save.descend.believers == believers and save.descend.cleared.size() == cleared,
		"neither night, abandoned, counted for anything")
	dev = was
	go_to(Screen.BOARD)
	step.call(screen == Screen.BOARD and not (_screen_node as MissionBoard).dev, "the board is rebuilt without the DEV tab")


## A left click at a screen point as the mouse would send it to a control's gui_input (FLOW, god P1).
func _flow_mouse(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = at
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e


## Endless Night through the real screens (god P1, spec §9.1, §14 P1's "playable at its end"; rulings C2, C7, C9, P9, pre-flight B3, R1, R2).
## 1. With --dev the board's ENDLESS opens the slot select: three empty slots. New -> the god select -> Ruin -> the hub (Night 1, the dev
##    fill's two starting abilities at level 1, the slot file written). The Skill Tree refuses a point the god has not got.
## 2. Descend (a fixture seed that draws The Warning): Prepare is the god's (one ruin tab, 3 slots, 6 Might, nothing locked); the night is
##    played with the god's pool, `in_night` is written once the clock starts, and R does not restart it.
## 3. The warnings stopped, F ascends: banked to the god (Divine Power, a level, a point, Faith 1:1, Night 1), the file agrees, and the results offer
##    Continue / Skill Tree / Faith. The tree raises Smite; Faith buys +1 Might (7).
## 4. No escape by quitting (spec §9.1): Abandon after the clock is a lost night (Night 2, the lost-night line, nothing earned); Abandon during
##    the intro is free; closing the game mid-night (the board with no forfeit) is forfeited on Continue (Night 3).
## 5. The title is unchanged, and the board's save -- its descend, its campaign, its bytes -- is what it was (C7). Ends on the board with `dev` restored.
func _flow_endless(step: Callable) -> void:
	var was := dev
	var camp := save.campaign
	var camp_night := camp.night if camp != null else -1
	var nights := save.descend.night
	var believers := save.descend.believers
	var cleared := save.descend.cleared.duplicate()
	var disk := FileAccess.get_file_as_bytes(save_path)
	var out := func() -> void:
		dev = was
		GodTree.dev_fill = false
		go_to(Screen.BOARD)
	var god_file := func() -> GodSlot: return GodSlot.read(GodSlot.path(god_slot, god_base))
	var pair := PackedStringArray(["smite", "ember"])
	dev = true
	go_to(Screen.BOARD)
	var board := _screen_node as MissionBoard
	board.click(MissionBoard.ENDLESS_RECT.get_center())
	var slots := _screen_node as SlotScreen
	step.call(screen == Screen.SLOTS and slots != null and GodTree.dev_fill and slots.slot_line(0) == "Empty"
		and slots.slot_line(1) == "Empty" and slots.slot_line(2) == "Empty",
		"--dev: the board's ENDLESS opens the slot select, three slots Empty (%s)" % [slots.slot_line(0) if slots != null else "-"])
	if slots == null:
		out.call()
		return

	# The god.
	slots.click(slots.button_rect(0, "new").get_center())
	var pick := _screen_node as GodSelectScreen
	step.call(screen == Screen.GOD_SELECT and pick != null and god_slot == 1, "New on slot 1 opens the god select")
	if pick == null:
		out.call()
		return
	pick.click(GodSelectScreen.ring_rect(0).get_center())
	pick.click(GodSelectScreen.CHOOSE_RECT.get_center())
	var hub := _screen_node as GodHub
	var saved: GodSlot = god_file.call()
	step.call(screen == Screen.HUB and hub != null and god != null and god.type == "ruin" and saved != null and saved.type == "ruin"
		and god.level == 1 and god.tier == 1 and god.learned == {"smite": 1, "ember": 1} and hub.lines()[6] == "Night 1"
		and FileAccess.file_exists(GodSlot.path(1, god_base)),
		"choosing Ruin makes the god (level 1, tier 1, Smite and Ember at 1), writes slot 1 and opens the hub at Night 1 (%s)" % [god.learned if god != null else {}])
	if hub == null or god == null:
		out.call()
		return

	# The Skill Tree refuses a point the god has not got.
	hub.click(hub.menu_rect("tree").get_center())
	var tree := _screen_node as SkillTreeScreen
	if tree == null:
		step.call(false, "the hub's Skill Tree opens the tree")
		out.call()
		return
	var why := tree.learn_at(1, 1, 0)
	step.call(screen == Screen.TREE and tree.columns()[1] == "ruin" and tree.key_at(1, 1, 0) == "smite" and why == "points"
		and god.level_of("smite") == 1 and god.points == 0,
		"the Skill Tree refuses a point the god has not got (%s, %d points)" % [why, god.points])
	tree.click(SkillTreeScreen.BACK_RECT.get_center())
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null, "Back from the tree is the hub")
	if hub == null:
		out.call()
		return

	# Night 1: The Warning, by a fixture seed.
	var s := 1
	while s < 1000:
		god.seed = s
		if GodNight.draw(god) == MissionBook.WARNING:
			break
		s += 1
	_write_god()
	hub.click(hub.menu_rect("descend").get_center())
	var prep := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and mission_id == MissionBook.WARNING and prep.god == god
		and prep.tabs() == PackedStringArray(["ruin"]) and prep.draft.slots == 3 and prep.draft.capacity == 6 and prep.draft.locked.is_empty(),
		"Descend draws The Warning (seed %d) and opens the god's Prepare: one Ruin tab, 3 slots, 6 Might, nothing locked" % s)
	if prep == null:
		out.call()
		return
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	if not is_instance_valid(_mission) or _mission.rules() == null:
		step.call(false, "MANIFEST starts the night")
		out.call()
		return
	var pool := _mission.rules().mission.pool
	var kit := _mission.rules().loadout
	var inside := not kit.is_empty()
	for key in kit:
		inside = inside and god.draftable().has(key)
	step.call(screen == Screen.MISSION and pool == god.draftable() and inside and god.in_night == "",
		"MANIFEST starts the night on the god's pool, its kit (%s) inside it, the clock not started so nothing in the file yet" % ", ".join(kit))
	await _past_intro()
	await _until(func() -> bool: return god.in_night != "", 3.0)
	var rules_before := _mission.rules()
	_mission._unhandled_input(_flow_key(KEY_R))
	await get_tree().process_frame
	saved = god_file.call()
	step.call(god.in_night == MissionBook.WARNING and saved != null and saved.in_night == MissionBook.WARNING and _mission.rules() == rules_before,
		"past the intro the clock has started and the file says so; R leaves the same night (restart locked)")

	# The night won and banked.
	for w: WarningDirector in (_mission.rules().director as StarfallDirector).stars:
		w.warning_dead = true
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var f := _flow_key(KEY_F)
	Input.parse_input_event(f)
	var up := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var d: Dictionary = result.get("descend", {})
	var banked: Dictionary = result.get("god", {})
	var kept := int(d.get("kept", 0))
	saved = god_file.call()
	var res := _screen_node as ResultsScreen
	var menu: Array = []
	if res != null:
		for item: Dictionary in res._menu.items:
			menu.append(String(item.action))
	step.call(up and res != null and res.endless and int(banked.get("divine_power", -1)) == 80 + 20 * kept and god.level >= 2 and god.points >= 1
		and god.faith == int(d.get("earned", -1)) and god.night == 1 and god.in_night == "" and saved != null and saved.night == 1
		and saved.level == god.level and saved.points == god.points and saved.faith == god.faith and saved.divine_power == god.divine_power
		and saved.in_night == "" and saved.last_mission == MissionBook.WARNING and menu == ["continue", "tree", "faith"],
		"F ascends: banked to the god -- %d Divine Power (80 + 20 x %d wishes), level %d, %d points, Faith %d = the %s believers, Night 1 -- the file agrees; Continue / Skill Tree / Faith"
		% [int(banked.get("divine_power", -1)), kept, god.level, god.points, god.faith, d.get("earned", "?")])
	if not up or res == null:
		out.call()
		return

	# The tree and Faith, from the results.
	res.action.emit("tree")
	tree = _screen_node as SkillTreeScreen
	if tree == null:
		step.call(false, "the results' Skill Tree opens the tree")
		out.call()
		return
	var points := god.points
	why = tree.learn_at(1, 1, 0)
	saved = god_file.call()
	step.call(screen == Screen.TREE and why == "" and god.level_of("smite") == 2 and god.points == points - 1 and saved != null
		and saved.level_of("smite") == 2 and saved.points == points - 1,
		"Skill Tree from the results: Smite to level 2 costs a point (%d -> %d), written at once" % [points, god.points])
	tree.click(SkillTreeScreen.BACK_RECT.get_center())
	hub = _screen_node as GodHub
	if hub == null:
		step.call(false, "Back from the tree is the hub")
		out.call()
		return
	hub.click(hub.menu_rect("faith").get_center())
	var faith := _screen_node as FaithScreen
	if faith == null:
		step.call(false, "the hub's Faith opens the Faith screen")
		out.call()
		return
	god.faith += 25  # a fixture: enough for the first +1 Might whatever the night earned
	var bought := faith.buy("might")
	saved = god_file.call()
	step.call(screen == Screen.FAITH and bought and god.max_might() == 7 and saved != null and saved.max_might() == 7 and saved.faith == god.faith,
		"Faith: +1 Might is bought (Might %d), the file agrees" % god.max_might())
	faith.click(FaithScreen.BACK_RECT.get_center())
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null, "Back from Faith is the hub")
	if hub == null:
		out.call()
		return

	# The second night, abandoned after the clock has started -- a lost night.
	var level := god.level
	var dp := god.divine_power
	var faith_held := god.faith
	hub.click(hub.menu_rect("descend").get_center())
	prep = _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and mission_id != MissionBook.WARNING and prep.draft.capacity == 7,
		"Descend draws another night than The Warning (%s) and Prepare has 7 Might" % mission_id)
	if prep == null:
		out.call()
		return
	var second := mission_id
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	await _until(func() -> bool: return god.in_night != "", 3.0)
	_open_pause()
	var rows: Array = []
	if is_instance_valid(_pause):
		for item: Dictionary in _pause._menu.items:
			rows.append(String(item.action))
	var ask := ""
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
		ask = _pause.confirm_line()
	step.call(god.in_night == second and rows == ["resume", "options", "abandon"] and ask == PauseMenu.lost_line(god.notice),
		"Pause in a night: Resume, Options, Abandon night (no Restart, no Change powers); after the clock its confirm says the night is lost")
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
	await _until(func() -> bool: return screen == Screen.HUB, 5.0)
	hub = _screen_node as GodHub
	saved = god_file.call()
	step.call(screen == Screen.HUB and hub != null and god.night == 2 and god.level == level and god.divine_power == dp and god.faith == faith_held
		and god.in_night == "" and saved != null and saved.night == 2 and saved.in_night == "" and hub.line == "Night 2 was abandoned: a lost night. Lantern Notice +25%.",
		"Abandon after the clock: Night 2 is a lost night -- counted, no Divine Power, no Faith -- and the hub says so")
	if hub == null:
		out.call()
		return

	# The next night, abandoned during its intro -- free.
	hub.click(hub.menu_rect("descend").get_center())
	prep = _screen_node as PrepareScreen
	if prep == null:
		step.call(false, "Descend opens Prepare again")
		out.call()
		return
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	var intro := is_instance_valid(_mission) and _mission.in_intro()
	_open_pause()
	ask = ""
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
		ask = _pause.confirm_line()
	step.call(intro and god.in_night == "" and ask == PauseMenu.CONFIRM_FREE,
		"Pause during the intro: the clock has not started, so the confirm says leaving is free")
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
	await _until(func() -> bool: return screen == Screen.HUB, 5.0)
	hub = _screen_node as GodHub
	saved = god_file.call()
	step.call(screen == Screen.HUB and hub != null and god.night == 2 and hub.line == "" and saved != null and saved.night == 2
		and saved.in_night == "" and god.level == level and god.faith == faith_held,
		"Abandon during the intro costs nothing: still Night 2, no line")
	if hub == null:
		out.call()
		return

	# The same night again, the game closed once its clock has run.
	hub.click(hub.menu_rect("descend").get_center())
	prep = _screen_node as PrepareScreen
	if prep == null:
		step.call(false, "Descend opens Prepare once more")
		out.call()
		return
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	await _until(func() -> bool: return god.in_night != "", 3.0)
	saved = god_file.call()
	var open_night := god.in_night
	step.call(open_night != "" and saved != null and saved.in_night == open_night, "past the intro the file says the night is open (%s)" % open_night)
	go_to(Screen.BOARD)  # as a quit would leave it: nothing forfeits on the way out
	board = _screen_node as MissionBoard
	board.click(MissionBoard.ENDLESS_RECT.get_center())
	slots = _screen_node as SlotScreen
	if slots == null:
		step.call(false, "the board's ENDLESS opens the slot select again")
		out.call()
		return
	step.call(slots.slot_line(0) != "Empty", "the slot still holds the god (%s)" % slots.slot_line(0))
	slots.click(slots.button_rect(0, "continue").get_center())
	hub = _screen_node as GodHub
	saved = god_file.call()
	step.call(screen == Screen.HUB and hub != null and god != null and god.night == 3 and god.in_night == "" and god.level == level
		and god.faith == faith_held and hub.line == "Night 3 was abandoned: a lost night. Lantern Notice +25%." and saved != null and saved.night == 3
		and saved.in_night == "",
		"Continue on a slot left mid-night forfeits it: Night 3 is a lost night, nothing earned, the hub says so")
	if hub == null:
		out.call()
		return

	# The title is unchanged and the board's save is what it was (C7).
	hub.click(hub.menu_rect("title").get_center())
	var title := _screen_node as TitleScreen
	var rows_title: Array = []
	if title != null:
		for item: Dictionary in title._menu.items:
			rows_title.append(String(item.action))
	step.call(screen == Screen.TITLE and title != null and rows_title == ["campaign", "play", "options", "sandbox", "quit"] and god == null,
		"the hub's Title is the title, its rows unchanged (%s)" % ", ".join(PackedStringArray(rows_title)))
	var camp_same := save.campaign == camp and (camp == null or save.campaign.night == camp_night)
	step.call(save.descend.night == nights and save.descend.believers == believers and save.descend.cleared == cleared and camp_same
		and FileAccess.get_file_as_bytes(save_path) == disk,
		"Endless Night left the board's save alone: night %d, believers %d, %d cleared, the campaign, and the file's bytes" % [
			save.descend.night, save.descend.believers, save.descend.cleared.size()])
	out.call()
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not (_screen_node as MissionBoard).dev and not GodTree.dev_fill,
		"the board is rebuilt without the DEV tab, the dev fill off")


## The Lantern through the real screens (god P2, spec §10, §14 P2; rulings P2-14, C6, C7, pre-flight B3, R1, R3, G3). Starts where
## `_flow_endless()` stopped: slot 1's god after Night 3, Notice 50%.
## 1. The board's ENDLESS (the board is rebuilt with `dev`, as `_flow_endless()` does), Continue on slot 1: the hub, Notice 50%, no Hunt line.
## 2. A fixture: Notice 75%, the first starting key carried 4 nights and the second 1 (so the Lantern's target is clear), a seed whose night
##    is neither the last night nor the Hunt's stand-in -- and whose Hunt night, were there no Hunt, would not be the stand-in either.
## 3. Descend, play into the night, Abandon: a lost night, Notice 100%, the hub says the Hunt is next, the file agrees; dev A is refused.
## 4. Descend: the Hunt (its stand-in at Tier 1, its name, THE LANTERN HUNT, the stake in IF LOST); in the night the pause confirm names
##    the stake, and Stay / Resume return to it.
## 5. The Hunt lost (force_end): results show the Notice change and the seal; the god and its file: the key sealed 3 nights, Notice 50%,
##    out of the loadout. Continue: the hub's seal line. Descend: another night, the sealed card refuses a pick and says why.
## 6. The title, and the board's save is what it was (C7). Ends on the board with `dev` restored.
func _flow_lantern(step: Callable) -> void:
	var was := dev
	var disk := FileAccess.get_file_as_bytes(save_path)
	var out := func() -> void:
		dev = was
		GodTree.dev_fill = false
		go_to(Screen.BOARD)
	var god_file := func() -> GodSlot: return GodSlot.read(GodSlot.path(god_slot, god_base))
	var hunt0: Dictionary = GodNight.HUNTS[0]
	dev = true
	go_to(Screen.BOARD)
	var board := _screen_node as MissionBoard
	board.click(MissionBoard.ENDLESS_RECT.get_center())
	var slots := _screen_node as SlotScreen
	if slots == null or slots.slot_line(0) == "Empty":
		step.call(false, "the Lantern walk finds slot 1 holding the endless walk's god (%s)" % [slots.slot_line(0) if slots != null else "no slot select"])
		out.call()
		return
	slots.click(slots.button_rect(0, "continue").get_center())
	var hub := _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and god != null and god.notice == 50 and hub.lines()[5] == "Lantern Notice 50%" and hub.hunt_line() == ""
		and hub.notice_fill() == 0.5,
		"Continue on slot 1: the hub at Lantern Notice 50%%, no Hunt line (%s)" % [god.notice if god != null else -1])
	if hub == null or god == null:
		out.call()
		return

	# The fixture: Notice 75%, a clear target, a seed that draws neither the last night nor the Hunt's stand-in (R1, R3).
	if god.in_tree().size() < 2:  # a tree whose Tier 1 holds fewer than two keys of this type: learn one more (pre-flight R3)
		for key in GodTree.keys_for(god.type, 2):
			if not god.learned.has(key):
				god.learned[key] = 1
				break
	var keys := god.in_tree()
	if keys.size() < 2:
		step.call(false, "the god has two abilities in the tree for the Lantern walk (%s)" % [keys])
		out.call()
		return
	var pair := PackedStringArray([keys[0], keys[1]])
	god.notice = 75
	god.carried = {pair[0]: 4, pair[1]: 1}
	var target := god.seal_target()
	var night_now := god.night
	var last_now := god.last_mission
	var picked := ""
	var seed_used := 0
	for s in range(1, 1000):
		god.seed = s
		var d := GodNight.draw(god)
		var def := GodNight.def_for(god, d)
		if d == god.last_mission or d == String(hunt0.id) or def == null or def.has_acts():
			continue
		god.night = night_now + 1  # the Hunt's night, were there no Hunt: it must not be the stand-in either
		god.last_mission = d
		god.notice = 0
		var later := GodNight.draw(god)
		god.night = night_now
		god.last_mission = last_now
		god.notice = 75
		if later != String(hunt0.id):
			picked = d
			seed_used = s
			break
	if picked == "":
		step.call(false, "a seed draws a single-act night that is not the Hunt's stand-in, now or on the next night")
		out.call()
		return
	god.seed = seed_used
	_write_god()
	go_to(Screen.HUB)
	hub = _screen_node as GodHub

	# Night 4 abandoned after the clock: a lost night, the Notice to 100%.
	var level := god.level
	hub.click(hub.menu_rect("descend").get_center())
	var prep := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and mission_id == picked and prep.header_text() == "PREPARE THE MANIFESTATION"
		and target == pair[0],
		"Descend at Notice 75%% draws %s (seed %d), an ordinary night; the Lantern's target is %s" % [mission_id, seed_used, target])
	if prep == null:
		out.call()
		return
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	await _until(func() -> bool: return god.in_night != "", 3.0)
	_open_pause()
	var ask := ""
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
		ask = _pause.confirm_line()
	step.call(god.in_night == picked and ask == PauseMenu.lost_line(75) and ask.contains("Lantern Notice +25%") and ask.contains("the Lantern Hunts next"),
		"Pause in an ordinary night at Notice 75%%: the confirm says it costs Lantern Notice +25%% and that the Lantern Hunts next (%s)" % ask)
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
	await _until(func() -> bool: return screen == Screen.HUB, 5.0)
	hub = _screen_node as GodHub
	var saved: GodSlot = god_file.call()
	step.call(screen == Screen.HUB and hub != null and god.night == night_now + 1 and god.notice == 100 and god.in_night == "" and hub.hunt_line() != ""
		and hub.lines()[5] == "Lantern Notice 100%" and hub.notice_fill() == 1.0
		and hub.line == "Night %d was abandoned: a lost night. Lantern Notice +25%%." % god.night
		and saved != null and saved.notice == 100 and saved.night == god.night and saved.in_night == "",
		"Abandon after the clock: a lost night, Lantern Notice 100%%, the hub says the Hunt is next, the file agrees (%s)" % [hub.hunt_line() if hub != null else ""])
	if hub == null:
		out.call()
		return
	hub._unhandled_input(_flow_key(KEY_A))
	step.call(god.tier == 1 and hub.line == GodHub.AWAKEN_HUNT, "dev A while the Hunt is due is refused (tier %d, \"%s\")" % [god.tier, hub.line])

	# The Hunt: its stand-in, its name, its stake.
	var hunt_night := god.night
	var faith_before := god.faith
	var dp_before := god.divine_power
	var name_target: String = PowerBook.get_power(target).name
	hub.click(hub.menu_rect("descend").get_center())
	prep = _screen_node as PrepareScreen
	var if_lost := ""
	if prep != null:
		for row: Array in prep.brief_rows():
			if String(row[0]) == "IF LOST":
				if_lost = String(row[1])
	step.call(screen == Screen.PREPARE and prep != null and mission_id == String(hunt0.id) and prep.header_text() == "THE LANTERN HUNT"
		and if_lost.begins_with(GodNight.hunt_stake(god)) and if_lost.contains(name_target),
		"Descend at Notice 100%% is the Hunt (%s): the header says so and IF LOST names %s (\"%s\")" % [mission_id, name_target, if_lost])
	if prep == null:
		out.call()
		return
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	await _until(func() -> bool: return god.in_night != "", 3.0)
	if not is_instance_valid(_mission) or _mission.rules() == null:
		step.call(false, "MANIFEST starts the Hunt")
		out.call()
		return
	var def_now := _mission.rules().mission
	step.call(god.in_night == String(hunt0.id) and def_now.name == String(hunt0.title) and def_now.tier == 1,
		"the Hunt is its stand-in at the god's tier, with its own name (%s, Tier %d)" % [def_now.name, def_now.tier])
	_open_pause()
	ask = ""
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
		ask = _pause.confirm_line()
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("stay").get_center()))
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("resume").get_center()))
	await get_tree().process_frame
	step.call(ask == PauseMenu.CONFIRM_HUNT % GodNight.hunt_stake(god) and not is_instance_valid(_pause) and god.in_night == String(hunt0.id),
		"Pause in the Hunt: Abandon's confirm names the stake (\"%s\"); Stay and Resume return to the night" % ask)

	# The Hunt lost: the seal.
	_mission.rules().force_end(false, "dawn")
	var decided_file: GodSlot = god_file.call()
	step.call(screen != Screen.RESULTS and god.in_night == "" and god.night == hunt_night + 1 and decided_file != null
		and decided_file.in_night == "" and decided_file.night == hunt_night + 1 and decided_file.sealed == target,
		"the Hunt is banked and written the moment it is decided, during its ending (review M1: a window closed now keeps the night)")
	var up := await _until(func() -> bool: return screen == Screen.RESULTS, 8.0)
	var banked: Dictionary = result.get("god", {})
	var hunt: Dictionary = banked.get("hunt", {})
	var lines := ResultsScreen.god_lines(result)
	var change_at := lines.find("Lantern Notice 50%  (-50%)")
	var seal_at := lines.find("The Lantern seals %s for 3 nights" % name_target)
	saved = god_file.call()
	step.call(up and not hunt.is_empty() and not bool(hunt.get("won", true)) and String(hunt.get("sealed", "")) == target and change_at >= 0 and seal_at > change_at
		and ResultsScreen.hunt_called(result) != "",
		"the lost Hunt's results: the Notice change, then \"The Lantern seals %s for 3 nights\", and the Hunt named (%s)" % [name_target, ", ".join(lines)])
	step.call(god.before_hunt == picked and saved != null and saved.before_hunt == picked,
		"the night before the Hunt is remembered, in the file too (review M3: %s)" % god.before_hunt)
	step.call(god.sealed == target and god.seal_nights == 3 and god.notice == 50 and god.night == hunt_night + 1 and god.last_mission == String(hunt0.id)
		and not god.loadout.has(target) and god.faith == faith_before and god.divine_power == dp_before and god.level == level
		and saved != null and saved.sealed == target and saved.seal_nights == 3 and saved.notice == 50 and saved.night == god.night
		and saved.in_night == "" and not saved.loadout.has(target),
		"the god and its file: %s sealed 3 nights, Notice 50%%, Night %d, out of the loadout, Faith %d and Divine Power %d as before the Hunt"
		% [god.sealed, god.night, god.faith, god.divine_power])
	var res := _screen_node as ResultsScreen
	if not up or res == null:
		out.call()
		return
	res.action.emit("continue")
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and hub.seal_line() == GodHub.SEALED % [name_target, "3 nights"] and hub.hunt_line() == "",
		"Continue: the hub says \"%s\" and the Hunt is no longer next" % [hub.seal_line() if hub != null else ""])
	if hub == null:
		out.call()
		return

	# The next night: the sealed card cannot be picked.
	hub.click(hub.menu_rect("descend").get_center())
	prep = _screen_node as PrepareScreen
	if prep == null:
		step.call(false, "Descend opens Prepare after the Hunt")
		out.call()
		return
	step.call(mission_id != picked and mission_id != String(hunt0.id),
		"the night after the Hunt is neither the Hunt's stand-in nor the night before it (review M3: %s)" % mission_id)
	var at_tab := -1
	var at_card := -1
	for i in prep.tabs().size():
		var found := prep.authority_keys(i).find(target)
		if found >= 0:
			at_tab = i
			at_card = found
	if at_tab >= 0:
		prep.set_tab(at_tab)
		prep.click(PrepareScreen.cell_rect(at_card, prep.shown().size()).get_center())
	step.call(mission_id != String(hunt0.id) and at_tab >= 0 and prep.card_cost_text(target) == "Sealed: 3 nights" and not prep.draft.picks.has(target)
		and prep.refused_reason == PrepareScreen.REFUSE_SEALED % "3 nights",
		"Descend after the Hunt is another night (%s); the sealed card says \"%s\" and a click on it picks nothing (\"%s\")"
		% [mission_id, prep.card_cost_text(target), prep.refused_reason])
	_on_prepare_action("back", prep)
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and god.night == hunt_night + 1 and god.sealed == target,
		"Back from Prepare is the hub, nothing counted (Night %d)" % [god.night + 1])
	if hub == null:
		out.call()
		return

	# The title is unchanged and the board's save is what it was (C7).
	hub.click(hub.menu_rect("title").get_center())
	step.call(screen == Screen.TITLE and god == null and FileAccess.get_file_as_bytes(save_path) == disk,
		"the Lantern left the board's save alone: the file's bytes are what they were")
	out.call()
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not (_screen_node as MissionBoard).dev and not GodTree.dev_fill,
		"the board is rebuilt without the DEV tab, the dev fill off")


## The Awaken rite through the real screens (god P3, MS §1, §2, §5, §9.1; plan P3-21, P3-22; pre-flight G5). Starts where `_flow_lantern()`
## stopped (the board; slot 1 holds the Lantern walk's god) and ends on the board with `dev` restored.
## 1. The board's ENDLESS, a fixture written over slot 1 (tier 1, level 10, the bar full, Notice 50, no seal, no gift), Continue: the hub shows
##    Awaken and no gifts line.
## 2. The Hunt first: Notice 100% (fixture), Awaken opens the Hunt's Prepare ("THE LANTERN HUNT"); Back is free; Notice back to 50.
## 3. Awaken: "THE AWAKENING RITE", its six rows, IF LOST exact. MANIFEST, past the intro: `in_night` is the rite, the def is Tier 1 with the Watch,
##    the director a FirstTasteDirector, the chain plate up. Real input: C then Esc ends an aim; C then a click on a lamplighter chains him (the
##    mouse is warped onto him; where this machine will not warp it, the click's own `chain_click()` is used and the step says so). The pause confirm
##    says the rite is lost and what it costs (+25%); Stay and Resume return to the night.
## 4. Win the real way: `offer()` three marked lamplighters (the captive first: the director's own sacrifice path -- shard banners, marches, the real
##    objective). Banked at the decision: Tier 2, +2 points, the cap 20, the gift, Notice 50, Night +1, `last_mission` as before, Faith and Divine
##    Power as before. The results: the rite's lines.
## 5. Continue: the hub has no Awaken and shows the gift. Descend: a Tier 2 night, Prepare's GIFTS row, the def's gifts. Back is free.
## 6. The god back at tier 1 capped (fixture). Awaken, MANIFEST, past the intro, lost the real way (`force_end(false, "dawn")`): Notice 75, Night +1,
##    still capped, no gift; the results say so; Continue offers Awaken again.
## 7. The title, and the board's save is what it was (C7).
func _flow_rite(step: Callable) -> void:
	var was := dev
	var disk := FileAccess.get_file_as_bytes(save_path)
	var out := func() -> void:
		dev = was
		GodTree.dev_fill = false
		go_to(Screen.BOARD)
	var god_file := func() -> GodSlot: return GodSlot.read(GodSlot.path(god_slot, god_base))
	var hunt0: Dictionary = GodNight.HUNTS[0]
	dev = true
	go_to(Screen.BOARD)
	(_screen_node as MissionBoard).click(MissionBoard.ENDLESS_RECT.get_center())
	var slots := _screen_node as SlotScreen
	if slots == null or slots.slot_line(0) == "Empty":
		step.call(false, "the rite walk finds slot 1 holding the Lantern walk's god (%s)" % [slots.slot_line(0) if slots != null else "no slot select"])
		out.call()
		return

	# 1. The fixture: a Tier 1 god at its cap with a full bar, Notice 50, nothing sealed, no gift.
	var fx: GodSlot = god_file.call()
	if fx == null or fx.in_tree().size() < 2:
		step.call(false, "slot 1 holds a god with two abilities in the tree for the rite walk (%s)" % [fx.in_tree() if fx != null else "no file"])
		out.call()
		return
	var pair := PackedStringArray([fx.in_tree()[0], fx.in_tree()[1]])
	fx.tier = 1
	fx.level = fx.cap()
	fx.divine_power = fx.need()
	fx.notice = 50
	fx.sealed = ""
	fx.seal_nights = 0
	fx.in_night = ""
	fx.before_hunt = ""
	fx.gifts = PackedStringArray()
	fx.loadout = pair.duplicate()
	fx.write(GodSlot.path(god_slot, god_base))
	slots.click(slots.button_rect(0, "continue").get_center())
	var hub := _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and god != null and god.tier == 1 and god.level == 10 and god.capped() and god.divine_power == god.need()
		and hub.lines()[2] == "AWAKEN TO GROW" and god.notice == 50 and god.seal_nights == 0 and god.gifts.is_empty(),
		"Continue on the fixture: Tier 1, level 10, the bar full, Notice 50%%, nothing sealed (%s)" % [hub.lines() if hub != null else []])
	step.call(hub != null and hub.awaken_shown() and not hub.awaken_dim() and hub.gifts_line() == "" and hub.hint_text().contains("A: Awaken"),
		"the hub shows Awaken (not dim), no gifts line, and the A hint")
	if hub == null or god == null:
		out.call()
		return
	var night0 := god.night
	var last0 := god.last_mission
	var faith0 := god.faith
	var dp0 := god.divine_power
	var points0 := god.points

	# 2. The Hunt first.
	god.notice = 100
	_write_god()
	go_to(Screen.HUB)
	hub = _screen_node as GodHub
	hub.click(hub.menu_rect("awaken").get_center())
	var prep := _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and mission_id == String(hunt0.id) and prep.header_text() == "THE LANTERN HUNT" and god.night == night0,
		"Awaken at Notice 100%% opens the Hunt, not the rite (%s, \"%s\")" % [mission_id, prep.header_text() if prep != null else ""])
	if prep == null:
		out.call()
		return
	_on_prepare_action("back", prep)
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and god.night == night0 and god.in_night == "", "Back from the Hunt's Prepare is the hub, free")
	god.notice = 50
	_write_god()
	go_to(Screen.HUB)
	hub = _screen_node as GodHub

	# 3. The rite: Prepare, the night, real input, the pause.
	if not await _flow_enter_rite(step, hub, pair):
		out.call()
		return
	var d := _mission.rules().director as FirstTasteDirector
	var def_now := _mission.rules().mission
	step.call(god.in_night == RiteBook.FIRST_TASTE and def_now.tier == 1 and def_now.lantern == LanternWatch.KIND_WATCH and d != null
		and _mission._hud.chain_shown(),
		"MANIFEST: the rite's night is the god's (in_night %s, Tier %d, the %s lantern, a FirstTasteDirector, the chain plate up)" % [god.in_night, def_now.tier, def_now.lantern])
	if d == null or d.marked.is_empty():
		out.call()
		return
	_mission._unhandled_input(_flow_key(KEY_C))
	var aimed: bool = _mission.chain_aim and _mission._hud.chain_aiming
	_mission._unhandled_input(_flow_key(KEY_ESCAPE))
	step.call(aimed and not _mission.chain_aim and not _mission._hud.chain_aiming and not is_instance_valid(_pause),
		"C raises the chain's aim (the plate's frame goes gold) and Esc lets it go without opening the pause menu")
	_mission._unhandled_input(_flow_key(KEY_C))
	var victim: Person = d.marked[0]
	var landed := await _flow_click_ground(victim.ground_pos)
	step.call(d.chain_state == RiteDirector.Chain.BITE and d.captive == victim and not _mission.chain_aim,
		"C then a click on a lamplighter chains him (%s); the aim ends" % ["a real click" if landed else "chain_click(): this machine would not warp the mouse"])
	_open_pause()
	var ask := ""
	if is_instance_valid(_pause):
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("abandon").get_center()))
		ask = _pause.confirm_line()
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("stay").get_center()))
		_pause._on_gui_input(_flow_mouse(_pause._menu.rect_of("resume").get_center()))
	await get_tree().process_frame
	step.call(ask == PauseMenu.rite_line(50) and ask.contains("Lantern Notice +25%") and not is_instance_valid(_pause) and god.in_night == RiteBook.FIRST_TASTE,
		"Pause in the rite: Abandon's confirm says it is lost and costs Notice +25%% (\"%s\"); Stay and Resume return to the night" % ask)

	# 4. Won the real way: the captive, then two more, each through offer().
	var picks: Array[Person] = [victim]
	for p: Person in d.marked:
		if picks.size() < d.need() and not picks.has(p):
			picks.append(p)
	for p in picks:
		d.offer(p)
	var decided := await _until(func() -> bool: return god.in_night == "", 6.0)
	var won_file: GodSlot = god_file.call()
	step.call(decided and d.shards == 3 and god.tier == 2 and god.points == points0 + 2 and god.cap() == 20 and not god.capped()
		and god.gifts == PackedStringArray([RiteBook.WATCHFUL_BELL]) and god.notice == 50 and god.night == night0 + 1 and god.last_mission == last0
		and god.faith == faith0 and god.divine_power == dp0,
		"three shards banked at the decision: Tier 2, +2 points, the cap 20, the gift, Notice 50, Night %d, last mission and Faith and Divine Power as before (tier %d, %s)"
		% [night0 + 1, god.tier, god.gifts])
	step.call(won_file != null and won_file.tier == 2 and won_file.gifts == god.gifts and won_file.points == god.points and won_file.in_night == ""
		and won_file.notice == 50 and won_file.night == night0 + 1,
		"and the god's file agrees the moment it is decided (a window closed during the ending keeps the rite)")
	var up := await _until(func() -> bool: return screen == Screen.RESULTS, 12.0)
	var banked: Dictionary = result.get("god", {})
	var rite: Dictionary = banked.get("rite", {})
	var lines := ResultsScreen.god_lines(result)
	var stolen_at := -1
	for i in lines.size():
		if lines[i].begins_with("Stolen: The Watchful Bell"):
			stolen_at = i
	step.call(up and bool(rite.get("won", false)) and String(rite.get("gift", "")) == RiteBook.WATCHFUL_BELL and lines.has("Tier 2: Omen")
		and lines.has("+2 ability points") and stolen_at > lines.find("Tier 2: Omen") and ResultsScreen.rite_called(result) != ""
		and String(result.get("reason", "")) == "shards" and bool(result.get("goal", {}).get("done", false)),
		"the won rite's results: the goal done, the Tier and the Stolen lines, the rite named (%s)" % [", ".join(lines)])
	var res := _screen_node as ResultsScreen
	if not up or res == null:
		out.call()
		return

	# 5. The hub after: no Awaken, the gift; a Tier 2 night carries it.
	res.action.emit("continue")
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and not hub.awaken_shown() and hub.gifts_line() == GodHub.GIFTS_LINE % RiteBook.gift_name(RiteBook.WATCHFUL_BELL),
		"Continue: the hub has no Awaken and says \"%s\"" % [hub.gifts_line() if hub != null else ""])
	if hub == null:
		out.call()
		return
	hub.click(hub.menu_rect("descend").get_center())
	prep = _screen_node as PrepareScreen
	var gifts_row := ""
	if prep != null:
		for row: Array in prep.brief_rows():
			if String(row[0]) == "GIFTS":
				gifts_row = String(row[1])
	var next_def := GodNight.def_for(god, mission_id) if prep != null else null
	step.call(screen == Screen.PREPARE and prep != null and next_def != null and next_def.tier == 2 and not prep.is_rite()
		and gifts_row == RiteBook.gift_effect(RiteBook.WATCHFUL_BELL) and next_def.gifts == PackedStringArray([RiteBook.WATCHFUL_BELL]),
		"Descend is a Tier 2 night (%s): Prepare's GIFTS row says \"%s\" and the night's def carries the gift" % [mission_id, gifts_row])
	if prep == null:
		out.call()
		return
	_on_prepare_action("back", prep)
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and god.night == night0 + 1, "Back from Prepare is the hub, nothing counted")

	# 6. Lost the real way: the god put back at the cap with no gift.
	god.tier = 1
	god.level = god.cap()
	god.divine_power = god.need()
	god.points = points0
	god.gifts = PackedStringArray()
	god.notice = 50
	_write_god()
	go_to(Screen.HUB)
	hub = _screen_node as GodHub
	step.call(hub != null and hub.awaken_shown() and god.capped() and god.gifts.is_empty(), "the fixture again: Tier 1 at the cap, Awaken offered")
	if hub == null or not await _flow_enter_rite(step, hub, pair):
		out.call()
		return
	var lost_night := god.night
	_mission.rules().force_end(false, "dawn")
	var lost_file: GodSlot = god_file.call()
	step.call(god.in_night == "" and god.tier == 1 and god.capped() and god.notice == 75 and god.night == lost_night + 1 and god.gifts.is_empty()
		and god.points == points0 and god.last_mission == last0 and lost_file != null and lost_file.notice == 75 and lost_file.night == lost_night + 1
		and lost_file.tier == 1 and lost_file.in_night == "",
		"the lost rite is banked at the decision: Tier 1 and capped, no gift, Notice 75, Night %d, the file agrees (Notice %d)" % [lost_night + 1, god.notice])
	up = await _until(func() -> bool: return screen == Screen.RESULTS, 8.0)
	banked = result.get("god", {})
	rite = banked.get("rite", {})
	lines = ResultsScreen.god_lines(result)
	step.call(up and not rite.is_empty() and not bool(rite.get("won", true)) and lines.has("The god is still capped. Awaken again when ready.")
		and lines.has("Lantern Notice 75%  (+25%)") and ResultsScreen.rite_called(result) != "" and not bool(result.get("goal", {}).get("done", true)),
		"the lost rite's results: the goal missed, the god still capped, Notice +25%% (%s)" % [", ".join(lines)])
	res = _screen_node as ResultsScreen
	if not up or res == null:
		out.call()
		return
	res.action.emit("continue")
	hub = _screen_node as GodHub
	step.call(screen == Screen.HUB and hub != null and hub.awaken_shown() and god.notice == 75,
		"Continue: Awaken is offered again at Notice 75%")
	if hub == null:
		out.call()
		return

	# 7. The title is unchanged and the board's save is what it was (C7).
	hub.click(hub.menu_rect("title").get_center())
	step.call(screen == Screen.TITLE and god == null and FileAccess.get_file_as_bytes(save_path) == disk,
		"the rite left the board's save alone: the file's bytes are what they were")
	out.call()
	step.call(screen == Screen.BOARD and _screen_node is MissionBoard and not (_screen_node as MissionBoard).dev and not GodTree.dev_fill,
		"the board is rebuilt without the DEV tab, the dev fill off")


## Awaken from the hub, Prepare's rite page, MANIFEST and into the night past its intro (FLOW, god P3): the rite's header and rows are checked,
## the draft is `pair`. False (and a failed step) when the screens do not come up.
func _flow_enter_rite(step: Callable, hub: GodHub, pair: PackedStringArray) -> bool:
	hub.click(hub.menu_rect("awaken").get_center())
	var prep := _screen_node as PrepareScreen
	var labels := PackedStringArray()
	var if_lost := ""
	if prep != null:
		for row: Array in prep.brief_rows():
			labels.append(String(row[0]))
			if String(row[0]) == "IF LOST":
				if_lost = String(row[1])
	step.call(screen == Screen.PREPARE and prep != null and mission_id == RiteBook.FIRST_TASTE and prep.header_text() == PrepareScreen.RITE_HEADER
		and labels == PackedStringArray(["RITE", "WIN", "LOSE", "IF WON", "IF LOST", "CHAIN"]) and if_lost == "Lantern Notice +25%; the god stays capped",
		"Awaken opens THE AWAKENING RITE (%s): its six rows and IF LOST \"%s\"" % [", ".join(labels), if_lost])
	if prep == null or mission_id != RiteBook.FIRST_TASTE:
		return false
	prep.draft.preselect(pair)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 15.0)
	await _past_intro()
	await _until(func() -> bool: return god.in_night != "", 3.0)
	return is_instance_valid(_mission) and _mission.rules() != null


## A real left click on the ground point `ground` (FLOW, god P3, pre-flight G5): the mouse is warped onto it, the click goes through the mission's
## own `_unhandled_input`, and true says the mouse really was there. Where this machine will not warp the mouse the click's work is done by
## `Mission.chain_click()` instead (false), so FLOW tests the rite and not the window manager.
func _flow_click_ground(ground: Vector2) -> bool:
	var view := get_viewport()
	var at := view.get_canvas_transform() * Iso.ground_to_screen(ground)
	view.warp_mouse(at)
	await get_tree().process_frame
	await get_tree().process_frame
	var landed: bool = _mission._bf.mouse_ground().distance_to(ground) < 0.4 and not _mission._hud.chain_rect().has_point(at) \
		and _mission._hud.slot_at(at) < 0 and view.get_visible_rect().has_point(at)
	if landed:
		_mission._unhandled_input(_flow_mouse(at))
	else:
		_mission.chain_click(ground)
	return landed


## FLOW (god P1, ruling P11): a board night's bank is a test bank -- flagged, no believers, no progress line, its first clear's fastest
## time among the bests -- and no tier has opened by it.
func _test_bank(bank: Dictionary) -> bool:
	return bool(bank.get("test", false)) and not bank.has("believers") and not bank.has("progress") and save.descend.open_tier == 1 \
		and save.descend.believers == 0 and _bests_text(bank).contains("Fastest clear")


## The bests a test bank reports, comma-joined (FLOW).
func _bests_text(bank: Dictionary) -> String:
	return ", ".join(PackedStringArray(bank.get("bests", PackedStringArray())))


## The night's wishes by id, in the order heard (FLOW, v0.11 M1).
func _wish_ids() -> PackedStringArray:
	var out := PackedStringArray()
	if is_instance_valid(_mission) and _mission.descent() != null:
		for w in _mission.descent().wishes:
			out.append(w.def.id)
	return out


## The steps from before the tier board (FLOW, v0.11 M1) play Last Judgement, The Long Night and their drafts with no upgrades bought,
## so the tiers' own budgets are checked. Every tier and power is open on the board whatever the save says (god P1, ruling C3), so the
## veteran's open tiers and unlocked powers are no longer set here.
func _veteran() -> void:
	save.descend.dp_bought = 0
	save.descend.slot_bought = 0


## The Long Night through the screens (v0.09), from the board: Act I won on its clock, the choice card, the re-draft,
## Act II (one building counted once), Act III ended on its clock for the night's results; then a restart in Act I and
## the way out through Pause. Ends on the board.
func _flow_night(step: Callable) -> void:
	var kit := MissionBook.long_night().default_loadout
	(_screen_node as MissionBoard).choose(MissionBook.LONG_NIGHT)
	var prep: PrepareScreen = _screen_node as PrepareScreen
	step.call(screen == Screen.PREPARE and prep != null and prep.mission.id == MissionBook.LONG_NIGHT
		and prep.draft.slots == 6 and prep.draft.capacity == 16 and mission_id == MissionBook.LONG_NIGHT,
		"picking The Long Night opens its draft on Tier 5's 6 slots and 16 DP (v0.11 M1)")
	step.call(prep.draft.picks == kit, "its first Prepare opens on the night's default loadout (%s)" % ",".join(prep.draft.picks))
	prep.draft.preselect(kit)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and is_instance_valid(_mission) and _mission.started(), 5.0)
	await _past_intro()
	step.call(screen == Screen.MISSION and is_instance_valid(_mission) and loadout == kit
		and _mission.act() != null and _mission.act().id == "omen" and _mission.night() != null,
		"MANIFEST starts the night in Act I, The Omen (%s)" % ",".join(loadout))

	# Act I wins by stopping the warning (v0.11 M1: its clock no longer wins), and the interlude after it is for that act.
	(_mission.rules().director as WarningDirector).warning_dead = true
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
		and _mission == first and prep.mission.id == "festival" and prep.draft.slots == 6 and prep.draft.capacity == 16,
		"Choose powers shows the Festival's draft with BEGIN and the tier's 6 slots and 16 DP, the mission still alive")
	prep.draft.preselect(kit)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and not _fading and _mission.act().id == "festival", 5.0)
	await _past_intro()
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
	step.call(screen == Screen.PREPARE and prep != null and prep.confirm_label == "BEGIN" and _mission == first
		and prep.draft.slots == 6 and prep.draft.capacity == 16, "Choose powers shows Act III's draft with BEGIN, the tier's 6 slots and 16 DP")
	prep.draft.preselect(kit)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return screen == Screen.MISSION and not _fading and _mission.act().id == "judgement", 5.0)
	# The festival held: Act III's director posts the marshals while the act is built, before its HUD exists -- the
	# banner is held and shown after the intro's (v0.09 final review; before, it was lost).
	var shown: PackedStringArray = _mission._hud.banners() if is_instance_valid(_mission._hud) else PackedStringArray()
	step.call(shown.has("THE SOLDIERS TAKE THE GATES"), "the held festival's carry-over banner shows (%s)" % ", ".join(shown))
	await _past_intro()
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
	await _past_intro()
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 5.0)
	await _past_intro()
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
	await _past_intro()
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
	await _past_intro()
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
	await _past_intro()
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
	await _past_intro()
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
	await _past_intro()

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
	await _past_intro()
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


## The Lantern campaign through the screens (v0.10), from the title: Night 1 won by stopping the warning, Night 2's three cards
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
	await _past_intro()

	# Review focus 2: Restart and Pause, Campaign record nothing either.
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	step.call(save.campaign.night == 0 and save.campaign.bites == 0, "Restart in a campaign night records nothing")
	await _past_intro()
	_open_pause()
	on_action("pause:campaign")
	await get_tree().process_frame
	step.call(screen == Screen.CAMPAIGN and not is_instance_valid(_mission) and save.campaign.night == 0
		and save.campaign.bites == 0, "Pause, Campaign leaves the night unplayed: no bite, the same night")

	# Night 1 won by stopping the warning (v0.11 M1, spec §7.3: dawn no longer wins it).
	night = _screen_node as CampaignScreen
	night.click(night.button_rect("draft").get_center())
	(_screen_node as PrepareScreen).draft.preselect(PackedStringArray(["whisper", "wisp"]))
	_on_prepare_action("manifest", _screen_node as PrepareScreen)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	(_mission.rules().director as WarningDirector).warning_dead = true
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
	# v0.10 M5: Back from the draft keeps tonight's card chosen.
	_on_prepare_action("back", _screen_node as PrepareScreen)
	night = _screen_node as CampaignScreen
	step.call(screen == Screen.CAMPAIGN and night != null and night.chosen == MissionBook.VIGIL_FLAME,
		"Back from the draft keeps the Vigil Flame chosen (%s)" % (night.chosen if night != null else "-"))
	night.click(night.button_rect("draft").get_center())
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.mission.id == MissionBook.VIGIL_FLAME and prep.draft.capacity == dp1
		and prep.draft.pool.has("heaven"), "the Vigil Flame's draft: the god's %d DP, every power" % dp1)
	prep.draft.preselect(quiet)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
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
	await _past_intro()
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
	step.call(mission_id == save.last_mission and loadout == starting_loadout(save, mission_id) and save.campaign.ending_seen,
		"leaving by the ending puts the board's own mission back (%s), the ending seen" % mission_id)

	# v0.10 M5: an ending never seen (the game quit on the last Results) opens from Campaign before a fresh one.
	save.campaign.ending_seen = false
	(_screen_node as TitleScreen).action.emit("campaign")
	var owed := _screen_node as EndingScreen
	step.call(screen == Screen.ENDING and owed != null and owed.pages.size() == 2 and owed.summary != "",
		"an ending left unseen opens from Campaign, with its closing line")
	owed.action.emit("title")
	step.call(screen == Screen.TITLE and save.campaign.ending_seen and save.campaign.ending == CampaignDef.FALSE_LANTERN,
		"and once seen it is done")

	# Review focus 3: after an ending, Campaign begins a fresh one.
	(_screen_node as TitleScreen).action.emit("campaign")
	step.call(screen == Screen.CAMPAIGN and save.campaign.night == 0 and save.campaign.ending == ""
		and save.campaign.dp == CampaignDef.START_DP, "after an ending, Campaign begins a fresh one")

	# Review focus 5: the board after the campaign drafts within its own mission's numbers.
	(_screen_node as CampaignScreen).action.emit("title")
	(_screen_node as TitleScreen).action.emit("play")
	(_screen_node as MissionBoard).choose(MissionBook.LAST_JUDGEMENT)
	prep = _screen_node as PrepareScreen
	step.call(prep != null and prep.draft.slots == 6 and prep.draft.capacity == 16 and not _in_campaign,
		"the board after the campaign: Last Judgement at Tier 5, 6 slots and 16 DP")
	on_action("prepare:back")
	(_screen_node as MissionBoard).action.emit("back")
	step.call(screen == Screen.TITLE, "and back to the title")


## v0.10 M6 (spec §5; review focus 4 and 5): Mira's House opens on its tour -- the clock waiting, a caption up -- and a
## Space press lands it at once: the caption gone, nothing cast, the clock running. A restart tours again from the top.
func _flow_tour(step: Callable) -> void:
	_in_campaign = false
	mission_id = MissionBook.MIRAS_HOUSE
	loadout = MissionBook.miras_house().default_loadout
	go_to(Screen.MISSION)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await get_tree().process_frame
	var clock0 := _mission.rules().time_left
	step.call(_mission.touring() and _mission._hud.caption() == "", "Mira's House opens on its tour, the banner alone first (no caption)")
	# v0.11.1: the tour waits for the opening banners, then each stop's caption shows while the camera holds there.
	var held := await _until(func() -> bool: return _mission._hud.caption() != "", 20.0)
	step.call(held and _mission.touring() and _mission._hud.banners().is_empty(), "then its first stop holds, a caption up")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await get_tree().process_frame
	await get_tree().process_frame
	var cooling := false
	for i in _mission.rules().loadout.size():
		cooling = cooling or _mission.rules().cooldown_left(i) > 0.0
	step.call(not _mission.in_intro() and _mission._hud.caption() == "" and not cooling,
		"Space lands it: no caption, nothing cast")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < clock0, "and the clock runs (%.2f)" % _mission.rules().time_left)
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	await get_tree().process_frame
	step.call(_mission.touring() and _mission._hud.caption() == "", "a restart tours again from the top")
	held = await _until(func() -> bool: return _mission._hud.caption() != "", 20.0)
	step.call(held, "and holds at its first stop under a caption")
	_mission.skip_intro()
	step.call(not _mission.in_intro() and _mission._hud.caption() == "", "and lands at once when skipped")
	_open_pause()
	on_action("pause:missions")
	await get_tree().process_frame
