# KAK Milestone 4 — Screens — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put the game around the mission: a title screen over the panning town, a Prepare screen where the player drafts four of the eleven powers, a pause menu, a results screen with the score and rank, and a save file that remembers the best score and the last loadout.

**Architecture:** `Game` becomes the project's main scene and owns one screen at a time — Title, Prepare, Mission, Results — plus the pause menu over the mission. Each screen is a `Control` on its own `CanvasLayer` that draws itself with the pixel `UiTheme` milestone 3 built, and reports what the player pressed through one signal. The parts worth proving without a screen are split out as plain objects: `SaveFile` (what survives between runs), `Draft` (the four-slot pick rules) and `Menu` (where the buttons are and which one the mouse is over). `Mission` gains a public `start()` and a `finished` signal so `Game` can drive it; it keeps working standalone for the scripted runs and the bench.

**Tech Stack:** Godot 4.7.2, GDScript, `gl_compatibility`, 640×360 viewport; `UiTheme`, `Hud`, `Rules`, `Mission`, `PowerBook` and the committed Pixelify Sans font and 84×84 / 42×42 icons.

## Global Constraints

- Engine: `F:\Godot\Godot_v4.7.2-stable_win64_console.exe` (Git Bash: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`), renderer `gl_compatibility`.
- Viewport 640×360, nearest filtering, `2d/snap/snap_2d_vertices_to_pixel=true`: pixel lines are hairlines (`width = -1.0`); never `draw_line` with width ≥ 1.
- Every screen is drawn at 640×360 with `UiTheme`'s font, palette and gold frame. No new fonts, no new colours outside `UiTheme`, no `Label`/`Button` nodes: the screens draw themselves in `_draw()` and hit-test with `Menu`, the way `Hud` does. The reason is consistency — a themed `Button` and a drawn panel do not match at this size.
- **A texture is loaded before it is drawn, never inside `_draw()`.** Milestone 3 lost an afternoon to this: `load()` during drawing hands over a texture the GPU does not have yet and paints a solid white block, and a screen that only redraws on change keeps the white. Load in `setup()` / `_ready()` and keep the reference.
- The 11 effects and the effect toolkit (`src/fx/`) do not change. Neither do `Rules`, `Stability`, `Targeting` or `Hud`, beyond what a task names.
- New code lives in `src/game/` (screens in `src/game/ui/`).
- Tests: `bash tools/test.sh` must end `checks=<N> failures=0`; the **495 checks** standing today keep passing. Suites are `extends RefCounted` scripts with `static func run(t) -> void`, registered in `tests/run_all.gd`; use `t.check(cond, msg)` and `t.near(a, b, eps, msg)`. A suite that builds nodes frees them — no leaked-object lines in the output.
- Behaviour gate: `/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd` must keep printing `rows=19`, `digest=61267b7e90524d800bf1c3473a71146b`, `blocked=000000111000000000000011000000000000000000001110000000000000`, `emitters=45`. Never edit that tool or those values.
- The scripted runs keep working, unchanged in name and output: `SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test` prints one `MISSION test ...` line, and `--bench` prints one `bench[mission] ...` line. They are how this milestone proves it did not break milestone 3.
- Saved data lives in `user://kak_save.cfg` and nowhere else. **Never** write test data to that path: every test passes its own `user://test_*.cfg` and deletes it afterwards.
- The game's name in any text is **Kingdoms Amid Kataclysm** / **KAK** (never KWAI or HUM).
- Every number and every screen's contents come from the spec (`docs/superpowers/specs/2026-09-19-kak-one-mission-game-design.md` §1, §4.4, §5). Where this plan deviates from the spec's layout it says so and why; do not invent further deviations — report them instead.
- GDScript style: tabs, typed vars; explicit types when a value comes from an untyped Array or Dictionary; `##` doc comments like the surrounding code.
- Commit after each task; every message ends with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commit new scripts with their generated `.gd.uid` files.
- Leave the untracked `.codex/` folder and `docs/HUM_Game_Design_Document_v1.docx` alone. Do not commit anything under `captures/` that git does not already track.
- **Out of scope, on purpose:** UI sounds and the numbers tuned from playtests — milestone 5. This milestone adds no audio.

---

## File Structure

| File | Responsibility |
|---|---|
| `src/game/save_file.gd` (new) | What survives between runs: best score, its rank, the last loadout. Reads and writes one `ConfigFile`. |
| `src/game/draft.gd` (new) | The Prepare screen's rules: four slots, in pick order, eleven candidates. |
| `src/game/ui/menu.gd` (new) | A set of pixel buttons: their rects, which one a point is over, and how they draw. Shared by Title, Results and Pause. |
| `src/game/ui/title_screen.gd` (new) | The title over the slowly panning town, and its three choices. |
| `src/game/ui/prepare_screen.gd` (new) | Briefing, the eleven cards, the 1–4 badges, the description bar and MANIFEST. |
| `src/game/ui/results_screen.gd` (new) | Victory or defeat, the rank letter, the score, NEW BEST!, the stat table, three choices. |
| `src/game/ui/pause_menu.gd` (new) | Resume, Restart, Change powers, Title, over a frozen mission. |
| `src/game/game.gd` (new) | The main scene: which screen is up, the save file, and driving `Mission`. |
| `scenes/game.tscn` (new) | The main scene. |
| `src/game/mission.gd` (modify) | A public `start(loadout, seed)` and a `finished` signal, the 2 s intro sweep, and Esc asking `Game` for the pause menu. |
| `project.godot` (modify) | `run/main_scene` becomes `res://scenes/game.tscn`. |
| `play.bat` (modify) | Opens the title screen. |
| `tests/test_save_file.gd`, `tests/test_draft.gd`, `tests/test_menu.gd`, `tests/test_flow.gd` (new) | One suite per provable unit, registered in `tests/run_all.gd`. |

Task order: 1, 2, 3, 4, 5, 6, 7. Each task ends with a green suite and a commit.

Expected `checks=` after each task: Task 1 → 508, Task 2 → 532, Task 3 → 544, Task 4 → 555, Task 5 → 562, Task 6 → 562, Task 7 → 562. Tasks 3 to 6 each end with a **screenshot the implementer must look at and describe** — these are screens, and headless checks cannot see them.

---

### Task 1: What survives between runs

**Files:**
- Create: `src/game/save_file.gd`
- Create: `tests/test_save_file.gd`
- Modify: `tests/run_all.gd`

**Why:** the Results screen needs to know whether this run beat the best one, and Prepare needs the last loadout preselected. Both come from one small file, and it is the one piece of this milestone that is pure I/O — worth getting right and proving before anything draws.

**Interfaces:**
- Consumes: `PowerBook.get_power(key)` (to drop a key that is no longer a power).
- Produces:
  - `SaveFile.new().load_from(path := SaveFile.PATH) -> SaveFile`
  - `save_to(path := SaveFile.PATH) -> void`
  - `record(score: int, rank: String) -> bool` — true when this run beat the best
  - `remember_loadout(keys: PackedStringArray) -> void`
  - `best_score: int`, `best_rank: String`, `last_loadout: PackedStringArray`, `const PATH`

- [ ] **Step 1: Write the failing test**

Create `tests/test_save_file.gd`:

```gdscript
extends RefCounted
## The save file: defaults when there is nothing to read, a round trip, only better scores recorded, and a
## file that has been damaged or hand-edited does not take the game down with it.


static func run(t) -> void:
	var path := "user://test_save_file.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var fresh := SaveFile.new().load_from(path)
	t.check(fresh.best_score == 0 and fresh.best_rank == "-", "no save file means no best score (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(fresh.last_loadout.is_empty(), "and no loadout to preselect")

	# A better score is recorded, a worse one is not.
	t.check(fresh.record(6200, "B"), "the first score is the best score")
	t.check(fresh.best_score == 6200 and fresh.best_rank == "B", "and is kept with its rank (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(not fresh.record(5000, "C"), "a worse run does not beat it")
	t.check(fresh.best_score == 6200 and fresh.best_rank == "B", "and does not overwrite it (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(fresh.record(12500, "S"), "a better run does")
	t.check(fresh.best_score == 12500 and fresh.best_rank == "S", "with its own rank (%d, %s)" % [fresh.best_score, fresh.best_rank])

	fresh.remember_loadout(PackedStringArray(["nova", "heaven", "cinder", "gravity"]))
	fresh.save_to(path)
	var read := SaveFile.new().load_from(path)
	t.check(read.best_score == 12500 and read.best_rank == "S", "the best score comes back (%d, %s)" % [read.best_score, read.best_rank])
	t.check(read.last_loadout == PackedStringArray(["nova", "heaven", "cinder", "gravity"]),
		"and the loadout comes back in its own order (%s)" % [read.last_loadout])

	# A loadout with a key that is not a power any more is dropped rather than carried into the draft.
	read.remember_loadout(PackedStringArray(["nova", "kettle", "cinder"]))
	read.save_to(path)
	var filtered := SaveFile.new().load_from(path)
	t.check(filtered.last_loadout == PackedStringArray(["nova", "cinder"]),
		"a key that is not a power is dropped (%s)" % [filtered.last_loadout])

	# A damaged file reads as a fresh one instead of raising.
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("this is not a config file\n\x00\x01")
	f.close()
	var broken := SaveFile.new().load_from(path)
	t.check(broken.best_score == 0 and broken.last_loadout.is_empty(),
		"a damaged save file reads as a fresh one (%d, %s)" % [broken.best_score, broken.last_loadout])

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	t.check(not FileAccess.file_exists(path), "the test cleans up after itself")
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_save_file.gd",` to `SUITES` after `"res://tests/test_hud.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_save_file.gd` and `checks=496 failures=1`.

- [ ] **Step 3: Write the implementation**

Create `src/game/save_file.gd`:

```gdscript
class_name SaveFile
extends RefCounted
## What survives between runs (spec §6): the best score with the rank it earned, and the last loadout the
## player drafted, so Prepare can preselect it. One ConfigFile, three values, and a bad read is never fatal --
## a player with a corrupted save should lose their best score, not the game.

const PATH := "user://kak_save.cfg"
const SECTION := "kak"
## The rank shown when nothing has been scored yet.
const NO_RANK := "-"

var best_score := 0
var best_rank := NO_RANK
## The last drafted loadout, in slot order. Empty when there is nothing to preselect.
var last_loadout := PackedStringArray()


func load_from(path := PATH) -> SaveFile:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		# Missing is the normal first run; damaged is rare and not worth a crash. Either way: defaults.
		return self
	best_score = int(cfg.get_value(SECTION, "best_score", 0))
	best_rank = String(cfg.get_value(SECTION, "best_rank", NO_RANK))
	last_loadout = _known(PackedStringArray(cfg.get_value(SECTION, "last_loadout", PackedStringArray())))
	return self


func save_to(path := PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "best_score", best_score)
	cfg.set_value(SECTION, "best_rank", best_rank)
	cfg.set_value(SECTION, "last_loadout", last_loadout)
	var err := cfg.save(path)
	if err != OK:
		push_warning("KAK could not write its save file (%d): %s" % [err, path])


## Take a finished mission's score. True when it is the new best, which is what earns the NEW BEST! line.
func record(score: int, rank: String) -> bool:
	if score <= best_score:
		return false
	best_score = score
	best_rank = rank
	return true


func remember_loadout(keys: PackedStringArray) -> void:
	last_loadout = _known(keys)


## Only keys that are still powers. A save from an older build (or a hand-edited one) cannot put a key the
## game has never heard of into the draft.
func _known(keys: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for key in keys:
		if not PowerBook.get_power(key).is_empty():
			out.append(key)
	return out
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tools/test.sh`
Expected: `checks=508 failures=0`, output pristine.

If the damaged-file check fails because `ConfigFile.load()` returned `OK` on the junk you wrote, print the return value and the parsed values, and report it — do not weaken the check. The point of it is that a bad file cannot take the game down.

- [ ] **Step 5: Commit**

```bash
git add src/game/save_file.gd src/game/save_file.gd.uid tests/test_save_file.gd tests/test_save_file.gd.uid tests/run_all.gd
git commit -m "feat: the save file" -m "The best score with the rank it earned and the last drafted loadout, in one ConfigFile at user://kak_save.cfg. A missing file is a first run and a damaged one reads as a fresh one, because a corrupted save should cost a player their best score and not the game. A loadout key that is no longer a power is dropped on the way in." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The mission takes orders, and the shell that gives them

**Files:**
- Modify: `src/game/mission.gd`
- Create: `src/game/game.gd`
- Create: `scenes/game.tscn`
- Create: `tests/test_flow.gd`
- Modify: `tests/run_all.gd`

**Why:** every screen after this one needs somewhere to live and something to hand control back to. This task builds that host and gives `Mission` the two things it lacks: a way to be told which four powers to use and which seed to run, and a way to say how it ended. Nothing is drawn yet — the screens land one per task, and until then `Game` goes straight into a mission, so the scripted runs and the bench keep working from the first commit.

**Interfaces:**
- Consumes: `Mission` (as `scenes/mission.tscn`), `SaveFile` (Task 1), `Rules.score/rank/stat_lines`.
- Produces (Mission):
  - `signal finished(won: bool, reason: String, score: int, rank: String, lines: Array[Dictionary])`
  - `var autostart := true` — set **false before adding the node** when something else will call `start()`
  - `func start(powers: PackedStringArray, seed_value: int) -> void`
  - `signal pause_pressed` — Esc with nothing to cancel, so `Game` can raise the pause menu
  - `func set_frozen(frozen: bool) -> void`
- Produces (Game):
  - `enum Screen {TITLE, PREPARE, MISSION, RESULTS}`
  - `const FLOW: Dictionary` — `"<screen>:<action>"` to the next screen
  - `static func next_screen(action: String) -> int` — the screen an action leads to, or `-1`
  - `func go_to(screen: int) -> void`, `var screen: int`, `var save: SaveFile`

- [ ] **Step 1: Write the failing test**

Create `tests/test_flow.gd`:

```gdscript
extends RefCounted
## The screen flow as data: every button on every screen leads somewhere, and the table matches the spec's
## flow (title -> prepare -> mission -> results, with pause over the mission).


static func run(t) -> void:
	t.check(Game.next_screen("title:play") == Game.Screen.PREPARE, "Play leads to Prepare")
	t.check(Game.next_screen("prepare:manifest") == Game.Screen.MISSION, "Manifest leads to the mission")
	t.check(Game.next_screen("prepare:back") == Game.Screen.TITLE, "Prepare can go back to the title")
	t.check(Game.next_screen("mission:over") == Game.Screen.RESULTS, "a finished mission leads to the results")
	t.check(Game.next_screen("results:replay") == Game.Screen.MISSION, "Replay runs the same loadout again")
	t.check(Game.next_screen("results:change") == Game.Screen.PREPARE, "Change powers goes back to the draft")
	t.check(Game.next_screen("results:title") == Game.Screen.TITLE, "and Title goes home")
	t.check(Game.next_screen("pause:resume") == Game.Screen.MISSION, "Resume stays in the mission")
	t.check(Game.next_screen("pause:restart") == Game.Screen.MISSION, "Restart is a new mission")
	t.check(Game.next_screen("pause:change") == Game.Screen.PREPARE, "Change powers from the pause menu drafts again")
	t.check(Game.next_screen("pause:title") == Game.Screen.TITLE, "and the pause menu can quit to the title")
	t.check(Game.next_screen("prepare:nonsense") == -1, "an action nobody offers leads nowhere")

	# Every action in the table names a screen that exists, and every screen can be reached.
	var reachable := {}
	for action in Game.FLOW:
		var to: int = Game.FLOW[action]
		t.check(to >= 0 and to <= Game.Screen.RESULTS, "%s leads to a real screen (%d)" % [action, to])
		reachable[to] = true
	t.check(reachable.size() == 4, "all four screens are reachable (%d)" % reachable.size())
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_flow.gd",` to `SUITES` after `"res://tests/test_save_file.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_flow.gd` and `checks=509 failures=1`.

- [ ] **Step 3: Give the mission a public way in and out**

In `src/game/mission.gd`, give the script a class name so `Game` can hold it as a typed variable — add
`class_name Mission` as the first line, above `extends Node2D`. (A plain `Node2D` variable cannot reach
`autostart` or `start()` without an unsafe-access error.) Then add the signals after `extends Node2D` and its
doc comment:

```gdscript
## The run is over, with everything the Results screen shows.
signal finished(won: bool, reason: String, score: int, rank: String, lines: Array[Dictionary])
## Esc with nothing to cancel: whoever owns this mission decides what that means.
signal pause_pressed
```

and the flag next to `var _scripted := false`:

```gdscript
## True when the mission runs on its own (play.bat before milestone 4, the scripted runs, the bench) and
## starts itself. Game sets it false before adding the node, then calls start() with the drafted loadout.
var autostart := true
```

Replace the middle of `_ready()` — the four lines from `var seed_arg := ...` to `_start(seed_value)` — with:

```gdscript
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var seed_value := int(seed_arg) if seed_arg != "" else (7 if scripted else Time.get_ticks_usec())
	if autostart:
		start(_loadout(args), seed_value)
```

Rename `_start(seed_value)` to the public `start(powers, seed_value)` and take the loadout as an argument. Its first lines become:

```gdscript
## A fresh mission: clear the world, build the town, spawn the people, hand out 100 DP and four minutes.
## `powers` is the drafted loadout in slot order; an empty array falls back to the command line's or the
## default four, so a standalone run still works.
func start(powers: PackedStringArray, seed_value: int) -> void:
	_bf.reset(seed_value)
```

and inside it, replace the `_rules.setup(_loadout(args), ...)` line with:

```gdscript
	var wanted := powers if not powers.is_empty() else _loadout(OS.get_cmdline_user_args())
	_rules.setup(wanted, _bf.ctx, _bf.ctx.env, _bf.ctx.field, _crowd, _town)
```

(the `var args := OS.get_cmdline_user_args()` line already in `start()` stays — it is what `--people` reads.)

Replace `_on_over()` so it reports instead of printing, keeping the console line for the scripted runs:

```gdscript
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
```

In `_unhandled_input()`, the Esc branch asks instead of quitting:

```gdscript
		elif event.physical_keycode == KEY_ESCAPE:
			# Aiming first: Esc cancels a drag. With nothing to cancel it is the pause menu's -- or, for a
			# mission running on its own with no Game around it, still the way out.
			if _aim.aiming:
				_aim.cancel()
			elif autostart:
				_bf.quit()
			else:
				# Handled here, so the same Esc cannot reach the pause menu it is about to open and close it again.
				get_viewport().set_input_as_handled()
				pause_pressed.emit()
```

And add, at the end of the file, the freeze the pause menu needs:

```gdscript
## Stop the world without stopping the menu over it. The whole mission lives under this node, so pausing the
## subtree freezes the town, the crowd, the effects and the clock together.
func set_frozen(frozen: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
```

- [ ] **Step 4: Write the shell**

Create `src/game/game.gd`:

```gdscript
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
	# Until Task 3 lands the title screen, go straight into a mission so the game is playable and the
	# scripted runs keep working.
	go_to(Screen.MISSION)


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
	mission.start(loadout, Time.get_ticks_usec())
	return mission


func _on_mission_finished(won: bool, reason: String, score: int, rank: String, lines: Array[Dictionary]) -> void:
	result = {"won": won, "reason": reason, "score": score, "rank": rank, "lines": lines,
		"best": save.record(score, rank)}
	save.remember_loadout(loadout)
	save.save_to()
	on_action("mission:over")
```

- [ ] **Step 5: Write the scene**

Create `scenes/game.tscn`:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://src/game/game.gd" id="1_game"]

[node name="Game" type="Node"]
script = ExtResource("1_game")
```

- [ ] **Step 6: Run the tests and the mission**

```bash
bash tools/test.sh
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|banner |ERROR|SCRIPT"
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
```

Expected: `checks=532 failures=0`; one `MISSION test ...` line with its three `banner` lines and no errors — that is the proof `autostart` still starts a standalone mission; the digest exactly as in the Global Constraints.

Then check the shell itself runs a mission:

```bash
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn --audio-driver Dummy --resolution 1280x720 -- --seed=7 2>&1 | grep -E "ERROR|SCRIPT|WARNING" | head
```

Expected: no output at all (the window opens on a mission; close it). A `KAK screen ... has nothing to show yet` warning here means `go_to()` was called with a screen this task does not build yet — that is only correct at the end of a mission.

- [ ] **Step 7: Commit**

```bash
git add src/game/game.gd src/game/game.gd.uid src/game/mission.gd scenes/game.tscn tests/test_flow.gd tests/test_flow.gd.uid tests/run_all.gd
git commit -m "feat: the shell the screens live in" -m "Mission takes its loadout and seed from start() and reports how it ended through finished(), so something else can drive it, while autostart keeps the standalone scene, the scripted runs and the bench working exactly as before. Game holds one screen at a time and reads the flow from a table, which is what lets the whole screen flow be proved without building a screen." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 3: The draft

**Files:**
- Create: `src/game/draft.gd`
- Create: `src/game/ui/prepare_screen.gd`
- Modify: `src/game/ui/ui_theme.gd` (one helper: `wrap()`)
- Modify: `src/game/game.gd` (the Prepare branch, `--show` / `--capture`, start on Prepare)
- Create: `tests/test_draft.gd`
- Modify: `tests/run_all.gd`

**Why:** the draft is the one real decision a player makes before the mission, and the only screen whose rules are worth proving on their own: exactly four picks, the pick order is the slot order, and unpicking closes the gap. It lands before the title screen on purpose — after this task the game opens on Prepare and MANIFEST starts a mission, so the build is playable at every commit.

**One stated deviation from the spec's layout** (§5 puts 84×84 art on the cards): the cards carry the 42×42 HUD icons, and the 84×84 art is shown large, in the left panel, for the card under the mouse. Eleven cards with the big art and a readable name do not fit on a 640×360 screen; this way both sizes do what they are good at. Nothing else in the layout moves.

**Interfaces:**
- Consumes: `PowerBook.POWERS` (already in cost order, cheapest first), `PowerBook.icon(key)`, `PowerBook.hud_icon(key)`, `UiTheme`, `Rules.DP_MAX` / `DP_REGEN` / `MISSION_SECONDS` / `ESCAPE_LIMIT`, `Crowd.CITIZENS` / `SOLDIERS`, `SaveFile.best_score` / `best_rank`.
- Produces:
  - `Draft.new()`, `const SLOTS := 4`, `picks: PackedStringArray`, `toggle(key: String) -> void`, `slot_of(key: String) -> int` (1–4, or 0), `is_full() -> bool`, `preselect(keys: PackedStringArray) -> Draft`
  - `PrepareScreen.new()` (a `Node`), `setup(preselect: PackedStringArray, best_score: int, best_rank: String) -> PrepareScreen`, `draft: Draft`, `signal action(name: String)` — `"manifest"` or `"back"`, `static func cell_rect(i: int) -> Rect2`, `hit(point: Vector2) -> String` (a power key, `"manifest"`, or `""`)
  - `UiTheme.wrap(s: String, width: float, size := SIZE_BODY) -> PackedStringArray`
  - `Game`: `--show=<title|prepare|results|pause>` opens straight onto a screen, and `--capture` saves `captures/screen_<name>.png` a second later and quits

- [ ] **Step 1: Write the failing test**

Create `tests/test_draft.gd`:

```gdscript
extends RefCounted
## The draft's rules: four slots filled in pick order, a fifth pick refused, unpicking closes the gap, and a
## saved loadout comes back cleaned up.


static func run(t) -> void:
	var d := Draft.new()
	t.check(d.picks.is_empty() and not d.is_full(), "a new draft is empty")

	d.toggle("nova")
	d.toggle("heaven")
	d.toggle("cinder")
	t.check(d.slot_of("nova") == 1 and d.slot_of("heaven") == 2 and d.slot_of("cinder") == 3,
		"picks fill the slots in the order they were made (%s)" % [d.picks])
	t.check(not d.is_full(), "three picks is not a loadout")
	d.toggle("gravity")
	t.check(d.is_full() and d.slot_of("gravity") == 4, "the fourth pick fills it")
	d.toggle("tornado")
	t.check(d.picks.size() == 4 and d.slot_of("tornado") == 0, "a fifth pick is refused (%s)" % [d.picks])

	# Taking a pick back closes the gap: the later picks move up a slot.
	d.toggle("heaven")
	t.check(d.picks == PackedStringArray(["nova", "cinder", "gravity"]), "unpicking closes the gap (%s)" % [d.picks])
	t.check(d.slot_of("cinder") == 2 and d.slot_of("heaven") == 0, "so the slots renumber (%d, %d)" % [d.slot_of("cinder"), d.slot_of("heaven")])

	d.toggle("kettle")
	t.check(d.picks.size() == 3, "a key that is not a power cannot be picked (%s)" % [d.picks])

	# A saved loadout comes back in its own order, without strangers, doubles or a fifth power.
	var saved := Draft.new().preselect(PackedStringArray(["judgement", "kettle", "nova", "nova", "laser", "dragon", "heaven"]))
	t.check(saved.picks == PackedStringArray(["judgement", "nova", "laser", "dragon"]),
		"a saved loadout is cleaned up on the way in (%s)" % [saved.picks])
	t.check(Draft.new().preselect(PackedStringArray()).picks.is_empty(), "and an empty one gives an empty draft")

	# The Prepare screen's grid: eleven cards and the MANIFEST cell, none overlapping, all on screen.
	var screen := Rect2(0, 0, 640, 360)
	var overlaps := 0
	for i in 12:
		var a := PrepareScreen.cell_rect(i)
		if not screen.encloses(a):
			overlaps += 100
		for j in range(i + 1, 12):
			if a.intersects(PrepareScreen.cell_rect(j)):
				overlaps += 1
	t.check(overlaps == 0, "the twelve cells fit the screen without touching (%d)" % overlaps)

	# Wrapping keeps every line inside its width.
	var lines := UiTheme.wrap("Judgement of the Ancients", 60.0, UiTheme.SIZE_SMALL)
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, UiTheme.width(line, UiTheme.SIZE_SMALL))
	t.check(lines.size() >= 2 and widest <= 60.0, "a long name wraps inside its width (%s, %.0f px)" % [lines, widest])
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_draft.gd",` to `SUITES` after `"res://tests/test_flow.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_draft.gd` and `checks=533 failures=1`.

- [ ] **Step 3: Write the draft**

Create `src/game/draft.gd`:

```gdscript
class_name Draft
extends RefCounted
## The Prepare screen's rules (spec §1): the player picks exactly four of the eleven powers, and the order they
## pick them in is the order of slots 1-4. Picking a card again takes it back out, and the later picks move up
## a slot to close the gap.

const SLOTS := 4

## The picked power keys, in slot order.
var picks := PackedStringArray()


func toggle(key: String) -> void:
	var at := picks.find(key)
	if at >= 0:
		picks.remove_at(at)
	elif picks.size() < SLOTS and not PowerBook.get_power(key).is_empty():
		picks.append(key)


## The slot a power sits in, 1 to 4, or 0 when it is not picked.
func slot_of(key: String) -> int:
	return picks.find(key) + 1


func is_full() -> bool:
	return picks.size() == SLOTS


## Start from a saved loadout, in its own order: keys that are not powers, repeats and anything past the
## fourth are dropped.
func preselect(keys: PackedStringArray) -> Draft:
	picks = PackedStringArray()
	for key in keys:
		if not picks.has(key):
			toggle(key)
	return self
```

- [ ] **Step 4: Teach the theme to wrap**

In `src/game/ui/ui_theme.gd`, add after `width()`:

```gdscript
## A string broken into lines no wider than `width`, at word boundaries. A single word wider than the line is
## left whole on its own line rather than cut: the pixel font has no hyphenation worth reading.
static func wrap(s: String, line_width: float, size := SIZE_BODY) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in s.split(" ", false):
		var tried := word if line == "" else line + " " + word
		if line != "" and width(tried, size) > line_width:
			lines.append(line)
			line = word
		else:
			line = tried
	if line != "":
		lines.append(line)
	return lines
```

- [ ] **Step 5: Write the Prepare screen**

Create `src/game/ui/prepare_screen.gd`:

```gdscript
class_name PrepareScreen
extends Node
## Prepare (spec §1, §5): the briefing and the card under the mouse on the left, the eleven power cards in a
## grid on the right, and MANIFEST in the grid's twelfth cell once four are picked.
##
## One deviation from the spec's layout, forced by 640x360: the cards carry the 42-pixel HUD icons, and the
## 84-pixel card art is shown large in the left panel for the card under the mouse. Eleven cards with the big
## art and a readable name do not fit on this screen.

## "manifest" (four are picked and the player pressed MANIFEST or Enter) or "back" (Esc).
signal action(name: String)

const CARD := Vector2(140.0, 64.0)
const GAP := 6.0
const GRID_AT := Vector2(196.0, 40.0)
const COLUMNS := 3
## The left panel: briefing above, the card under the mouse below.
const PANEL := Rect2(8.0, 40.0, 180.0, 274.0)
const BADGE := 11.0

var draft := Draft.new()

var _ui: Control
## Both icon sizes, loaded once here and never inside _draw() (a texture loaded while drawing can reach the
## draw list before the GPU has it and paint a white block that stays).
var _icons := {}
var _art := {}
var _best_score := 0
var _best_rank := ""
## The power key under the mouse, "manifest", or "".
var _hover := ""


func setup(preselect: PackedStringArray, best_score: int, best_rank: String) -> PrepareScreen:
	draft.preselect(preselect)
	_best_score = best_score
	_best_rank = best_rank
	for p: Dictionary in PowerBook.POWERS:
		var key := String(p.key)
		_icons[key] = PowerBook.hud_icon(key)
		_art[key] = PowerBook.icon(key)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## Where cell `i` sits: 0-10 are the powers in PowerBook order, 11 is MANIFEST.
static func cell_rect(i: int) -> Rect2:
	var col := i % COLUMNS
	var row := i / COLUMNS
	return Rect2(GRID_AT + Vector2(float(col) * (CARD.x + GAP), float(row) * (CARD.y + GAP)), CARD)


## What is under a point: a power key, "manifest", or "".
func hit(point: Vector2) -> String:
	for i in PowerBook.POWERS.size():
		if cell_rect(i).has_point(point):
			return String(PowerBook.POWERS[i].key)
	if cell_rect(PowerBook.POWERS.size()).has_point(point):
		return "manifest"
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			action.emit("back")
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and draft.is_full():
			action.emit("manifest")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := hit(event.position)
		if h == "manifest":
			if draft.is_full():
				action.emit("manifest")
		elif h != "":
			draft.toggle(h)
			_ui.queue_redraw()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "PREPARE THE MANIFESTATION", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	if _best_score > 0:
		var best := "Best %d  %s" % [_best_score, _best_rank]
		UiTheme.text(_ui, Vector2(632.0 - UiTheme.width(best, UiTheme.SIZE_SMALL), 24.0), best, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_draw_panel()
	for i in PowerBook.POWERS.size():
		_draw_card(i)
	_draw_manifest()


func _draw_panel() -> void:
	_ui.draw_rect(PANEL, UiTheme.COL_PANEL)
	var brief := [
		["TARGET", "Aldermere and its Royal Citadel"],
		["WIN", "Bring down the Citadel and break the city before %s" % UiTheme.clock(Rules.MISSION_SECONDS)],
		["LOSE", "%d citizens escape, or the time runs out" % Rules.ESCAPE_LIMIT],
		["CITY", "%d citizens, %d soldiers, a nine-part fortress" % [Crowd.CITIZENS, Crowd.SOLDIERS]],
		["POWER", "%d DP, +%.1f a second; towers, gates, soldiers and chains pay back" % [int(Rules.DP_MAX), Rules.DP_REGEN]],
	]
	var y := PANEL.position.y + 10.0
	for pair: Array in brief:
		UiTheme.text(_ui, Vector2(PANEL.position.x + 4.0, y), String(pair[0]), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		for line in UiTheme.wrap(String(pair[1]), PANEL.size.x - 48.0, UiTheme.SIZE_SMALL):
			UiTheme.text(_ui, Vector2(PANEL.position.x + 44.0, y), line, UiTheme.SIZE_SMALL)
			y += 9.0
		y += 3.0
	# The card under the mouse, with its big art.
	var p := PowerBook.get_power(_hover)
	if p.is_empty():
		UiTheme.text(_ui, Vector2(PANEL.position.x + 4.0, PANEL.end.y - 8.0), "Pick four powers, in the order you want them", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		return
	var art_at := Vector2(PANEL.position.x + 4.0, PANEL.end.y - 92.0)
	var art: Texture2D = _art.get(_hover)
	if art != null:
		_ui.draw_texture_rect(art, Rect2(art_at, Vector2(84, 84)), false)
		UiTheme.frame(_ui, Rect2(art_at, Vector2(84, 84)), true)
	var tx := art_at.x + 92.0
	var ty := art_at.y + 8.0
	for line in UiTheme.wrap(String(p.name), PANEL.end.x - tx - 4.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		ty += 9.0
	ty += 3.0
	for line in ["%d DP" % int(p.dp), "%d s cooldown" % int(p.cooldown), "aim: %s" % String(p.aim)]:
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL)
		ty += 9.0
	for line in UiTheme.wrap(String(p.shape), PANEL.end.x - tx - 4.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		ty += 9.0


func _draw_card(i: int) -> void:
	var p: Dictionary = PowerBook.POWERS[i]
	var key := String(p.key)
	var r := cell_rect(i)
	var slot := draft.slot_of(key)
	_ui.draw_rect(r, UiTheme.COL_PANEL if key != _hover else Color(0.1, 0.09, 0.07, 0.9))
	var icon: Texture2D = _icons.get(key)
	if icon != null:
		_ui.draw_texture_rect(icon, Rect2(r.position + Vector2(4, 4), Vector2(42, 42)), false)
	# Gold for a picked card (spec §5), so the four read at a glance across the grid.
	UiTheme.frame(_ui, r, slot > 0)
	var tx := r.position.x + 52.0
	var ty := r.position.y + 13.0
	for line in UiTheme.wrap(String(p.name), CARD.x - 56.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if slot > 0 else UiTheme.COL_TEXT)
		ty += 9.0
	UiTheme.text(_ui, Vector2(tx, r.position.y + 42.0), "%d DP  %d s" % [int(p.dp), int(p.cooldown)], UiTheme.SIZE_SMALL)
	# The shape's first clause is short enough for the card; the whole of it is in the left panel.
	var short := String(p.shape).split(",")[0]
	UiTheme.text(_ui, Vector2(r.position.x + 4.0, r.end.y - 5.0), short, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	if slot > 0:
		var badge := Rect2(Vector2(r.end.x - BADGE - 3.0, r.position.y + 3.0), Vector2(BADGE, BADGE))
		_ui.draw_rect(badge, UiTheme.COL_GOLD)
		UiTheme.text(_ui, badge.position + Vector2(3.0, 9.0), "%d" % slot, UiTheme.SIZE_SMALL, Color(0.08, 0.06, 0.02))


func _draw_manifest() -> void:
	var r := cell_rect(PowerBook.POWERS.size())
	var full := draft.is_full()  # not "ready": that is Node's own signal, and shadowing it warns
	_ui.draw_rect(r, Color(0.12, 0.1, 0.04, 0.95) if full else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, full and _hover == "manifest")
	var label := "MANIFEST"
	var col := UiTheme.COL_GOLD if full else UiTheme.COL_DIM
	UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(label, UiTheme.SIZE_BIG) * 0.5), r.position.y + 30.0), label, UiTheme.SIZE_BIG, col)
	var count := "loadout %d / %d" % [draft.picks.size(), Draft.SLOTS]
	UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(count, UiTheme.SIZE_SMALL) * 0.5), r.position.y + 46.0), count, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
```

- [ ] **Step 6: Put the draft in the game**

In `src/game/game.gd`, replace `_ready()` with:

```gdscript
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
			# The title screen arrives in Task 4; until then the game opens on the draft.
			go_to(Screen.PREPARE)
	if "--capture" in args:
		# A second for anything behind the screen to settle, then one frame to disk. This is how each screen
		# task shows its work: SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture
		await get_tree().create_timer(1.0).timeout
		await _capture("screen_%s.png" % (show if show != "" else "start"))
		get_tree().quit()
```

In `go_to()`'s `match`, add a branch before the default one:

```gdscript
		Screen.PREPARE:
			var prep := PrepareScreen.new()
			prep.name = "Prepare"
			add_child(prep)
			prep.setup(loadout, save.best_score, save.best_rank)
			prep.action.connect(_on_prepare_action.bind(prep))
			_screen_node = prep
```

and add:

```gdscript
func _on_prepare_action(what: String, prep: PrepareScreen) -> void:
	if what == "manifest":
		loadout = prep.draft.picks
		save.remember_loadout(loadout)
		save.save_to()
	on_action("prepare:" + what)


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
```

- [ ] **Step 7: Run the tests and look at the screen**

```bash
bash tools/test.sh
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture 2>&1 | grep -E "captured|ERROR|SCRIPT"
```

Expected: `checks=544 failures=0`; one `captured .../captures/screen_prepare.png` line and no errors.

The saved loadout is preselected, so if your `user://kak_save.cfg` is empty the screen shows no picks. Look at `captures/screen_prepare.png` with the Read tool and describe it concretely in your report:
- the title and (if there is a best score) the best line along the top;
- the briefing in the left panel — five labelled entries, every line inside the panel;
- the eleven cards in a 3-column grid, each with its icon, a name that fits (two lines at most), the DP and cooldown, and the short shape along the bottom;
- the MANIFEST cell dim, reading "loadout n / 4".

Then pick four and look again — the capture has no mouse, so do it by hand: run `/f/Godot/Godot_v4.7.2-stable_win64.exe --path . --scene res://scenes/game.tscn`, click four cards, hover one, and say what you saw (gold frames and 1–4 badges on the picks in click order, the hovered card's 84×84 art in the left panel, MANIFEST lit; clicking it starts a mission). If you cannot run a window, say so rather than guessing.

- [ ] **Step 8: Commit**

```bash
git add src/game/draft.gd src/game/draft.gd.uid src/game/ui/prepare_screen.gd src/game/ui/prepare_screen.gd.uid src/game/ui/ui_theme.gd src/game/game.gd tests/test_draft.gd tests/test_draft.gd.uid tests/run_all.gd
git commit -m "feat: the draft" -m "Prepare shows the briefing, the eleven power cards and MANIFEST, and the player picks exactly four in the order they want them in slots 1 to 4; picking a card again takes it back out and closes the gap. The last loadout comes back preselected. The cards carry the 42-pixel icons and the card under the mouse shows its 84-pixel art in the left panel, because eleven big cards with readable names do not fit at 640x360. The game opens on Prepare until the title screen lands, and --show / --capture let each screen be photographed on its own." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Buttons, and the title

**Files:**
- Create: `src/game/ui/menu.gd`
- Create: `src/game/ui/title_screen.gd`
- Modify: `src/game/ui/ui_theme.gd` (one constant: `SIZE_TITLE`)
- Modify: `src/game/game.gd` (the Title branch, start on the title)
- Create: `tests/test_menu.gd`
- Modify: `tests/run_all.gd`

**Why:** the title is the first thing anyone sees, and the three screens after it — Title, Results, Pause — all need the same thing: a few buttons that look like the rest of the game and know which one the mouse is over. `Menu` is that, written once and proved once. The title's backdrop is the real town, built without its people, drifting slowly past (spec §1).

**Interfaces:**
- Consumes: `Battlefield`, `Town`, `UiTheme`, `Iso`.
- Produces:
  - `Menu.new()`, `add(action: String, label: String, rect: Rect2) -> Menu`, `static column(actions: Array, labels: Array, centre_x: float, top: float, width: float, gap := 6.0) -> Menu`, `static row(actions: Array, labels: Array, centre_x: float, top: float, width: float, gap := 8.0) -> Menu`, `at(point: Vector2) -> String`, `rect_of(action: String) -> Rect2`, `draw_on(on: CanvasItem, hover: String, dim := PackedStringArray()) -> void`, `const HEIGHT := 18.0`
  - `TitleScreen.new()` (a `Node`), `setup(best_score: int, best_rank: String) -> TitleScreen`, `signal action(name: String)` — `"play"`, `"sandbox"` or `"quit"`
  - `UiTheme.SIZE_TITLE := 32`

- [ ] **Step 1: Write the failing test**

Create `tests/test_menu.gd`:

```gdscript
extends RefCounted
## Buttons: laid out in a column or a row without touching, centred where asked, and the point under the
## mouse maps to the right one -- or to none, between them.


static func run(t) -> void:
	var col := Menu.column(["play", "sandbox", "quit"], ["Play", "VFX Sandbox", "Quit"], 320.0, 200.0, 120.0)
	t.check(col.items.size() == 3, "a column of three buttons (%d)" % col.items.size())
	var a := col.rect_of("play")
	var b := col.rect_of("sandbox")
	var c := col.rect_of("quit")
	t.check(a.end.y < b.position.y and b.end.y < c.position.y, "stacked top to bottom, with a gap between")
	t.near(a.get_center().x, 320.0, 0.51, "centred on the x it was given (%.1f)" % a.get_center().x)
	t.near(a.size.y, Menu.HEIGHT, 0.001, "every button is one height")

	t.check(col.at(b.get_center()) == "sandbox", "the point over a button is that button (%s)" % col.at(b.get_center()))
	t.check(col.at(Vector2(320.0, a.end.y + 2.0)) == "", "the gap between two buttons is nobody's")
	t.check(col.at(Vector2(10.0, 10.0)) == "", "and so is the rest of the screen")
	t.check(col.rect_of("nothing") == Rect2(), "an action the menu does not have has no rect")

	var row := Menu.row(["replay", "change", "title"], ["Replay", "Change powers", "Title"], 320.0, 300.0, 100.0)
	var left := row.rect_of("replay")
	var right := row.rect_of("title")
	t.check(left.end.x < row.rect_of("change").position.x and row.rect_of("change").end.x < right.position.x,
		"a row runs left to right without touching")
	t.near((left.position.x + right.end.x) * 0.5, 320.0, 0.51, "and is centred as a whole")
	t.check(row.at(right.get_center()) == "title", "the last one answers to its own point")
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_menu.gd",` to `SUITES` after `"res://tests/test_draft.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_menu.gd` and `checks=545 failures=1`.

- [ ] **Step 3: Write the buttons**

Create `src/game/ui/menu.gd`:

```gdscript
class_name Menu
extends RefCounted
## A handful of pixel buttons: where each one is, which one a point is over, and how they draw. Title, Results
## and Pause all use it, so every button in the game looks and answers the same way.

const HEIGHT := 18.0

## One entry per button: {"action": String, "label": String, "rect": Rect2}.
var items: Array[Dictionary] = []


func add(action: String, label: String, rect: Rect2) -> Menu:
	items.append({"action": action, "label": label, "rect": rect})
	return self


## Buttons stacked downward from `top`, each `width` wide, centred on `centre_x`.
static func column(actions: Array, labels: Array, centre_x: float, top: float, width: float, gap := 6.0) -> Menu:
	var m := Menu.new()
	for i in actions.size():
		m.add(String(actions[i]), String(labels[i]),
			Rect2(roundf(centre_x - width * 0.5), top + float(i) * (HEIGHT + gap), width, HEIGHT))
	return m


## Buttons side by side at `top`, each `width` wide, the whole row centred on `centre_x`.
static func row(actions: Array, labels: Array, centre_x: float, top: float, width: float, gap := 8.0) -> Menu:
	var m := Menu.new()
	var total := float(actions.size()) * width + float(maxi(actions.size() - 1, 0)) * gap
	var left := roundf(centre_x - total * 0.5)
	for i in actions.size():
		m.add(String(actions[i]), String(labels[i]), Rect2(left + float(i) * (width + gap), top, width, HEIGHT))
	return m


## The action under a point, or "" between and around the buttons.
func at(point: Vector2) -> String:
	for item: Dictionary in items:
		if (item.rect as Rect2).has_point(point):
			return String(item.action)
	return ""


func rect_of(action: String) -> Rect2:
	for item: Dictionary in items:
		if String(item.action) == action:
			return item.rect
	return Rect2()


## Every button: a dark panel, the gold frame bright under the mouse, the label centred. `dim` names buttons
## that are shown but cannot be pressed yet.
func draw_on(on: CanvasItem, hover: String, dim := PackedStringArray()) -> void:
	for item: Dictionary in items:
		var r: Rect2 = item.rect
		var action := String(item.action)
		var off := dim.has(action)
		on.draw_rect(r, Color(0.04, 0.04, 0.06, 0.85))
		UiTheme.frame(on, r, action == hover and not off)
		var label := String(item.label)
		var col := UiTheme.COL_DIM if off else (UiTheme.COL_GOLD if action == hover else UiTheme.COL_TEXT)
		UiTheme.text(on, Vector2(roundf(r.get_center().x - UiTheme.width(label) * 0.5), r.position.y + 13.0),
			label, UiTheme.SIZE_BODY, col)
```

- [ ] **Step 4: Write the title**

In `src/game/ui/ui_theme.gd`, add after `const SIZE_BIG := 16`:

```gdscript
## The game's name on the title screen and the ending on the results screen.
const SIZE_TITLE := 32
```

Create `src/game/ui/title_screen.gd`:

```gdscript
class_name TitleScreen
extends Node
## The title (spec §1, §5): "KINGDOMS AMID KATACLYSM" with "KAK" small, over the town of Aldermere drifting
## slowly past, and three ways on: Play, the VFX Sandbox, Quit. The town is the real one, built without its
## people -- nothing here needs a crowd, and nothing here should cost a frame.

## "play", "sandbox" or "quit".
signal action(name: String)

## One slow loop of the camera every 1 / DRIFT_SPEED seconds, this far each way (screen pixels).
const DRIFT_SPEED := 0.02
const DRIFT := Vector2(240.0, 60.0)
const ZOOM := 0.7
## The band the title sits on, so it reads over any part of the town.
const BAND := Rect2(0.0, 76.0, 640.0, 88.0)

var _bf: Battlefield
var _town: Town
var _ui: Control
var _menu: Menu
var _hover := ""
var _best_score := 0
var _best_rank := ""
var _t := 0.0


func setup(best_score: int, best_rank: String) -> TitleScreen:
	_best_score = best_score
	_best_rank = best_rank
	_bf = Battlefield.new()
	_bf.name = "Backdrop"
	add_child(_bf)
	_bf.reset(7)
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_bf.camera.zoom = Vector2.ONE * ZOOM
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.column(["play", "sandbox", "quit"], ["Play", "VFX Sandbox", "Quit"], 320.0, 206.0, 132.0)
	return self


func _process(delta: float) -> void:
	_t += delta
	var base := Iso.ground_to_screen(Vector2(0.0, -1.0))
	var phase := _t * DRIFT_SPEED * TAU
	_bf.camera.position = (base + Vector2(sin(phase) * DRIFT.x, sin(phase * 0.7) * DRIFT.y)).round()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			action.emit("play")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a != "":
			action.emit(a)


func _draw_ui() -> void:
	_ui.draw_rect(BAND, Color(0.02, 0.02, 0.04, 0.66))
	_ui.draw_line(BAND.position, Vector2(BAND.end.x, BAND.position.y), UiTheme.COL_GOLD_DARK, -1.0)
	_ui.draw_line(Vector2(BAND.position.x, BAND.end.y), BAND.end, UiTheme.COL_GOLD_DARK, -1.0)
	var title := "KINGDOMS AMID KATACLYSM"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 128.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	var small := "KAK"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(small) * 0.5), 150.0), small, UiTheme.SIZE_BODY, UiTheme.COL_DIM)
	_menu.draw_on(_ui, _hover)
	if _best_score > 0:
		var best := "Best %d  %s" % [_best_score, _best_rank]
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(best, UiTheme.SIZE_SMALL) * 0.5), 290.0), best,
			UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
```

- [ ] **Step 5: Open on the title**

In `src/game/game.gd`'s `_ready()`, replace the whole `match show:` block with:

```gdscript
	match show:
		"prepare":
			go_to(Screen.PREPARE)
		_:
			go_to(Screen.TITLE)
```

In `go_to()`'s `match`, add:

```gdscript
		Screen.TITLE:
			var title := TitleScreen.new()
			title.name = "Title"
			add_child(title)
			title.setup(save.best_score, save.best_rank)
			title.action.connect(_on_title_action)
			_screen_node = title
```

and add:

```gdscript
const SANDBOX_SCENE := "res://scenes/sandbox.tscn"


func _on_title_action(what: String) -> void:
	match what:
		"sandbox":
			get_tree().change_scene_to_file(SANDBOX_SCENE)
		"quit":
			get_tree().quit()
		_:
			on_action("title:" + what)
```

(put the constant next to `MISSION_SCENE`).

- [ ] **Step 6: Run the tests and look at the screen**

```bash
bash tools/test.sh
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=title --capture 2>&1 | grep -E "captured|ERROR|SCRIPT"
```

Expected: `checks=555 failures=0`; one `captured .../screen_title.png` line, no errors.

Look at `captures/screen_title.png` and describe it: the town behind (walls, houses, the Citadel — and no people), the dark band with "KINGDOMS AMID KATACLYSM" in gold and "KAK" small under it, the three buttons in a column below, all inside the screen and centred. Then run the game windowed and check by hand that the town drifts slowly, that the buttons light under the mouse, that Play reaches Prepare, that VFX Sandbox opens the sandbox, and that Quit quits.

- [ ] **Step 7: Commit**

```bash
git add src/game/ui/menu.gd src/game/ui/menu.gd.uid src/game/ui/title_screen.gd src/game/ui/title_screen.gd.uid src/game/ui/ui_theme.gd src/game/game.gd tests/test_menu.gd tests/test_menu.gd.uid tests/run_all.gd
git commit -m "feat: the title screen" -m "Kingdoms Amid Kataclysm over the real town of Aldermere, built without its people and drifting slowly past, with Play, the VFX Sandbox and Quit. Menu is the button set every screen after this one uses: where each button is, which one the mouse is over, and one look for all of them. The game now opens on the title." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 5: Results

**Files:**
- Create: `src/game/ui/results_screen.gd`
- Modify: `src/game/ui/ui_theme.gd` (one constant: `SIZE_HUGE`)
- Modify: `src/game/game.gd` (the Results branch, `--show=results`)
- Create: `tests/test_results.gd`
- Modify: `tests/run_all.gd`

**Why:** the payoff for four minutes of destruction, drawn over the frozen ruins the player made. Everything on it already exists — `Rules.stat_lines()` has been producing the table since milestone 3, and `SaveFile.record()` knows whether it is a new best — so this task is the look and the three ways on.

**Interfaces:**
- Consumes: `Game.result` — `{"won": bool, "reason": String, "score": int, "rank": String, "lines": Array[Dictionary], "best": bool}`, each line `{"label", "value", "points"}` from `Rules.stat_lines()`; `Menu`; `UiTheme`.
- Produces:
  - `ResultsScreen.new()` (a `Node`), `setup(result: Dictionary) -> ResultsScreen`, `signal action(name: String)` — `"replay"`, `"change"` or `"title"`
  - `static func title_for(won: bool, reason: String) -> String`
  - `static func thousands(n: int) -> String` — `12450` → `"12,450"`
  - `UiTheme.SIZE_HUGE := 64`

- [ ] **Step 1: Write the failing test**

Create `tests/test_results.gd`:

```gdscript
extends RefCounted
## The Results screen's words: the right ending for each way a mission ends, and scores written the way the
## spec writes them.


static func run(t) -> void:
	t.check(ResultsScreen.title_for(true, "citadel") == "THE CITY HAS FALLEN", "a win reads THE CITY HAS FALLEN")
	t.check(ResultsScreen.title_for(false, "escapes") == "THE PEOPLE ESCAPED", "the escape reads THE PEOPLE ESCAPED")
	t.check(ResultsScreen.title_for(false, "timeout") == "MANIFESTATION ENDED", "the clock reads MANIFESTATION ENDED")

	t.check(ResultsScreen.thousands(12450) == "12,450", "scores get a thousands comma (%s)" % ResultsScreen.thousands(12450))
	t.check(ResultsScreen.thousands(999) == "999" and ResultsScreen.thousands(0) == "0", "small ones do not")
	t.check(ResultsScreen.thousands(1234567) == "1,234,567", "and big ones get every comma (%s)" % ResultsScreen.thousands(1234567))
	t.check(ResultsScreen.thousands(-3000) == "-3,000", "a negative keeps its sign in front (%s)" % ResultsScreen.thousands(-3000))
```

- [ ] **Step 2: Register it and run it to see it fail**

In `tests/run_all.gd`, add `"res://tests/test_results.gd",` to `SUITES` after `"res://tests/test_menu.gd",`.

Run: `bash tools/test.sh`
Expected: `FAIL: suite failed to load: res://tests/test_results.gd` and `checks=556 failures=1`.

- [ ] **Step 3: Write the Results screen**

In `src/game/ui/ui_theme.gd`, add after `SIZE_TITLE`:

```gdscript
## The rank letter on the results screen.
const SIZE_HUGE := 64
```

Create `src/game/ui/results_screen.gd`:

```gdscript
class_name ResultsScreen
extends Node
## Results (spec §5): the ending in gold for a win or red for a loss, the big rank letter, the score, NEW BEST!
## when it is one, the stat table with what each line was worth, and Replay / Change powers / Title. It is drawn
## over the mission's frozen ruins, which Game keeps up underneath it.

## "replay" (the same four powers again), "change" (back to the draft) or "title".
signal action(name: String)

const PANEL := Rect2(36.0, 20.0, 568.0, 320.0)
## The stat table's columns: label, value (right-aligned), points (right-aligned).
const TABLE_X := 300.0
const VALUE_R := 500.0
const POINTS_R := 588.0
const ROW := 12.0

var _result := {}
var _ui: Control
var _menu: Menu
var _hover := ""


## The line across the top for each way a mission can end.
static func title_for(won: bool, reason: String) -> String:
	if won:
		return "THE CITY HAS FALLEN"
	return "THE PEOPLE ESCAPED" if reason == "escapes" else "MANIFESTATION ENDED"


## 12450 -> "12,450".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


func setup(result: Dictionary) -> ResultsScreen:
	_result = result
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.row(["replay", "change", "title"], ["Replay", "Change powers", "Title"], 320.0, PANEL.end.y - 28.0, 120.0)
	return self


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			action.emit("replay")
		elif event.physical_keycode == KEY_ESCAPE:
			action.emit("title")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a != "":
			action.emit(a)


func _draw_ui() -> void:
	var won := bool(_result.get("won", false))
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.5))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.9))
	UiTheme.frame(_ui, PANEL, true)

	var title := title_for(won, String(_result.get("reason", "")))
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 60.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD if won else UiTheme.COL_BAD)

	# The rank on the left, big, with the score beside it.
	var rank := String(_result.get("rank", "D"))
	UiTheme.text(_ui, Vector2(64.0, 162.0), rank, UiTheme.SIZE_HUGE, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(66.0, 176.0), "RANK", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(132.0, 102.0), "SCORE", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(130.0, 132.0), thousands(int(_result.get("score", 0))), UiTheme.SIZE_TITLE)
	if bool(_result.get("best", false)):
		UiTheme.text(_ui, Vector2(132.0, 154.0), "NEW BEST!", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)

	# The stat table: what happened, and what each line was worth.
	var y := 100.0
	var total := 0
	for line: Dictionary in _result.get("lines", []):
		var label := String(line.label)
		var value := String(line.value)
		var points := int(line.points)
		total += points
		UiTheme.text(_ui, Vector2(TABLE_X, y), label, UiTheme.SIZE_SMALL)
		if value != "":
			UiTheme.text(_ui, Vector2(VALUE_R - UiTheme.width(value, UiTheme.SIZE_SMALL), y), value, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		var pts := thousands(points)
		UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(pts, UiTheme.SIZE_SMALL), y), pts, UiTheme.SIZE_SMALL,
			UiTheme.COL_TEXT if points > 0 else UiTheme.COL_DIM)
		y += ROW
	_ui.draw_line(Vector2(TABLE_X, y - 7.0), Vector2(POINTS_R, y - 7.0), UiTheme.COL_GOLD_DARK, -1.0)
	var sum := thousands(total)
	UiTheme.text(_ui, Vector2(TABLE_X, y + 4.0), "Total", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(sum, UiTheme.SIZE_SMALL), y + 4.0), sum, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)

	_menu.draw_on(_ui, _hover)
```

- [ ] **Step 4: Show it after a mission**

In `src/game/game.gd`, replace the `Screen.RESULTS:` branch of `go_to()` with:

```gdscript
		Screen.RESULTS:
			if is_instance_valid(_mission):
				_mission.set_frozen(true)
			var res := ResultsScreen.new()
			res.name = "Results"
			add_child(res)
			res.setup(result)
			res.action.connect(func(what: String) -> void: on_action("results:" + what))
			_screen_node = res
```

Add a canned result next to the other constants, so the screen can be photographed without playing a mission:

```gdscript
## What --show=results displays: a winning run with every line of the table in use.
const SAMPLE_RESULT := {
	"won": true, "reason": "citadel", "score": 16350, "rank": "S", "best": true,
	"lines": [
		{"label": "The city has fallen", "value": "", "points": 5000},
		{"label": "Time left", "value": "3:20", "points": 5000},
		{"label": "Divine Power left", "value": "100", "points": 1000},
		{"label": "Buildings destroyed", "value": "60", "points": 2400},
		{"label": "Citizens killed", "value": "110", "points": 1100},
		{"label": "Soldiers killed", "value": "50", "points": 1250},
		{"label": "Citizens escaped", "value": "0", "points": 0},
		{"label": "Chains", "value": "2", "points": 600},
	],
}
```

and in `_ready()`'s `match show:` add:

```gdscript
		"results":
			result = SAMPLE_RESULT.duplicate(true)
			go_to(Screen.RESULTS)
```

- [ ] **Step 5: Run the tests and look at the screen**

```bash
bash tools/test.sh
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=results --capture 2>&1 | grep -E "captured|ERROR|SCRIPT"
```

Expected: `checks=562 failures=0`; one `captured .../screen_results.png` line, no errors. (`--show=results` has no mission underneath, so the capture is the screen over the clear colour — correct for this photograph.)

Look at `captures/screen_results.png` and describe it: "THE CITY HAS FALLEN" in gold across the top, inside the panel; the big S with RANK under it; SCORE 16,350 and NEW BEST! beside it; eight table rows with their values and points in straight right-aligned columns and a Total of 16,350; the three buttons in a row along the bottom, inside the panel. Name anything that overlaps or runs past the panel edge.

Then check the real thing by hand: play a mission to its end (the quickest is to let the clock run out — or start with `-- --seed=7` and Nova the Citadel repeatedly), and confirm Results appears **over the frozen town**, that Replay starts the same four powers, that Change powers opens the draft with them preselected, and that Title goes home. If you cannot run a window, say so.

- [ ] **Step 6: Commit**

```bash
git add src/game/ui/results_screen.gd src/game/ui/results_screen.gd.uid src/game/ui/ui_theme.gd src/game/game.gd tests/test_results.gd tests/test_results.gd.uid tests/run_all.gd
git commit -m "feat: the results screen" -m "The ending in gold for a win or red for a loss, the rank letter, the score with NEW BEST! when it is one, and the stat table with what each line earned, drawn over the frozen ruins of the mission that produced it. Replay runs the same four powers again, Change powers returns to the draft with them preselected, and Title goes home. --show=results photographs it with a canned winning run." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Pause

**Files:**
- Create: `src/game/ui/pause_menu.gd`
- Modify: `src/game/game.gd` (open and close the pause menu, `--show=pause`)

**Why:** a four-minute mission needs a way to stop. The pause menu sits over the mission rather than replacing it, which is why it is not one of `Game`'s screens: Resume has to give back *that* mission, not build a new one.

**Interfaces:**
- Consumes: `Mission.pause_pressed`, `Mission.set_frozen(frozen)` (Task 2), `Menu` (Task 4).
- Produces: `PauseMenu.new()` (a `Node`), `setup() -> PauseMenu`, `signal action(name: String)` — `"resume"`, `"restart"`, `"change"` or `"title"`.

- [ ] **Step 1: Write the pause menu**

Create `src/game/ui/pause_menu.gd`:

```gdscript
class_name PauseMenu
extends Node
## Pause (spec §1): the mission frozen underneath, and Resume, Restart, Change powers, Title. Esc resumes, the
## way it paused. This node lives beside the mission, not inside it, so it keeps running while the mission is
## switched off.

## "resume", "restart" (a new mission with the same four powers), "change" (back to the draft) or "title".
signal action(name: String)

var _ui: Control
var _menu: Menu
var _hover := ""


func setup() -> PauseMenu:
	var layer := CanvasLayer.new()
	layer.layer = 20  # over the HUD
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.column(["resume", "restart", "change", "title"], ["Resume", "Restart", "Change powers", "Title"],
		320.0, 148.0, 140.0)
	return self


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		action.emit("resume")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a != "":
			action.emit(a)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.55))
	var title := "PAUSED"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 126.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	_menu.draw_on(_ui, _hover)
