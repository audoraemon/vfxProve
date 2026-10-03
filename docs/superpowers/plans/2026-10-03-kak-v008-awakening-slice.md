# KAK v0.08 Awakening Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the first slice of the Awakening direction:
- a mission framework (definitions, objectives, a director per mission) and a mission board;
- Divine Power as a loadout budget, with up to six slots and no DP spent during a mission;
- a new Tier 1 power, Mind Whisper;
- a Tier 1 mission, *The Warning*;
- today's mission kept as *Last Judgement*, a Tier 5 Skirmish.

**Architecture:**
- **`MissionDef`** describes a mission and **`MissionBook`** lists them, the way `PowerBook` lists powers.
- **`Objective`** subclasses report `PENDING`, `DONE` or `FAILED`. `Rules._check_end()` becomes a loop over the mission's primary objectives, in list order.
- **`MissionDirector`** subclasses run a mission's scripted actors. `Rules.advance()` steps the director just before it checks the objectives, so a director freezes and pauses with the mission.
- **Game** gains a `BOARD` screen between the Title and Prepare. **`SaveFile`** keeps one section per mission.
- **M2** removes the in-mission DP economy. **M3** adds a `WHISPERED` mind to `Person` and a drag-to-a-spot aim to `Targeting`. **M4** adds `WarningDirector`, which drives the watchman, the relay and the bell.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-10-03-kak-v008-awakening-slice-design.md`. Baseline tag `kak-v0.07.1` (commit `dc661ca`). The spec's commit is `73d0c36`.
- **Machine:** the BURIN_NITRO laptop. Older plans' `F:\Godot\...` paths mean these:
  - **Repository:** `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`). Work in it directly, with no worktree.
  - **Branch:** `feat/Develop-Main`. Check `git branch --show-current` before every commit. Do not touch `feat/vfx-proof` or `feat/pixellab-structures`.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. `tools/test.sh` defaults to the old F: path, so run it as `GODOT=$G bash tools/test.sh`.
- **Commands:**
  - **Import** (after adding a script with a new `class_name`, or a new test file): `timeout 180 $G --headless --editor --path . --import >/dev/null 2>&1`. It registers the class and writes the `.gd.uid` file.
  - **Tests:** `timeout 600 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`, with no SCRIPT ERROR or Parse Error lines.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `rows=19`, `digest=61267b7e90524d800bf1c3473a71146b`, `emitters=45`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `FLOW result ... failures=0`.
  - **Mission test:** `$G --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --mission-test 2>&1 | grep "MISSION"`. It is not exact: the hitstop runs on the wall clock, so compare it by eye. See "Gates" below.
  - **Behaviour:** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name> [args]`. Scenarios that cast a power differ by a few people from run to run; the others are exact.
  - **Bench:** `$G --path . --scene res://scenes/mission.tscn -- --bench`. Run it on a quiet machine (close Discord, Edge and ChatGPT).
- **Test style:**
  - A test file is `extends RefCounted` with `static func run(t) -> void:`, using `t.check(cond: bool, "message")` and `t.near(a, b, eps, "message")`.
  - Register a new file in `tests/run_all.gd` by adding `"res://tests/<file>.gd",` after `"res://tests/test_rebuild.gd",`.
  - Tests build a town and crowd with this helper (copy it into each new file that needs one):

```gdscript
static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()
```

  - Tests drive time by calling `step(delta)` or `advance(delta)` directly. A person walks only when the engine steps it, so a test "arrives" a person by setting `p.ground_pos = p.goal(); p._goal = Vector2.INF; p._path = PackedVector2Array()`.
- **Code style:**
  - tabs; `##` doc comments above declarations, in full sentences;
  - constants in `UPPER_CASE` with a `##` comment;
  - match the surrounding code's comment density;
  - new enum values go **at the end** of an enum. `crowd_check` and the behaviour checksums hash `int(p.mind)`, so inserting a value in the middle changes them.
- **Git:**
  - `git add` explicit paths only, including any new `.gd.uid` files;
  - never add `default_bus_layout.tres` (restore it with `git checkout -- default_bus_layout.tres` if it changed), anything under `captures/`, `.codex/`, `concepts/`, or `docs/HUM_Game_Design_Document_v1.docx`;
  - every commit message ends with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
  - **do not push or tag:** the controller does that at the end of each milestone.