```

- [ ] **Step 2: Open it from the mission**

In `src/game/game.gd`, add next to `_screen_node`:

```gdscript
## The pause menu, while it is up. It sits over the mission instead of replacing it.
var _pause: PauseMenu
```

In `_build_mission()`, after `mission.finished.connect(...)`:

```gdscript
	mission.pause_pressed.connect(_open_pause)
```

At the top of `go_to()`, before anything else, close the menu — every screen change leaves it behind:

```gdscript
	_close_pause()
```

In `on_action()`, handle Resume before the table: it stays in the mission that is already there.

```gdscript
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
	go_to(to)
```

And add:

```gdscript
func _open_pause() -> void:
	if is_instance_valid(_pause) or not is_instance_valid(_mission):
		return
	_mission.set_frozen(true)
	_pause = PauseMenu.new()
	_pause.name = "Pause"
	add_child(_pause)
	_pause.setup()
	_pause.action.connect(func(what: String) -> void: on_action("pause:" + what))


func _close_pause() -> void:
	if is_instance_valid(_pause):
		_pause.queue_free()
	_pause = null
```

and in `_ready()`'s `match show:`:

```gdscript
		"pause":
			go_to(Screen.MISSION)
			_open_pause()
```

- [ ] **Step 3: Run the tests and look at the screen**

```bash
bash tools/test.sh
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=pause --capture 2>&1 | grep -E "captured|ERROR|SCRIPT"
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|ERROR|SCRIPT"
```

Expected: `checks=562 failures=0` (this task adds no suite — the flow is already proved by `test_flow.gd`, and the rest is behaviour in a window); one `captured .../screen_pause.png`; one `MISSION test ...` line, unchanged in shape.

Look at `captures/screen_pause.png`: the town and the HUD dimmed underneath, PAUSED in gold, four buttons in a column. Then by hand, in a window: start a mission, press Esc — the clock must stop (read the HUD's time, wait five seconds, read it again), the crowd and any running effect must freeze, and a click on the town must not cast. Resume must carry on from the same second. Restart must be a fresh town with the same four powers. Change powers must open the draft. Esc on the pause menu resumes. Report each of these as seen or not.

- [ ] **Step 4: Commit**

```bash
git add src/game/ui/pause_menu.gd src/game/ui/pause_menu.gd.uid src/game/game.gd
git commit -m "feat: pause" -m "Esc in a mission freezes it -- the clock, the crowd and every running effect -- under Resume, Restart, Change powers and Title. The menu sits beside the mission rather than replacing it, so Resume gives back the same mission from the same second, and Esc resumes the way it paused." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---
### Task 7: The intro, and the game as the front door

**Files:**
- Modify: `src/game/mission.gd` (the 2 s intro sweep)
- Modify: `project.godot` (`run/main_scene`)
- Modify: `tools/capture.sh` (default to the sandbox scene)
- Modify: `play.bat`
- Modify: `README.md`

**Why:** two things finish the milestone. The spec opens every mission with a two-second camera sweep to the Citadel under a MANIFEST banner before the clock starts, and the game has to become what opens when someone runs the project. The second one has a trap in it: `tools/capture.sh` and `tools/dev/sandbox_baseline.sh` run the **default** scene when no `SCENE=` is given, and today that default is the sandbox. Changing the main scene without pinning the tool would silently turn every sandbox capture and the behaviour baseline into captures of the title screen.

**Interfaces:**
- Consumes: `Mission.start()`, `Rules` (its `_process` drives the clock), `Rules.banner`, `TownLayout.CITADEL_ORIGIN`.
- Produces: `Mission.INTRO_SECONDS := 2.0`; `Mission.in_intro() -> bool`.

- [ ] **Step 1: Pin the tools to the sandbox before anything moves**

In `tools/capture.sh`, replace:

```bash
if [[ -n "$SCENE" ]]; then EXTRA+=(--scene "$SCENE"); fi
```

with:

```bash
# The project's main scene is the game; every capture and bench written before milestone 4 means the sandbox.
EXTRA+=(--scene "${SCENE:-res://scenes/sandbox.tscn}")
```