- **M1 is a pure refactor.** Last Judgement must pass every gate unchanged before M2 changes any rule (spec §1). If a gate moves in M1, find out why before going on.
- **Tuning latitude:** the code below was written against `kak-v0.07.1` and has not been run.
  - You may change *placement* constants (where the watchman stands, the falling star's spot, screen layout pixels) when the town's geometry or the 640×360 screen demands it.
  - You may change the spec's gameplay numbers only in the tuning tasks that say so (M2 Task 13, M5 Task 23). Every such change goes in the final report.
  - Never weaken a test's intent. Report every deviation from the plan in your final message.
- **Gates.** Each milestone ends with this list; the controller runs it before tagging.
  - tests pass;
  - digest unchanged;
  - crowd_check unchanged;
  - FLOW passes;
  - the exact behaviour checksums recorded in Task 0 are unchanged (from M2 on: unchanged, or explained);
  - the mission test plays as at `kak-v0.07.1`: every number within a few of the Task 0 runs, and in M1 the same `MISSION result` won/reason.
- **The Dev Ledger:** after each milestone, the controller updates the KAK Dev Ledger (https://claude.ai/artifact/6zL2bsrt3H1Vnehk1RkfiK) with `ArtifactData`, as the memory note `kak-dev-ledger` says. Pin every write with `if_version`. The rows to update are the `tasks/v08-m1` … `tasks/v08-m5` cards and `meta/project`; at the end, add `releases/<id>` too.

---

## File structure

| File | Responsibility |
|---|---|
| `src/game/mission/objective.gd` | **New.** `Objective`: status enum, label, reason, `check()`, `hud_text()` |
| `src/game/mission/citadel_objective.gd`, `escape_limit_objective.gd`, `clock_objective.gd` | **New.** Last Judgement's three checks |
| `src/game/mission/bell_silent_objective.gd`, `warning_objective.gd`, `unseen_objective.gd` | **New (M4).** The Warning's checks |
| `src/game/mission/mission_def.gd` | **New.** `MissionDef`: one mission's data |
| `src/game/mission/mission_book.gd` | **New.** `MissionBook`: the missions |
| `src/game/mission/mission_director.gd` | **New.** `MissionDirector`: base class for scripted actors |
| `src/game/mission/warning_director.gd` | **New (M4).** The omen, the watchman, the errand, the relay |
| `src/game/rules.gd` | Mission def, objectives loop, director stepping, `result()`; M2 removes DP |
| `src/game/mission.gd` | Starts a mission from its def; `finished(result)`; six slot keys; camera and intro per mission |
| `src/game/game.gd` | `BOARD` screen, FLOW table, per-mission saves and loadouts, the FLOW test |
| `src/game/save_file.gd` | Per-mission sections; migration of the old `[kak]` best |
| `src/game/draft.gd` | Slots, DP capacity and pool from the mission; refusal reasons |
| `src/game/power_book.gd` | M2: `authority`, DP prices, cooldowns. M3: Mind Whisper |
| `src/game/ui/mission_board.gd` | **New.** The board |
| `src/game/ui/prepare_screen.gd` | The mission's pool, Authority tabs, budget meter, N slots |
| `src/game/ui/hud.gd` | M2: no DP bar, six compact slots. M4: the objective panel, the messenger's marker and edge arrow |
| `src/game/ui/results_screen.gd`, `pause_menu.gd` | The Missions button; The Warning's results |
| `src/game/crowd/person.gd` | M3: `Mind.WHISPERED`, `whisper()`. M4: `observe(at, seconds)`, the watchman's look |
| `src/game/crowd/crowd.gd` | M3: whispered people keep their errand at the evacuation. M4: `nearest_witness()` |
| `src/game/crowd/bell_network.gd` | M4: `hold_on_death`; `replace_keeper()` for a citizen |
| `src/game/crowd/citizen_profile.gd`, `routine_manager.gd` | M4: `Role.WATCHMAN` |
| `src/game/response_profile.gd` | M4: `ResponseProfile.unaware()` |
| `src/game/targeting.gd` | M3: the `"whisper"` aim and its preview |
| `src/fx/dominion/mind_whisper.gd` | **New (M3).** `MindWhisperFx` |
| `src/fx/omen/falling_star.gd` | **New (M4).** `FallingStarFx` |
| `tools/dev/behaviour_check.gd` | M2: `judgement` scenario. M3: whisper clip support. M5: `warning` scenario |
| `tools/dev/make_power_icons.py` | M3: the whisper icon |
| `tests/test_objectives.gd`, `test_mission_book.gd`, `test_whisper.gd`, `test_warning.gd` | **New** tests |

---

## Task 0: Baselines

**Files:** none changed. This task appends an "Execution notes" section to this plan.

- [ ] **Step 1: Confirm the starting point.** Run `git status` (clean) and `git branch --show-current` (`feat/Develop-Main`). Run `git log --oneline -1`, which should show `9afb699` or later.
- [ ] **Step 2: Import and run the five exact gates.** Record each output:
  - tests (expected `checks=1065 failures=0`, per the ledger);
  - digest;
  - crowd_check (expected `-346732806`);
  - FLOW.
- [ ] **Step 3: Record the exact behaviour checksums.** These scenarios cast nothing, so they are exact:
  - `--scenario=calm --seconds=60`;
  - `--scenario=bell --kill-keeper`;
  - `--scenario=gates`;
  - `--scenario=fire`;
  - `--scenario=rite --interrupt`;
  - `--scenario=soldiers --case=escort`.

  Run each twice. If the two runs of a scenario differ, drop it from the list and note why.
- [ ] **Step 4: Record the mission test, three times.** Keep each run's `MISSION result` line and its `MISSION test` line.
- [ ] **Step 5: Record the bench, three times, on a quiet machine.** Keep each run's `bench[mission]` line. This is the `kak-v0.07.1` baseline for M5. The ledger's figure, ~116 fps, came from the old laptop, so the new laptop needs its own.
- [ ] **Step 6: Write it down.** Append a section `## Execution notes` at the end of this plan, with a `### Task 0 baselines (BURIN_NITRO)` heading and every number above. Then commit:

```bash
git add docs/superpowers/plans/2026-10-03-kak-v008-awakening-slice.md
git commit -m "docs: v0.08 plan baselines on BURIN_NITRO

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Milestone 1 — Mission framework (pure refactor)

### Task 1: Objectives

**Files:**
- Create: `src/game/mission/objective.gd`, `citadel_objective.gd`, `escape_limit_objective.gd`, `clock_objective.gd`, `tests/test_objectives.gd`
- Modify: `src/game/rules.gd` (public `crowd()` and `town()` accessors only), `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `Objective.Status { PENDING, DONE, FAILED }`;
  - `Objective.label: String`, `Objective.reason: String`;
  - `Objective.check(rules: Rules) -> Objective.Status`, `Objective.hud_text(rules: Rules) -> String`;
  - `CitadelObjective`, `EscapeLimitObjective.new(limit := Rules.ESCAPE_LIMIT)`, `ClockObjective.new(succeeds := false, text := "", why := "timeout")`;
  - `Rules.crowd() -> Crowd`, `Rules.town() -> Town`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_objectives.gd`:

```gdscript
extends RefCounted
## v0.08 objectives: each reports PENDING, DONE or FAILED from the mission's state. The Citadel's is done once it has
## fallen and the city is broken; the escape limit fails at 50 escaped; the clock fails at 0:00, or -- for a mission
## that asks it to (The Warning) -- succeeds then.


static func _rules() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var rules := Rules.new().setup(PackedStringArray(["heaven"]), null, env, field, crowd, town)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	return [rules, crowd, world, town]


static func run(t) -> void:
	var made := _rules()
	var rules: Rules = made[0]
	var crowd: Crowd = made[1]
	var town: Town = made[3]
	var P := Objective.Status.PENDING
	var D := Objective.Status.DONE
	var F := Objective.Status.FAILED

	var citadel := CitadelObjective.new()
	t.check(citadel.check(rules) == P and citadel.reason == "citadel", "the Citadel standing is pending")
	var escape := EscapeLimitObjective.new()
	t.check(escape.check(rules) == P, "no escapes is pending")
	crowd.escaped_count = Rules.ESCAPE_LIMIT - 1
	t.check(escape.check(rules) == P, "49 escaped is still pending")
	crowd.escaped_count = Rules.ESCAPE_LIMIT
	t.check(escape.check(rules) == F and escape.reason == "escapes", "50 escaped fails it")
	crowd.escaped_count = 0

	var lose_clock := ClockObjective.new()
	var win_clock := ClockObjective.new(true, "Omen fades", "omen")
	t.check(lose_clock.check(rules) == P and win_clock.check(rules) == P, "both clocks are pending while time is left")
	rules.time_left = 0.0
	t.check(lose_clock.check(rules) == F and lose_clock.reason == "timeout", "at 0:00 the clock fails by default")
	t.check(win_clock.check(rules) == D and win_clock.reason == "omen", "or succeeds when the mission asks it to")
	rules.time_left = 83.0
	t.check(win_clock.hud_text(rules) == "Omen fades 1:23", "the clock's line shows the time (%s)" % win_clock.hud_text(rules))

	# The Citadel down and stability broken is done.
	for part in town.citadel.parts():
		part.destroy(&"stone")
	rules.stability.measure(rules._env, crowd, town.citadel)
	var broken := rules.stability.is_broken()
	t.check(citadel.check(rules) == (D if broken else P),
		"the Citadel's objective is done only with the city broken too (broken=%s)" % broken)
	rules.teardown()
	crowd.clear()
	(made[2] as Node).free()
```

  The Citadel part of the test depends on how `Citadel` exposes its parts. Before writing that part, read `src/game/town/citadel.gd` and `tests/test_rules.gd`. They show how existing tests bring the Citadel down: use the same calls, and keep the intent of the test.

  In `tests/run_all.gd`, add `"res://tests/test_objectives.gd",` after `"res://tests/test_rebuild.gd",`.

- [ ] **Step 2: Run the tests.** They fail, because `Objective` does not exist yet.
- [ ] **Step 3: Write the classes.** Create `src/game/mission/objective.gd`:

```gdscript
class_name Objective
extends RefCounted
## One thing a mission asks of the player (v0.08): it reports PENDING, DONE or FAILED from the mission's state. A
## mission's primary objectives decide it in list order -- the first to report DONE wins it, the first to report FAILED
## loses it (Rules._check_end()) -- so a mission can be won more than one way (The Warning: kill the messenger unseen,
## or outlast the omen). Bonus objectives only report in the results.

enum Status { PENDING, DONE, FAILED }

## Short, for the HUD's panel and the results.
var label := ""
## The ending this objective gives the mission when it decides it: "citadel", "escapes", "timeout", "warning", ...
var reason := ""


func check(_rules: Rules) -> Status:
	return Status.PENDING


## The HUD's line for it: the label, unless the objective has a number to show; "" keeps it off the panel.
func hud_text(_rules: Rules) -> String:
	return label
```

  `citadel_objective.gd`. This is the same test as `Rules._check_end()`'s first branch today:

```gdscript
class_name CitadelObjective
extends Objective
## Last Judgement's win (v0.08; before, Rules._check_end()'s first test): the Citadel is down and the city's stability
## has reached zero.


func _init() -> void:
	label = "Destroy the Royal Citadel"
	reason = "citadel"


func check(rules: Rules) -> Status:
	var town := rules.town()
	if is_instance_valid(town) and is_instance_valid(town.citadel) and town.citadel.is_fallen() \
			and rules.stability.is_broken():
		return Status.DONE
	return Status.PENDING
```

  `escape_limit_objective.gd`:

```gdscript
class_name EscapeLimitObjective
extends Objective
## The people got away (v0.08; before, Rules._check_end()'s second test): `limit` citizens reaching an exit fails it.

var limit := Rules.ESCAPE_LIMIT


func _init(most := Rules.ESCAPE_LIMIT) -> void:
	limit = most
	label = "Let fewer than %d escape" % most
	reason = "escapes"


func check(rules: Rules) -> Status:
	return Status.FAILED if rules.crowd().escaped_count >= limit else Status.PENDING
```

  `clock_objective.gd`:

```gdscript
class_name ClockObjective
extends Objective
## The manifestation's clock (v0.08): at 0:00 it fails the mission (Last Judgement), or -- `succeeds` -- wins it (The
## Warning: the omen fades with the bell still silent).

var succeeds := false


func _init(succeed := false, text := "", why := "timeout") -> void:
	succeeds = succeed
	label = text
	reason = why


func check(rules: Rules) -> Status:
	if rules.time_left > 0.0:
		return Status.PENDING
	return Status.DONE if succeeds else Status.FAILED


func hud_text(rules: Rules) -> String:
	return "" if label == "" else "%s %s" % [label, UiTheme.clock(rules.time_left)]
```

  In `rules.gd`, add after `func lose_time`:

```gdscript
## The mission's crowd and town, for its objectives and its director (v0.08).
func crowd() -> Crowd:
	return _crowd


func town() -> Town:
	return _town
```

- [ ] **Step 4: Import, then run the tests.** They pass.
- [ ] **Step 5: Commit.** Message: `feat: mission objectives -- the Citadel, the escape limit, the clock (v0.08 M1)`.

### Task 2: MissionDef, MissionBook, MissionDirector

**Files:**
- Create: `src/game/mission/mission_def.gd`, `mission_book.gd`, `mission_director.gd`, `tests/test_mission_book.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `MissionDef` fields: `id, name, tier, brief: PackedStringArray, goal, goal_label, slots, dp_capacity, pool: PackedStringArray, clock, profile: String, intro_from, camera_at, intro_banner, scored, default_loadout, director: GDScript, make_objectives: Callable, make_bonuses: Callable`;
  - `MissionDef.objectives() -> Array[Objective]`, `bonuses() -> Array[Objective]`, `powers() -> PackedStringArray`, `allows(key) -> bool`, `response_profile(chosen: ResponseProfile.Tier) -> ResponseProfile`, `chooses_difficulty() -> bool`;
  - `MissionBook.LAST_JUDGEMENT := "last_judgement"`, `MissionBook.all() -> Array[MissionDef]`, `MissionBook.get_mission(id) -> MissionDef` (unknown ids give Last Judgement);
  - `MissionDirector.setup(rules, crowd, town, ctx) -> MissionDirector`, `step(delta)`, `marker() -> Vector2`, `report() -> Dictionary`, `teardown()`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_mission_book.gd`:

```gdscript
extends RefCounted
## v0.08 missions as data: Last Judgement keeps today's mission -- every power, its clock, the chosen difficulty, the
## Citadel's objectives in today's order -- and an unknown id falls back to it.


static func run(t) -> void:
	var lj := MissionBook.get_mission(MissionBook.LAST_JUDGEMENT)
	t.check(lj != null and lj.id == "last_judgement" and lj.tier == 5 and lj.scored, "Last Judgement is a scored Tier 5")
	t.near(lj.clock, Rules.MISSION_SECONDS, 0.001, "on today's clock")
	t.check(lj.powers() == PowerBook.keys(), "every power is in its pool")
	t.check(lj.chooses_difficulty() and lj.director == null, "the player picks its difficulty, and it has no director")
	t.check(lj.response_profile(ResponseProfile.Tier.PREPARED).tier == ResponseProfile.Tier.PREPARED,
		"its town is the chosen tier")
	var reasons := []
	for o in lj.objectives():
		reasons.append(o.reason)
	t.check(reasons == ["citadel", "escapes", "timeout"], "its objectives in today's order (%s)" % [reasons])
	t.check(lj.objectives()[0] != lj.objectives()[0], "each mission gets fresh objectives")
	t.check(lj.bonuses().is_empty(), "and no bonus")
	t.check(Array(lj.default_loadout) == Mission.DEFAULT_LOADOUT, "its default loadout is today's four")
	t.check(MissionBook.get_mission("nonsense").id == MissionBook.LAST_JUDGEMENT, "an unknown id is Last Judgement")
	var ids := []
	for m in MissionBook.all():
		ids.append(m.id)
	t.check(ids.has(MissionBook.LAST_JUDGEMENT), "the book lists it (%s)" % [ids])
```

  Register it in `tests/run_all.gd`.

- [ ] **Step 2: Run the tests.** They fail.
- [ ] **Step 3: Write `mission_def.gd`:**

```gdscript
class_name MissionDef
extends RefCounted
## One mission (v0.08): what the board and Prepare show, the loadout it allows, the town it is played in, how it is
## won and lost, and the director that runs its scripted actors. MissionBook makes them.

var id := ""
var name := ""
## The Awakening Tier, 1 (Whisper) to 5 (Ascendance).
var tier := 1
## Two short lines for the board.
var brief := PackedStringArray()
## The goal line, for the board and Prepare.
var goal := ""
## The goal in a few words, for the results (unscored missions).
var goal_label := ""
## Loadout: how many slots, and how much Divine Power the picks may cost in all (0: no budget -- v0.08 M1 only).
var slots := 4
var dp_capacity := 0
## The powers it allows; empty for every power.
var pool := PackedStringArray()
var clock := 360.0
## The town's readiness: "" for the difficulty chosen on Prepare, "unaware" for The Warning's (v0.08 M4).
var profile := ""
## The intro's camera: from `intro_from` to `camera_at` (ground units); its banner.
var intro_from := Vector2(2.7, 12.0)
var camera_at := TownLayout.CITADEL_ORIGIN
var intro_banner := "MANIFEST"
## A score and a rank in the results (Last Judgement), rather than objectives ticked or crossed.
var scored := false
## For runs with no Prepare screen (scripted runs, a standalone mission).
var default_loadout := PackedStringArray()
## A MissionDirector script, or null.
var director: GDScript
## func() -> Array[Objective], each call a fresh set (objectives may keep state).
var make_objectives: Callable
var make_bonuses: Callable


func objectives() -> Array[Objective]:
	var out: Array[Objective] = []
	if make_objectives.is_valid():
		out.assign(make_objectives.call())
	return out


func bonuses() -> Array[Objective]:
	var out: Array[Objective] = []
	if make_bonuses.is_valid():
		out.assign(make_bonuses.call())
	return out


func powers() -> PackedStringArray:
	return pool if not pool.is_empty() else PowerBook.keys()


func allows(key: String) -> bool:
	return powers().has(key)


func chooses_difficulty() -> bool:
	return profile == ""


func response_profile(chosen: ResponseProfile.Tier) -> ResponseProfile:
	return ResponseProfile.for_tier(chosen)
```

  M4 changes `response_profile()` to return `ResponseProfile.unaware()` for `"unaware"`.

  `mission_book.gd`:

```gdscript
class_name MissionBook
extends RefCounted
## The missions (v0.08), the way PowerBook lists the powers. Last Judgement is v0.07's mission as a Tier 5 Skirmish;
## The Warning (Tier 1) joins it in M4.

const LAST_JUDGEMENT := "last_judgement"


static func all() -> Array[MissionDef]:
	var out: Array[MissionDef] = [last_judgement()]
	return out


static func get_mission(id: String) -> MissionDef:
	for m in all():
		if m.id == id:
			return m
	return last_judgement()


static func last_judgement() -> MissionDef:
	var m := MissionDef.new()
	m.id = LAST_JUDGEMENT
	m.name = "Last Judgement"
	m.tier = 5
	m.brief = PackedStringArray(["Aldermere and its Royal Citadel.", "Bring the whole kingdom down."])
	m.goal = "Destroy the Citadel and break the city before %s" % UiTheme.clock(Rules.MISSION_SECONDS)
	m.goal_label = "The city has fallen"
	m.slots = 4
	m.clock = Rules.MISSION_SECONDS
	m.scored = true
	m.default_loadout = PackedStringArray(Mission.DEFAULT_LOADOUT)
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [CitadelObjective.new(), EscapeLimitObjective.new(), ClockObjective.new()]
		return out
	return m
```

  `mission_director.gd`:

```gdscript
class_name MissionDirector
extends RefCounted
## A mission's own actors and setup (v0.08): Rules steps it every frame of the mission, just before the objectives are
## checked, so it pauses and freezes with the mission. Last Judgement has none; The Warning's runs the omen, the
## watchman and the relay (WarningDirector).

var rules: Rules
var crowd: Crowd
var town: Town
## The battlefield's effect context, for the director's own effects (null in tests).
var ctx: FxContext


func setup(r: Rules, c: Crowd, t: Town, x: FxContext) -> MissionDirector:
	rules = r
	crowd = c
	town = t
	ctx = x
	_begin()
	return self


## Virtual: the mission's setup, once the town and its people exist.
func _begin() -> void:
	pass


## Virtual: one step of the mission.
func step(_delta: float) -> void:
	pass


## The ground point the HUD marks (The Warning's messenger), or Vector2.INF for none.
func marker() -> Vector2:
	return Vector2.INF


## What the director adds to the results (The Warning's "solved_by").
func report() -> Dictionary:
	return {}


## Virtual: let go of the world's signals.
func teardown() -> void:
	pass
```

- [ ] **Step 4: Import, then run the tests.** They pass.
- [ ] **Step 5: Commit.** Message: `feat: MissionDef, MissionBook and MissionDirector; Last Judgement as data (v0.08 M1)`.

### Task 3: Rules and Mission run from a MissionDef

**Files:**
- Modify: `src/game/rules.gd`, `src/game/mission.gd`, `src/game/game.gd`, `tests/test_rules.gd`

**Interfaces:**
- Produces:
  - `Rules.setup(powers, ctx, env, field, crowd, town, mission := MissionBook.last_judgement())`;
  - `Rules.mission: MissionDef`, `Rules.objectives: Array[Objective]`, `Rules.bonuses: Array[Objective]`, `Rules.director: MissionDirector`;
  - `Rules.result() -> Dictionary`;
  - `Mission.mission_id: String`; `Mission.finished(result: Dictionary)` replaces the five-argument signal.
- Consumes: Tasks 1–2.

- [ ] **Step 1: Change `Rules`.**
  - Add the fields:

```gdscript
## The mission being played (v0.08), its objectives -- decided in list order, see Objective -- and its director.
var mission: MissionDef
var objectives: Array[Objective] = []
var bonuses: Array[Objective] = []
var director: MissionDirector
```

  - Give `setup()` an argument, `mission_def: MissionDef = null`, after `town`. In its body:

```gdscript
	mission = mission_def if mission_def != null else MissionBook.last_judgement()
	time_left = mission.clock
	objectives = mission.objectives()
	bonuses = mission.bonuses()
```

  - In `advance()`, step the director right before `_check_end()`:

```gdscript
	if director != null:
		director.step(delta)
	_check_end()
```

  - Replace `_check_end()`:

```gdscript
## The mission's primary objectives decide it, in their order (v0.08): the first DONE wins, the first FAILED loses.
## Last Judgement lists the Citadel first, so a city that falls on the last tick of the clock still counts.
func _check_end() -> void:
	if finished:
		return
	for o in objectives:
		match o.check(self):
			Objective.Status.DONE:
				_finish(true, o.reason)
				return
			Objective.Status.FAILED:
				_finish(false, o.reason)
				return
```

  - Add `result()`, after `stat_lines()`:

```gdscript
## Everything the Results screen and the save need (v0.08): the mission, the ending, the time it took, the goal and
## each bonus as earned or not, a scored mission's score, rank and table, and the director's own report.
func result() -> Dictionary:
	var out := {"mission": mission.id, "won": won, "reason": over_reason, "time": _elapsed,
		"goal": {"label": mission.goal_label, "done": won}, "bonuses": []}
	for b in bonuses:
		out.bonuses.append({"label": b.label, "earned": won and b.check(self) != Objective.Status.FAILED})
	if mission.scored:
		out["score"] = score()
		out["rank"] = rank()
		out["lines"] = stat_lines()
	if director != null:
		out.merge(director.report())
	return out
```

  - In `teardown()`, add `if director != null: director.teardown()` at the top.
- [ ] **Step 2: Change `Mission`.**
  - Replace the `finished` signal with `signal finished(result: Dictionary)`.
  - Add `var mission_id := MissionBook.LAST_JUDGEMENT`, with a doc comment: "Game sets it before start(); a standalone run reads --mission=<id>". Also add `var _def: MissionDef` and `var _director: MissionDirector`.
  - In `start()`:
    - At the top, before `_bf.reset`: `if _director != null: _director.teardown()` and `_director = null`.
    - After the args are read: `var wanted_mission := Battlefield.arg_value(args, "--mission") if autostart else ""`, then `_def = MissionBook.get_mission(wanted_mission if wanted_mission != "" else mission_id)`. The `args` line moves above this if needed.
    - Replace `_crowd.profile = ResponseProfile.for_tier(tier)` with `_crowd.profile = _def.response_profile(tier)`.
    - Pass `_def` as the last argument of `_rules.setup(...)`.
    - After `_rules.over.connect(_on_over)`:

```gdscript
	if _def.director != null:
		_director = (_def.director.new() as MissionDirector).setup(_rules, _crowd, _town, _bf.ctx)
		_rules.director = _director
```

    - The intro uses `_def.intro_from`, `_def.camera_at` and `_def.intro_banner` in place of `INTRO_FROM`, `TownLayout.CITADEL_ORIGIN` and `"MANIFEST"`. Make the same replacement in `_process()`'s lerp. For an empty banner, emit nothing.
    - The scripted camera (`_scripted`) stays at `Vector2(0, -2)` for Last Judgement. For any other mission it uses `_def.camera_at`.
  - `_loadout(args)` falls back to `_def.default_loadout`, not `DEFAULT_LOADOUT`. `_def` can be null there when it is called from `_ready()` before `start()`, so resolve the def first: `MissionBook.get_mission(...)`.
  - `_play_ending` ends with `finished.emit(_rules.result())`.
  - `_on_over`: keep it as it is. Its titles are Last Judgement's; M4 swaps them for `ResultsScreen.title_for()`.
- [ ] **Step 3: Change `Game`.**
  - `_on_mission_finished(result: Dictionary)`: `result["best"] = save.record(int(result.get("score", 0)), String(result.get("rank", "D")))`. Keep the rest. Task 4 replaces the save calls.
  - In `_build_mission()`, set `mission.mission_id = mission_id` before `add_child`, and add `var mission_id := MissionBook.LAST_JUDGEMENT` to Game. Task 5 makes the board set it.
- [ ] **Step 4: Fix the tests.** Run the suite, and fix any test that used the old `finished` signature or reads `Rules` fields that moved. `tests/test_rules.gd` should pass unchanged. Add one check at its end: `rules.mission.id == "last_judgement"`, and `rules.objectives.size() == 3`.
- [ ] **Step 5: Run the gates.**
  - tests pass;
  - digest and crowd_check unchanged;
  - the Task 0 behaviour checksums unchanged;
  - mission test: the same `won`/`reason`, and numbers within a few;
  - FLOW passes.
- [ ] **Step 6: Commit.** Message: `refactor: Rules decides the mission by its objectives, and Mission starts from a MissionDef (v0.08 M1)`.

### Task 4: Save file per mission

**Files:**
- Modify: `src/game/save_file.gd`, `src/game/game.gd`, `src/game/ui/title_screen.gd` (no change needed if `best_score`/`best_rank` keep working), `tests/test_save_file.gd`

**Interfaces:**
- Produces:
  - `SaveFile.last_mission: String`;
  - `SaveFile.best(id) -> Dictionary` with the keys `best_score`, `best_rank`, `won`, `bonus`;
  - `SaveFile.record(id: String, result: Dictionary) -> bool`, which is true for a new best;
  - `SaveFile.loadout_for(id) -> PackedStringArray`, `SaveFile.remember_loadout(id, keys)`;
  - `best_score` / `best_rank` stay as read-only properties for Last Judgement (the Title shows them).

**Format.** The save is one ConfigFile:
- section `kak`: `difficulty`, `last_mission`;
- section `mission.<id>`: `best_score`, `best_rank`, `won`, `bonus`, `last_loadout`.

A save from before v0.08 has `best_score`, `best_rank` and `last_loadout` in `kak`. On load, these move into `mission.last_judgement` when that section is missing.

- [ ] **Step 1: Rewrite the test.**
  - Keep every check `tests/test_save_file.gd` makes today, with the calls changed to the per-mission API: `record(MissionBook.LAST_JUDGEMENT, {"won": true, "score": 6200, "rank": "B"})`.
  - Add these checks:
    - An old-format file (write a ConfigFile with `kak/best_score=9000`, `kak/best_rank="B"` and `kak/last_loadout=["nova"]`) loads as Last Judgement's best and loadout.
    - Recording `"warning"` with `{"won": true, "bonus": [{"label": "Unseen", "earned": true}]}` is a new best. After that, `best("warning")` is `won` and `bonus`. A later loss is not a new best and does not clear `won`.
    - `last_mission` round-trips.
    - A loadout key outside the mission's pool is dropped. This check passes trivially until M4, while Last Judgement allows every power.
- [ ] **Step 2: Rewrite `SaveFile`.** One dictionary per mission id. `record()`:
  - for a scored result, a higher `score` is a new best, with its `rank`;
  - otherwise, `won` and `bonus` are each OR-ed in (the bonus counts when any entry in `result.bonuses` is `earned`), and the result is a new best when either went from false to true.

  `_known(id, keys)` keeps the keys that are powers and that `MissionBook.get_mission(id).allows(key)`.
- [ ] **Step 3: Update `Game`.**
  - `_ready`: `mission_id = save.last_mission`, then `loadout = save.loadout_for(mission_id)`.
  - `_on_mission_finished`: `result["best"] = save.record(mission_id, result)`, then `save.remember_loadout(mission_id, loadout)`.
  - `_on_prepare_action`: remember the loadout for `mission_id`.
  - The FLOW test's line `save.last_loadout == four` becomes `save.loadout_for(mission_id) == four`.
- [ ] **Step 4: Run the tests and FLOW.** Both pass.
- [ ] **Step 5: Commit.** Message: `feat: the save keeps each mission's best and loadout, and reads the old file (v0.08 M1)`.

### Task 5: The mission board and the new flow

**Files:**
- Create: `src/game/ui/mission_board.gd`
- Modify: `src/game/game.gd`, `src/game/ui/prepare_screen.gd`, `src/game/draft.gd`, `src/game/ui/results_screen.gd`, `src/game/ui/pause_menu.gd`, `tests/test_flow.gd`, `tests/test_draft.gd`, `tests/test_menu.gd` (only if it pins the pause menu's labels)

**Interfaces:**
- Produces:
  - `Game.Screen { TITLE, BOARD, PREPARE, MISSION, RESULTS }`;
  - the FLOW table below;
  - `MissionBoard.setup(save: SaveFile, current: String) -> MissionBoard`, signal `action(name)` with `"pick"` or `"back"`, `MissionBoard.chosen: String`, `MissionBoard.choose(id)`;
  - `PrepareScreen.setup(mission: MissionDef, preselect, tier)`;
  - `Draft.for_mission(def) -> Draft`, `Draft.slots: int`.

```gdscript
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
```

- [ ] **Step 1: Update `tests/test_flow.gd`.** It should state the table above:
  - Play leads to the board; the board's pick leads to Prepare and its back to the Title; Prepare's back leads to the board.
  - Results and Pause offer Missions. `results:title` and `pause:title` lead nowhere (-1).
  - All five screens are reachable.

  In `tests/test_draft.gd`:
  - `Draft.SLOTS` becomes `draft.slots`;
  - add: `Draft.new().for_mission(MissionBook.last_judgement()).slots == 4`.
- [ ] **Step 2: `Draft`.**
  - Replace `const SLOTS := 4` with `var slots := 4`, plus `var capacity := 0` and `var pool := PackedStringArray()`.
  - Add `for_mission(def)`, which copies `def.slots`, `def.dp_capacity` and `def.powers()`.
  - `toggle()` uses `slots`, and refuses keys outside `pool` when `pool` is non-empty.
  - `is_full()` is `picks.size() == slots`.
  - The budget comes in M2 (Task 9).
- [ ] **Step 3: `MissionBoard`.** A full-screen pixel UI in the style of `PrepareScreen`: a `CanvasLayer` at layer 10, one `Control` that draws everything, `UiTheme` everywhere.
  - **Header:** `"CHOOSE A MANIFESTATION"` at (8, 24), `SIZE_BIG`, gold.
  - **Cards:** one per `MissionBook.all()`, ordered by tier (lowest first). Each is `CARD := Vector2(300, 250)`, side by side centred on 320, `CARD_GAP := 12`, top 48. With one mission, its card sits in the middle.
  - **A card shows, top to bottom:**
    - the name (`SIZE_BIG`, gold);
    - a Tier badge (`"TIER %d"` on a framed plate, top-right);
    - the brief's two lines;
    - `"GOAL"` and the goal, wrapped to the card;
    - `"%d slots · %d DP"`. While `dp_capacity == 0` (M1), only `"%d slots"`;
    - the best result: for a scored mission `"Best %s  %s"` with `ResultsScreen.thousands(best_score)` and the rank, or `"Not yet played"`; otherwise `"Won ✔"` plus `"  Unseen ✔"` when the bonus is earned, or `"Not yet won"`. Draw ✔ with the `UiTheme.mark()` helper (Task 20 adds it). Until then, write `"Won"` / `"Won, Unseen"` in words.
  - **Selection:** the selected card has a bright gold frame; the others are dim.
  - **Input:**
    - `hover` follows the mouse, and a click picks;
    - Left and Right move the selection; Enter picks; Esc emits `"back"`;
    - picking sets `chosen` and emits `"pick"`;
    - `choose(id)` does the same, for the FLOW test and `--show=board`.
  - Sounds as on the other screens: `ui_hover`, `ui_click`, `ui_manifest` on a pick.
- [ ] **Step 4: `Game`.**
  - The enum and FLOW as above.
  - `go_to(BOARD)` builds a `MissionBoard` with `save` and `mission_id`, and connects `action` to `_on_board_action(what, board)`:
    - on `"pick"`: `mission_id = board.chosen`, `save.last_mission = mission_id`, `loadout = save.loadout_for(mission_id)`, `save.save_to(save_path)`;
    - then `on_action("board:" + what)`.
  - `go_to(PREPARE)`: `prep.setup(MissionBook.get_mission(mission_id), loadout, save.difficulty)`.
  - The board plays the theme music, like the Title and Prepare.
  - `--show=board` shows the board.
  - `_flow_test()`:
    - after `title:play`, check `screen == Screen.BOARD and _screen_node is MissionBoard` ("Play opens the mission board");
    - call `(_screen_node as MissionBoard).choose(MissionBook.LAST_JUDGEMENT)` and check Prepare is up for that mission;
    - the run continues as today;
    - where it ends with `prepare:back`, it now expects the board, then `board:back` → Title;
    - add a Pause → Missions step that lands on the board with the mission and the pause menu gone.
- [ ] **Step 5: `PrepareScreen`.**
  - `setup(mission: MissionDef, preselect, tier)` keeps `var mission: MissionDef` and does `draft = Draft.new().for_mission(mission)` before preselecting.
  - The briefing's TARGET/WIN lines come from `mission.brief` and `mission.goal`. Keep the other lines for now; M2 rewrites them.
  - The title-row "Best" moves to the board: drop it from Prepare.
  - The slot count drawn in the loadout bar is `draft.slots`, and `slot_rect` and `hit` use it. Keep today's widths for 4; M2 sizes them for 6.
  - `shown()` lists only keys in `mission.powers()`. Last Judgement allows every power, so nothing changes yet.
- [ ] **Step 6: Results and Pause.**
  - Results: `["replay", "change", "missions"]` / `["Replay", "Change powers", "Missions"]`; Esc emits `"missions"`.
  - Pause: `["resume", "restart", "change", "missions"]` / `["Resume", "Restart", "Change powers", "Missions"]`.
- [ ] **Step 7: Run the tests and FLOW.** Then capture the board: `SCENE=res://scenes/game.tscn GODOT=$G bash tools/capture.sh --show=board --capture`. Check the board looks right (it must not cut off or overlap text).
- [ ] **Step 8: Commit.** Message: `feat: the mission board between the Title and Prepare; Missions on Results and Pause (v0.08 M1)`.

### Task 6: M1 gate (controller)

- [ ] Run every gate in the Global Constraints. M1 must leave Last Judgement exactly as it was:
  - the digest, crowd_check and the Task 0 behaviour checksums are identical;
  - the mission test has the same `won`/`reason`, and its numbers are within a few of Task 0's three runs.
- [ ] Append the gate results to "Execution notes", then commit.
- [ ] Tag `kak-v008-m1` and push `feat/Develop-Main` with its tags.
- [ ] Update the ledger: set `tasks/v08-m1` to `done` (and `v08-plan` to `done` if it is not yet), and refresh `meta/project` (`tests`, `updated`, `note`).

---

## Milestone 2 — Divine loadout

### Task 7: The `judgement` scenario, measured before any rule changes

**Files:** Modify `tools/dev/behaviour_check.gd`.

This scenario is what spec §2 compares: it plays Last Judgement with the default loadout, at Organized, casting each power as soon as the rules let it. It is written only against APIs that exist both before and after M2 (`rules.refusal()`, `rules.cast()`, `rules.loadout`), so the same file runs on both sides of the change.

- [ ] **Step 1: Add the scenario.**
  - In the usage comment, add:

```
##   judgement (v0.08) Last Judgement played greedily with the default loadout: from 5 s, each slot is cast the moment
##          its rules allow it, at the next of a fixed ring of targets closing on the Citadel; a report every 30 s,
##          then when the Citadel fell, the ending, escapes, buildings, the score and the DP left at the end (if any)
```

  - Add `"judgement": await _judgement()` to the match.
  - Add the function:

```gdscript
const JUDGEMENT_TARGETS := [Vector2(-9.0, -11.0), Vector2(0.8, 2.2), Vector2(-12.0, 1.0), Vector2(-4.0, -6.0),
	TownLayout.CITADEL_ORIGIN, Vector2(-6.0, -12.0), Vector2(4.0, -4.0), Vector2(-10.5, -8.0)]


func _judgement() -> void:
	var rules: Rules = mission._rules
	var town: Town = mission._town
	var fell_at := -1.0
	var next := 0
	var t := 0.0
	await _frames(5 * 60)
	t = 5.0
	var report_at := 30.0
	while not rules.finished and t < Rules.MISSION_SECONDS + 1.0:
		await _frames(6)
		t += 0.1
		for slot in rules.loadout.size():
			if rules.refusal(slot) == "":
				var at: Vector2 = JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()]
				next += 1
				rules.cast(slot, at, {"dir": Vector2(0.2, 1.0).normalized()})
				break
		if fell_at < 0.0 and town.citadel.is_fallen():
			fell_at = t
		if t >= report_at:
			report_at += 30.0
			print("BEHAVIOUR judgement t=%d citadel=%d%% stability=%d%% escaped=%d buildings=%d stage=%s" % [
				roundi(t), roundi(town.citadel.fraction() * 100.0), roundi(rules.stability.total() * 100.0),
				mission._crowd.escaped_count, rules.buildings_down, mission._crowd.alarms.stage_name()])
	var dp_left: Variant = rules.get("dp")
	print("BEHAVIOUR judgement end t=%.1f citadel_fell=%.1f won=%s reason=%s escaped=%d buildings=%d score=%d rank=%s dp_left=%s" % [
		t, fell_at, rules.won, rules.over_reason, mission._crowd.escaped_count, rules.buildings_down, rules.score(),
		rules.rank(), str(dp_left)])
```

  The scenario runs at Organized, so do **not** add it to the Prepared list in `_run()`.
- [ ] **Step 2: Measure the baseline.** Run `--scenario=judgement` five times, and record every `end` line in "Execution notes" under `### Task 7 judgement baseline (pre-M2)`.

  Also note the median of `citadel_fell`, `escaped`, `score` and `floor(dp_left)` over the winning runs. Task 13 uses these numbers.
- [ ] **Step 3: Commit.** Message: `tools: a greedy Last Judgement scenario, for the DP-to-loadout comparison (v0.08 M2)`.

### Task 8: PowerBook — Authorities, prices, cooldowns

**Files:** Modify `src/game/power_book.gd`, `tests/test_power_book.gd`, `tests/test_draft.gd`.

**Interfaces:**
- Produces:
  - each power's `"authority"` (one of `PowerBook.AUTHORITIES`) replaces `"kind"`;
  - `"dp"` is now the **loadout price**, and `"cooldown"` the new value, both from spec §2's table;
  - `PowerBook.AUTHORITIES := ["ruin", "veil", "dominion", "passage", "disorder", "lifedeath"]`, `AUTHORITY_TITLES := ["RUIN", "VEIL", "DOMINION", "PASSAGE", "DISORDER", "LIFE/DEATH"]`;
  - `of_authority(a) -> PackedStringArray`, `authority_of(key) -> String`, `authority_title(a) -> String`;
  - `KINDS`, `KIND_TITLES`, `of_kind()` and `kind_of()` are removed.

| key | authority | dp | cooldown |
|---|---|---|---|
| doom | veil | 1 | 10.0 |
| wisp | dominion | 2 | 30.0 |
| discord | disorder | 2 | 30.0 |
| heaven | ruin | 2 | 30.0 |
| blight | veil | 2 | 36.0 |
| thorns | passage | 2 | 42.0 |
| tornado | ruin | 3 | 45.0 |
| pestilence | lifedeath | 3 | 48.0 |
| dragon | ruin | 3 | 54.0 |
| tsunami | ruin | 4 | 60.0 |
| gravity | ruin | 3 | 60.0 |
| laser | ruin | 3 | 66.0 |
| orbital | ruin | 3 | 66.0 |
| cinder | ruin | 4 | 75.0 |
| judgement | ruin | 4 | 90.0 |
| glacial | ruin | 4 | 90.0 |
| nova | ruin | 4 | 120.0 |

- [ ] **Step 1: Update the tests.**
  - `test_power_book.gd`:
    - every power has a known authority;
    - prices are 1–4;
    - every cooldown is at least the old one, as the rule of thumb requires — check this against the table, not computed;
    - nova is `dp == 4 and cooldown == 120.0`;
    - `of_authority("veil") == ["doom", "blight"]` and `authority_of("nova") == "ruin"`.
  - `test_draft.gd`:
    - tabs are Authorities;
    - `PrepareScreen.cooldown_text(doom)` is `"10 s"`.
- [ ] **Step 2: Change the table and the helpers.** Update the header comment: prices are the loadout budget (v0.08); cooldowns follow the rule of thumb max(old cooldown, 3 × old DP).
- [ ] **Step 3: Fix the callers.** `PrepareScreen` uses `AUTHORITIES` (Task 12 reworks the tabs; for now a straight rename is enough). Grep for `kind` uses in `src/` and `tests/`.
- [ ] **Step 4: Run the tests.** They pass.
- [ ] **Step 5: Commit.** Message: `feat: powers by Authority, with loadout prices and retuned cooldowns (v0.08 M2)`.

### Task 9: The draft's budget

**Files:** Modify `src/game/draft.gd`, `src/game/mission/mission_book.gd`, `tests/test_draft.gd`.

**Interfaces:**
- Produces:
  - `Draft.toggle(key) -> String`: `""` when it changed, else `"slots"`, `"dp"` or `"pool"`;
  - `Draft.refusal(key) -> String`, why an unpicked key cannot be added;
  - `Draft.spent() -> int`;
  - `Draft.can_manifest() -> bool`, true with at least one pick.
- Last Judgement becomes `slots = 6`, `dp_capacity = 14`.

- [ ] **Step 1: Tests**, in `test_draft.gd`, using a Last Judgement draft:
  - the default four (2+4+4+4) cost 14 and fit;
  - a fifth pick of 1 DP (`doom`) is refused with `"dp"`, and `spent()` stays 14;
  - taking out `nova` leaves 10, after which `doom` fits;
  - seven 1–2 DP picks are refused at the seventh with `"slots"` (build it from cheap keys so DP is not the limit);
  - an empty draft cannot manifest; one pick can;
  - a key outside the pool is refused with `"pool"`.

  Use a test-only `MissionDef` with `pool = ["doom", "discord"]`.
- [ ] **Step 2: Implement.**
  - `refusal()`, in order: `"pool"`; `"slots"` when full; `"dp"` when `capacity > 0` and `spent() + price > capacity`.
  - `preselect()` keeps the saved order, skipping anything refused.
- [ ] **Step 3: Run the tests, then commit.** Message: `feat: the draft fills up to the mission's slots within its Divine Power (v0.08 M2)`.

### Task 10: Rules without the DP economy; the Divine Surge

**Files:**
- Modify: `src/game/rules.gd`, `src/game/ui/hud.gd` (the DP references only), `src/game/game.gd` (`SAMPLE_RESULT`), `tools/dev/behaviour_check.gd` (`_force_cast`), `tools/dev/profile_wear.gd`
- Modify tests: `tests/test_rules.gd`, `tests/test_score.gd`, `tests/test_hud.gd`

**Interfaces:**
- Removed:
  - `dp`, `DP_MAX`, `DP_REGEN`, `DP_FOR_ROLE`, `TEMPLE_DP_SHARE`, `DP_SOLDIER`, `CITADEL_DP`, `CHAIN_DP`;
  - `dp_recovery`, `DP_RECOVERY_DEFAULT`, `SCORE_PER_DP`;
  - the signals `dp_changed` and `dp_gained`; `_gain()`, `_restore()`; `cost()`;
  - the refusal `"dp"`.
- Produced: `signal surged`; `Rules.surged_once: bool`.

- [ ] **Step 1: Rewrite the DP tests.**
  - `test_rules.gd`:
    - delete every DP assertion;
    - keep the cooldown, the busy lock, the clock, the chain, the Citadel banner and the credit tests;
    - the cooldown checks use the new values: Heaven's 30 s;
    - add: a cast changes nothing but the cooldown, and `refusal()` never returns `"dp"`.
  - Replace the Temple block with the **Divine Surge**:
    - put two slots on cooldown;
    - destroy the cathedral (the `temple` structure);
    - both cooldowns are now 0, `surged` fired once, and the banner `"DIVINE SURGE"` was emitted;
    - put a slot on cooldown again, then destroy a second temple-role structure if the town has one — or call `_on_structure_destroyed` with the same structure — and the cooldown stays.
  - `test_score.gd`:
    - the winning formula drops the DP term;
    - remove `dp_left`.
  - `test_hud.gd`: drop the `"dp"` slot state check.
- [ ] **Step 2: Change `Rules`.**
  - Update the header doc: no Divine Power is spent in a mission (v0.08); the loadout's price was paid in the draft.
  - `advance()` loses the regeneration lines. `cast()` loses the spending.
  - `_on_structure_destroyed` for a temple:

```gdscript
	if s.role == &"temple" and not surged_once:
		# The Divine Surge (v0.08): the Temple's fall resets every cooldown, once.
		surged_once = true
		_cooldowns.fill(0.0)
		surged.emit()
		banner.emit("DIVINE SURGE")
```

  - Remove the payouts from `_on_killed`, `_on_citadel_fallen` and `_check_chain`. The banners `"THE CITADEL FALLS"` and `"CHAIN!"` stay.
  - `score()` and `stat_lines()` drop the DP term and the "Divine Power left" line.
- [ ] **Step 3: Fix the callers.**
  - Hud: delete `_draw_dp`, `_popups`, `_on_dp_gained`, `_draw_popups`, `POPUP_SECONDS` and `DP_BAR`. Remove `_rules.dp` from `_signature()`. The slot's cost text becomes the cooldown (Task 11 finalises the layout).
  - `behaviour_check._force_cast`: remove `rules.dp = Rules.DP_MAX`.
  - `profile_wear.gd`: remove the DP top-up.
  - `Game.SAMPLE_RESULT`: remove the "Divine Power left" line; it also needs `"mission": "last_judgement"`.
  - `UiTheme.COL_DP` and `COL_DP_LOW` may stay, if anything else uses them; otherwise remove them.
  - Grep the whole tree for `\.dp\b`, `DP_` and `dp_` to be sure. `PowerBook`'s `"dp"` field stays: it is now the price.
- [ ] **Step 4: Run the tests, FLOW and the mission test.** The mission test's `MISSION test dp=` field goes: change the print to drop it.
- [ ] **Step 5: Commit.** Message: `feat: no Divine Power is spent in a mission; the Temple's fall is a Divine Surge (v0.08 M2)`.

### Task 11: The in-mission bar — six compact slots

**Files:** Modify `src/game/ui/hud.gd`, `src/game/mission.gd`, `tests/test_hud.gd`.

- [ ] **Step 1: Tests**, in `test_hud.gd`:
  - with a 6-power loadout, `slot_rect(0)` to `slot_rect(5)` fit inside 640 px and do not overlap;
  - `slot_at()` finds each one;
  - with 4 powers, the row is centred.
- [ ] **Step 2: Hud.**
  - `SLOT_W := 100.0`, `SLOT_GAP := 4.0`. The row's width is 620 px for six.
  - `SLOT_TOP` moves down to sit where the DP bar was, about `316.0`. Check it in a capture.
  - Each slot draws:
    - the 42-px icon with its key plate;
    - the name in one line at `SIZE_SMALL`, cut to fit the 54 px beside the icon (the Prepare loadout bar's rule: the first word, then trimmed);
    - under it, the cooldown as `PrepareScreen.cooldown_text(power)`, dim.
  - The busy and cooldown shades stay as they are.
- [ ] **Step 3: Mission.** `SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]`.
- [ ] **Step 4: Run the tests and look at it.** Capture a mission with six powers (`--loadout=doom,heaven,wisp,thorns,discord,blight --capture`) and look at the bar.
- [ ] **Step 5: Commit.** Message: `feat: six compact slots on the in-mission bar, no DP bar (v0.08 M2)`.

### Task 12: Prepare — Authority tabs, the budget meter, N slots

**Files:** Modify `src/game/ui/prepare_screen.gd`, `tests/test_draft.gd`.

- [ ] **Step 1: Tests**, in `test_draft.gd`:
  - **Tabs:**
    - a Prepare for Last Judgement shows a tab for every Authority that has a power in its pool, in `AUTHORITIES` order: all six;
    - for the test-only pool `["doom", "discord"]`, only Veil and Disorder.
  - **Slot rects:** for 6 slots, `slot_rect(0..5)` fit inside the bar left of MANIFEST and do not overlap.
  - **Clicks:**
    - clicking a card that does not fit leaves the draft unchanged and sets `prep.refused_reason` to `"Not enough Divine Power"`;
    - with no free slot, `"No free slot"`.
  - **MANIFEST:**
    - with one pick, MANIFEST is enabled (`prep.can_manifest()`);
    - with none, it buzzes and does not emit.
  - **Difficulty:** `prep.hit()` never returns `diff_prev` or `diff_next` when `mission.chooses_difficulty()` is false.
- [ ] **Step 2: Implement.**
  - **Tabs:**
    - `tabs()` returns the Authorities with at least one power in `mission.powers()`;
    - `TAB` is sized to share the 432-px row: `(432 - 4 × (n − 1)) / n` wide;
    - the label is the Authority's title alone if title plus count does not fit.
  - **Header right:** `"%d / %d slots   %d / %d DP"`, gold when full, dim otherwise.
  - **Cards:**
    - show `"%d DP  %s"` (price and cooldown);
    - a card whose `draft.refusal(key)` is not `""` (and that is not picked) is dimmed: its icon at 45% and its text in `COL_DIM`;
    - clicking it buzzes (`ui_buzz`) and shows the reason for `REFUSE_SECONDS := 1.5` in the panel's hint line (`refused_reason`).
  - **Loadout bar:**
    - `draft.slots` slots share the space left of MANIFEST: `room = MANIFEST_RECT.position.x − 4 − LOADOUT_BAR.position.x`, each `(room − 4 × slots) / slots` wide;
    - the name is drawn only when a slot is at least 70 px wide.
  - **MANIFEST** is lit when `draft.can_manifest()`; Enter likewise.
  - **The bottom strip:**
    - the difficulty selector and the Defense Profile show only when `mission.chooses_difficulty()`;
    - otherwise the strip shows the mission's fixed profile: `ResponseProfile` lines for `mission.response_profile(…)`, with the name `"UNAWARE"` coming from M4. It may stay hidden until M4.
  - **Briefing**, for Last Judgement:
    - drop the `POWER` and `TEMPLE` DP lines;
    - add `["LOADOUT", "%d slots, %d Divine Power to spend on them"]` and `["TEMPLE", "Its fall resets every cooldown, once"]`;
    - the hint becomes `"Pick up to %d powers within %d DP"`.
- [ ] **Step 3: Capture Prepare** (`--show=prepare` and `--show=prepare --hover=doom`) and check the layout at 640×360.
- [ ] **Step 4: Run the tests and FLOW.** The FLOW test's `four` still fits 14 DP, so it is unchanged.
- [ ] **Step 5: Commit.** Message: `feat: Prepare drafts by Authority within the mission's slots and Divine Power (v0.08 M2)`.

### Task 13: Retune Last Judgement (cooldowns, ranks)

**Files:** Modify `src/game/power_book.gd` (the four default powers' cooldowns only, if needed) and `src/game/rules.gd` (`RANKS`).

- [ ] **Step 1: Measure.** Run `--scenario=judgement` five times on the M2 build. Record every line under `### Task 13 judgement after M2`.
- [ ] **Step 2: Compare with Task 7** (spec §2):
  - the median `citadel_fell` must land in the same 30-second window as before (for example 120–150 s);
  - the median `escaped` must be within ±5.

  If either is off, tune the cooldowns of `heaven`, `tsunami`, `cinder` and `nova` (shorter makes the run faster), and measure again. Change only those four. Record each attempt.
- [ ] **Step 3: Retune the ranks.**
  - Today's ranks are `[[19200, "S"], [14400, "A"], [9600, "B"], [4800, "C"]]`. The winning runs in Task 7 had a DP term of `floor(dp_left) × 10`.
  - Lower each threshold by the median Task 7 DP term, rounded to the nearest 100. The ranks must still be in descending order.
  - Check that the median winning Task 13 run gets the same rank as the median Task 7 run. If it does not, explain why in the notes.
  - Update `tests/test_score.gd` if it pins the thresholds.
- [ ] **Step 4: Run the tests, then commit.** Message: `tune: Last Judgement's cooldowns and ranks for the loadout model (v0.08 M2)`. The message lists the before and after medians.

### Task 14: M2 gate (controller)

- [ ] Run the gates.
  - The digest and crowd_check must be unchanged. M2 does not touch `Structure` or the crowd.
  - The behaviour checksums that cast nothing must be unchanged.
  - The mission test may differ in its score, rank and the DP field only.
- [ ] Capture Prepare, a mission with six powers, and Results. Add the shots to the report to the user.
- [ ] Tag `kak-v008-m2` and push.
- [ ] Update the ledger: `v08-m2` → `done`; refresh `meta/project`; add a `needs_you: true` task "Playtest the v0.08 loadout model (M2)".

---

## Milestone 3 — Mind Whisper

### Task 15: The `WHISPERED` mind

**Files:**
- Modify: `src/game/crowd/person.gd`, `src/game/crowd/crowd.gd` (`_evacuate`), `src/game/ui/behaviour_overlay.gd` (`INTENT_COLS`)
- Create: `tests/test_whisper.gd`; modify `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `Person.Mind.WHISPERED` and `Person.Intent.WHISPERED`, each appended **last**;
  - `Person.whisper(to: Vector2, linger: float) -> bool`;
  - `Person.whispered_left() -> float`;
  - `Person.whisper_resume_flee()`: marks a whispered person to flee when it wakes (the evacuation call).
- Constants: `Person.COL_WHISPER := Color("f0d070")`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_whisper.gd`, using the `_crowd()` helper:

```gdscript
extends RefCounted
## v0.08 Mind Whisper's mind: a whispered person drops whatever it was doing, walks (not runs) to the spot, lingers
## there, then resumes -- flight again if it was fleeing, else its day, where a duty's manager takes it back. Soldiers,
## anyone inside and the dead do not hear it.

# (paste the _crowd() and _done() helpers here)


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _think(p: Person, seconds: float) -> void:
	var step := 0.1
	var t := 0.0
	while t < seconds:
		p._think(step)
		t += step


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var p: Person = crowd.citizens[0]
	var to := grid.nearest_walkable(p.ground_pos + Vector2(3.0, 0.0))
	t.check(p.whisper(to, 8.0) and p.mind == Person.Mind.WHISPERED, "a calm citizen hears the whisper")
	t.check(p.goal().distance_to(to) < 0.01 and p.walk_speed <= Person.WALK_SPEED * p.pace + 0.001,
		"and walks to the spot (%.2f)" % p.walk_speed)
	t.check(p.intent() == Person.Intent.WHISPERED, "its intent reads WHISPERED")
	_think(p, 3.0)
	t.check(p.mind == Person.Mind.WHISPERED, "the linger does not start on the way")
	_arrive(p)
	_think(p, 7.0)
	t.check(p.mind == Person.Mind.WHISPERED, "it lingers there")
	_think(p, 1.5)
	t.check(p.mind == Person.Mind.RECOVER, "after 8 s it goes back to its day (%s)" % Person.Mind.keys()[p.mind])

	# Flight is picked up again.
	var f: Person = crowd.citizens[1]
	f.flee()
	f.whisper(grid.nearest_walkable(f.ground_pos + Vector2(0.0, 2.0)), 8.0)
	_arrive(f)
	_think(f, 8.5)
	t.check(f.mind == Person.Mind.FLEE, "a whispered evacuee flees again after")

	# A duty: the bell's keeper drops the climb and the bell waits for it.
	var keeper: Person = crowd.bell.keeper
	crowd.bell.call_keeper()
	t.check(keeper.mind == Person.Mind.DUTY, "the keeper is called")
	keeper.whisper(grid.nearest_walkable(keeper.ground_pos + Vector2(-3.0, 0.0)), 8.0)
	crowd.bell.step(0.1)
	t.check(crowd.bell.state == BellNetwork.State.WAITING, "the bell waits for its whispered keeper")
	for i in 30:
		crowd.bell.step(0.5)
	t.check(keeper.mind == Person.Mind.WHISPERED, "and does not take it back mid-whisper")

	# Immune: soldiers, the dead, anyone inside.
	t.check(not crowd.soldiers[0].whisper(Vector2.ZERO, 8.0), "soldiers do not hear it")
	var inside: Person = crowd.citizens[2]
	inside.inside = true
	t.check(not inside.whisper(Vector2.ZERO, 8.0), "nor does anyone inside")
	inside.inside = false
	var dead: Person = crowd.citizens[3]
	(made[3] as EnemyField).kill(dead, &"doom", dead.ground_pos)
	t.check(not dead.whisper(Vector2.ZERO, 8.0), "nor the dead")

	# The evacuation leaves a whispered person to its whisper, then it flees.
	var w: Person = crowd.citizens[4]
	w.whisper(grid.nearest_walkable(w.ground_pos + Vector2(2.0, 0.0)), 8.0)
	crowd._evacuate()
	t.check(w.mind == Person.Mind.WHISPERED, "the evacuation call does not break a whisper")
	_arrive(w)
	_think(w, 8.5)
	t.check(w.mind == Person.Mind.FLEE, "and it joins the flight after")
	_done(made)
```

  If the test's `_think` stepping fights the half-rate thinking (`_think_due`), call `p._think()` directly as above. That bypasses `tick()`.

- [ ] **Step 2: Implement in `Person`.**
  - Append `WHISPERED` to `Mind` and to `Intent`, and add the variables:

```gdscript
## Mind Whisper (v0.08): seconds of lingering left once it has arrived, and whether it fled before (or must flee after).
var _whisper_left := 0.0
var _whisper_fled := false
```

  - The method, after `lure()`:

```gdscript
## Mind Whisper (v0.08): drop whatever it was doing -- its day, a duty, an errand, even flight -- walk to `to` and
## linger there `linger` seconds under a gold glyph, then pick up again: flight if it was fleeing, else back to its day,
## where a duty's manager takes it back. Soldiers, anyone inside and the dead do not hear it; true when it did.
func whisper(to: Vector2, linger: float) -> bool:
	if soldier or inside or state == State.DEAD:
		return false
	_whisper_fled = mind == Mind.FLEE or (mind == Mind.CONFUSED and _was_fleeing)
	release_from_queue()
	passing_gate = null
	mind = Mind.WHISPERED
	_whisper_left = linger
	_confused_left = 0.0
	_panic_left = 0.0
	anchor = to
	walk_speed = _mind_speed()
	set_goal(to)
	return true


func whispered_left() -> float:
	return _whisper_left if mind == Mind.WHISPERED else 0.0


## The town is evacuating while it is whispered: it flees once the whisper wears off.
func whisper_resume_flee() -> void:
	_whisper_fled = true


func _wake() -> void:
	_whisper_left = 0.0
	if _whisper_fled:
		_whisper_fled = false
		mind = Mind.CALM
		flee()
	else:
		_recover(rng.randf_range(1.0, 2.0))
```

  - In `_think()`, after the `elif mind == Mind.CONFUSED:` branch:

```gdscript
	elif mind == Mind.WHISPERED:
		if _goal == Vector2.INF:
			# There (or as near as the way allowed): stand and linger.
			_idle = maxf(_idle, 0.1)
			_whisper_left -= delta
			if _whisper_left <= 0.0:
				_wake()
```

  - In `_pick_target()`, add `or mind == Mind.WHISPERED` to the "stand where it arrived" condition (with OBSERVE, ASSIST, SHELTER and DUTY).
  - `_base_speed()` needs nothing: the `_` branch gives `WALK_SPEED * pace`.
  - `intent()`: `Mind.WHISPERED: return Intent.WHISPERED`.
  - `_art_signature()`: in `pose`, add `+ (5 if mind == Mind.WHISPERED else 0)`. A whispered person is never running, stumbling or confused, so 5 is free and stays under 7.
  - `_draw_citizen()`, after the Discord swirl:

```gdscript
	if mind == Mind.WHISPERED and state != State.DEAD:
		# Mind Whisper's glyph: a small gold eye over the head.
		_px(-1, -17 + lift, 3, 1, COL_WHISPER)
		_px(0, -18 + lift, 1, 3, COL_WHISPER)
```

  - `Crowd._evacuate()`, in the loop, before `p.flee()`:

```gdscript
		if p.mind == Person.Mind.WHISPERED:
			p.whisper_resume_flee()  # Mind Whisper (v0.08): it lingers first, then flees
			continue
```

  - `BehaviourOverlay.INTENT_COLS`: append `Color("f0d070")`.
- [ ] **Step 3: Import, run the tests and crowd_check.** crowd_check must be unchanged: nothing is whispered in it.
- [ ] **Step 4: Commit.** Message: `feat: a whispered mind -- walk to the spot, linger, resume (v0.08 M3)`.

### Task 16: `MindWhisperFx`, the PowerBook entry and the cast refusal

**Files:**
- Create: `src/fx/dominion/mind_whisper.gd`
- Modify: `src/game/power_book.gd`, `src/game/rules.gd`, `tests/test_whisper.gd`, `tests/test_power_book.gd`

**Interfaces:**
- Produces:
  - `MindWhisperFx.PICK_R := 0.6`, `REACH := 10.0`, `LINGER := 8.0`;
  - `MindWhisperFx.pick(field, at) -> Person`;
  - `MindWhisperFx.clamp_to(grid, from, to) -> Vector2`;
  - the cast's `extra` carries `{"to": Vector2, "target": Person}`;
  - `Rules.refuse(slot, reason)`; the refusal reason `"nobody"`.
- PowerBook entry, after `doom`:

```gdscript
	{"key": "whisper", "name": "Mind Whisper", "path": "res://src/fx/dominion/mind_whisper.gd",
		"dp": 1, "cooldown": 8.0, "aim": "whisper", "shape": "send one person somewhere, then they linger 8 s",
		"quiet": true, "authority": "dominion"},
```

- [ ] **Step 1: Tests**, appended to `test_whisper.gd`:
  - `pick()` finds a citizen within 0.6 and returns null 1 unit from anyone;
  - `pick()` skips soldiers and anyone inside;
  - `clamp_to()` caps a 20-unit drag to at most 10 and returns walkable ground;
  - with a `Rules` (`caster` stubbed to build the fx through `MindWhisperFx.new()`, or to call `p.whisper` directly — see Step 3):
    - a cast at an empty spot is refused with `"nobody"`;
    - the slot's cooldown stays 0;
    - `cast_made` did not fire;
  - a cast on a citizen starts the 8 s cooldown, and the citizen is `WHISPERED`, walking to `extra.to`.

  In `test_power_book.gd`: `whisper` is Dominion, 1 DP, 8 s, aim `"whisper"`, quiet.
- [ ] **Step 2: The effect.**

```gdscript
class_name MindWhisperFx
extends FxTimeline
## Mind Whisper (v0.08, Dominion): one person -- the citizen pressed on -- drops what they are doing, walks to where the
## player released, lingers LINGER seconds and resumes (Person.whisper()). Quiet: no threat, no alarm. A soft gold
## ring marks the spot while they are on their way and lingering; the glyph over them is the person's own.

## How near the press must be to a citizen.
const PICK_R := 0.6
## How far from them the spot may be.
const REACH := 10.0
const LINGER := 8.0
const COL_RING := Color(0.95, 0.82, 0.4, 0.6)
## The ring is drawn for as long as this, at most.
const MAX_SHOW := 30.0

var _target: Person
var _to := Vector2.INF


## The citizen a press at `at` whispers to: the nearest living one out in the open within PICK_R, or null.
static func pick(field: EnemyField, at: Vector2) -> Person:
	var best: Person = null
	for e in field.in_radius(at, PICK_R):
		var p := e as Person
		if p == null or p.soldier or p.inside or not p.is_alive():
			continue
		if best == null or p.ground_pos.distance_squared_to(at) < best.ground_pos.distance_squared_to(at):
			best = p
	return best


## Where a release at `to` sends someone standing at `from`: at most REACH away, on walkable ground.
static func clamp_to(grid: WalkGrid, from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	var g := from + d.limit_length(REACH)
	if grid == null or grid.walkable(g):
		return g
	var free := grid.nearest_walkable(g, 6)
	return free if free != Vector2.INF else from


func _build() -> void:
	duration = MAX_SHOW
	busy = 0.3
	_target = extra.get("target") as Person if extra.get("target") is Person else pick(ctx.field, origin)
	_to = extra.get("to", origin)
	if _target == null or not _target.whisper(_to, LINGER):
		duration = 0.1
		return
	ctx.play(&"grav_shimmer", _to, -14.0)


func _fx_process(_delta: float) -> void:
	if not is_instance_valid(_target) or _target.mind != Person.Mind.WHISPERED:
		duration = minf(duration, t + 0.4)  # fade out with the whisper
	queue_redraw()


func _draw() -> void:
	if _to == Vector2.INF:
		return
	var fade := clampf(minf(t / 0.3, (duration - t) / 0.4), 0.0, 1.0)
	var col := COL_RING
	col.a *= fade * (0.75 + 0.25 * sin(t * 3.0))
	# An iso ring at the spot (the effect sits on the overhead layer, in screen pixels).
	var c := Iso.ground_to_screen(_to)
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * float(i) / 24.0
		pts.append(c + Iso.ground_to_screen(Vector2(cos(a), sin(a)) * 0.5) - Iso.ground_to_screen(Vector2.ZERO))
	draw_polyline(pts, col, -1.0)
```

  Before writing `_draw`, check how the other quiet effects draw ground rings (for example `WillOWisp` or `FxParts`); if a helper exists, use it. Also check that `ctx.play(&"grav_shimmer", …)` is the right sound call for a quiet cue, by copying Discord's.
- [ ] **Step 3: Rules.**
  - Add `func refuse(slot: int, reason: String) -> void: cast_refused.emit(slot, reason)`.
  - In `cast()`, after `refusal()` passes, refuse a whisper with no one to whisper to, without starting the cooldown:

```gdscript
	if String(p.key) == "whisper":
		var who: Variant = extra.get("target")
		if not (who is Person and (who as Person).is_alive() and not (who as Person).inside) \
				and MindWhisperFx.pick(_field, ground) == null:
			cast_refused.emit(slot, "nobody")
			return null
```

    This goes above the line that starts the cooldown; `p` is `power(slot)`.
  - Update the `cast_refused` doc comment to list `"nobody"`.
- [ ] **Step 4: Import and run the tests.** In the test, use a `caster` that does the effect's work without a scene: `func(script, ground, extra): var p = extra.get("target", MindWhisperFx.pick(field, ground)); if p: p.whisper(extra.get("to", ground), MindWhisperFx.LINGER); return null`.
- [ ] **Step 5: Commit.** Message: `feat: Mind Whisper -- Dominion, 1 DP, 8 s: send one person somewhere (v0.08 M3)`.

### Task 17: Aiming the whisper

**Files:** Modify `src/game/targeting.gd`, `src/game/ui/hud.gd`, `tests/test_targeting.gd`.

**Interfaces:**
- Produces: aim `"whisper"`. The press snaps to `MindWhisperFx.pick()`. If it finds nobody, `rules.refuse(slot, "nobody")` and nothing is armed. The release casts at the target's position with `{"to": clamp_to(...), "target": person}`.
- Hud: a `"nobody"` refusal pushes the banner `"NO ONE TO WHISPER TO"`, with the usual red flash and buzz.

- [ ] **Step 1: Tests**, in `test_targeting.gd`, with a loadout `["whisper", …]`:
  - a press 3 units from anyone arms nothing and records the refusal `[0, "nobody"]`;
  - a press on a citizen and a release 4 units away casts slot 0 with `extra.to` within 0.01 of the walkable release point, and `extra.target` that citizen;
  - a release 20 units away gives `extra.to` at most `REACH` from the citizen;
  - `aiming` is true between the press and the release.
- [ ] **Step 2: Targeting.**
  - Add `var _whisper_target: Person`.
  - `press()`: when `_rules.power(slot).aim == "whisper"`:
    - pick, and on null call `_rules.refuse(slot, "nobody")` and return;
    - otherwise set `_press = target.ground_pos`, `_whisper_target = target`, `armed = true`, `aiming = true`.
  - `release()` for whisper: `extra = {"to": MindWhisperFx.clamp_to(_crowd._grid, _press, ground), "target": _whisper_target}`.
  - `_draw()` for `"whisper"`:
    - with no press, a ring of `PICK_R` around the hovered citizen, if any;
    - while aiming, a ring on the target and a dotted line (8 dashes) from it to the clamped spot, gold. The part past `REACH` is drawn red (`COL_BAD`) up to the cursor.
  - `AREAS["whisper"] := {"shape": "circle", "r": MindWhisperFx.PICK_R}`, so the generic ring draws.
  - `_on_cast_made` needs no change: the power is quiet, so `Crowd.on_cast` returns early.
- [ ] **Step 3: Hud.** `_on_cast_refused`: `if _reason == "nobody": push_banner("NO ONE TO WHISPER TO")`.
- [ ] **Step 4: Run the tests and try it.** Launch `$G --path . --scene res://scenes/mission.tscn -- --loadout=whisper,heaven` and whisper a few people by hand (or use the `run` skill). Check:
  - they walk;
  - the glyph shows;
  - the ring marks the spot;
  - they resume;
  - the 8 s cooldown runs.
- [ ] **Step 5: Commit.** Message: `feat: aim Mind Whisper by dragging from a person to a spot (v0.08 M3)`.

### Task 18: Icon, clip, M3 gate

**Files:**
- Modify: `tools/dev/make_power_icons.py`, `tools/dev/behaviour_check.gd`
- Create: `assets/pixellab/icons/whisper.png`, `assets/pixellab/icons/hud/whisper.png`, `assets/clips/whisper.png`

- [ ] **Step 1: The icon.** Add `def whisper():` to the script, in the painted icons' manner (a dark field with one glowing subject): a pale gold eye inside a spiral of faint script-like strokes, on a deep indigo field. Register it in `PAINTERS`, then run `python tools/dev/make_power_icons.py whisper`. Look at both PNGs.
- [ ] **Step 2: The clip.**
  - In `behaviour_check._clip`, when `key == "whisper"`: snap to the nearest citizen, and pass `{"to": <that citizen + (4, 1), walkable>, "target": <them>}` through a whisper-aware `_force_cast`. Run it 6 seconds, so the walk shows.
  - Record it: `--scenario=clip --power=whisper --snap --seconds=6`.
  - Look at `assets/clips/whisper.png`.
- [ ] **Step 3: Import** (the new PNGs need `.import` files), run the tests, then commit the script, the PNGs and their `.import` files. Message: `assets: Mind Whisper's icon and draft clip (v0.08 M3)`.
- [ ] **Step 4: Gate (controller).**
  - tests, digest, crowd_check, the exact behaviour checksums, FLOW;
  - Prepare shows Mind Whisper under Dominion in Last Judgement's pool.
  - Tag `kak-v008-m3`, push, and update the ledger (`v08-m3` → `done`, `meta.powers` 18).

---

## Milestone 4 — The Warning

### Task 19: The town's pieces — the Unaware profile, the watchman, the bell's hold, witnesses

**Files:**
- Modify:
  - `src/game/response_profile.gd`, `src/game/mission/mission_def.gd`;
  - `src/game/crowd/citizen_profile.gd`, `routine_manager.gd`, `person.gd`, `bell_network.gd`, `crowd.gd`;
  - `src/game/mission.gd` (the bell-replaced banner);
  - `tests/test_profile.gd`, `tests/test_bell.gd`, `tests/test_quiet.gd`
- Create: none

**Interfaces:**
- Produces:
  - `ResponseProfile.unaware() -> ResponseProfile`: Organized's numbers with `escorts_per_duty = 0` and `title = "Unaware"`. Add `var title := ""`; `tier_name()` returns `title` when it is set. Its `lines()` work as today.
  - `MissionDef.response_profile()` returns `ResponseProfile.unaware()` for `profile == "unaware"`.
  - `CitizenProfile.Role.WATCHMAN`, appended last. `RoutineManager.WEIGHTS[WATCHMAN] = [0.1, 0.9, 0.0, 0.0]`. `CitizenProfile.WORK[WATCHMAN] = ["gate"]`; if `TownLayout.anchors()` has no `"gate"` kind, leave WORK out — the director sets `profile.work` itself.
  - `Person.observe(from, seconds := -1.0)`: a positive `seconds` replaces the random 1–3 s.
  - The watchman's look: `WATCH_CLOAK := Color("2a2630")` for the coat and a lantern (`WATCH_LANTERN := Color("ffd27a")`, a 1×2 px glow) in the leading hand.
  - `BellNetwork.hold_on_death := false`. When it is true, a dead keeper neither silences the bell nor calls an escort: `step()` and `call_keeper()` leave it waiting for `replace_keeper()`.
  - `BellNetwork.replace_keeper(p)`: `keeper_is_soldier = p.soldier`. The 1.5× climb applies once, through a new `_replaced` flag. `keeper_replaced` still fires.
  - Mission's banner on `keeper_replaced`: `"A SOLDIER TAKES THE BELL ROPE"` when the new keeper is a soldier, else `"THE WATCHMAN TAKES THE BELL ROPE"`.
  - `Crowd.nearest_witness(at: Vector2, exclude: Person = null) -> Person`: the nearest living person (citizen or soldier) not inside within `DOOM_WITNESS` of `at`, or null. `_settle_doom()` uses it (`!= null`), so the doom rule does not change.

- [ ] **Step 1: Tests.**
  - `test_profile.gd`: `unaware()` has a bell with an 8 s climb, Organized's fire brigade, no escorts (`escorts_per_duty == 0`), marshals and rescue squads as at Organized, and `tier_name() == "Unaware"`.
  - `test_bell.gd`, with `hold_on_death`:
    - kill the keeper after `call_keeper()`, then `step()` 5 s: the state is still `CALLED`, with no `silenced` signal;
    - `replace_keeper(a citizen)`: the climb is ×1.5, `keeper_is_soldier` is false, and `keeper_replaced` fired.

    Without `hold_on_death`, today's behaviour is unchanged (the existing tests cover it).
  - `test_quiet.gd`:
    - `nearest_witness()` returns the nearer of two people 1.0 and 1.5 away;
    - it returns null with nobody within 2.0, and skips anyone inside and the dead;
    - the existing Silent Doom witness tests still pass.
  - `test_person.gd`: `observe(at, 4.0)` watches for 4 s, give or take one think step.
- [ ] **Step 2: Implement.**
  - `nearest_witness()` scans `citizens + soldiers` like `_settle_doom()`.
  - In `_settle_doom()`, replace the inner loop with `var seen := nearest_witness(at) != null`.
  - Draw the watchman in `_draw_citizen`: the cloak replaces the coat when `role == WATCHMAN`; the lantern sits at the hand opposite the facing.
- [ ] **Step 3: Run the tests, crowd_check, digest and the exact behaviour checksums.** All unchanged: nothing here runs in Last Judgement.
- [ ] **Step 4: Commit.** Message: `feat: the Unaware town, the watchman, a bell that waits for a relay, and Crowd.nearest_witness (v0.08 M4)`.

### Task 20: The Warning's objectives and director

**Files:**
- Create:
  - `src/game/mission/bell_silent_objective.gd`, `warning_objective.gd`, `unseen_objective.gd`, `warning_director.gd`;
  - `src/fx/omen/falling_star.gd`;
  - `tests/test_warning.gd`
- Modify: `src/game/mission/mission_book.gd`, `src/game/ui/ui_theme.gd` (`mark()`), `tests/run_all.gd`, `tests/test_objectives.gd`, `tests/test_mission_book.gd`

**Interfaces:**
- Produces:
  - **The objectives:**
    - `BellSilentObjective`: FAILED with reason `"bell"` once `crowd.bell.state == RUNG`; `hud_text` is `""`.
    - `WarningObjective`: DONE with reason `"warning"` once `(rules.director as WarningDirector).warning_dead`; its label is `"Stop the warning"`.
    - `UnseenObjective` (a bonus): FAILED once `crowd.alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY`; its label is `"Unseen"`.
  - **The mission:**
    - `MissionBook.WARNING := "warning"` and `MissionBook.warning()`;
    - `all()` lists The Warning first.
  - **The director's state and constants:**
    - `WarningDirector.Phase { OMEN, STARE, RUN, DELIVERED, OVER }`;
    - `messenger: Person`, `watchman: Person`, `warning_dead: bool`, `relays: int`;
    - `delayed_by: Dictionary` (authority → true), `killed_by: String` (a power key);
    - `OMEN_AT := 2.0`, `STARE := 4.0`, `RETARGET := 0.5`, `DELIVER_REACH := 0.8`, `DELAY_REACH := 3.0`;
    - `GATE_SPOT`: the Main Gate's inner side, `Vector2(TownLayout.MAIN_GATE.get_center().x, TownLayout.MAIN_GATE.position.y - 0.6)`, adjusted to walkable ground.
  - `FallingStarFx`: a streak from high above to `origin` over 0.6 s, a white-gold flash and a ground light. **No `impact` and no hitstop:** it must not stall the frame or make the scenario inexact. **No threat registered.**
  - `UiTheme.mark(on: CanvasItem, at: Vector2, ok: bool)`: a 7×7 pixel tick (gold) or cross (`COL_BAD`) drawn with lines. The font has no ✔ glyph.

- [ ] **Step 1: Write `tests/test_warning.gd`.** It builds a crowd with `ResponseProfile.unaware()`, a `Rules` for `MissionBook.warning()`, and a `WarningDirector` set up with `ctx = null`. With a null `ctx`, the director skips the falling star but still emits the banners. The test steps `rules.advance(dt)` (which steps the director) and `crowd.advance(dt)` by hand, and arrives people as the constraints describe. The cases:
  - **Setup:** a watchman is appointed: role `WATCHMAN`, standing within 1.5 of `GATE_SPOT`, and not the bellkeeper.
  - **The omen:** at 2 s the banners `"A STAR FALLS OVER THE MAIN GATE"` and `"STOP THE WARNING"` are emitted. The watchman is `OBSERVE` until 6 s, then `DUTY`, with a goal within 0.5 of the keeper.
  - **Re-target:** move the keeper 3 units, then advance 0.6 s; the messenger's goal follows.
  - **Delivery:** arrive the messenger within 0.8 of the keeper, then advance. The bell is `CALLED`, the keeper is `DUTY`, `messenger == keeper`, and the watchman is off duty (`RECOVER` or `REGROUP`).
  - **Keeper dead first:** in a fresh setup, kill the keeper quietly (`field.kill(keeper, &"doom", ...)` with nobody near — move everyone else away first). The watchman's goal becomes `crowd.bell.foot`. Arrive him there: `bell.keeper == watchman`, the state is `CALLED`, and the climb is ×1.5.
  - **Unseen kill wins:** in a fresh setup, at RUN, move every other person more than 3 units from the watchman, kill him with `&"doom"`, then advance twice. Now `warning_dead`, `rules.finished`, `won`, reason `"warning"`, and `killed_by == ""` (no cast in a test; `report().solved_by` is empty).
  - **A witnessed death relays:** in a fresh setup, put one citizen 1.0 from the watchman and kill the watchman. That citizen is the messenger, `relays == 1`, the banner is `"THE WARNING PASSES ON"`, and the citizen is `DUTY` toward the keeper. The mission is not over.
  - **The bell rings — a loss:** set `crowd.bell.state = RUNG` and advance. Lost, reason `"bell"`.
  - **The omen fades — a win:** set `rules.time_left = 0.01` with the bell silent, then advance 0.1. Won, reason `"omen"`.
  - **Interruptions:** confuse the messenger mid-run (`confuse(15)`) and step 1 s: no re-send while `CONFUSED`. Call `_come_to()`, set the mind to `RECOVER`, and advance 0.6 s: the messenger is `DUTY` again. Do the same with `whisper()`.
  - **The Unseen bonus:** `UnseenObjective` is PENDING at the start; FAILED after `crowd.alarms.update(...)` reaches Local Emergency (use `crowd.alarms.incident()` × `LOCAL_EVENTS` in one district, then `update`).
  - **Delayed-by:** `rules.cast_made.emit(0, "discord", messenger.ground_pos)` records `delayed_by.disorder`. A cast 10 units away records nothing. On an omen-fade win, `report().solved_by == ["DISORDER"]`.

  Register the file in `tests/run_all.gd`. In `test_mission_book.gd`, add:
  - `warning()` is Tier 1, 3 slots, 6 DP;
  - its pool is `["whisper", "doom", "wisp", "discord", "thorns"]`;
  - clock 120, profile `"unaware"`, not scored, director `WarningDirector`;
  - objective reasons `["warning", "bell", "omen"]`, one bonus `"Unseen"`;
  - it is first in `all()`.
- [ ] **Step 2: The objectives and the mission.** `MissionBook.warning()`:

```gdscript
const WARNING := "warning"


static func warning() -> MissionDef:
	var m := MissionDef.new()
	m.id = WARNING
	m.name = "The Warning"
	m.tier = 1
	m.brief = PackedStringArray(["A star falls over the Main Gate.", "A watchman runs to wake the bell."])
	m.goal = "Stop the warning before the bell tolls, or until the omen fades"
	m.goal_label = "Stop the warning"
	m.slots = 3
	m.dp_capacity = 6
	m.pool = PackedStringArray(["whisper", "doom", "wisp", "discord", "thorns"])
	m.clock = 120.0
	m.profile = "unaware"
	m.intro_from = TownLayout.MAIN_GATE.get_center() + Vector2(0.0, 6.0)
	m.camera_at = TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
	m.intro_banner = "THE FIRST STIRRING"
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.director = WarningDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [WarningObjective.new(), BellSilentObjective.new(),
			ClockObjective.new(true, "Omen fades", "omen")]
		return out
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [UnseenObjective.new()]
		return out
	return m
```

  `all()` returns `[warning(), last_judgement()]`, ordered by tier.

  The objective files follow the Task 1 pattern. Each `_init()` sets `label` and `reason`.

  **The `WarningDirector`:**

```gdscript
class_name WarningDirector
extends MissionDirector
## The Warning (v0.08, Tier 1): the god's first stirring. At OMEN_AT a star falls over the Main Gate; the watchman
## stares at it for STARE seconds, then runs (a DUTY, at the run) to the bellkeeper -- wherever the keeper is now,
## re-aimed every RETARGET -- to tell them. The keeper climbs and rings the bell, and the mission is lost. The player
## wins by killing whoever carries the warning (the messenger) with nobody living near enough to see it
## (Crowd.DOOM_WITNESS), or by holding the warning off until the omen fades. A death that is seen passes the warning to
## the nearest witness, who runs on with it. If the keeper is dead, the messenger climbs the tower in their place.
## The bell holds for the relay (BellNetwork.hold_on_death) rather than falling silent when its keeper dies.

enum Phase { OMEN, STARE, RUN, DELIVERED, OVER }

const OMEN_AT := 2.0
const STARE := 4.0
const RETARGET := 0.5
## How near the messenger must come to the keeper to tell them.
const DELIVER_REACH := 0.8
## A cast within this of the messenger or the keeper counts as delaying the warning, for "Solved by".
const DELAY_REACH := 3.0
## A goal is only re-aimed when the keeper has moved this far from it (a fresh path every half second for nothing
## costs a path-find).
const RETARGET_MOVE := 0.3
## Minds the messenger picks the errand up again from: back on its feet after a fright, Discord or Mind Whisper.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var phase := Phase.OMEN
var watchman: Person
var messenger: Person
var warning_dead := false
var relays := 0
var killed_by := ""
## Authority -> true for every power cast near the warning while it lived.
var delayed_by := {}
var gate_spot := Vector2.INF
var _clock := 0.0
var _retarget_in := 0.0
## Where the messenger fell, waiting to be judged once the cast's other victims have fallen too.
var _fell_at := Vector2.INF
var _fell_kind := &""


func _begin() -> void:
	gate_spot = crowd._grid.nearest_walkable(Vector2(TownLayout.MAIN_GATE.get_center().x,
		TownLayout.MAIN_GATE.position.y - 0.6))
	if crowd.bell != null:
		crowd.bell.hold_on_death = true
	watchman = _appoint_watchman()
	messenger = watchman
	crowd._field.enemy_killed.connect(_on_killed)
	rules.cast_made.connect(_on_cast)


## The citizen living nearest the Main Gate (not the bellkeeper, the clergy or the engineers) keeps the gate tonight.
func _appoint_watchman() -> Person:
	var best: Person = null
	for p in crowd.citizens:
		if p.profile == null or p == (crowd.bell.keeper if crowd.bell != null else null):
			continue
		if p.profile.role in [CitizenProfile.Role.CLERGY, CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			continue
		if best == null or p.ground_pos.distance_to(gate_spot) < best.ground_pos.distance_to(gate_spot):
			best = p
	if best == null:
		return null
	best.profile.role = CitizenProfile.Role.WATCHMAN
	best.profile.work = gate_spot
	# Placed at the gate before the first frame, with whatever walk the routine gave them dropped.
	best.ground_pos = gate_spot
	best.anchor = gate_spot
	best._goal = Vector2.INF
	best._path = PackedVector2Array()
	best._target = gate_spot
	best.stay_left = 60.0
	return best


func step(delta: float) -> void:
	if phase == Phase.OVER:
		return
	_clock += delta
	if _fell_at != Vector2.INF:
		_judge()
		if phase == Phase.OVER:
			return
	match phase:
		Phase.OMEN:
			if _clock >= OMEN_AT:
				_omen()
		Phase.STARE:
			if _clock >= OMEN_AT + STARE:
				phase = Phase.RUN
				_send()
		Phase.RUN:
			_retarget_in -= delta
			if _retarget_in <= 0.0:
				_retarget_in = RETARGET
				_run()


func _omen() -> void:
	phase = Phase.STARE
	if ctx != null:
		FxTimeline.cast(FallingStarFx, ctx, gate_spot + Vector2(0.0, 0.8))
	rules.banner.emit("A STAR FALLS OVER THE MAIN GATE")
	rules.banner.emit("STOP THE WARNING")
	if _alive(watchman):
		watchman.observe(gate_spot + Vector2(0.0, 0.8), STARE)


## The messenger's way: to the keeper while the keeper lives, else to the tower's foot to climb it.
func _goal() -> Vector2:
	var bell := crowd.bell
	if bell != null and _alive(bell.keeper):
		return bell.keeper.ground_pos
	return bell.foot if bell != null else Vector2.INF


func _send() -> void:
	if _alive(messenger) and _goal() != Vector2.INF:
		messenger.go_duty(_goal())


func _run() -> void:
	if not _alive(messenger):
		return
	var bell := crowd.bell
	if messenger == (bell.keeper if bell != null else null):
		_deliver()
		return
	if messenger.mind == Person.Mind.DUTY:
		var keeper_alive := bell != null and _alive(bell.keeper)
		if keeper_alive and messenger.ground_pos.distance_to(bell.keeper.ground_pos) <= DELIVER_REACH:
			_deliver()
		elif not keeper_alive and not messenger.has_goal() and bell != null \
				and messenger.ground_pos.distance_to(bell.foot) <= BellNetwork.FOOT_REACH:
			bell.replace_keeper(messenger)
			phase = Phase.DELIVERED
		elif messenger.anchor.distance_to(_goal()) > RETARGET_MOVE or not messenger.has_goal():
			messenger.go_duty(_goal())
	elif messenger.mind in RESUMABLE:
		_send()  # back on its feet: the errand again


## The keeper is told: the bell is called, and the warning is the keeper's to carry now.
func _deliver() -> void:
	var bell := crowd.bell
	var was := messenger
	messenger = bell.keeper
	bell.call_keeper()
	if was != messenger:
		crowd.off_duty(was)
	phase = Phase.DELIVERED


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if e == messenger and phase != Phase.OVER:
		_fell_at = e.ground_pos
		_fell_kind = kind
		killed_by = rules.credited_key(kind)


## Judged a step after the death, once a cast's other victims are dead too (as Crowd._settle_doom()).
func _judge() -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	var witness := crowd.nearest_witness(at)
	if witness == null:
		warning_dead = true
		phase = Phase.OVER
		return
	relays += 1
	messenger = witness
	rules.banner.emit("THE WARNING PASSES ON")
	var bell := crowd.bell
	if phase == Phase.DELIVERED or (bell != null and witness == bell.keeper):
		# The keeper fell (or saw the watchman fall): the witness takes the rope, or the keeper climbs.
		if bell != null and witness != bell.keeper:
			bell.replace_keeper(witness)
		elif bell != null:
			bell.call_keeper()
		phase = Phase.DELIVERED
	else:
		phase = Phase.RUN
		_send()


func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if warning_dead:
		return
	var near := _alive(messenger) and messenger.ground_pos.distance_to(at) <= DELAY_REACH
	var bell := crowd.bell
	near = near or (bell != null and _alive(bell.keeper) and bell.keeper.ground_pos.distance_to(at) <= DELAY_REACH)
	if near:
		delayed_by[PowerBook.authority_of(key)] = true


static func _alive(p: Person) -> bool:
	return is_instance_valid(p) and p.is_alive()


func marker() -> Vector2:
	return messenger.ground_pos if _alive(messenger) and not warning_dead else Vector2.INF


## "Solved by": a kill's Authority, else -- the omen faded -- the Authorities that delayed the warning (v0.08; shown,
## not saved: Resonance comes in v0.09).
func report() -> Dictionary:
	var by := PackedStringArray()
	if warning_dead and killed_by != "":
		by.append(PowerBook.authority_title(PowerBook.authority_of(killed_by)))
	elif not warning_dead:
		for a in PowerBook.AUTHORITIES:
			if delayed_by.has(a):
				by.append(PowerBook.authority_title(a))
	return {"solved_by": by, "relays": relays}


func teardown() -> void:
	if crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	if rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
```

  Notes for the implementer:
  - **The relay.** "THE WARNING PASSES ON" overrides the witness's fright on purpose: the spec says the witness "runs on". `_settle_doom()` panics the witness in the crowd's advance, and the director's `go_duty` then replaces that mind. Rules' `_process` and the crowd's `_process` run in tree order, so the director may judge a frame later than the crowd; that is fine.
  - **The phase while delivered.** In `DELIVERED`, the keeper is the messenger. BellNetwork runs the climb and its retries, and with `hold_on_death` a dead keeper waits for `_judge()`.
  - **`killed_by`.** It reads `rules.credited_key(kind)` when the death happens. A Doom cast credits `"doom"` → Veil.
  - **The Authority title.** `PowerBook.authority_title(a)` is added in Task 8. If it was not, add it now: `AUTHORITY_TITLES[AUTHORITIES.find(a)]`.

  **`FallingStarFx`** (`src/fx/omen/falling_star.gd`):
  - `duration = 2.0` and `busy = 0.0`.
  - A trail of gold-white particles from screen `(origin + (-40, -160))` to the origin over 0.6 s, a flash with `FxParts.ground_light` peaking at 0.6 s, and a ring of sparks.
  - Base it on the parts the other effects use: read `src/fx/set2/heaven_splitter.gd` for a flash and `FxParts` for helpers.
  - Play a soft cue: copy a quiet sound already in the catalogue, such as Discord's `grav_shimmer`.

  **`UiTheme.mark()`:**

```gdscript
## A tick (gold) or a cross (red) seven pixels square, its top-left at `at`: the font has no check-mark glyph.
static func mark(on: CanvasItem, at: Vector2, ok: bool) -> void:
	if ok:
		on.draw_polyline(PackedVector2Array([at + Vector2(0, 4), at + Vector2(2, 6), at + Vector2(7, 0)]), COL_GOLD, -1.0)
	else:
		on.draw_line(at, at + Vector2(6, 6), COL_BAD, -1.0)
		on.draw_line(at + Vector2(6, 0), at + Vector2(0, 6), COL_BAD, -1.0)
```

- [ ] **Step 3: Import, then run the tests.** Iterate until `test_warning.gd` passes. Where a check fails only because of geometry (the gate spot, a keeper standing inside), tune the placements, and say so.
- [ ] **Step 4: Commit.** Message: `feat: The Warning's director -- the omen, the watchman's errand, the relay -- and its objectives (v0.08 M4)`.

### Task 21: The Warning on screen

**Files:**
- Modify:
  - `src/game/mission.gd`, `src/game/ui/hud.gd`, `src/game/ui/results_screen.gd`;
  - `src/game/ui/mission_board.gd` (the marks), `src/game/ui/prepare_screen.gd` (the fixed profile strip), `src/game/game.gd` (`--show=results` sample for The Warning)
- Modify tests: `tests/test_hud.gd`, `tests/test_results.gd`

- [ ] **Step 1: Tests.**
  - **`test_results.gd`:**
    - `title_for(true, "warning")` and `title_for(true, "omen")` are `"THE WARNING DIES"`;
    - `title_for(false, "bell")` is `"THE BELL TOLLS"`;
    - the Last Judgement titles are unchanged.
  - **`test_hud.gd`**, with a Warning `Rules` and director:
    - `hud.objective_rows()` is `[["Stop the warning", ""], ["Omen fades 2:00", ""], ["Unseen", "ok"]]` at the start;
    - `"x"` against Unseen after Local Emergency;
    - `hud.marker_screen()` is the messenger's screen point, or INF with no messenger;
    - `hud.edge_arrow(point_off_screen)` is a point inside the 640×360 frame, with a margin of 10.
- [ ] **Step 2: Mission.**
  - `_on_over` emits `ResultsScreen.title_for(won, reason)`.
  - The scripted print also covers unscored missions: `MISSION result won=%s reason=%s time=%.1f relays=%s`.
  - Mission's existing bell banner, `"THE BELL TOLLS - THE TOWN IS WARNED"`, stays.
- [ ] **Step 3: Hud.**
  - **The objective panel.** When `not _rules.mission.scored`, draw the generic panel in place of today's Citadel and stability panel. It shows `objective_rows()`: each row's text, then `UiTheme.mark()` after it when its mark is `"ok"` or `"x"`. `objective_rows()` lists:
    - each primary objective whose `hud_text` is not empty, with mark `""`;
    - each bonus, with `"x"` once it has FAILED and `"ok"` otherwise.
  - **The marker.** When `_rules.director != null` and `marker()` is not INF:
    - on screen: a small gold chevron 26 px above the messenger's feet. The world point goes through `get_viewport().get_canvas_transform()`, as the old DP popups did;
    - off screen: an arrow at the screen edge (10-px margin) pointing at the messenger.
  - While a marker shows, the HUD redraws every frame, like the banners.
  - `_signature()` includes the rows.
- [ ] **Step 4: Results.**
  - `title_for` as tested above.
  - When the result has no `"score"`, draw a layout without rank or score: the title, then a table with these rows:
    - `goal.label`, with a mark for `goal.done`;
    - each bonus's label, with a mark;
    - `"Time"`: `UiTheme.clock(time)`;
    - `"Solved by"`: the `solved_by` titles joined with `", "`, or `"—"`;
    - `"NEW BEST!"` when `best` is true.
  - Game's `--show=results` keeps the scored sample. Add `--show=results-warning` with a won Warning sample: Unseen earned, solved by Veil.
- [ ] **Step 5: The board and Prepare.**
  - The board shows The Warning's card with marks for "Won" and "Unseen".
  - Prepare for The Warning: the bottom strip shows `UNAWARE` and its Defense Profile lines, with no arrows.
- [ ] **Step 6: Play it.** Start the game, pick The Warning, draft Whisper, Doom and Discord, and play. Check:
  - the intro frames the gate;
  - the star falls at 0:02 with both banners;
  - the marker follows the watchman, and the edge arrow shows when he is off screen;
  - an unseen Doom wins with "THE WARNING DIES";
  - a seen one relays;
  - doing nothing loses to the bell at about 0:25.

  Capture the board, the Warning's Prepare, a mid-run frame, and both results.
- [ ] **Step 7: Run the tests and FLOW, then commit.** Message: `feat: The Warning on screen -- the objective panel, the messenger's marker, its results (v0.08 M4)`.

### Task 22: M4 gate (controller)

- [ ] Run the gates. Last Judgement is untouched by M4:
  - the digest, crowd_check, the exact behaviour checksums and the mission test match M3.
- [ ] FLOW: add one pass through the board that picks The Warning, manifests the default loadout, lets the clock run out (set `time_left = 0.01`), and lands on Results with reason `"omen"`. It then returns to the board through Missions.
- [ ] Tag `kak-v008-m4`, push, and update the ledger (`v08-m4` → `done`).

---

## Milestone 5 — Wrap-up

### Task 23: The `warning` scenario and the balance pass

**Files:** Modify `tools/dev/behaviour_check.gd`.

- [ ] **Step 1: The scenario.** `--scenario=warning --case=<none|doom|whisper|discord|thornwall|mix>`:
  - It starts the mission with `mission.mission_id = MissionBook.WARNING` before `start()`, and powers per case: `doom` → `["doom"]`, `whisper` → `["whisper"]`, `discord` → `["discord"]`, `thornwall` → `["thorns"]`, `mix` → `["whisper", "discord", "doom"]`, `none` → `[]`. Add `"warning"` to the scenarios whose `start()` takes powers.
  - Every 0.1 s, it plays the case's policy against the director's messenger:
    - **doom:** cast on the messenger when `crowd.nearest_witness(messenger.ground_pos, messenger) == null`; otherwise wait.
    - **whisper:** whisper the messenger 8 units straight back toward the gate, whenever the slot is ready and the messenger is running.
    - **discord:** cast on the messenger whenever ready.
    - **thornwall:** once the messenger is running, cast across the street 3 units ahead of him (drag dir perpendicular to his heading); again whenever ready.
    - **mix:** whisper first; Discord when he resumes; Doom whenever he is alone.
  - Every 5 s, print `BEHAVIOUR warning t=… phase=… messenger_mind=… relays=… bell=… stage=…`.
  - At the end, print `BEHAVIOUR warning end case=… won=… reason=… time=… relays=… unseen=… solved_by=…`.
- [ ] **Step 2: Run each case three times.** Record the lines in "Execution notes". The spec's expectations:
  - `none` loses to the bell at about 0:25;
  - `doom` wins when it finds the watchman alone; otherwise it relays;
  - `whisper`, `discord` and `thornwall` each delay;
  - `mix` wins.
- [ ] **Step 3: Balance.** Compare with the spec's intent: each Authority solves it, and none trivialises it.
  - The unhindered ring should fall between 0:20 and 0:35. Tune `OMEN_AT`, `STARE` and the watchman's start spot to get it there; these are placements.
  - **A known risk.** Mind Whisper, at 8 s cooldown, `REACH` 10 and an 8 s linger, may hold the messenger off for the whole 2:00 on its own: a walk of up to 16 s, then the linger, then a run back. If `whisper` alone wins every run, **do not change the spec's numbers**. Report the measurements, and add a ledger task with `needs_you: true` that offers options: a longer cooldown (15 s), a shorter `REACH` (6), or a messenger who ignores a second whisper within 20 s.
- [ ] **Step 4: Commit the scenario.** Message: `tools: The Warning's scenario, one case per Authority (v0.08 M5)`.

### Task 24: Bench, summary, tag

**Files:** Create `docs/KAK_Version_0.08_Summary.md`. Modify `README.md` if it lists versions or controls.

- [ ] **Step 1: Bench.** On a quiet machine, run the bench for the M4 build three times. Alternate the runs with a `kak-v0.07.1` worktree in the scratchpad: `git worktree add <scratch>/v0071 kak-v0.07.1`, then copy `.godot` in, as in earlier benches. Last Judgement must be within 5 fps of `kak-v0.07.1` (spec §6). If it is not, profile it before changing anything (memory note `kak-m1-perf-debt`). Also bench The Warning once (`--mission=warning --bench`) and record the result.
- [ ] **Step 2: Run the final gates.**
  - tests, digest, crowd_check, FLOW;
  - the exact behaviour checksums;
  - the mission test;
  - every `warning` case.
- [ ] **Step 3: The summary.** Write `docs/KAK_Version_0.08_Summary.md` in the style of `KAK_Version_0.07_Summary.md`. Cover:
  - what is new (the board, the loadout, Mind Whisper, The Warning);
  - the retuned numbers (cooldowns, ranks), with Task 13's medians;
  - the gates, with their numbers;
  - the bench;
  - the balance findings;
  - what is deferred to v0.09: Resonance, Trials, the campaign save, civilization memory.
- [ ] **Step 4: Commit, then tag (controller).** Commit with the message `docs: KAK v0.08 summary`. Then tag `kak-v0.08` and push the branch and its tags.
- [ ] **Step 5: The ledger (controller).**
  - `v08-m5` → `done`;
  - `meta/project`: version `v0.08`, tag `kak-v0.08`, tests, fps, powers 18, a note;
  - add `releases/v008` with the tag, the date, the checks, a summary and highlights;
  - add `todo` cards for the follow-ups found in Tasks 13 and 23.

---

## Self-review against the spec

| Spec | Where |
|---|---|
| §1 MissionDef, MissionBook, objectives, director, Rules loop, flow, saves; M1 a pure refactor | Tasks 1–6 |
| §1 Last Judgement's evaluation order | Task 3 (`_check_end` in list order; the Citadel first) |
| §2 prices, slots, budget; nothing spent in a mission; removals; Divine Surge | Tasks 8–10 |
| §2 score retune; LJ tuned "about as before" | Tasks 7, 13 |
| §2 Authorities replace kinds | Tasks 8, 12 |
| §3 Unaware, the watchman, the omen, the errand, the keeper dead, interruptions, relay, win/lose, Unseen, on screen, results, Solved by | Tasks 19–21 |
| §4 Mind Whisper's aim, refusal, preview, effect, resume, immunities, look, icon, clip | Tasks 15–18 |
| §5 the board, Prepare, the in-mission bar, Results | Tasks 5, 11, 12, 21 |
| §6 the tests listed; the `warning` scenario; the gates; the bench | Tasks 1–24; Tasks 23, 24 |

**Interpretations to confirm with the user (also listed in the report):**
1. **How a mission is decided.** "All primaries done wins it" cannot express The Warning's either-or win, or Last Judgement's lose-only clock. The plan decides in list order: the first primary objective to report DONE wins, and the first to report FAILED loses. This keeps Last Judgement's order exactly.
2. **The messenger after delivery.** Once the keeper is told, the keeper is the messenger. The marker moves to the keeper, killing the keeper unseen still wins, and a witnessed death passes the rope to the witness.
3. **"Delayed a messenger" for Solved by.** A power cast within 3 units of the messenger or the keeper, while the warning is alive.
4. **Pause and Results.** Both offer Missions in place of Title. The Title is reached from the board, with Esc.
5. **Tags.** `kak-v008-m1` to `kak-v008-m4`, matching the earlier milestone tags, then `kak-v0.08`.

## Execution notes

### Task 0 baselines (BURIN_NITRO, 2026-10-03, at 369ec52 = kak-v0.07.1 code)

- tests `checks=1065 failures=0`; digest `rows=19 digest=61267b7e90524d800bf1c3473a71146b emitters=45`;
  crowd_check `checksum=-346732806 alive=220 escaped=0`; FLOW `checks=24 failures=0`.
- Exact behaviour checksums (two identical runs each):
  - `calm --seconds=60` -695580348
  - `gates` 619520995
  - `fire` -16560442
  - `rite --interrupt` -129298221
  - `soldiers --case=escort` -935015846
  - Dropped: `bell --kill-keeper` (-845730435, then -49782016): it casts a Heaven Splitter, so its hitstop is wall-clock.
- Mission test (it ends at 34 s, before any `MISSION result` line):
  - `dp=21.5 buildings=53 citizens=181 escaped=0 alarm=100 stability=69% citadel=50%`
  - `dp=21.5 buildings=57 citizens=175 escaped=0 alarm=100 stability=66% citadel=50%`
  - `dp=21.5 buildings=52 citizens=181 escaped=0 alarm=100 stability=69% citadel=50%`
- Bench (mission, Organized): 122.7 / 123.9 / 125.1 fps; worst 19.4 / 18.8 / 18.0 ms; draw calls 1052.

### M1 gate (at 0402472)

- Tests `checks=1120 failures=0`; digest unchanged; crowd_check `-346732806`; FLOW `checks=30 failures=0`.
- All five exact behaviour checksums identical to Task 0.
- Mission test, three runs: buildings 55/55/51, citizens 186/188/188, escaped 1/1/1, stability 69/69/70%, citadel 50%.
  - These are about 8 citizens higher and 1 escaped more than Task 0. The unchanged a875fd1, run the same day, gave the same (187–191 citizens, 1 escaped), so the drift is machine timing (the wall-clock hitstop), not M1.
- Deviations reported by the implementers:
  - The Task 1 test brings the Citadel down as `test_rules.gd` does.
  - Bonus results use the key `bonuses`.
  - The FLOW test waits out the fade before its second MANIFEST, and waits two frames after the title.
  - The board has a key-hint line, and hovering a card selects it.
  - Known small issue, left for later: a MANIFEST pressed during a fade-in is ignored.

### Task 7 judgement baseline (pre-M2)

- Measured at 5bd39e5 plus the scenario, on BURIN_NITRO, 2026-10-03.
- One run takes about 135 s of wall time (a mission of about 85 s of game time at `--fixed-fps 60`).
- The scenario counts `t` in game time (each frame's scaled delta): with hit-stop, counting frames would run ahead of the mission's clock. Its loop also stops after twice the mission's clock in frames, so a run always ends. `_run()` already turns the intro off (`_intro_left = 0.0`, the rules processing).
- Five runs, all Organized, the default loadout:
  - `end t=87.3 citadel_fell=47.1 won=false reason=escapes escaped=50 buildings=79 score=6930 rank=C dp_left=16.733`
  - `end t=88.6 citadel_fell=47.2 won=false reason=escapes escaped=50 buildings=79 score=6965 rank=C dp_left=17.404`
  - `end t=84.7 citadel_fell=47.3 won=false reason=escapes escaped=50 buildings=80 score=7045 rank=C dp_left=25.419`
  - `end t=83.7 citadel_fell=47.2 won=false reason=escapes escaped=50 buildings=80 score=7010 rank=C dp_left=24.934`
  - `end t=87.0 citadel_fell=47.2 won=false reason=escapes escaped=50 buildings=79 score=6910 rank=C dp_left=16.613`
  - A sixth run was thrown away: an R pressed in its window restarted the mission (`Mission._unhandled_input`), freeing the Rules the scenario held. The fourth line above is its redo.
- The 30-s reports (first run; the others differ by at most one escape):
  - `t=30 citadel=50% stability=75% escaped=0 buildings=44 stage=Evacuation`
  - `t=60 citadel=0% stability=47% escaped=19 buildings=64 stage=Collapse`
- **No run wins.** The Citadel falls at about 47 s, but stability is still about 47% at 60 s and never reaches zero. Every run is lost to the escape limit at 84–89 s.
- Medians over all five runs, since none won: `citadel_fell` 47.2, `escaped` 50, `score` 6965 (a loser's score: no win bonus, no time or DP), `floor(dp_left)` 17 (16, 16, 17, 24, 25). The end `t` has a median of 87.0 and `buildings` a median of 79.

### Task 13 judgement after M2

- Measured at 97e9b52 (M2 Tasks 8-12: no DP spent in a mission, the new prices and cooldowns, the Divine Surge), on
  BURIN_NITRO, 2026-10-03, five runs, Organized, the default loadout (`heaven`, `tsunami`, `cinder`, `nova`).
  - `end t=85.6 citadel_fell=46.9 won=false reason=escapes escaped=50 buildings=77 score=6815 rank=C dp_left=<null>`
  - `end t=86.9 citadel_fell=47.0 won=false reason=escapes escaped=50 buildings=84 score=7435 rank=C dp_left=<null>`
  - `end t=85.2 citadel_fell=47.1 won=false reason=escapes escaped=50 buildings=77 score=6850 rank=C dp_left=<null>`
  - `end t=85.1 citadel_fell=47.0 won=false reason=escapes escaped=50 buildings=77 score=6850 rank=C dp_left=<null>`
  - `end t=87.3 citadel_fell=47.1 won=false reason=escapes escaped=50 buildings=84 score=7400 rank=C dp_left=<null>`
  - The 30-s reports: `t=30 citadel=50% stability=75% escaped=0 buildings=44 stage=Evacuation` in every run;
    `t=60 citadel=0% stability=49% escaped=18-19 buildings=57 stage=Collapse`.
- Medians, before (Task 7) -> after: `citadel_fell` 47.2 -> 47.0, end `t` 87.0 -> 85.6, `escaped` 50 -> 50 (every run
  lost to the escape limit, as before), `buildings` 79 -> 77, `score` 6965 -> 6850, rank C -> C.
- The comparison (spec §2, as the controller adjusted it, since the Task 7 baseline never won): the median
  `citadel_fell` stays in the same 30-second window (30-60 s), the median end time is within 10 s of 87.0 s with the
  same ending (escapes at 50), so escapes are within 5. **No cooldown was tuned:** heaven 30, tsunami 60, cinder 75 and
  nova 120 s stay as Task 8 set them. No tuning attempts.
- The ranks: no run wins, so there is no winning median to compare. Each threshold of `Rules.RANKS` was lowered by the
  median DP term the Task 7 runs still held at their end, `floor(dp_left)` 17 x 10 = 170, rounded to 200:
  `[[19000, "S"], [14200, "A"], [9400, "B"], [4600, "C"]]` (was 19200/14400/9600/4800). **This is derived from losing
  runs**, whose score never had the DP term; a winning v0.07 run's DP term may differ. The median losing run is a C
  before (6965) and after (6850). `tests/test_score.gd` drives the new thresholds exactly with chains (300) and
  buildings (40). `Game.SAMPLE_RESULT` (15350, "S") does not follow the thresholds (it was already an A's score at
  19200) and is left as it is.
- Tests `checks=1140 failures=0`; FLOW `checks=30 failures=0`.

### M2 gate (at 9ae912c)

- Tests `checks=1140 failures=0`; digest unchanged; crowd_check `-346732806`; FLOW `checks=30 failures=0`.
- All five exact behaviour checksums identical to Task 0.
- Mission test, three runs: buildings 55/56/56, citizens 188/179/184, escaped 1/0/0, stability 69/67/69%, citadel 50%. The DP field is gone.
- Captures checked: the mission bar with six slots (names and cooldowns), and Prepare with the budget meter, dimmed cards and "Not enough Divine Power".
- Not changed: no cooldown was tuned in Task 13. The ranks are 200 lower each.

### M3 gate (at 28d4ebc)

- Tests `checks=1181 failures=0`; digest unchanged; crowd_check `-346732806`; FLOW `checks=30 failures=0`.
- All five exact behaviour checksums identical to Task 0.
- Mission test, three runs: buildings 53/55/55, citizens 187/190/192, escaped 1/1/1, stability 69/70/70%.
- Mind Whisper:
  - 18 powers; Dominion holds Mind Whisper and Will-o'-Wisp.
  - Icon painted (numpy and Pillow installed for the user's Python 3.12).
  - Draft clip recorded at `--at=0,11 --seconds=8`, on open paving. The destination ring was strengthened (alpha 0.9, fill 0.25, with a halo and a pulse) after the first clip did not read.
- Deviations: `clamp_to` now never passes REACH. The press refuses with the slot's own reason first. A target that dies mid-drag refuses the cast.