and update the usage comment at the top of the file to say that no `SCENE=` means the sandbox.

- [ ] **Step 2: Make the game the main scene**

In `project.godot`, change:

```
run/main_scene="res://scenes/sandbox.tscn"
```

to:

```
run/main_scene="res://scenes/game.tscn"
```

In `play.bat`, change the scene on the `start` line to `res://scenes/game.tscn`, and the comment line to `rem Play Kingdoms Amid Kataclysm from its title screen. ...` (keep the rest of the comment and the whole of the rest of the file).

Verify nothing that meant the sandbox now means the game:

```bash
bash tools/dev/sandbox_baseline.sh captures/m4_task7
python tools/dev/compare_captures.py captures/m1_base_a captures/m4_task7 'idle.png'
```

Expected: `frames: ...` as before, and `idle.png` `worst_mean_diff=0.000`. A non-zero diff here, or an idle frame that shows the title screen, means Step 1 did not take.

- [ ] **Step 3: The intro sweep**

In `src/game/mission.gd`, add next to the other constants:

```gdscript
## The mission opens with the camera sweeping in to the Citadel under a MANIFEST banner, and the clock only
## starts when it arrives (spec §1).
const INTRO_SECONDS := 2.0
## Where the sweep starts: the whole town, from further out.
const INTRO_FROM := Vector2(0.0, 3.0)
const INTRO_FROM_ZOOM := 0.5
## Where the camera rests for play, and how close.
const PLAY_ZOOM := 0.75
```

and next to the other state:

```gdscript
## Seconds of intro left; 0 once the mission is under way.
var _intro_left := 0.0
```

In `_ready()`, **delete** the two lines that set the camera (`_bf.camera.zoom = Vector2.ONE * 0.75` and `_bf.camera.position = Iso.ground_to_screen(Vector2(0, -2)).round()`): the camera now belongs to `start()`, because `Game` calls `start()` after `_ready()` has run and anything `_ready()` set would be overwritten half-way through the sweep.

At the end of `start()`, add:

```gdscript
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


func in_intro() -> bool:
	return _intro_left > 0.0
```

In `_process(delta)`, directly after its opening `if not started(): return` guard (added after Task 2 by commit
`c70815e` — a mission driven by `Game` exists for a few frames before `start()` has built anything) and before
the panning:

```gdscript
	if _intro_left > 0.0:
		_intro_left = maxf(0.0, _intro_left - delta)
		var k := 1.0 - _intro_left / INTRO_SECONDS
		var smooth := k * k * (3.0 - 2.0 * k)  # not "ease": that is a global function, and shadowing it warns
		_bf.camera.position = Iso.ground_to_screen(INTRO_FROM.lerp(TownLayout.CITADEL_ORIGIN, smooth)).round()
		_bf.camera.zoom = Vector2.ONE * lerpf(INTRO_FROM_ZOOM, PLAY_ZOOM, smooth)
		if _intro_left <= 0.0:
			_rules.set_process(true)
		return  # the camera is the intro's until it lands: no panning, no aiming
```

In `_unhandled_input(event)`, directly after its `if not started(): return` guard, let only Esc through during the
intro — a click there would cast before the clock starts:

```gdscript
	if in_intro() and not (event is InputEventKey and event.physical_keycode == KEY_ESCAPE):
		return
```

- [ ] **Step 4: Update the README**

In `README.md`:
- Line 43's note becomes: running the project (`& $godot --path .`, F5 in the editor, or `play.bat`) opens the **KAK title screen**; the VFX sandbox is its "VFX Sandbox" button, or `& $godot --path . --scene res://scenes/sandbox.tscn`.
- The benchmark command (`... -- --bench`, around line 142) gains `--scene res://scenes/sandbox.tscn` before the `--`, since it means the sandbox.
- The KAK section's milestone line becomes milestone 4's — Title, Prepare with the four-card draft, Pause, Results with the score and rank, and the save file at `user://kak_save.cfg` — keeping the milestone 3/2/1 sentences after it.
- Add the screen-photograph command next to the other KAK commands:

```bash
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture   # one screen → captures/screen_<name>.png (title|prepare|results|pause)
```

- The controls table gains the screen keys: Enter (Play on the title, MANIFEST on Prepare once four are picked, Replay on Results), Esc (back on Prepare, pause in a mission, resume from pause, Title from Results).
- Keep the check count line current.

- [ ] **Step 5: Check the whole milestone still holds**

```bash
bash tools/test.sh
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/dev/state_digest.gd
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test 2>&1 | grep -E "MISSION test|banner |ERROR|SCRIPT"
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test 2>&1 | grep -E "CROWD result|ERROR"
for s in title prepare results pause; do SCENE=res://scenes/game.tscn bash tools/capture.sh --show=$s --capture 2>&1 | grep -E "captured|ERROR|SCRIPT"; done
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/mission.tscn --audio-driver Dummy --disable-vsync --max-fps 0 -- --bench
```

Expected: `checks=562 failures=0`; the digest exactly as in the Global Constraints; one `MISSION test ...` line with its banner lines (no intro in a scripted run, so the numbers stay in milestone 3's range); one `CROWD result ...`; four `captured` lines; one `bench[mission] ...` line within a few fps of milestone 3's 96–108.

Then the intro, by hand, in a window (`play.bat`, Play, draft four, MANIFEST): the camera starts wide and eases in to the Citadel over two seconds under the MANIFEST banner; the clock reads 4:00 until the camera lands and only then counts down; a click during the sweep casts nothing; Esc during the sweep pauses. Report each as seen or not.

- [ ] **Step 6: Commit**

```bash
git add src/game/mission.gd project.godot tools/capture.sh play.bat README.md
git commit -m "feat: the game is the front door" -m "Running the project now opens the title screen, and every mission opens with a two-second sweep to the Citadel under the MANIFEST banner, the clock waiting until the camera lands. capture.sh defaults to the sandbox scene so every capture, bench and baseline written before this milestone keeps meaning what it meant; the scripted runs skip the intro so their timing and numbers stay comparable with milestone 3's." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Milestone check

After Task 7, before the milestone is called done:

1. `bash tools/test.sh` — `checks=562 failures=0`, output pristine.
2. The digest line, exactly as in the Global Constraints, and `idle.png` `worst_mean_diff=0.000` against `captures/m1_base_a`.
3. The four screen photographs, looked at and described.
4. One full loop by hand: title → Play → draft four → MANIFEST → intro → Esc → Resume → play to an ending → Results over the ruins → Replay → Esc → Change powers (the four preselected) → back → Title, with the best score now shown on the title and on Prepare. Then quit and relaunch: the best score and the last loadout must survive.
5. Show the user the four screen photographs and hand over `play.bat` for a playtest. Their notes on the screens, like their notes on the numbers, feed milestone 5.
